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
    This module provides console interface (toggling, history, etc.)
]]
module("console", package.seeall)

--[[!
    Function: toggle
    Toggles full console viewing. If you want to show the prompt, take
    a look at <prompt>.
]]
toggle = CAPI.toggleconsole

--[[!
    Function: skip
    Allows you to browse through the full console history by offsetting the output.

    Parameters:
        n - how much to skip. 1 means by 1 line back in history, -1000 resets the history.
]]
skip = CAPI.conskip

--[[!
    Function: miniskip
    See <skip>. This applies for the small console.
]]
miniskip = CAPI.miniconskip

--[[!
    Function: clear
    Clears the console.
]]
clear = CAPI.clearconsole

--[[!
    Function: say
    Says something in in-game chat. Sends messages through server.

    Parameters:
        msg - the message to send.
]]
say = CAPI.say

--[[!
    Function: prompt
    Shows a command prompt. Optionally allows to specify event and prompt string.

    Parameters:
        init - initial prompt value.
        action - action to perform when user finishes input, optional. It's string for now, FIXME.
        prompt_prefix - what to display before input field, optional.
]]
prompt = CAPI.prompt

--[[!
    Function: history
    Re-runs a command at position n.

    Parameters:
        n - a command position (counted from the end - 1 is previous command)
]]
history = CAPI.history
