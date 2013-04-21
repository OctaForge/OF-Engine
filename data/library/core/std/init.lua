--[[! File: library/core/std/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library general loader.
]]

#log(DEBUG, ":: Lua extensions.")
require("std.lua")

#log(DEBUG, ":: Network system.")
require("std.network")

#log(DEBUG, ":: Event system.")
require("std.events")

if CLIENT then

#log(DEBUG, ":: GUI system.")
require("std.gui")
end

#log(DEBUG, ":: Entity system.")
require("std.entities")

#log(DEBUG, ":: Engine system.")
require("std.engine")
