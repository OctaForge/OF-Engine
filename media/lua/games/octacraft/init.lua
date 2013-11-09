--[[! File: lua/games/octacraft/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        A main file for the "octacraft" test game. It's meant to be a
        Minecraft inspired demo with procedural world generation.
]]

local log = require("core.logger")

local input = require("core.engine.input")
local inputev = require("core.events.input")
local actions = require("core.events.actions")
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

cs.var_set("player_class", "Game_Player")

if SERVER then return end

local Mouse_Action = actions.Action:clone {
    name = "Mouse_Action",
    allow_multiple = false,
    block_size = 3,

    __start = function(self)
        self.counter = 0
        self:try_block()
    end,

    __run = function(self, millis)
        local cnt = self.counter
        cnt += millis
        local btn = self.button
        if (btn == 1 and cnt >= 300) or (btn != 1 and cnt >= 100) then
            self.counter = 0
            self:try_block()
        else
            self.counter = cnt
        end
        return false
    end,

    try_block = function(self)
        local pl = self.player
        local tg = input.get_target_position()
        local pos = pl:get_attr("position"):copy()
        pos.z += pl:get_attr("eye_height")
        local bf
        if self.button == 1 then
            tg:add((tg - pos):normalize())
            bf = edit.cube_delete
        else
            tg:sub((tg - pos):normalize())
            bf = edit.cube_create
        end
        local bsize = self.block_size
        bf(tg.x >> bsize << bsize, tg.y >> bsize << bsize,
           tg.z >> bsize << bsize, 1 << bsize)
    end
}

inputev.set_event("click", function(btn, down, x, y, z, ent, cx, cy)
    if ent and ent.click then
        return ent:click(btn, down, x, y, z, cx, cy)
    end
    local gm = game_manager.get()
    if down then
        local pl = ents.get_player()
        local mact = Mouse_Action()
        mact.button = btn
        mact.player = pl
        gm.mouse_action = mact
        gm:queue_action(mact)
    else
        gm.mouse_action:cancel()
        gm.mouse_action = nil
    end
end)
