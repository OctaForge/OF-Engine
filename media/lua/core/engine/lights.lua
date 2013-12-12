--[[!<
    Lua light API. You typically need to run each of the functions every
    frame to make it continuous (unless there are extended fade times
    or something else).

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")

--! Module: lights
return {
    --[[!
        Provides the available flags for $add and $add_spot. Includes
        SHRINK (shrinking light), EXPAND (expanding light) and FLASH
        (flashing light).
    ]]
    flags = {:
        SHRINK = 1 << 0,
        EXPAND = 1 << 1,
        FLASH  = 1 << 2
    :},

    --[[!
        Creates a light with the given parameters, for one frame unless
        you specify the extended parameters.

        Arguments:
            - pos - the light position (any value with x, y, z).
            - rad - the light radius.
            - r, g, b - the light color (floats typically from 0 to 1,
              can go outside this range).
            - fade - optional fadeout time in milliseconds.
            - peak - optional peak time (in milliseconds).
            - flags - see $flags (optional).
            - irad - optional initial light radius.
            - ir, ig, ib - optional initial light color.
            - own - optional light owner (a reference to an entity, used
              for tracking on e.g. gun lights).

        See also:
            - $add_spot
    ]]
    add = function(pos, rad, r, g, b, fade, peak, flags, irad, ir, ig, ib, own)
        capi.dynlight_add(pos.x, pos.y, pos.z, rad, r, g, b, fade, peak,
            flags, irad, ir, ig, ib, own)
    end,

    --[[!
        Creates a spotlight that works similarly as above.

        Arguments:
            - pos - the light origin position (any value with x, y, z).
            - dir - the light direction vector (any value with x, y, z).
            - rad - the light radius.
            - spot - the spotlight angle (angle of the wedge).
            - r, g, b - the light color (floats typically from 0 to 1,
              can go outside this range).
            - fade - optional fadeout time in milliseconds.
            - peak - optional peak time (in milliseconds).
            - flags - see $flags (optional).
            - irad - optional initial light radius.
            - ir, ig, ib - optional initial light color.
            - own - optional light owner (a reference to an entity, used
              for tracking on e.g. gun lights).

        See also:
            - $add
    ]]
    add_spot = function(from, dir, rad, spot, r, g, b, fade, peak, flags, irad,
    ir, ig, ib, own)
        capi.dynlight_add_spot(from.x, from.y, from.z, dir.x, dir.y, dir.z,
            rad, spot, r, g, b, fade, peak, flags, irad, ir, ig, ib, own)
    end
}
