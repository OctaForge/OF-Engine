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

--[[! Variable: _G
    The metatable on _G is overriden in that manner it doesn't allow creation
    of global variables (and usage of global variables that don't exist) using
    the regular way (assignment).
]]
setmetatable(_G, {
    __newindex = function(self, n)
        error("attempt to create a global variable '" .. n .. "'", 2)
    end,
    __index = function(self, n)
        error("attempt to use a global variable '" .. n .. "'", 2)
    end
})

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
local trace = function(event, line)
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

local capi = require("capi")


capi.log(1, "Initializing logging.")

local parse = require("luacy").parse

local io_open, load, error = io.open, load, error
local spath = package.searchpath

package.loaders[2] = function(modname, ppath)
    local  fname, err = spath(modname, ppath or package.path)
    if not fname then return err end
    local file = io_open(fname, "rb")
    local toparse = file:read("*all")
    file:close()
    local chunkname = "@" .. fname
    local parsed  = parse(chunkname, toparse, capi.should_log(1))
    local f, err  = load(parsed, chunkname)
    if not f then
        error("error loading module '" .. modname .. "' from file '"
            .. fname .. "':\n" .. err, 2)
    end
    return f
end

local loadfile, dofile = loadfile, dofile
local tconc, type = table.concat, type
local assert, pcall = assert, pcall
local io_read = io.read

local load_new = function(ld, chunkname, mode, env)
    if type(ld) ~= "string" then
        local buf = {}
        local ret = ld()
        while ret do
            buf[#buf + 1] = ret
            ret = ld()
        end
        ld = tconc(buf)
    end
    local ret, parsed = pcall(parse, chunkname, ld, capi.should_log(1))
    if not ret then return nil, parsed end
    return load(parsed, chunkname, mode, env)
end

local read_file = function(fname)
    if not fname then
        return io_read("*all"), "=stdin"
    end
    local  file, err = io_open(fname, "rb")
    if not file then return file, err end
    local cont = file:read("*all")
    file:close()
    return cont, "@" .. fname
end

local loadfile_new = function(fname, mode, env)
    local  file, chunkname = read_file(fname)
    if not file then return file, chunkname end
    local ret, parsed = pcall(parse, chunkname, file, capi.should_log(1))
    if not ret then return nil, parsed end
    return load(parsed, chunkname, mode, env)
end

rawset(_G, "load",       load_new)
rawset(_G, "loadstring", load_new)
rawset(_G, "loadfile",   loadfile_new)
rawset(_G, "dofile", function(fname)
    local  func, err = loadfile_new(fname)
    if not func then error(err, 0) end
    return func()
end)

local log = require("core.logger")

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

log.log(log.DEBUG, ":: GUI.")
require("core.gui")

log.log(log.DEBUG, "Core scripting initialization complete.")
