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
        variable table as EV (global).
]]

local VAR_I = 0
local VAR_F = 1
local VAR_S = 2

local VAR_PERSIST  = math.lsh(1, 0)
local VAR_OVERRIDE = math.lsh(1, 1)
local VAR_HEX      = math.lsh(1, 2)
local VAR_READONLY = math.lsh(1, 3)

local reset = CAPI.var_reset

local new = function(name, vtype, min, def, max, ...)
    if vtype == VAR_I then
        CAPI.var_new_i(name, min, def, max, ... and math.bor(...) or 0)
    elseif vtype == VAR_F then
        CAPI.var_new_f(name, min, def, max, ... and math.bor(...) or 0)
    elseif vtype == VAR_S then
        CAPI.var_new_s(name, min, def and math.bor(def, max, ...) or 0)
    end
end

local set = function(name, value)
    local t =  CAPI.var_get_type(name)
    if    t == -1 then
        return nil
    end

    CAPI["var_set_" .. (t == VAR_I and
        "i" or (t == VAR_F and "f" or "s"))](name, value)
end

local get = function(name)
    local t =  CAPI.var_get_type(name)
    if    t == -1 then
        return nil
    end

    return (t == VAR_S) and CAPI.var_get_s(name) or
        CAPI["var_get_" .. (t == VAR_I and "i" or "f")](name)
end

local get_min = function(name)
    local t =  CAPI.var_get_type(name)
    if    t == -1 or t == VAR_S then
        return nil
    end

    return CAPI["var_get_min_" .. (t == VAR_I and
        "i" or "f")](name)
end

local get_max = function(name)
    local t =  CAPI.var_get_type(name)
    if    t == -1 or t == VAR_S then
        return nil
    end

    return CAPI["var_get_min_" .. (t == VAR_I and
        "i" or "f")](name)
end

local get_def = function(name)
    local t =  CAPI.var_get_type(name)
    if    t == -1 then
        return nil
    end

    return CAPI["var_get_min_" .. (t == VAR_I and
        "i" or (t == VAR_S and "s" or "f"))](name)
end

local get_pretty = function(name)
    local val = get   (name)
    if CAPI.var_is_hex(name) then
        return ("0x%X (%d, %d, %d)"):format(val, hextorgb(val))
    end
    return tostring(val)
end

local get_type     = CAPI.var_get_type
local exists       = CAPI.var_exists
local is_hex       = CAPI.var_is_hex

local persist_vars = function() print("hai") end

local emits = function(name, v)
    return (type(v) == "boolean") and
        CAPI.var_emits_set(name, v) or CAPI.var_emits(name)
end

EV = setmetatable({
    __connect = function(self, name)
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        CAPI.var_emits_set(vn, true)
    end,

    __disconnect = function(self, name, id, len)
        if id and len ~= 0 then return nil end
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        CAPI.var_emits_set(vn, false)
    end
}, {
    __index = function(self, name)
        local t =  CAPI.var_get_type(name)
        if    t == -1 then
            return nil
        end

        return (t == VAR_S) and CAPI.var_get_s(name) or
            CAPI["var_get_" .. (t == VAR_I and "i" or "f")](name)
    end,

    __newindex = function(self, name, value)
        local t =  CAPI.var_get_type(name)
        if    t == -1 then
            return nil
        end

        local f
        local c
        if t == VAR_I then
            f = CAPI.var_set_i
            c = tonumber
        elseif t == VAR_F then
            f = CAPI.var_set_f
            c = tonumber
        elseif t == VAR_S then
            f = CAPI.var_set_s
            c = tostring
        end

        f(name, c(value))
    end
})

return {
    PERSIST  = VAR_PERSIST,
    OVERRIDE = VAR_OVERRIDE,
    HEX      = VAR_HEX,
    READONLY = VAR_READONLY,
    
    INT    = VAR_I,
    FLOAT  = VAR_F,
    STRING = VAR_S,

    reset        = reset,
    new          = new,
    set          = set,
    get          = get,
    get_min      = get_min,
    get_max      = get_max,
    ged_def      = get_def,
    get_type     = get_type,
    get_pretty   = get_pretty,
    exists       = exists,
    persist_vars = persist_vars,
    emits        = emits
}
