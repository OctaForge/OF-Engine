module("dynamic_lights", package.seeall)

dynamic_light = ents.register_class(plugins.bake(ents.Oriented_Marker, {{
    properties = {
        attr1 = svars.State_Integer { gui_name = "radius", alt_name = "radius" },
        attr2 = svars.State_Integer { gui_name = "red",    alt_name = "red"    },
        attr3 = svars.State_Integer { gui_name = "green",  alt_name = "green"  },
        attr4 = svars.State_Integer { gui_name = "blue",   alt_name = "blue"   }
    },

    per_frame = true,

    init = function(self)
        self.radius = 100
        self.red    = 128
        self.green  = 128
        self.blue   = 128
    end,

    dynamic_light_show = function(self, seconds)
        local pos = self.position
        _C.adddynlight(
            pos.x, pos.y, pos.z, self.radius,
            self.red / 255, self.green / 255, self.blue / 255,
            0, 0, 0, 0, 0, 0, 0
        )
    end,

    run = CLIENT and function(self, seconds)
        self:dynamic_light_show(seconds)
    end or nil
}}, "dynamic_light"))

ents.register_class(plugins.bake(dynamic_light, {{
    properties = {
        probability = svars.State_Float(),
        min_delay   = svars.State_Float(),
        max_delay   = svars.State_Float()
    },

    init = function(self)
        self.probability = 0.5
        self.min_delay   = 0.1
        self.max_delay   = 0.3
    end,

    activate = function(self)
        if CLIENT then
            self.delay = 0
        end
    end,

    dynamic_light_show = function(self, seconds)
        self.delay = self.delay - seconds
        if  self.delay <= 0 then
            self.delay = math.max(math.random() * self.max_delay, self.min_delay) * 2
            if math.random() < self.probability then
                local pos = self.position
                _C.adddynlight(
                    pos.x, pos.y, pos.z, self.radius,
                    self.red / 255, self.green / 255, self.blue / 255,
                    self.delay * 1000, 0, math.lsh(1, 2), 0, 0, 0, 0
                )
            end
        end
    end
}}, "flickering_dynamic_light"))
