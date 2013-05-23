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
local type, loadstring, setmetatable = type, loadstring, setmetatable
local setfenv, assert, rawget, rawset = setfenv, assert, rawget, rawset
local tostring = tostring

--[[! Function: table.is_array
    Checks whether a given table is an array (that is, contains only a
    consecutive sequence of values with indexes from 1 to #table). If
    there is any non-array element found, returns false. Otherwise
    returns true (and in both cases returns the amount of array
    elements as a second return value).
]]
table.is_array = function(tbl)
    local i = #tbl
    for _ in pairs(tbl) do
        i = i - 1
        if i < 0 then
            return false, #tbl
        end
    end
    return i == 0, #tbl
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

--[[! Function: table.serialize
    Serializes a given table, returning a string containing a literal
    representation of the table. By default it tries to be compact so
    it avoids whitespace and newlines. Arrays vs associative arrays
    are distinguished.

    Besides tables this can also serialize other Lua values. It serializes
    them in the same way as values inside a table, returning their literal
    representation (if serializable, otherwise just their tostring).

    The second argument is optional. It's a table containing additional
    parameters for the serialization.

    If the table contains member "pretty" with boolean value "true", the
    serializer attempts to format it for readability. While the "ugly" one
    is good for things like network transfers, the latter represents a human
    readable format.

    If pretty-printing, you can specify also "indent", an integral value
    specifying indentation. Defaults to 4 spaces.

    In the pretty formatting mode arrays are put on a single line with a space
    after commas and before/after beginning/ending brace. One exception happens
    when the array only contains one another table, then no spaces are used.
    Associative arrays put each element on a separate line appropriately
    indented, the beginning/ending braces are both on their own line.

    In associative arrays, only numbers and strings are allowed as keys.
    The serializer is also smart enough to detect recursion (both simple
    and mutual to any level) and avoid stack overflows.

    The table can contain one other thing, "simplifier". It's a function
    that takes a key/index and a value and returns true if it should be
    simplified and false if it shouldn't. If it should be simplified,
    it also has to return a second value specifying what it should
    simplify to. If it does not, it means the value should be
    omitted from the serialized table.

    There is one case where the serializer simplifies by default, objects
    having a numerical member "uid". Those are treated as entities and they
    serialize directly to the uid.

    Values that cannot be serialized are passed through tostring.

    This function is externally available as "table_serialize".
]]
table.serialize = function(tbl, kwargs)
    local pretty, indent, simplifier
    if kwargs then
        pretty     = kwargs.pretty or false
        indent     = kwargs.indent or 4
        simplifier = kwargs.simplifier
    else
        pretty = false
        indent = 4
    end

    local enc
    enc = function(tbl, tables, ind)
        local assoc, narr = is_array(tbl)
        local ret         = ctable(narr)
        tables = tables  or {}

        -- we want to know whether it's an associative array,
        -- not a regular array
        assoc = not assoc

        for k, v in (assoc and pairs or ipairs)(tbl) do
            local skip = false

            local tk = type(k)

            -- do not even attempt, useless and will fuck up
            if tk == "string" and k:sub(1, 2) == "__" then
                skip = true
            end

            if simplifier and not skip then
                local simplify, value = simplifier(k, v)
                if simplify then
                    if value == nil then
                        skip = true
                    else
                        v = value
                    end
                end
            end

            if not skip then
                local elem

                local t = type(v)

                -- simplify entities to their uids
                if t == "table" and type(v.uid) == "number" then
                    v = v.uid
                    t = "number"
                end

                if assoc then
                    assert(tk == "string" or tk == "number", 
                        "only string and number keys allowed for serialization"
                    )

                    if tk == "string" then
                        if not loadstring(k .. "=nil") then
                            elem = { "[\"", k, "\"]",
                                pretty and " = " or "=", true }
                        else
                            elem = { k, pretty and " = " or "=", true }
                        end
                    else
                        elem = { "[", tostring(k), "]",
                            pretty and " = " or "=", true }
                    end
                else
                    elem = { true }
                end

                if t == "table" then
                    -- the table references itself, infinite recursion
                    -- do not permit such behavior
                    if v == tbl or tables[v] then
                        elem[#elem] = "\"" .. tostring(v) .. "\""
                    else
                        tables[v] = true
                        elem[#elem] =
                            enc(v, tables, assoc and ind + indent or ind)
                    end
                elseif t == "number" or t == "boolean" then
                    elem[#elem] = tostring(v)
                else
                    elem[#elem] = "\"" .. tostring(v) .. "\""
                end

                if assoc and pretty then
                    ret[#ret + 1] = "\n" .. (" "):rep(ind)
                        .. table.concat(elem)
                else
                    ret[#ret + 1] = table.concat(elem)
                end
            end
        end

        if pretty then
            if assoc then
                ret[#ret + 1] = "\n" .. (" "):rep(ind - indent)
                return "{" .. table.concat(ret, ",") .. "}"
            -- special case - an array containing one table, don't add spaces
            elseif #tbl == 1 and type(tbl[1] == "table") then
                return "{" .. table.concat(ret, ", ") .. "}"
            end

            return "{ " .. table.concat(ret, ", ") .. " }"
        end

        return "{" .. table.concat(ret, ",") .. "}"
    end

    local t = type(tbl)

    if t ~= "table" then
        if t == "number" then
            return tostring(tbl)
        else
            return "\"" .. tostring(tbl) .. "\""
        end
    end

    return enc(tbl, nil, indent)
end
set_external("table_serialize", table.serialize)

--[[! Function: table.deserialize
    Takes a previously serialized table and converts it back to the original.
    This actually evaluates Lua code, but prevents anything malicious by
    working in an empty environment. Returns the table (unless an error
    happens). Different given literal values will work as well (for
    example, deserializing a string "\"foo\"" will result in value
    "foo"). External as "table_deserialize".
]]
table.deserialize = function(str)
    assert(type(str) == "string", "the input value must be a string")

    -- loadstring with empty environment - prevent malicious code
    local  status, ret = pcall(setfenv(loadstring("return " .. str), {}))
    assert(status, ret)

    return ret
end
set_external("table_deserialize", table.deserialize)

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

        -- getters
        if self.__get then
            local par = self
            r.__index = function (self, n)
                local v = par[n]
                if v == nil then return par.__get(self, n) end
                return v
            end
        end

        -- setters
        if self.__set then
            local par = self
            r.__newindex = function  (self, n, v)
                local  r = par.__set(self, n, v)
                if not r then rawset(self, n, v) end
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
