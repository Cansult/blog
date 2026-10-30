# brpc

## bthread

### work steal

IO 等阻塞操作调用 bthread 提供的指定接口时, 会在没准备好的情况下返回特定标志, 将当前的 bthread 放到 worker 的就绪队列;

就绪队列空的 worker 可以去其他 worker 的队列中偷取 bthread

### async call

IssueRPC 后直接返回, 

## rpc

### 安全保护 
