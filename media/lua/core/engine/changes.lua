--[[!<
    Lua interface to changes queue.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local table2 = require("core.lua.table")
local cs = require("core.engine.cubescript")
local signal = require("core.events.signal")

local set_external = require("core.externals").set

local needsapply = {}

local M = {}

--[[!
    Specifies the change type, can be GFX, SOUND or SHADERS.
]]
M.change = {:
    GFX     = 1 << 0,
    SOUND   = 1 << 1,
    SHADERS = 1 << 2
:}
local change = M.change

set_external("change_add", function(desc, ctype)
    signal.emit(M, "add", ctype, desc)
end)

--[[!
    Adds a change of the given type and description to the queue assuming
    a change of the same description doesn't already exist.
]]
M.add = function(ctype, desc)
    for i, v in pairs(needsapply) do
        if v.desc == desc then return end
    end
    needsapply[#needsapply + 1] = {
        ctype = ctype, desc = desc
    }
end

--[[!
    Clears out changes of the given type. If not given, clears out all.
]]
M.clear = function(ctype)
    ctype = ctype or (change.GFX | change.SOUND | change.SHADERS)

    needsapply = table2.filter(needsapply, function(i, v)
        if (v.ctype & ctype) == 0 then
            return true
        end

        v.ctype = (v.ctype & ~ctype)
        if v.ctype == 0 then
            return false
        end

        return true
    end)
end
set_external("changes_clear", M.clear)

--[[!
    Applies all queued changes.
]]
M.apply = function()
    local changetypes = 0
    for i, v in pairs(needsapply) do
        changetypes |= v.ctype
    end

    if (changetypes & change.GFX) != 0 then
        cs.execute("resetgl")
    elseif (changetypes & change.SHADERS) != 0 then
        cs.execute("resetshaders")
    end
    if (changetypes & change.SOUND) != 0 then
        cs.execute("resetsound")
    end
end

--[[!
    Returns a table of all queued changes' descriptions.
]]
M.get = function()
    return table2.map(needsapply, function(v) return v.desc end)
end

return M
