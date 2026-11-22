---
title: '比赛总结 Codeforces Round 525 (Div. 2) [清奇脑回路, 交互, 乱搞, 贪心]'
tags:
  - 清奇脑回路
  - 交互
  - 乱搞
  - 贪心
categories: 比赛总结
mathjax: true
abbrlink: 6903
date: 2018-12-05 13:55:34
layout:
---



我吃枣要死在这个破学校

<!--more-->

### [D. Ehab and another another xor problem](https://codeforces.com/contest/1088/problem/D)

题意: 有两个正整数$a, b < 2^{30}$不告诉你, 你可以询问$62$次, 你每次给出两个正整数$c, d < 2^{30}$, 出题人会告诉你$a\oplus c$和$b \oplus d$的大小关系, 最后输出$a, b$的值

现在的D怎么越来越恶心了... 我讨厌交互题...

警告: 我的做法超复杂的...

比赛的时候想的方法是找到一个$d$使得$a = b \oplus  d$, 然后用$2^i$来异或$a$和左边比较大小, 小了就说明$a$的这个位置是一个$1$, 求出$a$来然后$b = a \oplus d$就完事了...然后在找$d$的时候懵逼了...

后来想了一天改成了这样...

设$a_i$为$a$的二进制位中以$i$为开头($i$递减)的后缀所代表的数, $a’_i$为$a_i$中后$i - 1$个位按位取反所代表的数. 如果$a_i > b_i$, $a'_i < b'_i$, 说明第$i$位的$a$和$b$相同, 我们可以用`1 << i`来`xor`$b_i$, 和$a_i$判断大小, 来得知这个位上的$a$和$b$是$0$还是$1$, 并且由$a'_i < b'_i$推出$a_{i - 1} > b_{i - 1}$. 当$a_i < b_i, a'_i > b'_i$时同理. 否则若$a_i > b_i, a'_i > b'_i$说明第$i$为的$a$和$b$不同, 且第$i$位上的$a$为$1$, $b$为$0$, 然后用掉一次询问来判断$a_{i - 1}$和$b_{i - 1}$的大小关系. $a_i < b_i, a'_i < b'_i$时同理

够复杂吧?

交互题调试超蛋疼的... 还好一遍过了...

改天参悟一下题解的写法...

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define LL long long
using namespace std;
int a, b, c, d, cmp0, cmp1, cmp2;
void solve() { // a == b xor d
	for (int i = 29; i >= 0; i--) {
		printf("? %d %d\n", (1 << i) - 1, d xor ((1 << i) - 1));
		fflush(stdout);
		scanf("%d", &cmp1);
		if (cmp0 >= 0 && cmp1 <= 0) {
			printf("? %d %d\n", 0, d xor (1 << i));
			fflush(stdout);
			scanf("%d", &cmp2);
			if (cmp2 > 0)	b += (1 << i), a += (1 << i);
			cmp0 = -cmp1;
		}
		else if (cmp0 >= 0 && cmp1 >= 0) {
			a += (1 << i), d += (1 << i);
			printf("? %d %d\n", 0, d);
			fflush(stdout);
			scanf("%d", &cmp0);
		}
		else if (cmp0 < 0 && cmp1 > 0) {
			printf("? %d %d\n", 1 << i, d);
			fflush(stdout);
			scanf("%d", &cmp2);
			if (cmp2 < 0)	a += (1 << i), b += (1 << i);
			cmp0 = -cmp1;
		}
		else if (cmp0 < 0 && cmp1 < 0) {
			b += (1 << i), d += (1 << i);
			printf("? %d %d\n", 0, d);
			fflush(stdout);
			scanf("%d", &cmp0);
		}
	}
	printf("! %d %d\n", a, b);
}
int main() {
	puts("? 0 0");
	fflush(stdout);
	scanf("%d", &cmp0);
	solve();
	return 0;
}

```

### [E. Ehab and a component choosing problem](https://codeforces.com/contest/1088/problem/E)

题意: 给一颗$n$个点的树, 每个点有整数点权$a_i$(可能为负), 找$k$(自己定 但必须大于$1$)个不重叠的联通块, 使找出的数的权值和与$k$的比值最大, 在此情况下最大化$k$

如果有$> 1$的权值, $k = 1$, 因为如果$k > 1$, 我们大可以把最大的那个拿出来作为单独的一个...用`ans[i]`代表这个节点的子树中能搞到的最大答案即可...特判一下多个联通块权值和相等的情况, 因为如果要分成多个联通块一定是中间的节点上权值和为负且非常小足以抵消另一边的贡献

这回E比D简单... = =

参悟了一发[一位不知名大爷](https://codeforces.com/contest/1088/submission/46639565)的代码感觉非常优雅 ~~虽然我还是这么丑~~

```cpp
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#define LL long long
#define MAXN (300000 + 5)
#define pii pair<int, int>
using namespace std;
struct edg {
	int from, to, next;
} b[MAXN << 1];
int g[MAXN], cntb, n, a[MAXN], maxk;
LL sum[MAXN], maxz;
bool cmp(int x, int y) { return x > y; }
void adn(int from, int to) {
	b[++cntb].next = g[from];
	b[cntb].from = from, b[cntb].to = to;
	g[from] = cntb;
}
void dfs(int dq, int fa, bool gg) {
	sum[dq] = a[dq];
	LL maxs = 0; 
	for (int i = g[dq]; i; i = b[i].next)
		if (b[i].to != fa)
			dfs(b[i].to, dq, gg), maxs += max(0ll, sum[b[i].to]);
	sum[dq] += maxs;
	if (gg) {
		if (maxz == sum[dq])
			++maxk, sum[dq] = 0;
	}
	else
		 maxz = max(maxz, sum[dq]);
}
int main() {
	scanf("%d", &n);
	bool neg = false;
	for (int i = 1; i <= n; i++)
		scanf("%d", &a[i]), neg = (neg || (a[i] > 0));
	for (int i = 1, srx, sry; i < n; i++)
		scanf("%d%d", &srx, &sry), adn(srx, sry), adn(sry, srx);
	if (!neg) {
		sort(a + 1, a + n + 1, cmp);
		for (int i = 1; i <= n; i++)
			if (a[i] != a[1]) {
				printf("%lld %d", (LL)a[1] * (i - 1), i - 1);
				return 0;
			}
		printf("%lld %d", (LL)a[1] * n, n);
		return 0;
	}
	dfs(1, 1, false), dfs(1, 1, true);
	printf("%lld %d", maxz * maxk, maxk);
	return 0;
}

```

### [F. Ehab and a weird weight formula](https://codeforces.com/contest/1088/problem/F)

题意: 不懂...他到底是给了我一棵树还是让我构造一棵树啊...?

```cpp

```

By 准备退役旅游的 Cansult