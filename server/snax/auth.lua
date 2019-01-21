local skynet = require "skynet"
local snax = require "skynet.snax"
local loadproto = require "loadproto"
local sproto = require "sproto"
local crypt = require "skynet.crypt"
local errs = require "errorcodes"

local sp_host
local sp_request
local REQUEST = {}
local RESPONSE = {}

local clients = {}

--[[
    主动关闭客户端连接
]]
local function close_client(fd)
    local c = clients[fd]
    if c then
        local addr = skynet.queryservice("gated")
        skynet.send(addr,"lua","closeclient",fd)
        clients[fd] = nil
    end
end

local function clear_client(fd)
    local c = clients[fd]
    if c then
        clients[fd] = nil
    end
end

local function genverifycode()
    return math.random(0,9) .. math.random(0,9) .. math.random(0,9) .. math.random(0,9)
end

function init(...)
    sp_host = sproto.new( loadproto.getprotobin("./protocol/auth_c2s.spt") ):host "package"
    sp_request = sp_host:attach(sproto.new( loadproto.getprotobin("./protocol/auth_s2c.spt") ))
end

function response.message(fd,msg,sz)
    local msgtype, msgname, args , response = sp_host:dispatch(msg,sz)
    if msgtype == 'REQUEST' then
        local f = REQUEST[msgname]
        if f then
            local resp = f(fd,args)
            if response then
                return response(resp)
            end
        end
        return nil
    else
        -- local f = RESPONSE[msgname]
        -- if f then

        -- end
    end
end

--[[
    在认证的时候断开连接，并没有什么需要处理，只需要清理客户端的连接信息即可.
]]
function accept.disconnect(fd)
    clear_client(fd)
    return errs.code.SUCCESS
end

function REQUEST.handshake(fd,args)
    clients[fd] = {
        challenge = crypt.randomkey()
    }
    return {challenge = clients[fd].challenge}
end

function REQUEST.exeys(fd,args)
    local c = assert(clients[fd])
    c.clientkey = args.cye
    c.serverkey = crypt.randomkey()
    return { sye = crypt.dhexchange(c.serverkey) }
end

function REQUEST.exse(fd,args)
    local c = assert(clients[fd])
    local chmac = args.cse
    local tempsec = crypt.dhsecret(c.clientkey,c.serverkey)
    shmac = crypt.hmac64(c.challenge, tempsec)
    local errcode = errs.code.SUCCESS
    if shmac ~= chmac then
        errcode = errs.code.HANDSHAKEERROR
        close_client(fd)
    end
    return {errcode = errcode}
end

function REQUEST.verifycode(fd,args)
    local c = assert(clients[fd])
    if c.vctime and ( skynet.now() - c.vctime ) < 100 * 120 then
        return {errcode = errs.code.OPERTOOFAST}
    end
    c.vctime = skynet.now()
    c.verifycode = genverifycode()
    
    return {errcode = errs.code.SUCCESS, code = c.verifycode}
end

function REQUEST.register(fd,args)

end

function REQUEST.login(fd,args)

end

