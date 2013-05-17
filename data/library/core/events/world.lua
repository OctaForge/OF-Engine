--[[! File: library/core/events/world.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Registers several world events. Override these as you wish.
]]

local emit = signal.emit

--[[! Function: physics_off_map
    Called when a client falls off the map (keeps calling until the client
    changes its state).
]]
set_external("physics_off_map", function(ent) end)

--[[! Function: physics_in_deadly
    Called when a client is in a deadly material (lava or death). Takes
    the entity and the deadly material id. For material ids, see the
    <edit> module.
]]
set_external("physics_in_deadly", function(ent, mat) end)

--[[! Function: physics_state_change
    Called when a client changes their physical state. Takes the client
    entity, the "local" argument (false for multiplayer prediction), the
    "floorlevel" argument (specifying a delta from the previous state, 1
    when the client went up, 0 when stayed the same, -1 when down), the
    "liquidlevel" argument and the material id (for example when jumping
    out of/into water, it's water material id). For material ids, see the
    <edit> module.

    By default this plays water, lava, jumping and landing sounds on the
    client.
]]
set_external("physics_state_change", function(ent, loc, flevel, llevel, mat)
    print("MAT", mat)
    if not CLIENT then return nil end
    local ispl = (ent == ents.get_player())
    local pos = (not ispl) and ent.position or nil
    if llevel > 0 then
        if mat ~= edit.MATERIAL_LAVA then
            sound.play("yo_frankie/amb_waterdrip_2.wav", pos)
        end
    elseif llevel < 0 then
        sound.play(mat == edit.MATERIAL_LAVA and "yo_frankie/DeathFlash.wav"
            or "yo_frankie/watersplash2.wav", pos)
    end
    if flevel > 0 then
        if ispl then sound.play("gk/jump2.ogg") end
    elseif flevel < 0 then
        if ispl then sound.play("olpc/AdamKeshen/kik.wav") end
    end
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
