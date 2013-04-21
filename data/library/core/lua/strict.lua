--[[! File: library/core/lua/strict.lua

    About: Author
        Mike Pall, adapted by q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Taken from LuaJIT. Checks use of undeclared global variables, all
        have to be declared in the main chunk using assignment (any value,
        nil will work) before being used or assigned inside a function.
]]

local getinfo, error, rawset, rawget = debug.getinfo, error, rawset, rawget

local  mt = getmetatable(_G)
if not mt then
    mt = {}
    setmetatable(_G, mt)
end

mt.__declared = {}

local what = function()
    local  d = getinfo(3,  "S")
    return d and d.what or "C"
end

local glob = false
rawset(_G, "global", function()
    glob = true
end)

mt.__newindex = function(self, name, value)
    if not mt.__declared[name] then
        local w = what()
        if not glob and (w ~= "main" and w ~= "C") then
            error("assign to undeclared variable '" .. name .. "'", 2)
        end
        glob = false
        mt.__declared[name] = true
    end
    rawset(self, name, value)
end

mt.__index = function(self, name)
    if not mt.__declared[name] and what() ~= "C" then
        error("variable '" .. name .. "' is not declared", 2)
    end
    return rawget(self, name)
end
