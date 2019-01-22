local sharedata = require "skynet.sharedata"

local pmg = {}

pmg.addplayer = function(userinfo)
    local uid = userinfo.userid
    local ob = sharedata.query(uid)
    print('---------> ob:',ob)
    sharedata.new(uid, userinfo)
end

pmg.update = function(uid, key, val)
    local pobj = assert(sharedata.deepcopy(uid))
    pobj[key] = val
    sharedata.delete(uid)
    sharedata.new(uid,pobj)
end

pmg.getplayer = function(uid)
    return sharedata.deepcopy(uid)
end

pmg.landingplayer = function(uid)

end

return pmg