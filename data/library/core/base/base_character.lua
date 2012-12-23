--[[!
    File: library/core/base/base_character.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features character and player entities.
]]

--[[!
    Package: character
    This module contains character entity and player entity.
]]
module("character", package.seeall)

--[[!
    Struct: CLIENT_STATE
    Fields of this table represent the current "client state".

    Fields:
        ALIVE - means client is alive.
        DEAD - unused by us, handled differently.
        SPAWNING - unused by us.
        LAGGED - client is lagged.
        EDITING - client is editing.
        SPECTATOR - client is spectator.
]]
CLIENT_STATE = {
    ALIVE = 0,
    DEAD = 1,
    SPAWNING = 2,
    LAGGED = 3,
    EDITING = 4,
    SPECTATOR = 5
}

--[[!
    Struct: PHYSICAL_STATE
    Fields of this table represent the current "physical state" of a client.

    Fields:
        FLOAT - client is floating.
        FALL - client is falling.
        SLIDE - client is sliding.
        SLOPE - client is sloping.
        FLOOR - client is on floor.
        STEP_UP - client is stepping up.
        STEP_DOWN - client is stepping down.
        BOUNCE - client is bouncing.
]]
PHYSICAL_STATE = {
    FLOAT = 0,
    FALL = 1, 
    SLIDE = 2, 
    SLOPE = 3, 
    FLOOR = 4, 
    STEP_UP = 5, 
    STEP_DOWN = 6, 
    BOUNCE = 7
}

