--[[! File: lua/core/init.lua

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

_C.log(1, "Initializing logging.")

local log = require("core.logger")

local io_open, load, error = io.open, load, error
local pp_loader = function(fname, modname)
    if not _C.should_log(1) then return nil end
    local file = io_open(fname, "rb")
    local f, err = load(function()
        local  line = file:read("*L")
        if not line then
            file:close()
            return nil
        end
        return (line:match("^%s*--@D (.+)$")) or line
    end, "@" .. fname)
    if not f then
        error("error loading module '" .. modname .. "' from file '"
            .. fname .. "':\n" .. err, 2)
    end
    return f
end
_G["pp_loader"] = pp_loader

local spath = package.searchpath
table.insert(package.loaders, 2, function(modname)
    local  v, err = spath(modname, package.path)
    if not v then return err end
    return pp_loader(v, modname)
end)

--[[! Function: cubescript
    Executes the given cubescript string. Returns the return value of the
    cubescript expression.
]]
cubescript = _C.cubescript

log.log(log.DEBUG, "Initializing the core library.")

log.log(log.DEBUG, ":: Lua extensions.")
require("core.lua")

log.log(log.DEBUG, ":: Network system.")
require("core.network")

log.log(log.DEBUG, ":: Event system.")
require("core.events")

log.log(log.DEBUG, ":: Engine system.")
require("core.engine")

log.log(log.DEBUG, ":: Entity system.")
require("core.entities")

if not package.loaded["gui"] then
    log.log(log.DEBUG, "Initializing GUI")
    require("gui")
end

log.log(log.DEBUG, "Core scripting initialization complete.")
