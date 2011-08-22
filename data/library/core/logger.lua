--[[!
    File: logger.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file contains logger interface for Lua.
]]

--[[!
    Package: logging
    Logging system for OF/Lua with level support.
]]
module("logging", package.seeall)

--[[!
    Function: log
    Logs text into console with given level.
    Displayed levels depend on OctaForge launch options.

    This is wrapped from "logging" table exposed from C.

    Parameters:
        level - The logging level to use.
        text - The text to display.

    Levels:
        INFO - use for often repeating logging that usually just annoys people,
        but might come in use sometimes.
        DEBUG - use for usual debugging output.
        WARNING - this level is usually displayed by default.
        ERROR - Use for error messages, displayed always.
        Printed into in-engine console too, unlike all others.
]]
log = CAPI.log
INFO = CAPI.INFO
DEBUG = CAPI.DEBUG
WARNING = CAPI.WARNING
ERROR = CAPI.ERROR

_G["log"]     = log
_G["INFO"]    = INFO
_G["DEBUG"]   = DEBUG
_G["WARNING"] = WARNING
_G["ERROR"]   = ERROR

--[[!
    Function: echo
    Displays text into both consoles (ingame and terminal).
    This is wrapped from "logging" table exposed from C.

    Parameters:
        text - The text to display.
]]
echo = CAPI.echo

_G["echo"] = echo
