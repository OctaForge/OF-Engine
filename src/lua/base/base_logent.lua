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

local base = _G
local table = require("table")
local string = require("string")
local glob = require("of.global")
local log = require("of.logging")
local class = require("of.class")
local signals = require("of.signals")
local act = require("of.action")
local json = require("of.json")
local svar = require("of.state_variables")
local msgsys = require("of.msgsys")
local lstor = require("of.logent.store")
local CAPI = require("CAPI")

--- This module takes care of logic entities.
-- client_logent / server_logent will become only "logent",
-- depending on if we're on client or on server.
-- @class module
-- @name of.logent
module("of.logent")

base.assert(glob.CLIENT or glob.SERVER)
base.assert(not (glob.CLIENT and glob.SERVER))
log.log(log.DEBUG, "Generating logent system with CLIENT = " .. base.tostring(glob.CLIENT))

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
    { "tags", svar.state_array() },
    { "_persistent", svar.state_bool() }
}

--- Automatically substitute for class name when tostring() is called on entity.
-- @return Class name.
function root_logent:__tostring() return self._class end

--- General setup method. Performs some initialization magic like signal
-- methods adding, state variable values table, state variable setup etc.
function root_logent:_general_setup()
    log.log(log.DEBUG, "root_logent:_general_setup")

    if self._general_setup_complete then return nil end
    signals.methods_add(self)

    self.action_system = act.action_system(self)
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
    return self.state_var_vals[base.tostring(k)]
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
    log.log(log.DEBUG, "root_logent:del_tag(\"" .. base.tostring(t) .. "\")")
    self.tags = table.filterarray(self.tags:as_array(), function(i, tag) return tag ~= t end)
end

--- Check whether an entity has a tag.
-- @param t Tag to lookup, string.
function root_logent:has_tag(t)
    log.log(log.INFO, "i can has tag " .. base.tostring(t))
    return (table.find(self.tags:as_array(), t) ~= nil)
end

--- Setup state variables of the entity. Performs registration for each.
function root_logent:_setup_vars()
    for i = 1, #self.properties do
        local var = self.properties[i][2]
        if svar.is(var) then
            var:_register(self.properties[i][1], self)
        end
    end
end

