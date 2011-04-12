---
-- base_svars.lua, version 1<br/>
-- State variable system for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
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
local table = require("table")
local string = require("string")
local CAPI = require("CAPI")
local class = require("cc.class")
local log = require("cc.logging")
local glob = require("cc.global")
local lstor = require("cc.logent.store")
local conv = require("cc.typeconv")
local json = require("cc.json")
local vector = require("cc.vector")

--- State variable system for cC Lua interface.
-- @class module
-- @name cc.state_variables
module("cc.state_variables")

function get_onmodify_prefix()
    if glob.CLIENT then
        return "client_on_modify_"
    else
        return "on_modify_"
    end
end

variable = class.new()
function variable:__tostring() return "variable" end

function is(c)
    return base.type(c) == "table" and c.is_a and c:is_a(variable) or false
end

_SV_PREFIX = "__SV_"

function __get(uid, vn)
    return lstor.get(uid)[_SV_PREFIX .. vn]
end

function __getguin(uid, vn)
    local ent = lstor.get(uid)
    local var = ent[_SV_PREFIX .. vn]
    return var.guiname and var.guiname or vn
end

state_variable = class.new(variable)
function state_variable:__tostring() return "state_variable" end
function state_variable:__init(kwargs)
    log.log(log.INFO, "state_variable: constructor ..")

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

function state_variable:_register(_name, parent)
    log.log(log.DEBUG, "state_variable:_register("
         .. base.tostring(_name) .. ", "
         .. base.tostring(parent) .. ")")
    self._name = _name
    parent[_SV_PREFIX .. _name] = self
    parent:remove_getter(_name)
    parent:remove_setter(_name)

    base.assert(self.getter)
    base.assert(self.setter)

    log.log(log.DEBUG, "state_variable:_register: defining (g|s)etter for " .. base.tostring(_name))

    parent:define_getter(_name, self.getter, self)
    parent:define_setter(_name, self.setter, self)

    if self.altname then
        log.log(log.DEBUG, "state_variable:_register: defining (g|s)etter for " .. base.tostring(self.altname))
        parent[_SV_PREFIX .. self.altname] = self
        parent:define_getter(self.altname, self.getter, self)
        parent:define_setter(self.altname, self.setter, self)
    end
end

function state_variable:read_tests(ent)
    if not glob.SERVER and not self.clientread then
        base.assert(false)
    end
end

function state_variable:write_tests(ent)
    if ent.deactivated then
        log.log(log.ERROR, "Trying to write a field " .. self._name .. " of " .. ent.uid .. ", " .. base.tostring(ent))
        base.assert(false)
    end
    if not glob.SERVER and not self.clientwrite then
        base.assert(glob.SERVER or self.clientwrite)
    end
    if not ent.initialized then
        base.assert(ent.initialized)
    end
end

function state_variable:getter(var)
    var:read_tests(self)
    log.log(log.INFO, "SV getter: " .. base.tostring(var._name))
    return self.state_var_vals[var._name]
end

function state_variable:setter(var, val)
    var:write_tests(self)
    self:_set_statedata(var._name, val, -1)
end

function state_variable:validate(val)
    return true
end

function state_variable:should_send(ent, tcn)
    return not self.clientpriv or ent.cn == tcn
end

state_integer = class.new(state_variable)
function state_integer:__tostring() return "state_integer" end
function state_integer:to_wire(v) return conv.tostring(v) end
function state_integer:from_wire(v) return conv.tointeger(v) end
function state_integer:to_data(v) return conv.tostring(v) end
function state_integer:from_data(v) return conv.tointeger(v) end

state_float = class.new(state_variable)
function state_float:__tostring() return "state_float" end
function state_float:to_wire(v) return conv.todec2str(v) end
function state_float:from_wire(v) return conv.tonumber(v) end
function state_float:to_data(v) return conv.todec2str(v) end
function state_float:from_data(v) return conv.tonumber(v) end

state_enum = class.new(state_integer)
function state_enum:__tostring() return "state_enum" end

state_bool = class.new(state_variable)
function state_bool:__tostring() return "state_bool" end
function state_bool:to_wire(v) return conv.tostring(v) end
function state_bool:from_wire(v) return conv.toboolean(v) end
function state_bool:to_data(v) return conv.tostring(v) end
function state_bool:from_data(v) return conv.toboolean(v) end

state_string = class.new(state_variable)
function state_string:__tostring() return "state_string" end
function state_string:to_wire(v) return conv.tostring(v) end
function state_string:from_wire(v) return conv.tostring(v) end
function state_string:to_data(v) return conv.tostring(v) end
function state_string:from_data(v) return conv.tostring(v) end

