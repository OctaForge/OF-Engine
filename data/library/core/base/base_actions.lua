--[[!
    File: library/core/base/base_actions.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features action system for Lua.
]]

--[[!
    Package: actions
    Action system (actions / queue) for OctaForge's Lua API.
    You use actions when you want to conditionally perform
    something in a queue. Example use of actions are animations.

    As actions are sort of timers, there are also utility functions
    that can cache functions according to timestamps and time delays.
]]
module("actions", package.seeall)

--! Variable: ANIM_DEAD
ANIM_DEAD = 0
--! Variable: ANIM_DYING
ANIM_DYING = 1
--! Variable: ANIM_IDLE
ANIM_IDLE = 2
--! Variable: ANIM_FORWARD
ANIM_FORWARD = 3
--! Variable: ANIM_BACKWARD
ANIM_BACKWARD = 4
--! Variable: ANIM_LEFT
ANIM_LEFT = 5
--! Variable: ANIM_RIGHT
ANIM_RIGHT = 6
--! Variable: ANIM_HOLD1
ANIM_HOLD1 = 7
--! Variable: ANIM_HOLD2
ANIM_HOLD2 = 8
--! Variable: ANIM_HOLD3
ANIM_HOLD3 = 9
--! Variable: ANIM_HOLD4
ANIM_HOLD4 = 10
--! Variable: ANIM_HOLD5
ANIM_HOLD5 = 11
--! Variable: ANIM_HOLD6
ANIM_HOLD6 = 12
--! Variable: ANIM_HOLD7
ANIM_HOLD7 = 13
--! Variable: ANIM_ATTACK1
ANIM_ATTACK1 = 14
--! Variable: ANIM_ATTACK2
ANIM_ATTACK2 = 15
--! Variable: ANIM_ATTACK3
ANIM_ATTACK3 = 16
--! Variable: ANIM_ATTACK4
ANIM_ATTACK4 = 17
--! Variable: ANIM_ATTACK5
ANIM_ATTACK5 = 18
--! Variable: ANIM_ATTACK6
ANIM_ATTACK6 = 19
--! Variable: ANIM_ATTACK7
ANIM_ATTACK7 = 20
--! Variable: ANIM_PAIN
ANIM_PAIN = 21
--! Variable: ANIM_JUMP
ANIM_JUMP = 22
--! Variable: ANIM_SINK
ANIM_SINK = 23
--! Variable: ANIM_SWIM
ANIM_SWIM = 24
--! Variable: ANIM_EDIT
ANIM_EDIT = 25
--! Variable: ANIM_LAG
ANIM_LAG = 26
--! Variable: ANIM_TAUNT
ANIM_TAUNT = 27
--! Variable: ANIM_WIN
ANIM_WIN = 28
--! Variable: ANIM_LOSE
ANIM_LOSE = 29
--! Variable: ANIM_GUN_IDLE
ANIM_GUN_IDLE = 30
--! Variable: ANIM_GUN_SHOOT
ANIM_GUN_SHOOT = 31
--! Variable: ANIM_VWEP_IDLE
ANIM_VWEP_IDLE = 32
--! Variable: ANIM_VWEP_SHOOT
ANIM_VWEP_SHOOT = 33
--! Variable: ANIM_SHIELD
ANIM_SHIELD = 34
--! Variable: ANIM_POWERUP
ANIM_POWERUP = 35
--! Variable: ANIM_MAPMODEL
ANIM_MAPMODEL = 36
--! Variable: ANIM_TRIGGER
ANIM_TRIGGER = 37
--! Variable: NUMANIMS
NUMANIMS = 38

--! Variable: ANIM_INDEX
ANIM_INDEX = 0x7F
--! Variable: ANIM_LOOP
ANIM_LOOP = math.lsh(1, 7)
--! Variable: ANIM_START
ANIM_START = math.lsh(1, 8)
--! Variable: ANIM_END
ANIM_END = math.lsh(1, 9)
--! Variable: ANIM_REVERSE
ANIM_REVERSE = math.lsh(1, 10)
--! Variable: ANIM_SECONDARY
ANIM_SECONDARY = 11

