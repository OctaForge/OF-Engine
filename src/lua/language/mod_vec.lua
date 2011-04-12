---
-- mod_vec.lua, version 1<br/>
-- Vector types for Lua<br/>
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
local string = require("string")
local math = require("math")
local log = require("cc.logging")
local CAPI = require("CAPI")

--- Vector types for Lua. Contains vector3 and vector4 classes.
-- @class module
-- @name cc.vector
module("cc.vector")

--- Vector3 class (having x, y, z).
-- @class table
-- @name vec3
vec3 = class.new()

--- Return string representation of a vector.
-- @return String representation of a vector.
function vec3:__tostring()
    return string.format("vec3 <%s, %s, %s>",
                         base.tostring(self.x),
                         base.tostring(self.y),
                         base.tostring(self.z))
end

--- vec3 constructor.
-- @param x X value of vector.
-- @param y Y value of vector.
-- @param z Z value of vector.
-- @return A vector of those values.
function vec3:__init(x, y, z)
    if base.type(x) == "table" and x.is_a and x:is_a(vec3) then
        self.x = base.tonumber(x.x)
        self.y = base.tonumber(x.y)
        self.z = base.tonumber(x.z)
    elseif base.type(x) == "table" and #x == 3 then
        self.x = base.tonumber(x[1])
        self.y = base.tonumber(x[2])
        self.z = base.tonumber(x[3])
    else
        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
    end
    self.length = 3
end

--- Magnitude (length) of vec3.
-- @return Square root of sum of powers of two of x, y and z.
function vec3:magnitude()
    return math.sqrt(self.x * self.x
                   + self.y * self.y
                   + self.z * self.z)
end

--- Normalize the vector (divide each component with length)
-- @return Itself.
function vec3:normalize()
    local mag = self:magnitude()
    if mag ~= 0 then self:mul(1 / mag)
    else log.log(log.ERROR, "Can't normalize vec of null length.") end
    return self
end

--- Cap the vector (Multiply every component
-- with division of entered size and length)
-- @param s Size to cap the vector with.
-- @return Itself.
function vec3:cap(s)
    local mag = self:magnitude()
    if mag > s then self:mul(size / mag) end
    return self
end

--- Subtract a vector with other vector and return as new vector.
-- @param v Vector to subtract with.
-- @return New vector.
-- @see vec3:sub
function vec3:subnew(v)
    return vec3(self.x - v.x,
                self.y - v.y,
                self.z - v.z)
end

--- Sum a vector with other vector and return as new vector.
-- @param v Vector to sum with.
-- @return New vector.
-- @see vec3:add
function vec3:addnew(v)
    return vec3(self.x + v.x,
                self.y + v.y,
                self.z + v.z)
end

--- Multiply a vector with a number and return as new vector.
-- @param v Number to subtract with.
-- @return New vector.
-- @see vec3:mul
function vec3:mulnew(v)
    return vec3(self.x * v,
                self.y * v,
                self.z * v)
end

