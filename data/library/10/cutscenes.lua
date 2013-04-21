--[[!
    File: library/10/cutscenes.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Fully realtime-designed cutscene system for OctaForge.
]]

--[[!
    Package: cutscenes
    A cutscene system for OctaForge. This one is fully scripted (no C++ code
    behind it) and designed in real time using entity-based markers.
]]
module("cutscenes", package.seeall)

--[[!
    Function: show_distance
    Given an entity tag (string), origin entity and a color
    (hex number), this visually shows a distance between the origin
    position and the position of the entity got using given tag.

    If more than one entity of given tag is found, this function just
    returns. Same applies for zero entities found.

    The function uses caching heavily, so many distances shown don't
    give too big FPS drop.
]]
function show_distance(tag, origin, color)
    -- we cache values in the origin entity
    local cache_name = table.concat({ "__CACHED_", tag })

    if not origin[cache_name] then
        local entities = ents.get_by_tag(tag)
        if   #entities == 1 then
            origin[cache_name] = entities[1]
        else
            return nil
        end
    end
    local entity = origin[cache_name]

    effects.flare(
        effects.PARTICLE.STREAK,
        origin.position, entity.position,
        0, color, 0.2
    )
end

--[[!
    Class: action_base
    Base cutscene action that manages cancelling, timer,
    input capture, HUD hiding and subtitles.

    It, however, doesn't manage the movement, which is
    managed in the other class, <action_smooth>.

    This class inherits from <action_container>.
]]
action_base = events.action_container:clone {
    name = "action_base",

    --[[!
        Function: click
        This happens on client on click. By default,
        it cancels the action, if it's cancellable.
    ]]
    click = CLIENT and function(self)
        if self.cancellable then
            self:cancel()
        end
    end or nil,

    --[[!
        Function: start
        This basically sets up some stuff before the cutscene can start.
        It saves original actor's yaw and pitch, makes him not able to move,
        hides a crosshair, any sort of HUD and ends.
    ]]
    start = function(self)
        events.action_container.start(self)

        self.actor.can_move = false

        self.original_yaw   = self.actor.yaw
        self.original_pitch = self.actor.pitch

        self.old_crosshair = _G["crosshair"]
        _G["crosshair"]    = ""

        self.old_show_hud_text  = _C.showhudtext
        self.old_show_hud_rect  = _C.showhudrect
        self.old_show_hud_image = _C.showhudimage

        _C.showhudtext  = function() end
        _C.showhudrect  = function() end
        _C.showhudimage = function() end

        self.old_seconds_left = self.seconds_left

        events.action_input_capture_plugin.start(self)
    end,

    --[[!
        Function: run
        This forces a yaw and pitch on unmovable actor, so you can't
        i.e. control your player with a mouse while the cutscene is
        running.

        It also shows subtitles and manages the timing.
    ]]
    run = function(self, seconds)
        self.actor.yaw   = self.original_yaw
        self.actor.pitch = self.original_pitch

        if self.subtitles then
            self.show_subtitles(
                self, self.old_seconds_left - self.seconds_left
            )
        end

        return events.action_container.run(self, seconds)
            or ents.get_player().editing
    end,

    --[[!
        Function: finish
        Called when the cutscene ends. Restores the state set
        up by <start>.
    ]]
   finish = function(self)
        events.action_container.finish(self)

        self.actor.can_move = true

        _G["crosshair"] = self.old_crosshair

        _C.showhudtext  = self.old_show_hud_text
        _C.showhudrect  = self.old_show_hud_rect
        _C.showhudimage = self.old_show_hud_image

        events.action_input_capture_plugin.finish(self)
    end,

    --[[!
        Function: show_subtitles
        Called from <run> every frame. The time_val argument
        is used to check whether to show a subtitle or not (this basically
        loops all available subtitles, checks them and shows if needed).
    ]]
    show_subtitles = function(self, time_val)
        for i, subtitle in pairs(self.subtitles) do
            if  time_val >= subtitle.start_t
            and time_val <= subtitle.end_t then
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
}

