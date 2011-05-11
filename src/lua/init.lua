--[[!
    File: init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file takes care of properly loading all sub-modules of core
        OctaForge script library.

        Also sets up global logging methods so scripts can easily log things
        without having to repeat the logging module prefix.

        If you want to enable script tracing, look at commented out trace()
        function.

    Section: Core library initialization
]]

--[[!
    Variable: package.path
    Contains paths to Lua scripts. By default adds

    (start code)
        ;./src/lua/?.lua;./src/lua/?/init.lua;./?/init.lua;./data/library/?/init.lua
    (end)
]]
package.path = package.path .. ";./src/lua/?.lua;./src/lua/?/init.lua;./?/init.lua;./data/library/?/init.lua"

--[[!
    Function: trace
    By default commented out. Used to trace what's Lua doing.

    Activated using

    (start code)
        debug.sethook(trace, "c")
    (end)

    Parameters:
        event - The caught event.
        line - The line on which the event was caught.
]]
function trace (event, line)
    local s = debug.getinfo(2, "nSl")
    print("DEBUG:")
    print("    " .. tostring(s.name))
    print("    " .. tostring(s.namewhat))
    print("    " .. tostring(s.source))
    print("    " .. tostring(s.short_src))
    print("    " .. tostring(s.linedefined))
    print("    " .. tostring(s.lastlinedefined))
    print("    " .. tostring(s.what))
    print("    " .. tostring(s.currentline))
end
    
--debug.sethook(trace, "c")

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
        ERROR - Use for error messages, displayed always. Printed into in-engine
        console too, unlike all others.
]]
log = logging.log
INFO = logging.INFO
DEBUG = logging.DEBUG
WARNING = logging.WARNING
ERROR = logging.ERROR

--[[!
    Function: echo
    Displays text into both consoles (ingame and terminal).
    This is wrapped from "logging" table exposed from C.

    Parameters:
        text - The text to display.
]]
echo = logging.echo

logging.log(logging.DEBUG, "Initializing language extensions.")
require("language")

logging.log(logging.DEBUG, "Initializing base.")
require("base")

logging.log(logging.DEBUG, "Core scripting initialization complete.")
