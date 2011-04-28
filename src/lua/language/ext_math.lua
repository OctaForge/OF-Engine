---
-- ext_math.lua, version 1<br/>
-- Extensions for math module of Lua<br/>
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

--- Left bitshift surrogate.
-- @param v Left side of the shift.
-- @param n Right side of the shift.
-- @return The shifted value.
-- @class function
-- @name math.lsh
math.lsh = CAPI.lsh

--- Right bitshift surrogate.
-- @param v Left side of the shift.
-- @param n Right side of the shift.
-- @return The shifted value.
-- @class function
-- @name math.rsh
math.rsh = CAPI.rsh

--- Bitwise OR surrogate.
-- @param ... A variable number of arguments to perform bitwise OR on.
-- @return The result of bitwise OR between arguments.
-- @class function
-- @name math.bor
math.bor = CAPI.bor

--- Bitwise AND surrogate.
-- @param ... A variable number of arguments to perform bitwise AND on.
-- @return The result of bitwise AND between arguments.
-- @class function
-- @name math.band
math.band = CAPI.band

--- Bitwise NOT surrogate.
-- @param v A number value to make bitwise NOT for.
-- @return The result of bitwise NOT with argument.
-- @class function
-- @name math.bnot
math.bnot = CAPI.bnot

--- Round a floating point number to integral number.
-- @param v The floating point number to round.
-- @return A rounded integral value.
function math.round(v)
    return (type(v) == "number"
        and math.floor(v + 0.5)
        or nil
    )
end

--- Clamp a numerical value.
-- @param v The value to clamp.
-- @param l Lowest value result can have.
-- @param h Highest value result can have.
-- @return Clamped value.
function math.clamp(v, l, h)
    return math.max(l, math.min(v, h))
end

--- Calculate sign of a number.
-- @param v The number to calculate sign for.
-- @return 1 if number is bigger than 0, -1 if smaller and 0 if equals 0.
function math.sign(v)
    return (v < 0 and -1 or (v > 0 and 1 or 0))
end

--- Vector3 class (having x, y, z).
-- @class table
-- @name vec3
math.vec3 = class.new()

--- Return string representation of a vector.
-- @return String representation of a vector.
function math.vec3:__tostring()
    return string.format("vec3 <%s, %s, %s>",
                         tostring(self.x),
                         tostring(self.y),
                         tostring(self.z))
end

--- vec3 constructor.
-- @param x X value of vector.
-- @param y Y value of vector.
-- @param z Z value of vector.
function math.vec3:__init(x, y, z)
    if type(x) == "table" and x.is_a and x:is_a(vec3) then
        self.x = tonumber(x.x)
        self.y = tonumber(x.y)
        self.z = tonumber(x.z)
    elseif type(x) == "table" and #x == 3 then
        self.x = tonumber(x[1])
        self.y = tonumber(x[2])
        self.z = tonumber(x[3])
    else
        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
    end
    self.length = 3
end

--- Magnitude (length) of vec3.
-- @return Square root of sum of powers of two of x, y and z.
function math.vec3:magnitude()
    return math.sqrt(self.x * self.x
                   + self.y * self.y
                   + self.z * self.z)
end

--- Normalize the vector (divide each component with length)
-- @return Itself.
function math.vec3:normalize()
    local mag = self:magnitude()
    if mag ~= 0 then self:mul(1 / mag)
    else logging.log(logging.ERROR, "Can't normalize vec of null length.") end
    return self
end

--- Cap the vector (Multiply every component
-- with division of entered size and length)
-- @param s Size to cap the vector with.
-- @return Itself.
function math.vec3:cap(s)
    local mag = self:magnitude()
    if mag > s then self:mul(size / mag) end
    return self
end

--- Subtract a vector with other vector and return as new vector.
-- @param v Vector to subtract with.
-- @return New vector.
-- @see math.vec3:sub
function math.vec3:subnew(v)
    return math.vec3(self.x - v.x,
                     self.y - v.y,
                     self.z - v.z)
end

--- Sum a vector with other vector and return as new vector.
-- @param v Vector to sum with.
-- @return New vector.
-- @see math.vec3:add
function math.vec3:addnew(v)
    return math.vec3(self.x + v.x,
                     self.y + v.y,
                     self.z + v.z)
end

--- Multiply a vector with a number and return as new vector.
-- @param v Number to subtract with.
-- @return New vector.
-- @see math.vec3:mul
function math.vec3:mulnew(v)
    return math.vec3(self.x * v,
                     self.y * v,
                     self.z * v)
end

