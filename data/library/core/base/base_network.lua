--[[!
    File: base/base_network.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features networking interface.

    Section: Networking
]]

--[[!
    Package: network
    This module controls some networking functions, such as connection, uploading,
    local server handling etc.
]]
module("network", package.seeall)

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

--- Get client number of following player.
-- Possibly DEPRECATED in favor of better API.
-- @return Client number of following player, or -1.
-- @class function
-- @name getfollow
getfollow = CAPI.getfollow

--- Upload asset if connected to master, otherwise save locally.
-- @class function
-- @name do_upload
do_upload = CAPI.do_upload

--- Start / stop local server. Possibly DEPRECATED in favor of better API.
-- @param map Map name. If not given, running server gets stopped.
-- @class function
-- @name ssls
ssls = CAPI.ssls

get_stats = CAPI.get_network_stats
