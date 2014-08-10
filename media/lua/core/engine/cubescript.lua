--[[!<
    Lua access to cubescript features, such as code execution and engine
    variables. You can connect signals in form "varname,changed" to
    the module.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")
local signal = require("core.events.signal")

local emit = signal.emit

--! Module: cubescript
local M = {
    __connect = function(self, name)
        local  vn = name:match("(.+),changed$")
        if not vn then return end
        capi.var_make_emit(vn, true)
    end,

    __disconnect = function(self, name, id, scount)
        if scount == 0 then
            local  vn = name:match("(.+),changed$")
            if not vn then return end
            capi.var_make_emit(vn, false)
        end
    end
}

--[[!
    Runs a cubescript string. Returns the string return value (if possible).
]]
M.execute = capi.cubescript

--[[!
    Defines cubescript/engine variable types. Contains "int", "float"
    and "string".
]]
M.var_type = {:
    int = 0, float = 1, string = 2
:}

--[[!
    Defines flags that can be passed during variable creation. Includes
    PERSIST (the variable will be saved in the configuration file), OVERRIDE
    (a mapvar, will be reset after the map ends) and READONLY.

    In a "safe" environment (run within a mapscript), PERSIST has no effect,
    OVERRIDE is implicit and HEX and READONLY will still work.
]]
M.var_flags = {:
    PERSIST  = 1 << 0,
    OVERRIDE = 1 << 1,
    HEX      = 1 << 2,
    READONLY = 1 << 3
:}

--[[!
    Resets an engine variable of the given name.
]]
M.var_reset = capi.var_reset

--[[!
    Creates an engine variable using the given arguments. The number of
    arguments may differ depending on variable type.

    Arguments:
        - name - the new variable's name.
        - type - the new variable's type (see $var_type).
        - min, def, max - minimum, default and maximum value of the variable,
          for string variables only default is present.
        - flags - see $var_flags.

    See also:
        - $var_new_checked
]]
M.var_new = capi.var_new

--[[!
    Same as above, but checks for the variable existence. If it exists, it
    returns false, otherwise returns true.

    See also:
        - $var_new
]]
M.var_new_checked = function(varn, ...)
    if not capi.var_exists(varn) then
        capi.var_new(varn, ...)
        return true
    end
    return false
end

--[[!
    Sets an engine variable value.

    Arguments:
        - name - the variable's name.
        - val - the new value.
        - cb - a boolean specifying whether to run a callback on this change
          (true by default), such as any connected signal or builtin callback.
        - clamp - optional and present only for integer and float variables,
          defaults to true and specifies whether to clamp the value within
          the variable's bounds.
]]
M.var_set = capi.var_set

--[[!
    Given a variable name, this returns its value (or nothing if it doesn't
    exist).

    See also:
        - $var_get_min
        - $var_get_max
        - $var_get_def
]]
M.var_get = capi.var_get

--[[!
    See above, returns the minimum value.

    See also:
        - $var_get
        - $var_get_max
        - $var_get_def
]]
M.var_get_min = capi.var_get_min

--[[!
    See above, returns the maximum value.

    See also:
        - $var_get
        - $var_get_min
        - $var_get_def
]]
M.var_get_max = capi.var_get_max

--[[!
    See above, returns the default value.

    See also:
        - $var_get
        - $var_get_min
        - $var_get_max
]]
M.var_get_def = capi.var_get_def

--! Given a variable name, this returns its type.
M.var_get_type = capi.var_get_type

--! Checks if the engine variable of the given name is hex.
M.var_is_hex = capi.var_is_hex

--! Checks for existence of an engine variable.
M.var_exists = capi.var_exists

require("core.externals").set("var_emit_changed", function(name, ...)
    emit(M, name .. ",changed", ...)
end)

return M
