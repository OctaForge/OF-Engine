--[[!<
    Lua math extensions.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local log = require("core.logger")

local floor, min, max, abs = math.floor, math.min, math.max, math.abs

--[[!
    Rounds a given number and returns it. The second argument can be used to
    specify the number of places past the floating point, defaulting to 0
    (rounding to integers).
]]
math.round = function(v, d)
    local m = 10 ^ (d or 0)
    return floor(v * m + 0.5) / m
end

--[[!
    Clamps a number value given by the first argument between third and
    second argument. Globally available.
]]
math.clamp = function(val, low, high)
    return max(low, min(val, high))
end

--[[!
    Performs a linear interpolation between the two numerical values,
    given a weight.
]]
math.lerp = function(first, other, weight)
    return first + weight * (other - first)
end

--[[!
    If the distance between the two numerical values is in given radius,
    the second value is returned, otherwise the first is returned.
]]
math.magnet = function(value, other, radius)
    return (abs(value - other) <= radius) and other or value
end