--[[!
    Class: character
    This represents the base class for character.
    It serves as a base for "player" class.

    Properties are handled using state variables.

    Properties:
        _name - character name.
        facing_speed - how fast can character change facing
        (yaw / pitch) in degrees/second, integer.
        movement_speed - character movement speed, float.
        yaw - character yaw, integer.
        pitch - character pitch, integer.
        move - -1 when moving backwards, 0 when not, 1 when forward, integer.
        strafe - -1 when strafing left, 1 when right, 0 when not, integer.
        yawing - -1 when turning left, 1 when right, 0 when not.
        pitching - -1 when looking down, 1 when up, 0 when not.
        position - character position, vec3 (x, y, z).
        velocity - character velocity, vec3 (x, y, z).
        falling - character gravity falling, vec3 (x, y, z).
        radius - character bounding box radius, float.
        above_eye - distance from position vector to eyes.
        eye_height - distance from eyes to feet.
        blocked - true if character was blocked by obstacle on last
        movement cycle, boolean. Floor is not an obstacle.
        can_move - if false, character can't move, boolean.
        map_defined_position_data - position protocol data
        specific to current map, see fpsent, integer (TODO: make unsigned)
        client_state - client state, integer. (see <CLIENT_STATE>)
        physical_state - physical state, integer. (see <PHYSICAL_STATE>)
        in_water - 1 if character is underwater, integer.
        time_in_air - time in miliseconds spent in the air, integer
        (Should be unsigned, TODO)

    See Also:
        <player>
]]
character = ents.Physical_Entity:clone {
    name = "character",

    --[[!
        Variable: sauer_type
        The sauer type of the entity, fpsent
        is a dynamic character entity in sauer.
    ]]
    sauer_type = "fpsent",

    properties = {
        -- non-wrapped properties
        _name        = svars.State_String(),
        facing_speed = svars.State_Integer(),

        -- wrapped C properties
        movement_speed = svars.State_Float {
            getter = "CAPI.getmaxspeed",
            setter = "CAPI.setmaxspeed"
        },
        yaw = svars.State_Float {
            getter = "CAPI.getyaw",
            setter = "CAPI.setyaw",
            custom_sync = true
        },
        pitch = svars.State_Float {
            getter = "CAPI.getpitch",
            setter = "CAPI.setpitch",
            custom_sync = true
        },
        move = svars.State_Integer {
            getter = "CAPI.getmove",
            setter = "CAPI.setmove",
            custom_sync = true
        },
        strafe = svars.State_Integer {
            getter = "CAPI.getstrafe",
            setter = "CAPI.setstrafe",
            custom_sync = true
        },
        yawing = svars.State_Integer {
            getter = "CAPI.getyawing",
            setter = "CAPI.setyawing",
            custom_sync = true
        },
        pitching = svars.State_Integer {
            getter = "CAPI.getpitching",
            setter = "CAPI.setpitching",
            custom_sync = true
        },
        position = svars.State_Vec3 {
            getter = "CAPI.getdynent0",
            setter = "CAPI.setdynent0",
            custom_sync = true
        },
        velocity = svars.State_Vec3 {
            getter = "CAPI.getdynentvel",
            setter = "CAPI.setdynentvel",
            custom_sync = true
        },
        falling = svars.State_Vec3 {
            getter = "CAPI.getdynentfalling",
            setter = "CAPI.setdynentfalling",
            custom_sync = true
        },
        radius = svars.State_Float {
            getter = "CAPI.getradius",
            setter = "CAPI.setradius"
        },
        above_eye = svars.State_Float {
            getter = "CAPI.getaboveeye",
            setter = "CAPI.setaboveeye"
        },
        eye_height = svars.State_Float {
            getter = "CAPI.geteyeheight",
            setter = "CAPI.seteyeheight"
        },
        blocked = svars.State_Boolean {
            getter = "CAPI.getblocked",
            setter = "CAPI.setblocked"
        },
        can_move = svars.State_Boolean {
            setter = "CAPI.setcanmove",
            client_set = true
        },
        map_defined_position_data = svars.State_Integer {
            getter = "CAPI.getmapdefinedposdata",
            setter = "CAPI.setmapdefinedposdata",
            custom_sync = true
        },
        client_state = svars.State_Integer {
            getter = "CAPI.getclientstate",
            setter = "CAPI.setclientstate",
            custom_sync = true
        },
        physical_state = svars.State_Integer {
            getter = "CAPI.getphysstate",
            setter = "CAPI.setphysstate",
            custom_sync = true
        },
        in_water = svars.State_Integer {
            getter = "CAPI.getinwater",
            setter = "CAPI.setinwater",
            custom_sync = true
        },
        time_in_air = svars.State_Integer {
            getter = "CAPI.gettimeinair",
            setter = "CAPI.settimeinair",
            custom_sync = true
        }
    },

    --[[!
        Function: jump
        This is handler called when a character jumps.
    ]]
    jump = function(self)
        CAPI.setjumping(self, true)
    end,

    --[[!
        Function: init
        This is serverside initializer. It's called right on creation, when
        the entity is still not fully ready. Kwargs listed here are the ones
        that are specific to this class.

        Parameters:
            uid - character unique ID.
            kwargs - additional parameters.

        Kwargs:
            cn - Client number. Passed automatically.

        See Also:
            <Physical_Entity.init>
            <activate>
    ]]
    init = function(self, uid, kwargs)
        log(DEBUG, "character:init")
        ents.Physical_Entity.init(self, uid, kwargs)

        -- initial properties set by server, _name is set even later
        self._name          = "-?-"
        self.cn             = kwargs and kwargs.cn or -1
        self.model_name     = "player"
        self.eye_height     = 14.0
        self.above_eye      = 1.0
        self.movement_speed = 50.0
        self.facing_speed   = 120
        self.position       = { 512, 512, 550 }
        self.radius         = 3.0
        self.can_move       = true

        -- useful getters / setters for scoreboard
        self:define_getter("plag", function() return CAPI.getplag(self) end)
        self:define_getter("ping", function() return CAPI.getping(self) end)
    end,

    --[[!
        Function: activate
        This is serverside activator. Unlike <init>, it's called when
        entity is almost ready. Kwargs listed here are the ones
        that are specific to this class.

        Parameters:
            kwargs - additional parameters.

        Kwargs:
            cn - Client number. Passed automatically.

        See Also:
            <Physical_Entity.activate>
            <init>
    ]]
    activate = SERVER and function(self, kwargs)
        log(DEBUG, "character:activate")

        -- client number is set when character gets activated
        -- once again, asserting valid value
        self.cn = kwargs and kwargs.cn or -1
        assert(self.cn >= 0)

        -- we set up character sauer-side now
        CAPI.setupcharacter(self)

        -- we activate parent and flush variable changes
        ents.Physical_Entity.activate(self, kwargs)
        self:flush_queued_svar_changes()

        log(DEBUG, "character:activate complete.")
    end or function(self, kwargs)
        ents.Physical_Entity.activate(self, kwargs)

        -- we assert the client number on client as well
        self.cn = kwargs and kwargs.cn or -1
        CAPI.setupcharacter(self)

        -- and reset the timestamp
        self.rendering_args_timestamp = -1
    end,

    --[[!
        Function: deactivate
        This is serverside deactivator.
        Ran when the entity is about to vanish.
    ]]
    deactivate = function(self)
        -- we dismantle character and call parent deactivation
        CAPI.dismantlecharacter(self)
        ents.Physical_Entity.deactivate(self)
    end,

    --[[!
        Function: run
        This is a function ran serverside every frame.

        Parameters:
            seconds - Length of time to simulate.

        See Also:
            <default_action>
    ]]
    run = SERVER and function(self, seconds)
        -- if we're empty, we run default_action, which
        -- does nothing by default (but can be overriden)
        if #self.action_system:get() == 0 then
            self:default_action(seconds)
        else
            -- otherwise we run on parent
            ents.Physical_Entity.run(self, seconds)
        end
    end or nil,

    --[[!
        Function: default_action
        This is ran serverside by <act> if the action queue
        is empty. Override however you need, it does nothing
        by default.

        Parameters:
            seconds - Length of time to simulate.

        See Also:
            <act>
    ]]
    default_action = function(self, seconds)
    end,

    --[[!
        Function: render
        Clientside function ran every frame. It takes care of
        actually rendering the character model.
        It does computation of parameters, but caches them
        so it remains fast.
        If we're rendering a HUD model and the character has
        member variable hud_model_offset, which is a vec3,
        we can offset the HUD model that way.

        Parameters:
            hudpass - true if we're rendering HUD right now.
            needhud - true if model should be shown as HUD model
            (== we're in first person)
    ]]
    render = function(self, hudpass, needhud)
        -- just return if we're not yet initialized or shouldn't render
        if not self.initialized    then return nil end
        if not hudpass and needhud then return nil end

        -- re-generate the parameters if timestamp changed - efficiency
        if self.rendering_args_timestamp ~= frame.get_frame() then
            -- this is current client state, used when deciding animation
            local state = self.client_state

            -- if we're spectator or not spawned yet,
            -- then we don't render and return
            if state == CLIENT_STATE.SPECTAROR
            or state == CLIENT_STATE.SPAWNING then
                return nil
            end

            -- select model name according to if we
            -- want to firstperson model or thirdperson model
            local mdlname = (hudpass and needhud)
                and self.hud_model_name
                or self.model_name

            -- player yaw, rotated by 90° to remain
            -- compatible with sauer characters
            local yaw = self.yaw + 90

            -- player pitch
            local pitch = self.pitch

            -- player position
            local o = self.position:copy()

            -- we support offseting on HUD models, not used by default
            if hudpass and needhud and self.hud_model_offset then
                o:add(self.hud_model_offset)
            end

            -- time when we start rendering
            local basetime = self.start_time

            -- character physical state, for animation deciding
            local physstate = self.physical_state

            -- are we in water? for swimming animation
            local in_water = self.in_water

            -- save whether we're moving or strafing and which direction
            local move   = self.move
            local strafe = self.strafe

            -- save character velocity and falling as well
            local vel     = self.velocity:copy()
            local falling = self.falling:copy ()

            -- how long are we in air? for, again, animation deciding
            local time_in_air = self.time_in_air

            -- finally decide the animation
            local anim = self:decide_animation(
                state, physstate, move, strafe,
                vel, falling, in_water, time_in_air
            )

            -- and rendering flags (dynamic shadow, culling etc.)
            local flags = self:get_rendering_flags(hudpass, needhud)

            -- create a table of rendering arguments
            -- and save a timestamp for caching
            self.rendering_args = {
                self, mdlname, anim, o,
                yaw, pitch, flags, basetime
            }
            self.rendering_args_timestamp = frame.get_frame()
        end

        -- render only when model is set using the rendering arguments table
        if self.rendering_args[2] ~= "" then
            model.render(unpack(self.rendering_args))
        end
    end,

    --[[!
        Function: get_rendering_flags
        This function is used by <render> to get model rendering flags.
        By default, it enables some occlusion and dynamic shadow.
        It as well enables some HUD-specific flags for HUD models.

        Parameters:
            hudpass - true if we're rendering HUD right now.
            needhud - true if model should be shown as HUD model
            (== we're in first person)

        Returns:
            Resulting rendering flags.

        See Also:
            <render>
    ]]
    get_rendering_flags = function(self, hudpass, needhud)
        local flags = model.FULLBRIGHT

        -- for non-player, we add some culling flags
        if self ~= ents.get_player() then
            flags = math.bor(
                flags,
                model.CULL_VFC,
                model.CULL_OCCLUDED,
                model.CULL_QUERY
            )
        end

        -- return final flags
        return flags
    end,

    --[[!
        Function: decide_animation
        This function is used by <render>
        to get current model animation. This is guessed
        from values like strafe, move, in_water etc.

        Parameters:
            state - Current client state (see <CLIENT_STATE>)
            pstate - Current physical state (see <PHYSICAL_STATE>)
            move - Whether character is moving currently
            and which direction (1, 0, -1)
            strafe - Whether character is strafing currently
            and which direction (1, 0, -1)
            vel - Current character velocity (vec3)
            falling - Current character falling (vec3)
            in_water - Whether character is in water (1, 0)
            time_in_air - Time character is in air.

        Returns:
            Resulting animation.

        See Also:
            <render>
    ]]
    decide_animation = function(
        self, state, pstate,
        move, strafe, vel,
        falling, in_water, time_in_air
    )
        -- decide action animation - by default
        -- just returns self.animation, but can be overriden
        local anim = self:decide_action_animation()

        if state == CLIENT_STATE.EDITING
        or state == CLIENT_STATE.SPECTATOR then
            -- in editing and spec mode, use edit animation and loop it
            anim = math.bor(model.ANIM_EDIT, model.ANIM_LOOP)
        elseif state == CLIENT_STATE.LAGGED then
            -- in lagged state, loop lag animation
            anim = math.bor(model.ANIM_LAG, model.ANIM_LOOP)
        else
            -- more complex deciding
            if in_water ~= 0 and pstate <= PHYSICAL_STATE.FALL then
                -- in water, decide either swimming
                -- or sinking secondary animation
                anim = math.bor(
                    anim,
                    math.lsh(
                        math.bor(
                            ((move or strafe) or vel.z + falling.z > 0)
                                and model.ANIM_SWIM
                                or  model.ANIM_SINK,
                            model.ANIM_LOOP
                        ),
                        model.ANIM_SECONDARY
                    )
                )
            elseif time_in_air > 250 then
                -- jumping secondary animation gets decided,
                -- if we're in air for more than 250 miliseconds
                anim = math.bor(
                    anim,
                    math.lsh(
                        math.bor(
                            model.ANIM_JUMP,
                            model.ANIM_END
                        ),
                        model.ANIM_SECONDARY
                    )
                )
            elseif move ~= 0 or strafe ~= 0 then
                -- if we're moving or strafing, decide appropriate animations
                if move > 0 then
                    -- if we're moving forward, loop
                    -- secondary forward animation
                    anim = math.bor(
                        anim,
                        math.lsh(
                            math.bor(model.ANIM_FORWARD, model.ANIM_LOOP),
                            model.ANIM_SECONDARY
                        )
                    )
                elseif strafe ~= 0 then
                    -- if we're strafing any direction, but not
                    -- moving forward, loop secondary strafe animation
                    anim = math.bor(
                        anim,
                        math.lsh(
                            math.bor(
                                (strafe > 0 and ANIM_LEFT or ANIM_RIGHT),
                                model.ANIM_LOOP
                            ),
                            model.ANIM_SECONDARY
                        )
                    )
                elseif move < 0 then
                    -- if we're moving backwards with no strafe,
                    -- loop secondary backward animation
                    anim = math.bor(
                        anim,
                        math.lsh(
                            math.bor(model.ANIM_BACKWARD, model.ANIM_LOOP),
                            model.ANIM_SECONDARY
                        )
                    )
                end
            end

            if  math.band(anim, model.ANIM_INDEX) == model.ANIM_IDLE
            and math.band(
                math.rsh(anim, model.ANIM_SECONDARY),
                model.ANIM_INDEX
            ) ~= 0 then
                anim = math.rsh(anim, model.ANIM_SECONDARY)
            end
        end

        if math.band(
            math.rsh(anim, model.ANIM_SECONDARY),
            model.ANIM_INDEX
        ) == 0 then
            anim = math.bor(
                anim,
                math.lsh(
                    math.bor(model.ANIM_IDLE, model.ANIM_LOOP),
                    model.ANIM_SECONDARY
                )
            )
        end

        return anim
    end,

    --[[!
        Function: decide_action_animation
        Returns the "action" animation to show. Does not handle things like
        in_water, lag, etc which are handled in decide_animation.

        Returns:
            By default, simply returns self.animation,
            but can be overriden to handle more complex
            things like taking into account map-specific
            information in map_defined_position_data.

        See Also:
            <decide_animation>
    ]]
    decide_action_animation = function(self)
        return self.animation
    end,

    --[[!
        Function: get_center
        Gets center position of character, something like gravity center.
        For example AI bots would better aim at this point instead of
        "position" which is feet position. Override if your center is
        nonstandard. By default, it's 0.75 * eye_height above feet.

        Returns:
            Center position which is a vec3.
    ]]
    get_center = function(self)
        local r = self.position:copy()
        r.z = r.z + self.eye_height * 0.75
        return r
    end,

    --[[!
        Function: is_on_floor
        Gets whether the character is on floor.

        Returns:
            true if character is on floor, false otherwise.
    ]]
    is_on_floor = function(self)
        if floor_dist(self.position, 1024) < 1 then
            return true
        end

        if self.velocity.z < -1 or self.falling.z < -1 then
            return false
        end

        return geometry.is_colliding(self.position, self.radius + 2, self)
    end,

    --[[!
        Function: get_targeting_origin
        Given an origin position (usually from an attachment tag),
        fix it so it corresponds to where player actually targeted
        from.
    ]]
    get_targeting_origin = function(self, origin)
        return origin
    end,

    is_editing = function(self)
        return self.client_state == 4
    end
}

--[[!
    Class: player
    This represents the base class for player.
    Inherits from <character> and serves as a base
    for all overriden player classes.

    Properties listed here are only those which are added.

    Properties:
        can_edit - true if player can edit (== is in private edit mode)
        hud_model_name - by default empty string representing the model
        name to use when in first person.

    See Also:
        <character>
]]
player = character:clone {
    name = "player",

    properties = {
        can_edit = svars.State_Boolean(),
        hud_model_name = svars.State_String()
    },

    --[[!
        Function: init
        See <character.init>.

        Parameters:
            uid - player unique ID.
            kwargs - additional parameters.

        See Also:
            <character.init>
    ]]
    init = function(self, uid, kwargs)
        log(DEBUG, "player:init")
        -- init on parent, then add its own properties
        character.init(self, uid, kwargs)

        -- its own properties
        self.can_edit       = false
        self.hud_model_name = ""
    end
}

ents.register_class(character)
ents.register_class(player)
