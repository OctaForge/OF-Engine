--[[!
    File: library/core/entities/ents_basic.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Implements a basic entity set. Injects directly into the "ents" module.
]]

local M = ents

local Entity = M.Entity

local band, bor, lsh, rsh = math.band, math.bor, math.lsh, math.rsh
local assert, unpack, tonumber, tostring = assert, unpack, tonumber, tostring
local connect, emit = signal.connect, signal.emit

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
            setter = "_C.set_animation", client_set = true
        },
        start_time  = svars.State_Integer { getter = "_C.get_start_time"   },
        model_name  = svars.State_String  { setter = "_C.set_model_name"   },
        attachments = svars.State_Array   { setter = "_C.set_attachments" } 
    },

    init = SERVER and function(self, uid, kwargs)
        Entity.init(self, uid, kwargs)

        self.model_name  = ""
        self.attachments = {}
        self.animation   = bor(model.anims.IDLE, model.anims.LOOP)
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
        _C.set_animation(self, anim)
        self.svar_values["animation"] = anim
    end,

    --[[! Function: set_local_model_name
        Sets the model name property locally, without notifying the other side.
    ]]
    set_local_model_name = function(self, mname)
        _C.set_model_name(self, mname)
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

-- physics state flags
local MASK_MAT = 0x3
local FLAG_WATER = lsh(1, 0)
local FLAG_LAVA  = lsh(2, 0)
local MASK_LIQUID = 0xC
local FLAG_ABOVELIQUID = lsh(1, 2)
local FLAG_BELOWLIQUID = lsh(2, 2)
local MASK_GROUND = 0x30
local FLAG_ABOVEGROUND = lsh(1, 4)
local FLAG_BELOWGROUND = lsh(2, 4)

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
        roll [<svars.State_Float>] - the current character roll in degrees.
        move [<svars.State_Integer>] - -1 when moving backwards, 0 when not
        moving, 1 when forward.
        strafe [<svars.State_Integer>] - -1 when strafing left, 0 when not
        strafing, 1 when right.
        yawing [<svars.State_Integer>] - -1 when turning left, 1 when right,
        0 when not at all.
        pitching [<svars.State_Integer>] - -1 when looking down, 1 when up,
        0 when not.
        jumping [<svars.State_Boolean>] - true when the character has jumped,
        false otherwise.
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
        in_liquid [<svars.State_Integer>] - either 0 (in the air) or the
        liquid material id (water, lava).
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
            getter = "_C.get_maxspeed", setter = "_C.set_maxspeed"
        },
        yaw = svars.State_Float {
            getter = "_C.get_yaw", setter = "_C.set_yaw",
            custom_sync = true
        },
        pitch = svars.State_Float {
            getter = "_C.get_pitch", setter = "_C.set_pitch",
            custom_sync = true
        },
        roll = svars.State_Float {
            getter = "_C.get_roll", setter = "_C.set_roll",
            custom_sync = true
        },
        move = svars.State_Integer {
            getter = "_C.get_move", setter = "_C.set_move",
            custom_sync = true
        },
        strafe = svars.State_Integer {
            getter = "_C.get_strafe", setter = "_C.set_strafe",
            custom_sync = true
        },
        yawing = svars.State_Integer {
            getter = "_C.get_yawing", setter = "_C.set_yawing",
            custom_sync = true
        },
        pitching = svars.State_Integer {
            getter = "_C.get_pitching", setter = "_C.set_pitching",
            custom_sync = true
        },
        jumping = svars.State_Boolean {
            getter = "_C.get_jumping", setter = "_C.set_jumping",
            custom_sync = true
        },
        position = svars.State_Vec3 {
            getter = "_C.get_dynent_position",
            setter = "_C.set_dynent_position",
            custom_sync = true
        },
        velocity = svars.State_Vec3 {
            getter = "_C.get_dynent_velocity",
            setter = "_C.set_dynent_velocity",
            custom_sync = true
        },
        falling = svars.State_Vec3 {
            getter = "_C.get_dynent_falling",
            setter = "_C.set_dynent_falling",
            custom_sync = true
        },
        radius = svars.State_Float {
            getter = "_C.get_radius", setter = "_C.set_radius"
        },
        above_eye = svars.State_Float {
            getter = "_C.get_aboveeye", setter = "_C.set_aboveeye"
        },
        eye_height = svars.State_Float {
            getter = "_C.get_eyeheight", setter = "_C.set_eyeheight"
        },
        blocked = svars.State_Boolean {
            getter = "_C.get_blocked", setter = "_C.set_blocked"
        },
        can_move = svars.State_Boolean {
            setter = "_C.set_can_move", client_set = true
        },
        map_defined_position_data = svars.State_Integer {
            getter = "_C.get_mapdefinedposdata",
            setter = "_C.set_mapdefinedposdata",
            custom_sync = true
        },
        client_state = svars.State_Integer {
            getter = "_C.get_clientstate", setter = "_C.set_clientstate",
            custom_sync = true
        },
        physical_state = svars.State_Integer {
            getter = "_C.get_physstate", setter = "_C.set_physstate",
            custom_sync = true
        },
        in_liquid = svars.State_Integer {
            getter = "_C.get_inwater", setter = "_C.set_inwater",
            custom_sync = true
        },
        time_in_air = svars.State_Integer {
            getter = "_C.get_timeinair", setter = "_C.set_timeinair",
            custom_sync = true
        },

        physics_trigger = svars.State_Integer(),

        jumping_sound = svars.State_String(),
        landing_sound = svars.State_String()
    },

    --[[! Function: jump
        A handler called when the character is about to jump.
    ]]
    jump = function(self)
        self.jumping = true
    end,

    get_plag = _C.get_plag,
    get_ping = _C.get_ping,
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

        self.physics_trigger = 0
        self.jumping_sound   = "gk/jump2.ogg"
        self.landing_sound   = "olpc/AdamKeshen/kik.wav"

        self:define_getter("plag", self.get_plag)
        self:define_getter("ping", self.get_ping)
        self:define_getter("editing", self.get_editing)
        self:define_getter("lagged", self.get_lagged)
    end or nil,

    activate = SERVER and function(self, kwargs)
        self.cn = kwargs and kwargs.cn or -1
        assert(self.cn >= 0)
        _C.setup_character(self)

        Physical_Entity.activate(self, kwargs)

        self:flush_queued_svar_changes()
    end or function(self, kwargs)
        Physical_Entity.activate(self, kwargs)

        self.cn = kwargs and kwargs.cn or -1
        _C.setup_character(self)

        self.render_args_timestamp = -1

        -- see world.lua for field meanings
        connect(self, "physics_trigger_changed", function(self, val)
            if val == 0 then return nil end
            self.physics_trigger = 0

            local pos = (self ~= ents.get_player()) and self.position or nil

            local lst = band(val, MASK_LIQUID)
            if lst == FLAG_ABOVELIQUID then
                if band(val, MASK_MAT) ~= FLAG_LAVA then
                    sound.play("yo_frankie/amb_waterdrip_2.wav", pos)
                end
            elseif lst == FLAG_BELOWLIQUID then
                sound.play(band(val, MASK_MAT) == FLAG_LAVA
                    and "yo_frankie/DeathFlash.wav"
                    or "yo_frankie/watersplash2.wav", pos)
            end

            local gst = band(val, MASK_GROUND)
            if gst == FLAG_ABOVEGROUND then
                sound.play(self.jumping_sound, pos)
            elseif gst == FLAG_BELOWGROUND then
                sound.play(self.landing_sound, pos)
            end
        end)
    end,

    deactivate = function(self)
        _C.destroy_character(self)
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

            local yaw, pitch, roll = self.yaw, self.pitch, self.roll
            local o = self.position:copy()

            if hudpass and needhud and self.hud_model_offset then
                o:add(self.hud_model_offset)
            end

            local pstate = self.physical_state
            local bt, iw = self.start_time, self.in_liquid
            local mv, sf = self.move, self.strafe

            local vel, fall = self.velocity:copy(), self.falling:copy()
            local tia = self.time_in_air

            local anim = self:decide_animation(state, pstate, mv, sf, vel,
                fall, iw, tia)
            local flags = self:get_render_flags(hudpass, needhud)

            if not ra then
                ra = { self, "", true, true, true, true, true, true, true }
                self.render_args = ra
            end

            ra[2], ra[3], ra[4], ra[5], ra[6], ra[7], ra[8], ra[9] =
                mdn, anim, o, yaw, pitch, roll, flags, bt
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
        local flags = model.render_flags.FULLBRIGHT
        if self ~= M.get_player() then
            flags = bor(model.render_flags.CULL_VFC,
                model.render_flags.CULL_OCCLUDED,
                model.render_flags.CULL_QUERY)
        end
        return flags
    end or nil,

    --[[! Function: decide_animation
        Decides the current animation for the character. Starts with
        <get_animation>, then adjusts it to take things like moving,
        strafing, swimming etc into account.

        Passed arguments are client_state, physical_state, move, strafe,
        velocity, falling, in_liquid and time_in_air (same as the state
        variables).
    ]]
    decide_animation = CLIENT and function(self, state, pstate, move, strafe,
    vel, falling, inwater, tinair)
        local anim = self:get_animation()

        -- editing or spectator
        if state == 4 or state == 5 then
            anim = bor(model.anims.EDIT, model.anims.LOOP)
        -- lagged
        elseif state == 3 then
            anim = bor(model.anims.LAG, model.anims.LOOP)
        else
            -- in water and floating or falling
            if inwater ~= 0 and pstate <= 1 then
                anim = bor(anim, lsh(
                    bor(((move or strafe) or ((vel.z + falling.z) > 0))
                        and model.anims.SWIM or model.anims.SINK,
                    model.anims.LOOP),
                    model.anims.SECONDARY))
            -- jumping animation
            elseif tinair > 250 then
                anim = bor(anim, lsh(bor(model.anims.JUMP, model.anims.END),
                    model.anims.SECONDARY))
            -- moving or strafing
            elseif move ~= 0 or strafe ~= 0 then
                if move > 0 then
                    anim = bor(anim, lsh(bor(model.anims.FORWARD,
                        model.anims.LOOP), model.anims.SECONDARY))
                elseif strafe ~= 0 then
                    anim = bor(anim, lsh(bor((strafe > 0 and model.anims.LEFT
                        or model.anims.RIGHT), model.anims.LOOP),
                        model.anims.SECONDARY))
                elseif move < 0 then
                    anim = bor(anim, lsh(bor(model.anims.BACKWARD,
                        model.anims.LOOP), model.anims.SECONDARY))
                end
            end

            if band(anim, model.anims.INDEX) == model.anims.IDLE and
            band(rsh(anim, model.anims.SECONDARY), model.anims.INDEX) ~= 0 then
                anim = rsh(anim, model.anims.SECONDARY)
            end
        end

        if band(rsh(anim, model.anims.SECONDARY), model.anims.INDEX) == 0 then
            anim = bor(anim, lsh(bor(model.anims.IDLE, model.anims.LOOP),
                model.anims.SECONDARY))
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

