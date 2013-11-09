--[[! File: lua/core/lua/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        OctaForge standard library loader (Lua extensions).
]]

local log = require("core.logger")

log.log(log.DEBUG, ":::: Lua extensions: string")
require("core.lua.string")

log.log(log.DEBUG, ":::: Lua extensions: table")
require("core.lua.table")

log.log(log.DEBUG, ":::: Lua extensions: math")
require("core.lua.math")

log.log(log.DEBUG, ":::: Lua extensions: geom")
require("core.lua.geom")

log.log(log.DEBUG, ":::: Type conversions.")
require("core.lua.conv")

log.log(log.DEBUG, ":::: Environment support.")
require("core.lua.env")
