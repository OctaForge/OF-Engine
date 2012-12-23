module("game_manager", package.seeall)

player_plugin = {
    properties = {
        team = svars.State_String()
    },

    init = function(self)
        self.team = "" -- empty until set
    end,

    activate = function(self)
        if SERVER then
            get_singleton():pick_team(self)
            signal.connect(self,"pre_deactivate", function(_, self)
                get_singleton():leave_team(self)
            end)
            self:respawn()
        else
            signal.connect(self,"client_respawn", function(_, self)
                get_singleton():place_player(self)
            end)
        end
    end,
}

function setup(plugins_add)
    plugins_add = plugins_add or {}

    ents.register_class(
        plugins.bake(
            ents.Entity,
            table.merge(
                {{
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
                            signal.connect(self,"team_data_changed", function(_, self, value)
                                if self.team_data and value and ents.get_player() then
                                    local player_team = ents.get_player().team
                                    if value[player_team].score > self.team_data[player_team].score and
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
                            self.team_data = self.teams
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
                        if player.team then
                            self:leave_team(player, sync)
                        end

                        player.team = team
                        team = self.teams[team]
                        table.insert(team.player_list, player)
                        team:player_setup(player)
                        player:respawn()

                        if sync then
                            self:sync_team_data()
                        end
                    end,

                    leave_team = function(self, player, sync)
                        sync = sync or true

                        if player.team == "" then
                            return nil
                        end
                        local  player_team = self.teams[player.team]
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
                        local start_tag = "start_" .. player.team
                        local possibles = ents.get_by_tag(start_tag)
                        if possibles and #possibles > 0 then
                            local start = possibles[math.random(1, #possibles)]
                            if start then
                                start:place_entity(player)
                                return nil
                            end
                        end
                        log(WARNING, "player start not found (\"%(1)s\"), placing player elsewhere .." % { start_tag })
                        player.position = { 512, 512, 571 }
                    end,

                    adjust_score = function(self, team_name, diff)
                        self.teams[team_name].score = self.teams[team_name].score + diff
                        self:sync_team_data()
                    end,

                    get_scoreboard_text = function(self)
                        local data = {}
                        if not self.team_data then return data end
                        for team_name, team in pairs(self.team_data) do
                            table.insert(data, { -1, " << " .. team_name .. " >> " .. team.score .. " points" })
                            for idx, player in pairs(team.player_list) do
                                table.insert(data, { player.uid, player.character_name .. " -" })
                            end
                        end
                        return data
                    end,

                    set_local_animation = function(self) end -- just so it can fake being animated by actions
                }},
                plugins_add
            ),
            "game_manager"
        )
    )

    if SERVER then
        ents.new("game_manager")
    end
end

function get_singleton()
    if not singleton then
        singleton = ents.get_by_class("game_manager")[1]
    end
    return singleton
end

function get_scoreboard_text()
    return get_singleton():get_scoreboard_text()
end

manager_plugins = {
    messages = {
        properties = {
            server_message = svars.State_Table { has_history = false }
        },

        hud_messages = {},

        add_hud_message = function(self, text, color, duration, size, x, y, player)
            local kwargs
            if type(text) == "table" then
                kwargs = text
            else
                kwargs = { text = text, color = color, duration = duration, size = size, x = x, y = y, player = player }
            end

            if SERVER then
                kwargs.player = kwargs.player and kwargs.player.uid or -1
                self.server_message = kwargs
            else
                if type(kwargs.player) == "number" then kwargs.player = ents.get(kwargs.player) end
                self:clear_hud_messages() -- XXX: only 1 for now
                table.insert(self.hud_messages, kwargs)
            end
        end,

        clear_hud_messages = function(self)
            self.hud_messages = {}
        end,

        activate = function(self)
            if not CLIENT then return nil end
            signal.connect(self,"server_message_changed", function(_, self, kwargs)
                self:add_hud_message(kwargs)
            end)
            self.rendering_hash_hint = 0 -- used for rendering entities without fpsents
        end,

        run = CLIENT and function(self, seconds)
            self.hud_messages = table.filter(self.hud_messages, function(i, msg)
                if msg.player and msg.player ~= 0 and msg.player ~= ents.get_player() then return false end

                local size = msg.size and msg.size ~= 0 and msg.size or 1.0
                size = msg.duration >= 0.5 and size or size * math.pow(msg.duration * 2, 2)
                --gui.hud_label(
                --    msg.text,
                --    msg.x and msg.x ~= 0 and msg.x or 0.5,
                --    msg.y and msg.y ~= 0 and msg.y or 0.2,
                --    size, msg.color
                --)
                msg.duration = msg.duration - seconds
                return (msg.duration > 0)
            end)
        end or nil
    },

    limit_game_time = {
        max_time = 600, -- 10 minutes

        activate = function(self)
            if not SERVER then return nil end
            signal.connect(self,"start_game", function(_, self)
                self.time_left = self.max_time
            end)
        end,

        run = SERVER and function(self, seconds)
            if not self.game_running then return nil end

            self.time_left = self.time_left - seconds
            if self.time_left <= 0 then
                self:end_game()
            end
        end or nil
    },

    limit_game_score = {
        max_score = 10,

        activate = function(self)
            if not SERVER then return nil end
            signal.connect(self,"team_data_modified", function(_, self)
                if not self.game_running then return nil end

                for k, team in pairs(self.teams) do
                    if team.score >= self.max_score then
                        self:end_game()
                    end
                end
            end)
        end
    },

    intermission = {
        win_message  = "You won!",
        win_sound    = "",
        lose_message = "You lost...",
        lose_sound   = "",
        tie_message  = "The game is a tie.",
        tie_sound    = "",
        finish_title = "Game finished",

        activate = function(self)
            if not SERVER then return nil end
            signal.connect(self,"end_game", function(_, self)
                -- decide winner
                local max_score
                local min_score
                for k, team in pairs(self.teams) do
                    max_score = max_score or team.score
                    min_score = min_score or team.score
                    max_score = math.max(team.score, max_score)
                    min_score = math.min(team.score, min_score)
                end

                local tie = (max_score == min_score)

                local players = self:get_players()
                for k, player in pairs(players) do
                    player.can_move = false
                    local msg
                    local sound
                    if not tie then
                        if self.steams[player.team].score == max_score then
                            player.animation = math.bor(model.ANIM_WIN, model.ANIM_LOOP)
                            msg.show_client_message(player, self.finish_title, self.win_message)
                            if self.win_sound ~= "" then
                                sound.play(self.win_sound, math.Vec3(0, 0, 0), player.cn)
                            end
                        else
                            player.animation = math.bor(model.ANIM_LOSE, model.ANIM_LOOP)
                            msg.show_client_message(player, self.finish_title, self.lose_message)
                            if self.lose_sound ~= "" then
                                sound.play(self.lose_sound, math.Vec3(0, 0, 0), player.cn)
                            end
                        end
                    else
                        player.animation = math.bor(model.ANIM_IDLE, model.ANIM_LOOP)
                        msg.show_client_message(player, self.finish_title, self.tie_message)
                        if self.tie_sound ~= "" then
                            sound.play(self.tie_sound, math.Vec3(0, 0, 0), player.cn)
                        end
                    end
                end
                self.intermission_delay_left = 10.0
            end)
        end,

        run = SERVER and function(self, seconds)
            if self.intermission_delay_left and self.intermission_delay_left ~= 0 then
                self.intermission_delay_left = self.intermission_delay_left - seconds
                if self.intermission_delay_left <= 0 then
                    self.intermission_delay_left = nil

                    -- unfreeze players
                    local players = self:get_players()
                    for k, player in pairs(players) do
                        player.can_move = true
                    end

                    self:start_game()
                end
            end
        end or nil
    },

    balancer = {
        balanced_message = "Balanced the teams",

        activate = function(self)
            if not SERVER then return nil end
            self.balancer_timer = events.repeating_timer(1.0)
        end,

        run = SERVER and function(self, seconds)
            if self.balancer_timer:tick(seconds) then
                local relevant_teams = table.filter(self.teams, function(i, team)
                    return (not team.kwargs.ignore_for_balancing)
                end)

                local num_teams = #table.keys(relevant_teams)
                local total_players = table.foldr(
                    table.map(
                        relevant_teams,
                        function(team_data) return #team_data.player_list end
                    ),
                    function(a, b) return a + b end
                )
                local expected_players = total_players / num_teams

                local needs_reduce = table.filter(
                    relevant_teams,
                    function(k, team_data)
                        return (#team_data.player_list > expected_players + 1)
                    end
                )

                local changed = false
                for k, team_data in pairs(needs_reduce) do
                    local player = team_data.player_list[1]
                    self:leave_team(player, false)
                    self:pick_team(player, false)
                    player:respawn()
                    changed = true
                end
                self:sync_team_data() -- do all syncing at the end
                if changed and self.add_hud_message then
                    self:add_hud_message(self.balanced_message, 0xFFFFFF, 2.0, 0.66)
                end
            end
        end or nil
    },

    event_list = {
        activate = function(self)
            self.event_manager = {
                list = {},
                need_sort = false,

                sort_list = function(self)
                    table.sort(self.list, function(a, b) return a.deadline < b.deadline end)
                    self.need_sort = false
                end,

                add = function(self, kwargs, to_replace)
                    if to_replace then
                        to_replace.abort = true
                    end
                    kwargs.seconds_before  = kwargs.seconds_before  or 0
                    -- not repeating, no time between
                    kwargs.seconds_between = kwargs.seconds_between or -1
                    kwargs.deadline        = frame.get_time() + kwargs.seconds_before
                    kwargs.abort           = false
                    kwargs.sleeping        = false

                    table.insert(self.list, kwargs)
                    self.need_sort = true

                    return kwargs
                end,

                suspend = function(self, item)
                    if not item.sleeping then
                        item.sleeping  = true
                        item.deadline  = frame.get_time() + 86400 -- 24 hours
                        item.need_sort = true
                    end
                end,

                awaken = function(self, item, delay)
                    if item.sleeping then
                        item.sleeping  = false
                        item.deadline  = frame.get_time() + delay and delay or 0
                        item.need_sort = true
                    end
                end
            }
        end,

        run = function(self, seconds)
            if  self.event_manager.need_sort then
                self.event_manager:sort_list()
            end

            local ctime

            local events = self.event_manager.list
            local curr_index = 1
            for i, event in pairs(events) do
                local item = events[curr_index]
                if frame.get_time() < item.deadline then break end

                -- the item's time is now
                local skip = false

                if item.abort or (item.entity and item.entity.deactivated) then
                    table.remove(events, curr_index)
                    skip = true
                end

                if not skip and item.sleeping then
                    item.deadline = frame.get_time() + 86400 -- 24 hours
                    curr_index = curr_index + 1
                    skip = true
                end
                if not skip then
                    local more = item:func()
                    if item.seconds_between >= 0 and more ~= false then
                        more = more or 0
                        -- negative more means 'add some jitter'
                        if more < 0 then more = more * -(math.random() + 0.5) end
                        item.deadline = frame.get_time() + item.seconds_between + more
                        curr_index = curr_index + 1
                    else
                        table.remove(events, curr_index)
                    end

                    if curr_index > 0 then
                        self.event_manager.need_sort = true
                    end
                end
            end
        end
    }
}
