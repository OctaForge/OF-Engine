--[[! File: library/core/std/lua/var.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Provides high level engine variables handling, such as creation,
        access and setting. Further accessible as "var" and the engine
        variable table as EVAR (global).
]]

local reset = EAPI.var_reset

local new = function(name, vtype, value)
    if vtype == EAPI.VAR_I then
        EAPI.var_new_i(name, value)
    elseif vtype == EAPI.VAR_F then
        EAPI.var_new_f(name, value)
    elseif vtype == EAPI.VAR_S then
        EAPI.var_new_s(name, value)
    end end

local set = function(name, value)
    local t =  EAPI.var_get_type(name)
    if    t == EAPI.VAR_N then
        return nil end

    EAPI["var_set_" .. (t == EAPI.VAR_I and
        "i" or (t == EAPI.VAR_F and "f" or "s"))](name, value) end

local get = function(name)
    local t =  EAPI.var_get_type(name)
    if    t == EAPI.VAR_N then
        return nil end

    return (t == EAPI.VAR_S) and ffi.string(EAPI.var_get_s(name)) or
        EAPI["var_get_" .. (t == EAPI.VAR_I and "i" or "f")](name) end

local get_min = function(name)
    local t =  EAPI.var_get_type(name)
    if    t == EAPI.VAR_N or t == EAPI.VAR_S then
        return nil end

    return EAPI["var_get_min_" .. (t == EAPI.VAR_I and
        "i" or "f")](name) end

local get_max = function(name)
    local t =  EAPI.var_get_type(name)
    if    t == EAPI.VAR_N or t == EAPI.VAR_S then
        return nil end

    return EAPI["var_get_min_" .. (t == EAPI.VAR_I and
        "i" or "f")](name) end

local get_type     = EAPI.var_get_type
local exists       = EAPI.var_exists
local persist_vars = EAPI.var_persist_vars
local is_alias     = EAPI.var_is_alias

local changed = function(ch)
    return (type(ch) == "boolean") and
        EAPI.var_changed_set(ch) or EAPI.var_changed() end

EVAR = setmetatable({}, {
    __index = function(self, name)
        local t =  EAPI.var_get_type(name)
        if    t == EAPI.VAR_N then
            return nil end

        return (t == EAPI.VAR_S) and ffi.string(EAPI.var_get_s(name)) or
            EAPI["var_get_" .. (t == EAPI.VAR_I and "i" or "f")](name) end,

    __newindex = function(self, name, value)
        local t =  EAPI.var_get_type(name)
        if    t == EAPI.VAR_N then
            return nil end

        local f
        local c
        if t == EAPI.VAR_I then
            f = EAPI.var_set_i
            c = tonumber
        elseif t == EAPI.VAR_F then
            f = EAPI.var_set_f
            c = tonumber
        elseif t == EAPI.VAR_S then
            f = EAPI.var_set_s
            c = tostring end

        f(name, c(value)) end
})

return {
    reset        = reset,
    new          = new,
    set          = set,
    get          = get,
    get_min      = get_min,
    get_max      = get_max,
    get_type     = get_type,
    exists       = exists,
    persist_vars = persist_vars,
    is_alias     = is_alias,
    changed      = changed
}
