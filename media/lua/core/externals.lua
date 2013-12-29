--[[!<
    Provides the handling of externals. Not accessible from anywhere but the
    core library.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")

--! Module: externals
local M = {}

local externals = {}

--! Retrieves the external of the given name.
M.get = function(name)
    return externals[name]
end

--! Unsets the external of the given name, returns the previous value or nil.
M.unset = function(name)
    local old = externals[name]
    if old == nil then return nil end
    externals[name] = nil
    return old
end

--! Sets the external of the given name, returns the previous value or nil.
M.set = function(name, fun)
    local old = externals[name]
    externals[name] = fun
    return old
end

capi.external_hook(M.get)

return M
