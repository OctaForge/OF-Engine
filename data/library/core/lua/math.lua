--[[! File: library/core/lua/math.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua math module extensions. Functions are inserted directly into the
        math module.
]]

local bit = require("bit")

--[[! Function: math.lsh
    Bitwise left shift of a by b (both arguments are integral). Globally
    available as "bitlsh".
]]
math.lsh = bit.lshift

--[[! Function: math.rsh
    Bitwise right shift of a by b (both arguments are integral). Globally
    available as "bitrsh".
]]
math.rsh = bit.rshift

--[[! Function: math.bor
    Bitwise OR of variable number of integral arguments. Globally available
    as "bitor".
]]
math.bor = bit.bor

--[[! Function: math.bxor
    Bitwise XOR of variable number of integral arguments. Globally available
    as "bitxor".
]]
math.bxor = bit.bxor

--[[! Function: math.band
    Bitwise AND of variable number of integral arguments. Globally available
    as "bitand".
]]
math.band = bit.band

--[[! Function: math.bnot
    Bitwise NOT of an integral argument. Globally available as "bitnot".
]]
math.bnot = bit.bnot

--[[! Function: math.round
    Rounds a given number and returns it. Globally available. The second
    argument can be used to specify the number of places past the floating
    point, defaulting to 0 (rounding to integers).
]]
math.round = function(v, d)
    local m = 10 ^ (d or 0)
    return (type(v) == "number"
        and math.floor(v * m + 0.5) / m
        or nil
    )
end

--[[! Function: math.clamp
    Clamps a number value given by the first argument between third and
    second argument. Globally available.
]]
math.clamp = function(val, low, high)
    return math.max(low, math.min(val, high))
end

--[[! Function: math.sign
    Returns a sign of a numerical value
    (-1 for < 0, 0 for 0 and 1 for > 0).
]]
math.sign = function(v)
    return (v < 0 and -1 or (v > 0 and 1 or 0))
end

--[[! Function: math.lerp
    Performs a linear interpolation between the two
    numerical values, given a weight.
]]
math.lerp = function(first, other, weight)
    return first + weight * (other - first)
end

--[[! Function: math.magnet
    If the distance between the two numerical values is in given radius,
    the second value is returned, otherwise the first is returned.
]]
math.magnet = function(value, other, radius)
    return (math.abs(value - other) <= radius) and other or value
end

--[[! Function: math.frandom
    Returns a pseudo-random floating point value in the bounds of min and max.
]]
math.frandom = function(_min, _max)
    return math.random() * (_max - _min) + _min
end

--[[! Function: math.norm_vec3
    Returns a normalized <Vec3> of random components from -1 to 1.
]]
math.norm_vec3 = function()
    local ret = nil

    while not ret or ret:length() == 0 do
        ret = math.Vec3(
            math.frandom(-1, 1),
            math.frandom(-1, 1),
            math.frandom(-1, 1)
        )
    end

    return ret:normalize()
end

--[[! Function: math.distance
    Returns a distance between two <Vec3>.
]]
math.distance = function(a, b)
    return math.sqrt(
        math.pow(a.x - b.x, 2) +
        math.pow(a.y - b.y, 2) +
        math.pow(a.z - b.z, 2)
    )
end