--[[!
    Class: action_smooth
    This is another important part of the cutscene system, besides
    <action_base>. It manages the "points" the cutscene goes through
    and smooth interpolation between them.
]]
action_smooth = actions.Action:clone {
    name = "action_smooth",

    --[[!
        Variable: seconds_per_marker
        Specifies a number of seconds it takes to go between two
        markers (any). Defaults to 4.
    ]]
    seconds_per_marker = 4,

    --[[!
        Variable: delay_before
        Specifies a delay before the cutscene starts (in seconds).
        See also <delay_after>.
    ]]
    delay_before       = 0,

    --[[!
        Variable: delay_after
        See also <delay_before>. Specifies a delay after the cutscene.
    ]]
    delay_after        = 0,

    --[[!
        Variable: looped
        A boolean value specifying whether the cutscene will loop.
    ]]
    looped             = false,
    looping            = false,

    --[[!
        Function: init_markers
        A method that does nothing by default. It's called at the
        beginning of <start> and is meant mainly for later
        <cutscene_controller>. There it reads the marker entities
        and converts them into raw marker data to be used by this.
    ]]
    init_markers = function(self)
    end,

    --[[!
        Function: start
        Starts the smooth action. Manages the timer.
    ]]
    start = function(self)
        self:init_markers()

        self.timer = (- self.seconds_per_marker) / 2 - self.delay_before
        self.seconds_left = self.seconds_per_marker * #self.markers
    end,

    --[[!
        Function: run
        Per frame executed method taking care of camera forcing.
        Before doing that, it calls <set_markers> to perform
        proper interpolation.
    ]]
    run = function(self, seconds)
        -- get around loading time delays by ignoring long frames
        self.timer = self.timer + math.min(seconds, 1 / 25)

        self:set_markers()
        local p = self.position
        camera.force(p.x, p.y, p.z, self.yaw, self.pitch, 0)

        actions.Action.run(self, seconds)

        if self.looped then
            if (not self.looping
                and self.seconds_left <= (- self.delay_before)
            ) or (self.looping and self.seconds_left <= 0) then
                -- reset timer etc.
                self.timer = (- self.seconds_per_marker) / 2
                self.seconds_left = self.seconds_per_marker * #self.markers
                if not self.looping then self.looping = true end
            end
        end

        -- we end
        return (
            self.seconds_left <= ((- self.delay_after) - self.delay_before)
        )
    end,

    --[[!
        Function: set_markers
        This uses the available marker data to compute position, yaw
        and pitch. Uses cubic interpolation to smoothly go between
        markers.
    ]]
    set_markers = function(self)
        local raw = self.timer / self.seconds_per_marker
        local current_index = math.clamp(
            math.floor(raw + 0.5), 0, #self.markers
        )

        local function smooth_fun(x)
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

        -- how much to give the previous
        local alpha = smooth_fun(current_index - raw)
        -- how much to give the next
        local beta  = smooth_fun(raw - current_index)

        local last_marker = self.markers[math.clamp(
            current_index, 1, #self.markers
        )]
        local curr_marker = self.markers[math.clamp(
            current_index + 1, 1, #self.markers
        )]
        local next_marker = self.markers[math.clamp(
            current_index + 2, 1, #self.markers
        )]

        self.position = last_marker.position:mul_new(alpha):add(
              curr_marker.position:mul_new(1 - alpha - beta)
        ):add(next_marker.position:mul_new(beta))

        self.yaw   = math.normalize_angle(
                        last_marker.yaw, curr_marker.yaw
                     ) * alpha
                   + math.normalize_angle(
                        next_marker.yaw, curr_marker.yaw
                     ) * beta
                   + curr_marker.yaw * (1 - alpha - beta)

        self.pitch = math.normalize_angle(
                        last_marker.pitch, curr_marker.pitch
                     ) * alpha
                   + math.normalize_angle(
                        next_marker.pitch, curr_marker.pitch
                     ) * beta
                   + curr_marker.pitch * (1 - alpha - beta)
    end
}

