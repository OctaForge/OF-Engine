module("cutscenes", package.seeall)

-- shows a distance and a direction using line / flare
function show_distance(tag, origin, color, seconds)
    if not origin["__CACHED_" .. tag] then
        local entities = entity_store.get_all_bytag(tag)
        if #entities == 1 then origin["__CACHED_" .. tag] = entities[1]
        else return nil end
    end
    local entity = origin["__CACHED_" .. tag]

    effect.flare(effect.PARTICLE.STREAK, origin.position, entity.position, 0, color, 0.2)
end

action_base = class.new(events.action_container)

function action_base:__tostring() return "action_base" end

function action_base:client_click()
    if self.canbecancelled then
        self:cancel()
    end
end

function action_base:dostart()
    events.action_container.dostart(self)

    self.actor.can_move = false

    self.original_yaw   = self.actor.yaw
    self.original_pitch = self.actor.pitch

    self.old_crosshair = _G["crosshair"]
    _G["crosshair"]    = ""

    self.old_show_hud_text  = CAPI.showhudtext
    self.old_show_hud_rect  = CAPI.showhudrect
    self.old_show_hud_image = CAPI.showhudimage

    CAPI.showhudtext  = function() end
    CAPI.showhudrect  = function() end
    CAPI.showhudimage = function() end

    self.old_seconds_left = self.secondsleft

    events.action_input_capture_plugin.dostart(self)
end

function action_base:doexecute(seconds)
    self.actor.yaw   = self.original_yaw
    self.actor.pitch = self.original_pitch

    if self.subtitles then
        self.show_subtitles(self, self.old_seconds_left - self.secondsleft)
    end

    return events.action_container.doexecute(self, seconds)
        or entity_store.is_player_editing()
end

function action_base:dofinish()
    events.action_container.dofinish(self)

    self.actor.can_move = true

    _G["crosshair"] = self.old_crosshair

    CAPI.showhudtext  = self.old_show_hud_text
    CAPI.showhudrect  = self.old_show_hud_rect
    CAPI.showhudimage = self.old_show_hud_image

    events.action_input_capture_plugin.dofinish(self)
end

function action_base:show_subtitles(time_val)
    for i, subtitle in pairs(self.subtitles) do
        if time_val >= subtitle.start_t and time_val <= subtitle.end_t then
            if  self.show_subtitle_background then
                self:show_subtitle_background() end

            self.old_show_hud_text(
                subtitle.text,
                subtitle.x, self.subtitles[i].y,
                subtitle.size,
                subtitle.color
            )
        end
    end
end

action_smooth = class.new(actions.action)
action_smooth.seconds_per_marker = 4
action_smooth.delay_before       = 0
action_smooth.delay_after        = 0
action_smooth.looped             = false
action_smooth.looping            = false

function action_smooth:__tostring  () return "action_smooth" end
function action_smooth:init_markers() end

function action_smooth:dostart()
    self:init_markers()

    self.timer = (- self.seconds_per_marker) / 2 - self.delay_before
    self.secondsleft = self.seconds_per_marker * #self.markers
end

function action_smooth:doexecute(seconds)
    -- get around loading time delays by ignoring long frames
    self.timer = self.timer + math.min(seconds, 1 / 25)

    self:set_markers()
    camera.force(
        self.position.x, self.position.y, self.position.z,
        self.yaw, self.pitch, 0
    )

    actions.action.doexecute(self, seconds)

    if self.looped then
        if (not self.looping
            and self.secondsleft <= (- self.delay_before)
        ) or (self.looping and self.secondsleft <= 0) then
            -- reset timer etc.
            self.timer = (- self.seconds_per_marker) / 2
            self.secondsleft = self.seconds_per_marker * #self.markers
            if not self.looping then self.looping = true end
        end
    end

    -- we end
    return (self.secondsleft <= ((- self.delay_after) - self.delay_before))
end

function action_smooth:smooth_fun(x)
    if x <= (- 0.5) then
        -- 0 until -0.5
        return 0
    elseif x >= 0.5 then
        return 1
    else
        -- gives 0 for -0.5, 0.5 for 0.5
        return 0.5 * math.pow(math.abs(x + 0.5), 2)
    end
end

