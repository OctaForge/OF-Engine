--[[! File: library/core/std/lua/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (Lua extensions).

        Exposes "min", "max", "clamp", "abs", "floor", "ceil", "round" and the
        bitwise functions from std.math and "switch", "case", "default" and
        "match" from std.util into globals, as they are widely used and the
        default syntax is way too verbose. The bitwise functions are globally
        named "bitlsh", "bitrsh", "bitor", "bitand" and "bitnot".
]]

log(DEBUG, ":::: Safe FFI.")
std["ffi"] = require("std.lua.ffi")

log(DEBUG, ":::: Engine variables.")
std["var"] = require("std.lua.var")

log(DEBUG, ":::: Class system.")
std["class"] = require("std.lua.class")

log(DEBUG, ":::: Lua extensions: table")
require("std.lua.table")
std["table"] = _G["table"]

log(DEBUG, ":::: Lua extensions: string")
require("std.lua.string")
std["string"] = _G["string"]

log(DEBUG, ":::: Lua extensions: math")
require("std.lua.math")
std["math"] = _G["math"]

std["debug"] = _G["debug"]

log(DEBUG, ":::: Type conversions.")
std["conv"] = require("std.lua.conv")

log(DEBUG, ":::: JSON.")
std["json"] = require("std.lua.json")

log(DEBUG, ":::: Library.")
std["library"] = require("std.lua.library")

log(DEBUG, ":::: Utilities.")
std["util"] = require("std.lua.util")

-- Useful functionality exposed into globals

max   = math.max
min   = math.min
abs   = math.abs
floor = math.floor
ceil  = math.ceil
round = math.round
clamp = math.clamp

bitlsh  = math.lsh
bitrsh  = math.rsh

bitor  = math.bor
bitand = math.band

bitnot = math.bnot

match   = std.util.match
switch  = std.util.switch
case    = std.util.case
default = std.util.default
