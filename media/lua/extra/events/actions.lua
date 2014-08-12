--[[!<
    Various additional reusable actions.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local actions = require("core.events.actions")
local input   = require("core.events.input")

--! Module: actions
local M = {}

local Action = actions.Action
local ActionQueue = actions.ActionQueue

local ipairs = ipairs
local compact = table.compact

--[[!
    A container action that can queue more actions into itself, which run on
    its actor, finishes when both this action and all subactions are done.

    See also:
        - $ParallelAction
]]
M.ContainerAction = Action:clone {
    name = "ContainerAction",

    --[[!
        Takes kwargs. Those are passed unmodified to the {{$actions.Action}}
        constructor. This action looks up the field `actions` in it and uses
        it as an action source.
    ]]
    __ctor = function(self, kwargs)
        Action.__ctor(self, kwargs)
        self.other_actions = kwargs.actions or {}
    end,

    --[[!
        Iterates over the action array given in the constructor, adding
        each into the system using {{$add_action}}.
    ]]
    __start = function(self)
        local actqueue = ActionQueue(self.actor)
        for i, action in ipairs(self.other_actions) do
            self:add_action(action)
        end
        self.action_queue = actqueue
    end,

    --[[!
        Runs all the action queue for the given `millis`, returns the same as
        {{$actions.Action}} with the addition of another condition (the number
        of actions in the system must be zero - the action won't finish until
        everything is done).
    ]]
    __run = function(self, millis)
        local actqueue = self.action_queue
        actqueue:run(millis)
        return Action.__run(self, millis) and (#actqueue.actions == 0)
    end,

    --! Clears up the action queue.
    __finish = function(self)
        self.action_queue:clear()
    end,

    --[[!
        Given an action, this queues it into the action queue inside.
    ]]
    add_action = function(self, action)
        self.action_queue:enqueue(action)
    end
}

--[[!
    A container action that executes its actions in parallel. It's not
    cancelable. It works by parallel by having an internal action queue
    for each action.

    See also:
        - $ContainerAction
]]
M.ParallelAction = Action:clone {
    name = "ParallelAction",
    cancelable = false,

    --[[!
        Takes kwargs. Those are passed unmodified to the {{$actions.Action}}
        constructor. This action looks up the field `actions` in it and uses
        it as an action source.
    ]]
    __ctor = function(self, kwargs)
        Action.__ctor(self, kwargs)
        self.action_queues = {}
        self.other_actions = kwargs.actions or {}
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

    --! Clears up the remaining action queues.
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
        local actqueue = ActionQueue(self.actor)
        actqueue:enqueue(action)
        local systems = self.action_queues
        systems[#systems + 1] = actqueue
    end
}

--[[!
    Action that starts, sets its actor's animation to its local_animation
    property, runs, ends and sets back the old animation. Not too useful
    alone, but can be used for inheriting.
]]
M.LocalAnimationAction = Action:clone {
    name = "LocalAnimationAction",

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

local event_list = {
    "yaw", "pitch", "move", "strafe", "jump", "crouch", "click", "mouse_move"
}

--[[!
    An input capture plugin. Contains the __start and __finish methods you
    need to call in order to give your action input capturing capabilities.
    See $InputCaptureAction.
]]
M.input_capture_plugin = {
    --! Replaces the events.
    __start = function(self)
        local events = self.events
        local old_events = {}
        self.old_events = old_events
        for i = 1, #event_list do
            local en = event_list[i]
            local ev = events[en]
            if ev then old_events[en] = input.set_event(en,
                function(...) ev(self, ...) end) end
        end
    end,

    --! Restores the events.
    __finish = function(self)
        for en, ev in pairs(self.old_events) do
            input.set_event(en, ev)
        end
    end
}

--[[!
    An input capture action - temporarily replaces input handlers (yaw, pitch,
    move, strafe, jump, crouch, click, mouse_move) with provided functions and
    restores them when it finishes. Uses $input_capture_plugin.
]]
M.InputCaptureAction = Action:clone {
    name = "InputCaptureAction",

    --[[!
        Kwargs are passed as-is to the original constructor and a field
        `events` is looked up, which is an associative table of events.
        If that fails, it uses `self.events`. If that alos fails, it uses
        an empty table as a fallback.
    ]]
    __ctor = function(self, kwargs)
        Action.__ctor(self, kwargs)
        self.events = kwargs.events or self.events or {}
    end,

    __start = M.input_capture_plugin.__start,
    __finish = M.input_capture_plugin.__finish,
}

return M
