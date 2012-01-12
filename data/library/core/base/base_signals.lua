--[[!
    File: library/core/base/base_signals.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features signal system.
]]

--[[!
    Package: signals
    This module controls signal handling. If you set up a table with signal
    handlers, you can connect event to it and emit it anytime later.
]]
module("signals", package.seeall)

--[[!
    Variable: __post_emit_event_stack
    This is a local queue of actions to be done after emit. It's basically
    an array containing 1 other array which serves as an action queue.
    See <post_emit_event_add>.
]]
local __post_emit_event_stack = {}

--[[!
    Function: _connect
    This is used to connect a signal to a table. You never call this function
    directly. Instead, you use <methods_add> to add required signal handlers
    to the table and then use this function as table method, without
    the underscore.

    If you connect a signal function to a name, you can later <_emit>
    it and even pass some arguments to it (besides "self" which is passed
    automatically and it represents the table it was connected to).

    Parameters:
        self - the table you'll be calling connect for.
        Usually hidden by using :.
        name - the signal name to connect.
        callback - the callback function, accepts "self" argument + custom.
        The handler function can return two values, first one being boolean
        value, which when it's true, it makes the emit stop at that callback
        even when multiple callbacks are connected to the same signal,
        and second one being any return value you want to return from <_emit>.

    Returns:
        Unique ID for the signal.

    See Also:
        <methods_add>
        <_disconnect>
        <_disconnect_all>
        <_emit>
]]
function _connect(self, name, callback) 
    -- check if callback really is function
    if type(callback) ~= "function" then
        log(
            ERROR,
            "Specified callback is not a function, not connecting."
        )
        return nil
    end

    -- check if we already initiated the array
    if not self._signal_connections then
        self._signal_connections = {}
        self._next_connection_id = 1
    end

    local id = self._next_connection_id
    self._next_connection_id = self._next_connection_id + 1

    table.insert(self._signal_connections, {
        id = id,
        name = name,
        callback = callback,
        disconnected = false
    })

    return id
end

--[[!
    Function: _disconnect
    This is used to disconnect a signal from a table.
    You never call this function directly. Instead, you use
    <methods_add> to add required signal handlers to the table
    and then use this function as table method, without the underscore.

    If you disconnect a signal, you won't be able to emit it anymore.
    To disconnect it, you need to know the ID.

    Parameters:
        self - the table you'll be calling connect for.
        Usually hidden by using :.
        id - the ID to disconnect.

    See Also:
        <methods_add>
        <_connect>
        <_disconnect_all>
        <_emit>
]]
function _disconnect(self, id)
    -- do only if we already have connections
    if self._signal_connections then
        for i, connection in pairs(self._signal_connections) do
            if connection.id == id then
                -- fail if disconnected
                if connection.disconnected then
                    log(
                        ERROR,
                        "Connection with id "
                            .. id
                            .. " was already disconnected before."
                    )
                    return nil
                end
                -- set as disconnected
                connection.disconnected = true
                -- remove from connections
                table.remove(self._signal_connections, i)
                -- break from the function
                return nil
            end
        end
    end
    log(ERROR, "Connection with id " .. id .. " not found.")
end

--[[!
    Function: _disconnect_all
    See <_disconnect>. This basically loops all the IDs and disconnects
    them using <_disconnect>. No other arguments than self required.
    Other rules apply in the same way as for other methods.

    See Also:
        <methods_add>
        <_connect>
        <_disconnect>
        <_emit>
]]
function _disconnect_all(self)
    -- disconnect only if we have any
    if self._signal_connections then
        -- loop until it's not empty
        while #self._signal_connections > 0 do
            -- disconnect the id
            self:disconnect(self, self._signal_connections[1].id)
        end
    end
end

--[[!
    Function: _emit
    Emits a signal. Same calling rules as for i.e. <_connect> apply.
    Please note that if some callback adds another one, it won't get executed
    this run, since we're manipulating with separate table.

    Parameters:
        self - the table you'll be calling connect for.
        Usually hidden by using :.
        name - name of the signal.
        ... - additional arguments for emitting handler
        function, besides "self".

    Returns:
        Return value of last callback that was executed.

    See Also:
        <methods_add>
        <_connect>
        <_disconnect>
        <_disconnect_all>
]]
function _emit(self, name, ...)
    -- without signal connections, just return nil.
    if not self._signal_connections then
        return nil
    end

    -- get the args into a table
    local args = { ... }

    -- contains handlers, we manipulate with copy just in case
    local handlers = table.filter_array(
        self._signal_connections,
        function(i, connection)
            if connection.name == name then
                return true
            end
        end
    )

    -- initialize post-emit event stack
    table.insert(__post_emit_event_stack, {})

    -- so they're accessible outside for scope
    local ret
    local retval

    -- loop the connections
    for i, connection in pairs(handlers) do
        -- exec only if not disconnected
        if not connection.disconnected then
            -- get return values
            ret, retval = connection.callback(self, unpack(args))

            -- allow to break when we've got appropriate retval
            if ret == true then
                break
            end
        end
    end

    -- get a table of events from post emit event stack, which could
    -- be filled now, by signal handlers.
    local events = __post_emit_event_stack[#__post_emit_event_stack]

    -- clear it from the stack itself
    table.remove(__post_emit_event_stack)

    -- loop while we've actually got events
    while #events > 0 do
        -- add clear table again
        table.insert(__post_emit_event_stack, {})

        -- loop all post emit events and let them possibly
        -- queue more actions to post emit stack
        for i, event in pairs(events) do
            event(self)
        end

        -- get new events which could be possibly filled already
        -- by latest queued action execution
        events = __post_emit_event_stack[#__post_emit_event_stack]

        -- clear it from the stack itself
        table.remove(__post_emit_event_stack)
    end

    -- return the retval finally
    return retval
end

--[[!
    Function: methods_add
    Prepares a table for signal handling by adding methods
    named "connect" (<_connect>), "disconnect" (<_disconnect>),
    "emit" (<_emit>) and "disconnect_all" (<_disconnect_all)
    to it.

    Usage:
        (start code)
            local t = { x = 5 }
            signals.methods_add(t)

            local id = t:connect(
                "foo", function(self, arg)
                    echo(t.x + arg)
                end
            )
            t:emit("foo", 5) -- prints "10"
            t:disconnect(id) -- clear it up
        (end)
]]
function methods_add(self)
    self.connect        = _connect
    self.disconnect     = _disconnect
    self.emit           = _emit
    self.disconnect_all = _disconnect_all
end

--[[!
    Function: post_emit_event_add
    Queues an event into post emit event stack. Meant to be used from signal
    handlers. The queue gets then looped and every function from it gets
    executed. If any of functions added more events into the queue, it
    gets iterated once again and same actions are performed. Loops until
    the queue is empty.

    Usage:
        (start code)
            local t = {}
            signals.methods_add(t)

            local id = t:connect(
                "foo", function(self)
                    signals.post_emit_event_add(function(self)
                        echo("first iteration")

                        signal.post_emit_event_add(function(self)
                            echo("second iteration")
                        end)
                    end)
                end
            )
            -- prints "first iteration" and then "second iteration"
            t:emit("foo")
            t:disconnect(id) -- clear it up
        (end)
]]
function post_emit_event_add(event)
    table.insert(__post_emit_event_stack[#__post_emit_event_stack], event)
end
