---
title: 协程入门
categories: 学习笔记
tags:
  - C++
  - 协程
mathjax: true
date: 2026-11-18 19:16:15
---

`std::thread` 能不能看做能够暂停执行的函数?

<!--more-->

一般认为线程是抢占式的, 协程是协作式的, 所以称为协程

> 协程是一种能够暂停执行的函数：通过 `suspend` 操作暂停后，可以在稍后的某个时刻通过 `resume` 操作继续执行

协程本身不是并发的, worker 对协程的执行可能是并发的

(当然按这个说法 `std::thread` 本身也不是并发的, 是 CPU 核对线程的执行可能是并发的)

- 按 **控制转移机制** 区分, 分为对称协程和非对称协程
- 按 是否能够在**嵌套调用内部**暂停执行 区分, 分为有栈协程和无栈协程

# 协程之前

## 可维护性

异步读: 

- 通过回调实现

```cpp
void read_data() {
    async_read(fd, [](auto data) {
        async_process(data, [](auto result) {
            async_write(fd, result, [] {
                async_flush(fd, [] {
                    async_close(fd, [] {
                        // 完成
                    });
                });
            });
        });
    });
}
```

- 通过协程实现

```cpp
task<void> read_data() {
    auto data = co_await async_read(fd);
    auto result = co_await async_process(data);
    co_await async_write(fd, result);
    // 完成
}
```

从这个例子来看, 协程的控制权转移和回调是差不多的, 注册回调看做协程注册 handle 的部分, 调用回调看做协程的 `handle.resume()`

这里体现了协程的一些主要好处: 

- 最后的 `完成` 部分, 我们仍在初始的 `read_data` 内部, 这部分所需要的数据不需要一层层传给回调函数 (万一需要的数据变了接口全得改), 而是通过协程帧等方式自动处理
- 可以随意拆分 `read_data`; 回调版本只能改接口, 把拆分后的部分再作为回调

当然从理论上讲协程也是通过回调实现的, 所以两者的表达能力是相同的

## 性能

### 线程

>  A context switch between threads requires system calls (involving the OS kernel), which can cost more than thousand CPU cycles on x86 CPUs. By contrast, transferring control vias callcc()/continuation requires only few CPU cycles because it does not involve system calls as it is done within a single thread. 

额外消耗:

- 用户态内核态切换
- 内核调度器
- 可能切换到其他进程的线程导致的 tlb miss
- 可能被切到其他核

# 分类

## 无栈协程 (状态机)

提供三个操作:

- `create`: 创建, 但不执行
- `resume`: 开始执行(转移)
- `yield`: 到达下一个状态, 暂停执行

需要把所有跨越状态使用的变量额外保存在堆上, 实现类似于:

(注意无栈协程的暂停点是编译期确定的, 所以无栈协程可以不保存寄存器)

(如果编译器能确定协程生存期严格嵌入 caller 生存期中, 也可以放在 caller 的栈帧或者协程 frame 中)

```cpp
Task foo() {
    int a = 10;
    co_await something();
    int b = a + 1;
    // ...
}
```

```cpp
struct FooFrame {
    int state;
    int a;

    void resume() {
        switch (state) {
        case 0:
            a = 10;
            state = 1;
            return;

        case 1:
            int b = a + 1;
            // ...
            return;
        }
    }
};
```

