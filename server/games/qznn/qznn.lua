local skynet = require "skynet"
local snax = require "skynet.snax"
local loadproto = require "loadproto"
local sproto = require "sproto"
local errs = require "errorcodes"
local utils = require "utils"
local gamelogic = require "logic"

local sp_host
local sp_request
local REQUEST = {}
local _isplaying = false
local game_status
local turn_expire_time

local function setplayingstatu(isplaying)
    _isplaying = isplaying
end

local function isplaying()
    return _isplaying
end

local function tick()

end

function init(...)
    sp_host = sproto.new( loadproto.getprotobin("./protocol/qznn_c2s.spt") ):host "package"
    sp_request = sp_host:attach( sproto.new( loadproto.getprotobin("./protocol/qznn_s2c.spt") ) )

    skynet.fork(function()
        skynet.sleep(100)
        if isplaying() then
            tick()
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
end

function accept.game_init(players)
    for i = 1, #players do
        print('[qznn] -- > game_init:  ',players[i].seatno , players[i].userid)
    end

    setplayingstatu(true)
end

