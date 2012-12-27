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
local assert, unpack, tonumber, tostring = assert, unpack, tonumber, tostring

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
        #log(DEBUG, "Physical_Entity.activate")
        Entity.activate(self, kwargs)

        self.model_name = self.model_name
        #log(DEBUG, "Physical_Entity.activate complete")
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

local st_to_idx = {
    ["none"] = 0, ["light"] = 1, ["mapmodel"] = 2, ["playerstart"] = 3,
    ["envmap"] = 4, ["particles"] = 5, ["sound"] = 6, ["spotlight"] = 7
}

--[[! Class: Static_Entity
    A base for any static entity. Inherits from <Physical_Entity>. Unlike
    dynamic entities (such as <Character>), static entities usually don't
    invoke their "run" method per frame. To re-enable that, set the
    per_frame member to true (false by default for efficiency).

    Static entities are persistent by default, so they set the "persistent"
    inherited property to true. They also have the "sauer_type" member,
    which determines the "physical" type of the entity as in Cube 2,
    it can be "none", "light", "mapmodel", "playerstart", "envmap",
    "particles", "sound" and "spotlight". The default here is "none".

    This entity class is never registered, the inherited ones are.

    Properties:
        radius [<svars.State_Float>] - the entity bounding box radius.
        position [<svars.State_Vec3>] - the entity position.
        attr1 [<svars.State_Integer>] - the first "sauer" entity attribute.
        attr2 [<svars.State_Integer>] - the second "sauer" entity attribute.
        attr3 [<svars.State_Integer>] - the third "sauer" entity attribute.
        attr4 [<svars.State_Integer>] - the fourth "sauer" entity attribute.
        attr5 [<svars.State_Integer>] - the fifth "sauer" entity attribute.
]]
local Static_Entity = Physical_Entity:clone {
    name = "Static_Entity",

    per_frame = false,
    sauer_type = "none",

    properties = {
        radius = svars.State_Float(),
        position = svars.State_Vec3 {
            getter = "CAPI.getextent0", setter = "CAPI.setextent0"
        },
        attr1 = svars.State_Integer {
            getter = "CAPI.getattr1", setter = "CAPI.setattr1"
        },
        attr2 = svars.State_Integer {
            getter = "CAPI.getattr2", setter = "CAPI.setattr2"
        },
        attr3 = svars.State_Integer {
            getter = "CAPI.getattr3", setter = "CAPI.setattr3"
        },
        attr4 = svars.State_Integer {
            getter = "CAPI.getattr4", setter = "CAPI.setattr4"
        },
        attr5 = svars.State_Integer {
            getter = "CAPI.getattr5", setter = "CAPI.setattr5"
        }
    },

    init = function(self, uid, kwargs)
        #log(DEBUG, "Static_Entity.init")

        kwargs = kwargs or {}
        kwargs.persistent = true

        Physical_Entity.init(self, uid, kwargs)
        if not kwargs.position then
            self.position = { 511, 512, 513 }
        else
            self.position = {
                tonumber(kwargs.position.x),
                tonumber(kwargs.position.y),
                tonumber(kwargs.position.z)
            }
        end
        self.radius = 0

        #log(DEBUG, "Static_Entity.init complete")
    end,

    activate = SERVER and function(self, kwargs)
        kwargs = kwargs or {}

        #log(DEBUG, "Static_Entity.activate")
        Physical_Entity.activate(self, kwargs)

        if not kwargs._type then
            kwargs._type = st_to_idx[self.sauer_type]
        end

        kwargs.x = self.position.x or 512
        kwargs.y = self.position.y or 512
        kwargs.z = self.position.z or 512
        kwargs.attr1 = self.attr1 or 0
        kwargs.attr2 = self.attr2 or 0
        kwargs.attr3 = self.attr3 or 0
        kwargs.attr4 = self.attr4 or 0
        kwargs.attr5 = self.attr5 or 0

        #log(DEBUG, "Static_Entity: extent setup")
        CAPI.setupextent(self, kwargs._type, kwargs.x, kwargs.y, kwargs.z,
            kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4,
            kwargs.attr5)

        #log(DEBUG, "Static_Entity: flush")
        self:flush_queued_svar_changes()

        self.position = self.position
        self.attr1, self.attr2, self.attr3 = self.attr1, self.attr2, self.attr3
        self.attr4, self.attr5 = self.attr4, self.attr5
    end or function(self, kwargs)
        if not kwargs._type then
            kwargs._type = st_to_idx[self.sauer_type]
            kwargs.x, kwargs.y, kwargs.z = 512, 512, 512
            kwargs.attr1, kwargs.attr2, kwargs.attr3 = 0, 0, 0
            kwargs.attr4, kwargs.attr5 = 0, 0
        end

        CAPI.setupextent(self, kwargs._type, kwargs.x, kwargs.y, kwargs.z,
            kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4,
            kwargs.attr5)
        return Physical_Entity.activate(self, kwargs)
    end,

    deactivate = function(self)
        CAPI.dismantleextent(self)
        return Physical_Entity.deactivate(self)
    end,

    send_notification_full = SERVER and function(self, cn)
        local acn = msg.ALL_CLIENTS
        cn = cn or acn

        local cns = (cn == acn) and table.map(ents.get_players(), function(p)
            return p.cn end) or { cn }

        local uid = self.uid
        #log(DEBUG, "Static_Entity.send_notification_full: "
        #    .. cn .. ", " .. uid)

        local scn, sname = self.cn, tostring(self)
        for i = 1, #cns do
            local n = cns[i]
            msg.send(n, CAPI.extent_notification_complete,
                uid, sname, self:build_sdata({
                    target_cn = n, compressed = true }),
                tonumber(self.position.x), tonumber(self.position.y),
                tonumber(self.position.z), tonumber(self.attr1),
                tonumber(self.attr2), tonumber(self.attr3),
                tonumber(self.attr4), tonumber(self.attr5))
        end

        #log(DEBUG, "Static_Entity.send_notification_full: done")
    end or nil,

    --[[! Function: get_center
        See <Character.get_center>. In this case, it's self.radius above
        bottom.
    ]]
    get_center = function(self)
        local r = self.position:copy()
        r.z = r.z + self.radius
        return r
    end
}
M.Static_Entity = Static_Entity

