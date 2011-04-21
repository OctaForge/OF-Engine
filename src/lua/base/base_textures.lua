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

--- Convert PNG to DDS.
-- @param src Source path.
-- @param dest Destination path.
function convpngtodds(src, dest)
    CAPI.convpngtodds(src, dest or string.gsub(src, '.png', '.dds'))
end

--- Combine three images.
-- @param first First image.
-- @param sec Second image.
-- @param thr Third image.
-- @class function
-- @name combineimages
combineimages = CAPI.combineimages

--- Reset texture slots - start counting from 0.
-- @class function
-- @name reset
reset = CAPI.texturereset

--- Add new texture slot.
-- Texture types:<br/>
-- <br/>
-- - c - 0 - diffuse map<br/>
-- - u - 1 - unknown<br/>
-- - d - 2 - decal<br/>
-- - n - 3 - normal map<br/>
-- - g - 4 - glow map<br/>
-- - s - 5 - spec map<br/>
-- - z - 6 - depth map<br/>
-- - e - 7 - env map<br/>
-- <br/>
-- Rotation values:<br/>
-- <br/>
-- - 0 - none<br/>
-- - 1 - 90 clockwards<br/>
-- - 2 - 180<br/>
-- - 3 - 270 clockwards<br/>
-- - 4 - X flip<br/>
-- - 5 - Y flip<br/>
-- @param type Texture type - string.
-- @param name Path to the texture.
-- @param rot Rotation. From 0 to 5. Optional.
-- @param xoffset X offset in pixels. Optional.
-- @param yoffset Y offset in pixels. Optional.
-- @param scale Texture scale, defaults to 1.0.
-- @param forcedindex Forced texture slot index, optional.
-- @class function
-- @name add
add = CAPI.texture

--- Reset material slots. TODO: move elsewhere.
-- @class function
-- @name resetmat
resetmat = CAPI.materialreset

--- Assign grass texture to last texture slot.
-- @param name Path to the grass texture.
-- @class function
-- @name autograss
autograss = CAPI.autograss

--- Scroll a texture at X and Y Hz along the X and Y axes of the texture.
-- @param X X axis scroll frequency.
-- @param Y Y axis scroll frequency.
-- @class function
-- @name scroll
scroll = CAPI.texscroll

--- Offset a texture by Y and Y texels along the X and Y axes of the texture.
-- @param X X axis offset.
-- @param Y Y axis offset.
-- @class function
-- @name offset
offset = CAPI.texoffset

--- Rotate current texture slot. See add for rotation values.
-- @param rot Rotation. From 0 to 5. See add.
-- @class function
-- @name rotate
-- @see add
rotate = CAPI.texrotate

--- Scale current texture slot by N times its normal size.
-- @param scale The texture scale.
-- @class function
-- @name scale
scale = CAPI.texscale

--- Set a blendmap layer. If n is negative, values are relative to the back.
-- @param n Texture slot index you want to use as bottom layer.
-- @class function
-- @name layer
layer = CAPI.texlayer

--- Set alpha transparency of front / back faces of the texture slot.
-- Values range from 0.0 to 1.0.
-- @param f Front face transparency.
-- @param b Back face transparency.
-- @class function
-- @name alpha
alpha = CAPI.texalpha

--- Set texture tint. Values range from 0.0 to 1.0.
-- @param R Red component.
-- @param G Green component.
-- @param B Blue component.
-- @class function
-- @name color
color = CAPI.texcolor

--- Makes current texture slot reflect environment map in fixed function mode.
-- Requires some of environment reflection shader set, even though they're
-- not used in fixed function mode.
-- @param ffenv 1 to enable reflection, 0 to disable.
-- @class function
-- @name ffenv
ffenv = CAPI.texffenv

--- Reload a texture.
-- @param name Texture name.
-- @class function
-- @name reload
reload = CAPI.reloadtex

--- Generate dds for a texture.
-- @param infile Input file.
-- @param outfile Output file.
-- @class function
-- @name gendds
gendds = CAPI.gendds

---
-- @class function
-- @name flipnormalmapy
flipnormalmapy = CAPI.flipnormalmapy

--- Merge two normal maps (saving into the second one).
-- @param n1 First normal map.
-- @param n2 Second normal map.
-- @class function
-- @name mergenormalmaps
mergenormalmaps = CAPI.mergenormalmaps

--- Show texture slot GUI.
-- @class function
-- @name showgui
showgui = CAPI.showtexgui

--- DEPRECATED: replace
-- @class function
-- @name list
list = CAPI.listtex
--- DEPRECATED: replace
-- @class function
-- @name massreplace
massreplace = CAPI.massreplacetex
--- DEPRECATED: replace
-- @class function
-- @name edit
edit = CAPI.edittex
--- DEPRECATED: replace
-- @class function
-- @name get
get = CAPI.gettex
--- DEPRECATED: replace
-- @class function
-- @name getcur
getcur = CAPI.getcurtex
--- DEPRECATED: replace
-- @class function
-- @name getsel
getsel = CAPI.getseltex
--- DEPRECATED: replace
-- @class function
-- @name getrep
getrep = CAPI.getreptex
--- DEPRECATED: replace
-- @class function
-- @name getname
getname = CAPI.gettexname
