---
title: Linux 多线程 Fork
categories: 翻车笔记
tags:
  - Linux
  - 多线程
date: 2026-11-25 19:27:04
---

最近又遇到了, 趁这个机会理清楚一点

<!--more-->

linux 的线程本质是个小进程, 只不过虚拟内存 (和文件之类的其他资源) 指针是同一个; 这个设计还导致过用 tgid 打补丁避免 kill 不干净的问题 (理论上 tgid 能 kill 掉进程的线程就应该能复制进程的线程?)

在 fork 时, 复制了虚拟内存, 因此所有线程的栈都会复制

- cow 的情况就是:
    - 复制 mm_struct 和他拥有的所有 vma
    - 更改所有可写 vma 对应页表项的 writable 标志位至只读
    - copy 后的页表项改为可写, 原来的仍然是只读 (可能 fork 了多个子进程, 类似引用计数)

但是一个线程:
- 能被执行需要: 创建他的 `task_struct` 并放到一个 cpu 的任务队列 (running queue: struct rq) 里
    - 这个任务队列有空闲时 pull 任务, 太忙时 push 任务到其他核 的功能
    - 考虑内存亲和会尽量让这种 task 的移动在 NUMA 节点内
    - 还有一些 CPU 核的亲和性
- 能被遍历和 pid 查找到需要: 放在内核的全局 task 链表里

fork 不会自动为其他线程做这些

所以在子进程中, 只有运行 fork 的线程有可能被调度, 其他线程都泄露了

如果后续依赖一个 当前已经上锁, 其他线程负责 `unlock` 的锁: 由于内存完全复制, 所以锁是锁上的状态; 其他线程不会再执行, 没人负责给他解锁了; 就会死锁

所以 fork 只应该尽可能立刻跟上 execve

- 有一些解决方法有点邪门, 比如用一些 fork 过程中的回调做一些操作, 有点 trick, 不写了

--- 

参考: 

- [deadlock-with-logging-multiprocess-multithread-python](https://haoluobo.com/2021/03/deadlock-with-logging-multiprocess-multithread-python/)
- [grpc1](https://github.com/grpc/grpc/blob/master/doc/fork_support.md)
- [grpc2](https://chromium.googlesource.com/external/github.com/grpc/grpc/+/HEAD/examples/python/multiprocessing/)
- [python](https://docs.python.org/zh-cn/3.15/library/multiprocessing.html)
