local skynet = require "skynet"
local snax = require "skynet.snax"

local utils = {}

utils.getmgr = function(name)
    local obj = snax.queryservice(name)
    return obj
end

return utils