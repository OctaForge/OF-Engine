--[[! File: library/core/events/world.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Registers several world events.
]]

local emit = signal.emit

--[[! Function: event_off_map
    Called when an entity falls off the map. Emits a signal of the same name
    with the entity as an argument on the global table.
]]
set_external("event_off_map", function(ent)
    emit(_G, "event_off_map", ent)
end)

--[[! Function: event_text_message
    Called on a text message event. Emits a signal of the same name with
    the unique ID of the client and the text as arguments on the global table.
]]
set_external("event_text_message", function(uid, text)
    emit(_G, "event_text_message", uid, text)
end)

if SERVER then
--[[! Function: event_player_login
    Serverside. Called after a server sends all the active entities to the
    client. Emits a signal of the same name with the player entity as an
    argument on the global table.
]]
set_external("event_player_login", function(ent)
    emit(_G, "event_player_login", ent)
end)
end
