---
title: Agent 入门 [WIP]
categories: 学习笔记
tags:
  - LLM
  - Agent
mathjax: true
abbrlink: 3471
date: 2026-11-10 19:16:15
---

You are a helpful agent.

<!--more-->

# 什么是 Agent

这个问题太哲学了, 而且不知道是不是因为缺乏标准, 这帮人也是真能水论文; 我尽量写一些关键里程碑, 他们提出的定义真的能提高 Agent 性能

## 古典时代

有点纸上谈兵

- Rational Agent: 最大化得分的期望
- BDI: 划分 Belief, Desire (`/goal`?), Intention
- POMDP: Agent 观测到的不一定是真实的环境, 在马尔可夫决策过程的基础上增加 belief state 的维护

## 现代

- CoALA: 记忆、动作、决策; 有点像 BDI?
- Deliberative/Reactive: 开不开 plan?
- ReAct: 推理行动交替

算了直接用

> - Workflows are systems where LLMs and tools are orchestrated through predefined code paths.
> - Agents, on the other hand, are systems where LLMs dynamically direct their own processes and tool usage, maintaining control over how they accomplish tasks.

# 常见实现

## dsh

### session

结构如下:

- session: 完整会话, 所有要发给模型的部分
    - turn: 两次用户交互 (比如发送一条消息) 之间的部分
    - step: 两次模型调用之间的部分

### cordis

```typescript
import type { Context } from '@deepseek-ai/cordis'

export const name = 'lifecycle-demo'

function heartbeat(ctx: Context) { // 插件的函数体在 ctx.plugin 中注册, 但不是立即同步执行, 而且可能需要等条件满足之类的 
  console.log('heartbeat plugin loading')
  ctx.effect(() => { // 传入 ctx.effect 中的 callback 会被立即同步执行
    const timer = setInterval(() => console.log('tick'), 200)
    return () => {
      clearInterval(timer)
      console.log('heartbeat cleaned up')
    } // 这里返回的 disposer 被注册给框架, 可以通过框架返回的 fiber 调用
  })
}

export function apply(ctx: Context) {
  // Mount a child plugin and keep its fiber to dispose it later.
  const fiber = ctx.plugin(heartbeat) // ctx.plugin 将函数作为插件处理; 如果传入的是 Service 就是调 new construtor 之类的
  // The demo timer is itself an effect: if THIS plugin is unloaded first,
  // the pending callback is cancelled instead of firing on a dead app.
  ctx.effect(() => {
    const timer = setTimeout(async () => {
      await fiber.dispose()
      console.log('disposed')
      process.exit(0)
    }, 700)
    return () => clearTimeout(timer)
  })
}
```

#### 触发器

```typescript
// stats.ts
import { Service, type Context } from '@deepseek-ai/cordis'

declare module '@deepseek-ai/cordis' {
  interface Context {
    stats: StatsService
  }
  interface Events {
    'stats/report'(name: string, count: number): void
  }
}

export class StatsService extends Service {
  private counts = new Map<string, number>()

  constructor(ctx: Context) {
    super(ctx, 'stats')
  }

  bump(name: string) {
    const next = (this.counts.get(name) ?? 0) + 1
    this.counts.set(name, next)
    this.ctx.emit('stats/report', name, next) // 触发监听器: key 和 回调的参数
  }
}

export const name = 'stats'

export function apply(ctx: Context) {
  ctx.plugin(StatsService)
}
```

```typescript
// reporter.ts
import type { Context } from '@deepseek-ai/cordis'
import type {} from './stats.ts'

export const name = 'reporter'
export const inject = ['stats']

export function apply(ctx: Context) {
  ctx.on('stats/report', (name, count) => { // 注册监听器: 字符串可以看做是监听的 key; 回调
    console.log(`[stats] ${name} -> ${count}`)
  })
  ctx.stats.bump('tool_call')
  ctx.stats.bump('tool_call')
  ctx.stats.bump('prompt')
}
```

