--[[! File: lua/core/events/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        OctaForge standard library loader (Event system).
]]

local log = require("core.logger")

log.log(log.DEBUG, ":::: Frame handling.")
require("core.events.frame")

log.log(log.DEBUG, ":::: Signal system.")
require("core.events.signal")

log.log(log.DEBUG, ":::: Action system.")
require("core.events.actions")

log.log(log.DEBUG, ":::: World events.")
require("core.events.world")

log.log(log.DEBUG, ":::: Input events.")
require("core.events.input")
