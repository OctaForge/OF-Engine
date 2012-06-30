--[[! File: library/core/std/lua/util.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua util module. Further accessible as "util".
]]

return {
    --[[! Function: match
        Returns true if the value given by the first argument matches at least
        one of the values given afterwards. Available as global, too.
    ]]
    match = function(val, ...)
        for k, v in pairs({ ... }) do
            if val == v then
                return true end end
        return false end,

    --[[! Function: switch
        Implements switch, a type of conditional statement known from various
        languages, but unfortunately missing in Lua. See also <case> and
        <default>. Switch, case and default are globally available.

        (start code)
            switch(i,
                -- match one value
                case(5, function()
                    print("hello") end),
                -- match multiple values
                case({ 6, 8 }, function()
                    print("something") end),
                -- no match, must always be last
                default(function()
                    print("default") end))
        (end)
    ]]
    switch = function(expr, ...)
        local m = function(expr, t)
            if type(t) ~= "table" then
                return (expr == t)
            else for k, v in pairs(t) do
                if v == expr then return true end end end
            return false end

        for k, v in pairs({ ... }) do
            if not v[1] or m(expr, v[1]) then
                return v[2]() end end end,

    --[[! Function: case
        Helper function for <switch>.
    ]]
    case = function(val, fun)
        return { val, fun } end,

    --[[! Function: default
        Helper function for <switch>.
    ]]
    default = function(fun)
        return { nil, fun } end
}
