--[[! File: lua/extra/entities/lights.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Various types of light entities.
]]

local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

local bit = require("bit")

local M = {}

local Marker = ents.Marker

--[[! Class: Dynamic_Light
    A generic "dynamic light" entity class. It's not registered by default
    (a Light from the core set is already dynamic), it serves as a base for
    derived dynamic light types. Inherits from <ents.Marker> entity type of
    the core set. Note: even though this type is not registered by default,
    it's fully functional.

    Properties overlap with the core Light entity type (but it lacks flags).
]]
local Dynamic_Light = Marker:clone {
    name = "Dynamic_Light",

    properties = {
        radius = svars.State_Integer(),
        red    = svars.State_Integer(),
        green  = svars.State_Integer(),
        blue   = svars.State_Integer()
    },

    --[[! Variable: per_frame
        Set to true, as <run> doesn't work on static entities by default.
    ]]
    per_frame = true,

    init = function(self, uid, kwargs)
        Marker.init(self, uid, kwargs)
        self:set_attr("radius", 100)
        self:set_attr("red",    128)
        self:set_attr("green",  128)
        self:set_attr("blue",   128)
    end,

    --[[! Function: run
        Overloaded to show the dynamic light. Derived dynamic light types
        need to override this accordingly.
    ]]
    run = (not SERVER) and function(self, millis)
        Marker.run(self, millis)
        local pos = self:get_attr("position")
        _C.adddynlight(pos.x, pos.y, pos.z, self:get_attr("radius"),
            self:get_attr("red") / 255, self:get_attr("green") / 255,
            self:get_attr("blue") / 255, 0, 0, 0, 0, 0, 0, 0)
    end or nil
}
M.Dynamic_Light = Dynamic_Light

local max, random = math.max, math.random
local floor = math.floor
local flash_flag = bit.lshift(1, 2)

--[[! Class: Flickering_Light
    A flickering light entity type derived from <Dynamic_Light>. This one
    is registered. Delays are in milliseconds.

    Properties (all <svars.State_Float>):
        probability - the flicker probability (from 0 to 1, defaults to 0.5)
        min_delay - the minimal flicker delay (defaults to 100)
        max_delay - the maximal flicker delay (defaults to 300)
]]
M.Flickering_Light = Dynamic_Light:clone {
    name = "Flickering_Light",

    properties = {
        probability = svars.State_Float(),
        min_delay   = svars.State_Integer(),
        max_delay   = svars.State_Integer(),
    },

    init = function(self, uid, kwargs)
        Dynamic_Light.init(self, uid, kwargs)
        self:set_attr("probability", 0.5)
        self:set_attr("min_delay",   100)
        self:set_attr("max_delay",   300)
    end,

    activate = (not SERVER) and function(self, kwargs)
        Marker.activate(self, kwargs)
        self.delay = 0
    end or nil,

    run = (not SERVER) and function(self, millis)
        local d = self.delay - millis
        if  d <= 0 then
            d = max(floor(random() * self:get_attr("max_delay")),
                self:get_attr("min_delay"))
            if random() < self:get_attr("probability") then
                local pos = self:get_attr("position")
                _C.adddynlight(pos.x, pos.y, pos.z, self:get_attr("radius"),
                    self:get_attr("red") / 255, self:get_attr("green") / 255,
                    self:get_attr("blue") / 255, d, 0, flash_flag,
                    0, 0, 0, 0)
            end
        end
        self.delay = d
    end or nil
}

ents.register_class(M.Flickering_Light)

return M
