local skynet = require "skynet"
local snax = require "skynet.snax"
local mysql = require "skynet.db.mysql"
local errs = require "errorcodes"

local db

local function escape(param)
    return mysql.quote_sql_str(param)
end

local function dberror(errno,sqlstate)
    skynet.error('[db] register procedure errorno :' .. errno .. ", code:" .. sqlstate)
end

function init(...)
    local function on_connect(db)
        db:query("set charset utf8")
        skynet.error("connect to database success! ")
    end
    db = mysql.connect({
        host = "127.0.0.1",
        port = 3306,
        database = "z2oserver",
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

function response.register(cellphone,password,promotecode,agentcode)
    local sql_str = string.format("call proc_register(%s,%s,%s,%s)",escape(cellphone), escape(password),escape(promotecode),escape(agentcode))
    local ret = db:query(sql_str)
    if ret.badresult then
        dberror(ret.errno,ret.sqlstate)
        return errs.code.EXECUTE_DB_SCRIPT_ERROR
    else
        return (ret[1][1].errcode)
    end
end

function response.login(cellphone,password)
    local sql_str = string.format("call proc_login(%s,%s)",escape(cellphone),escape(password))
    local ret = db:query(sql_str)
    if ret.badresult then
        dberror(ret.errno,ret.sqlstate)
        return errs.code.EXECUTE_DB_SCRIPT_ERROR
    else
        return errs.code.SUCCESS,ret[1][1]
    end
end

function response.gamelist()
    local sql_str = string.format("select * from Game;")
    local ret = db:query(sql_str)
    if ret.badresult then
        dberror(ret.errno,ret.sqlstate)
        return errs.code.EXECUTE_DB_SCRIPT_ERROR
    else
        return errs.code.SUCCESS,ret
    end
end

function response.roomlist()
    local sql_str = string.format("select * from GameRoom;")
    local ret = db:query(sql_str)
    if ret.badresult then
        dberror(ret.errno,ret.sqlstate)
        return errs.code.EXECUTE_DB_SCRIPT_ERROR
    else
        return errs.code.SUCCESS,ret
    end
end