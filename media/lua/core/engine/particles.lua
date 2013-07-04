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
    },

    --[[! Function: register_renderer_quad
        Registers a "quad renderer" (a renderer that draws individual textures)
        given a name (arbitrary), a texture path and optionally flags
        (see <flags>) and the id of the decal that gets spawned if the
        particle collides with geometry (happens on particles with gravity,
        such as snow).

        Returns two values - a particle renderer id (which you will use when
        spawning particles) and a boolean value that is false if a renderer
        of such name was already registered (in such case it doesn't register
        anything, it simply returns the id of the already registered renderer)
        and true otherwise. This applies for all renderer registration
        functions, not only this one.
    ]]
    register_renderer_quad = _C.particle_register_renderer_quad,

    --[[! Function: register_renderer_tape
        Registers a tape renderer. The parameters are the same.
        Look above for more information.
    ]]
    register_renderer_tape = _C.particle_register_renderer_tape,

    --[[! Function: register_renderer_trail
        Registers a trail renderer. The parameters are the same.
        Look above for more information.
    ]]
    register_renderer_trail = _C.particle_register_renderer_trail,

    --[[! Function: register_renderer_fireball
        Registers a fireball renderer, given a name and a texture path.
        Look above for more information.
    ]]
    register_renderer_fireball = _C.particle_register_renderer_fireball,

    --[[! Function: register_renderer_lightning
        Registers a lightning renderer, given a name and a texture path.
        Look above for more information.
    ]]
    register_renderer_lightning = _C.particle_register_renderer_lightning,

    --[[! Function: register_renderer_flare
        Registers a lens flare renderer, given a name, a texture path
        and optionally a maximum flare count (defaults to 64) and flags.
        Look above for more information.
    ]]
    register_renderer_flare = _C.particle_register_renderer_flare,

    --[[! Function: register_renderer_meter
        Registers a progress meter renderer, given a name and a boolean
        specifying whether it's a two-color or one-color meter (if it's
        true, it has two colors, foreground and background; otherwise
        it has one color, foreground, on black) and optionally flags.
        Look above for more information.
    ]]
    register_renderer_meter = _C.particle_register_renderer_meter,

    --[[! Function: get_renderer
        Given a name, returns the id of the renderer of that name
        or nothing (if no such renderer exists).
    ]]
    get_renderer = _C.particle_get_renderer,

    
}
