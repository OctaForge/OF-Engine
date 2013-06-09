--[[! File: lua/core/events/actions.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Accessible as "actions". Actions are basically classes that are
        stored in an action queue (called action system). You can queue new
        actions and those will run for example for a period of time, depending
        on the action type. They're used to for example queue a player
        animation for a few seconds, or to trigger a world event at
        some specific point. They have numerous uses generally.
]]

--[[! Class: Action
    Provides the base action object other actions can inherit from.
    Takes care of the basic action infrastructure. It doesn't really
    do anything, though.
]]
local Action = table.Object:clone {
    name = "Action",

    --[[! Constructor: __init
        Constructs the action. Takes kwargs, which is an optional argument
        supplying modifiers for the action. It's an associative array.

        Actions also have the "actor" member specifying the entity they
        belong to. That is set while pushing the action to a queue.
        The respective action system automatically takes care
        of actor.

        Kwargs:
            seconds_left - Specifies how many seconds are left before the
            action ends. By default it's 0.

            animation - If specified, the action will change the actor's
            animation during its execution. One of the model.anims constants.

            allow_multiple - A boolean value specifying whether multiple
            actions of the same type can be present in one action system.
            Defaults to true. If explicitly set to false for the instance,
            it won't be possible to queue it into an action system already
            containing an action of the same type.

            cancellable - A boolean value specifying whether the action
            can be cancelled during its execution. Defaults to true.

            parallel_to - Specifies an action this one is parallel to.
            If specified, then this action will mirror the other action's
            finish status (i.e. it runs as long as the other action does,
            and it finishes as soon as the other action does). Useful for
            i.e. animations that run in parallel.
            
    ]]
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.begun      = false
        self.finished   = false
        self.start_time = _C.get_current_time()

        self.seconds_left = (self.seconds_left) or
            kwargs.seconds_left or 0

        self.animation    = (self.animation == nil) and
            kwargs.animation or false

        self.actor = false

        self.allow_multiple =
            (self.allow_multiple   == nil) and
            (kwargs.allow_multiple == nil) and true or false

        self.cancellable =
            (self.cancellable   == nil) and
            (kwargs.cancellable == nil) and true or false

        self.parallel_to =
            (self.parallel_to == nil) and kwargs.parallel_to or false
    end,

    --[[! Function: __inst_tostring
        Overloaded so that tostring(x) where x is an action instance simply
        returns the name ("Action" for the base action).
    ]]
    __inst_tostring = function(self) return self.name end,

    priv_start = function(self)
        self.begun = true
        self.start(self)
    end,

    --[[! Function: start
        By default, empty. Overload in your inherited actions as you need.
        Called when the action flow starts.
    ]]
    start = function(self)
    end,

    priv_run = function(self, seconds)
        if type(self.actor) == "table" and self.actor.deactivated then
            self.priv_finish(self)
            return true
        end

        if not self.begun then
            self.priv_start(self)

            if self.animation ~= false then
                self.last_animation = self.actor:get_attr("animation")
                if  self.actor:get_attr("animation") ~= self.animation then
                    self.actor:set_attr("animation", self.animation)
                end
            end
        end

        if self.parallel_to == false then
            #log(INFO, "Executing action " .. self.name)

            local finished = self.run(self, seconds)
            if    finished then
                self.priv_finish(self)
            end

            #log(INFO, "    finished: " .. tostring(finished))
            return finished
        else
            if  self.parallel_to.finished then
                self.parallel_to = false
                self.priv_finish(self)
                return true
            else
                return false
            end
        end
    end,

    --[[! Function: run
        Override this in inherited actions. By default does almost nothing,
        but the "almost nothing" is important, so make sure to call this
        always at the end of your custom "run", like this:

        (start code)
            Foo.run = function(self, seconds)
                echo("run")
                return self.__proto.__proto.run(self, seconds)
            end
        (end)

        Basically, the "almost nothing" it does is that it decrements
        the "seconds_left" property appropriately and returns true if
        the action has ended (that is, if "seconds_left" is lower or
        equal zero) and false otherwise.

        Of course, there are exceptions like the never ending action
        where you don't want to run this, but generally you should.

        The "seconds" argument specifies the amount of time to simulate
        this iteration in seconds.
    ]]
    run = function(self, seconds)
        self.seconds_left = self.seconds_left - seconds
        return (self.seconds_left <= 0)
    end,

    priv_finish = function(self)
        self.finished = true

        if self.animation and self.last_animation ~= nil then
            if  self.actor:get_attr("animation") ~= self.last_animation then
                self.actor:set_attr("animation", self.last_animation)
            end
        end

        self.finish(self)
    end,

    --[[! Function: finish
        By default, empty. Overload in your inherited actions as you need.
        Called when the action finishes.
    ]]
    finish = function(self)
    end,

    --[[! Function: cancel
        Forces the action finish. Effective only when the "cancellable"
        property of the action is true (it is by default).
    ]]
    cancel = function(self)
        if  self.cancellable then
            self.priv_finish(self)
        end
    end
}

