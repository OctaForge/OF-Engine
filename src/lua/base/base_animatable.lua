---
-- base_animatable.lua, version 1<br/>
-- Animatable entity and animation action for Lua<br/>
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

--- This module takes care of animatable logic entity and animation action.
-- @class module
-- @name of.animatable
module("of.animatable", package.seeall)

--- Base animatable logic entity class, not meant to be used directly.
-- @class table
-- @name animatable_logent
animatable_logent = class.new(of.logent.logent)
animatable_logent._class = "animatable_logent"

--- Base properties of animatable logic entity.
-- Inherits properties of root_logent plus adds its own.
-- @field animation Entity animation.
-- @field starttime Internal parameter. Not meant to be modified in any way.
-- @field modelname Model name assigned to the entity.
-- @field attachments Model attachments for the entity.
-- @class table
-- @name animatable_logent.properties
animatable_logent.properties = {
    of.logent.logent.properties[1], -- tags
    of.logent.logent.properties[2], -- _persistent
    { "animation", of.state_variables.wrapped_cinteger({ csetter = "CAPI.setanim", clientset = true }) },
    { "starttime", of.state_variables.wrapped_cinteger({ cgetter = "CAPI.getstarttime" }) },
    { "modelname", of.state_variables.wrapped_cstring ({ csetter = "CAPI.setmodelname" }) },
    { "attachments", of.state_variables.wrapped_carray({ csetter = "CAPI.setattachments" }) }
}

--- Init method for animatable logic entity. Performs initial setup.
-- @param uid Unique ID for the entity.
-- @param kwargs Table of additional parameters (for i.e. overriding _persistent)
function animatable_logent:init(uid, kwargs)
    if of.logent.logent.init then of.logent.logent.init(self, uid, kwargs) end

    self._attachments_dict = {}

    self.modelname = ""
    self.attachments = {}
    self.animation = math.bor(actions.ANIM_IDLE, actions.ANIM_LOOP)
end

--- Serverside entity activation.
-- @param kwargs Table of additional parameters.
function animatable_logent:activate(kwargs)
    of.logging.log(of.logging.DEBUG, "animatable_logent:activate")
    of.logent.logent.activate(self, kwargs)

    of.logging.log(of.logging.DEBUG, "animatable_logent:activate (2)")
    self.modelname = self.modelname

    of.logging.log(of.logging.DEBUG, "animatable_logent:activate complete")
end

--- Set model attachment for entity. Connected with "attachments" property.
-- @param tag Model tag.
-- @param mdlname Model name.
function animatable_logent:set_attachment(tag, mdlname)
    if not mdlname then
        if self._attachments_dict[tostring(tag)] then
            self._attachments_dict[tostring(tag)] = nil
        end
    else
        self._attachments_dict[tostring(tag)] = mdlname
    end

    local r = {}
    for k, v in pairs(self._attachments_dict) do
        table.insert(r, of.model.attachment(tostring(k), tostring(v)))
    end
    self.attachments = r
end

--- Set local animation (override value in state_var_vals).
-- @param anim Animation number. See base_actions documentation.
function animatable_logent:set_localanim(anim)
    CAPI.setanim(self, anim)
    self.state_var_vals["animation"] = anim -- store value so reading of self.animation returns the value
end

--- Set local model name (override value in state_var_vals).
-- @param mdlname Model name.
function animatable_logent:set_localmodelname(mdlname)
    CAPI.setmodelname(self, mdlname)
    self.state_var_vals["modelname"] = mdlname
end

--- General setup method. Called on initialization.
function animatable_logent:_general_setup(...)
    of.logent.logent._general_setup(self)
    self:define_getter("center", self.get_center)
end

--- Local animation action.
-- @class table
-- @name action_localanim
action_localanim = class.new(actions.action)

--- Return string representation of action.
-- @return String representation of action.
function action_localanim:__tostring() return "action_localanim" end

--- Overriden dostart method called on action start.
-- Sets local animation for actor.
function action_localanim:dostart()
    self.oldanim = self.actor.animation
    self.actor:set_localanim(self.localanim)
end

--- Finalizer method taking care of setting original pre-start animation.
function action_localanim:dofinish()
    if self.actor.animation == self.localanim then
        self.actor:set_localanim(self.oldanim)
    end
end
