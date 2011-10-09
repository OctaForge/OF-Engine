--[[!
    File: library/core/language/mod_class.lua

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
]]

--[[!
    Package: class
    A class library for Lua. Allows instances, parent calling
    and simple inheritance.

    Multiple inheritance isn't and won't be probably supported.
    This class system also allows getters / setters for virtual class members
    and general getter / setter overrides.
]]
module("class", package.seeall)

--[[!
    Function: new
    Creates a new class. You can then create instance of the class by
    calling output of this.

    Example:
        (start code)
            A = class.new(nil, {
                __tostring = function(self)
                    return self.name
                end
            })
            instance = A()
            n = tostring(instance) -- this is <UNNAMED>

            B = class.new(A, {
                dofoo = function(self)
                    print(self.a)
                end
            }, "foo")
            B.a = 150

            instance = B()

            n = tostring(instance) -- this is foo
            instance:dofoo() -- prints 10
        (end)

    Parameters:
        base - the base class this one inherits from. Can be nil.
        Inherited class contains all methods and members of base
        class.
        mixin - a table containing methods and members that are new
        in your class. It can as well be nil and you can define
        the members later, after calling this. If this is string,
        the function assumes you're providing name as the second
        argument, that mostly means you don't want mixin but you
        want your class named.
        name - the class name. It is then available under "name"
        class member. It defaults to "<UNNAMED>".
]]
function new(base, mixin, name)
    -- select base object
    base = base or object

    -- this will be the class
    local obj = nil

    -- if we have the mixin as table, use it
    if type(mixin) == "table" then
        obj = base:__sub_class(name)
        obj:mixin(mixin)
    else
        -- else assume we've provided name as second arg
        obj = base:__sub_class(mixin)
    end

    -- return it
    return obj
end

--[[!
    Class: object
    This is a base class from which every other class inherits.
    It provides certain basic members and also has metatable
    set up, so required metamethods work.
]]
object = {}

--[[!
    Variable: name
    This is the base object name. It's unused in all child
    classes, since those are either "<UNNAMED>" or have their
    own name.
]]
object.name = "object"

--[[!
    Variable: __class_dict
    Root "class dictionary". Contains default constructor
    and default __tostring for instance (which returns
    "instance: NAME"). It also has __index metamethod,
    which it sets to itself.
]]
object.__class_dict = {
    __init     = function() end,
    __tostring = function(self) return "instance: %(1)s" % {
        tostring(self.class.name) }
    end
}
object.__class_dict.__index = object.__class_dict

--[[!
    Variable: class_metatable
    Object has its own metatable. It's in fact unnamed.
    It sets __index to <__class_dict>, __newindex
    to the same, __call to <__new> so you can create
    instances by calling the class and also __tostring
    for class (not for instance).
]]
setmetatable(object, {
    __index    = object.__class_dict,
    __newindex = object.__class_dict,
    __call     = object.__new,
    __tostring = function() return "class: object" end
})

--[[!
    Function: __new
    This is called when we call the class. It's sort of "root constructor".
    It sets up metatables properly as well as metamethods for indexing
    with getter support and setting indexes with setter support.

    Also sets up internal storages for getters and setters and finally,
    calls class' own constructor.

    Parameters:
        ... - constructor arguments
]]
function object:__new(...)
    -- we return this - sets up basic metatables
    local inst = setmetatable(
        setmetatable(
            { class = self },
            self.__class_dict
        ),
        {}
    )

    -- internal getter / setter storages
    inst.__getters = {}
    inst.__setters = {}
    inst.__getter_data = {}
    inst.__setter_data = {}

    -- get its metatable
    local meta = getmetatable(inst)

    -- override __index so we can call getters properly
    meta.__index = function(self, key)
        -- if we have custom global getters, check if condition passed
        -- so we can call the global getter
        if self.__getters["__c"] and self.__getters["__c"](key) then
            return self.__getters["__u"](self, key)
        end

        -- specific getters - if we have one for the key, call it,
        -- else return raw member simply
        if self.__getters[key] then
            return self.__getters[key](self, self.__getter_data[key])
        else
            return self.class.__class_dict[key] or self.class[key]
        end
    end

    -- override __newindex so we can use setters
    meta.__newindex = function(self, key, value)
        -- see __index above
        if  self.__setters["__c"]
        and self.__setters["__c"](key, value) then
            self.__setters["__u"](self, key, value)
            return nil
        end

        -- see __index above
        if self.__setters[key] then
            self.__setters[key](self, value, self.__setter_data[key])
        else
            rawset(self, key, value)
        end
    end

    -- expose __tostring
    meta.__tostring = function(self)
        return self.__tostring(self)
    end

    -- expose __init
    meta.__init = function(self, ...)
        return self.__init(self, ...)
    end

    -- call the constructor
    inst:__init(...)

    -- return it
    return inst
end

--[[!
    Function: __sub_class
    Inherits a class. Returns inherited class. Makes sure everything
    is properly inherited, sets up default constructor (calls parent),
    metamethod handlers (__tostring) and naming.

    Shouldn't be called alone. See <class.new>.

    Parameters:
        name - name of the new class.
]]
function object:__sub_class(name)
    local _subcl = {
        name = name or "<UNNAMED>", __base = self, __class_dict = {}
    }

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

