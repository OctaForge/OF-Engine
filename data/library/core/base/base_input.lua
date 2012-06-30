--[[!
    File: library/core/base/base_input.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides interface to common input functions,
        like keybindings.
]]

--[[!
    Package: input
    This module provides input interface, like keybindings / mousebindings.

    Besides things documented in later parts, you can define a few global
    functions that'll greatly affect input handling.

    do_movement:
        Called when player should go forward or backward. Takes two arguments,
        first one being number of value 1 when going forward and -1 when
        backward, second one being a boolean value specifying if forward
        button is currently pressed. By default, simply sets move property.

    do_strafe:
        Same as do_movement, except that 1 is for right strafing
        and -1 for left strafing.

    do_jump:
        Called when player should jump, by default just sets jump property.
        Takes one argument specifying if key is currently pressed.

    do_yaw:
        Same as do_strafe, for turning motion.

    do_pitch:
        Same as do_yaw for looking up/down, except that 1 means
        looking up, -1 down.

    do_mousemove:
        Allows customization of mouse effects. Takes yaw and pitch and returns
        a table (associative) with first element with key yaw meaning yaw and
        second with key pitch meaning pitch. That way, allows modification of
        input yaw and pitch values. By default, simply returns the inputs
        as a table.

    client_click:
        Called when player clicks on client. Takes 6 arguments, first one being
        mouse button number (1 left, 2 right, 3 middle), second one being
        boolean variable with value of true when button is pressed, third being
        the position where the click occured, fourth one being the entity on
        which it occured, fifth one being X position where click occured
        (from 0 to 1) and sixth one being Y position where click occured
        (again, 0 to 1). You can also override this per-entity, see
        <base_client.client_click>.

    click:
        Same as client_click, but serverside. Doesn't take the last
        two x, y arguments. You can also override this per-entity,
        see <base_server.click>.
]]
module("input", package.seeall)

--[[!
    Variable: BIND_DEFAULT
    Standard binding outside edit mode / spectator mode.

    See Also:
        <BIND_SPEC>
        <BIND_EDIT>
        <BIND_MAP>
]]
BIND_DEFAULT = 0

--[[!
    Variable: BIND_SPEC
    Spectator mode specific binding.

    See Also:
        <BIND_DEFAULT>
        <BIND_EDIT>
        <BIND_MAP>
]]
BIND_SPEC    = 1

--[[!
    Variable: BIND_EDIT
    Edit mode specific binding.

    See Also:
        <BIND_SPEC>
        <BIND_DEFAULT>
        <BIND_MAP>
]]
BIND_EDIT    = 2

--[[!
    Variable: BIND_MAP
    You use this for per-map binding overrides.
    Applies outside edit / spec mode.

    See Also:
        <BIND_SPEC>
        <BIND_EDIT>
        <BIND_DEFAULT>
]]
BIND_MAP     = 3

--[[!
    Variable: per_map_keys
    Storage of overriden binds. Gets re-set with Lua engine
    restart, so applies per-map only.
]]
per_map_keys = {}

--[[!
    Function: bind
    Binds a key outside spec / edit mode. See <bind_spec> and
    <bind_edit> for specific bindings. There are also pre-defined
    bind functions that toggle vars / modifiers - <bind_var_toggle>
    and <bind_modifier>.

    Parameters:
        key - a string specifying the key to bind. See keymap.cfg.
        action - a string with Lua code executed when the bind
        gets activated.
]]
function bind(key, action)
    CAPI.bind(key, BIND_DEFAULT, action)
end

--[[!
    Function: bind_var_toggle
    Toggles an engine variable. Simillar to <bind>. If engine variable
    has value 0, it sets 1, otherwise 0. See also <bind_var_toggle_edit>
    and <bind_modifier>.

    Parameters:
        key - a string specifying the key to bind. See keymap.cfg.
        var - a variable to toggle.
]]
function bind_var_toggle(key, var)
    bind(key, [[
        EVAR[%(1)q] =  (EVAR[%(1)q] == 1) and 0 or 1
        echo(%(1)q .. ((EVAR[%(1)q] == 1) and " ON" or " OFF"))
    ]] % { var })
end

--[[!
    Function: bind_modifier
    Toggles a modifier variable, which is a global number variable
    with values 1 or 0. Simillar to <bind>. See also <bind_modifier_edit>
    and <bind_var_toggle>.

    Parameters:
        key - a string specifying the key to bind. See keymap.cfg.
        modifier - a global variable storing modifier state.
]]
function bind_modifier(key, modifier)
    bind(key, [[
        EVAR[%(1)q] = 1
        input.on_release(function()
            EVAR[%(1)q] = 0
        end)
    ]] % { modifier })
end

--[[!
    Function: bind_map_specific
    Same as <bind>, except that bind is made only for single map
    and it doesn't get persistently saved. Also, it has its own
    <BIND_MAP>.

    Parameters:
        key - see <bind>.
        action - see <bind>. Unlike <bind>, it is a function and
        can take argument when data is provided.
        data - a variable that is optionally passed to action.
]]
function bind_map_specific(key, action, data)
    if data then
        per_map_keys[key] = function() action(data) end
    else
        per_map_keys[key] = action
    end
