--[[!
    File: library/core/language/mod_table.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features various extensions made to Lua's table module.
]]

--[[!
    Package: table
    Provides various extensions to default table module,
    including mapping, filtering, merging etc.
]]
module("table", package.seeall)

--[[!
    Function: map
    Remaps a table (array). Usage -

    (start code)
        local a = { 1, 2, 3, 4, 5 }
        local b = table.map(a, function(i) return tostring(i) end)
        -- b is now a table of strings
    (end)

    Parameters:
        t - The table to remap.
        f - A function taking original element and returning remapped.

    Returns:
        A remapped table.
]]
function map(t, f)
    local r = {}
    for i, v in pairs(t) do
        r[i] = f(v)
    end
    return r
end

--[[!
    Function: merge_dicts
    Merges two tables (dictionaries) together. Usage -

    (start code)
        local a = { a = 5, b = 10 }
        local b = { c = 15, d = 20 }
        table.merge_dicts(a, b)
        -- a now has b's elements
    (end)

    Parameters:
        ta - The table to merge elements into.
        tb - The table to merge elements from.

    Returns:
        Merged table.
]]
function merge_dicts(ta, tb)
    for a, b in pairs(tb) do
        ta[a] = b
    end
    return ta
end

--[[!
    Function: merge_arrays
    Merges two tables (arrays) together. Usage -

    (start code)
        local a = { 5, 10, 15 }
        local b = { 20, 25, 30 }
        table.merge_arrays(a, b)
        -- a now has b's elements
    (end)

    Parameters:
        ta - The table to merge elements into.
        tb - The table to merge elements from.

    Returns:
        Merged table.
]]
function merge_arrays(ta, tb)
    for i, v in pairs(tb) do
        table.insert(ta, v)
    end
    return ta
end

--[[!
    Function: copy
    Copies a table. Remember, it does not take care of copying
    in case member is a table. Usage -

    (start code)
        local a = { 5, 10, 15 }
        local b = table.copy(a)
        -- b is now a copy of a
    (end)

    Parameters:
        t - The table to copy.

    Returns:
        Copied table.
]]
function copy(t)
    local r = {}
    for a, b in pairs(t) do
        r[a] = b
    end
    return r
end

--[[!
    Function: filter_dict
    Filters a table (dictionary). Usage -

    (start code)
        local a = { a = 5, b = 10 }
        local b = table.filter_dict(a, function (k, v)
            return ((v <= 5) and true or false)
        end)
        -- b now contains just "a"
    (end)

    Parameters:
        t - The table to filter.
        f - A function taking key and value and returning true if
        current element should be included in new table and false otherwise.

    Returns:
        A filtered table.
]]
function filter_dict(t, f)
    local r = {}
    for a, b in pairs(t) do
        if f(a, b) then
            r[a] = b
        end
    end
    return r
end

--[[!
    Function: filter_array
    Filters a table (array). Usage -

    (start code)
        local a = { 5, 10, 15 }
        local b = table.filter_array(a, function (i, v)
            return ((i <= 2) and true or false)
        end)
        -- b is empty
    (end)

    Parameters:
        t - The table to filter.
        f - A function taking index and value and returning true if
        current element should be included in new table and false otherwise.

    Returns:
        A filtered table.
]]
function filter_array(t, f)
    local r = {}
    for i, v in pairs(t) do
        if f(i, v) then
            table.insert(r, v)
        end
    end
    return r
end

--[[!
    Function: find
    Finds index / key of an element belonging to a table. Usage -

    (start code)
        local a = { a = 5, b = 10, c = 15 }
        local b = table.find(a, 15)
        -- b is now "c"
    (end)

    Parameters:
        t - The table to find index / key in.
        v - The value to find index / key of.

    Returns:
        Index / key of the value in the table.
]]
function find(t, v)
    for a, b in pairs(t) do
        if v == b then
            return a
        end
    end
    return nil
end

--[[!
    Function: keys
    Gets a table of indexes / keys of a table. Usage -

    (start code)
        local a = { a = 5, b = 10, c = 15 }
        local b = table.keys(a)
        -- b is now { "a", "b", "c" }
    (end)

    Parameters:
        t - The table to get indexes / keys from.

    Returns:
        Table of indexes / keys.
]]
function keys(t)
    local r = {}
    for a, b in pairs(t) do
        table.insert(r, a)
    end
    return r
end

--[[!
    Function: values
    Gets a table of values of a table. Usage -

    (start code)
        local a = { a = 5, b = 10, c = 15 }
        local b = table.values(a)
        -- b is now { 5, 10, 15 }
    (end)

    Parameters:
        t - The table to get values from.

    Returns:
        Table of values.
]]
function values(t)
    local r = {}
    for a, b in pairs(t) do
        table.insert(r, b)
    end
    return r
end

--[[!
    Function: pop
    Pops item from end of the table or
    from specific position and returns it. Usage -

    (start code)
        local a = { 5, 10, 15, 20, 25, 30, 35, 40 }
        local b = table.pop(a)
        -- b is now 40, a is { 5, 10, 15, 20, 25, 30, 35 }
        b = table.pop(a, 3)
        -- b is now 15, a is { 5, 10, 20, 25, 30, 35 }
    (end)

    Parameters:
        t - The table to pop item from.
        p - Optional argument specifying index, it's the
        end of the table if not specified.

    Returns:
        The popped item.
]]
function pop(t, p)
    p = p or #t
    local ret = t[p]
    table.remove(t, p)
    return ret
end

--[[!
    Function: sum
    Sums a table of numbers. Usage -

    (start code)
        local a = { 5, 10, 15 }
        local b = table.sum(a)
        -- b is now 5 + 10 + 15, that is 30
    (end)

    Parameters:
        t - The table of numbers to sum.

    Returns:
        The sum.
]]
function sum(t)
    local ret = 0
    for k, v in pairs(t) do
        ret = ret + v
    end
end
