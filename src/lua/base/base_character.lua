--[[!
    File: base/base_character.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features character and player entities.

    Section: Character system
]]

--[[!
    Package: character
    This module contains character entity and player entity.
]]
module("character", package.seeall)

--[[!
    Struct: CSTATE
    Fields of this table represent the current "client state".

    Fields:
        ALIVE - means client is alive.
        DEAD - unused by us, handled differently.
        SPAWNING - unused by us.
        LAGGED - client is lagged.
        EDITING - client is editing.
        SPECTATOR - client is spectator.
]]
CSTATE = {
    ALIVE = 0,
    DEAD = 1,
    SPAWNING = 2,
    LAGGED = 3,
    EDITING = 4,
    SPECTATOR = 5
}

--[[!
    Struct: PSTATE
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
PSTATE = {
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
        position - character position, vec3 (x, y, z).
        velocity - character velocity, vec3 (x, y, z).
        falling - character falling, vec3 (x, y, z).
        radius - character bounding box radius, float.
        aboveeye - distance from position vector to eyes.
        eyeheight - distance from eyes to feet.
        blocked - true if character was blocked by obstacle on last
        movement cycle, boolean. Floor is not an obstacle.
        canmove - if false, character can't move, boolean.
        mapdefinedposdata - position protocol data specific to current map,
        see fpsent, integer (TODO: make unsigned)
        cs - client state, integer. (see CSTATE table)
        ps - physical state, integer. (see PSTATE table)
        inwater - 1 if character is underwater, integer.
        timeinair - time in miliseconds spent in the air, integer (Should be unsigned, TODO)

    See Also:
        <player>
]]
character = class.new(entity_animated.animatable_logent)

--[[!
    Variable: _class
    The entity class for character. Its value is usually
    the same as class name, but doesn't have to be.
]]
character._class = "character"

--[[!
    Variable: _sauertype
    The sauertype of the entity. Fpsent is a dynamic character entity in sauer.
]]
character._sauertype = "fpsent"

character.properties = {
    _name = state_variables.state_string(),
    facing_speed = state_variables.state_integer(),

    movement_speed = state_variables.wrapped_cfloat({ cgetter = "CAPI.getmaxspeed", csetter = "CAPI.setmaxspeed" }),
    yaw = state_variables.wrapped_cfloat({ cgetter = "CAPI.getyaw", csetter = "CAPI.setyaw", customsynch = true }),
    pitch = state_variables.wrapped_cfloat({ cgetter = "CAPI.getpitch", csetter = "CAPI.setpitch", customsynch = true }),
    move = state_variables.wrapped_cinteger({ cgetter = "CAPI.getmove", csetter = "CAPI.setmove", customsynch = true }),
    strafe = state_variables.wrapped_cinteger({ cgetter = "CAPI.getstrafe", csetter = "CAPI.setstrafe", customsynch = true }),
--  intention to yaw / pitch. todo: enable
--  yawing = state_variables.wrapped_cinteger({ cgetter = "CAPI.getyawing", csetter = "CAPI.setyawing", customsynch = true }),
--  pitching = state_variables.wrapped_cinteger({ cgetter = "CAPI.getpitching", csetter = "CAPI.setpitching", customsynch = true }),
    position = state_variables.wrapped_cvec3({ cgetter = "CAPI.getdynent0", csetter = "CAPI.setdynent0", customsynch = true }),
    velocity = state_variables.wrapped_cvec3({ cgetter = "CAPI.getdynentvel", csetter = "CAPI.setdynentvel", customsynch = true }),
    falling = state_variables.wrapped_cvec3({ cgetter = "CAPI.getdynentfalling", csetter = "CAPI.setdynentfalling", customsynch = true }),
    radius = state_variables.wrapped_cfloat({ cgetter = "CAPI.getradius", csetter = "CAPI.setradius" }),
    aboveeye = state_variables.wrapped_cfloat({ cgetter = "CAPI.getaboveeye", csetter = "CAPI.setaboveeye" }),
    eyeheight = state_variables.wrapped_cfloat({ cgetter = "CAPI.geteyeheight", csetter = "CAPI.seteyeheight" }),
    blocked = state_variables.wrapped_cbool({ cgetter = "CAPI.getblocked", csetter = "CAPI.setblocked" }),
    canmove = state_variables.wrapped_cbool({ csetter = "CAPI.setcanmove", clientset = true }),
    mapdefinedposdata = state_variables.wrapped_cinteger({ cgetter = "CAPI.getmapdefinedposdata", csetter = "CAPI.setmapdefinedposdata", customsynch = true }),
    cs = state_variables.wrapped_cinteger({ cgetter = "CAPI.getclientstate", csetter = "CAPI.setclientstate", customsynch = true }),
    ps = state_variables.wrapped_cinteger({ cgetter = "CAPI.getphysstate", csetter = "CAPI.setphysstate", customsynch = true }),
    inwater = state_variables.wrapped_cinteger({ cgetter = "CAPI.getinwater", csetter = "CAPI.setinwater", customsynch = true }),
    timeinair = state_variables.wrapped_cinteger({ cgetter = "CAPI.gettimeinair", csetter = "CAPI.settimeinair", customsynch = true })
}

--[[!
    Function: jump
    This is handler called when a character jumps.
]]
function character:jump()
    CAPI.setjumping(self, true)
end

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
        <animatable_logent.init>
        <activate>
]]
function character:init(uid, kwargs)
    logging.log(logging.DEBUG, "character:init")
    entity_animated.animatable_logent.init(self, uid, kwargs)

    self._name = "-?-" -- set by the server later
    self.cn = kwargs and kwargs.cn or -1
    self.modelname = "player"
    self.eyeheight = 14.0
    self.aboveeye = 1.0
    self.movement_speed = 50.0
    self.facing_speed = 120
    self.position = { 512, 512, 550 }
    self.radius = 3.0
    self.canmove = true