--[[! Class: Light
    A regular point light. It has the sauer type "light" and five properties.
    In the extension library there are special light entity types that are
    e.g. triggered, flickering and so on.

    Properties:
        attr1 - light radius. (0 to N, alias "radius", default 100)
        attr2 - red value (0 to 255, alias "red", default 128)
        attr3 - green value (0 to 255, alias "green", default 128)
        attr4 - blue value (0 to 255, alias "blue", default 128)
        attr5 - shadow, 0 dynamic, 1 noshadow, 2 static (default 0)
]]
local Light = Static_Entity:clone {
    name = "Light",

    sauer_type = "light",

    properties = {
        attr1 = svars.State_Integer({
            getter = "CAPI.getattr1", setter = "CAPI.setattr1",
            gui_name = "radius", alt_name = "radius"
        }),
        attr2 = svars.State_Integer({
            getter = "CAPI.getattr2", setter = "CAPI.setattr2",
            gui_name = "red", alt_name = "red"
        }),
        attr3 = svars.State_Integer({
            getter = "CAPI.getattr3", setter = "CAPI.setattr3",
            gui_name = "green", alt_name = "green"
        }),
        attr4 = svars.State_Integer({
            getter = "CAPI.getattr4", setter = "CAPI.setattr4",
            gui_name = "blue", alt_name = "blue"
        }),
        attr5 = svars.State_Integer({
            getter = "CAPI.getattr5", setter = "CAPI.setattr5",
            gui_name = "shadow", alt_name = "shadow"
        })
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.red, self.green, self.blue = 128, 128, 128
        self.radius, self.shadow = 100, 0
    end
}
M.Light = Light

--[[! Class: Spot_Light
    A spot light. It's attached to the nearest <Light>. It has just one
    property, attr1 (alias "radius") which defaults to 90 and is in degrees
    (90 is a full hemisphere, 0 is a line).

    Properties such as color are inherited from the attached light entity.
    Its sauer type is "spotlight".
]]
local Spot_Light = Static_Entity:clone {
    name = "Spot_Light",

    sauer_type = "spotlight",

    properties = {
        attr1 = svars.State_Integer {
            getter = "CAPI.getattr1", setter = "CAPI.setattr1",
            gui_name = "radius", alt_name = "radius"
        }
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.radius = 90
    end
}
M.Spot_Light = Spot_Light

--[[! Class: Envmap
    An environment map entity class. Things reflecting on their surface using
    environment maps can generate their envmap from the nearest envmap entity
    instead of using skybox and reflect geometry that way (statically).

    It has one property, radius, which specifies the distance it'll still
    have effect in. Its sauer type is "envmap".
]]
local Envmap = Static_Entity:clone {
    name = "Envmap",

    sauer_type = "envmap",

    properties = {
        attr1 = svars.State_Integer {
            getter = "CAPI.getattr1", setter = "CAPI.setattr1",
            gui_name = "radius", alt_name = "radius"
        }
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.radius = 128
    end
}
M.Envmap = Envmap

--[[! Class: Sound
    An ambient sound in the world. Repeats the given sound at entity position.
    Its sauer type is "sound".

    Properties:
        attr2 - the sound radius (alias "radius", default 100)
        attr3 - the sound size, if this is 0, the sound is a point source,
        otherwise the sound volume will always be max until the distance
        specified by this property and then it'll start fading off
        (alias "size", default 0).
        attr4 - the sound volume, from 0 to 100 (alias "volume", default 100).
        sound_name [<svars.State_String>] - the  path to the sound in
        data/sounds (default "").
]]
local Sound = Static_Entity:clone {
    name = "Sound",

    sauer_type = "sound",

    properties = {
        attr2 = svars.State_Integer {
            getter = "CAPI.getattr2", setter = "CAPI.setattr2",
            gui_name = "radius", alt_name = "radius"
        },
        attr3 = svars.State_Integer {
            getter = "CAPI.getattr3", setter = "CAPI.setattr3",
            gui_name = "size", alt_name = "size"
        },
        attr4 = svars.State_Integer {
            getter = "CAPI.getattr4", setter = "CAPI.setsoundvol",
            gui_name = "volume", alt_name = "volume"
        },
        sound_name = svars.State_String {
            setter = "CAPI.setsoundname"
        }
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.attr1, self.radius, self.size  = -1, 100, 0
        if not self.volume then self.volume = 100 end
        self.sound_name = ""
    end
}
M.Sound = Sound

--[[! Class: Particle_Effect
    A particle effect entity class. Its sauer type is "particles". It has
    four properties. They all default to 0.

    Properties:
        attr1 - the type of the particle effect (alias "particle_effect").
        attr2 - alias "value1", effect specific.
        attr3 - alias "value2", effect specific.
        attr4 - alias "value3", effect specific.

    Particle types (and their values):

    0 (fire with smoke):
        radius - 0 is default, that equals 100.
        height - 0 is default, that equals 100.
        rgb - 0x000000 is default, that equals 0x903020.

    1 (steam vent):
        direction - 0 to 5.

    2 (water fountain):
        direction - 0 to 5, its color inherits from the water color.

    3 (explosion / fireball):
        size - 0 to 40.
        rgb - 0x000000 to 0xFFFFFF.

    4 (streak / flare):
        direction - 0 to 5.
        length - 0 to 100.
        rgb - 0x000000 to 0xFFFFFF.

    4 (multiple streaks / flares):
       direction - 256 + effect.
       length - 0 to 100.
       rgb - 0x000000 to 0xFFFFFF.

    4 effects:
        0 to 2 - circular.
        3 to 5 - cylinderical shell.
        6 to 11 - conic shell.
        12 to 14 - cubic volume.
        15 to 20 - planar surface.
        21 - sphere.

    5 (capture meter, rgb vs black):
        percentage - 0 to 100.
        rgb - 0x000000 to 0xFFFFFF.

    6 (vs capture meter, rgb vs bgr):
        percentage - 0 to 100.
        rgb - 0x000000 to 0xFFFFFF.

    7 (lightning):
        direction, length, rgb - see 4.

    9 (steam):
        direction, length, rgb - see 4.

    10 (water):
        direction, length, rgb - see 4.

    11 (flames):
        radius, height, rgb, see 0.

    12 (smoke plume):
        radius, height, rgb, see 0.

    32 (plain lens flare):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.

    33 (lens flare with sparkle center):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.

    34 (sun lens flare, i.e. fixed size regardless of distance):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.

    35 (sun lens flare with sparkle center):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.
]]
local Particle_Effect = Static_Entity:clone {
    name = "Particle_Effect",

    sauer_type = "particles",

    properties = {
        attr1 = svars.State_Integer {
            getter = "CAPI.getattr1", setter = "CAPI.setattr1",
            gui_name = "particle_type", alt_name = "particle_type"
        },
        attr2 = svars.State_Integer {
            getter = "CAPI.getattr2", setter = "CAPI.setattr2",
            gui_name = "value1", alt_name = "value1"
        },
        attr3 = svars.State_Integer {
            getter = "CAPI.getattr3", setter = "CAPI.setattr3",
            gui_name = "value2", alt_name = "value2"
        },
        attr4 = svars.State_Integer {
            getter = "CAPI.getattr4", setter = "CAPI.setattr4",
            gui_name = "value3", alt_name = "value3"
        }
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.particle_type, self.value1, self.value2, self.value3 = 0, 0, 0, 0
    end
}
M.Particle_Effect = Particle_Effect

--[[! Class: Mapmodel
    A model in the world. Its sauer type is "mapmodel". All properties
    default to 0.

    Properties:
        attr1 - the model yaw, alias "yaw".
        collision_radius_width - a custom bounding box
        width for models with per-entity collision boxes.
        Used with e.g. area trigger to specify trigger bounds.
        collision_radius_height - see above.
]]
local Mapmodel = Static_Entity:clone {
    name = "Mapmodel",

    sauer_type = "mapmodel",

    properties = {
        attr1 = svars.State_Integer {
            getter = "CAPI.getattr1", setter = "CAPI.setattr1",
            gui_name = "yaw", alt_name = "yaw"
        },
        collision_radius_width = svars.State_Float {
            getter = "CAPI.getcollisionradw", setter = "CAPI.setcollisionradw"
        },
        collision_radius_height = svars.State_Float {
            getter = "CAPI.getcollisionradh", setter = "CAPI.setcollisionradh"
        }
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.yaw, self.attr2 = 0, -1
        self.collision_radius_width = 0
        self.collision_radius_height = 0
    end,

    --[[! Function: get_center
        A variant of <Static_Entity.get_center> that assumes
        collision_radius_height.
    ]]
    get_center = function(self)
        local crh = self.collision_radius_height
        if crh ~= 0 then
            local r = self.position:copy()
            r.z = r.z + crh
        else
            return Static_Entity.get_center(self)
        end
    end
}
M.Mapmodel = Mapmodel

--[[! Class: Area_Trigger
    A variant of <Mapmodel> that emits a "collision" signal on itself
    when a client (player, NPC...) collide with it. Its default model
    is "areatrigger" and collision radius width/height are both 10.
    Likely deprecated (to be replaced with a better system).
]]
local Area_Trigger = Mapmodel:clone {
    name = "Area_Trigger",

    init = function(self, uid, kwargs)
        Mapmodel.init(self, uid, kwargs)
        self.collision_radius_width = 10
        self.collision_radius_height = 10
        self.model_name = "areatrigger"
    end
}
M.Area_Trigger = Area_Trigger

--[[! Class: World_Marker
    A generic marker with a wide variety of uses. Can be used as a base
    for various position markers (e.g. playerstarts). Its sauer type is
    "playerstart". It has one property, attr1 alias yaw.

    An example of world marker usage is a cutscene system. Different marker
    types inherited from this one can represent different nodes.
]]
local World_Marker = Static_Entity:clone {
    name = "World_Marker",

    sauer_type = "playerstart",

    properties = {
        attr1 = svars.State_Integer {
            getter = "CAPI.getattr1", setter = "CAPI.setattr1",
            gui_name = "yaw", alt_name = "yaw"
        }
    },

    --[[! Function: place_entity
        Places an entity on this marker's position.
    ]]
    place_entity = function(self, ent)
        ent.position, ent.yaw = self.position, self.yaw
    end
}
M.World_Marker = World_Marker

ents.register_class(Light)
ents.register_class(Spot_Light)
ents.register_class(Envmap)
ents.register_class(Sound)
ents.register_class(Particle_Effect)
ents.register_class(Mapmodel)
ents.register_class(Area_Trigger)
ents.register_class(World_Marker)