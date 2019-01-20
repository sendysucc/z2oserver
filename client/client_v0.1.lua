package.cpath = "../skynet/luaclib/?.so"
package.path = "../skynet/lualib/?.lua;" .. "./server/libs/?.lua"

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

send_request('exse',{ tempsecret = crypt.hmac64(challenge,tempsecret) })
rets = receive_data()
print('--->errcode:',rets.errcode)