end

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
        <animatable_logent.activate>
        <client_activate>
        <init>
]]
function character:activate(kwargs)
    logging.log(logging.DEBUG, "character:activate")
    self.cn = kwargs and kwargs.cn or -1
    assert(self.cn >= 0)

    CAPI.setupcharacter(self)
    entity_animated.animatable_logent.activate(self, kwargs)
    self:_flush_queued_sv_changes()

    logging.log(logging.DEBUG, "character:activate complete.")
end

--[[!
    Function: client_activate
    This is clientside activator. It's called when
    entity is almost ready. Kwargs listed here are the ones
    that are specific to this class.

    Parameters:
        kwargs - additional parameters.

    Kwargs:
        cn - Client number. Passed automatically.

    See Also:
        <client_logent.client_activate>
        <activate>
]]
function character:client_activate(kwargs)
    entity_animated.animatable_logent.client_activate(self, kwargs)
    self.cn = kwargs and kwargs.cn or -1
    CAPI.setupcharacter(self)

    self.rendering_args_timestamp = -1
end

--[[!
    Function: deactivate
    This is serverside deactivator.
    Ran when the entity is about to vanish.
]]
function character:deactivate()
    CAPI.dismantlecharacter(self)
    entity_animated.animatable_logent.deactivate(self)
end

--[[!
    Function: client_deactivate
    This is clientside deactivator.
    Ran when the entity is about to vanish.
]]
function character:client_deactivate()
    CAPI.dismantlecharacter(self)
    entity_animated.animatable_logent.client_deactivate(self)
end

--[[!
    Function: act
    This is a function ran serverside every frame.

    Parameters:
        sec - Length of time to simulate.

    See Also:
        <default_action>
]]
function character:act(sec)
    if self.action_system:isempty() then
        self:default_action(sec)
    else
        entity_animated.animatable_logent.act(self, sec)
    end
end

--[[!
    Function: default_action
    This is ran serverside by <act> if the action queue
    is empty. Override however you need, it does nothing
    by default.

    Parameters:
        sec - Length of time to simulate.

    See Also:
        <act>
]]
function character:default_action(sec)
end

