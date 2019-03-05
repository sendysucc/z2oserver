skynet = require "skynet"
snax = require "skynet.snax"

skynet.start(function() 
    skynet.error("main entry")

    snax.uniqueservice('dbmgr')

    snax.uniqueservice('redismgr')

    snax.uniqueservice('gamemgr')

    snax.uniqueservice('robotmgr')

    snax.uniqueservice('queue')

    snax.uniqueservice("hall")

    local auth = snax.uniqueservice("auth")

    local gate = skynet.uniqueservice('gated')
    skynet.send(gate,"lua","open", {
        port = 12288,
        maxclient = 10240,
        nodelay = true,
    })
    skynet.send(gate,"lua","setauth", auth)
end)