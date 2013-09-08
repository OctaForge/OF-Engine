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
local format = string.format

local flame, splash = particles.flame, particles.splash
local pflags = particles.flags
local quadrenderer = particles.register_renderer_quad
local Particle_Effect = ents.Particle_Effect

local M = {}

--[[! Variable: renderers
    Provides some extra renderers - "smoke", "flame" and "steam" used
    by the effect entities. On the client only, on the server this is nil.
]]
local renderers

if SERVER then
    renderers = {}
else
    renderers = {
        smoke = quadrenderer("smoke", "media/particle/smoke",
            pflags.FLIP | pflags.LERP),
        flame = quadrenderer("flame", "media/particle/flames",
            pflags.HFLIP | pflags.RND4 | pflags.BRIGHT),
        steam = quadrenderer("steam", "media/particle/steam", pflags.FLIP)
    }
    M.renderers = renderers
end

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

local SMOKE, FLAME = renderers.smoke, renderers.flame

--[[! Class: Fire_Effect
    A regular fire effect. Has properties radius (default 1.5), height
    (default 0.5), red, green, blue (integers, default 0x90, 0x30, 0x20).
]]
M.Fire_Effect = Particle_Effect:clone {
    name = "Fire_Effect",

    __properties = {
        radius = svars.State_Float(),
        height = svars.State_Float(),
        red    = svars.State_Integer(),
        green  = svars.State_Integer(),
        blue   = svars.State_Integer()
    },

    init_svars = function(self, kwargs)
        Particle_Effect.init_svars(self, kwargs)
        self:set_attr("radius", 1.5)
        self:set_attr("height", 0.5)
        self:set_attr("red",   0x90)
        self:set_attr("green", 0x30)
        self:set_attr("blue",  0x20)
    end,

    get_edit_color = function(self)
        return self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue")
    end,

    get_edit_info = function(self)
        return format("red :\f2 %d \f7| green :\f2 %d \f7| blue :\f2 %d\n\f7"
            .. "radius :\f2 %.3f \f7| height :\f2 %.3f",
            self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue"), self:get_attr("radius"),
            self:get_attr("height"))
    end,

    emit_particles = function(self)
        local radius = self:get_attr("radius")
        local height = self:get_attr("height")
        local r, g, b = self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue")
        local pos = self:get_attr("position")
        local spos = { x = pos.x, y = pos.y,
            z = pos.z + 4 * min(radius, height) }
        flame(FLAME, pos, radius, height, r / 255, g / 255, b / 255)
        flame(SMOKE, spos, radius, height, 0x30 / 255, 0x30 / 255,
            0x20 / 255, 2000, 1, 4, 100, -20)
    end
}

local STEAM = renderers.steam

--[[! Class: Steam_Effect
    A steam effect. Has one property, direction, which is passed to
    <offset_vec> directly.
]]
M.Steam_Effect = Particle_Effect:clone {
    name = "Steam_Effect",

    __properties = {
        direction = svars.State_Integer()
    },

    init_svars = function(self, kwargs)
        Particle_Effect.init_svars(self, kwargs)
        self:set_attr("direction", 0)
    end,

    get_edit_info = function(self)
        return format("direction :\f2 %d", self:get_attr("direction"))
    end,

    emit_particles = function(self)
        local dir = self:get_attr("direction")
        local pos = self:get_attr("position")
        local d = offset_vec({ x = pos.x, y = pos.y, z = pos.z }, dir, rand(9))
        splash(STEAM, d, 50, 1, 0x89 / 255, 0x76 / 255, 0x61 / 255,
            200, 2.4, -20)
    end
}

ents.register_class(M.Fire_Effect)
ents.register_class(M.Steam_Effect)

return M
