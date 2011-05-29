--[[!
    File: base/base_actions.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features action system for Lua.

    Section: Action system
]]

--[[!
    Package: actions
    Action system (actions / queue) for OctaForge's Lua API.
    You use actions when you want to conditionally perform something in a queue.
    Example use of actions are animations.
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
    Class: action
    Default action class which is here for other actions to
    inherit from. No other real use.
]]
action = class.new()

--[[!
    Constructor: __init
    This initializes the action.

    Parameters:
        kwargs - additional parameters for action initializer, table.

    Kwargs:
        secondsleft - how many seconds left till action ends.
        anim - action animation - see Variables section.
        canmulqueue - can multiply queue? boolean value.
        canbecancelled - can action be cancelled? boolean.
        parallelto - action it's parallel to.
]]
function action:__init(kwargs)
    kwargs = kwargs or {}

    self.begun = false
    self.finished = false
    self.starttime = CAPI.currtime()

    self.secondsleft = self.secondsleft or kwargs.secondsleft or 0
    self.anim = self.anim == nil and (kwargs.anim or false)
    self.actor = false

    self.canmulqueue = self.canmulqueue == nil and (kwargs.canmulqueue == nil and true or false)
    self.canbecancelled = self.canbecancelled == nil and (kwargs.canbecancelled == nil and true or false)
    self.parallelto = self.parallelto == nil and (kwargs.parallelto or false)
end

--[[!
    Function: __tostring
    Returns:
        string representation of the action.
]]
function action:__tostring() return "action" end

--[[!
    Function: start
    Action start method. This is meant to be untouched by inherited
    actions.

    See Also:
        <dostart>
]]
function action:start()
    self.begun = true
    self:dostart()
end

--[[!
    Function: dostart
    This is meant to be inherited by actions. It's called by start
    and is empty by default.

    See Also:
        <start>
]]
function action:dostart()
end

--[[!
    Function: execute
    Action execution method. This is meant to be untouched by inherited
    actions. It takes care of execution, deactivation ..

    Parameters:
        sec - How many seconds to execute.

    Returns:
        true if the action has ended, false otherwise.

    See Also:
        <doexecute>
]]
function action:execute(sec)
    -- take care of proper finish
    if self.actor ~= false and self.actor.deactivated then
        self:finish()
        return true
    end

    -- start if not begun yet.
    if not self.begun then
        self:start()
        if self.anim ~= false then
            self.lastanim = self.actor.anim
            if self.actor.anim ~= self.anim then
                self.actor.anim = self.anim
            end
        end
    end

    -- handle execution, and mirror finish status of parallel action
    -- if exists.
    if self.parallelto == false then
        logging.log(logging.INFO, "executing action " .. tostring(self))

        local finished = self:doexecute(sec)
        assert(finished == true or finished == false)
        if finished then
            self:finish()
        end

        logging.log(logging.INFO, "        ...finished: " .. tostring(finished))
        return finished
    else
        if self.parallelto.finished then
            self.parallelto = false
            self:finish()
            return true
        else
            return false
        end
    end
end

--[[!
    Function: doexecute
    This is meant to be inherited by actions. It's called by execute.
    In your overriden function, always make sure to call this at the
    end and return its value like this:

    (start code)
        function myaction:doexecute(sec)
            echo("HAH!")
            return self.__base.doexecute(self, sec)
        end
    (end)

    or at least make sure to perform required actions in your method.
    If you're always sure of return value, you don't have to call this
    though.

    Parameters:
        sec - How many seconds to execute. This is passed by <execute>.

    Returns:
        true if the action has ended, false otherwise.

    See Also:
        <execute>
]]
function action:doexecute(sec)
    self.secondsleft = self.secondsleft - sec
    return (self.secondsleft <= 0)
end

--[[!
    Function: finish
    Finalizer function for action. Takes are of proper
    shutdown. Calls <dofinish> at the end which you can
    override.

    See Also:
        <dofinish>
]]
function action:finish()
    self.finished = true

    if self.anim and self.lastanim ~= nil then
        if self.actor.anim ~= self.lastanim then
            self.actor.anim = self.lastanim
        end
    end

    self:dofinish()
end

--[[!
    Function: dofinish

    Override this in custom action if required.
    Empty by default. Called by <finish>.

    See Also:
        <finish>
]]
function action:dofinish()
end

