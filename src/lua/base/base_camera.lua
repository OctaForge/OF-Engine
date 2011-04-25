---
-- base_camera.lua, version 1<br/>
-- Camera interface for Lua<br/>
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

local CAPI = require("CAPI")

--- Camera for OF's Lua interface.
-- @class module
-- @name of.camera
module("of.camera")

--- Force yaw, pitch, roll and fov of a camera.
-- @param yaw Yaw to force.
-- @param pitch Pitch to force.
-- @param roll Roll to force.
-- @param fov Field of view to force.
-- @class function
-- @name forcecam
forcecam = CAPI.forcecam

--- Force camera position.
-- @param x X position.
-- @param y Y position.
-- @param z Z position.
-- @class function
-- @name forcepos
forcepos = CAPI.forcepos

--- Force camera yaw.
-- @param yaw Yaw to force.
-- @class function
-- @name forceyaw
forceyaw = CAPI.forceyaw

--- Force camera pitch.
-- @param pitch Pitch to force.
-- @class function
-- @name forcepitch
forcepitch = CAPI.forcepitch

--- Force camera roll.
-- @param roll Roll to force.
-- @class function
-- @name forceroll
forceroll = CAPI.forceroll

--- Force camera fov.
-- @param fov Field of view to force.
-- @class function
-- @name forcefov
forcefov = CAPI.forcefov

--- Reset camera (cancel all forcing)
-- @class function
-- @name resetcam
resetcam = CAPI.resetcam

--- Get a table containing position
-- as a vec3, yaw, pitch and roll.
-- @return A table with camera info.
-- @class function
-- @name getcam
getcam = CAPI.getcam

--- Get camera position. Possibly
-- DEPRECATED, because getcam is
-- sufficient enough.
-- @return A vec3 with camera position.
-- @class function
-- @name getcampos
getcampos = CAPI.getcampos

--- Increase camera zoom.
-- @class function
-- @name caminc
caminc = CAPI.caminc

--- Decrease camera zoom.
-- @class function
-- @name camdec
camdec = CAPI.camdec

--- Toggle mouse looking.
-- @class function
-- @name mouselook
mouselook = CAPI.mouselook

--- Toggle character viewing.
-- @class function
-- @name characterview
characterview = CAPI.characterview

--- Set third person mode as default.
-- DEPRECATED - engine variable
-- access is sufficient enough.
-- @class function
-- @name setdeftpm
setdeftpm = CAPI.setdeftpm
