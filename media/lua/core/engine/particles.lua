--[[! File: lua/core/engine/particles.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua particle API.
]]

local bit = require("bit")

return {
    --[[! Variable: flags
        The flags available during particle renderer registration. Use bitwise
        OR to combine them. They include MOD (multiplied), RND4 (picks one of
        the corners at random), LERP (use sparingly, has order of blending
        issues), TRACK (for tracked particles with owner, mainly for
        muzzleflashes), BRIGHT, SOFT, HFLIP/VFLIP (randomly flipped),
        ROT (randomly rotated), FEW (initializes the renderer with fewparticles
        instead of maxparticles if it's lower), ICON (4x4 icon grid), SHRINK
        (particle will keep shrinking), GROW (particle will keep growing),
        FLIP (a combination of HFLIP, VFLIP and ROT).
    ]]
    flags = {
        MOD    = bit.lshift(1, 8),
        RND4   = bit.lshift(1, 9),
        LERP   = bit.lshift(1, 10),
        TRACK  = bit.lshift(1, 11),
        BRIGHT = bit.lshift(1, 12),
        SOFT   = bit.lshift(1, 13),
        HFLIP  = bit.lshift(1, 14),
        VFLIP  = bit.lshift(1, 15),
        ROT    = bit.lshift(1, 16),
        FEW    = bit.lshift(1, 17),
        ICON   = bit.lshift(1, 18),
        SHRINK = bit.lshift(1, 19),
        GROW   = bit.lshift(1, 20),
        FLIP   = bit.bor(bit.lshift(1, 14), bit.lshift(1, 15),
            bit.lshift(1, 16))
    }
}
