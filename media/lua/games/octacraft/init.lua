--[[! File: lua/games/octacraft/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        A main file for the "octacraft" test game. It's meant to be a
        Minecraft inspired demo with procedural world generation.
]]

local log = require("core.logger")

local input = require("core.engine.input")
local inputev = require("core.events.input")
local edit = require("core.engine.edit")
local cs = require("core.engine.cubescript")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local geom = require("core.lua.geom")

local game_manager = require("extra.game_manager")
local health = require("extra.health")

local Player = ents.Player

--[[! Class: Game_Player
    This serves as a base for our player.
]]
local Game_Player = Player:clone {
    name = "Game_Player",
}

ents.register_class(Game_Player, {
    game_manager.player_plugin,
    health.player_plugin
})
ents.register_class(ents.Obstacle, { health.deadly_area_plugin },
    "Deadly_Area")

local cube_size = 3

if not SERVER then
    inputev.set_event("click", function(btn, down, x, y, z, ent, cx, cy)
        if ent and ent.click then
            return ent:click(btn, down, x, y, z, cx, cy)
        end
        if not down then return end
        local pl = ents.get_player()
        local tg = geom.Vec3(x, y, z)
        local pos = pl:get_attr("position"):copy()
        pos.z += pl:get_attr("eye_height")
        local bf
        if btn == 1 then
            tg:add((tg - pos):normalize())
            bf = edit.delete_cube
        else
            tg:sub((tg - pos):normalize())
            bf = edit.create_cube
        end
        bf(tg.x >> cube_size << cube_size,
           tg.y >> cube_size << cube_size,
           tg.z >> cube_size << cube_size, 1 << cube_size)
    end)
end

cs.var_set("player_class", "Game_Player")
