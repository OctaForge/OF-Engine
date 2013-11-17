-- OctaForge test map
-- author: q66 <quaker66@gmail.com>

local ents = require("core.entities.ents")

if not SERVER then
    require("core.engine.cubescript").execute [[
         loopfiles file media/texture/nobiax tex [ texload [nobiax/@file] ]
    ]]
end

local game_manager = require("extra.game_manager")

require("extra.entities.teleporters")
require("extra.entities.lights")
require("extra.entities.particles")

-- drawing game
require("games.drawing")

-- this is how you initialize game manager
game_manager.setup()

-- this function will run on server only (condition inside it)
-- it loads the entities into server storage and sends to clients
ents.load()
