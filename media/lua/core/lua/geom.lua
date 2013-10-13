--[[! File: lua/core/lua/geom.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Vector math, matrix math and geometry utilities. Roughly equivalent
        to geom.h in the core engine plus extensions.
]]

local capi = require("capi")
local ffi = require("ffi")
local log = require("core.logger")

local gen_vec2 = function(tp, sf, mt)
    ffi.cdef(([[
        typedef struct vec2%s_t {
            %s x, y;
        } vec2%s_t;
    ]]):format(sf, tp, sf))
    return ffi.metatype("vec2" .. sf .. "_t", mt), mt
end

local gen_vec3 = function(tp, sf, mt)
    ffi.cdef(([[
        typedef union vec3%s_t {
            struct { %s x, y, z; };
            struct { %s r, g, b; };
        } vec3%s_t;
    ]]):format(sf, tp, tp, sf))
    return ffi.metatype("vec3" .. sf .. "_t", mt), mt
end

local gen_vec4 = function(tp, sf, mt)
    ffi.cdef(([[
        typedef union vec4%s_t {
            struct { %s x, y, z, w; };
            struct { %s r, g, b, a; };
        } vec4%s_t;
    ]]):format(sf, tp, tp, sf))
    return ffi.metatype("vec4" .. sf .. "_t", mt), mt
end

local ffi_new = ffi.new
local type = type
local sin, cos, abs, min, max, sqrt, floor = math.sin, math.cos, math.abs,
    math.min, math.max, math.sqrt, math.floor
local clamp = function(v, l, h)
    return max(l, min(v, h))
end

local iton = { [0] = "x", [1] = "y", [2] = "z" }

local M = {}

local Vec2, Vec2_mt; Vec2, Vec2_mt = gen_vec2("float", "f", {
    __new = function(self, x, y)
        if type(x) == "number" then
            if not y then
                return ffi_new(self, x, x)
            else
                return ffi_new(self, x, y)
            end
        else
            return ffi_new(self, x.x, x.y)
        end
    end,
    __tostring = function(self)
        return ("Vec2 <%f, %f>"):format(self.x, self.y)
    end,
    __eq = function(self, o) return self.x == o.x and self.y == o.y end,
    __mul = function(self, o) return self:mul_new(o) end,
    __div = function(self, o) return self:div_new(o) end,
    __add = function(self, o) return self:add_new(o) end,
    __sub = function(self, o) return self:sub_new(o) end,
    __len = function(self) return self:magnitude() end,
    __index = {
        from_ffi_array = function(self, o)
            return ffi_new(self, o[0], o[1])
        end,
        from_array = function(self, o)
            return ffi_new(self, o[1], o[2])
        end,

        copy = function(self)
            return Vec2(self.x, self.y)
        end,
        to_array = function(self)
            return { self.x, self.y }
        end,
        unpack = function(self)
            return self.x, self.y
        end,
        get_nth = function(self, n) return self[iton[n - 1]] end,
        set_nth = function(self, n, v) self[iton[n - 1]] = v end,
        is_zero = function(self) return self.x == 0 and self.y == 0 end,
        dot = function(self, o) return self.x * o.x + self.y * o.y end,
        dot_abs = function(self, o)
            return abs(self.x * o.x) + abs(self.y * o.y)
        end,
        squared_len = function(self) return self:dot(self) end,
        magnitude = function(self) return sqrt(self:squared_len()) end,
        normalize = function(self)
            self:div(self:magnitude())
            return self
        end,
        cross = function(self, o) return self.x * o.y + self.y * o.x end,
        mul = function(self, o)
            if type(o) == "number" then
                self.x, self.y = self.x * o, self.y * o
            else
                self.x, self.y = self.x * o.x, self.y * o.y
            end
            return self
        end,
        div = function(self, o)
            if type(o) == "number" then
                self.x, self.y = self.x / o, self.y / o
            else
                self.x, self.y = self.x / o.x, self.y / o.y
            end
            return self
        end,
        add = function(self, o)
            if type(o) == "number" then
                self.x, self.y = self.x + o, self.y + o
            else
                self.x, self.y = self.x + o.x, self.y + o.y
            end
            return self
        end,
        sub = function(self, o)
            if type(o) == "number" then
                self.x, self.y = self.x - o, self.y - o
            else
                self.x, self.y = self.x - o.x, self.y - o.y
            end
            return self
        end,
        mul_new = function(self, o)
            if type(o) == "number" then
                return Vec2(self.x * o, self.y * o)
            else
                return Vec2(self.x * o.x, self.y * o.y)
            end
        end,
        div_new = function(self, o)
            if type(o) == "number" then
                return Vec2(self.x / o, self.y / o)
            else
                return Vec2(self.x / o.x, self.y / o.y)
            end
        end,
        add_new = function(self, o)
            if type(o) == "number" then
                return Vec2(self.x + o, self.y + o)
            else
                return Vec2(self.x + o.x, self.y + o.y)
            end
        end,
        sub_new = function(self, o)
            if type(o) == "number" then
                return Vec2(self.x - o, self.y - o)
            else
                return Vec2(self.x - o.x, self.y - o.y)
            end
        end,
        neg = function(self)
            self.x, self.y = -self.x, -self.y
            return self
        end,
        min = function(self, o)
            if type(o) == "number" then
                self.x, self.y = min(self.x, o), min(self.y, o)
            else
                self.x, self.y = min(self.x, o.x), min(self.y, o.y)
            end
            return self
        end,
        max = function(self, o)
            if type(o) == "number" then
                self.x, self.y = max(self.x, o), max(self.y, o)
            else
                self.x, self.y = max(self.x, o.x), max(self.y, o.y)
            end
            return self
        end,
        abs = function(self)
            self.x, self.y = abs(self.x), abs(self.y)
            return self
        end,
        clamp = function(self, l, h)
            self.x, self.y = clamp(self.x, l, h), clamp(self.y, l, h)
            return self
        end,
        dist = function(self, o)
            local dx, dy = self.x - o.x, self.y - o.y
            return sqrt(dx ^ 2 + dy ^ 2)
        end,
        lerp = function(self, a, b, t)
            if not t then a, b, t = self, a, b end
            self.x, self.y = a.x + (b.x - a.x) * t,
                             a.y * (b.y - a.y) * t
            return self
        end,
        avg = function(self, b) return self:add(b):mul(0.5) end,
        rotate_around_z = function(self, c, s)
            if type(c) == "number" then
                if not s then
                    local angle = c
                    return self:rotate_around_z(cos(angle), sin(angle))
                else
                    local rx, ry = self.x, self.y
                    self.x, self.y = c * rx - s * ry, c * ry + s * rx
                    return self
                end
            else
                return self:rotate_around_z(c.x, c.y)
            end
        end
    }
})
M.Vec2 = Vec2

