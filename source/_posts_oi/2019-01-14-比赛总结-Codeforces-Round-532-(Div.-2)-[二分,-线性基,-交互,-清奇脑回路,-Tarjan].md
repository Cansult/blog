---
title: '比赛总结 Codeforces Round 532 (Div. 2) [二分, 线性基, 交互, 清奇脑回路, Tarjan]'
tags:
  - 二分
  - 线性基
  - 交互
  - 清奇脑回路
  - Tarjan
categories: 比赛总结
mathjax: true
abbrlink: 1096
date: 2019-01-14 11:28:15
layout:
---

每次我不打的比赛都贼好上分...

带$\lg$的算法是真的舒服

<!--more-->



### [D. Dasha and Chess](https://codeforces.com/contest/1100/problem/D)

题意: 交互题...在一个$999 \times 999$的棋盘上, 你有一个白子, $CF$有$666$个黑子, 每回合双方都只能移动一个子, 黑子可以移动到棋盘上任意一个没有子的位置, 白子只能向周围八个方向移动一格, 你先手, 当$CF$移动完成之后, 若有黑子与白子同行或同列, 则白胜, 问白子怎么走在$2000$内获胜

大...大傻和象棋???

嗯...我一开始想的是预处理出每个点需要走多少步才能允许白点在这个位置, 然后在对每个点看看白点需要走多少步能到达这个位置, 然后就一路跑就完事了