--[[!
    Function: is_a
    Checks if the object is an instance of a class.
    Instances of child classes are also instances
    of parent classes!

    Returns true if object is an instance of given
    class, false otherwise.

    Example:
        (start code)
            A = class.new()
            B = class.new(A)
            C = class.new(B)
            D = class.new(C)
            E = class.new(D)
            F = class.new(E)

            inst = E();

            local r;
            r = inst:is_a(A) -- true
            r = inst:is_a(B) -- true
            r = inst:is_a(C) -- true
            r = inst:is_a(D) -- true
            r = inst:is_a(E) -- true
            r = inst:is_a(F) -- false
        (end)

    Parameters:
        class - the class to check against.
]]
function object:is_a(class)
    local cl = self.class
    while cl do
        if class == cl then return true end
        cl = cl.__base
    end
    return false
end

--[[!
    Function: define_getter
    Defines a getter for a class. Getter basically
    simulates a class member, but instead of returning
    the class member, it returns output of given getter
    function. You can pass one extra argument which
    will be always passed to the getter function as data.

    See also <define_setter> which has simillar usage.

    Example:
        (start code)
            A = class.new(nil, {
                data = 150,

                __init = function(self)
                    -- self.data as data doesn't make much
                    -- sense here, since we always have access
                    -- to self, but it's just an example
                    self:define_getter(
                        "foo",
                        function(self, data)
                            return data * 2
                        end,
                        self.data
                    )
                end
            })
            B = class.new(A, { data = 200 })

            inst = B()
            print(B.foo) -- prints 400
        (end)

    Parameters:
        key - name of the virtual member.
        fun - function taking at least one argument (self)
        and optionally a second one (data) that returns some
        value.
        data - optional second argument to getter function.
]]
function object:define_getter(key, fun, data)
    self.__getters[key] = fun
    self.__getter_data[key] = data
end

--[[!
    Function: define_setter
    This functions exactly the same as <define_getter>,
    but the function takes always two arguments, that is,
    self and value, and optional third one, that is data.

    The function doesn't have to return anything and any
    return value will be ignored. It's called when you
    attempt to set the member previously defined by setter.
    The value argument to setter function is the one after
    assignment operator.
]]
function object:define_setter(key, fun, data)
    self.__setters[key] = fun
    self.__setter_data[key] = data
end

--[[!
    Function: define_global_getter
    Simillar to <define_getter>, with several differences.
    It does not allow to pass custom data. You don't give
    it any key either. You give it two functions instead.
    The first function is called when you're trying to get
    any member. It gets exactly one argument, and that is
    the key. It evaluates the key and returns true if the
    getter should be called, and false otherwise.

    If it returns true, then the second function, actual
    getter, gets called. It accepts two arguments, self,
    and the key you were trying to get, and returns the
    appropriate value.

    Global getters allow to simply define getter for
    a range of keys (i.e. range of numbers) without
    writing separate getter for each.

    See also <define_global_setter>.

    Parameters:
        cond - the function that evaluates the key.
        fun - the function that returns the value.
]]
function object:define_global_getter(cond, fun)
    self.__getters["__c"] = cond
    self.__getters["__u"] = fun
end

--[[!
    Function: define_global_setter
    See <define_setter> and <define_global_getter>.
    It's basically exactly the same, including
    arguments to this function. The difference is
    that the function that evaluates things does
    not get only key, but also a value as second
    argument and the setter itself gets the value
    as third argument (after self and key).
]]
function object:define_global_setter(cond, fun)
    self.__setters["__c"] = cond
    self.__setters["__u"] = fun
end

--[[!
    Function: mixin
    Mixes a table inside the class. Mixin is basically
    an associative table containing any members.
    It'll get looped and its members will get assigned
    to the class.

    Mixins can also be a limited replacement to multiple
    inheritance. When you pass a class as a mixin, it'll
    get merged, including all its parent classes.

    Not all elements of class will get mixed in though;
    functions prefixed with __ will get skipped (that
    is, metamethods, constructors ..), certain core
    methods (such as <define_getter> or <is_a>) will
    get skipped as well.

    If mixed in class provides something that is also
    provided by its parent class, more recent member
    is preferred (only the member from child class
    will get merged).

    Please note that when mixing in a normal non-class
    table, everything, including possible metamethods,
    will get merged.

    Parameters:
        mixin_t - a raw table or a class.
]]
function object:mixin(mixin_t)
    -- skipped methods for a class
    local mixin_skip = {
        "define_getter", "define_setter",
        "define_userget", "define_userset",
        "remove_getter", "remove_setter",
        "is_a"
    }

    -- to_mixin will be the table by default
    -- this will get mixed in
    local to_mixin = mixin_t

    -- if the argument is a class..
    if mixin_t.__class_dict then
        -- set to_mixin as empty
        to_mixin = {}

        -- and inserting class contents into to_mixin
        while mixin_t do
            for name, value in pairs(mixin_t.__class_dict) do
                -- do not allow to mixin i.e. constructors
                -- for safety reasons.
                if string.sub(name, 1, 2) ~= "__" and
                not table.find(mixin_skip, name) and
                not to_mixin[name] then
                    to_mixin[name] = value
                end
            end
            -- go deeper
            mixin_t = mixin_t.__base
        end
    end

    -- finally merge to_mixin
    for name, value in pairs(to_mixin) do
        self[name] = value
    end

    -- returns the class so we can chain mixins
    return self
end
