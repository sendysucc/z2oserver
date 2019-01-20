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

function handler.open(source,conf)

end

function handler.message(fd,msg,sz)
    local c = assert(connection[fd])
    if c.secret then
        msg = crypt.desdecode(c.secret, crypt.base64decode(skynet.tostring(msg,sz)))
    else
        msg = crypt.base64decode(skynet.tostring(msg,sz))
    end
    
    if c.agent then
        local authobj = snax.bind(c.agent.handle,"auth")
        local resp = authobj.req.message(fd,msg,sz)
        if resp then
            sendmsg(fd,resp)
        end 
    end
end

function handler.connect(fd,addr)
    local c = {
        fd = fd,
        addr = addr,
        agent = authobj,
    }

    connection[fd] = c
    gateserver.openclient(fd)
end

function handler.disconnect(fd)

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

function CMD.forward(source,fd,obj)
    local c = assert(connection[fd])
    c.agent = obj
end

gateserver.start(handler)