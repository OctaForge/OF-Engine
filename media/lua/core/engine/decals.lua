--[[! File: lua/core/engine/decals.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        Lua decal API. Works on the client.
]]

if SERVER then return {} end

local capi = require("capi")

return {
    --[[! Variable: flags
        The flags available during decal renderer registration. Use bitwise
        OR to combine them. They include RND4 (picks one of four corners),
        ROTATE, INVMOD, OVERBRIGHT, GLOW, SATURATE.
    ]]
    flags = {:
        RND4       = 1 << 0,
        ROTATE     = 1 << 1,
        INVMOD     = 1 << 2,
        OVERBRIGHT = 1 << 3,
        GLOW       = 1 << 4,
        SATURATE   = 1 << 5
    :},

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
    register_renderer = capi.decal_register_renderer,

    --[[! Function: get_renderer
        Given a name, returns the id of the renderer of that name or
        nothing (if no such renderer exists).
    ]]
    get_renderer = capi.decal_get_renderer,

    --[[! Function: add
        Creates a decal given its type (the integer returned by renderer
        registration), center position (anything with x, y, z will do),
        surface normal (again, a vec3), radius, color and optionally an
        "info" parameter that decides the corner used (number from 0 to
        3).
    ]]
    add = function(tp, op, sp, rad, r, g, b, inf)
        capi.decal_add(tp, op.x, op.y, op.z, sp.x, sp.y, sp.z, rad, r, g, b,
            inf or 0)
    end
}
