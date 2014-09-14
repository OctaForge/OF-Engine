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

M.type = type
M.import = require

M.pcall = pcall
M.xpcall = xpcall
M.error = error

local type = type

M.null = ffi.cast("void*", 0)

local mt = debug.getmetatable(M.null)

local prev_eq = mt.__eq
mt.__eq = function(self, o)
    if type(o) ~= "cdata" then
        return false
    end
    return prev_eq(self, o)
end

return M
