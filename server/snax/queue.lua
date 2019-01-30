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
                local ret0,gameinfo = utils.getmgr('redismgr').req.getgameinfo(gid)
                local ret1,roominfo = utils.getmgr('redismgr').req.getroominfo(gid,rid)
                if  ret0 ~= errs.code.SUCCESS or gameinfo.enable == '0' or ret1 ~= errs.code.SUCCESS or roominfo.enable == '0' then    -- 通知所有排队的玩家,游戏维护中
                    while #rque > 0 do
                        local uid = table.remove(rque,1)
                        utils.getmgr('hall').post.matched(uid,{ errcode = errs.code.GAME_MAINTENANCE })
                    end
                end
                local minplayer = tonumber(gameinfo.minplayers)
                local maxplayer = tonumber(gameinfo.maxplayers)
                local minentry = tonumber( roominfo.minentry )
                local maxentry = tonumber(roominfo.maxentry)
                local gametype = tonumber(gameinfo.gametype)
                local servicename = assert(gamedata[gid].name)

                if gametype == 1 then    --百人游戏
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
                    alloc_gobj.post.player_join(alloc_uid)
                elseif gametype == 2 then    --对战类游戏
                    local queuecount = #rque
                    local playercount = math.random(minplayer,maxplayer)
                    local matched_players = {}
                    local robotcount = 0
                    local match_succ = true

                    if queuecount < playercount then
                        robotcount = playercount - queuecount
                    end

                    for i = 1, robotcount do
                        local robot = utils.getmgr('robotmgr').req.getidelrobot(minentry,maxentry)
                        if robot then
                            table.insert(matched_players,robot)
                        else
                            match_succ = false
                            for k,per in pairs(matched_players) do
                                if per.isrobot then
                                    utils.getmgr('robotmgr').post.freerobot(per.userid)
                                end
                            end
                            matched_players = {}
                        end
                    end

                    if not match_succ then
                        break
                    end

                    for i = 1 , playercount - robotcount do
                        local uid =  table.remove(rque,1)
                        local playerinfo = utils.getmgr('redismgr').req.getPlayerbyId(uid)
                        table.insert(matched_players,playerinfo)
                    end

                    if #matched_players ~= playercount then
                        break
                    end
                    local gamesrvobj = snax.newservice(servicename)
                    
                    local _seatnos = {}
                    for i =1, maxplayer do
                        _seatnos[i] = i
                    end
                    
                    for k,v in pairs(matched_players) do
                        v.seatno = table.remove(_seatnos, math.random(1,#_seatnos))
                    end

                    for k,pers in pairs(matched_players) do
                        if not pers.isrobot or pers.isrobot == '0'  then
                            utils.getmgr('hall').post.matched(pers.userid,{ errcode = errs.code.SUCCESS , serviceobj = gamesrvobj , players = matched_players })
                        end
                    end

                    local join_players = {}
                    for k, per in pairs(matched_players) do
                        table.insert(join_players,{seatno = per.seatno, userid = per.userid})
                    end
                    gamesrvobj.post.game_init(join_players)
                end
            end
        end
    end
end

function init(...)
    skynet.fork(function()
        while true do
            skynet.sleep(300)
            mathing()
        end
    end)
end

function accept.match(uid,gameid,roomid)
    queue[gameid] = queue[gameid] or {}
    queue[gameid][roomid] = queue[gameid][roomid] or {}
    table.insert(queue[gameid][roomid],uid)
end