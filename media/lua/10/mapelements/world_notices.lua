local sound = require("core.engine.sound")
local frame = require("core.events.frame")
local actions = require("core.events.actions")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")

module("world_notices", package.seeall)

world_notice = ents.register_class(plugins.bake(ents.Obstacle, {{
    per_frame = true,

    properties = {
        text  = svars.State_String(),
        color = svars.State_Integer(),
        size  = svars.State_Float(),
        sound = svars.State_String(),
        x     = svars.State_Float(),
        y     = svars.State_Float()
    },

    init = function(self)
        self:set_attr("text", "World notice text")
        self:set_attr("color", 0xFFFFFF)
        self:set_attr("size", 0.5)
        self:set_attr("sound", "")
        self:set_attr("x", 0.5)
        self:set_attr("y", 0.88)
    end,

    activate = (not SERVER) and function(self)
        self.colliding_time = -1
        signal.connect(self, "collision", self.client_on_collision)
    end or nil,

    run = (not SERVER) and function(self, seconds)
    end or nil,

    client_on_collision = function(self, entity)
        if entity ~= ents.get_player() then return nil end

        if not self.notice_action then
            self.notice_action = world_notice_action()
            self:queue_action(self.notice_action)
        end

        self.colliding_time = frame.get_time()
    end
}}, "world_notice"))

notice_action = actions.Action:clone {
    can_multiply_queue = false,

    should_continue = function(self)
        return false
    end,

    start = function(self)
        self.current_time = 0
        self.current_size_ratio = 0
    end,

    run = function(self, seconds)
        local current_size

        if self:should_continue() then
            if self.curr_time and self.sound and self.sound ~= "" then
                sound.play(self.sound, ents.get_player():get_attr("position"):copy())
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
            --gui.hud_label(self.text, self.x, self.y, current_size, self.color)
        end

        return (self.current_time == 0)
    end
}

world_notice_action = notice_action:clone {
    start = function(self)
        notice_action.start(self)

        self.text  = self.actor:get_attr("text")
        self.color = self.actor:get_attr("color")
        self.size  = self.actor:get_attr("size")
        self.sound = self.actor:get_attr("sound")
        self.x     = self.actor:get_attr("x")
        self.y     = self.actor:get_attr("y")
    end,

    should_continue = function(self)
        return ((frame.get_time() - self.actor.colliding_time) <= 0.5)
    end,

    finish = function(self)
        actions.Action.finish(self)
        self.actor.notice_action = nil
    end
}
