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

return M
