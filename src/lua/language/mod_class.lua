---
-- mod_class.lua, version 1<br/>
-- Class library for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com), bartbes<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local base = _G
local string = require("string")
local table = require("table")

--- Class library for Lua. Allows instances, parent calling and simple inheritance.
-- Multiple inheritance isn't and won't be supported. Code using multiple inheritance
-- won't be accepted into CubeCreate. What the class system allows are getters / setters
-- for virtual class members and get / set conditional function for emulating private
-- class members, which might be useful sometimes.
-- @class module
-- @name cc.class
module("cc.class")

--- Create a new class.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- A = class()<br/>
-- function A:__init(foo) end<br/>
-- function A:__tostring(foo) end<br/>
-- function A:blah(bleh) end<br/>
-- B = class(A)<br/>
-- instance = A(15)<br/>
-- binstance = B("foo")<br/>
-- </code>
-- @param b Base to inherit class from (optional)
-- @return The class.
function new(b)
    -- what will be the class
    local c = {}

    -- the base, empty when not inheriting
    if b and base.type(b) == "table" then c.__base = b
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
            else base.rawset(self, n, v) end
        end
    end

    -- the metatable for class
    local mt = {}
    -- call metamethod for constructor
    function mt:__call(...)
        local o = {}
        base.setmetatable(o, c)
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
        local m = base.getmetatable(self)
        while m do
            if c == m then return true end
            m = m.__base
        end
        return false
    end

    -- conditional for __index, returns true if it's okay (private emulation)
    function c:__indexcond(n) return n and true or false end

    -- define getter (callback when virtual element gets accessed)
    function c:define_getter(k, v, o)
        self.__getters[k] = v
        self.__getselfs[k] = self -- a little hack to get right self
        if o then self.__getaddargs[k] = o end
    end

    -- define setter (callback when virtual element is set)
    function c:define_setter(k, v, o)
        self.__setters[k] = v
        self.__setselfs[k] = self -- a little hack to get right self
        if o then self.__setaddargs[k] = o end
    end

    -- remove getter
    function c:remove_getter(k)
        -- do not check if exists, no need
        self.__getters[k] = nil
        self.__getselfs[k] = nil
        self.__getaddargs[k] = nil
    end

    -- remove setter
    function c:remove_setter(k)
        self.__setters[k] = nil
        self.__setselfs[k] = nil
        self.__setaddargs[k] = nil
    end

    -- define userget (callback on anything)
    function c:define_userget(f)
        self.__getters["*"] = f
        self.__getselfs["*"] = self
    end

    -- define userset (callback on anything)
    function c:define_userset(f)
        self.__setters["*"] = f
        self.__setselfs["*"] = self
    end

    -- set the metatable and return the class
    base.setmetatable(c, mt)
    return c
end
