--[[!
    File: library/core/base/base_ent_anim.lua

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
base_animated = ents.Entity:clone {
    name = "base_animated",

    properties = {
        animation = svars.State_Integer {
            setter = "CAPI.setanim",
            client_set = true
        },
        start_time = svars.State_Integer {
            getter = "CAPI.getstarttime"
        },
        model_name = svars.State_String {
            setter = "CAPI.setmodelname"
        },
        attachments = svars.State_Array {
            setter  = "CAPI.setattachments"
        }
    },

    --! Function: init
    --! See <base_server.init>.
    init = function(self, uid, kwargs)
        -- just in case
        if  ents.Entity.init then
            ents.Entity.init(self, uid, kwargs)
        end

        self._attachments_dict = {}

        self.model_name  = ""
        self.attachments = {}
        self.animation   = math.bor(model.ANIM_IDLE, model.ANIM_LOOP)
    end,

    --! Function: activate
    --! See <base_server.activate>.
    --!
    --! Note: Queues model_name property for updating.
    activate = SERVER and function(self, kwargs)
        -- call parent
        log(DEBUG, "base:activate")
        ents.Entity.activate(self, kwargs)

        -- queue model_name for updating
        log(DEBUG, "base:activate (2)")
        self.model_name = self.model_name

        log(DEBUG, "base:activate complete")
    end or nil,

    --[[!
        Function: set_attachment
        Sets model attachment for entity.
        Updates internal attachments dictionary.
        Updates "attachments" entity property.

        Parameters:
            tag - name of tag to attach model to.
            model_name - path to the model to attach.
            If it's nil, the attachment gets removed.
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
        Sets local animation (that means, updates "animation"
        property locally, just in value table). The animation
        gets updated in the engine as well.

        Parameters:
            animation - see ANIM variables in <actions>.
    ]]
    set_local_animation = function(self, animation)
        CAPI.setanim(self, animation)
        -- store value so reading of self.animation returns the value
        self.svar_values["animation"] = animation
    end,


    --[[!
        Function: set_local_model_name
        Sets model_name state variable locally and updates theengine.

        Parameters:
            model_name - the model path to set.
    ]]
    set_local_model_name = function(self, model_name)
        CAPI.setmodelname(self, model_name)
        self.svar_values["model_name"] = model_name
    end,

    --[[!
        Function: setup
        Overriden general setup method. Calls the parent and defines
        new "center" getter (see <get_center>).
    ]]
    setup = function(self)
        ents.Entity.setup(self)
        self:define_getter("center", self.get_center)
    end,

    --[[!
        Function: get_center
        See <character.get_center>. This method is empty here,
        used just for the new getter done in <setup> work.
    ]]
    get_center = function(self) end
}

--[[!
    Class: action_local_animation
    Action that sets a local animation on start and restores the original
    on finish. Useful for inheriting (some actions in <firing> and <health>
    do that). Inherits from <action>.
]]
action_local_animation = actions.Action:clone {
    name = "action_local_animation",

    --[[!
        Function: start
        See <action.start>. This overriden method saves
        actor's old animation, gives actor its own animation and ends.
    ]]
    start = function(self)
        self.old_animation = self.actor.animation
        self.actor:set_local_animation(self.local_animation)
    end,

    --[[!
        Function: finish
        See <action.finish>. This just restores actor's animation from saved.
    ]]
    finish = function(self)
        if self.actor.animation == self.local_animation then
            self.actor:set_local_animation(self.old_animation)
        end
    end
}
