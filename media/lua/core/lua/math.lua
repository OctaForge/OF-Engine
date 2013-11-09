--[[! File: lua/core/lua/math.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        Lua math extensions.
]]

local capi = require("capi")
local log = require("core.logger")

local type = type
local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local pow, sqrt = math.pow, math.sqrt
local atan2, asin = math.atan2, math.asin
local sin, cos, rad, deg = math.sin, math.cos, math.rad, math.deg

local Vec3

local M = {}

--[[! Function: round
    Rounds a given number and returns it. The second argument can be used to
    specify the number of places past the floating point, defaulting to 0
    (rounding to integers).
]]
M.round = function(v, d)
    local m = 10 ^ (d or 0)
    return floor(v * m + 0.5) / m
end

--[[! Function: clamp
    Clamps a number value given by the first argument between third and
    second argument. Globally available.
]]
M.clamp = function(val, low, high)
    return max(low, min(val, high))
end

--[[! Function: lerp
    Performs a linear interpolation between the two
    numerical values, given a weight.
]]
M.lerp = function(first, other, weight)
    return first + weight * (other - first)
end

--[[! Function: magnet
    If the distance between the two numerical values is in given radius,
    the second value is returned, otherwise the first is returned.
]]
M.magnet = function(value, other, radius)
    return (abs(value - other) <= radius) and other or value
end

--[[! Function: distance
    Returns a distance between two <Vec3>.
]]
local distance = function(a, b)
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2) + pow(a.z - b.z, 2))
end
M.distance = distance

--[[! Function: normalize_angle
    Normalizes an angle to be within +-180 degrees of some value.
    Useful to know if we need to turn left or right in order to be
    closer to something (we just need to check the sign, after normalizing
    relative to that angle).

    For example, for angle 100 and rel_to 300, this function returns 460
    (as 460 is within 180 degrees of 300, but 100 isn't).
]]
local normalize_angle = function(angle, rel_to)
    while angle < (rel_to - 180.0) do angle = angle + 360.0 end
    while angle > (rel_to + 180.0) do angle = angle - 360.0 end
    return angle
end
M.normalize_angle = normalize_angle

--[[! Function: floor_distance
    By default returns the distance to the floor below some given
    position, with maximal distance equal to max_dist. If radius
    is given, it finds the distance to the highest floor in given
    radius. If the fourth optional argument is true, it finds the
    lowest floor instead of highest floor.
]]
M.floor_distance = function(pos, max_dist, radius, lowest)
    local rt = capi.ray_floor(pos.x, pos.y, pos.z, max_dist)
    if not radius then return rt end

    local tbl = { -radius / 2, 0, radius / 2 }

    local f = min
    if lowest then f = max end

    for x = 1, #tbl do
        for y = 1, #tbl do
            local o = pos:add_new(Vec3(tbl[x], tbl[y], 0))
            rt = f(rt, capi.ray_floor(o.x, o.y, o.z, max_dist))
        end
    end

    return rt
end

--[[! Function: is_los
    Returns true is the line between two given positions is clear
    (if there are no obstructions). Returns false otherwise.
]]
M.is_los = function(o, d)
    return capi.ray_los(o.x, o.y, o.z, d.x, d.y, d.z)
end

--[[! Function: yaw_to
    Calculates the yaw from an origin to a target. Done on 2D data only.
    If the last "reverse" argument is given as true, it calculates away
    from the target. Returns the yaw.
]]
local function yaw_to(origin, target, reverse)
    return reverse and yaw_to(target, origin)
        or deg(-(atan2(target.x - origin.x, target.y - origin.y)))
end
M.yaw_to = yaw_to

--[[! Function: pitch_to
    Calculates the pitch from an origin to a target. Done on 2D data only.
    If the last "reverse" argument is given as true, it calculates away
    from the target. Returns the pitch.
]]
local function pitch_to(origin, target, reverse)
    return reverse and pitch_to(target, origin)
        or deg(asin((target.z - origin.z) / distance(origin, target)))
end
M.pitch_to = pitch_to

--[[! Function: compare_yaw
    Checks if the yaw between two points is within acceptable error range.
    Useful to see whether a character is facing closely enough to the target,
    for example. Returns true if it is within the range, false otherwise.
]]
M.compare_yaw = function(origin, target, yaw, acceptable)
    return abs(normalize_angle(yaw_to(origin, target), yaw) - yaw)
        <= acceptable
end

--[[! Function: compare_pitch
    Checks if the pitch between two points is within acceptable error range.
    Useful to see whether a character is facing closely enough to the target,
    for example. Returns true if it is within the range, false otherwise.
]]
M.compare_pitch = function(origin, target, pitch, acceptable)
    return abs(normalize_angle(pitch_to(origin, target), pitch) - pitch)
        <= acceptable
end

return M
