local sharedata = require "skynet.sharedata"

local prefix = 'game_'    -- game_gameid : game_10001
local prefix = 'room_'    -- room_gameid_roomid:  room_10001_1

local gmgr = {}

gmgr.initgamelist = function(gamelist)
    for k, game in pairs(gamelist) do

    end
end

gmgr.initroomlist = function(roomlist)
    for k, room in pairs(roomlist) do
        
    end
end



return gmgr