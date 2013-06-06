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

#log(DEBUG, "Initializing library version " .. library.current)

#log(DEBUG, ":: Plugin system.")
library.include("plugins")

#log(DEBUG, ":: Game manager.")
library.include("game_manager")

#log(DEBUG, ":: Extra events.")
library.include("extraevents")

#log(DEBUG, ":: Health.")
library.include("health")

_V.uwambient = 1
