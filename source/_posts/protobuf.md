写 protobuf, 写点总结

<!--more-->

```proto
message Person {
  int32 id = 1;  // id 字段的编号是 1
  string name = 2; // name 字段的编号是 2
}
```

pb 的每个字段都有一个 tag, 其值为 `(filed_num << 3) + wire_type`, filed_num 就是 proto 里等号后面的数字

`wire_type` 有下面几种

| Wire Type | 描述                               | 适用的数据类型                                                           |
|-----------|------------------------------------|--------------------------------------------------------------------------|
| 0         | VARINT (变长整数)                  | `int32`, `int64`, `uint32`, `uint64`, `sint32`, `sint64`, `bool`, `enum` |
| 1         | FIXED64 (固定 64 位整数)           | `double`, `fixed64`, `sfixed64`                                          |
| 2         | LENGTH_DELIMITED (长度限定)        | `string`, `bytes`, 嵌套消息 (message), 打包重复字段                      |
| 3         | START_GROUP (分组开始，Protobuf 2) | 不适用, Protbuf3 已弃用                                                  |
| 4         | END_GROUP (分组结束，Protobuf 2)   | 不适用, Protbuf3 已弃用                                                  |
| 5         | FIXED32 (固定 32 位整数)           | `float`, `fixed32`, `sfixed32`                                           |
| 6         | 保留未使用                         | 保留                                                                     |
| 7         | 保留未使用                         | 保留                                                                     |

在 protobuf 中, tag 是通过下面的函数读出来的

```cpp
// parse_context.h
// Same as ParseVarint but only accept 5 bytes at most.
inline const char* ReadTag(const char* p, uint32_t* out,
                           uint32_t /*max_tag*/ = 0) {
  uint32_t res = static_cast<uint8_t>(p[0]);
  if (res < 128) {
    *out = res;
    return p + 1;
  }
  uint32_t second = static_cast<uint8_t>(p[1]);
  res += (second - 1) << 7;
  if (second < 128) {
    *out = res;
    return p + 2;
  }
  auto tmp = ReadTagFallback(p, res);
  *out = tmp.second;
  return tmp.first;
}

// parse_context.cc
std::pair<const char*, uint32_t> ReadTagFallback(const char* p, uint32_t res) {
  for (std::uint32_t i = 2; i < 5; i++) {
    uint32_t byte = static_cast<uint8_t>(p[i]);
    res += (byte - 1) << (7 * i);
    if (ABSL_PREDICT_TRUE(byte < 128)) {
      return {p + i + 1, res};
    }
  }
  return {nullptr, 0};
}
```

其中的 ReadTag 实际上就是读 variant, 每个字节的最高位为 `0` 代表当前字节是最后一个字节, 否则下个字节要读

`second` 算是某种小数据加速, 大于两个字节的数会调用 `ReadTagFallback` 来读, Tag 最多只有五个字节

`Tag & 7` 可以得到 `wire_type`, 当 `wire_type == 2` 时, 其长度是未确定, 且写在接下来的字节里的, 可以通过 `ReadSize` 读出来

```cpp
// parse_context.h
inline uint32_t ReadSize(const char** pp) {
  auto p = *pp;
  uint32_t res = static_cast<uint8_t>(p[0]);
  if (res < 128) {
    *pp = p + 1;
    return res;
  }
  auto x = ReadSizeFallback(p, res);
  *pp = x.first;
  return x.second;
}

// parse_context.cc
std::pair<const char*, int32_t> ReadSizeFallback(const char* p, uint32_t res) {
  for (std::uint32_t i = 1; i < 4; i++) {
    uint32_t byte = static_cast<uint8_t>(p[i]);
    res += (byte - 1) << (7 * i);
    if (ABSL_PREDICT_TRUE(byte < 128)) {
      return {p + i + 1, res};
    }
  }
  std::uint32_t byte = static_cast<uint8_t>(p[4]);
  if (ABSL_PREDICT_FALSE(byte >= 8)) return {nullptr, 0};  // size >= 2gb
  res += (byte - 1) << 28;
  // Protect against sign integer overflow in PushLimit. Limits are relative
  // to buffer ends and ptr could potential be kSlopBytes beyond a buffer end.
  // To protect against overflow we reject limits absurdly close to INT_MAX.
  if (ABSL_PREDICT_FALSE(res > INT_MAX - ParseContext::kSlopBytes)) {
    return {nullptr, 0};
  }
  return {p + 5, res};
}
```

