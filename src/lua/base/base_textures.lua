---
-- base_textures.lua, version 1<br/>
-- Texture interface for Lua<br/>
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
local string = require("string")

--- Textures for cC's Lua interface.
-- @class module
-- @name cc.texture
module("cc.texture")

---
function convpngtodds(src, dest)
    CAPI.convpngtodds(src, dest or string.gsub(src, '.png', '.dds'))
end
---
-- @class function
-- @name combineimages
combineimages = CAPI.combineimages
---
-- @class function
-- @name reset
reset = CAPI.texturereset
---
-- @class function
-- @name add
add = CAPI.texture
---
-- @class function
-- @name resetmat
resetmat = CAPI.materialreset
---
-- @class function
-- @name autograss
autograss = CAPI.autograss
---
-- @class function
-- @name scroll
scroll = CAPI.texscroll
---
-- @class function
-- @name offset
offset = CAPI.texoffset
---
-- @class function
-- @name rotate
rotate = CAPI.texrotate
---
-- @class function
-- @name scale
scale = CAPI.texscale
---
-- @class function
-- @name layer
layer = CAPI.texlayer
---
-- @class function
-- @name alpha
alpha = CAPI.texalpha
---
-- @class function
-- @name color
color = CAPI.texcolor
---
-- @class function
-- @name ffenv
ffenv = CAPI.texffenv
---
-- @class function
-- @name reload
reload = CAPI.reloadtex
---
-- @class function
-- @name gendds
gendds = CAPI.gendds
---
-- @class function
-- @name flipnormalmapy
flipnormalmapy = CAPI.flipnormalmapy
---
-- @class function
-- @name mergenormalmaps
mergenormalmaps = CAPI.mergenormalmaps
---
-- @class function
-- @name showgui
showgui = CAPI.showtexgui
---
-- @class function
-- @name list
list = CAPI.listtex
---
-- @class function
-- @name massreplace
massreplace = CAPI.massreplacetex
---
-- @class function
-- @name edit
edit = CAPI.edittex
---
-- @class function
-- @name get
get = CAPI.gettex
---
-- @class function
-- @name getcur
getcur = CAPI.getcurtex
---
-- @class function
-- @name getsel
getsel = CAPI.getseltex
---
-- @class function
-- @name getrep
getrep = CAPI.getreptex
---
-- @class function
-- @name getname
getname = CAPI.gettexname
