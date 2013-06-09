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
    preload    = {},
    loaded     = {},
    path       = "",
    searchpath = package.searchpath
}

local spath     = package.searchpath
local open      = io.open
local loadfile  = loadfile
local assert    = assert
local type      = type
local tconc     = table.concat
local pp_loader = pp_loader

env_package.loaders = {
    function(modname)
        local  v = env_package.preload[modname]
        if not v then
            return ("\tno field package.preload['%s']"):format(modname)
        end
        return v
    end,
    function(modname)
        local  v, err = spath(modname, env_package.path)
        if not v then return err end
        return pp_loader(v, modname)
    end
}

local find_loader = function(modname)
    local err = { ("module '%s' not found\n"):format(modname) }
    local loaders = env_package.loaders
    for i = 1, #loaders do
        local v  = loaders[i](modname)
        local vt = type(v)
        if vt == "function" then
            return v
        elseif vt == "string" then
            err[#err + 1] = v
        end
    end
    return nil, tconc(err)
end

local env_require = function(modname)
    local v = env_package.loaded[modname]
    if v ~= nil then return v end
    local  loader, err = find_loader(modname)
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

--[[! Function: gen_mapscript_env
    Generates an environment for the mapscript. It's isolated from the outside
    world to some degree, providing some safety against potentially malicious
    code. Externally available as "mapscript_gen_env"
]]
M.gen_mapscript_env = function()
    env_package.path = package.path
    -- safety? bah, we don't need no stinkin' safety
    return setmetatable({
        --require = env_require
    }, { __index = _G })
end
_C.external_set("mapscript_gen_env", M.gen_mapscript_env)

return M
