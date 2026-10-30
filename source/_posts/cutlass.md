---
title: cutlass 入门
categories: 学习笔记
tags:
  - C++
  - cutlass
abbrlink: 20643
date: 2026-09-11 19:16:15
mathjax: true
---

学下 cutlass, 写点总结

<!--more-->

## swizzle 

为减少 (主要是 mma ldmatrix 的) bank conflict, 需要对 shape stride offset 后得到的标量一维地址进行 swizzle, 记作 Swizzle o Offset o Layout

(mma 只能小矩阵的乘法, 导致多个线程加载一个小部分的内存, 在行主序的情况下更容易导致 bank conflict, 可以参考[文章](https://zhuanlan.zhihu.com/p/27381896431))

### 具体过程

`swizzle<B, M, S>`

- B: Base \/ `num_bits`: 参与亦或的位的长度 `(len(z) == len(y))`
- M: Mask \/ `num_base`: 保持不变的末尾长度, 可以看做变换中的单位长度
- S: Shift \/ `num_shift`: 参与亦或的两段 bit 的距离

贴下 cutlass 中的原注释

```
 INPUT:
 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
  x  w  v  u  t  s  r  q  p  o  n  m  l Y3 Y2 Y1 Y0  k  j  i  h  g  f  e Z3 Z2 Z1 Z0  d  c  b  a
                                         ^        ^                       ^        ^
                          Extract y bits |        |                       |        |
                          by bitwise and |        |      num_shift        |        |
                          with mask      |        |<----------------------|------->|   num_base
                                         |________|      (>0 here)        |________|  <-------->
                                             |                                |
                                             ----------------------------------
                                             shift Yi bits, xor w/input    ___|____
                                                                          |        | Ai = Yi ^ Zi
 OUTPUT:                                                                  v        v
 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
  x  w  v  u  t  s  r  q  p  o  n  m  l Y3 Y2 Y1 Y0  k  j  i  h  g  f  e A3 A2 A1 A1  d  c  b  a
```

总的来说, swizzle 的输出就是把输入的一部分和另一部分做异或

### 本质

[参考](https://zhuanlan.zhihu.com/p/671419093)

swizzle 本质就是把二维坐标中的 `new_icol = icol xor irow`

从这个角度理解, 就可以:

- 把坐标的低 `M` 位看做操作的具体单元
- 更高的 `S` 位看做是表示列号的范围
- 再高的 `B` 位看做是表示行号的范围

这样, 定义中的 

```
true_mask = ((1 << B) - 1) << (M + S)
new_idx = (idx xor (idx & true_mask))
```

就可以理解为列号异或行号了

## swizzle 融入 layout 优化

在某些 `slice`(固定某些坐标) 的情况下, `swizzle(layout(irow, icol))` 可以被简化为一个 `new_layout(irow, icol)`, 而结果不变, 这样可以节约运算

这种简化要求 `swizzle` 具有一些性质, 比较简单的要求就是在 `slice` 的要求下, `y` 和 `z` 的所有对应的位 `i` 中, `y_i` 和 `z_i` 有一个不变:

- 都不变: 显然, swizzle 的结果不变
- `y_i` 不变: 
- `z_i` 不变: 

有一个简单的判断方法可以快速判断: 

设 `A = slice(max_index)`, `A` 中为 1 的位就是 swizzle 前活跃的位 (和数位 dp 之类的类似, 如果 slice 的这一位可以活动, 那能表示的最大值的这一位一定是 1)

`collision_bitwise = A and (~sw(A))`

**证明:**

对一对 $Y_i/Z_i$，设：$a_z=A_{Z_i},\ a_y=A_{Y_i}$

则： $\operatorname{sw}(A)_{Z_i}=a_z\oplus a_y$

四种情况是：

| $a_z$ | $a_y$ | 含义 | $\operatorname{sw}(A)_{Z_i}$ |
|---:|---:|---|---:|
| 0 | 0 | 都不 active | 0 |
| 0 | 1 | 只有 $Y_i$ active | 1 |
| 1 | 0 | 只有 $Z_i$ active | 1 |
| 1 | 1 | $Y_i,Z_i$ 同时 active | 0 |

再观察 $C$ 在 $Z_i$ 位置上的值：$C_{Z_i}=A_{Z_i}\land \neg \operatorname{sw}(A)_{Z_i}$

代入：$C_{Z_i}=a_z\land\neg(a_z\oplus a_y)$


| $a_z$ | $a_y$ | $a_z\oplus a_y$ | $a_z\land\neg(a_z\oplus a_y)$ |
|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 |
| 0 | 1 | 1 | 0 |
| 1 | 0 | 1 | 0 |
| 1 | 1 | 0 | 1 |

$C_i$ 为 1 当且仅当 $Z_i$ 和 $Y_i$ 都 active (对 `sw(A)` 取反消除了 $Y, Z$ 之外的位的影响)
