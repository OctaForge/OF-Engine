module("health", package.seeall)

local DYING = model.register_anim("dying")
local PAIN = model.register_anim("pain")

action_pain = ents.Local_Animation_Action:clone {
    name = "action_pain",
    seconds_left       = 0.6,
    local_animation    = PAIN,
    can_multiply_queue = false
}

action_death = actions.Action:clone {
    name = "action_death",
    can_multiply_queue = false,
    cancellable        = false,
    seconds_left       = 5.5,

    start = function(self)
        signal.emit(self.actor, "fragged")
        -- this won't clear us, as we cannot be cancelled
        self.actor:clear_actions()
        self.actor.can_move = false
    end,

    finish = function(self)
        self.actor:respawn()
    end
}

plugin = {
    -- client_set for health means that when we shoot someone, we get
    -- immediate feedback - no need to wait for server response
    properties = {
        health      = svars.State_Integer { client_set = true },
        max_health  = svars.State_Integer { client_set = true },
        spawn_stage = svars.State_Integer(),
        blood_color = svars.State_Integer(),
        pain_sound  = svars.State_String()
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
                    self.animation   = math.bor(model.anims.IDLE, model.anims.LOOP)
                    self.spawn_stage = 3
                end
                self:cancel_sdata_update()
            end
        elseif stage == 3 then -- client repositions etc.
            if CLIENT and self == ents.get_player() then
                signal.emit(self,"client_respawn")
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
                self:cancel_sdata_update()
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
        signal.connect(self,"health_changed",      self.on_health)
        signal.connect(self,"spawn_stage_changed", self.on_spawn_stage)
    end,

    decide_animation = function(self, ...)
        if self.health > 0 then
            return self.__proto.__proto.decide_animation(self, ...)
        else
            return math.bor(DYING, model.anims.RAGDOLL)
        end
    end,

    get_animation = function(self, ...)
        local ret = self.__proto.__proto.get_animation(self, ...)

        -- clean up if not dead
        if self.health > 0 and (ret == DYING or ret == math.bor(DYING, model.anims.RAGDOLL)) then
            self:set_local_animation(math.bor(model.anims.IDLE, model.anims.LOOP))
            ret = self.animation
        end

        return ret
    end,

    run = CLIENT and function(self)
        if self ~= ents.get_player() then return nil end

        --if not GLOBAL_GAME_HUD then
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
                --gui.hud_label(tostring(health), 0.94, 0.88, 0.5, color)
            end
        --[[else
            local raw    = math.floor((34 * self.health) / self.max_health)
            local whole  = math.floor(raw  / 2)
            local half   = raw > whole * 2
            local params = GLOBAL_GAME_HUD:get_health_params()
            --gui.hud_image(
            --    string.gsub(
            --        params.icon,
            --        "%VARIANT%",
            --        (whole >= 10 and whole or "0" .. math.clamp(whole, 1, 100))
             --        .. (half and "_5" or "")
             --   ),
             --   params.x, params.y, params.w, params.h
            --)
        end]]
    end or nil,

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
                    --if self == ents.get_player() and self.old_health ~= health then
                    --    effects.client_damage(diff, diff)
                    --end
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
        effects.splash(effects.PARTICLE.BLOOD, tointeger((self.old_health - health) / 3), 1000, pos, self.blood_color, 2.96)
        effects.decal(effects.DECAL.BLOOD, self.position, math.Vec3(0, 0, 1), 7, self.blood_color)
        --if self == ents.get_player() then effects.client_damage(0, self.old_health - health) end
    end,

    suffer_damage = function(self, source)
        local damage = (type(source.damage) == "number") and source.damage or source
        if  self.health > 0 and damage and damage ~= 0 then
            self.health = math.max(0, self.health - damage)
        end
    end
}

function die_if_off_map(entity)
    if  entity == ents.get_player() and is_valid_target(entity) then
        entity.health = 0 -- kill instantly
    end
end

function is_valid_target(entity)
    return (entity and not entity.deactivated
                   and entity.health
                   and entity.health > 0
                   and not entity.editing
                   and (not entity.spawn_stage or entity.spawn_stage == 0)
                   and not entity.lagged
    )
end

deadly_area_trigger_plugin = {
    client_on_collision = function(self, entity)
        if entity ~= ents.get_player() then return nil end

        if is_valid_target(entity) then
            entity.health = 0
        end
    end,
    activate = CLIENT and function(self)
        signal.connect(self, "collision", self.client_on_collision)
    end or nil
}

deadly_area = ents.register_class(
    plugins.bake(
        ents.Obstacle,
        { deadly_area_trigger_plugin },
        "deadly_area"
    )
)
