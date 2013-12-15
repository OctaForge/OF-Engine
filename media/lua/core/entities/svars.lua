--[[!<
    Implements "state variables". State variables are basically entity
    properties. They mimick real property behavior. They automatically
    sync changes between clients/server as required. They can be of
    various types and new svar types are easily implementable.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")
local logging = require("core.logger")
local log = logging.log
local DEBUG = logging.DEBUG
local INFO  = logging.INFO

local frame = require("core.events.frame")
local math2 = require("core.lua.math")
local geom  = require("core.lua.geom")
local table2 = require("core.lua.table")

local tostring, tonumber, abs, round, floor, rawget = tostring, tonumber,
    math.abs, math2.round, math.floor, rawget

    --! Module: svars
local M = {}

local State_Variable, State_Variable_Alias, State_Integer, State_Float,
      State_Boolean, State_Table, State_String, Array_Surrogate, State_Array,
      State_Array_Integer, State_Array_Float

--! Checks whether the given value is a state variable.
M.is_svar = function(v)
    return (type(v) == "table" and v.is_a) and v:is_a(State_Variable)
end

--! Checks whether the given value is a state variable alias.
M.is_svar_alias = function(v)
    return (type(v) == "table" and v.is_a) and v:is_a(State_Variable_Alias)
end

local define_accessors = function(cl, n, gf, sf, d)
    cl["__get_" .. n] = function(self)
        return gf(self, d)
    end
    cl["__set_" .. n] = function(self, v)
        return sf(self, v, d)
    end
end

--[[!
    Provides a base object for a state variable. Specialized svar types
    clone this and define their own methods. Fields can be initialized via
    kwargs.

    Fields:
        - client_read [true] - clients can read the value.
        - client_write [true] - the value can be written clientside
          (indirectly through a server message).
        - client_set [false] - the value can be written clientside
          directly without a server message.
        - client_private [false] - the value will be private to the client,
          other clients won't see it (but the server will).
        - custom_sync [false] - the state variable will use a custom sync
          method (useful for Cube 2 dynents).
        - gui_name [nil] - the name shown in the editing GUI for the svar.
          Can be set to false to hide it from the editing GUI completely.
        - alt_name [nil] - an alternative accessor name.
        - reliable [true] - the messages sent for this svar will be reliable,
          that is, always sent; you cannot send a big number of them. For
          e.g. position updates, you're better off with unreliable messages
          that do not need to be sent all the time.
        - has_history [true] - the var will retain its state and e.g.
          when a new client requests it, it'll receive the values set
          previously (even if set long before the connection).
        - getter_fun [nil] - provided in kwargs as just "getter", a custom
          getter for the state var, used typically with C functions (to handle
          C-side entity changes), takes one argument, an entity this state
          var belongs to.
        - setter_fun [nil] - provided in kwargs as just "setter", a custom
          setter similar to getter. Takes two arguments, the entity and the
          value we're setting. Note that even with getter and setter functions
          the value will be cached for better performance (so we don't always
          have to query).
]]
M.State_Variable = table2.Object:clone {
    name = "State_Variable",

    --! Makes svar objects return their name on tostring.
    __tostring = function(self)
        return self.name
    end,

    --! Initializes the svar. Parameters are passed in kwargs (a dict).
    __ctor = function(self, kwargs)
        debug then log(INFO, "State_Variable: init")

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

    --[[!
        Registers the state variable, given an entity class. It'll create
        getter and setter methods on the entity class for the given name
        and also for `alt_name` if set in constructor kwargs. You can access
        the raw state variable on the entity class by prefixing it with
        `_SV`. You can access the variable by gui_name by prefixing it with
        `_SV_GUI_` (if `gui_name` is not defined, regular name is used, if
        `gui_name` is false, this field won't exist at all).

        Arguments:
            - name - the state var name.
            - cl - the entity class.
    ]]
    register = function(self, name, cl)
        debug then log(DEBUG, "State_Variable: register(" .. name
            .. ", " .. cl.name .. ")")

        self.name = name
        cl["_SV_" .. name] = self

        assert(self.getter)
        assert(self.setter)

        debug then log(DEBUG, "State_Variable: register: getter/setter")
        define_accessors(cl, name, self.getter, self.setter, self)

        local an = self.alt_name
        if an then
            debug then log(DEBUG, "State_Variable: register: alt g/s")
            cl["_SV_" .. an] = self
            define_accessors(cl, an, self.getter, self.setter, self)
        end
        local gn = self.gui_name
        if gn != false then
            cl["_SV_GUI_" .. (gn or name)] = self
        end
    end,

    --[[!
        Performs clientside svar read tests. On the server we can always
        read, on the client we can't if client_read is false. Fails an
        assertion if on the client and client_read is false.
    ]]
    read_tests = function(self, ent)
        assert(self.client_read or SERVER)
    end,

    --[[!
        Performs clientside svar write tests. On the server we can always
        write, on the client we can't if client_write is false. Fails an
        assertion if on the client and client_read is false (or if an
        entity is deactivated/uninitialized).
    ]]
    write_tests = function(self, ent)
        if ent.deactivated then
            assert(false, "Writing a field " .. self.name ..
                 " of a deactivated entity " .. ent.name ..
                 "(" .. ent.uid .. ")")
        end

        assert(self.client_write or SERVER)
        assert(ent.initialized)
    end,

    --[[!
        Default getter for a state variable. Works on an entity (which
        is self here). It mostly simply returns the value from an internal
        table. It performs read tests.

        Note that if custom getter function is provided in the constructor's
        kwargs and no sufficient value is cached, it'll return the value
        the getter function returns (and it'll also save into the cache
        for further use).

        Arguments:
            - self - not the state var, it's an entity.
            - var - the state var.
    ]]
    getter = function(self, var)
        var:read_tests(self)

        local vn = var.name
        debug then log(INFO, "State_Variable: getter: " .. vn)

        local fr = frame.get_frame()

        if not var.getter_fun
            or (SERVER and self.svar_change_queue)
            or self.svar_value_timestamps[vn] == fr
        then
            return self.svar_values[vn]
        end

        debug then log(INFO, "State_Variable: getter: getter function")

        local val = var.getter_fun(self.uid)

        if not SERVER or self.svar_change_queue_complete then
            self.svar_values[vn] = val
            self.svar_value_timestamps[vn] = fr
        end

        return val
    end,

    --[[!
        Default setter for a state variable. It simply sets state data.

        Arguments:
            - self - not the state var, it's an entity.
            - val - the value.
            - var - the state var.
    ]]
    setter = function(self, val, var)
        var:write_tests(self)
        self:set_sdata(var.name, val, -1)
    end,

    --[[!
        Validates a state variable value. The default simply returns
        true. Can be overriden.
    ]]
    validate = function(self, val) return true end,

    --[[!
        Checks whether changes of this variable should be synced with other
        clients. Returns true if this variable is not client_private or if the
        target client number equals the client number of the given entity.

        Arguments:
            - ent - the entity.
            - tcn - target client number.
    ]]
    should_send = function(self, ent, tcn)
        return (not self.client_private) or (ent.cn == tcn)
    end,

    --[[!
        Converts the given value to wire format for this state variable.
        It's a string meant for final network transmission. On the other
        side it's simply converted back to the original format using
        $from_wire. By default simply converts to string.
    ]]
    to_wire = function(self, val)
        return tostring(val)
    end,

    --[[!
        Converts the given value in wire format back to the original
        format. See $to_wire. By default simply returns a string.
    ]]
    from_wire = function(self, val)
        return tostring(val)
    end
}
State_Variable = M.State_Variable

--[[!
    Specialization of $State_Variable for integer values. Overrides
    to_ and from_ wire appropriately, to_wire converts to a string,
    from_wire converts to an integer.
]]
M.State_Integer = State_Variable:clone {
    name = "State_Integer",

    to_wire   = function(self, val) return tostring(val) end,
    from_wire = function(self, val) return floor(tonumber(val)) end
}
State_Integer = M.State_Integer

--[[!
    Specialization of $State_Variable for float values. Overrides
    to_ and from_ wire appropriately, to_wire converts to a string
    (with max two places past the floating point represented in the
    string), from_wire converts to a float.
]]
M.State_Float = State_Variable:clone {
    name = "State_Float",

    to_wire   = function(self, val) return tostring(round(val, 2)) end,
    from_wire = function(self, val) return tonumber(val) end
}
State_Float = M.State_Float

--[[!
    Specialization of $State_Variable for boolean values. Overrides
    to_ and from_ wire appropriately, to_wire converts to a string,
    from_wire converts to a boolean.
]]
M.State_Boolean = State_Variable:clone {
    name = "State_Boolean",

    to_wire   = function(self, val) return tostring(val) end,
    from_wire = function(self, val) return val == "true" and true or false end
}
State_Boolean = M.State_Boolean

local ts, td = table2.serialize, table2.deserialize

--[[!
    Specialization of $State_Variable for table values. Overrides
    to_ and from_ wire appropriately, to_wire serializes the given
    table, from_wire deserializes it.
]]
M.State_Table = State_Variable:clone {
    name = "State_Table",

    to_wire   = function(self, val) return ts(val) end,
    from_wire = function(self, val) return td(val) end
}
State_Table = M.State_Table

--[[!
    Specialization of $State_Variable for string values. Doesn't
    override to_ and from_wire, because the defaults already work
    with strings.
]]
M.State_String = State_Variable:clone {
    name = "State_String"
}
State_String = M.State_String

local ctable = capi.table_create
local getmt, setmt = getmetatable, setmetatable
local newproxy = newproxy

--[[!
    Represents a "surrogate" for an array. Behaves like a regular
    array, but does not actually contain anything; it merely serves
    as an interface for state variables like $State_Array.

    You can manipulate this like a regular array (check its length,
    index it, assign indexes) but many of the functions from the
    table library likely won't work.

    Note that surrogates are not regular objects created using the
    prototypal system. They're manually managed with metatables and
    proxies in order to gain features such as __len under Lua 5.1 and
    you have to instantiate them yourself (well, you mostly don't, as
    the entity does it for you).
]]
M.Array_Surrogate = {
    name = "Array_Surrogate",

    --[[!
        Constructs the array surrogate. Defines its members "entity"
        and "variable", assigned using the provided arguments.
    ]]
    new = function(self, ent, var)
        debug then log(INFO, "Array_Surrogate: new: " .. var.name)
        local rawt = { entity = ent, variable = var }
        rawt.rawt = rawt -- yay! cycles!
        local ret = newproxy(true)
        local mt  = getmt(ret)
        mt.__tostring = self.__tostring
        mt.__index    = setmt(rawt, self)
        mt.__newindex = self.__newindex
        mt.__len      = self.__len
        return ret
    end,

    --! Makes surrogate objects return their names on tostring.
    __tostring = function(self)
        return self.name
    end,

    --[[!
        Called each time you index an array surrogate. It checks
        the validity of the given index by converting it to a number
        and flooring it. On invalid indexes, it simply fallbacks to
        regular indexing.
    ]]
    __index = function(self, name)
        local n = tonumber(name)
        if not n then
            return Array_Surrogate[name] or rawget(self.rawt, name)
        end
        local i = floor(n)
        if i != n then
            return Array_Surrogate[name] or rawget(self.rawt, name)
        end

        local v = self.variable
        return v:get_item(self.entity, i)
    end,

    --[[!
        Called each time you set an index on an array surrogate. It checks
        the validity of the given index by converting it to a number and
        flooring it. If the given index is not an integer, this fallbacks
        to regular setting. Otherwise sets the corresponding element using
        the state variable.
    ]]
    __newindex = function(self, name, val)
        local n = tonumber(name)
        if not n then return rawset(self.rawt, name, val) end
        local i = floor(n)
        if i != n then return rawset(self.rawt, name, val) end

        local v = self.variable
        v:set_item(self.entity, i, val)
    end,

    --! Returns the length of the "array" represented by the state variable.
    __len = function(self)
        local v = self.variable
        return v:get_length(self.entity)
    end,

    --! Returns a raw array of values stored using the state variable.
    to_array = function(self)
        local l = #self
        local r = ctable(l)
        for i = 1, l do
            r[#r + 1] = self[i]
        end
        return r
    end,

    --! Appends an element. For convenience only.
    append = function(self, v)
        self[#self + 1] = v
    end
}
Array_Surrogate = M.Array_Surrogate

local tc, tcc, map = table2.copy, table.concat, table2.map

--[[!
    Specialization of <State_Variable> for arrays. Uses $Array_Surrogate
    to provide an array-like "interface". The surrogate is required to
    properly reflect array element changes. This is the first state
    variable object that requires more complex to_wire and from_wire
    functions.
]]
M.State_Array = State_Variable:clone {
    name = "State_Array",

    --! An element separator used by the wire format. Defaults to "|".
    separator = "|",

    --[[!
        Specifies the surrogate used by the state variable. By default
        it's $Array_Surrogate, but may be overriden.
    ]]
    surrogate = Array_Surrogate,

    --[[!
        Instead of returning the raw value in non-wire format, this
        overriden getter returns the appropriate $surrogate. It
        does not create a new surrogate each time; it's cached
        for performance reasons. Performs read tests.

        See also:
            - {{$State_Variable.getter}}
    ]]
    getter = function(self, var)
        var:read_tests(self)

        if not var:get_raw(self) then return nil end

        local n = "__as_" .. var.name
        if not self[n] then self[n] = var.surrogate:new(self, var) end
        return self[n]
    end,

    --[[!
        Works the same as the default setter, but if a surrogate is
        given, then it converts it to a raw array and if a table
        is given, it copies the table before setting it.

        See also:
            - {{$State_Variable.setter}}
    ]]
    setter = function(self, val, var)
        debug then log(INFO, "State_Array: setter: " .. tostring(val))
        var:write_tests(self)

        self:set_sdata(var.name,
            val.to_array and val:to_array() or tc(val), -1)
    end,

    --[[! Function: to_wire_item
        This is not a regular method, it has no self. It's called by
        $to_wire for each value of the array before including it in
        the result.
    ]]
    to_wire_item = tostring,

    --[[! Function: from_wire_item
        This is not a regular method, it has no self. It's called by
        $from_wire for each value of the array before including it in
        the result.
    ]]
    from_wire_item = tostring,

    --[[!
        Returns the contents of the state array in a wire format. It
        starts with a "[", followed by a list of items separated by
        $separator. It ends with a "]". The value can be either an
        array or an array surrogate.
    ]]
    to_wire = function(self, val)
        return "[" .. tcc(map(val.to_array and val:to_array() or val,
            self.to_wire_item), self.separator) .. "]"
    end,

    --! Converts a string in a format given by $to_wire back to a table.
    from_wire = function(self, val)
        return (val == "[]") and {} or map(
            val:sub(2, #val - 1):split(self.separator), self.from_wire_item)
    end,

    --[[!
        Returns the raw array of state data. Retrieved from local storage
        without syncing assuming there is either no czstin getter function
        or a sufficient cached value. Otherwise returns the result of a
        getter function call and caches it.
    ]]
    get_raw = function(self, ent)
        local vn = self.name
        debug then log(INFO, "State_Array: get_raw: " .. vn)

        if not self.getter_fun then
            return ent.svar_values[vn] or {}
        end

        local fr = frame.get_frame()

        if (SERVER and ent.svar_change_queue)
            or ent.svar_value_timestamps[vn] == fr
        then
            return ent.svar_values[vn]
        end

        debug then log(INFO, "State_Array: get_raw: getter function")

        local val = self.getter_fun(ent.uid)

        if not SERVER or ent.svar_change_queue_complete then
            ent.svar_values[vn] = val
            ent.svar_value_timestamps[vn] = fr
        end

        return val
    end,

    --! Retrieves the state array length. Used by the surrogate.
    get_length = function(self, ent)
        return #self:get_raw(ent)
    end,

    --[[!
        Retrieves a specific element from the state array. Used by
        the surrogate.
    ]]
    get_item = function(self, ent, idx)
        debug then log(INFO, "State_Array: get_item: " .. idx)
        return self:get_raw(ent)[idx]
    end,

    --[[!
        Sets an element in the state array. Used by the surrogate. Performs
        an update on all clients by setting the state data on the entity.
    ]]
    set_item = function(self, ent, idx, val)
        debug then log(INFO, "State_Array: set_item: " .. idx .. ", "
            .. tostring(val))

        local a = self:get_raw(ent)
        if type(val) == "string" then
            assert(not val:find("%" .. self.separator))
        end

        a[idx] = val
        ent:set_sdata(self.name, a, -1)
    end
}
State_Array = M.State_Array

--[[!
    A variant of $State_Array for integer contents. Overrides to_wire_item,
    which converts a value to a string and from_wire_item, which converts
    it back to an integer.
]]
M.State_Array_Integer = State_Array:clone {
    name = "State_Array_Integer",

    to_wire_item   = tostring,
    from_wire_item = function(v) return floor(tonumber(v)) end
}
State_Array_Integer = M.State_Array_Integer

--[[!
    A variant of $State_Array for floating point contents. Overrides
    to_wire_item, which converts a value to a string (with max two places
    past the floating point represented in the string) and from_wire_item,
    which converts it back to a float.
]]
M.State_Array_Float = State_Array:clone {
    name = "State_Array_Float",

    to_wire_item   = function(v) return tostring(round(v, 2)) end,
    from_wire_item = tonumber
}
State_Array_Float = M.State_Array_Float

--[[!
    A specialization of State_Array_Float, providing its own surrogate,
    {{$geom.Vec2_Surrogate}}. Other than that, no changes are made.
]]
M.State_Vec2 = State_Array_Float:clone {
    name = "State_Vec2",
    surrogate = geom.Vec2_Surrogate
}

--[[!
    A specialization of State_Array_Float, providing its own surrogate,
    {{$geom.Vec3_Surrogate}}. Other than that, no changes are made.
]]
M.State_Vec3 = State_Array_Float:clone {
    name = "State_Vec3",
    surrogate = geom.Vec3_Surrogate
}

--[[!
    A specialization of State_Array_Float, providing its own surrogate,
    {{$geom.Vec4_Surrogate}}. Other than that, no changes are made.
]]
M.State_Vec4 = State_Array_Float:clone {
    name = "State_Vec4",
    surrogate = geom.Vec4_Surrogate
}

--[[!
    Aliases a state variable. Aliases are always registered last so that
    the variables they alias are already registered. They provide alternative
    getters and setters.
]]
State_Variable_Alias = State_Variable:clone {
    name = "State_Variable_Alias",

    --[[!
        Variable aliases don't really need all the properties, so the parent
        constructor is never called. They have one property, target_name,
        given by the constructor argument, which specifies the name of
        the state variable they point to.
    ]]
    __ctor = function(self, tname)
        self.target_name = tname
    end,

    --[[!
        Overriden registration function. It simply sets up the alias
        getter and setter. It also creates the _SV_ prefixed raw accessor
        pointing to the target var. See {{$State_Variable.register}}.
    ]]
    register = function(self, name, cl)
        debug then log(DEBUG, "State_Variable_Alias: register(" .. name
            .. ", " .. cl.name .. ")")

        self.name = name
        local tg = cl["_SV_" .. self.target_name]
        cl["_SV_" .. name] = tg

        debug then log(DEBUG, "State_Variable_Alias: register: getter/setter")
        define_accessors(cl, name, self.getter, self.setter, self)
    end
}
M.State_Variable_Alias = State_Variable_Alias

return M
