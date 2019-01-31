# z2oServer
test

first try. 2019-1-19

gated 负责加密解密
auth 负责握手,登录以及注册等
登录成功则创建agent , 并将消息转发给hall
如果client进入游戏，则通知agent将 消息转发给game服务




2019-1-31:
    抽象出一个游戏基础的snax 服务,  在基础 snax 服务启动时, 将具体的游戏逻辑作为一个lua模块传给 snax 服务 ( 通过 snax 的 init 函数的 参数传入)

