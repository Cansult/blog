---
title: '比赛总结 38th Petrozavodsk Programming Camp, Winter 2020 Day5'
tags:
  - 数论
categories: 比赛总结
mathjax: true
abbrlink: 43802
date: 2020-10-05 19:52:00
layout:
---



是人是鬼都在秀 只有宽嫂在挨揍

我最擅长的事原来是坑队友

<!--more-->

[题目](../pictures/200202.pdf)

[英文题解](../pictures/200202-tutorial.pdf)

### A

题意: 给$n \le 10^{11}$个整数从$1$到$n$, 如果两个数的$\gcd$大于$1$, 则他们两个可以合并为一组, 问最后最少的组数

设$D(n) = \{x\mid[(x为质数) \and (x > \frac{n}{2})]\or(x = 1)\}$ 从定义可知, $D(n)$里的数是不会被任何数合并的

下面我们来证明$R(n) = \{1, 2 , ... , n\} \setminus D(n)$中的数都是可以两两配对的(当$|R(n)|$为偶数)

设$f(x)$为$x$的最大质因数, 把$R(n)$中的数按照最大质因数分组, 对于有偶数个元素的组, 他们之间可以两两配对; 对于有奇数个元素的组, 一定会有一个数是$2f(x)$ (因为取遍$1$了到$n$, 且$2f(x)$一定是个合数), 把这个数挑出来, 剩下的两两配对; 而如果$|R(n)|$为偶数, 奇数元素个数组的个数一定是偶数, 所以会有偶数个$2f(x)$可以两两配对;

当然如果$|R(n)|$是奇数那就只能随便扔一个了... `= =`

好, 现在的问题就转化为了求$|D(n)|$, 求出它我们就可以求出$ans = \lfloor \frac{n - |D(n)|}{2}\rfloor$, 我们需要求出某个区间内质数的个数, 区间可能达到$10^{11}$, 毛子的官方题解是怎么做的呢

分段打表(不愧是你)

在本地预处理出`f[d], d = 10000`, `f[i]`代表$[(i - 1) \times 10^7, i \times 10^7)$间的质数个数, 然后搞搞就出来了

草

```cpp
// 咕咕咕咕
```

### B

开局不知道为啥我莫名自信觉得这玩意能二分

样例WA了之后反思了一下, 发现我不会组合数

去翻了一下组合数的性质, 发现有个lucas定理好像挺有意思 
$$
\binom{n}{m} \!\!\! \mod p = \binom{\lfloor \frac{n}{p}\rfloor}{\lfloor \frac{m}{p}\rfloor } \cdot \binom{n\!\! \mod p}{m\!\!\mod p}\!\!\! \mod p
$$
在这个题里, 我们只用到了$p=2$的情况, 要求$\binom{n}{m}\!\!\!\!\mod\!2$, 我们可以不断的给$n$和$m$除以$2$, 只关注等号右边第二个组合数, 当$n$为偶数且$m$为奇数时, 它的值为$0$, 也就是说原始的$\binom{n}{m} \!\equiv 0\mod \!2$

然后我就写了, 然后我就WA了, 然后我就发现我不会统计有多少个数满足[至少有一个位是1, 且在这一位上当前的数是0], 然后队友就秒了

设`f[i]`是二进制意义上的前缀和, 他的值是"`i`上是1的位上可以是1, 其他位都是0的数"的个数

前缀和求一波, 然后直接统计`sum{f[a[i]]}`就行了

```cpp
// 我的(错的)
// lucas过程中 当有一个m为奇数, n为偶数, 结果就是偶数, 否则为奇数
// n所有为0的位上m都必须为0

#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define MAXN (1000000)
#define LL long long
using namespace std;
int n, a[MAXN + 5], num[MAXN + 5], f[30];
LL ans;
inline void add(int x, int tim) {
    int nx = 0;
    while ((!(x & 1)) && x) x >>= 1, ++nx;
    if (x) f[nx] += tim;
}
inline int enq(int x) {
    int nx = 0, re = 0;
    while (x) {
        if (!(x & 1)) re += f[nx];
        x >>= 1;
        ++nx;
    }
    return re;
}
int main() {
    int z;
    scanf("%d", &z);
    while (z--) {
        memset(num, 0, sizeof(num));
        memset(f, 0, sizeof(f));
        ans = 0;
        scanf("%d", &n);
        for (int i = 1; i <= n; i++)
            scanf("%d", &a[i]), ++num[a[i]];
        sort(a + 1, a + n + 1);
        a[0] = unique(a + 1, a + n + 1) - a - 1;
        int nown = 0;
        for (int i = 1; i <= a[0]; i++) {
            add(a[i], num[a[i]]);
            nown += num[a[i]];
            ans += (LL)(nown - enq(a[i])) * num[a[i]];;
        }
        printf("%lld\n", ans);
    }
    return 0;
}
```



```cpp
// 孟队的
#include<bits\stdc++.h>
#include<iostream>
#define ll long long
#define maxn 1000001
#define maxb 20
using namespace std;
const ll maxnum=(1<<maxb);
ll ans;
ll arr[maxn];
ll f[maxnum];
ll t;
ll n;
void init()
{
    for(int i=0;i<maxnum;i++)
    {
        f[i]=0;
    }
    ans=0;
}
int main()
{
    scanf("%lld",&t);
    while(t--)
    {
        scanf("%lld",&n);
        init();
        for(int i=0;i<n;i++)
        {
            scanf("%lld",&arr[i]);
            f[arr[i]]++;
        }
        for(int i=0;i<maxb;i++)
        {
            for(int j=0;j<maxnum;j++)
            {
                if(j&(1<<i))
                {
                    f[j]+=f[j^(1<<i)];
                }
                else
                {
                    continue;
                }
            }
        }
        for(int i=0;i<n;i++)
        {
            ans+=f[arr[i]];
        }
        printf("%lld\n",ans);
    }
}
```

### C

咕

By Cansult