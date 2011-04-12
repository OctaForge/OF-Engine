---
-- base_character.lua, version 1<br/>
-- Character handling for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local base = _G
local table = require("table")
local math = require("math")
local log = require("cc.logging")
local svar = require("cc.state_variables")
local class = require("cc.class")
local anim = require("cc.animatable")
local lstor = require("cc.logent.store")
local lcl = require("cc.logent.classes")
local mdl = require("cc.model")
local act = require("cc.action")
local util = require("cc.utils")
local CAPI = require("CAPI")

--- This module takes care of character entity, states and player entity.
-- @class module
-- @name cc.character
module("cc.character")

-- these reflect ents.h
CSTATE = {
    ALIVE = 0,
    DEAD = 1, -- unused by us
    SPAWNING = 2, -- unused by us
    LAGGED = 3,
    EDITING = 4,
    SPECTATOR = 5
}
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

character = class.new(anim.animatable_logent)
character._class = "character"
character._sauertype = "fpsent"

character.properties = {
    anim.animatable_logent.properties[1], -- tags
    anim.animatable_logent.properties[2], -- _persitent
    anim.animatable_logent.properties[3], -- animation
    anim.animatable_logent.properties[4], -- starttime
    anim.animatable_logent.properties[5], -- modelname
    anim.animatable_logent.properties[6], -- attachments

    { "_name", svar.state_string() },
    { "facing_speed", svar.state_integer() },

    { "movement_speed", svar.wrapped_cfloat({ cgetter = "CAPI.getmaxspeed", csetter = "CAPI.setmaxspeed" }) },
    { "yaw", svar.wrapped_cfloat({ cgetter = "CAPI.getyaw", csetter = "CAPI.setyaw", customsynch = true }) },
    { "pitch", svar.wrapped_cfloat({ cgetter = "CAPI.getpitch", csetter = "CAPI.setpitch", customsynch = true }) },
    { "move", svar.wrapped_cinteger({ cgetter = "CAPI.getmove", csetter = "CAPI.setmove", customsynch = true }) },
    { "strafe", svar.wrapped_cinteger({ cgetter = "CAPI.getstrafe", csetter = "CAPI.setstrafe", customsynch = true }) },
--  intention to yaw / pitch. todo: enable
--  { "yawing", svar.wrapped_cinteger({ cgetter = "CAPI.getyawing", csetter = "CAPI.setyawing", customsynch = true }) },
--  { "pitching", svar.wrapped_cinteger({ cgetter = "CAPI.getpitching", csetter = "CAPI.setpitching", customsynch = true }) },
    { "position", svar.wrapped_cvec3({ cgetter = "CAPI.getdynent0", csetter = "CAPI.setdynent0", customsynch = true }) },
    { "velocity", svar.wrapped_cvec3({ cgetter = "CAPI.getdynentvel", csetter = "CAPI.setdynentvel", customsynch = true }) },
    { "falling", svar.wrapped_cvec3({ cgetter = "CAPI.getdynentfalling", csetter = "CAPI.setdynentfalling", customsynch = true }) },
    { "radius", svar.wrapped_cfloat({ cgetter = "CAPI.getradius", csetter = "CAPI.setradius" }) },
    { "aboveeye", svar.wrapped_cfloat({ cgetter = "CAPI.getaboveeye", csetter = "CAPI.setaboveeye" }) },
    { "eyeheight", svar.wrapped_cfloat({ cgetter = "CAPI.geteyeheight", csetter = "CAPI.seteyeheight" }) },
    { "blocked", svar.wrapped_cbool({ cgetter = "CAPI.getblocked", csetter = "CAPI.setblocked" }) },
    { "canmove", svar.wrapped_cbool({ csetter = "CAPI.setcanmove", clientset = true }) },
    { "mapdefinedposdata", svar.wrapped_cinteger({ cgetter = "CAPI.getmapdefinedposdata", csetter = "CAPI.setmapdefinedposdata", customsynch = true }) },
    { "cs", svar.wrapped_cinteger({ cgetter = "CAPI.getclientstate", csetter = "CAPI.setclientstate", customsynch = true }) },
    { "ps", svar.wrapped_cinteger({ cgetter = "CAPI.getphysstate", csetter = "CAPI.setphysstate", customsynch = true }) },
    { "inwater", svar.wrapped_cinteger({ cgetter = "CAPI.getinwater", csetter = "CAPI.setinwater", customsynch = true }) },
    { "timeinair", svar.wrapped_cinteger({ cgetter = "CAPI.gettimeinair", csetter = "CAPI.settimeinair", customsynch = true }) }
}

function character:jump()
    CAPI.setjumping(self, true)
end

function character:init(uid, kwargs)
    log.log(log.DEBUG, "character:init")
    anim.animatable_logent.init(self, uid, kwargs)

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

function character:activate(kwargs)
    log.log(log.DEBUG, "character:activate")
    self.cn = kwargs and kwargs.cn or -1
    base.assert(self.cn >= 0)

    CAPI.setupcharacter(self)
    anim.animatable_logent.activate(self, kwargs)
    self:_flush_queued_sv_changes()

    log.log(log.DEBUG, "character:activate complete.")
end

function character:client_activate(kwargs)
    anim.animatable_logent.client_activate(self, kwargs)
    self.cn = kwargs and kwargs.cn or -1
    CAPI.setupcharacter(self)

    self.rendering_args_timestamp = -1
end

