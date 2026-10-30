---
title: Transformer 入门
categories: 学习笔记
tags:
  - LLM
  - Transformer
abbrlink: 17401
date: 2026-06-30 19:27:04
mathjax: true
---

学变形金刚, 写点总结

<!--more-->

### flash attention

先定义下常用变量

$$
\begin{flalign*}
Q_{N \times d} &= X_{N \times d_{token}}W_{d_{token} \times d} && \\\\
O_{N \times d} &= \mathrm{attn} = \mathrm{softmax}(\frac{QK^T}{\sqrt{d}})V && \\\\
S_{N \times N} &= \frac{QK^T}{\sqrt{d}} && \\\\
P_{N \times N} &= \mathrm{softmax}(S) && \\\\
m_{N \times 1} &= \mathrm{rowmax}(S) && \\\\
l_{N \times 1} &= \mathrm{rowsum}(\exp(S - m)) && \\\\
O_{N \times d} &= PV && \\\\
\end{flalign*}
$$

`safe_softmax(X)[i] = expf(X[i] - max(X)) / sum( expf( X[i] - max(X) ) )`

$N$ 通常很大, 考虑分 Tile

$Q, O$ 分 $T_r = \frac{N}{B_r}$ 片, $Q_i, O_i: B_r \times d$

$K, V$ 分 $T_c = \frac{N}{B_c}$ 片, $K_i, V_i: B_c \times d$

$m, l$ 分 $T_r$ 片, $m_i, l_i: B_r \times 1$

#### V1

考虑要得到 $O_{i, j}$ 的话, 需要 $P_{i, :} \cdot V_{:, j}$

而 $P_{i, :}$ 需要 

$$
\frac{\exp(\frac{1}{\sqrt{d}} \times Q_{i, :} \times K^T  - m_i)}{l_i}
$$

$K_{N \times d}$ 按 $N$ 方向分片后, $K^T$ 被分成了横向的几块, 每一列是被完整保存的

```
          K^T
     ┌────┬────┬────┬─────┐
     │    │    │    │     │
     │  1 │  2 │ .. │ T_c │
     │    │    │    │     │
     └────┴────┴────┴─────┘
```

$Q_{N\times d} \times K^T_i$ 是最终 $Q \times K^T$ 的一部分, 在经过**全局** softmax 处理后, 这部分 乘上 $V_i$ 就是 $O_{N\times d}$ 的一部分贡献

(当然每次循环的时候我们是没有全局 softmax 的, 所以需要 online softmax 的技术去算贡献)

要求最终值只需要把不同 $K V$ 块得出的 $O$ 加起来即可

```
for each K/V block:
    load K[j],V[j]

    for each Q block:
        load Q[i], O[i], l[i], m[i] // 这里读取 l 和 m, 将来 K^T 向右遍历的时候需要更新他们
        compute
        store O, l, m
```

$Q$ 和 $O$ 也太大, 需要分块, 所以内层是 $Q$ 和 $O$ 用同一个坐标和块数; 实际上将整个内层循环看成一个整体, 我们可以当他是一个完整的 $Q$ 和 $O$

#### V2

我们发现 K V Tile 的每次迭代, 要读一遍 Q O l m, 写一遍 O l m, 内存内存太贵了, 考虑怎么优化

K V 是只读的, 不需写入, 交换 K V 循环到里层的话, 访问 K V 的次数变多了, 但是写入 O l m 的次数少了

```
for each Q block:
    load Q
    init O, l, m

    for each KV block:
        load K,V
        update O, l, m

    store O
```

##### split K -> split Q

V1 对 K 的行做并行, 每个 warp 只能拿到一部分贡献, 还需要 shared mem 做最终计算

Q 的行间是独立的, 改为对 Q 的行做并行, 每个 warp 都能拿到最终数据, 可以避免 shared mem 的消耗

#### V3

Hopper 增加了 TMA 和 Tensor Core, 和 Cuda Core 可以并行运行

因此改为 producer warp 加载到 Tensor Core 需要的地方, consumer warp 直接获取 Tensor 的矩阵计算结果




[参考](https://zhuanlan.zhihu.com/p/2068355332049522938)


### radix attention 


