---
-- base_blend.lua, version 1<br/>
-- Texture blending interface for Lua<br/>
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
local base = _G

--- Texture blending for cC's Lua interface.
-- @class module
-- @name cc.blend
module("cc.blend")

---
-- @class table
-- @name brush
brush = {}
---
-- @class function
-- @name brush.clearall
brush.clearall = CAPI.clearblendbrushes
---
-- @class function
-- @name brush.del
brush.del = CAPI.delblendbrush
---
-- @class function
-- @name brush.add
brush.add = CAPI.addblendbrush
---
-- @class function
-- @name brush.next
brush.next = CAPI.nextblendbrush
---
-- @class function
-- @name brush.set
brush.set = CAPI.setblendbrush
---
-- @class function
-- @name brush.getname
brush.getname = CAPI.getblendbrushName
---
-- @class function
-- @name brush.cur
brush.cur = CAPI.curblendbrush
---
-- @class function
-- @name brush.rotate
brush.rotate = CAPI.rotateblendbrush
---
function brush.scroll(b)
    if b then brush.next(b) else brush.next() end
    base.echo("blend brush set to: %(1)s" % { brush.getname(brush.cur()) })
end

---
-- @class table
-- @name map
map = {}
---
-- @class function
-- @name map.paint
map.paint = CAPI.paintblendmap
---
-- @class function
-- @name map.clearsel
map.clearsel = CAPI.clearblendmapsel
---
-- @class function
-- @name map.invertsel
map.invertsel = CAPI.invertblendmapsel
---
-- @class function
-- @name map.invert
map.invert = CAPI.invertblendmap
---
-- @class function
-- @name map.show
map.show = CAPI.showblendmap
---
-- @class function
-- @name map.optimize
map.optimize = CAPI.optimizeblendmap
---
-- @class function
-- @name map.clear
map.clear = CAPI.clearblendmap

---
-- @class table
-- @name paintmodes
paintmodes = { "off", "replace", "dig", "fill", "inverted dig", "inverted fill" }

---
function setpaintmode(m)
    base.blendpaintmode = m or 0
    base.echo("blend paint mode set to: %(1)s" % { paintmodes[base.blendpaintmode] })
end
