---
-- base_blend.lua, version 1<br/>
-- Texture blending interface for Lua<br/>
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

local env = _G

--- Texture blending for OF's Lua interface.
-- @class module
-- @name of.blend
module("of.blend", package.seeall)

--- Table holding methods relating texture blending brushes.
-- @class table
-- @name brush
brush = {}

--- Clear all blend brushes.
-- @class function
-- @name brush.clearall
brush.clearall = CAPI.clearblendbrushes

--- Delete a blend brush.
-- @param name Name of the brush.
-- @class function
-- @name brush.del
brush.del = CAPI.delblendbrush

--- Add a blend brush.
-- @param name Name of the brush.
-- @param imgn Name of the image file defining the brush.
-- @class function
-- @name brush.add
brush.add = CAPI.addblendbrush

--- Move to next blend brush.
-- @param dir Movement direction. 1 means next, -1 previous. Optional.
-- @class function
-- @name brush.next
-- @see brush.scroll
brush.next = CAPI.nextblendbrush

--- Select a blend brush.
-- @param name Name of the brush.
-- @class function
-- @name brush.set
brush.set = CAPI.setblendbrush

--- Get blend brush name.
-- @param num Number of the brush.
-- @return Name of the brush.
-- @class function
-- @name brush.getname
brush.getname = CAPI.getblendbrushName

--- Get current blend brush number.
-- @return Current blend brush number.
-- @class function
-- @name brush.cur
brush.cur = CAPI.curblendbrush

--- Rotate a blend brush.
-- @param n Rotation level. Number from 1 to 5.
-- @class function
-- @name brush.rotate
brush.rotate = CAPI.rotateblendbrush

--- Scroll blend brush. Prints nice output while scrolling.
-- @param b Optional direction (see brush.next)
-- @see brush.next
function brush.scroll(b)
    if b then brush.next(b) else brush.next() end
    echo("blend brush set to: %(1)s" % { brush.getname(brush.cur()) })
end

--- Table holding methods relating texture blend painting.
-- @class table
-- @name map
map = {}

--- Toggle blendmap painting.
-- @class function
-- @name map.paint
map.paint = CAPI.paintblendmap

--- Clear blend map selection.
-- @class function
-- @name map.clearsel
map.clearsel = CAPI.clearblendmapsel

--- Invert blend map selection.
-- @class function
-- @name map.invertsel
map.invertsel = CAPI.invertblendmapsel

--- Invert blend map.
-- @class function
-- @name map.invert
map.invert = CAPI.invertblendmap

--- Show blend map.
-- @class function
-- @name map.show
map.show = CAPI.showblendmap

--- Optimize blend map.
-- @class function
-- @name map.optimize
map.optimize = CAPI.optimizeblendmap

--- Clear blend map.
-- @class function
-- @name map.clear
map.clear = CAPI.clearblendmap

--- Blend map painting modes.
-- @field off Blendmap painting is off.
-- @field replace Replace / clear layer.
-- @field dig min(dest, src) - Dig where black is the dig pattern.
-- @field fill max(dest, src) - Fill where white is the fill pattern.
-- @field inverted_dig min(dest, invert(src)) - Dig where white is the dig pattern.
-- @field inverted_fill max(Dest, invert(src)) - Fill where black is the fill pattern.
-- @class table
-- @name paintmodes
paintmodes = { "off", "replace", "dig", "fill", "inverted dig", "inverted fill" }

--- Set blend paint mode.
-- @param m Paint mode index in paintmodes table, beginning with 1. Turns blendmap painting off when not ommited.
function setpaintmode(m)
    env.blendpaintmode = m or 1
    echo("blend paint mode set to: %(1)s" % { paintmodes[env.blendpaintmode] })
end
