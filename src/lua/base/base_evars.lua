---
-- base_evars.lua, version 1<br/>
-- Engine variable system<br/>
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
local logging = require("cc.logging")
local class = require("cc.class")
local CAPI = require("CAPI")

--- The engine variables module. It contains core "variables" shared between
-- engine and scripting system, like screen resolution, graphics settings,
-- editing variables and many others. Besides Lua representation, there
-- is also C++ representation. Lua is there just to minimize number
-- of stack changes - values are sync only when needed.<br/><br/>
-- The "storage" is a class, which has an instance called "inst".
-- From that you can get a variable (cc.engine_variables.inst.foo)
-- or set (cc.engine_variables.inst.foo = 5). VAR_I, VAR_F and VAR_S
-- are simple integers reflecting C++ enumeration. _VAR is the skeleton
-- for variable, IVAR, FVAR and SVAR inherit it in proper way.
-- To make things shorter, you don't have to get variables specifying
-- full module prefix. The global table _G has a metatable set, so
-- you can get / set variables as if they were global.
-- @class module
-- @name cc.engine_variables
module("cc.engine_variables")

-- Variable types

--- Variable types. (not table)
-- @class table
-- @name vartypes
-- @field VAR_I Integer variable.
-- @field VAR_F Floating point number variable.
-- @field VAR_S String variable.
VAR_I = 0
VAR_F = 1
VAR_S = 2

-- Class for variables

--- The storage class for variables.
-- @class table
-- @name storage
-- @field stor The storage table.
-- @field reg The register function.
-- @field clear The clear function.
storage = class.new()
storage.stor = {}

--- Register a variable into storage.
-- @param v Variable to register (IVAR, FVAR or SVAR)
function storage:reg(v)
    if not v:is_a(_VAR) then
        logging.log(logging.ERROR, "Cannot register variable because wrong class was provided.")
        return nil
    end

    if self.stor[v.name] then return nil end -- do not register registered
    self.stor[v.name] = v

    self:define_getter(v.name, function(self, v) return v.curv end, v)
    self:define_setter(v.name .. "_ns", function(self, v, val) v.curv = val end, v)
    self:define_setter(v.name, function(self, v, val)
        if v:check_bounds(val) then
            v.curv = val
            CAPI.svfl(v.name, v.type, val)
        end
    end, v)
end

--- Clear the storage.
function storage:clear()
    self.stor = {}
end

--- The storage class instance for variables.
-- @class table
-- @name inst
inst = storage()

-- Variable classes

--- Default skeleton variable class.
-- @class table
-- @name _VAR
-- @field __init The constructor.
_VAR = class.new()

--- Constructor for default engine variable skeleton.
-- @param name Name of the variable.
-- @param minv Minimal value.
-- @param curv Default value.
-- @param maxv Maximal value.
-- @param ro Read only.
-- @param alias Will create an alias.
function _VAR:__init(name, minv, curv, maxv, ro, alias)
    base.assert(name, "Cannot register variable: name is missing.")
    self.name = name
    self.minv = minv
    self.maxv = maxv
    self.curv = curv
    self.ro = ro
    self.alias = alias
end

--- Integer variable class.
-- @class table
-- @name IVAR
-- @field __init The constructor.
-- @field __tostring Returns string representation.
-- @field check_bounds Returns true if value to set is in variable bounds.
IVAR = class.new(_VAR)

--- Returns string representation of the variable class.
-- @return A string representing the variable class.
function IVAR:__tostring() return "IVAR" end

--- Constructor for integer variable.
-- @param name Name of the variable.
-- @param minv Minimal value.
-- @param curv Default value.
-- @param maxv Maximal value.
-- @param ro Read only.
-- @param alias Will create an alias.
function IVAR:__init(name, minv, curv, maxv, ro, alias)
    base.assert(base.type(minv) == "number"
            and base.type(curv) == "number"
            and base.type(maxv) == "number",
       "Wrong value type provided to IVAR.")

    _VAR.__init(self, name, minv, curv, maxv, ro, alias)
    self.type = VAR_I
end

--- Checks if value to set is in variable bounds.
-- @param v Value to set.
-- @return True if the value can be set, otherwise false.
function IVAR:check_bounds(v)
    if base.type(v) ~= "number" then
        logging.log(logging.ERROR, "Wrong value type passed to variable.")
        return false
    end
    if self.alias then return true end
    if self.ro then
        logging.log(logging.ERROR, "Variable is read only.")
        return false
    end
    if v < self.minv or v > self.maxv then
        logging.log(logging.ERROR,
                    "Variable accepts only values of range "
                    .. self.minv .. " to " .. self.maxv)
        return false
    end
    return true
end

--- Float variable class. Inherited from IVAR, takes its check_bounds.
-- @class table
-- @name FVAR
-- @field __init The constructor.
-- @field __tostring Returns string representation.
-- @field check_bounds Returns true if value to set is in variable bounds.
FVAR = class.new(IVAR)

--- Returns string representation of the variable class.
-- @return A string representing the variable class.
function FVAR:__tostring() return "FVAR" end

--- Constructor for float variable.
-- @param name Name of the variable.
-- @param minv Minimal value.
-- @param curv Default value.
-- @param maxv Maximal value.
-- @param ro Read only.
-- @param alias Will create an alias.
function FVAR:__init(name, minv, curv, maxv, ro, alias)
    base.assert(base.type(minv) == "number"
            and base.type(curv) == "number"
            and base.type(maxv) == "number",
       "Wrong value type provided to FVAR.")

    _VAR.__init(self, name, minv, curv, maxv, ro, alias)
    self.type = VAR_F
end

--- String variable class.
-- @class table
-- @name FVAR
-- @field __init The constructor.
-- @field __tostring Returns string representation.
-- @field check_bounds Returns true if value to set is in variable bounds.
SVAR = class.new(_VAR)

--- Returns string representation of the variable class.
-- @return A string representing the variable class.
function SVAR:__tostring() return "SVAR" end

--- Constructor for string variable.
-- @param name Name of the variable.
-- @param curv Default value.
-- @param ro Read only.
-- @param alias Will create an alias.
function SVAR:__init(name, curv, ro, alias)
    base.assert(base.type(curv) == "string" or not curv, "Wrong value type provided to SVAR.")
    _VAR.__init(self, name, nil, curv, nil, ro, alias)
    self.type = VAR_S
end

--- Checks if value to set is in variable bounds.
-- @param v Value to set.
-- @return True if the value can be set, otherwise false.
function SVAR:check_bounds(v)
    if base.type(v) ~= "string" then
        logging.log(logging.ERROR, "Wrong value type passed to variable.")
        return false
    end
    if self.alias then return true end
    if self.read then
        logging.log(logging.ERROR, "Variable is read only.")
        return false
    end
    return true
end

-- Some wrappers mainly for C++ to simplify registering.
function ivar(name, ...) inst:reg(IVAR(name, ...)) end
function fvar(name, ...) inst:reg(FVAR(name, ...)) end
function svar(name, ...) inst:reg(SVAR(name, ...)) end

--- Reset an engine variable.
-- @param n Name of the variable.
-- @class function
-- @name reset
reset = CAPI.resetvar

--- Doesn't do anything for now. TODO - implement,
-- though not important to do at this moment.
-- @class function
-- @name new
new = CAPI.newvar
