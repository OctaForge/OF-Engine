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

    Section: Message system
]]

--[[!
    Package: message
    This module controls message system. It allows to send message to server or to specific
    client from both server and client, as well as protocol ID handling for name compression.
]]
module("message", package.seeall)

-- -1 value represents all clients.
ALL_CLIENTS = -1

-- storage for ptocol names and IDs.
pntoids = {}
pidston = {}

--- Send a message, either client->server or server->client. Data after message function are passed to it.
-- @param a1 If this is logic entity or number, it's server->client message (number representing client number). On client, it's the message function.
-- @param a2 On server, it's a message function, on client, data begin here.
function send(...)
    logging.log(logging.DEBUG, "message.send")

    local server
    local cn

    local args = { ... }
    if type(args[1]) == "table" and args[1].is_a and args[1]:is_a(entity.logent) then
        -- server->client message, get clientnumber from entity
        server = true
        cn = args[1].cn
    elseif type(args[1]) == "number" then
        -- server->client message, given cn
        server = true
        cn = args[1]
    else
        server = false
    end

    if server then table.remove(args, 1) end

    local mt = args[1]
    table.remove(args, 1)

    if server then table.insert(args, 1, cn) end

    logging.log(logging.DEBUG, string.format("Lua msgsys: send(): %s with { %s }", tostring(mt), table.concat(table.map(args, function(x) return tostring(x) end), ", ")))
    mt(unpack(args))
end

--- Generate protocol data.
-- @param cln Client number.
-- @param svn State variable names (table)
function genprod(cln, svn)
    logging.log(logging.DEBUG, string.format("Generating protocol names for %s", cln))
    table.sort(svn) -- ensure there is the same order on both client and server

    local ntoids = {}
    local idston = {}
    for i = 1, #svn do
        ntoids[svn[i]] = tostring(i)
        idston[i] = svn[i]
    end

    pntoids[cln] = ntoids
    pidston[cln] = idston
end

--- Return protocol ID to corresponding state variable name.
-- @param cln Client number.
-- @param svn State variable name.
-- @return Corresponding protocol ID.
function toproid(cln, svn)
    logging.log(logging.DEBUG, string.format("Retrieving protocol ID for %s / %s", cln, svn))
    return pntoids[cln][svn]
end

--- Return state variable name to corresponding protocol ID.
-- @param cln Client number.
-- @param svn Protocol ID.
-- @return Corresponding state variable name.
function fromproid(cln, proid)
    logging.log(logging.DEBUG, string.format("Retrieving state variable name for %s / %i", cln, proid))
    return pidston[cln][proid]
end

--- Clear protocol data for client number.
-- @param cln Client number.
function delci(cln)
    pntoids[cln] = nil
    pidston[cln] = nil
end

--- Show message from server on clients.
-- @param cn Client number.
-- @param ti Message title.
-- @param tx Message text.
function showcm(cn, ti, tx)
    if cn.is_a and cn:is_a(entity.logent) then
        cn = cn.cn
    end
    send(cn, CAPI.personal_servmsg, ti, tx)
end
