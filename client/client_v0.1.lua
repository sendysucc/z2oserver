package.cpath = "./skynet/luaclib/?.so"
package.path = "./skynet/lualib/?.lua;" .. "./server/libs/?.lua"

local socket = require "client.socket"
local sproto = require "sproto"
local crypt = require "client.crypt"
local loadproto = require "loadproto"

local host = sproto.new( loadproto.getprotobin("./server/protocol/auth_s2c.spt") ):host "package"
local request = host:attach(sproto.new( loadproto.getprotobin("./server/protocol/auth_c2s.spt")) )

local fd = assert(socket.connect('127.0.0.1',12288))

local secret = nil
local session = 0
local last = ""

local function send_package(fd,pack)
    local package = string.pack(">s2",pack)
    socket.send(fd,package)
end

local function send_request(name,args)
    session = session + 1
	local str = request(name,args, session)
	if secret then
		str = crypt.desencode(secret,str)
    end
    str = crypt.base64encode( str)
    send_package(fd,str)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
        end
        
        v = crypt.base64decode(v)

		if secret then
			v = crypt.desdecode(secret ,v )
		end
		local resType , name , args = host:dispatch(v)
		return args
	end
end

local function receive_data()
	local rets = nil
	while true do
		rets = dispatch_package()
		if rets then
			break
		end
	end
	return rets
end

send_request("handshake")
local rets = receive_data()
local challenge = rets.challenge

local clientkey = crypt.randomkey()
send_request('exeys',{cye= crypt.dhexchange(clientkey)})

rets = receive_data()
local serverkey = rets.sye

print(serverkey)

local tempsecret = crypt.dhsecret(serverkey,clientkey)

send_request('exse',{ cse = crypt.hmac64(challenge,tempsecret) })
rets = receive_data()
print('--->errcode:',rets.errcode)

if rets.errcode ~= 0 then
	os.exit()
end


local phone = '15865671320'

send_request('verifycode', { cellphone = phone })
rets = receive_data()
print('----->verifycode:', rets.code)
local verifycode = rets.code


local password = 'sendysucc'

send_request('register', { cellphone = phone, password = password, verifycode = verifycode })
rets = receive_data()
print('------->register :', rets.errcode)

send_request('login',{cellphone = phone, password = password})
rets = receive_data()
print('------->login:',rets.errcode)
for k,v in pairs(rets) do
	print(k,v)
end


host = sproto.new( loadproto.getprotobin("./server/protocol/hall_s2c.spt") ):host "package"
request = host:attach(sproto.new( loadproto.getprotobin("./server/protocol/hall_c2s.spt")) )


if rets.errcode == 15 then
	send_request("reconnect",{handle= rets.gaminghandle, servicename = rets.gamingname })	
	print('---------> block on receive reconnect resonse')
	rets = receive_data()
end


send_request("gamelist")
rets = receive_data()
print('-------->gamelist',rets.errcode)
for k,v in pairs(rets.games) do
	for _k,_v in pairs(v)	do
		print('game:',_k,_v)
	end
end

local games = rets.games

for k,v in pairs(rets.rooms) do
	for _k,_v in pairs(v)	do
		print('room:',_k,_v)
	end
end

local rooms = rets.rooms
-- send_request("notice",{id = 0})
-- rets = receive_data()
-- print('------>notice:',rets.errcode)

-- send_request("mails",{id = 0})
-- rets = receive_data()
-- print('------->mails:',rets.errcode)

-- send_request('match',{ gameid= rooms[1].gameid , roomid= rooms[1].roomid })
send_request('match',{ gameid= 20001 , roomid= 2 })
-- send_request('match',{ gameid= 30001 , roomid= 6 })
rets = receive_data()
print('=----------->match:', rets.errcode)
for k,v in pairs(rets.players) do
	for _k,_v in pairs(v) do
		print(_k,_v)
	end
end

-- host = sproto.new( loadproto.getprotobin("./server/protocol/bjl_s2c.spt") ):host "package"
-- request = host:attach(sproto.new( loadproto.getprotobin("./server/protocol/bjl_c2s.spt")) )

-- send_request('hello', {msg="hello from client !"})
-- rets = receive_data()
-- print('----->bjl msg:',rets.msg)