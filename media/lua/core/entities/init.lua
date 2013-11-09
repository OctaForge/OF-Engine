--[[! File: lua/core/entities/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        OctaForge standard library loader (Entity system).
]]

local log = require("core.logger")

log.log(log.DEBUG, ":::: State variables.")
require("core.entities.svars")

log.log(log.DEBUG, ":::: Entities.")
require("core.entities.ents")

log.log(log.DEBUG, ":::: Entities: basic set.")
require("core.entities.ents_basic")
