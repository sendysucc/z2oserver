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

local _callbacks = {}
local cb_start
local cb_election
local cb_betting
local cb_sendcard
local cb_combination
local cb_compare
local cb_bonus
local cb_stop

--游戏信息
local _isplaying = false    --是否游戏中
local game_status           --游戏阶段
local turn_expire_time      --计时器
local seats = {}            --座位上的玩家
local gamesn                --当局游戏局号
local banker                --庄家座位号


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

local function cleargaminginfos(uid)
    utils.getmgr('redismgr').post.clearuservalue(uid,{"gaminghandle","gamingsrvname"})
end

local function setgaminginfos(uid)
    utils.getmgr('redismgr').post.setplayinggame(uid, snax.self().handle, snax.self().type)
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
        for k,player in pairs(seats) do
            if tonumber(player.userid) ~= uid and tonumber(player.userid) < 900000 then
                table.insert(users,player.userid)
            end
            --todo：清除玩家redis中记录的 gamingsrvname , gamingsrhandle 
            cleargaminginfos(player.userid)
        end
        if #users > 0 then
            sendmsg(users,"dismiss")
        end

        print('------->游戏还没开始就退出')

        snax.exit()
    else    --游戏中途退出, 则托管
        print('------->游戏中途退出')

        for seat, player in pairs(seats) do
            if player.userid == uid then
                player.breakline = true
            end
        end
        
    end
end

function accept.game_init(players)
    for i = 1, #players do
        print('[qznn] -- > game_init:  ---- player informs ---------1')
        for k,v in pairs(players[i]) do
            print(k,v)
        end
        print('[qznn] -- > game_init:  ---- player informs ---------2')
        local seatno = players[i].seatno
        seats[seatno] = players[i]

        --设置玩家正在玩的游戏服务
        setgaminginfos(player[i].userid)
    end
    init_game_status()
    setplayingstatu(true)
end

function response.gamestatus()

end

-- 是否继续,如果有一个玩家不再继续,则解散游戏,并将继续的玩家加入到新的排队队列中.
function REQUEST.continue(uid,args)

end

function REQUEST.quitgame(uid,args)
    if game_status ~= logic.stage.STOP then
        return { errcode = errs.code.NOT_ALLOW_QUIT_GAME }
    end
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

-- 当 STOP状态时, 要将短线的玩家的标志(redis 里的 gaminghandle)去掉
cb_stop = function()
    print('--------> cb_stop')

    for seatno, player in pairs(seats) do
        cleargaminginfos(player.userid)
    end
end