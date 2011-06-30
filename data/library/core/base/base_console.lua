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

--[[!
    Function: toggle
    Toggles the console viewing.
]]
toggle = CAPI.toggleconsole

--[[!
    Function: skip
    Allows you to browse through the console history by offsetting the output.

    Parameters:
        n - how much to skip. 1 means by 1 item back in history, -1000 resets the history.
]]
skip = CAPI.conskip

---
-- @class function
-- @name miniskip
miniskip = CAPI.miniconskip

--- Clear the console
-- @class function
-- @name clear
clear = CAPI.clearconsole

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