local Vec3, Vec3_mt; Vec3, Vec3_mt = gen_vec3("float", "f", {
    __new = function(self, x, y, z)
        if type(x) == "number" then
            if not y and not z then
                return ffi_new(self, x, x, x)
            else
                return ffi_new(self, x, y, z)
            end
        else
            return ffi_new(self, x.x, x.y, x.z)
        end
    end,
    __tostring = function(self)
        return ("Vec3 <%f, %f, %f>"):format(self.x, self.y, self.z)
    end,
    __eq = function(self, o)
        return self.x == o.x and self.y == o.y and self.z == o.z
    end,
    __mul = function(self, o) return self:mul_new(o) end,
    __div = function(self, o) return self:div_new(o) end,
    __add = function(self, o) return self:add_new(o) end,
    __sub = function(self, o) return self:sub_new(o) end,
    __len = function(self) return self:magnitude() end,
    __index = {
        from_ffi_array = function(self, o)
            return ffi_new(self, o[0], o[1], o[2])
        end,
        from_array = function(self, o)
            return ffi_new(self, o[1], o[2], o[3])
        end,
        from_vec2 = function(self, o, z)
            return ffi_new(self, o.x, o.y, z or 0)
        end,
        from_yaw_pitch = function(self, yaw, pitch)
            return ffi_new(self,
                -sin(yaw) * cos(pitch),
                 cos(yaw) * cos(pitch),
                 sin(pitch))
        end,
        from_hex_color = function(self, color)
            return ffi_new(self, ((color >> 16) & 0xFF) / 255,
                                 ((color >>  8) & 0xFF) / 255,
                                  (color        & 0xFF) / 255)
        end,

        copy = function(self)
            return Vec3(self.x, self.y, self.z)
        end,
        to_array = function(self)
            return { self.x, self.y, self.z }
        end,
        unpack2 = function(self)
            return self.x, self.y
        end,
        unpack = function(self)
            return self.x, self.y, self.z
        end,
        get_nth = function(self, n) return self[iton[n - 1]] end,
        set_nth = function(self, n, v) self[iton[n - 1]] = v end,
        is_zero = function(self)
            return self.x == 0 and self.y == 0 and self.z == 0
        end,
        dot2 = function(self, o) return self.x * o.x + self.y * o.y end,
        dot = function(self, o)
            return self.x * o.x + self.y * o.y + self.z * o.z
        end,
        dot_abs = function(self, o)
            return abs(self.x * o.x) + abs(self.y * o.y) + abs(self.z * o.z)
        end,
        dot_z = function(self, o)
            return self.z * o.z
        end,
        squared_len = function(self) return self:dot(self) end,
        magnitude2 = function(self) return sqrt(self:dot2(self)) end,
        magnitude = function(self) return sqrt(self:squared_len()) end,
        normalize = function(self) return self:div(self:magnitude()) end,
        is_normalized = function(self)
            local m = self:squared_len()
            return m > 0.99 and m < 1.01
        end,
        mul = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x * o, self.y * o, self.z * o
            else
                self.x, self.y, self.z = self.x * o.x, self.y * o.y,
                    self.z * o.z
            end
            return self
        end,
        div = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x / o, self.y / o, self.z / o
            else
                self.x, self.y, self.z = self.x / o.x, self.y / o.y,
                    self.z / o.z
            end
            return self
        end,
        add = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x + o, self.y + o, self.z + o
            else
                self.x, self.y, self.z = self.x + o.x, self.y + o.y,
                    self.z + o.z
            end
            return self
        end,
        add_z = function(self, f)
            self.z = self.z + f
            return self
        end,
        sub = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x - o, self.y - o, self.z - o
            else
                self.x, self.y, self.z = self.x - o.x, self.y - o.y,
                    self.z - o.z
            end
            return self
        end,
        sub_z = function(self, f)
            self.z = self.z - f
            return self
        end,
        mul_new = function(self, o)
            if type(o) == "number" then
                return Vec3(self.x * o, self.y * o, self.z * o)
            else
                return Vec3(self.x * o.x, self.y * o.y, self.z * o.z)
            end
        end,
        div_new = function(self, o)
            if type(o) == "number" then
                return Vec3(self.x / o, self.y / o, self.z / o)
            else
                return Vec3(self.x / o.x, self.y / o.y, self.z / o.z)
            end
        end,
        add_new = function(self, o)
            if type(o) == "number" then
                return Vec3(self.x + o, self.y + o, self.z + o)
            else
                return Vec3(self.x + o.x, self.y + o.y, self.z + o.z)
            end
        end,
        sub_new = function(self, o)
            if type(o) == "number" then
                return Vec3(self.x - o, self.y - o, self.z - o)
            else
                return Vec3(self.x - o.x, self.y - o.y, self.z - o.z)
            end
        end,
        neg2 = function(self)
            self.x, self.y = -self.x, -self.y
            return self
        end,
        neg = function(self)
            self.x, self.y, self.z = -self.x, -self.y, -self.z
            return self
        end,
        min = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = min(self.x, o), min(self.y, o),
                    min(self.z, o)
            else
                self.x, self.y, self.z = min(self.x, o.x), min(self.y, o.y),
                    min(self.z, o.z)
            end
            return self
        end,
        max = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = max(self.x, o), max(self.y, o),
                    max(self.z, o)
            else
                self.x, self.y, self.z = max(self.x, o.x), max(self.y, o.y),
                    max(self.z, o.z)
            end
            return self
        end,
        abs = function(self)
            self.x, self.y, self.z = abs(self.x), abs(self.y), abs(self.z)
            return self
        end,
        clamp = function(self, l, h)
            self.x, self.y, self.z = clamp(self.x, l, h), clamp(self.y, l, h),
                clamp(self.z, l, h)
            return self
        end,
        squared_dist = function(self, e)
            return self:sub_new(e):squared_len()
        end,
        dist = function(self, e)
            return self:sub_new(e):magnitude()
        end,
        dist2 = function(self, o)
            local dx, dy = self.x - o.x, self.y - o.y
            return sqrt(dx ^ 2 + dy ^ 2)
        end,
        reject = function(self, o, r)
            return self.x > (o.x + r) or self.x < (o.x - r)
                or self.y > (o.y + r) or self.y < (o.y - r)
        end,
        cross = function(self, a, b, o)
            if o then
                return self:cross(a:sub_new(o), b:sub_new(o))
            end
            self.x, self.y, self.z = a.y * b.z - a.z * b.y,
                                     a.z * b.x - a.x * b.z,
                                     a.x * b.y - a.y * b.x
            return self
        end,
        scalar_triple = function(self, a, b)
            return self.x * (a.y * b.z - a.z * b.y)
                 + self.y * (a.z * b.x - a.x * b.z)
                 + self.z * (a.x * b.y - a.y * b.x)
        end,
        scalar_triple_z = function(self, a, b)
            return self.z * (a.x * b.y - a.y * b.x)
        end,
        reflect_z = function(self, rz)
            self.z = 2 * rz - self.z
            return self
        end,
        reflect = function(self, n)
            local k = 2 * self:dot(n)
            self.x, self.y, self.z = self.x - k * n.x,
                                     self.y - k * n.y,
                                     self.z - k * n.z
            return self
        end,
        project = function(self, n)
            local k = self:dot(n)
            self.x, self.y, self.z = self.x - k * n.x,
                                     self.y - k * n.y,
                                     self.z - k * n.z
            return self
        end,
        project_xy_dir = function(self, n)
            if n.z != 0 then
                self.z = -(self.x * n.x / n.z + self.y * n.y / n.z)
            end
            return self
        end,
        project_xy = function(self, n, threshold)
            local m = self:squared_len()
            local k = threshold and min(self:dot(n), threshold) or self:dot(n)
            self:project_xy_dir()
            self:rescale(sqrt(max(m - k ^ 2, 0)))
            return self
        end,
        lerp = function(self, a, b, t)
            if not t then a, b, t = self, a, b end
            self.x, self.y, self.z = a.x + (b.x - a.x) * t,
                                     a.y * (b.y - a.y) * t,
                                     a.z * (b.z - a.z) * t
            return self
        end,
        avg = function(self, b) return self:add(b):mul(0.5) end,
        rescale = function(self, k)
            local mag = self:magnitude()
            if mag > 1e-6 then self:mul(k / mag) end
            return self
        end,
        rotate_around_z = function(self, c, s)
            if type(c) == "number" then
                if not s then
                    local angle = c
                    return self:rotate_around_z(cos(angle), sin(angle))
                else
                    local rx, ry = self.x, self.y
                    self.x, self.y = c * rx - s * ry, c * ry + s * rx
                    return self
                end
            else
                return self:rotate_around_z(c.x, c.y)
            end
        end,
        rotate_around_x = function(self, c, s)
            if type(c) == "number" then
                if not s then
                    local angle = c
                    return self:rotate_around_x(cos(angle), sin(angle))
                else
                    local ry, rz = self.y, self.z
                    self.y, self.z = c * ry - s * rz, c * rz + s * ry
                    return self
                end
            else
                return self:rotate_around_x(c.x, c.y)
            end
        end,
        rotate_around_y = function(self, c, s)
            if type(c) == "number" then
                if not s then
                    local angle = c
                    return self:rotate_around_y(cos(angle), sin(angle))
                else
                    local rx, rz = self.x, self.z
                    self.x, self.z = c * rx + s * rz, c * rz - s * rx
                    return self
                end
            else
                return self:rotate_around_y(c.x, c.y)
            end
        end,
        rotate = function(self, c, s, d)
            if not d then
                if type(c) == "number" then
                    local angle, d = c, s
                    return self:rotate(cos(angle), sin(angle), d)
                else
                    local sc, d = c, s
                    return self:rotate(sc.x, sc.y, d)
                end
            else
                local x, y, z = self.x, self.y, self.z
                self.x = x*(d.x*d.x*(1-c)+c) + y*(d.x*d.y*(1-c)-d.z*s)
                    + z*(d.x*d.z*(1-c)+d.y*s)
                self.y = x*(d.y*d.x*(1-c)+d.z*s) + y*(d.y*d.y*(1-c)+c)
                    + z*(d.y*d.z*(1-c)-d.x*s)
                self.z = x*(d.x*d.z*(1-c)-d.y*s) + y*(d.y*d.z*(1-c)+d.x*s)
                    + z*(d.z*d.z*(1-c)+c)
                return self
            end
        end,
        orthogonal = function(self, d)
            local i = (abs(d.x) > abs(d.y))
                and (abs(d.x) > abs(d.z) and 0 or 2)
                 or (abs(d.y) > abs(d.z) and 1 or 2)
            self[iton[i]] = d[iton[(i + 1) % 3]]
            self[iton[(i + 1) % 3]] = -d[iton[i]]
            self[iton[(i + 2) % 3]] = 0
            return self
        end,
        orthonormalize = function(self, s, t)
            s:project(self)
            t:project(self):project(s)
        end,
        inside_bb = function(self, bbmin, bbmax)
            if type(bbmax) == "number" then
                local o, size = bbmin, bbmax
                return self.x >= o.x and self.x <= (o.x + size)
                   and self.y >= o.y and self.y <= (o.y + size)
                   and self.z >= o.z and self.z <= (o.z + size)
            end
            return self.x >= bbmin.x and self.x <= bbmax.x
               and self.y >= bbmin.y and self.y <= bbmax.y
               and self.z >= bbmin.z and self.z <= bbmax.z
        end,
        dist_to_bb = function(self, min, max)
            if type(max) == "number" then
                local o, size = min, max
                return self:dist_to_bb(o, o:add_new(size))
            end
            local sqrdist = 0
            for i = 0, 2 do
                local n = iton[i]
                if self[n] < min[n] then
                    local delta = self[n] - min[n]
                    sqrdist = sqrdist + delta ^ 2
                elseif self[n] > max[n] then
                    local delta = max[n] - self[n]
                    sqrdist = sqrdist + delta ^ 2
                end
            end
            return sqrt(sqrdist)
        end,
        project_bb = function(self, min, max)
            local x, y, z = self.x, self.y, self.z
            return x * (x < 0 and max.x or min.x)
                 + y * (y < 0 and max.y or min.y)
                 + z * (z < 0 and max.z or min.z)
        end,
        to_hex_color = function(self)
            return floor(clamp(self.r, 0, 1) * 255) << 16
                 | floor(clamp(self.g, 0, 1) * 255) <<  8
                 | floor(clamp(self.b, 0, 1) * 255)
        end
    }
})
M.Vec3 = Vec3

