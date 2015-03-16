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

local std = require("octascript.std")

local M = {}

std.package.cond_env = { debug = capi.should_log(1), server = SERVER }

local compile = std.eval.compile
M.compile = compile
M.env = require("octascript.rt").env
M.traceback = debug.traceback

require("octascript.std.native")
require("octascript.std.native.geom")

capi.log(1, "OctaScript initialization complete.")

return M
