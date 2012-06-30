library.include("firing")

module("chaingun", package.seeall)

chaingun = table.subclass(firing.gun, {
    repeating     = true,
    delay         = 100, -- unused
    origin_tag    = "tag_weapon",
    damage        = 5,
    scatter       = 0.033,
    range         = 150,
    protocol_rate = 0.5,
    firing_rate   = 0.05,

    pellet_cache = {},
    pellet_cache_timestamp = -1,

    do_shot = function(self, shooter, target_position, target_entity)
        shooter.chaingun_firing_update = true
    end,

    stop_shooting = function(self, shooter)
        shooter.chaingun_firing_update = false
    end,

    do_real_shot = function(self, shooter)
        if shooter.controlled_here then
            self:do_recoil(shooter, math.random() * 4)
        end

        local visual_origin    = self:get_origin(shooter)
        local targeting_origin = shooter:get_targeting_origin(visual_origin)
        local target_data      = firing.find_target(
            shooter, visual_origin, targeting_origin,
            nil, self.range, self.scatter
        )
        local target           = target_data.target
        local target_entity    = target_data.target_entity

        if  target_entity and target_entity.suffer_damage then
            target_entity:suffer_damage({
                origin = target,
                damage = (shooter == entity_store.get_player_entity())
                    and self.damage
                    or 0,
                non_controller_damage =
                    (shooter ~= entity_store.get_player_entity())
                        and self.damage
                        or 0
            })
        end

        for i = 1, math.random(2, 4) do
            effects.flare(
                effects.PARTICLE.STREAK,
                visual_origin, target:sub_new(
                    math.norm_vec3():mul(1.5)
                ), self.firing_rate * 1.5, 0xE49B4B
            )
        end
        effects.lightning(
            visual_origin, target, self.firing_rate * 1.5, 0xFF3333
        )
        if math.random() < 0.25 then
            effects.splash(
                effects.PARTICLE.SPARK, 1,
                self.firing_rate * 0.75, visual_origin,
                0xB49B4B, 1.0, 70, 1
            )
        end

        if target:is_close_to(targeting_origin, self.range - 0.25) then
            effects.splash(
                effects.PARTICLE.SPARK, 15, 0.2, target, 0xF48877, 1.0, 70, 1
            )
            effects.decal(
                effects.DECAL.BULLET,
                target, visual_origin:sub_new(target):normalize(), 3
            )
            shooter.chaingun_target = target
        else
            shooter.chaingun_target = nil
        end

        
    end,
}, "chaingun")

chaingun.plugin = {
    properties = {
        chaingun_firing_update = state_variables.state_bool({
            client_set = true, reliable = false, has_history = false
        })
    },

    client_activate = function(self)
        self.chaingun_firing = false

        signal.connect(self,
            state_variables.get_on_modify_name("chaingun_firing_update"),
            function(self, value)
                value = value and health.is_valid_target(self)

                if not self.chaingun_firing and value then
                    self.chaingun_firing_timer
                        = events.repeating_timer(chaingun.firing_rate)
                    self.chaingun_firing_timer:prime()

                    if self.controlled_here then
                        self.chaingun_protocol_timer
                            = events.repeating_timer(chaingun.protocol_rate)
                    end
                end

                if not self.controlled_here then
                    self.chaingun_firing_expiration = 0
                end

                self.chaingun_firing = value
            end
        )
    end,

    client_act = function(self, seconds)
        if self.chaingun_firing then
            effects.dynamic_light(self.position, 30, 0xFFEECC)

            if self.chaingun_target then
                effects.dynamic_light(self.chaingun_target, 15, 0xFFEECC)
            end

            if not self.chaingun_firing_action then
                self.chaingun_firing_action
                    = firing.action_shoot2_repeating({ seconds_left = 10 })
                self:clear_actions()
                self:queue_action (self.chaingun_firing_action)
            else
                self.chaingun_firing_action.seconds_left = 10
            end

            if not health.is_valid_target(self) then
                self.chaingun_firing = false
                return nil
            end

            if self.chaingun_firing_timer:tick(seconds) then
                local gun = firing.guns[self.current_gun_index]
                if    gun:is_a(chaingun) then
                    firing.guns[self.current_gun_index]:do_real_shot(self)
                else
                    log(ERROR, "chaingun firing error")
                    self.chaingun_firing = false
                end
            end

            if self.controlled_here then
                if self.chaingun_protocol_timer:tick(seconds) then
                    self.chaingun_firing_update = true
                end
            else
                self.chaingun_firing_expiration
                    = self.chaingun_firing_expiration + seconds
                if self.chaingun_firing_expiration
                > (chaingun.protocol_rate * 2.5) then
                    self.chaingun_firing = false
                end
            end
        else
            if  self.chaingun_firing_action then
                self.chaingun_firing_action.seconds_left = -1
                self.chaingun_firing_action = nil
            end
        end
    end
}
