-- OctaForge empty map
-- author: q66 <quaker66@gmail.com>

-- Use library version "10"
library.use("10")

-- default skybox
skybox = "textures/sky/remus/sky01"

-- use drawing mode on empty map
library.include("mapscripts.drawing")
--library.include("mapscripts.sine_curve")
--library.include("mapscripts.sine_flower")

-- this is how you initialize game manager
game_manager.setup({
    game_manager.manager_plugins.messages,
    game_manager.manager_plugins.event_list
})
get_scoreboard_text = game_manager.get_scoreboard_text

if SERVER then
    local entities = utility.readfile("./entities.json")
    entity_store.load_entities(entities)
end
