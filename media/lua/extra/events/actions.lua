--[[! File: lua/extra/events/actions.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Various additional reusable actions.
]]

local actions = require("core.events.actions")
local table2 = require("core.lua.table")

local M = {}

local Action = actions.Action
local Action_System = actions.Action_System

local ipairs = ipairs
local filter = table2.filter

--[[! Class: Action_Parallel
    A container action that executes its actions in parallel. It's not
    cancellable. It works by parallel by having an internal action system
    for each action.
]]
M.Action_Parallel = Action:clone {
    name = "Action_Parallel",
    cancellable = false,

    --[[! Constructor: __init
        Takes an array of actions and kwargs. Those are passed unmodified
        to the <actions.Action> constructor.
    ]]
    __init = function(self, actions, kwargs)
        Action.__init(self, kwargs)
        self.action_systems = {}
        self.other_actions  = actions
    end,

    --[[! Function: start
        Iterates over the action array given in the constructor, adding
        each into the system using <add_action>.
    ]]
    start = function(self)
        for i, action in ipairs(self.other_actions) do
            self:add_action(action)
        end
    end,

    --[[! Function: run
        Runs all the action systems saved inside, filtering out those that
        are already done. Returns the same as <actions.Action> with the
        addition of another condition (the number of systems must be
        zero - the action won't finish until everything is done).
    ]]
    run = function(self, millis)
        local systems = filter(self.action_systems, function(i, actsys)
            actsys:run(millis)
            return #actsys:get() != 0
        end)
        self.action_systems = systems
        return Action.run(self, millis) and #systems == 0
    end,

    --[[! Function: finish
        Clears up the remaining action systems.
    ]]
    finish = function(self)
        for i, actsys in ipairs(self.action_systems) do
            actsys:clear()
        end
    end,

    --[[! Function: add_action
        Given an action, creates an action system and queues the given action
        inside, then appends the system into the action system table inside.
    ]]
    add_action = function(self, action)
        local actsys = Action_System(self.actor)
        actsys:queue(action)
        local systems = self.action_systems
        systems[#systems + 1] = actsys
    end
}

--[[! Class: Action_Local_Animation
    Action that starts, sets its actor's animation to its local_animation
    property (and optionally animation_flags to local_animation_flags), runs,
    ends and sets back the old animation (and flags). Not too useful alone,
    but can be used for inheriting.
]]
M.Action_Local_Animation = Action:clone {
    name = "Action_Local_Animation",

    --[[! Function: start
        Gives its actor the new animation. Uses the set_local_animation
        method of an entity.
    ]]
    start = function(self)
        local ac = self.actor
        self.old_animation = ac:get_attr("animation"):to_array()
        self.old_animflags = ac:get_attr("animation_flags")
        ac:set_local_animation(self.local_animation)
        ac:set_local_animation_flags(self.local_animation_flags or 0)
    end,

    --[[! Function: finish
        Resets the animation back.
    ]]
    finish = function(self)
        local ac = self.actor
        local anim = ac:get_attr("animation"):to_array()
        local lanim = self.local_animation
        if anim[1] == lanim[1] and anim[2] == lanim[2] then
            ac:set_local_animation(self.old_animation)
        end
        local lanimflags = self.local_animation_flags
        if lanimflags and ac:get_attr("animation_flags") == lanimflags then
            ac:set_local_animation_flags(self.old_animflags)
        end
    end
}

return M
