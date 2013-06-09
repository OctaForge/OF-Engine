--[[! File: lua/core/events/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (Event system).
]]

#log(DEBUG, ":::: Frame handling.")
require("core.events.frame")

#log(DEBUG, ":::: Signal system.")
require("core.events.signal")

#log(DEBUG, ":::: Action system.")
require("core.events.actions")

#log(DEBUG, ":::: World events.")
require("core.events.world")

#log(DEBUG, ":::: Input events.")
require("core.events.input")
