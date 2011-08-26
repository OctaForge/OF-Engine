module("dynamic_lights", package.seeall)

dynamic_light = entity_classes.register(plugins.bake(entity_static.world_marker, {{
    _class = "dynamic_light",

    should_act = { client = true },
    properties = {
        attr1 = state_variables.state_integer({ gui_name = "radius", alt_name = "radius" }),
        attr2 = state_variables.state_integer({ gui_name = "red",    alt_name = "red"    }),
        attr3 = state_variables.state_integer({ gui_name = "green",  alt_name = "green"  }),
        attr4 = state_variables.state_integer({ gui_name = "blue",   alt_name = "blue"   }),

        radius = state_variables.variable_alias("attr1"),
        red    = state_variables.variable_alias("attr2"),
        green  = state_variables.variable_alias("attr3"),
        blue   = state_variables.variable_alias("attr4")
    },

    init = function(self)
        self.radius = 100
        self.red    = 128
        self.green  = 128
        self.blue   = 128
    end,

    dynamic_light_show = function(self, seconds)
        CAPI.adddynlight(
            self.position, self.radius,
            math.vec3(
                self.red / 255, self.green / 255, self.blue / 255
            ),
            0, 0, 0, 0,
            math.vec3(0, 0, 0)
        )
    end,

    client_act = function(self, seconds)
        self:dynamic_light_show(seconds)
    end
}}), "playerstart")

entity_classes.register(plugins.bake(dynamic_light, {{
    _class = "flickering_dynamic_light",

    properties = {
        probability = state_variables.state_float(),
        min_delay   = state_variables.state_float(),
        max_delay   = state_variables.state_float()
    },

    init = function(self)
        self.probability = 0.5
        self.min_delay   = 0.1
        self.max_delay   = 0.3
    end,

    client_activate = function(self)
        self.delay = 0
    end,

    dynamic_light_show = function(self, seconds)
        self.delay = self.delay - seconds
        if  self.delay <= 0 then
            self.delay = math.max(math.random() * self.max_delay, self.min_delay) * 2
            if math.random() < self.probability then
                CAPI.adddynlight(
                    self.position, self.radius,
                    math.vec3(
                        self.red / 255, self.green / 255, self.blue / 255
                    ),
                    self.delay * 1000, 0, math.lsh(1, 2), 0,
                    math.vec3(0, 0, 0)
                )
            end
        end
    end
}}), "playerstart")
