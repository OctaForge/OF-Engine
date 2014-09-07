--[[!<
    A game manager module that manages spawning and teams, with the
    possibility of various plugins.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

--! Module: game_manager
var M = {}

var log = require("core.logger")

var signal = require("core.events.signal")
var svars = require("core.entities.svars")
var ents = require("core.entities.ents")
var connect, emit = signal.connect, signal.emit

var get

--[[!
    Player-side game manager functionality. If you want to use the game
    game manager, you need to set up your player entity prototype with this
    plugin.

    Properties:
        - team - the player's current team. Defaults to an empty string.
        - spawn_stage - the current spawn stage the player is going through.
]]
M.player_plugin = {
    __properties = {
        team        = svars.StateString(),
        spawn_stage = svars.StateInteger()
    },

    __init_svars = function(self)
        self:set_attr("team", "")
    end,

    __activate = function(self)
        connect(self, "spawn_stage,changed", self.game_manager_on_spawn_stage)
        @[server] do
            get():pick_team(self)
            connect(self, "pre_deactivate", function(self)
                get():leave_team(self)
            end)
            self:game_manager_respawn()
        else
            connect(self, "client,respawn", function(self)
                get():place_player(self)
            end)
        end
    end,

    game_manager_respawn = function(self)
        self:set_attr("spawn_stage", 1)
    end,

    game_manager_spawn_stage_0 = function(self, auid) end,

    game_manager_spawn_stage_1 = @[not server,function(self, auid)
        self:set_attr("spawn_stage", 2)
    end,function(self, auid) end],

    game_manager_spawn_stage_2 = @[server,function(self, auid)
        if auid == self.uid do
            self:set_attr("spawn_stage", 3)
        end
        self:cancel_sdata_update()
    end,function(self, auid) end],

    game_manager_spawn_stage_3 = @[not server,function(self, auid)
        if self == ents.get_player() do
            emit(self, "client,respawn")
            self:set_attr("spawn_stage", 4)
        end
    end,function(self, auid) end],

    game_manager_spawn_stage_4 = @[server,function(self, auid)
        self:set_attr("can_move", true)
        self:set_attr("spawn_stage", 0)
        self:cancel_sdata_update()
    end,function(self, auid) end],

    game_manager_on_spawn_stage = function(self, stage, auid)
        self["game_manager_spawn_stage_" .. stage](self, auid)
    end
}

var pairs, ipairs = pairs, ipairs
var tremove = table.remove
var rand, floor = math.random, math.floor

var Entity = ents.Entity

var GameManager = Entity:clone {
    name = "GameManager",

    __properties = {
        team_data = svars.StateTable()
    },

    __activate = @[server,function(self)
        Entity.__activate(self)
        self:add_tag("game_manager")
        self.teams = {}
    end],

    get_players = @[server,function(self)
        var players = {}
        for i, team in pairs(self.teams) do
            for i, v in ipairs(team.player_list) do
                players[#players + 1] = v
            end
        end
        return players
    end],

    start_game = @[server,function(self)
        var players = self:get_players()

        for i, team in pairs(self.teams) do
            team.player_list = {}
        end

        while #players > 0 do
            var pl = tremove(players, floor(rand() * #players))
            self:pick_team(p, false)
        end
        self:sync_team_data()

        for i, player in pairs(self:get_players()) do
            player:respawn()
        end

        emit(self, "game,start")
        self.game_running = true
    end],

    end_game = @[server,function(self)
        self.game_running = false
        emit(self, "game,end")
    end],

    sync_team_data = @[server,function(self)
        if not self.deactivated do
            self:set_attr("team_data", self.teams)
        end
    end],

    pick_team = @[server,function(self, player, sync)
    end],

    set_player_team = @[server,function(self, player, team, sync)
    end],

    leave_team = @[server,function(self, player, sync)
    end],

    place_player = function(self, player)
        var team = player:get_attr("team")
        var st
        if team == "" do
            st = "player_start"
        else
            st = "player_start_" .. team
        end
        var starts = ents.get_by_tag(st)
        if starts and #starts > 0 do
            starts[rand(1, #starts)]:place_entity(player)
            return
        end
        log.log(log.WARNING, ('player start not found (\"%s\"), '
            .. 'placing player elsewhere'):format(st))
        player:set_attr("position", { 512, 512, 571 })
    end,

    set_local_animation = function(self) end,
    set_local_animation_flags = function(self) end
}

var assert = assert

var gameman

--! Gets the current game manager instance.
M.get = function()
    if not gameman do
        gameman = ents.get_by_prototype("GameManager")[1]
    end
    assert(gameman)
    return gameman
end
get = M.get

--[[!
    Sets up the game manager. You should call this in your mapscript before
    {{$ents.load}}. On the server, this returns the entity.
]]
M.setup = function(plugins)
    ents.register_prototype(GameManager, plugins)
    @[server] do
        gameman = ents.new("GameManager")
        return gameman
    end
end

return M
