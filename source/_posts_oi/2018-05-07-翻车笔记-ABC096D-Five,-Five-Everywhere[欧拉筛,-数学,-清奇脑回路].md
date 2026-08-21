---
title: '翻车笔记 ABC096D "Five, Five Everywhere" [欧拉筛, 数学, 清奇脑回路]'
tags:
  - 欧拉筛
  - 数学
  - 清奇脑回路
categories: 翻车笔记
mathjax: true
abbrlink: 64976
date: 2018-05-07 21:33:00
layout:
---



不会ABC了已经

<!--more-->

### 懵逼的 题目

[qwq](https://abc096.contest.atcoder.jp/tasks/abc096_d)

### 扯淡的 题解

当时和Ycrpro看这道题的时候完全是懵逼的啊!

我翻了哥德巴赫猜想, 猜了是否5个素数的和不可能是合数, 算了$5000$以内的素数和为合数的情况, 找了$2, 4, 6$个素数和的规律

就是没有想到



>  其实题目名称有点小提示，让这些数的个位是1，5个这样的数加起来一定是5的倍数，也就是合数了。
>
>  ——from [一个不知名的大佬](https://blog.csdn.net/swunHJ/article/details/80211192)

[人生重来算了.jpg]

### 沙茶的 代码

去年的欧拉筛我居然没忘...

```cpp
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <cmath>
#include <vector>
#define MAXN (100000 + 5)
using namespace std;
bool isp[MAXN];
vector<int> prime;
void init()
{
	memset(isp, true, sizeof(isp));
	isp[1] = false;
	for (int i = 2; i < MAXN; i++)
	{
		if (isp[i])
			prime.push_back(i);
		for (int j = 0; j < prime.size() && prime[j] * i < MAXN; j++)
		{
			isp[i * prime[j]] = false;
			if (i % prime[j] == 0)
				break;
		}
	}
}
int main()
{
	freopen("in.in", "r", stdin);
	init();
	int n;
	scanf("%d", &n);
	int last = 0;
	for (int i = 1; i <= n; i++)
	{
		for (; last < prime.size(); last++)
			if (prime[last] % 10 == 1)
			{
				printf("%d ", prime[last]);
				++last;
				break;
			}
	}
	return 0;
}
```

By 大沙茶 Cansult