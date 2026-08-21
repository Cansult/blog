---
title: 动态 AC 自动机
categories: 学习笔记
tags:
  - 数据结构
  - AC 自动机
abbrlink: 14038
date: 2026-03-11 18:47:10
---

一个有趣的问题, AC 能不能动态加减模板串?

<!--more-->

[论文](https://se.inf.ethz.ch/~meyer/publications/string/string_matching.pdf)

### 动态添加

添加一个新模式串对自动机 fail 边的影响可以分为两部分: 新插入字符串的部分和已存在的字符串的部分

- 新插入的部分: 直接构建即可

- 已存在的部分: 
    - 考虑哪些需要修改: 设新插入的字符串与原自动机最深的可复用节点为 $f$, 考虑 $f$ 之后的下一个字符 $p$; 只有 `fail[y] == f` 的 `y.trie_son[p]` (记为 `x`) 的 `fail[x]` 需要修改; 此轮修改完成后 $p$ 变为 $f$, 继续该过程; 正确性证明如下:
        - 考虑 `fail[x]` 代表的意义: 存在于 trie 树中, `x` 的最长后缀
        - 需要证明修改后 `fail` 仍满足其性质
        - 插入后 `fail[x]` 需要更新, 当且仅当 trie 中: 
            - `x` 代表的串可以拆分为 `str_a + trie_str[f] + 'p'` 的形式 (`trie_str[f] + 'p'` 是 `trie_str[x]` 的后缀) 
            - 且不存在节点代表 `str_b + trie_str[f] + 'p'` 的串满足 `str_b` 为 `str_a` 的后缀 (且是最长后缀)
        - trie 中一个字符串只会有一种表示, 因此若需要 `x` 满足该条件, 就一定需要 `y = str_a + trie_str[f]` 即 `fail[y] == f` 且 `y.trie_son[p] == x`, 即我们的修改条件

最坏情况为 $O(\sum_{n\in fail^{-1}}{descendants(n)}) \le \mathrm{size}(trie) \times \mathrm{height}(trie)$ 上界非常松, 在此场景中基本不会超过直接重构, 且最坏情况出现的概率较小


平时空间会略大, 因为要同时记录 fail 的头和尾, 但峰值空间小于重构方案

![](DACA.jpeg)

构造过程: 

```cpp
while (!q.empty()) {
    index_type now = q.front();
    q.pop();
    aca_nodes_[now].dfn = ++cntdfn;
    for (const auto& kv : aca_nodes_[now].son_index) {
        const char_type& c = kv.first;
        const index_type& son = kv.second;
        index_type fail_index = aca_nodes_[now].fail_index;
        while (fail_index && aca_nodes_[fail_index].son_index.find(c) == aca_nodes_[fail_index].son_index.end()) { 
            // 以深度为势能函数, 摊还复杂度是可以接受的
            fail_index = aca_nodes_[fail_index].fail_index;
        }
        fail_index = aca_nodes_[fail_index].son_index[c];
        aca_nodes_[son].fail_index = fail_index;

        aca_nodes_[son].match_nodes.insert(aca_nodes_[son].match_nodes.end(), aca_nodes_[fail_index].match_nodes.begin(), aca_nodes_[fail_index].match_nodes.end());

        q.push(son);
    }
}
```
