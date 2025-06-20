写点 restrict 相关的东西

C++ 真的太有意思了

<!--more-->

```cpp
int x =  1 ;

// In C
float *fp = (float*)&x ;  // Not a valid aliasing

// In C++
float *fp = reinterpret_cast<float*>(&x) ;  // Not a valid aliasing

printf( "%f\n", *fp );
```

哈哈, 想不到吧, 这是个ub

简单来说, 编译期会认为两个不 "相似" 的指针不会指向同一个地址, 并依照这个信息做优化

具体的编译选项是 `-fstrict-aliasing` 和 `-Wstrict-aliasing` 在 O2 以上默认开启

据说不开这个优化的 C 打不过 Fortran, 所以还是得留意一下 (不开 O3 写什么 C++ 呢)

### 相似

简单来说相似基本上就是

- 有 cv 限定的版本
- 有无符号的版本
- 有这个类型的成员变量的 struct class union
- 基类
- char 和 std::byte 对所有类型都相似 (注意 `char8_t` 不是 `char`  而是一种特殊的类型; 就是为了避免编译器不敢优化而诞生的; [参考](https://www.zhihu.com/question/1904806645999047234/answer/1905396078708228989))

编译器会认为这些类型可能指向同一个指针, 避免错误的优化

```cpp
// 以下，在C中合法，在C++中未定义（因为没有经过 placement new）
void *p = malloc(sizeof(float));
float f = 1.0f;
memcpy( p, &f, sizeof(float));  // Effective type of *p is float in C
                                // Or
float *fp = p;
fp = 1.0f;                      // Effective type of *p is float in C
```

以及 C++ 认为类型应该初始化后才能被使用

```cpp
float *fp = new (p) float{1.0f} ;   // Dynamic type of *p is now float
```

### 来点反例

1

```cpp
int foo( float *f, int *i ) { 
    *i = 1;
    *f = 0.f;

   return *i;
}

int main() {
    int x = 0;

    std::cout << x << "\n";   // Expect 0，Output 0
    x = foo((float*)(&x), &x);
    std::cout << x << "\n";   // Expect 0, But Output 1
}
```

2.

```cpp
#include <stdio.h>
#include <stdint.h>

static inline void Store128(void *dst, const void *src) {
	const uint8_t *s = (const uint8_t*)src;
	uint8_t *d = (uint8_t*)dst;
	*(uint32_t*)(d + 0) = *(const uint32_t*)(s + 0);
	*(uint32_t*)(d + 4) = *(const uint32_t*)(s + 4);
	*(uint32_t*)(d + 8) = *(const uint32_t*)(s + 8);
	*(uint32_t*)(d + 12) = *(const uint32_t*)(s + 12);
}

int main(void)
{
	float A[4] = {1, 2, 3, 4};
	float B[4] = {5, 6, 7, 8};

	Store128(B, A);

	for (int i = 0; i < 4; i++) 
		printf("%f\n", B[i]);

	return 0;
}

/*
gcc -O2 output:
0.000000
0.000000
0.000000
0.000000

这个就牛逼了, gcc 认为 uint32_t* 不可能修改 float 变量, 直接把 Store128 这个函数给优化了
至于 B 为什么是未定义的, 从 O1 的汇编结果可以看出 为了优化, B 的值实际上是在内联后的 Store128 中存储的, 优化掉 Store128 之后自然就是未定义的了....
*/
```

3.

```cpp
#include <iostream>
#include <iomanip>
#include <stdint.h>

struct T{
   uint8_t* target;
   char* source;
   void unpack3bit( int size);
};

void T::unpack3bit(int size) {
        while(size > 0){
           uint64_t t = *reinterpret_cast<uint64_t*>(source);
        //    uint8_t* target = this->target; // << ptr cached in local variable
        // 不加这个缓存的话, 编译器认为 this 的类型和 uint8_t 即 unsigned char 是相似的, 每次改变 this->target 都需要重新读取一次内存以确定 this 指向的内存没有改变, target 还是那个 target; 导致性能下降
           target[0] = t & 0x7;
           target[1] = (t >> 3) & 0x7;
           target[2] = (t >> 6) & 0x7;
           target[3] = (t >> 9) & 0x7;
           target[4] = (t >> 12) & 0x7;
           target[5] = (t >> 15) & 0x7;
           target[6] = (t >> 18) & 0x7;
           target[7] = (t >> 21) & 0x7;
           target[8] = (t >> 24) & 0x7;
           target[9] = (t >> 27) & 0x7;
           target[10] = (t >> 30) & 0x7;
           target[11] = (t >> 33) & 0x7;
           target[12] = (t >> 36) & 0x7;
           target[13] = (t >> 39) & 0x7;
           target[14] = (t >> 42) & 0x7;
           target[15] = (t >> 45) & 0x7;
           source+=6;
           size-=6;
           target+=16;
        }
}

void unpack3bit(uint8_t* target, char* source, int size) {
   while(size > 0){
      uint64_t t = *reinterpret_cast<uint64_t*>(source);
      target[0] = t & 0x7;
      target[1] = (t >> 3) & 0x7;
      target[2] = (t >> 6) & 0x7;
      target[3] = (t >> 9) & 0x7;
      target[4] = (t >> 12) & 0x7;
      target[5] = (t >> 15) & 0x7;
      target[6] = (t >> 18) & 0x7;
      target[7] = (t >> 21) & 0x7;
      target[8] = (t >> 24) & 0x7;
      target[9] = (t >> 27) & 0x7;
      target[10] = (t >> 30) & 0x7;
      target[11] = (t >> 33) & 0x7;
      target[12] = (t >> 36) & 0x7;
      target[13] = (t >> 39) & 0x7;
      target[14] = (t >> 42) & 0x7;
      target[15] = (t >> 45) & 0x7;
      source+=6;
      size-=6;
      target+=16;
   }
}
```

从这个例子看, 由于[现代计算机并不是更快的 PDP-11](https://queue.acm.org/detail.cfm?id=3212479), 较小的内存拷贝的效率问题比起核间、指令间的同步简直是九牛一毛

### 使用姿势

1. `memcpy / std::bit_cast`

现代计算机的内存拷贝效率也许并不像大 O 记号显示的那么恐怖, 该用就用

```cpp
double foo(double x) { return x; }

// 假设 len 是 sizeof(double) 的整数倍
double bar(unsigned char *p, size_t len) {
    double result = 0.0;

    for (size_t index = 0; index < len; index += sizeof(double)) {
        double ui;
        memcpy(&ui, &p[index], sizeof(double)); // right
        // double ui = *(double*)(&p[index]); -> ub
        result += foo(ui);
    }

    return result;
}
```

2. `__restrict__`

这个关键字会提示编译期这两个指针即使是相似的, 也不会指向同一片内存

```cpp
int add(int* __restrict__ a, int* __restrict__ b)
{
    *a = 10;
    *b = 12;
    return *a + *b;
}
```

```asm
add(int*, int*):
        mov     DWORD PTR [rdi], 10
        mov     eax, 22
        mov     DWORD PTR [rsi], 12
        ret
```

3. `-fno-strict-aliasing`

linux 内核就加这个; 但是听说 C 一开始就是少了这个优化才打不过 Fortran 

其实看到这可以再去回顾一下那些个 `cast` 分别是干什么的

此外使用 `reinterpret_cast` 从小尺寸类型到大尺寸类型转换还需要注意内存对齐的问题


### 参考

[严格别名（Strict Aliasing）规则是什么，编译器为什么不做我想做的事？](https://zhuanlan.zhihu.com/p/595286568)

