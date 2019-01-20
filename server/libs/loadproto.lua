local parser = require "sprotoparser"
local core = require "sproto.core"

local loads = {}

function loads.getprotobin(filename)
    local f = assert(io.open(filename))
    local data = f:read "a"
    f:close()

    return parser.parse(data)
end

return loads