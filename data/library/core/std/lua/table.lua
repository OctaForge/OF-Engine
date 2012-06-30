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
    Merges the two given tables together and returns the result. The original
    tables are left unmodified. If they are arrays, the second table's contents
    come after the first's. If they are associative arrays and both tables
    contain an element of the same key, the one from the second table is
    used. If one of them is an array and the other is an associative array,
    the result is an associative array as well.
]]
table.merge = function(ta, tb)
    local r
    local l1, l2 = #ta, #tb
    if l1 ~= 0 and l2 ~= 0 then
        r = ctable(l1 + l2)
        for i = 1, l1 do table.insert(r, ta[i]) end
        for i = 1, l2 do table.insert(r, tb[i]) end
    else
        r = {}
        for a, b in pairs(ta) do r[a] = b end
        for a, b in pairs(tb) do r[a] = b end
    end
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
    Filters a table. Takes the table and a function returning true if the
    passed item should be a part of the returned table and false if it
    shouldn't. The function takes two arguments, the key or index and
    the value. This doesn't perform anything on the original table.

    (start code)
        -- table to filter
        foo = { a = 5, b = 10, c = 15, d = 15 }
        -- filtered table, contains just a, b, c
        bar = table.filter(foo, function(k, v)
            if k == "d" and v == 15 then
                return false
            else
                return true
            end
        end)
    (end)
]]
table.filter = function(t, f)
    local r = {}
    if #t ~= 0 then
        for a, b in pairs(t) do if f(a, b) then table.insert(r, b) end end
    else
        for a, b in pairs(t) do if f(a, b) then r[a] = b end end
    end
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
    values the resulting table should contain).

    If the first index is out of table bounds or the length is less or equals
    zero, this function returns nil. Otherwise the slice.
]]
table.slice = function(t, first, length)
    local tlen = #t
    if first > tlen or first <= 0 or length <= 0 then
        return nil
    end

    local restl = tlen - first + 1
    local r
    if restl >= len then
        r = ctable(len)
        for i = first, first + len - 1 do
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