可以看到与 `ReadTag` 基本一致, 都是读 variant, 长度最大为 2g

### Parse

有了这些知识我们就可以反序列化二进制 pb 了

```cpp
// Only call if at start of tag.
bool EpsCopyInputStream::ParseEndsInSlopRegion(const char* begin, int overrun,
                                               int depth) {
  constexpr int kSlopBytes = EpsCopyInputStream::kSlopBytes;
  ABSL_DCHECK_GE(overrun, 0);
  ABSL_DCHECK_LE(overrun, kSlopBytes);
  auto ptr = begin + overrun;
  auto end = begin + kSlopBytes;
  while (ptr < end) {
    uint32_t tag;
    ptr = ReadTag(ptr, &tag);
    if (ptr == nullptr || ptr > end) return false;
    // ending on 0 tag is allowed and is the major reason for the necessity of
    // this function.
    if (tag == 0) return true;
    switch (tag & 7) {
      case 0: {  // Varint
        uint64_t val;
        ptr = VarintParse(ptr, &val);
        if (ptr == nullptr) return false;
        break;
      }
      case 1: {  // fixed64
        ptr += 8;
        break;
      }
      case 2: {  // len delim
        int32_t size = ReadSize(&ptr);
        if (ptr == nullptr || size > end - ptr) return false;
        ptr += size;
        break;
      }
      case 3: {  // start group
        depth++;
        break;
      }
      case 4: {                    // end group
        if (--depth < 0) return true;  // We exit early
        break;
      }
      case 5: {  // fixed32
        ptr += 4;
        break;
      }
      default:
        return false;  // Unknown wireformat
    }
  }
  return false;
}
```

上面的函数是已知 end 位置的, 在实际解析的时候二进制串不一定是连续的, 可能会遇到解析时需要跳转到下一块二进制串的情况

protobuf 的设计会在不同块的二进制串头尾留有冗余, 保证读较短部分时的正确性

在解析长度不确定的的部分时, 需要用到 ReadString, 他可以在读到块结尾时自动跳转

```cpp
PROTOBUF_NODISCARD const char* ReadString(const char* ptr, int size,
                                          std::string* s) {
    if (size <= buffer_end_ + kSlopBytes - ptr) {
        s->assign(ptr, size);
        return ptr + size;
    }
    return ReadStringFallback(ptr, size, s);
}
PROTOBUF_NODISCARD const char* AppendString(const char* ptr, int size,
                                            std::string* s) {
    if (size <= buffer_end_ + kSlopBytes - ptr) {
        s->append(ptr, size);
        return ptr + size;
    }
    return AppendStringFallback(ptr, size, s);
}

const char* EpsCopyInputStream::ReadStringFallback(const char* ptr, int size,
                                                   std::string* str) {
    str->clear();
    if (PROTOBUF_PREDICT_TRUE(size <= buffer_end_ - ptr + limit_)) {
        // Reserve the string up to a static safe size. If strings are bigger than
        // this we proceed by growing the string as needed. This protects against
        // malicious payloads making protobuf hold on to a lot of memory.
        str->reserve(str->size() + std::min<int>(size, kSafeStringSize));
    }
    return AppendSize(ptr, size,
                      [str](const char* p, int s) { str->append(p, s); });
}

const char* EpsCopyInputStream::AppendStringFallback(const char* ptr, int size,
                                                     std::string* str) {
    if (PROTOBUF_PREDICT_TRUE(size <= buffer_end_ - ptr + limit_)) {
        // Reserve the string up to a static safe size. If strings are bigger than
        // this we proceed by growing the string as needed. This protects against
        // malicious payloads making protobuf hold on to a lot of memory.
        str->reserve(str->size() + std::min<int>(size, kSafeStringSize));
    }
    return AppendSize(ptr, size,
                      [str](const char* p, int s) { str->append(p, s); });
}

template <typename A>
const char* AppendSize(const char* ptr, int size, const A& append) {
    int chunk_size = buffer_end_ + kSlopBytes - ptr;
    do {
        GOOGLE_DCHECK(size > chunk_size);
        if (next_chunk_ == nullptr) return nullptr;
        append(ptr, chunk_size);
        ptr += chunk_size;
        size -= chunk_size;
        // TODO(gerbens) Next calls NextBuffer which generates buffers with
        // overlap and thus incurs cost of copying the slop regions. This is not
        // necessary for reading strings. We should just call Next buffers.
        if (limit_ <= kSlopBytes) return nullptr;
        ptr = Next();
        if (ptr == nullptr) return nullptr;  // passed the limit
        ptr += kSlopBytes;
        chunk_size = buffer_end_ + kSlopBytes - ptr;
    } while (size > chunk_size);
    append(ptr, size);
    return ptr + size;
}
```

