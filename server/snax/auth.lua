local skynet = require "skynet"
local snax = require "skynet.snax"
local loadproto = require "loadproto"
local sproto = require "sproto"
local crypt = require "skynet.crypt"

local sp_host
local sp_request
local REQUEST = {}
local RESPONSE = {}

local clients = {}

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
    local errcode = 0
    if shmac ~= chmac then
        errcode = 1
    end
    return {errcode = errcode}
end

function REQUEST.register(fd,args)

end

function REQUEST.login(fd,args)

end