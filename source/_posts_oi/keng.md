1. 变量默认都是 `extern` 的 常量不是，所以在需要显式声明 `extern const bool A = 0;`，才能在其他文件里 `extern const bool A;` [defination and declaration](https://timsong-cpp.github.io/cppwp/basic.def#example-1)

```cpp
// In namespace scope or global scope.
int i; // extern by default
const int ci; // static by default
extern const int eci; // explicitly extern
static int si; // explicitly static

// The same goes for functions (but there are no const functions).
int f(); // extern by default
static int sf(); // explicitly static 
```


