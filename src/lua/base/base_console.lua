---
-- base_console.lua, version 1<br/>
-- Console, bindings, input etc<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local base = _G
local CAPI = require("CAPI")

--- Console Lua interface. Provides methods for bindings,
-- console commands, input and others.
-- @class module
-- @name cc.console
module("cc.console")

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

---
-- @class table
-- @name binds
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
    CAPI.bind(key, [[%(1)s = 1; cc.console.onrelease([=[%(1)s = 0]=])]] % { modifier })
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
    CAPI.editbind(key, [[%(1)s = 1; cc.console.onrelease([=[%(1)s = 0]=])]] % { modifier })
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
function sayteamcommand() base.echo("Team chat not yet implemented") end

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

--- Complete a filename
-- @class function
-- @name complete
-- @param command The command to complete
-- @param dir The directory to look in
-- @param ext The extension of the file
complete = CAPI.complete

--- Complete using a list
-- @class function
-- @name listcomplete
-- @param command The command to complete
-- @param list The list to look commands up in (format unknown)
listcomplete = CAPI.listcomplete

--- Map a keycode to a key
-- @class function
-- @name keymap
-- @param keycode Numerical scancode of a key
-- @param key Key (name) to map it to
keymap = CAPI.keymap

--- Is this a keydown event?
-- @class function
-- @name iskeydown
-- @return Is a keydown event
iskeydown = CAPI.iskeydown

--- Is this a keyup event?
-- @class function
-- @name iskeyup
-- @return Is a keyup event
iskeyup = CAPI.iskeyup

--- Is this a mousedown event?
-- @class function
-- @name ismousedown
-- @return Is a mousedown event
ismousedown = CAPI.ismousedown

--- Is this a mouseup event?
-- @class function
-- @name ismouseup
-- @return Is a mouseup event
ismouseup = CAPI.ismouseup

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
