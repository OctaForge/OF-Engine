local sound = require("core.engine.sound")
local model = require("core.engine.model")
local msg = require("core.network.msg")
local frame = require("core.events.frame")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

module("game_manager", package.seeall)

player_plugin = {
    properties = {
        team = svars.State_String()
    },

    init = function(self)
        self:set_attr("team", "") -- empty until set
    end,

    activate = function(self)
        if SERVER then
            get_singleton():pick_team(self)
            signal.connect(self,"pre_deactivate", function(self)
                get_singleton():leave_team(self)
            end)
            self:respawn()
        else
            signal.connect(self,"client_respawn", function(self)
                get_singleton():place_player(self)
            end)
        end
    end,
}

function setup(plugins_add)
    plugins_add = plugins_add or {}

    ents.register_class(ents.Entity, table.merge({{
        properties = {
            team_data = svars.State_Table()
        },
        victory_sound = "",

        activate = function(self)
            if SERVER then
                self:add_tag("game_manager")
                self.teams = {}
                self.victory_sound = ""
            else
                signal.connect(self,"team_data_changed", function(self, value)
                    if self:get_attr("team_data") and value and ents.get_player() then
                        local player_team = ents.get_player():get_attr("team")
                        if value[player_team].score > self:get_attr("team_data")[player_team].score and
                           self.victory_sound ~= "" then sound.play(self.victory_sound)
                        end
                    end
                end)
            end
        end,

        get_players = function(self)
            local players = {}
            for i, team in pairs(table.values(self.teams)) do
                players = table.merge(players, team.player_list)
            end
            return players
        end,

        start_game = function(self)
            local players = self:get_players()

            -- clear teams
            for i, team in pairs(table.values(self.teams)) do
                team.score = 0
                team.player_list = {}
            end

            -- place players randomly
            while #players > 0 do
                local player = table.remove(players, math.floor(math.random() * #players))[1]
                self:pick_team(player, false) -- pick teams with no syncing until the end
            end

            self:sync_team_data()

            for i, player in pairs(self:get_players()) do
                player:respawn()
            end

            signal.emit(self,"start_game")
            self.game_running = true
        end,

        end_game = function(self)
            self.game_running = false
            -- usually you want to connect something here to run
            -- self.start_game, but see intermission plugin
            signal.emit(self,"end_game")
        end,

        register_teams = function(self, data)
            for i, team in pairs(data) do
                self.teams[team._name] = {
                    _name = team._name,
                    player_list = {},
                    player_setup = team.setup,
                    score = 0,
                    flag_model_name = team.flag_model_name or '',
                    kwargs = team.kwargs or {}
                }
            end

            signal.emit(self,'post_register_teams')
            self:start_game()
        end,

        sync_team_data = function(self)
            -- we are called during deactivation process, as players leave
            if not self.deactivated then
                self:set_attr("team_data", self.teams)
            end
            signal.emit(self,"team_data_modified")
        end,

        pick_team = function(self, player, sync)
            sync = sync or true
            local smallest = ""
            for name, team in pairs(self.teams) do
                if smallest == "" or #team.player_list < #self.teams[smallest].player_list then
                    smallest = name
                end
            end
            if smallest == "" then return nil end
            self:set_player_team(player, smallest, sync)
        end,

        set_player_team = function(self, player, team, sync)
            if player:get_attr("team") then
                self:leave_team(player, sync)
            end

            player:set_attr("team", team)
            team = self.teams[team]
            local lst = team.player_list
            lst[#lst + 1] = player
            team:player_setup(player)
            player:respawn()

            if sync then
                self:sync_team_data()
            end
        end,

        leave_team = function(self, player, sync)
            sync = sync or true

            if player:get_attr("team") == "" then
                return nil
            end
            local  player_team = self.teams[player:get_attr("team")]
            if not player_team then
                return nil
            end

            local player_list = player_team.player_list
            local index = table.find(player_list, player)
            if index and index >= 0 then
                table.remove(player_list, index)
                if sync then
                    self:sync_team_data()
                end
            end
        end,

        place_player = function(self, player)
            local start_tag = "start_" .. player:get_attr("team")
            local possibles = ents.get_by_tag(start_tag)
            if possibles and #possibles > 0 then
                local start = possibles[math.random(1, #possibles)]
                if start then
                    start:place_entity(player)
                    return nil
                end
            end
            #log(WARNING, ("player start not found (\"%s\"), placing player elsewhere .."):format(start_tag))
            player:set_attr("position", { 512, 512, 571 })
        end,

        adjust_score = function(self, team_name, diff)
            self.teams[team_name].score = self.teams[team_name].score + diff
            self:sync_team_data()
        end,

        set_local_animation = function(self) end -- just so it can fake being animated by actions
    }}, plugins_add), "game_manager")

    if SERVER then
        ents.new("game_manager")
    end
end

local singleton
function get_singleton()
    if not singleton then
        singleton = ents.get_by_class("game_manager")[1]
    end
    return singleton
end
