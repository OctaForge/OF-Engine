--[[! File: lua/core/gui/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        OctaForge standard library loader (GUI system).
]]

local log = require("core.logger")

log.log(log.DEBUG, ":::: Core UI implementation.")

require("core.gui.core")
require("core.gui.core_containers")
require("core.gui.core_spacers")
require("core.gui.core_primitives")
require("core.gui.core_scrollers")
require("core.gui.core_sliders")
require("core.gui.core_buttons")
require("core.gui.core_editors")
require("core.gui.core_misc")

require("core.gui.default")
