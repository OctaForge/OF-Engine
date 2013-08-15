--[[! File: lua/core/lua/math.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

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

--[[! Function: is_nan
    Returns true if the given value is nan, false otherwise.
]]
M.is_nan = function(n)
    return (n != n)
end

--[[! Function: is_inf
    Returns true if the given value is infinite, false otherwise.
]]
M.is_inf = function(n)
    return (n == 1/0)
end

local ffi = require("ffi")

ffi.cdef [[
    typedef struct vec3_t { float x, y, z;    } vec3_t;
    typedef struct vec4_t { float x, y, z, w; } vec4_t;
    void *memcpy(void *dest, const void *src, size_t n);
]]

local new, sizeof, istype, C = ffi.new, ffi.sizeof, ffi.istype, ffi.C
local type = type
local format = string.format

--[[! Struct: Vec3
    A standard 3 component vector with x, y, z components. A function
    "new_vec3" is externally available. Internally it's a FFI struct.

    (start code)
        a = Vec3(5, 10, 15)
        echo(a.x)
    (end)
]]
Vec3 = nil
local vec3_mt = {
    --[[! Constructor: __new
        You can construct a vec3 either by passing another vec3, a table
        convertible to vec3 (an array of 3 elements or an associative array
        with x, y, z) or the components directly.
    ]]
    __new = function(ct, x, y, z)
        if istype(ct, x) then
            local ret = new(ct)
            C.memcpy(ret, x, sizeof(ct))
            return ret
        elseif type(x) == "table" then
            if x.x then
                return new(ct, x.x or 0, x.y or 0, x.z or 0)
            else
                return new(ct, x[1] or 0, x[2] or 0, x[3] or 0)
            end
        else
            return new(ct, x or 0, y or 0, z or 0)
        end
    end,

    --[[! Function: __tostring
        Returns a string in format "Vec3 <x, y, z>".
    ]]
    __tostring = function(self)
        return format("Vec3 <%f, %f, %f>", self.x, self.y, self.z)
    end,

    __index = {
        --[[! Function: length
            Returns the vector length, equals "#vec".
        ]]
        length = function(self)
            return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
        end,

        --[[! Function: normalize
            Normalizes the vector. It must not be zero length.
        ]]
        normalize = function(self)
            local len  = self:length()
            if    len != 0 then
                self:mul(1 / len)
            else
                log.log(log.ERROR, "Can't normalize a vector of zero length.")
            end
            return self
        end,

        --[[! Function: cap
            Caps the vector length.
        ]]
        cap = function(self, max_len)
            local len = self:length()
            if len > max_len then
                self:mul(max_len / len)
            end
            return self
        end,

        --[[! Function: sub_new
            Returns a new vector that equals "this - other".
        ]]
        sub_new = function(self, v)
            return Vec3(self.x - v.x,
                        self.y - v.y,
                        self.z - v.z)
        end,

        --[[! Function: add_new
            Returns a new vector that equals "this + other".
        ]]
        add_new = function(self, v)
            return Vec3(self.x + v.x,
                        self.y + v.y,
                        self.z + v.z)
        end,

        --[[! Function: mul_new
            Returns a new vector that equals "this * other".
        ]]
        mul_new = function(self, v)
            return Vec3(self.x * v,
                        self.y * v,
                        self.z * v)
        end,

        --[[! Function: sub
            Subtracts a given vector from this one.
        ]]
        sub = function(self, v)
            self.x = self.x - v.x
            self.y = self.y - v.y
            self.z = self.z - v.z
            return self
        end,

        --[[! Function: add
            Adds a given vector to this one.
        ]]
        add = function(self, v)
            self.x = self.x + v.x
            self.y = self.y + v.y
            self.z = self.z + v.z
            return self
        end,

        --[[! Function: mul
            Multiplies this with a given vector.
        ]]
        mul = function(self, v)
            self.x = self.x * v
            self.y = self.y * v
            self.z = self.z * v
            return self
        end,

        --[[! Function: copy
            Returns a copy of this vector.
        ]]
        copy = function(self)
            return Vec3(self)
        end,

        --[[! Function: to_array
            Returns an array of components of this vector.
        ]]
        to_array = function(self)
            return { self.x, self.y, self.z }
        end,

        --[[! Function: from_yaw_pitch
            Initializes the vector using given yaw and pitch.
        ]]
        from_yaw_pitch = function(self, yaw, pitch)
            self.x = -(sin(rad(yaw)))
            self.y =  (cos(rad(yaw)))

            if pitch != 0 then
                self.x = self.x * cos(rad(pitch))
                self.y = self.y * cos(rad(pitch))
                self.z = sin(rad(pitch))
            else
                self.z = 0
            end

            return self
        end,

        --[[! Function: to_yaw_pitch
            Calculates yaw and pitch from the vector's components.
        ]]
        to_yaw_pitch = function(self)
            local mag = self:length()
            if mag < 0.001 then
                return { yaw = 0, pitch = 0 }
            end
            return {
                yaw = deg(-(atan2(self.x, self.y))),
                pitch = deg(asin(self.z / mag))
            }
        end,

        --[[! Function: is_close_to
            Optimized way to check if two positions are close. Faster than
            "a:sub(b):length() <= dist". Avoids the sqrt and may save some
            of the multiplications.
        ]]
        is_close_to = function(self, v, dist)
            dist = dist * dist
            local temp, sum

            -- note order: we expect z to be less
            -- important, as most maps are 'flat'
            temp = self.x - v.x
            sum = temp * temp
            if sum > dist then return false end

            temp = self.y - v.y
            sum = sum + temp * temp
            if sum > dist then return false end

            temp = self.z - v.z
            sum = sum + temp * temp
            return (sum <= dist)
        end,

        --[[! Function: dot_product
            Calculates a dot product of this and some other vector.
        ]]
        dot_product = function(self, v)
            return self.x * v.x + self.y * v.y + self.z * v.z
        end,

        --[[! Function: cross_product
            Calculates a cross product of this and some other vector.
        ]]
        cross_product = function(self, v)
            return Vec3((self.y * v.z) - (self.z * v.y),
                        (self.z * v.x) - (self.x * v.z),
                        (self.x * v.y) - (self.y * v.x))
        end,

        --[[! Function: project_along_surface
            Projects the vector along a surface defined by a normal.
            Returns this, the modified vector.
        ]]
        project_along_surface = function(self, surf)
            return self:sub(surf:mul_new(self:dot_product(surf)))
        end,

        --[[! Function: lerp
            Performs a linear interpolation between the two
            vectors, given a weight. Returns the new vector.
            Does not modify the original.
        ]]
        lerp = function(self, other, weight)
            return self:add_new(other:sub_new(self):mul(weight))
        end,

        --[[! Function: is_zero
            Returns true if each component is 0, false otherwise.
        ]]
        is_zero = function(self)
            return (self.x == 0 and self.y == 0 and self.z == 0)
        end
    }
}
vec3_mt.__add = vec3_mt.__index.add_new
vec3_mt.__sub = vec3_mt.__index.sub_new
vec3_mt.__mul = vec3_mt.__index.mul_new
vec3_mt.__len = vec3_mt.__index.length
Vec3 = ffi.metatype("vec3_t", vec3_mt)
M.Vec3 = Vec3
M.__Vec3_mt = vec3_mt

return M
