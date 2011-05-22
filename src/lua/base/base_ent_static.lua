--[[!
    File: base/base_ent_static.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features static logic entity class.

    Section: Static entity system
]]

--[[!
    Package: entity_static
    This module handles static entities. It contains all base static entities,
    the raw sauer ones, which you can then use as a base for custom ones.
]]
module("entity_static", package.seeall)

--- Base static logic entity class, not meant to be used directly.
-- Inherited from animatable_logent. Unlike dynamic entities,
-- static entities do not usually act (though can be forced to act
-- by overriding should_act property).
-- @class table
-- @name statent
statent = class.new(entity_animated.animatable_logent)
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
    radius = state_variables.state_float(), -- TODO: use sauer values for bounding box -- XXX - needed?

    position = state_variables.wrapped_cvec3({ cgetter = "CAPI.getextent0", csetter = "CAPI.setextent0" }),
    attr1 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1" }),
    attr2 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2" }),
    attr3 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3" }),
    attr4 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setattr4" })
}

--- Init method. Performs initial setup.
-- @param uid Unique ID for the entity.
-- @param kwargs Table of additional parameters (for i.e. overriding _persistent, position)
function statent:init(uid, kwargs)
    logging.log(logging.DEBUG, "statent:init")

    kwargs = kwargs or {}
    kwargs._persistent = true -- static entities are persistent by default

    entity_animated.animatable_logent.init(self, uid, kwargs)

    if not kwargs and not kwargs.position then
        self.position = { 511, 512, 513 }
    else
        self.position = { tonumber(kwargs.position.x), tonumber(kwargs.position.y), tonumber(kwargs.position.z) }
    end
    self.radius = 0

    logging.log(logging.DEBUG, "statent:init complete")
end

--- Serverside entity activation.
-- @param kwargs Table of additional parameters.
function statent:activate(kwargs)
    kwargs = kwargs or {}

    logging.log(logging.DEBUG, tostring(self.uid) .. " statent: __activate() " .. json.encode(kwargs))
    entity_animated.animatable_logent.activate(self, kwargs)

    if not kwargs._type then
        kwargs._type = self._sauertype_index
    end

    logging.log(logging.DEBUG, "statent defaults:")
    kwargs.x = self.position.x or 512
    kwargs.y = self.position.y or 512
    kwargs.z = self.position.z or 512
    kwargs.attr1 = self.attr1 or 0
    kwargs.attr2 = self.attr2 or 0
    kwargs.attr3 = self.attr3 or 0
    kwargs.attr4 = self.attr4 or 0

    logging.log(logging.DEBUG, "statent: setupextent:")
    CAPI.setupextent(self, kwargs._type, kwargs.x, kwargs.y, kwargs.z, kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4)

    logging.log(logging.DEBUG, "statent: flush:")
    self:_flush_queued_sv_changes()

    -- ensure the state data contains copies fo C++ stuff (toherwise, might be empty, and we need it for initializing on the server)
    -- XXX: needed?
    logging.log(logging.DEBUG, "ensuring statent values - deprecate")
    logging.log(logging.DEBUG, "position: " .. tostring(self.position.x) .. ", " .. tostring(self.position.y) .. ", " .. tostring(self.position.z))
    logging.log(logging.DEBUG, "position class: " .. tostring(self.position))
    self.position = self.position -- trigger SV change
    logging.log(logging.DEBUG, "position(2): " .. tostring(self.position.x) .. ", " .. tostring(self.position.y) .. ", " .. tostring(self.position.z))
    logging.log(logging.DEBUG, "ensuring statent values (2)")
    self.attr1 = self.attr1; self.attr2 = self.attr2; self.attr3 = self.attr3; self.attr4 = self.attr4
    logging.log(logging.DEBUG, "ensuring statent values complete.")
end

--- Serverside deactivation. Removes the entity in C store and calls parent.
function statent:deactivate()
    CAPI.dismantleextent(self)
    entity_animated.animatable_logent.deactivate(self)
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
    entity_animated.animatable_logent.client_activate(self, kwargs)
end

--- Clientside deactivation. Removes the entity in C store and calls parent.
function statent:client_deactivate()
    CAPI.dismantleextent(self)
    entity_animated.animatable_logent.client_deactivate(self)
end

--- Send complete notification to client(s).
-- @param cn Client number to send to. All clients if nil.
function statent:send_notification_complete(cn)
    cn = cn or message.ALL_CLIENTS
    local cns = cn == message.ALL_CLIENTS and entity_store.get_all_clientnums() or { cn }
    logging.log(logging.DEBUG, "statent:send_notification_complete:")
    for i = 1, #cns do
        message.send(cns[i],
                    CAPI.extent_notification_complete,
                    self.uid,
                    tostring(self),
                    self:create_statedatadict(cns[i], { compressed = true }), -- custom data per client
                    tonumber(self.position.x),
                    tonumber(self.position.y),
                    tonumber(self.position.z),
                    tonumber(self.attr1),
                    tonumber(self.attr2),
                    tonumber(self.attr3),
                    tonumber(self.attr4))
    end
    logging.log(logging.DEBUG, "statent:send_notification_complete done.")
