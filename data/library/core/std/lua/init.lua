--[[! File: library/core/std/lua/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (Lua extensions).
]]

log(DEBUG, ":::: Class system.")
std["class"] = require("std.lua.class")

log(DEBUG, ":::: Lua extensions: table")
require("std.lua.table")

log(DEBUG, ":::: Lua extensions: string")
require("std.lua.string")

log(DEBUG, ":::: Lua extensions: math")
require("std.lua.math")

std["table" ] = _G["table" ]
std["string"] = _G["string"]
std["math"  ] = _G["math"  ]
std["debug" ] = _G["debug" ]

log(DEBUG, ":::: Type conversions.")
std["conv"] = require("std.lua.conv")

log(DEBUG, ":::: JSON.")
std["json"] = require("std.lua.json")