--[[! Function: math.normalize_angle
    Normalizes an angle to be within +-180 degrees of some value.
    Useful to know if we need to turn left or right in order to be
    closer to something (we just need to check the sign, after normalizing
    relative to that angle).

    For example, for angle 100 and rel_to 300, this function returns 460
    (as 460 is within 180 degrees of 300, but 100 isn't).
]]
math.normalize_angle = function(angle, rel_to)
    while angle < (rel_to - 180.0) do
          angle =  angle  + 360.0
    end

    while angle > (rel_to + 180.0) do
          angle =  angle  - 360.0
    end

    return angle
end

--[[! Function: math.floor_distance
    By default returns the distance to the floor below some given
    position, with maximal distance equal to max_dist. If radius
    is given, it finds the distance to the highest floor in given
    radius. If the fourth optional argument is true, it finds the
    lowest floor instead of highest floor.
]]
math.floor_distance = function(pos, max_dist, radius, lowest)
    local rt = _C.ray_floor(pos.x, pos.y, pos.z, max_dist)

    if not radius then
        return rt
    end

    local tbl = {
       -radius / 2, 0,
        radius / 2
    }

    local f = math.min
    if lowest then
        f = math.max
    end

    for x = 1, #tbl do
        for y = 1, #tbl do
            local o = pos:add_new(math.Vec3(
                tbl[x],
                tbl[y], 0
            ))
            rt = f(rt, _C.ray_floor(o.x, o.y, o.z, max_dist))
        end
    end

    return rt
end

--[[! Function: math.is_los
    Returns true is the line between two given positions is clear
    (if there are no obstructions). Returns false otherwise.
]]
math.is_los = function(o, d)
    return _C.ray_los(o.x, o.y, o.z, d.x, d.y, d.z)
end

--[[! Function: math.yaw_to
    Calculates the yaw from an origin to a target. Done on 2D data only.
    If the last "reverse" argument is given as true, it calculates away
    from the target. Returns the yaw.
]]
math.yaw_to = function(origin, target, reverse)
    return (reverse
        and math.yaw_to(target, origin)
        or  math.deg(-(math.atan2(target.x - origin.x, target.y - origin.y)))
    )
end

--[[! Function: math.pitch_to
    Calculates the pitch from an origin to a target. Done on 2D data only.
    If the last "reverse" argument is given as true, it calculates away
    from the target. Returns the pitch.
]]
math.pitch_to = function(origin, target, reverse)
    return (reverse
        and math.pitch_to(target, origin)
        or (
            360.0 * (
                math.asin(
                    (target.z - origin.z) / math.distance(origin, target)
                )
            ) / (2.0 * math.pi)
        )
    )
end

--[[! Function: math.compare_yaw
    Checks if the yaw between two points is within acceptable error range.
    Useful to see whether a character is facing closely enough to the target,
    for example. Returns true if it is within the range, false otherwise.
]]
math.compare_yaw = function(origin, target, yaw, acceptable)
    return (math.abs(
        math.normalize_angle(
            math.yaw_to(origin, target), yaw
        ) - yaw
    ) <= acceptable)
end

--[[! Function: math.compare_pitch
    Checks if the pitch between two points is within acceptable error range.
    Useful to see whether a character is facing closely enough to the target,
    for example. Returns true if it is within the range, false otherwise.
]]
math.compare_pitch = function(origin, target, pitch, acceptable)
    return (math.abs(
        math.normalize_angle(
            math.pitch_to(origin, target), pitch
        ) - pitch
    ) <= acceptable)
end

--[[! Function: math.is_nan
    Returns true if the given value is nan, false otherwise.
]]
math.is_nan = function(n)
    return (n ~= n)
end

--[[! Function: math.is_inf
    Returns true if the given value is infinite, false otherwise.
]]
math.is_inf = function(n)
    return (n == 1/0)
end

local ffi = require("ffi")

ffi.cdef [[
    typedef struct { float x, y, z;    } vec3_t;
    typedef struct { float x, y, z, w; } vec4_t;
    void *memcpy(void *dest, const void *src, size_t n);
]]

local new, sizeof = ffi.new, ffi.sizeof
local type = type
local getmt = getmetatable
local format = string.format
local sqrt, abs = math.sqrt, math.abs
local sin, cos, rad = math.sin, math.cos, math.rad
local deg, asin, atan2 = math.deg, math.asin, math.atan2

local vec3_mt
--[[! Struct: math.Vec3
    A standard 3 component vector with x, y, z components. A function
    "new_vec3" is externally available. Internally it's a FFI struct.

    (start code)
        a = math.Vec3(5, 10, 15)
        echo(a.x)
    (end)
]]
local Vec3
vec3_mt = {
    --[[! Constructor: __call
        You can construct a vec3 either by passing another vec3, a table
        convertible to vec3 (an array of 3 elements or an associative array
        with x, y, z) or the components directly.
    ]]
    __call = function(x, y, z)
        if getmt(x) == vec3_mt then
            local ret = ffi.new "vec3_t"
            C.memcpy(ret, x, sizeof "vec3_t")
            return ret
        elseif type(x) == "table" then
            if x.x then
                return ffi.new("vec3_t", x.x, x.y, x.z)
            else
                return ffi.new("vec3_t", x[1], x[2], x[3])
            end
        else
            return ffi.new("vec3_t", x, y, z)
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
            if    len ~= 0 then
                self:mul(1 / len)
            else
                log(ERROR, "Can't normalize a vector of zero length.")
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

            if pitch ~= 0 then
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
math.Vec3 = Vec3
set_external("new_vec3", function(x, y, z) return Vec3(x, y, z) end)

local vec4_mt
--[[! Struct: math.Vec4
    A standard 4 component vector with x, y, z components.
    Similar to <math.Vec3> and contains exactly the same
    methods, with additions documented here. A function
    "new_vec4" is externally available.

    (start code)
        a = math.Vec4(5, 10, 15, 20)
        echo(a.x)
    (end)
]]
local Vec4
vec4_mt = {
    __call = function(x, y, z, w)
        if getmt(x) == vec3_mt then
            local ret = ffi.new "vec4_t"
            C.memcpy(ret, x, sizeof "vec4_t")
            return ret
        elseif type(x) == "table" then
            if x.x then
                return ffi.new("vec4_t", x.x, x.y, x.z, x.w)
            else
                return ffi.new("vec4_t", x[1], x[2], x[3], x[4])
            end
        else
            return ffi.new("vec4_t", x, y, z, w)
        end
    end,

    __tostring = function(self)
        return format("Vec4 <%f, %f, %f, %f>", self.x, self.y, self.z, self.w)
    end,

    __index = {
        length = function(self)
            return sqrt(self.x * self.x + self.y * self.y
                      + self.z * self.z + self.w * self.w)
        end,

        normalize = vec3_mt.__index.normalize,
        cap = vec3_mt.__index.cap,

        sub_new = function(self, v)
            return Vec4(self.x - v.x,
                        self.y - v.y,
                        self.z - v.z,
                        self.w - v.w)
        end,

        add_new = function(self, v)
            return Vec4(self.x + v.x,
                        self.y + v.y,
                        self.z + v.z,
                        self.w + v.w)
        end,

        mul_new = function(self, v)
            return Vec4(self.x * v,
                        self.y * v,
                        self.z * v,
                        self.w * v)
        end,

        sub = function(self, v)
            self.x = self.x - v.x
            self.y = self.y - v.y
            self.z = self.z - v.z
            self.w = self.w - v.w
            return self
        end,

        add = function(self, v)
            self.x = self.x + v.x
            self.y = self.y + v.y
            self.z = self.z + v.z
            self.w = self.w + v.w
            return self
        end,

        mul = function(self, v)
            self.x = self.x * v
            self.y = self.y * v
            self.z = self.z * v
            self.w = self.w * v
            return self
        end,

        copy = function(self)
            return Vec4(self)
        end,

        to_array = function(self)
            return { self.x, self.y, self.z, self.w }
        end,

        from_yaw_pitch = function(self, yaw, pitch)
            self.x = -(sin(rad(yaw)))
            self.y =  (cos(rad(yaw)))

            if pitch ~= 0 then
                self.x = self.x * cos(rad(pitch))
                self.y = self.y * cos(rad(pitch))
                self.z = sin(rad(pitch))
            else
                self.z = 0
            end

            return self
        end,

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

        is_close_to = vec3_mt.__index.is_close_to,

        dot_product = function(self, v)
            return self.x * v.x + self.y * v.y + self.z * v.z + self.w * v.w
        end,

        cross_product = function(self, v)
            return Vec4((self.y * v.z) - (self.z * v.y),
                        (self.z * v.x) - (self.x * v.z),
                        (self.x * v.y) - (self.y * v.x), 0)
        end,

        project_along_surface = vec3_mt.__index.project_along_surface,
        lerp = vec3_mt.__index.lerp,

        --[[! Function: to_yaw_pitch_roll
            Calculates yaw, pitch and roll from the vector's components.
        ]]
        to_yaw_pitch_roll = function(self)
            if abs(self.z) < 0.99 then
                local r = self:to_yaw_pitch()
                r.roll = deg(self.w)
                return r
            else
                return {
                    yaw = deg(self.w) * (self.z < 0 and 1 or -1),
                    pitch = self.z > 0 and -90 or 90,
                    roll = 0
                }
            end
        end,

        is_zero = function(self)
            return (self.x == 0 and self.y == 0
                and self.z == 0 and self.w == 0)
        end
    }
}
vec4_mt.__add = vec4_mt.__index.add_new
vec4_mt.__sub = vec4_mt.__index.sub_new
vec4_mt.__mul = vec4_mt.__index.mul_new
vec4_mt.__len = vec4_mt.__index.length
Vec4 = ffi.metatype("vec4_t", vec4_mt)
math.Vec4 = Vec4
set_external("new_vec4", function(x, y, z, w) return Vec4(x, y, z, w) end)
