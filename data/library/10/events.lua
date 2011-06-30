module("events", package.seeall)

-- action that can queue more actions on itself, which run on its actor,
-- finishes when both this action an all subactions are done.
action_container = class.new(actions.action)

function action_container:__tostring() return "action_container" end

function action_container:__init(other_actions, kwargs)
    actions.action.__init(self, kwargs)
    self.other_actions = other_actions
end

function action_container:dostart()
    self.action_system = actions.action_system(self.actor)

    for k, other_action in pairs(self.other_actions) do
        self.action_system:queue(other_action)
    end
end

function action_container:doexecute(seconds)
    self.action_system:manage(seconds)
    return actions.action.doexecute(self, seconds)
       and self.action_system:isempty()
end

function action_container:dofinish()
    if not self.action_system:isempty() and self.action_system.actlist[1].begun then
        self.action_system.actlist[1]:finish()
    end
end

function action_container:cancel()
    self.action_system:clear()
    self.action_system:manage(0.01)
    self:finish()
end

-- like action_container, but runs actions in parallel - finishes when all are done
action_parallel = class.new(actions.action)
action_parallel.canbecancelled = false

function action_parallel:__tostring() return "action_parallel" end

function action_parallel:__init(other_actions, kwargs)
    actions.action.__init(self, kwargs)
    self.action_systems = {}
    self.other_actions  = other_actions
end

function action_parallel:dostart()
    for k, other_action in pairs(self.other_actions) do
        self:add_action(other_action)
    end
end

function action_parallel:doexecute(seconds)
    self.action_systems = table.filter(
        self.action_systems,
        function(i, action_system)
            action_system:manage(seconds)
            return (not action_system:isempty())
        end
    )
    return actions.action.doexecute(self, seconds)
     and (#self.action_systems == 0)
end

function action_parallel:dofinish()
    for k, action_system in pairs(self.action_systems) do
        action_system:clear()
    end
end

function action_parallel:add_action(other_action)
    local action_system = actions.action_system(self.actor)
    action_system:queue(other_action)
    table.insert(self.action_systems, action_system)
end

action_delayed = class.new(actions.action)

function action_delayed:__tostring() return "action_delayed" end

function action_delayed:__init(command, kwargs)
    actions.action.__init(self, kwargs)
    self.command = command
end

function action_delayed:doexecute()
    if actions.action.doexecute(self, seconds) then
        self.command()
        return true
    else
        return false
    end
end

action_input_capture_plugin = {
    dostart = function(self)
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

    dofinish = function(self)
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

action_input_capture = class.new(actions.action, action_input_capture_plugin)
function action_input_capture:__tostring() return "action_input_capture" end

action_render_capture_plugin = {
    dostart = function(self, ...)
        self.__base.dostart(self, ...)

        if  self.render_dynamic then
            self.render_dynamic_old =  _G["render_dynamic"]
             _G["render_dynamic"]   = self.render_dynamic
        end
        if  self.render_hud_models then
            self.render_hud_models_old =  _G["render_hud_models"]
             _G["render_hud_models"]   = self.render_hud_models
        end
    end,

    dofinish = function(self, ...)
        if  self.render_dynamic then
             _G["render_dynamic"] = self.render_dynamic_old
        end
        if  self.render_hud_models then
             _G["render_hud_models"] = self.render_hud_models_old
        end

        self.__base.dofinish(self, ...)
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

_action_system_parallel_manager = class.new(class.new(nil, action_system_plugin), {
    __init = function(self, owner)
        self.__base.__init(self, owner)

        self.action = action_parallel({})
        self.action_system:queue(self.action)
    end
})

client_actions_parallel_plugin = {
    client_activate = function(self)
        self.action_system_parallel_manager = _action_system_parallel_manager(self)
    end,

    client_act = function(self, seconds)
        self.action_system_parallel_manager.action.secondsleft = seconds + 1.0 -- never end
        self.action_system_parallel_manager:tick(seconds)
    end,

    add_action_parallel = function(self, action)
        self.action_system_parallel_manager.action:add_action(action)
    end
}

actions_parallel_plugin = {
    activate = client_actions_parallel_plugin.client_activate,
    act = client_actions_parallel_plugin.client_act
}

