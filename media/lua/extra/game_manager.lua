--[[!<
    A game manager module that manages spawning and teams, with the
    possibility of various plugins.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

--! Module: game_manager
local M = {}

local log = require("core.logger")

local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local connect, emit = signal.connect, signal.emit

local get

--[[!
    Player-side game manager functionality. If you want to use the game
    game manager, you need to set up your player entity class with this
    plugin.

    Properties:
        - team - the player's current team. Defaults to an empty string.
        - spawn_stage - the current spawn stage the player is going through.
]]
M.player_plugin = {
    __properties = {
        team        = svars.State_String(),
        spawn_stage = svars.State_Integer()
    },

    __init_svars = function(self)
        self:set_attr("team", "")
    end,

    __activate = function(self)
        connect(self, "spawn_stage_changed", self.game_manager_on_spawn_stage)
        if SERVER then
            get():pick_team(self)
            connect(self, "pre_deactivate", function(self)
                get():leave_team(self)
            end)
            self:game_manager_respawn()
        else
            connect(self, "client_respawn", function(self)
                get():place_player(self)
            end)
        end
    end,

    game_manager_respawn = function(self)
        self:set_attr("spawn_stage", 1)
    end,

    game_manager_spawn_stage_0 = function(self, auid) end,

    game_manager_spawn_stage_1 = (not SERVER) and function(self, auid)
        self:set_attr("spawn_stage", 2)
    end or function(self, auid) end,

    game_manager_spawn_stage_2 = (SERVER) and function(self, auid)
        if auid == self.uid then
            self:set_attr("spawn_stage", 3)
        end
        self:cancel_sdata_update()
    end or function(self, auid) end,

    game_manager_spawn_stage_3 = (not SERVER) and function(self, auid)
        if self == ents.get_player() then
            emit(self, "client_respawn")
            self:set_attr("spawn_stage", 4)
        end
    end or function(self, auid) end,

    game_manager_spawn_stage_4 = (SERVER) and function(self, auid)
        self:set_attr("can_move", true)
        self:set_attr("spawn_stage", 0)
        self:cancel_sdata_update()
    end or function(self, auid) end,

    game_manager_on_spawn_stage = function(self, stage, auid)
        self["game_manager_spawn_stage_" .. stage](self, auid)
    end
}

local pairs, ipairs = pairs, ipairs
local tremove = table.remove
local rand, floor = math.random, math.floor

local Entity = ents.Entity

local Game_Manager = Entity:clone {
    name = "Game_Manager",

    __properties = {
        team_data = svars.State_Table()
    },

    __activate = SERVER and function(self)
        Entity.__activate(self)
        self:add_tag("game_manager")
        self.teams = {}
    end or nil,

    get_players = SERVER and function(self)
        local players = {}
        for i, team in pairs(self.teams) do
            for i, v in ipairs(team.player_list) do
                players[#players + 1] = v
            end
        end
        return players
    end or nil,

    start_game = SERVER and function(self)
        local players = self:get_players()

        for i, team in pairs(self.teams) do
            team.player_list = {}
        end

        while #players > 0 do
            local pl = tremove(players, floor(rand() * #players))
            self:pick_team(p, false)
        end
        self:sync_team_data()

        for i, player in pairs(self:get_players()) do
            player:respawn()
        end

        emit(self, "game_start")
        self.game_running = true
    end or nil,

    end_game = SERVER and function(self)
        self.game_running = false
        emit(self, "game_end")
    end or nil,

    sync_team_data = SERVER and function(self)
        if not self.deactivated then
            self:set_attr("team_data", self.teams)
        end
    end or nil,

    pick_team = SERVER and function(self, player, sync)
    end or nil,

    set_player_team = SERVER and function(self, player, team, sync)
    end or nil,

    leave_team = SERVER and function(self, player, sync)
    end or nil,

    place_player = function(self, player)
        local team = player:get_attr("team")
        local st
        if team == "" then
            st = "player_start"
        else
            st = "player_start_" .. team
        end
        local starts = ents.get_by_tag(st)
        if starts and #starts > 0 then
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

local assert = assert

local gameman

--! Gets the current game manager instance.
M.get = function()
    if not gameman then
        gameman = ents.get_by_class("Game_Manager")[1]
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
    ents.register_class(Game_Manager, plugins)
    if SERVER then
        gameman = ents.new("Game_Manager")
        return gameman
    end
end

return M
