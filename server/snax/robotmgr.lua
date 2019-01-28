local skynet = require "skynet"
local snax = require "skynet.snax"
local errs = require "errorcodes"
local utils = require "utils"

local baseidx = 900000
local robotlist 

function init(...)
    local retcode,robots = utils.getmgr('dbmgr').req.loadrobots(0,1800)
    if retcode == errs.code.SUCCESS then
        -- utils.getmgr('redismgr').post.loadrobots(robots)
        robotlist = robots
    end
end

function response.getrobotid(minentry,maxentry)
    for k, robot in pairs(robotlist) do
        if tonumber(robot.gold) >= tonumber(minentry) and tonumber(robot.gold) <= tonumber(maxentry) and not robot.busy then
            local uid = robot.userid
            robot.busy = true   --set busy flag :true
            return uid
        end
    end
    return nil
end

function response.getidelrobot(minentry,maxentry)
    for k, robot in pairs(robotlist) do
        if tonumber(robot.gold) >= tonumber(minentry) and tonumber(robot.gold) <= tonumber(maxentry) and not robot.busy then
            local uid = robot.userid
            robot.busy = true   --set busy flag :true
            local resp = {}
            local resp = {}
            resp.userid = robot.userid
            resp.username = robot.username
            resp.nickname = robot.nickname
            resp.avatoridx = robot.avatoridx
            resp.gender = robot.gender
            resp.gold = robot.gold
            resp.diamond = robot.diamond
            resp.isrobot = robot.isrobot
            return resp
        end
    end
    return nil
end

function accept.freerobot(uid)
    for k, robot in pairs(robotlist) do
        if robot.userid == uid then
            robot.busy = nil
            break
        end
    end
end

function response.getrobotinfo(robotid)
    for k,robot in pairs(robotlist) do
        if robot.userid == robotid then
            local resp = {}
            resp.userid = robot.userid
            resp.username = robot.username
            resp.nickname = robot.nickname
            resp.avatoridx = robot.avatoridx
            resp.gender = robot.gender
            resp.gold = robot.gold
            resp.diamond = robot.diamond
            resp.isrobot = robot.isrobot
            return resp
        end
    end
    return nil
end