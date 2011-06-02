-- OctaForge scripting library version 1.0
-- Contains scripts compatible with OF API version 1.0

logging.log(logging.DEBUG, "Initializing library version %(1)s" % { library.current })

logging.log(logging.DEBUG, ":: Plugin system.")
library.include("plugins")
logging.log(logging.DEBUG, ":: Game manager.")
library.include("game_manager")
logging.log(logging.DEBUG, ":: Events.")
library.include("events")

-- enable underwater ambience
uwambient = 1
