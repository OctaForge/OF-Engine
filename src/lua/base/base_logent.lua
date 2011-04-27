---
-- base_logent.lua, version 1<br/>
-- Logic entity system for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 OctaForge project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

--- This module takes care of logic entities.
-- client_logent / server_logent will become only "logent",
-- depending on if we're on client or on server.
-- @class module
-- @name of.logent
module("of.logent", package.seeall)

assert(of.global.CLIENT or of.global.SERVER)
assert(not (of.global.CLIENT and of.global.SERVER))
of.logging.log(of.logging.DEBUG, "Generating logent system with CLIENT = " .. tostring(of.global.CLIENT))

--- Root logic entity class, not meant to be used directly.
-- @class table
-- @name root_logent
root_logent = class.new()
root_logent._class = "logent"
root_logent.should_act = true

--- Base properties of animatable logic entity.
-- @field tags Entity tags, user defined, can be used for i.e. lookups of specific entities.
-- @field _persistent If this is true, entity gets saved on disk. True for static entities only.
-- @class table
-- @name root_logent.properties
root_logent.properties = {
    { "tags", of.state_variables.state_array() },
    { "_persistent", of.state_variables.state_bool() }
}

--- Automatically substitute for class name when tostring() is called on entity.
-- @return Class name.
function root_logent:__tostring() return self._class end

--- General setup method. Performs some initialization magic like signal
-- methods adding, state variable values table, state variable setup etc.
function root_logent:_general_setup()
    of.logging.log(of.logging.DEBUG, "root_logent:_general_setup")

    if self._general_setup_complete then return nil end
    of.signals.methods_add(self)

    self.action_system = actions.action_system(self)
    self.state_var_vals = {}
    -- caching reads from script into c++ (search for -- caching)
    self.state_var_val_timestamps = {}

    self.deactivated = false
    self:_setup_vars()
    self._general_setup_complete = true
end

--- General deactivation, clears action system, unregister entity in C and
-- marks this entity deactivated.
function root_logent:_general_deactivate()
    self:clear_actions()
    CAPI.unreglogent(self.uid)
    self.deactivated = true
end

--- Get state data locally from table.
-- @param k Property name.
-- @return Property value.
function root_logent:_get_statedata(k)
    return self.state_var_vals[tostring(k)]
end

--- Act method ran every frame. Manages action system by default.
-- Can be overriden, but make sure to call the original method everytime.
-- @param sec Length of the time to simulate.
function root_logent:act(sec)
    self.action_system:manage(sec)
end

--- Queue an action.
-- @param act The action to queue.
function root_logent:queue_action(act)
    self.action_system:queue(act)
end

--- Clear action queue.
function root_logent:clear_actions()
    self.action_system:clear()
end

--- Add a tag. Tags can be later used for lookups.
-- @param t Tag to add, a string.
function root_logent:add_tag(t)
    if not self:has_tag(t) then
        self.tags:push(t)
    end
end

--- Delete a tag.
-- @param t Tag to delete, string.
function root_logent:del_tag(t)
    of.logging.log(of.logging.DEBUG, "root_logent:del_tag(\"" .. tostring(t) .. "\")")
    self.tags = table.filterarray(self.tags:as_array(), function(i, tag) return tag ~= t end)
end

--- Check whether an entity has a tag.
-- @param t Tag to lookup, string.
function root_logent:has_tag(t)
    of.logging.log(of.logging.INFO, "i can has tag " .. tostring(t))
    return (table.find(self.tags:as_array(), t) ~= nil)
end

--- Setup state variables of the entity. Performs registration for each.
function root_logent:_setup_vars()
    for i = 1, #self.properties do
        local var = self.properties[i][2]
        if of.state_variables.is(var) then
            var:_register(self.properties[i][1], self)
        end
    end
end

