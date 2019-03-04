---
title: '比赛总结 Dwango Programming Contest V [清奇脑回路, 乱搞]'
tags:
  - 清奇脑回路
  - 乱搞
categories: 比赛总结
mathjax: true
abbrlink: 12769
date: 2018-11-27 19:14:12
layout:
---



菜的真实

<!--more-->

### [C - k-DMC](https://dwacon5th-prelims.contest.atcoder.jp/tasks/dwacon5th_prelims_c)

给$Q$个$k$, 对于每个$k_i$, 回答在程序初始给定的长度为$N$的字符串$S$中: 有多少个三元组$(a, b, c)$ 满足$S[a] = D, S[b] = M, S[c] = C$并且$c - a < k_i$; $N \le 10^6, Q \le 75$, 要求$NQ$做法

> 我(不确定这题$NQ$能不能过): Asia啊 这题复杂度多少啊
>  Asia: 这题(单次询问)复杂度线性的(注意句式为省略句)
> 我: ????
> Asia: 这是基础操作啊
> 我: ?????????(吓傻跪烂.jpg)

~~迫真线性~~ 

过于真实

对于每一个询问$k_i$, 遍历$S$, 遇到一个$M$就入队加入贡献, 遇到$C$就把不合法的$M$出队, 去掉不合法贡献, 计算当前队列的合法贡献

贡献: 先做一个前缀和数组`fr[i]`代表前`i`个字符中$D$的个数, 当前队列能对$M$产生的贡献为[队列中所有$M$位置的`fr` - $C$的下标减去$k_i$所在的位置的`fr` $\times$ 队列元素个数], 所以入队的时候加上当前位置的`fr`即可

注意不要在减`k`的时候下标越界

```cpp
#include <iostream>
#include <cstring>
#include <queue>
#define LL long long
#define MAXN (1000000 + 5)
using namespace std;
int n;
LL fr[MAXN];
char s[MAXN];
void solve(int k) {
	LL dqd = 0, ans = 0;
	queue<int> q;
	for (int i = 1; i <= n; i++) {
		if (s[i] == 'M')	q.push(i), dqd += fr[i];
		if (s[i] == 'C') {
			while (!q.empty() && i - q.front() >= k)
				dqd -= fr[q.front()], q.pop();
			ans += dqd - fr[max(0, i - k)] * q.size(); // 这个地方要小心越界
		}
	}
	printf("%lld\n", ans);
}
int main() {
	scanf("%d", &n);
	scanf("%s", s + 1);
	for (int i = 1; i <= n; i++)
		fr[i] = fr[i - 1] + (s[i] == 'D');
	int q;
	scanf("%d", &q);
	for (int i = 1, srq; i <= q; i++)
		scanf("%d", &srq), solve(srq);
	return 0;
}

```

### [D - Square Rotation](https://dwacon5th-prelims.contest.atcoder.jp/tasks/dwacon5th_prelims_d)

我怎么...只会搜索啊...

```cpp

```

### [E - Cyclic GCDs](https://dwacon5th-prelims.contest.atcoder.jp/tasks/dwacon5th_prelims_e)

我怎么...读不懂题啊...

```cpp

```

By 准备退役旅游的Cansult