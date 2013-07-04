-- OctaForge empty map
-- author: q66 <quaker66@gmail.com>

local ents = require("core.entities.ents")

local game_manager = require("extra.game_manager")

require("extra.entities.teleporters")
require("extra.entities.lights")
require("extra.entities.particles")

-- default skybox
require("core.lua.var").set("skybox", "remus/sky01")

-- use drawing mode on empty map
require("extra.mapscripts.drawing")

-- this is how you initialize game manager
game_manager.setup()

-- this function will run on server only (condition inside it)
-- it loads the entities into server storage and sends to clients
ents.load()
