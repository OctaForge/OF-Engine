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

logging.log(logging.DEBUG, "Initializing library version %(1)s" % { library.current })

logging.log(logging.DEBUG, ":: Plugin system.")
library.include("plugins")

logging.log(logging.DEBUG, ":: Game manager.")
library.include("game_manager")

logging.log(logging.DEBUG, ":: Events.")
library.include("events")

logging.log(logging.DEBUG, ":: Health.")
library.include("health")

uwambient = 1
