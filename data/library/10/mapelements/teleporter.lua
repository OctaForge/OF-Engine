module("teleporter", package.seeall)

plugin = {
    properties = {
        destination = svars.State_Integer(),
        sound_name  = svars.State_String()
    },

    init = function(self)
        self:set_destination(0)
        self:set_sound_name("")
    end,

    activate = CLIENT and function(self)
        signal.connect(self, "collision", self.client_on_collision)
    end or nil,

    client_on_collision = function(self, collider)
        if self:get_destination() >= 1 then
            local destinations = ents.get_by_tag("teledest_" .. self:get_destination())
            if #destinations == 0 then
                #log(ERROR, "No teleport destination found.")
                return nil
            end

            local destnum = math.random(1, #destinations)
            collider:set_position(destinations[destnum]:get_position():to_array())
            collider:set_yaw(destinations[destnum]:get_yaw())
            collider:set_velocity({ 0, 0, 0 })

            if self:get_sound_name() ~= "" then
                sound.play(self:get_sound_name())
            end
        end
    end,
}

ents.register_class(plugins.bake(
    ents.Obstacle,
    { plugin },
    "teleporter"
))
