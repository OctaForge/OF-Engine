--[[!
    File: base/base_svars.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features state variable system.
]]

--[[!
    Package: state_variables
    This module controls state variables. Those are usually representing entity properties.
    Their values can be transferred through client/server system and they handle "state"
    (thus the name)
]]
module("state_variables", package.seeall)

--[[!
    Function: get_on_modify_name
    Gets "on modify" name for state variables on either client or server.
    Useful for connecting "on modify" signal callbacks to state variables.

    Parameters:
        name - name of the state variable.

    Returns:
        "client_on_modify_NAME" on client and "on_modify_NAME" on server.
]]
function get_on_modify_name(name)
    if CLIENT then
        return "client_on_modify_%(1)s" % { name }
    else
        return "on_modify_%(1)s" % { name }
    end
end

--[[!
    Function: is_state_variable
    Returns true if given argument is state variable
    instance and false if it isn't.
]]
function is_state_variable(c)
    return type(c) == "table" and c.is_a and c:is_a(state_variable)
end

--[[!
    Function: is_state_variable_alias
    Returns true if given argument is state variable
    alias instance and false if it isn't.
]]
function is_state_variable_alias(c)
    return type(c) == "table" and c.is_a and c:is_a(variable_alias)
end

--[[!
    Variable: _SV_PREFIX
    This is used as prefix for raw state variable members in entity class.
    We use this, because when we access directly state variable name in
    the class, it calls getter and thus gets the actual value - we use this
    when we want to get raw state variable instance for further manipulation.
]]
_SV_PREFIX = "_SV_"

--[[!
    Function: __get
    Gets a raw state variable for an entity of given unique ID.

    Parameters:
        uid - unique ID of the entity.
        sv_name - state variable name.
]]
function __get(uid, sv_name)
    return entity_store.get(uid)[_SV_PREFIX .. sv_name]
end

--[[!
    Function: __get_gui_name
    Gets a GUI name of state variable for an entity of given unique ID.
    If the entity has no GUI name (see <state_variable.__init>), sv_name
    gets returned.

    Parameters:
        uid - unique ID of the entity.
        sv_name - state variable name.
]]
function __get_gui_name(uid, sv_name)
    -- get raw SV
    local var = __get(uid, sv_name)

    -- conditionally return
    return var.gui_name and var.gui_name or sv_name
end

