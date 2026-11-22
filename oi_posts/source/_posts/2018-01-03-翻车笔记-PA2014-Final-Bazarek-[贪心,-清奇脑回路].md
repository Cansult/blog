---
title: '翻车笔记 PA2014 Final Bazarek [清奇脑回路, 贪心]'
tags:
  - 清奇脑回路
  - 贪心
categories: 翻车笔记
mathjax: true
abbrlink: 37985
date: 2019-01-03 15:07:26
layout:
---





新年快乐啊

又是碌碌无为的一年啊

<!--more-->

### 懵逼的 题目

[BZOJ](https://lydsy.com/JudgeOnline/problem.php?id=3721)

### 扯淡的 题解

一开始老是往转移上面想, 比如说我 一次加一个偶数或者加两个奇数云云...后来发现似乎如果加奇数偶数的结果是一样的就GG了...

后来抄CA爷爷的题解 发现非常的厉害: 把所有的数从大到小排序, 记录每个位置的[这个位置之前的最小的偶数与这个位置之后的最大的奇数的差], 和[这个位置之前的最小的奇数与这个位置之后最大的偶数的差], 然后做前缀和

对于每一个位置, 如果这个位置的前缀和是奇数, 那很好, 直接跳过; 否则我们就要考虑花尽量少的代价来把这个前缀和改成奇数, 就用到我们预处理的东西, 挑一个小的然后减去就可以了

### 沙茶的 代码

这样写起来清新多了

```cpp
/**************************************************************
    Problem: 3721
    User: Cansult
    Language: C++
    Result: Accepted
    Time:11940 ms
    Memory:48168 kb
****************************************************************/
 
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define LL long long
#define MAXN (1000000 + 5)
#define INF (100000000000000ll + 5)
using namespace std;
int n;
LL a[MAXN], premin[2][MAXN], nexmax[2][MAXN], ans[MAXN];
bool cmp(int x, int y) { return x > y; }
int main() {
    scanf("%d", &n);
    for (int i = 1; i <= n; i++)
        scanf("%lld", &a[i]);
    sort(a + 1, a + n + 1, cmp);
    memset(premin, 0x7f, sizeof(premin));
    for (int i = 1; i <= n; i++) {
        premin[a[i] & 1][i] = min(premin[a[i] & 1][i - 1], a[i]);
        premin[(a[i] & 1) ^ 1][i] = premin[(a[i] & 1) ^ 1][i - 1];
    }
    for (int i = n; i >= 1; i--) {
        nexmax[a[i] & 1][i] = max(nexmax[a[i] & 1][i + 1], a[i]);
        nexmax[(a[i] & 1) ^ 1][i] = nexmax[(a[i] & 1) ^ 1][i + 1];
    }
    for (int i = 1; i <= n; i++) a[i] += a[i - 1];
    for (int i = 1; i <= n; i++)
        if (a[i] & 1)
            ans[i] = a[i];
        else {
            LL ans0, ans1;
            ans0 = ans1 = INF;
            if (nexmax[0][i + 1] && premin[1][i] < INF)
                ans0 = premin[1][i] - nexmax[0][i + 1];
            if (nexmax[1][i + 1] && premin[0][i] < INF)
                ans1 = premin[0][i] - nexmax[1][i + 1];
            if (ans1 >= INF && ans1 >= INF)
                ans[i] = -1;
            else
                ans[i] = a[i] - min(ans0, ans1);
        }
    int q;
    scanf("%d", &q);
    for (int i = 1, srx; i <= q; i++)
        scanf("%d", &srx), printf("%lld\n", ans[srx]);
    return 0;
}
```

By 准备退役旅游的 Cansult