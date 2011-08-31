--[[!
    File: library/core/base/base_ent_static.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features static logic entity class.
]]

--[[!
    Package: entity_static
    This module handles static entities. It contains all base static entities,
    the raw sauer ones, which you can then use as a base for custom ones.
]]
module("entity_static", package.seeall)

--[[!
    Class: base_static
    Base static entity class. Every other static entity inherits from this
    (or from something inherited from this and so on). This class itself
    inherits from <base_animated>. Unlike dynamic entities, static
    entities don't usually <base_root.act> or <base_client.client_act>.
    This functionality can be though re-enabled by setting <should_act>
    to true.

    Properties:
        radius - entity bounding box radius.
        position - entity position.
        attr1 - first sauer entity property.
        attr2 - second sauer entity property.
        attr3 - third sauer entity property.
        attr4 - fourth sauer entity property.
]]
base_static = class.new(entity_animated.base_animated, {
    --! Variable: should_act
    --! See <base_root.should_act>.
    should_act = false,

    --[[!
        Variable: use_render_dynamic_test
        This boolean value specifies whether to use render test.
        It's true by default for all static entities.
        It basically means that if this is true, it'll be tested
        if this entity is in player's sight and if it's not,
        rendering will be skipped to increase performance.

        The render test method is injected to entity by
        <entity_store.render_dynamic>.

        If this value is false, the entity will always render.
    ]]
    use_render_dynamic_test = true,

    --[[!
        Variable: sauer_type
        Type of the entity in Cube 2. For static entities,
        it's always "extent".
    ]]
    sauer_type = "extent",

    --[[!
        Variable: sauer_type_index
        This specifies index of specific entity type in Cube 2.
        Available are 0 (empty), 1 (light), 2 (mapmodel), 3 (playerstart),
        4 (envmap), 5 (particles), 6 (sound) and 7 (spotlight).

        You specify the name in parentheses when registering the entity class,
        see <entity_classes.register>.
    ]]
    sauer_type_index = 0,

    properties = {
        -- TODO: use sauer values for bounding box -- XXX - needed?
        radius       = state_variables.state_float(),

        position     = state_variables.wrapped_c_vec3({
            c_getter = "CAPI.getextent0",
            c_setter = "CAPI.setextent0"
        }),
        attr1        = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr1",
            c_setter = "CAPI.setattr1"
        }),
        attr2        = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr2",
            c_setter = "CAPI.setattr2"
        }),
        attr3        = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr3",
            c_setter = "CAPI.setattr3"
        }),
        attr4        = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr4",
            c_setter = "CAPI.setattr4"
        })
    },

    --[[!
        Function: init
        See <base_server.init>.

        Note: Makes entities persistent in any case,
        defaults position to { 511, 512, 513 } or to
        position specified by kwargs. Defaults BB radius to 0.

        Inherited entities will mostly override this
        function and initialize their state variable defaults here.
    ]]
    init = function(self, uid, kwargs)
        logging.log(logging.DEBUG, "base:init")

        kwargs = kwargs or {}
        -- static entities are persistent by default
        kwargs.persistent = true

        entity_animated.base_animated.init(self, uid, kwargs)

        if not kwargs and not kwargs.position then
            self.position = { 511, 512, 513 }
        else
            self.position = {
                tonumber(kwargs.position.x),
                tonumber(kwargs.position.y),
                tonumber(kwargs.position.z)
            }
        end
        self.radius = 0

        logging.log(logging.DEBUG, "base:init complete")
    end,

    --[[!
        Function: activate
        See <base_server.activate>.

        Note: Inserts position into kwargs (kwargs.x, kwargs.y, kwargs.z).
        Also inserts attr1, attr2, attr3, attr4 into kwargs and then sets up
        the entity in sauer using values in kwargs. Also triggers SV change
        for position property and attr* properties after flushing queued
        changes.
    ]]
    activate = function(self, kwargs)
        kwargs = kwargs or {}

        logging.log(
            logging.DEBUG,
            self.uid .. " base: __activate() " .. json.encode(kwargs)
        )

        -- call parent
        entity_animated.base_animated.activate(self, kwargs)

        -- set _type from sauer_type_index
        if not kwargs._type then
            kwargs._type = self.sauer_type_index
        end

        -- default some kwargs items
        logging.log(logging.DEBUG, "base defaults:")
        kwargs.x = self.position.x or 512
        kwargs.y = self.position.y or 512
        kwargs.z = self.position.z or 512
        kwargs.attr1 = self.attr1 or 0
        kwargs.attr2 = self.attr2 or 0
        kwargs.attr3 = self.attr3 or 0
        kwargs.attr4 = self.attr4 or 0

        logging.log(logging.DEBUG, "base: setupextent:")
        -- set up static entity in sauer subsystem
        CAPI.setupextent(
            self, kwargs._type,
            kwargs.x, kwargs.y, kwargs.z,
            kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4
        )

        logging.log(logging.DEBUG, "base: flush:")
        -- flush queue
        self:flush_queued_state_variable_changes()

        -- ensure the state data contains copies for C++ stuff
        -- (otherwise, might be empty, and we need it for
        -- initializing on the server)
        logging.log(logging.DEBUG, "ensuring base values - deprecate")
        logging.log(
            logging.DEBUG,
            "position: "
                .. tostring(self.position.x)
                .. ", "
                .. tostring(self.position.y)
                .. ", "
                .. tostring(self.position.z)
        )
        logging.log(
            logging.DEBUG, "position class: " .. tostring(self.position)
        )

        -- trigger SV change
        self.position = self.position

        logging.log(
            logging.DEBUG,
            "position(2): "
                .. tostring(self.position.x)
                .. ", "
                .. tostring(self.position.y)
                .. ", "
                .. tostring(self.position.z)
        )

        logging.log(logging.DEBUG, "ensuring base values (2)")
        self.attr1 = self.attr1
        self.attr2 = self.attr2
        self.attr3 = self.attr3
        self.attr4 = self.attr4
        logging.log(logging.DEBUG, "ensuring base values complete.")
    end,

    --! Function: deactivate
    --! See <base_server.deactivate>. Also dismantles
    --! static entity in sauer beforehand.
    deactivate = function(self)
        CAPI.dismantleextent(self)
        entity_animated.base_animated.deactivate(self)
    end,

    --[[!
        Function: client_activate
        See <base_client.client_activate>.

        Note: Inserts some temporary data into kwargs
        until it receives full state data.
    ]]
    client_activate = function(self, kwargs)
        -- make up some stuff until we get complete state data
        if not kwargs._type then
            kwargs._type = self.sauer_type_index
            kwargs.x = 512
            kwargs.y = 512
            kwargs.z = 512
            kwargs.attr1 = 0
            kwargs.attr2 = 0
            kwargs.attr3 = 0
            kwargs.attr4 = 0
        end

        -- set up static entity
        CAPI.setupextent(
            self, kwargs._type,
            kwargs.x, kwargs.y, kwargs.z,
            kwargs.attr1, kwargs.attr2, kwargs.attr3, kwargs.attr4
        )
        -- call parent
        entity_animated.base_animated.client_activate(self, kwargs)
    end,

    --! Function: client_deactivate
    --! See <base_client.client_deactivate>.
    --! Also dismantles static entity in sauer beforehand.
    client_deactivate = function(self)
        CAPI.dismantleextent(self)
        entity_animated.base_animated.client_deactivate(self)
    end,

    --[[!
        Function: send_complete_notification
        See <base_server.send_complete_notification>.

        This function overrides the original. The function remains,
        but different message gets sent, and more parameters are passed
        (like position and all the attr*).
    ]]
    send_complete_notification = function(self, cn)
        -- default the client number
        cn = cn or message.ALL_CLIENTS

        -- create a table of client numbers
        local cns = (cn == message.ALL_CLIENTS)
                    and entity_store.get_all_client_numbers()
                     or { cn }

        logging.log(logging.DEBUG, "base:send_complete_notification:")

        -- loop client numbers and send message to each
        for i = 1, #cns do
            message.send(cns[i],
                        CAPI.extent_notification_complete,
                        self.uid,
                        tostring(self),
                        -- custom data per client
                        self:create_state_data_dict(
                            cns[i], { compressed = true }
                        ),
                        tonumber(self.position.x),
                        tonumber(self.position.y),
                        tonumber(self.position.z),
                        tonumber(self.attr1),
                        tonumber(self.attr2),
                        tonumber(self.attr3),
                        tonumber(self.attr4))
        end
        logging.log(logging.DEBUG, "base:send_complete_notification done.")
    end,

    --[[!
        Function: get_center
        Gets center position of static entity, something like gravity center.
        Override if your center is nonstandard.
        By default, it's self.radius above bottom.

        Returns:
            Center position which is a vec3.
    ]]
    get_center = function(self)
        local r = self.position:copy()
        r.z = r.z + self.radius
        return r
    end
}, "base_static")