function character:deactivate()
    CAPI.dismantlecharacter(self)
    anim.animatable_logent.deactivate(self)
end

function character:client_deactivate()
    CAPI.dismantlecharacter(self)
    anim.animatable_logent.client_deactivate(self)
end

function character:act(sec)
    if self.action_system:isempty() then
        self:default_action(sec)
    else
        anim.animatable_logent.act(self, sec)
    end
end

function character:default_action(sec)
end

function character:render_dynamic(hudpass, needhud)
    if not self.initialized then return nil end
    if not hudpass and needhud then return nil end

    if self.rendering_args_timestamp ~= lstor.curr_timestamp then
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
        local flags = self:get_renderingflags()

        self.rendering_args = { self, mdlname, anim, o.x, o.y, o.z, yaw, pitch, 0, flags, basetime }
        self.rendering_args_timestamp = lstor.curr_timestamp
    end

    -- render only when model is set
    if self.rendering_args[2] ~= "" then mdl.render(base.unpack(self.rendering_args)) end
end

function character:get_renderingflags()
    local flags = math.bor(mdl.LIGHT, mdl.DYNSHADOW)
    if self ~= lstor.get_plyent() then
        flags = math.bor(flags, mdl.CULL_VFC, mdl.CULL_OCCLUDED, mdl.CULL_QUERY)
    end
    return flags -- TODO: for non-characters, use flags = math.bor(flags, mdl.CULL_DIST)
end

function character:decide_animation(state, pstate, move, strafe, vel, falling, inwater, timeinair)
    -- same naming convention as rendermodel.cpp in cube 2
    local anim = self:decide_action_animation()

    if state == CSTATE.EDITING or state == CSTATE.SPECTATOR then
        anim = math.bor(act.ANIM_EDIT, act.ANIM_LOOP)
    elseif state == CSTATE.LAGGED then
        anim = math.bor(act.ANIM_LAG, act.ANIM_LOOP)
    else
        if inwater and pstate <= PSTATE.FALL then
            anim = math.bor(anim, math.lsh(math.bor(((move or strafe) or vel.z + falling.z > 0) and act.ANIM_SWIM or act.ANIM_SINK, act.ANIM_LOOP), act.ANIM_SECONDARY))
        elseif timeinair > 250 then
            anim = math.bor(anim, math.lsh(math.bor(act.ANIM_JUMP, act.ANIM_END), act.ANIM_SECONDARY))
        elseif move or strafe then
            if move > 0 then
                anim = math.bor(anim, math.lsh(math.bor(act.ANIM_FORWARD, act.ANIM_LOOP), act.ANIM_SECONDARY))
            elseif strafe then
                anim = math.bor(anim, math.lsh(math.bor((strafe > 0 and ANIM_LEFT or ANIM_RIGHT), act.ANIM_LOOP), act.ANIM_SECONDARY))
            elseif move < 0 then
                anim = math.bor(anim, math.lsh(math.bor(act.ANIM_BACKWARD, act.ANIM_LOOP), act.ANIM_SECONDARY))
            end
        end

        if math.band(anim, act.ANIM_INDEX) == act.ANIM_TITLE and math.band(math.rsh(anim, act.ANIM_SECONDARY), act.ANIM_INDEX) then
            anim = math.rsh(anim, act.ANIM_SECONDARY)
        end
    end

    if not math.band(math.rsh(anim, act.ANIM_SECONDARY), act.ANIM_INDEX) then
        anim = math.bor(anim, math.lsh(math.bor(act.ANIM_IDLE, act.ANIM_LOOP), act.ANIM_SECONDARY))
    end

    return anim
end

function character:decide_action_animation()
    return self.animation
end

function character:get_center()
    local r = self.position:copy()
    r.z = r.z + self.eyeheight * 0.75
    return r
end

function character:get_targeting_origin(o)
    return o
end

function character:is_onfloor()
    if floor_dist(self.position, 1024) < 1 then return true end
    if self.velocity.z < -1 or self.falling.z < -1 then return false end
    return util.iscolliding(self.position, self.radius + 2, self)
end

player = class.new(character)
player._class = "player"

player.properties = {
    character.properties[1], -- tags
    character.properties[2], -- _persitent
    character.properties[3], -- animation
    character.properties[4], -- starttime
    character.properties[5], -- modelname
    character.properties[6], -- attachments

    character.properties[7], -- _name
    character.properties[8], -- facing_speed

    character.properties[9], -- movement_speed
    character.properties[10], -- yaw
    character.properties[11], -- pitch
    character.properties[12], -- move
    character.properties[13], -- strafe
    -- character.properties[X], -- yawing
    -- character.properties[X], -- pitching
    character.properties[14], -- position
    character.properties[15], -- velocity
    character.properties[16], -- falling
    character.properties[17], -- radius
    character.properties[18], -- aboveeye
    character.properties[19], -- eyeheight
    character.properties[20], -- blocked
    character.properties[21], -- canmove
    character.properties[22], -- mapdefinedposdata
    character.properties[23], -- cs
    character.properties[24], -- ps
    character.properties[25], -- inwater
    character.properties[26], -- timeinair

    { "_can_edit", svar.state_bool() },
    { "hud_modelname", svar.state_string() }
}

function player:init(uid, kwargs)
    log.log(log.DEBUG, "player:init")
    character.init(self, uid, kwargs)

    self._can_edit = false
    self.hud_modelname = ""
end

lcl.reg(character, "fpsent")
lcl.reg(player, "fpsent")
