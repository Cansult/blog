---
title: '比赛总结 Codeforces Round 680 (Div. 2, based on Moscow Team Olympiad)'
tags:
  - 二分图
  - 乱搞
categories: 比赛总结
mathjax: true
abbrlink: 65233
date: 2020-11-02 14:12:00
layout:
---

终于不掉分了

~~因为已经掉底了~~

<!--more-->

[传送门](https://codeforc.es/contest/1445)

### A. Array Rearrangment

`multiset`搞搞搞

```cpp
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <set>
#define MAXN 50
#define DD double
#define LL long long
using namespace std;
int main() {
	int t;
	scanf("%d", &t);
	while (t--) {
		int n, a[MAXN + 5], b[MAXN + 5], x;
		multiset<int> gg;
		scanf("%d%d", &n, &x);
		for (int i = 1; i <= n; i++)
			scanf("%d", &a[i]);
		for (int i = 1; i <= n; i++) scanf("%d", &b[i]), gg.insert(x - b[i]);
		bool ok = true;
		for (int i = 1; i <= n; i++) {
			multiset<int>::iterator ggx = gg.lower_bound(a[i]);
			if (ggx == gg.end()) {
				ok = false;
				break;
			}
			gg.erase(ggx);
		}
		puts(ok ? "Yes" : "No");
	}
	return 0;
}
```

### B. Elimination

题意:

第一场的前100名第一场都至少a分, 第二场都至少b分
第二场的前100名第二场都至少c分, 第一场都至少d分

或者说:

构造一个`pair`的数组, 以`first`排序时前100名的`first = a, second >= b`; 以`second`排序时前100名的`second = c, first = d`.
求在以`first + second`排序时第100名的最小值

题解:

因为没有限定人数, 所以只要取`max(a + b, b + c)`就好了 (一百个人是第一场`a`第二场`b`分, 一百个人是第二场`c`分第一场`a`分)

```cpp
/*
第一场的前100名第一场都至少a分, 第二场都至少b分
第二场的前100名第二场都至少c分, 第一场都至少d分
构造一个pair, 以first排序时前100名的first = a, second >= b; 以second排序时前100名的second = c, first = d
求在以first + second排序时第100名的最小值
*/



#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#define DD double
#define LL long long
using namespace std;
int main() {
	int t;
	scanf("%d", &t);
	while (t--) {
		int a, b, c, d;
		scanf("%d%d%d%d", &a, &b, &c, &d);
		printf("%d\n", max(a + b, c + d));
	}
	return 0;
}
```

### C. Division

题意:

给两个数`a, b`, 找一个最大的`x`满足`a % x == 0 && x % b != 0`

题解:

筛完素数 枚举质因数就行了

```cpp
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#define DD double
#define LL long long
#define MAXN 100000
using namespace std;
bool isp[MAXN + 5];
LL prim[MAXN + 5];
int main() {
	memset(isp, true, sizeof(isp));
    isp[1] = false;
    for (int i = 1; i <= MAXN; i++) {
        if (isp[i])
            prim[++prim[0]] = i;
        for (int j = 1; j <= prim[0] && (LL)i * prim[j] <= MAXN; j++) {
            isp[i * prim[j]] = false;
            if (i % prim[j] == 0) break;
        }
    }
	int t;
	scanf("%d", &t);
	while (t--) {
		LL a, b;
		scanf("%lld%lld", &a, &b);
		if (a % b != 0) printf("%lld\n", a);
		else {
			LL ans = a;
			while (ans % b == 0) ans /= b;
			for (int i = 1; i <= prim[0] && prim[i] <= b; i++) {
				if (b % prim[i]) continue;
				LL bans = 0, aans = 0, xb = b, xa = a;
				while (xb % prim[i] == 0) ++bans, xb /= prim[i];
				while (xa % prim[i] == 0) ++aans, xa /= prim[i];
				LL xans = a;
				for (int j = 1; j <= aans - bans + 1; j++) xans /= prim[i];
				ans = max(ans, xans);
			}
			printf("%lld\n", ans);
		}
	}
	return 0;
}
```

### D. Divide and Sum

题意:

给一个长度为 $2n$ 的数列, 分成两个长度为 $n$ 的数列 $\{a_n\}, \{b_n\}$ 一个从小到大排序, 一个从大到小排序, 令 $F = \sum_{i = 1}^n |a_i - b_i|$
求出所有可能的 $F$ 的和

题解:



### E

题意:

给一个图, 每个点有所属的一个group, 问有多少种方案能选出两个group, 里面的点和边组成一个二分图

题解:

我一开始想的是, 先对每个group的点和边测一下二分图. 然后把所有的边按照它连接的两个group分组, 对于每一个组, 检验 组中的每一条边加入后 这两个组和这些边组成的图是否是一个二分图

然后就是如何检验的问题了

我一开始想的是对于每一条边 看他两边的点的`dis`的奇偶的异或, 然后如果一个组里所有的边的异或值都相等, 那么就是合法的

后来发现了一个比较严重的问题(第三个样例): 我们之前的检验方法没有考虑到组内边的互相影响

后来瞅了一眼题解, 发现了一个词 "compress", 一下子完全理解了, 我们在检验的时候其实可以用更暴力的方法: 直接加边后dfs. 但是我们发现, 这样复杂度有点小高, 考虑复杂度的主要来源是每一个组内的边都要重复被加入 $\mathrm O(m)$ 次, 所以我们可以对一个组内的点进行压缩, 把`dis`是奇数和偶数的点分别压缩成一个点, 然后在这两个点之间连边, 然后把组里的边加入后dfs就可以了

然后就是一些细节问题

首先组内的点可能不一定联通, 所以压缩实际上是对每一个联通块来压缩, 然后要还要考虑一个group是二分图却不与其他是二分图的group联通 的情况, 记录出来之后加一加就好了

最后别忘了数组开大点 然后初始化的时候也记得脑子清醒点, 搞清楚那些位置变化了

```cpp
// 给一张无向图, 每个点有一个所属的group, 问有多少中选择group的方法, 让两个group里的点可以形成一个二分图

#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <vector>
#include <set>
#include <map>
#include <queue>
#define DD double
#define LL long long
#define MAXN 500000
#define MAXM 500000
using namespace std;
struct edg {
	int from, to, next;
} b[MAXM * 2 + 5], ob[MAXM + 5], nb[MAXM * 10 + 5]; // ob: 原始的边
int g[MAXN + 5], cntb, n, m, k, group[MAXN + 5], dis[MAXN + 5], cntg, cnte, belong[MAXN + 5], ndis[MAXN * 2 + 5];
int ng[MAXN * 2 + 5], cntn;
LL ans;
bool ise[MAXN + 5], chan[MAXN + 5];
map<int, int> bh[MAXN + 5]; // 记录连接group(i, j)这一类边在bigb中的编号
map<int, int> xbh[MAXN + 5];
set<int> ce[MAXN + 5];
vector<int> bigb[MAXM + 5]; // 记录连接同一对group的边的编号, 每次检查一类边, 看看是否合法, 如果合法就++ans
vector<int> ning[MAXN + 5];
void ade(int fr, int to) {
	b[++cntb] = {fr, to, g[fr]};
	g[fr] = cntb;
}
void ade2(int fr, int to) {
	nb[++cntn] = {fr, to, ng[fr]};
	ng[fr] = cntn;
}
bool ok;
void dfs(int now) {
	for (int i = g[now]; i; i = b[i].next) {
		if (group[b[i].to] != group[now]) continue;
		if (dis[b[i].to] == -1)
			dis[b[i].to] = dis[now] ^ 1, belong[b[i].to] = belong[now], dfs(b[i].to);
		else if (dis[b[i].to] != (dis[now] ^ 1)) { ok = false; return ; }
		if (!ok) return ;
	}
}
void dfs2(int now) {
	for (int i = ng[now]; i; i = nb[i].next) {
		if (ndis[nb[i].to] == -1)
			ndis[nb[i].to] = ndis[now] ^ 1, dfs2(nb[i].to);
		else if (ndis[nb[i].to] != (ndis[now] ^ 1)) { ok = false; return ; }
		if (!ok) return ;
	}
}
void recov(int now) {
	ndis[now] = -1;
	for (int i = ng[now]; i; i = nb[i].next)
		if (~ndis[nb[i].to]) recov(nb[i].to);
}
bool pd(int now) {
	ok = true;
	for (int i = 0; i < bigb[now].size(); i++) {
		int xi = ob[bigb[now][i]].from, yi = ob[bigb[now][i]].to;
		if (!ise[group[xi]] || !ise[group[yi]])
			return false;
		int bx = belong[xi], by = belong[yi];
		ade2(bx + dis[xi] * MAXN, by + dis[yi] * MAXN);
		ade2(by + dis[yi] * MAXN, bx + dis[xi] * MAXN);
		ade2(bx, bx + MAXN), ade2(bx + MAXN, bx);
		ade2(by, by + MAXN), ade2(by + MAXN, by);
	}
	for (int i = 0; i < bigb[now].size(); i++) {
		int xi = ob[bigb[now][i]].from, yi = ob[bigb[now][i]].to;
		int bx = belong[xi], by = belong[yi];
		if (ndis[bx + dis[xi] * MAXN] == -1)
			ndis[bx + dis[xi] * MAXN] = 0, dfs2(bx + dis[xi] * MAXN);
		if (ndis[by + dis[yi] * MAXN] == -1)
			ndis[by + dis[yi] * MAXN] = 0, dfs2(by + dis[yi] * MAXN);
	}
	for (int i = 0; i < bigb[now].size(); i++) {
		int xi = ob[bigb[now][i]].from, yi = ob[bigb[now][i]].to;
		int bx = belong[xi], by = belong[yi];
		if (~ndis[bx + dis[xi] * MAXN])
			recov(bx + dis[xi] * MAXN);
		if (~ndis[by + dis[yi] * MAXN])
			recov(by + dis[yi] * MAXN);
	}
	for (int i = 0; i < bigb[now].size(); i++) {
		int xi = ob[bigb[now][i]].from, yi = ob[bigb[now][i]].to;
		int bx = belong[xi], by = belong[yi];
		ng[bx + MAXN] = ng[bx] = ng[by] = ng[by + MAXN] = 0;
	}
	cntn = 0;
	return ok;
}
int main() {
	memset(dis, -1, sizeof(dis));
	memset(ndis, -1, sizeof(ndis));
	scanf("%d%d%d", &n, &m, &k);
	for (int i = 1; i <= n; i++) {
		scanf("%d", &group[i]);
		ning[group[i]].push_back(i);
	}
	for (int i = 1, xi, yi; i <= m; i++) {
		scanf("%d%d", &xi, &yi);
		ade(xi, yi), ade(yi, xi);
		if (group[xi] > group[yi]) swap(xi, yi);
		ob[i].from = xi, ob[i].to = yi;
		int gx = group[xi], gy = group[yi];
		if (gx == gy) continue;
		if (bh[gx].find(gy) == bh[gx].end()) bh[gx][gy] = ++cntg;
		bigb[bh[gx][gy]].push_back(i);
	}
	for (int i = 1; i <= k; i++) {
		ise[i] = true;
		if (ning[i].size()) {
			for (int j = 0; j < ning[i].size(); j++)
				if (dis[ning[i][j]] == -1) {
					ok = true;
					dis[ning[i][j]] = 0;
					belong[ning[i][j]] = ++belong[0];
					dfs(ning[i][j]);
					if (!ok) ise[i] = false;
				}
		}
		if (ise[i])
			++cnte;
	}
	for (int i = 1, xi, yi; i <= m; i++) {
		xi = ob[i].from, yi = ob[i].to;
		int gx = group[xi], gy = group[yi];
		if (!ise[gx] || !ise[gy] || gx == gy) continue;
		ce[gx].insert(gy), ce[gy].insert(gx);
	}
	if (cnte) {
		for (int i = 1; i <= k; i++)
			if (ise[i])
				ans += cnte - 1 - (int)ce[i].size();
	}
	ans >>= 1;
	for (int i = 1; i <= cntg; i++)
		if (pd(i))
			++ans;
	printf("%lld", ans);
	return 0;
}
```
