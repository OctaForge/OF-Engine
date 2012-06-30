-- OctaForge empty map
-- author: q66 <quaker66@gmail.com>

-- Use library version "10"
library.use("10")

-- more modules
library.include("cutscenes")
library.include("firing")
library.include("projectiles")
library.include("mapelements.jump_pad")
library.include("mapelements.teleporter")
library.include("mapelements.dynamic_lights")
library.include("mapelements.detection_areas")
library.include("mapelements.world_areas")
library.include("mapelements.world_notices")
library.include("mapelements.world_sequences")
library.include("platformer")
library.include("guns.chaingun")
library.include("guns.rocket_launcher")

-- rain
library.include("weather_effects")

-- default skybox
EVAR.skybox = "textures/sky/remus/sky01"

-- use drawing mode on empty map
library.include("mapscripts.drawing")
--library.include("mapscripts.sine_curve")
--library.include("mapscripts.sine_flower")

-- this is how you initialize game manager
game_manager.setup({
    game_manager.manager_plugins.messages,
    game_manager.manager_plugins.event_list,
    projectiles.plugin,
    events.actions_parallel_plugin
})
get_scoreboard_text = game_manager.get_scoreboard_text

--[[
-- enable for bot player
entity_classes.register(plugins.bake(
    character.player, {
        health.plugin,
        {
            init = function(self)
                self.model_name = "player"
            end
        }
    }, "bot_player"
), "fpsent")
]]

-- this function will run on server only (condition inside it)
-- it loads the entities into server storage and sends to clients
entity_store.load_entities()

-- enable for bot player
--if SERVER then
--    edit.add_npc("bot_player")
--end
