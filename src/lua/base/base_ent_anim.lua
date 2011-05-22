--[[!
    File: base/base_ent_anim.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features animatable logic entity class.

    Section: Animatable entity system
]]

--[[!
    Package: entity_animated
    This module handles animatable entities. It contains base animatable entity
    class from which BOTH static and dynamic entities (character) inherit.
]]
module("entity_animated", package.seeall)

--- Base animatable logic entity class, not meant to be used directly.
-- @class table
-- @name animatable_logent
animatable_logent = class.new(entity.logent)
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
    animation = state_variables.wrapped_cinteger({ csetter = "CAPI.setanim", clientset = true }),
    starttime = state_variables.wrapped_cinteger({ cgetter = "CAPI.getstarttime" }),
    modelname = state_variables.wrapped_cstring ({ csetter = "CAPI.setmodelname" }),
    attachments = state_variables.wrapped_carray({ csetter = "CAPI.setattachments" })
}

--- Init method for animatable logic entity. Performs initial setup.
-- @param uid Unique ID for the entity.
-- @param kwargs Table of additional parameters (for i.e. overriding _persistent)
function animatable_logent:init(uid, kwargs)
    if entity.logent.init then entity.logent.init(self, uid, kwargs) end

    self._attachments_dict = {}

    self.modelname = ""
    self.attachments = {}
    self.animation = math.bor(actions.ANIM_IDLE, actions.ANIM_LOOP)
end

--- Serverside entity activation.
-- @param kwargs Table of additional parameters.
function animatable_logent:activate(kwargs)
    logging.log(logging.DEBUG, "animatable_logent:activate")
    entity.logent.activate(self, kwargs)

    logging.log(logging.DEBUG, "animatable_logent:activate (2)")
    self.modelname = self.modelname

    logging.log(logging.DEBUG, "animatable_logent:activate complete")
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
        table.insert(r, model.attachment(tostring(k), tostring(v)))
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
    entity.logent._general_setup(self)
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