--[[! Class: Infinite_Action
    An action that never ends.
]]
local Infinite_Action = Action:clone {
    name = "Infinite_Action",

    --[[! Function: run
        One of the exceptional cases of the "run" method; it always returns
        false because it doesn't manipulate "seconds_left".
    ]]
    run = function(self, seconds)
        return false
    end
}

--[[! Class: Targeted_Action
    An action with an entity as a "target" member.
]]
local Targeted_Action = Action:clone {
    name = "Targeted_Action",

    --[[! Constructor: __init
        Constructs this action. Compared to a standard action, it takes
        an additional argument, "target". That specifies an entity that
        will be later available as "target" class member.
    ]]
    __init = function(self, target, kwargs)
        Action.__init(self, kwargs)
        self.target = target
    end
}

--[[! Class: Single_Action
    An action that runs a single command and ends. Useful for i.e. queuing
    a command for next run of an entity.
]]
local Single_Action = Action:clone {
    name = "Single_Action",

    --[[! Constructor: __init
        Constructs this action. Compared to a standard action, it takes
        an additional argument, "command", which is a function taking
        this action as a first argument. It is then available as
        "command" class member.
    ]]
    __init = function(self, command, kwargs)
        Action.__init(self, kwargs)
        self.command = command
    end,

    --[[! Function: run
        Another of the exceptional cases. This runs the command initialized
        in the constructor and returns true (so that it finishes).
    ]]
    run = function(self, seconds)
        self.command(self)
        return true
    end
}

local Action_System_MT = {
    __index = {
        get = function(sys)
            return sys.actions
        end,

        run = function(sys, seconds)
            local acts = table.filter(sys.actions,
                function(i, v) return not v.finished end)
            sys.actions = acts

            if #acts > 0 then
                local act = acts[1]
                #log(INFO, table.concat { "Executing ", act.name })

                -- keep the removal for the next frame
                act:priv_run(seconds)
            end
        end,

        queue = function(sys, act)
            local acts = sys.actions
            if not act.allow_multiple then
                local str = act.name
                for i = 1, #acts do
                    if str == acts[i].name then
                        #log(WARNING, table.concat { "Action of the type ",
                        #    str, " is already present in the system, ",
                        #    "multiplication explicitly disabled for the ",
                        #    "action." })
                        return nil
                    end
                end
            end

            acts[#acts + 1] = act
            act.actor = sys.parent
        end,

        clear = function(sys)
            local acts = sys.actions
            for i = 1, #acts do
                acts[i]:cancel()
            end
        end
    }
}

local createtable = _C.table_create

local Action_System = function(parent)
    return setmetatable({
        parent  = parent,
        actions = createtable(4)
    }, Action_System_MT)
end

return {
    Action          = Action,
    Infinite_Action = Infinite_Action,
    Targeted_Action = Targeted_Action,
    Single_Action   = Single_Action,
    Action_System   = Action_System
}
