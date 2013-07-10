--[[! File: lua/core/engine/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (Engine system).
]]

local log = require("core.logger")

log.log(log.DEBUG, ":::: Cubescript utilities.")
require("core.engine.cubescript")

log.log(log.DEBUG, ":::: Input.")
require("core.engine.input")

log.log(log.DEBUG, ":::: Camera.")
require("core.engine.camera")

log.log(log.DEBUG, ":::: Sound.")
require("core.engine.sound")

log.log(log.DEBUG, ":::: Models.")
require("core.engine.model")

log.log(log.DEBUG, ":::: Lights.")
require("core.engine.lights")

log.log(log.DEBUG, ":::: Decals.")
require("core.engine.decals")

log.log(log.DEBUG, ":::: Particles.")
require("core.engine.particles")

log.log(log.DEBUG, ":::: Editing.")
require("core.engine.edit")