--[[!
    Class: light
    Light static entity. Inherits from <base_static>.

    Properties:
        attr1 - light radius. (0 to N, alias "radius")
        attr2 - red value (0 to 255, alias "red")
        attr3 - green value (0 to 255, alias "green")
        attr4 - blue value (0 to 255, alias "blue")
]]
light = class.new(base_static, {
    --! Variable: sauer_type_index
    --! See <base_static.sauer_type_index>.
    sauer_type_index = 1,

    properties = {
        attr1 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr1",
            c_setter = "CAPI.setattr1",
            gui_name = "radius",
            alt_name = "radius"
        }),
        attr2 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr2",
            c_setter = "CAPI.setattr2",
            gui_name = "red",
            alt_name = "red"
        }),
        attr3 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr3",
            c_setter = "CAPI.setattr3",
            gui_name = "green",
            alt_name = "green"
        }),
        attr4 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr4",
            c_setter = "CAPI.setattr4",
            gui_name = "blue",
            alt_name = "blue"
        }),

        radius = state_variables.variable_alias("attr1"),
        red = state_variables.variable_alias("attr2"),
        green = state_variables.variable_alias("attr3"),
        blue = state_variables.variable_alias("attr4")
    },

    --! Function: init
    --! See <base_static.init>.
    init = function(self, uid, kwargs)
        base_static.init(self, uid, kwargs)

        -- default values
        self.radius = 100
        self.red = 128
        self.green = 128
        self.blue = 128
    end
}, "light")

