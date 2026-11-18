---
title: 现代 C++ 并发
categories: 学习笔记
tags:
  - C++
  - 并发
mathjax: true
abbrlink: 41633
date: 2026-11-17 19:16:15
---

写点高级并发

<!--more-->

## 协程

协程本身不是并发的, worker 对协程的执行是并发的

(当然按这个说法 `std::thread` 本身也不是并发的, 是 CPU 核对线程的执行是并发的)

> 协程是一种能够暂停执行的函数：通过 `suspend` 操作暂停后，可以在稍后的某个时刻通过 `resume` 操作继续执行

- 按**控制转移机制**来区分, 分为对称协程和非对称协程
- 按是否能够在**嵌套调用内部**暂停执行 来区分, 分为有栈协程和无栈协程

### 无栈协程 (状态机)

提供三个操作:

- `create`: 创建, 但不执行
- `resume`: 开始执行(转移)
- `yield`: 到达下一个状态, 暂停执行

需要把所有跨越状态使用的变量额外保存在堆上, 实现类似于:

(注意无栈协程的暂停点是编译期确定的)

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

### 有栈协程

和线程类似, 保存着当前的调用栈 (不管是协程的, 还是协程调用的非协程函数的, 更可能需要编译器开洞), 协程暂停时还需要保存寄存器之类的; 一般是放在堆上


### 对称协程

可以将控制权交给任意协程

### 非对称协程

只能将控制权交给调用者

### 常见实现

#### goroutine

#### bthread

#### python

#### cpp20:

哎我靠 cpp 怎么这么自由

除了内部的状态, 协程还需要: 

- promise 类 (不是 `std::promise`)
- handle 类 (继承 `coroutine_handle<yourPromise>`): 可以让我们操作协程

大概会长这样:

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
    void destroy(); // 销毁

    void* address() const;
    static coroutine_handle from_address(void* address); // 中 promise 中找回 handle: 同一个协程的 promise 和 handle 在同一个协程帧中, 地址偏移是确定的
  };

  template<typename Promise>
  struct coroutine_handle : coroutine_handle<void>
  {
    Promise& promise() const;
    static coroutine_handle from_promise(Promise& promise); // 注意必须确保 promise 类型与协程帧所使用的具体 promise 类型完全一致；如果具体 promise 类型是 Derived，尝试构造 coroutine_handle<Base> 可能导致未定义行为。

    static coroutine_handle from_address(void* address);
  };
}
```

操作: 

- `co_await`: 一个一元运算符, 可以作用在一个 `Awaitable` 上, 代表挂起直到异步操作 `Awaitable` 完成
    - `Awaitable`: 能被 `co_await` 调用的类型 (可能通过 `operator co_await()` 返回另一个 `Awaiter`, 所以不一定是一个 `Awaiter`)
    - `Awaiter`: 实现下列接口的类型 (`Awaiter` 一定是一个 `Awaitable`): 这些接口允许程序员做一些自定义操作
        - `await_ready()`: 判断是否需要挂起时调用的回调函数, 避免下面 `<suspend-coroutine>` 操作的开销
        - `await_suspend(std::coroutine_handle<>)`: 挂起时调用的回调函数, 可以返回 `bool` 或 `void`; 一般用来启动异步操作, 且负责在异步操作结束后恢复协程, 比如注册回调函数调用 handle 的 resume, 或者把 handle 扔给调度器
            - 返回 `bool`: `true` 代表真的挂起, 否则继续执行 `co_await` 后面的代码; 避免 `await_ready` 到 `await_suspend` 之间的部分状态发生了变化
            - 返回 `void`: 一定挂起
        - `await_resume()`: 恢复时调用的回调函数, 其返回值就是整个 `co_await` 的返回值; 如果抛出异常就从 `co_await` 传播出去, 这种情况下协程会被自动恢复, 且这个恢复不会再调用 `await_resume()`

    - `co_await <expr>` 流程如下:
        1. 获取 Awaitable: 如果协程的 promise 有 `await_transform` 方法, 就通过 `promise.await_transform(<expr>)` 获取; 否则把 `<expr>` 本身作为 Awaitable
        2. 获取 Awaiter: 如果 Awaitable 有 `operator co_await()` 方法, 就用这个获取 Awaiter; 否则把 Awaitable 作为 Awaiter
        3. 挂起

```cpp
{
  auto&& value = /*<expr>*/;
  auto&& awaitable = get_awaitable(promise, static_cast<decltype(value)>(value));
  auto&& awaiter = get_awaiter(static_cast<decltype(awaitable)>(awaitable));
  if (!awaiter.await_ready()) // 异步操作是否已完成, 是否不需要挂起
  {
    using handle_t = std::experimental::coroutine_handle<P>;

    using await_suspend_result_t =
      decltype(awaiter.await_suspend(handle_t::from_promise(promise)));

    // <suspend-coroutine>
    // 这里编译器会生成代码来保存协程当前状态并为其恢复做好准备，包括存储 <resume-point> 的位置，以及把当前寄存器中持有的值溢出写入协程帧内存。

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

    // <resume-point>
  }

  return awaiter.await_resume();
}
```

- `co_yield`:
- `co_return`: 

#### boost coroutine

## 同步手段

### 条件变量

其实机制和 mutex 差不多, 这个的想法是很自然的

考虑一个朴素的生产消费: 

```cpp
std::mutex m;
std::queue<int> q;

// Producer
void producer() {
    {
        std::lock_guard lk(m);
        q.push(1);
    }
}

