--[[!
    File: language/mod_class.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file implements a class system for Lua with simple inheritance.

    Section: Class system
]]

--[[!
    Package: class
    A class library for Lua. Allows instances, parent calling and simple inheritance.

    Multiple inheritance isn't and won't be probably supported.
    This class system also allows getters / setters for virtual class members
    and general getter / setter overrides.
]]
module("class", package.seeall)

--[[!
    Function: new
    This function creates a new class. New class then can be given
    methods, constructors, various metamethods etc. and instances
    can be created. Usage -

    (start code)
        A = class.new()
        function A:__init()
            echo("This is constructor")
            self.a = 5
            self.b = 15
        end
        function A:print()
            echo(self.a)
            echo(self.b)
        end
        B = class.new(a)
        function B:__init(_a)
            self.__base.__init(self)
            echo("Overriden constructor")
            self.a = _a
        end
        a = A()
        b = B(20)
        -- This will print:
        -- 5
        -- 15
        a:print()
        -- This will print:
        -- 20
        -- 15
        b:print()
    (end)

    Parameters:
        b - Optional argument specifying the class to inherit from.

    Returns:
        New class from which you can create instances.
]]
function new(b)
    --[[!
        Class: c
        This is/will be the base class that's returned from <new>.
        It has several default methods and that's why it's documented.
    ]]
    local c = {}

    -- the base, empty when not inheriting
    if b and type(b) == "table" then c.__base = b
    else c.__base = {} end

    -- inherit tostring. todo: inherit other metamethods too.
    if b then c.__tostring = b.__tostring end

    c.__index = c
    -- getters, setters, selfs, addargs
    c.__getters = {}
    c.__setters = {}
    c.__getselfs = {}
    c.__setselfs = {}
    c.__getaddargs = {}
    c.__setaddargs = {}

    -- called when new index gets created in table
    function c:__newindex(n, v)
        if not self:__indexcond(n) then return nil end

        if self.__setters["*"] then
            self.__setters["*"](self.__setselfs["*"], n, v)
        else
            if self.__setters[n] then
                if self.__setaddargs[n] then
                    self.__setters[n](self.__setselfs[n], self.__setaddargs[n], v)
                else
                    self.__setters[n](self.__setselfs[n], v)
                end
            else rawset(self, n, v) end
        end
    end

    -- the metatable for class
    local mt = {}
    -- call metamethod for constructor
    function mt:__call(...)
        local o = {}
        setmetatable(o, c)
        if self.__init then
            self.__init(o, ...)
        end
        return o
    end

    -- called when index is accessed
    function mt:__index(n)
        if not self:__indexcond(n) then return nil end

        -- allow for user methods only, no metamethods or internals
        if string.sub(n, 1, 2) ~= "__" and self.__getters["*"] then
            local rv = self.__getters["*"](self.__getselfs["*"], n)
            if rv then return rv end
        end

        if self.__getters[n] then
            if self.__getaddargs[n] then
                return self.__getters[n](self.__getselfs[n], self.__getaddargs[n])
            else
                return self.__getters[n](self.__getselfs[n])
            end
        else
            return self.__base[n]
        end
    end

    -- returns true if table is instance of class c
    -- (returns true for class + all of its parents)
    function c:is_a(c)
        local m = getmetatable(self)
        while m do
            if c == m then return true end
            m = m.__base
        end
        return false
    end

    -- conditional for __index, returns true if it's okay (private emulation)
    function c:__indexcond(n) return n and true or false end

    --[[!
        Function: define_getter
        This defines a new getter for the class. Getter is a function assigned
        to a key. When they key is accessed, the function is called and its
        return value is returned instead of real existing member.

        Parameters:
            k - A key to assign getter to.
            v - The getter. It either accepts no argument or extra data.
            o - Optional argument specifying extra data to always pass to getter.

        See also:
            <define_userget>
            <remove_getter>
    ]]
    function c:define_getter(k, v, o)
        self.__getters[k] = v
        self.__getselfs[k] = self -- a little hack to get right self
        if o then self.__getaddargs[k] = o end
    end

    --[[!
        Function: define_setter
        This defines a new setter for the class. Setter is a function assigned
        to a key. When they key is set, the function is called instead and it's
        expected from it to do the setting itself.

        Parameters:
            k - A key to assign getter to.
            v - The setter. It either accepts only the value that's meant to be set
            or also extra data. If extra data is present, it's passed before value.
            o - Optional argument specifying extra data to always pass to setter.

        See also:
            <define_userset>
            <remove_setter>
    ]]
    function c:define_setter(k, v, o)
        self.__setters[k] = v
        self.__setselfs[k] = self -- a little hack to get right self
        if o then self.__setaddargs[k] = o end
    end

    --[[!
        Function: remove_getter
        This removes getter from a key so it doesn't function anymore.

        Parameters:
            k - A key to remove getter from.

        See also:
            <define_getter>
    ]]
    function c:remove_getter(k)
        -- do not check if exists, no need
        self.__getters[k] = nil
        self.__getselfs[k] = nil
        self.__getaddargs[k] = nil
    end

    --[[!
        Function: remove_setter
        This removes setter from a key so it doesn't function anymore.

        Parameters:
            k - A key to remove setter from.

        See also:
            <define_setter>
    ]]
    function c:remove_setter(k)
        self.__setters[k] = nil
        self.__setselfs[k] = nil
        self.__setaddargs[k] = nil
    end

    --[[!
        Function: define_userget
        This defines an userget for the class. Userget is something like
        "global getter" - it's called on EVERY key access. If it returns
        something, that value is used; if not, it simply passes as if there
        was no userget.

        Parameters:
            f - The userget function. Has the same format as getter, except that
            you can't have extra data with it.

        See also:
            <define_getter>
    ]]
    function c:define_userget(f)
        self.__getters["*"] = f
        self.__getselfs["*"] = self
    end

    --[[!
        Function: define_userset
        This defines an userset for the class. Userset is something like
        "global setter" - it's called on EVERY key set.

        Parameters:
            f - The userset function. Has the same format as setter, except that
            you can't have extra data with it.

        See also:
            <define_setter>
    ]]
    function c:define_userset(f)
        self.__setters["*"] = f
        self.__setselfs["*"] = self
    end

    -- set the metatable and return the class
    setmetatable(c, mt)
    return c
end