--! Variable: ANIM_RAGDOLL
ANIM_RAGDOLL = math.lsh(1, 27)

--[[!
    Function: cache_by_time_delay
    Caches a function (or rather, callable table - see <convert.tocalltable>!)
    by time delay. That allows to execute a function per-frame, But it'll take
    any real action just once upon a time. That is useful for performance
    reasons, mainly.

    Parameters:
        fun - A callable table. See <convert.tocalltable>.
        delay - delay between runs in seconds.

    Returns:
        A function that can be ran per-frame, but it'll execute the callable
        table passed from arguments just once upon time (specified by delay
        between runs).
]]
function cache_by_time_delay(fun, delay)
    fun.last_time = ((-delay) * 2)
    return function(...)
        if (GLOBAL_TIME - fun.last_time) >= delay then
            fun.last_cached_val = fun(...)
            fun.last_time       = GLOBAL_TIME
        end
        return fun.last_cached_val
    end
end

--[[!
    Function: cache_by_time_global_timestamp
    Caches a function (or rather, callable table - see <convert.tocalltable>!)
    by timestamp change. That means the function (callable table) will get
    executed just when <GLOBAL_CURRENT_TIMESTAMP> changes.

    Parameters:
        fun - A callable table. See <convert.tocalltable>.

    Returns:
        A function that takes action only when <GLOBAL_CURRENT_TIMESTAMP>
        gets changed.
]]
function cache_by_global_timestamp(fun)
    return function(...)
        if fun.last_timestamp  ~= GLOBAL_CURRENT_TIMESTAMP then
            fun.last_cached_val = fun(...)
            fun.last_timestamp  = GLOBAL_CURRENT_TIMESTAMP
        end
        return fun.last_cached_val
    end
end

