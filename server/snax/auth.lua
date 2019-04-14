local skynet = require "skynet"
local snax = require "skynet.snax"
local loadproto = require "loadproto"
local sproto = require "sproto"
local crypt = require "skynet.crypt"
local errs = require "errorcodes"
local utils = require "utils"
local playermgr = require "playermgr"

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
        skynet.sleep(50)
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

local function sha1(text)
	local c = crypt.sha1(text)
	return crypt.hexencode(c)
end

local function hmac_sha1(key, text)
	local c = crypt.hmac_sha1(key, text)
	return crypt.hexencode(c)
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
function response.disconnect(fd)
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
    c.cellphone = args.cellphone
    if c.vctime and ( skynet.now() - c.vctime ) < 100 * 120 then
        return {errcode = errs.code.OPERTOOFAST}
    end
    c.vctime = skynet.now()
    c.verifycode = genverifycode()
    
    return {errcode = errs.code.SUCCESS, code = c.verifycode}
end

function REQUEST.register(fd,args)
    local cellphone = args.cellphone
    local password = args.password
    local verifycode = args.verifycode
    local promotecode = args.promotecode or 'uidsystem'
    local agentcode = args.agentcode or 'adv1301'

    local errcode = errs.code.SUCCESS
    if not cellphone or not password or not verifycode or string.len(cellphone) ~= 11 then
        errcode = errs.code.INVALIDREGISTERINFO
        return { errcode = errcode }
    end
    
    local c = clients[fd]
    if not c.verifycode then
        errcode = errs.code.ILLEGALREGISTER
        return { errcode = errcode }
    end
    if c.cellphone ~= cellphone then
        errcode = errs.code.PHONE_NUMBER_NOT_MATCHED
        return { errcode = errcode }
    end
    if c.verifycode ~= verifycode then
        errcode = errs.code.INVALIDVERIFYCODE
        return { errcode = errcode }
    end
    if not password or string.len(password) <= 6 then
        errcode = errs.code.PASSWORD_NOT_ALLOWED
        return { errcode = errcode }
    end
    password = sha1(password)
    local ret = utils.getmgr('dbmgr').req.register(cellphone,password,promotecode,agentcode)
    return {errcode = ret}
end

local function filluserdata(orginUser)
    local newUser = {}
    for k,v in pairs(orginUser) do
        newUser[k] = v
    end
    return newUser
end

function REQUEST.login(fd,args)
    local phone = args.cellphone
    local password = args.password
    

    if not phone or not password then
        return { errcode = errs.code.LOGIN_INFO_ERR }
    end

    password = sha1(password)

    local resp = {}
    
    --login from redis first
    local redis_user = utils.getmgr('redismgr').req.getPlayerbyPhone(phone)
    if redis_user then 
        if password ~= redis_user.password then
            return { errcode = errs.code.PASSWORD_MISS }
        end
        if redis_user.online == "1" then
            return { errcode = errs.code.ALREADY_LOGIN }
        end
        resp = redis_user

        if redis_user.gaminghandle then
            resp.errcode = errs.code.PLAYER_BREAKLINE
            resp.gamingname = redis_user.gamingsrvname
            resp.gaminghandle = tonumber(redis_user.gaminghandle)
        else
            resp.errcode = errs.code.SUCCESS    
        end

    else
        local _errcode, mysql_user = utils.getmgr('dbmgr').req.login(phone,password)
        if _errcode ~= errs.code.SUCCESS then
            return { errcode = _errcode }
        end
        
        resp = filluserdata(mysql_user)
        resp.errcode = _errcode

        mysql_user.errcode = nil
        --add player to redis
        utils.getmgr('redismgr').post.addPlayer(mysql_user)
    end

    --将后续的消息转发给hall
    local hallobj = snax.queryservice('hall')
    local addr = skynet.queryservice("gated")
    skynet.send(addr,"lua","forward",fd,hallobj,resp.userid)

    utils.getmgr('redismgr').post.playeronline(resp.userid)
    
    --清理auth中的用户数据
    clear_client(fd)

    return resp
end