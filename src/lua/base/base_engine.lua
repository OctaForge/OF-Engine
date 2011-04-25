---
-- base_engine.lua, version 1<br/>
-- Engine interface for Lua<br/>
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

--- Engine interface for OF's Lua.
-- @class module
-- @name of.engine
module("of.engine")

--- Quit the engine, showing a dialog when there are unsaved changes.
-- @class function
-- @name quit
quit = CAPI.quit

--- Quit the engine without asking for anything.
-- @class function
-- @name force_quit
force_quit = CAPI.force_quit

--- Reload graphics subsystem of the engine. 
-- @class function
-- @name resetgl
resetgl = CAPI.resetgl

--- Check for available OpenGL extension.
-- @param ext The extension to check for.
-- @return 1 if extension is available, 0 otherwise. (TODO: change to booleans)
-- @class function
-- @name glext
glext = CAPI.glext

--- Get current frame rate.
-- @return Frame rate.
-- @class function
-- @name getfps
getfps = CAPI.getfps

--- Take a screenshot.
-- @param name Screenshot will get saved as name.png.
-- @class function
-- @name screenshot
screenshot = CAPI.screenshot

--- Record an ingame video. WARNING: videos are huge!
-- Controlled by engine variables (moview, movieh,
-- moviesound, moviefps, moviesync, movieaccel,
-- movieaccelyuv, movieaccelblit)
-- @param name Movie will get recorded into name.avi.
-- @class function
-- @name movie
movie = CAPI.movie
