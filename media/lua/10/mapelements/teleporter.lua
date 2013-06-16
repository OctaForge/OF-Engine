local sound = require("core.engine.sound")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

module("teleporter", package.seeall)

plugin = {
    properties = {
        destination = svars.State_Integer(),
        sound_name  = svars.State_String()
    },

    init = function(self)
        self:set_attr("destination", 0)
        self:set_attr("sound_name", "")
    end,

    activate = (not SERVER) and function(self)
        signal.connect(self, "collision", self.client_on_collision)
    end or nil,

    client_on_collision = function(self, collider)
        if self:get_attr("destination") >= 1 then
            local destinations = ents.get_by_tag("teledest_" .. self:get_attr("destination"))
            if #destinations == 0 then
                #log(ERROR, "No teleport destination found.")
                return nil
            end

            local destnum = math.random(1, #destinations)
            collider:set_attr("position", destinations[destnum]:get_attr("position"):to_array())
            collider:set_attr("yaw", destinations[destnum]:get_attr("yaw"))
            collider:set_attr("velocity", { 0, 0, 0 })

            if self:get_attr("sound_name") ~= "" then
                sound.play(self:get_attr("sound_name"))
            end
        end
    end,
}

ents.register_class(ents.Obstacle, { plugin }, "teleporter")
