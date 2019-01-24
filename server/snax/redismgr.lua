local skynet = require "skynet"
local redis = require "skynet.db.redis"
local snax = require "skynet.snax"

local db

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