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

这个问题好像有点太哲学了

## 古典时代

- Rational Agent: 最大化得分的期望
- BDI: 划分 Belief, Desire (`/goal`?), Intention
- POMDP: Agent 观测到的不一定是真实的环境, 在马尔可夫决策过程的基础上增加 belief state 的维护

## 现代

- CoALA: 记忆、动作、决策; 有点像 BDI?
- Deliberative/Reactive: 开不开 plan?
- ReAct: 推理行动交替

算了还是直接用

> - Workflows are systems where LLMs and tools are orchestrated through predefined code paths.
> - Agents, on the other hand, are systems where LLMs dynamically direct their own processes and tool usage, maintaining control over how they accomplish tasks.

从产品来看 agent 就是给个 `/goal` 就能完成任务; 现在还需要和人多轮交互还是模型水平问题 (goal 不够明确算不算模型水平问题呢, 或许以后能足够强了不需要人传达任务了?)

从实现来看就是个维护上下文的 `while (!done): context = curl chat/completion context;`; 模型、人、工具都可以改上下文, 直到最终有个特殊上下文表示任务完成了

# 常见实现

## dsh

### context

结构如下:

- session: 完整会话, 所有要发给模型的部分
- turn: 两次用户交互 (比如发送一条消息) 之间的部分
- step: 两次模型调用之间的部分

#### compact

- pruneContent: 直接删过长的 `tool_result` 内容, 只保留首位 
- Autocompact: 到阈值后的自动 `/compact`; 近期的内容会原样保留, 避免拆散 `tool_call` 和 `tool_result`

### tool



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

## claude code

致敬 26H1 最佳开源软件 (

### context

- session: 似乎一个 cc 进程一个时刻只能有一个活跃的 session, 他的 message[] 被放在内存里; 不活跃的 session 在 .cluade 的 .jsonl 里
- message: 一个 role 的一条消息
- content: 实际信息, 可以有多种类型 (图片 / 文本 / `tool_use` / ...)

#### compact

- Microcompact: 清理工具调用结果

```typescript
// 压缩前
tool_result {
  tool_use_id: "read_123",
  content: "...long text..."
}

// 压缩后
tool_result {
  tool_use_id: "read_123",
  content: "[Old tool result content cleared]"
}
```

- History Snip: 直接删某几条 message, 模型通过 message id 判断哪些不需要了
- Context Collapse: 局部摘要, 模型判断哪些 message 需要压缩, 压成一个 message 替换他们
- Autocompact: 到阈值后的自动 `/compact`