后来发现[SamuraiBebop大爷的代码](https://codeforces.com/contest/1100/submission/48353320)似乎更好写一些?

先走到$(500, 500)$然后看哪个角(准确的说是围棋里愚三角的形状, 包含三个$\frac{1}{2}$原大小的正方形)包含的点数大于$500$, 然后就一路向那个角走, 因为走一步影响了行和列至少两个点, 而黑点一次只能移动一个, 所以最后一定会获胜

懒得写了...

```cpp
#include<bits/stdc++.h>
#define MAXN 1005
#define INF 1000000000
#define MOD 1000000007
#define F first
#define S second
using namespace std;
typedef long long ll;
typedef pair<int,int> P;
int x,y,k,xx,yy;
bool rook[MAXN][MAXN];
P rk[MAXN];
void mov(int dx,int dy)
{
    if(dx!=0&&dy!=0&&rook[x+dx][y+dy])
    {
        assert(!rook[x][y+dy]);
        printf("%d %d\n",x,y+dy);
        y=y+dy;
        fflush(stdout);
        scanf("%d%d%d",&k,&xx,&yy);
        assert(k==-1);
        exit(0);
    }
    printf("%d %d\n",x+dx,y+dy);
    fflush(stdout);
    x+=dx;y+=dy;
    scanf("%d%d%d",&k,&xx,&yy);
    if(k==-1) exit(0);
    rook[rk[k].F][rk[k].S]=false;
    rook[xx][yy]=true;
    rk[k]=P(xx,yy);
}
int main()
{
    scanf("%d%d",&x,&y);
    for(int i=1;i<=666;i++)
    {
        scanf("%d%d",&xx,&yy);
        rook[xx][yy]=true;
        rk[i]=P(xx,yy);
    }
    while(x<500) mov(1,0);
    while(x>500) mov(-1,0);
    while(y<500) mov(0,1);
    while(y>500) mov(0,-1);
    int cnt0=0,cnt1=0,cnt2=0,cnt3=0;
    for(int i=1;i<=666;i++)
    {
        if(rk[i].F>=500||rk[i].S<=500) cnt0++;
        if(rk[i].F>=500||rk[i].S>=500) cnt1++;
        if(rk[i].F<=500||rk[i].S>=500) cnt2++;
        if(rk[i].F<=500||rk[i].S<=500) cnt3++;
    }
    if(cnt0>=500) while(true) mov(1,-1);
    if(cnt1>=500) while(true) mov(1,1);
    if(cnt2>=500) while(true) mov(-1,1);
    if(cnt3>=500) while(true) mov(-1,-1);
    return 0;
}
```

### [E. Andrew and Taxi](https://codeforces.com/contest/1100/problem/E)

题意: 给一个有向图, 边有边权, 要求选择一些边翻转, 使图变成$DAG$, 且边权最大值最小; 要求$\mathrm O(n\lg n)$的做法

一开始gayge给我说错题意了...说让边权和最小...我直接就懵逼了...

后来知道是要求最大边权最小... = =~~这不是很垃圾吗~~ 直接二分答案然后把大于答案的边拿出来跑$Tarjan$, 如果有环就`false`, 否则`true`

~~输出方案就是乱搞...~~好吧Refun大爷教我输出方案的正确姿势是对于可以更改的边, 由拓扑序(入度仅包括不可更改的边)小的点连向拓扑序大的, 这样可以保证不会出现环

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#include <stack>
#include <vector>
#include <queue>
#define MAXN (100000 + 5)
#define INF (1000000000 + 5)
using namespace std;
struct edg {
	int from, to, cost, next, bh;
} b[MAXN];
int n, m, cntb, g[MAXN], dfn[MAXN], low[MAXN], cntdfn, du[MAXN], rnk[MAXN];
bool ins[MAXN];
stack<int> gary;
vector<int> outp;
queue<int> q;
bool tarjan(int dq, int x) {
	gary.push(dq);
	ins[dq] = true;
	dfn[dq] = low[dq] = ++cntdfn;
	bool re = false;
	for (int i = g[dq]; i; i = b[i].next) {
		if (b[i].cost <= x) continue;
		if (!dfn[b[i].to])
			re |= tarjan(b[i].to, x), low[dq] = min(low[dq], low[b[i].to]);
		else if (ins[b[i].to])
			low[dq] = min(low[dq], dfn[b[i].to]);
		if (re)
			return true;
	}
	if (dfn[dq] == low[dq]) {
		if (gary.top() != dq)
			return true;
		while (gary.top() != dq) ins[gary.top()] = false, gary.pop();
		gary.pop();
		ins[dq] = false;
	}
	return false;
}
void ef() {
	int le = 0, ri = INF, ans = INF;
	while (le < ri) {
		int mi = (le + ri) >> 1;
		memset(dfn, 0, sizeof(dfn));
		memset(low, 0, sizeof(low));
		cntdfn = 0;
		bool ok = false;
		for (int i = 1; i <= n && !ok; i++)
			if (!dfn[i])
				ok = tarjan(i, mi);
		if (ok) le = mi + 1;
		else ans = ri = mi;
	}
	printf("%d ", ans);
	if (!ans) {
		puts("0");
		return ;
	}
	for (int i = 1; i <= m; i++)
		if (b[i].cost > ans)
			++du[b[i].to];
	for (int i = 1; i <= n; i++)
		if (!du[i])
			q.push(i), rnk[i] = ++rnk[0];
	while (!q.empty()) {
		int dq = q.front();
		q.pop();
		for (int i = g[dq]; i; i = b[i].next)
			if (b[i].cost > ans) {
				--du[b[i].to];
				if (!du[b[i].to])
					rnk[b[i].to] = ++rnk[0], q.push(b[i].to);
			}
	}
	for (int i = 1; i <= m; i++)
		if (b[i].cost <= ans && rnk[b[i].from] > rnk[b[i].to])
			outp.push_back(b[i].bh);
	printf("%d\n", outp.size());
	for (int i = 0; i < outp.size(); i++)
		printf("%d ", outp[i]);
}
void adn(int from, int to, int cost, int bh) {
	b[++cntb].next = g[from];
	b[cntb].from = from, b[cntb].to = to, b[cntb].cost = cost, b[cntb].bh = bh;
	g[from] = cntb;
}
int main() {
	scanf("%d%d", &n, &m);
	for (int i = 1, srx, sry, src; i <= m; i++)
		scanf("%d%d%d", &srx, &sry, &src), adn(srx, sry, src, i);
	ef();
	return 0;
}
```



### [F. Ivan and Burgers](https://codeforces.com/contest/1100/problem/F)

题意: 给一个大小为$n$的序列, 有$q$个区间, 求出每个区间中选一些数的异或最大值; 要求$\mathrm O(n\lg n)$的做法

一开始以为是线性基板子题...这不就是开个线段树维护区间线性基吗 ~~查询一次最多合并三个节点$\mathrm O(n\lg^2n)$不能再科学了~~ 然而被部长打脸了查询一次要合并$\lg$个区间所以复杂度是$\mathrm O(n \lg^3 n)$的就假了

然后发现似乎...跑不过去...

然后参悟了[dragonslayerintraining大爷的代码](https://codeforces.com/contest/1100/submission/48369357)

发现了船新的$\mathrm O(n\lg n)$的做法 还贼好写...还是固定一个端点然后找满足另一个节点的套路...看代码还是很好懂的...



#### Before

```cpp
#include <iostream>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <algorithm>
#define MAXN (500000 + 5)
#define MAXL (20 + 2)
#define LS(dq) ((dq) << 1)
#define RS(dq) (((dq) << 1) | 1)
using namespace std;
struct xxj {
	int zh[MAXL];
	xxj() { memset(zh, 0, sizeof(zh)); }
	void ins(int x) {
		for (int i = MAXL - 1; i >= 0; i--)
			if (x & (1 << i)) {
				if (!zh[i]) {
					zh[i] = x;
					break;
				}
				x ^= zh[i];
			}
	}
	int max() {
		int re = 0;
		for (int i = MAXL - 1; i >= 0; i--)
			if ((re ^ zh[i]) > re)
				re ^= zh[i];
		return re;
	}
};
struct node {
	int le, ri;
	xxj zh;
} b[MAXN << 2];
int n, a[MAXN];
xxj uni(xxj re, const xxj y) {
	for (int i = MAXL - 1; i >= 0; i--)
		re.ins(y.zh[i]);
	return re;
}
void js(int dq, int le, int ri) {
	b[dq].le = le, b[dq].ri = ri;
	for (int i = le; i <= ri; i++) b[dq].zh.ins(a[i]);
	if (le == ri) return ;
	int mi = (le + ri) >> 1;
	js(LS(dq), le, mi), js(RS(dq), mi + 1, ri);
}
xxj cx(int dq, int le, int ri) {
	if (b[dq].le == le && b[dq].ri == ri) return b[dq].zh;
	int mi = (b[dq].le + b[dq].ri) >> 1;
	if (le > mi) return cx(RS(dq), le, ri);
	else if (ri <= mi) return cx(LS(dq), le, ri);
	else return uni(cx(LS(dq), le, mi), cx(RS(dq), mi + 1, ri));
}
inline int read() {
	int re = 0;
	char x = 0;
	while (x < '0' || x > '9') x = getchar();
	while (x >= '0' && x <= '9') re = re * 10 + x - '0', x = getchar();
	return re;
}
int main() {
	n = read();
	for (int i = 1; i <= n; i++) a[i] = read();
	js(1, 1, n);
	int q;
	q = read();
	for (int i = 1, srx, sry; i <= q; i++) srx = read(), sry = read(), printf("%d\n", cx(1, srx, sry).max());
	return 0;
}

```

#### After


```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <algorithm>
#include <vector>
#define MAXN (500000 + 5)
#define MAXL (20 + 1)
#define pii pair<int, int>
using namespace std;
struct xxj {
	pii zh[MAXL];
	xxj() { memset(zh, 0, sizeof(zh)); }
	void ins(pii x) {
		for (int i = MAXL - 1; i >= 0; i--)
			if (x.second & (1 << i)) {
				if (!zh[i].second) {
					zh[i] = x;
					return ;
				}
				x.second ^= zh[i].second;
			}
	}
	int max(int le) {
		int re = 0;
		for (int i = MAXL - 1; i >= 0; i--)
			if (zh[i].first >= le && (re ^ zh[i].second) > re)
				re ^= zh[i].second;
		return re;
	}
}node[MAXN]; 
int n, q;
int main() {
	scanf("%d", &n);
	for (int i = 1, srx; i <= n; i++) {
		scanf("%d", &srx);
		vector<pii> qwq;
		qwq.push_back(make_pair(i, srx));
		for (int j = 0; j < MAXL; j++)
			if (node[i - 1].zh[j].second)
				qwq.push_back(node[i - 1].zh[j]);
		sort(qwq.begin(), qwq.end());
		int ni = qwq.size();
		for (int j = ni - 1; j >= 0; j--)
			node[i].ins(qwq[j]);
	}
	int q;
	scanf("%d", &q);
	for (int i = 1, srx, sry; i <= q; i++)
		scanf("%d%d", &srx, &sry), printf("%d\n", node[sry].max(srx));
	return 0;
}

```

By 准备退役旅游的 Cansult