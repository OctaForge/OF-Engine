---
-- base_statent.lua, version 1<br/>
-- Static entity classes for Lua<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 OctaForge project<br/>
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
local glob = require("of.global")
local log = require("of.logging")
local svar = require("of.state_variables")
local class = require("of.class")
local anim = require("of.animatable")
local lcl = require("of.logent.classes")
local lstor = require("of.logent.store")
local json = require("of.json")
local msgsys = require("of.msgsys")
local act = require("of.action")
local CAPI = require("CAPI")

--- This module takes care of static entities.
-- Some of internal methods which are not meant
-- to be overriden are not documented. They are
-- usually documented in parent class, so
-- if you want documentation for them, look
-- in there.
-- @class module
-- @name of.statent
module("of.statent")

--- Base static logic entity class, not meant to be used directly.
-- Inherited from animatable_logent. Unlike dynamic entities,
-- static entities do not usually act (though can be forced to act
-- by overriding should_act property).
-- @class table
-- @name statent
statent = class.new(anim.animatable_logent)
statent._class = "statent"

statent.should_act = false
statent.use_render_dynamic_test = true

statent._sauertype = "extent"
statent._sauertype_index = 0

--- Base properties of static entity.
-- Inherits properties of animatable_logent plus adds its own.
-- @field radius Bounding box radius.
-- @field position Entity position.
-- @field attr1 First attr.
-- @field attr2 Second attr.
-- @field attr3 Third attr.
-- @field attr4 Fourth attr.
-- @class table
-- @name statent.properties
statent.properties = {
    anim.animatable_logent.properties[1], -- tags
    anim.animatable_logent.properties[2], -- _persitent
    anim.animatable_logent.properties[3], -- animation
    anim.animatable_logent.properties[4], -- starttime
    anim.animatable_logent.properties[5], -- modelname
    anim.animatable_logent.properties[6], -- attachments

    { "radius", svar.state_float() }, -- TODO: use sauer values for bounding box -- XXX - needed?

    { "position", svar.wrapped_cvec3({ cgetter = "CAPI.getextent0", csetter = "CAPI.setextent0" }) },
    { "attr1", svar.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1" }) },
    { "attr2", svar.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2" }) },
    { "attr3", svar.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3" }) },
    { "attr4", svar.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setattr4" }) }
}

--- Init method. Performs initial setup.
-- @param uid Unique ID for the entity.
-- @param kwargs Table of additional parameters (for i.e. overriding _persistent, position)
function statent:init(uid, kwargs)
    log.log(log.DEBUG, "statent:init")

    kwargs = kwargs or {}
    kwargs._persistent = true -- static entities are persistent by default

    anim.animatable_logent.init(self, uid, kwargs)

    if not kwargs and not kwargs.position then
        self.position = { 511, 512, 513 }
    else
        self.position = { base.tonumber(kwargs.position.x), base.tonumber(kwargs.position.y), base.tonumber(kwargs.position.z) }
    end
    self.radius = 0

    log.log(log.DEBUG, "statent:init complete")
end

--- Serverside entity activation.
-- @param kwargs Table of additional parameters.
function statent:activate(kwargs)
    kwargs = kwargs or {}

    log.log(log.DEBUG, base.tostring(self.uid) .. " statent: __base.activate() " .. json.encode(kwargs))
    anim.animatable_logent.activate(self, kwargs)

    if not kwargs._type then
        kwargs._type = self._sauertype_index
    end

    log.log(log.DEBUG, "statent defaults:")
    kwargs.x = self.position.x or 512
    kwargs.y = self.position.y or 512
    kwargs.z = self.position.z or 512
    kwargs.attr1 = self.attr1 or 0
    kwargs.attr2 = self.attr2 or 0
    kwargs.attr3 = self.attr3 or 0
    kwargs.attr4 = self.attr4 or 0

    log.log(log.DEBUG, "statent: setupextent:")
    CAPI.setupextent(self, kwargs._type, kwargs.x, kwargs.y, kwargs.z, kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4)

    log.log(log.DEBUG, "statent: flush:")
    self:_flush_queued_sv_changes()

    -- ensure the state data contains copies fo C++ stuff (toherwise, might be empty, and we need it for initializing on the server)
    -- XXX: needed?
    log.log(log.DEBUG, "ensuring statent values - deprecate")
    log.log(log.DEBUG, "position: " .. base.tostring(self.position.x) .. ", " .. base.tostring(self.position.y) .. ", " .. base.tostring(self.position.z))
    log.log(log.DEBUG, "position class: " .. base.tostring(self.position))
    self.position = self.position -- trigger SV change
    log.log(log.DEBUG, "position(2): " .. base.tostring(self.position.x) .. ", " .. base.tostring(self.position.y) .. ", " .. base.tostring(self.position.z))
    log.log(log.DEBUG, "ensuring statent values (2)")
    self.attr1 = self.attr1; self.attr2 = self.attr2; self.attr3 = self.attr3; self.attr4 = self.attr4
    log.log(log.DEBUG, "ensuring statent values complete.")
end

--- Serverside deactivation. Removes the entity in C store and calls parent.
function statent:deactivate()
    CAPI.dismantleextent(self)
    anim.animatable_logent.deactivate(self)
end

--- Clientside entity activation.
-- @param kwargs Table of additional parameters.
function statent:client_activate(kwargs)
    if not kwargs._type then -- make up some stuff until we get complete state data
        kwargs._type = self._sauertype_index
        kwargs.x = 512
        kwargs.y = 512
        kwargs.z = 512
        kwargs.attr1 = 0
        kwargs.attr2 = 0
        kwargs.attr3 = 0
        kwargs.attr4 = 0
    end

    CAPI.setupextent(self, kwargs._type, kwargs.x, kwargs.y, kwargs.z, kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4)
    anim.animatable_logent.client_activate(self, kwargs)
end

--- Clientside deactivation. Removes the entity in C store and calls parent.
function statent:client_deactivate()
    CAPI.dismantleextent(self)
    anim.animatable_logent.client_deactivate(self)
end

--- Send complete notification to client(s).
-- @param cn Client number to send to. All clients if nil.
function statent:send_notification_complete(cn)
    cn = cn or msgsys.ALL_CLIENTS
    local cns = cn == msgsys.ALL_CLIENTS and lstor.get_all_clientnums() or { cn }
    log.log(log.DEBUG, "statent:send_notification_complete:")
    for i = 1, #cns do
        msgsys.send(cns[i],
                    CAPI.extent_notification_complete,
                    self.uid,
                    base.tostring(self),
                    self:create_statedatadict(cns[i], { compressed = true }), -- custom data per client
                    base.tonumber(self.position.x),
                    base.tonumber(self.position.y),
                    base.tonumber(self.position.z),
                    base.tonumber(self.attr1),
                    base.tonumber(self.attr2),
                    base.tonumber(self.attr3),
                    base.tonumber(self.attr4))
    end
    log.log(log.DEBUG, "statent:send_notification_complete done.")
end

--- Get center position of static entity, something like gravity center.
-- Override if your center is nonstandard.
-- By default, it's self.radius above bottom.
-- @return Center position which is a vec3.
function statent:get_center()
    local r = self.position:copy()
    r.z = r.z + base.tonumber(self.radius)
    return r
end

--- Light entity class.
-- @class table
-- @name light
light = class.new(statent)
light._class = "light"
light._sauertype_index = 1

--- Light entity class properties.
-- Inherits some properties of statent plus adds its own.
-- @field attr1 Custom attr1.
-- @field attr2 Custom attr2.
-- @field attr3 Custom attr3.
-- @field attr4 Custom attr4.
-- @field radius Alias for attr1.
-- @field red Alias for attr2.
-- @field green Alias for attr3.
-- @field blue Alias for attr4.
-- @class table
-- @name light.properties
light.properties = {
    statent.properties[1], -- tags
    statent.properties[2], -- _persitent
    statent.properties[3], -- animation
    statent.properties[4], -- starttime
    statent.properties[5], -- modelname
    statent.properties[6], -- attachments

    statent.properties[8], -- position

    { "attr1", svar.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "radius", altname = "radius" }) },
    { "attr2", svar.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2", guiname = "red", altname = "red" }) },
    { "attr3", svar.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3", guiname = "green", altname = "green" }) },
    { "attr4", svar.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setattr4", guiname = "blue", altname = "blue" }) },

    { "radius", svar.variable_alias("attr1") },
    { "red", svar.variable_alias("attr2") },
    { "green", svar.variable_alias("attr3") },
    { "blue", svar.variable_alias("attr4") }
}

function light:init(uid, kwargs)
    statent.init(self, uid, kwargs)

    -- default values
    self.radius = 100
    self.red = 128
    self.green = 128
    self.blue = 128
end

--- Spotlight entity class.
-- @class table
-- @name spotlight
spotlight = class.new(statent)
spotlight._class = "spotlight"
spotlight._sauertype_index = 7

--- Spotlight entity class properties.
-- Inherits some properties of statent plus adds its own.
-- @field attr1 Custom attr1.
-- @field radius Alias for attr1.
-- @class table
-- @name spotlight.properties
spotlight.properties = {
    statent.properties[1], -- tags
    statent.properties[2], -- _persitent
    statent.properties[3], -- animation
    statent.properties[4], -- starttime
    statent.properties[5], -- modelname
    statent.properties[6], -- attachments

    statent.properties[8], -- position

    { "attr1", svar.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "radius", altname = "radius" }) },
    { "radius", svar.variable_alias("attr1") }
}

function spotlight:init(uid, kwargs)
    statent.init(self, uid, kwargs)
    self.radius = 90
end

--- Envmap entity class.
-- @class table
-- @name envmap
envmap = class.new(statent)
envmap._class = "envmap"
envmap._sauertype_index = 4

--- Envmap entity class properties.
-- Inherits some properties of statent plus adds its own.
-- @field attr1 Custom attr1.
-- @field radius Alias for attr1.
-- @class table
-- @name envmap.properties
envmap.properties = {
    statent.properties[1], -- tags
    statent.properties[2], -- _persitent
    statent.properties[3], -- animation
    statent.properties[4], -- starttime
    statent.properties[5], -- modelname
    statent.properties[6], -- attachments

    statent.properties[8], -- position

    { "attr1", svar.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "radius", altname = "radius" }) },
    { "radius", svar.variable_alias("attr1") }
}

function envmap:init(uid, kwargs)
    statent.init(self, uid, kwargs)
    self.radius = 128
end

--- Ambient sound entity class.
-- @class table
-- @name ambient_sound
ambient_sound = class.new(statent)
ambient_sound._class = "ambient_sound"
ambient_sound._sauertype_index = 6

--- Ambient sound entity class properties.
-- Inherits some properties of statent plus adds its own.
-- @field attr2 Custom attr2.
-- @field attr3 Custom attr3.
-- @field attr4 Custom attr4.
-- @field soundname Path to the sound file.
-- @field radius Alias for attr2.
-- @field size Alias for attr3.
-- @field volume Alias for attr4.
-- @class table
-- @name ambient_sound.properties
ambient_sound.properties = {
    statent.properties[1], -- tags
    statent.properties[2], -- _persitent
    statent.properties[3], -- animation
    statent.properties[4], -- starttime
    statent.properties[5], -- modelname
    statent.properties[6], -- attachments

    statent.properties[8], -- position

    { "attr2", svar.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2", guiname = "radius", altname = "radius" }) },
    { "attr3", svar.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3", guiname = "size", altname = "size" }) },
    { "attr4", svar.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setsoundvol", guiname = "volume", altname = "volume" }) },
    { "soundname", svar.wrapped_cstring({ csetter = "CAPI.setsoundname" }) },

    { "radius", svar.variable_alias("attr2") },
    { "size", svar.variable_alias("attr3") },
    { "volume", svar.variable_alias("attr4") }
}

function ambient_sound:init(uid, kwargs)
    statent.init(self, uid, kwargs)
    -- attr1 is the slot index - replaced
    self.attr1 = -1
    self.radius = 100
    self.size = 0
    if not self.volume then self.volume = 100 end
    self.soundname = ""
end

--- Particle effect entity class.
-- @class table
-- @name particle_effect
particle_effect = class.new(statent)
particle_effect._class = "particle_effect"
particle_effect._sauertype_index = 5

--- Particle effect entity class properties.
-- Inherits some properties of statent plus adds its own.
-- @field attr1 Custom attr2.
-- @field attr2 Custom attr2.
-- @field attr3 Custom attr3.
-- @field attr4 Custom attr4.
-- @field particle_type Alias for attr1.
-- @field value1 Alias for attr2.
-- @field value2 Alias for attr3.
-- @field value3 Alias for attr4.
-- @class table
-- @name particle_effect.properties
particle_effect.properties = {
    statent.properties[1], -- tags
    statent.properties[2], -- _persitent
    statent.properties[3], -- animation
    statent.properties[4], -- starttime
    statent.properties[5], -- modelname
    statent.properties[6], -- attachments
    statent.properties[7], -- radius

    statent.properties[8], -- position

    { "attr1", svar.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "particle_type", altname = "particle_type" }) },
    { "attr2", svar.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2", guiname = "value1", altname = "value1" }) },
    { "attr3", svar.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3", guiname = "value2", altname = "value2" }) },
    { "attr4", svar.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setattr4", guiname = "value3", altname = "value3" }) },

    { "particle_type", svar.variable_alias("attr1") },
    { "value1", svar.variable_alias("attr2") },
    { "value2", svar.variable_alias("attr3") },
    { "value3", svar.variable_alias("attr4") }
}

function particle_effect:init(uid, kwargs)
    statent.init(self, uid, kwargs)

    self.particle_type = 0
    self.value1 = 0
    self.value2 = 0
    self.value3 = 0
end

--- Mapmodel entity class.
-- @class table
-- @name mapmodel
mapmodel = class.new(statent)
mapmodel._class = "mapmodel"
mapmodel._sauertype_index = 2

--- Mapmodel entity class properties.
-- Inherits some properties of statent plus adds its own.
-- @field attr1 Custom attr1.
-- @field yaw Alias for attr1.
-- @field collision_radius_width Collision radius width.
-- @field collision_radius_height Collision radius height.
-- @class table
-- @name mapmodel.properties
mapmodel.properties = {
    statent.properties[1], -- tags
    statent.properties[2], -- _persitent
    statent.properties[3], -- animation
    statent.properties[4], -- starttime
    statent.properties[5], -- modelname
    statent.properties[6], -- attachments
    statent.properties[7], -- radius

    statent.properties[8], -- position

    { "attr1", svar.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "yaw", altname = "yaw" }) },
    { "yaw", svar.variable_alias("attr1") },

    { "collision_radius_width", svar.wrapped_cinteger({
        cgetter = "CAPI.getcollisionradw",
        csetter = "CAPI.setcollisionradw"
    }) },

    { "collision_radius_height", svar.wrapped_cinteger({
        cgetter = "CAPI.getcollisionradh",
        csetter = "CAPI.setcollisionradh"
    }) }
}

function mapmodel:init(uid, kwargs)
    log.log(log.DEBUG, "mapmodel:init")
    statent.init(self, uid, kwargs)

    self.attr2 = -1 -- sauer mapmodel index - put as -1 to use out model names as default
    self.yaw = 0

    self.collision_radius_width = 0
    self.collision_radius_height = 0

    log.log(log.DEBUG, "mapmodel:init complete.")
end

function mapmodel:client_activate(kwargs)
    statent.client_activate(self, kwargs)
end

--- On collision handler (serverside). Can be overriden (see area_trigger)
-- @param collider Colliding entity.
-- @see area_trigger:on_collision
function mapmodel:on_collision(collider)
end

--- On collision handler (clientside). Can be overriden (see area_trigger)
-- @param collider Colliding entity.
-- @see area_trigger:client_on_collision
function mapmodel:client_on_collision(collider)
end

--- Overriden center getter for mapmodel.
-- It uses collision_radius_height instead
-- of radius if available, otherwise standard radius.
function mapmodel:get_center()
    if self.collision_radius_height then
        local r = self.position:copy()
        r.z = r.z + base.tonumber(self.collision_radius_height)
        return r
    else
        return statent.get_center(self)
    end
end

--- Area trigger entity class. Inherited from mapmodel.
-- Calls a script when an entity goes through it.
-- @class table
-- @name area_trigger
area_trigger = class.new(mapmodel)
area_trigger._class = "area_trigger"
-- ran on collision

--- Area trigger entity class properties.
-- Inherits properties of mapmodel plus adds its own.
-- @field script_to_run Script to run on trigger (when entity goes through it)
-- @class table
-- @name area_trigger.properties
area_trigger.properties = {
    mapmodel.properties[1], -- tags
    mapmodel.properties[2], -- _persitent
    mapmodel.properties[3], -- animation
    mapmodel.properties[4], -- starttime
    mapmodel.properties[5], -- modelname
    mapmodel.properties[6], -- attachments
    mapmodel.properties[7], -- radius

    mapmodel.properties[8], -- position

    mapmodel.properties[9], -- attr1
    mapmodel.properties[10], -- yaw

    mapmodel.properties[11], -- collision_radius_width
    mapmodel.properties[12], -- collision_radius_height

    { "script_to_run", svar.state_string() }
}

function area_trigger:init(uid, kwargs)
    mapmodel.init(self, uid, kwargs)

    self.script_to_run = ""
    self.collision_radius_width = 10
    self.collision_radius_height = 10
    self.modelname = "areatrigger" -- hardcoded, appropriate model, with collisions only for triggering and perentity collision boxes.
end

--- Overriden collision handler. Area trigger works serverside.
-- @param collider The colliding entity.
function area_trigger:on_collision(collider)
    --- XXX potential security risk
    if base.tostring(self.script_to_run) ~= "" then
        base.loadstring("return " .. base.tostring(self.script_to_run))()(collider)
    end
end

--- Resettable area trigger entity class. Inherited from area_trigger.
-- Calls a script when an entity goes through it. Can be re-set.
-- @class table
-- @name resettable_area_trigger
resettable_area_trigger = class.new(area_trigger)
resettable_area_trigger._class = "resettable_area_trigger"
resettable_area_trigger.properties = area_trigger.properties

function resettable_area_trigger:activate(kwargs)
    area_trigger.activate(self, kwargs)
    self:reset()
end

function resettable_area_trigger:client_activate(kwargs)
    area_trigger.client_activate(self, kwargs)
    self:reset()
end

function resettable_area_trigger:on_collision(collider)
    --- XXX potential security risk
    if self.ready_to_trigger then
        self.ready_to_trigger = false
    else
        return nil
    end

    if base.tostring(self.script_to_run) ~= "" then
        area_trigger.on_collision(self, collider)
    else
        self:on_trigger(collider)
    end
end

function resettable_area_trigger:client_on_collision(collider)
    --- XXX potential security risk
    if self.ready_to_trigger then
        self.ready_to_trigger = false
    else
        return nil
    end

    if base.tostring(self.script_to_run) ~= "" then
        area_trigger.client_on_collision(self, collider)
    else
        self:client_on_trigger(collider)
    end
end

--- Reset handler.
function resettable_area_trigger:reset()
    self.ready_to_trigger = true
    if glob.SERVER then
        self:on_reset()
    else
        self:client_on_reset()
    end
end

--- Custom - overridable - on reset handler (serverside)
function resettable_area_trigger:on_reset()
end

--- Custom - overridable - on reset handler (clientside)
function resettable_area_trigger:client_on_reset()
end

--- Custom - overridable - on trigger handler (serverside)
-- @param collider The colliding entity.
function resettable_area_trigger:on_trigger(collider)
end

--- Custom - overridable - on trigger handler (clientside)
-- @param collider The colliding entity.
function resettable_area_trigger:client_on_trigger(collider)
end

--- World marker entity class. Serves as generic marker
-- in the world, so can be used as player start,
-- point to later get from scripting system etc.
-- @class table
-- @name world_marker
world_marker = class.new(statent)
world_marker._class = "world_marker"
world_marker._sauertype_index = 3

--- World marker entity class properties.
-- Inherits some properties of statent plus adds its own.
-- @field attr1 Custom attr1.
-- @field yaw Alias for attr1.
-- @class table
-- @name world_marker.properties
world_marker.properties = {
    statent.properties[1], -- tags
    statent.properties[2], -- _persitent
    statent.properties[3], -- animation
    statent.properties[4], -- starttime
    statent.properties[5], -- modelname
    statent.properties[6], -- attachments
    statent.properties[7], -- radius

    statent.properties[8], -- position

    { "attr1", svar.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "yaw", altname = "yaw" }) },
    { "yaw", svar.variable_alias("attr1") }
}

--- Make an entity be placed on position of this marker with its yaw.
-- @param ent Entity to place.
function world_marker:place_entity(ent)
    ent.position = self.position
    ent.yaw = self.yaw
end

lcl.reg(statent, "mapmodel")
lcl.reg(light, "light")
lcl.reg(spotlight, "spotlight")
lcl.reg(envmap, "envmap")
lcl.reg(ambient_sound, "sound")
lcl.reg(particle_effect, "particles")
lcl.reg(mapmodel, "mapmodel")
lcl.reg(area_trigger, "mapmodel")
lcl.reg(resettable_area_trigger, "mapmodel")
lcl.reg(world_marker, "playerstart")
