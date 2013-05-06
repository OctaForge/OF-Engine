--[[! File: library/core/gui/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OctaForge standard library loader (GUI system).
]]

#log(DEBUG, ":::: Core UI implementation.")

gui = {}
require("gui.core")
require("gui.core_containers")
require("gui.core_spacers")
require("gui.core_primitives")
require("gui.core_scrollers")
require("gui.core_sliders")
require("gui.core_buttons")
require("gui.core_editors")
require("gui.core_misc")

require("gui.default")
