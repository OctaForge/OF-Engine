---
-- base_animatable.lua, version 1<br/>
-- Animatable entity and animation action for Lua<br/>
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
local math = require("math")
local log = require("cc.logging")
local svar = require("cc.state_variables")
local lent = require("cc.logent")
local class = require("cc.class")
local act = require("cc.action")
local mdl = require("cc.model")

--- This module takes care of animatable logic entity and animation action.
-- @class module
-- @name cc.animatable
module("cc.animatable")

animatable_logent = class.new(lent.logent)
animatable_logent._class = "animatable_logent"

animatable_logent.properties = {
    lent.logent.properties[1], -- tags
    lent.logent.properties[2], -- _persistent
    { "animation", svar.wrapped_cinteger({ csetter = "CAPI.setanim", clientset = true }) },
    { "starttime", svar.wrapped_cinteger({ cgetter = "CAPI.getstarttime" }) },
    { "modelname", svar.wrapped_cstring ({ csetter = "CAPI.setmodelname" }) },
    { "attachments", svar.wrapped_carray({ csetter = "CAPI.setattachments" }) }
}

function animatable_logent:init(uid, kwargs)
    if lent.logent.init then lent.logent.init(self, uid, kwargs) end

    self._attachments_dict = {}

    self.modelname = ""
    self.attachments = {}
    self.animation = math.bor(act.ANIM_IDLE, act.ANIM_LOOP)
end

function animatable_logent:activate(kwargs)
    log.log(log.DEBUG, "animatable_logent:activate")
    lent.logent.activate(self, kwargs)

    log.log(log.DEBUG, "animatable_logent:activate (2)")
    self.modelname = self.modelname

    log.log(log.DEBUG, "animatable_logent:activate complete")
end

function animatable_logent:set_attachment(tag, mdlname)
    if not mdlname then
        if self._attachments_dict[base.tostring(tag)] then
            self._attachments_dict[base.tostring(tag)] = nil
        end
    else
        self._attachments_dict[base.tostring(tag)] = mdlname
    end

    local r = {}
    for k, v in base.pairs(self._attachments_dict) do
        table.insert(r, mdl.attachment(base.tostring(k), base.tostring(v)))
    end
    self.attachments = r
end

function animatable_logent:set_localanim(anim)
    CAPI.setanim(self, anim)
    self.state_var_vals["animation"] = anim -- store value so reading of self.animation returns the value
end

function animatable_logent:set_localmodelname(mdlname)
    CAPI.setmodelname(self, mdlname)
    self.state_var_vals["modelname"] = mdlname
end

function animatable_logent:_general_setup(...)
    lent.logent._general_setup(self)
    self:define_getter("center", self.get_center)
end

action_localanim = class.new(act.action)
function action_localanim:__tostring() return "action_localanim" end

function action_localanim:dostart()
    self.oldanim = self.actor.animation
    self.actor:set_localanim(self.localanim)
end

function action_localanim:dofinish()
    if self.actor.animation == self.localanim then
        self.actor:set_localanim(self.oldanim)
    end
end
