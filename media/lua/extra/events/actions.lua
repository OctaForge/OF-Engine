--[[!<
    Various additional reusable actions.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local actions = require("core.events.actions")
local table2 = require("core.lua.table")

--! Module: actions
local M = {}

local Action = actions.Action
local Action_Queue = actions.Action_Queue

local ipairs = ipairs
local compact = table2.compact

--[[! Object: actions.Action_Parallel
    A container action that executes its actions in parallel. It's not
    cancelable. It works by parallel by having an internal action queue
    for each action.
]]
M.Action_Parallel = Action:clone {
    name = "Action_Parallel",
    cancelable = false,

    --[[!
        Takes an array of actions and kwargs. Those are passed unmodified
        to the {{$actions.Action}} constructor.
    ]]
    __ctor = function(self, actions, kwargs)
        Action.__ctor(self, kwargs)
        self.action_queues = {}
        self.other_actions  = actions
    end,

    --[[!
        Iterates over the action array given in the constructor, adding
        each into the system using {{$add_action}}.
    ]]
    __start = function(self)
        for i, action in ipairs(self.other_actions) do
            self:add_action(action)
        end
    end,

    --[[!
        Runs all the action queues saved inside, filtering out those that
        are already done. Returns the same as {{$actions.Action}} with the
        addition of another condition (the number of systems must be
        zero - the action won't finish until everything is done).
    ]]
    __run = function(self, millis)
        local systems = compact(self.action_queues, function(i, actqueue)
            actqueue:run(millis)
            return #actqueue.actions != 0
        end)
        return Action.__run(self, millis) and #systems == 0
    end,

    --[[!
        Clears up the remaining action queues.
    ]]
    __finish = function(self)
        for i, actqueue in ipairs(self.action_queues) do
            actqueue:clear()
        end
    end,

    --[[!
        Given an action, creates an action queue and queues the given action
        inside, then appends the system into the action queue table inside.
    ]]
    add_action = function(self, action)
        local actqueue = Action_Queue(self.actor)
        actqueue:enqueue(action)
        local systems = self.action_queues
        systems[#systems + 1] = actqueue
    end
}

--[[! Object: actions.Action_Local_Animation
    Action that starts, sets its actor's animation to its local_animation
    property, runs, ends and sets back the old animation. Not too useful
    alone, but can be used for inheriting.
]]
M.Action_Local_Animation = Action:clone {
    name = "Action_Local_Animation",

    --[[!
        Gives its actor the new animation. Uses the set_local_animation
        method of an entity.
    ]]
    __start = function(self)
        local ac = self.actor
        self.old_animation = ac:get_attr("animation")
        ac:set_local_animation(self.local_animation)
    end,

    --! Resets the animation back.
    __finish = function(self)
        local ac = self.actor
        local anim = ac:get_attr("animation")
        local lanim = self.local_animation
        if anim == lanim then ac:set_local_animation(self.old_animation) end
    end
}

return M