--[[!
    Class: cutscene_controller
    This is an entity that you can insert to the world.
    It basically "manages" the cutscene. It has markers
    connected to it. Markers serve as "places" through
    which the cutscene will pass.

    You can have multiple controllers connected in the
    world and each can have its own set of markers.

    Controllers and markers are identified using tags.
    Each controller must have tag ctl_N, where N is
    its number. Controller numbers start with 1.

    Properties:
        cancellable - controls whether cutscene belonging
        to this controller can be cancelled. Defaults to
        false.
        cancel_siblings - if this is true, cancelling this
        cutscene will cancel any other possibly connected
        to it. Defaults to true.
        seconds_per_marker - controls how many seconds it
        will take to go from one marker to another. Defaults
        to 4.
        delay_before - delay in seconds it'll take to start
        the cutscene, defaults to 0.
        delay_after - see above.
        next_controller - the N from ctl_N of the next
        controller.

    Besides standard properties, there is also "started"
    class member, which is not a state variable.

    By setting it to true, you start the cutscene.
]]
ents.register_class(
    plugins.bake(ents.World_Marker, {{
        per_frame = true,
        factor     = 4 / 3,
        started    = false,
        cancel     = false,

        properties = {
            cancellable        = svars.State_Boolean(),
            cancel_siblings    = svars.State_Boolean(),
            seconds_per_marker = svars.State_Float(),
            delay_before       = svars.State_Float(),
            delay_after        = svars.State_Float(),
            next_controller    = svars.State_Integer(),
        },

        --[[!
            Function: before_start
            Override if you need. This gets
            called before the cutscene start.
        ]]
        before_start = function(self) end,

        --[[!
            Function: after_end
            See <before_start>.
        ]]
        after_end    = function(self) end,

        --[[!
            Function: start
            Called once from <run> if the "started"
            member is set to true. If a global variable called
            GLOBAL_NO_CUTSCENES is defined, nothing starts.

            Calls <before_start>, sets up "base action" which
            can be multiple things. If an instance of entity
            <cutscene_base_action> is present (or any other
            inherited from that) with tag ctl_NUM_base,
            it is used. Otherwise, raw <action_base> is used.

            It also sets up "cutscene action" optionally,
            which is <cutscene_action> or inherited from
            that. Cutscene action has to have tag ctl_NUM_action
            and it can i.e. take care of events (like opening
            doors the camera is flying through).

            Besides that, it also sets up <action_smooth> for
            camera movement. Cutscene action is mixed inside
            <action_smooth>.
        ]]
        start = function(self)
            if GLOBAL_NO_CUTSCENES then return nil end

            self:before_start()

            if not self.m_tag then
                self.m_tag = self.tags:to_array()[1]
            end

            local entity = self

            local base_action = ents.get_by_tag(self.m_tag .. "_base")
            if #base_action ~= 1 then
                base_action  = action_base
            else
                base_action  = base_action[1].action
            end

            local action = ents.get_by_tag(self.m_tag .. "_action")
            if #action ~= 1 then
                action  = {}
            else
                action  = action[1].action
            end

            ents.get_player():queue_action(
                (base_action:clone {
                    cancel = function(self)
                        if  self.cancellable
                        and entity.started
                        and not self.finished then
                            self.action_system:clear()
                            self.action_system:run(0.01)
                            self:finish()
                        end
                    end,

                    start = function(self)
                        base_action.start(self)

                        self.cancellable = entity.cancellable

                        if entity.cancel then self:cancel() end

                        self.subtitles = {}

                        local i = 2
                        local start_mark = ents.get_by_tag(
                            entity.m_tag .. "_sub_1"
                        )
                        if   #start_mark ~= 1 then return nil end
                        if    start_mark[1].parent_id > 0 then
                            local start_time = start_mark[1].start_time
                                            + (entity.seconds_per_marker
                                                * (start_mark[1].parent_id - 1)
                                            ) + entity.delay_before

                            local end_time = start_time
                                           + start_mark[1].total_time

                            local subs = self.subtitles
                            subs[#subs + 1] = {
                                start_t = start_time * entity.factor,
                                end_t   = end_time   * entity.factor,
                                text    = start_mark[1].text,
                                x       = start_mark[1].x_pos,
                                y       = start_mark[1].y_pos,
                                size    = start_mark[1].size,
                                color   = rgbtohex(
                                    start_mark[1].red,
                                    start_mark[1].green,
                                    start_mark[1].blue
                                )
                            }
                        end
                        while true do
                            local next_mark = ents.get_by_tag(
                                entity.m_tag .. "_sub_" .. i
                            )
                            if   #next_mark ~= 1 then break end
                            if    next_mark[1].parent_id > 0 then
                                local start_time = next_mark[1].start_time
                                            + (entity.seconds_per_marker
                                                * (next_mark[1].parent_id - 1)
                                            ) + entity.delay_before

                                local end_time = start_time
                                               + next_mark[1].total_time

                                local subs = self.subtitles
                                subs[#subs + 1] = {
                                    start_t = start_time * entity.factor,
                                    end_t   = end_time   * entity.factor,
                                    text    = next_mark[1].text,
                                    x       = next_mark[1].x_pos,
                                    y       = next_mark[1].y_pos,
                                    size    = next_mark[1].size,
                                    color   = rgbtohex(
                                        next_mark[1].red,
                                        next_mark[1].green,
                                        next_mark[1].blue
                                    )
                                }
                            end
                            i = i + 1
                        end
                    end,

                    finish = function(self)
                        base_action.finish(self)

                        -- clear up the queue from base actions just in case
                        local player = ents.get_player()
                        local queue  = player.action_system(1) -- get
                        for i, v in pairs(queue) do
                            if v:is_a(base_action) then
                                table.remove(queue, i)
                            end
                        end

                        local next_control = ents.get_by_tag(
                            "ctl_" .. entity.next_controller
                        )
                        if   #next_control == 1 then
                              next_control[1].started = true
                              next_control[1].cancel = entity.cancel_siblings
                        end
                    end
                })({
                    (action_smooth:clone {
                        init_markers = function(self)
                            self.markers            = {}
                            self.seconds_per_marker = entity.seconds_per_marker
                            self.delay_before       = entity.delay_before
                            self.delay_after        = entity.delay_after

                            local start_mark = ents.get_by_tag(
                                entity.m_tag .. "_mrk_1"
                            )
                            if   #start_mark ~= 1 then return nil end
                            local  prev_mark = start_mark
                            local mrkrs = self.markers
                            mrkrs[#mrkrs + 1] = {
                                position = start_mark[1].position:copy(),
                                yaw      = start_mark[1].yaw,
                                pitch    = start_mark[1].pitch
                            }

                            while true do
                                local next_mark = ents.get_by_tag(
                                    entity.m_tag
                                        .. "_mrk_"
                                        .. prev_mark[1].next_marker
                                )
                                if   #next_mark ~= 1 then break end

                                prev_mark = next_mark
                                local nm = next_mark[1]
                                mrkrs[#mrkrs + 1] = {
                                    position = nm.position:copy(),
                                    yaw      = nm.yaw,
                                    pitch    = nm.pitch
                                }
                                if next_mark[1].next_marker == 1 then
                                    if entity.next_controller <= 0 then
                                        self.looped = true
                                    end
                                    next_mark = ents.get_by_tag(
                                        entity.m_tag
                                            .. "_mrk_"
                                            .. prev_mark[1].next_marker
                                    )
                                    local nm = next_mark[1]
                                    mrkrs[#mrkrs + 1] = {
                                        position = nm.position:copy(),
                                        yaw      = nm.yaw,
                                        pitch    = nm.pitch
                                    }
                                    break
                                end
                            end
                        end
                    }):mixin(action)()
                })
            )
            self:after_end()
        end,

        --[[!
            Function: activate
            Called clientside on entity activation. Sets up callbacks
            for attribute changes, so the visual representation of
            connections remains up to date.
        ]]
        activate = function(self)
            if not CLIENT then return nil end
            signal.connect(self,
                "tags_changed",
                function(_, self)
                    self.m_tag = self.tags:to_array()[1]
                end
            )
            signal.connect(self,
                "next_controller_changed",
                function(_, self)
                    -- flush the cache
                    for k, v in pairs(self) do
                        if string.sub(k, 1, 9) == "__CACHED_" then
                            v = nil
                        end
                    end
                end
            )
        end,

        --[[!
            Function: init
            Called serverside on entity creation. Sets up defaults.
        ]]
        init = function(self)
            self.cancellable        = false
            self.cancel_siblings    = true
            self.seconds_per_marker = 4
            self.delay_before       = 0
            self.delay_after        = 0
            self.next_controller    = -1
        end,

        --[[!
            Function: run
            Takes care of cutscene start (JUST ONCE) if the "started"
            member is set to true. After starting, it creates a lock,
            so the same thing can't be started twice.

            In edit mode, it takes care of visual connection representation.
        ]]
        run = CLIENT and function(self, seconds)
            if self.started and not ents.get_player().editing
            and not self.lock then
                self:start()
                self.lock = true
            end
            self.lock = (not self.started and self.lock) and false or self.lock

            if ents.get_player().editing then
                if self.next_controller >= 1 then
                    show_distance(
                        "ctl_" .. self.next_controller, self, 0xFFED22
                    )
                end
            end
        end or nil
    }}, "cutscene_controller")
)

