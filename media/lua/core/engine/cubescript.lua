--[[! File: lua/core/engine/cubescript.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua access to cubescript features, such as code execution and engine
        variables. You can connect signals in form "varname_changed" to
        the module.
]]

local capi = require("capi")

local M = {
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

--[[! Function: execute
    Runs a cubescript string. Returns the string return value (if possible).
]]
M.execute = capi.cubescript

--[[! Variable: var_type
    Defines cubescript/engine variable types. Contains "int", "float"
    and "string".
]]
M.var_type = {
    int = 0, float = 1, string = 2
}

--[[! Variable: var_flags
    Defines flags that can be passed during variable creation. Includes
    PERSIST (the variable will be saved in the configuration file), OVERRIDE
    (a mapvar, will be reset after the map ends) and READONLY.

    In a "safe" environment (run within a mapscript), PERSIST has no effect,
    OVERRIDE is implicit and HEX and READONLY will still work.
]]
M.var_flags = {
    PERSIST  = bit.lshift(1, 0),
    OVERRIDE = bit.lshift(1, 1),
    HEX      = bit.lshift(1, 2),
    READONLY = bit.lshift(1, 3)
}

--[[! Function: var_reset
    Resets an engine variable of the given name.
]]
M.var_reset = capi.var_reset

--[[! Function: var_new
    Creates an engine variable. Takes the name and the type, further arguments
    depend on the type. For integers and floats, they're minimum value,
    default value and maximum value and optional flags. For strings they're
    default value and optional flags.
]]
M.var_new = capi.var_new

--[[! Function: var_new_checked
    Same as above, but checks for the variable existence. If it exists, it
    returns false, otherwise returns true.
]]
M.var_new_checked = function(varn, ...)
    if not capi.var_exists(varn) then
        capi.var_new(varn, ...)
        return true
    end
    return false
end

--[[! Function: var_set
    Sets an engine variable value. Takes the variable name, further arguments
    depend on the type. For integers and floats, they're the new value and
    optionally two booleans, both defaulting to true - the first one
    specifies whether to run a callback (if any) and the second one
    specifies whether to clamp the value. For strings, it takes the
    value and the callback boolean.
]]
M.var_set = capi.var_set

--[[! Function: var_get
    Given a variable name, this returns its value (or nothing if it doesn't
    exist).
]]
M.var_get = capi.var_get

--[[! Function: var_get_min
    See above, returns the minimum value.
]]
M.var_get_min = capi.var_get_min

--[[! Function: var_get_max
    See above, returns the maximum value.
]]
M.var_get_max = capi.var_get_max

--[[! Function: var_get_def
    See above, returns the default value.
]]
M.var_get_def = capi.var_get_def

--[[! Function: var_get_type
    Given a variable name, this returns its type.
]]
M.var_get_type = capi.var_get_type

--[[! Function: var_is_hex
    Checks if the engine variable of the given name is hex.
]]
M.var_is_hex = capi.var_is_hex

--[[! Function: var_exists
    Checks for existence of an engine variable.
]]
M.var_exists = capi.var_exists

capi.external_set("var_get_table", function()
    return M
end)

return M