local Vec4, Vec4_mt; Vec4, Vec4_mt = gen_vec4("float", "f", {
    __new = function(self, x, y, z, w)
        if type(x) == "number" then
            if not y and not z and not w then
                return ffi_new(self, x, x, x, x)
            else
                return ffi_new(self, x, y, z, w)
            end
        else
            return ffi_new(self, x.x, x.y, x.z, x.w)
        end
    end,
    __tostring = function(self)
        return ("Vec3 <%f, %f, %f, %f>"):format(self.x, self.y, self.z, self.w)
    end,
    __eq = function(self, o)
        return self.x == o.x and self.y == o.y
           and self.z == o.z and self.w == o.w
    end,
    __mul = function(self, o) return self:mul_new(o) end,
    __div = function(self, o) return self:div_new(o) end,
    __add = function(self, o) return self:add_new(o) end,
    __sub = function(self, o) return self:sub_new(o) end,
    __len = function(self) return self:magnitude() end,
    __index = {
        from_ffi_array = function(self, o)
            return ffi_new(self, o[0], o[1], o[2], o[3])
        end,
        from_array = function(self, o)
            return ffi_new(self, o[1], o[2], o[3], o[4])
        end,
        from_vec3 = function(self, o, w)
            return ffi_new(self, o.x, o.y, o.z, w or 0)
        end,

        copy = function(self)
            return Vec4(self.x, self.y, self.z, self.w)
        end,
        to_array = function(self)
            return { self.x, self.y, self.z, self.w }
        end,
        unpack3 = function(self)
            return self.x, self.y, self.z
        end,
        unpack = function(self)
            return self.x, self.y, self.z, self.w
        end,
        get_nth = function(self, n) return self[iton[n - 1]] end,
        set_nth = function(self, n, v) self[iton[n - 1]] = v end,
        is_zero = function(self)
            return self.x == 0 and self.y == 0 and self.z == 0 and self.w == 0
        end,
        dot3 = function(self, o)
            return self.x * o.x + self.y * o.y + self.z * o.z
        end,
        dot = function(self, o)
            return self.x * o.x + self.y * o.y + self.z * o.z + self.w * o.w
        end,
        squared_len = function(self) return self:dot(self) end,
        magnitude3 = function(self) return sqrt(self:dot3(self)) end,
        magnitude = function(self) return sqrt(self:squared_len()) end,
        normalize = function(self) return self:div(self:magnitude()) end,
        lerp = function(self, a, b, t)
            if not t then a, b, t = self, a, b end
            self.x, self.y, self.z, self.w = a.x + (b.x - a.x) * t,
                                             a.y * (b.y - a.y) * t,
                                             a.z * (b.z - a.z) * t,
                                             a.w * (b.w - a.w) * t
            return self
        end,
        avg = function(self, b) return self:add(b):mul(0.5) end,
        mul3 = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x * o, self.y * o, self.z * o
            else
                self.x, self.y, self.z = self.x * o.x, self.y * o.y,
                    self.z * o.z
            end
            return self
        end,
        div3 = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x / o, self.y / o, self.z / o
            else
                self.x, self.y, self.z = self.x / o.x, self.y / o.y,
                    self.z / o.z
            end
            return self
        end,
        add3 = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x + o, self.y + o, self.z + o
            else
                self.x, self.y, self.z = self.x + o.x, self.y + o.y,
                    self.z + o.z
            end
            return self
        end,
        sub3 = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z = self.x - o, self.y - o, self.z - o
            else
                self.x, self.y, self.z = self.x - o.x, self.y - o.y,
                    self.z - o.z
            end
            return self
        end,
        mul = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z, self.w = self.x * o, self.y * o,
                    self.z * o, self.w * o
            else
                self.x, self.y, self.z, self.w = self.x * o.x, self.y * o.y,
                    self.z * o.z, self.w * o.w
            end
            return self
        end,
        div = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z, self.w = self.x / o, self.y / o,
                    self.z / o, self.w / o
            else
                self.x, self.y, self.z, self.w = self.x / o.x, self.y / o.y,
                    self.z / o.z, self.w / o.w
            end
            return self
        end,
        add = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z, self.w = self.x + o, self.y + o,
                    self.z + o, self.w + o
            else
                self.x, self.y, self.z, self.w = self.x + o.x, self.y + o.y,
                    self.z + o.z, self.w + o.w
            end
            return self
        end,
        add_w = function(self, f)
            self.w = self.w + f
            return self
        end,
        sub = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z, self.w = self.x - o, self.y - o,
                    self.z - o, self.w - o
            else
                self.x, self.y, self.z, self.w = self.x - o.x, self.y - o.y,
                    self.z - o.z, self.w - o.w
            end
            return self
        end,
        sub_w = function(self, f)
            self.w = self.w - f
            return self
        end,
        mul_new = function(self, o)
            if type(o) == "number" then
                return Vec4(self.x * o, self.y * o, self.z * o, self.w * o)
            else
                return Vec4(self.x * o.x, self.y * o.y, self.z * o.z,
                    self.w * o.w)
            end
        end,
        div_new = function(self, o)
            if type(o) == "number" then
                return Vec4(self.x / o, self.y / o, self.z / o, self.w / o)
            else
                return Vec4(self.x / o.x, self.y / o.y, self.z / o.z,
                    self.w / o.w)
            end
        end,
        add_new = function(self, o)
            if type(o) == "number" then
                return Vec4(self.x + o, self.y + o, self.z + o, self.w + o)
            else
                return Vec4(self.x + o.x, self.y + o.y, self.z + o.z,
                    self.w + o.w)
            end
        end,
        sub_new = function(self, o)
            if type(o) == "number" then
                return Vec4(self.x - o, self.y - o, self.z - o, self.w - o)
            else
                return Vec4(self.x - o.x, self.y - o.y, self.z - o.z,
                    self.w - o.w)
            end
        end,
        neg3 = function(self)
            self.x, self.y, self.z = -self.x, -self.y, -self.w
            return self
        end,
        neg = function(self)
            self.x, self.y, self.z, self.w = -self.x, -self.y, -self.z, -self.w
            return self
        end,
        min = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z, self.w = min(self.x, o),
                    min(self.y, o), min(self.z, o), min(self.w, o)
            else
                self.x, self.y, self.z, self.w = min(self.x, o.x),
                    min(self.y, o.y), min(self.z, o.z), min(self.w, o.w)
            end
            return self
        end,
        max = function(self, o)
            if type(o) == "number" then
                self.x, self.y, self.z, self.w = max(self.x, o),
                    max(self.y, o), max(self.z, o), max(self.w, o)
            else
                self.x, self.y, self.z, self.w = max(self.x, o.x),
                    max(self.y, o.y), max(self.z, o.z), max(self.w, o.w)
            end
            return self
        end,
        abs = function(self)
            self.x, self.y, self.z, self.w = abs(self.x), abs(self.y),
                abs(self.z), abs(self.w)
            return self
        end,
        clamp = function(self, l, h)
            self.x, self.y, self.z, self.w = clamp(self.x, l, h),
                clamp(self.y, l, h), clamp(self.z, l, h), clamp(self.w, l. h)
            return self
        end,
        dist = function(self, o)
            local dx, dy, dz = self.x - o.x, self.y - o.y, self.z - o.z
            return sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2)
        end,
        dist2 = function(self, o)
            local dx, dy = self.x - o.x, self.y - o.y
            return sqrt(dx ^ 2 + dy ^ 2)
        end,
        rotate_around_z = function(self, c, s)
            if type(c) == "number" then
                if not s then
                    local angle = c
                    return self:rotate_around_z(cos(angle), sin(angle))
                else
                    local rx, ry = self.x, self.y
                    self.x, self.y = c * rx - s * ry, c * ry + s * rx
                    return self
                end
            else
                return self:rotate_around_z(c.x, c.y)
            end
        end,
        rotate_around_x = function(self, c, s)
            if type(c) == "number" then
                if not s then
                    local angle = c
                    return self:rotate_around_x(cos(angle), sin(angle))
                else
                    local ry, rz = self.y, self.z
                    self.y, self.z = c * ry - s * rz, c * rz + s * ry
                    return self
                end
            else
                return self:rotate_around_x(c.x, c.y)
            end
        end,
        rotate_around_y = function(self, c, s)
            if type(c) == "number" then
                if not s then
                    local angle = c
                    return self:rotate_around_y(cos(angle), sin(angle))
                else
                    local rx, rz = self.x, self.z
                    self.x, self.z = c * rx + s * rz, c * rz - s * rx
                    return self
                end
            else
                return self:rotate_around_y(c.x, c.y)
            end
        end
    }
})
M.Vec4 = Vec4

