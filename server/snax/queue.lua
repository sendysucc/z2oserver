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
            while #rque > 0 do
                local ret,roominfo = utils.getmgr('redismgr').req.getroominfo(gid,rid)
                if ret ~= errs.code.SUCCESS or roominfo.enable == "0" then    -- 通知所有排队的玩家,游戏维护中
                    while #rque > 0 do
                        local uid = table.remove(rque,1)
                        utils.getmgr('hall').post.matched(uid,{ errcode = errs.code.GAME_MAINTENANCE })
                    end
                    break
                end

                local minplayer = roominfo.minplayers 
                local maxplayer = roominfo.maxplayers
                local gametype = roominfo.gametype

                if gametype == "1" or gametype == 1 then    --百人游戏
                    local alloc_gobj = 0
                    if game_services[gid] and game_services[gid][rid] and game_services[gid][rid].onlines < 100 then
                        game_services[gid][rid].onlines = game_services[gid][rid].onlines + 1
                        alloc_gobj = game_services[gid][rid].obj
                    else    --create new game service
                        local servicename = assert[gamedata[gid].name]
                        game_services[gid] = game_services[gid] or {}
                        game_services[gid][rid] = game_services[gid][rid] or {}
                        game_services[gid][rid].obj = snax.newservice(name)
                        game_services[gid][rid].onlines = 1
                        alloc_gobj = game_services[gid][rid].obj
                    end
                    local alloc_uid = table.remove(rque,1)
                    utils.getmgr('hall').post.matched(alloc_uid,{ errcode = errs.code.SUCCESS , serviceobj = alloc_gobj })

                elseif gametype == "2" or gametype == 2 then    --对战匹配游戏


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

