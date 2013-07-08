--[[! File: lua/core/lua/env.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Provides additional utilities for environment management.
]]

local M = {}

local env_package = {
    preload = {}
}

local spath     = package.searchpath
local open      = io.open
local loadfile  = loadfile
local assert    = assert
local type      = type
local setfenv   = setfenv
local tconc     = table.concat

env_package.loaders = {
    function(modname)
        local  v = env_package.preload[modname]
        if not v then
            return ("\tno field package.preload['%s']"):format(modname)
        end
        return v
    end,
    package.loaders[2],
    package.loaders[3]
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
        if v ~= nil then return v end
        local  loader, err = find_loader(modname, env)
        if not loader then
            error(err, 2)
        end
        local ret    = loader(modname)
        local loaded = env_package.loaded
        if ret ~= nil then
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
    ["assert"      ] = true,
    ["bit"         ] = true,
    ["coroutine"   ] = true,
    ["cubescript"  ] = true,
    ["error"       ] = true,
    ["getmetatable"] = true,
    ["ipairs"      ] = true,
    ["math"        ] = true,
    ["next"        ] = true,
    ["os"          ] = {
        ["clock"   ] = true,
        ["date"    ] = true,
        ["difftime"] = true,
        ["time"    ] = true
    },
    ["pairs"       ] = true,
    ["pcall"       ] = true,
    ["print"       ] = true,
    ["rawequal"    ] = true,
    ["rawget"      ] = true,
    ["rawlen"      ] = true,
    ["rawset"      ] = true,
    ["require"     ] = true,
    ["select"      ] = true,
    ["setmetatable"] = true,
    ["string"      ] = {
        ["byte"    ] = true,
        ["char"    ] = true,
        ["find"    ] = true,
        ["format"  ] = true,
        ["gmatch"  ] = true,
        ["gsub"    ] = true,
        ["len"     ] = true,
        ["lower"   ] = true,
        ["match"   ] = true,
        ["rep"     ] = true,
        ["reverse" ] = true,
        ["sub"     ] = true,
        ["upper"   ] = true
    },
    ["table"       ] = true,
    ["tonumber"    ] = true,
    ["tostring"    ] = true,
    ["type"        ] = true,
    ["unpack"      ] = true,
    ["xpcall"      ] = true
}

local getmetatable = getmetatable
local env_replacements = {
    ["getmetatable"] = function(tbl)
        return type(tbl) == "table" and getmetatable(tbl) or nil
    end
}

local ploaded = package.loaded

local eloaded = {
    ["bit"      ] = ploaded["bit"      ],
    ["coroutine"] = ploaded["coroutine"],
    ["math"     ] = ploaded["math"     ],
    ["table"    ] = ploaded["table"    ]
}
env_package.loaded = eloaded

local gen_envtable; gen_envtable = function(tbl, env, rp, mod)
    for k, v in pairs(tbl) do
        if v == true then
            env[k] = rp and rp[k] or (mod or _G)[k]
        elseif type(v) == "table" then
            env[k] = {}
            gen_envtable(v, env[k], rp and rp[k] or nil, (mod or _G)[k])
            eloaded[k] = env[k]
        end
    end
    if not mod then
        env["_G"] = env
        env["_C"] = _C
        env["SERVER"] = SERVER
        env["require"] = gen_require(env)
        env_package.loaded["_G"] = env
        for k, v in pairs(ploaded) do
            if k:match("core%..+") then
                eloaded[k] = v
            end
        end
    end
    return setmetatable(env, getmetatable(_G))
end

--[[! Function: gen_mapscript_env
    Generates an environment for the mapscript. It's isolated from the outside
    world to some degree, providing some safety against potentially malicious
    code. Externally available as "mapscript_gen_env".

    The new environment contains the following global functions: assert,
    cubescript, error, getmetatable (modified so that it can get only table
    metatables), ipairs, next, pairs, pcall, print, rawequal, rawget, rawlen,
    rawset, require (custom version without C module loading and with modified
    loaded table), select, setmetatable, tonumber, tostring, type, unpack,
    xpcall.

    The new environment contains the following default modules: bit, coroutine,
    math, table. It also contains a modified version of the string module that
    doesn't have string.dump and a stripped down version of the os module
    containing functions clock, date, difftime and time.

    The environment also contains the special variables SERVER and _C and
    it inherits the metatable of _G.

    All the core.* modules that are preloaded outside are preloaded inside
    as well.
]]
M.gen_mapscript_env = function()
    env_package.path = package.path
    return gen_envtable(env_structure, {}, env_replacements)
end
_C.external_set("mapscript_gen_env", M.gen_mapscript_env)

return M
