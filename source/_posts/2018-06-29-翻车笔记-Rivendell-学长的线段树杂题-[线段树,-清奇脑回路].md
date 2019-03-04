---
title: '翻车笔记 Rivendell 学长的线段树杂题 [线段树, 清奇脑回路]'
tags:
  - 线段树
  - 主席树
  - 清奇脑回路
categories: 翻车笔记
mathjax: true
abbrlink: 49219
date: 2018-06-29 15:52:27
layout:
---



寒假的时候讲的 现在才开始补...惭愧啊

<!--more-->

### [BZOJ 3333: 排队计划](https://www.lydsy.com/JudgeOnline/problem.php?id=3333)

我们发现, 你抽出后面的数排序后, **[取出来的数之间]就没有逆序对了**

然后我们又发现, 因为没取出来的都比取出来的数要大, 所以实际上原来 [取出来和没取出的数之间] 构成逆序对的地方现在还是逆序对, 之前后面比前面小的地方, 现在后面还是比前面小; 也就是**[取出来的数和没取出来的数之间]的逆序对数量不变**


我们考虑用树状数组找逆序对的过程: 找后面所有比他小的数的个数(或者前面比他大的数, 无所谓)的和

我们发现, 如果这个数被取出来了, 他后面就没有比他小的数了(排序后取出来的数比他大的一定在他后面, 没取出来的数比$a_p$都大, 肯定比取出来的所有数大)

我们计一个数$i$后面比他小的数的个数为$nxd_i$

那么我们只需要在他选出来的$p$后面, 取出所有比他小的数$i$, 然后在答案里减去$nxd_i$就行了

具体实现的话, 为了去重我们要把已经取出来的数都设为$\infty$, 防止被多次取出(因为已经排过序了)


所以代码的实现就是: 

- 初始答案为整个序列的逆序对个数$ans$
- 不断的在$p$的后面找比$p$小的数$i$(用线段树), 把$i$设成$\infty$, $ans = ans - nxd_i$, 直到$p$后面的数都比$a_p$大, 输出$ans$

```cpp
/**************************************************************
    Problem: 3333
    User: Cansult
    Language: C++
    Result: Accepted
    Time:8792 ms
    Memory:42236 kb
****************************************************************/
 
#include <iostream>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <algorithm>
#define MAXN (500000 + 5)
#define MAXM (500000 + 5)
#define INF (0x7fffffff)
#define lowbit(i) ((i) & (-(i)))
#define LS(dq) ((dq) << 1)
#define RS(dq) (((dq) << 1) | 1)
#define LL long long
using namespace std;
struct node
{
    int le, ri, minz, minwz;
}b[MAXN << 2];
struct bitnode
{
    int b[MAXN], n;
    void xg(int wz)
    {
        for (int i = wz; i <= n; i += lowbit(i))
            ++b[i];
    }
    int cx(int le, int ri)
    {
        int re = 0;
        for (int i = ri; i; i -= lowbit(i))
            re += b[i];
        for (int i = le - 1; i; i -= lowbit(i))
            re -= b[i];
        return re;
    }
    void init(int* a, int xn, LL* ans)
    {
        n = xn;
        int sora[MAXN];
        for (int i = 1; i <= n; i++)
            sora[i] = a[i];
        sort(sora + 1, sora + n + 1);
        sora[0] = unique(sora + 1, sora + n + 1) - sora - 1;
        for (int i = 1; i <= n; i++)
            a[i] = lower_bound(sora + 1, sora + sora[0] + 1, a[i]) - sora;
        for (int i = n; i >= 1; i--)
            ans[i] = cx(1, a[i] - 1), xg(a[i]);
    }
};
int n, m, a[MAXN];
LL xd[MAXN];
void init()
{
    bitnode qwq;
    qwq.init(a, n, xd);
}
node push_up(node ls, node rs)
{
    node re;
    re.le = ls.le, re.ri = rs.ri;
    if (ls.minz < rs.minz)
        re.minz = ls.minz, re.minwz = ls.minwz;
    else
        re.minz = rs.minz, re.minwz = rs.minwz;
    return re;
}
void js(int dq, int le, int ri)
{
    if (le == ri)
    {
        b[dq].le = le, b[dq].ri = ri;
        b[dq].minz = a[le];
        b[dq].minwz = le;
        return ;
    }
    int mi = (le + ri) >> 1;
    js(LS(dq), le, mi);
    js(RS(dq), mi + 1, ri);
    b[dq] = push_up(b[LS(dq)], b[RS(dq)]);
}
void xg(int dq, int wz, int zh)
{
    if (b[dq].le == b[dq].ri)
    {
        b[dq].minz = zh;
        return ;
    }
    int mi = (b[dq].le + b[dq].ri) >> 1;
    if (wz <= mi)
        xg(LS(dq), wz, zh);
    else
        xg(RS(dq), wz, zh);
    b[dq] = push_up(b[LS(dq)], b[RS(dq)]);
}
node cx(int dq, int le, int ri)
{
    if (b[dq].le == le && b[dq].ri == ri)
        return b[dq];
    int mi = (b[dq].le + b[dq].ri) >> 1;
    if (ri <= mi)
        return cx(LS(dq), le, ri);
    else if (le > mi)
        return cx(RS(dq), le, ri);
    else
        return push_up(cx(LS(dq), le, mi), cx(RS(dq), mi + 1, ri));
}
int main()
{
    scanf("%d%d", &n, &m);
    for (int i = 1; i <= n; i++)
        scanf("%d", &a[i]);
    init();
    js(1, 1, n);
    LL dans = 0;
    for (int i = 1; i <= n; i++)
        dans += xd[i];
    printf("%lld\n", dans);
    for (int i = 1, srp; i <= m; i++)
    {
        scanf("%d", &srp);
        while (1)
        {
            node qwq = cx(1, srp, n);
            if (qwq.minz > a[srp])
                break;
            xg(1, qwq.minwz, INF);
            dans -= xd[qwq.minwz];
        }
        printf("%lld\n", dans);
    }
    return 0;
}
```

