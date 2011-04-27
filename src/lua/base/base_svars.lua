---
-- base_svars.lua, version 1<br/>
-- State variable system for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 OctaForge project<br/>
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

--- State variable system for OF Lua interface.
-- @class module
-- @name of.state_variables
module("of.state_variables", package.seeall)

--- Get "on modify event" prefix for state variables.
-- @return "on modify event" prefix.
function get_onmodify_prefix()
    if of.global.CLIENT then
        return "client_on_modify_"
    else
        return "on_modify_"
    end
end

--- Get whether something is state variable.
-- @param c Class to check.
-- @return True if it's state variable, false otherwise.
function is(c)
    return type(c) == "table" and c.is_a and c:is_a(state_variable) and true or false
end

_SV_PREFIX = "__SV_"

--- Get actual raw state variable for entity.
-- @param uid Unique ID of the entity.
-- @param vn State variable name.
-- @return Actual raw state variable.
function __get(uid, vn)
    return of.logent.store.get(uid)[_SV_PREFIX .. vn]
end

--- Get GUI name of state variable for entity.
-- @param uid Unique ID of the entity.
-- @param vn State variable name.
-- @return State variable GUI name.
function __getguin(uid, vn)
    local ent = of.logent.store.get(uid)
    local var = ent[_SV_PREFIX .. vn]
    return var.guiname and var.guiname or vn
end

--- Default state variable class, all other inherit from this.
-- @class table
-- @name state_variable
state_variable = class.new()

--- Return string representation of state variable.
-- @return String representation of state variable.
function state_variable:__tostring() return "state_variable" end

--- Constructor for default state variable.
-- Its parameters can be overriden via kwargs.
-- @param kwargs Additional parameters.
function state_variable:__init(kwargs)
    of.logging.log(of.logging.INFO, "state_variable: constructor ..")

    if not kwargs then kwargs = {} end

    self.clientread = kwargs.clientread or true
    self.clientwrite = kwargs.clientwrite or true
    self.customsynch = kwargs.customsynch or false
    self.clientset = kwargs.clientset or false
    self.guiname = kwargs.guiname
    self.altname = kwargs.altname
    self.reliable = kwargs.reliable or true
    self.hashistory = kwargs.hashistory or true
    self.clientpriv = kwargs.clientpriv or false
end

--- State variable registration method. This way (g|s)etter for
-- an entity is created instead of actual raw state variable,
-- and raw state variable is accessible only when prefixed
-- with _SV_PREFIX. There is a function called __get which
-- makes it easy for scripter.
-- @param _name State variable name.
-- @param parent Parent entity to register (g|s)etters for.
-- @see __get
function state_variable:_register(_name, parent)
    of.logging.log(of.logging.DEBUG, "state_variable:_register("
         .. tostring(_name) .. ", "
         .. tostring(parent) .. ")")
    self._name = _name
    parent[_SV_PREFIX .. _name] = self
    parent:remove_getter(_name)
    parent:remove_setter(_name)

    assert(self.getter)
    assert(self.setter)

    of.logging.log(of.logging.DEBUG, "state_variable:_register: defining (g|s)etter for " .. tostring(_name))

    parent:define_getter(_name, self.getter, self)
    parent:define_setter(_name, self.setter, self)

    if self.altname then
        of.logging.log(of.logging.DEBUG, "state_variable:_register: defining (g|s)etter for " .. tostring(self.altname))
        parent[_SV_PREFIX .. self.altname] = self
        parent:define_getter(self.altname, self.getter, self)
        parent:define_setter(self.altname, self.setter, self)
    end
end

--- Read tests. Throws a failed assertion if
-- we're on client but variable is not readable from client.
-- @param ent Entity - currently doesn't perform checks on it - unused.
function state_variable:read_tests(ent)
    if not of.global.SERVER and not self.clientread then
        assert(false)
    end
end

--- Write tests. Throws a failed assertion if entity is either deactivated
-- or we're on client with non-client-writable variable or if entity is not
-- yet initialized.
-- @param ent Entity to perform checks for.
function state_variable:write_tests(ent)
    if ent.deactivated then
        of.logging.log(of.logging.ERROR, "Trying to write a field " .. self._name .. " of " .. ent.uid .. ", " .. tostring(ent))
        assert(false)
    end
    if not of.global.SERVER and not self.clientwrite then
        assert(of.global.SERVER or self.clientwrite)
    end
    if not ent.initialized then
        assert(ent.initialized)
    end