--- Create state data dictionary. That gets returned as of.json. Names
-- can be compressed as protocol IDs, so bandwidth is saved (returned
-- JSON is sent through network later). Compression can be set
-- with kwargs - you have to provide "compressed" element with
-- "true" value in order to do so.
-- @param tcn Client number to send state data to. When nil, it's sent to all clients.
-- @param kwargs Additional parameter table.
-- @return JSON with state data (string).
-- @see root_logent:_update_statedata_complete
function root_logent:create_statedatadict(tcn, kwargs)
    tcn = tcn or of.msgsys.ALL_CLIENTS
    kwargs = kwargs or {}

    of.logging.log(of.logging.DEBUG, "create_statedatadict(): " .. tostring(self) .. tostring(self.uid) .. ", " .. tostring(tcn))

    local r = {}
    local _names = table.keys(self)
    for i = 1, #_names do
        local var = self[_names[i]]
        if of.state_variables.is(var) and var.hashistory then
            -- do not send private data
            local skip = false
            if tcn >= 0 and not var:should_send(self, tcn) then skip = true end
            if not skip then
                local val = self[var._name]
                if val then
                    of.logging.log(of.logging.DEBUG, "create_statedatadict() adding " .. tostring(var._name) .. ": " .. of.json.encode(val))
                    r[not kwargs.compressed and var._name or of.msgsys.toproid(tostring(self), var._name)] = var:to_data(val)
                    of.logging.log(of.logging.DEBUG, "create_statedatadict() currently: " .. of.json.encode(r))
                end
            end
        end
    end

    of.logging.log(of.logging.DEBUG, "create_statedatadict() returns: " .. of.json.encode(r))
    if not kwargs.compressed then return r end

    -- pre-compression: keep numbers as numbers, not strings
    _names = table.keys(r)
    for i = 1, #_names do
        if tonumber(r[_names[i]]) and r[_names[i]] ~= "" then
            r[_names[i]] = tonumber(r[_names[i]])
        end
    end

    r = of.json.encode(r)
    of.logging.log(of.logging.DEBUG, "pre-compression: " .. r)

    local _filters = {
        function(d) return string.gsub(d, "\", \"", "\",\"") end, -- "foo", "bar" --> "foo","bar"
        --function(d) return string.gsub(d, "\"%[%]\"", "%[%]") end, -- "[]" --> []
        function(d) return string.gsub(d, ":\"(%d+)\.(%d+)\"", ":\"%1\".\"%2\"") end, -- :"3.14" --> :"3"."14"
        function(d) return string.gsub(d, ", ", ",") end -- ", " --> "," (without quotes)
    }
    for i = 1, #_filters do
        local n = _filters[i](r)
        if #n < #r and of.json.encode(of.json.decode(n)) == of.json.encode(of.json.decode(r)) then
            r = n
        end
    end

    of.logging.log(of.logging.DEBUG, "compressed: " .. r)

    return string.sub(r, 2, #r - 1) -- remove {}
end

--- Update state data from string created by create_statedatadict.
-- @param sd State data JSON string.
-- @see root_logent:create_statedatadict
function root_logent:_update_statedata_complete(sd)
    of.logging.log(of.logging.DEBUG, "updating complete state data for " .. tostring(self.uid) .. " with " .. tostring(sd) .. " (" .. type(sd) .. ")")

    sd = string.sub(sd, 1, 1) ~= "{" and "{" .. sd .. "}" or sd
    local nsd = of.json.decode(sd)

    assert(type(nsd) == "table")

    self.initialized = true
    for k, v in pairs(nsd) do
        k = tonumber(k) and of.msgsys.fromproid(tostring(self), tonumber(k)) or k
        of.logging.log(of.logging.DEBUG, "update of complete state data: " .. tostring(k) .. " = " .. tostring(v))
        self:_set_statedata(k, v, nil, true) -- true - this is internal op, we are sending raw state data
        of.logging.log(of.logging.DEBUG, "update of complete state data ok")
    end

    of.logging.log(of.logging.DEBUG, "update of complete state data done.")
end

--- Client version of root logic entity.
-- @class table
-- @name client_logent
client_logent = class.new(root_logent)

--- Entity activation.
-- @param kwargs This in fact doesn't do anything, but it makes effect on entities inherited from this.
function client_logent:client_activate(kwargs)
    self:_general_setup()

    if not self._sauertype then
        of.logging.log("non-sauer entity going to be set up: " .. tostring(self) .. ", " .. tostring(self._sauertype))
        CAPI.setupnonsauer(self) -- does c++ reg etc, sauer types need special reg which is done by them
    end

    -- set to true when we receive complete sd from server
    self.initialized = false
end

--- Entity deactivation. Calls _general_deactivate by default, though can be overriden.
function client_logent:client_deactivate()
    self:_general_deactivate()
end

--- Set entity state data. This is clientside only function.
-- @param k Property name.
-- @param v Property value.
-- @param auid Unique ID of the actor.
function client_logent:_set_statedata(k, v, auid)
    of.logging.log(of.logging.DEBUG, "setting state data: " .. tostring(k) .. " = " .. of.json.encode(v) .. " for " .. tostring(self.uid))
    local var = self[of.state_variables._SV_PREFIX .. tostring(k)]

    local customsynch_fromhere = var.customsynch and self._controlled_here
    local clientset = var.clientset

    if auid == -1 and not customsynch_fromhere then
        of.logging.log(of.logging.DEBUG, "sending request / notification to server.")
        -- todo: supress msg sending of the same val, at least for some SVs
        of.msgsys.send(var.reliable and CAPI.statedata_changerequest or CAPI.statedata_changerequest_unreliable,
                    self.uid,
                    of.msgsys.toproid(tostring(self),
                    tostring(var._name)), var:to_wire(v))
    end

    if auid ~= -1 or clientset or customsynch_fromhere then
        of.logging.log(of.logging.DEBUG, "updating locally")
        -- if originated from server, translated
        if auid ~= -1 then v = var:from_wire(v) end
        assert(var:validate(v))
        self:emit(of.state_variables.get_onmodify_prefix() .. tostring(k), v, auid ~= -1)
        self.state_var_vals[k] = v
    end
end

--- Act method which is ran every frame. Performs action system management by default.
-- @param sec Length of the time to simulate.
function client_logent:client_act(sec)
    of.logging.log(of.logging.INFO, "client_logent:client_act, " .. tostring(self.uid))
    self.action_system:manage(sec)
end

--- Server version of root logic entity.
-- @class table
-- @name server_logent
server_logent = class.new(root_logent)
server_logent.sent_notification_complete = false

--- Initializer method. Called on creation. Performs some basic setup.
-- This is called by add function which is in store.
-- @param uid Unique ID of the entity.
-- @param kwargs Additional parameters (for i.e. overriding _persistent).
function server_logent:init(uid, kwargs)
    of.logging.log(of.logging.DEBUG, "server_logent:init(" .. tostring(uid) .. ", " .. tostring(kwargs) .. ")")
    assert(uid ~= nil)
    assert(type(uid) == "number")

    self.uid = uid
    self:_logent_setup()

    self.tags = {}
    kwargs = kwargs or {}
    self._persistent = kwargs._persistent or false
end

--- Activate function. Kwargs are used for passing state data string here.
-- @param kwargs Additional parameters.
function server_logent:activate(kwargs)
    of.logging.log(of.logging.DEBUG, "server_logent:activate(" .. tostring(kwargs) .. ")")
    self:_logent_setup()

    if not self._sauertype then
        of.logging.log("non-sauer entity going to be set up: " .. tostring(self) .. ", " .. tostring(self._sauertype))
        CAPI.setupnonsauer(self) -- does c++ reg etc, sauer types need special reg which is done by them
        self:_flush_queued_sv_changes()
    end

    if kwargs and kwargs.state_data then
        self:_update_statedata_complete(kwargs.state_data)
    end

    self:send_notification_complete(of.msgsys.ALL_CLIENTS)
    self.sent_notification_complete = true

    of.logging.log(of.logging.DEBUG, "LE.activate complete.")
end

--- Send complete notification to client(s).
-- @param cn Client number to send to. All clients if nil.
function server_logent:send_notification_complete(cn)
    cn = cn or of.msgsys.ALL_CLIENTS
    local cns = cn == of.msgsys.ALL_CLIENTS and of.logent.store.get_all_clientnums() or { cn }

    of.logging.log(of.logging.DEBUG, "LE.send_notification_complete: " .. tostring(self.cn) .. ", " .. tostring(self.uid))
    for i = 1, #cns do
        of.msgsys.send(cns[i],
                    CAPI.le_notification_complete,
                    self.cn and self.cn or of.msgsys.ALL_CLIENTS,
                    self.uid,
                    tostring(self),
                    self:create_statedatadict(cns[i], { compressed = true })) -- custom data per client
    end

    of.logging.log(of.logging.DEBUG, "LE.send_notification_complete done.")
end

--- Logic entity setup. Performs _general_setup and makes entity "initialized"
-- @see root_logent:_general_setup
function server_logent:_logent_setup()
    if not self.initialized then
        of.logging.log(of.logging.DEBUG, "LE setup")

        self:_general_setup()

        self._queued_sv_changes = {}
        self._queued_sv_changes_complete = false

        self.initialized = true
        of.logging.log(of.logging.DEBUG, "LE setup complete.")
    end
end

--- Deactivation. Calls _general_deactivate and sends message to perform
-- entity removal to all clients.
-- @see root_logent:_general_deactivate
function server_logent:deactivate()
    self:_general_deactivate()
    of.msgsys.send(of.msgsys.ALL_CLIENTS, CAPI.le_removal, self.uid)
end

--- Set entity state data. This is serverside only function.
-- @param k Property name.
-- @param v Property value.
-- @param auid Unique ID of the actor (client that triggered the change) or -1 when it comes from server.
-- @param iop Whether this is internal server operation, not sending messages and giving input in data format.
function server_logent:_set_statedata(k, v, auid, iop)
    of.logging.log(of.logging.INFO, "Setting state data: " ..
                      tostring(k) .. " = " ..
                      tostring(v) .. " (" ..
                      type(v) .. ") : " ..
                      of.json.encode(v) .. ", " ..
                      tostring(v))

    local _class = tostring(self)
    local var = self[of.state_variables._SV_PREFIX .. tostring(k)]

    if not var then
        of.logging.log(of.logging.WARNING, "Ignoring state data setting for unknown (possibly deprecated) variable " .. tostring(k))
        return nil
    end

    if auid and auid ~= -1 then
        v = var:from_wire(v)
        if not var.clientwrite then
            of.logging.log(of.logging.ERROR, "Client " .. tostring(auid) .. " tried to change " .. tostring(k))
            return nil
        end
    elseif iop then v = var:from_data(v)
    end

    of.logging.log(of.logging.INFO, "Translated value: " ..
                      tostring(k) .. " = " ..
                      tostring(v) .. " (" ..
                      type(v) .. ") : " ..
                      of.json.encode(v) .. ", " ..
                      tostring(v))

    self:emit(of.state_variables.get_onmodify_prefix() .. tostring(k), v, auid)
    if cancel_sd_update then
        cancel_sd_update = nil
        return nil
    end

    self.state_var_vals[k] = v
    of.logging.log(of.logging.INFO, "new state data: " .. tostring(self.state_var_vals[k]))

    local customsynch_fromhere = var.customsynch and self._controlled_here
    if not iop and var.clientread then
        if not self.sent_notification_complete then
            return nil
        end

        local args = {
            nil,
            var.reliable and CAPI.statedata_update or CAPI.statedata_update_unreliable,
            self.uid,
            of.msgsys.toproid(_class, tostring(k)),
            var:to_wire(v),
            (var.clientset and auid and auid ~= -1) and of.logent.store.get(auid).cn or of.msgsys.ALL_CLIENTS
        }

        local cns = of.logent.store.get_all_clientnums()
        for i = 1, #cns do
            local skip = false
            if not var:should_send(self, cns[i]) then skip = true end
            if not skip then
                args[1] = cns[i]
                of.msgsys.send(unpack(args))
            end
        end
    end
end

--- Queue state variable change. Performs simple table changes.
-- @param k Property name.
-- @param v Property value.
function server_logent:_queue_sv_change(k, v)
    of.logging.log(of.logging.DEBUG, "Queueing SV change: " .. tostring(k) .. " - " .. tostring(v) .. " (" .. type(v) .. ")")
    self._queued_sv_changes[k] = v
end

--- TODO: simillar for client. Returns true if this can
-- call C functions (== no _queued_sv_changes table)
-- @return True if this can call C functions, false otherwise.
function server_logent:can_call_cfuncs()
    return (not self._queued_sv_changes)
end

--- Flush queued SV changes. Called after CAPI.setupblah. See _queue_sv_change.
-- @see _queue_sv_change
function server_logent:_flush_queued_sv_changes()
    of.logging.log(of.logging.DEBUG, "flushing queued SV changes for " .. tostring(self.uid))
    if self:can_call_cfuncs() then return nil end

    local changes = self._queued_sv_changes
    self._queued_sv_changes = nil
    assert(self:can_call_cfuncs())

    local _keys = table.keys(changes)
    for i = 1, #_keys do
        local val = changes[_keys[i]]
        local var = self[of.state_variables._SV_PREFIX .. tostring(k)]

        of.logging.log(of.logging.DEBUG, "(A) flushing queued SV change: " ..
                tostring(_keys[i]) .. " - " ..
                tostring(val) .. " (real: " ..
                tostring(self.state_var_vals[_keys[i]]) .. ")")

        self[_keys[i]] = self.state_var_vals[_keys[i]]

        of.logging.log(of.logging.DEBUG, "(B) flushing of " .. tostring(_keys[i]) .. " - ok.")
    end

    self._queued_sv_changes_complete = true
end

logent = of.global.CLIENT and client_logent or (of.global.SERVER and server_logent or nil)
