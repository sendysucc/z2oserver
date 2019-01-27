local skynet = require "skynet"
local snax = require "skynet.snax"
local errs = require "errorcodes"
local utils = require "utils"

local baseidx = 900000
local busy_robots = {}  -- robot id list


function init(...)
    local retcode,robots = utils.getmgr('dbmgr').req.loadrobots(0,1800)
    if retcode == errs.code.SUCCESS then
        utils.getmgr('redismgr').post.loadrobots(robots)
    end
end