--[[!
    Class: spotlight
    Spotlight static entity. It's attached to nearest <light> entity.
    It has just one own property, and that is attr1 (alias "radius").
    Radius is in degrees, 0 to 90, where 90 is full hemisphere
    and 0 simply a line.
]]
spotlight = class.new(base_static, {
    --! Variable: sauer_type_index
    --! See <base_static.sauer_type_index>.
    sauer_type_index = 7,

    properties = {
        attr1 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr1",
            c_setter = "CAPI.setattr1",
            gui_name = "radius",
            alt_name = "radius"
        }),
        radius = state_variables.variable_alias("attr1")
    },

    --! Function: init
    --! See <base_static.init>.
    init = function(self, uid, kwargs)
        base_static.init(self, uid, kwargs)
        self.radius = 90
    end
}, "spotlight")

--[[!
    Class: envmap
    Environment map entity. Things reflecting on their surface using
    environment map can generate their envmap from near envmap entity
    instead of using skybox and reflect geometry that way (altough just
    statically, so no dynamic updates).

    It has just one own property, and that is attr1 (alias "radius").
]]
envmap = class.new(base_static, {
    --! Variable: sauer_type_index
    --! See <base_static.sauer_type_index>.
    sauer_type_index = 4,

    properties = {
        attr1 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr1",
            c_setter = "CAPI.setattr1",
            gui_name = "radius",
            alt_name = "radius"
        }),
        radius = state_variables.variable_alias("attr1")
    },

    --! Function: init
    --! See <base_static.init>.
    init = function(self, uid, kwargs)
        base_static.init(self, uid, kwargs)
        self.radius = 128
    end
}, "envmap")

