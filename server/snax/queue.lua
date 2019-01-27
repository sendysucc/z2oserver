local skynet = require "skynet"
local snax = require "skynet.snax"
local gamedata = require "gamedata"
local errs = require "errorcodes"
local utils = require "utils"

local queue = {}
local game_services = {}

local test_uid 

local function mathing()
    for gid , gque in pairs(queue) do
        for rid , rque in pairs(gque) do

            local ret0,gameinfo = utils.getmgr('redismgr').req.getgameinfo(gid)
            local ret1,roominfo = utils.getmgr('redismgr').req.getroominfo(gid,rid)
            if  ret0 ~= errs.code.SUCCESS or gameinfo.enable == '0' or ret1 ~= errs.code.SUCCESS or roominfo.enable == '0' then    -- 通知所有排队的玩家,游戏维护中
                while #rque > 0 do
                    local uid = table.remove(rque,1)
                    utils.getmgr('hall').post.matched(uid,{ errcode = errs.code.GAME_MAINTENANCE })
                end
            end

            local minplayer = roominfo.minplayers 
            local maxplayer = roominfo.maxplayers
            local gametype = gameinfo.gametype
            local servicename = assert(gamedata[gid].name)
            
            while #rque > 0 do
                if gametype == "1" or gametype == 1 then    --百人游戏
                    local alloc_gobj = 0
                    if game_services[gid] and game_services[gid][rid] and game_services[gid][rid].onlines < 100 then
                        game_services[gid][rid].onlines = game_services[gid][rid].onlines + 1
                        alloc_gobj = game_services[gid][rid].obj
                    else    --create new game service
                        game_services[gid] = game_services[gid] or {}
                        game_services[gid][rid] = game_services[gid][rid] or {}
                        game_services[gid][rid].obj = snax.newservice(servicename)
                        game_services[gid][rid].onlines = 1
                        alloc_gobj = game_services[gid][rid].obj
                    end
                    local alloc_uid = table.remove(rque,1)
                    utils.getmgr('hall').post.matched(alloc_uid,{ errcode = errs.code.SUCCESS , serviceobj = alloc_gobj })
                elseif gametype == "2" or gametype == 2 then    --对战类游戏
                    local queuecount = #rque
                    if queuecount < minplayer then  --need robots

                    elseif queuecount >= minplayer and queuecount <= maxplayer then

                    elseif queuecount > maxplayer then

                    end
                end
            end
        end
    end
end

function init(...)
    skynet.fork(function()
        while true do
            skynet.sleep(200)
            mathing()
        end
    end)
end

function accept.match(uid,gameid,roomid)
    queue[gameid] = queue[gameid] or {}
    queue[gameid][roomid] = queue[gameid][roomid] or {}
    table.insert(queue[gameid][roomid],uid)
end

