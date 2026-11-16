---
title: Agent 入门
categories: 学习笔记
tags:
  - LLM
  - Agent
mathjax: true
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
