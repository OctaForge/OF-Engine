module("custom_effect", package.seeall)

rain = {
    drops = {},

    start = function(self, kwargs)
        kwargs = kwargs or {}
        kwargs.radius        = kwargs.radius        or 200
        kwargs.frequency     = kwargs.frequency     or 0.1
        kwargs.spawn_at_once = kwargs.spawn_at_once or 400
        kwargs.max_amount    = kwargs.max_amount    or 2000
        kwargs.x_tilt        = kwargs.x_tilt        or 0
        kwargs.y_tilt        = kwargs.y_tilt        or 0
        kwargs.drop_color    = kwargs.drop_color    or 0xBDBDBD
        kwargs.splash_color  = kwargs.splash_color  or 0xCCDDFF
        kwargs.speed         = kwargs.speed         or 1300
        kwargs.size          = kwargs.size          or 15
        kwargs.thickness     = kwargs.thickness     or 0.05

        self.drops = {}

        local wsize = world.get_size()

        self.add_drop_event = game_manager.get_singleton().event_manager:add({
            seconds_before  = 0,
            seconds_between = kwargs.frequency,
            func = function(_self)
                local camera = entity_store.get_player_entity().position:copy()
                local lx     = math.max(0, camera.x - kwargs.radius)
                local ly     = math.max(0, camera.y - kwargs.radius)
                local hx     = math.min(camera.x + kwargs.radius, wsize)
                local hy     = math.min(camera.y + kwargs.radius, wsize)
                local dx     = hx - lx
                local dy     = hy - ly
                local chance = (dx * dy) / math.pow(wsize, 2);
                local amount = kwargs.spawn_at_once * chance
                if (#self.drops + amount) > kwargs.max_amount then
                    amount = max_amount - #self.drops
                end
                for i = 1, amount do
                    local origin = math.vec3(lx + math.random() * dx, ly + math.random() * dy, wsize)
                    local floor_dist = math.get_floor_distance(origin, wsize * 2)
                    if floor_dist < 0 then floor_dist = wsize end
                    table.insert(self.drops, {
                        position = origin,
                        final_z  = origin.z - floor_dist
                    })
                end
            end
        }, self.add_drop_event)

        self.visual_effect_event = game_manager.get_singleton().event_manager:add({
            seconds_before = 0,
            seconds_between = 0,
            func = function(_self)
                local delta = GLOBAL_CURRENT_TIMEDELTA
                self.drops = table.filter_dict(self.drops, function(k, drop)
                    local bottom = drop.position:copy()
                    bottom.z = bottom.z - kwargs.size
                    bottom.x = bottom.x - kwargs.x_tilt
                    bottom.y = bottom.y - kwargs.y_tilt
                    effects.flare(
                        effects.PARTICLE.STREAK,
                        drop.position, bottom,
                        0,
                        kwargs.drop_color,
                        kwargs.thickness
                    )
                    drop.position.z = drop.position.z - kwargs.speed * delta
                    if drop.position.z > drop.final_z then
                        -- add custom code here (i.e. for water ripples)
                        return true
                    else
                        drop.position.z = drop.final_z - 2
                        effects.splash(
                            effects.PARTICLE.SPARK,
                            15, 0.1,
                            drop.position,
                            kwargs.splash_color,
                            0.2, 70, -1
                        )
                        return false
                    end
                end)
            end
        }, self.visual_effect_event)
    end
}
