--[[! File: library/core/std/lua/string.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua string module extensions. Functions are inserted directly
        into the string module.
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
        local ts = s:gsub(prefix .. "%b()", ""):gsub("%b\"\"", ""
            ):gsub("%[=*%[.*%]=*%]", "")
        s = ts:find("return ") and s or "return " .. s
        env = envalt and setmetatable(env, { __index = envalt }) or env
        local r = (env
            and setfenv(loadstring(s), env)
            or  loadstring(s))()
        return r and tostring(r):eval_embedded(prefix, env, envalt) or "" end)
    return ret end

--[[! Function: string.repp
    Returns a string that is the concatenation of iend-istart (or istart-iend)
    copies of the string str. Unlike string.rep, each copy of the string will
    be searched for a given pattern which will be then replaced with the
    current index. The indexes range from istart to iend. If iend is
    smaller than istart, it'll iterate backwards. The copies will
    be concatenated using a delimiter specified as the last argument.
    If not given, a space will be used.

    (start code)
        assert(("$i"):repp("$i", 5, 8) == "5 6 7 8")
    (end)
]]
string.repp = function(str, pattern, istart, iend, delim)
    delim = delim or " "
    local ret = {}
    local bkw  = iend < istart and true or false
    for i = istart, iend, bkw and -1 or 1 do
        local s = str:gsub(pattern, tostring(i))
        table.insert(ret, s) end
    return table.concat(ret, delim) end

--[[! Function: string.reppn
    See above. The difference is that the second number doesn't set the last
    index, but instead it sets the total amount of iterations (the first
    numbers remains the same as above).
]]
string.reppn = function(str, pattern, is, n, delim)
    delim = delim or " "
    local ret = {}
    for i = is, is + n - 1 do
        local s = str:gsub(pattern, tostring(i))
        table.insert(ret, s) end
    return table.concat(ret, delim) end