--[[!
    Class: action
    Default action class which is here for other actions to
    inherit from. No other real use.
]]
action = class.new(nil, {
    --[[!
        Constructor: __init
        This initializes the action.

        Parameters:
            kwargs - additional parameters for action initializer, table.

        Kwargs:
            seconds_left - how many seconds left till action ends.
            anim - action animation - see Variables section.
            can_multiply_queue - can multiply queue? boolean value,
            defaults to true.
            cancellable - can action be cancelled? boolean, defaults to true.
            parallel_to - action it's parallel to.
    ]]
    __init = function(self, kwargs)
        -- specifies additional parameters for the action
        kwargs = kwargs or {}

        -- has it begun yet?
        self.begun      = false
        -- or has it already finished?
        self.finished   = false
        -- action start time - initialize to current time
        self.start_time = CAPI.currtime()

        self.seconds_left = (self.seconds_left)
            or kwargs.seconds_left
            or 0

        self.anim = (self.anim == nil)
            and (kwargs.anim or false)

        -- actor the action acts on
        self.actor = false

        self.can_multiply_queue = (self.can_multiply_queue == nil)
            and ((kwargs.can_multiply_queue == nil)
                and true
                or false
            )

        self.cancellable = (self.cancellable == nil)
            and ((kwargs.cancellable == nil)
                and true
                or false
            )

        self.parallel_to = (self.parallel_to == nil)
            and (kwargs.parallel_to or false)
    end,

    --[[!
        Function: __tostring
        Returns string representation of the action. It basically
        returns action's name, which is set as third argument
        to <class.new>.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[!
        Function: start
        Action start method. This is meant to be untouched by inherited
        actions.

        See Also:
            <do_start>
    ]]
    start = function(self)
        -- begin!
        self.begun = true

        -- action-defined start method call
        self:do_start()
    end,

    --[[!
        Function: do_start
        This is meant to be inherited by actions. It's called by start
        and is empty by default.

        See Also:
            <start>
    ]]
    do_start = function(self)
    end,

    --[[!
        Function: execute
        Action execution method. This is meant to be untouched by inherited
        actions. It takes care of execution, deactivation ..

        Parameters:
            seconds - How many seconds to execute.

        Returns:
            true if the action has ended, false otherwise.

        See Also:
            <do_execute>
    ]]
    execute = function(self, seconds)
        -- take care of proper finish
        if self.actor ~= false and self.actor.deactivated then
            self:finish()
            return true
        end

        -- start if not begun yet.
        if not self.begun then
            self:start()

            -- if we have actual anim..
            if self.anim ~= false then
                -- save actor animation inside the action
                self.last_anim = self.actor.anim

                -- if action has different animation than actor,
                -- give actor action's animation
                if  self.actor.anim ~= self.anim then
                    self.actor.anim  = self.anim
                end
            end
        end

        -- handle execution, and mirror finish status of parallel action
        -- if exists.
        if self.parallel_to == false then
            logging.log(logging.INFO, "executing action " .. tostring(self))

            -- check if we've already finished via retvals of do_execute
            local finished = self:do_execute(seconds)

            -- if we've finished according to do_execute, call the method
            if finished then
                self:finish()
            end

            logging.log(
                logging.INFO,
                "        ...finished: "
                    .. tostring(finished)
            )
            return finished
        else
            -- this happens if we're parallel to action -
            -- if parallel action is finished, finish as well
            -- and reset parallel_action back to false
            if self.parallel_to.finished then
                self.parallel_to = false
                self:finish()
                return true
            else
                return false
            end
        end
    end,

    --[[!
        Function: do_execute
        This is meant to be inherited by actions. It's called by execute.
        In your overriden function, always make sure to call this at the
        end and return its value like this:

        (start code)
            function myaction:do_execute(seconds)
                echo("HAH!")
                return self.__base.do_execute(self, seconds)
            end
        (end)

        or at least make sure to perform required actions in your method.
        If you're always sure of return value, you don't have to call this
        though.

        Parameters:
            seconds - How many seconds to execute. This is passed by <execute>.

        Returns:
            true if the action has ended, false otherwise.

        See Also:
            <execute>
    ]]
    do_execute = function(self, seconds)
        -- update seconds_left
        self.seconds_left = self.seconds_left - seconds

        -- return appropriate value if we finished
        return (self.seconds_left <= 0)
    end,

    --[[!
        Function: finish
        Finalizer function for action. Takes are of proper
        shutdown. Calls <do_finish> at the end which you can
        override.

        See Also:
            <do_finish>
    ]]
    finish = function(self)
        -- mark as finished
        self.finished = true

        -- reset animation on actor
        if self.anim and self.last_anim ~= nil then
            if  self.actor.anim ~= self.last_anim then
                self.actor.anim  = self.last_anim
            end
        end

        -- action-defined finish call
        self:do_finish()
    end,

    --[[!
        Function: do_finish

        Override this in custom action if required.
        Empty by default. Called by <finish>.

        See Also:
            <finish>
    ]]
    do_finish = function(self)
    end,

    --[[!
        Function: cancel

        Cancel action event. Calls <finish>, but only if the action
        can be actually cancelled (it can by default, but also doesn't
        have to be, because you can override through kwargs).

        See Also:
            <finish>
            <do_finish>
    ]]
    cancel = function(self)
        -- finish only if we're cancellable
        if self.cancellable then
            self:finish()
        end
    end
}, "action")

--[[!
    Class: action_infinite
    Infinite action accomplished by always returning false
    on do_execute.
]]
action_infinite = class.new(action, {
    --[[!
        Function: do_execute
        Overriden do_execute to accomplish never ending behavior.

        Parameters:
            seconds - Irrelevant here.

        Returns:
            always false in this case.
    ]]
    do_execute = function(self, seconds)
        return false
    end
}, "action_infinite")

--[[!
    Class: action_targeted
    Action with entity as a target. Such actions inherit this
    class and save some code.
]]
action_targeted = class.new(action, {
    --[[!
        Constructor: __init
        This initializes the action.

        Parameters:
            target - The entity to set as a target.
            kwargs - additional parameters for action initializer, table.
            See <action>'s constructor for kwargs details.

        See:
            <action>
    ]]
    __init = function(self, target, kwargs)
        action.__init(self, kwargs)

        -- the target - entity
        self.target = target
    end
}, "action_targeted")

--[[!
    Class: action_single_command
    Action that runs a single command with arguments.
    Useful for i.e. queuing a command for next act() of
    an entity.
]]
action_single_command = class.new(action, {
    --[[!
        Constructor: __init
        This initializes the action.

        Parameters:
            command - Command to execute on do_execute, it's a function.
            It can take one argument, which is the action.
            kwargs - additional parameters for action initializer, table.
            See <action>'s constructor for kwargs details.

        See:
            <action>
    ]]
    __init = function(self, command, kwargs)
        action.__init(self, kwargs)

        self.command = command
    end,

    --[[!
        Function: do_execute
        Overriden do_execute. Always returns true, because this is performed
        just *once*. It simply executes the command and dies.

        Parameters:
            seconds - Irrelevant here.

        Returns:
            always true in this case.
    ]]
    do_execute = function(self, seconds)
        self:command()
        return true
    end
}, "action_single_command")

--[[!
    Class: action_system
    Action system class which manages action queue. One action per <manage>
    gets executed.
]]
action_system = class.new(nil, {
    --[[!
        Constructor: __init
        This initializes the action system. It basically sets the parent entity
        this action system belongs to and initializes the queue, which is
        just a table.

        Parameters:
            parent - the parent entity this action system belongs to.
    ]]
    __init = function(self, parent)
        self.parent       = parent

        -- here all actions in the system will get queued
        self.action_list  = {}
    end,

    --[[!
        Function: is_empty
        Checks if action queue is empty.

        Returns:
            true if it's empty, false otherwise.
    ]]
    is_empty = function(self)
        -- we're empty if the action list is empty
        return (#self.action_list == 0)
    end,

    --[[!
        Function: manage
        Executes next queued action and removes it
        from the queue if it finishes. Also filters
        out finished actions from previous iterations
        if required.

        Parameters:
            seconds - Number of seconds to pass to the executing action.
    ]]
    manage = function(self, seconds)
        -- filter out finished actions beforehand
        self.action_list = table.filter_array(
            self.action_list,
            function (i, v)
                return not v.finished
            end
        )

        -- if we've still got something queued, proceed
        if #self.action_list > 0 then
            logging.log(
                logging.INFO,
                "executing " .. tostring(self.action_list[1])
            )

            -- if the action is completed, remove it
            -- immediately to not mess with it later
            if self.action_list[1]:execute(seconds) then
                table.remove(self.action_list, 1)
            end
        end

        -- TODO: move remaining seconds to next action.
        -- It's unlikely to do problems as currently,
        -- but eventually FIXME.
        -- Do not forget to do a clear between every action.
    end,

    --[[!
        Function: clear
        Cancels all actions in the queue.
        They then get cleared out from the queue on next <manage>.

        See Also:
            <manage>
    ]]
    clear = function(self)
        -- note: they don't get removed here - just cancelled -
        -- finished actions get removed in manage function.
        for i = 1, #self.action_list do
            self.action_list[i]:cancel()
        end
    end,

    --[[!
        Function: queue
        Adds an action to the queue. Doesn't allow two actions
        of the same type if queue multiplication is explicitly
        disabled via kwargs on constructor.

        Parameters:
            action - Action to queue.
    ]]
    queue = function(self, action)
        -- if we can't multiply queue, check if action of the same type
        -- isn't already present in the system, return if it is
        if not action.can_multiply_queue then
            for i = 1, #self.action_list do
                -- check via tostring, we don't want
                -- to assume inherited actions
                if tostring(self.action_list[i]) == tostring(action) then
                    logging.log(
                        logging.WARNING,
                        string.format(
                            "Trying to multiply queue %s, that isn't allowed.",
                            tostring(action)
                        )
                    )
                    return nil
                end
            end
        end

        -- queue it finally
        table.insert(self.action_list, action)

        -- and set its actor to system's parent
        action.actor = self.parent
    end
})
