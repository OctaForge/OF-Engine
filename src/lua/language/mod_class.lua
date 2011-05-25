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
        It is inspired by "middleclass" class system for Lua, but not directly
        based on it.

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

object = {}
object.__class_dict = {
    __init     = function() end,
    __tostring = function(self) return "instance: %(1)s" % { tostring(self.class.name) } end
}
object.__class_dict.__index = object.__class_dict

setmetatable(object, {
    __index    = object.__class_dict,
    __newindex = object.__class_dict,
    __call     = object.__new,
    __tostring = function() return "class: object" end
})

function object:__new(...)
    local inst = setmetatable(setmetatable({ class = self }, self.__class_dict), {})

    inst.__getters = {}
    inst.__setters = {}
    inst.__getter_data = {}
    inst.__setter_data = {}

    local meta = getmetatable(inst)

    meta.__index = function(self, key)
        if self.__getters["__c"] and self.__getters["__c"](key) then
            return self.__getters["__u"](self, key)
        end

        if self.__getters[key] then
            return self.__getters[key](self, self.__getter_data[key])
        else
            return self.class.__class_dict[key] or self.class[key]
        end
    end

    meta.__newindex = function(self, key, val)
        if self.__setters["__c"] and self.__setters["__c"](key, val) then
            self.__setters["__u"](self, key, val)
            return nil
        end

        if self.__setters[key] then
            local data = self.__setter_data[key]
            if data then
                self.__setters[key](self, data, val)
            else
                self.__setters[key](self, val)
            end
        else
            rawset(self, key, val)
        end
    end

    meta.__tostring = function(self)
        return self.__tostring(self)
    end

    meta.__init = function(self, ...)
        return self.__init(self, ...)
    end

    inst:__init(...)
    return inst
end

function object:__sub_class(name)
    local _subcl = { name = name or "<UNNAMED>", __base = self, __class_dict = {} }

    local _sub_dict = _subcl.__class_dict
    local _sup_dict =   self.__class_dict
    _sub_dict.__index = _sub_dict

    setmetatable(_sub_dict, _sup_dict)

    setmetatable(_subcl, {
        __index = _sub_dict,
        __newindex = function(_self, n, v)
            rawset(_sub_dict, n, v)
        end,
        __tostring = function(self) return "class: %(1)s" % { self.name } end,
        __call = function(self, ...) return _subcl:__new(...) end
    })

    _sub_dict["__tostring"] = _sup_dict["__tostring"]

    _subcl.__init = function(_self, ...) self.__init(_self, ...) end

    return _subcl
end

function object:is_a(cl)
    local _cl = self.class
    while _cl do
        if cl == _cl then return true end
        _cl = _cl.__base
    end
    return false
end

function object:define_getter(key, func, data)
    self.__getters[key] = func
    self.__getter_data[key] = data
end

function object:define_setter(key, func, data)
    self.__setters[key] = func
    self.__setter_data[key] = data
end

function object:define_userget(cond, func)
    self.__getters["__c"] = cond
    self.__getters["__u"] = func
end

function object:define_userset(cond, func)
    self.__setters["__c"] = cond
    self.__setters["__u"] = func
end

function object:remove_getter(key)
    self.__getters[key] = nil
    self.__getter_data[key] = nil
end

function object:remove_setter(key)
    self.__setters[key] = nil
    self.__setter_data[key] = nil
end

function new(base, name)
    base = base or object
    return base:__sub_class(name)
end
