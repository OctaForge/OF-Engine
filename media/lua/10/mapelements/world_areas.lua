local actions = require("core.events.actions")
local signal = require("core.events.signal")

module("world_areas", package.seeall)

active = nil

plugin = {
    per_frame = true,

    client_on_collision = function(self, entity)
        if entity ~= ents.get_player() then return nil end

        -- cannot have more than one active
        if active then return nil end

        active = self
        self:queue_action(action_input_capture())
    end,
    activate = CLIENT and function(self)
        signal.connect(self, "collision", self.client_on_collision)
    end or nil
}

action = actions.Action:clone {
    start = function(self)
        assert(active == self.actor)
    end,

    run = function(self, seconds)
        if geometry.is_player_colliding_entity(ents.get_player(), self.actor) then
            signal.emit(self.actor, "world_area_active")
            return false
        else
            return true
        end
    end,

    finish = function(self)
        active = nil
    end
}

action_input_capture = actions.Action:clone {
    start = function(self)
        self.click = CLIENT and function(self, ...)
            return self.actor.click(self.actor, ...)
        end or nil

        self.per_map_keys  = self.actor.per_map_keys
        self.self.action_key_self = self.actor

        self.do_movement  = function(self, ...) return self.actor.do_movement (self.actor, ...) end
        self.do_mousemove = function(self, ...) return self.actor.do_mousemove(self.actor, ...) end
        self.do_jump      = function(self, ...) return self.actor.do_jump     (self.actor, ...) end

        extraevents.action_input_capture_plugin.start(self)
    end,

    finish = extraevents.action_input_capture_plugin.finish
}