end

--- Default state variable getter. This getter is registered for
-- entity, not state variable, so "self" here is the entity and
-- state variable is passed via argument. Read checks are performed.
-- @param var Corresponding state variable.
-- @return Value of the state variable.
-- @see state_variable:read_tests
-- @see state_variable:setter
function state_variable:getter(var)
    var:read_tests(self)
    of.logging.log(of.logging.INFO, "SV getter: " .. tostring(var._name))
    return self.state_var_vals[var._name]
end

--- Default state variable setter. Simillar to getter, only for setting.
-- @param var Corresponding state variable.
-- @param val Value to set.
-- @see state_variable:write_tests
-- @see state_variable:getter
function state_variable:setter(var, val)
    var:write_tests(self)
    self:_set_statedata(var._name, val, -1)
end

--- Validate value for state variable. Called when setting state data.
-- Can be overriden in children, normally just returns true.
-- @param val Value to validate.
-- @return Always true by default.
function state_variable:validate(val)
    return true
end

--- Check whether this variable should be synced with a client on entity.
-- @param ent Entity to perform checks for.
-- @param tcn Target client number.
-- @return True if target client number equals the one from entity, false otherwise.
function state_variable:should_send(ent, tcn)
    return not self.clientpriv or ent.cn == tcn
end

--- State integer. Simple state variable case. to_(wire|data) simply return a string,
-- from_(wire|data) convert string back to integer.
-- @class table
-- @name state_integer
state_integer = class.new(state_variable)
function state_integer:__tostring() return "state_integer" end
function state_integer:to_wire(v) return convert.tostring(v) end
function state_integer:from_wire(v) return convert.tointeger(v) end
function state_integer:to_data(v) return convert.tostring(v) end
function state_integer:from_data(v) return convert.tointeger(v) end

--- State float. to_(wire|data) return a string with max two digits after
-- floating point. from_(wire|data) convert string back to integer.
-- @class table
-- @name state_float
state_float = class.new(state_variable)
function state_float:__tostring() return "state_float" end
function state_float:to_wire(v) return convert.todec2str(v) end
function state_float:from_wire(v) return convert.tonumber(v) end
function state_float:to_data(v) return convert.todec2str(v) end
function state_float:from_data(v) return convert.tonumber(v) end

--- State boolean. to_(wire|data) return a string, from_(wire|data) convert
-- it back to boolean.
-- @class table
-- @name state_bool
state_bool = class.new(state_variable)
function state_bool:__tostring() return "state_bool" end
function state_bool:to_wire(v) return convert.tostring(v) end
function state_bool:from_wire(v) return convert.toboolean(v) end
function state_bool:to_data(v) return convert.tostring(v) end
function state_bool:from_data(v) return convert.toboolean(v) end

--- State string. Simple case, because purely string manipulation gets performed.
-- Though, some tostring conversions are done to make sure. TODO: get rid of them?
-- requires testing without conversions.
-- @class table
-- @name state_string
state_string = class.new(state_variable)
function state_string:__tostring() return "state_string" end
function state_string:to_wire(v) return convert.tostring(v) end
function state_string:from_wire(v) return convert.tostring(v) end
function state_string:to_data(v) return convert.tostring(v) end
function state_string:from_data(v) return convert.tostring(v) end

--- This class serves as "array surrogate" for state_array.
-- Currently, array surrogate gets newly created whenever
-- it's needed - TODO: cache it! And maybe TODO: make DEPRECATED.
-- @class table
-- @name array_surrogate
array_surrogate = class.new()

--- Return string representation of array surrogate.
-- @return String representation of array surrogate.
function array_surrogate:__tostring() return "array_surrogate" end