--[[!
    Class: cutscene_marker
    This class represents a "marker", that is a position the cutscene
    will go through. Markers have to be properly tagged. The tag has
    to be "ctl_N_mrk_M". N is the number of <cutscene_controller>. M
    is the number of the marker.

    Properties:
        next_marker - the number of the next marker this should go
        to. The number is given by the tag.
        pitch - as sauer entities don't have any pitch, we're defining
        our own at this place.
]]
ents.register_class(
    plugins.bake(ents.World_Marker, {{
        per_frame = true,

        properties = {
            next_marker = svars.State_Integer(),
            pitch       = svars.State_Float()
        },

        --[[!
            Function: init
            Called serverside on entity creation. Sets up defaults.
        ]]
        init = function(self)
            self.next_marker = 0
            self.pitch       = 0
        end,

        --[[!
            Function: activate
            Called clientside on entity activation. Sets up callbacks
            for attribute changes, so the visual representation of
            connections remains up to date.
        ]]
        activate = function(self)
            if not CLIENT then return nil end
            signal.connect(self,
                "tags_changed",
                function(_, self)
                    self.m_tag = self.tags:to_array()[1]
                    -- flush the cache
                    for k, v in pairs(self) do
                        if string.sub(k, 1, 9) == "__CACHED_" then
                            v = nil
                        end
                    end
                end
            )
            signal.connect(self,
                "next_marker_changed",
                function(_, self)
                    -- flush the cache
                    for k, v in pairs(self) do
                        if string.sub(k, 1, 9) == "__CACHED_" then
                            v = nil
                        end
                    end
                end
            )
        end,

        --[[!
            Function: run
            In edit mode, this takes care of proper visual representation.
        ]]
        run = CLIENT and function(self, seconds)
            if not ents.get_player().editing then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:to_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 4 then return nil end

            if self.next_marker > 0 and tonumber(arr[2]) > 0 then
                show_distance(
                    "ctl_" .. arr[2] .. "_mrk_" .. self.next_marker,
                    self, 0x22BBFF
                )
            end

            if tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0x22FF27)
            end

            local direction = math.Vec3():from_yaw_pitch(self.yaw, self.pitch)
            local target    = geometry.get_ray_collision_world(
                self.position:copy(), direction, 10
            )
            effects.flare(
                effects.PARTICLE.STREAK,
                self.position, target,
                0, 0x22BBFF, 0.3
            )
        end or nil
    }}, "cutscene_marker")
)

