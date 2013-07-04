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

    --[[! Function: new
        Spawns a new generic particle, given a type (renderer ID), origin
        position, target position, color (three floats typically from 0 to 1,
        can go out of bounds), fade time (in millis), size (float) and
        optionally gravity (defaults to 0).
    ]]
    new = function(tp, o, d, r, g, b, fade, size, gravity)
        _C.particle_new(tp, o.x, o.y, o.z, d.x, d.y, d.z, r, g, b, fade,
            size, gravity or 0)
    end,

    --[[! Function: splash
        Spawns a splash particle effect, given a type, position, radius
        (an integer), number of particles, color, fade time, size and
        optionally gravity (defaults to 0), delay (defaults to 0) and
        a boolean that makes the splash unbounded when true (always
        keeps spawning particles).
    ]]
    splash = function(tp, o, rad, num, r, g, b, fade, size, gravity, delay, un)
        _C.particle_splash(tp, o.x, o.y, o.z, rad, num, r, g, b, fade, size,
            gravity or 0, delay or 0, un)
    end,

    trail = function(tp, o, d, r, g, b, fade, size, gravity)
        _C.particle_trail(tp, o.x, o.y, o.z, d.x, d.y, d.z, r, g, b, fade,
            size, gravity or 0)
    end,

    text = function(tp, o, text, r, g, b, fade, size, gravity)
        _C.particle_text(tp, o.x, o.y, o.z, text, r, g, b, fade, size,
            gravity or 0)
    end,

    icon_generic = function(tp, o, ix, iy, r, g, b, fade, size, gravity)
        _C.particle_icon_generic(tp, o.x, o.y, o.z, ix, iy, r, g, b, fade,
            size, gravity or 0)
    end,

    icon = function(tp, o, itex, r, g, b, fade, size, gravity)
        _C.particle_icon(tp, o.x, o.y, o.z, itex, r, g, b, fade, size,
            gravity or 0)
    end,

    meter = function(tp, o, val, r, g, b, fade, size)
        _C.particle_meter(tp, o.x, o.y, o.z, val, r, g, b, 0, 0, 0, fade, size)
    end,

    meter_vs = function(tp, o, val, r, g, b, r2, g2, b2, fade, size)
        _C.particle_meter(tp, o.x, o.y, o.z, val, r, g, b, r2, g2, b2, fade,
            size)
    end,

    flare = function(tp, o, d, r, g, b, fade, size, owner)
        _C.particle_flare(tp, o.x, o.y, o.z, d.x, d.y, d.z, r, g, b, fade,
            size, owner)
    end,

    fireball = function(tp, o, r, g, b, fade, size, maxsize)
        _C.particle_fireball(tp, o.x, o.y, o.z, r, g, b, fade, size, maxsize)
    end,

    lens_flare = function(tp, o, sun, sparkle, r, g, b)
        _C.particle_lensflare(tp, o.x, o.y, o.z, sun, sparkle, r, g, b)
    end,

    shape = function(tp, o, rad, dir, num, r, g, b, fade, size, gravity, vel)
        _C.particle_shape(tp, o.x, o.y, o.z, rad, dir, num, r, g, b, fade,
            size, gravity or 0, vel or 200)
    end,

    flame = function(tp, o, rad, h, r, g, b, fade, dens, scale, speed, grav)
        _C.particle_flame(tp, o.x, o.y, o.z, rad, h, r, g, b, fade or 600,
            dens or 3, scale or 2, speed or 200, grav or -15)
    end
}
