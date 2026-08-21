---
title: '翻车笔记 种树 + [POJ Challenge]生日礼物 + [CTSC2007]数据备份Backup [贪心, 清奇脑回路, 翻车] + [NOI2010]超级钢琴'
tags:
  - 贪心
  - 清奇脑回路
  - 翻车
categories: 翻车笔记
mathjax: true
abbrlink: 18992
date: 2019-02-22 20:41:02
layout:
---



> Siehst, Vater, du den Erlkönig nicht?
>
> Den Erlkönig mit Kron' und Schweif?

<!--more-->

### 懵逼的 题目

[[CTSC2007]数据备份Backup](https://lydsy.com/JudgeOnline/problem.php?id=1150)

[种树](https://lydsy.com/JudgeOnline/problem.php?id=2151)

[[POJ Challenge]生日礼物](https://lydsy.com/JudgeOnline/problem.php?id=2288)

### 扯淡的 题解

我头一次感觉到智商是我做题(抄题解)的瓶颈(遭了 是脑死亡的感觉) = =

ZKY学长让我们做的种树 不会 遂抄黄学长博客 发现黄学长的做题顺序是 $2288 \to 1150 \to 2151$可是为什么我觉着$2288$明明是最难的呢...~~当然你先做完最难的就可以秒后面的题了~~

三个题的思路都是用一个堆记录当前的所有决策 越优的决策越靠近堆顶, 每次做决策就是取堆顶元素 然后取出堆顶元素之后 再考虑怎么处理影响

#### 1150

就是选出$k$个间隔 让他们的总和最小 任意两个间隔不能共享一个点

把间隔化成点 就是选$k$个不相邻的点 让他们的点权和最小

所以我们每次取出堆顶元素的时候 就要把[堆顶的两边点权和 - 堆顶点权]加入到堆里供"不时之需"

```cpp
/**************************************************************
    Problem: 1150
    User: Cansult
    Language: C++
    Result: Accepted
    Time:640 ms
    Memory:10032 kb
****************************************************************/
 
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <queue>
#include <vector>
#define INF ((MAXN << 1) - 1)
#define LINF (100000000000000000ll)
#define MAXN (100000 + 5)
#define int LL 
#define LL long long
#define pii pair<int, int>
using namespace std;
struct cmp {
    bool operator () (const pii x, const pii y) { return x.first > y.first; }
};
int n, m, a[MAXN], nex[MAXN << 1], pre[MAXN << 1];
LL ta[MAXN << 1], ans;
bool del[MAXN << 1];
priority_queue<pii, vector<pii>, cmp> q;
main() {
    scanf("%lld%lld", &n, &m);
    scanf("%lld", &a[1]);
    for (int i = 2; i <= n; i++) scanf("%lld", &a[i]), ta[++ta[0]] = a[i] - a[i - 1];
    for (int i = 1; i <= ta[0]; i++) pre[i] = i - 1, nex[i] = i + 1, q.push(make_pair(ta[i], i));
    n = ta[0];
    pre[1] = nex[n] = INF, pre[INF] = n, nex[INF] = INF;
    ta[INF] = LINF;
    while (m) {
        while (del[q.top().second]) q.pop();
        int dqz = q.top().first, dqx = q.top().second;
        q.pop();
        ans += dqz;
        ta[++ta[0]] = ta[pre[dqx]] + ta[nex[dqx]] - dqz;
        del[dqx] = del[pre[dqx]] = del[nex[dqx]] = true;
        nex[ta[0]] = nex[nex[dqx]], pre[ta[0]] = pre[pre[dqx]];
        pre[nex[ta[0]]] = ta[0], nex[pre[ta[0]]] = ta[0];
        q.push(make_pair(ta[ta[0]], ta[0]));
        --m;
    }
    printf("%lld", ans);
    return 0;
}

```

#### 2151

和上面的问题差不多 无非就是转成了环形 并且求的是点权和最大

双向链表的边界处理一下 再把`cmp`函数的大于号方向换一下就行了

~~顺便提一下当时zky学长讲这题的时候被烜爷爷用DP+FFT秒了~~

```cpp
/**************************************************************
    Problem: 2151
    User: Cansult
    Language: C++
    Result: Accepted
    Time:472 ms
    Memory:9448 kb
****************************************************************/
 
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <queue>
#include <vector>
#define MAXN (200000 + 5)
#define pii pair<int, int>
using namespace std;
struct cmp {
    bool operator () (const pii x, const pii y) { return x.first < y.first; }
};
int n, m, ta[MAXN << 1], pre[MAXN << 1], nex[MAXN << 1], ans;
bool del[MAXN << 1];
priority_queue<pii, vector<pii>, cmp> q;
int main() {
    scanf("%d%d", &n, &m);
    if (m > n / 2) {
        puts("Error!");
        return 0;
    }
    for (int i = 1; i <= n; i++) scanf("%d", &ta[i]), pre[i] = i - 1, nex[i] = i + 1, q.push(make_pair(ta[i], i));
    pre[1] = n, nex[n] = 1;
    ta[0] = n; // 这个地方忘记没有用过ta[0]就忘给他赋值了 导致后面错了一片
    while (m) {
        while (q.size() && del[q.top().second]) q.pop();
        int dqz = q.top().first, dqx = q.top().second;
        q.pop();
        ans += dqz;
        ta[++ta[0]] = -dqz + ta[pre[dqx]] + ta[nex[dqx]];
        del[dqx] = del[pre[dqx]] = del[nex[dqx]] = true;
        pre[ta[0]] = pre[pre[dqx]], nex[ta[0]] = nex[nex[dqx]];
        nex[pre[ta[0]]] = ta[0], pre[nex[ta[0]]] = ta[0];
        q.push(make_pair(ta[ta[0]], ta[0]));
        --m;
    }
    printf("%d", ans);
    return 0;
}
```

#### 2288

这题绝对难度不是一个档次的好吧... = =

首先 我们要把整个序列合并 让同号的区间变成一个点(把他们的点权加起来) 把`0`都舍去(对没影响)

然后我们发现这个序列现在变得正负交错了 考虑如果正数的个数小于等于$m$就不用做了直接输出他们的和就可以了 现在的情况是正数的个数大于$m$

我们就有了两个决策: 

1. 扔掉几个正数 

2. 加入一些负数 让这个负数的两边的正数连成一个

这两个决策都会让我们选的数的个数减少$1$

考虑怎么表示出这两个决策和他们对答案的影响~~反正我想不出来~~: 把所有数加到堆里 按照绝对值从小到大排序

是不是很妙?

对于正数 绝对值小就代表对答案的贡献小 可以扔掉ta

对于负数 绝对值小就代表用这个负数把两边的正数连起来"损失"最小 于是就用这个负数来连接ta两边的正数

当然还有喜闻乐见的边界问题 边界上的负数是不能选的(选了也不会减少答案选择的块数) (当然正数是可以选的 (就相当于扔掉了))



说道选数 选出来我们要干什么呢 我们知道了负数是用来连接旁边的两块正数的 我们可以直接把这个负数和两边的正数合一起放到堆里

那正数呢 其实正数也是连接两边的两块负数 就想到与把两边的负数和这个正数合在一起变成一大段负数(为什么是负数呢 因为这个正数的绝对值比旁边的两个负数都要小嘛)

还有就是选一个数对答案的影响 正数就是直接减去这个正数的值 负数就是加上负数的值 然后就喜闻乐见的可以统一为减去堆顶的绝对值

到这就算做完了 反正我觉得考场上想出这种做法的人...大概已经可以归为神了

~~[当然gayge给我安利了一天他的线段树做法(虽然维护了18个值就跟一坨狗屎一样吧)(还有我很想吐槽他背景那个哒哒哒冒蓝火的加特林怎么办)](https://a-failure.github.io/2018/10/26/BZOJ2288-POJ-Challenge-%E7%94%9F%E6%97%A5%E7%A4%BC%E7%89%A9/)~~

```cpp
/**************************************************************
    Problem: 2288
    User: Cansult
    Language: C++
    Result: Accepted
    Time:124 ms
    Memory:4996 kb
****************************************************************/
 
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <queue>
#include <vector>
#define pii pair<int, int>
#define MAXN (100000 + 5)
#define INF ((MAXN << 1) - 1)
#define abs(x) (((x) > 0) ? (x) : (-(x)))
using namespace std;
struct cmp {
    bool operator () (const pii x, const pii y) { return abs(x.first) > abs(y.first); }
};
int n, m, a[MAXN], ta[MAXN << 1], pre[MAXN << 1], nex[MAXN << 1], ans, cntz;
bool del[MAXN << 1];
priority_queue<pii, vector<pii>, cmp> q;
int main() {
    scanf("%d%d", &n, &m);
    for (int i = 1; i <= n; i++) scanf("%d", &a[++a[0]]), a[0] -= (!a[a[0]]); // 刚刚忘记处理有0的情况
    n = a[0];
    int dq = a[1];
    for (int i = 2; i <= n; i++)
        if (a[i] * a[i - 1] > 0) dq += a[i];
        else {
            if (dq > 0) ans += dq, ++cntz;
            if (dq) ta[++ta[0]] = dq;
            dq = a[i];
        }
    if (dq > 0) ans += dq, ++cntz;
    if (dq) ta[++ta[0]] = dq;
    if (cntz <= m) {
        printf("%d", ans);
        return 0;
    }
    n = ta[0];
    for (int i = 1; i <= n; i++) pre[i] = i - 1, nex[i] = i + 1, q.push(make_pair(ta[i], i));
    pre[1] = pre[0] = 0, nex[n] = nex[INF] = INF;
    pre[INF] = n, nex[0] = 1;
    while (cntz > m) {
        while (del[q.top().second]) q.pop();
        int dqz = q.top().first, dqx = q.top().second;
        q.pop();
        if (pre[dqx] == 0 || nex[dqx] == INF) {
            if (dqz > 0) 
                ans -= dqz, --cntz; // cntz的修改写到if外面了
            del[dqx] = true;
            if (pre[dqx]) nex[pre[dqx]] = INF;
            else pre[nex[dqx]] = 0;
            continue;
        }
        ans -= abs(dqz);
        ta[++ta[0]] = dqz + ta[pre[dqx]] + ta[nex[dqx]];
        pre[ta[0]] = pre[pre[dqx]], nex[ta[0]] = nex[nex[dqx]];
        nex[pre[ta[0]]] = ta[0], pre[nex[ta[0]]] = ta[0];
        del[dqx] = del[pre[dqx]] = del[nex[dqx]] = true;
        q.push(make_pair(ta[ta[0]], ta[0]));
        --cntz;  // 这个地方一不小心减了两遍
    }
    printf("%d", ans);
    return 0;   
}
```



By 准备退役旅游的 Cansult