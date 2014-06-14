--[[!<
    Provides environment management for sandboxed scripts.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local logger = require("core.logger")
local stream = require("core.lua.stream")

--! Module: env
local M = {}

local env_package = {
    preload = {}
}

local assert  = assert
local type    = type
local setfenv = setfenv
local tconc   = table.concat

env_package.loaders = {
    function(modname)
        local  v = env_package.preload[modname]
        if not v then
            return ("\tno field package.preload['%s']"):format(modname)
        end
        return v
    end,
    package.loaders[2]
}

local find_loader = function(modname, env)
    env = env or _G
    local err = { ("module '%s' not found\n"):format(modname) }
    local loaders = env_package.loaders
    for i = 1, #loaders do
        local v  = loaders[i](modname)
        local vt = type(v)
        if vt == "function" then
            return setfenv(v, env)
        elseif vt == "string" then
            err[#err + 1] = v
        end
    end
    return nil, tconc(err)
end

local gen_require = function(env)
    return function(modname)
        local v = env_package.loaded[modname]
        if v != nil then return v end
        local  loader, err = find_loader(modname, env)
        if not loader then
            error(err, 2)
        end
        local ret    = loader(modname)
        local loaded = env_package.loaded
        if ret != nil then
            loaded[modname] = ret
            return ret
        elseif loaded[modname] == nil then
            loaded[modname] = true
            return true
        end
        return loaded[modname]
    end
end

local env_structure = {
    ["assert"        ] = true,
    ["bit"           ] = {
        ["arshift"   ] = true,
        ["band"      ] = true,
        ["bnot"      ] = true,
        ["bor"       ] = true,
        ["bswap"     ] = true,
        ["bxor"      ] = true,
        ["lshift"    ] = true,
        ["rol"       ] = true,
        ["ror"       ] = true,
        ["rshift"    ] = true,
        ["tobit"     ] = true,
        ["tohex"     ] = true
    },
    ["coroutine"     ] = true,
    ["error"         ] = true,
    ["getmetatable"  ] = true,
    ["ipairs"        ] = true,
    ["math"          ] = true,
    ["next"          ] = true,
    ["os"            ] = {
        ["clock"     ] = true,
        ["date"      ] = true,
        ["difftime"  ] = true,
        ["time"      ] = true
    },
    ["pairs"         ] = true,
    ["pcall"         ] = true,
    ["print"         ] = true,
    ["rawequal"      ] = true,
    ["rawget"        ] = true,
    ["rawlen"        ] = true,
    ["rawset"        ] = true,
    ["require"       ] = true,
    ["select"        ] = true,
    ["setmetatable"  ] = true,
    ["string"        ] = true,
    ["table"         ] = true,
    ["tonumber"      ] = true,
    ["tostring"      ] = true,
    ["type"          ] = true,
    ["unpack"        ] = true,
    ["xpcall"        ] = true
}

local getmetatable = getmetatable
local env_replacements = {
    ["getmetatable"] = function(tbl)
        return type(tbl) == "table" and getmetatable(tbl) or nil
    end
}

local ploaded = package.loaded

local eloaded = {}
env_package.loaded = eloaded

local rawget = rawget

local disallow = {
    ["core.externals"] = true, ["core.lua.stream"] = true
}

local gen_envtable; gen_envtable = function(tbl, env, rp, mod)
    for k, v in pairs(tbl) do
        if v == true then
            env[k] = rp and rp[k] or (mod and mod[k] or rawget(_G, k))
        elseif type(v) == "table" then
            env[k] = {}
            gen_envtable(v, env[k], rp and rp[k] or nil,
                (mod and mod[k] or rawget(_G, k)))
            eloaded[k] = env[k]
        end
    end
    if not mod then
        env["_G"] = env
        env["SERVER"] = SERVER
        env["require"] = gen_require(env)
        eloaded["_G"] = env
        for k, v in pairs(ploaded) do
            if k:match("core%..+") or k:match("luacy%..+") then
                if not disallow[k] then
                    eloaded[k] = v
                else
                    eloaded[k] = false
                end
            end
        end
    end
    return setmetatable(env, getmetatable(_G))
end

--[[!
    Generates an environment for the mapscript. It's isolated from the outside
    world to some degree, providing some safety against potentially malicious
    code.

    The new environment contains the following global functions: assert, error,
    getmetatable (modified so that it can get only table metatables), ipairs,
    next, pairs, pcall, print, rawequal, rawget, rawlen (when LuaJIT is built
    with 5.2 features), rawset, require (custom version without C module
    loading and with modified loaded table), select, setmetatable, tonumber,
    tostring, type, unpack, xpcall.

    The new environment contains the following default modules: bit, coroutine,
    math, table. It also contains a modified version of the string module that
    doesn't have string.dump and a stripped down version of the os module
    containing functions clock, date, difftime and time.

    The environment also contains the special variable SERVER and inherits
    the metatable of _G.

    All the core.* modules that are preloaded outside are preloaded inside
    as well.
]]
M.gen_mapscript_env = function()
    env_package.path = package.path
    return gen_envtable(env_structure, {}, env_replacements)
end
local gen_mapscript_env = M.gen_mapscript_env

local consolemap = {
    ["capi"                  ] = "capi",
    ["core.engine.camera"    ] = "camera",
    ["core.engine.cubescript"] = "cubescript",
    ["core.engine.stains"    ] = "stains",
    ["core.engine.edit"      ] = "edit",
    ["core.engine.input"     ] = "input",
    ["core.engine.lights"    ] = "lights",
    ["core.engine.model"     ] = "model",
    ["core.engine.particles" ] = "particles",
    ["core.engine.sound"     ] = "sound",
    ["core.entities.ents"    ] = "ents",
    ["core.entities.svars"   ] = "svars",
    ["core.events.actions"   ] = "actions",
    ["core.events.frame"     ] = "frame",
    ["core.events.input"     ] = "inputev",
    ["core.events.signal"    ] = "signal",
    ["core.events.world"     ] = "world",
    ["core.externals"        ] = "externals",
    ["core.gui.core"         ] = "gui",
    ["core.logger"           ] = "logger",
    ["core.lua.conv"         ] = "conv",
    ["core.lua.geom"         ] = "geom",
    ["core.lua.stream"       ] = "stream",
    ["core.network.msg"      ] = "msg"
}

local consoleenv
local gen_console_env = function()
    if consoleenv then return consoleenv end
    local env = {}
    for k, v in pairs(ploaded) do
        local cmap = consolemap[k]
        if cmap then env[cmap] = v end
    end
    -- extra fields
    env["echo"   ] = logger.echo
    env["log"    ] = logger.log
    env["INFO"   ] = logger.INFO
    env["DEBUG"  ] = logger.DEBUG
    env["WARNING"] = logger.WARNING
    env["ERROR"  ] = logger.ERROR
    setmetatable(env, setmetatable({ __index = _G, __newindex = _G },
        { __index = getmetatable(_G) }))
    consoleenv = env
    return env
end

local ext_set = require("core.externals").set

--[[! Function: console_lua_run
    An external called when you run Lua code in the console. The console
    has its own special environment featuring most of the core modules as
    globals (so that you don't have to type so much).

    Global mappings:
        - capi - capi
        - core.engine.camera - camera
        - core.engine.cubescript - cubescript
        - core.engine.stains - stains
        - core.engine.edit - edit
        - core.engine.input - input
        - core.engine.lights - lights
        - core.engine.model - model
        - core.engine.particles - particles
        - core.engine.sound - sound
        - core.entities.ents - ents
        - core.entities.svars - svars
        - core.events.actions - actions
        - core.events.frame - frame
        - core.events.input - inputev
        - core.events.signal - signal
        - core.events.world - world
        - core.externals - externals
        - core.gui.core - gui
        - core.logger - logger
        - core.lua.conv - conv
        - core.lua.geom - geom
        - core.lua.stream - stream
        - core.network.msg - msg

    Other global variables:
        - echo, log, INFO, DEBUG, WARNING, ERROR - logger.*
]]
ext_set("console_lua_run", function(str)
    local  ret, err = loadstring(str, "=console")
    if not ret then return err end
    ret, err = pcall(setfenv(ret, gen_console_env()))
    if not ret then return err end
    return nil
end)

ext_set("mapscript_run", function(fname)
    local fs, err = stream.open(fname)
    if not fs then error(err, 2) end
    local f, err = loadstring(fs:read("*a"), "@" .. fname)
    fs:close()
    if not f then error(err, 2) end
    setfenv(f, gen_mapscript_env())()
end)

ext_set("mapscript_verify", function(fn)
    local f, err = loadfile(fn)
    if not f then
        logger.log(logger.ERROR, "Compilation failed: " .. err)
        return false
    end
    return true
end)

return M
