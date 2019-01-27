local skynet = require "skynet"
local redis = require "skynet.db.redis"
local snax = require "skynet.snax"
local errs = require "errorcodes"

local db
local prefix_player = "Player:"
--[[
    将一个 key-value 的 table 转为 k,v 顺序的数组
    如 old_table = {name = "sendy", age = 10} :
        new_table = {name , sendy , age , 10}
]]
local function convertT(origin_table)
    local newT = {}
    for k,v in pairs(origin_table) do
        table.insert(newT,k)
        table.insert(newT,v)
    end
    return newT
end

local function reverseT(origin_table)
    local newT = {}
    for i = 1,  #origin_table/2 do
        newT[origin_table[i*2 - 1]] = origin_table[i*2]
    end
    return newT
end

local function _getPlayerbyId(uid)
    -- local mytes = db:keys("*")
    -- print('-------keys----->:',mytes)
    -- print('-------keys----->: len = ',#mytes)
    -- for k,v in pairs(mytes) do
    --     print(k,v)
    -- end

    local key = prefix_player .. uid
    local res = db:hgetall(key)
    return reverseT(res)
end

local function _setplayerval(uid,name,val)
    local key = prefix_player .. uid
    local res = reverseT(db:hgetall(key))
    if res.userid then
        db:hset(key,name,val)
    end
end

function init(...)
    local conf = {
        host = '127.0.0.1',
        port = 6379,
        db = 0,
    }
    db = redis.connect(conf)

    -- test example:
    -- local player = {userid = 10001,name = "hansen", gold = 500, diamond = 0, avatoridx = 3}

    -- db:hmset("Player:" .. player.userid,  table.unpack(convertT(player)))

    -- local t = db:hgetall("Player:" .. player.userid)   -- if not exists , return a empty table

    -- print('----------->redis mgr: ',t, #t)
    -- for k,v in pairs(t) do
    --     print(k,v)
    -- end

    -- print('-=----------> reverse:')
    -- for k,v in pairs(reverseT(t)) do
    --     print(k,v)
    -- end
end

function response.checkbreakline(uid)
    local userinfo =  _getPlayerbyId(uid) 
    if not userinfo.userid then -- not breakline
        return errs.code.SUCCESS, nil
    else
        return errs.code.PLAYER_BREAKLINE, userinfo
    end
end

function accept.addPlayer(userinfo)
    local key = prefix_player .. userinfo.userid
    db:hmset(key, table.unpack(convertT(userinfo)) )
end

function response.getPlayerbyPhone(phone)
    local keys = db:keys("Player:*")
    for k,val in pairs(keys) do
        local userinfo = reverseT(db:hgetall(val))
        if userinfo.cellphone == phone then
            return userinfo
        end
    end
    return nil
end

function response.getPlayerbyId(uid)
    return _getPlayerbyId(uid)
end

function accept.setlayerval(uid,key,val)
    _setplayerval(uid,key,val)
end

function accept.playeroffline(uid)
    _setplayerval(uid,"online",0)
end

function accept.playeronline(uid)
    _setplayerval(uid,"online",1)
end

function accept.initgamelist(gamelist)
    for k,v in pairs(gamelist) do
        local key = "Game:" .. v.gameid
        db:hmset(key,table.unpack( convertT(v)))
    end
end

function accept.initroomlist(roomlist)
    for k,v in pairs(roomlist) do
        local key = "Room:" .. v.gameid .. ":" .. v.roomid
        db:hmset(key,table.unpack( convertT(v)))
    end
end

function response.getgamelist()
    local glist = {}
    local rlist = {}
    local keys = db:keys("Game:*")
    if #keys <= 0 then
        return errs.code.NO_GAME_AVAILABLE
    end

    for k,v in pairs(keys) do
        local game = reverseT( db:hgetall(v) )
        table.insert(glist,game)
    end

    local keys = db:keys("Room:*")
    if #keys <= 0 then
        return errs.code.NO_GAME_AVAILABLE
    end

    for k,v in pairs(keys) do
        local room = reverseT( db:hgetall(v) )
        table.insert(rlist,room)
    end

    return errs.code.SUCCESS, glist,rlist
end

function response.getgameinfo(gameid)
    local keys = "Game:" .. gameid
    local gameinfo = reverseT(db:hgetall(keys))
    if not gameinfo.gameid then
        return errs.code.GAME_NOT_FOUND
    end
    return errs.code.SUCCESS,gameinfo
end

function response.getroominfo(gameid,roomid)
    local keys = "Room:" .. gameid .. ":" .. roomid
    local roominfo = reverseT(db:hgetall(keys))
    if not roominfo.roomid then
        return errs.code.ROOM_NOT_FOUND
    end
    return errs.code.SUCCESS,roominfo
end

function accept.loadrobots(robots)
    for k,v in pairs(robots) do
        local key = prefix_player .. v.userid
        db:hmset(key, table.unpack(convertT(v)) )
    end
end