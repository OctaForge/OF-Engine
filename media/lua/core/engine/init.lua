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

#log(DEBUG, ":::: Engine variables.")
require("core.engine.var")

#log(DEBUG, ":::: Input.")
require("core.engine.input")

#log(DEBUG, ":::: Camera.")
require("core.engine.camera")

#log(DEBUG, ":::: Sound.")
require("core.engine.sound")

#log(DEBUG, ":::: Models.")
require("core.engine.model")

#log(DEBUG, ":::: Lights.")
require("core.engine.lights")

#log(DEBUG, ":::: Decals.")
require("core.engine.decals")

#log(DEBUG, ":::: Particles.")
require("core.engine.particles")

#log(DEBUG, ":::: Editing.")
require("core.engine.edit")
