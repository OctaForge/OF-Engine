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
    return type(v)
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
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local setmt = setmetatable
local unpack = unpack

local ArrayMT = {
    __metatable = false,

    __tostring = function(self)
        return "array(" .. self.__size .. ")"
    end,

    __index = {
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
            tinsert(self, n, v)
            if n >= size then
                self.__size = n + 1
            else
                self.__size = size + 1
            end
        end,

        remove = function(self, n)
            local size = self.__size
            if n < 0 or n >= size then
                error("attempt to remove an invalid index", 2)
            end
            local v = tremove(self, n)
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

        each = function(self)
            return self.__array_iter, self, -1
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

        length = function(self)
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
        end
    }
}

M.array = function(...)
    return setmt({ __size = select("#", ...),
        [0] = select(1, ...), select(2, ...)
    }, ArrayMT)
end

return M
