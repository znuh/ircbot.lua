--[[
Name	: ircbot.lua -- fast, diverse irc bot in lua
Author	: David Shaw (dshaw@redspin.com)
Date	: August 8, 2010
Desc.	: ircbot.lua uses the luasocket library. This
	  can be installed on Debian-based OS's with
	  sudo apt-get install liblua5.1-socket2.
	
License	: BSD License
Copyright (c) 2010, David Shaw
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]--

--[[
	TODO !!
	
	- Socket (s) needs to be global (table?) to be accessible
	by all functions, instead of passed as an argument as it is currently.
	
	- File IO for functions (memos, possible http cache?)
	
		\- Loading config from config.txt
]]

socket = require "socket" -- luasocket

-- globals
list = {}
lineregex = "[^\r\n]+"

function deliver(s, content)
	s:send(content .. "\r\n\r\n")
end

function msg(s, channel, content)
	deliver(s, "PRIVMSG " .. channel .. " :" .. content)
end

function process(s, channel, lnick, line) --!! , nick, host
	local mittwoch = (tonumber(os.date("%w"))==3)
	if not mittwoch then return end
	if string.find(" "..line:lower().." ", "[^%a]amazon[^%a]") then
		msg(s, channel, lnick .. ": Heute ist amazonfreier Mittwoch!")
	end	
end

-- config
-- !! should take cli args 
local serv = arg[1]
local nick = arg[2]
local channel = "#" .. arg[3]
local verbose = false
local welcomemsg = false

-- connect
print("[+] setting up socket to " .. serv)
s = socket.tcp()
s:connect(socket.dns.toip(serv), 6667) -- !! add more support later; ssl?

-- initial setup

-- !! function-ize
print("[+] trying nick", nick)

s:send("USER " .. nick .. " " .. " " .. nick .. " " ..  nick .. " " .. ":" .. nick .. "\r\n\r\n")
s:send("NICK " .. nick .. "\r\n\r\n")
print("[+] joining", channel)
s:send("JOIN " .. channel .. "\r\n\r\n")


if welcomemsg then msg(s, channel, welcomemsg) end
local line = nil

-- the guts of the script -- parses out input and processes
while true do
	-- just grab one line ("*l")
	receive = s:receive('*l')
	
	-- gotta grab the ping "sequence".
	if string.find(receive, "PING :") then
		s:send("PONG :" .. string.sub(receive, (string.find(receive, "PING :") + 6)) .. "\r\n\r\n")
		if verbose then print("[+] sent server pong") end
	else
		-- is this a message?
		if string.find(receive, "PRIVMSG") then
			if verbose then msg(s, channel, receive) end
			if receive:find(channel .. " :") then line = string.sub(receive, (string.find(receive, channel .. " :") + (#channel) + 2)) end
			if receive:find(":") and receive:find("!") then lnick = string.sub(receive, (string.find(receive, ":")+1), (string.find(receive, "!")-1)) end
			-- !! add support for multiple channels (lchannel)
			if line then
				--print("processing "..line)
				process(s, channel, lnick, line)
			end
		end		
	end
	-- verbose flag sees everything
	if verbose then print(receive) end
end
-- fin!
