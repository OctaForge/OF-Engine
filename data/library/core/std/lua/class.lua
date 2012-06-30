--[[! File: library/core/std/lua/class.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua class module. Further accessible as "class". Represents an
        OOP system which the library further extensively uses.
]]

local Object = {
    name = "Object"
}

Object.__class_dict = {
    __init     = function() end,
    __tostring = function(self)
        return string.format("Complex instance: %s", tostring(self.class.name))
    end
}

Object.__class_dict.__index = Object.__class_dict

setmetatable(Object, {
    __index    = Object.__class_dict,
    __newindex = Object.__class_dict,
    __call     = Object.__new,
    __tostring = function() return "Complex class: Object" end
    
})

Object.__new = function(self, ...)
    local inst = setmetatable(
        setmetatable({ class = self }, self.__class_dict),
        {}
    )

    inst.__getters     = {}
    inst.__setters     = {}
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

    meta.__newindex = function(self, key, value)
        if  self.__setters["__c"]
        and self.__setters["__c"](key, value) then
            self.__setters["__u"](self, key, value)
            return nil
        end

        if self.__setters[key] then
            self.__setters[key](self, value, self.__setter_data[key])
        else
            rawset(self, key, value)
        end
    end

    meta.__tostring = function(self)
        return self.__tostring(self)
    end

    meta.__init = function(self, ...)
        return self.__init(self, ...)
    end

    inst.__init(inst, ...)

    return inst
end

Object.__sub_class = function(self, name)
    local sub = {
        name         = name or "<UNNAMED>",
        base_class   = self,
        __class_dict = {}
    }

    local sub_dict   =  sub.__class_dict
    local sup_dict   = self.__class_dict
    sub_dict.__index = sub_dict

    setmetatable(sub_dict, sup_dict)

    setmetatable(sub, {
        __index    = sub_dict,
        __newindex = function(obj, name, value)
            rawset(sub_dict, name, value)
        end,
        __tostring = function(obj)
            return string.format("Complex class: %s", obj.name)
        end,
        __call     = function(obj, ...)
            return self.__new(obj, ...)
        end
    })

    sub_dict.__tostring = sup_dict.__tostring

    for k, v in pairs(self) do if type(v) == "function" then
        sub[k] = sup[k]
    end end

    sub.__init = function(obj, ...)
        self.__init(obj, ...)
    end

    return sub
end

Object.is_a = function(self, class)
    local _class = self.class
    while _class do
        if class == _class then
            return true
        end
        _class = _class.base_class
    end
    return false
end

Object.define_getter = function(self, key, fun, data)
    self.__getters    [key] = fun
    self.__getter_data[key] = data
end

Object.define_setter = function(self, key, fun, data)
    self.__setters    [key] = fun
    self.__setter_data[key] = data
end

Object.define_global_getter = function(self, condition, fun)
    self.__getters["__c"] = condition
    self.__getters["__u"] = fun
end

Object.define_global_setter = function(self, condition, fun)
    self.__setters["__c"] = condition
    self.__setters["__u"] = fun
end

Object.mixin = function(self, mixin_table)
    local skip = {
        "define_getter",
        "define_setter",
        "define_global_getter",
        "define_global_setter",
        "is_a"
    }

    local to_mixin = mixin_table

    if mixin_table.__class_dict then
        to_mixin = {}

        while mixin_table do
            for name, value in pairs(mixin_table.__class_dict) do
                if string.sub(name, 1, 2) ~= "__" and not
                   table.find(skip, name) and not to_mixin[name]
                then
                    to_mixin[name] = value
                end
            end

            mixin_table = mixin_table.base_class
        end
    end

    for name, value in pairs(to_mixin) do
        self[name] = value
    end

    return self
end

