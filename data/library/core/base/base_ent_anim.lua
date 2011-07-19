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
]]

--[[!
    Package: entity_animated
    This module handles animatable entities. It contains base animatable entity
    class from which BOTH static and dynamic entities (character) inherit.
]]
module("entity_animated", package.seeall)

--[[!
    Class: base_animated
    This represents the base class for all animated and static entities.

    Properties:
        animation - entity animation.
        start_time - internal property, used when i.e. rendering models.
        model_name - path to model assigned to this entity.
        attachments - model attachments for the entity.
]]
base_animated = class.new(entity.base, {
    --! Variable: _class
    --! See <base_root._class>
    _class = "base_animated",

    properties = {
        animation   = state_variables.wrapped_c_integer({ c_setter = "CAPI.setanim", client_set = true }),
        start_time  = state_variables.wrapped_c_integer({ c_getter = "CAPI.getstarttime" }),
        model_name  = state_variables.wrapped_c_string ({ c_setter = "CAPI.setmodelname" }),
        attachments = state_variables.wrapped_c_array  ({ c_setter = "CAPI.setattachments" })
    },

    --! Function: init
    --! See <base_server.init>.
    init = function(self, uid, kwargs)
        -- just in case
        if  entity.base.init then
            entity.base.init(self, uid, kwargs)
        end

        self._attachments_dict = {}

        self.model_name  = ""
        self.attachments = {}
        self.animation   = math.bor(actions.ANIM_IDLE, actions.ANIM_LOOP)
    end,

    --! Function: activate
    --! See <base_server.activate>.
    --!
    --! Note: Queues model_name property for updating.
    activate = function(self, kwargs)
        -- call parent
        logging.log(logging.DEBUG, "base:activate")
        entity.base.activate(self, kwargs)

        -- queue model_name for updating
        logging.log(logging.DEBUG, "base:activate (2)")
        self.model_name = self.model_name

        logging.log(logging.DEBUG, "base:activate complete")
    end,

    --[[!
        Function: set_attachment
        Sets model attachment for entity. Updates internal attachments dictionary.
        Updates "attachments" entity property.

        Parameters:
            tag - name of tag to attach model to.
            model_name - path to the model to attach. If it's nil, the attachment
            gets removed.
    ]]
    set_attachment = function(self, tag, model_name)
        -- delete the attachment if we don't have the model
        if not model_name then
            if  self._attachments_dict[tag] then
                self._attachments_dict[tag] = nil
            end
        else
            self._attachments_dict[tostring(tag)] = model_name
        end

        -- convert the dictionary to array of properly formatted strings
        local r = {}
        for k, v in pairs(self._attachments_dict) do
            table.insert(r, model.attachment(tostring(k), tostring(v)))
        end

        -- update the state variable
        self.attachments = r
    end,

    --[[!
        Function: set_local_animation
        Sets local animation (that means, updates "animation" property locally, just in
        value table). The animation gets updated in the engine as well.

        Parameters:
            animation - see ANIM variables in <actions>.
    ]]
    set_local_animation = function(self, animation)
        CAPI.setanim(self, animation)
        -- store value so reading of self.animation returns the value
        self.state_variable_values["animation"] = animation
    end,


    --[[!
        Function: set_local_model_name
        Sets model_name state variable locally and updates theengine.

        Parameters:
            model_name - the model path to set.
    ]]
    set_local_model_name = function(self, model_name)
        CAPI.setmodelname(self, model_name)
        self.state_variable_values["model_name"] = model_name
    end,

    --[[!
        Function: general_setup
        Overriden general setup method. Calls the parent and defines
        new "center" getter (see <get_center>).
    ]]
    general_setup = function(self)
        entity.base.general_setup(self)
        self:define_getter("center", self.get_center)
    end,

    --[[!
        Function: get_center
        See <character.get_center>. This method is empty here,
        used just for the new getter done in <general_setup> work.
    ]]
    get_center = function(self) end
})

--[[!
    Class: action_local_animation
    Action that sets a local animation on start and restores the original
    on finish. Useful for inheriting (some actions in <firing> and <health>
    do that). Inherits from <action>.
]]
action_local_animation = class.new(actions.action, {
    --[[!
        Function: do_start
        See <action.do_start>. This overriden method saves actor's old animation,
        gives actor its own animation and ends.
    ]]
    do_start = function(self)
        self.old_animation = self.actor.animation
        self.actor:set_local_animation(self.local_animation)
    end,

    --[[!
        Function: do_finish
        See <action.do_finish>. This just restores actor's animation from saved.
    ]]
    do_finish = function(self)
        if self.actor.animation == self.local_animation then
            self.actor:set_local_animation(self.old_animation)
        end
    end
}, "action_local_animation")
