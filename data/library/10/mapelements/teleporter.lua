module("teleporter", package.seeall)

plugin = {
    properties = {
        destination = svars.State_Integer(),
        sound_name  = svars.State_String()
    },

    init = function(self)
        self.destination = 0
        self.sound_name  = ""
    end,

    activate = CLIENT and function(self)
        signal.connect(self, "collision", self.client_on_collision)
    end or nil,

    client_on_collision = function(_, self, collider)
        if self.destination >= 1 then
            local destinations = ents.get_by_tag("teledest_" .. self.destination)
            if #destinations == 0 then
                #log(ERROR, "No teleport destination found.")
                return nil
            end

            local destnum = math.random(1, #destinations)
            collider.position = destinations[destnum].position:to_array()
            collider.yaw      = destinations[destnum].yaw
            collider.velocity = { 0, 0, 0 }

            if self.sound_name ~= "" then
                sound.play(self.sound_name)
            end
        end
    end,
}

ents.register_class(plugins.bake(
    ents.Area_Trigger,
    { plugin },
    "teleporter"
))
