---
-- base_utils.lua, version 1<br/>
-- Various utilities for Lua CubeCreate interface<br/>
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
local class = require("cc.class")
local math = require("math")
local string = require("string")
local CAPI = require("CAPI")

--- Utilities for CubeCreate Lua inteface.
-- Contains various additional utilities (geometry, timer) for Lua cC interface.
-- @class module
-- @name cc.utils
module("cc.utils")

--- A simple timer.
-- @class table
-- @name repeatingtimer
repeatingtimer = class.new()

--- Return string representation of a timer.
-- @return String representation of a timer.
function repeatingtimer:__tostring()
    return string.format("repeatingtimer: %s %s %s",
                         tostring(self.interval),
                         tostring(self.carryover),
                         tostring(self.sum))
end

--- Constructor for simple timer.
-- @param i Interval for timer.
-- @param c Carry over the timer.
function repeatingtimer:__init(i, c)
    self.interval = i
    self.carryover = c or false
    self.sum = 0
end

--- Tick a specified amount of time. If timer has reached the interval ("fire"),
-- it returns true and resets the timer. If carryover is on, the time
-- over interval is left for next time.
-- @param s Specifies how long to tick.
-- @return true if interval reached, false otherwise.
function repeatingtimer:tick(s)
    self.sum = self.sum + s
    if self.sum >= self.interval then
        if not self.carryover then
            self.sum = 0
        else
            self.sum = self.sum - self.interval
        end
        return true
    else
        return false
    end
end

--- Sets the timer to fire next tick, no matter how many seconds are given
function repeatingtimer:prime()
    self.sum = self.interval
end

--- Calculate the distance between two vectors.
-- @param a first vector.
-- @param b second vector.
-- @return The distance between them.
function distance(a, b)
    return math.sqrt(math.pow(a.x - b.x, 2)
                   + math.pow(a.y - b.y, 2)
                   + math.pow(a.z - b.z, 2))
end

--- Normalize the angle to be within +-180 degrees of some value.
-- @param ag Angle to normalize. (i.e. 80)
-- @param rt Angle to which we'll relatively normalize. (i.e. 360)
-- @return Angle normalized relatively to rt. (in the example, 260)
function angle_normalize(ag, rt)
    while ag < (rt - 180.0) do
        ag = ag + 360.0
    end
    while ag > (rt + 180.0) do
        ag = ag - 360.0
    end
    return ag
end

--- Get the direction of angle change.
-- @param ag The angle.
-- @param rt The angle to which it's changing.
-- @return Sign of the change (1 / 0 / -1)
function angle_dirchange(ag, rt)
    ag = angle_normalize(ag, rt)
    return math.sign(ag - rt)
end

--- Calculate the yaw from origin to target on 2D data (x, y).
-- @param o Origin (position from which we start).
-- @param t Target (position towards which we calculate).
-- @param r Whether to calculate the yaw away from target (defaults to false)
-- @return The calculated yaw.
function yawto(o, t, r)
    return (r and yawto(t, o) or math.deg(-(math.atan2(t.x - o.x, t.y - o.y))))
end

--- Calculate the pitch from origin to target on 2D data (y, z).
-- @param o Origin (position from which we start).
-- @param t Target (position towards which we calculate).
-- @param r Whether to calculate the pitch away from target (defaults to false)
-- @return The calculated pitch.
function pitchto(o, t, r)
    return (r and pitchto(t, o) or (360.0 * (math.asin((t.z - o.z) / distance(o, t))) / (2.0 * math.pi)))
end

--- Check if the yaw between two points is within acceptable error range.
-- @param o Origin.
-- @param t Target.
-- @param cy Current yaw (which we ask is close to actual yaw)
-- @param ae How close the yaws must be to return true.
-- @return True or false, depends on if they're close or not.
function yawcompare(o, t, cy, ae)
    local ty = yawto(o, t)
    ty = angle_normalize(ty, cy)
    return (math.abs(ty - cy) <= ae)
end

