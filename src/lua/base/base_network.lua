---
-- base_network.lua, version 1<br/>
-- Network interface for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 OctaForge project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

--- Network for OF's Lua interface.
-- @class module
-- @name of.network
module("of.network", package.seeall)

--- Connect to a server.
-- @param ip An IP address (string)
-- @param port A port (integer)
-- @class function
-- @name connect
connect = CAPI.connect

--- Is this client connected? TODO: return a boolean,
-- or possibly DEPRECATED and replaced.
-- @param N player number
-- @return If player N is connected, return 1, otherwise 0
-- @class function
-- @name isconnected
isconnected = CAPI.isconnected

--- Get host IP.
-- @return Host IP
-- @class function
-- @name connectedip
connectedip = CAPI.connectedip

--- Get host port.
-- @return Host port.
-- @class function
-- @name connectedport
connectedport = CAPI.connectedport

--- Connect to a server (raw, DEPRECATED after some fixes)
-- @param ip An IP address (string)
-- @param port A port (integer)
-- @param pass A server password.
-- @class function
-- @name connectserv
connectserv = CAPI.connectserv

--- LAN connection. DEPRECATED after some fixes (will use connect())
-- @param port A port (integer)
-- @param pass A server password.
-- @class function
-- @name lanconnect
lanconnect = CAPI.lanconnect

--- Disconnect from a server.
-- @class function
-- @name disconnect
disconnect = CAPI.disconnect

--- Add and connect local client. DEPRECATED in scripting (useful for NPCs
-- which are done from C++ and then exported to Lua)
-- @class function
-- @name localconnect
localconnect = CAPI.localconnect

--- Disconnect local client(s). DEPRECATED in scripting, since it doesn't handle
-- several required things.
-- @param cleanup Doesn't have effect.
-- @param 
-- @class function
-- @name localdisconnect
localdisconnect = CAPI.localdisconnect

--- Start listen server. DEPRECATED
-- @param master Use master?
-- @class function
-- @name startlistenserver
startlistenserver = CAPI.startlistenserver

--- Stop listen server. DEPRECATED
-- @class function
-- @name stoplistenserver
stoplistenserver = CAPI.stoplistenserver

--- Get client number of following player.
-- Possibly DEPRECATED in favor of better API.
-- @return Client number of following player, or -1.
-- @class function
-- @name getfollow
getfollow = CAPI.getfollow

--- Connect to server instance on master.
-- Possibly DEPRECATED in favor of better API.
-- @param inst Instance. (string)
-- @class function
-- @name connect_to_instance
connect_to_instance = CAPI.connect_to_instance

--- Connect to master lobby.
-- Possibly DEPRECATED in favor of better API.
-- @class function
-- @name connect_to_lobby
connect_to_lobby = CAPI.connect_to_lobby

--- Connect to selected server instance on master.
-- Possibly DEPRECATED in favor of better API.
-- @class function
-- @name connect_to_selected_instance
connect_to_selected_instance = CAPI.connect_to_selected_instance

--- Show GUI of server instances on master.
-- Possibly DEPRECATED in favor of better API.
-- @class function
-- @name show_instances
show_instances = CAPI.show_instances

--- Upload asset if connected to master, otherwise save locally.
-- @class function
-- @name do_upload
do_upload = CAPI.do_upload

--- Reupload asset, doesn't require running world and doesn't save one,
-- useful when things crash.
-- @class function
-- @name repeat_upload
repeat_upload = CAPI.repeat_upload

--- Login to masterserver. Possibly DEPRECATED in favor of better API.
-- @param user Username.
-- @param pass Password.
-- @class function
-- @name do_login
do_login = CAPI.do_login

--- Start / stop local server. Possibly DEPRECATED in favor of better API.
-- @param map Map name. If not given, running server gets stopped.
-- @class function
-- @name ssls
ssls = CAPI.ssls
