---
title: '翻车笔记 Tyvj1952 Easy && OSU! [期望DP]'
tags:
  - 期望DP
  - DP
categories: 翻车笔记
mathjax: true
abbrlink: 61115
date: 2020-12-07 14:37:30
layout:
---

啥时候得自己学学概率了

蛋疼

<!--more-->

### [Tyvj1952 Easy](https://darkbzoj.tk/problem/3450)

考虑递推, 计算答案的增量, $f_{n} - f_{n - 1} = (x + 1)^2\cdot p_i - x^2$, 其中$x$代表从$n - 1$向前延伸的最长连续o的期望, $p_i$是位置$n$上为o的概率

所以$f_n = f_{n - 1} + p_i\cdot (2x_{n - 1} + 1)$, 我们只需要计算出$\{x_n\}$就可以了

这就很简单了 $x_n = (x_{n - 1} + 1) \cdot p_n$

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define MAXN 300000
#define DD double
using namespace std;
int n, a[MAXN + 5];
char s[MAXN + 5];
DD El[MAXN + 5], ans;
int main() {
	scanf("%d", &n);
	scanf("%s", s);
	for (int i = 1; i <= n; i++)
		a[i] = (s[i - 1] == '?') ? 2 :
			(s[i - 1] == 'x' ? 0 : 1);
	for (int i = 1; i <= n; i++) {
		if (!a[i]) El[i] = 0;
		else if (a[i] == 1) El[i] = El[i - 1] + 1;
		else El[i] = (El[i - 1] + 1) / 2;
	}
	for (int i = 1; i <= n; i++)
		ans += (a[i] == 1) ? El[i - 1] * 2 + 1 : (a[i] == 2 ? (El[i - 1] + 0.5) : 0);
	printf("%.4lf", ans);
	return 0;
}

```

### [OSU!](https://darkbzoj.tk/problem/4318)

和上面的题差不多

$f_{n} - f_{n - 1} = (x + 1)^2\cdot p_i - x^2$
