--[[! File: lua/core/entities/svars.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Implements "state variables". State variables are basically entity
        properties. They mimick real property behavior. They automatically
        sync changes between clients/server as required. They can be of
        various types and new svar types are easily implementable.
]]

local capi = require("capi")
local logging = require("core.logger")
local log = logging.log
local DEBUG = logging.DEBUG
local INFO  = logging.INFO

local frame = require("core.events.frame")
local math2 = require("core.lua.math")
local table2 = require("core.lua.table")

local tostring, tonumber, abs, round, floor, rawget = tostring, tonumber,
    math.abs, math2.round, math.floor, rawget

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

local define_accessors = function(cl, n, gf, sf, d)
    cl["__get_" .. n] = function(self)
        return gf(self, d)
    end
    cl["__set_" .. n] = function(self, v)
        return sf(self, v, d)
    end
end

--[[! Class: State_Variable
    Provides a base object for a state variable. Specialized svar types
    clone this and define their own methods.
]]
State_Variable = table2.Object:clone {
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
        --@D log(INFO, "State_Variable: init")

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
        Registers the state variable, given an entity class. It'll create
        getter and setter methods on the entity class for the given name
        and also for alt_name if set in constructor kwargs. You can access
        the raw state variable on the entity class by prefixing it with
        _SV. You can access the variable by gui_name by prefixing it with
        _SV_GUI_ (if gui_name is not defined, regular name is used).
    ]]
    register = function(self, name, cl)
        --@D log(DEBUG, "State_Variable: register(" .. name
        --@D     .. ", " .. cl.name .. ")")

        self.name = name
        cl["_SV_" .. name] = self

        assert(self.getter)
        assert(self.setter)

        --@D log(DEBUG, "State_Variable: register: getter/setter")
        define_accessors(cl, name, self.getter, self.setter, self)

        local an = self.alt_name
        if an then
            --@D log(DEBUG, "State_Variable: register: alt getter/setter")
            cl["_SV_" .. an] = self
            define_accessors(cl, an, self.getter, self.setter, self)
        end
        cl["_SV_GUI_" .. (self.gui_name or name)] = self

        local gf, sf = self.getter_fun, self.setter_fun
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
                 " of a deactivated entity " .. ent.name ..
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
        --@D log(INFO, "State_Variable: getter: " .. vn)

        local fr = frame.get_frame()

        if not var.getter_fun
            or (SERVER and self.svar_change_queue)
            or self.svar_value_timestamps[vn] == fr
        then
            return self.svar_values[vn]
        end

        --@D log(INFO, "State_Variable: getter: getter function")

        local val = var.getter_fun(self)

        if not SERVER or self.svar_change_queue_complete then
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

    to_wire   = function(self, val) return tostring(val) end,
    from_wire = function(self, val) return floor(tonumber(val)) end
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

    to_wire   = function(self, val) return tostring(val) end,
    from_wire = function(self, val) return val == "true" and true or false end
}
M.State_Boolean = State_Boolean

local ts, td = table2.serialize, table2.deserialize

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

local ctable = capi.table_create
local getmt, setmt = getmetatable, setmetatable
local newproxy = newproxy