// Consumer
void consumer() {
    while (true) {
        std::unique_lock lk(m);

        if (!q.empty()) {
            int x = q.front();
            q.pop();
            lk.unlock();

            consume(x);
        }
    }
}
```

当没在生产的时候, 获取 mutex 不会被阻塞, 所以即使不满足条件也会不断获取 mutex 然后判断 pred, 造成浪费

引入唤醒机制

- `wait( std::unique_lock<std::mutex>& lock, Predicate pred )`: 线程进入阻塞态; 直到 `notify` 唤醒, 从阻塞变为就绪, 检查 `pred`, 不满足就再进入阻塞态
    - `lock`: 保护共享数据; 避免错过 `notify`
    - `pred`: 避免虚假唤醒

```cpp
std::unique_lock lock(m);
cv.wait(lock, []{ return ready; });
```

约等于

```cpp
while (!pred()) {
    // pred = true; notify();
    lock.unlock(); // 如果没有 lock, notify 可能发生在 pred 不满足之后, 进入阻塞之前, 导致错过通知
    // 阻塞, 这里保证进入阻塞和 unlock 是原子的

    // 就绪
    lock.lock(); // 被唤醒后重新获取 mutex
}
```

- `notify`: 对共享数据处理的过程中要加锁:
    - 为了消费者对共享数据的可见性, 这里可以参考[内存序](https://cansult.github.io/posts/20346.html)
    - 避免错过 `notify`

所以哪怕共享数据是原子的, 也需要加锁

```cpp
{
    std::lock_guard lock(m);
    ready = true;
}
cv.notify_one();
```

#### futex

Fast Userspace Mutex, 尽量 (没有竞争时) 不进入内核态

```cpp
void lock() {
    if (CAS(&state, 0, 1)) {
        return;
    }

    // 慢速路径：发生竞争，进入 futex 等待
    futex_wait(...);
}
```

### atomic::wait

`-std=c++20`

C++20 提供了可以把原子变量的类似条件变量的操作, 挺有意思的

```cpp
std::atomic<bool> ready{false};

void consumer() {
    ready.wait(false);
    // ready 已经变成 true
}

void producer() {
    ready.store(true);
    ready.notify_one();
}
```

复杂场景可能还是得用条件变量

### `promise` & `future`

可以看做某种一次性条件变量 + 内容传递

`promise` 和 `future` 共同指向要传递的值的地址, 类似引用计数; 

`get` 转移所有权并减少引用计数 (所以 get 后 future 就无效了), promise 析构时减少引用计数

`wait_for/wait_until` 在 `ready` 之前会返回 `deferred` (任务还未开始执行, 比如 `std::launch::deferred` 参数的 `std::async`) 或 `timeout` (超时)

`shared_future` 可以让多个线程等待同一个 promise, 他的 get 不会转移所有权, 返回的是 `const &`

#### `packaged_task`

用来包装一个 callable, 使其可以纳入 `future` 的体系中去

```cpp
#include <future>
#include <iostream>
#include <thread>

int main()
{
    // 来自 packaged_task 的 future
    std::packaged_task<int()> task([](){ return 7; }); // 包装函数
    std::future<int> f1 = task.get_future();  // 获取 future
    std::thread t(std::move(task)); // 在线程上运行

    // 来自 async() 的 future
    std::future<int> f2 = std::async(std::launch::async, [](){ return 8; });

    // 来自 promise 的 future
    std::promise<int> p;
    std::future<int> f3 = p.get_future();
    std::thread([&p]{ p.set_value_at_thread_exit(9); }).detach();

    std::cout << "等待..." << std::flush;
    f1.wait();
    f2.wait();
    f3.wait();
    std::cout << "完成!\n结果为: "
              << f1.get() << ' ' << f2.get() << ' ' << f3.get() << '\n';
    t.join();
}
```

```cpp
#include <future>
#include <iostream>
#include <thread>

int main()
{
    std::promise<int> p;
    std::future<int> f = p.get_future();

    std::thread t([&p]
    {
        try
        {
            // 可能抛出异常的代码
            throw std::runtime_error("Example");
        }
        catch (...)
        {
            try
            {
                // 存储 promise 中抛出的任何异常
                p.set_exception(std::current_exception());
            }
            catch (...) {} // set_exception() 也可能抛出异常
        }
    });

    try
    {
        std::cout << f.get();
    }
    catch (const std::exception& e)
    {
        std::cout << "来自线程的异常: " << e.what() << '\n';
    }
    t.join();
}
```

### `latch` & `barrier`

`-std=c++20`

- `latch`: 感觉就像一个加了限制的原子变量, 初始是任务数, 每个任务完成后减一, `wait` 直到 0; 有点像 go 的 `sync.WaitGroup`
- `barrier`: 功能更强大, 划分了阶段, 阶段结束后还能执行回调; 当前是哪个 phase 保存在 `barrier` 实例中
    - `arrive`: 调用者报告完成了当前 phase, 返回一个 `arrival_token`; 当前 phase 的待完成数 `-= 1`
    - `wait(arrival_token&&)`: 让调用者阻塞, 直到当前 phase 的所有预期 worker 都 arrive
    - `arrive_and_wait`: 等价于 `wait(arrive())`
    - `arrive_and_drop`: 调用者报告完成了当前 phase, 且以后的所有 phase 减少一个需要同步的 worker (有趣的是, `arrive` 可以报告多次完成当前 phase, 而 `arrive_and_xxx` 只能报告一次)
    - 阶段结束的回调函数在 phase 未完成计数为 0 时, 下一次 `arrive/wait` 调用时执行; 最后一次回调是否执行取决于实现 (... 男人什么罐头我说)
