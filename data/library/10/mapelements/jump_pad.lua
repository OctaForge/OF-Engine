module("jump_pad", package.seeall)

plugin = {
    properties = {
        jump_velocity = svars.State_Vec3(),
        pad_model  = svars.State_String(),
        pad_rotate = svars.State_Boolean(),
        pad_pitch  = svars.State_Integer(),
        pad_roll   = svars.State_Integer(),
        pad_sound  = svars.State_String()
    },

    per_frame = true,

    init = function(self)
        self.jump_velocity = { 0, 0, 500 } -- default
        self.pad_model     = ""
        self.pad_rotate    = false
        self.pad_pitch     = 90
        self.pad_roll      = 0
        self.pad_sound     = ""
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

    client_on_collision = function(self, collider)
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
            model.render_flags.CULL_VFC, model.render_flags.OCCLUDED, model.render_flags.CULL_QUERY,
            model.render_flags.FULLBRIGHT, model.render_flags.CULL_DIST
        )
        local yaw
        if self.pad_rotate then
            yaw = -(frame.get_time() * 120) % 360
        end

        model.render(
            self, self.pad_model,
            math.bor(model.anims.IDLE, model.anims.LOOP),
            o, yaw and yaw or self.yaw, self.pad_pitch, self.pad_roll,
            flags, 0
        )
    end
}

ents.register_class(plugins.bake(
    ents.Area_Trigger,
    { plugin },
    "jump_pad"
))
