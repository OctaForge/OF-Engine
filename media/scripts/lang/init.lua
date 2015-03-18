--[[!<
    Loads OctaScript, a language that compiles to LuaJIT bytecode and is
    used by OctaForge for scripting.

    This is an OctaForge project that also lives within its own repository
    on the OctaForge Git as well as on GitHub mirror (OctaForge/OctaScript).

    Author:
        q66 <daniel@octaforge.org>

    License:
        See COPYING.txt.
]]

local capi = require("capi")

capi.log(1, "Initializing OctaScript.")

package.path = "media/scripts/lang/octascript/?/init.oct;"
            .. "media/scripts/lang/octascript/?/init.lua;"
            .. "media/scripts/lang/octascript/?.lua"

local std = require("octascript.stdcore")

local M = {}

std.package.cond_env = { debug = capi.should_log(1), server = SERVER }

local compile = std.eval.compile
M.compile = compile
M.env = require("octascript.rt").env
M.traceback = debug.traceback

require("octascript.stdcore.native")

capi.log(1, "OctaScript initialization complete.")

local oldloader = std.package.loaders[1]

local octfile_read = function(path)
    local file, err = capi.stream_open(path, "r")
    if not file then return nil, err end
    local tp = file:read("*all")
    file:close()
    return tp
end

std.package.loaders[1] = function(modname, ppath)
    return oldloader(modname, ppath, capi.search_oct_path, octfile_read)
end

std.package.path = "media/?/init.oct;"
                .. "media/?.oct;"
                .. "media/scripts/lang/octascript/octascript/stdlib/?.oct;"
                .. "media/scripts/?/init.oct;"
                .. "media/scripts/?.oct"

return M
