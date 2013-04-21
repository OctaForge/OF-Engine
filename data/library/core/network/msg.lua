--[[! File: library/core/network/msg.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Provides an API to the OctaForge message system.
]]

local M = {}

local type, assert = type, assert

--[[! Variable: ALL_CLIENTS
    A constant (value -1) used when sending messages. Specifying this constant
    means that the message will be sent to all clients.
]]
M.ALL_CLIENTS = -1

--[[! Function: send
    Sends a message. On the client, it simply calls the given message function,
    using the remaining arguments as the call arguments.

    On the server, the first argument is a client number and the second
    argument is the message function. The message function is called
    with the client number as its first argument, using the remaining
    argument as the rest of call arguments. Using <ALL_CLIENTS>
    as the client number, you can send the message to all clients.
]]
M.send = CLIENT and function(mf, ...)
    mf(...)
end or function(cn, mf, ...)
    mf(cn, ...)
end

--[[! Function: show_client_message
    Shows a message on the client, coming from the server (this only works
    serverside). You need to provide a client number or a client entity, a
    message title and a message text.
]]
M.show_client_message = SERVER and function(cn, title, text)
    cn = type(cn) == "table" and cn.cn or cn
    assert(cn)
    send(cn, _C.personal_servmsg, title, text)
end or nil

return M
