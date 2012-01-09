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

logging.log(logging.DEBUG, ":::: Class system.")

std["class"] = require("std.lua.class")

logging.log(logging.DEBUG, ":::: Lua extensions: table")
require("std.lua.table")

logging.log(logging.DEBUG, ":::: Lua extensions: string")
require("std.lua.string")

logging.log(logging.DEBUG, ":::: Lua extensions: math")
require("std.lua.math")

std["table" ] = _G["table" ]
std["string"] = _G["string"]
std["math"  ] = _G["math"  ]
std["debug" ] = _G["debug" ]

logging.log(logging.DEBUG, ":::: Type conversion module.")
std["conv"] = require("std.lua.conv")
