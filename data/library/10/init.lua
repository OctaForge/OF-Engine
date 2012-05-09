--[[!
    File: library/10/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This loads core modules of 1.0 extension library (plugin system,
        game manager, event system and health system).

    Section: Extension library 1.0 initialization
]]

log(DEBUG, "Initializing library version %(1)s" % { std.library.current })

log(DEBUG, ":: Plugin system.")
std.library.include("plugins")

log(DEBUG, ":: Game manager.")
std.library.include("game_manager")

log(DEBUG, ":: Events.")
std.library.include("events")

log(DEBUG, ":: Health.")
std.library.include("health")

EVAR.uwambient = 1
