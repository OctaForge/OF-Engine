--[[!
    File: library/core/std/entities/ents_basic.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Implements a basic entity set. Injects directly into the "ents" module.
]]

local M = ents

local Entity = M.Entity

local bor = math.bor

--[[! Class: Physical_Entity
    Represents a base for every entity that has some kind of physical
    representation in the world. This entity class never gets registered.

    Properties:
        animation [<svars.State_Integer>] - the entity's current animation.
        start_time [<svars.State_Integer>] - an internal property used e.g.
        when rendering models.
        model_name [<svars.State_String>] - name of the model associated with
        this entity.
        attachments [<svars.State_Array>] - an array of model attachments.
        Those are strings in format "tagname,attachmentname".
]]
M.Physical_Entity = Entity:clone {
    name = "Physical_Entity",

    properties = {
        animation = svars.State_Integer {
            setter = "CAPI.setanim", client_set = true
        },
        start_time  = svars.State_Integer { getter = "CAPI.getstarttime"   },
        model_name  = svars.State_String  { setter = "CAPI.setmodelname"   },
        attachments = svars.State_Array   { setter = "CAPI.setattachments" } 
    },

    init = SERVER and function(self, uid, kwargs)
        Entity.init(self, uid, kwargs)

        self.model_name  = ""
        self.attachments = {}
        self.animation   = bor(model.ANIM_IDLE, model.ANIM_LOOP)
    end or nil,

    activate = SERVER and function(self, kwargs)
        log(DEBUG, "Physical_Entity.activate")
        Entity.activate(self, kwargs)

        self.model_name = self.model_name
        log(DEBUG, "Physical_Entity.activate complete")
    end or nil,

    --[[! Function: set_local_animation
        Sets the animation property locally, without notifying the other side.
        Useful when allowing actions to animate the entity (as we mostly
        don't need the changes to reflect elsewhere).
    ]]
    set_local_animation = function(self, anim)
        CAPI.setanim(self, anim)
        self.svar_values["animation"] = anim
    end,

    --[[! Function: set_local_model_name
        Sets the model name property locally, without notifying the other side.
    ]]
    set_local_model_name = function(self, mname)
        CAPI.setmodelname(self, mname)
        self.svar_values["model_name"] = mname
    end,

    --[[! Function: setup
        In addition to regular setup, registers the center property
        (using <get_center> as a getter).
    ]]
    setup = function(self)
        Entity.setup(self)
        self:define_getter("center", self.get_center)
    end,

    --[[! Function: get_center
        See <Character.get_center>. This does nothing, serving simply
        as a getter registration placeholder.
    ]]
    get_center = function(self) end
}

--[[! Class: Local_Animation_Action
    Action that starts, sets its actor's animation to its local_animation
    property, runs, ends and sets back the old animation. Not too useful
    alone, but can be used for inheriting.
]]
M.Local_Animation_Action = actions.Action:clone {
    name = "Local_Animation_Action",

    --[[! Function: start
        Gives its actor the new animation. Uses
        <Physical_Entity.set_local_animation>.
    ]]
    start = function(self)
        local ac = self.actor
        self.old_animation = ac.animation
        ac:set_local_animation(self.local_animation)
    end,

    --[[! Function: finish
        Resets the animation back.
    ]]
    finish = function(self)
        local ac = self.actor
        if ac.animation == self.local_animation then
            ac:set_local_animation(self.old_animation)
        end
    end
}