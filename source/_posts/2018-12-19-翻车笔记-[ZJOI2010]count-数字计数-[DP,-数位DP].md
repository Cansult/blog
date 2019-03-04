---
title: '翻车笔记 [ZJOI2010]count 数字计数 [DP, 数位DP]'
tags:
  - DP
  - 数位DP
categories: 翻车笔记
mathjax: true
abbrlink: 49914
date: 2018-12-19 21:25:26
layout:
---

数位DP真是有够自闭的

<!--more-->

### 懵逼的 题目

[BZOJ](https://lydsy.com/JudgeOnline/problem.php?id=1833)

### 扯淡的 题解

每次感觉只是个细节问题 然后就改不了了...

一开始我用`f[i][0 : 1][0 : 1][0 : 9]`表示: 当前在第`i`位, 是否还是前导`0`, 是否卡上界, `0 ~ 9`每个数码的个数

然后发现在更新的时候我要加的是[符合前`i`个条件的数的个数]...但是我并没有记录...

后来参悟了一下[zyf2000学姐的写法](https://blog.csdn.net/Clove_unique/article/details/53081255) ~~似乎也只有本校的学长学姐用数组的写法了~~

枚举当前要处理的数位$x$ `f[i][times][0 : 1][0 : 1]`代表当前在第`i`位, 有`times`个$x$, 是否卡上界, 是否是前导`0`的**数**的个数

这样在更新的时候我们就可以搞数的个数了...

而且还有一个地方就是尽量的减少DP数组的状态, 毕竟DP是对状态的压缩 当然是要越简单越好了...枚举$x$减少了肥肠大的代码复杂度...

### 沙茶的 代码

#### Before

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define LL long long
#define MAXL (15 + 5)
using namespace std;
void solve(LL x, LL* ans) {
	LL f[MAXL][2][2][11]; // f[i][0 : 1][0 : 1][0 : 9]: 当前在第i位, 是否还是前导0, 是否卡上界, 0 ~ 9每个数码的个数
	int a[MAXL];
	memset(f, 0, sizeof(f));
	a[0] = 0;
	while (x)	a[++a[0]] = x % 10ll, x /= 10ll;
	f[a[0] + 1][1][1][10] = 1;
	for (int i = a[0]; i >= 1; i--)
		for (int is0 = 0; is0 <= 1; is0++)
			for (int u = 0; u <= 1; u++)
				if (f[i + 1][is0][u][10])
					for (int nn = 0; nn <= 9; nn++) {
						int uu = u & (nn == a[i]), nis = is0 & (!nn);
						if (u && nn > a[i])	continue;
						f[i][nis][uu][10] = 1;
						if (nis)	continue;
						for (int gg = 0; gg <= 9; gg++)
							f[i][nis][uu][gg] += f[i + 1][is0][u][gg];
						++f[i][nis][uu][nn]; // 假的 应该是加前几位符合条件的数的个数, 所以要加一维表示最后一位?
					}
	for (int is0 = 0; is0 <= 1; is0++)
		for (int u = 0; u <= 1; u++)
			if (f[1][is0][u][10])
				for (int n = 0; n <= 9; n++)
					ans[n] += f[1][is0][u][n];

}
int main() {
	LL a, b, ax[MAXL], bx[MAXL];
	memset(ax, 0, sizeof(ax));
	memset(bx, 0, sizeof(bx));
	scanf("%lld%lld", &a, &b);
	solve(b, bx);
	solve(a - 1, ax);
	for (int i = 0; i <= 9; i++)
		printf("%lld ", bx[i] - ax[i]);
	puts("");
	return 0;
}

```

#### After

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define LL long long
#define MAXL (15 + 5)
#define MAXZ (10)
using namespace std;
LL solve(LL x, int dqw) {
	int a[MAXL];
	a[0] = 0;
	while (x)	a[++a[0]] = x % 10, x /= 10;
	LL f[MAXL][MAXL][2][2];
	memset(f, 0, sizeof(f));
	f[a[0] + 1][0][1][1] = 1;
	for (int i = a[0]; i >= 1; i--)
		for (int times = 0; times < MAXL; times++)
			for (int u = 0; u <= 1; u++)
				for (int is0 = 0; is0 <= 1; is0++)
					if (f[i + 1][times][u][is0]) {
						for (int nn = 0; nn <= 9; nn++) {
							if (u && nn > a[i])	continue;
							int uu = (u && nn == a[i]), nis = (is0 && !nn);
							if (is0)
								++f[i][nn == dqw][uu][nis];
							else
								f[i][times + (nn == dqw)][uu][nis] += f[i + 1][times][u][is0];
						}
					}
	LL re = 0;
	for (int times = 0; times < MAXL; times++)
		for (int u = 0; u <= 1; u++)
			re += f[1][times][u][0] * times;
	return re;
}
int main() {
	LL a, b;
	scanf("%lld%lld", &a, &b);
	for (int i = 0; i < 9; i++)
		printf("%lld ", solve(b, i) - solve(a - 1, i));
	printf("%lld", solve(b, 9) - solve(a - 1, 9));
	return 0;
}
```

By 准备退役旅游的 Cansult