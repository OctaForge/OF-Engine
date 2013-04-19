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
    Function: set_targeted_entity
    Sets currently targeted entity. Useful for i.e. entity properties GUI.

    Parameters:
        uid - unique ID of the entity to target.
]]
set_targeted_entity = _C.set_targeted_entity

--[[!
    Function: get_target_position
    Returns the position we're targeting to.
]]
get_target_position = frame.cache_by_frame(function()
    return math.Vec3(_C.gettargetpos())
end)

--[[!
    Function: get_target_entity
    Returns the entity we're targeting to.
]]
get_target_entity = frame.cache_by_frame(_C.gettargetent)

--[[!
    Function: save_mouse_position
    Saves mouse position in internal storage. This is later
    used when editing, i.e. when inserting entity to know
    where to insert it.
]]
save_mouse_position = _C.save_mouse_position
