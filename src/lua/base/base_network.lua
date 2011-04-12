---
-- base_network.lua, version 1<br/>
-- Network interface for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
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

local CAPI = require("CAPI")

--- Network for cC's Lua interface.
-- @class module
-- @name cc.network
module("cc.network")

---
-- @class function
-- @name connect
connect = CAPI.connect
---
-- @class function
-- @name isconnected
isconnected = CAPI.isconnected
---
-- @class function
-- @name connectedip
connectedip = CAPI.connectedip
---
-- @class function
-- @name connectedport
connectedport = CAPI.connectedport
---
-- @class function
-- @name connectserv
connectserv = CAPI.connectserv
---
-- @class function
-- @name lanconnect
lanconnect = CAPI.lanconnect
---
-- @class function
-- @name disconnect
disconnect = CAPI.disconnect
---
-- @class function
-- @name localconnect
localconnect = CAPI.localconnect
---
-- @class function
-- @name localdisconnect
localdisconnect = CAPI.localdisconnect
---
-- @class function
-- @name startlistenserver
startlistenserver = CAPI.startlistenserver
---
-- @class function
-- @name stoplistenserver
stoplistenserver = CAPI.stoplistenserver
---
-- @class function
-- @name getfollow
getfollow = CAPI.getfollow
---
-- @class function
-- @name connect_to_instance
connect_to_instance = CAPI.connect_to_instance
---
-- @class function
-- @name connect_to_lobby
connect_to_lobby = CAPI.connect_to_lobby
---
-- @class function
-- @name connect_to_selected_instance
connect_to_selected_instance = CAPI.connect_to_selected_instance
---
-- @class function
-- @name show_instances
show_instances = CAPI.show_instances
---
-- @class function
-- @name do_upload
do_upload = CAPI.do_upload
---
-- @class function
-- @name repeat_upload
repeat_upload = CAPI.repeat_upload
---
-- @class function
-- @name do_login
do_login = CAPI.do_login
---
-- @class function
-- @name ssls
ssls = CAPI.ssls
