--[[!<
    Registers several input events.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")
local msg = require("core.network.msg")
local signal = require("core.events.signal")

local emit = signal.emit
local ents

--[[! Function: input_mouse_move
    The default behavior is hardcoded. If the external exists, it takes two
    arguments (yaw and pitch) and should return again yaw and pitch (as two
    return values). Just returning the inputs results in the default behavior,
    so this pretty much works as a filter.
]]
local input_mouse_move

local get_ext, set_ext = capi.external_get, capi.external_set

local event_map

if not SERVER then
--[[! Function: input_yaw
    An external triggered on yaw change. By default it sets the "yawing"
    property on the player to "dir".

    Arguments:
        - dir - the yawing direction.
        - down - whether the key was pressed.
]]
set_ext("input_yaw", function(dir, down)
    if not ents then ents = require("core.entities.ents") end
    ents.get_player():set_attr("yawing", dir)
end)

--[[! Function: input_pitch
    An external triggered on pitch change. By default it sets the "pitching"
    property on the player to "dir".

    Arguments:
        - dir - the pitching direction.
        - down - whether the key was pressed.
]]
set_ext("input_pitch", function(dir, down)
    if not ents then ents = require("core.entities.ents") end
    ents.get_player():set_attr("pitching", dir)
end)

--[[! Function: input_move
    An external triggered during movement. By default it sets the "move"
    property on the player to "dir".

    Arguments:
        - dir - the move direction.
        - down - whether the key was pressed.
]]
set_ext("input_move", function(dir, down)
    if not ents then ents = require("core.entities.ents") end
    ents.get_player():set_attr("move", dir)
end)

--[[! Function: input_strafe
    An external triggered during strafing. By default it sets the "strafe"
    property on the player to "dir".

    Arguments:
        - dir - the strafe direction.
        - down - whether the key was pressed.
]]
set_ext("input_strafe", function(dir, down)
    if not ents then ents = require("core.entities.ents") end
    ents.get_player():set_attr("strafe", dir)
end)

--[[! Function: input_jump
    An external triggered when the player jumps. By default calls the method
    "jump" on the player, passing "down" as an argument.

    Arguments:
        - down - whether the key was pressed.
]]
set_ext("input_jump", function(down)
    if not ents then ents = require("core.entities.ents") end
    ents.get_player():jump(down)
end)

--[[! Function: input_crouch
    An external triggered when the player crouches. By default calls the method
    "crouch" on the player, passing "down" as an argument.

    Arguments:
        - down - whether the key was pressed.
]]
set_ext("input_crouch", function(down)
    if not ents then ents = require("core.entities.ents") end
    ents.get_player():crouch(down)
end)

--[[! Function: input_click
    Clientside click input handler. It calls another external,
    $input_click_client, which you can override. If that external doesn't
    return a value that evaluates to true, it sends a click request to the
    server. Do not override this.

    Arguments:
        - btn - the clicked button.
        - down - whether it was pressed.
        - x, y, z - the position of the click in the world.
        - uid - the unique ID of the entity that was clicked
          (if any, nil otherwise).
        - cx, cy - the cursor position.
]]
set_ext("input_click", function(btn, down, x, y, z, uid, cx, cy)
    if not get_ext("input_click_client")(btn, down, x, y, z, uid, cx, cy) then
        msg.send(capi.do_click, btn, down, x, y, z, uid)
    end
end)

--[[! Function: input_click_client
    Clientside external for user-defined clicks. By default it tries to call
    the click method on the given entity assuming the entity exists and it
    has a method of that name. It takes the same arguments as $input_click
    and by default returns false, which means the above external will
    trigger a server request.
]]
set_ext("input_click_client", function(btn, down, x, y, z, uid, cx, cy)
    if not ents then ents = require("core.entities.ents") end
    local ent
    if uid >= 0 then ent = ents.get(uid) end
    if ent and ent.click then
        return ent:click(btn, down, x, y, z, cx, cy)
    end
    return false
end)

event_map = {
    ["input_yaw"         ] = true,
    ["input_pitch"       ] = true,
    ["input_move"        ] = true,
    ["input_strafe"      ] = true,
    ["input_jump"        ] = true,
    ["input_crouch"      ] = true,
    ["input_click_client"] = true,
    ["input_mouse_move"  ] = true
}

end

if SERVER then
--[[! Function: input_click_server
    Serverside external for user-defined clicks. Called assuming
    $input_click_client returns a value that evaluates to false. By default
    it tries to call the same method on the entity as above but on the server.
    Return values of this one are ignored. The arguments are the same, but
    the cursor position is not there (obviously).
]]
set_ext("input_click_server", function(btn, dn, x, y, z, uid)
    if not ents then ents = require("core.entities.ents") end
    local ent
    if uid >= 0 then ent = ents.get(uid) end
    if ent and ent.click then
        return ent:click(btn, down, x, y, z)
    end
end)

event_map = {
    ["input_click_server"] = true
}
end

--! Module: input
local M = {}
local type, assert = type, assert

--[[!
    Sets an event callback. If the callback is not provided, the default
    callback is used (as before overriding).

    On the client you can use "yaw", "pitch", "move", "strafe", "jump",
    "crouch", "click" and "mouse_move". On the server you can use "click".
    They map to the input_EVENTNAME events above. For "click", this maps
    to $input_click_client and $input_click_server on the client and
    server respectively.

    This function returns false when no or invalid name is provided,
    true when callback is nil and the previous callback in other cases
    (nil if the callback doesn't exist - mouse_move).

    Arguments:
        - en - the event name.
        - fun - the callback.
]]
M.set_event = function(en, fun)
    if not en then
        return false
    elseif en == "click" then
        en = SERVER and "input_click_server" or "input_click_client"
    else
        en = "input_" .. en
    end
    local old = event_map[en]
    if not old then return false end
    if fun == nil then
        if en == "input_mouse_move" then
            unset_ext(en)
            return true
        end
        if old == true then return true end
        set_ext(en, old)
        event_map[en] = true
        return true
    end
    assert(type(fun) == "function")
    local ret = get_ext(en)
    if old == true and en != "input_mouse_move" then event_map[en] = ret end
    set_ext(en, fun)
    return ret
end

--[[!
    Gets an event callback. For naming, see $set_event. Returns nil if the name
    is invalid or the callback doesn't exist and the callback otherwise.
]]
M.get_event = function(en)
    if not en then
        return nil
    elseif en == "click" then
        en = SERVER and "input_click_server" or "input_click_client"
    else
        en = "input_" .. en
    end
    if not event_map[en] then return nil end
    return get_ext(en)
end

return M
