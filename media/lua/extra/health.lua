--[[!<
    A reusable health system that integrates with the game manager and
    other modules (the game manager is required).

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

--! Module: health
local M = {}

local frame = require("core.events.frame")
local actions = require("core.events.actions")
local signal = require("core.events.signal")
local model = require("core.engine.model")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

local eactions = require("extra.events.actions")

local connect, emit = signal.connect, signal.emit
local min, max = math.min, math.max

--[[! Enum: health.anims
    This module adds three new animations, "dead", "dying" and "pain",
    on the client. They're stored in this enumeration.
]]
local anims = (not SERVER) and {:
    dead  = model.register_anim "dead",
    dying = model.register_anim "dying",
    pain  = model.register_anim "pain"
:} or nil
M.anims = anims

--[[! Object: health.Action_Pain
    Derives from {{$actions.Action_Local_Animation}} and is queued as a pain
    effect. The default duration is 600 milliseconds and it uses the
    previously defined PAIN animation. It also cannot be used more than
    once at a time. It only exists on the client.
]]
local Action_Pain = (not SERVER) and eactions.Action_Local_Animation:clone {
    name            = "Action_Pain",
    millis_left     = 600,
    local_animation = anims.pain,
    allow_multiple  = false
} or nil
M.Action_Pain = Action_Pain

--[[! Object: health.Action_Death
    Derives from a regular Action. Represents player death and the default
    duration is 5 seconds. Like pain, it cannot be used more than once at
     a time and it's not cancelable. It only exists on the server.
]]
local Action_Death = SERVER and actions.Action:clone {
    name            = "Action_Death",
    allow_multiple  = false,
    cancelable      = false,
    millis_left     = 5000,

    --[[!
        Makes the player unable to move, sets up a possible ragdoll, clears
        the player's actions (except itself as it's not cancelable) and
        emits the "killed" signal on the player.
    ]]
    __start = function(self)
        local actor = self.actor
        actor:set_attr("can_move", false)
        actor:clear_actions()
        emit(actor, "killed")
    end,

    --! Triggers a respawn.
    __finish = function(self)
        self.actor:game_manager_respawn()
    end
} or nil
M.Action_Death = Action_Death

--[[! Object: health.player_plugin
    The player plugin - use it when baking your player entity class. Must be
    used after the game manager player plugin has been baked in (it overrides
    some of its stuff).

    Properties:
        - health - the player's current health.
        - max_health - the maximum health a player can have.
]]
M.player_plugin = {
    __properties = {
        health = svars.State_Integer     { client_set = true },
        max_health = svars.State_Integer { client_set = true }
    },

    __init_svars = function(self)
        self:set_attr("health", 100)
        self:set_attr("max_health", 100)
    end,

    __activate = function(self)
        connect(self, "health_changed", self.health_on_health)
    end,

    --[[!
        Overrides the serverside spawn stage 4. In addition to the default
        behavior it restores the player's health.
    ]]
    game_manager_spawn_stage_4 = (SERVER) and function(self, auid)
        self:set_attr("health", self:get_attr("max_health"))
        self:set_attr("can_move", true)
        self:set_attr("spawn_stage", 0)
        self:cancel_sdata_update()
    end or nil,

    get_animation = function(self)
        local ret = self.__parent_class.get_animation(self)
        local INDEX, idle = model.anims.INDEX, model.anims.idle
        if self:get_attr("health") > 0 then
            if (ret & INDEX) == anims.dying or (ret & INDEX) == anims.dead then
                self:set_local_animation(idle | model.anim_control.LOOP)
                self.prev_bt = nil
                ret = self:get_attr("animation")
            end
        end
        return ret
    end,

    --[[!
        Overriden so that the "dying" animation is displayed correctly.
    ]]
    decide_base_time = function(self, anim)
        if (anim & model.anims.INDEX) == anims.dying then
            local pbt = self.prev_bt
            if not pbt then
                pbt = frame.get_last_millis()
                self.prev_bt = pbt
            end
            return pbt
        end
        return self:get_attr("start_time")
    end,

    --[[!
        Overriden so that the "dying" animation can be used when health is 0
        (and "dead" when at least 1 second after death).
    ]]
    decide_animation = (not SERVER) and function(self, ...)
        if self:get_attr("health") > 0 then
            return self.__parent_class.decide_animation(self, ...)
        else
            local anim
            local pbt = self.prev_bt
            if pbt and (frame.get_last_millis() - pbt) > 1000 then
                anim = anims.dead | model.anim_control.LOOP
            else
                anim = anims.dying
            end
            return anim | model.anim_flags.NOPITCH | model.anim_flags.RAGDOLL
        end
    end or nil,

    health_on_health = function(self, health, server_orig)
        local oh = self.old_health
        self.old_health = health
        if not oh then return end
        self:health_changed(health, health - oh, server_orig)
    end,

    --[[!
        There are two variants of this one, for the client and for the server.

        Server:
            Handles death, so the serverside version queues the death action
            if health is <= 0.

        Client:
            The clientside variant handles pain, so it queues the pain action
            if health is > 0 and the diff is lower than -5.

        Arguments:
            - health - the current health.
            - diff - the difference from the old health state.
            - server_orig - true if the change originated on the server.
    ]]
    health_changed = SERVER and function(self, health, diff, server_orig)
        if health <= 0 then self:enqueue_action(Action_Death()) end
    end or function(self, health, diff, server_orig)
        if diff <= -5 and health > 0 then
            self:enqueue_action(Action_Pain())
        end
    end,

    --[[!
        Adds to player's health. If the provided amount is zero, it does
        nothing. The current health also must be larger than 0. Negative
        amount does damage to the player. The result is always clamped
        at 0 on the bottom and at max_health on the top.
    ]]
    health_add = function(self, amount)
        local ch = self:get_attr("health")
        if ch > 0 and amount != 0 then
            local mh = self:get_attr("max_health")
            self:set_attr("health", min(mh, max(0, ch + amount)))
        end
    end
}

--[[! Function: health.is_valid_target
    Returns true if the given player entity is a valid target (for example
    for shooting or other kind of damage). The player must not be editing
    or lagged, its health must be higher than 0 and it must be already
    spawned (the spawn stage must be 0).
]]
local is_valid_target = function(ent)
    if not ent or ent.deactivated then return false end

    local cs = ent:get_attr("client_state")
    if cs == 3 or cs == 4 then return false end -- editing, lagged

    local health, sstage = ent:get_attr("health"     ) or 0,
                            ent:get_attr("spawn_stage") or 0

    return health > 0 and sstage == 0
end
M.is_valid_target = is_valid_target

local Health_Action = actions.Action:clone {
    cancelable = false,

    __ctor = function(self, kwargs)
        actions.Action.__ctor(self, kwargs)
        self.health_step = kwargs.health_step
    end,

    __finish = function(self)
        self.actor:health_add(self.health_step)
    end
}

--[[!
    A plugin that turns an entity (colliding one) into a "health area". It
    hooks a collision signal to the entity that changes the collider's health
    in steps (optionally, and only if it's a valid target). Bake it with an
    obstacle.

    When any of the properties is zero, this won't do anything.

    Properties:
        - health_step - the amount of health points to add (when positive) or
          subtract (when negative) in one step.
        - health_step_millis - the amount of time one health step takes (the
          health is taken away at the end of each step). When this is negative,
          the area won't work in steps, instead it'll kill the collider when
          `health_step` is negative or restore maximum health when it's
          positive.
]]
M.health_area_plugin = {
    __properties = {
        health_step = svars.State_Integer(),
        health_step_millis = svars.State_Integer()
    },

    __init_svars = function(self)
        self:set_attr("health_step", -10)
        self:set_attr("health_step_millis", 1000)
    end,

    health_area_on_collision = function(self, collider)
        if collider != ents.get_player() then return end
        if is_valid_target(collider) then
            local step = self:get_attr("health_step")
            if    step == 0 then return end
            local step_millis = self:get_attr("health_step_millis")
            if    step_millis == 0 then return end

            if step_millis < 0 then
                local oldhealth = collider:get_attr("health")
                collider:set_attr("health", step < 0 and 0
                    or max(oldhealth, collider:get_attr("max_health")))
            else
                local prev = self.health_previous_act
                if not prev or prev.finished then
                    self.health_previous_act = collider:enqueue_action(
                        Health_Action { millis_left = step_millis,
                            health_step = step })
                end
            end
        end
    end,

    __activate = (not SERVER) and function(self)
        signal.connect(self, "collision", self.health_area_on_collision)
    end
}

return M