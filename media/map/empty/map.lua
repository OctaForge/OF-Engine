-- OctaForge empty map
-- author: q66 <quaker66@gmail.com>

local ents = require("core.entities.ents")

-- Use library version "10"
require("10")

-- more modules
require("10.firing")
require("10.projectiles")
require("10.mapelements.jump_pad")
require("10.mapelements.teleporter")
require("10.guns.chaingun")
require("10.guns.rocket_launcher")

require("extra.entities.lights")

-- default skybox
require("core.lua.var").set("skybox", "remus/sky01")

-- use drawing mode on empty map
require("10.mapscripts.drawing")

-- this is how you initialize game manager
game_manager.setup({ projectiles.plugin })

-- this function will run on server only (condition inside it)
-- it loads the entities into server storage and sends to clients
ents.load()