--[[!
    Class: ambient_sound
    Ambient sound in the world. Repeats given sound at entity position.

    Properties:
        attr2 - alias "radius" - the sound will fade off at border.
        attr3 - alias "size" - if this is 0, the sound is point source,
        otherwise the sound volume will be always max to distance specified
        by this property and then it'll start fading off.
        attr4 - alias "volume" - sound volume. Value from 0 to 100.
        sound_name - path to the sound in data/sounds.
]]
ambient_sound = class.new(base_static, {
    --! Variable: sauer_type_index
    --! See <base_static.sauer_type_index>.
    sauer_type_index = 6,

    properties = {
        attr2 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr2",
            c_setter = "CAPI.setattr2",
            gui_name = "radius",
            alt_name = "radius"
        }),
        attr3 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr3",
            c_setter = "CAPI.setattr3",
            gui_name = "size",
            alt_name = "size"
        }),
        attr4 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr4",
            c_setter = "CAPI.setsoundvol",
            gui_name = "volume",
            alt_name = "volume"
        }),
        sound_name = state_variables.wrapped_c_string({
            c_setter = "CAPI.setsoundname"
        }),

        radius = state_variables.variable_alias("attr2"),
        size = state_variables.variable_alias("attr3"),
        volume = state_variables.variable_alias("attr4")
    },

    --! Function: init
    --! See <base_static.init>.
    init = function(self, uid, kwargs)
        base_static.init(self, uid, kwargs)
        -- attr1 is the slot index - replaced
        self.attr1 = -1
        self.radius = 100
        self.size = 0
        if not self.volume then self.volume = 100 end
        self.sound_name = ""
    end
}, "ambient_sound")

--[[!
    Class: particle_effect
    Spawns a particle emitter at position in the world.

    Properties:
        attr1 - alias "particle_type" - type of the particle.
        attr2 - alias "value1" - emitter-specific value.
        attr3 - alias "value2" - emitter-specific value.
        attr4 - alias "value3" - emitter-specific value.

    Particle types (and their values):

    0 (fire with smoke):
        radius - 0 means default - that equals to 100.
        height - 0 means default - that equals to 100.
        rgb - 0x000000 is default - that equals to 0x903020.

    1 (steam vent):
        direction - values 0 to 5.

    2 (water fountain):
        direction - values 0 to 5, color inherits from water color.

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

    79 (glow particle):
        rgb - 0x000000 to 0xFFFFFF.
        size - 0 to N.
        shimmer - if 1, the glow particle will "shimmer" (usable on i.e. fire).
]]
particle_effect = class.new(base_static, {
    --! Variable: sauer_type_index
    --! See <base_static.sauer_type_index>.
    sauer_type_index = 5,

    properties = {
        attr1 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr1",
            c_setter = "CAPI.setattr1",
            gui_name = "particle_type",
            alt_name = "particle_type"
        }),
        attr2 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr2",
            c_setter = "CAPI.setattr2",
            gui_name = "value1",
            alt_name = "value1"
        }),
        attr3 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr3",
            c_setter = "CAPI.setattr3",
            gui_name = "value2",
            alt_name = "value2"
        }),
        attr4 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr4",
            c_setter = "CAPI.setattr4",
            gui_name = "value3",
            alt_name = "value3"
        }),

        particle_type = state_variables.variable_alias("attr1"),
        value1 = state_variables.variable_alias("attr2"),
        value2 = state_variables.variable_alias("attr3"),
        value3 = state_variables.variable_alias("attr4")
    },

    --! Function: init
    --! See <base_static.init>.
    init = function(self, uid, kwargs)
        base_static.init(self, uid, kwargs)

        self.particle_type = 0
        self.value1 = 0
        self.value2 = 0
        self.value3 = 0
    end
}, "particle_effect")

