--[[! File: lua/core/events/signal.lua

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

local type = type
local rawget, rawset = rawget, rawset
local clamp = clamp
local tfind = table.find

local M = {}

--[[! Function: connect
    Connects a signal to a slot inside a table. The callback has to be a
    function.

    You can later use <emit> to call the connected slot(s), passing
    arguments to it (them).

    This function returns the id for the slot. You can later use this id
    to disconnect the slot. It also returns the number of currently
    connected slots.

    Slots take at least one argument, the table they're connected to.
    They're called in the order they were conected. Any further arguments
    passed to <emit> are also passed to any connected slot.

    (start code)
        Foo = {}
        signal.connect(Foo, "blah", function(self, a, b, c)
            echo(a)
            echo(b)
            echo(c)
        end)
        signal.emit(Foo, "blah", 5, 10, 15)
    (end)
]]
M.connect = function(self, name, callback)
    if type(callback) ~= "function" then
        #log(ERROR, "Not connecting non-function callback: " .. name)
        return nil
    end
    local clistn = "_sig_conn_" .. name

    local  clist = rawget(self, clistn)
    if not clist then
           clist = { slotcount = 0 }
           rawset(self, clistn, clist)
    end

    local id = #clist + 1
    clist[id] = callback

    clist.slotcount = clist.slotcount + 1

    local cb = rawget(self, "__connect")
    if    cb then cb (self, name, callback) end

    return id, clist.slotcount
end

--[[! Function: disconnect
    Disconnects a slot. You have to provide the signal name and the slot
    id. If you don't know the id, you can provide the slot itself.
    If the id is not provided, it disconnects all slots associated with
    the given signal. Returns the number of connected slots after the
    disconnect (or nil if nothing could be disconnected).
]]
M.disconnect = function(self, name, id)
    local clistn = "_sig_conn_" .. name
    local clist  = rawget(self, clistn)
    local cb     = rawget(self, "__disconnect")
    if clist then
        if not id then
            rawset(self, clistn, nil)
            if cb then cb(self, name) end
            return 0
        end
        if type(id) ~= "number" then
            id = tfind(clist, id)
        end
        if id and id <= #clist then
            local scnt = clist.slotcount - 1
            clist.slotcount = scnt
            rawset(clist, id, false)
            if cb then cb(self, name, id, scnt) end
            return scnt
        end
    end
end

--[[! Function: emit
    Emits a signal, calling all the slots associated with it in the
    order of connection, passing all extra arguments to it (besides
    the "self" argument). Returns the number of called slots.
    External as "signal_emit".
]]
M.emit = function(self, name, ...)
    local clistn = "_sig_conn_" .. name
    local clist  = rawget(self, clistn)
    if not clist then
        return 0
    end

    local ncalled = 0
    for i = 1, #clist do
        local cb = clist[i]
        if cb then
            ncalled = ncalled + 1
            cb(self, ...)
        end
    end

    return ncalled
end
set_external("signal_emit", M.emit)

return M
