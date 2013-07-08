--[[! File: lua/core/engine/var.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Provides high level engine variables handling, such as creation,
        access and setting.
]]

local capi = require("capi")

local VAR_I = 0
local VAR_F = 1
local VAR_S = 2

local VAR_PERSIST  = bit.lshift(1, 0)
local VAR_OVERRIDE = bit.lshift(1, 1)
local VAR_HEX      = bit.lshift(1, 2)
local VAR_READONLY = bit.lshift(1, 3)

local M = {
    PERSIST  = VAR_PERSIST,
    OVERRIDE = VAR_OVERRIDE,
    HEX      = VAR_HEX,
    READONLY = VAR_READONLY,
    
    INT    = VAR_I,
    FLOAT  = VAR_F,
    STRING = VAR_S,

    reset        = capi.var_reset,
    new          = capi.var_new,
    set          = capi.var_set,
    get          = capi.var_get,
    get_min      = capi.var_get_min,
    get_max      = capi.var_get_max,
    get_def      = capi.var_get_def,
    get_type     = capi.var_get_type,
    is_hex       = capi.var_is_hex,
    exists       = capi.var_exists,
    emits        = capi.var_emits,

    new_checked = function(varn, ...)
        if not capi.var_exists(varn) then
            capi.var_new(varn, ...)
        end
    end,

    __connect = function(self, name)
        local  vn = name:match("(.+)_changed$")
        if not vn then return nil end
        capi.var_emits(vn, true)
    end,

    __disconnect = function(self, name, id, scount)
        if scount == 0 then
            local  vn = name:match("(.+)_changed$")
            if not vn then return nil end
            capi.var_emits(vn, false)
        end
    end
}

capi.external_set("var_get_table", function()
    return M
end)

return M