end

--- Get center position of static entity, something like gravity center.
-- Override if your center is nonstandard.
-- By default, it's self.radius above bottom.
-- @return Center position which is a vec3.
function statent:get_center()
    local r = self.position:copy()
    r.z = r.z + tonumber(self.radius)
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
    attr1 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "radius", altname = "radius" }),
    attr2 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2", guiname = "red", altname = "red" }),
    attr3 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3", guiname = "green", altname = "green" }),
    attr4 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setattr4", guiname = "blue", altname = "blue" }),

    radius = state_variables.variable_alias("attr1"),
    red = state_variables.variable_alias("attr2"),
    green = state_variables.variable_alias("attr3"),
    blue = state_variables.variable_alias("attr4")
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
    attr1 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "radius", altname = "radius" }),
    radius = state_variables.variable_alias("attr1")
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
    attr1 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "radius", altname = "radius" }),
    radius = state_variables.variable_alias("attr1")
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
    attr2 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2", guiname = "radius", altname = "radius" }),
    attr3 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3", guiname = "size", altname = "size" }),
    attr4 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setsoundvol", guiname = "volume", altname = "volume" }),
    soundname = state_variables.wrapped_cstring({ csetter = "CAPI.setsoundname" }),

    radius = state_variables.variable_alias("attr2"),
    size = state_variables.variable_alias("attr3"),
    volume = state_variables.variable_alias("attr4")
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
    attr1 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "particle_type", altname = "particle_type" }),
    attr2 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr2", csetter = "CAPI.setattr2", guiname = "value1", altname = "value1" }),
    attr3 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr3", csetter = "CAPI.setattr3", guiname = "value2", altname = "value2" }),
    attr4 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr4", csetter = "CAPI.setattr4", guiname = "value3", altname = "value3" }),

    particle_type = state_variables.variable_alias("attr1"),
    value1 = state_variables.variable_alias("attr2"),
    value2 = state_variables.variable_alias("attr3"),
    value3 = state_variables.variable_alias("attr4")
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
    attr1 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "yaw", altname = "yaw" }),
    yaw = state_variables.variable_alias("attr1")
}

mapmodel.collision_radius_width = state_variables.wrapped_cinteger({
        cgetter = "CAPI.getcollisionradw",
        csetter = "CAPI.setcollisionradw"
    })

mapmodel.collision_radius_height = state_variables.wrapped_cinteger({
        cgetter = "CAPI.getcollisionradh",
        csetter = "CAPI.setcollisionradh"
    })

function mapmodel:init(uid, kwargs)
    logging.log(logging.DEBUG, "mapmodel:init")
    statent.init(self, uid, kwargs)

    self.attr2 = -1 -- sauer mapmodel index - put as -1 to use out model names as default
    self.yaw = 0

    self.collision_radius_width = 0
    self.collision_radius_height = 0

    logging.log(logging.DEBUG, "mapmodel:init complete.")
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
        r.z = r.z + tonumber(self.collision_radius_height)
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
    script_to_run = state_variables.state_string()
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
    if tostring(self.script_to_run) ~= "" then
        loadstring("return " .. tostring(self.script_to_run))()(collider)
    end
end

--- Resettable area trigger entity class. Inherited from area_trigger.
-- Calls a script when an entity goes through it. Can be re-set.
-- @class table
-- @name resettable_area_trigger
resettable_area_trigger = class.new(area_trigger)
resettable_area_trigger._class = "resettable_area_trigger"

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

    if tostring(self.script_to_run) ~= "" then
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

    if tostring(self.script_to_run) ~= "" then
        area_trigger.client_on_collision(self, collider)
    else
        self:client_on_trigger(collider)
    end
end

--- Reset handler.
function resettable_area_trigger:reset()
    self.ready_to_trigger = true
    if SERVER then
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
    attr1 = state_variables.wrapped_cinteger({ cgetter = "CAPI.getattr1", csetter = "CAPI.setattr1", guiname = "yaw", altname = "yaw" }),
    yaw = state_variables.variable_alias("attr1")
}

--- Make an entity be placed on position of this marker with its yaw.
-- @param ent Entity to place.
function world_marker:place_entity(ent)
    ent.position = self.position
    ent.yaw = self.yaw
end

entity_classes.reg(statent, "mapmodel")
entity_classes.reg(light, "light")
entity_classes.reg(spotlight, "spotlight")
entity_classes.reg(envmap, "envmap")
entity_classes.reg(ambient_sound, "sound")
entity_classes.reg(particle_effect, "particles")
entity_classes.reg(mapmodel, "mapmodel")
entity_classes.reg(area_trigger, "mapmodel")
entity_classes.reg(resettable_area_trigger, "mapmodel")
entity_classes.reg(world_marker, "playerstart")
