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

local reset = EAPI.var_reset

local new = function(name, vtype, min, def, max, ...)
    if vtype == EAPI.VAR_I then
        EAPI.var_new_i(name, min, def, max, ... and math.bor(...) or 0)
    elseif vtype == EAPI.VAR_F then
        EAPI.var_new_f(name, min, def, max, ... and math.bor(...) or 0)
    elseif vtype == EAPI.VAR_S then
        EAPI.var_new_s(name, min, def and math.bor(def, max, ...) or 0)
    end
end

local set = function(name, value)
    local t =  EAPI.var_get_type(name)
    if    t == -1 then
        return nil
    end

    EAPI["var_set_" .. (t == EAPI.VAR_I and
        "i" or (t == EAPI.VAR_F and "f" or "s"))](name, value)
end

local get = function(name)
    local t =  EAPI.var_get_type(name)
    if    t == -1 then
        return nil
    end

    return (t == EAPI.VAR_S) and ffi.string(EAPI.var_get_s(name)) or
        EAPI["var_get_" .. (t == EAPI.VAR_I and "i" or "f")](name)
end

local get_min = function(name)
    local t =  EAPI.var_get_type(name)
    if    t == -1 or t == EAPI.VAR_S then
        return nil
    end

    return EAPI["var_get_min_" .. (t == EAPI.VAR_I and
        "i" or "f")](name)
end

local get_max = function(name)
    local t =  EAPI.var_get_type(name)
    if    t == -1 or t == EAPI.VAR_S then
        return nil
    end

    return EAPI["var_get_min_" .. (t == EAPI.VAR_I and
        "i" or "f")](name)
end

local get_def = function(name)
    local t =  EAPI.var_get_type(name)
    if    t == -1 then
        return nil
    end

    return EAPI["var_get_min_" .. (t == EAPI.VAR_I and
        "i" or (t == EAPI.VAR_S and "s" or "f"))](name)
end

local get_pretty = function(name)
    local val = get   (name)
    if EAPI.var_is_hex(name) then
        return ("0x%X (%d, %d, %d)"):format(val, hextorgb(val))
    end
    return tostring(val)
end

local get_type     = EAPI.var_get_type
local exists       = EAPI.var_exists
local is_hex       = EAPI.var_is_hex

local persist_vars = function() print("hai") end

local emits = function(name, v)
    return (type(v) == "boolean") and
        EAPI.var_emits_set(name, v) or EAPI.var_emits(name)
end

EV = setmetatable({
    __connect = function(self, name)
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        EAPI.var_emits_set(vn, true)
    end,

    __disconnect = function(self, name, id, len)
        if id and len ~= 0 then return nil end
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        EAPI.var_emits_set(vn, false)
    end
}, {
    __index = function(self, name)
        local t =  EAPI.var_get_type(name)
        if    t == -1 then
            return nil
        end

        return (t == EAPI.VAR_S) and ffi.string(EAPI.var_get_s(name)) or
            EAPI["var_get_" .. (t == EAPI.VAR_I and "i" or "f")](name)
    end,

    __newindex = function(self, name, value)
        local t =  EAPI.var_get_type(name)
        if    t == -1 then
            return nil
        end

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
            c = tostring
        end

        f(name, c(value))
    end
})

return {
    PERSIST  = EAPI.VAR_PERSIST,
    OVERRIDE = EAPI.VAR_OVERRIDE,
    HEX      = EAPI.VAR_HEX,
    
    INT    = EAPI.VAR_I,
    FLOAT  = EAPI.VAR_F,
    STRING = EAPI.VAR_S,

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
