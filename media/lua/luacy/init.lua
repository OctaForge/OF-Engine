--[[!<
    Loads the Luacy language, a supetset of Lua (github: quaker66/luacy).
    This is not an OF project. This init file serves as a loader and it
    also replaces the default module loader and convenience functions
    (load, loadstring, loadfile, dofile) with Luacy-enabled ones.

    Returns the parser module. It's aloded before any other OF library
    component.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")

capi.log(1, "Initializing Luacy.")

local M = require("luacy.parser")
local parse = M.parse

local io_open, load, error = io.open, load, error
local spath = package.searchpath

local cond_env = { debug = capi.should_log(1), server = SERVER }

package.loaders[2] = function(modname, ppath)
    local  fname, err = spath(modname, ppath or package.path)
    if not fname then return err end
    local file = io_open(fname, "rb")
    local toparse = file:read("*all")
    file:close()
    local chunkname = "@" .. fname
    local parsed  = parse(chunkname, toparse, cond_env)
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
        chunkname = chunkname or "=(load)"
    else
        chunkname = chunkname or ld
    end
    local ret, parsed = pcall(parse, chunkname, ld, cond_env)
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
    local ret, parsed = pcall(parse, chunkname, file, cond_env)
    if not ret then return nil, parsed end
    return load(parsed, chunkname, mode, env)
end

--[[! Function: load
    Replaces the default "load" with a version that uses the Luacy compiler.
    Fully compatible with LuaJIT "load".
]]
_G["load"] = load_new

--[[! Function: loadstring
    An alias for "load".
]]
_G["loadstring"] = load_new

--[[! Function: loadfile
    Replaces the default "loadfile" with a version that uses the Luacy
    compiler. Fully compatible wih LuaJIT "loadfile".
]]
_G["loadfile"] = loadfile_new

--[[! Function: dofile
    Replaces the default "dofile" with a version that uses the Luacy
    compiler. Fully compatible wih LuaJIT "dofile".
]]
_G["dofile"] = function(fname)
    local  func, err = loadfile_new(fname)
    if not func then error(err, 0) end
    return func()
end

capi.log(1, "Luacy initialization complete.")

return M
