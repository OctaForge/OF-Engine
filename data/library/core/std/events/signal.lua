--[[! File: library/core/std/events/signal.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua signal system. Allows connecting and further emitting signals.
        Available as "std.signal".
]]

local post_emit_queue = {}

return {
    --[[! Function: connect
        Connects a signal to a table. The callback has to be a function.

        You can later use <emit> to call the connected function, passing
        arguments to it.

        Callbacks can add post emit hooks (see <add_post_emit_event>).

        This function returns the signal ID.

        (start code)
            Foo = {}
            std.signal.connect(Foo, "blah", function(self, a, b, c)
                echo(a)
                echo(b)
                echo(c) end)
            std.signal.emit(Foo, "blah", 5, 10, 15)
        (end)
    ]]
    connect = function(self, name, callback)
        if type(callback) ~= "function" then
            log(ERROR, "Not connecting non-function callback: " .. name)
            return nil end

        if not self._sig_connections then
            self._sig_connections = {}
            self._sig_next_id = 1 end

        local id = self._sig_next_id
        self._sig_next_id = self._sig_next_id + 1

        table.insert(self._sig_connections, {
            id = id, name = name, callback = callback
        })

        return id end,

    --[[! Function: disconnect
        Disconnects a signal previously connected with <connect>. You have to
        provide a signal ID, which is the return value of <connect>.
    ]]
    disconnect = function(self, id)
        if self._sig_connections then
            local len = #self._sig_connections
            self._sig_connections = std.table.filter(self._sig_connections,
                function(idx, connection)
                    if connection.id == id then return false
                    else return true end end)
            if #self._sig_connections ~= len then return nil end end
        log(ERROR, "Connection with id " .. id .. " not found.") end,

    --[[! Function: disconnect_all
        Disconnects all signals from a table.
    ]]
    disconnect_all = function(self)
        if not self._sig_connections then return nil end
        self._sig_connections = {} end,

    --[[! Function: emit
        Emits a previously connected signal of a given name. You can
        provide arguments to pass to the callback after "self".

        See <connect> if you want an example.
    ]]
    emit = function(self, name, ...)
        if not self._sig_connections then return nil end

        local handlers = std.table.filter(self._sig_connections,
            function(i, connection) if connection.name == name then
                return true end end)

        post_emit_queue = {}
        local ret
        local retval

        for i, connection in pairs(handlers) do
            ret, retval = connection.callback(self, ...)
            if ret then break end end

        local events = post_emit_queue
        post_emit_queue = nil

        while events and #events > 0 do
            post_emit_queue = {}
            for i, event in pairs(events) do
                event(self) end
            events = post_emit_queue
            post_emit_queue = nil end

        return retval end,

    --[[! Function: add_post_emit_event
        Queues an event to be done after emit. Typically called from the
        signal we're emitting. Post emit events can add their own post
        emit events freely, they'll be called in the right order.

        (start code)
            local t = {}
            std.signal.connect(t, "foo", function(self)
                std.signal.add_post_emit_event(function(self)
                    echo("first")
                    std.signal.add_post_emit_event(function(self)
                        echo("second") end) end) end)
            -- prints "first" and then "second".
            std.signal.emit(t, "foo")
        (end)
    ]]
    add_post_emit_event = function(event)
        table.insert(post_emit_queue, event) end
}