capi.external_set("new_vec2", function(x, y) return Vec2(x, y) end)
capi.external_set("new_vec3", function(x, y, z) return Vec3(x, y, z) end)
capi.external_set("new_vec4", function(x, y, z, w) return Vec4(x, y, z, w) end)

local newproxy = newproxy
local getmt, setmt = getmetatable, setmetatable

local ntoi2 = { x = 1, y = 2 }
local ntoi3 = { x = 1, y = 2, z = 3, r = 1, g = 2, b = 3 }
local ntoi4 = { x = 1, y = 2, z = 3, w = 4, r = 1, g = 2, b = 3, a = 4 }

local gen_vec_surrogate = function(name, base, ltable)
    local surrtbl
    surrtbl = {
        name = name,
        new = function(self, ent, var)
            debug then log.log(log.INFO, name .. ": new: " .. var.name)
            local rawt = { entity = ent, variable = var }
            rawt.rawt = rawt
            local ret = newproxy(true)
            local mt = getmt(ret)
            mt.__tostring = self.__tostring
            mt.__index    = setmt(rawt, self)
            mt.__newindex = self.__newindex
            mt.__eq, mt.__len, mt.__mul, mt.__div, mt.__add, mt.__sub
                = base.__eq, base.__len, base.__mul, base.__div, base.__add,
                  base.__sub
            return ret
        end,
        __tostring = (ltable.w and function(self)
            return ("%s <%f, %f, %f, %f>"):format(name, self.x, self.y,
                self.z, self.w)
        end or (ltable.z and function(self)
            return ("%s <%f, %f, %f>"):format(name, self.x, self.y, self.z)
        end or function(self)
            return ("%s <%f, %f>"):format(name, self.x, self.y)
        end)),
        __index = function(self, n)
            local i = ltable[n]
            if i then return self.variable:get_item(self.entity, i) end
            return surrtbl[n] or rawget(self.rawt, n)
        end,
        __newindex = function(self, n, val)
            local i = ltable[n]
            if i then return self.variable:set_item(self.entity, i, val) end
            rawset(self.rawt, n, val)
        end
    }
    for k, v in pairs(base.__index) do
        if not k:match("^from_.+$") then surrtbl[k] = v end
    end
    return surrtbl
end

M.Vec2_Surrogate = gen_vec_surrogate("Vec2_Surrogate", Vec2_mt, ntoi2)
M.Vec3_Surrogate = gen_vec_surrogate("Vec3_Surrogate", Vec3_mt, ntoi3)
M.Vec4_Surrogate = gen_vec_surrogate("Vec4_Surrogate", Vec4_mt, ntoi4)

