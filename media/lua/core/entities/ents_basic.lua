--[[! File: lua/core/entities/ents_basic.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        Implements a basic entity set. Injects directly into the "ents" module.
]]

local capi = require("capi")
local logging = require("core.logger")
local log = logging.log
local DEBUG = logging.DEBUG

local sound = require("core.engine.sound")
local model = require("core.engine.model")
local frame = require("core.events.frame")
local actions = require("core.events.actions")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local msg = require("core.network.msg")
local table2 = require("core.lua.table")
local cs = require("core.engine.cubescript")
local conv = require("core.lua.conv")

local hextorgb = conv.hex_to_rgb

local var_get = cs.var_get

local set_external = capi.external_set

local Entity = ents.Entity

local assert, unpack, tonumber, tostring = assert, unpack, tonumber, tostring
local connect, emit = signal.connect, signal.emit
local format = string.format
local abs = math.abs
local tconc = table.concat
local min, max = math.min, math.max
local clamp = require("core.lua.math").clamp
local map = table2.map

local set_attachments = capi.set_attachments

-- physics state flags
local MASK_MAT = 0x3
local FLAG_WATER = 1 << 0
local FLAG_LAVA  = 2 << 0
local MASK_LIQUID = 0xC
local FLAG_ABOVELIQUID = 1 << 2
local FLAG_BELOWLIQUID = 2 << 2
local MASK_GROUND = 0x30
local FLAG_ABOVEGROUND = 1 << 4
local FLAG_BELOWGROUND = 2 << 4

local animctl   = model.anim_control
local animctl_l = {}
if not SERVER then
    for k, v in pairs(animctl) do
        animctl_l[k:lower()] = v
    end
end
local anims = model.anims

local csetanim = capi.set_animation
local setanim = SERVER and function(self, v)
    csetanim(self, 0, 0)
end or function(self, v)
    local panim = v[1]
    if panim then
        local xy = panim:split(",")
        panim = (model.get_anim(xy[1]) or 0) | (animctl_l[xy[2]] or 0)
    else
        panim = 0
    end
    local sanim = v[2]
    if sanim then
        local xy = panim:split(",")
        sanim = (model.get_anim(xy[1]) or 0) | (animctl_l[xy[2]] or 0)
    else
        sanim = 0
    end
    csetanim(self, panim, sanim)
end

local anim_dirs, anim_jump, anim_run
if not SERVER then
    anim_dirs = {
        anims.run_SE, anims.run_S, anims.run_SW,
        anims.run_E,  0,           anims.run_W,
        anims.run_NE, anims.run_N, anims.run_NW
    }

    anim_jump = {
        [anims.jump_N] = true, [anims.jump_NE] = true, [anims.jump_NW] = true,
        [anims.jump_S] = true, [anims.jump_SE] = true, [anims.jump_SW] = true,
        [anims.jump_E] = true, [anims.jump_W ] = true
    }

    anim_run = {
        [anims.run_N] = true, [anims.run_NE] = true, [anims.run_NW] = true,
        [anims.run_S] = true, [anims.run_SE] = true, [anims.run_SW] = true,
        [anims.run_E] = true, [anims.run_W ] = true
    }
end

