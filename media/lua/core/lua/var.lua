--[[! File: lua/core/lua/var.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Provides high level engine variables handling, such as creation,
        access and setting. Further accessible as "var" and the engine
        variable table as _V (global).
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
    if _C.var_is_hex(name) then
        return ("0x%X (%d, %d, %d)"):format(val, hextorgb(val))
    end
    return tostring(val)
end

_V = setmetatable({
    __connect = function(self, name)
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        _C.var_emits(vn, true)
    end,

    __disconnect = function(self, name, id, scount)
        if scount == 0 then
            local  vn = name:match("(.+)_changed$")
            if not vn then return nil end
            _C.var_emits(vn, false)
        end
    end
}, {
    __index = function(self, name)
        return _C.var_get(name)
    end,

    __newindex = function(self, name, value)
        _C.var_set(name, value)
    end
})
set_external("vars_get", function() return _V end)

return {
    PERSIST  = VAR_PERSIST,
    OVERRIDE = VAR_OVERRIDE,
    HEX      = VAR_HEX,
    READONLY = VAR_READONLY,
    
    INT    = VAR_I,
    FLOAT  = VAR_F,
    STRING = VAR_S,

    reset        = _C.var_reset,
    new          = _C.var_new,
    set          = _C.var_set,
    get          = _C.var_get,
    get_min      = _C.var_get_min,
    get_max      = _C.var_get_max,
    get_def      = _C.var_get_def,
    get_type     = _C.var_get_type,
    get_pretty   = get_pretty,
    is_hex       = _C.var_is_hex,
    exists       = _C.var_exists,
    emits        = _C.var_emits
}
