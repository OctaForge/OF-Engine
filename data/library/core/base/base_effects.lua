--[[!
    File: library/core/base/base_effects.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features effects (particle system, dynamic lights etc.).
        DEPRECATED for OF API v2 (Stays in v1).
]]

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
        SOFTSMOKE - soft smoke particle.
        STEAM - steam particle.
        FLAME - flame particle.
        FIREBALL1 - first variant of fireball - these are deprecated.
        FIREBALL2 - second variant of fireball - these are deprecated.
        FIREBALL3 - third variant of fireball - these are deprecated.
        STREAK - streak particle.
        LIGHTNING - lightning particle.
        EXPLOSION - explosion particle.
        EXPLOSION_NO_GLARE - exposion particle without glare.
        SPARK - spark particle.
        EDIT - edit mode particle, deprecated now (uses icons).
        MUZZLE_FLASH1 - muzzle flash particle.
        MUZZLE_FLASH2 - muzzle flash particle.
        MUZZLE_FLASH3 - muzzle flash particle.
        MUZZLE_FLASH4A - muzzle flash particle.
        MUZZLE_FLASH4B - muzzle flash particle.
        MUZZLE_FLASH5 - muzzle flash particle.
        TEXT - text particle.
        METER - meter particle (rgb vs black)
        METER_VS - metervs particle (rgb vs bgr).
        LENS_FLARE - lens flare particle.
        FLAME1 - flame particle.
        FLAME2 - flame particle.
        FLAME3 - flame particle.
        FLAME4 - flame particle.
        SNOW - snow particle.
        RAIN - rain particle.
        BULLET - bullet particle.
        GLOW - glow particle.
        GLOW_TRACK - glow track particle.
        LIGHTFLARE - light flare particle.
        BUBBLE - bubble particle.
        EXPLODE - explosion particle (flat).
        SMOKETRAIL - smoke trail particle.
]]
PARTICLE = {
    BLOOD = 0,
    WATER = 1,
    SMOKE = 2,
    SOFTSMOKE = 3,
    STEAM = 4,
    FLAME = 5,
    FIREBALL1 = 6,
    FIREBALL2 = 7,
    FIREBALL3 = 8,
    STREAK = 9,
    LIGHTNING = 10,
    EXPLOSION = 11,
    EXPLOSION_NO_GLARE = 12,
    SPARK = 13,
    EDIT = 14,
    MUZZLE_FLASH1 = 15,
    MUZZLE_FLASH2 = 16,
    MUZZLE_FLASH3 = 17,
    MUZZLE_FLASH4A = 18,
    MUZZLE_FLASH4B = 19,
    MUZZLE_FLASH5 = 20,
    TEXT = 21,
    METER = 22,
    METER_VS = 23,
    LENS_FLARE = 24,
    FLAME1 = 25,
    FLAME2 = 26,
    FLAME3 = 27,
    FLAME4 = 28,
    SNOW = 29,
    RAIN = 30,
    BULLET = 31,
    GLOW = 32,
    GLOW_TRACK = 33,
    LIGHTFLARE = 34,
    BUBBLE = 35,
    EXPLODE = 36,
    SMOKETRAIL = 37
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
    SHRINK = std.math.lsh(1, 0),
    EXPAND = std.math.lsh(1, 1),
    FLASH  = std.math.lsh(1, 2)
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
function decal(decal_type, position, direction, radius, color, info)
    info      = info or 0
    local rgb = std.conv.hex_to_rgb(color or 0xFFFFFF)

    CAPI.adddecal(decal_type, position, direction, radius, rgb, info)
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
    position, radius, color, fade,
    peak, flags, initial_radius, initial_color
)
    local rgbc  = std.conv.hex_to_rgb(color)
    local rgbic = std.conv.hex_to_rgb(initial_color or 0xFFFFFF)

    fade = fade or 0
    peak = peak or 0

    CAPI.adddynlight(
        position, radius,
        std.math.Vec3(rgbc.r / 255, rgbc.g / 255, rgbc.b / 255),
        fade * 1000, peak * 1000,
        flags, initial_radius,
        std.math.Vec3(rgbic.r / 255, rgbic.g / 255, rgbic.b / 255)
    )
end

