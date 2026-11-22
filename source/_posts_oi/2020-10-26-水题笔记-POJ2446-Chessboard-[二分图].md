---
title: '水题笔记 POJ2446 Chessboard [二分图]'
tags:
  - 二分图
categories: 水题笔记
mathjax: true
abbrlink: 22377
date: 2020-10-26 14:54:00
layout:
---

> 吃屎吧，数组要开到2000，血试出来的，唉
> 


<!--more-->

### 题目

[POJ](http://poj.org/problem?id=2446)

### 题解

把矩阵上的点编号, 然后复制一遍, 作为二分图的两部, 看看能匹配的边数是否和矩阵的可用点一样多就好了

其实这道题直观的想法是把矩阵的可行点分成两部分作为二分图的两部, 然后跑匹配, 一个匹配边就是一个骨牌. 但是我们不知道怎么分, 所以只能复制一遍了, 反正不会对答案造成影响.

### 代码

```cpp
#include <iostream>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <algorithm>
#define MAXN (1000)
#define MAXK (32)
#define bh(i, j) ((((i) - 1) * MAXK) + (j))
using namespace std;
const int xy[4][2] = { {0, 1}, {1, 0}, {0, -1}, {-1, 0} };
struct edg {
	int from, to, next;
} b[MAXN * 4 + 5];
int g[MAXN * 2 + 5], cntb, n, m, link[MAXN * 2 + 5], ans, kk;
bool fbd[MAXN + 5], vis[MAXN * 2 + 5];
void ade(int fr, int t) {
	++cntb;
	b[cntb].from = fr, b[cntb].to = t, b[cntb].next = g[fr];
	g[fr] = cntb;
}
bool find(int x) {
	for (int i = g[x]; i; i = b[i].next)
		if (!vis[b[i].to]) {
			vis[b[i].to] = true;
			if (!link[b[i].to] || find(link[b[i].to])) {
				link[b[i].to] = x;
				return true;
			}
		}
	return false;
}
int main() {
	scanf("%d%d%d", &m, &n, &kk);
	for (int i = 1, xi, yi; i <= kk; i++) {
		scanf("%d%d", &xi, &yi);
		fbd[bh(xi, yi)] = true;
	}
	for (int i = 1; i <= n; i++)
		for (int j = 1; j <= m; j++)
			for (int k = 0; k < 4; k++) {
				int ni = i + xy[k][0], nj = j + xy[k][1];
				if (i + xy[k][0] <= n && j + xy[k][1] <= m && i + xy[k][0] > 0 && j + xy[k][1] > 0 && !fbd[bh(i, j)] && !fbd[bh(ni, nj)])
					ade(bh(i, j), bh(ni, nj));
			}
	for (int i = 1; i <= n; i++)
		for (int j = 1; j <= m; j++) {
			memset(vis, false, sizeof(vis));
			if (find(bh(i, j)))
				++ans;
		}
	puts((ans == n * m - kk) ? "YES" : "NO");
	return 0;
}
```

By Cansult