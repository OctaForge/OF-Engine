--[[! File: lua/core/engine/particles.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua particle API. Works on the client.
]]

local M = {}
if SERVER then return M end

local capi = require("capi")

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
local flags = {
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
    GROW   = bit.lshift(1, 20)
}
flags.FLIP = bit.bor(flags.HFLIP, flags.VFLIP, flags.ROT)
M.flags = flags

--[[! Variable: renderers
    Contains two predefined renderers that are mandatory - "text" and "icon".
]]
local renderers = {
    text = capi.particle_register_renderer_text("text"),
    icon = capi.particle_register_renderer_icon("icon")
}
M.renderers = renderers

--[[! Function: register_renderer_quad
    Registers a "quad renderer" (a renderer that draws individual textures)
    given a name (arbitrary), a texture path and optionally flags
    (see <flags>) and the id of the decal that gets spawned if the
    particle collides with geometry (happens on particles with gravity,
    such as snow). The id can be -1 - in such case the particles will
    collide but won't spawn any decal.

    Returns two values - a particle renderer id (which you will use when
    spawning particles) and a boolean value that is false if a renderer
    of such name was already registered (in such case it doesn't register
    anything, it simply returns the id of the already registered renderer)
    and true otherwise. This applies for all renderer registration
    functions, not only this one.
]]
M.register_renderer_quad = capi.particle_register_renderer_quad

--[[! Function: register_renderer_tape
    Registers a tape renderer. The parameters are the same.
    Look above for more information.
]]
M.register_renderer_tape = capi.particle_register_renderer_tape

--[[! Function: register_renderer_trail
    Registers a trail renderer. The parameters are the same.
    Look above for more information.
]]
M.register_renderer_trail = capi.particle_register_renderer_trail

--[[! Function: register_renderer_fireball
    Registers a fireball renderer given a name and a texture path.
    Look above for more information.
]]
M.register_renderer_fireball = capi.particle_register_renderer_fireball

--[[! Function: register_renderer_lightning
    Registers a lightning renderer given a name and a texture path.
    Look above for more information.
]]
M.register_renderer_lightning = capi.particle_register_renderer_lightning

--[[! Function: register_renderer_flare
    Registers a lens flare renderer given a name, a texture path
    and optionally a maximum flare count (defaults to 64) and flags.
    Look above for more information.
]]
M.register_renderer_flare = capi.particle_register_renderer_flare

--[[! Function: register_renderer_text
    Registers a text renderer given a name and optionally flags.
    Look above for more information.
]]
M.register_renderer_text = capi.particle_register_renderer_text

--[[! Function: register_renderer_icon
    Registers an icon renderer given a name and optionally flags.
    Look above for more information.
]]
M.register_renderer_icon = capi.particle_register_renderer_icon

--[[! Function: register_renderer_meter
    Registers a progress meter renderer given a name and a boolean
    specifying whether it's a two-color or one-color meter (if it's
    true, it has two colors, foreground and background; otherwise
    it has one color, foreground, on black) and optionally flags.
    Look above for more information.
]]
M.register_renderer_meter = capi.particle_register_renderer_meter

--[[! Function: get_renderer
    Given a name, returns the id of the renderer of that name
    or nothing (if no such renderer exists).
]]
M.get_renderer = capi.particle_get_renderer

--[[! Function: new
    Spawns a new generic particle given a type (renderer ID), origin
    position, target position, color (three floats typically from 0 to 1,
    can go out of bounds), fade time (in millis), size (float) and
    optionally gravity (defaults to 0) and owner (defaults to nil).

    Any dynamic entity can be an owner, it's used for particle tracking.
    Tracking is only enabled if the TRACK flag is on.

    Returns the particle object on which you can further set properties.
]]
M.new = function(tp, o, d, r, g, b, fade, size, gravity, owner)
    capi.particle_new(tp, o.x, o.y, o.z, d.x, d.y, d.z, r, g, b, fade,
        size, gravity or 0)
end

--[[! Function: splash
    Spawns a splash particle effect given a type, position, radius
    (an integer), number of particles, color, fade time, size and
    optionally gravity (defaults to 0), delay (defaults to 0), owner
    (defaults to nil) and a boolean that makes the splash unbounded
    when true (always keeps spawning particles).

    Returns true on success and false on failure (when invalid type is
    provided). The same applies for all subsequent particle effects.
]]
M.splash = function(tp, o, rad, num, r, g, b, fade, size, gravity, delay,
owner, un)
    return capi.particle_splash(tp, o.x, o.y, o.z, rad, num, r, g, b, fade,
        size, gravity or 0, delay or 0, owner, un)
end

--[[! Function: trail
    Spawns a trail particle effect given a type, origin position,
    target position, color, fade time, size and optionally gravity
    (defaults to 0) and owner (defaults to nil).
]]
M.trail = function(tp, o, d, r, g, b, fade, size, gravity, owner)
    return capi.particle_trail(tp, o.x, o.y, o.z, d.x, d.y, d.z, r, g, b,
        fade, size, gravity or 0, owner)
