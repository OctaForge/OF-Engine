--[[! File: lua/core/lua/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (Lua extensions).
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
require("core.lua.var")

#log(DEBUG, ":::: Type conversions.")
require("core.lua.conv")

#log(DEBUG, ":::: Utilities.")
require("core.lua.util")

#log(DEBUG, ":::: Environment support.")
require("core.lua.env")
