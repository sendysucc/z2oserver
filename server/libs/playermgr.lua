local sharedata = require "skynet.sharedata"

local prefix = 'player_'

local pmg = {}

pmg.addplayer = function(userinfo)
    local uid = userinfo.userid
    local key =  prefix .. uid
    local ok,ob = pcall(sharedata.query,key)
    if not ok then
        sharedata.new(key, userinfo)
    end
end

pmg.update = function(uid, key, val)
    local _key = prefix .. uid
    local pobj = assert(sharedata.deepcopy(_key))
    pobj[key] = val
    sharedata.delete(_key)
    sharedata.new(_key,pobj)
end

pmg.getplayer = function(uid)
    local key = prefix .. uid
    return sharedata.deepcopy(key)
end

--玩家数据落地到数据库
pmg.landingplayer = function(uid)
    local key = prefix .. uid

end

return pmg