--- Create state data dictionary. That gets returned as JSON. Names
-- can be compressed as protocol IDs, so bandwidth is saved (returned
-- JSON is sent through network later). Compression can be set
-- with kwargs - you have to provide "compressed" element with
-- "true" value in order to do so.
-- @param tcn Client number to send state data to. When nil, it's sent to all clients.
-- @param kwargs Additional parameter table.
-- @return JSON with state data (string).
-- @see root_logent:_update_statedata_complete
function root_logent:create_statedatadict(tcn, kwargs)
    tcn = tcn or msgsys.ALL_CLIENTS
    kwargs = kwargs or {}

    log.log(log.DEBUG, "create_statedatadict(): " .. base.tostring(self) .. base.tostring(self.uid) .. ", " .. base.tostring(tcn))

    local r = {}
    local _names = table.keys(self)
    for i = 1, #_names do
        local var = self[_names[i]]
        if svar.is(var) and var.hashistory then
            -- do not send private data
            local skip = false
            if tcn >= 0 and not var:should_send(self, tcn) then skip = true end
            if not skip then
                local val = self[var._name]
                if val then
                    log.log(log.DEBUG, "create_statedatadict() adding " .. base.tostring(var._name) .. ": " .. json.encode(val))
                    r[not kwargs.compressed and var._name or msgsys.toproid(base.tostring(self), var._name)] = var:to_data(val)
                    log.log(log.DEBUG, "create_statedatadict() currently: " .. json.encode(r))
                end
            end
        end
    end

    log.log(log.DEBUG, "create_statedatadict() returns: " .. json.encode(r))
    if not kwargs.compressed then return r end

    -- pre-compression: keep numbers as numbers, not strings
    _names = table.keys(r)
    for i = 1, #_names do
        if base.tonumber(r[_names[i]]) and r[_names[i]] ~= "" then
            r[_names[i]] = base.tonumber(r[_names[i]])
        end
    end

    r = json.encode(r)
    log.log(log.DEBUG, "pre-compression: " .. r)

    local _filters = {
        function(d) return string.gsub(d, "\", \"", "\",\"") end, -- "foo", "bar" --> "foo","bar"
        --function(d) return string.gsub(d, "\"%[%]\"", "%[%]") end, -- "[]" --> []
        function(d) return string.gsub(d, ":\"(%d+)\.(%d+)\"", ":\"%1\".\"%2\"") end, -- :"3.14" --> :"3"."14"
        function(d) return string.gsub(d, ", ", ",") end -- ", " --> "," (without quotes)
    }
    for i = 1, #_filters do
        local n = _filters[i](r)
        if #n < #r and json.encode(json.decode(n)) == json.encode(json.decode(r)) then
            r = n
        end
    end

    log.log(log.DEBUG, "compressed: " .. r)

    return string.sub(r, 2, #r - 1) -- remove {}
end

--- Update state data from string created by create_statedatadict.
-- @param sd State data JSON string.
-- @see root_logent:create_statedatadict
function root_logent:_update_statedata_complete(sd)
    log.log(log.DEBUG, "updating complete state data for " .. base.tostring(self.uid) .. " with " .. base.tostring(sd) .. " (" .. base.type(sd) .. ")")

    sd = string.sub(sd, 1, 1) ~= "{" and "{" .. sd .. "}" or sd
    local nsd = json.decode(sd)

    base.assert(base.type(nsd) == "table")

    self.initialized = true
    for k, v in base.pairs(nsd) do
        k = base.tonumber(k) and msgsys.fromproid(base.tostring(self), base.tonumber(k)) or k
        log.log(log.DEBUG, "update of complete state data: " .. base.tostring(k) .. " = " .. base.tostring(v))
        self:_set_statedata(k, v, nil, true) -- true - this is internal op, we are sending raw state data
        log.log(log.DEBUG, "update of complete state data ok")
    end

    log.log(log.DEBUG, "update of complete state data done.")
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
        log.log("non-sauer entity going to be set up: " .. base.tostring(self) .. ", " .. base.tostring(self._sauertype))
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
    log.log(log.DEBUG, "setting state data: " .. base.tostring(k) .. " = " .. json.encode(v) .. " for " .. base.tostring(self.uid))
    local var = self[svar._SV_PREFIX .. base.tostring(k)]

    local customsynch_fromhere = var.customsynch and self._controlled_here
    local clientset = var.clientset

    if auid == -1 and not customsynch_fromhere then
        log.log(log.DEBUG, "sending request / notification to server.")
        -- todo: supress msg sending of the same val, at least for some SVs
        msgsys.send(var.reliable and CAPI.statedata_changerequest or CAPI.statedata_changerequest_unreliable,
                    self.uid,
                    msgsys.toproid(base.tostring(self),
                    base.tostring(var._name)), var:to_wire(v))
    end

    if auid ~= -1 or clientset or customsynch_fromhere then
        log.log(log.DEBUG, "updating locally")
        -- if originated from server, translated
        if auid ~= -1 then v = var:from_wire(v) end
        base.assert(var:validate(v))
        self:emit(svar.get_onmodify_prefix() .. base.tostring(k), v, auid ~= -1)
        self.state_var_vals[k] = v
    end
end

--- Act method which is ran every frame. Performs action system management by default.
-- @param sec Length of the time to simulate.
function client_logent:client_act(sec)
    log.log(log.INFO, "client_logent:client_act, " .. base.tostring(self.uid))
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
    log.log(log.DEBUG, "server_logent:init(" .. base.tostring(uid) .. ", " .. base.tostring(kwargs) .. ")")
    base.assert(uid ~= nil)
    base.assert(base.type(uid) == "number")

    self.uid = uid
    self:_logent_setup()

    self.tags = {}
    kwargs = kwargs or {}
    self._persistent = kwargs._persistent or false
end

--- Activate function. Kwargs are used for passing state data string here.
-- @param kwargs Additional parameters.
function server_logent:activate(kwargs)
    log.log(log.DEBUG, "server_logent:activate(" .. base.tostring(kwargs) .. ")")
    self:_logent_setup()

    if not self._sauertype then
        log.log("non-sauer entity going to be set up: " .. base.tostring(self) .. ", " .. base.tostring(self._sauertype))
        CAPI.setupnonsauer(self) -- does c++ reg etc, sauer types need special reg which is done by them
        self:_flush_queued_sv_changes()
    end

    if kwargs and kwargs.state_data then
        self:_update_statedata_complete(kwargs.state_data)
    end

    self:send_notification_complete(msgsys.ALL_CLIENTS)
    self.sent_notification_complete = true

    log.log(log.DEBUG, "LE.activate complete.")
end

--- Send complete notification to client(s).
-- @param cn Client number to send to. All clients if nil.
function server_logent:send_notification_complete(cn)
    cn = cn or msgsys.ALL_CLIENTS
    local cns = cn == msgsys.ALL_CLIENTS and lstor.get_all_clientnums() or { cn }

    log.log(log.DEBUG, "LE.send_notification_complete: " .. base.tostring(self.cn) .. ", " .. base.tostring(self.uid))
    for i = 1, #cns do
        msgsys.send(cns[i],
                    CAPI.le_notification_complete,
                    self.cn and self.cn or msgsys.ALL_CLIENTS,
                    self.uid,
                    base.tostring(self),
                    self:create_statedatadict(cns[i], { compressed = true })) -- custom data per client
    end

    log.log(log.DEBUG, "LE.send_notification_complete done.")
end

--- Logic entity setup. Performs _general_setup and makes entity "initialized"
-- @see root_logent:_general_setup
function server_logent:_logent_setup()
    if not self.initialized then
        log.log(log.DEBUG, "LE setup")

        self:_general_setup()

        self._queued_sv_changes = {}
        self._queued_sv_changes_complete = false

        self.initialized = true
        log.log(log.DEBUG, "LE setup complete.")
    end
end

--- Deactivation. Calls _general_deactivate and sends message to perform
-- entity removal to all clients.
-- @see root_logent:_general_deactivate
function server_logent:deactivate()
    self:_general_deactivate()
    msgsys.send(msgsys.ALL_CLIENTS, CAPI.le_removal, self.uid)
end

--- Set entity state data. This is serverside only function.
-- @param k Property name.
-- @param v Property value.
-- @param auid Unique ID of the actor (client that triggered the change) or -1 when it comes from server.
-- @param iop Whether this is internal server operation, not sending messages and giving input in data format.
function server_logent:_set_statedata(k, v, auid, iop)
    log.log(log.INFO, "Setting state data: " ..
                      base.tostring(k) .. " = " ..
                      base.tostring(v) .. " (" ..
                      base.type(v) .. ") : " ..
                      json.encode(v) .. ", " ..
                      base.tostring(v))

    local _class = base.tostring(self)
    local var = self[svar._SV_PREFIX .. base.tostring(k)]

    if not var then
        log.log(log.WARNING, "Ignoring state data setting for unknown (possibly deprecated) variable " .. base.tostring(k))
        return nil
    end

    if auid and auid ~= -1 then
        v = var:from_wire(v)
        if not var.clientwrite then
            log.log(log.ERROR, "Client " .. base.tostring(auid) .. " tried to change " .. base.tostring(k))
            return nil
        end
    elseif iop then v = var:from_data(v)
    end

    log.log(log.INFO, "Translated value: " ..
                      base.tostring(k) .. " = " ..
                      base.tostring(v) .. " (" ..
                      base.type(v) .. ") : " ..
                      json.encode(v) .. ", " ..
                      base.tostring(v))

    self:emit(svar.get_onmodify_prefix() .. base.tostring(k), v, auid)
    if base.cancel_sd_update then
        base.cancel_sd_update = nil
        return nil
    end

    self.state_var_vals[k] = v
    log.log(log.INFO, "new state data: " .. base.tostring(self.state_var_vals[k]))

    local customsynch_fromhere = var.customsynch and self._controlled_here
    if not iop and var.clientread then
        if not self.sent_notification_complete then
            return nil
        end

        local args = {
            nil,
            var.reliable and CAPI.statedata_update or CAPI.statedata_update_unreliable,
            self.uid,
            msgsys.toproid(_class, base.tostring(k)),
            var:to_wire(v),
            (var.clientset and auid and auid ~= -1) and lstor.get(auid).cn or msgsys.ALL_CLIENTS
        }

        local cns = lstor.get_all_clientnums()
        for i = 1, #cns do
            local skip = false
            if not var:should_send(self, cns[i]) then skip = true end
            if not skip then
                args[1] = cns[i]
                msgsys.send(base.unpack(args))
            end
        end
    end
end

--- Queue state variable change. Performs simple table changes.
-- @param k Property name.
-- @param v Property value.
function server_logent:_queue_sv_change(k, v)
    log.log(log.DEBUG, "Queueing SV change: " .. base.tostring(k) .. " - " .. base.tostring(v) .. " (" .. base.type(v) .. ")")
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
    log.log(log.DEBUG, "flushing queued SV changes for " .. base.tostring(self.uid))
    if self:can_call_cfuncs() then return nil end

    local changes = self._queued_sv_changes
    self._queued_sv_changes = nil
    base.assert(self:can_call_cfuncs())

    local _keys = table.keys(changes)
    for i = 1, #_keys do
        local val = changes[_keys[i]]
        local var = self[svar._SV_PREFIX .. base.tostring(k)]

        log.log(log.DEBUG, "(A) flushing queued SV change: " ..
                base.tostring(_keys[i]) .. " - " ..
                base.tostring(val) .. " (real: " ..
                base.tostring(self.state_var_vals[_keys[i]]) .. ")")

        self[_keys[i]] = self.state_var_vals[_keys[i]]

        log.log(log.DEBUG, "(B) flushing of " .. base.tostring(_keys[i]) .. " - ok.")
    end

    self._queued_sv_changes_complete = true
end

logent = glob.CLIENT and client_logent or (glob.SERVER and server_logent or nil)
