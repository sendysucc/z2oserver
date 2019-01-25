local skynet = require "skynet"
local snax = require "skynet.snax"
local loadproto = require "loadproto"
local sproto = require "sproto"
local playermgr = require "playermgr"
local errs = require "errorcodes"
local utils = require "utils"

local sp_host
local sp_request
local REQUEST = {}

function init(...)
    sp_host = sproto.new( loadproto.getprotobin("./protocol/hall_c2s.spt") ):host "package"
    sp_request = sp_host:attach( sproto.new( loadproto.getprotobin("./protocol/hall_s2c.spt") ) )
end

function response.message(uid,msg,sz)
    local msgtype , msgname, args, response = sp_host:dispatch(msg,sz)
    if msgtype == 'REQUEST' then
        local f = REQUEST[msgname]
        if f then
            local resp = f(uid,args)
            if response then
                return response(resp)
            end
        end
        return nil
    else

    end
end

function response.disconnect(uid)
    utils.getmgr('redismgr').post.playeroffline(uid)
end

--游戏列表
function REQUEST.gamelist(uid,args)
    local ecode , glist,rlist = utils.getmgr('redismgr').req.getgamelist()
    return { errcode = ecode, games = glist, rooms = rlist }
end

--公告
function REQUEST.notice(uid,args)

end

--消息
function REQUEST.mail(uid,args)

end

--匹配游戏
function REQUEST.match(uid,args)

end

--充值
function REQUEST.recharge(uid,args)

end