--- Subtract current vector with other vector.
-- @param v Vector to subtract with.
-- @return Itself.
-- @see vec3:subnew
function vec3:sub(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
    return self
end

--- Sum current vector with other vector.
-- @param v Vector to sum with.
-- @return Itself.
-- @see vec3:addnew
function vec3:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
    return self
end

--- Multiply current vector with a number.
-- @param v Number to multiply with.
-- @return Itself.
-- @see vec3:mulnew
function vec3:mul(v)
    self.x = self.x * v
    self.y = self.y * v
    self.z = self.z * v
    return self
end

--- Create a new vector as copy of current one.
-- @return New vector as a copy of current one.
function vec3:copy()
    return vec3(self.x, self.y, self.z)
end

--- Get array of vector components.
-- @return Array of vector components.
function vec3:as_array()
    return { self.x, self.y, self.z }
end

--- Set vector values from known yaw and pitch.
-- @param yaw Yaw to use.
-- @param pitch Pitch to use.
-- @return Itself.
function vec3:fromyawpitch(yaw, pitch)
    self.x = -(math.sin(math.rad(yaw)))
    self.y =   math.cos(math.rad(yaw))

    if pitch ~= 0 then
        self.x = self.x * math.cos(math.rad(pitch))
        self.y = self.y * math.cos(math.rad(pitch))
        self.z = math.sin(math.rad(pitch))
    else
        self.z = 0
    end

    return self
end

--- Get table containing yaw and pitch from vector components.
-- @return Table containing yaw and pitch.
function vec3:toyawpitch()
    local mag = self:magnitude()
    if mag < 0.001 then
        return { yaw = 0, pitch = 0 }
    end
    return {
        yaw = math.deg(-(math.atan2(self.x, self.y))),
        pitch = math.deg(math.asin(self.z / mag))
    }
end

--- Calculate if vector is close to another vector, knowing distance.
-- @param v Other vector.
-- @param d The max distance to assume as close.
-- @return True if vectors are close to each other.
function vec3:iscloseto(v, d)
    d = d * d
    local temp, sum

    -- note order: we expect z to be less important, as most maps are 'flat'
    temp = self.x - v.x
    sum = temp * temp
    if sum > d then return false end

    temp = self.y - v.y
    sum = sum + temp * temp
    if sum > d then return false end

    temp = self.z - v.z
    sum = sum + temp * temp
    return (sum <= d)
end

--- Calculate dot product of two vectors.
-- @param v The other vector.
-- @return Dot product of two vectors.
function vec3:dotproduct(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

--- Vector4 class (having x, y, z, w).
-- @class table
-- @name vec4
vec4 = class.new(vec3)

--- Return string representation of a vector.
-- @return String representation of a vector.
function vec4:__tostring()
    return string.format("vec4 <%s, %s, %s, %s>",
                         base.tostring(self.x),
                         base.tostring(self.y),
                         base.tostring(self.z),
                         base.tostring(self.w))
end

--- vec4 constructor.
-- @param x X value of vector.
-- @param y Y value of vector.
-- @param z Z value of vector.
-- @param w W value of vector.
-- @return A vector of those values.
function vec4:__init(x, y, z, w)
    if base.type(x) == "table" and x.is_a and x:is_a(vec4) then
        self.x = base.tonumber(x.x)
        self.y = base.tonumber(x.y)
        self.z = base.tonumber(x.z)
        self.w = base.tonumber(x.w)
    elseif base.type(x) == "table" and #x == 4 then
        self.x = base.tonumber(x[1])
        self.y = base.tonumber(x[2])
        self.z = base.tonumber(x[3])
        self.z = base.tonumber(x[4])
    else
        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
        self.w = w or 0
    end
    self.length = 4
end

--- Magnitude (length) of vec4.
-- @return Square root of sum of powers of two of x, y, z and w.
function vec4:magnitude()
    return math.sqrt(self.x * self.x
                   + self.y * self.y
                   + self.z * self.z
                   + self.w * self.w)
end

--- Subtract a vector with other vector and return as new vector.
-- @param v Vector to subtract with.
-- @return New vector.
-- @see vec4:sub
function vec4:subnew(v)
    return vec4(self.x - v.x,
                self.y - v.y,
                self.z - v.z,
                self.w - v.w)
end

--- Sum a vector with other vector and return as new vector.
-- @param v Vector to sum with.
-- @return New vector.
-- @see vec4:add
function vec4:addnew(v)
    return vec4(self.x + v.x,
                self.y + v.y,
                self.z + v.z,
                self.w + v.w)
end

--- Multiply a vector with a number and return as new vector.
-- @param v Number to subtract with.
-- @return New vector.
-- @see vec4:mul
function vec4:mulnew(v)
    return vec4(self.x * v,
                self.y * v,
                self.z * v,
                self.w * v)
end

--- Subtract current vector with other vector.
-- @param v Vector to subtract with.
-- @return Itself.
-- @see vec4:subnew
function vec4:sub(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
    self.w = self.w - v.w
    return self
end

--- Sum current vector with other vector.
-- @param v Vector to sum with.
-- @return Itself.
-- @see vec4:addnew
function vec4:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
    self.w = self.w + v.w
    return self
end

--- Multiply current vector with a number.
-- @param v Number to multiply with.
-- @return Itself.
-- @see vec4:mulnew
function vec4:mul(v)
    self.x = self.x * v
    self.y = self.y * v
    self.z = self.z * v
    self.w = self.w * v
    return self
end

--- Create a new vector as copy of current one.
-- @return New vector as a copy of current one.
function vec4:copy()
    return vec4(self.x, self.y, self.z, self.w)
end

--- Get array of vector components.
-- @return Array of vector components.
function vec4:as_array()
    return { self.x, self.y, self.z, self.w }
end

--- Set components knowing axis (which is vec3)
-- and angle (which is a number in degrees)
-- @param ax The axis (vec3)
-- @param an The angle (number in degrees)
-- @return Itself.
function vec4:quatfromaxiangle(ax, an)
    an = math.rad(an)
    self.w = math.cos(an / 2)
    local s = math.sin(an / 2)

    self.x = s * ax.x
    self.y = s * ax.y
    self.z = s * ax.z

    return self
end

--- Get table containing yaw, pitch and roll from vector components.
-- TODO: test and fix bugs
-- @return Table containing yaw, pitch and roll.
function vec4:toyawpitchroll()
    --local r = self:toyawpitch()
    --r.roll = 0
    --return r

    if math.abs(self.z) < 0.99 then
        local r = self:toyawpitch()
        r.roll = math.deg(self.w)
        return r
    else
        return {
            yaw = math.deg(self.w) * (self.z < 0 and 1 or -1),
            pitch = self.z > 0 and -90 or 90,
            roll = 0
        }
    end
end
