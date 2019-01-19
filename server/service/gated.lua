local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local crypt = require "skynet.crypt"

local connection = {}
local handler = {}
local CMD = {}
local authobj

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
        local resp = agent.req.rawmessage(msg,sz)
        if resp then
            
        end 
    end
end

function handle.connect(fd,addr)
    local c = {
        fd = fd,
        addr = addr,
        agent = authobj,
    }

    connection[fd] = c
    gateserver.openclient(fd)
end

function handle.disconnect(fd)

end

function handle.error(fd,msg)

end

function handle.warning(fd,size)

end

function CMD.command(cmd,source,...)
    local f = CMD[cmd]
    if f then
        f(source,fd,...)
    end
end

function CMD.setauth(source,auth)
    authobj = auth
end

gateserver.start(handler)