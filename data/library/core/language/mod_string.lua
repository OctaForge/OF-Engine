--[[!
    File: library/core/language/mod_string.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features various extensions made to Lua's string module.
]]

--[[!
    Package: string
    Provides various extensions to default string module,
    including splitting, template parsing and extended parameters. 
]]
module("string", package.seeall)

--[[!
    Function: _str_interp
    String interpolation function taken and modified from here
    <http://lua-users.org/wiki/StringInterpolation>.
    Unlike the way in the link, we also handle unnamed arguments,
    _ and numbers.

    It is activated using

    (start code)
        getmetatable("").__mod = _str_interp
    (end)

    Parameters:
        s - The input string.
        t - A table of arguments to substitute.

    Returns:
        Final string with all substitutions done.
]]
function _str_interp(s, t)
    return (
        string.gsub(
            s, '%%%(([a-zA-Z_0-9]*)%)([-0-9%.]*[cdeEfgGiouxXsq])',
            function(k, fmt)
                k = tonumber(k) or k
                return (t[k]
                    and
                        string.format("%" .. fmt, t[k])
                    or
                        "%(" .. k .. ")" .. fmt
                )
            end
        )
    )
end

--[[!
    Function: _str_index
    Allows getting character of string using [] operator.

    It is activated using

    (start code)
        getmetatable("").__index = _str_index
    (end)

    Parameters:
        s - The input string.
        i - Index of the character to get.

    Returns:
        The character
]]
function _str_index(s, n)
    local i = tonumber(n)
    return i and string.sub(s, i, i) or string[n]
end

getmetatable("").__mod   = _str_interp
getmetatable("").__index = _str_index

--[[!
    Function: split
    Splits a string into table of tokens, based on
    <http://lua-users.org/wiki/SplitJoin>. Usage -

    (start code)
        local a = "abc|def|ghi|jkl"
        local b = string.split(a, '|')
        assert(table.concat(b) == "abcdefghijkl")
    (end)

    Parameters:
        s - The string to split.
        d - A delimiter to use.

    Returns:
        A table of tokens.
]]
function split(s, d)
    d = d and tostring(d) or ","
    local r = {}
    string.gsub(tostring(s),
                string.format("([^%s]+)", d),
                function(t) r[#r + 1] = t end)
    return r
end

--[[!
    Function: template
    Parses a string template (string with embedded lua code),
    inspired by luadoc parser system. Usage -

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

    Parameters:
        s - The string to parse.
        l - Level to parse string from.
        Everything with higer or equal level gets parsed. Defaults to 0.
        e - optional associative table of items that should be visible
        to the embedded lua code as part of environment.

    Returns:
        Parsed string.
]]
function template(s, l, e)
    l = l or 0
    s = string.gsub(s, "<$" .. l .. "(.-)$" .. l .. ">", "<?lua %1 ?>")

    e = e or _G
    e = (not e._VERSION) and
        setmetatable(table.merge_dicts(e, table.copy(_G)), getmetatable(_G))
    or e

    -- r - table to concaterate as retval; sp - start position
    local r = {}; local sp = 1
    -- it iterates if new matches are found. After last match, loop ends
    while true do
        -- ip - where the match begins, fp - where the match ends (numbers)
        -- dm - not used, ex - "=" or "", in case of "=", match is expression
        -- cd - the code / expression to run
        local ip, fp, dm, ex, cd
            = string.find(s, "<%?(%w*)[ \t]*(=?)(.-)%?>", sp)
        -- no match? stop the loop
        if not ip then break end

        -- insert everything from start position to
        -- match beginning into return table
        table.insert(r, string.sub(s, sp, ip - 1))
        -- expression? insert a return value of "return EXPRESSION"
        -- command? insert a return value of the code.
        if ex == "=" then
            local ret = tostring(setfenv(loadstring("return " .. cd), e)())
            if ret ~= "nil" then table.insert(r, ret) end
        else
            -- make sure there is no more embedded code by looping it.
            local p = template(cd, l + 1, e)
            while p ~= cd do cd = p; p = template(p, l + 1) end

            -- done, insert.
            local rs = setfenv(loadstring(cd), e)()
            if rs then table.insert(r, tostring(rs)) end
        end
        -- set start position for next iteration as position
        -- of first character after last match.
        sp = fp + 1
    end

    -- make sure everything after last match is inserted too
    table.insert(r, string.sub(s, sp, -1))
    -- return concaterated output
    return table.concat(r)
end
