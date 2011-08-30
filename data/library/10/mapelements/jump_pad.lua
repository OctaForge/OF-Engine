module("jump_pad", package.seeall)

plugin = {
    properties = {
        jump_velocity = state_variables.state_vec3(),
        pad_model  = state_variables.state_string(),
        pad_rotate = state_variables.state_bool(),
        pad_pitch  = state_variables.state_integer(),
        pad_sound  = state_variables.state_string()
    },

    should_act = true,

    init = function(self)
        self.jump_velocity = { 0, 0, 500 } -- default
        self.pad_model     = ""
        self.pad_rotate    = false
        self.pad_pitch     = 90
        self.pad_sound     = ""
        self.collision_radius_width  = 3
        self.collision_radius_height = 0.5
    end,

    client_activate = function(self)
        self.player_delay = -1
    end,

    client_act = function(self, seconds)
        if  self.player_delay > 0 then
            self.player_delay = self.player_delay - seconds
        end
    end,

    client_on_collision = function(self, collider)
        -- each player handles themselves
        if collider ~= entity_store.get_player_entity() then return nil end

        -- do not trigger many times each jump
        if self.player_delay > 0 then return nil end
           self.player_delay = 0.5

        -- throw collider up
        collider.velocity = self.jump_velocity:as_array()

        if self.pad_sound ~= "" then
            sound.play(self.pad_sound)
        end
    end,

    render_dynamic = function(self)
        if self.pad_model == "" then return nil end

        local o = self.position
        local flags = math.bor(
            model.LIGHT, model.CULL_VFC,
            model.OCCLUDED, model.CULL_QUERY,
            model.FULLBRIGHT, model.CULL_DIST,
            model.DYNSHADOW
        )
        local yaw
        if self.pad_rotate then
            yaw = -(GLOBAL_TIME * 120) % 360
        end

        model.render(
            self, self.pad_model,
            math.bor(actions.ANIM_IDLE, actions.ANIM_LOOP),
            o, yaw and yaw or self.yaw, self.pad_pitch,
            flags, 0
        )
    end
}

entity_classes.register(
    plugins.bake(
        entity_static.area_trigger,
        { plugin },
        "jump_pad"
    ),
    "mapmodel"
)
