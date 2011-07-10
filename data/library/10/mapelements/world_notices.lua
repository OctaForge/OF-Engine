module("world_notices", package.seeall)

world_notice = entity_classes.register(plugins.bake(entity_static.area_trigger, {{
    _class     = "world_notice",
    should_act = true,

    properties = {
        text  = state_variables.state_string (),
        color = state_variables.state_integer(),
        size  = state_variables.state_float  (),
        sound = state_variables.state_string (),
        x     = state_variables.state_float  (),
        y     = state_variables.state_float  ()
    },

    init = function(self)
        self.text  = "World notice text"
        self.color = 0xFFFFFF
        self.size  = 0.5
        self.sound = ""
        self.x     = 0.5
        self.y     = 0.88
    end,

    client_activate = function(self)
        self.colliding_time = -1
    end,

    client_act = function(self, seconds)
    end,

    client_on_collision = function(self, entity)
        if entity ~= entity_store.get_player_entity() then return nil end

        if not self.notice_action then
            self.notice_action = world_notice_action()
            self:queue_action(self.notice_action)
        end

        self.colliding_time = GLOBAL_TIME
    end
}}), "mapmodel")

notice_action = class.new(actions.action, {
    can_multiply_queue = false,

    should_continue = function(self)
        return false
    end,

    do_start = function(self)
        self.current_time = 0
        self.current_size_ratio = 0
    end,

    do_execute = function(self, seconds)
        local current_size

        if self:should_continue() then
            if self.curr_time and self.sound and self.sound ~= "" then
                sound.play(self.notice_sound, entity_store.get_player_entity().position:copy())
            end

            self.current_time = self.current_time + seconds * 3
            self.current_time = math.min(math.pi / 2, self.current_time)
            self.current_size_ratio = math.sin(self.current_time)
            current_size = self.current_size_ratio * self.size
        else
            self.current_time = self.current_time - seconds * 4
            self.current_time = math.max(0, self.current_time)
            self.current_size_ratio = math.sin(self.current_time)
            current_size = self.current_size_ratio * self.size
        end

        if self.current_time ~= 0 and self.text then
            gui.showhudtext(self.text, self.x, self.y, current_size, self.color)
        end

        return (self.current_time == 0)
    end
})

world_notice_action = class.new(notice_action, {
    do_start = function(self)
        notice_action.do_start(self)

        self.text  = self.actor.text
        self.color = self.actor.color
        self.size  = self.actor.size
        self.sound = self.actor.sound
        self.x     = self.actor.x
        self.y     = self.actor.y
    end,

    should_continue = function(self)
        return ((GLOBAL_TIME - self.actor.colliding_time) <= 0.5)
    end,

    do_finish = function(self)
        actions.action.do_finish(self)
        self.actor.notice_action = nil
    end
})
