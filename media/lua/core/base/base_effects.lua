--[[!
    File: lua/core/base/base_effects.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features effects (particle system, dynamic lights etc.).
        DEPRECATED for OF API v2 (Stays in v1).
]]

local msg = require("core.network.msg")

local hextorgb = require("core.lua.conv").hex_to_rgb

--[[!
    Package: effects
    This module contains effect interface,
    such as particle system, dynamic lights
    and others.
]]
module("effects", package.seeall)

--[[!
    Variable: DECAL
    This table specifies decal types. It's in sync with iengine.h header.

    Fields:
        SCORCH - scorch decal, used i.e. after explosions.
        BLOOD - blood decal, used for blood splatters on geometry.
        BULLET - bullet decal, used to mark a
        place after it's being shot by a bullet.
]]
DECAL = {
    SCORCH = 0,
    BLOOD = 1,
    BULLET = 2
}

--[[!
    Variable: PARTICLE
    This table specifies particle types. It's in sync with iengine.h header.

    Fields:
        BLOOD - blood particle used for immediate blood splatters on hit.
        WATER - water "fountain" particle.
        SMOKE - smoke particle.
        STEAM - steam particle.
        FLAME - flame particle.
        FIREBALL1 - first variant of fireball - these are deprecated.
        FIREBALL2 - second variant of fireball - these are deprecated.
        FIREBALL3 - third variant of fireball - these are deprecated.
        STREAK - streak particle.
        LIGHTNING - lightning particle.
        EXPLOSION - explosion particle.
        EXPLOSION_BLUE - blue explosion.
        SPARK - spark particle.
        EDIT - edit mode particle, deprecated now (uses icons).
        MUZZLE_FLASH1 - muzzle flash particle.
        MUZZLE_FLASH2 - muzzle flash particle.
        MUZZLE_FLASH3 - muzzle flash particle.
        TEXT - text particle.
        METER - meter particle (rgb vs black)
        METER_VS - metervs particle (rgb vs bgr).
        LENS_FLARE - lens flare particle.
]]
PARTICLE = {
    BLOOD = 0,
    WATER = 1,
    SMOKE = 2,
    STEAM = 3,
    FLAME = 4,
    FIREBALL1 = 5,
    FIREBALL2 = 6,
    FIREBALL3 = 7,
    STREAK = 8,
    LIGHTNING = 9,
    EXPLOSION = 10,
    EXPLOSION_BLUE = 11,
    SPARK = 12,
    EDIT = 13,
    SNOW = 14,
    MUZZLE_FLASH1 = 15,
    MUZZLE_FLASH2 = 16,
    MUZZLE_FLASH3 = 17,
    TEXT = 18,
    METER = 19,
    METER_VS = 20,
    LENS_FLARE = 21
}

--[[!
    Variable: DYNAMIC_LIGHT
    This table specifies dynamic light flags.

    Fields:
        SHRINK - dynamic light will be shrinking.
        EXPAND - dynamic light will be expanding.
        FLASH  - dynamic light will be flashing.
]]
DYNAMIC_LIGHT = {
    SHRINK = math.lsh(1, 0),
    EXPAND = math.lsh(1, 1),
    FLASH  = math.lsh(1, 2)
}

--[[!
    Function: decal
    Adds a decal at specified position in the world.

    Parameters:
        decal_type - type of the decal (<DECAL>).
        position - a vector indicating decal position.
        direction - a vector indicating direction the decal faces.
        radius - radius of the decal.
        color - decal color specified as hex integer (0xRRGGBB).
        info - decal-specific information, currently used in case of blood,
        where number from 0 to 3 specifies which one of 4 blood variants
        to render.
]]
function decal(decal_type, pos, dir, radius, color, info)
    info      = info or 0
    local r, g, b = hextorgb(color or 0xFFFFFF)

    _C.adddecal(decal_type, pos.x, pos.y, pos.z, dir.x, dir.y, dir.z, radius,
        r, g, b, info)
end

--[[!
    Function: dynamic_light
    Adds a dynamic light at specified position in the world.
    It is for now queued for next frame, so we get one frame lose,
    which is mostly okay, but FIXME anyway.

    Parameters:
        position - a vector indicating dynamic light position.
        radius - dynamic light radius as integral number.
        color - dynamic light color specified as hex integer (0xRRGGBB).
        fade - fade time in seconds.
        peak - peak time in seconds.
        flags - dynamic light flags (<DYNAMIC_LIGHT>).
        initial_radius - dynamic light initial radius.
        initial_color - dynamic light initial color
        specified as hex integer (0xRRGGBB).
]]
function dynamic_light(
    pos, radius, color, fade,
    peak, flags, initial_radius, initial_color
)
    local r,  g,  b  = hextorgb(color)
    local r1, g1, b1 = hextorgb(initial_color or 0xFFFFFF)

    fade = fade or 0
    peak = peak or 0

    _C.adddynlight(
        pos.x, pos.y, pos.z, radius,
        r / 255, g / 255, b / 255,
        fade * 1000, peak * 1000,
        flags or 0, initial_radius or 0,
        r1 / 255, g1 / 255, b1 / 255
    )
end

