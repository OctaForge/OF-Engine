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

local ffi = require("ffi")

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

local ffi_new, ffi_typeof = ffi.new, ffi.typeof
local type = type
local sin, cos, abs, min, max, sqrt, floor = math.sin, math.cos, math.abs,
    math.min, math.max, math.sqrt, math.floor
local clamp = function(v, l, h)
    return max(l, min(v, h))
end

local iton = { [0] = "x", [1] = "y", [2] = "z" }

local M = {}

M.Vec2, M.Vec2_mt = gen_vec2("double", "d", {
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
    __index = {
        from_ffi_array = function(self, o)
            return ffi_new(self, o[0], o[1])
        end,
        from_array = function(self, o)
            return ffi_new(self, o[1], o[2])
        end,

        copy = function(self)
            return ffi_typeof(self)(self.x, self.y)
        end,
        to_array = function(self)
            return { self.x, self.y }
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
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x * o, self.y * o)
            else
                return tp(self.x * o.x, self.y * o.y)
            end
        end,
        div_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x / o, self.y / o)
            else
                return tp(self.x / o.x, self.y / o.y)
            end
        end,
        add_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x + o, self.y + o)
            else
                return tp(self.x + o.x, self.y + o.y)
            end
        end,
        sub_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x - o, self.y - o)
            else
                return tp(self.x - o.x, self.y - o.y)
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

M.Vec3, M.Vec3_mt = gen_vec3("double", "d", {
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
            return ffi_typeof(self)(self.x, self.y, self.z)
        end,
        to_array = function(self)
            return { self.x, self.y, self.z }
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
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x * o, self.y * o, self.z * o)
            else
                return tp(self.x * o.x, self.y * o.y, self.z * o.z)
            end
        end,
        div_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x / o, self.y / o, self.z / o)
            else
                return tp(self.x / o.x, self.y / o.y, self.z / o.z)
            end
        end,
        add_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x + o, self.y + o, self.z + o)
            else
                return tp(self.x + o.x, self.y + o.y, self.z + o.z)
            end
        end,
        sub_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x - o, self.y - o, self.z - o)
            else
                return tp(self.x - o.x, self.y - o.y, self.z - o.z)
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

M.Vec4, M.Vec4_mt = gen_vec4("double", "d", {
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
            return ffi_typeof(self)(self.x, self.y, self.z, self.w)
        end,
        to_array = function(self)
            return { self.x, self.y, self.z, self.w }
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
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x * o, self.y * o, self.z * o, self.w * o)
            else
                return tp(self.x * o.x, self.y * o.y, self.z * o.z,
                    self.w * o.w)
            end
        end,
        div_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x / o, self.y / o, self.z / o, self.w / o)
            else
                return tp(self.x / o.x, self.y / o.y, self.z / o.z,
                    self.w / o.w)
            end
        end,
        add_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x + o, self.y + o, self.z + o, self.w + o)
            else
                return tp(self.x + o.x, self.y + o.y, self.z + o.z,
                    self.w + o.w)
            end
        end,
        sub_new = function(self, o)
            local tp = ffi_typeof(self)
            if type(o) == "number" then
                return tp(self.x - o, self.y - o, self.z - o, self.w - o)
            else
                return tp(self.x - o.x, self.y - o.y, self.z - o.z,
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

return M