end

--[[!
    Function: unbind_map_specific
    Removes a per-map binding from key, which was set by <bind_map_specific>.

    Parameters:
        key - key to remove binding from.
]]
function unbind_map_specific(key)
    per_map_keys[key] = nil
end

--[[!
    Function: bind_spec
    Binds a key in spectator mode.

    Parameters:
        See <bind>.
]]
function bind_spec(key, action)
    CAPI.bind(key, BIND_SPEC, action)
end

--[[!
    Function: bind_edit
    Binds a key in edit mode.

    Parameters:
        See <bind>.
]]
function bind_edit(key, action)
    CAPI.bind(key, BIND_EDIT, action)
end

--[[!
    Function: bind_var_toggle_edit
    See <bind_var_toggle>. It's the same, but it's for edit mode.
]]
function bind_var_toggle_edit(key, var)
    bind_edit(key, [[
        EVAR[%(1)q] =  (EVAR[%(1)q] == 1) and 0 or 1
        echo(%(1)q .. ((EVAR[%(1)q] == 1) and " ON" or " OFF"))
    ]] % { var })
end

--[[!
    Function: bind_modifier_edit
    See <bind_var_toggle>. It's the same, but it's for edit mode.
]]
function bind_modifier_edit(key, modifier)
    bind_edit(key, [[
        EVAR[%(1)q] = 1
        input.on_release(function()
            EVAR[%(1)q] = 0
        end)
    ]] % { modifier })
end

--[[!
    Function: get_bind
    Gets action function for specific key.

    Parameters:
        key - the key to get action for.
        bind_type - see <BIND_DEFAULT>, <BIND_SPEC>,
        <BIND_EDIT> and <BIND_MAP>.

    Returns:
        The action.
]]
function get_bind(key, bind_type)
    if bind_type == BIND_MAP then
        return per_map_keys[key]
    else
        return CAPI.getbind(key, bind_type)
    end
end

--[[!
    Function: search_binds
    Get an array of keybindings that fit given action and bind
    type. The array then consists of names of they keys.

    Parameters:
        action - the action to get keys for.
        bind_type - see <BIND_DEFAULT>, <BIND_SPEC>,
        <BIND_EDIT> and <BIND_MAP>.
]]
search_binds = CAPI.searchbinds

--[[!
    Function: on_release
    Executes a function on key release. You'll want to use this
    inside key binding probably.

    Parameters:
        action - the action to execute. Takes no arguments.
]]
on_release = CAPI.onrelease

--[[!
    Function: map_key
    Maps a key ID to name. See keymap.cfg.

    Parameters:
        id - The key id (number).
        name - The name to map id to.
]]
map_key = CAPI.keymap

--[[!
    Function: turn_left
    Turns player left. Used for motion control with keyboard.
]]
turn_left = CAPI.turn_left

--[[!
    Function: turn_right
    Turns player right. Used for motion control with keyboard.
]]
turn_right = CAPI.turn_right

--[[!
    Function: look_up
    Makes player look up. Used for motion control with keyboard.
]]
look_down = CAPI.look_down

--[[!
    Function: look_down
    Makes player look down. Used for motion control with keyboard.
]]
look_up = CAPI.look_up

--[[!
    Function: backward
    Makes player go backward. Used for motion control with keyboard.
]]
backward = CAPI.backward

--[[!
    Function: forward
    Makes player go forward. Used for motion control with keyboard.
]]
forward = CAPI.forward

--[[!
    Function: strafe_left
    Makes player strafe left. Used for motion control with keyboard.
]]
strafe_left = CAPI.left

--[[!
    Function: strafe_right
    Makes player strafe right. Used for motion control with keyboard.
]]
strafe_right = CAPI.right

--[[!
    Function: jump
    Makes player jump. Used for motion control with keyboard.
]]
jump = CAPI.jump

--[[!
    Function: set_targeted_entity
    Sets currently targeted entity. Useful for i.e. entity properties GUI.

    Parameters:
        uid - unique ID of the entity to target.
]]
set_targeted_entity = CAPI.set_targeted_entity

--[[!
    Function: mouse1click
    Triggers left click event. Used mainly by bindings. User can then define
    their own functions that'll affect mouse clicking.
]]
mouse1click = CAPI.mouse1click

--[[!
    Function: mouse2click
    Triggers right click event. Used mainly by bindings. User can then define
    their own functions that'll affect mouse clicking.
]]
mouse2click = CAPI.mouse2click

--[[!
    Function: mouse3click
    Triggers middle click event. Used mainly by bindings. User can then define
    their own functions that'll affect mouse clicking.
]]
mouse3click = CAPI.mouse3click

--[[!
    Function: get_target_position
    Returns the position we're targeting to.
]]
get_target_position = frame.cache_by_frame(CAPI.gettargetpos)

--[[!
    Function: get_target_entity
    Returns the entity we're targeting to.
]]
get_target_entity = frame.cache_by_frame(CAPI.gettargetent)

--[[!
    Function: save_mouse_position
    Saves mouse position in internal storage. This is later
    used when editing, i.e. when inserting entity to know
    where to insert it.
]]
save_mouse_position = CAPI.save_mouse_position
