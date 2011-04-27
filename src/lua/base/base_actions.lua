---
-- base_actions.lua, version 1<br/>
-- Action system for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 OctaForge project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

--- Action system (actions / queue) for OF Lua interface.
-- @class module
-- @name of.action
module("of.action", package.seeall)

ANIM_DEAD = 0
ANIM_DYING = 1
ANIM_IDLE = 2
ANIM_FORWARD = 3
ANIM_BACKWARD = 4
ANIM_LEFT = 5
ANIM_RIGHT = 6
ANIM_HOLD1 = 7
ANIM_HOLD2 = 8
ANIM_HOLD3 = 9
ANIM_HOLD4 = 10
ANIM_HOLD5 = 11
ANIM_HOLD6 = 12
ANIM_HOLD7 = 13
ANIM_ATTACK1 = 14
ANIM_ATTACK2 = 15
ANIM_ATTACK3 = 16
ANIM_ATTACK4 = 17
ANIM_ATTACK5 = 18
ANIM_ATTACK6 = 19
ANIM_ATTACK7 = 20
ANIM_PAIN = 21
ANIM_JUMP = 22
ANIM_SINK = 23
ANIM_SWIM = 24
ANIM_EDIT = 25
ANIM_LAG = 26
ANIM_TAUNT = 27
ANIM_WIN = 28
ANIM_LOSE = 29
ANIM_GUN_IDLE = 30
ANIM_GUN_SHOOT = 31
ANIM_VWEP_IDLE = 32
ANIM_VWEP_SHOOT = 33
ANIM_SHIELD = 34
ANIM_POWERUP = 35
ANIM_MAPMODEL = 36
ANIM_TRIGGER = 37
NUMANIMS = 38

ANIM_INDEX = 0x7F
ANIM_LOOP = math.lsh(1, 7)
ANIM_START = math.lsh(1, 8)
ANIM_END = math.lsh(1, 9)
ANIM_REVERSE = math.lsh(1, 10)
ANIM_SECONDARY = 11

ANIM_RAGDOLL = math.lsh(1, 27)

--- Default action class, every other action inherits from this.
-- @class table
-- @name action
action = class.new()

--- Return string representation of action.
-- @return String representation of action.
function action:__tostring() return "action" end

