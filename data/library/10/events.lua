module("events", package.seeall)

repeating_timer = std.class.new(nil, {
    __tostring = function(self)
        return string.format(
            "repeating_timer: %s %s %s",
            tostring(self.interval),
            tostring(self.carry_over),
            tostring(self.sum)
        )
    end,

    __init = function(self, interval, carry_over)
        self.interval   = interval
        self.carry_over = carry_over or false
        self.sum        = 0
    end,

    tick = function(self, seconds)
        self.sum = self.sum + seconds

        if  self.sum >= self.interval then
            self.sum  = self.carry_over
                and (self.sum - self.interval)
                or 0
            return true
        else
            return false
        end
    end,

    prime = function(self)
        self.sum = self.interval
    end
}, "repeating_timer")

-- action that can queue more actions on itself, which run on its actor,
-- finishes when both this action an all subactions are done.
action_container = std.class.new(actions.action, {
    __init = function(self, other_actions, kwargs)
        actions.action.__init(self, kwargs)
        self.other_actions = other_actions
    end,

    do_start = function(self)
        self.action_system = actions.action_system(self.actor)

        for k, other_action in pairs(self.other_actions) do
            self.action_system:queue(other_action)
        end
    end,

    do_execute = function(self, seconds)
        self.action_system:manage(seconds)
        return actions.action.do_execute(self, seconds)
           and self.action_system:is_empty()
    end,

    do_finish = function(self)
        if not self.action_system:is_empty()
           and self.action_system.action_list[1].begun then
            self.action_system.action_list[1]:finish()
        end
    end,

    cancel = function(self)
        self.action_system:clear()
        self.action_system:manage(0.01)
        self:finish()
    end
}, "action_container")

-- like action_container, but runs actions in parallel - finishes when all are done
action_parallel = std.class.new(actions.action, {
    cancellable = false,

    __init = function(self, other_actions, kwargs)
        actions.action.__init(self, kwargs)
        self.action_systems = {}
        self.other_actions  = other_actions
    end,

    do_start = function(self)
        for k, other_action in pairs(self.other_actions) do
            self:add_action(other_action)
        end
    end,

    do_execute = function(self, seconds)
        self.action_systems = table.filter_dict(
            self.action_systems,
            function(i, action_system)
                action_system:manage(seconds)
                return (not action_system:is_empty())
            end
        )
        return actions.action.do_execute(self, seconds)
         and (#self.action_systems == 0)
    end,

    do_finish = function(self)
        for k, action_system in pairs(self.action_systems) do
            action_system:clear()
        end
    end,

    add_action = function(self, other_action)
        local action_system = actions.action_system(self.actor)
        action_system:queue(other_action)
        table.insert(self.action_systems, action_system)
    end
}, "action_parallel")

action_delayed = std.class.new(actions.action, {
    __init = function(self, command, kwargs)
        actions.action.__init(self, kwargs)
        self.command = command
    end,

    do_execute = function(self, seconds)
        if actions.action.do_execute(self, seconds) then
            self.command()
            return true
        else
            return false
        end
    end
}, "action_delayed")

action_input_capture_plugin = {
    do_start = function(self)
        if self.client_click then
            self.old_client_click = _G["client_click"]
            _G["client_click"] = function(...) self.client_click(self, ...) end
        end
        if self.per_map_keys then
            self.old_per_map_keys = {}
            for key, action in pairs(self.per_map_keys) do
                self.old_per_map_keys[key] = input.get_bind(key, input.BIND_MAP)
                input.bind_map_specific(key, action, self.action_key_self or self)
            end
        end
        if self.do_movement then
            self.old_do_movement = _G["do_movement"]
            _G["do_movement"] = function(...) self.do_movement(self, ...) end
        end
        if self.do_mousemove then
            self.old_do_mousemove = _G["do_mousemove"]
            _G["do_mousemove"] = function(...) return self.do_mousemove(self, ...) end 
        end
        if self.do_jump then
            self.old_do_jump = _G["do_jump"]
            _G["do_jump"] = function(...) self.do_jump(self, ...) end
        end
    end,

    do_finish = function(self)
        if self.client_click then
            _G["client_click"] = self.old_client_click
        end
        if self.per_map_keys then
            for key, action in pairs(self.old_per_map_keys) do
                input.bind_map_specific(key, action)
            end
        end
        if self.do_movement then
            _G["do_movement"] = self.old_do_movement
        end
        if self.do_mousemove then
            _G["do_mousemove"] = self.old_do_mousemove
        end
        if self.do_jump then
            _G["do_jump"] = self.old_do_jump
        end
    end
}

action_input_capture = std.class.new(
    actions.action,
    action_input_capture_plugin,
    "action_input_capture"
)

action_render_capture_plugin = {
    do_start = function(self, ...)
        self.base_class.do_start(self, ...)

        if  self.render_dynamic then
            self.render_dynamic_old     = entity_store.render_dynamic
            entity_store.render_dynamic = self.render_dynamic
        end
        if  self.render_hud_model then
            self.render_hud_model_old     = entity_store.render_hud_model
            entity_store.render_hud_model = self.render_hud_model
        end
    end,

    do_finish = function(self, ...)
        if self.render_dynamic then
            entity_store.render_dynamic = self.render_dynamic_old
        end
        if self.render_hud_model then
            entity_store.render_hud_model = self.render_hud_model_old
        end

        self.base_class.do_finish(self, ...)
    end
}

action_system_plugin = {
    __init = function(self, owner)
        self.action_system = actions.action_system(owner and owner or self)
    end,

    tick = function(self, seconds)
        self.action_system:manage(seconds)
    end
}

_action_system_parallel_manager = std.class.new(std.class.new(nil, action_system_plugin), {
    __init = function(self, owner)
        self.base_class.__init(self, owner)

        self.action = action_parallel({})
        self.action_system:queue(self.action)
    end
})

client_actions_parallel_plugin = {
    client_activate = function(self)
        self.action_system_parallel_manager = _action_system_parallel_manager(self)
    end,

    client_act = function(self, seconds)
        self.action_system_parallel_manager.action.seconds_left = seconds + 1.0 -- never end
        self.action_system_parallel_manager:tick(seconds)
    end,

    add_action_parallel = function(self, action)
        self.action_system_parallel_manager.action:add_action(action)
    end
}

actions_parallel_plugin = table.merge_dicts(client_actions_parallel_plugin, {
    activate = client_actions_parallel_plugin.client_activate,
    act = client_actions_parallel_plugin.client_act
})

