-- OctaForge empty map
-- author: q66 <quaker66@gmail.com>

local ents = require("core.entities.ents")

-- Use library version "10"
require("10")

-- more modules
require("10.cutscenes")
require("10.firing")
require("10.projectiles")
require("10.mapelements.jump_pad")
require("10.mapelements.teleporter")
require("10.platformer")
require("10.guns.chaingun")
require("10.guns.rocket_launcher")

require("extra.entities.lights")

-- default skybox
require("core.lua.var").set("skybox", "remus/sky01")

-- use drawing mode on empty map
require("10.mapscripts.drawing")
--require("10.mapscripts.sine_curve")
--require("10.mapscripts.sine_flower")

-- this is how you initialize game manager
game_manager.setup({
    game_manager.manager_plugins.messages,
    game_manager.manager_plugins.event_list,
    projectiles.plugin,
    extraevents.actions_parallel_plugin
})
get_scoreboard_text = game_manager.get_scoreboard_text

--[[
-- enable for bot player
entity_classes.register(plugins.bake(
    character.player, {
        health.plugin,
        {
            init = function(self)
                self:set_attr("model_name", "player")
            end
        }
    }, "bot_player"
), "fpsent")
]]

-- this function will run on server only (condition inside it)
-- it loads the entities into server storage and sends to clients
ents.load()

-- enable for bot player
--if SERVER then
--    edit.add_npc("bot_player")
--end