end

--[[! Function: text
    Spawns a text particle effect given a type, position, text string,
    color, fade time, size and optionally gravity (defaults to 0) and
    owner (defaults to nil).
]]
M.text = function(tp, o, text, r, g, b, fade, size, gravity, owner)
    return capi.particle_text(tp, o.x, o.y, o.z, text, r, g, b, fade, size,
        gravity or 0, owner)
end

--[[! Function: icon_generic
    Creates an icon. The renderer has to have an ICON flag set. The icons
    make a 4x4 grid - you have to provide the type, position, horizontal
    icon position in the texture (0 to 3), vertical position (0 to 3),
    color, fade time, size and optionally gravity (defaults to 0) and
    owner (defaults to nil).
]]
M.icon_generic = function(tp, o, ix, iy, r, g, b, fade, size, gravity, owner)
    return capi.particle_icon_generic(tp, o.x, o.y, o.z, ix, iy, r, g, b,
        fade, size, gravity or 0, owner)
end

--[[! Function: icon
    Creates an icon using a specialized icon renderer. You have to provide
    the type, position, texture path, color, fade time, size and optionally
    gravity (defaults to 0) and owner (defaults to nil).
]]
M.icon = function(tp, o, itex, r, g, b, fade, size, gravity, owner)
    return capi.particle_icon(tp, o.x, o.y, o.z, itex, r, g, b, fade, size,
        gravity or 0, owner)
end

--[[! Function: meter
    Creates a meter particle. You have to provide the type, position,
    value (from 0 to 100), color, fade time, size and optionally owner
    (defaults to nil). The background will be black here.
]]
M.meter = function(tp, o, val, r, g, b, fade, size, owner)
    return capi.particle_meter(tp, o.x, o.y, o.z, val, r, g, b, 0, 0, 0,
        fade, size, owner)
end

--[[! Function: meter_vs
    Similar to above, but you have to provide two sets of colors, the former
    specifying the foreground and the latter the background.
]]
M.meter_vs = function(tp, o, val, r, g, b, r2, g2, b2, fade, size, owner)
    return capi.particle_meter(tp, o.x, o.y, o.z, val, r, g, b, r2, g2, b2,
        fade, size, owner)
end

--[[! Function: flare
    Creates a flare particle effect given the type, origin position, target
    position, color, fade time, size and optionally owner (defaults to nil).
]]
M.flare = function(tp, o, d, r, g, b, fade, size, owner)
    return capi.particle_flare(tp, o.x, o.y, o.z, d.x, d.y, d.z, r, g, b,
        fade, size, owner)
end

--[[! Function: fireball
    Given a type, position, color, fade time, size, maximum size and optionally
    owner (defaults to nil), this creates a fireball effect.
]]
M.fireball = function(tp, o, r, g, b, fade, size, msize, owner)
    return capi.particle_fireball(tp, o.x, o.y, o.z, r, g, b, fade, size,
        msize, owner)
end

--[[! Function: lens_flare
    Creates a lens flare effect given a type, position, a boolean specifying
    whether it's a sun lens flare (fixed size regardless the distance), a
    boolean specifying whether to display a sparkle center and color.
]]
M.lens_flare = function(tp, o, sun, sparkle, r, g, b)
    return capi.particle_lensflare(tp, o.x, o.y, o.z, sun, sparkle, r, g, b)
end

--[[! Function: shape
    Creates a particle shape effect. You have to provide the type, position,
    radius, direction, number of particles, color, fade time, size and
    optionally gravity (defaults to 0), velocity (defaults to 200) and
    owner (defaults to nil).

    The direction argument specifies the shape. From 0 to 2 you get a circle,
    3 to 5 is a cylinder shell, 6 to 11 is a cone shell, 12 to 14 is a plane
    volume, 15 to 20 is a line volume (wall), 21 is a sphere, 24 to 26 is
    a flat plane and adding 32 reverses the direction.

    The remainder of division of the direction argument by 3 specifies the
    actual direction - 0 is x, 1 is y, 2 is z (up).
]]
M.shape = function(tp, o, rad, dir, num, r, g, b, fade, size, grav, vel, owner)
    return capi.particle_shape(tp, o.x, o.y, o.z, rad, dir, num, r, g, b, fade,
        size, grav or 0, vel or 200, owner)
end

--[[! Function: flame
    Creaets a flame particle effect. You have to provide the type, position,
    radius (float), height (float), color and optionally fade time (defaults
    to 600), density (defaults to 3), scale (defaults to 2), speed (defaults
    to 200), gravity (defaults to 15) and owner (defaults to nil).
]]
M.flame = function(tp, o, rad, h, r, g, b, fade, dens, sc, speed, grav, owner)
    return capi.particle_flame(tp, o.x, o.y, o.z, rad, h, r, g, b, fade or 600,
        dens or 3, sc or 2, speed or 200, grav or -15, owner)
end

return M
