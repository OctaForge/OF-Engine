library.include("firing")
library.include("projectiles")

module("stunball", package.seeall)

projectile = class.new(projectiles.projectile, {
    radius = 4,
    color  = 0xABCDFF,
    speed  = 90,
    time_left = 1,
    explosion_power = 50,

    custom_damage_fun = function(entity, damage)
        if damage > 25 then
            entity:suffer_stun(damage)
        end
    end
})

gun = class.new(firing.gun, {
    delay      = 0.5,
    repeating  = false,
    origin_tag = "",

    handle_client_effect = function(self, shooter, origin_position, target_position, target_entity)
        shooter.projectile_manager:add(
            projectile(
                origin_position,
                target_position:subnew(origin_position):normalize(),
                shooter
            )
        )
    end
})

victim_plugin = {
    properties = {
        suffering_stun = state_variables.state_bool({ client_set = true })
    },

    suffer_stun = function(self, stun)
        if not self.suffering_stun then
            self.old_movement_speed = self.movement_speed
            self.movement_speed     = self.movement_speed / 4
            self.suffering_stun     = true
        end
        self.suffering_stun_left = stun / 10
    end,

    client_act = function(self, seconds)
        if self.suffering_stun then
            local ox = (math.random() - 0.5) * 2 * 2
            local oy = (math.random() - 0.5) * 2 * 2
            local oz = (math.random() - 0.5) * 2
            local speed   = 150
            local density = 2
            effects.flame(
                effects.PARTICLE.SMOKE,
                self:get_center():add(math.vec3(ox, oy, oz)),
                0.5, 1.5, 0x000000, density, 2, speed, 0.6, -15
            )

            if self == entity_store.get_player_entity() then
                self.suffering_stun_left = self.suffering_stun_left - seconds
                if self.suffering_stun_left <= 0 then
                    self.movement_speed = self.old_movement_speed
                    self.suffering_stun = false
                end
            end
        end
    end
}

bot_plugin = {
    init = function(self)
        self.bot_firing_params = {
            firing_delay         = self.gun.delay,
            trigger_finger_delay = 0
        }
    end
}
