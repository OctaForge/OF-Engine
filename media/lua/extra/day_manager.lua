--[[!<
    A day manager module. It can control all kinds of things, from a basic
    day-night cycle to weather. It's server controlled (time management
    happens on the server) with clientside effect.

    The controller entity runs in the background.
]]

--! Module: day_manager
local M = {}

local signal = require("core.events.signal")
local ents = require("core.entities.ents")
local svars = require("core.entities.svars")
local lights = require("core.engine.lights")
local edit = require("core.engine.edit")

local connect, emit = signal.connect, signal.emit

local assert = assert

local get

local Entity = ents.Entity

--[[!
    This is the day manager entity prototype.
]]
local Day_Manager = Entity:clone {
    name = "Day_Manager",

    __properties = {
        day_seconds = svars.State_Integer(),
        day_progress = svars.State_Integer { reliable = false }
    },

    __init_svars = function(self)
        Entity.__init_svars(self)
        self:set_attr("day_seconds", 40)
        self:set_attr("day_progress", 0)
    end,

    __activate = SERVER and function(self)
        Entity.__activate(self)
        self.day_seconds_s = self:get_attr("day_seconds")
        connect(self, "day_seconds,changed", |self, v| do
            self.day_seconds_s = v
        end)
        self.day_progress_s = 0
    end or nil,

    __run = function(self, millis)
        if not SERVER then return end
        Entity.__run(self, millis)
        local dm = self.day_seconds_s * 1000
        if dm == 0 then return end
        local dp = self.day_progress_s
        dp += millis
        if dp >= dm then dp -= dm end
        self:set_attr("day_progress", dp)
        self.day_progress_s = dp
    end
}

local dayman

--! Gets the day manager instance.
M.get = function()
    if not dayman then
        dayman = ents.get_by_prototype("Day_Manager")[1]
    end
    assert(dayman)
    return dayman
end
get = M.get

--[[!
    Sets up the day manager. You should call this in your map script before
    {{$ents.load}}. You can provide various plugins. This module implements
    a handful of plugins that you can use. On the server this returns the
    entity.
]]
M.setup = function(plugins)
    ents.register_prototype(Day_Manager, plugins)
    if SERVER then
        dayman = ents.new("Day_Manager")
        return dayman
    end
end

local getsunscale = function(dayprog)
    -- the numbers here are very approximate, in reality they'd depend
    -- on the which part of the year it is - here the sun is at the horizon
    -- by 6 AM and 6 PM respectively (equally long night and day) so we need
    -- the sunlightscale at 0 by 6 PM and rising up to 1 from 6 AM (so that
    -- we don't get shadows from the bottom) - both dawn and dusk take 2
    -- hours... TODO: more configurable system where you can set how long
    -- is day and night (and affect actual seasons)
    local r1, r2 = 0.67, 0.75 -- dusk: 4 - 6 hrs
    local d1, d2 = 0.25, 0.33 -- dawn: 6 - 8 hrs
    if dayprog > d2 and dayprog < r1 then return 1 end
    if dayprog > r2  or dayprog < d1 then return 0 end
    if dayprog > r1 then
        return (r2 - dayprog) / (r2 - r1)
    end
    return (dayprog - d1) / (d2 - d1)
end

local getsunparams = function(daytime, daylen)
    local mid = daylen / 2
    local yaw = 360 - (daytime / daylen) * 360
    local pitch
    if daytime <= mid then
        pitch = (daytime / mid) * 180 - 90
    else
        pitch = 90 - ((daytime - mid) / mid) * 180
    end
    return yaw, pitch, getsunscale(daytime / daylen)
end

--[[!
    Various plugins for the day manager.
]]
M.plugins = {
    --[[!
        A plugin that adds day/night cycles to the day manager. It works
        by manipulating the sunlight yaw and pitch.
    ]]
    day_night = {
        __activate = (not SERVER) and function(self)
            local daylen
            connect(self, "day_seconds,changed", |self, v| do
                daylen = v
            end)
            connect(self, "day_progress,changed", |self, v| do
                if not daylen then return end
                if edit.player_is_editing() then return end
                self.sun_changed_dir = true
                local yaw, pitch, scale = getsunparams(v, daylen * 1000)
                lights.set_sun_yaw_pitch(yaw, pitch)
                lights.set_sunlight_scale(scale)
                lights.set_skylight_scale(scale)
            end)
        end or nil,

        __run = (not SERVER) and function(self)
            if self.sun_changed_dir and edit.player_is_editing() then
                lights.reset_sun()
                self.sun_changed_dir = false
            end
        end or nil
    }
}

return M
