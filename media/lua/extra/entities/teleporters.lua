--[[! File: lua/extra/entities/teleporters.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Reusable teleporter entities.
]]

local log = require("core.logger")
local sound = require("core.engine.sound")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

local play = sound.play
local connect = signal.connect
local get_by_tag = ents.get_by_tag

local rand = math.random
local unpack = unpack

local M = {}

local Obstacle = ents.Obstacle

--[[! Class: Teleporter
    A regular invisible teleporter. Derives from <ents.Obstacle>. It has
    two new properties, "destination" which is an integer from 1 to N
    (0 by default, as in, invalid) and "sound_name", which is an optional
    string specifying which sound to play on teleportation (empty by default).

    A destination for this teleporter can be any entity type that has a method
    "place_entity". By default, <ents.Marker> and <ents.Oriented_Marker> have
    this. The destination entity has to have a tag teledest_N, where N is
    the value of "destination". There can be any number of destinations,
    one is always picked at random (using Lua's math.random).

    In edit mode, the links from teleporter to destinations are visualized.
]]
M.Teleporter = Obstacle:clone {
    name = "Teleporter",

    properties = {
        destination = svars.State_Integer(),
        sound_name  = svars.State_String()
    },

    init = function(self, uid, kwargs)
        Obstacle.init(self, uid, kwargs)
        self:set_attr("destination", 0)
        self:set_attr("sound_name", "")
    end,

    activate = (not SERVER) and function(self, kwargs)
        Obstacle.activate(self, kwargs)
        connect(self, "collision", self.on_collision)
    end or nil,

    on_collision = function(self, collider)
        local dest = self:get_attr("destination")
        if dest <= 0 then return end
        local dests = get_by_tag("teledest_" .. dest)
        if #dests == 0 then
            log.log(log.ERROR, "No teledest found.")
            return
        end
        dests[rand(1, #dests)]:place_entity(collider)
        local sn = self:get_attr("sound_name")
        if sn != "" then play(sn) end
    end,

    get_attached_next = function(self)
        local dest = self:get_attr("destination")
        if dest <= 0 then return end
        return unpack(get_by_tag("teledest_" .. dest))
    end
}

ents.register_class(M.Teleporter)

return M
