--[[! File: lua/extra/entities/lights.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Various types of particle effects. All of the entity types here
        derive from <ents.Particle_Effect>.
]]

local ents = require("core.entities.ents")
local svars = require("core.entities.svars")
local particles = require("core.engine.particles")

local min, rand = math.min, math.random

local flame, splash = particles.flame, particles.splash
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

local cmap = { "x", "y", "z" }

--[[! Function: offset_vec
    Given an object with members x, y, z (that are numbers), a direction
    (0 to 5 where 0 is up) and distance, this adds or subtracts the distance
    to the vector component given by the direction. 0 is z with addition,
    1 is x with addition, 2 is y with addition, 3 is z with subtraction,
    4 is x with subtraction, 5 is y with subtraction.
    
]]
local offset_vec = function(v, dir, dist)
    local e = cmap[((2 + dir) % 3) + 1]
    v[e] = v[e] + ((dir > 2) and -dist or dist)
    return v
end
M.offset_vec = offset_vec

--[[! Class: Fire_Effect
    A regular fire effect. Has properties radius (default 1.5), height
    (default 0.5), red, green, blue (integers, default 0x90, 0x30, 0x20).
]]
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

--[[! Class: Steam_Effect
    A steam effect. Has one property, direction, which is passed to
    <offset_vec> directly.
]]
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
        splash(PART_STEAM, d, 50, 1, 0x89 / 255, 0x76 / 255, 0x61 / 255,
            200, 2.4, -20)
    end
}

ents.register_class(M.Fire_Effect)
ents.register_class(M.Steam_Effect)

return M
