--[[! File: lua/core/engine/decals.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua decal API.
]]

local bit = require("bit")

return {
    --[[! Variable: flags
        The flags available during decal renderer registration. Use bitwise
        OR to combine them. They include RND4 (picks one of four corners),
        ROTATE, INVMOD, OVERBRIGHT, ADD, SATURATE.
    ]]
    flags = {
        RND4       = bit.lshift(1, 0),
        ROTATE     = bit.lshift(1, 1),
        INVMOD     = bit.lshift(1, 2),
        OVERBRIGHT = bit.lshift(1, 3),
        ADD        = bit.lshift(1, 4),
        SATURATE   = bit.lshift(1, 5)
    },

    --[[! Function: register_renderer
        Given a name (you can select any you want), a decal texture path
        and optionally flags (see above), fade in time, fade out time and
        timeout time, this registers a new decal renderer and returns two
        values - a decal renderer id (which you use when spawning decals)
        and a boolean value that is false if a renderer of such name was
        already registered (in such case it doesn't register anything,
        it simply returns the id of the already registered renderer)
        and true otherwise.
    ]]
    register_renderer = _C.decal_register_renderer,

    --[[! Function: get_renderer
        Given a name, returns the id of the renderer of that name or
        nothing (if no such renderer exists).
    ]]
    get_renderer = _C.decal_get_renderer,

    --[[! Function: add
        Creates a decal given its type (the integer returned by renderer
        registration), center position (anything with x, y, z will do),
        surface normal (again, a vec3), radius, color and optionally an
        "info" parameter that decides the corner used (number from 0 to
        3).
    ]]
    add = function(tp, op, sp, rad, r, g, b, inf)
        _C.decal_add(tp, op.x, op.y, op.z, sp.x, sp.y, sp.z, rad, r, g, b, inf)
    end
}
