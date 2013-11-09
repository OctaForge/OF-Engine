--[[! File: lua/core/logger.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        A logger module.
]]

local capi = require("capi")

local M = {}

--[[! Variable: INFO ]]
M.INFO = 0

--[[! Variable: DEBUG ]]
M.DEBUG = 1

--[[! Variable: WARNING ]]
M.WARNING = 2

--[[! Variable: ERROR ]]
M.ERROR = 3

--[[! Function: log
    Logs some text into the console with the given level. By default, OF
    uses the "WARNING" level. You can change it on engine startup.

    Takes the log level and the text.

    Levels:
        INFO - Use for often repeating output that is not by default of much
        use.
        DEBUG - Use for the usual debugging output.
        WARNING - This level is usually displayed by default.
        ERROR - Use for serious error messages, displayed always. Printed into
        the in-engine console.
]]
M.log = capi.log

--[[! Function: echo
    Displays some text into both consoles (in-engine and terminal). Takes
    only the text, there is no logging level, no changes are made to the
    text. It's printed as it's given.
]]
M.echo = capi.echo

--[[! Function: should_log
    Given a log level, this returns true if that level should be logged
    and false otherwise.
]]
M.should_log = capi.should_log

return M
