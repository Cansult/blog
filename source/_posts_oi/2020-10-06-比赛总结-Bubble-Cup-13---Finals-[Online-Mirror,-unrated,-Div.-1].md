---
title: '比赛总结 Bubble Cup 13 - Finals [Online Mirror, unrated, Div. 1]'
tags:
  - 网络流
  - 二分
  - 数论
categories: 比赛总结
mathjax: true
abbrlink: 46997
date: 2020-10-06 19:52:00
layout:
---

呜呜呜我一定好好学数学(

<!--more-->	

### B. Valuable Paper

这标题...和WT的"珍贵物资"有异曲同工之妙啊

二分完了跑网络流就行了

一开始尝试一边加边一边网络流, 结果T了...

然后二分还写错了一次

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#include <queue>
#define MAXM (100000)
#define MAXN (10000)
#define rev(i) ((((i) - 1) ^ 1) + 1)
using namespace std;
struct fedg {
    int x, y, d;
} rb[MAXM + 5];
struct edg {
    int from, to, next, cap, flow, xd;
} b[MAXM * 20];
int g[MAXN * 2 + 5], cntb, s = MAXN * 2 + 1, t = MAXN * 2 + 2, n, m, dis[MAXN * 2 + 5], nd;
void ade(int fr, int t, int ca, int dd) {
    b[++cntb] = {fr, t, g[fr], ca, 0, dd};
    g[fr] = cntb;
}
bool bfs() {
    memset(dis, 0, sizeof(dis));
    queue<int> q;
    q.push(s);
    dis[s] = 1;
    while (!q.empty()) {
        int now = q.front();
        q.pop();
        for (int i = g[now]; i; i = b[i].next)
            if (b[i].cap > b[i].flow && b[i].xd <= nd && !dis[b[i].to])
                dis[b[i].to] = dis[now] + 1, q.push(b[i].to);
    }
    return dis[t];
}
int dinic(int now, int maxf) {
    int re = 0, ri;
    if (now == t || !maxf) return maxf;
    for (int i = g[now]; i; i = b[i].next)
        if (b[i].xd <= nd && b[i].cap > b[i].flow && dis[b[i].to] == dis[now] + 1) {
            ri = dinic(b[i].to, min(maxf, b[i].cap - b[i].flow));
            maxf -= ri;
            b[i].flow += ri;
            b[rev(i)].flow -= ri;
            re += ri;
        }
    return re;
}
bool cmp(fedg& x, fedg& y) { return x.d < y.d; }
bool pd() {
    for (int i = 1; i <= cntb; i++) b[i].flow = 0;
    int re = 0;
    while (bfs()) re += dinic(s, n);
    return (re == n);
}
int main() {
    scanf("%d%d", &n, &m);
    for (int i = 1; i <= n; i++) ade(s, i, 1, 0), ade(i, s, 0, 0), ade(i + MAXN, t, 1, 0), ade(t, i + MAXN, 0, 0);
    for (int i = 1; i <= m; i++) {
        scanf("%d%d%d", &rb[i].x, &rb[i].y, &rb[i].d);
        ade(rb[i].x, rb[i].y + MAXN, 1, rb[i].d);
        ade(rb[i].y + MAXN, rb[i].x, 0, rb[i].d);
    }
    sort(rb + 1, rb + m + 1, cmp);
    int le = n, ri = m + 1, ans = m + 1;
    while (le <= ri) { // 这个地方之前写成 le < ri 了... 导致有的值取不到...
        int mi = (le + ri) >> 1;
        nd = rb[mi].d;
        if (pd()) ri = mi - 1, ans = mi;
        else le = mi + 1;
    }
    if (ans > m) puts("-1");
    else printf("%d", rb[ans].d);
    return 0;
}
```

### K. Lonely Numbers

题意: 给一个整数$n$, 如果一个数$1\le x\le n$, 不存在$1\le y \le n, y\neq x$使$\gcd(x, y), x / \gcd(x, y), y / \gcd(x, y)$能构成三角形, 则称$x$是孤独的; 问$t$次$[1, n]$中有多少个数是孤独的$(t ,n \le 10^6)$

比赛的时候我进行了一些复杂的思考, 企图在所有素数能影响的范围$[p, ?]$内给答案数组都`+1`

```cpp
// 对于大于2的质数a gcd(a, b) = a, a / gcd = 1, b / gcd = b / a
// 1 + a > b / a 或者 1 + b / a > a
// a + a^2 > b 或者 a + b > a^2
// b < a^2 + a 或者 b > a^2 - a....?
 
// b < a^2 + a 且 b / a > a
// [a^2, a^2 + a];
 
// b > a^2 - a 且 b / a < a
// [a^2 - a, a^2]
 
// a | b
 
// 1 lonely
 
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define MAXN (1000000)
#define LL long long
using namespace std;
bool isp[MAXN + 5];
int prim[MAXN + 5], n, fr[MAXN + 5];
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
    for (int i = 1; i <= prim[0]; i++) {
        ++fr[prim[i]];
        LL x = (LL)prim[i] * prim[i] - prim[i] + 1;
        if (x < MAXN)
            --fr[nx + 1]; // 这个地方应该改成 --fr[nx]
    }
    for (int i = 1; i <= MAXN; i++)
        fr[i] += fr[i - 1];
    int t, n;
    scanf("%d", &t);
    while (t--) {
        scanf("%d", &n);
        printf("%d\n", fr[n] + 1);
    }
    return 0;
}
```

蛋是 ta WA了

然后比完赛看了看带佬的代码

```cpp
#include<cstdio>
#include<string>
#include<cstring>
#include<utility>
#include<cmath>
#include<map>
#include<queue>
#include<set>
#include<algorithm>
#include<vector>
#include<iostream>
#define ll long long
#define pii pair<int,int>
#define mp make_pair
#define fi first
#define se second
#define inf 0x7fffffff
#define minn(x,y) x=min(x,y)
#define maxx(x,y) x=max(x,y)
using namespace std;
int a[1000010],b[1000010];
int main()
{
    int i,j,k,n,m,x,y,z,t;
    n=1000000;
    for(i=2;i<=n;i++)
    {
        if(a[i]==0)
        {
            for(j=i*2;j<=n;j+=i)
            {
                a[j]=1;
            }
        }
    }
    a[1]=1;
    for(i=1;i<=n;i++)
    {
        b[i]=b[i-1]+(1^a[i]);
    }
    scanf("%d",&t);
    while(t--)
    {
        scanf("%d",&n);
        printf("%d\n",b[n]-b[(int)sqrt(n)]+1);
    }
}
```



??? 这啥啊???

然后发现很有道理

首先合数基本上不用考虑, 因为...显然?

然后一个质数$p$在$n \ge p^2$之后就都不会是孤独的了.

然后就没有然后了

感觉两个程序一个是$\frac{b}{a} \ge a$, 一个是$\frac{b}{a} + 1 > a$, 蛋是我当时脑瘫了, 写的`--fr[nx + 1]`, 但实际应该是`--fr[nx]`, 因为在`n == nx`时答案已经受到影响了

By 心态崩了的Cansult