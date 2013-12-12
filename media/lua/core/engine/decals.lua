--[[!<
    Lua decal API. Works on the client.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

if SERVER then return {} end

local capi = require("capi")

--! Module: decals
return {
    --[[!
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
        Registers a new decal renderer.

        Arguments:
            - name - the renderer name.
            - tex - the decal texture name.
            - flags - the optional decal renderer flags.

        Returns:
            The decal renderer id (an integer, use it for spawning decals)
            and a boolean which is false if a renderer of such name is
            already registered (in this case the id returned belongs to
            the registered renderer).

        See also:
            - $flags
    ]]
    register_renderer = capi.decal_register_renderer,

    --[[! Function: get_renderer
        Given a name, returns the id of the renderer of that name or
        nothing (if no such renderer exists).
    ]]
    get_renderer = capi.decal_get_renderer,

    --[[!
        Creates a decal.

        Arguments:
            - tp - the decal renderer id.
            - op - the origin position (any value with x, y, z).
            - sp - a surface normal vector (again, any value with x, y, z).
            - rad - the decal radius (a float).
            - r, g, b - the decal color (floats, typically from 0 to 1).
            - info - optional, specifies the corner to use if it's rnd4
              (0 to 3).
    ]]
    add = function(tp, op, sp, rad, r, g, b, inf)
        capi.decal_add(tp, op.x, op.y, op.z, sp.x, sp.y, sp.z, rad, r, g, b,
            inf or 0)
    end
}