--[[! Class: Array_Surrogate
    Represents a "surrogate" for an array. Behaves like a regular
    array, but does not actually contain anything; it merely serves
    as an interface for state variables like <State_Array>.

    You can manipulate this like a regular array (check its length,
    index it, assign indexes) but many of the functions from the
    table library likely won't work.

    Note that surrogates are not regular objects created using the
    prototypal system. They're manually managed with metatables and
    proxies in order to gain features such as __len under Lua 5.1 and
    you have to instantiate them yourself (well, you mostly don't, as
    the entity does it for you).
]]
Array_Surrogate = {
    name = "Array_Surrogate",

    --[[! Constructor: new
        Constructs the array surrogate. Defines its members "entity"
        and "variable", assigned using the provided arguments.
    ]]
    new = function(self, ent, var)
        --@D log(INFO, "Array_Surrogate: new: " .. var.name)
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

    --[[! Function: __tostring
        Makes surrogate objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Function: __index
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
        if i ~= n then
            return Array_Surrogate[name] or rawget(self.rawt, name)
        end

        local v = self.variable
        return v:get_item(self.entity, i)
    end,

    --[[! Function: __newindex
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
        if i ~= n then return rawset(self.rawt, name, val) end

        local v = self.variable
        v:set_item(self.entity, i, val)
    end,

    --[[! Function: __len
        Returns the length of the "array" represented by the state variable.
    ]]
    __len = function(self)
        local v = self.variable
        return v:get_length(self.entity)
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

    --[[! Function: append
        Appends an element. For convenience only (foo:get_array():append(...)).
    ]]
    append = function(self, v)
        self[#self + 1] = v
    end
}
M.Array_Surrogate = Array_Surrogate

local tc, tcc, map = table2.copy, table.concat, table2.map

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
        if not self[n] then self[n] = var.surrogate:new(self, var) end
        return self[n]
    end,

    --[[! Function: setter
        Works the same as the default setter, but if a surrogate is
        given, then it converts it to a raw array and if a table
        is given, it copies the table before setting it.
    ]]
    setter = function(self, val, var)
        --@D log(INFO, "State_Array: setter: " .. tostring(val))
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
        --@D log(INFO, "State_Array: get_raw: " .. vn)

        if not self.getter_fun then
            return ent.svar_values[vn] or {}
        end

        local fr = frame.get_frame()

        if (SERVER and ent.svar_change_queue)
            or ent.svar_value_timestamps[vn] == fr
        then
            return ent.svar_values[vn]
        end

        --@D log(INFO, "State_Array: get_raw: getter function")

        local val = self.getter_fun(ent)

        if not SERVER or ent.svar_change_queue_complete then
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
        --@D log(INFO, "State_Array: get_item: " .. idx)
        return self:get_raw(ent)[idx]
    end,

    --[[! Function: set_item
        Sets an element in the state array. Used by the surrogate. Performs
        an update on all clients by setting the state data on the entity.
    ]]
    set_item = function(self, ent, idx, val)
        --@D log(INFO, "State_Array: set_item: " .. idx .. ", "
        --@D     .. tostring(val))

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
    from_wire_item = function(v) return floor(tonumber(v)) end
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

local Vec3 = math2.Vec3
local vec3_index = math2.__Vec3_mt.__index

--[[! Class: Vec3_Surrogate
    See <Array_Surrogate>. The only difference is that instead of emulating
    an array, it emulates <math.Vec3>.
]]
Vec3_Surrogate = {
    name = "Vec3_Surrogate",

    --[[! Constructor: new
        Constructs the vec3 surrogate. Defines its members "entity"
        and "variable", assigned using the provided arguments.
    ]]
    new = function(self, ent, var)
        --@D log(INFO, "Vec3_Surrogate: new: " .. var.name)
        local rawt = { entity = ent, variable = var }
        rawt.rawt = rawt
        local ret = newproxy(true)
        local mt  = getmt(ret)
        mt.__tostring = self.__tostring
        mt.__index    = setmt(rawt, self)
        mt.__newindex = self.__newindex
        mt.__len      = self.__len
        return ret
    end,

    --[[! Function: __tostring
        Makes surrogate objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Function: __index
        Called each time you index a vec3 surrogate. Works similarly to
        <Array_Surrogate.__index>. Valid indexes are x, y, z, 1, 2, 3.
    ]]
    __index = function(self, n)
        if n == "x" or n == 1 then
            local v = self.variable
            return v:get_item(self.entity, 1)
        elseif n == "y" or n == 2 then
            local v = self.variable
            return v:get_item(self.entity, 2)
        elseif n == "z" or n == 3 then
            local v = self.variable
            return v:get_item(self.entity, 3)
        end
        return Vec3_Surrogate[n] or rawget(self.rawt, n)
    end,

    --[[! Function: __newindex
        Called each time you set an index on a vec3 surrogate. Works similarly
        to <Array_Surrogate.__newindex>. Valid indexes are x, y, z, 1, 2, 3.
    ]]
    __newindex = function(self, n, val)
        if n == "x" or n == 1 then
            local v = self.variable
            v:set_item(self.entity, 1, val)
        elseif n == "y" or n == 2 then
            local v = self.variable
            v:set_item(self.entity, 2, val)
        elseif n == "z" or n == 3 then
            local v = self.variable
            v:set_item(self.entity, 3, val)
        else
            rawset(self.rawt, n, val)
        end
    end,

    --[[! Function: __len
        See <Array_Surrogate.__len>. In this case always returns 3.
    ]]
    __len = function(self)
        return 3
    end,

    copy = function(self)
        return Vec3(self.x, self.y, self.z)
    end,

    length = vec3_index.length,
    normalize = vec3_index.normalize,
    cap = vec3_index.cap,
    sub_new = vec3_index.sub_new,
    add_new = vec3_index.add_new,
    mul_new = vec3_index.mul_new,
    sub = vec3_index.sub,
    add = vec3_index.add,
    mul = vec3_index.mul,
    to_array = vec3_index.to_array,
    from_yaw_pitch = vec3_index.from_yaw_pitch,
    to_yaw_pitch = vec3_index.to_yaw_pitch,
    is_close_to = vec3_index.is_close_to,
    dot_product = vec3_index.dot_product,
    cross_product = vec3_index.cross_product,
    project_along_surface = vec3_index.project_along_surface,
    lerp = vec3_index.lerp,
    is_zero = vec3_index.is_zero,

    __sub = vec3_index.sub_new,
    __add = vec3_index.add_new,
    __mul = vec3_index.mul_new
}
M.Vec3_Surrogate = Vec3_Surrogate

local Vec4 = math2.Vec4
local vec4_index = math2.__Vec4_mt.__index

--[[! Class: Vec4_Surrogate
    See <Array_Surrogate>. The only difference is that instead of emulating
    an array, it emulates <math.Vec4>.
]]
Vec4_Surrogate = {
    name = "Vec4_Surrogate",

    --[[! Constructor: new
        Constructs the vec4 surrogate. Defines its members "entity"
        and "variable", assigned using the provided arguments.
    ]]
    new = function(self, ent, var)
        --@D log(INFO, "Vec4_Surrogate: new: " .. var.name)
        local rawt = { entity = ent, variable = var }
        rawt.rawt = rawt
        local ret = newproxy(true)
        local mt  = getmt(ret)
        mt.__tostring = self.__tostring
        mt.__index    = setmt(rawt, self)
        mt.__newindex = self.__newindex
        mt.__len      = self.__len
        return ret
    end,

    --[[! Function: __tostring
        Makes surrogate objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Function: __index
        Called each time you index a vec4 surrogate. Works similarly to
        <Vec3_Surrogate.__index>. Valid indexes are x, y, z, w, 1, 2, 3, 4.
    ]]
    __index = function(self, n)
        if n == "x" or n == 1 then
            local v = self.variable
            return v:get_item(self.entity, 1)
        elseif n == "y" or n == 2 then
            local v = self.variable
            return v:get_item(self.entity, 2)
        elseif n == "z" or n == 3 then
            local v = self.variable
            return v:get_item(self.entity, 3)
        elseif n == "w" or n == 4 then
            local v = self.variable
            return v:get_item(self.entity, 4)
        end
        return Vec4_Surrogate[n] or rawget(self.rawt, n)
    end,

    --[[! Function: __newindex
        Called each time you set an index on a vec3 surrogate. Works similarly
        to <Vec3_Surrogate.__newindex>. Valid indexes are x, y, z, w,
        1, 2, 3, 4.
    ]]
    __newindex = function(self, n, val)
        if n == "x" or n == 1 then
            local v = self.variable
            v:set_item(self.entity, 1, val)
        elseif n == "y" or n == 2 then
            local v = self.variable
            v:set_item(self.entity, 2, val)
        elseif n == "z" or n == 3 then
            local v = self.variable
            v:set_item(self.entity, 3, val)
        elseif n == "w" or n == 4 then
            local v = self.variable
            v:set_item(self.entity, 4, val)
        else
            rawset(self.rawt, n, val)
        end
    end,

    --[[! Function: __len
        See <Array_Surrogate.__len>. In this case always returns 4.
    ]]
    __len = function(self)
        return 4
    end,

    copy = function(self)
        return Vec4(self.x, self.y, self.z, self.w)
    end,

    length = vec4_index.length,
    normalize = vec4_index.normalize,
    cap = vec4_index.cap,
    sub_new = vec4_index.sub_new,
    add_new = vec4_index.add_new,
    mul_new = vec4_index.mul_new,
    sub = vec4_index.sub,
    add = vec4_index.add,
    mul = vec4_index.mul,
    to_array = vec4_index.to_array,
    from_yaw_pitch = vec4_index.from_yaw_pitch,
    to_yaw_pitch = vec4_index.to_yaw_pitch,
    to_yaw_pitch_roll = vec4_index.to_yaw_pitch_roll,
    is_close_to = vec4_index.is_close_to,
    dot_product = vec4_index.dot_product,
    cross_product = vec4_index.cross_product,
    project_along_surface = vec4_index.project_along_surface,
    lerp = vec4_index.lerp,
    is_zero = vec4_index.is_zero,

    __sub = vec4_index.sub_new,
    __add = vec4_index.add_new,
    __mul = vec4_index.mul_new
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
    register = function(self, name, cl)
        --@D log(DEBUG, "State_Variable_Alias: register(" .. name
        --@D     .. ", " .. cl.name .. ")")

        self.name = name
        local tg = cl["_SV_" .. self.target_name]
        cl["_SV_" .. name] = tg

        --@D log(DEBUG, "State_Variable_Alias: register: getter/setter")
        define_accessors(cl, name, self.getter, self.setter, self)
    end
}
M.State_Variable_Alias = State_Variable_Alias

return M
