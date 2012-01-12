--[[! File: library/core/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Loads all required core modules. Before doing that, sets up logging.
]]

--[[! Function: trace
    Not in use. Traces what Lua does and logs it into the console. Very
    verbose. Use only when absolutely required. Uncomment the sethook
    line to use it. Takes two arguments, the caught event and the
    line on which the event was caught.

    Does not get logged, just printed into the console.

    (start code)
        debug.sethook(trace, "c")
    (end)
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

--[[! Function: log
    Logs some text into the console with a given level. By default, OF
    uses the "WARNING" level. You can change it on engine startup.

    Takes the log level and the text.

    Levels:
        INFO - Use for often repeating output that is not by default of much
        use. Tend to use DEBUG instead of this, however.
        DEBUG - Use for the usual debugging output.
        WARNING - This level is usually displayed by default.
        ERROR - Use for serious error messages, displayed always. Printed into
        the in-engine console too, unlike all others.
]]
log = CAPI.log

INFO    = CAPI.INFO
DEBUG   = CAPI.DEBUG
WARNING = CAPI.WARNING
ERROR   = CAPI.ERROR

--[[! Function: echo
    Displays some text into both consoles (in-engine and terminal). Takes
    only the text, there is no logging level, no changes are made to the
    text. It's printed as it's given.
]]
echo = CAPI.echo

log(DEBUG, "Initializing the new core library.")
require("std")

log(DEBUG, "Initializing base.")
require("base")

log(DEBUG, "Initializing tgui.")
require("tgui")

log(DEBUG, "Initializing LAPI.")
LAPI = require("lapi")

log(DEBUG, "Core scripting initialization complete.")
