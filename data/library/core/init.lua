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

CAPI.log(CAPI.DEBUG, "Initializing logging.")
require("logger")

logging.log(logging.DEBUG, "Initializing language extensions.")
require("language")

logging.log(logging.DEBUG, "Initializing base.")
require("base")

logging.log(logging.DEBUG, "Initializing tgui.")
require("tgui")

logging.log(logging.DEBUG, "Core scripting initialization complete.")
