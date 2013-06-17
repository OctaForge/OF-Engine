--[[! File: lua/extra/game_manager.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        A game manager module that manages spawning and teams, with the
        possibility of various plugins.
]]

local M = {}

local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local connect, emit = signal.connect, signal.emit

local get

--[[! Class: player_plugin
    Player-side game manager functionality. If you want to use the game
    game manager, you need to set up your player entity class with this
    plugin.
]]
M.player_plugin = {
    properties = {
        team        = svars.State_String(),
        spawn_stage = svars.State_Integer()
    },

    init = function(self)
        self:set_attr("team", "")
    end,

    respawn = function(self)
        self:set_attr("spawn_stage", 1)
    end,

    activate = function(self)
        connect(self, "spawn_stage_changed", self.on_spawn_stage)
        if SERVER then
            get():pick_team(self)
            connect(self, "pre_deactivate", function(self)
                get():leave_team(self)
            end)
            self:respawn()
        else
            connect(self, "client_respawn", function(self)
                get():place_player(self)
            end)
        end
    end,

    on_spawn_stage = function(self, stage, auid)
        if stage == 1 then
            if not SERVER then self:set_attr("spawn_stage", 2) end
        elseif stage == 2 then
            if SERVER then
                if auid == self.uid then
                    self:set_attr("spawn_stage", 3)
                end
                self:cancel_sdata_update()
            end
        elseif stage == 3 then
            if not SERVER and self == ents.get_player() then
                emit(self, "client_respawn")
                self:set_attr("spawn_stage", 4)
            end
        elseif stage == 4 then
            if SERVER then
                self:set_attr("can_move", true)
                self:set_attr("spawn_stage", 0)
                self:cancel_sdata_update()
            end
        end
    end
}

local pairs, ipairs = pairs, ipairs
local tremove = table.remove
local rand, floor = math.random, math.floor

local Game_Manager = ents.Entity:clone {
    name = "Game_Manager",

    properties = {
        team_data = svars.State_Table()
    },

    activate = SERVER and function(self)
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
            return nil
        end
        #log(WARNING, ('player start not found (\"%s\"), '
        #    .. 'placing player elsewhere'):format(st))
        player:set_attr("position", { 512, 512, 571 })
    end,

    set_local_animation = function(self) end
}

local assert = assert

local gameman

--[[! Function: get
    Gets the current game manager instance.
]]
get = function()
    if not gameman then
        gameman = ents.get_by_class("Game_Manager")[1]
    end
    assert(gameman)
    return gameman
end
M.get = get

--[[! Function: setup
    Sets up the game manager. You can provide an optional list of game
    manager plugins. You should call this in your mapscript before ents.load().
]]
M.setup = function(plugins)
    ents.register_class(Game_Manager, plugins)
    if SERVER then ents.new(Game_Manager.name) end
end

return M
