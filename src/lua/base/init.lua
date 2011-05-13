--[[!
    File: base/init.lua

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
        - JSON parser
        - Signals system
        - Engine interface
        - Utility library
        - Console interface
        - GUI interface
        - Shader interface
        - Model interface
        - Action system
        - Message system
        - Entity storage
        - State variable system
        - Entity class system
        - Entity system
        - Effect system
        - Sound system
        - Animatable entities
        - Character
        - Static entities
        - Texture interface
        - World interface

    Section: Base library initialization
]]

-- see world metatable below
local gravity

logging.log(logging.DEBUG, ":: Library system.")
require("base.base_library")

logging.log(logging.DEBUG, ":: JSON.")
require("base.base_json")

logging.log(logging.DEBUG, ":: Signals.")
require("base.base_signals")

logging.log(logging.DEBUG, ":: Engine interface.")
require("base.base_engine")


--[[!
    Class: _G
    Overriden metamethods for transparentyl getting / setting
    engine variables. If engine variable exists, it's returned,
    otherwise normal variable is returned. Same applies for
    setting.
]]
setmetatable(_G, {
    --[[!
        Function: __index
        This is overriden metamethod for getting.
        It returns engine variable if it exists,
        normal variable otherwise.

        Parameters:
            self - the table
            n - name of the variable we're getting

        Returns:
            either engine variable or normal variable.
    ]]
    __index = function(self, n)
        return (engine.varexists(n) and
            engine.getvar(n) or
            rawget(self, n)
        )
    end,

    --[[!
        Function: __newindex
        This is overriden metamethod for setting.
        It sets engine variable if it exists or normal
        one otherwise.

        Parameters:
            self - the table
            n - name of the variable we're setting
            v - value we're setting
    ]]
    __newindex = function(self, n, v)
        if engine.varexists(n) then
            engine.setvar(n, v)
        else
            rawset(self, n, v)
        end
    end
})

logging.log(logging.DEBUG, ":: Utilities.")
require("base.base_utility")

logging.log(logging.DEBUG, ":: Console.")
require("base.base_console")

logging.log(logging.DEBUG, ":: GUI.")
require("base.base_gui")

logging.log(logging.DEBUG, ":: Shaders.")
require("base.base_shaders")

logging.log(logging.DEBUG, ":: Models.")
require("base.base_models")

logging.log(logging.DEBUG, ":: Action system.")
require("base.base_actions")

logging.log(logging.DEBUG, ":: Message system.")
require("base.base_messages")

logging.log(logging.DEBUG, ":: Logic entity storage.")
require("base.base_ent_store")

logging.log(logging.DEBUG, ":: State variables.")
require("base.base_svars")

logging.log(logging.DEBUG, ":: Logic entity classes.")
require("base.base_ent_classes")

logging.log(logging.DEBUG, ":: Logic entities.")
require("base.base_ent")

logging.log(logging.DEBUG, ":: Effects.")
require("base.base_effects")

logging.log(logging.DEBUG, ":: Sound.")
require("base.base_sound")

logging.log(logging.DEBUG, ":: Animatables.")
require("base.base_ent_anim")

logging.log(logging.DEBUG, ":: Character.")
require("base.base_character")

logging.log(logging.DEBUG, ":: Static entities.")
require("base.base_ent_static")

logging.log(logging.DEBUG, ":: Textures.")
require("base.base_textures")

logging.log(logging.DEBUG, ":: World interface.")
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

logging.log(logging.DEBUG, ":: Network interface.")
require("base.base_network")

logging.log(logging.DEBUG, ":: Camera.")
require("base.base_camera")
