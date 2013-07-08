--[[! File: lua/core/engine/lights.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua light API. You typically need to run each of the functions every
        frame to make it continuous (unless there are extended fade times
        or something else).
]]

local capi = require("capi")

return {
    --[[! Variable: flags
        Provides the available flags for <add> and <add_spot>. Includes
        SHRINK (shrinking light), EXPAND (expanding light) and FLASH
        (flashing light).
    ]]
    flags = {
        SHRINK = bit.lshift(1, 0),
        EXPAND = bit.lshift(1, 1),
        FLASH  = bit.lshift(1, 2)
    },

    --[[! Function: add
        Creates a light at the given position, with the given radius and
        color. The other parameters are optional, namely the fadeout time
        (in milliseconds), the peak time (in milliseconds), flags (see
        above), initial radius and initial color (specified as r, g, b)
        and owner (which is an entity and is used for tracking).

        Colors are specified as floats typically from 0 to 1 (but it can
        go outside this range). Position can be any object indexable
        with x, y and z. The function returns true.
    ]]
    add = function(pos, rad, r, g, b, fade, peak, flags, irad, ir, ig, ib, own)
        capi.dynlight_add(pos.x, pos.y, pos.z, rad, r, g, b, fade, peak,
            flags, irad, ir, ig, ib, own)
    end,

    --[[! Function: add_spot
        Creates a spotlight. It works similarly to above. You need to provide
        the origin position, the direction (which should be normalized),
        radius, spotlight angle (specifies the angle of the wedge, how "open"
        it is), the color and further optional parameters that are identical
        to <add>.
    ]]
    add_spot = function(from, dir, rad, spot, r, g, b, fade, peak, flags, irad,
    ir, ig, ib, own)
        capi.dynlight_add_spot(from.x, from.y, from.z, dir.x, dir.y, dir.z,
            rad, spot, r, g, b, fade, peak, flags, irad, ir, ig, ib, own)
    end
}
