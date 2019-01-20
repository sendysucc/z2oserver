local skynet = require "skynet"
local snax = require "skynet.snax"
local mysql = require "skynet.db.mysql"

function init(...)

    local function on_connect(db)
        db:query("set charset utf8")
        skynet.error("connect to database success! ")
    end

    db = mysql.connect({
        host = "127.0.0.1",
        port = 3306,
        -- database = "z2oserver",
        database = "z2osrv",
        user = "sendy",
        password = "sendy",
        max_packet_size = 1024*1024,
        on_connect = on_connect,
    })

    if not db then
        skynet.error("connect database failed ! please check it out.")
        snax.exit()
    end
end
