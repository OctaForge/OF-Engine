-- OctaForge empty map
-- author: q66 <quaker66@gmail.com>

-- Use library version "10"
std.library.use("10")

-- more modules
std.library.include("cutscenes")
std.library.include("firing")
std.library.include("projectiles")
std.library.include("mapelements.jump_pad")
std.library.include("mapelements.teleporter")
std.library.include("mapelements.dynamic_lights")
std.library.include("mapelements.detection_areas")
std.library.include("mapelements.world_areas")
std.library.include("mapelements.world_notices")
std.library.include("mapelements.world_sequences")
std.library.include("platformer")
std.library.include("guns.chaingun")
std.library.include("guns.rocket_launcher")

-- rain
std.library.include("weather_effects")

-- default skybox
EVAR.skybox = "textures/sky/spiney/bluecloud"

-- use drawing mode on empty map
std.library.include("mapscripts.drawing")
--std.library.include("mapscripts.sine_curve")
--std.library.include("mapscripts.sine_flower")

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