--- Subtract current vector with other vector.
-- @param v Vector to subtract with.
-- @return Itself.
-- @see math.vec3:subnew
function math.vec3:sub(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
    return self
end

--- Sum current vector with other vector.
-- @param v Vector to sum with.
-- @return Itself.
-- @see math.vec3:addnew
function math.vec3:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
    return self
end

--- Multiply current vector with a number.
-- @param v Number to multiply with.
-- @return Itself.
-- @see math.vec3:mulnew
function math.vec3:mul(v)
    self.x = self.x * v
    self.y = self.y * v
    self.z = self.z * v
    return self
end

--- Create a new vector as copy of current one.
-- @return New vector as a copy of current one.
function math.vec3:copy()
    return math.vec3(self.x, self.y, self.z)
end

--- Get array of vector components.
-- @return Array of vector components.
function math.vec3:as_array()
    return { self.x, self.y, self.z }
end

--- Set vector values from known yaw and pitch.
-- @param yaw Yaw to use.
-- @param pitch Pitch to use.
-- @return Itself.
function math.vec3:fromyawpitch(yaw, pitch)
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
function math.vec3:toyawpitch()
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
function math.vec3:iscloseto(v, d)
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
function math.vec3:dotproduct(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

--- Vector4 class (having x, y, z, w).
-- @class table
-- @name vec4
math.vec4 = class.new(math.vec3)

--- Return string representation of a vector.
-- @return String representation of a vector.
function math.vec4:__tostring()
    return string.format("vec4 <%s, %s, %s, %s>",
                         tostring(self.x),
                         tostring(self.y),
                         tostring(self.z),
                         tostring(self.w))
end

--- vec4 constructor.
-- @param x X value of vector.
-- @param y Y value of vector.
-- @param z Z value of vector.
-- @param w W value of vector.
-- @return A vector of those values.
function math.vec4:__init(x, y, z, w)
    if type(x) == "table" and x.is_a and x:is_a(vec4) then
        self.x = tonumber(x.x)
        self.y = tonumber(x.y)
        self.z = tonumber(x.z)
        self.w = tonumber(x.w)
    elseif type(x) == "table" and #x == 4 then
        self.x = tonumber(x[1])
        self.y = tonumber(x[2])
        self.z = tonumber(x[3])
        self.z = tonumber(x[4])
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
function math.vec4:magnitude()
    return math.sqrt(self.x * self.x
                   + self.y * self.y
                   + self.z * self.z
                   + self.w * self.w)
end

--- Subtract a vector with other vector and return as new vector.
-- @param v Vector to subtract with.
-- @return New vector.
-- @see math.vec4:sub
function math.vec4:subnew(v)
    return math.vec4(self.x - v.x,
                     self.y - v.y,
                     self.z - v.z,
                     self.w - v.w)
end

--- Sum a vector with other vector and return as new vector.
-- @param v Vector to sum with.
-- @return New vector.
-- @see math.vec4:add
function math.vec4:addnew(v)
    return math.vec4(self.x + v.x,
                     self.y + v.y,
                     self.z + v.z,
                     self.w + v.w)
end

--- Multiply a vector with a number and return as new vector.
-- @param v Number to subtract with.
-- @return New vector.
-- @see math.vec4:mul
function math.vec4:mulnew(v)
    return math.vec4(self.x * v,
                     self.y * v,
                     self.z * v,
                     self.w * v)
end

--- Subtract current vector with other vector.
-- @param v Vector to subtract with.
-- @return Itself.
-- @see math.vec4:subnew
function math.vec4:sub(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
    self.w = self.w - v.w
    return self
end

--- Sum current vector with other vector.
-- @param v Vector to sum with.
-- @return Itself.
-- @see math.vec4:addnew
function math.vec4:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
    self.w = self.w + v.w
    return self
end

--- Multiply current vector with a number.
-- @param v Number to multiply with.
-- @return Itself.
-- @see math.vec4:mulnew
function math.vec4:mul(v)
    self.x = self.x * v
    self.y = self.y * v
    self.z = self.z * v
    self.w = self.w * v
    return self
end

--- Create a new vector as copy of current one.
-- @return New vector as a copy of current one.
function math.vec4:copy()
    return math.vec4(self.x, self.y, self.z, self.w)
end

--- Get array of vector components.
-- @return Array of vector components.
function math.vec4:as_array()
    return { self.x, self.y, self.z, self.w }
end

--- Set components knowing axis (which is vec3)
-- and angle (which is a number in degrees)
-- @param ax The axis (vec3)
-- @param an The angle (number in degrees)
-- @return Itself.
function math.vec4:quatfromaxiangle(ax, an)
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
function math.vec4:toyawpitchroll()
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