--[[!
    Function: render_dynamic
    Clientside function ran every frame. It takes care of
    actually rendering the character model.
    It does computation of parameters, but caches them
    so it remains fast.

    Parameters:
        hudpass - true if we're rendering HUD right now.
        needhud - true if model should be shown as HUD model
        (== we're in first person)
]]
function character:render_dynamic(hudpass, needhud)
    if not self.initialized then return nil end
    if not hudpass and needhud then return nil end

    if self.rendering_args_timestamp ~= entity_store.curr_timestamp then
        local state = self.cs
        if state == CSTATE.SPECTAROR or state == CSTATE.SPAWNING then return nil end

        local mdlname = (hudpass and needhud) and self.hud_modelname or self.modelname
        local yaw = self.yaw + 90
        local pitch = self.pitch
        local o = self.position:copy()
        
        if hudpass and needhud and self.hud_modeloffset then o:add(self.hud_modeloffset) end
        local basetime = self.starttime
        local physstate = self.ps
        local inwater = self.inwater
        local move = self.move
        local strafe = self.strafe
        local vel = self.velocity:copy()
        local falling = self.falling:copy()
        local timeinair = self.timeinair
        local anim = self:decide_animation(state, physstate, move, strafe, vel, falling, inwater, timeinair)
        local flags = self:get_renderingflags(hudpass, needhud)

        self.rendering_args = { self, mdlname, anim, o.x, o.y, o.z, yaw, pitch, flags, basetime }
        self.rendering_args_timestamp = entity_store.curr_timestamp
    end

    -- render only when model is set
    if self.rendering_args[2] ~= "" then model.render(unpack(self.rendering_args)) end
end

--[[!
    Function: get_renderingflags
    This function is used by <render_dynamic> to get model rendering flags.
    By default, it enables some occlusion and dynamic shadow.
    It as well enables some HUD-specific flags for HUD models.

    Parameters:
        hudpass - true if we're rendering HUD right now.
        needhud - true if model should be shown as HUD model
        (== we're in first person)

    Returns:
        Resulting rendering flags.

    See Also:
        <render_dynamic>
]]
function character:get_renderingflags(hudpass, needhud)
    local flags = math.bor(model.LIGHT, model.DYNSHADOW, model.FULLBRIGHT)
    if self ~= entity_store.get_plyent() then
        flags = math.bor(flags, model.CULL_VFC, model.CULL_OCCLUDED, model.CULL_QUERY)
    end
    if hudpass and needhud then
        flags = math.bor(flags, model.HUD)
    end
    return flags -- TODO: for non-characters, use flags = math.bor(flags, model.CULL_DIST)
end

--[[!
    Function: decide_animation
    This function is used by <render_dynamic> to get current model animation.
    This is guessed from values like strafe, move, inwater etc.

    Parameters:
        state - Current client state (see <CSTATE>)
        pstate - Current physical state (see <PSTATE>)
        move - Whether character is moving currently and which direction (1, 0, -1)
        strafe - Whether character is strafing currently and which direction (1, 0, -1)
        vel - Current character velocity (vec3)
        falling - Current character falling (vec3)
        inwater - Whether character is in water (1, 0)
        timeinair - Time character is in air.

    Returns:
        Resulting animation.

    See Also:
        <render_dynamic>
]]
function character:decide_animation(state, pstate, move, strafe, vel, falling, inwater, timeinair)
    -- same naming convention as rendermodel.cpp in cube 2
    local anim = self:decide_action_animation()

    if state == CSTATE.EDITING or state == CSTATE.SPECTATOR then
        anim = math.bor(actions.ANIM_EDIT, actions.ANIM_LOOP)
    elseif state == CSTATE.LAGGED then
        anim = math.bor(actions.ANIM_LAG, actions.ANIM_LOOP)
    else
        if inwater ~= 0 and pstate <= PSTATE.FALL then
            anim = math.bor(anim, math.lsh(math.bor(((move or strafe) or vel.z + falling.z > 0) and actions.ANIM_SWIM or actions.ANIM_SINK, actions.ANIM_LOOP), actions.ANIM_SECONDARY))
        elseif timeinair > 250 then
            anim = math.bor(anim, math.lsh(math.bor(actions.ANIM_JUMP, actions.ANIM_END), actions.ANIM_SECONDARY))
        elseif move ~= 0 or strafe ~= 0 then
            if move > 0 then
                anim = math.bor(anim, math.lsh(math.bor(actions.ANIM_FORWARD, actions.ANIM_LOOP), actions.ANIM_SECONDARY))
            elseif strafe ~= 0 then
                anim = math.bor(anim, math.lsh(math.bor((strafe > 0 and ANIM_LEFT or ANIM_RIGHT), actions.ANIM_LOOP), actions.ANIM_SECONDARY))
            elseif move < 0 then
                anim = math.bor(anim, math.lsh(math.bor(actions.ANIM_BACKWARD, actions.ANIM_LOOP), actions.ANIM_SECONDARY))
            end
        end

        if math.band(anim, actions.ANIM_INDEX) == actions.ANIM_TITLE and math.band(math.rsh(anim, actions.ANIM_SECONDARY), actions.ANIM_INDEX) then
            anim = math.rsh(anim, actions.ANIM_SECONDARY)
        end
    end

    if math.band(math.rsh(anim, actions.ANIM_SECONDARY), actions.ANIM_INDEX) == 0 then
        anim = math.bor(anim, math.lsh(math.bor(actions.ANIM_IDLE, actions.ANIM_LOOP), actions.ANIM_SECONDARY))
    end

    return anim
end

--[[!
    Function: decide_action_animation
    Returns the "action" animation to show. Does not handle things like
    inwater, lag, etc which are handled in decide_animation.

    Returns:
        By default, simply returns self.animation, but can be overriden to handle more complex
        things like taking into account map-specific information in mapdefinedposdata.

    See Also:
        <decide_animation>
]]
function character:decide_action_animation()
    return self.animation
end

--[[!
    Function: decide_action_animation
    Gets center position of character, something like gravity center.
    For example AI bots would better aim at this point instead of "position"
    which is feet position. Override if your center is nonstandard.
    By default, it's 0.75 * eyeheight above feet.

    Returns:
        Center position which is a vec3.
]]
function character:get_center()
    local r = self.position:copy()
    r.z = r.z + self.eyeheight * 0.75
    return r
end

--[[!
    Function: is_onfloor
    Gets whether the character is on floor.

    Returns:
        true if character is on floor, false otherwise.
]]
function character:is_onfloor()
    if floor_dist(self.position, 1024) < 1 then return true end
    if self.velocity.z < -1 or self.falling.z < -1 then return false end
    return utility.iscolliding(self.position, self.radius + 2, self)
end

--[[!
    Class: player
    This represents the base class for player.
    Inherits from <character> and serves as a base
    for all overriden player classes.

    Properties listed here are only those which are added.

    Properties:
        _can_edit - true if player can edit (== is in private edit mode)
        hud_modelname - by default empty string representing the model
        name to use when in first person.

    See Also:
        <character>
]]
player = class.new(character)

--[[!
    Variable: _class
    The entity class for player. Its value is usually
    the same as class name, but doesn't have to be.
]]
player._class = "player"

player.properties = {
    _can_edit = state_variables.state_bool(),
    hud_modelname = state_variables.state_string()
}

--[[!
    Function: init
    See <character.init>.

    Parameters:
        uid - player unique ID.
        kwargs - additional parameters.

    See Also:
        <character.init>
]]
function player:init(uid, kwargs)
    logging.log(logging.DEBUG, "player:init")
    character.init(self, uid, kwargs)

    self._can_edit = false
    self.hud_modelname = ""
end

entity_classes.reg(character, "fpsent")
entity_classes.reg(player, "fpsent")