--[[!
    Function: splash
    Spawns a splash emitter. If ran on server,
    a message gets sent to all clients.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        num - number of particles.
        fade - fade time in seconds.
        position - vector specifying splash position.
        color - splash color as hex integer (0xRRGGBB).
        size - particle spze.
        radius - particle radius.
        gravity - gravity pull on the particles.
        regular_fade - boolean value specifying whether
        to use a regular particle fade (false usually).
        flags - particle flags.
        fast_splash - boolean value specifying whether
        the splash should be fast.
        grow - integer value specifying particle grow factor (1 to 4).
]]
function splash(
    particle_type, num, fade, position,
    color, size, radius, gravity,
    regular_fade, flags, fast_splash, grow
)
    if CLIENT then
        color   = color   or 0xFFFFFF
        size    = size    or 1.0
        radius  = radius  or 150
        gravity = gravity or 2
        regular_fade = regular_fade or false
        fast_splash  = fast_splash  or false

        CAPI.particle_splash(
            particle_type, num, fade * 1000, position,
            color, size, radius, gravity, regular_fade,
            flags, fast_splash, grow
        )
    else
        message.send(
            message.ALL_CLIENTS, CAPI.particle_splash_toclients,
            particle_type, num, fade * 1000,
            position.x, position.y, position.z
        ) -- TODO: last 8 params
    end
end

--[[!
    Function: regular_splash
    Spawns a regular splash emitter. If ran on server,
    a message gets sent to all clients.

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
        hover - boolean value specifying whether
        the particle should hover.
        grow - integer value specifying particle grow factor (1 to 4).
]]
function regular_splash(
    particle_type, num, fade, position,
    color, size, radius, gravity, delay, hover, grow
)
    if CLIENT then
        color   = color   or 0xFFFFFF
        size    = size    or 1.0
        radius  = radius  or 150
        gravity = gravity or 2
        hover   = hover   or false

        CAPI.regular_particle_splash(
            particle_type, num, fade * 1000, position,
            color, size, radius, gravity, delay, hover,
            grow
        )
    else
        message.send(
            message.ALL_CLIENTS, CAPI.particle_regularsplash_toclients,
            particle_type, num, fade * 1000,
            position.x, position.y, position.z
        ) -- TODO: last 7 params
    end
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
    particle_type, position, max_size,
    fade, color, size, gravity, num
)
    fade  = (fade ~= nil) and fade * 1000 or -1
    color = color or 0xFFFFFF
    size  = size  or 4.0
    CAPI.particle_fireball(
        position, max_size, particle_type, fade,
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
        grow - integer value specifying particle grow factor (1 to 4).
        owner - flare owner entity.
]]
function flare(
    particle_type, target_position, source_position,
    fade, color, size, grow, owner
)
    fade  = fade and fade * 1000 or 0
    color = color or 0xFFFFFF
    size  = size  or 0.28
    local oid = owner and owner.uid or -1
    CAPI.particle_flare(
        source_position, target_position, fade,
        particle_type, color, size, grow, oid
    )
end

--[[!
    Function: flying_flare
    Spawns a flying flare. Clientside only.

    Parameters:
        particle_type - particle type (<PARTICLE>).
        target_position - vector specifying target flare position.
        source_position - vector specifying source flare position.
        fade - fade time in seconds.
        color - flare color as hex integer (0xRRGGBB).
        size - flare size (thickness).
        grow - integer value specifying particle grow factor (1 to 4).
]]
function flying_flare(
    particle_type, target_position,
    source_position, fade, color, size, grow
)
    fade  = fade and fade * 1000 or 0
    CAPI.particle_flying_flare(
        source_position, target_position, fade,
        particle_type, color, size, grow
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
        bubbles - if true, the trail will consist of bubbles.
]]
function trail(
    particle_type, fade, target_position,
    source_position, color, size, grow, bubbles
)
    color   = color   or 0xFFFFFF
    size    = size    or 1.0
    grow    = grow    or 20
    bubbles = bubbles or false
    CAPI.particle_trail(
        particle_type, fade * 1000, source_position,
        target_position, color, size, grow, bubbles
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
    particle_type, position, radius, height,
    color, density, scale, speed, fade, gravity
)
    density = density or 3
    scale   = scale   or 2.0
    speed   = speed   or 200.0
    fade    = fade    and fade * 1000 or 600.0
    gravity = gravity or -15
    CAPI.particle_flame(
        particle_type, position,
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
function text(position, text, fade, color, size, gravity)
    fade  = fade  or 2.0
    color = color or 0xFFFFFF
    size  = size  or 2.0
    CAPI.particle_text(
        position, text, PARTICLE.TEXT,
        fade * 1000, color, size, gravity
    )
end

--[[!
    Function: client_damage
    Shows client damage effect.

    Parameters:
        amount - amount of damage made.
        color - damage color as hex integer (0xRRGGBB).
]]
function client_damage(amount, color)
    if not SERVER then
        CAPI.client_damage_effect(amount, color)
    end
end
