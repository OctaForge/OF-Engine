--[[! File: library/core/std/lua/table.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua table module extensions. Functions are inserted directly into
        the table module.
]]

local ctable = createtable

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
    return true, #tbl
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
    for i = 1, l1 do table.insert(r, ta[i]) end
    for i = 1, l2 do table.insert(r, tb[i]) end
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
    Returns a copy of a given table.
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
    for i = 1, #t do if f(i, t[i]) then table.insert(r, t[i]) end end
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
    for a, b in pairs(t) do table.insert(r, a) end
    return r
end

--[[! Function: table.keys
    Returns an array of table values. See also <table.keys>.
]]
table.values = function(t)
    local r = ctable(#t)
    for a, b in pairs(t) do table.insert(r, b) end
    return r
end

--[[! Function: table.sum
    Returns a sum of array values. Works on numerical arrays.
]]
table.sum = function(t)
    local ret = 0
    for k, v in pairs(t) do ret = ret + tonumber(v) end
end

--[[! Function: table.clear
    Clears out all table elements.
]]
table.clear = function(t)
    for k, v in pairs(t) do t[k] = nil end
end

--[[! Function: table.slice
    Slices a table using given index (represents the first value in the
    table represented in the slice) and length (which specifies how many
    values the resulting table should contain). If the length is unspecified,
    it slices from the first index until the end.

    If the first index is out of table bounds or the length is less or equals
    zero, this function returns nil. Otherwise the slice.
]]
table.slice = function(t, first, length)
    length = length or 1 / 0
    local tlen = #t

    if first > tlen or first <= 0 or length <= 0 then
        return nil
    end

    local restl = tlen - first + 1
    local r
    if restl >= length then
        r = ctable(length)
        for i = first, first + length - 1 do
            table.insert(r, t[i])
        end
    else
        r = ctable(restl)
        for i = first, tlen do
            table.insert(r, t[i])
        end
    end
    return r
end

local Object = {
    __call = function(self, ...)
        local ret = setmetatable({}, { 
            __index    = self,
            __tostring = self.__tostring or function(self)
                return ("Instance: %s"):format(self.name or "<UNNAMED>")
            end
        })

        if  self.__init then
            self.__init(ret, ...)
        end

        return ret
    end,

    __tostring = function(self)
        return ("Class: %s"):format(self.name or "<UNNAMED>")
    end
}

--[[! Function: table.classify
    Makes any table a class. These classes are very simple and don't have
    any features except that they can inherit and have constructors (which
    are standard member functions and are called __init). Instantiate such
    class by simply calling it with the appropriate constructor arguments.
    Classes can also specify a __tostring method, which returns a string
    that is returned on tostring() of the class instance. The second
    argument specifies an optional class name.

    Note that this simple class system is not compatible with the class
    module.
]]
table.classify = function(t, name)
    t           = t or {}
    t.name      = name
    t.is_a      = table.is_a
    t.get_class = table.get_class
    return setmetatable(t, Object)
end

--[[! Function: table.subclass
    Inherits a classified table. That means the inherited table will have
    access to all base member functions. Constructors inherit as well.
    The third argument specifies an optional class name.
]]
table.subclass = function(base, new, name)
    new = new or {}
    new.name       = name
    new.base_class = base
    return setmetatable(new, {
        __index    = base,
        __call     = Object.__call,
        __tostring = Object.__tostring
    })
end

--[[! Function: table.is_a
    Returns true if an object given by the first argument is an instance
    of the class given by the second argument, false otherwise. Note that
    instance of a class X is an instance of any base class of X as well.
]]
table.is_a = function(inst, base)
    local  cl = getmetatable(inst).__index
    while  cl and type(cl) == "table" do
        if cl == base then return true end
        cl = cl.base_class
    end

    return false
end

--[[! Function: table.get_class
    Returns the base class of an object.
]]
table.get_class = function(inst)
    return getmetatable(inst).__index
end

--[[! Function: table.serialize
    Serializes a given table, returning a string containing a literal
    representation of the table. By default it tries to be compact so
    it avoids whitespace and newlines. Arrays vs associative arrays
    are distinguished.

    Besides tables this can also serialize other Lua values. It serializes
    them in the same way as values inside a table, returning their literal
    representation (if serializable, otherwise just their tostring).

    If the second given argument is true, the serializer attempts to
    format it for readability. While the first case is good for things
    like network transfers, the latter represents a human readable format.

    The third argument specifies the number of spaces used for indentation.
    It defaults to 4 spaces.

    In the pretty formatting mode arrays are put on a single line with a space
    after commas and before/after beginning/ending brace. One exception happens
    when the array only contains one another table, then no spaces are used.
    Associative arrays put each element on a separate line appropriately
    indented, the beginning/ending braces are both on their own line.

    In associative arrays, only numbers and strings are allowed as keys.
    The serializer is also smart enough to detect recursion (both simple
    and mutual to any level) and avoid stack overflows.

    There is one other optional argument called simplifier. It's a function
    that takes a key/index and a value and returns true if it should be
    simplified and false if it shouldn't. If it should be simplified,
    it also has to return a second value specifying what it should
    simplify to. If it does not, it means the value should be
    omitted from the serialized table.

    There is one case where the serializer simplifies by default, objects
    having a numerical member "uid". Those are treated as entities and they
    serialize directly to the uid.

    Values that cannot be serialized are passed through tostring.
]]
table.serialize = function(tbl, pretty, indent, simplifier)
    pretty = pretty or false
    indent = indent or 4

    local enc
    enc = function(tbl, tables, ind)
        local assoc, narr = is_array(tbl)
        local ret         = {} -- or ctable(narr) for efficiency - custom api
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
                elseif t == "number" then
                    elem[#elem] = tostring(v)
                else
                    elem[#elem] = "\"" .. tostring(v) .. "\""
                end

                if assoc and pretty then
                    table.insert(ret, "\n" .. (" "):rep(ind)
                        .. table.concat(elem))
                else
                    table.insert(ret, table.concat(elem))
                end
            end
        end

        if pretty then
            if assoc then
                table.insert(ret, "\n" .. (" "):rep(ind - indent))
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

--[[! Function: table.deserialize
    Takes a previously serialized table and converts it back to the original.
    This actually evaluates Lua code, but prevents anything malicious by
    working in an empty environment. Returns the table (unless an error
    happens). Different given literal values will work as well (for
    example, deserializing a string "\"foo\"" will result in value
    "foo").
]]
table.deserialize = function(str)
    assert(type(str) == "string", "the input value must be a string")

    -- loadstring with empty environment - prevent malicious code
    local  status, ret = pcall(setfenv(loadstring("return " .. str), {}))
    assert(status, ret)

    return ret
end
