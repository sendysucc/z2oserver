skynet = require "skynet"
snax = require "skynet.snax"

skynet.start(function() 
    skynet.error("main entry")

    snax.uniqueservice("dbmgr")
    local auth = snax.newservice("auth")

    local gate = skynet.uniqueservice('gated')
    skynet.send(gate,"lua","open", {
        port = 12288,
        maxclient = 10240,
        nodelay = true,
    })
    skynet.send(gate,"lua","setauth", auth)
end)