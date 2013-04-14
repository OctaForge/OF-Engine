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

local get_pretty = function(name)
    local val = get   (name)
    if CAPI.var_is_hex(name) then
        return ("0x%X (%d, %d, %d)"):format(val, hextorgb(val))
    end
    return tostring(val)
end

EV = setmetatable({
    __connect = function(self, name)
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        CAPI.var_emits(vn, true)
    end,

    __disconnect = function(self, name, id, len)
        if id and len ~= 0 then return nil end
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        CAPI.var_emits(vn, false)
    end
}, {
    __index = function(self, name)
        return CAPI.var_get(name)
    end,

    __newindex = function(self, name, value)
        CAPI.var_set(name, value)
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

    reset        = CAPI.var_reset,
    new          = CAPI.var_new,
    set          = CAPI.var_set,
    get          = CAPI.var_get,
    get_min      = CAPI.var_get_min,
    get_max      = CAPI.var_get_max,
    get_def      = CAPI.var_get_def,
    get_type     = CAPI.var_get_type,
    get_pretty   = get_pretty,
    is_hex       = CAPI.var_is_hex,
    exists       = CAPI.var_exists,
    emits        = CAPI.var_emits
}
