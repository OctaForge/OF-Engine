--[[!
    File: lua/10/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This loads core modules of 1.0 extension library (plugin system,
        game manager, event system and health system).

    Section: Extension library 1.0 initialization
]]

#log(DEBUG, "Initializing library version 1.0")

#log(DEBUG, ":: Plugin system.")
require("10.plugins")

#log(DEBUG, ":: Game manager.")
require("10.game_manager")

#log(DEBUG, ":: Health.")
require("10.health")
