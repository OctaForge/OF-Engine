module("health", package.seeall)

action_pain = std.class.new(entity_animated.action_local_animation, {
    seconds_left       = 0.6,
    local_animation    = actions.ANIM_PAIN,
    can_multiply_queue = false
}, "action_pain")

action_death = std.class.new(actions.action, {
    can_multiply_queue = false,
    cancellable        = false,
    seconds_left       = 5.5,

    do_start = function(self)
        std.signal.emit(self.actor, "fragged")
        -- this won't clear us, as we cannot be cancelled
        self.actor:clear_actions()
        self.actor.can_move = false
    end,

    do_finish = function(self)
        self.actor:respawn()
    end
}, "action_death")

plugin = {
    -- client_set for health means that when we shoot someone, we get
    -- immediate feedback - no need to wait for server response
    properties = {
        health      = state_variables.state_integer({ client_set = true }),
        max_health  = state_variables.state_integer({ client_set = true }),
        spawn_stage = state_variables.state_integer(),
        blood_color = state_variables.state_integer(),
        pain_sound  = state_variables.state_string ()
    },

    on_spawn_stage = function(self, stage, auid)
        if stage == 1 then -- client ack
            if CLIENT then
                self.spawn_stage = 2
            end
        elseif stage == 2 then -- server vanishes player
            if SERVER then
                if auid == self.uid then
                    if  self.default_model_name then
                        self.model_name  = ""
                    end
                    self.animation   = std.math.bor(actions.ANIM_IDLE, actions.ANIM_LOOP)
                    self.spawn_stage = 3
                end
                return true, "cancel_state_data_update"
            end
        elseif stage == 3 then -- client repositions etc.
            if CLIENT and self == entity_store.get_player_entity() then
                std.signal.emit(self,"client_respawn")
                self.spawn_stage = 4
            end
        elseif stage == 4 then -- server appears player and sets in motion
            if SERVER then
                -- do this first
                self.health     = self.max_health
                self.can_move   = true

                if  self.default_model_name then
                    self.model_name = self.default_model_name
                end
                if  self.default_hud_model_name then
                    self.hud_model_name = self.default_hud_model_name
                end

                self.spawn_stage = 0
                return true, "cancel_state_data_update"
            end
        end
    end,

    respawn = function(self)
        self.spawn_stage = 1
    end,

    init = function(self)
        self.max_health  = 100
        self.health      = self.max_health
        self.pain_sound  = ""
        self.blood_color = 0x60FFFF
    end,

    activate = function(self)
        std.signal.connect(self,state_variables.get_on_modify_name("health"),      self.on_health)
        std.signal.connect(self,state_variables.get_on_modify_name("spawn_stage"), self.on_spawn_stage)
    end,

    client_activate = function(self)
        std.signal.connect(self,state_variables.get_on_modify_name("health"),      self.on_health)
        std.signal.connect(self,state_variables.get_on_modify_name("spawn_stage"), self.on_spawn_stage)
    end,

    decide_animation = function(self, ...)
        if self.health > 0 then
            return self.base_class.decide_animation(self, ...)
        else
            return std.math.bor(actions.ANIM_DYING, actions.ANIM_RAGDOLL)
        end
    end,

    decide_action_animation = function(self, ...)
        local ret = self.base_class.decide_action_animation(self, ...)

        -- clean up if not dead
        if self.health > 0 and (ret == actions.ANIM_DYING or ret == std.math.bor(actions.ANIM_DYING, actions.ANIM_RAGDOLL)) then
            self:set_local_animation(std.math.bor(actions.ANIM_IDLE, actions.ANIM_LOOP))
            ret = self.animation
        end

        return ret
    end,

    client_act = function(self)
        if self ~= entity_store.get_player_entity() then return nil end

        if not GLOBAL_GAME_HUD then
            local health = self.health
            if health then
                local color
                if health > 75 then
                    color = 0x88FFAA
                elseif health > 33 then
                    color = 0xCCDD67
                else
                    color = 0xFF4431
                end
                gui.hud_label(tostring(health), 0.94, 0.88, 0.5, color)
            end
        else
            local raw    = std.math.floor((34 * self.health) / self.max_health)
            local whole  = std.math.floor(raw  / 2)
            local half   = raw > whole * 2
            local params = GLOBAL_GAME_HUD:get_health_params()
            gui.hud_image(
                string.gsub(
                    params.icon,
                    "%VARIANT%",
                    (whole >= 10 and whole or "0" .. std.math.clamp(whole, 1, 100))
                     .. (half and "_5" or "")
                ),
                params.x, params.y, params.w, params.h
            )
        end
    end,

    on_health = function(self, health, server_origin)
        if self.old_health and health < self.old_health then
            local diff = self.old_health - health

            if CLIENT then
                if diff >= 5 then
                    if self.pain_sound ~= "" then
                        sound.play(self.pain_sound, self.position)
                    end
                    self:visual_pain_effect(health)
                    if not server_origin or health > 0 then
                        self:queue_action(action_pain())
                    end
                    if self == entity_store.get_player_entity() and self.old_health ~= health then
                        effects.client_damage(diff, diff)
                    end
                end
            else
                if health <= 0 then
                    self:queue_action(action_death())
                end
            end
        end
        self.old_health = health
    end,

    visual_pain_effect = function(self, health)
        local pos = self.position:copy()
        pos.z = pos.z + self.eye_height - 4
        effects.splash(effects.PARTICLE.BLOOD, std.conv.to("integer", (self.old_health - health) / 3), 1000, pos, self.blood_color, 2.96)
        effects.decal(effects.DECAL.BLOOD, self.position, std.math.Vec3(0, 0, 1), 7, self.blood_color)
        if self == entity_store.get_player_entity() then effects.client_damage(0, self.old_health - health) end
    end,

    suffer_damage = function(self, source)
        local damage = (type(source.damage) == "number") and source.damage or source
        if  self.health > 0 and damage and damage ~= 0 then
            self.health = std.math.max(0, self.health - damage)
        end
    end
}

function die_if_off_map(entity)
    if  entity == entity_store.get_player_entity() and is_valid_target(entity) then
        entity.health = 0 -- kill instantly
    end
end

function is_valid_target(entity)
    return (entity and not entity.deactivated
                   and entity.health
                   and entity.health > 0
                   and entity.client_state ~= character.CLIENT_STATE.EDITING
                   and (not entity.spawn_stage or entity.spawn_stage == 0)
                   and entity.client_state ~= character.CLIENT_STATE.LAGGED
    )
end

deadly_area_trigger_plugin = {
    client_on_collision = function(self, entity)
        if entity ~= entity_store.get_player_entity() then return nil end

        if is_valid_target(entity) then
            entity.health = 0
        end
    end
}

deadly_area = entity_classes.register(
    plugins.bake(
        entity_static.area_trigger,
        { deadly_area_trigger_plugin },
        "deadly_area"
    ),
    "mapmodel"
)
