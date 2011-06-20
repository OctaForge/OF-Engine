--[[!
    File: base/base_signals.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features signal system.

    Section: Signal handling
]]

--[[!
    Package: signals
    This module controls signal handling. If you set up a table with signal handlers,
    you can connect event to it and emit it anytime later.
]]
module("signals", package.seeall)

--- Table of actions to be done after doing emit,
-- see postemitevent_add.
-- @class table
-- @name __post_emit_event_stack
local __post_emit_event_stack = {}

--- This is used to connect signals to table.
-- You don't call this directly. Instead, you add the method into the table using
-- methods_add, and then it's called "connect" without the underscore.
-- @param self The table you connect signal to (hidden usually, automatically filled in using : )
-- @param name Name of the signal; serves as identifier so you can emit it later
-- @param callback Function to connect to name
-- @return Unique numerical identifier for the signal.
-- @see methods_add
-- @see _disconnect
-- @see _disconnectall
-- @see _emit
function _connect(self, name, callback) 
    -- check if callback really is function
    if type(callback) ~= "function" then
        error("Specified callback is not a function, not connecting.")
    end

    -- check if we already initiated the array
    if not self._signalConnections then
        self._signalConnections = {}
        self._nextConnectionId = 1
    end

    local id = self._nextConnectionId
    self._nextConnectionId = self._nextConnectionId + 1

    table.insert(self._signalConnections, { id = id, name = name, callback = callback, disconnected = false })

    return id
end

--- This is used to disconnect signals from table.
-- You don't call this directly. Instead, you add the method into the table using
-- methods_add, and then it's called "disconnect" without the underscore.
-- @param self The table you disconnect signal from (hidden usually, automatically filled in using : )
-- @param id Number specifying signal connection ID. Returned from connect.
-- @see methods_add
-- @see _connect
-- @see _disconnectall
-- @see _emit
function _disconnect(self, id)
    if self._signalConnections then
        for i = 1, #self._signalConnections do
            local connection = self._signalConnections[i]
            if connection.id == id then
                if connection.disconnected then
                    error("Connection with id " .. id .. " was already disconnected before.")
                end
                self._signalConnections[i].disconnected = true
                table.remove(self._signalConnections, i)
                return nil
            end
        end
    end
    error("Connection with id " .. id .. " not found.")
end

--- This is used to disconnect signals from table, but unlike _disconnect it disconnects all signals.
-- You don't call this directly. Instead, you add the method into the table using
-- methods_add, and then it's called "disconnectall" without the underscore.
-- @param self The table you disconnect signals from (hidden usually, automatically filled in using : )
-- @see methods_add
-- @see _connect
-- @see _disconnect
-- @see _emit
function _disconnectall(self)
    if self._signalConncetions then
        while #self._signalConnections > 0 do
            self:disconnect(self, self._signalConnections[1].id)
        end
    end
end

--- This is used to emit a signal.
-- You don't call this directly. Instead, you add the method into the table using
-- methods_add, and then it's called "emit" without the underscore.
-- @param self The table you emit signal from (hidden usually, automatically filled in using : )
-- @param name Name of signal connection specified when calling connect.
-- @param ... Variable number of arguments, they're all passed to callback.
-- @return Return value of last callback assigned to name.
-- @see methods_add
-- @see _connect
-- @see _disconnect
-- @see _disconnectall
function _emit(self, name, ...)
    if not self._signalConnections then return nil end

    local args = {...}
    local handlers = {}
    local length = #self._signalConnections

    for i = 1, length do
        local connection = self._signalConnections[i]
        if connection.name == name then table.insert(handlers, connection) end
    end

    local arg_array = {}
    length = #args
    for i = 1, length do
        table.insert(arg_array, args[i])
    end

    table.insert(__post_emit_event_stack, {})

    length = #handlers
    for i = 1, length do
        local connection = handlers[i]
        if not connection.disconnected then
            local ret, retval = connection.callback(self, unpack(args))
            if ret == true then break end
        end
    end

    local events = __post_emit_event_stack[#__post_emit_event_stack]
    table.remove(__post_emit_event_stack)
    length = #events
    while length > 0 do
        table.insert(__post_emit_event_stack, {})
        for i = 1, #events do
            events[i](self)
        end
        events = __post_emit_event_stack[#__post_emit_event_stack]
        table.remove(__post_emit_event_stack)
        length = #events
    end

    return retval
end

--- Adds signal calls into a table.
-- @param self The table to insert calls into.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local mytable = {}<br/>
-- Signals.methods_add(mytable)<br/>
-- local id = mytable:connect("test", function () echo("Hello world") end)<br/>
-- mytable:emit("test")<br/>
-- mytable:disconnect(id)<br/>
-- </code>
function methods_add(self)
    self.connect = _connect
    self.disconnect = _disconnect
    self.emit = _emit
    self.disconnectall = _disconnectall
end

--- Adds an event to be called after emit. You can add as many events as you want.
-- @param event A function to be called as post-emit event.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local mytable = {}<br/>
-- Signals.methods_add(mytable)<br/>
-- local id = mytable:connect("test", function () postemitevent_add(function (self) echo("Hello world") end) end)<br/>
-- mytable:emit("test")<br/>
-- mytable:disconnect(id)<br/>
-- </code>
function post_emit_event_add(event)
    if not __post_emit_event_stack[#__post_emit_event_stack + 1] then
        __post_emit_event_stack[#__post_emit_event_stack + 1] = {}
    end
    table.insert(__post_emit_event_stack[#__post_emit_event_stack + 1], event)
end
