---
-- base_signals.lua, version 1<br/>
-- A signal system allowing to connect callbacks to tables and later emit them.<br/>
-- Original code by litl/gnome/gjs, licensed under MIT/X11 (see the COPYING.txt).<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
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

--- Signal system allowing to connect callbacks to tables and disconnect or
-- emit them at any point in code where the table is available.
-- @class module
-- @name cc.signals
module("cc.signals")

--- Table of actions to be done after doing emit,
-- see postemitevent_add.
-- @class table
-- @name __postemitevstack
local __postemitevstack = {}

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
    if base.type(callback) ~= "function" then
        base.error("Specified callback is not a function, not connecting.")
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
                    base.error("Connection with id " .. id .. " was already disconnected before.")
                end
                self._signalConnections[i].disconnected = true
                table.remove(self._signalConnections, i)
                return nil
            end
        end
    end
    base.error("Connection with id " .. id .. " not found.")
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

    table.insert(__postemitevstack, {})

    length = #handlers
    for i = 1, length do
        local connection = handlers[i]
        if not connection.disconnected then
            local ret, retval = connection.callback(self, base.unpack(args))
            if ret == true then break end
        end
    end

    local events = __postemitevstack[#__postemitevstack]
    table.remove(__postemitevstack)
    length = #events
    while length > 0 do
        table.insert(__postemitevstack, {})
        for i = 1, #events do
            events[i](self)
        end
        events = __postemitevstack[#__postemitevstack]
        table.remove(__postemitevstack)
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
function postemitevent_add(event)
    if not __postemitevstack[#__postemitevstack + 1] then
        __postemitevstack[#__postemitevstack + 1] = {}
    end
    table.insert(__postemitevstack[#__postemitevstack + 1], event)
end