[一个示例](https://lewissbaker.github.io/2017/09/25/coroutine-theory#an-illustration)

## 有栈协程

和线程类似, 保存着当前的调用栈 (不管是协程的, 还是协程调用的非协程函数的), 协程暂停时还需要保存寄存器之类的 (更可能需要编译器开洞或者手写汇编)

## 对称协程

可以将控制权交给任意协程

## 非对称协程

只能将控制权交给调用者

# 常见实现

## cpp20:

无栈, 对称转移

一般来说, C++ 启动协程后获取这个协程的 handle (或者能拿到协程 promise 的任何东西), 通过协程的 promise 获取实际执行完成的返回值

之所以是一般来说, 是因为 C++ 是自由的

C++ 经常为了解决一个问题, 通过一个特性, 后来因为太自由功能太强大, 这个特性实际用来做的事和原先的问题没什么关系了; 我看协程有这个潜力

> 在 C++ 看来, 协程就是函数体包含 `co_await`, `co_yield`, `co_return` 关键字之一的函数
> C++ coroutine 是无栈且对称转移的

似乎标准没规定, 但是对于常见的实现, 我们可以认为跨挂起点的局部变量一开始就是分配在协程帧上的, 在协程函数中对他们的操作也是在帧上操作的 (而不是平时在栈上, 挂起后复制到帧里)

### promise

(不是 `std::promise`, 但是在典型协程中使用方式是相似的)

promise 实例的一些方法会在协程调用的一些时机被调用, 用来控制协程的行为

```cpp
struct promise
{
    // 必须实现: 
    some_handle get_return_object() { return /*{some_handle::from_promise(*this)};*/ } // 返回协程调用者看到的返回对象, 就是调用后立刻返回的那个
    some_awaiter initial_suspend() noexcept { return {}; } // 返回协程创建后的挂起操作
    some_awaiter final_suspend() noexcept { return {}; } // 返回协程执行结束时的挂起操作
    void return_void(void) {} // 或者 void return_value(foo_T); 设置协程通过 co_return 返回的返回值; 理论上如果没有 co_return 就不需要这个函数, 但是所有 coroutine 如果没有显式 co_return 都会在末尾添加一个隐式的 co_return, 所以省不掉的
    void unhandled_exception() {} // 异常处理, 协程体中的异常没有被内部捕获时调用


    // 可选实现:
    some_awaiter yield_value(foo_T) {} // 返回协程 yield 的结果
    auto await_transform(some_T&& value); // 可以在进入 co_await <expr> 处理之前, 改写 <expr>
    static some_handle get_return_object_on_allocation_failure() noexcept; // 字面意思
    static void* operator new(std::size_t size); // 替换创建协程帧的 operator new; 还可以传入协程的一些参数, 允许通过这些参数做一些操作 (比如得出需要分配的最终大小)
    static void operator delete(void* ptr) noexcept;
};
```

协程函数体的一部分会被编译器替换为对协程的 promise 成员函数的调用, 对于一个函数体为 `<body-statements>` 的协程函数, 其协程体会被变换为大致如下的形式：

```cpp
{
    /*
        - 使用 operator new 分配协程帧 (可选)
        - 把所有函数参数复制到协程帧 // 他们肯定跨第一次挂起
        - 调用 promise 对象的构造函数
        - 调用 promise.get_return_object() 获取协程首次挂起时要返回给调用方的结果, 并将其保存为局部变量。
    */

    co_await promise.initial_suspend(); // 首次挂起

    // 在这之前的部分被称作 ramp, 会受到用户定义的协程函数签名影响
    // 下面的部分除了 destroy 的部分都被称作 body, 不难看出 body 没有 abi 问题, 全是编译器决定的

    try
    {
        // <body-statements>

        /*
            到达 co_return 时还会执行一些额外步骤:
            - 调用 promise.return_void() 或 promise.return_value()
            - 按创建顺序的逆序销毁所有具有自动存储期的变量
        */
    }
    catch (...)
    {
        promise.unhandled_exception(); 
        /*
            如果 unhandled_exception 也抛出异常, 就传播到协程外, 还会
            - 调用 promise, 函数参数的析构
            - 使用 operator delete 销毁协程帧 (可选)
            这部分也属于 destroy
        */ 
    }
FinalSuspend:
    co_await promise.final_suspend();

    // 接下来的部分属于 destroy
    // - 调用 promise, 函数参数的析构
    // - 使用 operator delete 销毁协程帧 (可选)
}
```

### handle

一般来说协程的返回值继承或持有 `coroutine_handle<yourPromise>`, 一个非拥有指针, 可以让我们操作协程

`coroutine_handle` 大概会长这样:

```cpp
namespace std
{
  template<typename Promise>
  struct coroutine_handle;

  template<>
  struct coroutine_handle<void>
  {
    bool done() const; // 判断是否完成

    void resume(); // 恢复 
    void destroy(); // 销毁, 一般是由拥有 handle 的管理类 RAII 自动管理的

    void* address() const;
    static coroutine_handle from_address(void* address); // 中 promise 中找回 handle: 同一个协程的 promise 和 handle 在同一个协程帧中, 地址偏移是确定的
  };

  template<typename Promise>
  struct coroutine_handle : coroutine_handle<void>
  {
    Promise& promise() const;
    static coroutine_handle from_promise(Promise& promise); // 需要确保 promise 类型与协程帧所使用的具体 promise 类型完全一致: 如果 promise 类型是 Derived, 构造 coroutine_handle<Base> 是 ub
    static coroutine_handle from_address(void* address);
  };
}
```

### `co_await`

一个一元运算符, 可以作用在一个 `Awaitable` 上, 代表挂起直到异步操作 `Awaitable` 完成

`Awaitable` 是要 `co_await` 的目标, 主要逻辑在其 `await_suspend` 中; 当前协程的 handle 会被传递给 `Awaitable` 的 `await_suspend` 的参数, 当前的函数栈就会被销毁, handle 作为和异步操作的联系, 供后来找到当前协程帧并恢复执行

- `Awaitable`: 能被 `co_await` 调用的类型 (可能通过 `operator co_await()` 返回另一个 `Awaiter`, 所以不一定是一个 `Awaiter`)
- `Awaiter`: 实现下列接口的类型 (一个 `Awaiter` 一定是一个 `Awaitable`): 这些接口允许程序员做一些自定义操作
    - `await_ready()`: 判断是否需要挂起时调用的回调函数, 避免下面 `<suspend-coroutine>` 操作的开销
    - `await_suspend(std::coroutine_handle<>)`: 挂起时调用的回调函数, 传入执行 `co_await` 表达式的协程的 handle, 返回 `bool` 或 `void` (代表是否一定挂起); 一般用来启动异步操作, 且负责在异步操作结束后恢复当前的协程, 比如注册回调函数调用 handle 的 resume, 或者把 handle 扔给调度器
        - 返回 `bool`: `true` 代表真的挂起, 否则继续执行 `co_await` 后面的代码; 避免 `await_ready` 到 `await_suspend` 之间的部分状态发生了变化
        - 返回 `void`: 一定挂起
    - `await_resume()`: 恢复时调用的回调函数, 其返回值就是整个 `co_await <expr>` 的返回值; 如果抛出异常就从 `co_await` 传播出去

非对称转移的 `co_await <expr>` 流程如下:

1. 获取 Awaitable: 如果**协程**的 promise 有 `await_transform` 方法, 就通过 `promise.await_transform(<expr>)` 获取; 否则把 `<expr>` 本身作为 Awaitable
2. 获取 Awaiter: 如果 Awaitable 有 `operator co_await()` 方法, 就用这个获取 Awaiter; 否则把 Awaitable 作为 Awaiter
3. 挂起

```cpp
{
  auto&& value = /*<expr>*/;
  auto&& awaitable = get_awaitable(promise, static_cast<decltype(value)>(value)); // 当前协程的 promise
  auto&& awaiter = get_awaiter(static_cast<decltype(awaitable)>(awaitable));
  if (!awaiter.await_ready()) // 异步操作是否已完成, 是否不需要挂起
  {
    using handle_t = std::experimental::coroutine_handle<P>;

    using await_suspend_result_t =
      decltype(awaiter.await_suspend(handle_t::from_promise(promise)));

    // <suspend-coroutine>
    // 挂起, 这里编译器会生成代码来保存协程当前状态并为其恢复做好准备，包括存储 <resume-point> 的位置，以及把协程帧中被缓存到寄存器中的新值写回协程帧

    if constexpr (std::is_void_v<await_suspend_result_t>) // 是 void, 一定挂起
    {
      awaiter.await_suspend(handle_t::from_promise(promise));
      // <return-to-caller-or-resumer>
    }
    else
    {
      static_assert(
         std::is_same_v<await_suspend_result_t, bool>,
         "await_suspend() must return 'void' or 'bool'.");

      if (awaiter.await_suspend(handle_t::from_promise(promise))) // true 就挂起, 否则继续执行
      {
        // <return-to-caller-or-resumer>
      }
    }

    // <resume-point> // 调用 handle.resume() 时在这里开始执行
  }

  return awaiter.await_resume();
}
```

注意 `<return-to-caller-or-resumer>` 后这个 "栈" 就销毁了, 恢复时从 `<resume-point>` 所需要的内容就保存在协程帧里了

{% note info 快速安全切换协程 worker %}

可以注意到 `await_suspend` 是在 协程挂起之后, 转移控制权之前 调用的

有一种 trick 用法是 `Awaiter` 对象在协程已经挂起之后启动异步操作, 并把已挂起协程的 `coroutine_handle` 传给该操作; 操作完成时 (可能在另一个线程上), 它可以直接安全地恢复协程, 不需要任何额外的同步

这种用法需要注意: 在传递完 handle 后, `await_suspend` 就要避免访问 `this` 和 promise; 因为在 交出 handle 之后, `await_suspend` 结束之前, 协程就可能已经恢复了, 这时整个 `Awaiter` 对象都已经被析构了

还是太 trick 了, 尽量少用

```
Time     Thread 1                           Thread 2
  |      --------                           --------
  |      ....                               Call OS - Wait for I/O event
  |      Call await_ready()                    |
  |      <await-ready>                         |
  |      Call await_suspend(handle)            |
  |        Store handle in operation           |
  V        Start AsyncFileRead ---+            V
                                  +----->
                                            Load coroutine_handle from operation
                                            Call handle.resume()

                                              Call to await_resume()
                                              execution continues....
           Call to AsyncFileRead returns
         Call to await_suspend() returns
```

有栈协程就很难做到这一点: 大部分有栈协程框架中, 一个协程的挂起与另一个协程的恢复被合并成一次 "上下文切换"; 在这种 "上下文切换" 中一般没有机会在 挂起当前协程之后、把执行权转移给另一个协程之前 执行逻辑

如果我们想在有栈协程上实现类似的异步文件读操作, 就必须在挂起协程*之前*启动操作; 而操作有可能在 协程挂起、具备恢复资格 之前 就在另一个线程上完成, 这时调用恢复就会存在竞争, 需要线程同步

[参考](https://lewissbaker.github.io/2017/11/17/understanding-operator-co-await#synchronisation-free-async-code)

{% endnote %}

还有一个有趣的内存分配优化:

{% note info 内存分配优化 %}

考虑传统 callback 方式的异步调用: 

```cpp
struct ReadOperation {
    OVERLAPPED overlapped;
    char buffer[4096];
};

void async_read() {
    auto* op = new ReadOperation();

    ReadFile(
        file,
        op->buffer,
        sizeof(op->buffer),
        nullptr,
        &op->overlapped
    );

    // 不能在这里 delete op, 因为 I/O 操作可能还没有完成
    // 需要在操作完成后通过 callback 找到对应的 ReadOperation 并释放

    // ...
}
```

并发高的情况下会产生大量的堆分配和释放

考虑协程的情况: 

```cpp
Task read_async() {
    ReadOperation op;

    co_await async_read(file, op);

    // op 保存在协程帧上, 可以复用帧的的空间, 且在异步操作中保持有效
    // 局部变量不用手动管理生命周期

    // ...
}
```

更好的方法可以把只有异步操作需要的内存放在 `Awaiter` 里:

```cpp
struct ReadAwaiter {
    OVERLAPPED overlapped;
    char buffer[4096];

    bool await_ready() noexcept {
        return false;
    }

    void await_suspend(std::coroutine_handle<> h) {
        // 启动异步 I/O
        // 将 &overlapped 传给操作系统
        // 保存 h，等待 I/O 完成
    }

    void await_resume() noexcept {
        // 处理 I/O 结果
    }
};

Task read_async() {
    co_await ReadAwaiter{};
}
```

注意 `Awaiter` 跨越了调用点, 也需要保存在协程帧中; `op` 在异步操作完成后, 随着 `Awaiter` 的销毁而被销毁, 协程帧的空闲空间可以留给下一次挂起使用

其实就是类似手动的

```cpp
Task read_async() {
    {
        ReadOperation op;
        co_await async_read(file, op);
    }
}
```

吧?

[参考](https://lewissbaker.github.io/2017/11/17/understanding-operator-co-await#avoiding-memory-allocations)

{% endnote %}


### `co_yield`

`co_yield <expr>`: 向 promise 中产生值 `<expr>` 并挂起

实现上基本就是 `co_await promise.yield_value(<expr>)`

```cpp
#include <coroutine>
#include <iostream>

struct Generator {
    struct promise_type {
        int value;
        Generator get_return_object() { return Generator{ std::coroutine_handle<promise_type>::from_promise(*this) }; }
        std::suspend_always initial_suspend() noexcept { return {}; }
        std::suspend_always final_suspend() noexcept { return {}; }
        std::suspend_always yield_value(int v) noexcept {
            value = v;
            return {};
        }
        void return_void() {}
        void unhandled_exception() { std::terminate(); }
    };

    using handle_type = std::coroutine_handle<promise_type>;
    handle_type handle;

    explicit Generator(handle_type h) : handle(h) {}
    ~Generator() {
        if (handle) {
            handle.destroy();
        }
    }

    bool next() {
        if (!handle || handle.done()) {
            return false;
        }

        handle.resume();
        return !handle.done();
    }

    int value() const {
        return handle.promise().value;
    }
};

Generator generate() {
    co_yield 10;
    co_yield 20;
    co_yield 30;
}

int main() {
    Generator gen = generate();

    while (gen.next()) {
        std::cout << gen.value() << '\n';
    }
}
```

### `co_return`

实现上基本就是 
```cpp
promise.return_void(); // 或 promise.return_value(<expr>)
// 销毁变量
co_await promise.final_suspend();
```

### 对称转移

考虑一个朴素 协程执行器的实现

```cpp
///////////////////////////////////////////////////////////////////////////
// Example source code for blog post:
// "C++ Coroutines: Understanding Symmetric-Transfer"
//
// Implementation of a naive 'task' coroutine type.

#include <experimental/coroutine>
#include <iostream>

using namespace std::experimental;

class task {
public:
  class promise_type {
  public:
    task get_return_object() noexcept {
      return task{coroutine_handle<promise_type>::from_promise(*this)};
    }

    suspend_always initial_suspend() noexcept {
      return {};
    }

    void return_void() noexcept {}

    void unhandled_exception() noexcept {
      std::terminate();
    }

    struct final_awaiter {
      bool await_ready() noexcept {
        return false;
      }
      void await_suspend(coroutine_handle<promise_type> h) noexcept {
        h.promise().continuation.resume();
      }
      void await_resume() noexcept {}
    };

    final_awaiter final_suspend() noexcept {
      return {};
    }

    coroutine_handle<> continuation;
  };

  task(task&& t) noexcept
  : coro_(std::exchange(t.coro_, {}))
  {}

  ~task() {
    if (coro_)
      coro_.destroy();
  }

  class awaiter {
  public:
    bool await_ready() noexcept {
      return false;
    }

    void await_suspend(coroutine_handle<> continuation) noexcept { // 把 co_await 调用者的 handle 保存到自己 promise 的成员变量中, 然后恢复自己 handle 的执行
      // Store the continuation in the task's promise so that the final_suspend()
      // knows to resume this coroutine when the task completes.
      coro_.promise().continuation = continuation;

      // Then we resume the task's coroutine, which is currently suspended
      // at the initial-suspend-point (ie. at the open curly brace).
      coro_.resume();
    }

    void await_resume() noexcept {}
  private:
    friend task;
    explicit awaiter(coroutine_handle<promise_type> h) noexcept
    : coro_(h)
    {}

    coroutine_handle<promise_type> coro_;
  };

  awaiter operator co_await() && noexcept { // 可以将 task 作为 Awaiter 使用
    return awaiter{coro_};
  }

private:
  explicit task(coroutine_handle<promise_type> h) noexcept
  : coro_(h)
  {}

  coroutine_handle<promise_type> coro_;
};


struct sync_wait_task {
    struct promise_type {
        sync_wait_task get_return_object() noexcept {
            return sync_wait_task{coroutine_handle<promise_type>::from_promise(*this)};
        }

        suspend_never initial_suspend() noexcept { return{}; }
        
        suspend_always final_suspend() noexcept { return{}; }

        void return_void() noexcept {}

        void unhandled_exception() noexcept { std::terminate(); }
    };

    coroutine_handle<promise_type> coro_;

    explicit sync_wait_task(coroutine_handle<promise_type> h) noexcept : coro_(h) {}

    sync_wait_task(sync_wait_task&& t) noexcept : coro_(t.coro_) {
        t.coro_ = {};
    }

    ~sync_wait_task() {
        if (coro_) {
            coro_.destroy();
        }
    }

    static sync_wait_task start(task&& t) {
        co_await std::move(t); // co_await bar 的 task, task::promise_type::await_suspend 执行完成后挂起 start 协程; 返回返回值: 自己的 sync_wait_task
        // 隐式 co_return
        // co_await final_suspend 返回的 suspend_always: 
        // 挂起当前执行; 
        // 执行 std::suspend_always::await_suspend:
            // {}
        // 返回 caller , 这里是 bar 的 co_return 中的 co_await final_suspend 的执行结束处
    }

    bool done() {
        return coro_.done();
    }
};

struct manual_executor {
    struct schedule_op {
        manual_executor& executor_;
        schedule_op* next_ = nullptr;
        coroutine_handle<> continuation_;

        schedule_op(manual_executor& executor)
        : executor_(executor)
        {}

        bool await_ready() noexcept { return false; }

        void await_suspend(coroutine_handle<> continuation) noexcept { // 保存调用者的 handle, 把自己加入链表
            continuation_ = continuation;
            next_ = executor_.head_;
            executor_.head_ = this;
        }

        void await_resume() noexcept {}
    };

    schedule_op* head_ = nullptr;

    schedule_op schedule() noexcept {
        return schedule_op{*this};
    }

    void drain() {
        while (head_ != nullptr) { // 取出链表头, 恢复链表头中保存的 handle 所操作的协程
            auto* item = head_;
            head_ = item->next_;
            item->continuation_.resume();
        }
    }

    void sync_wait(task&& t) {
        auto t2 = sync_wait_task::start(std::move(t)); // sync_wait_task::promise_type::initial_suspend 返回 suspend_never, 所以直接开始执行 sync_wait_task::start, 在下一个挂起点返回 sync_wait_task::task 的返回值 sync_wait_task
        while (!t2.done()) { // 判断 start 协程是否到达 final_suspend; 题外话, 如果 final_suspend  返回的 awaiter 不挂起 (比如 std::suspend_never), 协程会被直接销毁, 对 handle 的调用也就非法了
            drain();
        }
        // t2 的析构销毁 bar 的 handle, 以及对应的帧等资源
    }
};

task foo(manual_executor& ex) {
    std::cout << "inside foo()\n";
    co_await ex.schedule(); // 这里的表达式求值是普通的同步函数; 调用返回值的 await_suspend, 传入 foo 的 handle
    // await_suspend 同步执行完后返回 caller , 这里就是 bar 的 co_await 中的返回 caller 之前的位置
    std::cout << "about to return from foo()\n";
    co_return; // co_await final_suspend 返回的 task::final_awaiter: 
    // 挂起当前执行; 
    // 执行 task::final_awaiter::await_suspend:
        // resume promise 中保存的 handle, 这里是 bar 的 co_await foo(ex) 结束的位置
    // 返回 caller , 这里是 manual_executor::drain
}

task bar(manual_executor& ex) {
    std::cout << "about to call foo()\n";
    co_await foo(ex); // 求值 foo(ex), foo 的返回类型和 bar 一样, 行为也一样, foo 挂起后返回 handle; co_await 这个 handle; 这个 handle 作为临时变量会在语句结束时自动析构
    // await_suspend 同步执行完后返回 caller , 这里就是 sync_wait_task::start 的 co_await 中的返回 caller 之前的位置
    std::cout << "done calling foo()\n";
    // 隐式 co_return
    // co_await final_suspend 返回的 task::final_awaiter: 
    // 挂起当前执行; 
    // 执行 task::final_awaiter::await_suspend:
        // resume promise 中保存的 handle, 这里是 sync_wait_task::start 的 co_await 挂起位置 (co_await 语句结束)
    // 返回 caller , 这里是 foo 的 final_awaiter::await_suspend 中的 h.promise().continuation.resume(); 
}

int main() {
    manual_executor ex;
    ex.sync_wait(bar(ex)); 
    // 求值 bar(ex): bar 的函数体包含协程操作, 被视作协程;
    // 对 bar 的调用被替换 (参考 promise 部分): 首先调用 task::promise_type::initial_suspend, 返回 suspend_always, 所以 bar() 挂起并返回持有 bar handle 的 task (惰性启动)

    // sync_wait 这个 handle
    return 0;
}
```

真是一场酣畅淋漓的赤石啊, 控制权到处乱飞 资源管理心惊肉跳给人一种 goto 领域大神的感觉

{% note warning 栈溢出 %}

我们可以注意到, 在上面的实现中, `await foo()` 执行完成开始销毁的时候, 控制权在 `foo` 和 `bar` 之间来回横跳

考虑下面的执行过程:

```cpp
task completes_synchronously() {
    co_return;
    // co_await task::promise_type::final_awaiter
        // 挂起当前协程
        // task::promise_type::final_awaiter::await_suspend
            // 恢复 promise 中保存的 handle 的执行, 即 loop_synchronously 的 co_await 结束部分
}


task loop_synchronously(int count) {
    std::cout << "loop_synchronously(" << count << ")" << std::endl;
    for (int i = 0; i < count; ++i) {
        co_await completes_synchronously(); 
        // 表达式求值 拿到 task
        // co_await 这个 task: 
            // 挂起当前协程
            // task::awaiter::await_suspend
                // 保存 loop_synchronously 的 handle, resume completes_synchronously 的执行
                
                // 恢复
                // 执行下一个迭代, 当前 co_await 调用中的 task::promise_type::final_awaiter::await_suspend 和 completes_synchronously co_return 调用的 task::promise_type::final_awaiter::await_suspend 栈帧的释放要等到整个 loop_synchronously 的隐式 co_return 了
    }
    std::cout << "loop_synchronously(" << count << ") returning" << std::endl;
}

int main() {
    manual_executor ex;
    ex.sync_wait(loop_synchronously(100));
    ex.sync_wait(loop_synchronously(1000));
    ex.sync_wait(loop_synchronously(100'000));
    ex.sync_wait(loop_synchronously(1'000'000)); // Crashes with stack-overflow!
    return 0;
}
```

{% endnote %}


{% note warning 朴素解法 %}

TODO

要用原子变量, 有额外同步消耗

{% endnote %}

#### 返回 handle

进入正题, 对称转移

允许 `await_suspend` 返回一个 `std::coroutine_handle<>`

`co_await` 流程变为:

```cpp
{
  decltype(auto) value = <expr>;
  decltype(auto) awaitable =
      get_awaitable(promise, static_cast<decltype(value)&&>(value));
  decltype(auto) awaiter =
      get_awaiter(static_cast<decltype(awaitable)&&>(awaitable));
  if (!awaiter.await_ready())
  {
    using handle_t = std::coroutine_handle<P>;

    //<suspend-coroutine>

    auto h = awaiter.await_suspend(handle_t::from_promise(p));
    h.resume(); // 这里不同, 执行权交给 当前协程 awaiter.await_suspend 的返回值, 而非调用者
    //<return-to-caller-or-resumer>

    //<resume-point>
  }

  return awaiter.await_resume();
}
```

总的来说, 如果把 resume 也看做调用, 协程在 await_suspend 执行结束后, co_await 的非对称形式从调用者调用完成的位置继续执行, 对称形式从 await_suspend 返回的 handle 代表的协程的挂起位置继续执行

由于 `<return-to-caller-or-resumer>` 时, 当前的函数调用栈已经被销毁了, 所以 `h.resume()` 就是函数调用中的最后一个操作了, 即 "尾调用"

{% note info 尾调用 %}

尾调用可以复用当前的函数调用栈, 如果:

- 调用约定支持尾调用, 且调用方与被调用方一致: body 部分的 abi 由编译器决定, 编译器可以构造一个一致且支持尾调用的
- 返回类型相同: 都是 void
- 调用之后、返回给调用方之前没有需要运行的非平凡析构函数: 在调用下一个协程的 `resume` 之前, 栈上的对象都析构完了, 协程帧上的不用析构
- 调用不在 try/catch 块内: 如果看 promise 那一节的伪代码可能觉得在 try 内, 但是实际实现时为了规避这个问题把 `h.resume` 挪出去了

所以对于对称转移的协程, 这些条件都满足

{% endnote %}

使用对称转移改造后, 代码如下

```cpp
///////////////////////////////////////////////////////////////////////////
// Example source code for blog post:
// "C++ Coroutines: Understanding Symmetric-Transfer"
//
// Implementation of a naive 'task' coroutine type.

#include <experimental/coroutine>
#include <iostream>

using namespace std::experimental;

class task {
public:
  class promise_type {
  public:
    task get_return_object() noexcept {
      return task{coroutine_handle<promise_type>::from_promise(*this)};
    }

    suspend_always initial_suspend() noexcept {
      return {};
    }

    void return_void() noexcept {}

    void unhandled_exception() noexcept {
      std::terminate();
    }

    struct final_awaiter {
      bool await_ready() noexcept {
        return false;
      }
      coroutine_handle<> await_suspend(coroutine_handle<promise_type> h) noexcept {
        return h.promise().continuation; // 从直接调用 h.promise().continuation.resume(); 改为返回 continuation, 通过 caller 的尾调用恢复 continuation
      }
      void await_resume() noexcept {}
    };

    final_awaiter final_suspend() noexcept {
      return {};
    }

    coroutine_handle<> continuation;
  };

  task(task&& t) noexcept
  : coro_(std::exchange(t.coro_, {}))
  {}

  ~task() {
    if (coro_)
      coro_.destroy();
  }

  class awaiter {
  public:
    bool await_ready() noexcept {
      return false;
    }

    coroutine_handle<> await_suspend(coroutine_handle<> continuation) noexcept {
      // Store the continuation in the task's promise so that the final_suspend()
      // knows to resume this coroutine when the task completes.
      coro_.promise().continuation = continuation;

      // Then we resume the task's coroutine, which is currently suspended
      // at the initial-suspend-point (ie. at the open curly brace).
      return coro_; // 从直接调用 coro_.resume(); 改为返回 coro_, 通过 caller 的尾调用恢复 coro_
      // 直接调用不能释放当前 await_suspend 的栈
    }

    void await_resume() noexcept {}
  private:
    friend task;
    explicit awaiter(coroutine_handle<promise_type> h) noexcept
    : coro_(h)
    {}

    coroutine_handle<promise_type> coro_;
  };

  awaiter operator co_await() && noexcept {
    return awaiter{coro_};
  }

private:
  explicit task(coroutine_handle<promise_type> h) noexcept
  : coro_(h)
  {}

  coroutine_handle<promise_type> coro_;
};


struct sync_wait_task {
    struct promise_type {
        sync_wait_task get_return_object() noexcept {
            return sync_wait_task{coroutine_handle<promise_type>::from_promise(*this)};
        }

        suspend_never initial_suspend() noexcept { return{}; }
        
        suspend_always final_suspend() noexcept { return{}; }

        void return_void() noexcept {}

        void unhandled_exception() noexcept { std::terminate(); }
    };

    coroutine_handle<promise_type> coro_;

    explicit sync_wait_task(coroutine_handle<promise_type> h) noexcept : coro_(h) {}

    sync_wait_task(sync_wait_task&& t) noexcept : coro_(t.coro_) {
        t.coro_ = {};
    }

    ~sync_wait_task() {
        if (coro_) {
            coro_.destroy();
        }
    }

    static sync_wait_task start(task&& t) {
        co_await std::move(t);
    }

    bool done() {
        return coro_.done();
    }
};

struct manual_executor {
    struct schedule_op {
        manual_executor& executor_;
        schedule_op* next_ = nullptr;
        coroutine_handle<> continuation_;

        schedule_op(manual_executor& executor)
        : executor_(executor)
        {}

        bool await_ready() noexcept { return false; }

        void await_suspend(coroutine_handle<> continuation) noexcept {
            continuation_ = continuation;
            next_ = executor_.head_;
            executor_.head_ = this;
        }

        void await_resume() noexcept {}
    };

    schedule_op* head_ = nullptr;

    schedule_op schedule() noexcept {
        return schedule_op{*this};
    }

    void drain() {
        while (head_ != nullptr) {
            auto* item = head_;
            head_ = item->next_;
            item->continuation_.resume();
        }
    }

    void sync_wait(task&& t) {
        auto t2 = sync_wait_task::start(std::move(t));
        while (!t2.done()) {
            drain();
        }
    }
};

task completes_synchronously() {
    co_return;
}


task loop_synchronously(int count) {
    std::cout << "loop_synchronously(" << count << ")" << std::endl;
    for (int i = 0; i < count; ++i) {
        co_await completes_synchronously();
    }
    std::cout << "loop_synchronously(" << count << ") returning" << std::endl;
}

int main() {
    manual_executor ex;
    ex.sync_wait(loop_synchronously(100));
    ex.sync_wait(loop_synchronously(1000));
    ex.sync_wait(loop_synchronously(100'000));
    ex.sync_wait(loop_synchronously(1'000'000)); // Crashes with stack-overflow!
    return 0;
}
```

调用过程中的栈帧图可以[参考](https://lewissbaker.github.io/2020/05/11/understanding_symmetric_transfer#task-revisited)

{% note info 对称转移可以实现非对称转移 %}

显然, 从定义来看, 转移给任意协程包括转移给调用者

只需要 `await_suspend` 返回 `std::noop_coroutine()` (通常的实现就是只包含 ret) 就行了

#### 例 1

- 返回 void 的形式

```cpp
void my_awaiter::await_suspend(std::coroutine_handle<> h) {
  this->coro = h;
  enqueue(this);
}
```

- 返回 bool 的形式

```cpp
bool my_awaiter::await_suspend(std::coroutine_handle<> h) {
  this->coro = h;
  enqueue(this);
  return true;
}
```

- 对称转移形式

```cpp
std::noop_coroutine_handle my_awaiter::await_suspend(
    std::coroutine_handle<> h) {
  this->coro = h;
  enqueue(this);
  return std::noop_coroutine();
}
```

#### 例 2

- 返回 bool 的形式

```cpp
bool my_awaiter::await_suspend(std::coroutine_handle<> h) {
  this->coro = h;
  if (try_start(this)) {
    // 操作将异步完成。
    // 返回 true，把执行转移给 coroutine_handle::resume()
    // 的调用方。
    return true;
  }

  // 操作同步完成。
  // 返回 false，立即恢复当前协程。
  return false;
}
```

- 对称转移形式

```cpp
std::coroutine_handle<> my_awaiter::await_suspend(std::coroutine_handle<> h) {
  this->coro = h;
  if (try_start(this)) {
    // 操作将异步完成。
    // 返回 std::noop_coroutine()，把执行转移给
    // coroutine_handle::resume() 的调用方。
    return std::noop_coroutine();
  }

  // 操作同步完成。
  // 返回当前协程的句柄，立即恢复当前协程。
  return h;
}
```

{% endnote %}

### 编译器转换

TODO

### 最佳实践?

总的来说, C++ 是自由的

可惜程序员不是, 所以找点最佳实践洗洗眼睛

TODO

## python

无栈, 非对称转移

不能自定义协程返回 handle 的是不是基本都是非对称的

`async def` 返回 handle, 可以对 handle 进行:

- `asyncio.run(handle)`: 有点类似 cuda 里的 `__global__`, 用来作为桥梁在普通函数中启动协程
- `await`: 只能在 `async def` 的函数中执行; 挂起当前协程, 等待 `await` 的协程结束后继续执行

```python
import asyncio
import time

async def say_after(delay, what):
    await asyncio.sleep(delay) # 控制权交给调度器, sleep 的过程中调度器可以执行其他任务, 定时器到期后调度器再 resume 到语句结束时
    print(what)

async def main():
    print(f"started at {time.strftime('%X')}")

    await say_after(1, 'hello')
    await say_after(2, 'world') # 这里不会自动并发执行

    print(f"finished at {time.strftime('%X')}")

asyncio.run(main())
```

```python
async def main():
    task1 = asyncio.create_task( # 这里实际已经可能开始执行了
        say_after(1, 'hello'))

    task2 = asyncio.create_task(
        say_after(2, 'world'))

    print(f"started at {time.strftime('%X')}")

    # 等待直到两个任务都完成
    # （会花费约 2 秒钟。）
    await task1 # 这里只是等待结束
    await task2

    print(f"finished at {time.strftime('%X')}")
```

python 还能 await 一个 future, 类似 `future.get` 的异步版本

### loop

TODO

## bthread

有栈, 非对称转移

虽然日常说法都把 bthread 当做协程

但是 bthread [第一个 faq](https://brpc.apache.org/docs/bthread/bthread/#qbthread%E6%98%AF%E5%8D%8F%E7%A8%8Bcoroutine%E5%90%97) 就说他不是协程

为什么?

- bthread 定义的协程似乎是每个线程上有一个任务队列, 一个任务分配到一个线程就只能在这个线程执行了, 这个线程可以切换在这个线程上的任务? 可能是定义年代问题吧, 不然 cpp 的 coroutine 恐怕都不算协程了
- bthread 有调度器? 但是似乎日常也把 goroutine 看做协程?

注意其中所谓的 "一个bthread被卡住不会影响其他bthread" 只能说不会卡死所有 bthread, 执行效率依然下降了 (少了一个 worker)

操作: 

- `bthread_start_background`: 在后台启动新 bthread
- `bthread_start_urgent`: 挂起当前 bthread, 后台启动新 bthread 并立刻执行这个新 bthread
- `bthread_yield()`: 挂起
- `return `: 销毁
- bthread 提供的非阻塞操作: `bthread_usleep`, `bthread_cond_wait` ...

bthread 操作的一个好处在于可以在 bthread 上进行也可以在 pthread 上进行, bthread 上表现为非阻塞操作 (对 worker 来说), pthread 上表现为阻塞操作

注意虽然 bthread 只在这些非阻塞函数上表现为协程 (可以挂起), 但这个挂起可以让上层的非协程函数也跟着挂起 (表现为有栈); 对比 cpp20 的协程如果想让上层跟着挂起, 上层必须是个协程 (包含 `co_await`)

bthread 的函数调用栈类似于多线程时不同线程的栈, 挂起时的寄存器用汇编压到 bthread 自己的栈上, 恢复时再用汇编弹回寄存器上

注意到 bthread 的启动方式导致 bthread 的函数调用栈和创建者的函数调用栈没有关系

## Boost.Context

### fiber

有栈, 对称转移

```cpp
// main()

namespace ctx=boost::context;
int a;
ctx::fiber source{[&a](ctx::fiber&& sink){ // sink 由 context 库自动传入
    a=0;
    int b=1;
    for(;;){
        sink=std::move(sink).resume(); // resume 继续 fiber, 消耗旧的 (只能是右值) 句柄, 返回新的句柄
        // 虽然这里是非对称的返回了 caller, 但是不难发现如果能传进来一个 fiber, 想调谁调谁
        int next=a+b;
        a=b;
        b=next;
    }
    return std::move(sink); // 这里和普通函数一样不可达
}};
for (int j=0;j<10;++j) {
    source=std::move(source).resume(); // 有点类似 bthread_start_background, source 的栈不在 main 之上; 只不过没有调度器, 是保存上下文后立刻启动的
    // 寄存器之类的东西还是保存在栈上, 具体手段看平台
    std::cout << a << " ";
}

/*
output:
    0 1 1 2 3 5 8 13 21 34
*/
```

#### 参数

参数只能通过捕获, 全局变量, `std::bind` 传递; 有点麻烦

```cpp
ctx::fiber generate(int& a, ctx::fiber&& sink) { // 不能作为 fiber 直接调用
    a = 0;
    int b = 1;

    for (;;) {
        sink = std::move(sink).resume();
        int next = a + b;
        a = b;
        b = next;
    }

    return std::move(sink);
}
```

`ctx::fibre` 的构造函数只接受签名为 `fiber(fiber && f)` 的 callable

所以要包装一层:

```cpp
int a;

ctx::fiber source{
    std::bind(generate, std::ref(a), std::placeholders::_1)
};
```

#### 注入

`resume_with` 可以在对方的栈上执行代码, 挺有意思的

```cpp
namespace ctx=boost::context;
int data=0;
ctx::fiber f1{[&data](ctx::fiber&& f2) {
    std::cout << "f1: entered first time: " << data << std::endl;
    data+=1;
    f2=std::move(f2).resume();
    std::cout << "f1: entered second time: " << data << std::endl;
    data+=1;
    f2=std::move(f2).resume();
    std::cout << "f1: entered third time: " << data << std::endl;
    return std::move(f2);
}};
f1=std::move(f1).resume();
std::cout << "f1: returned first time: " << data << std::endl;
data+=1;
f1=std::move(f1).resume();
std::cout << "f1: returned second time: " << data << std::endl;
data+=1;
f1=std::move(f1).resume_with([&data](ctx::fiber&& f2){ // 这里的 f2 是调用者, 由 context 库传入
    std::cout << "f2: entered: " << data << std::endl;
    data=-1;
    return std::move(f2); // 这里的返回值会作 resume_with 的对象 (f1) 的参数 (首次调用时) 或者 上次挂起时的 std::move(f2).resume(); 的返回值
});
std::cout << "f1: returned third time" << std::endl;

/*
output:
    f1: entered first time: 0
    f1: returned first time: 1
    f1: entered second time: 2
    f1: returned second time: 3
    f2: entered: 4
    f1: entered third time: -1
    f1: returned third time
*/
```

在谁的栈上执行有区别吗?

比较简单的例子就是异常处理:

```cpp
namespace ctx=boost::context;
struct my_exception : public std::runtime_error {
    ctx::fiber    f;
    my_exception(ctx::fiber&& f_,std::string const& what) :
        std::runtime_error{ what },
        f{ std::move(f_) } {
    }
};

ctx::fiber f{[](ctx::fiber && f) ->ctx::fiber {
    std::cout << "entered" << std::endl;
    try {
        f=std::move(f).resume();
    } catch (my_exception & ex) {
        std::cerr << "my_exception: " << ex.what() << std::endl;
        return std::move(ex.f);
    }
    return {};
});
f=std::move(f).resume();
f=std::move(f).resume_with([](ctx::fiber && f) ->ctx::fiber {
    throw my_exception(std::move(f),"abc");
    return {};
});

/*
output:
    entered
    my_exception: abc
*/
```

### callcc & continuation


```cpp
namespace ctx=boost::context;
int a;
ctx::continuation source=ctx::callcc(
    [&a](ctx::continuation && sink){
        a=0;
        int b=1;
        for(;;){
            sink=sink.resume();
            int next=a+b;
            a=b;
            b=next;
        }
        return std::move(sink);
    });
for (int j=0;j<10;++j) {
    std::cout << a << " ";
    source=source.resume();
}

/*
output:
    0 1 1 2 3 5 8 13 21 34
*/
```

## Boost.Coroutine

有栈, 

## Boost.Coroutine2

有栈, 非对称转移

## goroutine

有栈, 非对称转移

goroutine 的栈可以动态扩缩容, 不像多线程 / bthread 的栈, 超大小了就栈溢出了

- M 可以看做 pthread, 只负责执行
- P 看做调度单位, 有任务队列等, 最多绑定一个 M
- G 就是 task, 一个 Goroutine

M 数量一般大于 P, 多出来的 M 用来:

M 阻塞时可以解绑其上的 P, 绑定到空闲的其他 M 上, 避免阻塞整个 P 队列中的其他任务; 阻塞的任务完成后就像新加入一个任务一样分配到一个 P 上

这样可以利用原先的阻塞 api, 很简单, 很爽

(也有非阻塞的操作比如等 channel 之类的可以主动让出 P)

需要额外开销, 但是感觉对于有 runtime 的语言来说, 应该就是最优解了

## typescript

无栈, 非对称转移

