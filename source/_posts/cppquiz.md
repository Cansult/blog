做 [CppQuiz](https://cppquiz.org) ，总结一下错题

计数器：

## <font color=#b11d23>21 / 163</font> 

<!--more-->

### [313](https://cppquiz.org/quiz/question/313)

```cpp
#include <iostream>

void f(float &&) { std::cout << "f"; }
void f(int &&) { std::cout << "i"; }

template <typename... T>
void g(T &&... v)
{
    (f(v), ...);
}

int main()
{
    g(1.0f, 2);
}
```

右值引用本身是左值，但是在隐式转换后就变成了 prvalue

### [244](https://cppquiz.org/quiz/question/244)

```cpp
#include <iostream>

using namespace std;

template <typename T>
struct A {
    static_assert(false);
};

int main() {
    cout << 1;
}
```

与模版参数推导无关的 ill-form 会导致整个程序 ill-from ，是UB

### [250](https://cppquiz.org/quiz/question/250)

```cpp
#include<iostream>

template<typename T>
void foo(T...) {std::cout << 'A';}

template<typename... T>
void foo(T...) {std::cout << 'B';}

int main(){  
   foo(1); 
   foo(1,2);
}
```

上面那个是 C 风格的 `va_list` ，下面那个才是参数包

对于 `foo(1)`

两个都不需要隐式转换

如果推导 A 可以被传入推导 B 中，那么推导 A 是一个更特化的推导。如果分不出来，就是 ill-form

对于 `foo(1, 2)`

第一个函数需要将第二个参数隐式转换为 `...` ，而第二个不需要，所以第二个更好

### [148](https://cppquiz.org/quiz/question/148)

```cpp
#include <iostream>

volatile int a;

int main() {
  std::cout << (a + a);
}
```

读 volatile glvalue 有 side-effect 

顺序不确定的对同一个内存做有 side-effect 的访问是 UB

### [251](https://cppquiz.org/quiz/question/251)

```cpp
#include <iostream>

template<class T>
void f(T) { std::cout << 1; }

template<>
void f<>(int*) { std::cout << 2; }

template<class T>
void f(T*) { std::cout << 3; }

int main() {
    int *p = nullptr; 
    f( p );
}
```

`T*` 可以传入 `T` 中，反过来不行，所以 `T*` 更加特化

而重载决议先考虑模版，再考虑显式特化，所以模版函数 `f(T)` 的特化 `f<>(int*)` 不被考虑

### [242](https://cppquiz.org/quiz/question/242)

```cpp
#include <iostream>
#include <type_traits>

void g(int&) { std::cout << 'L'; }
void g(int&&) { std::cout << 'R'; }

template<typename T>
void f(T&& t) {
    if (std::is_same_v<T, int>) { std::cout << 1; } 
    if (std::is_same_v<T, int&>) { std::cout << 2; } 
    if (std::is_same_v<T, int&&>) { std::cout << 3; } 
    g(std::forward<T>(t));
}

int main() {
    f(42);
    int i = 0;
    f(i);
}
```

`42`: rvalue ，`T` 推导为 `int`

`i`: lvalue ，`T` 推导为 `int&`

### [184](https://cppquiz.org/quiz/question/184)

```cpp
#include <iostream>

struct Base {
  void f(int) { std::cout << "i"; }
};

struct Derived : Base {
  void f(double) { std::cout << "d"; }
};

int main() {
  Derived d;
  int i = 0;
  d.f(i);
}
```

派生类隐藏基类的同名函数

### [122](https://cppquiz.org/quiz/question/122)

```cpp
#include <iostream> 

typedef long long ll;

void foo(unsigned ll) {
    std::cout << "1";
}

void foo(unsigned long long) {
    std::cout << "2";
}

int main() {
    foo(2ull);
}
```

`ll` 会被优先解释为一个 `unsigned` 变量

有空看看[这个的3~4条](https://timsong-cpp.github.io/cppwp/n4659/dcl.spec)

### [217](https://cppquiz.org/quiz/question/217)

```cpp    
#include <iostream>

int main() {
    int i = 1;
    int const& a = i > 0 ? i : 1;
    i = 2;
    std::cout << i << a;
}
```

条件表达式的返回值的左右性取决于[这个的2~5条](https://timsong-cpp.github.io/cppwp/n4659/expr.cond)，本题中 `i` 是 lvalue ，`1` 是 prvalue ，返回值为 prvalue

### [335](https://cppquiz.org/quiz/question/335)

```cpp
#include <cstddef>
#include <iostream>

void f(void*) {
    std::cout << 1;
}

void f(std::nullptr_t) {
    std::cout << 2;
}

int main() {
    int* a{};

    f(a);
    f(nullptr);
    f(NULL);
}
```

`nullprr` 的类型是 `std::nullptr_t` 的 prvalue

但是 `NULL` 的定义并不确定，可以是 `int long std::nullptr_t` 想不到吧

### [261](https://cppquiz.org/quiz/question/261)

```cpp
#include <iostream>
#include <sstream>

int main() {
  std::stringstream ss("a");
  std::cout << ss.str();
  ss << "b";
  std::cout << ss.str();
}
```

`stringstream` 不传参数的情况下默认从开头开始，会覆盖原有数据

### [178](https://cppquiz.org/quiz/question/178)

```cpp
#include <iostream>

int main() {
 int a = 5,b = 2;
 std::cout << a+++++b;
}
```

对符号的识别是接受尽可能长的字符，即使可能导致剩下的符号无法识别

### [225](https://cppquiz.org/quiz/question/225)

```cpp
#include <iostream>

struct X {
    X() { std::cout << "1"; }
    X(const X &) { std::cout << "3"; }
    ~X() { std::cout << "2"; }

    void f() { std::cout << "4"; }

} object;

int main() {
    X(object);
    object.f();
}
```

“所有会被识别为声明的东西都会被识别为声明”

所以 `X(object)` 实际上声明了一个类型为 `X` 的 `object`, 而不是拷贝构造了一个临时变量

想不到吧

> An expression-statement with a function-style explicit type conversion as its leftmost subexpression can be indistinguishable from a declaration where the first declarator starts with a (. In those cases the statement is a declaration.

[src](https://timsong-cpp.github.io/cppwp/std23/stmt.ambig#1)


### [233](https://cppquiz.org/quiz/question/233)

```cpp
#include <type_traits>
#include <iostream>

using namespace std;

struct X {
    int f() const&&{
        return 0;
    }
};

int main() {
    auto ptr = &X::f;
    cout << is_same_v<decltype(ptr), int()>
         << is_same_v<decltype(ptr), int(X::*)()>;
}
```

返回值 参数列表 左右值引用修饰符 cv修饰符 异常 都是函数的一部分

### [131](https://cppquiz.org/quiz/question/131)

```cpp
#include <iostream>

class C {
public:
  explicit C(int) {
    std::cout << "i";
  }
  C(double) {
    std::cout << "d";
  }
};

int main() {
  C c1(7);
  C c2 = 7;
}
```

这个题其实挺蛋疼的, 也解释了做题的必要性, 有的东西光看了学了真不一定能搞明白; 甚至做题没做仔细没仔细看自己和答案的过程差在哪, 都可能把盲点放过去...因为过程错了结果说不定还是对的

比如我第一次做这个题的时候以为在考构造函数

其实是考初始化

我之前甚至都没注意到初始化这么个和吃饭喝水一样平常的东西

默认初始化不等于默认构造函数, 拷贝初始化不等于拷贝构造函数

简单来说就是下面这坨

![初始化](../pictures/2506061.png)

然后复制初始化只考虑转换构造函数 (没有 explicit 修饰的), 而直接初始化考虑

列表初始化分直接列表初始化（考虑 explicit 和非 explicit 构造函数）和复制列表初始化（考虑 explicit 和非 explicit 构造函数，但只能调用非 explicit 构造函数 (有点没懂, 那这里的考虑的意义是啥) ）

记吧, 没啥好说的

![直接初始化](../pictures/2506062.png)

![复制初始化](../pictures/2506063.png)

![列表初始化](../pictures/2506064.png)

还有一些乱七八糟的初始化

![其他初始化](../pictures/2506065.png)

然后在说下构造函数相关的

`c2` 作为复制初始化理论上是构造一个匿名对象然后拷贝或移动，但是在 C++17 后会保证被优化掉，实际上没有拷贝或移动或析构函数被调用 (C++11 14 可能被优化掉, 如果没有, 会优先调移动构造函数)

### [365](https://cppquiz.org/quiz/question/365)

```cpp
#include <iostream>

int main() {
  unsigned short zero = 0, one = 1;
  if (zero - one < zero)
    std::cout << "less";
  else
    std::cout << "more";
}
```

算数操作中，如果所有操作数都能被提升为 `int` 那么就都会被提升为 `int` ，无符号会被提升为 `unsigned int`

所以如果 `unsigned short` 的字节数小于 `int` 那么实际上相当于都是 `int` 运算

而在一些机器上 `unsigned short` 和 `int` 的字节数一样，会被提升为 `unsigned int` ，则会溢出

[整数提升](https://timsong-cpp.github.io/cppwp/n4659/expr#11.5)

[标准转换](https://timsong-cpp.github.io/cppwp/n4659/conv.prom#1)

[转换等级](https://timsong-cpp.github.io/cppwp/n4659/conv.rank)

这个东西似乎是为了符合 CPU 的整形运算器的字节长度而搞出来的

### [319](https://cppquiz.org/quiz/question/319)

```cpp
#include <iostream>

struct A {
    A() { std::cout << "a"; }

    void foo() { std::cout << "1"; }
};

struct B {
    B() { std::cout << "b"; }
    B(const A&) { std::cout << "B"; }

    void foo() { std::cout << "2"; }
};

int main()
{
    auto L = [](auto flag) -> auto {return flag ? A{} : B{};};
    L(true).foo();
    L(false).foo();
}
```

`decltype( ? : )` 的结果：如果后两个操作数有一个隐式转换，那么使用转换的结果作为返回的类型。

[规范](https://timsong-cpp.github.io/cppwp/n4659/expr.cond#4)

### [52](https://cppquiz.org/quiz/question/52)

```cpp
#include <iostream>

class A;

class B {
public:
  B() { std::cout << "B"; }
  friend B A::createB();
};

class A {
public:
  A() { std::cout << "A"; }

  B createB() { return B(); }
};

int main() {
  A a;
  B b = a.createB();
}
```

CE ，你需要先声明 `A::createB();`

### [350](https://cppquiz.org/quiz/question/350)

```cpp
#include<iostream>
#include<functional>
class Q{
    int v=0;
    public:
        Q(Q&&){
            std::cout << "M";
        }
        Q(const Q&){
            std::cout << "C";
        }
        Q(){
            std::cout << "D";
        }
        void change(){
            ++v;
        }
        void func(){
            std::cout << v;
        }
};
void takeQfunc(std::function<void(Q)> qfunc){
    Q q;
    q.func();
    qfunc(q);
    q.func();
}
int main(){
    takeQfunc([](Q&& q){
        q.change();
    });
    return 0;
}
```

`qfunc(q)` 实际上拷贝了一个 `q` ，然后绑定给了 `Q&& q` ，所以发生了一次拷贝，并且原本的 `q` 没有发生改变

当然如果直接把左值传入右值参数肯定是不行的，但是`function`就可以

```cpp
template<class R, class... ArgTypes>
class function<R(ArgTypes...)> {
(...)
R operator()(ArgTypes...) const;
(...)
}
```

模板推导把 `lambda` 的 `Q&&` 推导为了 `Q`

所以发生了一次拷贝 并且匿名变量传入了右值引用中

### [198](https://cppquiz.org/quiz/question/198)

```cpp
#include <iostream>

namespace A {
  extern "C" { int x; }
};

namespace B {
  extern "C" { int x; }
};

int A::x = 0;

int main() {
  std::cout << B::x;
  A::x=1;
  std::cout << B::x;
}
```

注意 `extern "C"` 和 `extern "C" {}` 的区别

```cpp
extern "C" int i;                   // declaration
extern "C" {
  int i;                            // definition
}
```

而在所有的 `extern "C"` 中，`namespace` 是[不起作用的](https://timsong-cpp.github.io/cppwp/n4659/dcl.link#6)

所以出现了重复定义

### [291](https://cppquiz.org/quiz/question/291)

```cpp
#include <iostream>

int _global = 1;

int main() {
  std::cout << _global;
}
```

是保留字 ub

> In addition, some identifiers are reserved for use by C++ implementations and shall not be used otherwise; no diagnostic is required.
>
>    Each identifier that contains a double underscore __ or begins with an underscore followed by an uppercase letter is reserved to the implementation for any use.
>
>    Each identifier that begins with an underscore is reserved to the implementation for use as a name in the global namespace.

### [130](https://cppquiz.org/quiz/question/130)

```cpp
#include <iostream>
using namespace std;

template<typename T>
void adl(T)
{
  cout << "T";
}

struct S
{
};

template<typename T>
void call_adl(T t)
{
  adl(S());
  adl(t);
}

void adl(S)
{
  cout << "S";
}

int main ()
{
  call_adl(S());
}
```

与模版参数相关的名字查找会被推迟到模板参数确定的地方，而名字查找只找之前的

### [289](https://cppquiz.org/quiz/question/289)

```cpp
#include <iostream>

void f(int a = []() { static int b = 1; return b++; }())
{
   std::cout << a;
}

int main()
{
   f();
   f();
}
```

默认参数是将参数压入栈中，而不是简单的编译期替换(?)，所以两次调用的lambda是相同的

### [239](https://cppquiz.org/quiz/question/249)

```cpp
#include <iostream>

using namespace std;

int main() {
    int a = '0';
    char const &b = a;
    cout << b;
    a++;
    cout << b;
}
```

引用只能指向相同类型或者派生类

不相关类型之间的引用建立会导致隐式类型转换，因此 `const char&` 实际上指向的是一个右值临时变量。

如果是指针的话可能就是要考虑大小端了吧

### [354](https://cppquiz.org/quiz/question/354)

```cpp
#include <cstdlib>
#include <iostream>

struct S {
    char s;
    S(char s): s{s} {}
    ~S() { std::cout << s; }
};

S a('a');

int main() {
    S b('b');
    std::exit(0);
}
```

`std::exit(0)` 有自己的[析构顺序](https://timsong-cpp.github.io/cppwp/n4659/support.start.term#9.1)

但是总之他**不管**自动变量的析构，这点好像还挺要命的

### [186](cppquiz.org/quiz/question/186)

```cpp
#include <iostream>
#include <typeinfo>

void takes_pointer(int* pointer) {
  if (typeid(pointer) == typeid(int[])) std::cout << 'a';
  if (typeid(pointer) == typeid(int*)) std::cout << 'p';
}

void takes_array(int array[]) {
  if (typeid(array) == typeid(int[])) std::cout << 'a';
  if (typeid(array) == typeid(int*)) std::cout << 'p';
}

int main() {
  int* pointer = nullptr;
  int array[1];

  takes_pointer(array);
  takes_array(pointer);

  std::cout << (typeid(int*) == typeid(int[]));
}
```

C++对数组参数的处理感觉有点傻逼

`int[]` 的类型是有一个 `int` 的数组

数组传入时会被退化为一个纯右值的指针

而 `int[]` 作为函数参数时，会在**确定每个参数的类型之后**，变为 `int*` 

### [159](https://cppquiz.org/quiz/question/159)

```cpp
#include <iostream>

int i;

void f(int x) {
    std::cout << x << i;
}

int main() {
    i = 3;
    f(i++);
}
```

函数调用是一个序列化点

所有与参数相关的数值计算和负作用都会在调用之前完成

### [208](https://cppquiz.org/quiz/question/208)

```cpp
#include <iostream>
#include <map>
using namespace std;

bool default_constructed = false;
bool constructed = false;
bool assigned = false;

class C {
public:
    C() { default_constructed = true; }
    C(int) { constructed = true; }
    C& operator=(const C&) { assigned = true; return *this;}
};

int main() {
    map<int, C> m;
    m[7] = C(1);

    cout << default_constructed << constructed << assigned;
}
```

`map` 在用 `[]` 访问不存在的key时会先`insert`一个，哪怕待会就赋值了

### [312](https://cppquiz.org/quiz/question/312)

```cpp
#include <iostream>

class A {};

class B {
public:
    int x = 0;
};

class C : public A, B {};

struct D : private A, B {};


int main()
{
    C c;
    c.x = 3;

    D d;
    d.x = 3;

    std::cout << c.x << d.x;
}
```

没想到吧 继承的可见性修饰符并不对逗号后面的生效

但是struct默认是公有继承 class默认是私有继承

所以其实ce的是`c.x = 3`这句

### [1](https://cppquiz.org/quiz/question/1)

```cpp
#include <iostream>

template <class T> void f(T &i) { std::cout << 1; }

template <> void f(const int &i) { std::cout << 2; }

int main() {
  int i = 42;
  f(i);
}
```

对包含模板函数的重载决议步骤如下

1. 对所有模板函数做类型推导. 本例中 `T` 被推导为 `int`, 第一个函数的形参为 `int &i`
2. 将推到成功的模板函数加入候选函数集合中
3. 将所有同名非模板函数加入候选函数集合中
4. 对候选函数做重载决议

在其他条件都相同的情况下对于引用而言, 带有 c-v 修饰符的模板会比不带的更特化(也很好理解, `const int&` 能接受 `const int` 而 `int&` 不行), 因此重载决议挑选了第一个函数


### [113](https://cppquiz.org/quiz/question/113)

```cpp
#include <iostream>

template<typename T>
void f(T) {
    std::cout << 1;
}

template<>
void f(int) {
    std::cout << 2;
}

void f(int) {
    std::cout << 3;
}

int main() {
    f(0.0);
    f(0);
    f<>(0);
}
```

### [228](https://cppquiz.org/quiz/question/228)

```cpp
template <typename ...Ts>
struct X {
  X(Ts ...args) : Var(0, args...) {}
  int Var;
};

int main() {
  X<> x;
}
```

如果一个可变参数模板的每一个合法特化, 其模板参数包都必须为空, 那么程序非良构, 因此产生了一个 UB

### [375](https://cppquiz.org/quiz/question/375)

```cpp
#include <iostream>
#include <utility>

struct A {
  A() = default;
  A(const A &a) { std::cout << '1'; }
  A(A &&a) { std::cout << '2'; }
};

A a;

int main() {
  [a = std::move(a)]() {
    [a = std::move(a)]() {};
  }();
}
```

lambda 的按值捕获需要把 lambda 声明为 `mutable` 才能修改捕获的变量

否则 lambda 的 `operator()` 是 `const` 的
