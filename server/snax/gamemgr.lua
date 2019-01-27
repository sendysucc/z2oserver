local skynet = require "skynet"
local snax = require "skynet.snax"
local errs = require "errorcodes"
local utils = require "utils"


function init(...)
    local retcode,gamelist = utils.getmgr('dbmgr').req.gamelist()
    if retcode == errs.code.SUCCESS then
        utils.getmgr('redismgr').post.initgamelist(gamelist)
    end
    local retcode,roomlist = utils.getmgr('dbmgr').req.roomlist()
    if retcode == errs.code.SUCCESS then
        utils.getmgr('redismgr').post.initroomlist(roomlist)
    end
end
