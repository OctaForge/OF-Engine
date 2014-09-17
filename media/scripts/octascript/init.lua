--[[!<
    Loads OctaScript, a language that compiles to LuaJIT bytecode and is
    used by OctaForge for scripting.

    This is an OctaForge project that also lives within its own repository
    on the OctaForge Git as well as on GitHub mirror (quaker66/octascript).

    This init file serves as a loader and it also replaces the default module
    loader and convenience functions (load, loadstring, loadfile, dofile)
    with OctaScript-enabled ones.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")

capi.log(1, "Initializing OctaScript.")

local parser = require('octascript.parser')
local generator = require('octascript.generator')
local util = require("octascript.util")

rawset(_G, "__rt_core", require("octascript.rt"))

require("octascript.std")

local M = {}

local io_open, load, error = io.open, load, error
local spath = package.searchpath

local cond_env = { debug = capi.should_log(1), server = SERVER }

local compile = function(fname, src)
    local succ, tree = pcall(parser.parse, fname, src, cond_env)
    if not succ then error(select(2, util.error(tree))) end
    local succ, bcode = pcall(generator, tree, fname)
    if not succ then error(select(2, util.error(bcode))) end
    return bcode
end
M.compile = compile

package.loaders[2] = function(modname, ppath)
    local  fname, err = spath(modname, ppath or package.path)
    if not fname then return err end
    local file = io_open(fname, "rb")
    local toparse = file:read("*all")
    file:close()
    local chunkname = "@" .. fname
    local parsed
    if fname:sub(#fname - 3) == ".lua" then
        parsed = toparse
    else
        parsed = compile(chunkname, toparse)
    end
    local f, err = load(parsed, chunkname)
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
        chunkname = chunkname or "=(load)"
    else
        chunkname = chunkname or ld
    end
    local ret, parsed = pcall(compile, chunkname, ld)
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
    local ret, parsed = pcall(compile, chunkname, file)
    if not ret then return nil, parsed end
    return load(parsed, chunkname, mode, env)
end

local eval = package.loaded["std.eval"]

--[[! Function: load
    Replaces the default "load" with a version that uses the OctaScript
    compiler. Fully compatible with LuaJIT "load".
]]
eval["load"] = load_new

--[[! Function: loadstring
    An alias for "load".
]]
eval["loadstring"] = load_new

--[[! Function: loadfile
    Replaces the default "loadfile" with a version that uses the OctaScript
    compiler. Fully compatible wih LuaJIT "loadfile".
]]
eval["loadfile"] = loadfile_new

--[[! Function: dofile
    Replaces the default "dofile" with a version that uses the OctaScript
    compiler. Fully compatible wih LuaJIT "dofile".
]]
eval["dofile"] = function(fname)
    local  func, err = loadfile_new(fname)
    if not func then error(err, 0) end
    return func()
end

capi.log(1, "OctaScript initialization complete.")

return M
