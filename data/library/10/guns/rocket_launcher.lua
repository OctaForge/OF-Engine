library.include("firing")
library.include("projectiles")

module("rocket_launcher", package.seeall)

rocket = projectiles.projectile:clone {
    radius          = 2,
    visual_radius   = 20,
    color           = 0xDCBBAA,
    explosion_power = 100,
    speed           = 160,
    time_left       = 5,
    gravity_factor  = 0,

    tick = function(self, seconds)
        if self.gravity_factor > 0 then
            self.velocity.z = self.velocity.z
                            - self.gravity_factor
                            * world.gravity
                            * seconds
        end

        return projectiles.projectile.tick(self, seconds)
    end,

    render = function(self)
        local o     = self.position
        local flags = math.bor(
            model.render_flags.CULL_VFC,
            model.render_flags.CULL_OCCLUDED,
            model.render_flags.FULLBRIGHT,
            model.render_flags.CULL_DIST
        )
        local yaw_pitch = self.velocity:to_yaw_pitch()
        local yaw       = yaw_pitch.yaw - 90
        local pitch     = 90 - yaw_pitch.pitch
              pitch     = math.is_nan(pitch) and 0 or pitch
        local args      = {
            self.owner,
            "guns/rocket",
            math.bor(model.anims.IDLE, model.anims.LOOP),
            o, yaw, pitch, 0, flags, 0
        }
        model.render(unpack(args))
    end,

    render = function(self)
        --if edit.get_material(self.position) == edit.MATERIAL_WATER then
        --    effects.regular_splash(
        --        effects.PARTICLE.BUBBLE,
        --        4, 0.5, self.position,
        --        0xFFFFFF, 0.5, 25, 500
        --    )
        --else
            effects.splash(
                effects.PARTICLE.SMOKE,
                2, 0.3, self.position,
                0xF0F0F0, 1.2, 50, -20
            
            )
            effects.flame(
                effects.PARTICLE.FLAME,
                self.position, 0.5, 0.5,
                0xBB8877, 2, 3, 100, 0.4,
                -6
            )
        --end
        effects.dynamic_light(
            self.position, self.visual_radius * 1.8, self.color
        )
    end
}

action_rocket_fire = extraevents.action_parallel:clone {
    name = "action_rocket_fire",
    can_multiply_queue = false
}

rocket_launcher = projectiles.gun:clone {
    projectile_class = rocket,
    delay            = 0.5,
    repeating        = false,
    origin_tag       = "tag_weapon",

    handle_client_effect = function(
        self, shooter, origin_position, target_position, target_entity
    )
        local action_performer = shooter.should_act
            and shooter
            or game_manager.get_singleton()

        local action_adder = shooter.should_act
            and shooter.queue_action
            or action_performer.add_action_parallel

        action_adder(action_performer, action_rocket_fire({
            firing.action_shoot1({ seconds_left = 1 }),
            extraevents.action_delayed(function()
                if not health.is_valid_target(shooter) then
                    return nil
                end

                local current_origin_position = self:get_origin(shooter)
                local targeting_origin = shooter:get_targeting_origin(
                    current_origin_position
                )
                local target_data = firing.find_target(
                    shooter, current_origin_position,
                    targeting_origin, target_position,
                    2048
                )
                local current_target_position = target_data.target

                effects.fireball(
                    effects.PARTICLE.EXPLOSION, current_origin_position,
                    3, 0.5, 0xFF775F, 3
                )
                effects.dynamic_light(
                    current_origin_position, 20, 0xFF775F, 0.8, 0.1, 0, 10
                )

                if shooter.radius > 0 then
                    #log(DEBUG, "adjusting rocket origin")
                    local shooter_position = shooter:get_position():copy()
                    shooter_position.z = current_origin_position.z
                    local dir = shooter_position:sub_new(
                        current_origin_position
                    )
                    local dist = dir:length()
                        + self.projectile_class.radius

                    if dist > shooter.radius then
                        current_origin_position:add(
                            dir:normalize():mul(
                                dist - shooter.radius
                                     + self.projectile_class.shooter_safety
                            )
                        )
                    end

                    self:shoot_projectile(
                        shooter, current_origin_position,
                        current_target_position, target_entity,
                        self.projectile_class
                    )
                    self:do_recoil(shooter, 40)
                end
            end, { seconds_left = 0.2 })
        }))
    end
}