--[[!
    Class: cutscene_subtitle
    This class represents a "subtitle marker", which is connected with
    a controller and a marker. It displays a text with given color and
    position for given amount of time. Markers have to be properly tagged.
    The tag has to be "ctl_N_sub_M". N is the number of <cutscene_controller>.
    M is the number of the marker.

    Properties:
        parent_id - the number of the <cutscene_marker> this belongs to.
        start_time - time in seconds relative to the start time of
        <cutscene_marker>.
        total_time - the number of seconds the subtitle shows for from
        the start time.
        text - the subtitle text.
        x_pos - the subtitle X position, from 0.0 to 1.0 (1.0 being right).
        Defaults to 0.5.
        y_pos - see above. 1.0 represents bottom. Defaults to 0.92.
        size - the font scale. Defaults to 0.5.
        red - the red component of the text color. Ranges from 0 to 255.
        Defaults to 255.
        green - see above.
        blue - see above.
]]
ents.register_class(
    plugins.bake(ents.World_Marker, {{
        per_frame = true,

        properties = {
            parent_id  = svars.State_Integer(),

            start_time = svars.State_Float(),
            total_time = svars.State_Float(),
            text       = svars.State_String(),
            x_pos      = svars.State_Float(),
            y_pos      = svars.State_Float(),
            size       = svars.State_Float(),
            red        = svars.State_Integer(),
            green      = svars.State_Integer(),
            blue       = svars.State_Integer()
        },

        --[[!
            Function: init
            Called serverside on entity creation. Sets up defaults.
        ]]
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

        --[[!
            Function: activate
            Called clientside on entity activation. Sets up callbacks
            for attribute changes, so the visual representation of
            connections remains up to date.
        ]]
        activate = function(self)
            if not CLIENT then return nil end
            signal.connect(self,
                "tags_changed",
                function(_, self)
                    self.m_tag = self.tags:to_array()[1]
                    -- flush the cache
                    for k, v in pairs(self) do
                        if string.sub(k, 1, 9) == "__CACHED_" then
                            v = nil
                        end
                    end
                end
            )
            signal.connect(self,
                "parent_id_changed",
                function(_, self)
                    -- flush the cache
                    for k, v in pairs(self) do
                        if string.sub(k, 1, 9) == "__CACHED_" then
                            v = nil
                        end
                    end
                end
            )
        end,

        --[[!
            Function: run
            In edit mode, this takes care of proper visual representation.
        ]]
        run = CLIENT and function(self, seconds)
            if not ents.get_player().editing then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:to_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 4 then return nil end

            if self.parent_id > 0 and tonumber(arr[2]) > 0 then
                show_distance(
                    "ctl_" .. arr[2] .. "_mrk_" .. self.parent_id,
                    self, 0xFF22C3
                )
            end

            if tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0xFF2222)
            end
        end or nil
    }}, "cutscene_subtitle")
)

