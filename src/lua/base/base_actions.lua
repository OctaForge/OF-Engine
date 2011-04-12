---
-- base_actions.lua, version 1<br/>
-- Action system for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
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

local base = _G
local CAPI = require("CAPI")
local math = require("math")
local table = require("table")
local string = require("string")
local class = require("cc.class")
local log = require("cc.logging")

--- Action system (actions / queue) for cC Lua interface.
-- @class module
-- @name cc.action
module("cc.action")

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

-- Default action from which every other inherits
action = class.new()
function action:__tostring() return "action" end

function action:__init(kwargs)
    kwargs = kwargs or {}

    self.begun = false
    self.finished = false
    self.starttime = CAPI.currtime()

    self.secondsleft = self.secondsleft or kwargs.secondsleft or 0
    self.anim = self.anim or kwargs.anim or nil

    self.canmulqueue = self.canmulqueue or kwargs.canmulqueue or true
    self.canbecancelled = self.canbecancelled or kwargs.canbecancelled or true
    self.parallelto = self.parallelto or kwargs.parallelto or nil
end

function action:start()
    self.begun = true
    self:dostart()
end

function action:dostart()
end

function action:execute(sec)
    if self.actor and self.actor.deactivated then
        self:finish()
        return true
    end

    if not self.begun then
        self:start()
        if self.anim then
            self.lastanim = self.actor.anim
            if self.actor.anim ~= self.anim then
                self.actor.anim = self.anim
            end
        end
    end

    if not self.parallelto then
        log.log(log.INFO, "executing action " .. base.tostring(self))

        local finished = self:doexecute(sec)
        base.assert(finished == true or finished == false)
        if finished then
            self:finish()
        end

        log.log(log.INFO, "        ...finished: " .. finished)
        return finished
    else
        if self.parallelto.finished then
            self.parallelto = nil
            self:finish()
            return true
        else
            return false
        end
    end
end

function action:doexecute(sec)
    self.secondsleft = self.secondsleft - sec
    return (self.secondsleft <= 0)
end

function action:finish()
    self.finished = true

    if self.anim and self.lastanim then
        if self.actor.anim ~= self.lastanim then
            self.actor.anim = self.lastanim
        end
    end

    self:dofinish()
end

function action:dofinish()
end

function action:cancel()
    if self.canbecancelled then
        self:finish()
    end
end

-- Never ending action
action_infinite = class.new(action)
function action_infinite:__tostring() return "action_infinite" end
function action_infinite:doexecute(sec)
    return false
end

-- Action with logent as target - such actions inherit this class and save some code
action_targeted = class.new(action)
function action_targeted:__tostring() return "action_targeted" end
function action_infinite:__init(target, kwargs)
    action.__init(self, kwargs)
    -- the target - logent
    self.target = target
end

-- Runs a single command with parameterers. Useful for queuing a command for next act() of entity.
action_singlecommand = class.new(action)
function action_singlecommand:__tostring() return "action_singlecommand" end
function action_singlecommand:__init(command, kwargs)
    action.__init(kwargs)
    self.command = command
end
function action_singlecommand:doexecute(sec)
    self.command()
    return true
end


-- Action queue for single logent and their management
action_system = class.new()

function action_system:__init(parent)
    self.parent = parent
    self.actlist = {}
end

function action_system:isempty()
    return (#self.actlist == 0)
end

function action_system:manage(sec)
    self.actlist = table.filterarray(self.actlist, function (i, v) return not v.finished end)
    if #self.actlist > 0 then
        log.log(log.INFO, "executing " .. base.tostring(self.actlist[1]))
        if self.actlist[1]:execute(sec) then -- if the action is completed, remove it immediately to not mess with it later
            table.remove(self.actlist, 1)
        end
    end
    -- TODO: move remaining seconds to next action. it's unlikely to do problems as currently, but eventually FIXME
    -- do not forget to do a clear between every action
end

function action_system:clear()
    -- note: they don't get removed here - just cancelled - finished actions get removed in manage function.
    for i = 1, #self.actlist do
        self.actlist[i]:cancel()
    end
end

function action_system:queue(act)
    if not action.canmulqueue then
        for i = 1, #self.actlist do
            if base.tostring(self.actlist[i]) == base.tostring(act) then
                log.log(log.WARNING, string.format("Trying to multiply queue %s, but that isn't allowed\n", base.tostring(act)))
                return nil
            end
        end
    end

    table.insert(self.actlist, act)
    act.actor = self.parent
end