local mrender = (not SERVER) and model.render

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
        animation [<svars.State_Array>] - the entity's current animation.
        It's an array of strings in format "animname,dir" and defaults
        to "idle,loop".
        animation_flags [<svars.State_Integer>] - the entity's current anim
        flags.
        start_time [<svars.State_Integer>] - an internal property used for
        animation timing.
        model_name [<svars.State_String>] - name of the model associated with
        this entity.
        attachments [<svars.State_Array>] - an array of model attachments.
        Those are strings in format "tagname,attachmentname".
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
        crouching [<svars.State_Integer>] - -1 when crouching down, 1 when up,
        0 when not.
        jumping [<svars.State_Boolean>] - true when the character has jumped,
        false otherwise.
        position [<svars.State_Vec3>] - the current position. Defaults to
        { 512, 512, 550 }.
        velocity [<svars.State_Vec3>] - the current velocity.
        falling [<svars.State_Vec3>] - the character's gravity falling.
        radius [<svars.State_Float>] - the character's bounding box radius.
        Defaults to 4.1.
        above_eye [<svars.State_Float>] - the height of the character above
        its eyes. Defaults to 2.0.
        eye_height [<svars.State_Float>] - the distance from the ground to
        the eye position. Defaults to 22.0.
        max_height [<svars.State_Float>] - the maximum distance from the
        ground to the eye position. Defaults to 22.0. Used when crouching.
        crouch_height [<svars.State_Float>] - the fraction from max_height
        to use when crouched, defaults to 0.75.
        crouch_time [<svars.State_Integer>] - the time in milliseconds spent
        to crouch, adjust to change the speed.
        jump_velocity [<svars.State_Float>] - the vertical velocity to apply
        when jumping, defaults to 125.
        gravity [<svars.State_Float>] - a custom character gravity to override
        the global defaults. By default it's -1, which means the character
        will use the global gravity.
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
local Character = Entity:clone {
    name = "Character",

    -- so that it isn't nonsauer
    sauer_type = -1,

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

    __properties = {
        animation = svars.State_Array {
            setter = setanim, client_set = true
        },
        animation_flags = svars.State_Integer {
            setter = capi.set_animflags, client_set = true
        },
        start_time  = svars.State_Integer { getter = capi.get_start_time   },
        model_name  = svars.State_String  { setter = capi.set_model_name   },
        attachments = svars.State_Array   {
            setter = function(self, val)
                return set_attachments(self, map(val, function(str)
                    return str:split(",")
                end))
            end
        },

        character_name = svars.State_String(),
        facing_speed   = svars.State_Integer(),

        movement_speed = svars.State_Float {
            getter = capi.get_maxspeed, setter = capi.set_maxspeed
        },
        yaw = svars.State_Float {
            getter = capi.get_yaw, setter = capi.set_yaw,
            custom_sync = true
        },
        pitch = svars.State_Float {
            getter = capi.get_pitch, setter = capi.set_pitch,
            custom_sync = true
        },
        roll = svars.State_Float {
            getter = capi.get_roll, setter = capi.set_roll,
            custom_sync = true
        },
        move = svars.State_Integer {
            getter = capi.get_move, setter = capi.set_move,
            custom_sync = true
        },
        strafe = svars.State_Integer {
            getter = capi.get_strafe, setter = capi.set_strafe,
            custom_sync = true
        },
        yawing = svars.State_Integer {
            getter = capi.get_yawing, setter = capi.set_yawing,
            custom_sync = true
        },
        pitching = svars.State_Integer {
            getter = capi.get_pitching, setter = capi.set_pitching,
            custom_sync = true
        },
        crouching = svars.State_Integer {
            getter = capi.get_crouching, setter = capi.set_crouching,
            custom_sync = true
        },
        jumping = svars.State_Boolean {
            getter = capi.get_jumping, setter = capi.set_jumping,
            custom_sync = true
        },
        position = svars.State_Vec3 {
            getter = capi.get_dynent_position,
            setter = capi.set_dynent_position,
            custom_sync = true
        },
        velocity = svars.State_Vec3 {
            getter = capi.get_dynent_velocity,
            setter = capi.set_dynent_velocity,
            custom_sync = true
        },
        falling = svars.State_Vec3 {
            getter = capi.get_dynent_falling,
            setter = capi.set_dynent_falling,
            custom_sync = true
        },
        radius = svars.State_Float {
            getter = capi.get_radius, setter = capi.set_radius
        },
        above_eye = svars.State_Float {
            getter = capi.get_aboveeye, setter = capi.set_aboveeye
        },
        eye_height = svars.State_Float {
            getter = capi.get_eyeheight, setter = capi.set_eyeheight
        },
        max_height = svars.State_Float {
            getter = capi.get_maxheight, setter = capi.set_maxheight
        },
        crouch_height = svars.State_Float {
            getter = capi.get_crouchheight, setter = capi.set_crouchheight
        },
        crouch_time = svars.State_Integer {
            getter = capi.get_crouchtime, setter = capi.set_crouchtime
        },
        jump_velocity = svars.State_Float {
            getter = capi.get_jumpvel, setter = capi.set_jumpvel
        },
        gravity = svars.State_Float {
            getter = capi.get_gravity, setter = capi.set_gravity
        },
        blocked = svars.State_Boolean {
            getter = capi.get_blocked, setter = capi.set_blocked
        },
        can_move = svars.State_Boolean {
            setter = capi.set_can_move, client_set = true
        },
        map_defined_position_data = svars.State_Integer {
            getter = capi.get_mapdefinedposdata,
            setter = capi.set_mapdefinedposdata,
            custom_sync = true
        },
        client_state = svars.State_Integer {
            getter = capi.get_clientstate, setter = capi.set_clientstate,
            custom_sync = true
        },
        physical_state = svars.State_Integer {
            getter = capi.get_physstate, setter = capi.set_physstate,
            custom_sync = true
        },
        in_liquid = svars.State_Integer {
            getter = capi.get_inwater, setter = capi.set_inwater,
            custom_sync = true
        },
        time_in_air = svars.State_Integer {
            getter = capi.get_timeinair, setter = capi.set_timeinair,
            custom_sync = true
        },

        physics_trigger = svars.State_Integer(),

        jumping_sound = svars.State_String(),
        landing_sound = svars.State_String()
    },

    --[[! Function: jump
        A handler called when the character is about to jump. It takes the
        "down" parameter as an argument. By default sets "jumping" to "down".
    ]]
    jump = function(self, down)
        self:set_attr("jumping", down)
    end,

    --[[! Function: crouch
        A handler called when the character is about to crouch. It takes the
        "down" parameter as an argument. By default checks if "down" is true
        and if it is, sets "crouching" to -1, otherwise sets "crouching" to
        abs(crouching).
    ]]
    crouch = function(self, down)
        if down then
            self:set_attr("crouching", -1)
        else
            self:set_attr("crouching", abs(self:get_attr("crouching")))
        end
    end,

    get_plag = function(self) return capi.get_plag(self.uid) end,
    get_ping = function(self) return capi.get_ping(self.uid) end,
    get_editing = function(self) return self:get_attr("client_state") == 4 end,
    get_lagged = function(self) return self:get_attr("client_state") == 3 end,

    __init_svars = SERVER and function(self, kwargs)
        Entity.__init_svars(self, kwargs)

        self:set_attr("model_name", "")
        self:set_attr("attachments", {})
        self:set_attr("animation", { "idle,loop" })
        self:set_attr("animation_flags", 0)

        self.cn = kwargs and kwargs.cn or -1
        self:set_attr("character_name", "none")
        self:set_attr("model_name", "player")
        self:set_attr("eye_height", 22.0)
        self:set_attr("max_height", 22.0)
        self:set_attr("crouch_height", 0.75)
        self:set_attr("crouch_time", 200)
        self:set_attr("jump_velocity", 125)
        self:set_attr("gravity", -1)
        self:set_attr("above_eye", 2.0)
        self:set_attr("movement_speed", 100.0)
        self:set_attr("facing_speed", 120)
        self:set_attr("position", { 512, 512, 550 })
        self:set_attr("radius", 4.1)
        self:set_attr("can_move", true)

        self:set_attr("physics_trigger", 0)
        self:set_attr("jumping_sound", "gk/jump2.ogg")
        self:set_attr("landing_sound", "olpc/AdamKeshen/kik.wav")
    end or nil,

    __activate = SERVER and function(self, kwargs)
        self.cn = kwargs and kwargs.cn or -1
        assert(self.cn >= 0)
        capi.setup_character(self)

        Entity.__activate(self, kwargs)

        self:set_attr("model_name", self:get_attr("model_name"))

        self:flush_queued_svar_changes()
    end or function(self, kwargs)
        Entity.__activate(self, kwargs)

        self.cn = kwargs and kwargs.cn or -1
        capi.setup_character(self)

        self.render_args_timestamp = -1

        -- see world.lua for field meanings
        connect(self, "physics_trigger_changed", function(self, val)
            if val == 0 then return end
            self:set_attr("physics_trigger", 0)

            local pos = (self != ents.get_player())
                and self:get_attr("position") or nil

            local lst = val & MASK_LIQUID
            if lst == FLAG_ABOVELIQUID then
                if (val & MASK_MAT) != FLAG_LAVA then
                    sound.play("yo_frankie/amb_waterdrip_2.wav", pos)
                end
            elseif lst == FLAG_BELOWLIQUID then
                sound.play((val & MASK_MAT) == FLAG_LAVA
                    and "yo_frankie/DeathFlash.wav"
                    or "yo_frankie/watersplash2.wav", pos)
            end

            local gst = val & MASK_GROUND
            if gst == FLAG_ABOVEGROUND then
                sound.play(self:get_attr("jumping_sound"), pos)
            elseif gst == FLAG_BELOWGROUND then
                sound.play(self:get_attr("landing_sound"), pos)
            end
        end)
    end,

    __deactivate = function(self)
        capi.destroy_character(self)
        Entity.__deactivate(self)
    end,

    --[[! Function: __render
        Clientside and run per frame. It renders the character model. Decides
        all the parameters, including animation etc., but not every frame -
        they're cached by self.render_args_timestamp (they're only
        recomputed when this timestamp changes).

        When rendering HUD (determined by the paramters hudpass, which
        determines whether we're rendering HUD right now, and needhud,
        which determines whether we're in first person mode), the member
        hud_model_offset (vec3) is used to offset the HUD model (if available).

        There is one additional argument, fpsshadow - it's true if we're about
        to render a first person shadow (can be true only when needhud is true
        and hudpass is false).
    ]]
    __render = (not SERVER) and function(self, hudpass, needhud, fpsshadow)
        if not self.initialized then return end
        if not hudpass and needhud and not fpsshadow then return end

        local state = self:get_attr("client_state")
        -- spawning or spectator
        if state == 5 or state == 2 then return end
        local mdn = (hudpass and needhud)
            and self:get_attr("hud_model_name")
            or  self:get_attr("model_name")

        if mdn == "" then return end

        local yaw, pitch, roll = self:get_attr("yaw"),
            self:get_attr("pitch"),
            self:get_attr("roll")
        local o = self:get_attr("position"):copy()

        if hudpass and needhud and self.hud_model_offset then
            o:add(self.hud_model_offset)
        end

        local pstate = self:get_attr("physical_state")
        local bt, iw = self:get_attr("start_time"),
            self:get_attr("in_liquid")
        local mv, sf = self:get_attr("move"), self:get_attr("strafe")

        local vel, fall = self:get_attr("velocity"):copy(),
            self:get_attr("falling"):copy()
        local tia = self:get_attr("time_in_air")

        local cr = self:get_attr("crouching")

        local anim, animflags = self:decide_animation(state, pstate, mv,
            sf, cr, vel, fall, iw, tia)
        local flags = self:get_render_flags(hudpass, needhud)

        mrender(self, mdn, anim, animflags, o, yaw, pitch, roll, flags, bt)
    end or nil,

    --[[! Function: get_render_flags
        Returns the rendering flags used when rendering the character. By
        default, it enables some occlusion stuff. Override as needed,
        the parameters are hudpass (whether we're rendering HUD right now)
        and needhud (whether we're in first person mode). Called from
        <__render>. Clientside.
    ]]
    get_render_flags = (not SERVER) and function(self, hudpass, needhud)
        local flags
        if self != ents.get_player() then
            flags = model.render_flags.CULL_VFC
                | model.render_flags.CULL_OCCLUDED
                | model.render_flags.CULL_QUERY
        else
            flags = model.render_flags.FULLBRIGHT
        end
        if needhud then
            if hudpass then
                flags |= model.render_flags.NOBATCH
            else
                flags |= model.render_flags.ONLY_SHADOW
            end
        end
        return flags
    end or nil,

    --[[! Function: get_animation
        Returns the base "action animation" used by <decide_animation>. By
        default simply return the "animation" attribute.
    ]]
    get_animation = (not SERVER) and function(self)
        return self:get_attr("animation")
    end or nil,

    --[[! Function: decide_animation
        Decides the current animation for the character. Starts with
        <get_animation>, then adjusts it to take things like moving,
        strafing, swimming etc into account. Returns the animation
        (an array) and animation flags (by default 0).

        Passed arguments are client_state, physical_state, move, strafe,
        crouching, velocity, falling, in_liquid and time_in_air (same as the
        state variables).
    ]]
    decide_animation = (not SERVER) and function(self, state, pstate, move,
    strafe, crouching, vel, falling, inwater, tinair)
        local anim = self:get_animation()
        local panim = anim[1]
        if panim then
            local xy = panim:split(",")
            panim = (model.get_anim(xy[1]) or 0) | (animctl_l[xy[2]] or 0)
        else
            panim = 0
        end
        local sanim = anim[2]
        if sanim then
            local xy = panim:split(",")
            sanim = (model.get_anim(xy[1]) or 0) | (animctl_l[xy[2]] or 0)
        else
            sanim = 0
        end

        -- editing or spectator
        if state == 4 or state == 5 then
            panim = anims.edit | animctl.LOOP
        -- lagged
        elseif state == 3 then
            panim = anims.lag | animctl.LOOP
        else
            -- in water and floating or falling
            if inwater != 0 and pstate <= 1 then
                sanim = (((move or strafe) or ((vel.z + falling.z) > 0))
                    and anims.swim or anims.sink) | animctl.LOOP
            -- moving or strafing
            else
                local dir = anim_dirs[(move + 1) * 3 + strafe + 2]
                -- jumping anim
                if tinair > 100 then
                    sanim = ((dir != 0) and (dir + anims.jump_N - anims.run_N)
                        or anims.jump) | animctl.END
                elseif dir != 0 then
                    sanim = dir | animctl.LOOP
                end
            end

            if crouching != 0 then
                local v = sanim & anims.INDEX
                if v == anims.idle then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch
                elseif v == anims.jump then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch_jump
                elseif v == anims.swim then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch_swim
                elseif v == anims.sink then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch_sink
                elseif v == 0 then
                    sanim = anims.crouch | animctl.LOOP
                elseif anim_run[v] then
                    sanim = sanim + anims.crouch_N - anims.run_N
                elseif anim_jump[v] then
                    sanim = sanim + anims.crouch_jump_N - anims.jump_N
                end
            end

            if (panim & anims.INDEX) == anims.idle and
               (sanim & anims.INDEX) != 0 then
                panim = sanim
            end
        end

        if (sanim & anims.INDEX) == 0 then
            sanim = anims.idle | animctl.LOOP
        end
        return { panim, sanim }, 0
    end or nil,

    --[[! Function: get_center
        Gets the center position of a character, something like gravity center
        (approximate). Useful for e.g. bots (better to aim at this position,
        the actual "position" is feet position). Override if you need this
        non-standard. By default it's 0.75 * eye_height above feet.
    ]]
    get_center = function(self)
        local r = self:get_attr("position"):copy()
        r.z = r.z + self:get_attr("eye_height") * 0.75
        return r
    end,

    --[[! Function: get_targeting_origin
        Given an origin position (e.g. from an attachment tag), this method
        is supposed to fix it so that it corresponds to where player actually
        targeted from. By default just returns origin.
    ]]
    get_targeting_origin = function(self, origin)
        return origin
    end,

    --[[! Function: set_local_animation
        Sets the animation property locally, without notifying the other side.
        Useful when allowing actions to animate the entity (as we mostly
        don't need the changes to reflect elsewhere).
    ]]
    set_local_animation = function(self, anim)
        setanim(self, anim)
        self.svar_values["animation"] = anim
    end,

    --[[! Function: set_local_animation_flags
        Sets the animation_flags property locally, without notifying the other
        side. Useful when allowing actions to animate the entity (as we mostly
        don't need the changes to reflect elsewhere).
    ]]
    set_local_animation_flags = function(self, animflags)
        capi.set_animflags(self, animflags)
        self.svar_values["animation_flags"] = animflags
    end,

    --[[! Function: set_local_model_name
        Sets the model name property locally, without notifying the other side.
    ]]
    set_local_model_name = function(self, mname)
        capi.set_model_name(self, mname)
        self.svar_values["model_name"] = mname
    end
}
ents.Character = Character

--[[! Function: physics_collide_client
    An external called when two clients collide. Takes both entities. By
    default emits the "collision" signal on both clients, passing the other
    one as an argument. The client we're testing collisions against gets
    the first emit.
]]
set_external("physics_collide_client", function(cl1, cl2, dx, dy, dz)
    emit(cl1, "collision", cl2, dx, dy, dz)
    emit(cl2, "collision", cl1, dx, dy, dz)
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

    __properties = {
        can_edit = svars.State_Boolean(),
        hud_model_name = svars.State_String()
    },

    __init_svars = SERVER and function(self, kwargs)
        Character.__init_svars(self, kwargs)

        self:set_attr("can_edit", false)
        self:set_attr("hud_model_name", "")
    end or nil
}
ents.Player = Player

ents.register_class(Character)
ents.register_class(Player)

local c_get_attr = capi.get_attr
local c_set_attr = capi.set_attr

local gen_attr = function(i, name)
    i = i - 1
    return svars.State_Integer {
        getter = function(ent)      return c_get_attr(ent, i)      end,
        setter = function(ent, val) return c_set_attr(ent, i, val) end,
        gui_name = name, alt_name = name
    }
end

--[[! Class: Static_Entity
    A base for any static entity. Inherits from <Entity>. Unlike
    dynamic entities (such as <Character>), static entities usually don't
    invoke their "__run" method per frame. To re-enable that, set the
    __per_frame member to true (false by default for efficiency).

    Static entities are persistent by default, so they set the "persistent"
    inherited property to true.

    This entity class is never registered, the inherited ones are.

    Properties:
        position [<svars.State_Vec3>] - the entity position.
        attr1 [<svars.State_Integer>] - the first "sauer" entity attribute.
        attr2 [<svars.State_Integer>] - the second "sauer" entity attribute.
        attr3 [<svars.State_Integer>] - the third "sauer" entity attribute.
        attr4 [<svars.State_Integer>] - the fourth "sauer" entity attribute.
        attr5 [<svars.State_Integer>] - the fifth "sauer" entity attribute.
]]
local Static_Entity = Entity:clone {
    name = "Static_Entity",

    --[[! Variable: __edit_icon
        The icon that'll be displayed in edit mode.
    ]]
    __edit_icon = "media/interface/icon/edit_generic",

    __per_frame = false,
    sauer_type = 0,
    attr_num   = 0,

    __properties = {
        position = svars.State_Vec3 {
            getter = capi.get_extent_position,
            setter = capi.set_extent_position
        }
    },

    __init_svars = function(self, kwargs)
        debug then log(DEBUG, "Static_Entity.init")

        kwargs = kwargs or {}
        kwargs.persistent = true

        Entity.__init_svars(self, kwargs)
        if not kwargs.position then
            self:set_attr("position", { 511, 512, 513 })
        else
            self:set_attr("position", {
                tonumber(kwargs.position.x),
                tonumber(kwargs.position.y),
                tonumber(kwargs.position.z)
            })
        end

        debug then log(DEBUG, "Static_Entity.init complete")
    end,

    __activate = SERVER and function(self, kwargs)
        kwargs = kwargs or {}

        debug then log(DEBUG, "Static_Entity.__activate")
        Entity.__activate(self, kwargs)

        debug then log(DEBUG, "Static_Entity: extent setup")
        capi.setup_extent(self, self.sauer_type)

        debug then log(DEBUG, "Static_Entity: flush")
        self:flush_queued_svar_changes()

        self:set_attr("position", self:get_attr("position"))
        for i = 1, self.attr_num do
            local an = "attr" .. i
            self:set_attr(an, self:get_attr(an))
        end
    end or function(self, kwargs)
        capi.setup_extent(self, self.sauer_type)
        return Entity.__activate(self, kwargs)
    end,

    __deactivate = function(self)
        capi.destroy_extent(self)
        return Entity.__deactivate(self)
    end,

    send_notification_full = SERVER and function(self, cn)
        local acn = msg.ALL_CLIENTS
        cn = cn or acn

        local cns = (cn == acn) and map(ents.get_players(), function(p)
            return p.cn end) or { cn }

        local uid = self.uid
        debug then log(DEBUG, "Static_Entity.send_notification_full: "
            .. cn .. ", " .. uid)

        local scn, sname = self.cn, self.name
        for i = 1, #cns do
            local n = cns[i]
            msg.send(n, capi.extent_notification_complete, uid, sname,
                self:build_sdata({ target_cn = n, compressed = true }))
        end

        debug then log(DEBUG, "Static_Entity.send_notification_full: done")
    end or nil,

    --[[! Function: get_center
        See <Character.get_center>. By default this is the entity position.
        May be overloaded for other entity types.
    ]]
    get_center = function(self)
        return self:get_attr("position"):copy()
    end,

    --[[! Function: __get_edit_color
        Returns the color of the entity icon in edit mode. If an invalid
        value is returned, it defaults to 255, 255, 255 (white). This is
        useful for e.g. light entity that is colored.
    ]]
    __get_edit_color = function(self)
        return 255, 255, 255
    end,

    --[[! Function: __get_edit_info
        Returns any piece of information displayed in in the edit HUD in
        addition to the entity name. Overload for different entity types.
    ]]
    __get_edit_info = function(self)
        return nil
    end,

    --[[! Function: get_attached_entity
        Returns the currently attached entity. Useful mainly for spotlights.
        This refers to the "internally attached" entity that the core engine
        works with.
    ]]
    get_attached_entity = function(self)
        return capi.get_attached_entity(self.uid)
    end,

    --[[! Function: get_edit_drop_height
        Returns the height above the floor to use when dropping the entity
        to the floor. By default returns 4, may be useful to overload (for
        say, mapmodels).
    ]]
    get_edit_drop_height = function(self)
        return 4
    end
}
ents.Static_Entity = Static_Entity

--[[! Function: entity_get_edit_info
    An external. Returns ent.__edit_icon, ent:__get_edit_color().
]]
set_external("entity_get_edit_icon_info", function(ent)
    return ent.__edit_icon, ent:__get_edit_color()
end)

--[[! Function: entity_get_edit_info
    An external. Returns the entity name and the return value of
    <Static_Entity.__get_edit_info>.
]]
set_external("entity_get_edit_info", function(ent)
    return ent.name, ent:__get_edit_info()
end)

--[[! Function: entity_get_edit_drop_height
    An external, see <Entity.get_edit_drop_height>.
]]
set_external("entity_get_edit_drop_height", function(ent)
    return ent:get_edit_drop_height()
end)

--[[! Class: Marker
    A generic marker without orientation. It doesn't have any default
    additional properties.
]]
local Marker = Static_Entity:clone {
    name = "Marker",

    __edit_icon = "media/interface/icon/edit_marker",

    sauer_type = 1,

    --[[! Function: place_entity
        Places an entity on this marker's position.
    ]]
    place_entity = function(self, ent)
        ent:set_attr("position", self:get_attr("position"))
    end
}
ents.Marker = Marker

--[[! Class: Oriented_Marker
    A generic (oriented) marker with a wide variety of uses. Can be used as
    a base for various position markers (e.g. playerstarts). It has two
    properties, attr1 alias yaw, attr2 alias pitch.

    An example of world marker usage is a cutscene system. Different marker
    types inherited from this one can represent different nodes.
]]
local Oriented_Marker = Static_Entity:clone {
    name = "Oriented_Marker",

    __edit_icon = "media/interface/icon/edit_marker",

    sauer_type = 2,
    attr_num   = 2,

    __properties = {
        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch")
    },

    --[[! Function: place_entity
        Places an entity on this marker's position.
    ]]
    place_entity = function(self, ent)
        ent:set_attr("position", self:get_attr("position"))
        ent:set_attr("yaw", self:get_attr("yaw"))
        ent:set_attr("pitch", self:get_attr("pitch"))
    end,

    __get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d", self:get_attr("yaw"),
            self:get_attr("pitch"))
    end
}
ents.Oriented_Marker = Oriented_Marker

local lightflags = setmetatable({
    [0] = "dynamic (0)",
    [1] = "none (1)",
    [2] = "static (2)"
}, {
    __index = function(self, i)
        return ("invalid (%d)"):format(i)
    end
})

--[[! Class: Light
    A regular point light. In the extension library there are special light
    entity types that are e.g. triggered, flickering and so on. When providing
    properties as extra arguments to newent, you can specify red, green, blue,
    radius and shadow in that order.

    Properties:
        attr1 - light radius. (0 to N, alias "radius", default 100 - 0 or
        lower means the light is off)
        attr2 - red value (can be any range, even negative - typical values
        are 0 to 255, negative values make a negative light, alias "red",
        default 128)
        attr3 - green value (alias "green", default 128)
        attr4 - blue value (alias "blue", default 128)
        attr5 - shadow type, 0 means dnyamic, 1 disabled, 2 static (default 0).
]]
local Light = Static_Entity:clone {
    name = "Light",

    __edit_icon = "media/interface/icon/edit_light",

    sauer_type = 3,
    attr_num   = 5,

    __properties = {
        attr1 = gen_attr(1, "radius"),
        attr2 = gen_attr(2, "red"),
        attr3 = gen_attr(3, "green"),
        attr4 = gen_attr(4, "blue"),
        attr5 = gen_attr(5, "shadow")
    },

    __init_svars = function(self, kwargs)
        Static_Entity.__init_svars(self, kwargs)
        local nd = kwargs.newent_data or {}
        self:set_attr("red", 128, nd[1])
        self:set_attr("green", 128, nd[2])
        self:set_attr("blue", 128, nd[3])
        self:set_attr("radius", 100, nd[4])
        self:set_attr("shadow", 0, nd[5])
    end,

    __get_edit_color = function(self)
        return self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue")
    end,

    __get_edit_info = function(self)
        return format("red :\f2 %d \f7| green :\f2 %d \f7| blue :\f2 %d\n\f7"
            .. "radius :\f2 %d \f7| shadow :\f2 %s",
            self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue"), self:get_attr("radius"),
            lightflags[self:get_attr("shadow")])
    end
}
ents.Light = Light

--[[! Class: Spot_Light
    A spot light. It's attached to the nearest <Light>. It has just one
    property, attr1 (alias "radius") which defaults to 90 and is in degrees
    (90 is a full hemisphere, 0 is a line).

    Properties such as color are inherited from the attached light entity.
]]
local Spot_Light = Static_Entity:clone {
    name = "Spot_Light",

    __edit_icon = "media/interface/icon/edit_spotlight",

    sauer_type = 4,
    attr_num   = 1,

    __properties = {
        attr1 = gen_attr(1, "radius")
    },

    __init_svars = function(self, kwargs)
        Static_Entity.__init_svars(self, kwargs)
        self:set_attr("radius", 90)
    end,

    __get_edit_color = function(self)
        local ent = self:get_attached_entity()
        if not ent then return 255, 255, 255 end
        return ent:get_attr("red"), ent:get_attr("green"), ent:get_attr("blue")
    end,

    __get_edit_info = function(self)
        return format("radius :\f2 %d", self:get_attr("radius"))
    end
}
ents.Spot_Light = Spot_Light

--[[! Class: Envmap
    An environment map entity class. Things reflecting on their surface using
    environment maps can generate their envmap from the nearest envmap entity
    instead of using skybox and reflect geometry that way (statically).

    It has one property, radius, which specifies the distance it'll still
    have effect in.
]]
local Envmap = Static_Entity:clone {
    name = "Envmap",

    __edit_icon = "media/interface/icon/edit_envmap",

    sauer_type = 5,
    attr_num   = 1,

    __properties = {
        attr1 = gen_attr(1, "radius")
    },

    __init_svars = function(self, kwargs)
        Static_Entity.__init_svars(self, kwargs)
        self:set_attr("radius", 128)
    end,

    __get_edit_info = function(self)
        return format("radius :\f2 %d", self:get_attr("radius"))
    end
}
ents.Envmap = Envmap

--[[! Class: Sound
    An ambient sound in the world. Repeats the given sound at entity position.

    Properties:
        attr1 - the sound radius (alias "radius", default 100)
        attr2 - the sound size, if this is 0, the sound is a point source,
        otherwise the sound volume will always be max until the distance
        specified by this property and then it'll start fading off
        (alias "size", default 0).
        attr3 - the sound volume, from 0 to 100 (alias "volume", default 100).
        sound_name [<svars.State_String>] - the  path to the sound in
        media/sound (default "").
]]
local Sound = Static_Entity:clone {
    name = "Sound",

    __edit_icon = "media/interface/icon/edit_sound",

    sauer_type = 6,
    attr_num   = 3,

    __properties = {
        attr1 = gen_attr(1, "radius"),
        attr2 = gen_attr(2, "size"),
        attr3 = gen_attr(3, "volume"),
        sound_name = svars.State_String()
    },

    __init_svars = function(self, kwargs)
        Static_Entity.__init_svars(self, kwargs)
        self:set_attr("radius", 100)
        self:set_attr("size", 0)
        self:set_attr("volume", 100)
        self:set_attr("sound_name", "")
    end,

    __activate = (not SERVER) and function(self, ...)
        Static_Entity.__activate(self, ...)
        local f = |self| capi.sound_stop_map(self.uid)
        connect(self, "sound_name_changed", f)
        connect(self, "radius_changed", f)
        connect(self, "size_changed", f)
        connect(self, "volume_changed", f)
    end or nil,

    __get_edit_info = function(self)
        return format("radius :\f2 %d \f7| size :\f2 %d \f7| volume :\f2 %d"
            .. "\n\f7name :\f2 %s",
            self:get_attr("radius"), self:get_attr("size"),
            self:get_attr("volume"), self:get_attr("sound_name"))
    end,

    __play_sound = function(self)
        capi.sound_play_map(self.uid, self:get_attr("sound_name"),
            self:get_attr("volume"))
    end
}
ents.Sound = Sound

set_external("sound_play_map", function(ent)
    ent:__play_sound()
end)

--[[! Class: Particle_Effect
    A particle effect entity class. You can derive from this to create
    your own effects, but by default this doesn't draw anything and is
    not registered.
]]
local Particle_Effect = Static_Entity:clone {
    name = "Particle_Effect",

    __edit_icon  = "media/interface/icon/edit_particles",
    sauer_type = 7,

    --[[! Function: get_edit_drop_height
        Returns 0.
    ]]
    get_edit_drop_height = function(self)
        return 0
    end,

    --[[! Function: __emit_particles
        This is what you need to override - draw your particles from here.
    ]]
    __emit_particles = function(self) end
}
ents.Particle_Effect = Particle_Effect

set_external("particle_entity_emit", function(e)
    e:__emit_particles()
end)

--[[! Class: Mapmodel
    A model in the world. All attrs default to 0. On mapmodels and all
    entity types derived from mapmodels, the engine emits the "collision"
    signal with the collider entity passed as an argument when collided.

    Properties:
        animation [<svars.State_Array>] - the mapmodel's current animation.
        See <Character>.
        animation_flags [<svars.State_Integer>] - the mapmodel's current anim
        flags.
        start_time [<svars.State_Integer>] - an internal property used for
        animation timing.
        model_name [<svars.State_String>] - name of the model associated with
        this mapmodel.
        attachments [<svars.State_Array>] - an array of model attachments.
        Those are strings in format "tagname,attachmentname".
        attr1 - the model yaw, alias "yaw".
        attr2 - the model pitch, alias "pitch".
        attr3 - the model roll, alias "roll".
        attr4 - the model scale, alias "scale".
]]
local Mapmodel = Static_Entity:clone {
    name = "Mapmodel",

    __edit_icon = "media/interface/icon/edit_mapmodel",

    sauer_type = 8,
    attr_num   = 4,

    __properties = {
        animation = svars.State_Array {
            setter = setanim, client_set = true
        },
        animation_flags = svars.State_Integer {
            setter = capi.set_animflags, client_set = true
        },
        start_time  = svars.State_Integer { getter = capi.get_start_time   },
        model_name  = svars.State_String  { setter = capi.set_model_name   },
        attachments = svars.State_Array   {
            setter = function(self, val)
                return set_attachments(self, map(val, function(str)
                    return str:split(",")
                end))
            end
        },

        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch"),
        attr3 = gen_attr(3, "roll"),
        attr4 = gen_attr(4, "scale")
    },

    __init_svars = SERVER and function(self, kwargs)
        Static_Entity.__init_svars(self, kwargs)

        self:set_attr("model_name", "")
        self:set_attr("attachments", {})
        self:set_attr("animation", { "idle,loop" })
        self:set_attr("animation_flags", 0)
    end or nil,

    __activate = SERVER and function(self, kwargs)
        Static_Entity.__activate(self, kwargs)
        self:set_attr("model_name", self:get_attr("model_name"))
    end or nil,

    __get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d \f7| roll :\f2 %d \f7|"
            .. " scale :\f2 %d\n\f7name :\f2 %s",
            self:get_attr("yaw"), self:get_attr("pitch"),
            self:get_attr("roll"), self:get_attr("scale"),
            self:get_attr("model_name"))
    end,

    --[[! Function: get_edit_drop_height
        Returns 0.
    ]]
    get_edit_drop_height = function(self)
        return 0
    end,

    --[[! Function: set_local_animation
        See <Character.set_local_animation>.
    ]]
    set_local_animation = Character.set_local_animation,

    --[[! Function: set_local_animation_flags
        See <Character.set_local_animation_flags>.
    ]]
    set_local_animation_flags = Character.set_local_animation_flags,

    --[[! Function: set_local_model_name
        See <Character.set_local_model_name>.
    ]]
    set_local_model_name = Character.set_local_model_name
}
ents.Mapmodel = Mapmodel

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

--[[! Class: Obstacle
    An entity class that emits a "collision" signal on itself when a client
    (player, NPC...) collides with it. It has its own yaw (attr1), dimensions
    (attr2 alias a, attr3 alias b, attr4 alias c) and the solid property
    (attr5) which makes the obstacle solid when it isn't 0.
]]
local Obstacle = Static_Entity:clone {
    name = "Obstacle",

    sauer_type = 9,
    attr_num   = 7,

    __properties = {
        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch"),
        attr3 = gen_attr(3, "roll"),
        attr4 = gen_attr(4, "a"),
        attr5 = gen_attr(5, "b"),
        attr6 = gen_attr(6, "c"),
        attr7 = gen_attr(7, "solid")
    },

    __init_svars = function(self, kwargs)
        Static_Entity.__init_svars(self, kwargs)
        self:set_attr("yaw", 0)
        self:set_attr("pitch", 0)
        self:set_attr("roll", 0)
        self:set_attr("a", 10)
        self:set_attr("b", 10)
        self:set_attr("c", 10)
        self:set_attr("solid", 0)
    end,

    __get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d \f7| roll :\f2 %d\n\f7"
            .. "a :\f2 %d \f7| b :\f2 %d \f7| c :\f2 %d \f7| solid :\f2 %d",
            self:get_attr("yaw"),  self:get_attr("pitch"),
            self:get_attr("roll"), self:get_attr("a"),
            self:get_attr("b"),    self:get_attr("c"), self:get_attr("solid"))
    end,

    --[[! Function: get_edit_drop_height
        Returns 0.
    ]]
    get_edit_drop_height = function(self)
        return 0
    end
}
ents.Obstacle = Obstacle

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

ents.register_class(Marker)
ents.register_class(Oriented_Marker)
ents.register_class(Light)
ents.register_class(Spot_Light)
ents.register_class(Envmap)
ents.register_class(Sound)
ents.register_class(Mapmodel)
ents.register_class(Obstacle)
