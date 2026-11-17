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


## 协程

### 有栈协程

### 无栈协程