--[[!
    Function: cancel

    Cancel action event. Calls <finish>, but only if the action
    can be actually cancelled (it can by default, but also doesn't
    have to be, because you can override through kwargs).

    See Also:
        <finish>
        <dofinish>
]]
function action:cancel()
    if self.canbecancelled then
        self:finish()
    end
end

--[[!
    Class: action_infinite
    Infinite action accomplished by always returning false
    on doexecute.
]]
action_infinite = class.new(action)

function action_infinite:__tostring() return "action_infinite" end

--[[!
    Function: doexecute
    Overriden doexecute to accomplish never ending behavior.

    Parameters:
        sec - Irrelevant here.

    Returns:
        always false in this case.
]]
function action_infinite:doexecute(sec)
    return false
end

--[[!
    Class: action_targeted
    Action with entity as a target. Such actions inherit this
    class and save some code.
]]
action_targeted = class.new(action)

function action_targeted:__tostring() return "action_targeted" end

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
function action_targeted:__init(target, kwargs)
    action.__init(self, kwargs)
    -- the target - entity
    self.target = target
end

--[[!
    Class: action_singlecommand
    Action that runs a single command with arguments.
    Useful for i.e. queuing a command for next act() of
    an entity.
]]
action_singlecommand = class.new(action)

function action_singlecommand:__tostring() return "action_singlecommand" end

--[[!
    Constructor: __init
    This initializes the action.

    Parameters:
        command - Command to execute on doexecute, it's a function.
        It takes no arguments.
        kwargs - additional parameters for action initializer, table.
        See <action>'s constructor for kwargs details.

    See:
        <action>
]]
function action_singlecommand:__init(command, kwargs)
    action.__init(kwargs)
    self.command = command
end

--[[!
    Function: doexecute
    Overriden doexecute. Always returns true, because this is performed
    just *once*. It simply executes the command and dies.

    Parameters:
        sec - Irrelevant here.

    Returns:
        always true in this case.
]]
function action_singlecommand:doexecute(sec)
    self.command()
    return true
end

--[[!
    Class: action_system
    Action system class which manages action queue. One action per <manage>
    gets executed.
]]
action_system = class.new()

--[[!
    Constructor: __init
    This initializes the action system. It basically sets the parent entity
    this action system belongs to and initializes the queue, which is
    just a table.

    Parameters:
        parent - the parent entity this action system belongs to.
]]
function action_system:__init(parent)
    self.parent = parent
    self.actlist = {}
end

--[[!
    Function: isempty
    Checks if action queue is empty.

    Returns:
        true if it's empty, false otherwise.
]]
function action_system:isempty()
    return (#self.actlist == 0)
end

--[[!
    Function: manage
    Executes next queued action and removes it from the queue if it finishes.
    Also filters out finished actions from previous iterations
    if required.

    Parameters:
        sec - Number of seconds to pass to the executing action.
]]
function action_system:manage(sec)
    self.actlist = table.filterarray(self.actlist, function (i, v) return not v.finished end)
    if #self.actlist > 0 then
        logging.log(logging.INFO, "executing " .. tostring(self.actlist[1]))
        if self.actlist[1]:execute(sec) then -- if the action is completed, remove it immediately to not mess with it later
            table.remove(self.actlist, 1)
        end
    end
    -- TODO: move remaining seconds to next action. it's unlikely to do problems as currently, but eventually FIXME
    -- do not forget to do a clear between every action
end

--[[!
    Function: clear
    Cancels all actions in the queue.
    They then get cleared out from the queue on next <manage>.

    See Also:
        <manage>
]]
function action_system:clear()
    -- note: they don't get removed here - just cancelled - finished actions get removed in manage function.
    for i = 1, #self.actlist do
        self.actlist[i]:cancel()
    end
end

--[[!
    Function: queue
    Adds an action to the queue. Doesn't allow two actions
    of the same type if queue multiplication is explicitly
    disabled via kwargs on constructor.

    Parameters:
        act - Action to queue.
]]
function action_system:queue(act)
    if not action.canmulqueue then
        for i = 1, #self.actlist do
            if tostring(self.actlist[i]) == tostring(act) then
                logging.log(logging.WARNING, string.format("Trying to multiply queue %s, but that isn't allowed\n", tostring(act)))
                return nil
            end
        end
    end

    table.insert(self.actlist, act)
    act.actor = self.parent
end

