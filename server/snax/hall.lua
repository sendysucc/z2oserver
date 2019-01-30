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

--匹配游戏请求
local match_request = {}

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

function accept.matched(uid,matchinfo)
    if not match_request[uid] then
        return 
    end
    match_request[uid].matched = matchinfo
    skynet.wakeup(match_request[uid].co)
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
    local gameid = args.gameid or 0
    local roomid = args.roomid or 0

    local player = utils.getmgr('redismgr').req.getPlayerbyId(uid)
    if not player.userid then
        return { errcode = errs.code.PLAYER_NOT_FOUND }
    end

    if player.gameing == "1" then
        return { errcode = errs.code.PLAY_MULTI_GAME_SAME_TIME }
    end

    local code, gameinfo = utils.getmgr('redismgr').req.getgameinfo(gameid)
    if code ~= errs.code.SUCCESS then
        return { errcode = errs.code.GAME_MAINTENANCE }
    end
    
    local code , roominfo = utils.getmgr('redismgr').req.getroominfo(gameid,roomid)
    if code ~= errs.code.SUCCESS then
        return { errcode = errs.code.GAME_MAINTENANCE }
    end

    if gameinfo.enable == "0" or roominfo.enable == "0" then
        return { errcode = errs.code.GAME_MAINTENANCE }
    end

    --check money weather enought
    print('--->gold:', player.gold, 'minentry:',roominfo.minentry)
    if (tonumber(player.gold) or 0) < (tonumber(roominfo.minentry) or 2) then
        return { errcode = errs.code.GOLD_LIMITS }
    end

    if match_request[uid] then
        return { errcode = errs.code.ALREADY_MATCHING }
    end

    utils.getmgr('queue').post.match(uid,gameid,roomid)
    match_request[uid] = {}
    match_request[uid].co = coroutine.running()
    skynet.wait()

    local matchinfo = match_request[uid].matched
    match_request[uid] = nil
    local resp = {}
    
    local addr = skynet.queryservice("gated")
    skynet.send(addr,"lua","forward",uid, matchinfo.serviceobj )
    return { errcode = matchinfo.errcode , players = matchinfo.players }
end

--充值
function REQUEST.recharge(uid,args)

end