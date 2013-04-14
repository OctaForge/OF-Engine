--[[! File: library/core/std/events/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (Event system).
]]

#log(DEBUG, ":::: Frame handling.")
frame = require("std.events.frame")

#log(DEBUG, ":::: Signal system.")
signal = require("std.events.signal")

#log(DEBUG, ":::: Action system.")
actions = require("std.events.actions")

#log(DEBUG, ":::: World events.")
require("std.events.world")