--[[!
    Class: cutscene_base_action
    See <cutscene_controller.start>. This can be supplied to
    the controller and then it'll be used as a replacement for
    <action_base>. It has an "action" member, which is a class
    inheriting from <action_base> and THAT will be then used
    by the controller.

    This entity basically encapsulates the base action. That is
    useful, because you can i.e. pass some attributes to the
    base action itself.

    This will most likely be useful only as a base for futher
    inherited entity.

    Properties:
        background_image - a background image that'll display
        over the cutscene. See <gui.hud_image>.
        subtitle_background - see above. A background for subtitle
        area (0.5, 0.9).
]]
ents.register_class(
    plugins.bake(ents.World_Marker, {{
        per_frame = true,

        properties = {
            background_image =    svars.State_String(),
            subtitle_background = svars.State_String()
        },

        --[[!
            Function: init
            Called serverside on entity creation. Sets up defaults.
        ]]
        init = function(self)
            self.background_image    = ""
            self.subtitle_background = ""
        end,

        --[[!
            Function: activate
            Called clientside on entity activation. Sets up callbacks
            for attribute changes, so the visual representation of
            connections remains up to date.
        ]]
        activate = function(self)
            if not CLIENT then return nil end
            signal.connect(self,
                "tags_changed",
                function(_, self)
                    self.m_tag = self.tags:to_array()[1]
                    -- flush the cache
                    for k, v in pairs(self) do
                        if string.sub(k, 1, 9) == "__CACHED_" then
                            v = nil
                        end
                    end
                end
            )
        end,

        --[[!
            Function: run
            In edit mode, this takes care of proper visual representation.
            In both modes, it takes care of that the background_image and
            subtitle_background attributes inside the <action> will be
            always up to date with those of entity.
        ]]
        run = CLIENT and function(self, seconds)
            if self.action.background_image    ~= self.background_image then
               self.action.background_image     = self.background_image end
            if self.action.subtitle_background ~= self.subtitle_background then
               self.action.subtitle_background  = self.subtitle_background end

            if not ents.get_player().editing then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:to_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 3 then return nil end

            if self.m_tag and tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0xFF9A22)
            end
        end or nil,

        --[[!
            Variable: action
            Actual action used by <cutscene_controller>. This
            inherits from <action_base>. By default, it inherits
            start, run and show_subtitle_background
            methods.
        ]]
        action = action_base:clone {
            start = function(self)
                action_base.start(self)

                self.background_image    = ""
                self.subtitle_background = ""
            end,

            run = function(self, seconds)
                if self.background_image ~= "" then
                    self.old_show_hud_image(
                        self.background_image,
                        0.5, 0.5,
                        math.max((_V.scr_w / _V.scr_h), 1),
                        math.min((_V.scr_w / _V.scr_h), 1)
                    )
                end
                return action_base.run(self, seconds)
            end,

            show_subtitle_background = function(self)
                if GLOBAL_GAME_HUD then
                    local factors = GLOBAL_GAME_HUD:calc_factors()
                    if self.subtitle_background ~= "" then
                        self.old_show_hud_image(
                            self.subtitle_background,
                            0.5,
                            0.9,
                            (factors.x * 800) / _V.scr_w,
                            (factors.y * 128) / _V.scr_h
                        )
                    end
                end
            end
        }
    }}, "cutscene_base_action")
)