array_surrogate = class.new()
function array_surrogate:__tostring() return "array_surrogate" end

function array_surrogate:__init(ent, var)
    log.log(log.INFO, "setting up array_surrogate(" .. base.tostring(ent) .. ", " .. base.tostring(var) .. "(" .. var._name .. "))")

    self.entity = ent
    self.variable = var

    self:define_userget(function(self, n)
        if n == "length" then
            return (self.variable and
                self.variable.get_length(self.variable, self.entity)
            or 0)
        end
        if not base.tonumber(n) or not self.variable then return nil end
        return self.variable.get_item(self.variable, self.entity, base.tonumber(n))
    end)
    self:define_userset(function(self, n, v)
        if base.tonumber(n) and self.variable then
            self.variable.set_item(self.variable, self.entity, base.tonumber(n), v)
        else
            base.rawset(self, n, v)
        end
    end)
end

function array_surrogate:push(v)
    self[self.length + 1] = v
end

function array_surrogate:as_array()
    log.log(log.DEBUG, "as_array: " .. base.tostring(self))

    local r = {}
    for i = 1, self.length do
        log.log(log.DEBUG, "as_array(" .. base.tostring(i) .. ")")
        table.insert(r, self[i])
    end
    return r
end

state_array = class.new(state_variable)
function state_array:__tostring() return "state_array" end
state_array.separator = "|"
state_array.surrogate_class = array_surrogate

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

function state_array:setter(var, val)
    log.log(log.DEBUG, "state_array setter: " .. json.encode(val))
    if val.x then
        log.log(log.INFO, "state_array setter: " .. base.tostring(val.x) .. ", " .. base.tostring(val.y) .. ", " .. base.tostring(val.z))
    end
    if val[1] then
        log.log(log.INFO, "state_array setter: " .. base.tostring(val[1]) .. ", " .. base.tostring(val[2]) .. ", " .. base.tostring(val[3]))
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

state_array.to_wire_item = conv.tostring

function state_array:to_wire(v)
    log.log(log.INFO, "to_wire of state_array: " .. json.encode(v))
    if v.as_array then
        -- array surrogate
        v = v:as_array()
    end
    return "[" .. table.concat(table.map(v, self.to_wire_item), self.separator) .. "]"
end

state_array.from_wire_item = conv.tostring