--[[!
    Class: mapmodel
    A model on a specific place in the world.

    Properties:
        attr1 - model yaw, alias "yaw".
        collision_radius_width - custom bounding box
        width for models with per-entity collision boxes.
        Used with i.e. area trigger to specify trigger bounds.
        collision_radius_height - see above.
]]
mapmodel = class.new(base_static, {
    --! Variable: sauer_type_index
    --! See <base_static.sauer_type_index>.
    sauer_type_index = 2,

    properties = {
        attr1 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr1",
            c_setter = "CAPI.setattr1",
            gui_name = "yaw",
            alt_name = "yaw"
        }),
        yaw = state_variables.variable_alias("attr1"),

        collision_radius_width = state_variables.wrapped_c_float({
            c_getter = "CAPI.getcollisionradw",
            c_setter = "CAPI.setcollisionradw"
        }),
        collision_radius_height = state_variables.wrapped_c_float({
            c_getter = "CAPI.getcollisionradh",
            c_setter = "CAPI.setcollisionradh"
        })
    },

    --! Function: init
    --! See <base_static.init>.
    init = function(self, uid, kwargs)
        logging.log(logging.DEBUG, "mapmodel:init")
        base_static.init(self, uid, kwargs)

        -- sauer mapmodel index - put as -1 to use out model names as default
        self.attr2 = -1
        self.yaw = 0

        self.collision_radius_width = 0
        self.collision_radius_height = 0

        logging.log(logging.DEBUG, "mapmodel:init complete.")
    end,

    --[[!
        Function: on_collision
        This gets called serverside when something collides with the model.
        Doesn't do anything by default, but can be overriden, as exampled
        in <area_trigger>.

        Parameters:
            collider - the entity that collided with the model.
    ]]
    on_collision = function(self, collider)
    end,

    --[[!
        Function: client_on_collision
        This gets called clientside when something collides with the model.
        Doesn't do anything by default, but can be overriden, as exampled
        in <area_trigger>.

        Parameters:
            collider - the entity that collided with the model.
    ]]
    client_on_collision = function(self, collider)
    end,

    --[[!
        Function: get_center
        See <base_static.get_center>. The difference is that the z
        coordinate can be self.collision_radius_width above bottom
        instead of self.radius if self.collision_radius_height is
        available.

        If it's not available, method from base_static is used.
    ]]
    get_center = function(self)
        if self.collision_radius_height ~= 0 then
            local r = self.position:copy()
            r.z = r.z + self.collision_radius_height
            return r
        else
            return base_static.get_center(self)
        end
    end
}, "mapmodel")

--[[!
    Class: area_trigger
    A trigger that runs looped actions when something
    is in its area. Inherits from <mapmodel>.

    Properties:
        server_function - name of function that is run when something
        is in area_trigger's area. Collider entity is passed to it.
        client_function - clientside variant of server_function.
]]
area_trigger = class.new(mapmodel, {
    properties = {
        server_function = state_variables.state_string(),
        client_function = state_variables.state_string(),
    },

    --! Function: init
    --! See <base_static.init>.
    init = function(self, uid, kwargs)
        mapmodel.init(self, uid, kwargs)

        self.server_function = ""
        self.client_function = ""
        self.collision_radius_width = 10
        self.collision_radius_height = 10

        -- hardcoded, appropriate model, with collisions only
        -- for triggering and per-entity collision boxes.
        self.model_name = "areatrigger"
    end,

    --[[!
        Function: on_collision
        Overriden <mapmodel.on_collision>.
        Runs self.server_function when needed.
    ]]
    on_collision = function(self, collider)
        --- XXX potential security risk
        if     self.server_function ~= "" then
            _G[self.server_function](collider)
        end
    end,

    --[[!
        Function: client_on_collision
        Overriden <mapmodel.client_on_collision>.
        Runs self.client_function when needed.
    ]]
    client_on_collision = function(self, collider)
        --- XXX potential security risk
        if     self.client_function ~= "" then
            _G[self.client_function](collider)
        end
    end
}, "area_trigger")

