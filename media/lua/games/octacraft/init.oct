--[[!<
    A main file for the "octacraft" test game. It's meant to be a
    Minecraft inspired demo with procedural world generation.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

var log = require("core.logger")

var input = require("core.engine.input")
var inputev = require("core.events.input")
var actions = require("core.events.actions")
var edit = require("core.engine.edit")
var cs = require("core.engine.cubescript")
var signal = require("core.events.signal")
var svars = require("core.entities.svars")
var ents = require("core.entities.ents")
var geom = require("core.lua.geom")

var game_manager = require("extra.game_manager")
var day_manager = require("extra.day_manager")
var health = require("extra.health")

var Player = ents.Player

--[[! Object: GamePlayer
    This serves as a base for our player.
]]
var GamePlayer = Player:clone {
    name = "GamePlayer",
}

ents.register_prototype(GamePlayer, {
    game_manager.player_plugin,
    health.player_plugin,
    health.plugins.player_hud,
    health.plugins.player_off_map,
    health.plugins.player_in_deadly_material
})
ents.register_prototype(ents.Obstacle, { health.plugins.area },
    "HealthArea")

day_manager.setup({ day_manager.plugins.day_night })

@[server] do
    ents.set_player_prototype("GamePlayer")
    return
end

var MouseAction = actions.Action:clone {
    name = "MouseAction",
    allow_multiple = false,
    block_size = 4,

    __start = function(self)
        self.counter = 0
        self:try_block()
    end,

    __run = function(self, millis)
        var cnt = self.counter
        cnt += millis
        var btn = self.button
        if (btn == 1 and cnt >= 600) or (btn != 1 and cnt >= 200) do
            self.counter = 0
            self:try_block()
        else
            self.counter = cnt
        end
        return false
    end,

    try_block = function(self)
        var pl = self.player
        var tg = input.get_target_position()
        var pos = pl:get_attr("position"):copy()
        pos.z += pl:get_attr("eye_height")
        var bf
        if self.button == 1 do
            tg:add((tg - pos):normalize())
            bf = edit.cube_delete
        else
            tg:sub((tg - pos):normalize())
            bf = edit.cube_create
        end
        var bsize = self.block_size
        bf(tg.x >> bsize << bsize, tg.y >> bsize << bsize,
           tg.z >> bsize << bsize, 1 << bsize)
    end
}

inputev.set_event("click", function(btn, down, x, y, z, uid, cx, cy)
    var ent = ents.get(uid)
    if ent and ent.click do
        return ent:click(btn, down, x, y, z, cx, cy)
    end
    var gm = game_manager.get()
    if down do
        var pl = ents.get_player()
        var mact = MouseAction()
        mact.button = btn
        mact.player = pl
        gm.mouse_action = mact
        gm:enqueue_action(mact)
    else
        gm.mouse_action:cancel()
        gm.mouse_action = nil
    end
end)
