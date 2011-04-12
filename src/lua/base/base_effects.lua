---
-- base_effects.lua, version 1<br/>
-- Particle / dynlight / ... interface for Lua.<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- @author bartbes (bart.bes@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local CAPI = require("CAPI")
local color = require("cc.color")
local glob = require("cc.global")
local msgsys = require("cc.msgsys")

--- Particle / dynlight / ... interface for cC's Lua.
-- @class module
-- @name cc.effect
module("cc.effect")

-- in sync with iengine.h

--- Decal types
-- @class table
-- @name DECAL
-- @field SCORCH scorch
-- @field BLOOD blood
-- @field BULLET bullet
-- @field DECAL decal
-- @field CIRCLE circle
DECAL = {
    SCORCH = 0,
    BLOOD = 1,
    BULLET = 2,
    DECAL = 3,
    CIRCLE = 4
}

-- in sync with iengine.h

--- Particle types
-- @class table
-- @name PARTICLE
-- @field BLOOD blood
-- @field WATER water
-- @field SMOKE smoke
-- @field SOFTSMOKE softsmoke
-- @field STEAM steam
-- @field FLAME flame
-- @field FIREBALL1 fireball
-- @field FIREBALL2 fireball
-- @field FIREBALL3 fireball
-- @field STREAK streak
-- @field LIGHTNING lightning
-- @field EXPLOSION explosion
-- @field EXPLOSION_NO_GLARE explosion without glare
-- @field SPARK spark
-- @field EDIT edit
-- @field MUZZLE_FLASH1 muzzle flash
-- @field MUZZLE_FLASH2 muzzle flash
-- @field MUZZLE_FLASH3 muzzle flash
-- @field MUZZLE_FLASH4A muzzle flash
-- @field MUZZLE_FLASH4B muzzle flash
-- @field MUZZLE_FLASH5 muzzle flash
-- @field TEXT text
-- @field METER meter
-- @field METER_VS meter
-- @field LENS_FLARE lens flare
-- @field FLAME1 flame
-- @field FLAME2 flame
-- @field FLAME3 flame
-- @field FLAME4 flame
-- @field SNOW snow
-- @field RAIN rain
-- @field BULLET bullet
-- @field GLOW glow
-- @field GLOW_TRACK glow
-- @field LIGHTFLARE light flare
-- @field BUBBLE bubble
-- @field EXPLODE explode
-- @field SMOKETRAIL smoke trail
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

--- Add a decal
-- @param ty The decal type
-- @param pos A vector that indicates the position of the decal
-- @param dir A vector that indicates the direction the decal travels in
-- @param rd Radius
-- @param col The color (Specified as 0xRRGGBB)
-- @param inf Info (?!)
function decal_add(ty, pos, dir, rd, col, inf)
    i = i or 0
    local rgb = color.hextorgb(c or 0xFFFFFF)
    CAPI.adddecal(ty, pos.x, pos.y, pos.z, dir.x, dir.y, dir.z, rd, rgb.r, rgb.g, rgb.b, inf)
end

--- Add a dynlight
-- @param pos A vector that indicates the position of the dynlight
-- @param rd Radius
-- @param col Color (0xRRGGBB)
-- @param fd Fade time in seconds
-- @param pk Peak
-- @param fl Flags
-- @param ird Initial radius
-- @param icol Initial color (0xRRGGBB)
function dynlight_add(pos, rd, col, fd, pk, fl, ird, icol)
    local rgbc = color.hextorgb(col)
    local rgbic = color.hextorgb(icol or 0xFFFFFF)
    CAPI.adddynlight(pos.x, pos.y, pos.z, rd, rgbc.r, rgbc.g, rgbc.b, fd * 1000, pk * 1000, fl, ird, rgbic.r, rgbic.g, rgbic.b)
end


--- Create a particle splash
-- @param ty Particle type
-- @param n Number of particles
-- @param fd Fade time in seconds
-- @param pos Position of the splash (vector)
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
-- @param rd Radius
-- @param grav Gravity pull on the particles
-- @param regfd Regfade (?!) (boolean)
-- @param fl Flags
-- @param fs Fast splash (boolean)
-- @param gr Grow (boolean)
function splash(ty, n, fd, pos, col, sz, rd, grav, regfd, fl, fs, gr)
    if glob.CLIENT then
        col = col or 0xFFFFFF
        sz = sz or 1.0
        rd = rd or 150
        grav = grav or 2
        regfd = regfd or false
        fs = fs or false
        CAPI.particle_splash(ty, n, fd * 1000, pos.x, pos.y, pos.z, col, sz, rd, grav, regfd, fl, fs, gr)
    else
        msgsys.send(msgsys.ALL_CLIENTS, CAPI.particle_splash_toclients, ty, n, fd * 1000, pos.x, pos.y, pos.z) -- TODO: last 4 params
    end
end

--- Create a regular particle splash
-- @param ty Particle type
-- @param n Number of particles
-- @param fd Fade time in seconds
-- @param pos Position of the splash (vector)
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
-- @param rd Radius
-- @param grav Gravity pull on the particles
-- @param dl Delay
-- @param hv Hover (boolean)
-- @param gr Grow (boolean)
function regular_splash(ty, n, fd, pos, col, sz, rd, grav, dl, hv, gr)
    if glob.CLIENT then
        col = col or 0xFFFFFF
        sz = sz or 1.0
        rd = rd or 150
        grav = grav or 2
        hv = hv or false
        CAPI.regular_particle_splash(ty, n, fd * 1000, pos.x, pos.y, pos.z, col, sz, rd, grav, regfd, fl, fs, gr)
    else
        msgsys.send(msgsys.ALL_CLIENTS, CAPI.particle_regularsplash_toclients, ty, n, fd * 1000, pos.x, pos.y, pos.z) -- TODO: last 5 params
    end
end


--- Explosion splash
-- @param ty Particle type
-- @param pos Position of explosion (vector)
-- @param fade Fade time in seconds
-- @param col Color (0xRRGGBB)
-- @param sz Size of particles
-- @param grav Gravity pull on the particles
-- @param n Number of particles
function explode_splash(ty, pos, fd, col, sz, grav, n)
    fd = (fd ~= nil) and fd * 1000 or -1
    col = col or 0xFFFFFF
    sz = sz or 1.0
    grav = grav or -20
    n = n or 16
    CAPI.particle_fireball(pos.x, pos.y, pos.z, fd, ty, col, sz, grav, n)
end


--- Create a fireball
-- @param ty Particle type
-- @param pos Position of fireball (vector)
-- @param mx Maximum size of fireball
-- @param fd Fade time in seconds
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
function fireball(ty, pos, mx, fd, col, sz)
    fd = (fd ~= nil) and fd * 1000 or -1
    col = col or 0xFFFFFF
    sz = sz or 4.0
    CAPI.particle_fireball(pos.x, pos.y, pos.z, mx, ty, fd, col, sz)
end

--- Create a flare
-- @param ty Particle type
-- @param fpos Target position (vector)
-- @param spos Source position (vector)
-- @param fd Fade time in seconds
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
-- @param gr Grow
-- @param own Owner (entity)
function flare(ty, fpos, spos, fd, col, sz, gr, own)
    fd = fd and fd * 1000 or 0
    col = col or 0xFFFFFF
    sz = sz or 0.28
    local oid = own and own.uid or -1
    CAPI.particle_flare(spos.x, spos.y, spos.z, fpos.x, fpos.y, fpos.z, fd, ty, col, sz, gr, oid)
end

--- Create a flying flare
-- @param ty Particle type
-- @param fpos Target position (vector)
-- @param spos Source position (vector)
-- @param fd Fade time in seconds
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
-- @param gr Gravity pull on the flare
function flying_flare(ty, fpos, spos, fd, col, sz, gr)
    fd = fd and fd * 1000 or 0
    CAPI.particle_flying_flare(spos.x, spos.y, spos.z, fpos.x, fpos.y, fpos.z, fd, ty, col, sz, gr)
end


--- Create a particle trail
-- @param ty Particle type
-- @param fd Fade time in seconds
-- @param fpos Target position (vector)
-- @param spos Source position (vector)
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
-- @param gr Gravity pull on the particles
-- @param bub Bubbles (boolean)
function trail(ty, fd, spos, fpos, col, sz, gr, bub)
    col = col or 0xFFFFFF
    sz = sz or 1.0
    gr = gr or 20
    bub = bub or false
    CAPI.particle_trail(ty, fd * 1000, spos.x, spos.y, spos.z, fpos.x, fpos.y, fpos.z, col, sz, gr, bub)
end

--- Create a flame
-- @param ty Particle type
-- @param pos Position (vector)
-- @param rd Radius
-- @param h Height
-- @param col Color (0xRRGGBB)
-- @param d Density
-- @param sc Scale
-- @param sp Speed
-- @param fd Fade time in seconds
-- @param gr Gravity pull on the particles
function flame(ty, pos, rd, h, col, d, sc, sp, fd, gr)
    d = d or 3
    sc = sc or 2.0
    sp = sp or 200.0
    fd = fd and fd * 1000 or 600.0
    gr = gr or -15
    CAPI.particle_flame(ty, pos.x, pos.y, pos.z, rd, h, col, d, sc, sp, fd, gr)
end

--- Create lighting
-- @param spos Source position (vector)
-- @param fpos Target position (vector)
-- @param fd Fade time in seconds
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
function lighting(spos, fpos, fd, col, sz)
    flare(PARTICLE.LIGHTING, spos, fpos, fd, col, sz)
end


--- Add text
-- @param pos Position (vector)
-- @param tx Text
-- @param fd Fade time in seconds
-- @param col Color (0xRRGGBB)
-- @param sz Particle size
-- @param gr Gravity pull on the text
function text(pos, tx, fd, col, sz, gr)
    fd = fd or 2.0
    col = col or 0xFFFFFF
    sz = sz or 2.0
    CAPI.particle_text(pos.x, pos.y, pos.z, tx, PARTICLE.TEXT, fd * 1000, col, sz, gr)
end

--- Play damage effect
-- @param r Amount of damage
-- @param col Color (0xRRGGBB)
function cldamage(r, col)
    if not glob.SERVER then
        CAPI.client_damage_effect(r, col)
    end
end
