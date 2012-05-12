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
    return (str:gsub(
        '%%%(([a-zA-Z_0-9]*)%)([-0-9%.]*[cdeEfgGiouxXsq])', function(k, fmt)
            k = tonumber(k) or k
            return (args[k]
                and ("%" .. fmt):format(args[k])
                or "%(" .. k .. ")" .. fmt) end)) end

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
    tostring(str):gsub(("([^%s]+)"):format(delim),
        function(t) r[#r + 1] = t end)
    return r end

--[[! Function: string.del
    Deletes a substring in a string. The start argument specifies which
    first index to delete, count specifies the amount of characters to
    delete afterwards (the first one inclusive).
]]
string.del = function(str, start, count)
    return table.concat { str:sub(1, start - 1), str:sub(start + count) } end

--[[! Function: string.insert
    Inserts a string "new" into a string so that it starts on index "idx".
    The rest of the string is placed after it. Returns the modified string.
]]
string.insert = function(str, idx, new)
    return table.concat { str:sub(1, idx - 1), new, str:sub(idx) } end

--[[! Function: string.eval_embedded
    Evaluates embedded Lua code in a string. The code has to return a string
    value that is used in place of the embedded code. Embedded code can
    contain more embedded code, as the evaluation is recursive. Useful
    for various sorts of templating. The optional second argument specifies
    a prefix before the (embedded code), defaulting to "@". The third argument
    allows you to optionally set the environment of execution. The fourth
    argument allows you to set "alternative environment", from which
    things will be indexed if they're not in the primary environment
    (useful for i.e. global variables).

    (start code)
        assert((\[\[hello @(return "farkin @(return 'world')")\]\]
            ):eval_embedded() == "hello farkin world")
    (end)

    Note that for simple expressions you don't need the "return" keyword:

    (start code)
        assert(("@(5 * 5 + 1)"):eval_embedded() == "26")
    (end)

    Non-string returns will be automatically stringified if possible.
]]
string.eval_embedded = function(str, prefix, env, envalt)
    prefix = prefix or "@"
    local ret = str:gsub(prefix .. "%b()", function(s)
        s = s:sub(3, #s - 1)
        s = s:find("return ") and s or "return " .. s
        env = envalt and setmetatable(env, { __index = envalt }) or env
        local r = (env
            and setfenv(loadstring(s), env)
            or  loadstring(s))()
        return r and tostring(r):eval_embedded(prefix, env, envalt) or "" end)
    return ret end

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
        assert(string.template(
            "bar : <$0 return <$1=foo$1> $0>") == "bar : blah")
    (end)
]]
string.template = function(str, level, env)
    level = level or 0
    str   = str:gsub("<$" .. level .. "(.-)$" .. level .. ">", "<?lua %1 ?>")

    env = env or _G
    if not env._VERSION then
        env = std.table.merge(env, std.table.copy(_G))
        setmetatable(env, getmetatable(_G)) end

    -- r - table to concatenate as retval; sp - start position
    local r = {}; local sp = 1
    -- it iterates if new matches are found. After last match, loop ends
    while true do
        -- ip - where the match begins, fp - where the match ends (numbers)
        -- dm - not used, ex - "=" or "", in case of "=", match is expression
        -- cd - the code / expression to run
        local ip, fp, dm, ex, cd = str:find("<%?(%w*)[ \t]*(=?)(.-)%?>", sp)
        -- no match? stop the loop
        if not ip then break end

        -- insert everything from start position to
        -- match beginning into return table
        table.insert(r, str:sub(sp, ip - 1))
        -- expression? insert a return value of "return EXPRESSION"
        -- command? insert a return value of the code.
        if ex == "=" then
            local ret = tostring(setfenv(loadstring("return " .. cd), env)())
            if ret ~= "nil" then table.insert(r, ret) end
        else
            -- make sure there is no more embedded code by looping it.
            local p  = cd:template(level + 1, env)
            while p ~= cd do
                  cd = p
                  p  = p:template(level + 1, env) end

            -- done, insert.
            local rs = setfenv(loadstring(cd), env)()
            if rs then table.insert(r, tostring(rs)) end end
        -- set start position for next iteration as position
        -- of first character after last match.
        sp = fp + 1 end

    -- make sure everything after last match is inserted too
    table.insert(r, string.sub(str, sp, -1))
    -- return concatenated output
    return table.concat(r) end
