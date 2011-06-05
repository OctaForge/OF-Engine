--[[!
    File: base/base_console.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features console interface.

    Section: Console system
]]

--[[!
    Package: console
    This module provides console interface, such as bindings, some commands,
    input system and others.
]]
module("console", package.seeall)

--- Toggle the console.
-- @class function
-- @name toggle
toggle = CAPI.toggleconsole

---
-- @class function
-- @name skip
skip = CAPI.conskip

---
-- @class function
-- @name miniskip
miniskip = CAPI.miniconskip

--- Clear the console
-- @class function
-- @name clear
clear = CAPI.clearconsole

action_keys = {}
binds = {}

--- Bind a key to an action
-- @class function
-- @name binds.add
-- @param key Key to bind
-- @param action Action to bind the key to
binds.add = CAPI.bind

--- Bind a key to toggling a variable
-- @param key Key to bind
-- @param var The variable to toggle
function binds.addvar(key, var)
    CAPI.bind(key, [[%(1)s = %(1)s == 1 and 0 or 1; echo(%(1)q .. %(1)s == 1 and "ON" or "OFF")]] % { var })
end

--- Bind a modifier
-- @param key Key to bind
-- @param modifier
function binds.addmod(key, modifier)
    CAPI.bind(key, [[%(1)s = 1; console.onrelease([=[%(1)s = 0]=])]] % { modifier })
end

function binds.add_action_key(key, action, self)
    if type(action) == "string" then
        local _action = action
        action = function() loadstring(_action)() end
    end
    if self then
        action_keys[key] = function() action(self) end
    else
        action_keys[key] = action
    end
end

function binds.del_action_key(key)
    action_keys[key] = nil
end

function binds.get_action_key(key)
    return action_keys[key]
end

--- Bind a key to an action (spectator mode)
-- @class function
-- @name binds.addspec
-- @param key Key to bind
-- @param action Action to bind the key to
binds.addspec = CAPI.specbind

--- Bind a key to an action (edit mode)
-- @class function
-- @name binds.addedit
-- @param key Key to bind
-- @param action Action to bind the key to
binds.addedit = CAPI.editbind

--- Bind a key to toggling a variable (edit mode)
-- @param key Key to bind
-- @param var The variable to toggle
function binds.addvaredit(key, var)
    CAPI.editbind(key, [[%(1)s = %(1)s == 1 and 0 or 1; echo(%(1)q .. %(1)s == 1 and "ON" or "OFF")]] % { var })
end

--- Bind a modifier (edit mode)
-- @param key Key to bind
-- @param modifier
function binds.addmodedit(key, modifier)
    CAPI.editbind(key, [[%(1)s = 1; console.onrelease([=[%(1)s = 0]=])]] % { modifier })
end

--- Get the action a key is bound to
-- @class function
-- @name binds.get
-- @param key The key you want to know the bound action of
-- @return The action the key is bound to
binds.get = CAPI.getbind

--- Get the action a key is bound to (spectator mode)
-- @class function
-- @name binds.getspec
-- @param key The key you want to know the bound action of
-- @return The action the key is bound to
binds.getspec = CAPI.getspecbind

--- Get the action a key is bound to (edit mode)
-- @class function
-- @name binds.getedit
-- @param key The key you want to know the bound action of
-- @return The action the key is bound to
binds.getedit = CAPI.geteditbind

--- Get all keys bound to an action
-- @class function
-- @name binds.search
-- @param action The action
-- @return ... A list of bound keys (vararg, no table)
binds.search = CAPI.searchbinds

--- Get all keys bound to an action (spectator mode)
-- @class function
-- @name binds.searchspec
-- @param action The action
-- @return ... A list of bound keys (vararg, no table)
binds.searchspec = CAPI.searchspecbinds

--- Get all keys bound to an action (edit mode)
-- @class function
-- @name binds.searchedit
-- @param action The action
-- @return ... A list of bound keys (vararg, no table)
binds.searchedit = CAPI.searcheditbinds

--- Send text to the server (aka 'say')
-- @class function
-- @name say
-- @param ... The text
say = CAPI.say

--- 
-- @class function
-- @name saycommand
saycommand = CAPI.saycommand

---
function sayteamcommand() echo("Team chat not yet implemented") end

---
-- @class function
-- @name inputcommand
inputcommand = CAPI.inputcommand

--- Rerun command at position n
-- @class function
-- @name history
-- @param n Position of command to rerun (counted from end)
history = CAPI.history

---
-- @class function
-- @name onrelease
onrelease = CAPI.onrelease

--- Map a keycode to a key
-- @class function
-- @name keymap
-- @param keycode Numerical scancode of a key
-- @param key Key (name) to map it to
keymap = CAPI.keymap

--- Turn to the left
-- @class function
-- @name turn_left
turn_left = CAPI.turn_left

--- Turn to the right
-- @class function
-- @name turn_right
turn_right = CAPI.turn_right

--- Look down
-- @class function
-- @name look_down
look_down = CAPI.look_down

--- Look up
-- @class function
-- @name look_up
look_up = CAPI.look_up

--- Move backward
-- @class function
-- @name backward
backward = CAPI.backward

--- Move forward
-- @class function
-- @name forward
forward = CAPI.forward

--- Move left
-- @class function
-- @name left
left = CAPI.left

--- Move right
-- @class function
-- @name right
right = CAPI.right

--- Jump
-- @class function
-- @name jump
jump = CAPI.jump

--- Use mouse targeting
-- @class function
-- @name mouse_targeting
-- @param mouse_targeting Use mouse targeting
mouse_targeting = CAPI.mouse_targeting

--- Set the entity that is targeted
-- @class function
-- @name set_mouse_targeting_ent
-- @param ent Entity id
-- @return valid Is the set entity valid?
set_mouse_targeting_ent = CAPI.set_mouse_targeting_ent

--- Set the client/player that is targeted
-- @class function
-- @name set_mouse_targeting_client
-- @param client Client id
-- @return valid Is the set entity valid?
set_mouse_target_client = CAPI.set_mouse_target_client

--- Save the current mouse position
-- @class function
-- @name save_mouse_pos
save_mouse_pos = CAPI.save_mouse_pos

--- Mouse button 1 click (left mouse button).
-- @class function
-- @name mouse1click
mouse1click = CAPI.mouse1click

--- Mouse button 2 click (right mouse button).
-- @class function
-- @name mouse1click
mouse2click = CAPI.mouse2click

--- Mouse button 3 click (middle mouse button).
-- @class function
-- @name mouse1click
mouse3click = CAPI.mouse3click
