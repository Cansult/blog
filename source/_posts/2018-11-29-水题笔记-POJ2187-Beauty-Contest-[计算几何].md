---
title: '水题笔记 POJ2187 Beauty Contest [计算几何]'
categories: 水题笔记
mathjax: true
tags:
  - 计算几何
  - 凸包
  - 旋转卡壳
abbrlink: 18830
date: 2018-12-03 16:25:20
layout:
---



作死开新坑...

<!--more-->

### 懵逼的 题目

[POJ又双叒叕倒闭了](https://www.luogu.org/problemnew/show/P1452)

### 沙茶的 代码

因为这题没让输出凸包所以就没有特判多点一线的情况...以后慢慢写吧...

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#include <vector>
#define DD double
#define pii pair<int, int>
#define pdd pair<DD, DD>
#define MAXN (50000 + 5)
using namespace std;
int n, chn;
pii a[MAXN], ch[MAXN];
int cross(pii x, pii y) { return x.first * y.second - x.second * y.first; }
pii minu(pii x, pii y) { return make_pair(x.first - y.first, x.second - y.second); }
int cxdis2(pii x) { return x.first * x.first + x.second * x.second; }
int mabs(int x) { return (x > 0) ? x : -x; }
int cxara(pii x, pii y, pii z) { return mabs(cross(minu(x, y), minu(y, z))); }
void cxch(int xn, pii* xa, int& xchn, pii* xch) {
    sort(xa + 1, xa + xn + 1);
    for (int i = 1; i <= n; i++) {
        while (xchn >= 2 && cross(minu(xch[xchn], xch[xchn - 1]), minu(xa[i], xch[xchn - 1])) <= 0)	--xchn;
        xch[++xchn] = xa[i];
    }
    int k = xchn;
    for (int i = n; i >= 1; i--) {
        while (xchn > k && cross(minu(xch[xchn], xch[xchn - 1]), minu(xa[i], xch[xchn - 1])) <= 0)	--xchn;
        xch[++xchn] = xa[i];
    }
    /*
    for (int i = 1; i <= xchn; i++)
        printf("%d %d\n", xa[i].first, xa[i].second);
    puts("");
    */
}
int cxld(int xchn, pii* xch) {
    if (xchn < 2)	return 0;
    if (xchn == 2)	return cxdis2(minu(xch[1], xch[2]));
    int dqmaxi = 1, ans = 0, cnt = 0;
    xch[xchn + 1] = xch[1];
    for (int i = 1; i <= xchn; i++) {
        while (cnt < 3 && cxara(xch[dqmaxi], xch[i], xch[i + 1]) <= cxara(xch[dqmaxi + 1], xch[i], xch[i + 1]))	dqmaxi = dqmaxi % xchn + 1, cnt += (dqmaxi == 1);
        ans = max(ans, cxdis2(minu(xch[dqmaxi], xch[i])));
        ans = max(ans, cxdis2(minu(xch[dqmaxi], xch[i + 1])));
    }
    return ans;
}
int main() {
    scanf("%d", &n);
    for (int i = 1; i <= n; i++)	scanf("%d%d", &a[i].first, &a[i].second);
    cxch(n, a, chn, ch);
    printf("%d", cxld(chn, ch));
    return 0;
}

```

By 准备退役旅游的Cansult