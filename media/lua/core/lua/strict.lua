--[[! File: lua/core/lua/strict.lua

    About: Author
        Mike Pall, adapted by q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Disallows global variable manipulation (other than raw).
]]

local  mt = getmetatable(_G)
if not mt then
    mt = {}
    setmetatable(_G, mt)
end

mt.__newindex = function(self, name, value)
    error("attempt to create a global variable '" .. name .. "'")
end

mt.__index = function(self, name)
    error("undeclared variable '" .. name .. "'")
end