--- Check if the pitch between two points is within acceptable error range.
-- @param o Origin.
-- @param t Target.
-- @param cy Current pitch (which we ask is close to actual pitch)
-- @param ae How close the pitches must be to return true.
-- @return True or false, depends on if they're close or not.
function pitchcompare(o, t, cp, ae)
    local tp = pitchto(o, t)
    tp = angle_normalize(tp, cp)
    return (math.abs(tp - cp) <= ae)
end

--- Check for a line of sight between two positions (i.e. if
-- the path is clear and there is no obstacle between them). (Ignores entities?)
-- @param a First position.
-- @param b Another position.
-- @return True if line of sight is clear, false otherwise.
function haslineofsight(a, b)
    return CAPI.raylos(a.x, a.y, a.z,
                       b.x, b.y, b.z)
end

--- Check for collision of ray against world geometry, ignoring entities.
-- The length of the ray implies how far ahead to look. XXX - seems we look farther
-- @param o Where the ray starts.
-- @param r We look for collisions along this ray.
-- @return The distance along the ray to the first collision.
function ray_collisiondist(o, r)
    local rm = ray:magnitude()
    return CAPI.raypos(o.x, o.y, o.z,
                       r.x / rm,
                       r.y / rm,
                       r.z / rm)
end

--- Finds the floor below some position.
-- @param o The position from which to start searching.
-- @param d Max distance to look before giving up.
-- @return The distance to the floor.
-- @see floor_highestdist
-- @see floor_lowestdist
function floor_dist(o, d)
    return CAPI.rayfloor(o.x, o.y, o.z, d)
end

--- Finds the distance to the highest floor, not just a point, but seach within a radius.
-- By highest floor, we mean the smallest distance from the origin to that floor.
-- @param o Where we start searching.
-- @param d Max distance to look before giving up.
-- @param r Radius around the origin where we're looking.
-- @return The distance to the floor.
function floor_highestdist(o, d, r)
    local rt = floor_dist(o, d)
    local tb = { -r / 2, 0, r / 2 }
    for x = 1, #tbl do
        for y = 1, #tbl do
            rt = math.min(rt, floor_dist(o:addnew(vec3(tb[x], tb[y], 0)), d))
        end
    end

    return rt
end

--- Finds the distance to the lowest floor, not just a point, but seach within a radius.
-- By lost floor, we mean the biggest distance from the origin to that floor.
-- @param o Where we start searching.
-- @param d Max distance to look before giving up.
-- @param r Radius around the origin where we're looking.
-- @return The distance to the floor.
function floor_lowestdist(o, d, r)
    local rt = floor_dist(o, d)
    local tb = { -r / 2, 0, r / 2 }
    for x = 1, #tbl do
        for y = 1, #tbl do
            rt = math.max(rt, floor_dist(o:addnew(vec3(tb[x], tb[y], 0)), d))
        end
    end

    return rt
end

--- Finds whether position is colliding.
-- @param p The position.
-- @param r Radius it applies for.
-- @param i Entity to ignore. (optional)
function iscolliding(p, r, i)
    return CAPI.iscolliding(p.x, p.y, p.z, r, i and i.uid or -1)
end

--- Get current time.
-- @class function
-- @name currtime
currtime = CAPI.currtime

--- Get current millis.
-- @class function
-- @name getmillis
getmillis = CAPI.getmillis

--- Tabify a string.
-- @class function
-- @name tabify
tabify = CAPI.tabify

--- Execute a CubeCreate cfg.
-- @class function
-- @name execcfg
execcfg = CAPI.execcfg

--- Write a CubeCreate cfg.
-- @class function
-- @name writecfg
writecfg = CAPI.writecfg

--- Get a CubeCreate cfg.
-- @class function
-- @name getcfg
getcfg = CAPI.getcfg

--- Read a file from disk.
-- @class function
-- @name readfile
readfile = CAPI.readfile

--- Add a zip.
-- @class function
-- @name addzip
addzip = CAPI.addzip

--- Remove a zip.
-- @class function
-- @name removezip
removezip = CAPI.removezip

--- Get target position.
-- @class function
-- @name gettargetpos
gettargetpos = CAPI.gettargetpos

--- Get target entity.
-- @class function
-- @name gettargetent
gettargetent = CAPI.gettargetent