--[[!
    Event: simplifier
    Registers a JSON simplifier for entity instances.
    See <json.register>. When JSON finds it should
    encode something that is an entity instance,
    instead of encoding it in a raw way, it substitutes
    it with entity's unique ID. We don't mostly need more,
    and this can save bandwidth very much.

    Code:
        (start code)
            json.register(
                function(value)
                    return (type(value) == "table"
                             and value.uid ~= nil)
                end,
                function(value)
                    return value.uid
                end
            )
        (end
]]
json.register(
    function(value)
        return (type(value) == "table"
                 and value.uid ~= nil)
    end,
    function(value)
        return value.uid
    end
)

--[[!
    Class: state_variable
    Base state variable class. Other state variable classes inherit from
    this one, providing their own methods to convert from / to wire format
    and others.
]]
state_variable = class.new(nil, {
    --[[!
        Function: __tostring
        Returns a string representation of this state variable,
        that is the name set as third argument to <class.new>.
        Each class overrides this name, so there is no need
        for overriding __tostring further.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[!
        Constructor: __init
        Initializes the state variable. Basically defaults certain
        members from kwargs table passed as argument.

        Parameters:
            kwargs - SV arguments.

        Kwargs:
            client_read - specifies whether client can read the
            value, true by default.
            client_write - specifies whether the value can be
            written clientside (indirectly through server message),
            true by default.
            custom_synch - false by default, if true, this state
            variable uses special method of value synchronization.
            Useful for i.e. updates on sauer dynent properties,
            which use their own system of syncing.
            client_set - false by default, if true, clients can
            set the state data directly without going through
            server. Useful in cases where we don't need server
            synced at first.
            gui_name - this is the name that will be shown in
            editing GUIs for this state variable.
            alt_name - alternative name under which this state
            variable will be accessible.
            reliable - true by default. Specifies whether the messages
            for this state variable should be reliable or unreliable.
            Reliable messages are always sent, so you cannot set
            a high number of them without risking crashes.
            Unreliable messages are useful for i.e. position updates,
            which you don't really need to send all time.
            has_history - true by default. It basically means variable
            will retain its state and when i.e. new client requests
            it, it'll receive values that have been set previously,
            even if they were set long before the client connected.
            client_private - false by default. If true, it means this
            state variable will be private to specific client while
            still being accessible from the server (but not from other
            clients).
    ]]
    __init = function(self, kwargs)
        logging.log(logging.INFO, "state_variable: constructor ..")

        if not kwargs then
            kwargs = {}
        end

        self.client_read = kwargs.client_read or true
        self.client_write = kwargs.client_write or true
        self.custom_synch = kwargs.custom_synch or false
        self.client_set = kwargs.client_set or false
        self.gui_name = kwargs.gui_name
        self.alt_name = kwargs.alt_name
        self.reliable = kwargs.reliable or true
        self.has_history = kwargs.has_history or true
        self.client_private = kwargs.client_private or false
    end,

    --[[!
        Function: register
        Registers a state variable for entity. It sets up getter and
        setter for given name and also alt_name if set in <__init>
        via kwargs.

        Raw state variables will be accessible with prefix
        <state_variables._SV_PREFIX>. See also <state_variables.__get>.

        Parameters:
            _name - name of the state variable.
            parent - entity to register the SV for.
    ]]
    register = function(self, _name, parent)
        logging.log(logging.DEBUG, "state_variable:register("
             .. tostring(_name) .. ", "
             .. tostring(parent) .. ")")

        -- set _name.
        self._name = _name

        -- raw accessor.
        parent[_SV_PREFIX .. _name] = self

        -- some assertions.
        assert(self.getter)
        assert(self.setter)

        logging.log(logging.DEBUG, "state_variable:register: defining (g|s)etter for " .. tostring(_name))

        -- define new getter / setter.
        parent:define_getter(_name, self.getter, self)
        parent:define_setter(_name, self.setter, self)

        -- if alt_name is available, setup as well.
        if self.alt_name then
            logging.log(logging.DEBUG, "state_variable:register: defining (g|s)etter for " .. tostring(self.alt_name))
            parent[_SV_PREFIX .. self.alt_name] = self
            parent:define_getter(self.alt_name, self.getter, self)
            parent:define_setter(self.alt_name, self.setter, self)
        end
    end,

    --[[!
        Function: read_tests
        Performs read tests for state variable on client. On server,
        we can always read, on client, we can't read if client_read
        is false (see <__init> kwargs section).

        Throws a failed assertion on failure.

        Parameters:
            entity - unused, corrently no checks are performed. It's
            the entity the state variable belongs to.
    ]]
    read_tests = function(self, entity)
        if not SERVER and not self.client_read then
            assert(false)
        end
    end,

    --[[!
        Function: write_tests
        Performs write tests for state variable. Throws a failed assertion
        if the entity is either deactivated or not yet initialized,
        or we've set client_write to false (see <__init> kwargs section).

        Parameters:
            entity - the entity the state variable belongs to.
    ]]
    write_tests = function(self, entity)
        -- if deactivated, do extra logging and fail
        if entity.deactivated then
            logging.log(
                logging.ERROR,
                "Trying to write a field "
                    .. self._name
                    .. " of "
                    .. entity.uid
                    .. ", "
                    .. tostring(entity)
            )
            assert(false)
        end

        -- check for client_write only on client
        if not SERVER and not self.client_write then
            assert(SERVER or self.client_write)
        end

        -- if unitialized, just fail
        if not entity.initialized then
            assert(ent.initialized)
        end
    end,

    --[[!
        Function: getter
        Default state variable getter. Registered for entity.
        When you try to access the state variable as entity
        member, it calls this function on it and returns
        the value instead of returning the member.

        This is initialized in <register>.
        Before trying to get something, performs <read_tests>.
        See also <setter>.

        Parameters:
            self - the entity.
            variable - the state variable instance.
    ]]
    getter = function(self, variable)
        -- read tests
        variable:read_tests(self)

        logging.log(logging.INFO, "SV getter: " .. variable._name)

        -- return the local value
        return self.state_variable_values[variable._name]
    end,

    --[[!
        Function: setter
        Default state variable setter. Registered for entity.
        When you try to write the state variable as entity
        member, it calls this function on it instead of setting
        raw member.

        This is initialized in <register>.
        Before trying to write something, performs <write_tests>.
        See also <getter>.

        Parameters:
            self - the entity.
            variable - the state variable instance.
            value - the value we're setting.
    ]]
    setter = function(self, value, variable)
        -- write tests
        variable:write_tests(self)

        -- set entity SD
        self:set_state_data(variable._name, value, -1)
    end,

    --[[!
        Function: validate
        Validates state variable value. Called when setting state data,
        can be overriden in child state variables, by default simply
        lets all data pass - returns true.

        Parameters:
            value - the value to validate.
    ]]
    validate = function(self, value)
        return true
    end,

    --[[!
        Function: should_send
        Checks whether this variable should be synced with a client on
        the entity. It can be synced if the variable is not private
        to certain client (see <__init> kwargs section) or if target
        client number is client number of the entity the SV belongs to.

        Parameters:
            entity - the entity the SV belongs to.
            target_cn - client number to check syncing with.

        Returns:
            true if we should send, false otherwise.
    ]]
    should_send = function(self, entity, target_cn)
        return not self.client_private or entity.cn == target_cn
    end,

    --[[!
        Function: to_wire
        Returns a state variable value in wire format. Wire format
        is a string which can be transferred via network and
        then converted back to standard format. By default, just
        converts to string.

        Parameters:
            value - the value to convert.
    ]]
    to_wire = function(self, value)
        return convert.tostring(value)
    end,

    --[[!
        Function: from_wire
        Returns a state variable value in standard format. That means,
        it takes a wire-formatted value and converts it back (see
        <to_wire>). By default returns a string.

        Parameters:
            value - the value to convert.
    ]]
    from_wire = function(self, value)
        return convert.tostring(value)
    end
}, "state_variable")

--[[!
    Class: state_integer
    State integer variable class. Overrides <state_variable.to_wire>,
    <state_variable.from_wire>.

    to_wire performs raw conversion to a string.
    from_wire performs raw conversion to an integer.
]]
state_integer = class.new(state_variable, {
    to_wire = function(self, value)
        return convert.tostring(value)
    end,

    from_wire = function(self, value)
        return convert.tointeger(value)
    end
}, "state_integer")

--[[!
    Class: state_float
    State float variable class. Overrides <state_variable.to_wire>,
    <state_variable.from_wire>.

    to_wire performs conversion to a string, which keeps just maximum
    of two digits after floating point (see <convert.todec2str>).
    from_wire performs raw conversion to a number.
]]
state_float = class.new(state_variable, {
    to_wire = function(self, value)
        return convert.todec2str(value)
    end,

    from_wire = function(self, value)
        return convert.tonumber(value)
    end
}, "state_float")

--[[!
    Class: state_bool
    State boolean variable class. Overrides <state_variable.to_wire>,
    <state_variable.from_wire>.

    to_wire performs raw conversion to a string.
    from_wire performs conversion to a boolean (<convert.toboolean>).
]]
state_bool = class.new(state_variable, {
    to_wire = function(self, value)
        return convert.tostring(value)
    end,

    from_wire = function(self, value)
        return convert.toboolean(value)
    end
}, "state_bool")

--[[!
    Class: state_json
    State JSON variable class. Overrides <state_variable.to_wire>,
    <state_variable.from_wire>.

    to_wire performs JSON encoding of an object, returning a string.
    from_wire decodes the string back to original object.
]]
state_json = class.new(state_variable, {
    to_wire = function(self, value)
        return json.encode(value)
    end,

    from_wire = function(self, value)
        return json.decode(value)
    end
}, "state_json")

--[[!
    Class: state_string
    State string variable class. Doesn't override, because
    <state_variable.to_wire> and <state_variable.from_wire>
    already work with strings. This is basically a nice alias
    for <state_variable>.
]]
state_string = class.new(state_variable, "state_string")

--[[!
    Class: array_surrogate
    This represents array "surrogate". Basically, it behaves like
    standard array, but it's in fact an object that gets / sets
    values using entity and state variable. Array surrogate always
    belongs to certain state variable.

    Getting and setting values is accomplished via class getters
    and setters (see <class.define_getter> and <class.define_setter>).
    In surrogate's case, it uses global getter and setter, see
    <class.define_global_getter> and <class.define_global_setter>.

    There is one difference in behavior compared to standard array
    and that is length getting; with array surrogate, you can't
    use the # operator, you have to access .length object property.

    You can't also use most of things from Lua "table" module.
    There are certain specialized methods for manipulation present
    as object methods.
]]
array_surrogate = class.new(nil, {
    --[[!
        Function: __tostring
        Returns string representation of the surrogate, that is
        name set as third argument to <class.new>.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[!
        Constructor: __init
        Array surrogate constructor. Assigns an entity and state
        variable to the surrogate. Also defines a getter for
        length and userget / userset for items.

        Parameters:
            entity - the entity the state variable belongs to.
            variable - the state variable the surrogate belongs to.
    ]]
    __init = function(self, entity, variable)
        logging.log(
            logging.INFO,
            "setting up array_surrogate("
                .. tostring(entity)
                .. ", "
                .. tostring(variable)
                .. "("
                .. variable._name
                .. "))"
        )

        -- set the members
        self.entity = entity
        self.variable = variable

        -- length getter
        self:define_getter(
            "length", function(self)
                -- by default, returns output of get_length on state variable
                return self.variable.get_length(self.variable, self.entity)
            end
        )
        self:define_global_getter(
            -- condition - use userget only for numerical access
            function(n) return tonumber(n) and true or false end,
            -- return the item
            function(self, n)
                return self.variable.get_item(
                    self.variable, self.entity, tonumber(n)
                )
            end
        )
        self:define_global_setter(
            -- again, only numerical access
            function(n, v) return tonumber(n) and true or false end,
            -- set the item
            function(self, n, v)
                self.variable.set_item(
                    self.variable, self.entity, tonumber(n), v
                )
            end
        )
    end,

    --[[!
        Function: push
        Appends an item to the array surrogate.

        Parameters:
            value - the value to push.
    ]]
    push = function(self, value)
        self[self.length + 1] = value
    end,

    --[[!
        Function: as_array
        Returns raw array of values, which are stored inside
        the entity via state variable.
    ]]
    as_array = function(self)
        logging.log(logging.INFO, "as_array: " .. tostring(self))

        local r = {}
        for i = 1, self.length do
            logging.log(logging.INFO, "as_array(" .. tostring(i) .. ")")
            table.insert(r, self[i])
        end
        return r
    end
}, "array_surrogate")

--[[!
    Class: state_array
    State array class. Inherits from <state_variable>. It's an example
    of more complex state variable, which doesn't just convert data
    to wire format and back. State arrays make use of <array_surrogate>
    to provide interface for manipulating. When the getter is called,
    instead of returning raw array (which can't write changes back
    to the entity) it returns <array_surrogate> which has entity
    and SV assigned and thus can change internal values.
]]
state_array = class.new(state_variable, {
    --[[!
        Variable: separator
        This is the separator that is used in wire format (string)
        to separate array elements.
    ]]
    separator = "|",

    --[[!
        Variable: surrogate_class
        This is the surrogate class that will be used to return
        from getter. Default state array uses <array_surrogate>.
    ]]
    surrogate_class = array_surrogate,

    --[[!
        Function: getter
        Overriden <state_variable.getter>. Instead of returning
        raw value in non-wire format (which would be array in
        our case), it returns <surrogate_class> instance.

        Surrogate class instance is cached, so it doesn't have to
        be recreated every get (usually is created on first getter
        call only).

        Other rules apply the same way as for <state_variable.getter>,
        including execution of <state_variable.read_tests> and
        function arguments.
    ]]
    getter = function(self, variable)
        -- read tests
        variable:read_tests(self)

        -- if we don't have raw value, return nil
        if not variable:get_raw(self) then
            return nil
        end

        -- surrogate caching - save it inside the entity
        if not self["__asurrogate_" .. variable._name] then
               self["__asurrogate_" .. variable._name] = variable.surrogate_class(self, variable)
        end

        -- return the surrogate instance
        return self["__asurrogate_" .. variable._name]
    end,

    --[[!
        Function: setter
        Overriden <state_variable.setter>. Same rules
        as for parent function apply, but you have more
        possibilities to set as value.

        You can besides raw array also provide array
        surrogate as value. That is sometimes handy.
    ]]
    setter = function(self, value, variable)
        logging.log(logging.DEBUG, "state_array setter: " .. json.encode(value))

        -- we can also detect vectors :)
        if value.x then
            logging.log(
                logging.INFO,
                "state_array setter: "
                    .. value.x
                    .. ", "
                    .. value.y
                    .. ", "
                    .. value.z
            )
        end

        -- and arrays, try to print first 3 values
        -- we tostring the two ones because of nil values
        if value[1] then
            logging.log(
                logging.INFO,
                "state_array setter: "
                    .. value[1]
                    .. ", "
                    .. tostring(value[2])
                    .. ", "
                    .. tostring(value[3])
            )
        end

        -- pre-declare data
        local data

        -- for surrogates, we have as_array
        if value.as_array then
            data = value:as_array()
        else
            -- otherwise we get raw table, copy it
            data = table.copy(value)
        end

        -- set data
        self:set_state_data(variable._name, data, -1)
    end,

    --[[!
        Function: to_wire_item
        Used by <to_wire> to convert a single table item to wire format.
        Doesn't have self argument, accepts just one argument and that
        is the value. Returns an item in wire format.
    ]]
    to_wire_item = convert.tostring,

    --[[!
        Function: to_wire
        Overriden <state_variable.to_wire>. It takes an array as an argument
        (or array surrogate, which is then converted to raw array) and
        returns the array in wire format which looks like this:

        (start code)
            [ITEM|ITEM2|ITEM3]
        (end)

        Separator for items is selected using <separator> and each item
        is converted to wire format using <to_wire_item>.

        Parameters:
            value - either raw array or array surrogate to convert.
    ]]
    to_wire = function(self, value)
        logging.log(logging.INFO, "to_wire of state_array: " .. json.encode(value))

        -- if we have array surrogate, get a raw array
        if value.as_array then
            value = value:as_array()
        end

        -- return right format, use <table.map> to map items to wire format.
        return "[" .. table.concat(table.map(value, self.to_wire_item), self.separator) .. "]"
    end,

    --[[!
        Function: from_wire_item
        Used by <from_wire> to convert a single table item from wire format.
        Doesn't have self argument, accepts just one argument and that
        is the value. Returns an item in non-wire format.
    ]]
    from_wire_item = convert.tostring,

    --[[!
        Function: from_wire
        Overriden <state_variable.from_wire>. Converts output of <to_wire> back to
        its raw format. To convert each item from wire format, <from_wire_item>
        output is used.

        Basically, it splits the string with stripped out leading/trailing []
        by <separator> and then re-maps it to array. Returns the raw array.

        Parameters:
            value - the string value to get array from.
    ]]
    from_wire = function(self, value)
        logging.log(logging.DEBUG, "from_wire of state_array: " .. tostring(self._name) .. "::" .. value)

        -- if it's empty, don't bother mapping
        if value == "[]" then
            return {}
        else
            return table.map(string.split(string.sub(value, 2, #value - 1), self.separator), self.from_wire_item)
        end
    end,

    --[[!
        Function: get_raw
        Gets raw array of state array data. Gets the value from local storage,
        doesn't involve any client-server messing.

        Parameters:
            entity - the entity to get raw data from.
    ]]
    get_raw = function(self, entity)
        logging.log(logging.INFO, "get_raw: " .. tostring(self))
        logging.log(logging.INFO, json.encode(entity.state_variable_values))

        local val = entity.state_variable_values[self._name]
        return val and val or {}
    end,

    --[[!
        Function: set_item
        Sets state array item. Used by <array_surrogate> to set elements.
        Performs an update on all clients by calling set_state_data on
        the entity (see <base_server.set_state_data> and <base_client.set_state_data>
        for more information).

        Parameters:
            entity - the entity to set item for.
            index - state array index.
            value - the value to set.
    ]]
    set_item = function(self, entity, index, value)
        logging.log(logging.INFO, "set_item: " .. index .. " : " .. json.encode(value))

        -- get raw array
        local arr = self:get_raw(entity)

        logging.log(logging.INFO, "got_raw: " .. json.encode(arr))

        -- do not allow separator to be present in the item if it's
        -- string, it could mess up the whole system.
        if type(value) == "string" then
            assert(not string.find(value, "%" .. self.separator))
        end

        -- set the item in array
        arr[index] = value

        -- and set it as state data
        entity:set_state_data(self._name, arr, -1)
    end,

    --[[!
        Function: get_item
        Gets state array item. Used by <array_surrogate> to get elements.
        Basically calls <get_raw> and returns required index.

        Parameters:
            entity - the entity to get item from.
            index - state array index.
    ]]
    get_item = function(self, entity, index)
        logging.log(logging.INFO, "state_array:get_item for " .. index)

        -- raw array
        local arr = self:get_raw(entity)
        logging.log(logging.INFO, "state_array:get_item " .. json.encode(arr) .. " ==> " .. arr[index])

        -- TODO: optimize
        return arr[index]
    end,

    --[[!
        Function: get_length
        Gets state array length. Used by
        <array_surrogate> to get its length.

        Basically gets a raw array using
        <get_raw> and counts its elements.

        Parameters:
            entity - the entity to get length for.
    ]]
    get_length = function(self, entity)
        local  arr = self:get_raw(entity)
        if not arr then
            assert(arr)
        end
        return #arr
    end
}, "state_array")

--[[!
    Class: state_array_float
    Version of <state_array> that works with floating
    point numbers. The 2-digit rule applies in the same
    way as for <state_float>. Overrides <state_array.to_wire_item>
    and <state_array.from_wire_item>.
]]
state_array_float = class.new(state_array, {
    to_wire_item = convert.todec2str,
    from_wire_item = convert.tonumber
}, "state_array_float")

--[[!
    Class: state_array_integer
    Version of <state_array> that works with integer numbers.
    Overrides <state_array.to_wire_item> and
    <state_array.from_wire_item>.
]]
state_array_integer = class.new(state_array, {
    to_wire_item = convert.tostring,
    from_wire_item = convert.tointeger

}, "state_array_integer")

--[[!
    Class: variable_alias
    State variable alias. Variable aliases are always registered
    last for the entity, so the variables they point at are ready
    at the time of registration. Variable alias basically points
    at existing state variable, providing an alternative getter
    and setter for the SV. Useful when you're i.e. aliasing
    Cube 2 entity properties (attrN) to a nicer name.
]]
variable_alias = class.new(state_variable, {
    --[[!
        Constructor: __init
        Overriden constructor for alias. Variable aliases don't
        have properties like client_set, custom_synch etc., so
        no need to call parent constructor. This sets just target
        state variable name.

        Parameter:
            target_name - name of the SV this alias points at.
    ]]
    __init = function(self, target_name)
        self.target_name = target_name
    end,

    --[[!
        Function: register
        See <state_variable.register>. This doesn't call parent,
        it just sets up the alias. Basically, it allows to access
        the true state variable under <state_variables._SV_PREFIX>
        plus alias name, and creates a getter / setter for alias name.
    ]]
    register = function(self, _name, parent)
        logging.log(logging.DEBUG, "variable_alias:register(%(1)q, %(2)s)" % { _name, tostring(parent) })

        -- set _name
        self._name = _name

        logging.log(logging.DEBUG, "Getting target entity for variable alias " .. _name .. ": " .. _SV_PREFIX .. self.target_name)

        -- point to the true variable
        local tg = parent[_SV_PREFIX .. self.target_name]
        parent[_SV_PREFIX .. _name] = tg

        -- define getters
        parent:define_getter(_name, tg.getter, tg)
        parent:define_setter(_name, tg.setter, tg)
    end
}, "variable_alias")

--[[!
    Class: wrapped_c_variable
    This is not actual class. This is a mixin table that can make
    a wrapped C state variable class from actual standard state
    variable class. Basically, each wrapped C SV has C getter
    function and C setter function (in fact, sometimes one of
    them can be omitted, like when client_set is true - see
    <state_variable.__init> kwargs section).

    This table overrides constructor, registration and getter
    for the SV class.
]]
wrapped_c_variable = {
    --[[!
        Constructor: __init
        Overriden constructor, see <state_variable.__init>.

        This one reads two more kwargs - that is, c_setter
        and c_getter, which are either strings containing
        names of C getter and setter functions (like, "CAPI.blah")
        or are directly the functions.

        They get saved in the class as c_getter_raw and c_setter_raw.
        Values in kwargs get set to nil.

        Then, parent constructor gets called as usual.
    ]]
    __init = function(self, kwargs)
        logging.log(logging.INFO, "wrapped_c_variable:__init()")

        -- read kwargs
        self.c_getter_raw = kwargs.c_getter
        self.c_setter_raw = kwargs.c_setter
        -- and clear up kwargs
        kwargs.c_getter = nil
        kwargs.c_setter = nil

        -- and call parent with the kwargs
        self.__base.__init(self, kwargs)
    end,

    --[[!
        Function: register
        Overriden <state_variable.register> (or any registration
        method further overriden by children). It first calls the
        parent function as usual and then evaluates c_getter_raw
        and c_setter_raw. If they're functions, it just sets
        them directly. If they're strings, it gets the functions.

        Then, if C setter is available (as mentioned in <__init>,
        it can be omitted in certain cases), it connects a signal
        on value modification (see <base_client.set_state_data>
        and <base_server.set_state_data>) which performs required
        setting of values on C side. The signal handler calls C
        setter always on client or on server if there are no
        queued SV changes (when <base_server.can_call_c_functions>
        returns true value). Otherwise, it queues the SV change
        for next time.

        The value is also cached after C getter is called for
        performance reasons (via global timestamp).
    ]]
    register = function(self, _name, parent)
        -- call parent
        self.__base.register(self, _name, parent)

        logging.log(logging.DEBUG, "WCV register: " .. tostring(_name))

        -- allow use of string names, for late binding at
        -- this stage we copy raw walues, then eval
        self.c_getter = self.c_getter_raw
        self.c_setter = self.c_setter_raw

        -- evaluate string names
        if type(self.c_getter) == "string" then
            self.c_getter = loadstring("return " .. self.c_getter)()
        end
        if type(self.c_setter) == "string" then
            self.c_setter = loadstring("return " .. self.c_setter)()
        end

        -- if we have C setter ..
        if self.c_setter then
            -- prepare a renamed instance of state variable
            local variable = self
            -- connect the handler
            parent:connect(get_on_modify_name(_name), function (self, value)
                -- on client or with empty SV change queue, call the setter
                if CLIENT or parent:can_call_c_functions() then
                    logging.log(logging.INFO, string.format("Calling c_setter for %s, with %s (%s)", variable._name, tostring(value), type(value)))
                    -- we've been set up, apply the change
                    variable.c_setter(parent, value)
                    logging.log(logging.INFO, "c_setter called successfully.")

                    -- cache the value locally for performance reasons
                    parent.state_variable_values[variable._name] = value
                    parent.state_variable_value_timestamps[variable._name] = GLOBAL_CURRENT_TIMESTAMP
                else
                    -- not yet set up, queue change
                    parent:queue_state_variable_change(variable._name, value)
                end
            end)
        else
            -- valid behavior, but log it anyway
            logging.log(logging.DEBUG, "No c_setter for " .. _name .. ": not connecting to signal.")
        end
    end,

    --[[!
        Function: getter
        Overriden <state_variable.getter> (or any getter defined
        further by children). Performs <state_variable.read_tests>,
        checks for cached value - if timestamp fits, returns the local
        value directly (values are cached by event handler set up by
        <register>). If not, it checks for getter (it doesn't have to
        exist, omitting it sometimes is valid behavior) and also
        checks if state variable change queue is empty
        (that is, when <base_server.can_call_c_functions> returns true).
        If all conditions are true, gets the value using C getter
        and on client (or on server when all queued SV changes are
        already done) caches the value again via global timestamp.

        If no getter is available, it calls standard SV getter
        as defined by <state_variable.getter> or children.
    ]]
    getter = function(self, variable)
        -- read tests
        variable:read_tests(self)

        logging.log(logging.INFO, "WCV getter " .. tostring(variable._name))

        -- caching - return from cache if timestamp is okay
        local cached_timestamp = self.state_variable_value_timestamps[variable._name]
        if cached_timestamp == GLOBAL_CURRENT_TIMESTAMP then
            return self.state_variable_values[tostring(variable._name)]
        end

        -- if it needs updated value, do checks
        if variable.c_getter and (CLIENT or self:can_call_c_functions()) then
            logging.log(logging.INFO, "WCV getter: call C")
            -- call C now
            local val = variable.c_getter(self)

            -- re-cache the value since it was outdated
            if CLIENT or self._queued_sv_changes_complete then
                self.state_variable_values[variable._name] = val
                self.state_variable_value_timestamps[variable._name] = GLOBAL_CURRENT_TIMESTAMP
            end

            -- return the value
            return val
        else
            -- call standard getter if no C getter available
            logging.log(logging.INFO, "WCV getter: fallback to state_data since " .. tostring(variable.c_getter))
            return variable.__base.getter(self, variable)
        end
    end
}

--[[!
    Class: wrapped_c_integer
    Wrapped C version of <state_integer>. Takes <state_integer>
    and mixes in <wrapped_c_variable>.
]]
wrapped_c_integer = class.new(
    state_integer, wrapped_c_variable, "wrapped_c_integer"
)

--[[!
    Class: wrapped_c_float
    Wrapped C version of <state_float>. Takes <state_float>
    and mixes in <wrapped_c_variable>.
]]
wrapped_c_float = class.new(
    state_float, wrapped_c_variable, "wrapped_c_float"
)

--[[!
    Class: wrapped_c_bool
    Wrapped C version of <state_bool>. Takes <state_bool>
    and mixes in <wrapped_c_variable>.
]]
wrapped_c_bool = class.new(
    state_bool, wrapped_c_variable, "wrapped_c_bool"
)

--[[!
    Class: wrapped_c_string
    Wrapped C version of <state_string>. Takes <state_string>
    and mixes in <wrapped_c_variable>.
]]
wrapped_c_string = class.new(
    state_string, wrapped_c_variable, "wrapped_c_string"
)

--[[!
    Class: wrapped_c_array
    Wrapped C version of <state_array>. Takes <state_array>
    and mixes in part of <wrapped_c_variable>. Doesn't use
    <wrapped_c_variable.getter>. Overrides <state_array.get_raw>
    so it makes use of C getters.
]]
wrapped_c_array = class.new(state_array, "wrapped_c_array"):mixin({
    __init   = wrapped_c_variable.__init,
    register = wrapped_c_variable.register,

    --[[!
        Function: get_raw
        Overriden <state_array.get_raw>. Never calls the parent.
        It checks if we have c_getter and if we're either on client
        or on server with empty SV change queue. If we are, it
        checks if we're up to date enough according to timestamp,
        if we are, it just returns local value.

        If timestamp is out of date, it gets the value using c_getter
        and caches it as local for next call.

        If we don't have c_getter (valid behavior) it just falls back
        to local state data.
    ]]
    get_raw = function(self, entity)
        logging.log(logging.INFO, "WCA:get_raw " .. self._name .. " " .. tostring(self.c_getter))

        -- check if we can use getter
        if self.c_getter and (CLIENT or entity:can_call_c_functions()) then
            -- try getting the value from cache first, check timestamp
            local cached_timestamp = entity.state_variable_value_timestamps[self._name]
            if cached_timestamp == GLOBAL_CURRENT_TIMESTAMP then
                return entity.state_variable_values[self._name]
            end

            logging.log(logging.INFO, "WCA:get_raw: call C")
            -- call C if we can't.
            local val = self.c_getter(entity)
            logging.log(logging.INFO, "WCA:get_raw:result: " .. json.encode(val))

            -- cache the value so we're up to date for next time
            if CLIENT or entity._queued_sv_changes_complete then
                entity.state_variable_values[self._name] = val
                entity.state_variable_value_timestamps[self._name] = GLOBAL_CURRENT_TIMESTAMP
            end

            -- return the value
            return val
        else
            -- fallback to state data
            logging.log(logging.INFO, "WCA:get_raw: fallback to state_data")
            local r = entity.state_variable_values[self._name]
            logging.log(logging.INFO, "WCA:get_raw .. " .. json.encode(r))
            return r
        end
    end
})

--[[!
    Class: vec3_surrogate
    Inherited from <array_surrogate>. It's basically array surrogate
    modified to fit better with <math.vec3>. It takes <array_surrogate>,
    mixes in <math.vec3> so it has all vector operation methods and
    overrides <array_surrogate.__init> and <array_surrogate.push>
    with its own methods.
]]
vec3_surrogate = class.new(
    array_surrogate, math.vec3, "vec3_surrogate"
):mixin({
    --[[!
        Constructor: __init
        Overriden <array_surrogate.__init>. Doesn't call the parent,
        but performs most of its actions (like setting internal
        references to entity and variable). Defines custom getters
        for x, y, z as well as setters + standard numerical access.

        Length getter always returns 3.
    ]]
    __init = function(self, entity, variable)
        -- internal references
        self.entity = entity
        self.variable = variable

        -- proper getters
        self:define_getter("length", function(self) return 3 end)
        self:define_getter(
            "x", function(self)
                return self.variable.get_item(self.variable, self.entity, 1)
            end
        )
        self:define_getter(
            "y", function(self)
                return self.variable.get_item(self.variable, self.entity, 2)
            end
        )
        self:define_getter(
            "z", function(self)
                return self.variable.get_item(self.variable, self.entity, 3)
            end
        )

        -- and setters
        self:define_setter(
            "x", function(self, v)
                self.variable.set_item(self.variable, self.entity, 1, v)
            end
        )
        self:define_setter(
            "y", function(self, v)
                self.variable.set_item(self.variable, self.entity, 2, v)
            end
        )
        self:define_setter(
            "z", function(self, v)
                self.variable.set_item(self.variable, self.entity, 3, v)
            end
        )

        -- allow classic numerical access
        self:define_global_getter(
            function(n) return tonumber(n) and true or false end,
            function(self, n) return self.variable.get_item(self.variable, self.entity, tonumber(n)) end
        )
        self:define_global_setter(
            function(n, v) return tonumber(n) and true or false end,
            function(self, n, v) self.variable.set_item(self.variable, self.entity, tonumber(n), v) end
        )
    end,

    --[[!
        Function: push
        Overriden <array_surrogate.push>. Throws a failed assertion,
        because we never push into vector so this is bad behavior.
    ]]
    push = function(self, value)
        assert(false)
    end
})

--[[!
    Class: state_vec3
    State vec3. Inherits from <state_array_float>. Provides its own
    surrogate class, <vec3_surrogate> which provides the part with
    which you manipulate (and contains all vector manipulation methods).
    See <state_array.surrogate_class>.
]]
state_vec3 = class.new(state_array_float, {
    surrogate_class = vec3_surrogate
}, "state_vec3")

--[[!
    Class: wrapped_c_vec3
    Wrapped C version of <state_vec3>. Takes <state_vec3>
    and mixes in part of <wrapped_c_variable>. Doesn't use
    <wrapped_c_variable.getter>. Uses <wrapped_c_array.get_raw>
    for C interfacing.
]]
wrapped_c_vec3 = class.new(state_vec3, {
    __init   = wrapped_c_variable.__init,
    register = wrapped_c_variable.register,
    get_raw  = wrapped_c_array.get_raw
}, "wrapped_c_vec3")

--[[!
    Class: vec4_surrogate
    Inherited from <array_surrogate>. It's basically array surrogate
    modified to fit better with <math.vec4>. It takes <array_surrogate>,
    mixes in <math.vec4> so it has all vector operation methods and
    overrides <array_surrogate.__init> and <array_surrogate.push>
    with its own methods.
]]
vec4_surrogate = class.new(
    array_surrogate, math.vec4, "vec4_surrogate"
):mixin({
    --[[!
        Constructor: __init
        Overriden <array_surrogate.__init>. Doesn't call the parent,
        but performs most of its actions (like setting internal
        references to entity and variable). Defines custom getters
        for x, y, z, w as well as setters + standard numerical access.

        Length getter always returns 4.
    ]]
    __init = function(self, entity, variable)
        -- internal references
        self.entity = entity
        self.variable = variable

        -- proper getters
        self:define_getter("length", function(self) return 4 end)
        self:define_getter(
            "x", function(self)
                return self.variable.get_item(self.variable, self.entity, 1)
            end
        )
        self:define_getter(
            "y", function(self)
                return self.variable.get_item(self.variable, self.entity, 2)
            end
        )
        self:define_getter(
            "z", function(self)
                return self.variable.get_item(self.variable, self.entity, 3)
            end
        )
        self:define_getter(
            "w", function(self)
                return self.variable.get_item(self.variable, self.entity, 4)
            end
        )

        -- and setters
        self:define_setter(
            "x", function(self, v)
                self.variable.set_item(self.variable, self.entity, 1, v)
            end
        )
        self:define_setter(
            "y", function(self, v)
                self.variable.set_item(self.variable, self.entity, 2, v)
            end
        )
        self:define_setter(
            "z", function(self, v)
                self.variable.set_item(self.variable, self.entity, 3, v)
            end
        )
        self:define_setter(
            "w", function(self, v)
                self.variable.set_item(self.variable, self.entity, 4, v)
            end
        )

        -- allow classic numerical access
        self:define_global_getter(
            function(n) return tonumber(n) and true or false end,
            function(self, n) return self.variable.get_item(self.variable, self.entity, tonumber(n)) end
        )
        self:define_global_setter(
            function(n, v) return tonumber(n) and true or false end,
            function(self, n, v) self.variable.set_item(self.variable, self.entity, tonumber(n), v) end
        )
    end,

    --[[!
        Function: push
        Overriden <array_surrogate.push>. Throws a failed assertion,
        because we never push into vector so this is bad behavior.
    ]]
    push = function(self, value)
        assert(false)
    end
})

--[[!
    Class: state_vec4
    State vec4. Inherits from <state_array_float>. Provides its own
    surrogate class, <vec4_surrogate> which provides the part with
    which you manipulate (and contains all vector manipulation methods).
    See <state_array.surrogate_class>.
]]
state_vec4 = class.new(state_array_float, {
    surrogate_class = vec4_surrogate
}, "state_vec4")

--[[!
    Class: wrapped_c_vec4
    Wrapped C version of <state_vec4>. Takes <state_vec4>
    and mixes in part of <wrapped_c_variable>. Doesn't use
    <wrapped_c_variable.getter>. Uses <wrapped_c_array.get_raw>
    for C interfacing.
]]
wrapped_c_vec4 = class.new(state_vec4, {
    __init   = wrapped_c_variable.__init,
    register = wrapped_c_variable.register,
    get_raw  = wrapped_c_array.get_raw
}, "wrapped_c_vec4")
