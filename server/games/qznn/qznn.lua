local skynet = require "skynet"
local snax = require "skynet.snax"
local loadproto = require "loadproto"
local sproto = require "sproto"
local errs = require "errorcodes"
local utils = require "utils"
local logic = require "qznnlogic"

local sesion = 1
local sp_host
local sp_request
local REQUEST = {}
local _isplaying = false
local game_status
local turn_expire_time
local seats = {}
local _callbacks = {}
local cb_start
local cb_election
local cb_betting
local cb_sendcard
local cb_combination
local cb_compare
local cb_bonus
local cb_stop

local function register_method(statu, callback)
    _callbacks[statu] = callback
end

local function sendmsg(uids,name,msg)
    local addr = skynet.queryservice("gated")
    if addr then
        local str = sp_request(name,msg, session)
        skynet.send(addr,'lua','sendmsg',uids,str)
        sesion = sesion + 1
    end
end

local function setplayingstatu(isplaying)
    _isplaying = isplaying
end

local function isplaying()
    return _isplaying
end

local function set_game_status(statu)
    game_status = statu
    turn_expire_time = logic.expires[statu]
end

local function tick()
    if logic.expires[game_status] == turn_expire_time then
        _callbacks[game_status]()
    end
    turn_expire_time = turn_expire_time  - 1
    if turn_expire_time == 0 then
        if game_status == logic.stage.STOP then
            setplayingstatu(false)
            set_game_status(1)
        else
            set_game_status(game_status +1)
        end
    end
end

local function init_game_status()
    set_game_status(logic.stage.START)

end

function init(...)
    sp_host = sproto.new( loadproto.getprotobin("./protocol/qznn_c2s.spt") ):host "package"
    sp_request = sp_host:attach( sproto.new( loadproto.getprotobin("./protocol/qznn_s2c.spt") ) )

    register_method(logic.stage.START, cb_start)
    register_method(logic.stage.ELECTION, cb_election)
    register_method(logic.stage.BETTING, cb_betting)
    register_method(logic.stage.SENDCARD, cb_sendcard)
    register_method(logic.stage.COMBINATION, cb_combination)
    register_method(logic.stage.COMPARE, cb_compare)
    register_method(logic.stage.BONUS, cb_bonus)
    register_method(logic.stage.STOP,cb_stop)

    skynet.fork(function()
        while true do
            skynet.sleep(100)
            if isplaying() == true then
                tick()
            end
        end
    end)
end

function response.message(uid,msg,sz)
    local msgtype, msgname, args, response = sp_host:dispatch(msg,sz)
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
    skynet.error('[qznn] user disconnect :',uid)
    utils.getmgr('redismgr').post.playeroffline(uid)

    if not isplaying() then --游戏没开始,则解散桌子
        local users = {}
        for k,_uid in pairs(seats) do
            if tonumber(_uid) ~= uid and tonumber(_uid) < 900000 then
                table.insert(users,_uid)
            end
        end
        if #users > 0 then
            sendmsg(users,"dismiss")
        end
        print('------->游戏还没开始就退出')
        snax.exit()
    else    --游戏中途退出, 则托管
        print('------->游戏中途退出')
    end
end

function accept.game_init(players)
    for i = 1, #players do
        print('[qznn] -- > game_init:  ',players[i].seatno , players[i].userid)
        local seatno = players[i].seatno
        local userid = players[i].userid
        seats[seatno] = userid

        --设置玩家正在玩的游戏服务
        utils.getmgr('redismgr').post.setplayinggame(userid, snax.self().handle, snax.self().type)

    end
    init_game_status()
    setplayingstatu(true)
end

-- 是否继续,如果有一个玩家不再继续,则解散游戏,并将继续的玩家加入到新的排队队列中.
function REQUEST.continue(uid,beagain)

end

cb_start = function()
    print('----------> cb_start')
end

cb_election = function()
    print('----------> cb_election')
end

cb_betting = function()
    print('----------> cb_betting')
end

cb_sendcard = function()
    print('----------> cb_sendcard')
end

cb_combination = function()
    print('----------> cb_combination')
end

cb_compare = function()
    print('----------> cb_compare')
end

cb_bonus = function()
    print('----------> cb_bonus')
end

cb_stop = function()
    print('--------> cb_stop')


end