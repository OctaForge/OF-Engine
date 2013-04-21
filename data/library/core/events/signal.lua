--[[! File: library/core/events/signal.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua signal system. Allows connecting and further emitting signals.
        Available as "signal".
]]

return {
    --[[! Function: connect
        Connects a signal to a table. The callback has to be a function.

        You can later use <emit> to call the connected function, passing
        arguments to it.

        This function returns the position of the signal inside signal
        queue for the given name (by default it's appended to the end,
        optional fourth argument can specify position into which to insert).
        It also returns the callback after being wrapped.

        Signals can return values (any number they want). They take at least
        two arguments, first being a reference to the next signal in the
        queue, second being the table. Only the first signal in the queue
        is called on emit, so if you want to call the whole sequence, make
        sure to use the argument. The system doesn't do it automatically.
        Of course, any further arguments after the two are passed from
        <emit>.

        (start code)
            Foo = {}
            signal.connect(Foo, "blah", function(_, self, a, b, c)
                echo(a)
                echo(b)
                echo(c) end)
            signal.emit(Foo, "blah", 5, 10, 15)
        (end)
    ]]
    connect = function(self, name, callback, pos)
        if type(callback) ~= "function" then
            #log(ERROR, "Not connecting non-function callback: " .. name)
            return nil
        end

        local  connections = rawget(self, "_sig_connections")
        if not connections then
               connections = {}
               rawset(self, "_sig_connections", connections)
        end

        local  conn = connections[name]
        if not conn then
               conn = {}
               connections[name] = conn
        end

        local id = #conn + 1
        pos = clamp(pos or id, 1, id)

        local fun = function(...)
            return callback(conn[pos + 1], ...)
        end
        if pos == id then
            conn [id] = fun
        else
            table.insert(conn, pos, fun)
        end

        local cb = rawget(self, "__connect")
        if    cb then cb (self, name, callback, pos) end

        return id, fun
    end,

    --[[! Function: disconnect
        Disconnects a signal previously connected with <connect>. You have to
        provide the name and the number of the signal in the queue. If you
        don't know the number, you can provide the callback itself (as
        returned by <connect>, not the raw form).
        If the number (or callback) is not provided, all signals of the
        given name are disconnected. If the name is not given either,
        all signals are disconnected from the table.

        If id is provided, this function returns the number of signals
        connected to name after this disconnect. Otherwise nil.
    ]]
    disconnect = function(self, name, id)
        local connections = rawget(self, "_sig_connections")
        local cb          = rawget(self, "__disconnect")
        if    connections then
            if not id then
                connections[name] = nil
                if cb then cb(self, name) end
                return nil
            end
            local conn = connections[name]
            if    conn and type(id) ~= "number" then
                id = table.find(conn, id)
            end
            if conn and #conn >= id then
                table.remove(conn, id)
                local len = #conn
                if cb then cb(self, name, id, len) end
                return len
            end
        end
        rawset(self, "_sig_connections", nil)
        if cb then cb(self) end
    end,

    --[[! Function: emit
        Emits a previously connected signal of a given name. You can
        provide arguments to pass to the callback after "next" and "self".

        Only the first signal in the queue is called, so make sure to use
        "next" when required in order to call further signals in the
        sequence.

        This function returns values returned by the called signal.

        See <connect> if you want an example.
    ]]
    emit = function(self, name, ...)
        local  connections = rawget(self, "_sig_connections")
        if not connections then return nil end

        local  handlers = connections[name]
        if not handlers then return nil end

        local  cb = handlers[1]
        if not cb then return nil end

        return cb(self, ...)
    end
}
