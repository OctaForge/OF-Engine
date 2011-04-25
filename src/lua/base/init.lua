---
-- init.lua, version 1<br/>
-- Loader for all base files.<br/>
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

-- see of.world metatable below
local gravity

of.logging.log(of.logging.DEBUG, ":: JSON.")
require("base.base_json")

of.logging.log(of.logging.DEBUG, ":: Signals.")
require("base.base_signals")

of.logging.log(of.logging.DEBUG, ":: Platform.")
require("base.base_platform")

of.logging.log(of.logging.DEBUG, ":: Engine variables.")
require("base.base_evars")

--- Metatable for global table made for transparently
-- getting / setting engine variables. If engine variable
-- exists, it gets it on __index, otherwise it gets standard
-- lua variable. Same applies for __newindex, just for setting.
-- @class table
-- @name _G_metatable
-- @field __index Called when a value is got.
-- @field __newindex Called when a value is set.
setmetatable(_G, {
    __index = function(self, n)
        return (of.engine_variables.inst.stor[n] and
            of.engine_variables.inst[n] or
            rawget(self, n)
        )
    end,
    __newindex = function(self, n, v)
        if of.engine_variables.inst.stor[n] then
            of.engine_variables.inst[n] = v
        else
            rawset(self, n, v)
        end
    end
})

require("base.stub_logent")
require("base.stub_logent_classes")

of.logging.log(of.logging.DEBUG, ":: Utilities.")
require("base.base_utils")

of.logging.log(of.logging.DEBUG, ":: Color conversion.")
require("base.base_colors")

of.logging.log(of.logging.DEBUG, ":: Console.")
require("base.base_console")

of.logging.log(of.logging.DEBUG, ":: GUI.")
require("base.base_gui")

of.logging.log(of.logging.DEBUG, ":: Shaders.")
require("base.base_shaders")

of.logging.log(of.logging.DEBUG, ":: Models.")
require("base.base_models")

of.logging.log(of.logging.DEBUG, ":: Texture blending.")
require("base.base_blend")

of.logging.log(of.logging.DEBUG, ":: Action system.")
require("base.base_actions")

of.logging.log(of.logging.DEBUG, ":: Message system.")
require("base.base_msgsys")

of.logging.log(of.logging.DEBUG, ":: Logic entity storage.")
require("base.base_logent_store")

of.logging.log(of.logging.DEBUG, ":: State variables.")
require("base.base_svars")

of.logging.log(of.logging.DEBUG, ":: Logic entity classes.")
require("base.base_logent_classes")

of.logging.log(of.logging.DEBUG, ":: Logic entities.")
require("base.base_logent")

of.logging.log(of.logging.DEBUG, ":: Effects.")
require("base.base_effects")

of.logging.log(of.logging.DEBUG, ":: Sound.")
require("base.base_sound")

of.logging.log(of.logging.DEBUG, ":: Animatables.")
require("base.base_animatable")

of.logging.log(of.logging.DEBUG, ":: Character.")
require("base.base_character")

of.logging.log(of.logging.DEBUG, ":: Static entities.")
require("base.base_statent")

of.logging.log(of.logging.DEBUG, ":: Textures.")
require("base.base_textures")

of.logging.log(of.logging.DEBUG, ":: World interface.")
require("base.base_world")

--- Metatable for world for setting gravity.
-- @class table
-- @name world_metatable
-- @field __index Called when a value is got.
-- @field __newindex Called when a value is set.
setmetatable(of.world, {
    __index = function(self, n)
        return (n == "gravity" and gravity or rawget(self, n))
    end,
    __newindex = function(self, n, v)
        if n == "gravity" then
            CAPI.setgravity(v)
            gravity = v
        else
            rawset(self, n, v)
        end
    end
})

of.world.gravity = 200

of.logging.log(of.logging.DEBUG, ":: Network interface.")
require("base.base_network")

of.logging.log(of.logging.DEBUG, ":: Camera.")
require("base.base_camera")

of.logging.log(of.logging.DEBUG, ":: Engine interface.")
require("base.base_engine")
