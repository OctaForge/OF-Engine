module("jump_pad", package.seeall)

plugin = {
    properties = {
        jump_velocity = svars.State_Vec3(),
        pad_model  = svars.State_String(),
        pad_rotate = svars.State_Boolean(),
        pad_pitch  = svars.State_Integer(),
        pad_sound  = svars.State_String()
    },

    per_frame = true,

    init = function(self)
        self.jump_velocity = { 0, 0, 500 } -- default
        self.pad_model     = ""
        self.pad_rotate    = false
        self.pad_pitch     = 90
        self.pad_sound     = ""
        self.collision_radius_width  = 3
        self.collision_radius_height = 0.5
    end,

    activate = CLIENT and function(self)
        self.player_delay = -1
        signal.connect(self, "collision", self.client_on_collision)
    end or nil,

    run = CLIENT and function(self, seconds)
        if  self.player_delay > 0 then
            self.player_delay = self.player_delay - seconds
        end
    end or nil,

    client_on_collision = function(_, self, collider)
        -- each player handles themselves
        if collider ~= ents.get_player() then return nil end

        -- do not trigger many times each jump
        if self.player_delay > 0 then return nil end
           self.player_delay = 0.5

        -- throw collider up
        collider.velocity = self.jump_velocity:to_array()

        if self.pad_sound ~= "" then
            sound.play(self.pad_sound)
        end
    end,

    render = function(self)
        if self.pad_model == "" then return nil end

        local o = self.position
        local flags = math.bor(
            model.CULL_VFC, model.OCCLUDED, model.CULL_QUERY,
            model.FULLBRIGHT, model.CULL_DIST
        )
        local yaw
        if self.pad_rotate then
            yaw = -(frame.get_time() * 120) % 360
        end

        model.render(
            self, self.pad_model,
            math.bor(model.ANIM_IDLE, model.ANIM_LOOP),
            o, yaw and yaw or self.yaw, self.pad_pitch,
            flags, 0
        )
    end
}

ents.register_class(plugins.bake(
    ents.Area_Trigger,
    { plugin },
    "jump_pad"
))
