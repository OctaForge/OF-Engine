---
-- base_camera.lua, version 1<br/>
-- Camera interface for Lua<br/>
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

--- Camera for cC's Lua interface.
-- @class module
-- @name cc.camera
module("cc.camera")

---
-- @class function
-- @name forcecam
forcecam = CAPI.forcecam
---
-- @class function
-- @name forcepos
forcepos = CAPI.forcepos
---
-- @class function
-- @name forceyaw
forceyaw = CAPI.forceyaw
---
-- @class function
-- @name forcepitch
forcepitch = CAPI.forcepitch
---
-- @class function
-- @name forceroll
forceroll = CAPI.forceroll
---
-- @class function
-- @name forcefov
forcefov = CAPI.forcefov
---
-- @class function
-- @name resetcam
resetcam = CAPI.resetcam
---
-- @class function
-- @name getcam
getcam = CAPI.getcam
---
-- @class function
-- @name getcampos
getcampos = CAPI.getcampos
---
-- @class function
-- @name caminc
caminc = CAPI.caminc
---
-- @class function
-- @name camdec
camdec = CAPI.camdec
---
-- @class function
-- @name mouselook
mouselook = CAPI.mouselook
---
-- @class function
-- @name characterview
characterview = CAPI.characterview
---
-- @class function
-- @name setdeftpm
setdeftpm = CAPI.setdeftpm