--[[!
    Class: resettable_area_trigger
    Area trigger that triggers action just once, unlike <area_trigger>.
    Then its ready_to_trigger is set to false.

    When its <reset> method is called, ready_to_trigger is set back
    to true and it can be triggered again.

    Besides, this has multiple overridable callbacks for re-setting
    and triggering.
]]
resettable_area_trigger = class.new(area_trigger, {
    --! Function: activate
    --! See <base_static.activate>. Calls <reset>.
    activate = function(self, kwargs)
        area_trigger.activate(self, kwargs)
        self:reset()
    end,

    --! Function: client_activate
    --! See <base_static.client_activate>. Calls <reset>.
    client_activate = function(self, kwargs)
        area_trigger.client_activate(self, kwargs)
        self:reset()
    end,

    --[[!
        Function: on_collision
        Overriden <area_trigger.on_collision>.

        If we're ready to trigger, ready_to_trigger is set to false.
        Then, if we have server_function (see <area_trigger>), it gets
        called, otherwise <on_trigger> gets called.
    ]]
    on_collision = function(self, collider)
        if self.ready_to_trigger then
            self.ready_to_trigger = false
        else
            return nil
        end

        --- XXX potential security risk
        if     self.server_function ~= "" then
            _G[self.server_function](collider)
        else
            self:on_trigger(collider)
        end
    end,

    --[[!
        Function: client_on_collision
        Overriden <area_trigger.client_on_collision>.

        If we're ready to trigger, ready_to_trigger is set to false.
        Then, if we have client_function (see <area_trigger>), it gets
        called, otherwise <client_on_trigger> gets called.
    ]]
    client_on_collision = function(self, collider)
        --- XXX potential security risk
        if self.ready_to_trigger then
            self.ready_to_trigger = false
        else
            return nil
        end

        --- XXX potential security risk
        if     self.client_function ~= "" then
            _G[self.client_function](collider)
        else
            self:client_on_trigger(collider)
        end
    end,

    --[[!
        Function: reset
        Sets ready_to_trigger to true and calls either on_reset or
        client_on_reset callback, depending if we're on server or client.
    ]]
    reset = function(self)
        self.ready_to_trigger = true
        if SERVER then
            self:on_reset()
        else
            self:client_on_reset()
        end
    end,

    --[[!
        Function: on_reset
        Called on state reset on server. Does nothing by default,
        meant to be overriden from children.
    ]]
    on_reset = function(self)
    end,

    --[[!
        Function: client_on_reset
        Called on state reset on client. Does nothing by default,
        meant to be overriden from children.
    ]]
    client_on_reset = function(self)
    end,

    --[[!
        Function: on_trigger
        See <on_collision>.

        Called on trigger on server. Does nothing by default,
        meant to be overriden from children.

        This does not get called if we have self.server_function
        set to some value.

        Parameters:
            collider - see <mapmodel.on_collision>.
    ]]
    on_trigger = function(self, collider)
    end,

    --[[!
        Function: client_on_trigger
        See <client_on_collision>.

        Called on trigger on client. Does nothing by default,
        meant to be overriden from children.

        This does not get called if we have self.client_function
        set to some value.

        Parameters:
            collider - see <mapmodel.client_on_collision>.
    ]]
    client_on_trigger = function(self, collider)
    end
}, "resettable_area_trigger")

--[[!
    Class: world_marker
    Generic world marker that has multiple uses. It can be used
    as base entity for various position markers. It can be used
    i.e. as player start position. Example use of this is shown
    in cutscene system, where all the markers are children
    of this entity class.

    This entity is represented as "playerstart" in Cube 2.

    Properties:
        attr1 - marker yaw, alias "yaw".
]]
world_marker = class.new(base_static, {
    --! Variable: sauer_type_index
    --! See <base_static.sauer_type_index>.
    sauer_type_index = 3,

    properties = {
        attr1 = state_variables.wrapped_c_integer({
            c_getter = "CAPI.getattr1",
            c_setter = "CAPI.setattr1",
            gui_name = "yaw",
            alt_name = "yaw"
        }),
        yaw = state_variables.variable_alias("attr1")
    },

    --[[!
        Function: place_entity
        Places an entity on position of this marker instance.

        Parameters:
            entity - the entity to place.
    ]]
    place_entity = function(self, entity)
        entity.position = self.position
        entity.yaw      = self.yaw
    end
}, "world_marker")

-- register all the entities
entity_classes.register(base_static, "mapmodel")
entity_classes.register(light, "light")
entity_classes.register(spotlight, "spotlight")
entity_classes.register(envmap, "envmap")
entity_classes.register(ambient_sound, "sound")
entity_classes.register(particle_effect, "particles")
entity_classes.register(mapmodel, "mapmodel")
entity_classes.register(area_trigger, "mapmodel")
entity_classes.register(resettable_area_trigger, "mapmodel")
entity_classes.register(world_marker, "playerstart")
