--[[
    OctaScript runtime

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.
]]

local M = {}

local bit = require("bit")
local ffi = require("ffi")

M.bit_bnot    = bit.bnot
M.bit_bor     = bit.bor
M.bit_band    = bit.band
M.bit_bxor    = bit.bxor
M.bit_lshift  = bit.lshift
M.bit_rshift  = bit.rshift
M.bit_arshift = bit.arshift

local type = type
local error = error

M.type = function(v)
    if v == nil then
        return "undef"
    end
    local tp = type(v)
    if tp == "table" and v.__OCT_actually_is_array then
        -- this ugly hack until we move to 2.1 where debug.getmetatable is JIT'd
        return "array"
    end
    return tp
end

M.pcall = pcall
M.xpcall = xpcall
M.error = error

M.null = ffi.cast("void*", 0)

local mt = debug.getmetatable(M.null)

local prev_eq = mt.__eq

mt.__eq = function(self, o)
    if type(o) ~= "cdata" then
        return false
    end
    return prev_eq(self, o)
end

debug.setmetatable(nil, {
    __tostring = function() return "undef" end
})

M.print = print

M.env = { __rt_core = M }

-- Arrays

local select = select
local tconcat = table.concat
local setmt = setmetatable
local unpack = unpack
local round = math.round

local ArrayMT
ArrayMT = {
    __metatable = false,

    __tostring = function(self)
        return "array(" .. self.__size .. ")"
    end,

    __concat = function(self, b)
        return self:merge(b)
    end,

    __index = {
        __OCT_actually_is_array = true,

        push = function(self, x)
            local size = self.__size
            self[size] = x
            self.__size = size + 1
        end,

        pop = function(self)
            local size = self.__size - 1
            if size < 0 then
                return nil
            end
            local v = self[size]
            self[size] = nil
            self.__size = size
            return v
        end,

        insert = function(self, n, v)
            if n < 0 then
                error("attempt to insert into negative index", 2)
            end
            local size = self.__size
            if n < size then
                for i = self.__size - 1, n, -1 do
                    self[i + 1] = self[i]
                end
                self.__size = size + 1
            else
                self.__size = n + 1
            end
            self[n] = v
        end,

        remove = function(self, n)
            local size = self.__size
            if n < 0 or n >= size then
                error("attempt to remove an invalid index", 2)
            end
            local v = self[n]
            for i = n + 1, size - 1 do
                self[i - 1] = self[i]
            end
            self[size - 1] = nil
            self.__size = size - 1
            return v
        end,

        __array_iter = function(self, i)
            local j = i + 1
            if j < self.__size then
                return j, self[j]
            end
            return nil
        end,

        __array_iter_r = function(self, i)
            local j = i - 1
            if j >= 0 then
                return j, self[j]
            end
            return nil
        end,

        each = function(self)
            return self.__array_iter, self, -1
        end,

        each_r = function(self)
            return self.__array_iter_r, self, self.__size
        end,

        resize = function(self, n, v)
            if n < 0 then
                error("attempt to resize an array to negative size", 2)
            end
            local size = self.__size
            if n == size then
                return
            end
            if n < size then
                for i = n, size - 1 do
                    self[i] = nil
                end
            elseif v ~= nil then
                for i = size, n - 1 do
                    self[i] = v
                end
            end
            self.__size = n
        end,

        first = function(self)
            return self[0]
        end,

        last = function(self)
            return self[self.__size - 1]
        end,

        rest = function(self)
            local sz = self.__size - 1
            if sz < 0 then
                error("attempt to get tail of an empty array", 2)
            elseif sz == 0 then
                return setmt({ __size = 0 }, ArrayMT)
            end
            local r = { __size = sz }
            for i = 1, sz do
                r[i - 1] = self[i]
            end
            return setmt(r, ArrayMT)
        end,

        len = function(self)
            return self.__size
        end,

        empty = function(self)
            return self.__size == 0
        end,

        concat = function(self, delim, i, j)
            if i and i < 0 then
                error("invalid lower bound for 'concat'", 2)
            end
            local size = self.__size
            if j and j > size then
                error("invalid upper bound for 'concat'", 2)
            end
            return tconcat(self, delim, i or 0, j and (j - 1) or (size - 1))
        end,

        unpack = function(self, i, j)
            if i and i < 0 then
                error("invalid lower bound for 'unpack'", 2)
            end
            local size = self.__size
            if j and j > size then
                error("invalid upper bound for 'unpack'", 2)
            end
            return unpack(self, i or 0, j and (j - 1) or (size - 1))
        end,

        copy = function(self)
            local sz = self.__size
            local r = { __size = sz }
            for i = 0, sz - 1 do
                r[i] = self[i]
            end
            return setmt(r, ArrayMT)
        end,

        merge = function(self, o)
            local sz = self.__size
            local oz = o.__size
            local r = { __size = sz + oz }
            for i = 0, sz - 1 do
                r[i] = self[i]
            end
            for i = 0, oz - 1 do
                r[sz + i] = o[i]
            end
            return setmt(r, ArrayMT)
        end,

        slice = function(self, i, j, step)
            i = i or 0
            if i < 0 or i >= self.__size then
                error("invalid slice range start", 2)
            end
            if j and (j <= 0 or j >= self.__size) then
                error("invalid slice range end", 2)
            end
            j = (j or self.__size) - 1
            local r = {}
            local idx = 0
            if step < 0 then i, j = j, i end
            for a = i, j, step or 1 do
                r[idx] = self[a]
                idx = idx + 1
            end
            r.__size = idx
            return setmt(r, ArrayMT)
        end
    }
}

M.array_mt = ArrayMT

M.array = function(t, size, ...)
    if not ... then
        t.__size = size
        return setmt(t, ArrayMT)
    end
    local n = select("#", ...)
    t.__size = size + n
    for i = 1, n do
        t[size + i - 1] = select(i, ...)
    end
    return setmt(t, ArrayMT)
end

return M
