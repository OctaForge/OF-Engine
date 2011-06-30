module("world_areas", package.seeall)

active = nil

plugin = {
    should_act = true,

    client_on_collision = function(self, entity)
        if entity ~= entity_store.get_plyent() then return nil end

        -- cannot have more than one active
        if active then return nil end

        active = self
        self:queue_action(action_input_capture())
    end
}

action = class.new(actions.action, {
    dostart = function(self)
        assert(active == self.actor)
    end,

    doexecute = function(self, seconds)
        if world.is_player_colliding_entity(entity_store.get_plyent(), self.actor) then
            self.actor:emit("world_area_active")
            return false
        else
            return true
        end
    end,

    dofinish = function(self)
        active = nil
    end
})

action_input_capture = class.new(actions.action, {
    dostart = function(self)
        self.client_click = function(self, ...) return self.actor.client_click(self.actor, ...) end

        self.per_map_keys  = self.actor.per_map_keys
        self.self.action_key_self = self.actor

        self.do_movement  = function(self, ...) return self.actor.do_movement (self.actor, ...) end
        self.do_mousemove = function(self, ...) return self.actor.do_mousemove(self.actor, ...) end
        self.do_jump      = function(self, ...) return self.actor.do_jump     (self.actor, ...) end

        events.action_input_capture_plugin.dostart(self)
    end,

    dofinish = events.action_input_capture_plugin.dofinish
})