function state_array:from_wire(v)
    log.log(log.DEBUG, "from_wire of state_array: " .. base.tostring(self._name) .. "::" .. base.tostring(v))
    if v == "[]" then
        return {}
    else
        return table.map(string.split(string.sub(v, 2, #v - 1), self.separator), self.from_wire_item)
    end
end

state_array.to_data_item = conv.tostring

function state_array:to_data(v)
    log.log(log.DEBUG, "(1) to_data of state_array: " .. base.tostring(v) .. ", " .. base.type(v) .. ", " .. json.encode(v))
    if v.as_array then
        log.log(log.DEBUG, "(1.5) to_data of state_array: using as_array ..")
        v = v:as_array()
    end

    log.log(log.DEBUG, "(2) to_data of state_array: " .. base.tostring(v) .. ", " .. base.type(v) .. ", " .. json.encode(v))

    return "[" .. table.concat(table.map(v, self.to_data_item), self.separator) .. "]"
end

state_array.from_data_item = conv.tostring

function state_array:from_data(v)
    log.log(log.DEBUG, "from_data of state_array: " .. base.tostring(self._name) .. "::" .. base.tostring(v))
    if v == "[]" then
        return {}
    else
        return table.map(string.split(string.sub(v, 2, #v - 1), self.separator), self.from_data_item)
    end
end

function state_array:get_raw(ent)
    log.log(log.INFO, "get_raw: " .. base.tostring(self))
    log.log(log.INFO, json.encode(ent.state_var_vals))
    local val = ent.state_var_vals[self._name]
    return val and val or {}
end

function state_array:set_item(ent, i, v)
    log.log(log.INFO, "set_item: " .. base.tostring(i) .. " : " .. json.encode(v))
    local arr = self:get_raw(ent)
    log.log(log.INFO, "got_raw: " .. json.encode(arr))
    if base.type(v) == "string" then
        base.assert(not string.find(v, "%" .. self.separator))
    end
    arr[i] = v
    ent:_set_statedata(self._name, arr, -1)
end

function state_array:get_item(ent, i)
    log.log(log.INFO, "state_array:get_item for " .. base.tostring(i))
    local arr = self:get_raw(ent)
    log.log(log.INFO, "state_array:get_item " .. json.encode(arr) .. " ==> " .. base.tostring(arr[i]))
    return arr[i] -- TODO: optimize
end

function state_array:get_length(ent)
    local arr = self:get_raw(ent)
    if not arr then
        base.assert(false)
    end
    return #arr
end

state_array_string = class.new(state_array)
function state_array_string:__tostring() return "state_array_string" end

state_array_string_comma = class.new(state_array_string)
function state_array_string_comma:__tostring() return "state_array_string_comma" end
state_array_string_comma.separator = ","

state_array_float = class.new(state_array)
function state_array_float:__tostring() return "state_array_float" end
state_array_float.to_wire_item = conv.todec2str
state_array_float.from_wire_item = conv.tonumber
state_array_float.to_data_item = conv.todec2str
state_array_float.from_data_item = conv.tonumber

state_array_integer = class.new(state_array)
function state_array_integer:__tostring() return "state_array_integer" end
state_array_integer.to_wire_item = conv.todec2str
state_array_integer.from_wire_item = conv.tointeger
state_array_integer.to_data_item = conv.todec2str
state_array_integer.from_data_item = conv.tointeger

variable_alias = class.new(variable)
function variable_alias:__tostring() return "variable_alias" end

function variable_alias:__init(tn)
    self.targetname = tn
end

function variable_alias:_register(_name, parent)
    log.log(log.DEBUG, "variable_alias:_register(%(1)q, %(2)s)" % { _name, base.tostring(parent) })
    self._name = _name

    parent:remove_getter(_name)
    parent:remove_setter(_name)
    log.log(log.DEBUG, "Getting target entity for variable alias " .. _name .. ": " .. _SV_PREFIX .. self.targetname)
    local tg = parent[_SV_PREFIX .. self.targetname]
    parent[_SV_PREFIX .. _name] = tg -- point to the true variable

    parent:define_getter(_name, tg.getter, tg)
    parent:define_setter(_name, tg.setter, tg)

    base.assert(not self.altname)
end

-- not actual class. meant just for constructing other classes.
wrapped_cvariable = {}
function wrapped_cvariable:__init(kwargs)
    log.log(log.INFO, "wrapped_cvariable:__init()")

    self.cgetter_raw = kwargs.cgetter
    self.csetter_raw = kwargs.csetter
    kwargs.cgetter = nil
    kwargs.csetter = nil

    self.__base.__init(self, kwargs)
end

function wrapped_cvariable:_register(_name, parent)
    self.__base._register(self, _name, parent)

    log.log(log.DEBUG, "WCV register: " .. base.tostring(_name))

    -- allow use of string names, for late binding at this stagem we copy raw walues, then eval
    self.cgetter = self.cgetter_raw
    self.csetter = self.csetter_raw

    if base.type(self.cgetter) == "string" then
        self.cgetter = base.loadstring("return " .. self.cgetter)()
    end
    if base.type(self.csetter) == "string" then
        self.csetter = base.loadstring("return " .. self.csetter)()
    end

    if self.csetter then
        -- subscribe to modify event, so we always call csetter
        local prefix = get_onmodify_prefix()
        local variable = self
        parent:connect(prefix .. _name, function (self, v)
            if glob.CLIENT or parent:can_call_cfuncs() then
                log.log(log.DEBUG, string.format("Calling csetter for %s, with %s (%s)", base.tostring(variable._name), base.tostring(v), base.type(v)))
                -- we've been set up, apply the change
                variable.csetter(parent, v)
                log.log(log.DEBUG, "csetter called successfully.")

                -- caching reads from script into C++ (search for -- caching)
                parent.state_var_vals[base.tostring(variable._name)] = v
                parent.state_var_val_timestamps[base.tostring(variable._name)] = glob.curr_timestamp
            else
                -- not yet set up, queue change
                parent:_queue_sv_change(base.tostring(variable._name), v)
            end
        end)
    else
        log.log(log.DEBUG, "No csetter for " .. base.tostring(_name) .. ": not connecting to signal.")
    end
end

function wrapped_cvariable:getter(var)
    var:read_tests(self)

    log.log(log.INFO, "WCV getter " .. base.tostring(var._name))

    -- caching
    local cached_timestamp = self.state_var_val_timestamps[base.tostring(var._name)]
    if cached_timestamp == glob.curr_timestamp then
        return self.state_var_vals[base.tostring(var._name)]
    end
    if var.cgetter and (glob.CLIENT or self:can_call_cfuncs()) then
        log.log(log.INFO, "WCV getter: call C")
        local val = var.cgetter(self)

        -- caching
        if glob.CLIENT or self._queued_sv_changes_complete then
            self.state_var_vals[base.tostring(var._name)] = val
            self.state_var_val_timestamps[base.tostring(var._name)] = glob.curr_timestamp
        end

        return val
    else
        log.log(log.INFO, "WCV getter: fallback to state_data since " .. base.tostring(var.cgetter))
        return var.__base.getter(self, var)
    end
end

-- wrapped_c versions of state variables

wrapped_cinteger = class.new(state_integer)
function wrapped_cinteger:__tostring() return "wrapped_cinteger" end
wrapped_cinteger.__init    = wrapped_cvariable.__init
wrapped_cinteger._register = wrapped_cvariable._register
wrapped_cinteger.getter    = wrapped_cvariable.getter

wrapped_cfloat = class.new(state_float)
function wrapped_cfloat:__tostring() return "wrapped_cfloat" end
wrapped_cfloat.__init    = wrapped_cvariable.__init
wrapped_cfloat._register = wrapped_cvariable._register
wrapped_cfloat.getter    = wrapped_cvariable.getter

wrapped_cenum = class.new(state_enum)
function wrapped_cenum:__tostring() return "wrapped_cenum" end
wrapped_cenum.__init    = wrapped_cvariable.__init
wrapped_cenum._register = wrapped_cvariable._register
wrapped_cenum.getter    = wrapped_cvariable.getter

wrapped_cbool = class.new(state_bool)
function wrapped_cbool:__tostring() return "wrapped_cbool" end
wrapped_cbool.__init    = wrapped_cvariable.__init
wrapped_cbool._register = wrapped_cvariable._register
wrapped_cbool.getter    = wrapped_cvariable.getter

wrapped_cstring = class.new(state_string)
function wrapped_cstring:__tostring() return "wrapped_cstring" end
wrapped_cstring.__init    = wrapped_cvariable.__init
wrapped_cstring._register = wrapped_cvariable._register
wrapped_cstring.getter    = wrapped_cvariable.getter

-- wrapped vectors

wrapped_carray = class.new(state_array)
function wrapped_carray:__tostring() return "wrapped_carray" end
wrapped_carray.__init    = wrapped_cvariable.__init
wrapped_carray._register = wrapped_cvariable._register

function wrapped_carray:get_raw(ent)
    log.log(log.INFO, "WCA:get_raw " .. base.tostring(self._name) .. " " .. base.tostring(self.cgetter))

    if self.cgetter and (glob.CLIENT or ent:can_call_cfuncs()) then
        -- caching
        local cached_timestamp = ent.state_var_val_timestamps[base.tostring(self._name)]
        if cached_timestamp == glob.curr_timestamp then
            return ent.state_var_vals[base.tostring(self._name)]
        end

        log.log(log.INFO, "WCA:get_raw: call C")
        -- caching
        local val = self.cgetter(ent)
        log.log(log.INFO, "WCA:get_raw:result: " .. json.encode(val))
        if glob.CLIENT or ent._queued_sv_changes_complete then
            ent.state_var_vals[base.tostring(self._name)] = val
            ent.state_var_val_timestamps[base.tostring(self._name)] = glob.curr_timestamp
        end
        return val
    else
        log.log(log.INFO, "WCA:get_raw: fallback to state_data")
        local r = ent.state_var_vals[base.tostring(self._name)]
        log.log(log.INFO, "WCA:get_raw .. " .. json.encode(r))
        return r
    end
end

vec3_surrogate = class.new(array_surrogate)
function vec3_surrogate:__tostring() return "vec3_surrogate" end

function vec3_surrogate:__init(ent, var)
    array_surrogate.__init(self, ent, var)

    self.magnitude = vector.vec3.magnitude
    self.normalize = vector.vec3.normalize
    self.cap = vector.vec3.cap
    self.subnew = vector.vec3.subnew
    self.addnew = vector.vec3.addnew
    self.mulnew = vector.vec3.mulnew
    self.sub = vector.vec3.sub
    self.add = vector.vec3.add
    self.mul = vector.vec3.mul
    self.copy = vector.vec3.copy
    self.getarr = vector.vec3.getarr
    self.fromyawpitch = vector.vec3.fromyawpitch
    self.toyawpitch = vector.vec3.toyawpitch
    self.iscloseto = vector.vec3.iscloseto
    self.dotproduct = vector.vec3.dotproduct

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
        if not base.tonumber(n) then return nil end
        return self.variable.get_item(self.variable, self.entity, base.tonumber(n))
    end)
    self:define_userset(function(self, n, v)
        if base.tonumber(n) then
            self.variable.set_item(self.variable, self.entity, base.tonumber(n), v)
        else
            if n == "x" then
                self.variable.set_item(self.variable, self.entity, 1, v)
            elseif n == "y" then
                self.variable.set_item(self.variable, self.entity, 2, v)
            elseif n == "z" then
                self.variable.set_item(self.variable, self.entity, 3, v)
            else
                base.rawset(self, n, v)
            end
        end
    end)
end

function vec3_surrogate:push(v)
    base.assert(false)
end

wrapped_cvec3 = class.new(state_array)
function wrapped_cvec3:__tostring() return "wrapped_cvec3" end

wrapped_cvec3.surrogate_class = vec3_surrogate
wrapped_cvec3.__init          = wrapped_cvariable.__init
wrapped_cvec3._register       = wrapped_cvariable._register
wrapped_cvec3.from_wire_item  = conv.tonumber
wrapped_cvec3.to_wire_item    = conv.todec2str
wrapped_cvec3.from_data_item  = conv.tonumber
wrapped_cvec3.to_data_item    = conv.todec2str
wrapped_cvec3.get_raw         = wrapped_carray.get_raw

state_vec3 = class.new(state_array)
function state_vec3:__tostring() return "state_vec3" end

state_vec3.surrogate_class = vec3_surrogate
state_vec3.from_wire_item  = conv.tonumber
state_vec3.to_wire_item    = conv.todec2str
state_vec3.from_data_item  = conv.tonumber
state_vec3.to_data_item    = conv.todec2str


vec4_surrogate = class.new(array_surrogate)
function vec4_surrogate:__tostring() return "vec4_surrogate" end

function vec4_surrogate:__init(ent, var)
    array_surrogate.__init(self, ent, var)

    self.magnitude = vector.vec4.magnitude
    self.subnew = vector.vec4.subnew
    self.addnew = vector.vec4.addnew
    self.mulnew = vector.vec4.mulnew
    self.sub = vector.vec4.sub
    self.add = vector.vec4.add
    self.mul = vector.vec4.mul
    self.copy = vector.vec4.copy
    self.getarr = vector.vec4.getarr
    self.quatfromaxiangle = vector.vec4.quatfromaxiangle
    self.toyawpitchroll = vector.vec4.toyawpitchroll
    self.normalize = vector.vec4.normalize
    self.cap = vector.vec4.cap
    self.fromyawpitch = vector.vec4.fromyawpitch
    self.toyawpitch = vector.vec4.toyawpitch
    self.iscloseto = vector.vec4.iscloseto
    self.dotproduct = vector.vec4.dotproduct

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
        if not base.tonumber(n) then return nil end
        return self.variable.get_item(self.variable, self.entity, base.tonumber(n))
    end)
    self:define_userset(function(self, n, v)
        if base.tonumber(n) then
            self.variable.set_item(self.variable, self.entity, base.tonumber(n), v)
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
                base.rawset(self, n, v)
            end
        end
    end)
end

function vec4_surrogate:push(v)
    base.assert(false)
end

wrapped_cvec4 = class.new(state_array)
function wrapped_cvec4:__tostring() return "wrapped_cvec4" end

wrapped_cvec4.surrogate_class = vec4_surrogate
wrapped_cvec4.__init          = wrapped_cvariable.__init
wrapped_cvec4._register       = wrapped_cvariable._register
wrapped_cvec4.from_wire_item  = conv.tonumber
wrapped_cvec4.to_wire_item    = conv.todec2str
wrapped_cvec4.from_data_item  = conv.tonumber
wrapped_cvec4.to_data_item    = conv.todec2str
wrapped_cvec4.get_raw         = wrapped_carray.get_raw


state_vec4 = class.new(state_array)
function state_vec4:__tostring() return "state_vec4" end

state_vec4.surrogate_class = vec4_surrogate
state_vec4.from_wire_item  = conv.tonumber
state_vec4.to_wire_item    = conv.todec2str
state_vec4.from_data_item  = conv.tonumber
state_vec4.to_data_item    = conv.todec2str

-- no surrogate, won't notice changes to internals
state_json = class.new(state_variable)
function state_json:__tostring() return "state_json" end
function state_json:to_wire(v) return json.encode(v) end
function state_json:from_wire(v) return json.decode(v) end
function state_json:to_data(v) return json.encode(v) end
function state_json:from_data(v) return json.decode(v) end

json.register(function(v) return (base.type(v) == "table" and v.uid ~= nil) end, function(v) return v.uid end)
