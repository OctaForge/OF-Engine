--[[! File: lua/extra/entities/lights.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Various types of particle effects.
]]

local ents = require("core.entities.ents")
local svars = require("core.entities.svars")
local particles = require("core.engine.particles")

local min, rand = math.min, math.random

local flame = particles.flame
local Particle_Effect = ents.Particle_Effect

local M = {}

local PART_TEXT = 0
local PART_ICON = 1
local PART_METER = 2
local PART_METER_VS = 3
local PART_BLOOD = 4
local PART_WATER = 5
local PART_SMOKE = 6
local PART_STEAM = 7
local PART_FLAME = 8
local PART_FIREBALL1 = 9
local PART_FIREBALL2 = 10
local PART_FIREBALL3 = 11
local PART_STREAK = 12
local PART_LIGHTNING = 13
local PART_EXPLOSION = 14
local PART_EXPLOSION_BLUE = 15
local PART_SPARK = 16
local PART_SNOW = 17
local PART_MUZZLE_FLASH1 = 18
local PART_MUZZLE_FLASH2 = 19
local PART_MUZZLE_FLASH3 = 20
local PART_LENS_FLARE = 21
--[[
local typemap = { PART_STREAK, -1, -1, PART_LIGHTNING, -1, PART_STEAM,
    PART_WATER, -1, -1, PART_SNOW }
local sizemap = { 0.28, 0, 0, 1, 0, 2.4, 0.6, 0, 0, 0.5 }
local gravmap = { 0, 0, 0, 0, 0, -20, 2, 0, 0, 20 }


local part_draw_1 = function(pt, x, y, z, a1, a2, a3, a4)
    local tp = typemap[pt - 3]
    local sz = sizemap[pt - 3]
    local gv = gravmap[pt - 3]
    local r, g, b = hextorgb(a3)
    if a1 >= 256 then
        _C.particle_shape(tp, x, y, z, max(1 + a2, 1), a1 - 256, 5, r / 255,
            g / 255, b / 255, a4 > 0 and min(a4, 10000) or 200, sz, gv, 200)
    else
        local d = offset_vec({ x = x, y = y, z = z }, a1, max(1 + a2, 0))
        _C.particle_new(tp, x, y, z, d.x, d.y, d.z, r / 255, g / 255, b / 255,
            1, sz, gv)
    end
end

local rand = math.random

local part_draw_tbl = {
    [4] = part_draw_1, -- tape - dir, length, rgb
    [7] = part_draw_1, -- lightning
    [9] = part_draw_1, -- steam
    [10] = part_draw_1, -- water
    [13] = part_draw_1, -- snow
}
]]

local cmap = { "x", "y", "z" }
local offset_vec = function(v, dir, dist)
    local e = cmap[((2 + dir) % 3) + 1]
    v[e] = v[e] + ((dir > 2) and -dist or dist)
    return v
end
M.offset_vec = offset_vec

M.Fire_Effect = Particle_Effect:clone {
    name = "Fire_Effect",

    properties = {
        radius = svars.State_Float(),
        height = svars.State_Float(),
        red    = svars.State_Integer(),
        green  = svars.State_Integer(),
        blue   = svars.State_Integer()
    },

    init = function(self, uid, kwargs)
        Particle_Effect.init(self, uid, kwargs)
        self:set_attr("radius", 1.5)
        self:set_attr("height", 0.5)
        self:set_attr("red",   0x90)
        self:set_attr("green", 0x30)
        self:set_attr("blue",  0x20)
    end,

    emit_particles = function(self)
        local radius = self:get_attr("radius")
        local height = self:get_attr("height")
        local r, g, b = self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue")
        local pos = self:get_attr("position")
        local spos = { x = pos.x, y = pos.y,
            z = pos.z + 4 * min(radius, height) }
        flame(PART_FLAME, pos, radius, height, r / 255, g / 255, b / 255)
        flame(PART_SMOKE, spos, radius, height, 0x30 / 255, 0x30 / 255,
            0x20 / 255, 2000, 1, 4, 100, -20)
    end
}

M.Steam_Effect = Particle_Effect:clone {
    name = "Steam_Effect",

    properties = {
        direction = svars.State_Integer()
    },

    init = function(self, uid, kwargs)
        Particle_Effect.init(self, uid, kwargs)
        self:set_attr("direction", 0)
    end,

    emit_particles = function(self)
        local dir = self:get_attr("direction")
        local pos = self:get_attr("position")
        local d = offset_vec({ x = pos.x, y = pos.y, z = pos.z }, dir, rand(9))
        _C.particle_splash(PART_STEAM, d.x, d.y, d.z, 50, 1,
            0x89 / 255, 0x76 / 255, 0x61 / 255, 200, 2.4, -20, 0)
    end
}

ents.register_class(M.Fire_Effect)
ents.register_class(M.Steam_Effect)

return M