function action_smooth:set_markers()
    local raw = self.timer / self.seconds_per_marker
    local current_index = math.clamp(math.floor(raw + 0.5), 0, #self.markers)

    -- how much to give the previous
    local alpha = self:smooth_fun(current_index - raw)
    -- how much to give the next
    local beta  = self:smooth_fun(raw - current_index)

    local last_marker = self.markers[math.clamp(current_index, 1, #self.markers)]
    local curr_marker = self.markers[math.clamp(current_index + 1,     1, #self.markers)]
    local next_marker = self.markers[math.clamp(current_index + 2, 1, #self.markers)]

    self.position = last_marker.position:mulnew(alpha):add(
          curr_marker.position:mulnew(1 - alpha - beta)
    ):add(next_marker.position:mulnew(beta))

    self.yaw   = utility.angle_normalize(last_marker.yaw, curr_marker.yaw) * alpha
               + utility.angle_normalize(next_marker.yaw, curr_marker.yaw) * beta
               + curr_marker.yaw * (1 - alpha - beta)

    self.pitch = utility.angle_normalize(last_marker.pitch, curr_marker.pitch) * alpha
               + utility.angle_normalize(next_marker.pitch, curr_marker.pitch) * beta
               + curr_marker.pitch * (1 - alpha - beta)
end

---------------------
-- CUTSCENE MANAGER -
---------------------

-- cutscene controller
entity_classes.reg(
    plugins.bake(entity_static.world_marker, {{
        _class     = "cutscene_controller",
        should_act = true,
        factor     = 4 / 3,
        started    = false,
        cancel     = false,

        properties = {
            cancellable     = state_variables.state_bool(),
            cancel_siblings = state_variables.state_bool(),
            seconds_per_marker = state_variables.state_float(),
            delay_before    = state_variables.state_float(),
            delay_after     = state_variables.state_float(),
            next_controller = state_variables.state_integer(),
        },

        before_start = function(self) end,
        after_end    = function(self) end,

        start = function(self)
            if GLOBAL_NO_CUTSCENES then return nil end

            self:before_start()

            if not self.m_tag then
                self.m_tag = self.tags:as_array()[1]
            end

            local entity = self

            local base_action = entity_store.get_all_bytag(
                self.m_tag .. "_base"
            )
            if #base_action ~= 1 then
                base_action  = action_base
            else
                base_action  = base_action[1].action
            end

            local action = entity_store.get_all_bytag(
                self.m_tag .. "_action"
            )
            if #action ~= 1 then
                action  = {}
            else
                action  = action[1].action
            end

            entity_store.get_plyent():queue_action(
                class.new(base_action, {
                    cancel = function(self)
                        if self.canbecancelled and entity.started and not self.finished then
                            self.action_system:clear()
                            self.action_system:manage(0.01)
                            self:finish()
                        end
                    end,

                    dostart = function(self)
                        self.__base.dostart(self)

                        self.canbecancelled = entity.cancellable

                        if entity.cancel then self:cancel() end

                        self.subtitles = {}

                        local i = 2
                        local start_mark = entity_store.get_all_bytag(entity.m_tag .. "_sub_1")
                        if   #start_mark ~= 1 then return nil end
                        if    start_mark[1].parent_id > 0 then
                            local start_time = start_mark[1].start_time
                                            + (entity.seconds_per_marker * (start_mark[1].parent_id - 1))
                                            +  entity.delay_before
                            local end_time   = start_time + start_mark[1].total_time

                            table.insert(self.subtitles, {
                                start_t = start_time * entity.factor,
                                end_t   = end_time   * entity.factor,
                                text    = start_mark[1].text,
                                x       = start_mark[1].x_pos,
                                y       = start_mark[1].y_pos,
                                size    = start_mark[1].size,
                                color   = tonumber(convert.rgbtohex(start_mark[1].red, start_mark[1].green, start_mark[1].blue))
                            })
                        end
                        while true do
                            local next_mark = entity_store.get_all_bytag(entity.m_tag .. "_sub_" .. i)
                            if   #next_mark ~= 1 then break end
                            if    next_mark[1].parent_id > 0 then
                                local start_time = next_mark[1].start_time
                                                + (entity.seconds_per_marker * (next_mark[1].parent_id - 1))
                                                +  entity.delay_before
                                local end_time   = start_time + next_mark[1].total_time

                                table.insert(self.subtitles, {
                                    start_t = start_time * entity.factor,
                                    end_t   = end_time   * entity.factor,
                                    text    = next_mark[1].text,
                                    x       = next_mark[1].x_pos,
                                    y       = next_mark[1].y_pos,
                                    size    = next_mark[1].size,
                                    color   = tonumber(convert.rgbtohex(next_mark[1].red, next_mark[1].green, next_mark[1].blue))
                                })
                            end
                            i = i + 1
                        end
                    end,

                    dofinish = function(self)
                        self.__base.dofinish(self)

                        -- clear up the queue from base actions just in case
                        local queue = entity_store.get_plyent().action_system.actlist
                        for i, v in pairs(queue) do
                            if v:is_a(base_action) then
                                table.remove(queue, i)
                            end
                        end

                        local next_control = entity_store.get_all_bytag("ctl_" .. entity.next_controller)
                        if   #next_control == 1 then
                              next_control[1].started = true
                              next_control[1].cancel = entity.cancel_siblings
                        end
                    end
                })({
                    class.new(action_smooth, {
                        init_markers = function(self)
                            self.markers            = {}
                            self.seconds_per_marker = entity.seconds_per_marker
                            self.delay_before       = entity.delay_before
                            self.delay_after        = entity.delay_after

                            local start_mark = entity_store.get_all_bytag(entity.m_tag .. "_mrk_1")
                            if   #start_mark ~= 1 then return nil end
                            local  prev_mark = start_mark
                            table.insert(self.markers, {
                                position = start_mark[1].position:copy(),
                                yaw      = start_mark[1].yaw,
                                pitch    = start_mark[1].pitch
                            })

                            while true do
                                local next_mark = entity_store.get_all_bytag(
                                    entity.m_tag .. "_mrk_" .. prev_mark[1].next_marker
                                )
                                if   #next_mark ~= 1 then break end

                                prev_mark = next_mark
                                table.insert(self.markers, {
                                    position = next_mark[1].position:copy(),
                                    yaw      = next_mark[1].yaw,
                                    pitch    = next_mark[1].pitch
                                })
                                if next_mark[1].next_marker == 1 then
                                    if entity.next_controller <= 0 then self.looped = true end
                                    next_mark = entity_store.get_all_bytag(
                                        entity.m_tag .. "_mrk_" .. prev_mark[1].next_marker
                                    )
                                    table.insert(self.markers, {
                                        position = next_mark[1].position:copy(),
                                        yaw      = next_mark[1].yaw,
                                        pitch    = next_mark[1].pitch
                                    })
                                    break
                                end
                            end
                        end
                    }):mixin(action)()
                })
            )

            self:after_end()
        end,

        client_activate = function(self)
            self:connect(state_variables.get_onmodify_prefix() .. "tags", function(self)
                self.m_tag = self.tags:as_array()[1]
            end)
            self:connect(state_variables.get_onmodify_prefix() .. "next_controller", function(self)
                -- flush the cache
                for k, v in pairs(self) do
                    if string.sub(k, 1, 9) == "__CACHED_" then
                        v = nil
                    end
                end
            end)
        end,

        init = function(self)
            self.cancellable     = false
            self.cancel_siblings = true
            self.seconds_per_marker = 4
            self.delay_before    = 0
            self.delay_after     = 0
            self.next_controller = -1
        end,

        client_act = function(self, seconds)
            if self.started and not entity_store.is_player_editing() and not self.lock then
                self:start()
                self.lock = true
            end
            self.lock = (not self.started and self.lock) and false or self.lock

            if entity_store.is_player_editing() then
                if self.next_controller >= 1 then
                    show_distance("ctl_" .. self.next_controller, self, 0xFFED22, seconds)
                end
            end
        end
    }}), "playerstart"
)

-- cutscene position marker
entity_classes.reg(
    plugins.bake(entity_static.world_marker, {{
        _class     = "cutscene_marker",
        should_act = true,

        properties = {
            next_marker = state_variables.state_integer(),
            pitch       = state_variables.state_float()
        },

        init = function(self)
            self.next_marker = 0
            self.pitch       = 0
        end,

        client_activate = function(self)
            self:connect(state_variables.get_onmodify_prefix() .. "tags", function(self)
                self.m_tag = self.tags:as_array()[1]
                -- flush the cache
                for k, v in pairs(self) do
                    if string.sub(k, 1, 9) == "__CACHED_" then
                        v = nil
                    end
                end
            end)
            self:connect(state_variables.get_onmodify_prefix() .. "next_marker", function(self)
                -- flush the cache
                for k, v in pairs(self) do
                    if string.sub(k, 1, 9) == "__CACHED_" then
                        v = nil
                    end
                end
            end)
        end,

        client_act = function(self, seconds)
            if not entity_store.is_player_editing() then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:as_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 4 then return nil end

            if self.next_marker > 0 and tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2] .. "_mrk_" .. self.next_marker, self, 0x22BBFF, seconds)
            end

            if tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0x22FF27, seconds)
            end

            local direction = math.vec3():fromyawpitch(self.yaw, self.pitch)
            local target    = utility.get_ray_collision_world(self.position:copy(), direction, 10)
            effect.flare(
                effect.PARTICLE.STREAK,
                self.position, target,
                0, 0x22BBFF, 0.3
            )
        end
    }}), "playerstart"
)

-- cutscene subtitle marker
entity_classes.reg(
    plugins.bake(entity_static.world_marker, {{
        _class     = "cutscene_subtitle",
        should_act = true,

        properties = {
            parent_id  = state_variables.state_integer(),

            start_time = state_variables.state_float(),
            total_time = state_variables.state_float(),
            text       = state_variables.state_string(),
            x_pos      = state_variables.state_float(),
            y_pos      = state_variables.state_float(),
            size       = state_variables.state_float(),
            red        = state_variables.state_integer(),
            green      = state_variables.state_integer(),
            blue       = state_variables.state_integer()
        },

        init = function(self)
            self.parent_id  = 0
            self.start_time = 0
            self.total_time = 0
            self.text       = ""
            self.x_pos      = 0.5
            self.y_pos      = 0.92
            self.size       = 0.5
            self.red        = 255
            self.green      = 255
            self.blue       = 255
        end,

        client_activate = function(self)
            self:connect(state_variables.get_onmodify_prefix() .. "tags", function(self)
                self.m_tag = self.tags:as_array()[1]
                -- flush the cache
                for k, v in pairs(self) do
                    if string.sub(k, 1, 9) == "__CACHED_" then
                        v = nil
                    end
                end
            end)
            self:connect(state_variables.get_onmodify_prefix() .. "parent_id", function(self)
                -- flush the cache
                for k, v in pairs(self) do
                    if string.sub(k, 1, 9) == "__CACHED_" then
                        v = nil
                    end
                end
            end)
        end,

        client_act = function(self, seconds)
            if not entity_store.is_player_editing() then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:as_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 4 then return nil end

            if self.parent_id > 0 and tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2] .. "_mrk_" .. self.parent_id, self, 0xFF22C3, seconds)
            end

            if tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0xFF2222, seconds)
            end
        end
    }}), "playerstart"
)

-- cutscene base action
entity_classes.reg(
    plugins.bake(entity_static.world_marker, {{
        _class     = "cutscene_base_action",
        should_act = true,

        properties = {
            background_image =    state_variables.state_string(),
            subtitle_background = state_variables.state_string()
        },

        init = function(self)
            self.background_image    = ""
            self.subtitle_background = ""
        end,

        client_activate = function(self)
            self:connect(state_variables.get_onmodify_prefix() .. "tags", function(self)
                self.m_tag = self.tags:as_array()[1]
                -- flush the cache
                for k, v in pairs(self) do
                    if string.sub(k, 1, 9) == "__CACHED_" then
                        v = nil
                    end
                end
            end)
        end,

        client_act = function(self, seconds)
            if  self.action.background_image    ~= self.background_image then
                self.action.background_image     = self.background_image end
            if  self.action.subtitle_background ~= self.subtitle_background then
                self.action.subtitle_background  = self.subtitle_background end

            if not entity_store.is_player_editing() then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:as_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 3 then return nil end

            if self.m_tag and tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0xFF9A22, seconds)
            end
        end,

        action = class.new(action_base, {
            dostart = function(self)
                self.__base.dostart(self)

                self.background_image    = ""
                self.subtitle_background = ""
            end,

            doexecute = function(self, seconds)
                if self.background_image ~= "" then
                    self.old_show_hud_image(
                        self.background_image,
                        0.5, 0.5,
                        math.max((scr_w / scr_h), 1),
                        math.min((scr_w / scr_h), 1)
                    )
                end
                return self.__base.doexecute(self, seconds)
            end,

            show_subtitle_background = function(self)
                if GLOBAL_GAME_HUD then
                    local factors = GLOBAL_GAME_HUD:calc_factors()
                    if self.subtitle_background ~= "" then
                        self.old_show_hud_image(
                            self.subtitle_background,
                            0.5,
                            0.9,
                            (factors.x * 800) / scr_w,
                            (factors.y * 128) / scr_h
                        )
                    end
                end
            end
        })
    }}), "playerstart"
)

-- cutscene action marker
entity_classes.reg(
    plugins.bake(entity_static.world_marker, {{
        _class     = "cutscene_action",
        should_act = true,

        client_activate = function(self)
            self:connect(state_variables.get_onmodify_prefix() .. "tags", function(self)
                self.m_tag = self.tags:as_array()[1]
                -- flush the cache
                for k, v in pairs(self) do
                    if string.sub(k, 1, 9) == "__CACHED_" then
                        v = nil
                    end
                end
            end)
        end,

        client_act = function(self, seconds)
            if not entity_store.is_player_editing() then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:as_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 3 then return nil end

            if self.m_tag and tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0x22FFD3, seconds)
            end
        end,

        action = {
            -- extend with dostart, doexecute, dofinish, don't forget to call parent
        }
    }}), "playerstart"
)
