module("teleporter", package.seeall)

plugin = {
    _class = "teleporter",

    properties = {
        destination = state_variables.state_integer(),
        sound_name  = state_variables.state_string ()
    },

    init = function(self)
        self.destination = 0
        self.sound_name  = ""
    end,

    client_on_collision = function(self, collider)
        if self.destination >= 1 then
            local destinations = entity_store.get_all_bytag("teledest_" .. self.destination)
            if #destinations == 0 then
                logging.log(logging.ERROR, "No teleport destination found.")
                return nil
            end

            local destnum = math.random(1, #destinations)
            collider.position = destinations[destnum].position:as_array()
            collider.yaw      = destinations[destnum].yaw
            collider.velocity = { 0, 0, 0 }

            if self.sound_name ~= "" then
                sound.play(self.sound_name)
            end
        end
    end,
}

entity_classes.reg(
    plugins.bake(
        entity_static.area_trigger,
        { plugin }
    ),
    "mapmodel"
)
