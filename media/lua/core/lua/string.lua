--[[! File: lua/core/lua/string.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua string module extensions. Functions are inserted directly
        into the string module.
]]

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
    delim = delim or ","
    local r = {}
    for ch in str:gmatch("([^" .. delim .. "]+)") do
        r[#r + 1] = ch
    end
    return r
end

--[[! Function: string.del
    Deletes a substring in a string. The start argument specifies which
    first index to delete, count specifies the amount of characters to
    delete afterwards (the first one inclusive).
]]
string.del = function(str, start, count)
    return table.concat { str:sub(1, start - 1), str:sub(start + count) }
end

--[[! Function: string.insert
    Inserts a string "new" into a string so that it starts on index "idx".
    The rest of the string is placed after it. Returns the modified string.
]]
string.insert = function(str, idx, new)
    return table.concat { str:sub(1, idx - 1), new, str:sub(idx) }
end

local str_escapes = setmetatable({
    ["\n"] = "\\n", ["\r"] = "\\r",
    ["\a"] = "\\a", ["\b"] = "\\b",
    ["\f"] = "\\f", ["\t"] = "\\t",
    ["\v"] = "\\v", ["\\"] = "\\\\",
    ['"' ] = '\\"', ["'" ] = "\\'"
}, {
    __index = function(self, c) return ("\\%03d"):format(c:byte()) end
})

--[[! Function: string.escape
    Escapes a string. Works similarly to the Lua %q format but it tries
    to be more compact (e.g. uses \r instead of \13), doesn't insert newlines
    in the result (\n instead) and automatically decides if to delimit the
    result with ' or " depending on the number of nested ' and " (uses the
    one that needs less escaping).
]]
string.escape = function(s)
    -- a space optimization: decide which string quote to
    -- use as a delimiter (the one that needs less escaping)
    local nsq, ndq = 0, 0
    for c in s:gmatch("'") do nsq = nsq + 1 end
    for c in s:gmatch('"') do ndq = ndq + 1 end
    local sd = (ndq > nsq) and "'" or '"'
    return sd .. s:gsub("[\\"..sd.."%z\001-\031]", str_escapes) .. sd
end

--[[! Variable: string.dump
    This function is disabled in OctaForge.
]]
string.dump = nil
