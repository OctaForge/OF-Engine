--[[! File: library/core/lua/table.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua table module extensions. Functions are inserted directly into
        the table module.
]]

local ctable = createtable
local pairs, ipairs = pairs, ipairs
local type, setmetatable = type, setmetatable
local rawget, rawset = rawget, rawset
local tostring = tostring
local tconc = table.concat
local pcall = pcall
local floor, log = math.floor, math.log

--[[! Function: table.is_array
    Checks whether a given table is an array (that is, contains only a
    consecutive sequence of values with indexes from 1 to #table). If
    there is any non-array element found, returns false. Otherwise
    returns true.
]]
table.is_array = function(t)
    local i = 0
    while t[i + 1] do i = i + 1 end
    for _ in pairs(t) do
        i = i - 1 if i < 0 then return false end
    end
    return i == 0
end

local is_array = table.is_array

--[[! Function: table.map
    Performs conversion on each item of the table. Takes the table and a
    function taking one argument (which is the item value) and returning
    some other value. The returned value will then replace the value
    passed to the function. There are no modifications done on the
    original table. Instead, remapped table is returned.

    (start code)
        -- table of numbers
        foo = { bar = 5, baz = 10 }
        -- table of strings
        bar = table.map(foo, function(v) return tostring(v) end)
    (end)
]]
table.map = function(t, f)
    local r = {}
    for i, v in pairs(t) do r[i] = f(v) end
    return r
end

--[[! Function: table.merge
    Merges two arrays. Contents of the other come after those of the first one.
]]
table.merge = function(ta, tb)
    local l1, l2 = #ta, #tb
    local r = ctable(l1 + l2)
    for i = 1, l1 do r[#r + 1] = ta[i] end
    for i = 1, l2 do r[#r + 1] = tb[i] end
    return r
end

--[[! Function: table.merge_maps
    Merges two associative arrays (maps). When a key overlaps, the latter
    value is preferred.
]]
table.merge_maps = function(ta, tb)
    local r = {}
    for a, b in pairs(ta) do r[a] = b end
    for a, b in pairs(tb) do r[a] = b end
    return r
end

--[[! Function: table.copy
    Returns a copy of the given table. Doesn't copy tables inside (only
    primitives are copied, no reference types).
]]
table.copy = function(t)
    local r = ctable(#t)
    for a, b in pairs(t) do r[a] = b end
    return r
end

--[[! Function: table.filter
    Filters an array. Takes the array and a function returning true if the
    passed value should be a part of the returned array and false if it
    shouldn't. The function takes two arguments, the index and the value.
    This doesn't perform anything on the original table.

    (start code)
        -- a table to filter
        foo = { 5, 10, 15, 20 }
        -- the filtered table, contains just 5, 10, 20
        bar = table.filter(foo, function(k, v)
            if v == 15 then
                return false
            else
                return true
            end
        end)
    (end)
]]
table.filter = function(t, f)
    local r = {}
    for i = 1, #t do if f(i, t[i]) then r[#r + 1] = t[i] end end
    return r
end

--[[! Function: table.filter_map
    The same as the filter function above. The difference is that it works
    on an associative array (map). That means it doesn't work with length,
    but instead with key/value pairs.

    (start code)
        -- a table to filter
        foo = { a = 5, b = 10, c = 15, d = 20 }
        -- the filtered table, contains just key/value pairs a, b, d
        bar = table.filter_map(foo, function(k, v)
            if k == "c" then
                return false
            else
                return true
            end
        end)
    (end)
]]
table.filter_map = function(t, f)
    local r = {}
    for a, b in pairs(t) do if f(a, b) then r[a] = b end end
    return r
end

--[[! Function: table.find
    Finds a key of a value in the given table. The first argument is the
    table, the second argument is the value. Returns the key, or nil if
    nothing is found.
]]
table.find = function(t, v)
    for a, b in pairs(t) do if v == b then return a end end
end

--[[! Function: table.keys
    Returns an array of table keys. See also <table.values>.
]]
table.keys = function(t)
    local r = ctable(#t)
    for a, b in pairs(t) do r[#r + 1] = a end
    return r
end

--[[! Function: table.keys
    Returns an array of table values. See also <table.keys>.
]]
table.values = function(t)
    local r = ctable(#t)
    for a, b in pairs(t) do r[#r + 1] = b end
    return r
end

--[[! Function: table.foldr
    Performs a right fold on a table (array). The first argument
    is the table, followed by the predicate and a default value.
    If the default value is not provided, it defaults to the
    first array element and folding is then performed from
    indexes 2 to len.

    (start code)
        local a = { 5, 10, 15, 20 }
        assert(table.foldr(a, function(a, b) return a + b end) == 50)
    (end)
]]
table.foldr = function(t, fun, z)
    local idx = 1
    if not z then
        z   = t[1]
        idx = 2
    end

    for i = idx, #t do
        z = fun(z, t[i])
    end
    return z
end

--[[! Function: table.foldl
    See above. Performs a left fold on a table.
]]
table.foldl = function(t, fun, z)
    local len = #t
    if not z then
        z   = t[len]
        len = len - 1
    end
    
    for i = len, 1, -1 do
        z = fun(z, t[i])
    end
    return z
end

local escape_string = string.escape

local function serialize_fn(v, stream, kwargs, simp, tables, indent)
    if simp then
        v = simp(v)
    end
    local tv = type(v)
    if tv == "string" then
        stream(escape_string(v))
    elseif tv == "number" or tv == "boolean" then
        stream(tostring(v))
    elseif tv == "table" then
        local mline   = kwargs.multiline
        local indstr  = kwargs.indent
        local asstr   = kwargs.assign or "="
        local sepstr  = kwargs.table_sep or ","
        local isepstr = kwargs.item_sep
        local endsep  = kwargs.end_sep
        local optk    = kwargs.optimize_keys
        local arr = is_array(v)
        local nline   = arr and kwargs.narr_line or kwargs.nrec_line or 0
        if tables[v] then
            stream() -- let the stream know about an error
            return false,
                "circular table reference detected during serialization"
        end
        tables[v] = true
        stream("{")
        if mline then stream("\n") end
        local first = true
        local n = 0
        local simp = kwargs.simplifier
        for k, v in (arr and ipairs or pairs)(v) do
            if first then first = false
            else
                stream(sepstr)
                if mline then
                    if n == 0 then
                        stream("\n")
                    elseif isepstr then
                        stream(isepstr)
                    end
                end
            end
            if mline and indstr and n == 0 then
                for i = 1, indent do stream(indstr) end
            end
            if arr then
                local ret, err = serialize_fn(v, stream, kwargs, simp, tables,
                    indent + 1)
                if not ret then return ret, err end
            else
                if optk and type(k) == "string"
                and k:match("^[%a_][%w_]*$") then
                    stream(k)
                else
                    stream("[")
                    local ret, err = serialize_fn(k, stream, kwargs, simp,
                        tables, indent + 1)
                    if not ret then return ret, err end
                    stream("]")
                end
                stream(asstr)
                local ret, err = serialize_fn(v, stream, kwargs, simp, tables,
                    indent + 1)
                if not ret then return ret, err end
            end
            n = (n + 1) % nline
        end
        if not first then
            if endsep then stream(sepstr) end
            if mline then stream("\n") end
        end
        if mline and indstr then
            for i = 2, indent do stream(indstr) end
        end
        stream("}")
    else
        stream()
        return false, ("invalid value type: " .. tv)
    end
    return true
end

local defkw = {
    multiline = false, indent = nil, assign = "=", table_sep = ",",
    end_sep = false, optimize_keys = true
}

local defkwp = {
    multiline = true, indent = "    ", assign = " = ", table_sep = ",",
    item_sep = " ", narr_line = 4, nrec_line = 2, end_sep = false,
    optimize_keys = true
}

--[[! Function: table.serialize
    Serializes a given table, returning a string containing a literal
    representation of the table. It tries to be compact by default so it
    avoids whitespace and newlines. Arrays and associative arrays are
    serialized differently (for compact output).

    Besides tables this can also serialize other Lua values. It serializes
    them in the same way as values inside a table, returning their literal
    representation (if serializable, otherwise just their tostring). The
    serializer allows strings, numbers, booleans and tables.

    Circular tables can't be serialized. The function normally returns either
    the string output or nil + an error message (which can signalize either
    circular references or invalid types).

    The function allows you to pass in a "kwargs" table as the second argument.
    It's a table of options. Those can be multiline (boolean, false by default,
    pretty much pretty-printing), indent (string, nil by default, specifies
    how an indent level looks), assign (string, "=" by default, specifies how
    an assignment between a key and a value looks), table_sep (table separator,
    by default ",", can also be ";" for tables, separates items in all cases),
    item_sep (item separator, string, nil by default, comes after table_sep
    but only if it isn't followed by a newline), narr_line (number, 0 by
    default, how many array elements to fit on a line), nrec_line (same,
    just for key-value pairs), end_sep (boolean, false by default, makes
    the serializer put table_sep after every item including the last one),
    optimize_keys (boolean, true by default, optimizes string keys like
    that it doesn't use string literals for keys that can be expressed
    as Lua names).

    If kwargs is nil or false, the values above are used. If kwargs is a
    boolean value true, pretty-printing defaults are used (multiline is
    true, indent is 4 spaces, assign is " = ", table_sep is ",", item_sep
    is one space, narr_line is 4, nrec_line is 2, end_sep is false,
    optimize_keys is true).

    A third argument, "stream" can be passed. As a table is serialized
    by pieces, "stream" is called each time a new piece is saved. It's
    useful for example for file I/O. When a custom stream is supplied,
    the function doesn't return a string, instead it returns true
    or false depending on whether it succeeded and the error message
    if any.

    And finally there is the fourth argument, "simplifier". It's a
    function that takes a value and "simplifies" it (returns another
    value it should be replaced by). By default nothing is simplified
    of course.

    This function is externally available as "table_serialize".
]]
local serialize = function(val, kwargs, stream, simplifier)
    if kwargs == true then
        kwargs = defkwp
    elseif not kwargs then
        kwargs = defkw
    else
        if  kwargs.optimize_keys == nil then
            kwargs.optimize_keys = true
        end
    end
    if stream then
        return serialize_fn(val, stream, kwargs, simplifier, {}, 1)
    else
        local t = {}
        local ret, err = serialize_fn(val, function(out)
            t[#t + 1] = out end, kwargs, simplifier, {}, 1)
        if not ret then
            return nil, err
        else
            return tconc(t)
        end
    end
end
table.serialize = serialize
set_external("table_serialize", serialize)

local lex_get = function(ls)
    while true do
        local c = ls.curr
        if not c then break end
        ls.tname, ls.tval = nil, nil
        if c == "\n" or c == "\r" then
            local prev = c
            c = ls.rdr()
            if (c == "\n" or c == "\r") and c ~= prev then
                c = ls.rdr()
            end
            ls.curr = c
            ls.linenum = ls.linenum + 1
        elseif c == " " or c == "\t" or c == "\f" or c == "\v" then
            ls.curr = ls.rdr()
        elseif c == "." or c:byte() >= 48 and c:byte() <= 57 then
            local buf = { ls.curr }
            ls.curr = ls.rdr()
            while ls.curr and ls.curr:match("[epxEPX0-9.+-]") do
                buf[#buf + 1] = ls.curr
                ls.curr = ls.rdr()
            end
            local str = tconc(buf)
            local num = tonumber(str)
            if not num then error(("%d: malformed number near '%s'")
                :format(ls.linenum, str), 0) end
            ls.tname, ls.tval = "<number>", num
            return "<number>"
        elseif c == '"' or c == "'" then
            local d = ls.curr
            ls.curr = ls.rdr()
            local buf = {}
            while ls.curr ~= d do
                local c = ls.curr
                if c == nil then
                    error(("%d: unfinished string near '<eos>'")
                        :format(ls.linenum), 0)
                elseif c == "\n" or c == "\r" then
                    error(("%d: unfinished string near '<string>'")
                        :format(ls.linenum), 0)
                -- not complete escape sequence handling: handles only these
                -- that are or can be in the serialized output
                elseif c == "\\" then
                    c = ls.rdr()
                    if c == "a" then
                        buf[#buf + 1] = "\a" ls.curr = ls.rdr()
                    elseif c == "b" then
                        buf[#buf + 1] = "\b" ls.curr = ls.rdr()
                    elseif c == "f" then
                        buf[#buf + 1] = "\f" ls.curr = ls.rdr()
                    elseif c == "n" then
                        buf[#buf + 1] = "\n" ls.curr = ls.rdr()
                    elseif c == "r" then
                        buf[#buf + 1] = "\r" ls.curr = ls.rdr()
                    elseif c == "t" then
                        buf[#buf + 1] = "\t" ls.curr = ls.rdr()
                    elseif c == "v" then
                        buf[#buf + 1] = "\v" ls.curr = ls.rdr()
                    elseif c == "\\" or c == '"' or c == "'" then
                        buf[#buf + 1] = c
                        ls.curr = ls.rdr()
                    elseif not c then
                        error(("%d: unfinished string near '<eos>'")
                            :format(ls.linenum), 0)
                    else
                        if not c:match("%d") then
                            error(("%d: invalid escape sequence")
                                :format(ls.linenum), 0)
                        end
                        local dbuf = { c }
                        c = ls.rdr()
                        if c:match("%d") then
                            dbuf[2] = c
                            c = ls.rdr()
                            if c:match("%d") then
                                dbuf[3] = c
                                c = ls.rdr()
                            end
                        end
                        ls.curr = c
                        buf[#buf + 1] = tconc(dbuf):char()
                    end
                else
                    buf[#buf + 1] = c
                    ls.curr = ls.rdr()
                end
            end
            ls.curr = ls.rdr() -- skip delim
            ls.tname, ls.tval = "<string>", tconc(buf)
            return "<string>"
        elseif c:match("[%a_]") then
            local buf = { c }
            ls.curr = ls.rdr()
            while ls.curr and ls.curr:match("[%w_]") do
                buf[#buf + 1] = ls.curr
                ls.curr = ls.rdr()
            end
            local str = tconc(buf)
            if str == "true" or str == "false" or str == "nil" then
                ls.tname, ls.tval = str, nil
                return str
            else
                ls.tname, ls.tval = "<name>", str
                return "<name>"
            end
        else
            ls.curr = ls.rdr()
            ls.tname, ls.tval = c, nil
            return c
        end
    end
end

local function assert_tok(ls, tok, ...)
    if not tok then return nil end
    if ls.tname ~= tok then
        error(("%d: unexpected symbol near '%s'"):format(ls.linenum,
            ls.tname), 0)
    end
    lex_get(ls)
    assert_tok(ls, ...)
end

local function parse(ls)
    local tok = ls.tname
    if tok == "<string>" or tok == "<number>" then
        local v = ls.tval
        lex_get(ls)
        return v
    elseif tok == "true"  then lex_get(ls) return true
    elseif tok == "false" then lex_get(ls) return false
    elseif tok == "nil"   then lex_get(ls) return nil
    else
        assert_tok(ls, "{")
        local tbl = {}
        repeat
            if ls.tname == "<name>" then
                local key = ls.tval
                lex_get(ls)
                assert_tok(ls, "=")
                tbl[key] = parse(ls)
            elseif ls.tname == "[" then
                lex_get(ls)
                local key = parse(ls)
                assert_tok(ls, "]", "=")
                tbl[key] = parse(ls)
            else
                tbl[#tbl + 1] = parse(ls)
            end
        until (ls.tname ~= "," and ls.tname ~= ";") or not lex_get(ls)
        assert_tok(ls, "}")
        return tbl
    end
end

--[[! Function: table.deserialize
    Takes a previously serialized table and converts it back to the original.
    Uses a simple tokenizer and a recursive descent parser to build the result,
    so it's safe (doesn't evaluate anything). The input can also be a callable
    value that return the next character each call.
    External as "table_deserialize". This returns the deserialized value on
    success and nil + the error message on failure.
]]
table.deserialize = function(s)
    local stream = (type(s) == "string") and s:gmatch(".") or s
    local ls = { curr = stream(), rdr = stream, linenum = 1 }
    local r, v = pcall(lex_get, ls)
    if not r then return nil, v end
    r, v = pcall(parse, ls)
    if not r then return nil, v end
    return v
end
set_external("table_deserialize", table.deserialize)

local sift_down = function(tbl, l, s, e, fun)
    local root = s
    while root * 2 - l + 1 <= e do
        local child = root * 2 - l + 1
        local swap  = root
        if fun(tbl[swap], tbl[child]) then
            swap = child
        end
        if child + 1 <= e and fun(tbl[swap], tbl[child + 1]) then
            swap = child + 1
        end
        if swap ~= root then
            tbl[root], tbl[swap] = tbl[swap], tbl[root]
            root = swap
        else
            return nil
        end
    end
end

local heapsort = function(tbl, l, r, fun)
    local start = floor((l + r) / 2)
    while start >= l do
        sift_down(tbl, l, start, r, fun)
        start = start - 1
    end
    local e = r
    while e > l do
        tbl[e], tbl[l] = tbl[l], tbl[e]
        e = e - 1
        sift_down(tbl, l, l, e, fun)
    end
end

local partition = function(tbl, l, r, pidx, fun)
    local pivot = tbl[pidx]
    tbl[pidx], tbl[r] = tbl[r], tbl[pidx]
    for i = l, r - 1 do
        if fun(tbl[i], pivot) then
            tbl[i], tbl[l] = tbl[l], tbl[i]
            l = l + 1
        end
    end
    tbl[l], tbl[r] = tbl[r], tbl[l]
    return l
end

local insertion_sort = function(tbl, l, r, fun)
    for i = l, r do
        local j, v = i, tbl[i]
        while j > 1 and not fun(tbl[j - 1], v) do
            tbl[j] = tbl[j - 1]
            j = j - 1
        end
        tbl[j] = v
    end
end

local function introloop(tbl, l, r, depth, fun)
    if (r - l) > 10 then
        if depth == 0 then
            return heapsort(tbl, l, r, fun)
        end
        local pidx = partition(tbl, l, r, floor((l + r) / 2), fun)
        introloop(tbl, l, pidx - 1, depth - 1, fun)
        introloop(tbl, pidx + 1, r, depth - 1, fun)
    else insertion_sort(tbl, l, r, fun) end
end

local introsort = function(tbl, l, r, fun)
    return introloop(tbl, l, r, 2 * floor(log(r - l + 1) / log(2)), fun)
end

local defaultcmp = function(a, b) return a < b end

--[[! Function: table.sort
    Replaces the original table.sort. Normally it behaves exactly like
    table.sort (takes a table, optionally a comparison function and
    sorts the table in-place), but it also takes two other arguments
    specifying from where to where to sort the table (the starting
    and ending indexes, both are inclusive). Under LuaJIT it's also
    considerably faster than vanilla table.sort (about 3x).

    The sorting algorithm used here is introsort. It's a modification
    of quicksort that switches to heapsort when the recursion depth
    exceeds 2 * floor(log(nitems) / log(2)). It also uses insertion
    sort to sort small sublists (10 elements and smaller). The
    quicksort part uses a median of three pivot.
]]
table.sort = function(tbl, fun, l, r)
    l, r = l or 1, r or #tbl
    return introsort(tbl, l, r, fun or defaultcmp)
end

------------------
-- Object system -
------------------

-- operator overloading
local Meta = {
    -- mathematic operators
    "__unm",
    "__add",
    "__sub",
    "__mul",
    "__div",
    "__pow",
    "__concat",
    "__eq",
    "__lt",
    "__le",

    -- other metamethods
    "__tostring",
    "__gc",
    "__mode",
    "__metatable",
    "__len"
}

table.Object = {
    __call = function(self, ...)
        local r = {
            __index = self, __proto = self, __call = self.__call,
            __tostring = self.__inst_tostring or self.__tostring
        }
        setmetatable(r, r)
        if self.__init then self.__init(r, ...)end

        -- if we don't allow metamethod inheritance, don't bother copying
        -- improves performance where appropriate
        if self.__inherit_meta then
            for i = 1, #Meta do
                local k, v = Meta[i], self[k]
                if v then r[k] = v end
            end
        end

        return r
    end,

    clone = function(self, tbl)
        tbl = tbl or {}
        tbl.__index, tbl.__proto, tbl.__call = self, self, self.__call
        if not tbl.__tostring then tbl.__tostring = self.__tostring end

        -- see above
        if self.__inherit_meta then
            for i = 1, #Meta do
                local k, v = Meta[i], self[k]
                if v then tbl[k] = v end
            end
        end

        setmetatable(tbl, tbl)
        return tbl
    end,

    is_a = function(self, base)
        if self == base then return true end
        local pt = self.__proto
        local is = (pt == base)
        while not is and pt do
            pt = pt.__proto
            is = (pt == base)
        end
        return is
    end,

    __tostring = function(self)
        return ("Object: %s"):format(self.name or "unnamed")
    end
}