--- Array surrogate constructor. Surrogate gets created for
-- specific state variable and specific entity and
-- getter / setter gets created for it.
-- @param ent Entity to create surrogate for.
-- @param var State variable to create surrogate for.
function array_surrogate:__init(ent, var)
    of.logging.log(of.logging.INFO, "setting up array_surrogate(" .. tostring(ent) .. ", " .. tostring(var) .. "(" .. var._name .. "))")

    self.entity = ent
    self.variable = var

    self:define_userget(function(self, n)
        if n == "length" then
            return (self.variable and
                self.variable.get_length(self.variable, self.entity)
            or 0)
        end
        if not tonumber(n) or not self.variable then return nil end
        return self.variable.get_item(self.variable, self.entity, tonumber(n))
    end)
    self:define_userset(function(self, n, v)
        if tonumber(n) and self.variable then
            self.variable.set_item(self.variable, self.entity, tonumber(n), v)
        else
            rawset(self, n, v)
        end
    end)
end

--- Push into array surrogate. Appends a value on the end.
-- @param v Value to push.
function array_surrogate:push(v)
    self[self.length + 1] = v
end

--- Return raw array of values.
-- @return Raw array of values.
function array_surrogate:as_array()
    of.logging.log(of.logging.DEBUG, "as_array: " .. tostring(self))

    local r = {}
    for i = 1, self.length do
        of.logging.log(of.logging.DEBUG, "as_array(" .. tostring(i) .. ")")
        table.insert(r, self[i])
    end
    return r
end

--- State array. State variable like any other, but makes
-- use of array surrogate class to perform things.
-- State arrays also have (to|from)_(wire|data)_item methods.
-- @class table
-- @name state_array
state_array = class.new(state_variable)
function state_array:__tostring() return "state_array" end
state_array.separator = "|"
state_array.surrogate_class = array_surrogate

--- Overriden getter. See state_variable:getter.
-- Getter returns a new surrogate in this case.
-- @param var State variable to create surrogate for.
-- @return Newly created surrogate.
-- @see state_variable:getter
function state_array:getter(var)
    var:read_tests(self)

    if not var:get_raw(self) then return nil end
    -- caching: TODO: enable later
    -- if not self["__asurrogate_" .. var._name] then
    --     self["__asurrogate_" .. var._name] = var.surrogate_class(self, var)
    -- end
    -- return self["__asurrogate_" .. var._name]
    return var.surrogate_class(self, var)
end

--- Overriden setter. See state:variable:setter.
-- @param var State variable to set.
-- @param val Value to set.
function state_array:setter(var, val)
    of.logging.log(of.logging.DEBUG, "state_array setter: " .. of.json.encode(val))
    if val.x then
        of.logging.log(of.logging.INFO, "state_array setter: " .. tostring(val.x) .. ", " .. tostring(val.y) .. ", " .. tostring(val.z))
    end
    if val[1] then
        of.logging.log(of.logging.INFO, "state_array setter: " .. tostring(val[1]) .. ", " .. tostring(val[2]) .. ", " .. tostring(val[3]))
    end

    local data

    if val.as_array then data = val:as_array()
    else
        data = {}
        local i

        local sz = (val.is_a and val:is_a(array_surrogate)) and val.length or #val

        for i = 1, sz do
            data[i] = val[i]
        end
    end

    self:_set_statedata(var._name, data, -1)
end

state_array.to_wire_item = convert.tostring

function state_array:to_wire(v)
    of.logging.log(of.logging.INFO, "to_wire of state_array: " .. of.json.encode(v))
    if v.as_array then
        -- array surrogate
        v = v:as_array()
    end
    return "[" .. table.concat(table.map(v, self.to_wire_item), self.separator) .. "]"
end

state_array.from_wire_item = convert.tostring

