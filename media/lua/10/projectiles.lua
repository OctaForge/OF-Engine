local sound = require("core.engine.sound")
local model = require("core.engine.model")
local edit = require("core.engine.edit")
local ents = require("core.entities.ents")

require("10.firing")

module("projectiles", package.seeall)

serverside = true

function do_blast_wave(position, power, velocity, custom_damage_fun, owner)
    local expo = 1.333
    local max_dist = math.pow(power - 1, 1 / expo)

    local entities
    if serverside then
        if SERVER then
            entities = ents.get_by_distance(position, { max_distance = max_dist })
            entities = table.map   (entities, function(pair) return pair[1] end)
            entities = table.filter(entities, function(i, entity) return not entity:is_a(ents.Player) end)
        else
            entities = { ents.get_player() }
        end
    else
        entities = {}
        if owner == ents.get_player() then
            entities = ents.get_by_distance(position, { max_distance = max_dist })
            entities = table.map   (entities, function(pair) return pair[1] end)
            entities = table.filter(entities, function(i, entity) return not entity:is_a(ents.Player) end)
        end
        entities[#entities + 1] = ents.get_player()
    end

    for i, entity in pairs(entities) do
        if not entity.suffer_damage then return nil end

        local distance = entity:get_center():sub(position):length()
        distance   = math.max(1, distance)
        local bump = math.round(math.max(0, power - math.pow(distance, expo)))
              bump = bump - (bump % 5)

        if not custom_damage_fun then
            if entity:get_attr("velocity") then
                entity:get_attr("velocity"):add(
                    entity:get_attr("position"):sub_new(
                        position
                    ):add(
                        velocity:copy():normalize():mul(4)
                    ):add(
                        math.Vec3(0, 0, 2)
                    ):normalize():mul(bump * 4)
                )
            end
            entity:suffer_damage({ damage = bump })
        else
            custom_damage_fun(entity, bump)
        end
    end
end

projectile = table.Object:clone {
    physics_frame_size = 0.02,
    speed              = 1,
    time_left          = 5,
    gravity            = 0,
    radius             = 1,
    explosion_power    = 0,
    shooter_safety     = 0.1,

    __init = function(self, position, velocity, owner, target_entity)
        self.position = position:copy()
        self.velocity = velocity:copy():mul(self.speed)

        self.owner  = owner
        self.ignore = owner

        self.target_entity = target_entity

        self.physics_frame_timer = extraevents.repeating_timer(self.physics_frame_size, true)

        if owner then
            self.yaw = owner:get_attr("yaw")
            self.pitch = owner:get_attr("pitch")
            self.roll = owner:get_attr("roll")
        end

        self.collide_fun = geometry.is_colliding
    end,

    destroy = function(self) end,

    tick = function(self, seconds)
        self.time_left = self.time_left - seconds
        if self.time_left < 0 then
            return false
        end

        if  self.gravity then
            self.velocity.z = self.velocity.z - world.gravity * self.gravity * seconds
        end

        local first_tick =  self.physics_frame_timer:tick(seconds)
        while first_tick or self.physics_frame_timer:tick(0) do
              first_tick = false

            local last_position = self.position:copy()
            if  self.bounce_fun then
                self:bounce_fun(self.physics_frame_size)
            else
                self.position:add(self.velocity:mul_new(self.physics_frame_size))
            end

            if self.collide_fun(self.position, self.radius, self.owner) then
                local NUM_STEPS = 5
                local step      = self.velocity:mul_new(self.physics_frame_size / NUM_STEPS)
                for i = 1, NUM_STEPS do
                    last_position:add(step)
                    if i == NUM_STEPS or self.collide_fun(last_position, self.radius, self.owner) then
                        break
                    end
                end
                self.position = last_position
                return self:on_explode()
            end
        end

        return true
    end,

    render = function(self)
        effects.fireball(
            effects.PARTICLE.EXPLOSION_NO_GLARE,
            self.position,
            self.radius,
            0.05,
            self.color,
            self.radius
        )
        effects.dynamic_light(
            self.position,
            self.radius * 9,
            self.color
        )
    end,

    on_explode = function(self)
        if not SERVER then
            local radius = self.visual_radius or self.radius
            -- TODO: proper explosion effect
            --effects.splash(effects.PARTICLE.SMOKE, 5, 2.5, self.position, 0x222222, 12, 50, 500, nil, 1, false, 3)
            --effects.splash(effects.PARTICLE.SMOKE, 5, 0.2, self.position, 0x222222, 12, 50, 500, nil, 1, false, 4)
            --effects.splash(effects.PARTICLE.SPARK, 160, 0.03, self.position, 0xFFC864, 1.4, 300, nil, nil, nil, true)
            --effects.splash(effects.PARTICLE.FLAME1, 15, 0.03, self.position, 0xFFFFFF, 3.2, 300, nil, nil, nil, true)
            --effects.splash(effects.PARTICLE.FLAME2, 15, 0.03, self.position, 0xFFFFFF, 3.2, 300, nil, nil, nil, true)
            --effects.splash(effects.PARTICLE.FLAME2, 15, 0.03, self.position, 0xFFFFFF, 3.2, 300, nil, nil, nil, true)
            --effects.splash(effects.PARTICLE.EXPLODE, 1, 0.1, self.position, 0xFFFFFF, 10, 300, 500, true, nil, nil, 4)
            effects.fireball(effects.PARTICLE.EXPLOSION, self.position, radius, 1, self.color, radius)

            if edit.get_material(self.position) == edit.MATERIAL_WATER then
                if self.underwater_explosion_sound then
                    sound.play(self.underwater_explosion_sound, self.position)
                end
            else
                if self.explosion_sound then
                    sound.play(self.explosion_sound, self.position)
                end
            end

            effects.decal        (effects.DECAL.SCORCH, self.position, self.velocity:copy():normalize():mul(-1), radius)
            effects.dynamic_light(self.position, radius * 14, self.color, 0.2666, 0.0333, 0, radius * 9)
        end

        do_blast_wave(self.position, self.explosion_power, self.velocity, self.custom_damage_fun, self.owner)
        return false
    end
}

manager = table.Object:clone {
    __init = function(self)
        self.projectiles = {}
    end,

    add = function(self, projectile)
        local projs = self.projectiles
        projs[#projs + 1] = projectile
    end,

    tick = function(self, seconds)
        self.projectiles = table.filter(self.projectiles, function(i, projectile)
            local persist = projectile:tick(seconds)
            if not persist then
                projectile:destroy()
            end
            return persist
        end)
    end,

    render = function(self)
        for i,  projectile in pairs(self.projectiles) do
            if  projectile.render then
                projectile:render()
            end
        end
    end,

    render = function(self)
        for i,  projectile in pairs(self.projectiles) do
            if  projectile.render then
                projectile:render()
            end
        end
    end
}

plugin = {
    activate = function(self)
        self.projectile_manager = manager()
    end,

    run = function(self, seconds)
        if #self.projectile_manager.projectiles == 0 then
            return nil
        end

        self.projectile_manager:tick(seconds)
        if not SERVER then self.projectile_manager:render() end
    end,

    render = function(self, hud_pass, need_hud)
        if #self.projectile_manager.projectiles == 0 then
            return nil
        end

        if not hud_pass then
            self.projectile_manager:render()
        end
    end
}

gun = firing.gun:clone {
    shoot_projectile = function(self, shooter, origin_position, target_position, target_entity, projectile_class)
        local projectile_handler = (
            shooter.per_frame and
            shooter.projectile_manager
        ) and shooter or game_manager.get_singleton()

        projectile_handler.projectile_manager:add(
            projectile_class(
                origin_position,
                target_position:sub_new(origin_position):normalize(),
                shooter,
                target_entity
            )
        )
    end
}

-- examples

small_shot = projectile:clone {
    radius = 5,
    color  = 0xFFCC66,
    speed  = 50,
    explosion_power = 50
}

debris = projectile:clone {
    radius     = 0.5,
    color      = 0xDCBBAA,
    time_left  = 5,
    gravity    = 1,
    elasticity = 0.5,
    friction   = 0.6,

    __init = function(self, position, velocity, kwargs)
        projectile.__init(self, position, velocity, kwargs)

        self.bounce_fun = function(seconds)
            return geometry.bounce(
                self,
                self.elasticity,
                self.friction,
                seconds
            )
        end
    end,

    render = function(self)
        effects.splash(effects.PARTICLE.SMOKE, 1, 0.25, self.position, 0x000000, 1, 2, -20)
    end,

    render = function(self)
        if not self.debris_model then return nil end

        local o     = self.position
        local flags = math.bor(model.render_flags.CULL_VFC, model.render_flags.CULL_DIST)
        
        model.render(
            game_manager.get_singleton(),
            self.debris_model,
            model.anims.IDLE,
            o, 0, 0, 0, flags, 0
        )
    end,

    on_explode = function(self)
        return false
    end
}
