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

local function getPlayerbyId(uid)
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

local function getPlayerbyPhone(phone)
    local keys = db:keys("Player:*")
    for k,val in pairs(keys) do
        local userinfo = reverseT(db:hgetall(val))
        if userinfo.cellphone == phone then
            return userinfo
        end
    end
    return nil
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
    local userinfo = reverseT( getPlayerbyId(uid) )
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