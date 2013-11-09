--[[! File: lua/extra/health.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        A reusable health system that integrates with the game manager and
        other modules (the game manager is required).
]]

local M = {}

local actions = require("core.events.actions")
local signal = require("core.events.signal")
local model = require("core.engine.model")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

local eactions = require("extra.events.actions")

local connect, emit = signal.connect, signal.emit
local min, max = math.min, math.max

--[[! Variable: anims
    This module adds two new animations, "dying" and "pain", on the client.
]]
local anims = (not SERVER) and {:
    dying = model.register_anim "dying",
    pain  = model.register_anim "pain"
:} or nil
M.anims = anims

--[[! Struct: Action_Pain
    Derives from <actions.Action_Local_Animation> and is queued as a pain
    effect. The default duration is 600 milliseconds and it uses the
    previously defined PAIN animation. It also cannot be used more than
    once at a time. It only exists on the client.
]]
M.Action_Pain = (not SERVER) and eactions.Action_Local_Animation:clone {
    name            = "Action_Pain",
    millis_left     = 600,
    local_animation = anims.pain,
    allow_multiple  = false
} or nil

--[[! Struct: Action_Death
    Derives from a regular Action. Represents player death and the default
    duration is 5 seconds. Like pain, it cannot be used more than once at
     a time and it's not cancelable. It only exists on the server.
]]
local Action_Death = SERVER and actions.Action:clone {
    name            = "Action_Death",
    allow_multiple  = false,
    cancelable      = false,
    millis_left     = 5000,

    --[[! Function: __start
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

    --[[! Function: __finish
        Triggers a respawn.
    ]]
    __finish = function(self)
        self.actor:game_manager_respawn()
    end
} or nil
M.Action_Death = Action_Death

--[[! Struct: player_plugin
    The player plugin - use it when baking your player entity class. Must be
    used after the game manager player plugin has been baked in (it overrides
    some of its stuff). Introduces properties "health" and "max_health", both
    default to 100.
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

    --[[! Function: game_manager_spawn_stage_4
        Overrides the serverside spawn stage 4. In addition to the default
        behavior it restores the player's health.
    ]]
    game_manager_spawn_stage_4 = (SERVER) and function(self, auid)
        self:set_attr("health", self:get_attr("max_health"))
        self:set_attr("can_move", true)
        self:set_attr("spawn_stage", 0)
        self:cancel_sdata_update()
    end or nil,

    --[[! Function: decide_animation
        Overriden so that the "dying" animation can be used when health is 0.
    ]]
    decide_animation = (not SERVER) and function(self, ...)
        if self:get_attr("health") > 0 then
            return self.__parent_class.decide_animation(self, ...)
        else
            return { anims.dying, 0 }, model.anim_flags.RAGDOLL
        end
    end or nil,

    health_on_health = function(self, health, server_orig)
        local oh = self.old_health
        self.old_health = health
        if not oh then return end
        self:health_changed(health, health - oh, server_orig)
    end,

    --[[! Function: health_changed
        There are two variants of this one, for the client and for the server.
        The server handles death, so the serverside version queues the death
        action if health is <= 0. The clientside variant handles pain, so
        it queues the pain action if health is > 0 and the diff is lower
        than -5. The function always takes the current health, the difference
        from the old state and a boolean that is true if the change originated
        on the server as arguments.
    ]]
    health_changed = SERVER and function(self, health, diff, server_orig)
        if health <= 0 then self:queue_action(Action_Death()) end
    end or function(self, health, diff, server_orig)
        if diff <= -5 and health > 0 then
            self:queue_action(Action_Pain())
        end
    end,

    --[[! Function: health_add
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

--[[! Function: is_valid_target
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

--[[! Struct: deadly_area_plugin
    A plugin that turns an entity (colliding one) into a deadly area. It
    hooks a collision signal to the entity that kills the collider (if
    it's a valid target). Bake it with an obstacle to create a deadly
    area.
]]
M.deadly_area_plugin = {
    deadly_area_on_collision = function(self, collider)
        if collider != ents.get_player() then return end
        if is_valid_target(collider) then
            collider:set_attr("health", 0)
        end
    end,

    __activate = (not SERVER) and function(self)
        signal.connect(self, "collision", self.deadly_area_on_collision)
    end
}

return M