return {
    --[[! Function: new
        Creates a new class. The first argument represents the class
        to inherit from. If nil, it inherits from nothing.

        The second argument specifies an associative table of things that will
        be members of the class. Useful to pre-define various member functions,
        values etc. This one is optional.

        The third optional argument specifies name for the class. It's a
        string.

        (start code)
            -- empty named class
            Foo = class.new(nil, nil, "Foo")

            -- named class with mixin
            Bar = class.new(nil, { __init = function(self) end }, "Bar")

            -- named inherited class
            Baz = class.new(Bar, nil, "Baz")
        (end)

        Inherited classes automatically call their parent constructors,
        unless overriden. In inherited classes, the parent class is
        accessible under "base_class".

        Constructors are __init member function. Special __tostring member
        function returns a string that is supposed to be returned when doing
        tostring(X).

        (start code)
            Foo = class.new(nil, {
                __init = function(self, arg1)
                    echo("hello world, " .. arg1)
                end,

                __tostring = function(self)
                    return "this is %(1)s instance" % { self.name }
                end,

                foo = function(self)
                    echo("hello from foo")
                end
            }, "Foo")

            Bar = class.new(Foo, {
                __init = function(self, arg1, arg2)
                    self.base_class.__init(self, arg1)
                    echo("hello from Bar: " .. arg2)
                end,

                bar = function(self)
                    echo("hello from bar")
                    -- calls "foo" from the foo class
                    self:foo()
                end
            }, "Bar")

            -- calls the ctor, which calls the parent ctor
            baz = Bar(5, 10)

            -- prints "this is Bar instance"
            echo(tostring(baz))

            -- prints "hello from bar"
            -- and then "hello from foo"
            baz:bar()
        (end)

        Class instances have five builtin methods.

        "is_a" can be used to check if the value is an instance of
        a given class.

        (start code)
            Foo = class.new(...)
            foo = foo()

            assert(foo:is_a(Foo))
        (end)

        "define_getter" can be used to define a virtual getter for the class.

        (start code)
            Foo = class.new(nil, {
                __init = function(self)
                    -- the third argument to define_getter is optional and
                    -- specifies data that will be passed to the function
                    -- as an argument (without it, nothing is passed)
                    self:define_getter("bah", function(data)
                        return "data: " .. tostring(data)
                    end, "foobar")
                end
            }, "Foo")

            foo = Foo()
            -- prints "data: foobar"
            echo(foo.bah)
        (end)

        "define_setter" is used in the same way, except that it returns
        nothing and is called when a value is set on the class instance.
        The callback function takes two arguments, one is the value that
        is being set and the other is again, optional data (passed on
        define_setter).

        "define_global_getter" takes two functions, each taking a key as
        an argument. The first function serves as a condition. It has to
        return true for the second function to do something. The second
        function is the actual getter.

        (start code)
            Foo = class.new(nil, {
                __init = function(self)
                    self:define_global_getter(
                        -- will perform only on keys "bah" and "meh"
                        -- for everything else, the global getter will
                        -- be ignored
                        function(key)
                            if key == "bah" or key == "meh" then
                                return true
                            end
                            return false
                        end,
                        -- if they key is "bah", returns 5, otherwise
                        -- returns 10 (which applies only for the key "meh")
                        function(self, key)
                            if key == "bah" then
                                return 5
                            else
                                return 10
                            end
                        end
                    )
                end
            }, "Foo")

            foo = Foo()
            -- prints 5
            echo(foo.bah)
            -- prints 10
            echo(foo.meh)
            -- prints nil - no such member and condition returned false
            echo(tostring(foo.xyz))
        (end)

        For "define_global_setter", see "define_global_getter" and
        "define_setter". Both functions take an additional "value"
        argument, similarly to how "define_setter" callback does,
        but otherwise works as "define_global_getter".

        Note that class is not compatible with the simple system provided
        by the table module.
    ]]
    new = function(base, mixin, name)
        base = base or Object

        local obj = nil

        obj = base:__sub_class(name)
        if mixin then obj:mixin(mixin) end

        return obj
    end
}
