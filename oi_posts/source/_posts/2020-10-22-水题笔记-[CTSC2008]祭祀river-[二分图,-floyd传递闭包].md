---
title: '水题笔记 [CTSC2008]祭祀river [二分图, floyd传递闭包]'
tags:
  - 二分图
  - floyd传递闭包
categories: 水题笔记
mathjax: true
abbrlink: 50036
date: 2020-10-22 20:43:00
layout:
---





天好冷啊

我要妹子

<!--more-->

### 题目

[dbzoj](https://darkbzoj.tk/problem/1143)

### 题解

luogu上的还要输出方案, 感觉很蛋疼, 不想做

题目要求我们选一个最大点集, 点之间不能互相到达.

等价于floyd传递闭包后, 选出一个最大点集, 点之间没有边相连, 即求最大独立集

[这里](https://cansult.github.io/posts/16301.html)讲过做法了

### 代码

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define MAXM (50000)
#define MAXN (100)
#define rev(i) ((((i) - 1) ^ 1) + 1)
using namespace std;
bool edg[MAXN + 5][MAXN + 5], vis[MAXN + 5];
int link[MAXN + 5], n, m, ans;
bool find(int now) {
	for (int i = 1; i <= n; i++)
		if (!vis[i] && edg[now][i]) {
			vis[i] = true;
			if (!link[i] || find(link[i])) {
				link[i] = now;
				return true;
			}
		}
	return false;
}
void floyd() {
	for (int k = 1; k <= n; k++)
		for (int i = 1; i <= n; i++)
			for (int j = 1; j <= n; j++)
				edg[i][j] = edg[i][j] || (edg[i][k] && edg[k][j]);
}
int main() {
	memset(edg, false, sizeof(edg));
	scanf("%d%d", &n, &m);
	for (int i = 1, xi, yi; i <= m; i++)
		scanf("%d%d", &xi, &yi), edg[xi][yi] = true;
	floyd();
	for (int i = 1; i <= n; i++) {
		memset(vis, false, sizeof(vis));
		if (find(i)) ++ans;
	}
	printf("%d", n - ans);
}
```

By Cansult