--[[!
    Class: cutscene_action
    See <cutscene_controller.start>. This can be supplied to
    the controller and then it'll be mixed inside <action_smooth>.

    Same as <cutscene_base_action>, this encapsulates the actual
    <action>, which is represented by a raw table to mix inside
    the smooth action. It can contain start, run and
    finish and user-defined methods.

    This is useful when you need something that manages events,
    like opening doors the camera goes through.
]]
ents.register_class(
    plugins.bake(ents.World_Marker, {{
        per_frame = true,

        --[[!
            Function: activate
            Called clientside on entity activation. Sets up callbacks
            for attribute changes, so the visual representation of
            connections remains up to date.
        ]]
        activate = function(self)
            if not CLIENT then return nil end
            signal.connect(self,
                "tags_changed",
                function(_, self)
                    self.m_tag = self.tags:to_array()[1]
                    -- flush the cache
                    for k, v in pairs(self) do
                        if string.sub(k, 1, 9) == "__CACHED_" then
                            v = nil
                        end
                    end
                end
            )
        end,

        --[[!
            Function: run
            In edit mode, this takes care of proper visual representation.
        ]]
        run = CLIENT and function(self, seconds)
            if not ents.get_player().editing then return nil end

            if not self.m_tag then
                self.m_tag = self.tags:to_array()[1]
                if not self.m_tag then
                    return nil
                end
            end
            local arr = string.split(self.m_tag, "_")
            if #arr ~= 3 then return nil end

            if self.m_tag and tonumber(arr[2]) > 0 then
                show_distance("ctl_" .. arr[2], self, 0x22FFD3)
            end
        end or nil,

        action = {
            -- extend with start, run,
            -- finish, don't forget to call parent
        }
    }}, "cutscene_action")
)
