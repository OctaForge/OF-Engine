--[[! File: library/core/std/lua/table.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua table module extensions. Functions are inserted directly into
        the table module. You can also access the table module as "std.table".
]]

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
        bar = table.map(foo, function(v) return std.conv.to("string", v) end)
    (end)
]]
table.map = function(t, f)
    local r = {}
    for i, v in pairs(t) do
        r[i] = f(v)
    end
    return r
end

--[[! Function: table.merge_dicts
    Merges two associative arrays (dictionaries) together
    and returns the result.
]]
table.merge_dicts = function(ta, tb)
    for a, b in pairs(tb) do
        ta[a] = b
    end
    return ta
end

--[[! Function: table.merge_arrays
    Merges two arrays (with numerical indexes) together and
    returns the result. The table has to be a proper array.
]]
table.merge_arrays = function(ta, tb)
    for i, v in pairs(tb) do
        table.insert(ta, v)
    end
    return ta
end

--[[! Function: table.copy
    Returns a copy of a given table.
]]
table.copy = function(t)
    local r = {}
    for a, b in pairs(t) do
        r[a] = b
    end
    return r
end

--[[! Function: table.filter_dict
    Filters an associative array (dictionary). Takes the table and a function
    returning true if the passed item should be part of the returned table
    and false if it shouldn't. The function takes two arguments, the key
    and the value. This doesn't perform anything on the original table.

    (start code)
        -- array to filter
        foo = { a = 5, b = 10, c = 15, d = 15 }
        -- filtered array, contains just a, b, c
        bar = table.filter(foo, function(k, v)
            if k == "d" and v == 15 then
                return false
            else
                return true
            end
        end)
    (end)

    See also <table.filter_array>.
]]
table.filter_dict = function(t, f)
    local r = {}
    for a, b in pairs(t) do
        if f(a, b) then
            r[a] = b
        end
    end
    return r
end

--[[! Function: table.filter_array
    See <table.filter_dict>. This works exactly in the same way, except that
    the table is not a dict, instead, it's an array. The function takes the
    same arguments, except that the first argument is an index, not a key.
]]
table.filter_array = function(t, f)
    local r = {}
    for i, v in pairs(t) do
        if f(i, v) then
            table.insert(r, v)
        end
    end
    return r
end

--[[! Function: table.find
    Finds a key of a value in the given table. The first argument is the
    table, the second argument is the value. Returns the key, or nil if
    nothing is found.
]]
table.find = function(t, v)
    for a, b in pairs(t) do
        if v == b then
            return a
        end
    end
    return nil
end

--[[! Function: table.keys
    Returns an array of table keys. See also <table.values>.
]]
table.keys = function(t)
    local r = {}
    for a, b in pairs(t) do
        table.insert(r, a)
    end
    return r
end

--[[! Function: table.keys
    Returns an array of table values. See also <table.keys>.
]]
table.values = function(t)
    local r = {}
    for a, b in pairs(t) do
        table.insert(r, b)
    end
    return r
end

--[[! Function: table.pop
    Pops out the last item of an array. Performs on the array itself.
    Returns the popped value.
]]
table.pop = function(t, p)
    p = p or #t
    local ret = t[p]
    table.remove(t, p)
    return ret
end

--[[! Function: table.sum
    Returns a sum of array values. Works on numerical arrays.
]]
table.sum = function(t)
    local ret = 0
    for k, v in pairs(t) do
        ret = ret + tonumber(v)
    end
end
