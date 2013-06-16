--[[!
    File: lua/core/base/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file takes care of properly loading all modules of OctaForge
        base library.
]]

-- see world metatable below
local gravity

#log(DEBUG, ":: Effects.")
require("core.base.base_effects")

#log(DEBUG, ":: World interface.")
require("core.base.base_world")

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
        If we're setting gravity, set it via _C.
        Set "world" member otherwise.

        Parameters:
            self - the table
            n - name of the variable we're setting
            v - value we're setting
    ]]
    __newindex = function(self, n, v)
        if n == "gravity" then
            _C.setgravity(v)
            gravity = v
        else
            rawset(self, n, v)
        end
    end
})

world.gravity = 200
