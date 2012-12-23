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

local band, bor, lsh, rsh = math.band, math.bor, math.lsh, math.rsh
local assert, unpack = assert, unpack

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
local Physical_Entity = Entity:clone {
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
M.Physical_Entity = Physical_Entity

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

--[[! Class: Character
    Represents the base class for any character (NPC, player etc.). Players
    use the <Player> entity class that inherits from this one.
    Inherited property model_name defaults to "player".

    This entity class defines several more properties that do not belong to any
    state variable. These mostly correspond to client_state == <State>.*.
    More will be defined later as needed.

    Non-svar properties:
        ping - the client ping.
        plag - the client plag.
        editing - client_state == EDITING.
        lagged - client_state == LAGGED.

    Properties:
        character_name [<svars.State_String>] - name of the character.
        facing_speed [<svars.State_Integer>] - how fast can the character
        change facing (yaw/pitch) in degrees per second. Defaults to 120.
        movement_speed [<svars.State_Float>] - how fast the character can move.
        Defaults to 50.
        yaw [<svars.State_Float>] - the current character yaw in degrees.
        pitch [<svars.State_Float>] - the current character pitch in degrees.
        move [<svars.State_Integer>] - -1 when moving backwards, 0 when not
        moving, 1 when forward.
        strafe [<svars.State_Integer>] - -1 when strafing left, 0 when not
        strafing, 1 when right.
        yawing [<svars.State_Integer>] - -1 when turning left, 1 when right,
        0 when not at all.
        pitching [<svars.State_Integer>] - -1 when looking down, 1 when up,
        0 when not.
        position [<svars.State_Vec3>] - the current position. Defaults to
        { 512, 512, 550 }.
        velocity [<svars.State_Vec3>] - the current velocity.
        falling [<svars.State_Vec3>] - the character's gravity falling.
        radius [<svars.State_Float>] - the character's bounding box radius.
        Defaults to 3.0.
        above_eye [<svars.State_Float>] - the height of the character above
        its eyes. Defaults to 1.0.
        eye_height [<svars.State_Float>] - the distance from the ground to
        the eye position. Defaults to 14.0.
        blocked [<svars.State_Boolean>] - true when the character is currently
        blocked from moving. Floor is not considered an obstacle.
        can_move [<svars.State_Boolean>] - when false, the character can't
        move. Defaults to true.
        map_defined_position_data [<svars.State_Integer>] - position protocol
        data specific to the current map, see fpsent (TODO: make unsigned).
        client_state [<svars.State_Integer>] - see <State>.
        physical_state [<svars.State_Integer>] - see <Physical_State>.
        in_water [<svars.State_Integer>] - 1 when the character is underwater,
        TODO: make boolean.
        time_in_air [<svars.State_Integer>] - time in milliseconds spent in
        the air (TODO: unsigned).
]]
local Character = Physical_Entity:clone {
    name = "Character",

    --[[! Variable: sauer_type
        Dynamic entities correspond to fpsent.
    ]]
    sauer_type = "fpsent",

    --[[! Variable: State
        Defines the "client states". 0 is ALIVE, 1 is DEAD, 2 is SPAWNING,
        3 is LAGGED, 4 is EDITING, 5 is SPECTATOR.
    ]]
    State = {
        ALIVE = 0, DEAD = 1, SPAWNING = 2, LAGGED = 3, EDITING = 4,
        SPECTATOR = 5
    },

    --[[! Variable: Physical_State
        Defines the "physical states". 0 is FLOATING, 1 is FALLING,
        2 is SLIDING, 3 is SLOPING, 4 is ON_FLOOR, 5 is STEPPING_UP,
        6 is STEPPING_DOWN, 7 is BOUNCING.
    ]]
    Physical_State = {
        FLOATING = 0, FALLING = 1, SLIDING = 2, SLOPING = 3,
        ON_FLOOR = 4, STEPPING_UP = 5, STEPPING_DOWN = 6, BOUNCING = 7
    },

    properties = {
        character_name = svars.State_String(),
        facing_speed   = svars.State_Integer(),

        movement_speed = svars.State_Float {
            getter = "CAPI.getmaxspeed", setter = "CAPI.setmaxspeed"
        },
        yaw = svars.State_Float {
            getter = "CAPI.getyaw", setter = "CAPI.setyaw",
            custom_sync = true
        },
        pitch = svars.State_Float {
            getter = "CAPI.getpitch", setter = "CAPI.setpitch",
            custom_sync = true
        },
        move = svars.State_Integer {
            getter = "CAPI.getmove", setter = "CAPI.setmove",
            custom_sync = true
        },
        strafe = svars.State_Integer {
            getter = "CAPI.getstrafe", setter = "CAPI.setstrafe",
            custom_sync = true
        },
        yawing = svars.State_Integer {
            getter = "CAPI.getyawing", setter = "CAPI.setyawing",
            custom_sync = true
        },
        pitching = svars.State_Integer {
            getter = "CAPI.getpitching", setter = "CAPI.setpitching",
            custom_sync = true
        },
        position = svars.State_Vec3 {
            getter = "CAPI.getdynent0", setter = "CAPI.setdynent0",
            custom_sync = true
        },
        velocity = svars.State_Vec3 {
            getter = "CAPI.getdynentvel", setter = "CAPI.setdynentvel",
            custom_sync = true
        },
        falling = svars.State_Vec3 {
            getter = "CAPI.getdynentfalling", setter = "CAPI.setdynentfalling",
            custom_sync = true
        },
        radius = svars.State_Float {
            getter = "CAPI.getradius", setter = "CAPI.setradius"
        },
        above_eye = svars.State_Float {
            getter = "CAPI.getaboveeye", setter = "CAPI.setaboveeye"
        },
        eye_height = svars.State_Float {
            getter = "CAPI.geteyeheight", setter = "CAPI.seteyeheight"
        },
        blocked = svars.State_Boolean {
            getter = "CAPI.getblocked", setter = "CAPI.setblocked"
        },
        can_move = svars.State_Boolean {
            setter = "CAPI.setcanmove", client_set = true
        },
        map_defined_position_data = svars.State_Integer {
            getter = "CAPI.getmapdefinedposdata",
            setter = "CAPI.setmapdefinedposdata",
            custom_sync = true
        },
        client_state = svars.State_Integer {
            getter = "CAPI.getclientstate", setter = "CAPI.setclientstate",
            custom_sync = true
        },
        physical_state = svars.State_Integer {
            getter = "CAPI.getphysstate", setter = "CAPI.setphysstate",
            custom_sync = true
        },
        in_water = svars.State_Integer {
            getter = "CAPI.getinwater", setter = "CAPI.setinwater",
            custom_sync = true
        },
        time_in_air = svars.State_Integer {
            getter = "CAPI.gettimeinair", setter = "CAPI.settimeinair",
            custom_sync = true
        }
    },

    --[[! Function: jump
        A handler called when the character is about to jump.
    ]]
    jump = function(self)
        CAPI.setjumping(self, true)
    end,

    get_plag = function(self) return CAPI.getplag(self) end,
    get_ping = function(self) return CAPI.getping(self) end,
    get_editing = function(self) return self.client_state == 4 end,
    get_lagged = function(self) return self.client_state == 3 end,

    init = SERVER and function(self, uid, kwargs)
        Physical_Entity.init(self, uid, kwargs)

        self.character_name = "none"
        self.cn             = kwargs and kwargs.cn or -1
        self.model_name     = "player"
        self.eye_height     = 14.0
        self.above_eye      = 1.0
        self.movement_speed = 50.0
        self.facing_speed   = 120
        self.position       = { 512, 512, 550 }
        self.radius         = 3.0
        self.can_move       = true

        self:define_getter("plag", self.get_plag)
        self:define_getter("ping", self.get_ping)
        self:define_getter("editing", self.get_editing)
        self:define_getter("lagged", self.get_lagged)
    end or nil,

    activate = SERVER and function(self, kwargs)
        self.cn = kwargs and kwargs.cn or -1
        assert(self.cn >= 0)
        CAPI.setupcharacter(self)

        Physical_Entity.activate(self, kwargs)

        self:flush_queued_svar_changes()
    end or function(self, kwargs)
        Physical_Entity.activate(self, kwargs)

        self.cn = kwargs and kwargs.cn or -1
        CAPI.setupcharacter(self)

        self.render_args_timestamp = -1
    end,

    deactivate = function(self)
        CAPI.dismantlecharacter(self)
        Physical_Entity.deactivate(self)
    end,

    --[[! Function: render
        Clientside and run per frame. It renders the character model. Decides
        all the parameters, including animation etc., but not every frame -
        they're cached by self.rendering_args_timestamp (they're only
        recomputed when this timestamp changes).

        When rendering HUD (determined by the paramters hudpass, which
        determines whether we're rendering HUD right now, and needhud,
        which determines whether we're in first person mode), the member
        hud_model_offset (vec3) is used to offset the HUD model (if available).
    ]]
    render = CLIENT and function(self, hudpass, needhud)
        if not self.initialized then return nil end
        if not hudpass and needhud then return nil end

        local ra = self.render_args
        local fr = frame.get_frame()
        if self.render_args_timestamp ~= fr then
            local state = self.client_state
            -- spawning or spectator
            if state == 5 or state == 2 then return nil end
            local mdn = (hudpass and needhud) and self.hud_model_name
                or self.model_name

            local yaw, pitch = self.yaw + 90, self.pitch
            local o = self.position:copy()

            if hudpass and needhud and self.hud_model_offset then
                o:add(self.hud_model_offset)
            end

            local pstate = self.physical_state
            local bt, iw = self.start_time, self.in_water
            local mv, sf = self.move, self.strafe

            local vel, fall = self.velocity:copy(), self.falling:copy()
            local tia = self.time_in_air

            local anim = self:decide_animation(state, pstate, mv, sf, vel,
                fall, iw, tia)
            local flags = self:get_render_flags(hudpass, needhud)

            if not ra then
                ra = { self, "", true, true, true, true, true, true }
                self.render_args = ra
            end

            ra[2], ra[3], ra[4], ra[5], ra[6], ra[7], ra[8] =
                mdn, anim, o, yaw, pitch, flags, bt
            self.render_args_timestamp = fr
        end
        if (ra and ra[2] ~= "") then model.render(unpack(ra)) end
    end or nil,

    --[[! Function: get_render_flags
        Returns the rendering flags used when rendering the character. By
        default, it enables some occlusion stuff. Override as needed,
        the parameters are hudpass (whether we're rendering HUD right now)
        and needhud (whether we're in first person mode). Called from <render>.
        Clientside.
    ]]
    get_render_flags = CLIENT and function(self, hudpass, needhud)
        local flags = model.FULLBRIGHT
        if self ~= M.get_player() then
            flags = bor(model.CULL_VFC, model.CULL_OCCLUDED, model.CULL_QUERY)
        end
        return flags
    end or nil,

    --[[! Function: decide_animation
        Decides the current animation for the character. Starts with
        <get_animation>, then adjusts it to take things like moving,
        strafing, swimming etc into account.

        Passed arguments are client_state, physical_state, move, strafe,
        velocity, falling, in_water and time_in_air (same as the state
        variables).
    ]]
    decide_animation = CLIENT and function(self, state, pstate, move, strafe,
    vel, falling, inwater, tinair)
        local anim = self:get_animation()

        -- editing or spectator
        if state == 4 or state == 5 then
            anim = bor(model.ANIM_EDIT, model.ANIM_LOOP)
        -- lagged
        elseif state == 3 then
            anim = bor(model.ANIM_LAG, model.ANIM_LOOP)
        else
            -- in water and floating or falling
            if inwater ~= 0 and pstate <= 1 then
                anim = bor(anim, lsh(
                    bor(((move or strafe) or ((vel.z + falling.z) > 0))
                        and model.ANIM_SWIM or model.ANIM_SINK,
                    model.ANIM_LOOP),
                    model.ANIM_SECONDARY))
            -- jumping animation
            elseif tinair > 250 then
                anim = bor(anim, lsh(bor(model.ANIM_JUMP, model.ANIM_END),
                    model.ANIM_SECONDARY))
            -- moving or strafing
            elseif move ~= 0 or strafe ~= 0 then
                if move > 0 then
                    anim = bor(anim, lsh(bor(model.ANIM_FORWARD,
                        model.ANIM_LOOP), model.ANIM_SECONDARY))
                elseif strafe ~= 0 then
                    anim = bor(anim, lsh(bor((strafe > 0 and model.ANIM_LEFT
                        or model.ANIM_RIGHT), model.ANIM_LOOP),
                        model.ANIM_SECONDARY))
                elseif move < 0 then
                    anim = bor(anim, lsh(bor(model.ANIM_BACKWARD,
                        model.ANIM_LOOP), model.ANIM_SECONDARY))
                end
            end

            if band(anim, model.ANIM_INDEX) == model.ANIM_IDLE and
            band(rsh(anim, model.ANIM_SECONDARY), model.ANIM_INDEX) ~= 0 then
                anim = rsh(anim, model.ANIM_SECONDARY)
            end
        end

        if band(rsh(anim, model.ANIM_SECONDARY), model.ANIM_INDEX) == 0 then
            anim = bor(anim, lsh(bor(model.ANIM_IDLE, model.ANIM_LOOP),
                model.ANIM_SECONDARY))
        end
        return anim
    end or nil,

    --[[! Function: get_animation
        Gets the character's current "action" animation. By default just
        returns self.animation. Override as needed. Client only.
    ]]
    get_animation = CLIENT and function(self)
        return self.animation
    end or nil,

    --[[! Function: get_center
        Gets the center position of a character, something like gravity center
        (approximate). Useful for e.g. bots (better to aim at this position,
        the actual "position" is feet position). Override if you need this
        non-standard. By default it's 0.75 * eye_height above feet.
    ]]
    get_center = function(self)
        local r = self.position:copy()
        r.z = r.z + self.eye_height * 0.75
        return r
    end,

    --[[! Function: get_targeting_origin
        Given an origin position (e.g. from an attachment tag), this method
        is supposed to fix it so that it corresponds to where player actually
        targeted from. By default just returns origin.
    ]]
    get_targeting_origin = function(self, origin)
        return origin
    end
}
M.Character = Character

--[[! Class: Player
    The default entity class for player. Inherits from <Character>. Adds
    two new properties.

    Properties:
        can_edit [false] - if player can edit, it's true (private edit mode).
        hud_model_name [""] - the first person model to use for the player.
]]
local Player = Character:clone {
    name = "Player",

    properties = {
        can_edit = svars.State_Boolean(),
        hud_model_name = svars.State_String()
    },

    init = SERVER and function(self, uid, kwargs)
        Character.init(self, uid, kwargs)

        self.can_edit       = false
        self.hud_model_name = ""
    end or nil
}
M.Player = Player

ents.register_class(Character)
ents.register_class(Player)