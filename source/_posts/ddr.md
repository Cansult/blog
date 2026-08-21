
学下 ddr, 记录下

<!--more-->

**cell**: 一个电容, 一个三级管, 存储一个 bit

row: 一行 cell

word line: 这个 row 的控制线, 可以决定哪些行接入 bitline 

bitline: 一列 cell 的控制线

**bank**: word line $\times$ bit line 形成的 cell 矩阵

row buffer: bank 每次读取的时候会先激活一整个 row, 再取出需要的列

**bank group**: 一个芯片里共用芯片的 io routing 的 bank; 同一时间, 一个 bank group 中只能有一个 bank 输出数据

**dram 芯片**: 多个 bank group, 和一些乱七八糟的玩意

x\_: x4 x8 x16... 每个 dram 芯片提供多少 bit

**rank**: 内存控制器一次访问到的芯片组叫做一个 rank

beat: 每个芯片提供的 bit $\times$ 这个 rank 的芯片数量, 即一个 rank 一次读取的 bit 数

burst length: 一次 burst 读取, 读取多少次 beat

总线宽度: 等于一个 beat 的 bit 数; 一个时钟周期在上下沿分别读取两个 beat

sub channel: ddr5 后把一个 channel 拆成两部分, 两部分可以分别读不同地址的内存, 加速随机小内存的读取

burst: 一个 burst 内存读取就是 BL 次这样的读取; 相对分别进行 BL 次单次内存读取可以节约一些共用的部分, 比如找基地址和激活行的过程等

**dimm**: 内存条, 可以有多个 rank

缓存行: CPU 缓存失效就会读一整个缓存行
