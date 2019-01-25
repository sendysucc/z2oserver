local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local crypt = require "skynet.crypt"
local snax = require "skynet.snax"
local socketdriver = require "skynet.socketdriver"

local connection = {}
local handler = {}
local CMD = {}
local authobj

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

function handler.open(source,conf)

end

function handler.message(fd,msg,sz)
    local c = assert(connection[fd])
    msg = crypt.base64decode(skynet.tostring(msg,sz))
    if c.secret then
        msg = crypt.desdecode(c.secret, msg)
    end
    
    if c.agent then
        local authobj = snax.bind(c.agent.handle,c.agent.type )
        local id = c.uid or fd
        local resp = authobj.req.message(id,msg,sz)
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
    local c = assert(connection[fd])
    c.agent = obj
    c.uid = uid
end

function CMD.closeclient(source,fd)
    closeclient(fd)
end

gateserver.start(handler)