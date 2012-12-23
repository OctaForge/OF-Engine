--[[!
    File: library/core/base/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file takes care of properly loading all modules of OctaForge
        base library.

        It loads:
        - Library system
        - Engine interface
        - Utility library
        - Geometry library
        - Console interface
        - Shader interface
        - Model interface
        - Action system
        - Message system
        - Entity storage
        - Entity class system
        - Entity system
        - Effect system
        - Sound system
        - Animatable entities
        - Character
        - Static entities
        - Texture interface
        - World interface
]]

-- see world metatable below
local gravity

log(DEBUG, ":: Engine interface.")
require("base.base_engine")

log(DEBUG, ":: Geometry interface.")
require("base.base_geometry")

log(DEBUG, ":: Input.")
require("base.base_input")

log(DEBUG, ":: Console.")
require("base.base_console")

log(DEBUG, ":: Shaders.")
require("base.base_shaders")

log(DEBUG, ":: Models.")
require("base.base_models")

log(DEBUG, ":: Effects.")
require("base.base_effects")

log(DEBUG, ":: Sound.")
require("base.base_sound")

log(DEBUG, ":: Character.")
require("base.base_character")

log(DEBUG, ":: Static entities.")
require("base.base_ent_static")

log(DEBUG, ":: Textures.")
require("base.base_textures")

log(DEBUG, ":: VSlots.")
require("base.base_vslots")

log(DEBUG, ":: Editing.")
require("base.base_editing")

log(DEBUG, ":: World interface.")
require("base.base_world")

--[[!
    Class: world
    Overriden metamethods for getting / setting gravity.
    Gravity defaults to 200.
]]
setmetatable(world, {
    --[[!
        Function: __index
        If we're getting gravity, return it from globals.
        Get "world" member otherwise.

        Parameters:
            self - the table
            n - name of the variable we're getting

        Returns:
            either gravity or "world" member.
    ]]
    __index = function(self, n)
        return (n == "gravity" and gravity or rawget(self, n))
    end,

    --[[!
        Function: __newindex
        If we're setting gravity, set it via CAPI.
        Set "world" member otherwise.

        Parameters:
            self - the table
            n - name of the variable we're setting
            v - value we're setting
    ]]
    __newindex = function(self, n, v)
        if n == "gravity" then
            CAPI.setgravity(v)
            gravity = v
        else
            rawset(self, n, v)
        end
    end
})

world.gravity = 200

log(DEBUG, ":: Camera.")
require("base.base_camera")
