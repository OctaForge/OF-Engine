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
            _G["client_click"] = self.client_click
        end
        if self.action_keys then
            self.old_action_keys = {}
            for key, action in pairs(self.action_keys) do
                self.old_action_keys[key] = console.binds.get_action_key(key)
                console.binds.add_action_key(key, action)
            end
        end
        if self.do_movement then
            self.old_do_movement = _G["do_movement"]
            _G["do_movement"] = self.do_movement
        end
        if self.do_mousemove then
            self.old_do_mousemove = _G["do_mousemove"]
            _G["do_mousemove"] = self.do_mousemove
        end
        if self.do_jump then
            self.old_do_jump = _G["do_jump"]
            _G["do_jump"] = self.do_jump
        end
    end,

    dofinish = function(self)
        if self.client_click then
            _G["client_click"] = self.old_client_click
        end
        if self.action_keys then
            for key, action in pairs(self.old_action_keys) do
                console.binds.add_action_key(key, action)
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
