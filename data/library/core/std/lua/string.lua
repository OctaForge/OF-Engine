--[[! File: library/core/std/lua/string.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua string module extensions. Functions are inserted directly
        into the string module. You can also access the table module
        as "std.string".
]]

--[[! Function: string.__mod
    String interpolation function taken and modified from here
    <http://lua-users.org/wiki/StringInterpolation>.
    Unlike the way in the link, we also handle unnamed arguments,
    _ and numbers.

    It takes the input string and a table of arguments, returns the
    formatted string.
]]
getmetatable("").__mod = function(str, args)
    return (
        string.gsub(
            str, '%%%(([a-zA-Z_0-9]*)%)([-0-9%.]*[cdeEfgGiouxXsq])',
            function(k, fmt)
                k = tonumber(k) or k
                return (args[k]
                    and
                        string.format("%" .. fmt, args[k])
                    or
                        "%(" .. k .. ")" .. fmt
                )
            end
        )
    )
end

--[[! Function: string.__index
    Allows getting a character of a string using the [] operator.
    Takes the input string and an index, returns the character.
]]
getmetatable("").__index = function(str, idx)
    local  i = tonumber(idx)
    return i and string.sub(str, i, i) or string[idx]
end

--[[! Function: string.split
    Splits a string into a table of tokens, based on
    <http://lua-users.org/wiki/SplitJoin>. Takes a
    string and a delimiter.

    (start code)
        local a = "abc|def|ghi|jkl"
        local b = string.split(a, '|')
        assert(table.concat(b) == "abcdefghijkl")
    (end)
]]
string.split = function(str, delim)
    delim = delim and tostring(delim) or ","
    local r = {}
    string.gsub(
        tostring(str),
        string.format("([^%s]+)", delim),
        function(t) r[#r + 1] = t end
    )
    return r
end

--[[! Function: string.template
    Parses a string template (a string with embedded Lua code), inspired by
    luadoc parser system. Takes a string and a level to parse string from,
    defaulting to 0. Everything with higher or equal level gets parsed.
    The last optional argument is an associative table of items that
    should be visible to the embedded Lua code as part of the
    environment. Returns the parsed string.

    (start code)
        foo = "bar"
        bar = "blah"
        -- this returns "bar: blah"
        -- first, gets parsed to "bar : <$0 return bar $0>"
        -- then, it gets parsed to "bar : blah" (value of bar)
        assert(
            string.template("bar : <$0 return <$1=foo$1> $0>") == "bar : blah"
        )
    (end)
]]
string.template = function(str, level, env)
    level = level or 0
    str   = string.gsub(
        str, "<$" .. level .. "(.-)$" .. level .. ">", "<?lua %1 ?>"
    )

    env = env or _G
    env = (not env._VERSION) and
        setmetatable(
            std.table.merge_dicts(env, std.table.copy(_G)), getmetatable(_G)
        )
    or env

    -- r - table to concaterate as retval; sp - start position
    local r = {}; local sp = 1
    -- it iterates if new matches are found. After last match, loop ends
    while true do
        -- ip - where the match begins, fp - where the match ends (numbers)
        -- dm - not used, ex - "=" or "", in case of "=", match is expression
        -- cd - the code / expression to run
        local ip, fp, dm, ex, cd
            = string.find(str, "<%?(%w*)[ \t]*(=?)(.-)%?>", sp)
        -- no match? stop the loop
        if not ip then break end

        -- insert everything from start position to
        -- match beginning into return table
        std.table.insert(r, string.sub(str, sp, ip - 1))
        -- expression? insert a return value of "return EXPRESSION"
        -- command? insert a return value of the code.
        if ex == "=" then
            local ret = tostring(setfenv(loadstring("return " .. cd), env)())
            if ret ~= "nil" then std.table.insert(r, ret) end
        else
            -- make sure there is no more embedded code by looping it.
            local p  = string.template(cd, level + 1, env)
            while p ~= cd do
                  cd = p
                  p  = string.template(p, level + 1, env)
            end

            -- done, insert.
            local rs = setfenv(loadstring(cd), env)()
            if rs then std.table.insert(r, tostring(rs)) end
        end
        -- set start position for next iteration as position
        -- of first character after last match.
        sp = fp + 1
    end

    -- make sure everything after last match is inserted too
    std.table.insert(r, string.sub(str, sp, -1))
    -- return concaterated output
    return std.table.concat(r)
end
