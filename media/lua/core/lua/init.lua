--[[! File: lua/core/lua/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (Lua extensions).

        Exposes "min", "max", "clamp", "abs", "floor", "ceil", "round" and the
        bitwise functions from math and the util module into globals, as they
        are widely used and the default syntax is way too verbose. The bitwise
        functions are globally named "bitlsh", "bitrsh", "bitor", "bitand" and
        "bitnot".
]]

#log(DEBUG, ":::: Strict mode.")
require("core.lua.strict")

#log(DEBUG, ":::: Lua extensions: string")
require("core.lua.string")

#log(DEBUG, ":::: Lua extensions: table")
require("core.lua.table")

#log(DEBUG, ":::: Lua extensions: math")
require("core.lua.math")

#log(DEBUG, ":::: Engine variables.")
var = require("core.lua.var")

#log(DEBUG, ":::: Type conversions.")
conv = require("core.lua.conv")

#log(DEBUG, ":::: Library.")
library = require("core.lua.library")

#log(DEBUG, ":::: Utilities.")
util = require("core.lua.util")

#log(DEBUG, ":::: Environment support.")
env = require("core.lua.env")

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
bitxor = math.bxor
bitand = math.band

bitnot = math.bnot

match   = util.match
switch  = util.switch
case    = util.case
default = util.default

assert_param = util.assert_param
