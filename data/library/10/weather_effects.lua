--[[!
    File: library/10/weather_effects.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Weather effects for OctaForge. Currently features rain.
]]

--[[!
    Package: weather_effects
    This module is meant to provide various weather effects like rain,
    snow etc., currently rain is provided. Can be used in more complex
    modules later.
]]
module("weather_effects", package.seeall)

--[[!
    Class: rain
    Rain effect. Fully customizable. Use <start> to begin.
]]
rain = {
    drops = {},

    --[[!
        Function: start
        Starts a rain effect. Use like this:

        (start code)
            weather_effects.rain:start(PARAMETERS)
        (end)

        Parameters:
            kwargs - an optional argument. It's an associative table supplying
            various additional parameters to adjust the rain effect.

        Kwargs:
            radius - the radius around the player the rain will take effect
            in. Defaults to 200, which is mostly satisfactory.
            frequency - the rain frequency. Defaults to 0.1.
            spawn_at_once - maximal amount of raindrops that can spawn at
            once, defaults to 400.
            max_amount - maximal amount of raindrops that can spawn, defaults
            to 2000.
            x_tilt - specifies by how much to tilt the raindrops to create
            a wind effect on them. Defaults to 0.
            y_tilt - see above.
            drop_color - hex number specifying the raindrop color. Defaults
            to 0xBDBDBD
            splash_color - hex number specifying the color of the splash
            that appears on the ground when the raindrop hits it. Defaults
            to 0xCCDDFF.
            speed - raindrop speed, defaults to 1300.
            size - raindrop size, defaults to 15.
            thickness - raindrop thickness, defaults to 0.05.
    ]]
    start = function(self, kwargs)
        -- default values for kwargs
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

        -- clears up the drops - there is a possibility previous rain
        -- was started already, clear up its stuff
        self.drops = {}

        -- world size
        local wsize = _V.mapsize

        -- the game manager singleton
        local singleton = game_manager.get_singleton()

        -- add drop event - the one that has no visible effect, adds a
        -- raindrop to the storage with the right parameters
        self.add_drop_event = singleton.event_manager:add({
            seconds_before  = 0,
            seconds_between = kwargs.frequency,
            func = function(_self)
                local camera = ents.get_player():get_position():copy()
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
                    local origin = math.Vec3(
                        lx + math.random() * dx,
                        ly + math.random() * dy,
                        wsize
                    )
                    local floor_dist = math.floor_distance(
                        origin, wsize * 2
                    )
                    if floor_dist < 0 then floor_dist = wsize end
                    local drops = self.drops
                    drops[#drops + 1] = {
                        position = origin,
                        final_z  = origin.z - floor_dist
                    }
                end
            end
        }, self.add_drop_event)

        -- the visual effect, loops the drops, shows some and filters
        -- them out
        self.visual_effect_event = singleton.event_manager:add({
            seconds_before = 0,
            seconds_between = 0,
            func = function(_self)
                local delta = frame.get_frame_time()
                self.drops = table.filter(self.drops, function(k, drop)
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