--[[! Function: physics_collide_client
    An external called when two clients collide. Takes both entities. By
    default emits the "collision" signal on both clients, passing the other
    one as an argument. The client we're testing collisions against gets
    the first emit.
]]
set_external("physics_collide_client", function(cl1, cl2)
    emit(cl1, "collision", cl2)
    emit(cl2, "collision", cl1)
end)

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
    ["none"] = 0, ["light"] = 1, ["mapmodel"] = 2, ["marker"] = 3,
    ["envmap"] = 4, ["particles"] = 5, ["sound"] = 6, ["spotlight"] = 7,
    ["obstacle"] = 8
}

--[[! Class: Static_Entity
    A base for any static entity. Inherits from <Physical_Entity>. Unlike
    dynamic entities (such as <Character>), static entities usually don't
    invoke their "run" method per frame. To re-enable that, set the
    per_frame member to true (false by default for efficiency).

    Static entities are persistent by default, so they set the "persistent"
    inherited property to true. They also have the "sauer_type" member,
    which determines the "physical" type of the entity as in Cube 2,
    it can be "none", "light", "mapmodel", "marker", "envmap",
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

    --[[! Variable: edit_icon
        The icon that'll be displayed in edit mode.
    ]]
    edit_icon = "data/textures/icons/edit_generic",

    per_frame = false,
    sauer_type = "none",

    properties = {
        radius = svars.State_Float(),
        position = svars.State_Vec3 {
            getter = "_C.get_extent_position",
            setter = "_C.set_extent_position"
        },
        attr1 = svars.State_Integer {
            getter = "_C.get_attr1", setter = "_C.set_attr1"
        },
        attr2 = svars.State_Integer {
            getter = "_C.get_attr2", setter = "_C.set_attr2"
        },
        attr3 = svars.State_Integer {
            getter = "_C.get_attr3", setter = "_C.set_attr3"
        },
        attr4 = svars.State_Integer {
            getter = "_C.get_attr4", setter = "_C.set_attr4"
        },
        attr5 = svars.State_Integer {
            getter = "_C.get_attr5", setter = "_C.set_attr5"
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
        _C.setup_extent(self, kwargs._type, kwargs.x, kwargs.y, kwargs.z,
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

        _C.setup_extent(self, kwargs._type, kwargs.x, kwargs.y, kwargs.z,
            kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4,
            kwargs.attr5)
        return Physical_Entity.activate(self, kwargs)
    end,

    deactivate = function(self)
        _C.destroy_extent(self)
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
            msg.send(n, _C.extent_notification_complete,
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
    end,

    --[[! Function: get_edit_color
        Returns the color of the entity icon in edit mode. If an invalid
        value is returned, it defaults to 0xFFFFFF (white). This is useful
        for e.g. light entity that is colored.
    ]]
    get_edit_color = function(self)
        return 0xFFFFFF
    end
}
M.Static_Entity = Static_Entity

--[[! Function: entity_get_edit_info
    An external. Returns ent.edit_icon, ent:get_edit_color().
]]
set_external("entity_get_edit_info", function(ent)
    return ent.edit_icon, ent:get_edit_color()
end)

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

    edit_icon = "data/textures/icons/edit_light",

    sauer_type = "light",

    properties = {
        attr1 = svars.State_Integer({
            getter = "_C.get_attr1", setter = "_C.set_attr1",
            gui_name = "radius", alt_name = "radius"
        }),
        attr2 = svars.State_Integer({
            getter = "_C.get_attr2", setter = "_C.set_attr2",
            gui_name = "red", alt_name = "red"
        }),
        attr3 = svars.State_Integer({
            getter = "_C.get_attr3", setter = "_C.set_attr3",
            gui_name = "green", alt_name = "green"
        }),
        attr4 = svars.State_Integer({
            getter = "_C.get_attr4", setter = "_C.set_attr4",
            gui_name = "blue", alt_name = "blue"
        }),
        attr5 = svars.State_Integer({
            getter = "_C.get_attr5", setter = "_C.set_attr5",
            gui_name = "shadow", alt_name = "shadow"
        })
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.red, self.green, self.blue = 128, 128, 128
        self.radius, self.shadow = 100, 0
    end,

    get_edit_color = function(self)
        return bor(self.blue, lsh(self.green, 8), lsh(self.red, 16))
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

    edit_icon = "data/textures/icons/edit_spotlight",

    sauer_type = "spotlight",

    properties = {
        attr1 = svars.State_Integer {
            getter = "_C.get_attr1", setter = "_C.set_attr1",
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

    edit_icon = "data/textures/icons/edit_envmap",

    sauer_type = "envmap",

    properties = {
        attr1 = svars.State_Integer {
            getter = "_C.get_attr1", setter = "_C.set_attr1",
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

    edit_icon = "data/textures/icons/edit_sound",

    sauer_type = "sound",

    properties = {
        attr2 = svars.State_Integer {
            getter = "_C.get_attr2", setter = "_C.set_attr2",
            gui_name = "radius", alt_name = "radius"
        },
        attr3 = svars.State_Integer {
            getter = "_C.get_attr3", setter = "_C.set_attr3",
            gui_name = "size", alt_name = "size"
        },
        attr4 = svars.State_Integer {
            getter = "_C.get_attr4", setter = "_C.set_sound_volume",
            gui_name = "volume", alt_name = "volume"
        },
        sound_name = svars.State_String {
            setter = "_C.set_sound_name"
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

    edit_icon = "data/textures/icons/edit_particles",

    sauer_type = "particles",

    properties = {
        attr1 = svars.State_Integer {
            getter = "_C.get_attr1", setter = "_C.set_attr1",
            gui_name = "particle_type", alt_name = "particle_type"
        },
        attr2 = svars.State_Integer {
            getter = "_C.get_attr2", setter = "_C.set_attr2",
            gui_name = "value1", alt_name = "value1"
        },
        attr3 = svars.State_Integer {
            getter = "_C.get_attr3", setter = "_C.set_attr3",
            gui_name = "value2", alt_name = "value2"
        },
        attr4 = svars.State_Integer {
            getter = "_C.get_attr4", setter = "_C.set_attr4",
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
    default to 0. On mapmodels and all entity types derived from mapmodels,
    the engine emits the "collision" signal with the collider entity passed
    as an argument when collided.

    Properties:
        attr1 - the model yaw, alias "yaw".
        attr2 - the model pitch, alias "pitch".
        attr3 - the model roll, alias "roll".
        attr4 - the model scale, alias "scale".
]]
local Mapmodel = Static_Entity:clone {
    name = "Mapmodel",

    edit_icon = "data/textures/icons/edit_mapmodel",

    sauer_type = "mapmodel",

    properties = {
        attr1 = svars.State_Integer {
            getter = "_C.get_attr1", setter = "_C.set_attr1",
            gui_name = "yaw", alt_name = "yaw"
        },
        attr2 = svars.State_Integer {
            getter = "_C.get_attr2", setter = "_C.set_attr2",
            gui_name = "pitch", alt_name = "pitch"
        },
        attr3 = svars.State_Integer {
            getter = "_C.get_attr3", setter = "_C.set_attr3",
            gui_name = "roll", alt_name = "roll"
        },
        attr4 = svars.State_Integer {
            getter = "_C.get_attr4", setter = "_C.set_attr4",
            gui_name = "scale", alt_name = "scale"
        }
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self.yaw, self.pitch, self.roll = 0, 0, 0
    end
}
M.Mapmodel = Mapmodel

--[[! Function: physics_collide_mapmodel
    An external called when a client collides with a mapmodel. Takes the
    collider entity (the client) and the mapmodel entity. By default emits
    the "collision" signal on both entities, passing the other one as an
    argument. The mapmodel takes precedence.
]]
set_external("physics_collide_mapmodel", function(collider, entity)
    emit(entity, "collision", collider)
    emit(collider, "collision", entity)
end)

--[[! Class: World_Marker
    A generic marker with a wide variety of uses. Can be used as a base
    for various position markers (e.g. playerstarts). Its sauer type is
    "marker". It has two properties, attr1 alias yaw, attr2 alias pitch.

    An example of world marker usage is a cutscene system. Different marker
    types inherited from this one can represent different nodes.
]]
local World_Marker = Static_Entity:clone {
    name = "World_Marker",

    edit_icon = "data/textures/icons/edit_marker",

    sauer_type = "marker",

    properties = {
        attr1 = svars.State_Integer {
            getter = "_C.get_attr1", setter = "_C.set_attr1",
            gui_name = "yaw", alt_name = "yaw"
        },
        attr2 = svars.State_Integer {
            getter = "_C.get_attr2", setter = "_C.set_attr2",
            gui_name = "pitch", alt_name = "pitch"
        }
    },

    --[[! Function: place_entity
        Places an entity on this marker's position.
    ]]
    place_entity = function(self, ent)
        ent.position, ent.yaw, ent.pitch = self.position, self.yaw, self.pitch
    end
}
M.World_Marker = World_Marker

--[[! Class: Obstacle
    An entity class that emits a "collision" signal on itself when a client
    (player, NPC...) collides with it. It has its own yaw (attr1), dimensions
    (attr2 alias a, attr3 alias b, attr4 alias c) and the solid property
    (attr5) which makes the obstacle solid when it isn't 0.
]]
local Obstacle = Static_Entity:clone {
    name = "Obstacle",

    sauer_type = "obstacle",

    properties = {
        attr1 = svars.State_Integer {
            getter = "_C.get_attr1", setter = "_C.set_attr1",
            gui_name = "yaw", alt_name = "yaw"
        },
        attr2 = svars.State_Integer {
            getter = "_C.get_attr2", setter = "_C.set_attr2",
            gui_name = "a", alt_name = "a"
        },
        attr3 = svars.State_Integer {
            getter = "_C.get_attr3", setter = "_C.set_attr3",
            gui_name = "b", alt_name = "b"
        },
        attr4 = svars.State_Integer {
            getter = "_C.get_attr4", setter = "_C.set_attr4",
            gui_name = "c", alt_name = "c"
        },
        attr5 = svars.State_Integer {
            getter = "_C.get_attr5", setter = "_C.set_attr5",
            gui_name = "solid", alt_name = "solid"
        }
    }
}
M.Obstacle = Obstacle

--[[! Function: physics_collide_area
    An external called when a client collides with an area. Takes the
    collider entity (the client) and the area entity.  By default emits
    the "collision" signal on both entities, passing the other one as an
    argument. The obstacle takes precedence.
]]
set_external("physics_collide_area", function(collider, entity)
    emit(entity, "collision", collider)
    emit(collider, "collision", entity)
end)

ents.register_class(Light)
ents.register_class(Spot_Light)
ents.register_class(Envmap)
ents.register_class(Sound)
ents.register_class(Particle_Effect)
ents.register_class(Mapmodel)
ents.register_class(World_Marker)
ents.register_class(Obstacle)