function state_array:from_wire(v)
    of.logging.log(of.logging.DEBUG, "from_wire of state_array: " .. tostring(self._name) .. "::" .. tostring(v))
    if v == "[]" then
        return {}
    else
        return table.map(string.split(string.sub(v, 2, #v - 1), self.separator), self.from_wire_item)
    end
end

state_array.to_data_item = convert.tostring

function state_array:to_data(v)
    of.logging.log(of.logging.DEBUG, "(1) to_data of state_array: " .. tostring(v) .. ", " .. type(v) .. ", " .. of.json.encode(v))
    if v.as_array then
        of.logging.log(of.logging.DEBUG, "(1.5) to_data of state_array: using as_array ..")
        v = v:as_array()
    end

    of.logging.log(of.logging.DEBUG, "(2) to_data of state_array: " .. tostring(v) .. ", " .. type(v) .. ", " .. of.json.encode(v))

    return "[" .. table.concat(table.map(v, self.to_data_item), self.separator) .. "]"
end

state_array.from_data_item = convert.tostring

function state_array:from_data(v)
    of.logging.log(of.logging.DEBUG, "from_data of state_array: " .. tostring(self._name) .. "::" .. tostring(v))
    if v == "[]" then
        return {}
    else
        return table.map(string.split(string.sub(v, 2, #v - 1), self.separator), self.from_data_item)
    end
end

--- Get a raw array from the data. By default, it's state data,
-- but can be further overriden in children.
-- @param ent Entity to get raw data for.
-- @return Raw data.
function state_array:get_raw(ent)
    of.logging.log(of.logging.INFO, "get_raw: " .. tostring(self))
    of.logging.log(of.logging.INFO, of.json.encode(ent.state_var_vals))
    local val = ent.state_var_vals[self._name]
    return val and val or {}
end

--- Set state array item.
-- @param ent Entity to set item for.
-- @param i Array index.
-- @param v Item value.
function state_array:set_item(ent, i, v)
    of.logging.log(of.logging.INFO, "set_item: " .. tostring(i) .. " : " .. of.json.encode(v))
    local arr = self:get_raw(ent)
    of.logging.log(of.logging.INFO, "got_raw: " .. of.json.encode(arr))
    if type(v) == "string" then
        assert(not string.find(v, "%" .. self.separator))
    end
    arr[i] = v
    ent:_set_statedata(self._name, arr, -1)
end

--- Get state array item.
-- @param ent Entity to get item for.
-- @param i Array index.
-- @return Item value.
function state_array:get_item(ent, i)
    of.logging.log(of.logging.INFO, "state_array:get_item for " .. tostring(i))
    local arr = self:get_raw(ent)
    of.logging.log(of.logging.INFO, "state_array:get_item " .. of.json.encode(arr) .. " ==> " .. tostring(arr[i]))
    return arr[i] -- TODO: optimize
end

--- Get state array length.
-- @param ent Entity to get length for.
-- @return State array length.
function state_array:get_length(ent)
    local arr = self:get_raw(ent)
    if not arr then
        assert(false)
    end
    return #arr
end

--- State array with elements of floating point number type.
-- @class table
-- @name state_array_float
state_array_float = class.new(state_array)
function state_array_float:__tostring() return "state_array_float" end
state_array_float.to_wire_item = convert.todec2str
state_array_float.from_wire_item = convert.tonumber
state_array_float.to_data_item = convert.todec2str
state_array_float.from_data_item = convert.tonumber

--- State array with elements of integral type.
-- @class table
-- @name state_array_integer
state_array_integer = class.new(state_array)
function state_array_integer:__tostring() return "state_array_integer" end
state_array_integer.to_wire_item = convert.todec2str
state_array_integer.from_wire_item = convert.tointeger
state_array_integer.to_data_item = convert.todec2str
state_array_integer.from_data_item = convert.tointeger

--- Variable alias. Useful to get simpler setters.
-- @class table
-- @name variable_alias
variable_alias = class.new(variable)

--- Return string representation of variable alias.
-- @return String representation of variable alias.
function variable_alias:__tostring() return "variable_alias" end

--- Constructor for variable alias.
-- @param tn Target state variable name.
function variable_alias:__init(tn)
    self.targetname = tn
end

--- Custom registration method for variable alias.
-- Uses getter / setter of the target and
-- _SV_PREFIXed entity element points to actual
-- state variable, not to the alias.
-- @param _name Alias name.
-- @param parent Parent entity to perform registration for.
function variable_alias:_register(_name, parent)
    of.logging.log(of.logging.DEBUG, "variable_alias:_register(%(1)q, %(2)s)" % { _name, tostring(parent) })
    self._name = _name

    parent:remove_getter(_name)
    parent:remove_setter(_name)
    of.logging.log(of.logging.DEBUG, "Getting target entity for variable alias " .. _name .. ": " .. _SV_PREFIX .. self.targetname)
    local tg = parent[_SV_PREFIX .. self.targetname]
    parent[_SV_PREFIX .. _name] = tg -- point to the true variable

    parent:define_getter(_name, tg.getter, tg)
    parent:define_setter(_name, tg.setter, tg)

    assert(not self.altname)
end

-- not actual class. meant just for constructing other classes.
wrapped_cvariable = {}

--- Common constructor for wrapped C variables. Wrapped C variables
-- make use of C getters and setters instead of their own data,
-- though C getter data get cached in lua to improve performance.
-- Kwargs can contain csetter, cgetter as well as kwargs for base
-- state variables (wrapped_cinteger kwargs can contain state_integer
-- kwargs)
-- @param kwargs Additional parameters.
function wrapped_cvariable:__init(kwargs)
    of.logging.log(of.logging.INFO, "wrapped_cvariable:__init()")

    self.cgetter_raw = kwargs.cgetter
    self.csetter_raw = kwargs.csetter
    kwargs.cgetter = nil
    kwargs.csetter = nil

    self.__base.__init(self, kwargs)
end

--- Common register method for wrapped C variables.
-- @param _name Wrapped C variable name.
-- @param parent Parent entity.
-- @see state_variable:_register
function wrapped_cvariable:_register(_name, parent)
    self.__base._register(self, _name, parent)

    of.logging.log(of.logging.DEBUG, "WCV register: " .. tostring(_name))

    -- allow use of string names, for late binding at this stagem we copy raw walues, then eval
    self.cgetter = self.cgetter_raw
    self.csetter = self.csetter_raw

    if type(self.cgetter) == "string" then
        self.cgetter = loadstring("return " .. self.cgetter)()
    end
    if type(self.csetter) == "string" then
        self.csetter = loadstring("return " .. self.csetter)()
    end

    if self.csetter then
        -- subscribe to modify event, so we always call csetter
        local prefix = get_onmodify_prefix()
        local variable = self
        parent:connect(prefix .. _name, function (self, v)
            if of.global.CLIENT or parent:can_call_cfuncs() then
                of.logging.log(of.logging.DEBUG, string.format("Calling csetter for %s, with %s (%s)", tostring(variable._name), tostring(v), type(v)))
                -- we've been set up, apply the change
                variable.csetter(parent, v)
                of.logging.log(of.logging.DEBUG, "csetter called successfully.")

                -- caching reads from script into C++ (search for -- caching)
                parent.state_var_vals[tostring(variable._name)] = v
                parent.state_var_val_timestamps[tostring(variable._name)] = of.global.curr_timestamp
            else
                -- not yet set up, queue change
                parent:_queue_sv_change(tostring(variable._name), v)
            end
        end)
    else
        of.logging.log(of.logging.DEBUG, "No csetter for " .. tostring(_name) .. ": not connecting to signal.")
    end
end

--- Common overriden getter for wrapped C variables.
-- @param var Wrapped C variable the getter is belonging to.
-- @return The value.
function wrapped_cvariable:getter(var)
    var:read_tests(self)

    of.logging.log(of.logging.INFO, "WCV getter " .. tostring(var._name))

    -- caching
    local cached_timestamp = self.state_var_val_timestamps[tostring(var._name)]
    if cached_timestamp == of.global.curr_timestamp then
        return self.state_var_vals[tostring(var._name)]
    end
    if var.cgetter and (of.global.CLIENT or self:can_call_cfuncs()) then
        of.logging.log(of.logging.INFO, "WCV getter: call C")
        local val = var.cgetter(self)

        -- caching
        if of.global.CLIENT or self._queued_sv_changes_complete then
            self.state_var_vals[tostring(var._name)] = val
            self.state_var_val_timestamps[tostring(var._name)] = of.global.curr_timestamp
        end

        return val
    else
        of.logging.log(of.logging.INFO, "WCV getter: fallback to state_data since " .. tostring(var.cgetter))
        return var.__base.getter(self, var)
    end
end

--- Wrapped C integer. Inherits from state_integer,
-- but wraps it over C getter / setter.
-- @class table
-- @name wrapped_cinteger
wrapped_cinteger = class.new(state_integer)
function wrapped_cinteger:__tostring() return "wrapped_cinteger" end
wrapped_cinteger.__init    = wrapped_cvariable.__init
wrapped_cinteger._register = wrapped_cvariable._register
wrapped_cinteger.getter    = wrapped_cvariable.getter

--- Wrapped C float. Inherits from state_float,
-- but wraps it over C getter / setter.
-- @class table
-- @name wrapped_cfloat
wrapped_cfloat = class.new(state_float)
function wrapped_cfloat:__tostring() return "wrapped_cfloat" end
wrapped_cfloat.__init    = wrapped_cvariable.__init
wrapped_cfloat._register = wrapped_cvariable._register
wrapped_cfloat.getter    = wrapped_cvariable.getter

--- Wrapped C boolean. Inherits from state_bool,
-- but wraps it over C getter / setter.
-- @class table
-- @name wrapped_cbool
wrapped_cbool = class.new(state_bool)
function wrapped_cbool:__tostring() return "wrapped_cbool" end
wrapped_cbool.__init    = wrapped_cvariable.__init
wrapped_cbool._register = wrapped_cvariable._register
wrapped_cbool.getter    = wrapped_cvariable.getter

--- Wrapped C string. Inherits from state_string,
-- but wraps it over C getter / setter.
-- @class table
-- @name wrapped_cstring
wrapped_cstring = class.new(state_string)
function wrapped_cstring:__tostring() return "wrapped_cstring" end
wrapped_cstring.__init    = wrapped_cvariable.__init
wrapped_cstring._register = wrapped_cvariable._register
wrapped_cstring.getter    = wrapped_cvariable.getter

--- Wrapped C array. Inherits from state_array,
-- but wraps it over C getter / setter.
-- @class table
-- @name wrapped_carray
wrapped_carray = class.new(state_array)
function wrapped_carray:__tostring() return "wrapped_carray" end
wrapped_carray.__init    = wrapped_cvariable.__init
wrapped_carray._register = wrapped_cvariable._register

--- Wrapped C array overrides method for getting raw array
-- so it makes use of C getter (though everything is cached).
-- @param ent Entity the wrapped C array is belonging to.
function wrapped_carray:get_raw(ent)
    of.logging.log(of.logging.INFO, "WCA:get_raw " .. tostring(self._name) .. " " .. tostring(self.cgetter))

    if self.cgetter and (of.global.CLIENT or ent:can_call_cfuncs()) then
        -- caching
        local cached_timestamp = ent.state_var_val_timestamps[tostring(self._name)]
        if cached_timestamp == of.global.curr_timestamp then
            return ent.state_var_vals[tostring(self._name)]
        end

        of.logging.log(of.logging.INFO, "WCA:get_raw: call C")
        -- caching
        local val = self.cgetter(ent)
        of.logging.log(of.logging.INFO, "WCA:get_raw:result: " .. of.json.encode(val))
        if of.global.CLIENT or ent._queued_sv_changes_complete then
            ent.state_var_vals[tostring(self._name)] = val
            ent.state_var_val_timestamps[tostring(self._name)] = of.global.curr_timestamp
        end
        return val
    else
        of.logging.log(of.logging.INFO, "WCA:get_raw: fallback to state_data")
        local r = ent.state_var_vals[tostring(self._name)]
        of.logging.log(of.logging.INFO, "WCA:get_raw .. " .. of.json.encode(r))
        return r
    end
end

--- This inherits from array surrogate in order to achieve
-- vec3 behavior. Used by state_vec3 and wrapped_cvec3.
-- @class table
-- @name vec3_surrogate
-- @see vec4_surrogate
vec3_surrogate = class.new(array_surrogate)

--- Return string representation of vec3 surrogate.
-- @return String representation of vec3 surrogate.
function vec3_surrogate:__tostring() return "vec3_surrogate" end

--- Vec3 surrogate constructor. Surrogate gets created for
-- specific state variable and specific entity and
-- getter / setter gets created for it.
-- @param ent Entity to create surrogate for.
-- @param var State variable to create surrogate for.
function vec3_surrogate:__init(ent, var)
    array_surrogate.__init(self, ent, var)

    self.magnitude = math.vec3.magnitude
    self.normalize = math.vec3.normalize
    self.cap = math.vec3.cap
    self.subnew = math.vec3.subnew
    self.addnew = math.vec3.addnew
    self.mulnew = math.vec3.mulnew
    self.sub = math.vec3.sub
    self.add = math.vec3.add
    self.mul = math.vec3.mul
    self.copy = math.vec3.copy
    self.getarr = math.vec3.getarr
    self.fromyawpitch = math.vec3.fromyawpitch
    self.toyawpitch = math.vec3.toyawpitch
    self.iscloseto = math.vec3.iscloseto
    self.dotproduct = math.vec3.dotproduct

    self.entity = ent
    self.variable = var

    self:define_userget(function(self, n)
        if n == "length" then
            return 3
        elseif n == "x" then
            return self.variable.get_item(self.variable, self.entity, 1)
        elseif n == "y" then
            return self.variable.get_item(self.variable, self.entity, 2)
        elseif n == "z" then
            return self.variable.get_item(self.variable, self.entity, 3)
        end
        if not tonumber(n) then return nil end
        return self.variable.get_item(self.variable, self.entity, tonumber(n))
    end)
    self:define_userset(function(self, n, v)
        if tonumber(n) then
            self.variable.set_item(self.variable, self.entity, tonumber(n), v)
        else
            if n == "x" then
                self.variable.set_item(self.variable, self.entity, 1, v)
            elseif n == "y" then
                self.variable.set_item(self.variable, self.entity, 2, v)
            elseif n == "z" then
                self.variable.set_item(self.variable, self.entity, 3, v)
            else
                rawset(self, n, v)
            end
        end
    end)
end

--- Push method for vec3 throws a failed assertion,
-- because you never push into vec3.
function vec3_surrogate:push(v)
    assert(false)
end

--- Wrapped C vec3. Inherits from state_array,
-- but wraps it over C getter / setter and uses
-- surrogate class of vec3, as well as its own
-- wire / data methods.
-- @class table
-- @name wrapped_cvec3
-- @see wrapped_cvec4
wrapped_cvec3 = class.new(state_array)
function wrapped_cvec3:__tostring() return "wrapped_cvec3" end

wrapped_cvec3.surrogate_class = vec3_surrogate
wrapped_cvec3.__init          = wrapped_cvariable.__init
wrapped_cvec3._register       = wrapped_cvariable._register
wrapped_cvec3.from_wire_item  = convert.tonumber
wrapped_cvec3.to_wire_item    = convert.todec2str
wrapped_cvec3.from_data_item  = convert.tonumber
wrapped_cvec3.to_data_item    = convert.todec2str
wrapped_cvec3.get_raw         = wrapped_carray.get_raw

--- State vec3. Inherits state array, but uses
-- its own surrogate class as well as its own
-- wire / data methods.
-- @class table
-- @name state_vec3
-- @see state_vec4
state_vec3 = class.new(state_array)
function state_vec3:__tostring() return "state_vec3" end

state_vec3.surrogate_class = vec3_surrogate
state_vec3.from_wire_item  = convert.tonumber
state_vec3.to_wire_item    = convert.todec2str
state_vec3.from_data_item  = convert.tonumber
state_vec3.to_data_item    = convert.todec2str

--- This inherits from array surrogate in order to achieve
-- vec4 behavior. Used by state_vec4 and wrapped_cvec4.
-- @class table
-- @name vec4_surrogate
-- @see vec3_surrogate
vec4_surrogate = class.new(array_surrogate)

--- Return string representation of vec4 surrogate.
-- @return String representation of vec4 surrogate.
function vec4_surrogate:__tostring() return "vec4_surrogate" end

--- Vec4 surrogate constructor. Surrogate gets created for
-- specific state variable and specific entity and
-- getter / setter gets created for it.
-- @param ent Entity to create surrogate for.
-- @param var State variable to create surrogate for.
function vec4_surrogate:__init(ent, var)
    array_surrogate.__init(self, ent, var)

    self.magnitude = math.vec4.magnitude
    self.subnew = math.vec4.subnew
    self.addnew = math.vec4.addnew
    self.mulnew = math.vec4.mulnew
    self.sub = math.vec4.sub
    self.add = math.vec4.add
    self.mul = math.vec4.mul
    self.copy = math.vec4.copy
    self.getarr = math.vec4.getarr
    self.quatfromaxiangle = math.vec4.quatfromaxiangle
    self.toyawpitchroll = math.vec4.toyawpitchroll
    self.normalize = math.vec4.normalize
    self.cap = math.vec4.cap
    self.fromyawpitch = math.vec4.fromyawpitch
    self.toyawpitch = math.vec4.toyawpitch
    self.iscloseto = math.vec4.iscloseto
    self.dotproduct = math.vec4.dotproduct

    self.entity = ent
    self.variable = var

    self:define_userget(function(self, n)
        if n == "length" then
            return 4
        elseif n == "x" then
            return self.variable.get_item(self.variable, self.entity, 1)
        elseif n == "y" then
            return self.variable.get_item(self.variable, self.entity, 2)
        elseif n == "z" then
            return self.variable.get_item(self.variable, self.entity, 3)
        elseif n == "w" then
            return self.variable.get_item(self.variable, self.entity, 4)
        end
        if not tonumber(n) then return nil end
        return self.variable.get_item(self.variable, self.entity, tonumber(n))
    end)
    self:define_userset(function(self, n, v)
        if tonumber(n) then
            self.variable.set_item(self.variable, self.entity, tonumber(n), v)
        else
            if n == "x" then
                self.variable.set_item(self.variable, self.entity, 1, v)
            elseif n == "y" then
                self.variable.set_item(self.variable, self.entity, 2, v)
            elseif n == "z" then
                self.variable.set_item(self.variable, self.entity, 3, v)
            elseif n == "w" then
                self.variable.set_item(self.variable, self.entity, 4, v)
            else
                rawset(self, n, v)
            end
        end
    end)
end

--- Push method for vec4 throws a failed assertion,
-- because you never push into vec4.
function vec4_surrogate:push(v)
    assert(false)
end

--- Wrapped C vec4. Inherits from state_array,
-- but wraps it over C getter / setter and uses
-- surrogate class of vec4, as well as its own
-- wire / data methods.
-- @class table
-- @name wrapped_cvec4
-- @see wrapped_cvec3
wrapped_cvec4 = class.new(state_array)
function wrapped_cvec4:__tostring() return "wrapped_cvec4" end

wrapped_cvec4.surrogate_class = vec4_surrogate
wrapped_cvec4.__init          = wrapped_cvariable.__init
wrapped_cvec4._register       = wrapped_cvariable._register
wrapped_cvec4.from_wire_item  = convert.tonumber
wrapped_cvec4.to_wire_item    = convert.todec2str
wrapped_cvec4.from_data_item  = convert.tonumber
wrapped_cvec4.to_data_item    = convert.todec2str
wrapped_cvec4.get_raw         = wrapped_carray.get_raw

--- State vec4. Inherits state array, but uses
-- its own surrogate class as well as its own
-- wire / data methods.
-- @class table
-- @name state_vec4
-- @see state_vec3
state_vec4 = class.new(state_array)
function state_vec4:__tostring() return "state_vec4" end

state_vec4.surrogate_class = vec4_surrogate
state_vec4.from_wire_item  = convert.tonumber
state_vec4.to_wire_item    = convert.todec2str
state_vec4.from_data_item  = convert.tonumber
state_vec4.to_data_item    = convert.todec2str

--- State of.json. Simple state variable. On to_(wire|data)
-- it encodes JSON table, on from_(wire|data), it decodes
-- JSON string.
-- @class table
-- @name state_json
state_json = class.new(state_variable)
function state_json:__tostring() return "state_json" end
function state_json:to_wire(v) return of.json.encode(v) end
function state_json:from_wire(v) return of.json.decode(v) end
function state_json:to_data(v) return of.json.encode(v) end
function state_json:from_data(v) return of.json.decode(v) end

of.json.register(function(v) return (type(v) == "table" and v.uid ~= nil) end, function(v) return v.uid end)
