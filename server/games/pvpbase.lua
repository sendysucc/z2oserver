local battle = {}

local skynet = require "skynet"
local snax = require "skynet.snax"
local utils = require "utils"
local errs = require "errorcodes"

local handler 
local _request 
local _host
local seats = {}
local game_status
local turn_time_expire
local _isplaying = false
local tick 


function init(...)
    handler = ...
    _request = handler.sp_request
    _host = handler.sp_host

    skynet.fork(function()
        while true do
            skynet.sleep(100)
            if is_game_playing() == true then
                tick()
            end
        end
    end)
end



local function set_game_status(statu)
    game_status = statu
    turn_time_expire = handler.expire[statu]
end

local function set_game_playing(isplay)
    _isplaying = isplay
end

local function is_game_playing()
    return _isplaying == true
end

function response.message(uid,msg,sz)
    local msgtype,msgname, args, response = _host:dispatch(msg,sz)
    if msgtype == 'REQUEST' then
        local f = REQUEST[msgname]
        if not f then
            f = handler.REQUEST[msgname]
        end
        if f then
            local resp = f (uid,args)
            if response then
                return response(resp)
            end
        end
        return nil
    else
        local f = RESPONSE[msgname]
        if not f then
            f = handler.RESPOSNE[msgname]
        end
        if f then
            f(uid,args)
        end
    end
end

function response.disconnect(uid)
    skynet.error( '[' .. handler.name .. '] user disconnect, uid:', uid )
    utils.getmgr('redismgr').post.playeroffline(uid)

    
end

function accept.game_init(players)
    for i = 1, #players do
        print('[qznn] -- > game_init:  ',players[i].seatno , players[i].userid)
        local seatno = players[i].seatno
        local userid = players[i].userid
        seats[seatno] = userid
    end

    set_game_status(handler.stage[1])
    set_game_playing(true)
end

tick = function()
    if turn_time_expire == handler.expire[game_status] then
        handler.callback[game_status]()
    end
    turn_time_expire = turn_time_expire - 1
    if turn_time_expire == 0 then
        if game_status == handler.stage[#(handler.stage)] then
            set_game_status(handler.stage[1])
            set_game_playing(false)
        else
            set_game_status(game_status + 1)
        end
    end
end