可以看到 pb.cc 中的操作也是类似的, 只不过 pb.cc 中可以通过 proto 文件提前得知都有哪些 field 和他们的类型

```cpp
const char* HelloRequest::_InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) {
#define CHK_(x) if (PROTOBUF_PREDICT_FALSE(!(x))) goto failure
  while (!ctx->Done(&ptr)) {
    uint32_t tag;
    ptr = ::PROTOBUF_NAMESPACE_ID::internal::ReadTag(ptr, &tag);
    switch (tag >> 3) {
      // string name = 1;
      case 1:
        if (PROTOBUF_PREDICT_TRUE(static_cast<uint8_t>(tag) == 10)) {
          auto str = _internal_mutable_name();
          ptr = ::PROTOBUF_NAMESPACE_ID::internal::InlineGreedyStringParser(str, ptr, ctx);
          CHK_(::PROTOBUF_NAMESPACE_ID::internal::VerifyUTF8(str, "helloworld.HelloRequest.name"));
          CHK_(ptr);
        } else
          goto handle_unusual;
        continue;
      // string fuck = 2;
      case 2:
        if (PROTOBUF_PREDICT_TRUE(static_cast<uint8_t>(tag) == 18)) {
          auto str = _internal_mutable_fuck();
          ptr = ::PROTOBUF_NAMESPACE_ID::internal::InlineGreedyStringParser(str, ptr, ctx);
          CHK_(::PROTOBUF_NAMESPACE_ID::internal::VerifyUTF8(str, "helloworld.HelloRequest.fuck"));
          CHK_(ptr);
        } else
          goto handle_unusual;
        continue;
      default:
        goto handle_unusual;
    }  // switch
  handle_unusual:
    if ((tag == 0) || ((tag & 7) == 4)) {
      CHK_(ptr);
      ctx->SetLastTag(tag);
      goto message_done;
    }
    ptr = UnknownFieldParse(
        tag,
        _internal_metadata_.mutable_unknown_fields<::PROTOBUF_NAMESPACE_ID::UnknownFieldSet>(),
        ptr, ctx);
    CHK_(ptr != nullptr);
  }  // while
message_done:
  return ptr;
failure:
  ptr = nullptr;
  goto message_done;
#undef CHK_
}
```

```proto
syntax = "proto3";

option java_multiple_files = true;
option java_package = "io.grpc.examples.helloworld";
option java_outer_classname = "HelloWorldProto";
option objc_class_prefix = "HLW";
option go_package = "./;helloworld";

package helloworld;

// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
  string fuck = 2;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
  int32 count = 2;
}
```