--- action constructor.
-- Kwargs can contain secondsleft (how many seconds left till action ends, number),
-- anim (action animation, number - see beginning of this file),
-- canmulqueue (can multiply queue?, boolean), canbecancelled (can action be cancelled?, boolean)
-- and parallelto (action it's parallel to, action).
-- @param kwargs A table of additional properties.
function action:__init(kwargs)
    kwargs = kwargs or {}

    self.begun = false
    self.finished = false
    self.starttime = CAPI.currtime()

    self.secondsleft = self.secondsleft or kwargs.secondsleft or 0
    self.anim = self.anim == nil and (kwargs.anim == nil and false or kwargs.anim)
    self.actor = false

    self.canmulqueue = self.canmulqueue == nil and (kwargs.canmulqueue == nil and true or false)
    self.canbecancelled = self.canbecancelled == nil and (kwargs.canbecancelled == nil and true or false)
    self.parallelto = self.parallelto == nil and (kwargs.parallelto == nil and false or kwargs.parallelto)
end

--- start method for action.
-- Marks the action as begun and calls dostart,
-- which is meant to be overriden by inherited actions.
function action:start()
    self.begun = true
    self:dostart()
end

--- dostart method, meant to be overriden.
-- @see action:start
function action:dostart()
end

--- execute method, which takes care of execution, deactivation etc.
-- doexecute gets called here, which is meant to be overriden.
-- @param sec How many seconds to execute.
-- @return True if the action has ended, false otherwise.
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
        of.logging.log(of.logging.INFO, "executing action " .. tostring(self))

        local finished = self:doexecute(sec)
        assert(finished == true or finished == false)
        if finished then
            self:finish()
        end

        of.logging.log(of.logging.INFO, "        ...finished: " .. finished)
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

--- doexecute method, meant to be overriden.
-- Always make sure your inherited action calls base doexecute
-- at the end, though, or at least make sure it's performing
-- needed actions (modification of secondsleft and proper return).
-- @param sec How many seconds to execute, passed by execute.
-- @return True if the action has ended, false otherwise.
-- @see action:execute
function action:doexecute(sec)
    self.secondsleft = self.secondsleft - sec
    return (self.secondsleft <= 0)
end

--- finish method, taking care of proper action shutdown.
-- Calls dofinish at the end, which is meant to be overriden by
-- custom actions.
function action:finish()
    self.finished = true

    if self.anim and self.lastanim ~= nil then
        if self.actor.anim ~= self.lastanim then
            self.actor.anim = self.lastanim
        end
    end

    self:dofinish()
end

--- dofinish method, meant to be overriden.
-- @see action:finish
function action:dofinish()
end

--- Cancel actione vent. Performs finish, but only if action
-- can be cancelled.
function action:cancel()
    if self.canbecancelled then
        self:finish()
    end
end

--- Never ending action. Such behavior is accomplished by
-- always returning false on doexecute.
-- @class table
-- @name action_infinite
action_infinite = class.new(action)

--- Return string representation of action.
-- @return String representation of action.
function action_infinite:__tostring() return "action_infinite" end

--- Custom doexecute. Always returns false in order to make
-- the action never end.
-- @param sec How many seconds to execute, passed by execute.
-- @return Always false here.
function action_infinite:doexecute(sec)
    return false
end

--- Action with logent as target - such
-- actions inherit this class and save some code.
-- @class table
-- @name action_targeted
action_targeted = class.new(action)

--- Return string representation of action.
-- @return String representation of action.
function action_targeted:__tostring() return "action_targeted" end

--- Custom constructor. Executes the default constructor and additionally
-- sets a target logic entity. Accepts one more constructor argument.
-- @param target The target logic entity.
-- @param kwargs Action parameters, see kwargs at action constructor.
-- @see action:__init
function action_targeted:__init(target, kwargs)
    action.__init(self, kwargs)
    -- the target - logent
    self.target = target
end

--- Runs a single command with parameterers.
-- Useful for queuing a command for next act() of entity.
-- @class table
-- @name action_singlecommand
action_singlecommand = class.new(action)

--- Return string representation of action.
-- @return String representation of action.
function action_singlecommand:__tostring() return "action_singlecommand" end

--- Custom constructor. Executes the default constructor and additionally
-- sets a command, which is a function, and gets executed on doexecute.
-- Accepts one more constructor argument.
-- @param command Command to execute on doexecute, is a function.
-- @param kwargs Action parameters, see kwargs at action constructor.
-- @see action:__init
function action_singlecommand:__init(command, kwargs)
    action.__init(kwargs)
    self.command = command
end

--- Custom doexecute. Always returns true, because exactly one thing is done.
-- Custom command specified on constructor is ran here.
-- @param sec Value is irrelevant here, since only the command gets executed.
-- @return Always true here.
function action_singlecommand:doexecute(sec)
    self.command()
    return true
end


--- Action queue for single logent and their management.
-- @class table
-- @name action_system
action_system = class.new()

--- Action system constructor. Accepts parent logent. Initializes action queue.
-- @param parent The parent logent.
function action_system:__init(parent)
    self.parent = parent
    self.actlist = {}
end

--- Returns true if there are no more actions to do (queue is empty)
-- @return True if queue is empty, false otherwise.
function action_system:isempty()
    return (#self.actlist == 0)
end

--- Manage the action queue for a number of seconds.
-- Filters out finished actions from previous iterations and executes next action in queue for
-- a number of seconds.
-- @param sec Number of seconds to pass to executing action.
function action_system:manage(sec)
    self.actlist = table.filterarray(self.actlist, function (i, v) return not v.finished end)
    if #self.actlist > 0 then
        of.logging.log(of.logging.INFO, "executing " .. tostring(self.actlist[1]))
        if self.actlist[1]:execute(sec) then -- if the action is completed, remove it immediately to not mess with it later
            table.remove(self.actlist, 1)
        end
    end
    -- TODO: move remaining seconds to next action. it's unlikely to do problems as currently, but eventually FIXME
    -- do not forget to do a clear between every action
end

--- Cancel all actions in queue.
function action_system:clear()
    -- note: they don't get removed here - just cancelled - finished actions get removed in manage function.
    for i = 1, #self.actlist do
        self.actlist[i]:cancel()
    end
end

--- Add an action into queue. Doesn't allow two actions of same
-- type if queue multiplication is explicitly set to false.
-- @param act Action to queue.
function action_system:queue(act)
    if not action.canmulqueue then
        for i = 1, #self.actlist do
            if tostring(self.actlist[i]) == tostring(act) then
                of.logging.log(of.logging.WARNING, string.format("Trying to multiply queue %s, but that isn't allowed\n", tostring(act)))
                return nil
            end
        end
    end

    table.insert(self.actlist, act)
    act.actor = self.parent
end

