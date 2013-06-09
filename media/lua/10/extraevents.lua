local actions = require("core.events.actions")

module("extraevents", package.seeall)

repeating_timer = table.Object:clone {
    name = "repeating_timer",

    __inst_tostring = function(self)
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
}

-- action that can queue more actions on itself, which run on its actor,
-- finishes when both this action an all subactions are done.
action_container = actions.Action:clone {
    name = "action_container",

    __init = function(self, other_actions, kwargs)
        actions.Action.__init(self, kwargs)
        self.other_actions = other_actions
    end,

    start = function(self)
        self.action_system = actions.Action_System(self.actor)

        for k, other_action in pairs(self.other_actions) do
            self.action_system:queue(other_action)
        end
    end,

    run = function(self, seconds)
        self.action_system:run(seconds)
        return actions.Action.run(self, seconds)
           and #self.action_system:get() == 0
    end,

    finish = function(self)
        local sys = self.action_system:get()
        if not #sys == 0 and sys[1].begun then
            sys[1]:finish()
        end
    end,

    cancel = function(self)
        self.action_system:clear()
        self.action_system:run(0.01)
        self:finish()
    end
}

-- like action_container, but runs actions in parallel - finishes when all are done
action_parallel = actions.Action:clone {
    name = "action_parallel",
    cancellable = false,

    __init = function(self, other_actions, kwargs)
        actions.Action.__init(self, kwargs)
        self.action_systems = {}
        self.other_actions  = other_actions
    end,

    start = function(self)
        for k, other_action in pairs(self.other_actions) do
            self:add_action(other_action)
        end
    end,

    run = function(self, seconds)
        self.action_systems = table.filter(
            self.action_systems,
            function(i, action_system)
                action_system:run(seconds)
                return (not (#action_system:get() == 0))
            end
        )
        return actions.Action.run(self, seconds)
         and (#self.action_systems == 0)
    end,

    finish = function(self)
        for k, action_system in pairs(self.action_systems) do
            action_system:clear()
        end
    end,

    add_action = function(self, other_action)
        local action_system = actions.Action_System(self.actor)
        action_system:queue(other_action)
        local sys = self.action_systems
        sys[#sys + 1] = action_system
    end
}

action_delayed = actions.Action:clone {
    name = "action_delayed",

    __init = function(self, command, kwargs)
        actions.Action.__init(self, kwargs)
        self.command = command
    end,

    run = function(self, seconds)
        if actions.Action.run(self, seconds) then
            self.command()
            return true
        else
            return false
        end
    end
}

local set_external = _C.external_set

action_input_capture_plugin = {
    name = "action_input_capture",

    start = function(self)
        if self.click then
            self.old_click = set_external("input_click_client", function(...)
                return self:click(...)
            end)
        end
        --if self.per_map_keys then
        --    self.old_per_map_keys = {}
        --    for key, action in pairs(self.per_map_keys) do
        --        self.old_per_map_keys[key] = input.get_bind(key, input.BIND_MAP)
        --        input.bind_map_specific(key, action, self.action_key_self or self)
        --    end
        --end
        if self.do_movement then
            self.old_do_movement = set_external("input_move", function(...)
                self.do_movement(self, ...)
            end)
        end
        if self.do_mousemove then
            self.old_do_mousemove = set_external("input_mouse_move", function(...)
                return self.do_mousemove(self, ...)
            end) 
        end
        if self.do_jump then
            self.old_do_jump = set_external("input_jump", function(...)
                self.do_jump(self, ...)
            end)
        end
    end,

    finish = function(self)
        if self.click then
            set_external("input_click_client", self.old_click)
            self.old_click = nil
        end
        --if self.per_map_keys then
        --    for key, action in pairs(self.old_per_map_keys) do
        --        input.bind_map_specific(key, action)
        --    end
        --end
        if self.do_movement then
            set_external("input_move", self.old_do_movement)
        end
        if self.do_mousemove then
            set_external("input_mouse_move", self.old_do_mousemove)
        end
        if self.do_jump then
            set_external("input_jump", self.old_do_jump)
        end
    end
}

action_input_capture = actions.Action:clone(action_input_capture_plugin)

action_render_capture_plugin = {
    start = function(self, ...)
        self.__proto.__proto.start(self, ...)

        if  self.render then
            self.render_old = set_external("game_render", self.render)
        end
        if  self.render_hud_model then
            self.render_hud_old = set_external("game_render_hud",
                self.render_hud_model)
        end
    end,

    finish = function(self, ...)
        if self.render then
            set_external("game_render", self.render_old)
            self.render_old = nil
        end
        if self.render_hud_model then
            set_external("game_render_hud", self.render_hud_old)
            self.render_hud_old = nil
        end

        self.__proto.__proto.finish(self, ...)
    end
}

action_system_plugin = {
    __init = function(self, owner)
        self.action_system = actions.Action_System(owner and owner or self)
    end,

    tick = function(self, seconds)
        self.action_system:run(seconds)
    end
}

_action_system_parallel_manager = table.Object:clone(action_system_plugin):clone {
    __init = function(self, owner)
        self.__proto.__proto.__init(self, owner)

        self.action = action_parallel({})
        self.action_system:queue(self.action)
    end
}

actions_parallel_plugin = {
    activate = function(self)
        self.action_system_parallel_manager = _action_system_parallel_manager(self)
    end,

    run = function(self, seconds)
        self.action_system_parallel_manager.action.seconds_left = seconds + 1.0 -- never end
        self.action_system_parallel_manager:tick(seconds)
    end,

    add_action_parallel = function(self, action)
        self.action_system_parallel_manager.action:add_action(action)
    end
}
