--[[!<
    Loads OctaScript, a language that compiles to LuaJIT bytecode and is
    used by OctaForge for scripting.

    This is an OctaForge project that also lives within its own repository
    on the OctaForge Git as well as on GitHub mirror (quaker66/octascript).

    Author:
        q66 <quaker66@gmail.com>

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

capi.log(1, "OctaScript initialization complete.")

return M