local sincos360 = {
    Vec2( 1.00000000,  0.00000000), Vec2( 0.99984770,  0.01745241), Vec2( 0.99939083,  0.03489950), Vec2( 0.99862953,  0.05233596), Vec2( 0.99756405,  0.06975647), Vec2( 0.99619470,  0.08715574), -- 0
    Vec2( 0.99452190,  0.10452846), Vec2( 0.99254615,  0.12186934), Vec2( 0.99026807,  0.13917310), Vec2( 0.98768834,  0.15643447), Vec2( 0.98480775,  0.17364818), Vec2( 0.98162718,  0.19080900), -- 6
    Vec2( 0.97814760,  0.20791169), Vec2( 0.97437006,  0.22495105), Vec2( 0.97029573,  0.24192190), Vec2( 0.96592583,  0.25881905), Vec2( 0.96126170,  0.27563736), Vec2( 0.95630476,  0.29237170), -- 12
    Vec2( 0.95105652,  0.30901699), Vec2( 0.94551858,  0.32556815), Vec2( 0.93969262,  0.34202014), Vec2( 0.93358043,  0.35836795), Vec2( 0.92718385,  0.37460659), Vec2( 0.92050485,  0.39073113), -- 18
    Vec2( 0.91354546,  0.40673664), Vec2( 0.90630779,  0.42261826), Vec2( 0.89879405,  0.43837115), Vec2( 0.89100652,  0.45399050), Vec2( 0.88294759,  0.46947156), Vec2( 0.87461971,  0.48480962), -- 24
    Vec2( 0.86602540,  0.50000000), Vec2( 0.85716730,  0.51503807), Vec2( 0.84804810,  0.52991926), Vec2( 0.83867057,  0.54463904), Vec2( 0.82903757,  0.55919290), Vec2( 0.81915204,  0.57357644), -- 30
    Vec2( 0.80901699,  0.58778525), Vec2( 0.79863551,  0.60181502), Vec2( 0.78801075,  0.61566148), Vec2( 0.77714596,  0.62932039), Vec2( 0.76604444,  0.64278761), Vec2( 0.75470958,  0.65605903), -- 36
    Vec2( 0.74314483,  0.66913061), Vec2( 0.73135370,  0.68199836), Vec2( 0.71933980,  0.69465837), Vec2( 0.70710678,  0.70710678), Vec2( 0.69465837,  0.71933980), Vec2( 0.68199836,  0.73135370), -- 42
    Vec2( 0.66913061,  0.74314483), Vec2( 0.65605903,  0.75470958), Vec2( 0.64278761,  0.76604444), Vec2( 0.62932039,  0.77714596), Vec2( 0.61566148,  0.78801075), Vec2( 0.60181502,  0.79863551), -- 48
    Vec2( 0.58778525,  0.80901699), Vec2( 0.57357644,  0.81915204), Vec2( 0.55919290,  0.82903757), Vec2( 0.54463904,  0.83867057), Vec2( 0.52991926,  0.84804810), Vec2( 0.51503807,  0.85716730), -- 54
    Vec2( 0.50000000,  0.86602540), Vec2( 0.48480962,  0.87461971), Vec2( 0.46947156,  0.88294759), Vec2( 0.45399050,  0.89100652), Vec2( 0.43837115,  0.89879405), Vec2( 0.42261826,  0.90630779), -- 60
    Vec2( 0.40673664,  0.91354546), Vec2( 0.39073113,  0.92050485), Vec2( 0.37460659,  0.92718385), Vec2( 0.35836795,  0.93358043), Vec2( 0.34202014,  0.93969262), Vec2( 0.32556815,  0.94551858), -- 66
    Vec2( 0.30901699,  0.95105652), Vec2( 0.29237170,  0.95630476), Vec2( 0.27563736,  0.96126170), Vec2( 0.25881905,  0.96592583), Vec2( 0.24192190,  0.97029573), Vec2( 0.22495105,  0.97437006), -- 72
    Vec2( 0.20791169,  0.97814760), Vec2( 0.19080900,  0.98162718), Vec2( 0.17364818,  0.98480775), Vec2( 0.15643447,  0.98768834), Vec2( 0.13917310,  0.99026807), Vec2( 0.12186934,  0.99254615), -- 78
    Vec2( 0.10452846,  0.99452190), Vec2( 0.08715574,  0.99619470), Vec2( 0.06975647,  0.99756405), Vec2( 0.05233596,  0.99862953), Vec2( 0.03489950,  0.99939083), Vec2( 0.01745241,  0.99984770), -- 84
    Vec2( 0.00000000,  1.00000000), Vec2(-0.01745241,  0.99984770), Vec2(-0.03489950,  0.99939083), Vec2(-0.05233596,  0.99862953), Vec2(-0.06975647,  0.99756405), Vec2(-0.08715574,  0.99619470), -- 90
    Vec2(-0.10452846,  0.99452190), Vec2(-0.12186934,  0.99254615), Vec2(-0.13917310,  0.99026807), Vec2(-0.15643447,  0.98768834), Vec2(-0.17364818,  0.98480775), Vec2(-0.19080900,  0.98162718), -- 96
    Vec2(-0.20791169,  0.97814760), Vec2(-0.22495105,  0.97437006), Vec2(-0.24192190,  0.97029573), Vec2(-0.25881905,  0.96592583), Vec2(-0.27563736,  0.96126170), Vec2(-0.29237170,  0.95630476), -- 102
    Vec2(-0.30901699,  0.95105652), Vec2(-0.32556815,  0.94551858), Vec2(-0.34202014,  0.93969262), Vec2(-0.35836795,  0.93358043), Vec2(-0.37460659,  0.92718385), Vec2(-0.39073113,  0.92050485), -- 108
    Vec2(-0.40673664,  0.91354546), Vec2(-0.42261826,  0.90630779), Vec2(-0.43837115,  0.89879405), Vec2(-0.45399050,  0.89100652), Vec2(-0.46947156,  0.88294759), Vec2(-0.48480962,  0.87461971), -- 114
    Vec2(-0.50000000,  0.86602540), Vec2(-0.51503807,  0.85716730), Vec2(-0.52991926,  0.84804810), Vec2(-0.54463904,  0.83867057), Vec2(-0.55919290,  0.82903757), Vec2(-0.57357644,  0.81915204), -- 120
    Vec2(-0.58778525,  0.80901699), Vec2(-0.60181502,  0.79863551), Vec2(-0.61566148,  0.78801075), Vec2(-0.62932039,  0.77714596), Vec2(-0.64278761,  0.76604444), Vec2(-0.65605903,  0.75470958), -- 126
    Vec2(-0.66913061,  0.74314483), Vec2(-0.68199836,  0.73135370), Vec2(-0.69465837,  0.71933980), Vec2(-0.70710678,  0.70710678), Vec2(-0.71933980,  0.69465837), Vec2(-0.73135370,  0.68199836), -- 132
    Vec2(-0.74314483,  0.66913061), Vec2(-0.75470958,  0.65605903), Vec2(-0.76604444,  0.64278761), Vec2(-0.77714596,  0.62932039), Vec2(-0.78801075,  0.61566148), Vec2(-0.79863551,  0.60181502), -- 138
    Vec2(-0.80901699,  0.58778525), Vec2(-0.81915204,  0.57357644), Vec2(-0.82903757,  0.55919290), Vec2(-0.83867057,  0.54463904), Vec2(-0.84804810,  0.52991926), Vec2(-0.85716730,  0.51503807), -- 144
    Vec2(-0.86602540,  0.50000000), Vec2(-0.87461971,  0.48480962), Vec2(-0.88294759,  0.46947156), Vec2(-0.89100652,  0.45399050), Vec2(-0.89879405,  0.43837115), Vec2(-0.90630779,  0.42261826), -- 150
    Vec2(-0.91354546,  0.40673664), Vec2(-0.92050485,  0.39073113), Vec2(-0.92718385,  0.37460659), Vec2(-0.93358043,  0.35836795), Vec2(-0.93969262,  0.34202014), Vec2(-0.94551858,  0.32556815), -- 156
    Vec2(-0.95105652,  0.30901699), Vec2(-0.95630476,  0.29237170), Vec2(-0.96126170,  0.27563736), Vec2(-0.96592583,  0.25881905), Vec2(-0.97029573,  0.24192190), Vec2(-0.97437006,  0.22495105), -- 162
    Vec2(-0.97814760,  0.20791169), Vec2(-0.98162718,  0.19080900), Vec2(-0.98480775,  0.17364818), Vec2(-0.98768834,  0.15643447), Vec2(-0.99026807,  0.13917310), Vec2(-0.99254615,  0.12186934), -- 168
    Vec2(-0.99452190,  0.10452846), Vec2(-0.99619470,  0.08715574), Vec2(-0.99756405,  0.06975647), Vec2(-0.99862953,  0.05233596), Vec2(-0.99939083,  0.03489950), Vec2(-0.99984770,  0.01745241), -- 174
    Vec2(-1.00000000,  0.00000000), Vec2(-0.99984770, -0.01745241), Vec2(-0.99939083, -0.03489950), Vec2(-0.99862953, -0.05233596), Vec2(-0.99756405, -0.06975647), Vec2(-0.99619470, -0.08715574), -- 180
    Vec2(-0.99452190, -0.10452846), Vec2(-0.99254615, -0.12186934), Vec2(-0.99026807, -0.13917310), Vec2(-0.98768834, -0.15643447), Vec2(-0.98480775, -0.17364818), Vec2(-0.98162718, -0.19080900), -- 186
    Vec2(-0.97814760, -0.20791169), Vec2(-0.97437006, -0.22495105), Vec2(-0.97029573, -0.24192190), Vec2(-0.96592583, -0.25881905), Vec2(-0.96126170, -0.27563736), Vec2(-0.95630476, -0.29237170), -- 192
    Vec2(-0.95105652, -0.30901699), Vec2(-0.94551858, -0.32556815), Vec2(-0.93969262, -0.34202014), Vec2(-0.93358043, -0.35836795), Vec2(-0.92718385, -0.37460659), Vec2(-0.92050485, -0.39073113), -- 198
    Vec2(-0.91354546, -0.40673664), Vec2(-0.90630779, -0.42261826), Vec2(-0.89879405, -0.43837115), Vec2(-0.89100652, -0.45399050), Vec2(-0.88294759, -0.46947156), Vec2(-0.87461971, -0.48480962), -- 204
    Vec2(-0.86602540, -0.50000000), Vec2(-0.85716730, -0.51503807), Vec2(-0.84804810, -0.52991926), Vec2(-0.83867057, -0.54463904), Vec2(-0.82903757, -0.55919290), Vec2(-0.81915204, -0.57357644), -- 210
    Vec2(-0.80901699, -0.58778525), Vec2(-0.79863551, -0.60181502), Vec2(-0.78801075, -0.61566148), Vec2(-0.77714596, -0.62932039), Vec2(-0.76604444, -0.64278761), Vec2(-0.75470958, -0.65605903), -- 216
    Vec2(-0.74314483, -0.66913061), Vec2(-0.73135370, -0.68199836), Vec2(-0.71933980, -0.69465837), Vec2(-0.70710678, -0.70710678), Vec2(-0.69465837, -0.71933980), Vec2(-0.68199836, -0.73135370), -- 222
    Vec2(-0.66913061, -0.74314483), Vec2(-0.65605903, -0.75470958), Vec2(-0.64278761, -0.76604444), Vec2(-0.62932039, -0.77714596), Vec2(-0.61566148, -0.78801075), Vec2(-0.60181502, -0.79863551), -- 228
    Vec2(-0.58778525, -0.80901699), Vec2(-0.57357644, -0.81915204), Vec2(-0.55919290, -0.82903757), Vec2(-0.54463904, -0.83867057), Vec2(-0.52991926, -0.84804810), Vec2(-0.51503807, -0.85716730), -- 234
    Vec2(-0.50000000, -0.86602540), Vec2(-0.48480962, -0.87461971), Vec2(-0.46947156, -0.88294759), Vec2(-0.45399050, -0.89100652), Vec2(-0.43837115, -0.89879405), Vec2(-0.42261826, -0.90630779), -- 240
    Vec2(-0.40673664, -0.91354546), Vec2(-0.39073113, -0.92050485), Vec2(-0.37460659, -0.92718385), Vec2(-0.35836795, -0.93358043), Vec2(-0.34202014, -0.93969262), Vec2(-0.32556815, -0.94551858), -- 246
    Vec2(-0.30901699, -0.95105652), Vec2(-0.29237170, -0.95630476), Vec2(-0.27563736, -0.96126170), Vec2(-0.25881905, -0.96592583), Vec2(-0.24192190, -0.97029573), Vec2(-0.22495105, -0.97437006), -- 252
    Vec2(-0.20791169, -0.97814760), Vec2(-0.19080900, -0.98162718), Vec2(-0.17364818, -0.98480775), Vec2(-0.15643447, -0.98768834), Vec2(-0.13917310, -0.99026807), Vec2(-0.12186934, -0.99254615), -- 258
    Vec2(-0.10452846, -0.99452190), Vec2(-0.08715574, -0.99619470), Vec2(-0.06975647, -0.99756405), Vec2(-0.05233596, -0.99862953), Vec2(-0.03489950, -0.99939083), Vec2(-0.01745241, -0.99984770), -- 264
    Vec2(-0.00000000, -1.00000000), Vec2( 0.01745241, -0.99984770), Vec2( 0.03489950, -0.99939083), Vec2( 0.05233596, -0.99862953), Vec2( 0.06975647, -0.99756405), Vec2( 0.08715574, -0.99619470), -- 270
    Vec2( 0.10452846, -0.99452190), Vec2( 0.12186934, -0.99254615), Vec2( 0.13917310, -0.99026807), Vec2( 0.15643447, -0.98768834), Vec2( 0.17364818, -0.98480775), Vec2( 0.19080900, -0.98162718), -- 276
    Vec2( 0.20791169, -0.97814760), Vec2( 0.22495105, -0.97437006), Vec2( 0.24192190, -0.97029573), Vec2( 0.25881905, -0.96592583), Vec2( 0.27563736, -0.96126170), Vec2( 0.29237170, -0.95630476), -- 282
    Vec2( 0.30901699, -0.95105652), Vec2( 0.32556815, -0.94551858), Vec2( 0.34202014, -0.93969262), Vec2( 0.35836795, -0.93358043), Vec2( 0.37460659, -0.92718385), Vec2( 0.39073113, -0.92050485), -- 288
    Vec2( 0.40673664, -0.91354546), Vec2( 0.42261826, -0.90630779), Vec2( 0.43837115, -0.89879405), Vec2( 0.45399050, -0.89100652), Vec2( 0.46947156, -0.88294759), Vec2( 0.48480962, -0.87461971), -- 294
    Vec2( 0.50000000, -0.86602540), Vec2( 0.51503807, -0.85716730), Vec2( 0.52991926, -0.84804810), Vec2( 0.54463904, -0.83867057), Vec2( 0.55919290, -0.82903757), Vec2( 0.57357644, -0.81915204), -- 300
    Vec2( 0.58778525, -0.80901699), Vec2( 0.60181502, -0.79863551), Vec2( 0.61566148, -0.78801075), Vec2( 0.62932039, -0.77714596), Vec2( 0.64278761, -0.76604444), Vec2( 0.65605903, -0.75470958), -- 306
    Vec2( 0.66913061, -0.74314483), Vec2( 0.68199836, -0.73135370), Vec2( 0.69465837, -0.71933980), Vec2( 0.70710678, -0.70710678), Vec2( 0.71933980, -0.69465837), Vec2( 0.73135370, -0.68199836), -- 312
    Vec2( 0.74314483, -0.66913061), Vec2( 0.75470958, -0.65605903), Vec2( 0.76604444, -0.64278761), Vec2( 0.77714596, -0.62932039), Vec2( 0.78801075, -0.61566148), Vec2( 0.79863551, -0.60181502), -- 318
    Vec2( 0.80901699, -0.58778525), Vec2( 0.81915204, -0.57357644), Vec2( 0.82903757, -0.55919290), Vec2( 0.83867057, -0.54463904), Vec2( 0.84804810, -0.52991926), Vec2( 0.85716730, -0.51503807), -- 324
    Vec2( 0.86602540, -0.50000000), Vec2( 0.87461971, -0.48480962), Vec2( 0.88294759, -0.46947156), Vec2( 0.89100652, -0.45399050), Vec2( 0.89879405, -0.43837115), Vec2( 0.90630779, -0.42261826), -- 330
    Vec2( 0.91354546, -0.40673664), Vec2( 0.92050485, -0.39073113), Vec2( 0.92718385, -0.37460659), Vec2( 0.93358043, -0.35836795), Vec2( 0.93969262, -0.34202014), Vec2( 0.94551858, -0.32556815), -- 336
    Vec2( 0.95105652, -0.30901699), Vec2( 0.95630476, -0.29237170), Vec2( 0.96126170, -0.27563736), Vec2( 0.96592583, -0.25881905), Vec2( 0.97029573, -0.24192190), Vec2( 0.97437006, -0.22495105), -- 342
    Vec2( 0.97814760, -0.20791169), Vec2( 0.98162718, -0.19080900), Vec2( 0.98480775, -0.17364818), Vec2( 0.98768834, -0.15643447), Vec2( 0.99026807, -0.13917310), Vec2( 0.99254615, -0.12186934), -- 348
    Vec2( 0.99452190, -0.10452846), Vec2( 0.99619470, -0.08715574), Vec2( 0.99756405, -0.06975647), Vec2( 0.99862953, -0.05233596), Vec2( 0.99939083, -0.03489950), Vec2( 0.99984770, -0.01745241), -- 354
    Vec2( 1.00000000,  0.00000000), Vec2( 0.99984770,  0.01745241), Vec2( 0.99939083,  0.03489950), Vec2( 0.99862953,  0.05233596), Vec2( 0.99756405,  0.06975647), Vec2( 0.99619470,  0.08715574), -- 360
    Vec2( 0.99452190,  0.10452846), Vec2( 0.99254615,  0.12186934), Vec2( 0.99026807,  0.13917310), Vec2( 0.98768834,  0.15643447), Vec2( 0.98480775,  0.17364818), Vec2( 0.98162718,  0.19080900), -- 366
    Vec2( 0.97814760,  0.20791169), Vec2( 0.97437006,  0.22495105), Vec2( 0.97029573,  0.24192190), Vec2( 0.96592583,  0.25881905), Vec2( 0.96126170,  0.27563736), Vec2( 0.95630476,  0.29237170), -- 372
    Vec2( 0.95105652,  0.30901699), Vec2( 0.94551858,  0.32556815), Vec2( 0.93969262,  0.34202014), Vec2( 0.93358043,  0.35836795), Vec2( 0.92718385,  0.37460659), Vec2( 0.92050485,  0.39073113), -- 378
    Vec2( 0.91354546,  0.40673664), Vec2( 0.90630779,  0.42261826), Vec2( 0.89879405,  0.43837115), Vec2( 0.89100652,  0.45399050), Vec2( 0.88294759,  0.46947156), Vec2( 0.87461971,  0.48480962), -- 384
    Vec2( 0.86602540,  0.50000000), Vec2( 0.85716730,  0.51503807), Vec2( 0.84804810,  0.52991926), Vec2( 0.83867057,  0.54463904), Vec2( 0.82903757,  0.55919290), Vec2( 0.81915204,  0.57357644), -- 390
    Vec2( 0.80901699,  0.58778525), Vec2( 0.79863551,  0.60181502), Vec2( 0.78801075,  0.61566148), Vec2( 0.77714596,  0.62932039), Vec2( 0.76604444,  0.64278761), Vec2( 0.75470958,  0.65605903), -- 396
    Vec2( 0.74314483,  0.66913061), Vec2( 0.73135370,  0.68199836), Vec2( 0.71933980,  0.69465837), Vec2( 0.70710678,  0.70710678), Vec2( 0.69465837,  0.71933980), Vec2( 0.68199836,  0.73135370), -- 402
    Vec2( 0.66913061,  0.74314483), Vec2( 0.65605903,  0.75470958), Vec2( 0.64278761,  0.76604444), Vec2( 0.62932039,  0.77714596), Vec2( 0.61566148,  0.78801075), Vec2( 0.60181502,  0.79863551), -- 408
    Vec2( 0.58778525,  0.80901699), Vec2( 0.57357644,  0.81915204), Vec2( 0.55919290,  0.82903757), Vec2( 0.54463904,  0.83867057), Vec2( 0.52991926,  0.84804810), Vec2( 0.51503807,  0.85716730), -- 414
    Vec2( 0.50000000,  0.86602540), Vec2( 0.48480962,  0.87461971), Vec2( 0.46947156,  0.88294759), Vec2( 0.45399050,  0.89100652), Vec2( 0.43837115,  0.89879405), Vec2( 0.42261826,  0.90630779), -- 420
    Vec2( 0.40673664,  0.91354546), Vec2( 0.39073113,  0.92050485), Vec2( 0.37460659,  0.92718385), Vec2( 0.35836795,  0.93358043), Vec2( 0.34202014,  0.93969262), Vec2( 0.32556815,  0.94551858), -- 426
    Vec2( 0.30901699,  0.95105652), Vec2( 0.29237170,  0.95630476), Vec2( 0.27563736,  0.96126170), Vec2( 0.25881905,  0.96592583), Vec2( 0.24192190,  0.97029573), Vec2( 0.22495105,  0.97437006), -- 432
    Vec2( 0.20791169,  0.97814760), Vec2( 0.19080900,  0.98162718), Vec2( 0.17364818,  0.98480775), Vec2( 0.15643447,  0.98768834), Vec2( 0.13917310,  0.99026807), Vec2( 0.12186934,  0.99254615), -- 438
    Vec2( 0.10452846,  0.99452190), Vec2( 0.08715574,  0.99619470), Vec2( 0.06975647,  0.99756405), Vec2( 0.05233596,  0.99862953), Vec2( 0.03489950,  0.99939083), Vec2( 0.01745241,  0.99984770), -- 444
    Vec2( 0.00000000,  1.00000000), Vec2(-0.01745241,  0.99984770), Vec2(-0.03489950,  0.99939083), Vec2(-0.05233596,  0.99862953), Vec2(-0.06975647,  0.99756405), Vec2(-0.08715574,  0.99619470), -- 450
    Vec2(-0.10452846,  0.99452190), Vec2(-0.12186934,  0.99254615), Vec2(-0.13917310,  0.99026807), Vec2(-0.15643447,  0.98768834), Vec2(-0.17364818,  0.98480775), Vec2(-0.19080900,  0.98162718), -- 456
    Vec2(-0.20791169,  0.97814760), Vec2(-0.22495105,  0.97437006), Vec2(-0.24192190,  0.97029573), Vec2(-0.25881905,  0.96592583), Vec2(-0.27563736,  0.96126170), Vec2(-0.29237170,  0.95630476), -- 462
    Vec2(-0.30901699,  0.95105652), Vec2(-0.32556815,  0.94551858), Vec2(-0.34202014,  0.93969262), Vec2(-0.35836795,  0.93358043), Vec2(-0.37460659,  0.92718385), Vec2(-0.39073113,  0.92050485), -- 468
    Vec2(-0.40673664,  0.91354546), Vec2(-0.42261826,  0.90630779), Vec2(-0.43837115,  0.89879405), Vec2(-0.45399050,  0.89100652), Vec2(-0.46947156,  0.88294759), Vec2(-0.48480962,  0.87461971), -- 474
    Vec2(-0.50000000,  0.86602540), Vec2(-0.51503807,  0.85716730), Vec2(-0.52991926,  0.84804810), Vec2(-0.54463904,  0.83867057), Vec2(-0.55919290,  0.82903757), Vec2(-0.57357644,  0.81915204), -- 480
    Vec2(-0.58778525,  0.80901699), Vec2(-0.60181502,  0.79863551), Vec2(-0.61566148,  0.78801075), Vec2(-0.62932039,  0.77714596), Vec2(-0.64278761,  0.76604444), Vec2(-0.65605903,  0.75470958), -- 486
    Vec2(-0.66913061,  0.74314483), Vec2(-0.68199836,  0.73135370), Vec2(-0.69465837,  0.71933980), Vec2(-0.70710678,  0.70710678), Vec2(-0.71933980,  0.69465837), Vec2(-0.73135370,  0.68199836), -- 492
    Vec2(-0.74314483,  0.66913061), Vec2(-0.75470958,  0.65605903), Vec2(-0.76604444,  0.64278761), Vec2(-0.77714596,  0.62932039), Vec2(-0.78801075,  0.61566148), Vec2(-0.79863551,  0.60181502), -- 498
    Vec2(-0.80901699,  0.58778525), Vec2(-0.81915204,  0.57357644), Vec2(-0.82903757,  0.55919290), Vec2(-0.83867057,  0.54463904), Vec2(-0.84804810,  0.52991926), Vec2(-0.85716730,  0.51503807), -- 504
    Vec2(-0.86602540,  0.50000000), Vec2(-0.87461971,  0.48480962), Vec2(-0.88294759,  0.46947156), Vec2(-0.89100652,  0.45399050), Vec2(-0.89879405,  0.43837115), Vec2(-0.90630779,  0.42261826), -- 510
    Vec2(-0.91354546,  0.40673664), Vec2(-0.92050485,  0.39073113), Vec2(-0.92718385,  0.37460659), Vec2(-0.93358043,  0.35836795), Vec2(-0.93969262,  0.34202014), Vec2(-0.94551858,  0.32556815), -- 516
    Vec2(-0.95105652,  0.30901699), Vec2(-0.95630476,  0.29237170), Vec2(-0.96126170,  0.27563736), Vec2(-0.96592583,  0.25881905), Vec2(-0.97029573,  0.24192190), Vec2(-0.97437006,  0.22495105), -- 522
    Vec2(-0.97814760,  0.20791169), Vec2(-0.98162718,  0.19080900), Vec2(-0.98480775,  0.17364818), Vec2(-0.98768834,  0.15643447), Vec2(-0.99026807,  0.13917310), Vec2(-0.99254615,  0.12186934), -- 528
    Vec2(-0.99452190,  0.10452846), Vec2(-0.99619470,  0.08715574), Vec2(-0.99756405,  0.06975647), Vec2(-0.99862953,  0.05233596), Vec2(-0.99939083,  0.03489950), Vec2(-0.99984770,  0.01745241), -- 534
    Vec2(-1.00000000,  0.00000000), Vec2(-0.99984770, -0.01745241), Vec2(-0.99939083, -0.03489950), Vec2(-0.99862953, -0.05233596), Vec2(-0.99756405, -0.06975647), Vec2(-0.99619470, -0.08715574), -- 540
    Vec2(-0.99452190, -0.10452846), Vec2(-0.99254615, -0.12186934), Vec2(-0.99026807, -0.13917310), Vec2(-0.98768834, -0.15643447), Vec2(-0.98480775, -0.17364818), Vec2(-0.98162718, -0.19080900), -- 546
    Vec2(-0.97814760, -0.20791169), Vec2(-0.97437006, -0.22495105), Vec2(-0.97029573, -0.24192190), Vec2(-0.96592583, -0.25881905), Vec2(-0.96126170, -0.27563736), Vec2(-0.95630476, -0.29237170), -- 552
    Vec2(-0.95105652, -0.30901699), Vec2(-0.94551858, -0.32556815), Vec2(-0.93969262, -0.34202014), Vec2(-0.93358043, -0.35836795), Vec2(-0.92718385, -0.37460659), Vec2(-0.92050485, -0.39073113), -- 558
    Vec2(-0.91354546, -0.40673664), Vec2(-0.90630779, -0.42261826), Vec2(-0.89879405, -0.43837115), Vec2(-0.89100652, -0.45399050), Vec2(-0.88294759, -0.46947156), Vec2(-0.87461971, -0.48480962), -- 564
    Vec2(-0.86602540, -0.50000000), Vec2(-0.85716730, -0.51503807), Vec2(-0.84804810, -0.52991926), Vec2(-0.83867057, -0.54463904), Vec2(-0.82903757, -0.55919290), Vec2(-0.81915204, -0.57357644), -- 570
    Vec2(-0.80901699, -0.58778525), Vec2(-0.79863551, -0.60181502), Vec2(-0.78801075, -0.61566148), Vec2(-0.77714596, -0.62932039), Vec2(-0.76604444, -0.64278761), Vec2(-0.75470958, -0.65605903), -- 576
    Vec2(-0.74314483, -0.66913061), Vec2(-0.73135370, -0.68199836), Vec2(-0.71933980, -0.69465837), Vec2(-0.70710678, -0.70710678), Vec2(-0.69465837, -0.71933980), Vec2(-0.68199836, -0.73135370), -- 582
    Vec2(-0.66913061, -0.74314483), Vec2(-0.65605903, -0.75470958), Vec2(-0.64278761, -0.76604444), Vec2(-0.62932039, -0.77714596), Vec2(-0.61566148, -0.78801075), Vec2(-0.60181502, -0.79863551), -- 588
    Vec2(-0.58778525, -0.80901699), Vec2(-0.57357644, -0.81915204), Vec2(-0.55919290, -0.82903757), Vec2(-0.54463904, -0.83867057), Vec2(-0.52991926, -0.84804810), Vec2(-0.51503807, -0.85716730), -- 594
    Vec2(-0.50000000, -0.86602540), Vec2(-0.48480962, -0.87461971), Vec2(-0.46947156, -0.88294759), Vec2(-0.45399050, -0.89100652), Vec2(-0.43837115, -0.89879405), Vec2(-0.42261826, -0.90630779), -- 600
    Vec2(-0.40673664, -0.91354546), Vec2(-0.39073113, -0.92050485), Vec2(-0.37460659, -0.92718385), Vec2(-0.35836795, -0.93358043), Vec2(-0.34202014, -0.93969262), Vec2(-0.32556815, -0.94551858), -- 606
    Vec2(-0.30901699, -0.95105652), Vec2(-0.29237170, -0.95630476), Vec2(-0.27563736, -0.96126170), Vec2(-0.25881905, -0.96592583), Vec2(-0.24192190, -0.97029573), Vec2(-0.22495105, -0.97437006), -- 612
    Vec2(-0.20791169, -0.97814760), Vec2(-0.19080900, -0.98162718), Vec2(-0.17364818, -0.98480775), Vec2(-0.15643447, -0.98768834), Vec2(-0.13917310, -0.99026807), Vec2(-0.12186934, -0.99254615), -- 618
    Vec2(-0.10452846, -0.99452190), Vec2(-0.08715574, -0.99619470), Vec2(-0.06975647, -0.99756405), Vec2(-0.05233596, -0.99862953), Vec2(-0.03489950, -0.99939083), Vec2(-0.01745241, -0.99984770), -- 624
    Vec2(-0.00000000, -1.00000000), Vec2( 0.01745241, -0.99984770), Vec2( 0.03489950, -0.99939083), Vec2( 0.05233596, -0.99862953), Vec2( 0.06975647, -0.99756405), Vec2( 0.08715574, -0.99619470), -- 630
    Vec2( 0.10452846, -0.99452190), Vec2( 0.12186934, -0.99254615), Vec2( 0.13917310, -0.99026807), Vec2( 0.15643447, -0.98768834), Vec2( 0.17364818, -0.98480775), Vec2( 0.19080900, -0.98162718), -- 636
    Vec2( 0.20791169, -0.97814760), Vec2( 0.22495105, -0.97437006), Vec2( 0.24192190, -0.97029573), Vec2( 0.25881905, -0.96592583), Vec2( 0.27563736, -0.96126170), Vec2( 0.29237170, -0.95630476), -- 642
    Vec2( 0.30901699, -0.95105652), Vec2( 0.32556815, -0.94551858), Vec2( 0.34202014, -0.93969262), Vec2( 0.35836795, -0.93358043), Vec2( 0.37460659, -0.92718385), Vec2( 0.39073113, -0.92050485), -- 648
    Vec2( 0.40673664, -0.91354546), Vec2( 0.42261826, -0.90630779), Vec2( 0.43837115, -0.89879405), Vec2( 0.45399050, -0.89100652), Vec2( 0.46947156, -0.88294759), Vec2( 0.48480962, -0.87461971), -- 654
    Vec2( 0.50000000, -0.86602540), Vec2( 0.51503807, -0.85716730), Vec2( 0.52991926, -0.84804810), Vec2( 0.54463904, -0.83867057), Vec2( 0.55919290, -0.82903757), Vec2( 0.57357644, -0.81915204), -- 660
    Vec2( 0.58778525, -0.80901699), Vec2( 0.60181502, -0.79863551), Vec2( 0.61566148, -0.78801075), Vec2( 0.62932039, -0.77714596), Vec2( 0.64278761, -0.76604444), Vec2( 0.65605903, -0.75470958), -- 666
    Vec2( 0.66913061, -0.74314483), Vec2( 0.68199836, -0.73135370), Vec2( 0.69465837, -0.71933980), Vec2( 0.70710678, -0.70710678), Vec2( 0.71933980, -0.69465837), Vec2( 0.73135370, -0.68199836), -- 672
    Vec2( 0.74314483, -0.66913061), Vec2( 0.75470958, -0.65605903), Vec2( 0.76604444, -0.64278761), Vec2( 0.77714596, -0.62932039), Vec2( 0.78801075, -0.61566148), Vec2( 0.79863551, -0.60181502), -- 678
    Vec2( 0.80901699, -0.58778525), Vec2( 0.81915204, -0.57357644), Vec2( 0.82903757, -0.55919290), Vec2( 0.83867057, -0.54463904), Vec2( 0.84804810, -0.52991926), Vec2( 0.85716730, -0.51503807), -- 684
    Vec2( 0.86602540, -0.50000000), Vec2( 0.87461971, -0.48480962), Vec2( 0.88294759, -0.46947156), Vec2( 0.89100652, -0.45399050), Vec2( 0.89879405, -0.43837115), Vec2( 0.90630779, -0.42261826), -- 690
    Vec2( 0.91354546, -0.40673664), Vec2( 0.92050485, -0.39073113), Vec2( 0.92718385, -0.37460659), Vec2( 0.93358043, -0.35836795), Vec2( 0.93969262, -0.34202014), Vec2( 0.94551858, -0.32556815), -- 696
    Vec2( 0.95105652, -0.30901699), Vec2( 0.95630476, -0.29237170), Vec2( 0.96126170, -0.27563736), Vec2( 0.96592583, -0.25881905), Vec2( 0.97029573, -0.24192190), Vec2( 0.97437006, -0.22495105), -- 702
    Vec2( 0.97814760, -0.20791169), Vec2( 0.98162718, -0.19080900), Vec2( 0.98480775, -0.17364818), Vec2( 0.98768834, -0.15643447), Vec2( 0.99026807, -0.13917310), Vec2( 0.99254615, -0.12186934), -- 708
    Vec2( 0.99452190, -0.10452846), Vec2( 0.99619470, -0.08715574), Vec2( 0.99756405, -0.06975647), Vec2( 0.99862953, -0.05233596), Vec2( 0.99939083, -0.03489950), Vec2( 0.99984770, -0.01745241), -- 714
    Vec2( 1.00000000,  0.00000000) -- 720
}
M.sin_cos_360 = function(angle)
    return sincos360[angle + 1]
end

local mod_360 = function(angle)
    if angle < 0 then
        angle = 360 + ((angle <= -360) and -((-angle) % 360) or angle)
    elseif angle >= 360 then
        angle %= 360
    end
    return angle
end
M.mod_360 = mod_360

M.sin_cos_mod_360 = function(angle)
    return sincos360[mod_360(angle) + 1]
end

return M
