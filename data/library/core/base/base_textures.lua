--[[!
    File: base/base_textures.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features texture handling interface.
]]

local env = _G

--[[!
    Package: texture
    This module controls textures (their registration and manipulation) and
    texture blending for i.e. heightmap.
]]
module("texture", package.seeall)

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
-- @param n1 First normal blendmap.
-- @param n2 Second normal blendmap.
-- @class function
-- @name mergenormalmaps
mergenormalmaps = CAPI.mergenormalmaps

--- DEPRECATED: replace
-- @class function
-- @name edit
edit = CAPI.edittex
--- DEPRECATED: replace
-- @class function
-- @name get
get = CAPI.gettex
set = CAPI.settex
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

--- Table holding methods relating texture blending brushes.
-- @class table
-- @name blendbrush
blendbrush = {}

--- Clear all blend brushes.
-- @class function
-- @name blendbrush.clearall
blendbrush.clearall = CAPI.clearblendbrushes

--- Delete a blend blendbrush.
-- @param name Name of the blendbrush.
-- @class function
-- @name blendbrush.del
blendbrush.del = CAPI.delblendbrush

--- Add a blend blendbrush.
-- @param name Name of the blendbrush.
-- @param imgn Name of the image file defining the blendbrush.
-- @class function
-- @name blendbrush.add
blendbrush.add = CAPI.addblendbrush

--- Move to next blend blendbrush.
-- @param dir Movement direction. 1 means next, -1 previous. Optional.
-- @class function
-- @name blendbrush.next
-- @see blendbrush.scroll
blendbrush.next = CAPI.nextblendbrush

--- Select a blend blendbrush.
-- @param name Name of the blendbrush.
-- @class function
-- @name blendbrush.set
blendbrush.set = CAPI.setblendbrush

--- Get blend brush name.
-- @param num Number of the blendbrush.
-- @return Name of the blendbrush.
-- @class function
-- @name blendbrush.getname
blendbrush.getname = CAPI.getblendbrushName

--- Get current blend brush number.
-- @return Current blend brush number.
-- @class function
-- @name blendbrush.cur
blendbrush.cur = CAPI.curblendbrush

--- Rotate a blend blendbrush.
-- @param n Rotation level. Number from 1 to 5.
-- @class function
-- @name blendbrush.rotate
blendbrush.rotate = CAPI.rotateblendbrush

--- Scroll blend blendbrush. Prints nice output while scrolling.
-- @param b Optional direction (see blendbrush.next)
-- @see blendbrush.next
function blendbrush.scroll(b)
    if b then blendbrush.next(b) else blendbrush.next() end
    echo("blend brush set to: %(1)s" % { blendbrush.getname(blendbrush.cur()) })
end

--- Table holding methods relating texture blend painting.
-- @class table
-- @name blendmap
blendmap = {}

--- Toggle blendmap painting.
-- @class function
-- @name blendmap.paint
blendmap.paint = CAPI.paintblendmap

--- Clear blend map selection.
-- @class function
-- @name blendmap.clearsel
blendmap.clearsel = CAPI.clearblendmapsel

--- Invert blend map selection.
-- @class function
-- @name blendmap.invertsel
blendmap.invertsel = CAPI.invertblendmapsel

--- Invert blend blendmap.
-- @class function
-- @name blendmap.invert
blendmap.invert = CAPI.invertblendmap

--- Show blend blendmap.
-- @class function
-- @name blendmap.show
blendmap.show = CAPI.showblendmap

--- Optimize blend blendmap.
-- @class function
-- @name blendmap.optimize
blendmap.optimize = CAPI.optimizeblendmap

--- Clear blend blendmap.
-- @class function
-- @name blendmap.clear
blendmap.clear = CAPI.clearblendmap

--- Blend map painting modes.
-- @field off Blendmap painting is off.
-- @field replace Replace / clear layer.
-- @field dig min(dest, src) - Dig where black is the dig pattern.
-- @field fill max(dest, src) - Fill where white is the fill pattern.
-- @field inverted_dig min(dest, invert(src)) - Dig where white is the dig pattern.
-- @field inverted_fill max(Dest, invert(src)) - Fill where black is the fill pattern.
-- @class table
-- @name blendpaintmodes
blendpaintmodes = { "off", "replace", "dig", "fill", "inverted dig", "inverted fill" }

--- Set blend paint mode.
-- @param m Paint mode index in blendpaintmodes table, beginning with 1. Turns blendmap painting off when not ommited.
function setblendpaintmode(m)
    env.blendpaintmode = m or 1
    echo("blend paint mode set to: %(1)s" % { blendpaintmodes[env.blendpaintmode] })
end

filltexlist = CAPI.filltexlist
getnumslots = CAPI.getnumslots

---
-- @class function
-- @name replace
replace = CAPI.replace

---
-- @class function
-- @name replacesel
replacesel = CAPI.replacesel
