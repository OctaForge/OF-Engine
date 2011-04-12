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

--- Callback that gets called when action 0 occurs (mapped using keymap)
-- @class function
-- @name actionkey0
actionkey0 = CAPI.actionkey0

--- Callback that gets called when action 1 occurs (mapped using keymap)
-- @class function
-- @name actionkey1
actionkey1 = CAPI.actionkey1

--- Callback that gets called when action 2 occurs (mapped using keymap)
-- @class function
-- @name actionkey2
actionkey2 = CAPI.actionkey2

--- Callback that gets called when action 3 occurs (mapped using keymap)
-- @class function
-- @name actionkey3
actionkey3 = CAPI.actionkey3

--- Callback that gets called when action 4 occurs (mapped using keymap)
-- @class function
-- @name actionkey4
actionkey4 = CAPI.actionkey4

--- Callback that gets called when action 5 occurs (mapped using keymap)
-- @class function
-- @name actionkey5
actionkey5 = CAPI.actionkey5

--- Callback that gets called when action 6 occurs (mapped using keymap)
-- @class function
-- @name actionkey6
actionkey6 = CAPI.actionkey6

--- Callback that gets called when action 7 occurs (mapped using keymap)
-- @class function
-- @name actionkey7
actionkey7 = CAPI.actionkey7

--- Callback that gets called when action 8 occurs (mapped using keymap)
-- @class function
-- @name actionkey8
actionkey8 = CAPI.actionkey8

--- Callback that gets called when action 9 occurs (mapped using keymap)
-- @class function
-- @name actionkey9
actionkey9 = CAPI.actionkey9

--- Callback that gets called when action 10 occurs (mapped using keymap)
-- @class function
-- @name actionkey10
actionkey10 = CAPI.actionkey10

--- Callback that gets called when action 11 occurs (mapped using keymap)
-- @class function
-- @name actionkey11
actionkey11 = CAPI.actionkey11

--- Callback that gets called when action 12 occurs (mapped using keymap)
-- @class function
-- @name actionkey12
actionkey12 = CAPI.actionkey12

--- Callback that gets called when action 13 occurs (mapped using keymap)
-- @class function
-- @name actionkey13
actionkey13 = CAPI.actionkey13

--- Callback that gets called when action 14 occurs (mapped using keymap)
-- @class function
-- @name actionkey14
actionkey14 = CAPI.actionkey14

--- Callback that gets called when action 15 occurs (mapped using keymap)
-- @class function
-- @name actionkey15
actionkey15 = CAPI.actionkey15

--- Callback that gets called when action 16 occurs (mapped using keymap)
-- @class function
-- @name actionkey16
actionkey16 = CAPI.actionkey16

--- Callback that gets called when action 17 occurs (mapped using keymap)
-- @class function
-- @name actionkey17
actionkey17 = CAPI.actionkey17

--- Callback that gets called when action 18 occurs (mapped using keymap)
-- @class function
-- @name actionkey18
actionkey18 = CAPI.actionkey18

--- Callback that gets called when action 19 occurs (mapped using keymap)
-- @class function
-- @name actionkey19
actionkey19 = CAPI.actionkey19

--- Callback that gets called when action 20 occurs (mapped using keymap)
-- @class function
-- @name actionkey20
actionkey20 = CAPI.actionkey20

--- Callback that gets called when action 21 occurs (mapped using keymap)
-- @class function
-- @name actionkey21
actionkey21 = CAPI.actionkey21

--- Callback that gets called when action 22 occurs (mapped using keymap)
-- @class function
-- @name actionkey22
actionkey22 = CAPI.actionkey22

--- Callback that gets called when action 23 occurs (mapped using keymap)
-- @class function
-- @name actionkey23
actionkey23 = CAPI.actionkey23

--- Callback that gets called when action 24 occurs (mapped using keymap)
-- @class function
-- @name actionkey24
actionkey24 = CAPI.actionkey24

--- Callback that gets called when action 25 occurs (mapped using keymap)
-- @class function
-- @name actionkey25
actionkey25 = CAPI.actionkey25

--- Callback that gets called when action 26 occurs (mapped using keymap)
-- @class function
-- @name actionkey26
actionkey26 = CAPI.actionkey26

--- Callback that gets called when action 27 occurs (mapped using keymap)
-- @class function
-- @name actionkey27
actionkey27 = CAPI.actionkey27

--- Callback that gets called when action 28 occurs (mapped using keymap)
-- @class function
-- @name actionkey28
actionkey28 = CAPI.actionkey28

--- Callback that gets called when action 29 occurs (mapped using keymap)
-- @class function
-- @name actionkey29
actionkey29 = CAPI.actionkey29

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

--- Callback that gets called when mouse button 1 is clicked
-- @class function
-- @name mouse1click
mouse1click = CAPI.mouse1click

--- Callback that gets called when mouse button 2 is clicked
-- @class function
-- @name mouse2click
mouse2click = CAPI.mouse2click

--- Callback that gets called when mouse button 3 is clicked
-- @class function
-- @name mouse3click
mouse3click = CAPI.mouse3click

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
