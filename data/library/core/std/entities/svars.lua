--[[!
    File: library/core/std/entities/svars.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Implements "state variables". State variables are basically entity
        properties. They mimick real property behavior. They automatically
        sync changes between clients/server as required. They can be of
        various types and new svar types are easily implementable.
]]

local tostring, tointeger, tonumber, toboolean, abs, round, floor, rawget
    = tostring, tointeger, tonumber, toboolean, math.abs, math.round,
      math.floor, rawget

local M = {}

local State_Variable, State_Variable_Alias, State_Integer, State_Float,
      State_Boolean, State_Table, State_String, Array_Surrogate, State_Array,
      State_Array_Integer, State_Array_Float, Vec3_Surrogate, Vec4_Surrogate,
      State_Vec3, State_Vec4

--[[! Function: is_svar
    Checks whether the given value is a state variable.
]]
M.is_svar = function(v)
    return (type(v) == "table" and v.is_a) and v:is_a(State_Variable)
end

--[[! Function: is_svar_alias
    Checks whether the given value is a state variable alias.
]]
M.is_svar_alias = function(v)
    return (type(v) == "table" and v.is_a) and v:is_a(State_Variable_Alias)
end

--[[! Class: State_Variable
    Provides a base object for a state variable. Specialized svar types
    clone this and define their own methods.
]]
State_Variable = table.Object:clone {
    name = "State_Variable",

    --[[! Function: __tostring
        Makes svar objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Constructor: __init
        Initializes the svar. Parameters are passed in kwargs.

        Kwargs:
            client_read [true] - clients can read the value.
            client_write [true] - the value can be written clientside
            (indirectly through a server message).
            client_set [false] - the value can be written clientside
            directly without a server message.
            client_private [false] - the value will be private to the client,
            other clients won't see it (but the server will).
            custom_sync [false] - the state variable will use a custom
            synchronization method (useful for Cube 2 dynents).
            gui_name [nil] - the name shown in the editing GUI for the svar.
            alt_name [nil] - alternative accessor name.
            reliable [true] - the messages sent for this svar will be reliable,
            that is, always sent; you cannot send a big number of them.
            For i.e. position updates, you're better off with unreliable
            messages that do not need to be sent all the time.
            has_history [true] - the var will retain its state and i.e.
            when a new client requests it, it'll receive the values set
            previously (even if set long before the connection).
            getter [nil] - a custom getter for the state var, used typically
            with C functions (to handle C-side entity changes). Takes one
            argument, an entity this state var belongs to.
            setter [nil] - similar to getter, just for setting. Takes two
            arguments, the entity and the value we're setting. Note that
            even with getter and setter functions, the value will be cached
            for better performance (we don't always have to query).
    ]]
    __init = function(self, kwargs)
        log(INFO, "State_Variable: init")

        kwargs = kwargs or {}

        self.client_read    = kwargs.client_read    or true
        self.client_write   = kwargs.client_write   or true
        self.client_set     = kwargs.client_set     or false
        self.client_private = kwargs.client_private or false

        self.custom_sync = kwargs.custom_sync or false

        self.gui_name, self.alt_name = kwargs.gui_name, kwargs.alt_name

        self.reliable    = kwargs.reliable    or true
        self.has_history = kwargs.has_history or true

        self.getter_fun = kwargs.getter
        self.setter_fun = kwargs.setter
    end,

    --[[! Function: register
        Registers the state variable, given an entity. It'll create
        getters and setters on the entity for the given name and also
        for alt_name if set in constructor kwargs. You can still access
        the raw state variable on the entity by prefixing it with _SV_.
    ]]
    register = function(self, name, parent)
        log(DEBUG, "State_Variable: register(" .. name
            .. ", " .. tostring(parent) .. ")")

        self.name = name
        parent["_SV_" .. name] = self

        assert(self.getter)
        assert(self.setter)

        log(DEBUG, "State_Variable: register: getter/setter")
        parent:define_getter(name, self.getter, self)
        parent:define_setter(name, self.setter, self)

        local an = self.alt_name
        if an then
            log(DEBUG, "State_Variable: register: alt getter/setter")
            parent["_SV_" .. an] = self
            parent:define_getter(an, self.getter, self)
            parent:define_setter(an, self.setter, self)
        end

        local gf, sf = self.getter_fun, self.setter_fun

        -- strings: late binding, sometimes useful
        if type(gf) == "string" then
            self.getter_fun = loadstring("return " .. gf)()
        end

        if type(sf) == "string" then
            self.setter_fun = loadstring("return " .. sf)()
            sf = self.setter_fun
        end

        if not sf then return nil end

        log(DEBUG, "State_Variable: register: found a setter function")

        local var = self
        local sn  = name .. "_changed"
        signal.connect(parent, sn, function(_, self, val)
            if CLIENT or not self.svar_change_queue then
                log(INFO, "Calling setter function for " .. name)
                var.setter_fun(self, val)
                log(INFO, "Setter called")

                self.svar_values[name] = val
                self.svar_value_timestamps[name] = frame.get_frame()
            else
                self:queue_svar_change(name, val)
            end
        end)
    end,

    --[[! Function: read_tests
        Performs clientside svar read tests. On the server we can always
        read, on the client we can't if client_read is false. Fails an
        assertion if on the client and client_read is false.
    ]]
    read_tests = function(self, ent)
        assert(self.client_read or SERVER)
    end,

    --[[! Function: read_tests
        Performs clientside svar write tests. On the server we can always
        write, on the client we can't if client_write is false. Fails an
        assertion if on the client and client_read is false (or if an
        entity is deactivated/uninitialized).
    ]]
    write_tests = function(self, ent)
        if ent.deactivated then
            assert(false, "Writing a field " .. self.name ..
                 " of a deactivated entity " .. tostring(ent) ..
                 "(" .. ent.uid .. ")")
        end

        assert(self.client_write or SERVER)
        assert(ent.initialized)
    end,

    --[[! Function: getter
        Default getter for a state variable. Works on an entity (which
        is self here). It mostly simply returns the value from an internal
        table. The second argument here is the state variable. It performs
        read tests.

        Note that if custom getter function is provided in the constructor's
        kwargs and no sufficient value is cached, it'll return the value
        the getter function returns (and it'll also save into the cache
        for further use).
    ]]
    getter = function(self, var)
        var:read_tests(self)

        local vn = var.name
        log(INFO, "State_Variable: getter: " .. vn)

        local fr = frame.get_frame()

        if not var.getter_fun
            or (not CLIENT and self.svar_change_queue)
            or self.svar_value_timestamps[vn] == fr
        then
            return self.svar_values[vn]
        end

        log(INFO, "State_Variable: getter: getter function")

        local val = var.getter_fun(self)

        if CLIENT or self.svar_change_queue_complete then
            self.svar_values[vn] = val
            self.svar_value_timestamps[vn] = fr
        end

        return val
    end,

    --[[! Function: setter
        Default setter for a state variable. Works on an entity (which
        is self here). It sets state data on the entity. The third argument
        is the variable. It performs write tests.
    ]]
    setter = function(self, val, var)
        var:write_tests(self)
        self:set_sdata(var.name, val, -1)
    end,

    --[[! Function: validate
        Validates a state variable value. The default simply returns
        true. Can be overriden.
    ]]
    validate = function(self, val) return true end,

    --[[! Function: should_send
        Checks whether changes of this variable should be synced
        with other clients. The arguments specify an entity the change
        is happening on and a target client number to check. Returns
        true if this variable is not client_private or if the target
        client number equals the client number of the given entity.
    ]]
    should_send = function(self, ent, tcn)
        return (not self.client_private) or (ent.cn == tcn)
    end,

    --[[! Function: to_wire
        Converts the given value to wire format for this state variable.
        It's a string meant for final network transmission. On the other
        side it's simply converted back to the original format using
        <from_wire>. By default simply converts to string.
    ]]
    to_wire = function(self, val)
        return tostring(val)
    end,

    --[[! Function: from_wire
        Converts the given value in wire format back to the original
        format. See <to_wire>. By default simply returns a string.
    ]]
    from_wire = function(self, val)
        return tostring(val)
    end
}
M.State_Variable = State_Variable

--[[! Class: State_Integer
    Specialization of <State_Variable> for integer values. Overrides
    to_ and from_ wire appropriately, to_wire converts to a string,
    from_wire converts to an integer.
]]
State_Integer = State_Variable:clone {
    name = "State_Integer",

    to_wire   = function(self, val) return tostring (val) end,
    from_wire = function(self, val) return tointeger(val) end
}
M.State_Integer = State_Integer

--[[! Class: State_Float
    Specialization of <State_Variable> for float values. Overrides
    to_ and from_ wire appropriately, to_wire converts to a string
    (with max two places past the floating point represented in the
    string), from_wire converts to a float.
]]
State_Float = State_Variable:clone {
    name = "State_Float",

    to_wire   = function(self, val) return tostring(round(val, 2)) end,
    from_wire = function(self, val) return tonumber(val) end
}
M.State_Float = State_Float

--[[! Class: State_Boolean
    Specialization of <State_Variable> for boolean values. Overrides
    to_ and from_ wire appropriately, to_wire converts to a string,
    from_wire converts to a boolean.
]]
State_Boolean = State_Variable:clone {
    name = "State_Boolean",

    to_wire   = function(self, val) return tostring (val) end,
    from_wire = function(self, val) return toboolean(val) end
}
M.State_Boolean = State_Boolean

local ts, td = table.serialize, table.deserialize

--[[! Class: State_Table
    Specialization of <State_Variable> for table values. Overrides
    to_ and from_ wire appropriately, to_wire serializes the given
    table, from_wire deserializes it.
]]
State_Table = State_Variable:clone {
    name = "State_Table",

    to_wire   = function(self, val) return ts(val) end,
    from_wire = function(self, val) return td(val) end
}
M.State_Table = State_Table

--[[! Class: State_String
    Specialization of <State_Variable> for string values. Doesn't
    override to_ and from_wire, because the defaults already work
    with strings.
]]
State_String = State_Variable:clone {
    name = "State_String"
}
M.State_String = State_String

local ctable = createtable

--[[! Class: Array_Surrogate
    Represents a "surrogate" for an array. Behaves like a regular
    array, but does not actually contain anything; it merely serves
    as an interface for state variables like <State_Array>.

    You can manipulate this like a regular array (check its length,
    index it, assign indexes) but many of the functions from the
    table library likely won't work.
]]
Array_Surrogate = table.Object:clone {
    name = "Array_Surrogate",

    --[[! Function: __tostring
        Makes surrogate objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Function: __get
        Called each time you index an array surrogate. It checks
        the validity of the given index by converting it to a number
        and flooring it. If the given index is not an integer, this
        has no effect. Otherwise returns the corresponding state variable
        element.
    ]]
    __get = function(self, n)
        n = tonumber(n)
        if not n then return nil end
        local i = floor(n)
        if i ~= n then return nil end

        local v = rawget(self, "variable")
        return v:get_item(rawget(self, "entity"), i)
    end,

    --[[! Function: __set
        Called each time you set an index on an array surrogate. It checks
        the validity of the given index by converting it to a number and
        flooring it. If the given index is not an integer, this has no
        effect. Otherwise sets the corresponding element using the state
        variable.
    ]]
    __set = function(self, n, val)
        n = tonumber(n)
        if not n then return nil end
        local i = floor(n)
        if i ~= n then return nil end

        local v = rawget(self, "variable")
        v:set_item(rawget(self, "entity"), i, val)
        return true
    end,

    --[[! Function: __len_fn
        Returns the length of the "array" represented by the state variable.
        Set as a value of the __len metamethod on surrogate instances.
        The prefix _fn is used to prevent its effects on the prototype.
    ]]
    __len_fn = function(self)
        local v = rawget(self, "variable")
        return v:get_length(rawget(self, "entity"))
    end,

    --[[! Function: to_array
        Returns a raw array of values stored using the state variable.
    ]]
    to_array = function(self)
        local l = #self
        local r = ctable(l)
        for i = 1, l do
            r[#r + 1] = self[i]
        end
        return r
    end,

    --[[! Constructor: __init
        Constructs the array surrogate. Defines its members "entity"
        and "variable", assigned using the provided arguments.
    ]]
    __init = function(self, ent, var)
        log(INFO, "Array_Surrogate: __init: " .. var.name)
        self.entity, self.variable, self.__len = ent, var, self.__len_fn
    end
}
M.Array_Surrogate = Array_Surrogate

local tc, tcc, map = table.copy, table.concat, table.map

--[[! Class: State_Array
    Specialization of <State_Variable> for arrays. Uses <Array_Surrogate>
    to provide an array-like "interface". The surrogate is required to
    properly reflect array element changes. This is the first state
    variable object that requires more complex to_wire and from_wire
    functions.
]]
State_Array = State_Variable:clone {
    name = "State_Array",

    --[[! Variable: separator
        An element separator used by the wire format. Defaults to "|".
    ]]
    separator = "|",

    --[[! Variable: surrogate
        Specifies the surrogate used by the state variable. By default
        it's <Array_Surrogate>, but may be overriden.
    ]]
    surrogate = Array_Surrogate,

    --[[! Function: getter
        Instead of returning the raw value in non-wire format, this
        overriden getter returns the appropriate <surrogate>. It
        does not create a new surrogate each time; it's cached
        for performance reasons. Performs read tests.
    ]]
    getter = function(self, var)
        var:read_tests(self)

        if not var:get_raw(self) then return nil end

        local n = "__as_" .. var.name
        if not self[n] then self[n] = var.surrogate(self, var) end
        return self[n]
    end,

    --[[! Function: setter
        Works the same as the default setter, but if a surrogate is
        given, then it converts it to a raw array and if a table
        is given, it copies the table before setting it.
    ]]
    setter = function(self, val, var)
        log(INFO, "State_Array: setter: " .. tostring(val))
        var:write_tests(self)

        self:set_sdata(var.name,
            val.to_array and val:to_array() or tc(val), -1)
    end,

    --[[! Function: to_wire_item
        This is not a regular method, it has no self. It's called by
        <to_wire> for each value of the array before including it in
        the result.
    ]]
    to_wire_item = tostring,

    --[[! Function: from_wire_item
        This is not a regular method, it has no self. It's called by
        <from_wire> for each value of the array before including it in
        the result.
    ]]
    from_wire_item = tostring,

    --[[! Function: to_wire
        Returns the contents of the state array in a wire format. It
        starts with a "[", followed by a list of items separated by
        <separator>. It ends with a "]". The value can be either an
        array or an array surrogate.
    ]]
    to_wire = function(self, val)
        return "[" .. tcc(map(val.to_array and val:to_array() or val,
            self.to_wire_item), self.separator) .. "]"
    end,

    --[[! Function: from_wire
        Converts a string in a format given by <to_wire> back to a table.
    ]]
    from_wire = function(self, val)
        return (val == "[]") and {} or map(
            val:sub(2, #val - 1):split(self.separator), self.from_wire_item)
    end,

    --[[! Function: get_raw
        Returns the raw array of state data. Retrieved from local storage
        without syncing assuming there is either no czstin getter function
        or a sufficient cached value. Otherwise returns the result of a
        getter function call and caches it.
    ]]
    get_raw = function(self, ent)
        local vn = self.name
        log(INFO, "State_Array: get_raw: " .. vn)

        if not self.getter_fun then
            return ent.svar_values[vn] or {}
        end

        local fr = frame.get_frame()

        if (not CLIENT and ent.svar_change_queue)
            or ent.svar_value_timestamps[vn] == fr
        then
            return ent.svar_values[vn]
        end

        log(INFO, "State_Array: get_raw: getter function")

        local val = self.getter_fun(ent)

        if CLIENT or ent.svar_change_queue_complete then
            ent.svar_values[vn] = val
            ent.svar_value_timestamps[vn] = fr
        end

        return val
    end,

    --[[! Function: get_length
        Retrieves the state array length. Used by the surrogate.
    ]]
    get_length = function(self, ent)
        return #self:get_raw(ent)
    end,

    --[[! Function: get_item
        Retrieves a specific element from the state array. Used by
        the surrogate.
    ]]
    get_item = function(self, ent, idx)
        log(INFO, "State_Array: get_item: " .. idx)
        return self:get_raw(ent)[idx]
    end,

    --[[! Function: set_item
        Sets an element in the state array. Used by the surrogate. Performs
        an update on all clients by setting the state data on the entity.
    ]]
    set_item = function(self, ent, idx, val)
        log(INFO, "State_Array: set_item: " .. idx .. ", " .. tostring(val))

        local a = self:get_raw(ent)
        if type(val) == "string" then
            assert(not val:find("%" .. self.separator))
        end

        a[idx] = val
        ent:set_sdata(self.name, a, -1)
    end
}
M.State_Array = State_Array

--[[! Class: State_Array_Integer
    A variant of <State_Array> for integer contents. Overrides to_wire_item,
    which converts a value to a string and from_wire_item, which converts
    it back to an integer.
]]
State_Array_Integer = State_Array:clone {
    name = "State_Array_Integer",

    to_wire_item   = tostring,
    from_wire_item = tointeger
}
M.State_Array_Integer = State_Array_Integer

--[[! Class: State_Array_Float
    A variant of <State_Array> for floating point contents. Overrides
    to_wire_item, which converts a value to a string (with max two places
    past the floating point represented in the string) and from_wire_item,
    which converts it back to a float.
]]
State_Array_Float = State_Array:clone {
    name = "State_Array_Float",

    to_wire_item   = function(v) return tostring(round(v, 2)) end,
    from_wire_item = tonumber
}
M.State_Array_Float = State_Array_Float

--[[! Class: Vec3_Surrogate
    See <Array_Surrogate>. The only difference is that instead of emulating
    an array, it emulates <math.Vec3>. It clones it and injects it with its
    own methods.
]]
Vec3_Surrogate = math.Vec3:clone {
    name = "Vec3_Surrogate",

    --[[! Function: __tostring
        Makes surrogate objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Function: __get
        Called each time you index a vec3 surrogate. Works similarly to
        <Array_Surrogate.__get>. Valid indexes are x, y, z, 1, 2, 3.
        Otherwise, the getter has no effect.
    ]]
    __get = function(self, n)
        if n == "x" or n == 1 then
            local v = rawget(self, "variable")
            return v:get_item(rawget(self, "entity"), 1)
        elseif n == "y" or n == 2 then
            local v = rawget(self, "variable")
            return v:get_item(rawget(self, "entity"), 2)
        elseif n == "z" or n == 3 then
            local v = rawget(self, "variable")
            return v:get_item(rawget(self, "entity"), 3)
        end
    end,

    --[[! Function: __set
        Called each time you set an index on a vec3 surrogate. Works similarly
        to <Array_Surrogate.__set>. Valid indexes are x, y, z, 1, 2, 3.
        Otherwise, the setter has no effect.
    ]]
    __set = function(self, n, val)
        if n == "x" or n == 1 then
            local v = rawget(self, "variable")
            v:set_item(rawget(self, "entity"), 1, val)
            return true
        elseif n == "y" or n == 2 then
            local v = rawget(self, "variable")
            v:set_item(rawget(self, "entity"), 2, val)
            return true
        elseif n == "z" or n == 3 then
            local v = rawget(self, "variable")
            v:set_item(rawget(self, "entity"), 3, val)
            return true
        end
    end,

    --[[! Function: __len_fn
        See <Array_Surrogate.__len_fn>. In this case always returns 3.
    ]]
    __len_fn = function(self)
        return 3
    end,

    --[[! Constructor: __init
        Uses the constructor of <Array_Surrogate>.
    ]]
    __init = Array_Surrogate.__init
}
M.Vec3_Surrogate = Vec3_Surrogate

--[[! Class: Vec4_Surrogate
    See <Array_Surrogate>. The only difference is that instead of emulating
    an array, it emulates <math.Vec4>. It clones it and injects it with its
    own methods.
]]
Vec4_Surrogate = math.Vec4:clone {
    name = "Vec4_Surrogate",

    --[[! Function: __tostring
        Makes surrogate objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Function: __get
        Called each time you index a vec4 surrogate. Works similarly to
        <Array_Surrogate.__get>. Valid indexes are x, y, z, w, 1, 2, 3, 4.
        Otherwise, the getter has no effect.
    ]]
    __get = function(self, n)
        if n == "x" or n == 1 then
            local v = rawget(self, "variable")
            return v:get_item(rawget(self, "entity"), 1)
        elseif n == "y" or n == 2 then
            local v = rawget(self, "variable")
            return v:get_item(rawget(self, "entity"), 2)
        elseif n == "z" or n == 3 then
            local v = rawget(self, "variable")
            return v:get_item(rawget(self, "entity"), 3)
        elseif n == "w" or n == 4 then
            local v = rawget(self, "variable")
            return v:get_item(rawget(self, "entity"), 4)
        end
    end,

    --[[! Function: __set
        Called each time you set an index on a vec4 surrogate. Works similarly
        to <Array_Surrogate.__set>. Valid indexes are x, y, z, w, 1, 2, 3, 4.
        Otherwise, the setter has no effect.
    ]]
    __set = function(self, n, val)
        if n == "x" or n == 1 then
            local v = rawget(self, "variable")
            v:set_item(rawget(self, "entity"), 1, val)
            return true
        elseif n == "y" or n == 2 then
            local v = rawget(self, "variable")
            v:set_item(rawget(self, "entity"), 2, val)
            return true
        elseif n == "z" or n == 3 then
            local v = rawget(self, "variable")
            v:set_item(rawget(self, "entity"), 3, val)
            return true
        elseif n == "w" or n == 4 then
            local v = rawget(self, "variable")
            v:set_item(rawget(self, "entity"), 4, val)
            return true
        end
    end,

    --[[! Function: __len_fn
        See <Array_Surrogate.__len_fn>. In this case always returns 4.
    ]]
    __len_fn = function(self)
        return 4
    end,

    --[[! Constructor: __init
        Uses the constructor of <Array_Surrogate>.
    ]]
    __init = Array_Surrogate.__init
}
M.Vec4_Surrogate = Vec4_Surrogate

--[[! Class: State_Vec3
    A specialization of <State_Array_Float>, providing its own surrogate,
    <Vec3_Surrogate>. Other than that, no changes are made.
]]
State_Vec3 = State_Array_Float:clone {
    name = "State_Vec3",
    surrogate = Vec3_Surrogate
}
M.State_Vec3 = State_Vec3

--[[! Class: State_Vec4
    A specialization of <State_Array_Float>, providing its own surrogate,
    <Vec4_Surrogate>. Other than that, no changes are made.
]]
State_Vec4 = State_Array_Float:clone {
    name = "State_Vec4",
    surrogate = Vec3_Surrogate
}
M.State_Vec4 = State_Vec4

--[[! Class: State_Variable_Alias
    Aliases a state variable. Aliases are always registered last so that
    the variables they alias are already registered. They provide alternative
    getters and setters.
]]
State_Variable_Alias = State_Variable:clone {
    name = "State_Variable_Alias",

    --[[! Constructor: __init
        Variable aliases don't really need all the properties, so the parent
        constructor is never called. They have one property, target_name,
        given by the constructor argument, which specifies the name of
        the state variable they point to.
    ]]
    __init = function(self, tname)
        self.target_name = tname
    end,

    --[[! Function: register
        Overriden registration function. It simply sets up the alias
        getter and setter. It also creates the _SV_ prefixed raw accessor
        pointing to the target var.
    ]]
    register = function(self, name, parent)
        log(DEBUG, "State_Variable_Alias: register(" .. name
            .. ", " .. tostring(parent) .. ")")

        self.name = name
    
        local tg = parent["_SV_" .. self.target_name]
        parent["_SV_" .. name] = tg

        log(DEBUG, "State_Variable_Alias: register: getter/setter")
        parent:define_getter(name, tg.getter, tg)
        parent:define_setter(name, tg.setter, tg)
    end
}
M.State_Variable_Alias = State_Variable_Alias

return M
