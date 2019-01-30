local skynet = require "skynet"
local snax = require "skynet.snax"
local loadproto = require "loadproto"
local sproto = require "sproto"
local errs = require "errorcodes"
local utils = require "utils"
local gamelogic = require "logic"

local sesion = 1
local sp_host
local sp_request
local REQUEST = {}
local _isplaying = false
local game_status
local turn_expire_time
local seats = {}

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

    if not isplaying() then
        local users = {}
        for k,_uid in pairs(seats) do
            if tonumber(_uid) ~= uid and tonumber(_uid) < 900000 then
                table.insert(users,_uid)
            end
        end
        if #users > 0 then
            sendmsg(users,"dismiss")
        end
        
        snax.exit()
    end
end

function accept.game_init(players)
    for i = 1, #players do
        print('[qznn] -- > game_init:  ',players[i].seatno , players[i].userid)
        local seatno = players[i].seatno
        local userid = players[i].userid
        seats[seatno] = userid
    end

    setplayingstatu(true)
end