### [Codechef FRBSUM](https://www.lydsy.com/JudgeOnline/problem.php?id=4299) && [[Fjoi 2016]神秘数](https://www.lydsy.com/JudgeOnline/problem.php?id=4408)

这题好神啊qwq

首先我们要知道一个显而易见的结论: 

> 我们给要求的区间排序, 如果前$i$个数的神秘数为$ans_i$, 那么: 
>
> 1. $a_{i+ 1} \le ans_i \to ans_{i + 1} = ans_i + a_{i + 1}$: 考虑把$a_i$放在"底下"(或者说放在"前面")
> 2. $a_{i + 1} > ans_i \to ans_{\text{整个区间}} = ans_i$: 考虑如果这个数自己就超过了$ans_i$, 那么之后的整个区间都不可能有数能到达$ans_i$了

想一想是不是这样的


那么, 我们就可以这样

- 先设一个$ans = 1$(因为$0$肯定能凑出来), 然后开始循环: 
- 在主席树中查找给定区间里所有不大于$ans$的数的和[^1], 记作$qwq$
- 如果$qwq$小于$ans$, 那么直接输出现在的$ans$: 因为所有不大于$ans$的数加起来都不能凑出$ans$, 而加入大于$ans$的数肯定也不可能正好是$ans$, 也就是这个区间里不可能凑出$ans$
- 如果$qwq$大于$ans$, 那么$ans = qwq + 1$: 考虑上面的结论, 我们加入的数(其实就是第一个结论, 但是一次加了多个数)都没有超过$ans$, 所以我们可以扩大$ans$到$ans + a_x + a_y + \cdots = qwq + 1$

感性理解一下就是: 

在上一轮循环, 我们用了一些$a$, 得到了一个$ans$
在这一轮循环里, 我们加入了一些$a$, 这些$a$都满足上面的第一个结论, 每一个$a_x$都可以让$ans$变成$ans + a_x$
我们一次加了好多的$a$, 每一个$a$都符合要求, 所以我们可以让$ans$扩大$\sum \text{所有被加进来(也就是比$ans$小的)}a$, 而之前的$ans$就是前面几轮中被加入的$a$, 所以新的$ans$就是所有比$ans$小的数的和了

因为如果要继续循环的话, $ans$一定比上一个$ans$的两倍还要大, 所以复杂度是$\mathrm O(n\lg ^2n)$的

```cpp
/**************************************************************
    Problem: 4408
    User: Cansult
    Language: C++
    Result: Accepted
    Time:2540 ms
    Memory:64968 kb
****************************************************************/
 
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define MAXN (100000 + 5)
#define INF (0x7fffffff)
using namespace std;
struct node
{
    int zh, ls, rs, le, ri;
}b[MAXN << 5];
int n, m, a[MAXN], sora[MAXN], cntb, root[MAXN];
void xg(int pre, int& dq, int le, int ri, int zh, int tz)
{
    dq = ++cntb;
    b[dq].le = le, b[dq].ri = ri;
    if (le == ri)
    {
        b[dq].zh = b[pre].zh + tz; 
        return ;
    }
    int mi = (le + ri) >> 1;
    if (zh <= mi)
        xg(b[pre].ls, b[dq].ls, le, mi, zh, tz), b[dq].rs = b[pre].rs;
    else
        xg(b[pre].rs, b[dq].rs, mi + 1, ri, zh, tz), b[dq].ls = b[pre].ls;
    b[dq].zh = b[b[dq].ls].zh + b[b[dq].rs].zh;
}
int cx(int ler, int rir, int le, int ri)
{
    if (!rir)
        return 0;
    if (b[rir].le == le && b[rir].ri == ri)
        return b[rir].zh - b[ler].zh;
    int mi = (b[rir].le + b[rir].ri) >> 1;
    if (ri <= mi)
        return cx(b[ler].ls, b[rir].ls, le, ri);
    else if (le > mi)
        return cx(b[ler].rs, b[rir].rs, le, ri);
    else
        return cx(b[ler].ls, b[rir].ls, le, mi) + cx(b[ler].rs, b[rir].rs, mi + 1, ri);
}
int main()
{
    scanf("%d", &n);
    for (int i = 1; i <= n; i++)
        scanf("%d", &a[i]), sora[i] = a[i];
    sort(sora + 1, sora + n + 1);
    sora[0] = unique(sora + 1, sora + n + 1) - sora - 1;
    for (int i = 1; i <= n; i++)
        a[i] = lower_bound(sora + 1, sora + sora[0] + 1, a[i]) - sora,
        xg(root[i - 1], root[i], 1, sora[sora[0]], a[i], sora[a[i]]);
    scanf("%d", &m);
    for (int i = 1, srl, srr; i <= m; i++)
    {
        scanf("%d%d", &srl, &srr);
        int ans = 1;
        while (true)
        {
            int tans = upper_bound(sora + 1, sora + sora[0] + 1, ans) - sora - 1, qwq = cx(root[srl - 1], root[srr], 1, tans);
            if (qwq < ans)
                break;
            ans = qwq + 1;
        }
        printf("%d\n", ans);
    }
    return 0;
}
```



By Cansult

[^1]: 其实就是在插入一个数的时候, 不是`b[dq].zh = b[pre].zh + 1`, 而是`b[dq].zh = b[pre].zh + zh`