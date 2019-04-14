local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local crypt = require "skynet.crypt"
local snax = require "skynet.snax"
local socketdriver = require "skynet.socketdriver"

local connection = {}
local handler = {}
local CMD = {}
local authobj
local uid_fd = {}

local function sendmsg(fd,msg)
    local c = connection[fd]
    if c.secret then
        msg = crypt.desencode(secret,msg)
    end
    msg = crypt.base64encode(msg)
    local package = string.pack(">s2",msg)
    socketdriver.send(fd,package)
end

local function closeclient(fd)
    gateserver.closeclient(fd)
    connection[fd] = nil
end

--服务端监听socket建立成功后，会调用 handler.open 方法
function handler.open(source,conf)

end

function handler.message(fd,msg,sz)
    local c = assert(connection[fd])
    msg = crypt.base64decode(skynet.tostring(msg,sz))
    if c.secret then
        msg = crypt.desdecode(c.secret, msg)
    end
    
    if c.agent then
        local agent = snax.bind(c.agent.handle,c.agent.type )
        local id = c.uid or fd
        local resp = agent.req.message(id,msg,sz)
        if resp then
            sendmsg(fd,resp)
        end 
    end
end

function handler.connect(fd,addr)
    local c = {
        fd = fd,
        addr = string.match(addr,'(%d+%.%d+%.%d+%.%d+):%d+'),
        agent = authobj,
    }
    connection[fd] = c
    gateserver.openclient(fd)
end

function handler.disconnect(fd)
    local c = assert(connection[fd])
    if c.agent then
        local obj = snax.bind(c.agent.handle, c.agent.type)
        local id = c.uid or fd
        local ret = obj.req.disconnect(id)
        if uid_fd[id] then
            uid_fd[id] = nil
        end
        connection[fd] = nil
    end
end

function handler.error(fd,msg)

end

function handler.warning(fd,size)

end

function handler.command(cmd,source,...)
    local f = CMD[cmd]
    if f then
        f(source,...)
    end
end

function CMD.setauth(source,auth)
    authobj = auth
end

function CMD.setsecret(source,secret)

end

function CMD.forward(source,fd,obj,uid)
    local c = connection[fd]
    if not c then
        c = assert(connection[uid_fd[fd]])
    end
    c.agent = obj
    if uid then
        c.uid = uid
        uid_fd[uid] = fd
    end
end

function CMD.closeclient(source,fd)
    closeclient(fd)
end

function CMD.sendmsg(source,uids,msg)
    for k,uid in pairs(uids) do
        local fd = uid_fd[uid]
        if fd then
            sendmsg(fd,msg)
        end
    end
end

gateserver.start(handler)