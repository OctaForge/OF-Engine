--[[!
    File: base/base_messages.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features message system.
]]

--[[!
    Package: message
    This module controls message system. It allows to send message to server
    or to specific client from both server and client, as well as protocol
    ID handling for name compression.
]]
module("message", package.seeall)

--[[!
    Variable: ALL_CLIENTS
    This is useful if you want to send something to all clients, not
    just specific one. It has a value of -1, but you should use this
    alias instead of -1 directly.
]]
ALL_CLIENTS = -1

--[[!
    Variable: protocol_names_to_ids
    This is an associative table of associative tables. Keys of this table
    are entity class names. Values are associative tables which have keys
    as state variable names and values as protocol IDs.
]]
protocol_names_to_ids = {}

--[[!
    Variable: protocol_ids_to_names
    Same as <protocol_names_to_ids>, but reverse. Used for converting from
    IDs back to names.
]]
protocol_ids_to_names = {}

--[[!
    Function: send
    Sends a message either from client to server or from server to client.
    Data passed after function argument are given to the function.
    On server, first data argument is always client number.

    Parameters:
        en - either entity instance or client number. If it is an entity,
        it's server->client message and we get the client number from the
        entity and if it's a client number directly, it's server->client
        as well, just easier (without need to get the client number).
        On client, this is message function.
        mf - on server, this is message function. On client,
        this is first data argument or nil.
]]
function send(...)
    logging.log(logging.DEBUG, "message.send")

    -- pre-declare locals
    local server
    local cn

    -- get args into a table
    local args = { ... }

    -- checking
    if  type(args[1]) == "table"
    and args[1].is_a
    and args[1]:is_a(entity.base) then
        -- server->client message, get client number from the entity
        server = true
        cn = args[1].cn
    elseif type(args[1]) == "number" then
        -- server->client message, given cn
        server = true
        cn = args[1]
    else
        server = false
    end

    -- get rid of first arg on server
    if server then
        table.remove(args, 1)
    end

    -- get the message function
    local mf = args[1]

    -- and get rid of it in args
    table.remove(args, 1)

    -- on server, supply client number as first data arg
    if server then
        table.insert(args, 1, cn)
    end

    logging.log(
        logging.DEBUG,
        string.format(
            "Lua msgsys: send(): %s with { %s }",
            tostring(mf), table.concat(
                table.map(
                    args,
                    function(arg)
                        return tostring(arg)
                    end
                ),
                ", "
            )
        )
    )

    -- call it
    mf(unpack(args))
end

--[[!
    Function: generate_protocol_data
    Generates protocol data for a class. That means, generates
    a table of protocol IDs to protocol names and reverse.
    That is then used for network transfers to save bandwidth
    (no need to send full names).

    Parameters:
        class_name - name of the entity class to generate data for.
        sv_names - state variable names corresponding to
        the class (an array).
]]
function generate_protocol_data(class_name, sv_names)
    logging.log(
        logging.DEBUG,
        string.format(
            "Generating protocol names for %s",
            class_name
        )
    )

    -- ensure that the order is always the same,
    -- on both client and server.
    table.sort(sv_names)

    -- will get inserted
    local names_to_ids = {}
    local ids_to_names = {}

    -- loop the names
    for id, name in pairs(sv_names) do
        names_to_ids[name] = tostring(id)
        ids_to_names[id]   = name
    end

    -- save those globals locally
    protocol_names_to_ids[class_name] = names_to_ids
    protocol_ids_to_names[class_name] = ids_to_names
end

--[[!
    Function: to_protocol_id
    Returns protocol ID of given state variable name.

    Parameters:
        class_name - name of the entity class.
        sv_name - name of the state variable.
]]
function to_protocol_id(class_name, sv_name)
    logging.log(
        logging.DEBUG,
        string.format(
            "Retrieving protocol ID for %s / %s",
            class_name, sv_name
        )
    )
    return protocol_names_to_ids[class_name][sv_name]
end

--[[!
    Function: to_protocol_name
    Returns protocol state variable of given protocol ID.

    Parameters:
        class_name - name of the entity class.
        protocol_id - the protocol ID.
]]
function to_protocol_name(class_name, protocol_id)
    logging.log(
        logging.DEBUG,
        string.format(
            "Retrieving state variable name for %s / %i",
            class_name, protocol_id
        )
    )
    return protocol_ids_to_names[class_name][protocol_id]
end

--[[!
    Function: clear_protocol_data
    Clears protocol data for a given entity class.

    Parameters:
        class_name - name of the entity class.
]]
function clear_protocol_data(class_name)
    protocol_names_to_ids[class_name] = nil
    protocol_ids_to_names[class_name] = nil
end

--[[!
    Function: show_client_message
    Shows a message coming from the server on given client.

    Parameters:
        client_number - either direct client number (can
        as well be <ALL_CLIENTS>) or an entity it's possible
        to get client number from.
        message_title - title of the message.
        message_text - contents of the message.
]]
function show_client_message(client_number, message_title, message_text)
    -- convert if required
    if type(client_number) == "table" and client_number.cn then
        client_number = client_number.cn
    end

    send(
        client_number,
        CAPI.personal_servmsg,
        message_title, message_text
    )
end