--[[!
    Function: splash
    Spawns a splash emitter.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        num - number of particles.
        fade - fade time in seconds.
        position - vector specifying splash position.
        color - splash color as hex integer (0xRRGGBB).
        size - particle spze.
        radius - particle radius.
        gravity - gravity pull on the particles.
]]
function splash(
    particle_type, num, fade, pos,
    color, size, radius, gravity,
    regular_fade, flags, fast_splash, grow
)
    color   = color   or 0xFFFFFF
    size    = size    or 1.0
    radius  = radius  or 150
    gravity = gravity or 2

    _C.particle_splash(
        particle_type, num, fade * 1000, pos.x, pos.y, pos.z,
        color, size, radius, gravity
    )
end

--[[!
    Function: regular_splash
    Spawns a regular splash emitter.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        num - number of particles.
        fade - fade time in seconds.
        position - vector specifying splash position.
        color - splash color as hex integer (0xRRGGBB).
        size - particle size.
        radius - particle radius.
        gravity - gravity pull on the particles.
        delay - particle delay.
]]
function regular_splash(
    particle_type, num, fade, pos,
    color, size, radius, gravity, delay
)
    color   = color   or 0xFFFFFF
    size    = size    or 1.0
    radius  = radius  or 150
    gravity = gravity or 2

    _C.regular_particle_splash(
        particle_type, num, fade * 1000, pos.x, pos.y, pos.z,
        color, size, radius, gravity, delay
    )
end

--[[!
    Function: fireball
    Spawns a fireball. Clientside only.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        position - vector specifying fireball position.
        max_size - maximal size of the fireball.
        fade - fade time in seconds.
        color - fireball color as hex integer (0xRRGGBB).
        size - fireball size.
        gravity - gravity pull on the particles.
        num - number of particles.
]]
function fireball(
    particle_type, pos, max_size,
    fade, color, size, gravity, num
)
    fade  = (fade ~= nil) and fade * 1000 or -1
    color = color or 0xFFFFFF
    size  = size  or 4.0
    _C.particle_fireball(
        pos.x, pos.y, pos.z, max_size, particle_type, fade,
        color, size, gravity, num
    )
end

--[[!
    Function: flare
    Spawns a flare. Clientside only.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        target_position - vector specifying target flare position.
        source_position - vector specifying source flare position.
        fade - fade time in seconds.
        color - flare color as hex integer (0xRRGGBB).
        size - flare size (thickness).
        owner - flare owner entity.
]]
function flare(
    particle_type, tp, sp, fade, color, size, owner
)
    fade  = fade and fade * 1000 or 0
    color = color or 0xFFFFFF
    size  = size  or 0.28
    local oid = owner and owner.uid or -1
    _C.particle_flare(
        sp.x, sp.y, sp.z, tp.x, tp.y, tp.z, fade,
        particle_type, color, size, oid
    )
end

--[[!
    Function: trail
    Spawns a particle trail. Clientside only.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        fade - fade time in seconds.
        target_position - vector specifying target flare position.
        source_position - vector specifying source flare position.
        color - flare color as hex integer (0xRRGGBB).
        size - flare size (thickness).
        grow - integer value specifying particle grow factor (1 to 4).
]]
function trail(
    particle_type, fade, tp, sp, color, size, grow
)
    color   = color   or 0xFFFFFF
    size    = size    or 1.0
    grow    = grow    or 20
    _C.particle_trail(
        particle_type, fade * 1000, sp.x, sp.y, sp.z,
        tp.x, tp.y, tp.z, color, size, grow
    )
end

--[[!
    Function: flame
    Spawns a flame. Clientside only.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        position - vector specifying flame position.
        radius - flame radius.
        height - flame height.
        color - flame color.
        density - flame density.
        scale - flame scale.
        speed - falme speed.
        fade - fade time in seconds.
        gravity - gravity pull on the particles.
]]
function flame(
    particle_type, pos, radius, height,
    color, density, scale, speed, fade, gravity
)
    density = density or 3
    scale   = scale   or 2.0
    speed   = speed   or 200.0
    fade    = fade    and fade * 1000 or 600.0
    gravity = gravity or -15
    _C.particle_flame(
        particle_type, pos.x, pos.y, pos.z,
        radius, height, color, density,
        scale, speed, fade, gravity
    )
end

--[[!
    Function: lightning
    Spawns a lightning. Clientside only.

    Parameters:
        target_position - vector specifying target lightning position.
        source_position - vector specifying source lightning position.
        fade - fade time in seconds.
        color - lightning color as hex integer (0xRRGGBB).
        size - lightning size (thickness).
]]
function lightning(target_position, source_position, fade, color, size)
    flare(
        PARTICLE.LIGHTNING,
        target_position, source_position,
        fade, color, size
    )
end

--[[!
    Function: text
    Spawns a text. Clientside only.

    Parameters:
        position - vector specifying text position.
        text - the text to show.
        fade - fade time in seconds.
        color - text color as hex integer (0xRRGGBB).
        size - text size.
        gravity - gravity pull on the particles.
]]
function text(pos, text, fade, color, size, gravity)
    fade  = fade  or 2.0
    color = color or 0xFFFFFF
    size  = size  or 2.0
    _C.particle_text(
        pos.x, pos.y, pos.z, text, PARTICLE.TEXT,
        fade * 1000, color, size, gravity
    )
end
