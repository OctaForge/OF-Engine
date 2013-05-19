--[[! File: library/core/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Loads all required core modules. Before doing that, sets up logging.
        This also loads the LuaJIT FFI, which is however fully accessible for
        the core library only.
]]

-- lua 5.2 feature test
assert(#setmetatable({}, { __len = function() return 1337 end }) == 1337,
    "a version of LuaJIT with 5.2 features on is required")

-- init a random seed
math.randomseed(os.time())

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

INFO    = 0
DEBUG   = 1
WARNING = 2
ERROR   = 3

_C.log(DEBUG, "Initializing logging.")

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
log = _C.log

local io_open, load, error = io.open, load, error
table.insert(package.loaders, 2, function(modname)
    local err, modpath = "", modname:gsub("%.", "/")
    for path in package.path:gmatch("([^;]+)") do
        local fname = path:gsub("%?", modpath)
        local file = io_open(fname, "rb")
        local prevlevel
        if file then
            local f, err = load(function()
                local  line = file:read("*L")
                if not line then
                    file:close()
                    return nil
                end
                local lvl, rst = line:match("^%s*#log%s*%(([A-Z]+),%s*(.+)$")
                if lvl then
                    prevlevel = _G[lvl]
                    if _C.should_log(prevlevel) then
                        local a, b = line:find("^%s*#")
                        return line:sub(b + 1)
                    else
                        return "--" .. line
                    end
                elseif prevlevel then
                    local a, b = line:find("^%s*#")
                    if a then
                        if _C.should_log(prevlevel) then
                            return line:sub(b + 1)
                        else
                            return "--" .. line
                        end
                    else
                        prevlevel = nil
                        return line
                    end
                else
                    return line
                end
            end, "@" .. fname)
            if not f then
                error("error loading module '" .. modname .. "' from file '"
                    .. fname .. "':\n" .. err, 2)
            end
            return f
        end
        err = err .. "\n\tno file '" .. fname .. "'"
    end
    return err
end)

--[[! Function: echo
    Displays some text into both consoles (in-engine and terminal). Takes
    only the text, there is no logging level, no changes are made to the
    text. It's printed as it's given.
]]
echo = _C.echo

--[[! Function: cubescript
    Executes the given cubescript string. Returns the return value of the
    cubescript expression.
]]
cubescript = _C.cubescript

local dbg = _C.should_log(DEBUG)

if dbg then log(DEBUG, "Initializing the core library.") end

if dbg then log(DEBUG, ":: Lua extensions.") end
require("lua")

if dbg then log(DEBUG, ":: Network system.") end
require("network")

if dbg then log(DEBUG, ":: Event system.") end
require("events")

if CLIENT then
if dbg then log(DEBUG, ":: GUI system.") end
require("gui")
end

if dbg then log(DEBUG, ":: Entity system.") end
require("entities")

if dbg then log(DEBUG, ":: Engine system.") end
require("engine")

if dbg then log(DEBUG, "Initializing base (deprecated).") end
require("base")

if dbg then log(DEBUG, "Core scripting initialization complete.") end
