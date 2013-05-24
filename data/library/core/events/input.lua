--[[! File: library/core/events/world.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Registers several input events.
]]

local emit = signal.emit

--[[! Function: input_mouse_move
    Set this external if you want to override the default behavior. The default
    is hardcoded. If the external exists, it takes two arguments (yaw and
    pitch) and should return again yaw and pitch (as two return values).
    Just returning the inputs results in the default behavior, so this
    pretty much works as a filter.
]]
local input_mouse_move

local get_ext, set_ext = get_external, set_external

if CLIENT then
--[[! Function: input_yaw
    An external triggered on yaw change. Override as needed. By default
    it sets the "yawing" property on the player to "dir".
]]
set_external("input_yaw", function(dir, down)
    ents.get_player():set_yawing(dir)
end)

--[[! Function: input_pitch
    An external triggered on pitch change. Override as needed. By default
    it sets the "pitching" property on the player to "dir".
]]
set_external("input_pitch", function(dir, down)
    ents.get_player():set_pitching(dir)
end)

--[[! Function: input_move
    An external triggered during movement. Override as needed. By default
    it sets the "move" property on the player to "dir".
]]
set_external("input_move", function(dir, down)
    ents.get_player():set_move(dir)
end)

--[[! Function: input_strafe
    An external triggered during strafing. Override as needed. By default
    it sets the "strafe" property on the player to "dir".
]]
set_external("input_strafe", function(dir, down)
    ents.get_player():set_strafe(dir)
end)

--[[! Function: input_jump
    An external triggered when the player jumps. Override as needed. By default
    calls the method "jump" on the player when "down" is true.
]]
set_external("input_jump", function(down)
    if down then ents.get_player():jump() end
end)

--[[! Function: input_click
    Clientside click input handler. It takes the mouse button number, a
    boolean that is true when the button was down, the x, y, z position
    of the click, an entity that was clicked (if any, otherwise nil)
    and the position of the cursor on the screen during the click (values
    from 0 to 1). It calls another external, input_click_client, which
    you can override. If that external doesn't return a value that evaluates
    to true, it sends a click request to the server.
]]
set_ext("input_click", function(btn, down, x, y, z, ent, cx, cy)
    if not get_ext("input_click_client")(btn, down, x, y, z, ent, cx, cy) then
        msg.send(_C.do_click, btn, down, x, y, z, ent and ent.uid or -1)
    end
end)

--[[! Function: input_click_client
    Clientside external for user-defined clicks. By default it tries to call
    the click method on the given entity assuming the entity exists and it
    has a method of that name. It takes the same arguments as above and
    by default returns false, which means the above external will trigger
    a server request.
]]
set_external("input_click_client", function(btn, down, x, y, z, ent, cx, cy)
    if ent and ent.click then
        return ent:click(btn, down, x, y, z, cx, cy)
    end
    return false
end)
end

if SERVER then
--[[! Function: input_click_server
    Serverside external for user-defined clicks. Called assuming
    input_click_client returns a value that evaluates to false. By default
    it tries to call the same method on the entity as above but on the server.
    Return values of this one are ignored.
]]
set_external("input_click_server", function(btn, dn, x, y, z, ent)
    if ent and ent.click then
        return ent:click(btn, down, x, y, z)
    end
end)
end
