--[[!
    File: library/core/base/base_ent_store.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features entity storage system.
]]

--[[!
    Package: entity_store
    This module handles entity storage for instances,
    as well as various functions for controlling their
    properties and getting/creating.
]]
module("entity_store", package.seeall)

--[[!
    Variable: __entities_store
    Local table storing all instances of entities in the world.
    It parallels C++ storage. It's accessible by various functions
    from this module. Entities are stored by unique ID here (the key
    is unique id).
]]
local __entities_store = {}

--[[!
    Variable: __entities_store_by_class
    Simillar to <__entities_store>, but it stores arrays of entities
    by class. Basically, keys in this table are class names and values
    are arrays of entities, not stored by unique ID. It is used mainly
    for caching.
]]
local __entities_store_by_class = {}

--[[!
    Variable: __entities_sauer
    Stores Sauerbraten entity definitions for the map. Automatically
    cleared after the entities are loaded. It's made for the automatic
    Sauerbraten map import.
]]
local __entities_sauer = {}

--[[!
    Function: add_sauer
    Adds a Sauerbraten entity into <__entities_sauer>. Called from
    inside the engine.

    Parameters:
        entity_type - a number specifying the entity type according
        to Cube 2 source code.
        position - a <vec3> specifying the entity position.
        attr1..4 - entity attributes.
]]
function add_sauer(entity_type, position, attr1, attr2, attr3, attr4, attr5)
    if not SERVER then return nil end
    table.insert(__entities_sauer, {
        entity_type, position, attr1, attr2, attr3, attr4, attr5
    })
end

--[[!
    Function: get
    Returns an entity that has specified unique ID. If not found, nil
    is returned.

    Parameters:
        uid - the unique ID of the entity.
]]
function get(uid)
    log(DEBUG, "get: entity " .. uid)

    local r = __entities_store[uid]
    if    r then
        log(
            DEBUG,
            "get: entity " .. uid .. " found (" .. r.uid .. ")"
        )
        return r
    else
        log(
            DEBUG, "get: could not find entity " .. uid
        )
        return nil
    end
end

--[[!
    Function: get_all
    Returns <__entities_store>.
]]
function get_all()
    return __entities_store
end

--[[!
    Function: get_all_by_tag
    Gets an array of entities with common tag or empty array
    if no such entities are found.

    Parameters:
        tag - the tag the entities should have.
]]
function get_all_by_tag(tag)
    local r = {}

    for k, v in pairs(__entities_store) do
        if v:has_tag(tag) then
            table.insert(r, v)
        end
    end

    return r
end

--[[!
    Function: get_by_tag
    Gets a single entity of given tag. If more or none
    are found, nil is returned.

    Parameters:
        tag - the tag the entities should have.
]]
function get_by_tag(tag)
    local r = get_all_by_tag(tag)
    if   #r == 1 then
        return r[1]
    elseif  #r > 1 then
        log(
            WARNING,
            "Attempt to get a single entity with tag '"
                .. tostring(wtag)
                .. "', but several exist."
        )
        return nil
    else
        log(
            WARNING,
            "Attempt to get a single entity with tag '"
                .. tostring(wtag)
                .. "', but none exist."
        )
        return nil
    end
end

--[[!
    Function: get_all_by_tag
    Gets an array of entities with common class or empty array
    if no such entities are found. Note that this will return
    also entities of all classes that inherit from the class
    specified by argument.

    Parameters:
        class - the class the entities should have.
        Either the real class or just class name.
]]
function get_all_by_class(class)
    if type(class) == "table" then
        class = tostring(class)
    end

    -- caching
    if __entities_store_by_class[class] then
        return __entities_store_by_class[class]
    else
        return {}
    end
end

--[[!
    Function: get_all_clients
    Gets an array of clients (== all entities of currently set player class).
    Empty if no clients are found (that means we're not in game probably).
]]
function get_all_clients()
    local ret = get_all_by_class(EVAR.player_class)

    log(
        INFO,
        "entity store: get_all_clients: got %(1)s clients" % { #ret }
    )

    return ret
end

--[[!
    Function: get_all_client_numbers
    Gets an array of all client numbers. It basically returns
    a re-mapped output of <get_all_clients> (see <table.map>).
]]
function get_all_client_numbers()
    return table.map(get_all_clients(), function(c) return c.cn end)
end

--[[!
    Function: is_player_editing
    Returns true if given player is editing, false otherwise.

    Parameters:
        player - specific player. If it's nil,
        current player is assumed (see <get_player_entity>).
        That works only clientside though, serverside player
        must be given.
]]
function is_player_editing(player)
    if CLIENT then
        player = player or get_player_entity()
    end
    -- character.CLIENT_STATE.EDITING
    return player and player.client_state == 4
end

--[[!
    Function: get_all_close
    Returns all entities close to position (with some more possible options).

    Parameters:
        origin - the position entities should be close to.
        kwargs - table of parameters for the function.

    Kwargs:
        max_distance - maximal distance entity can have from origin, required.
        class - entity class the entity should be of, optional.
        tag - tag that the entity should have, optional.
        unsorted - boolean specifying whether to not sort the resulting table,
        optional, sorted by default.
        fun - a function returning vec3 to subtract origin with, optional,
        defaults to function that returns entity's position
        (basic distance calculation).

    Returns:
        Array of tables. Each table in array contains an entity and distance
        of it from origin position. Usually the array is sorted by distances,
        but can be overriden in kwargs.
]]
function get_all_close(origin, kwargs)
    kwargs = kwargs or {}

    -- save to locals + some defaulting
    local max_distance = kwargs.max_distance
    local class        = kwargs.class
    local tag          = kwargs.tag
    local unsorted     = kwargs.unsorted
    local fun          = kwargs.fun or function(entity)
        return entity.position:copy()
    end

    -- we'll return this
    local ret = {}

    for uid, entity in pairs(__entities_store) do
        local skip = false

        -- choose whether to skip this iteration
        if (class and not entity:is_a(class))
        or (tag   and not entity:has_tag(tag)) then
            skip = true
        end

        -- check distances
        if not skip and (
            origin:sub_new(fun(entity)):length() <= max_distance
        ) then
            table.insert(ret, { entity, distance })
        end
    end

    -- sort if required
    if not unsorted then
        table.sort(ret, function(a, b) return a[2] < b[2] end)
    end

    -- and return
    return ret
end

--[[!
    Function: add
    Adds a logic entity into the store.
    The entity will get stored and activated. We should already know
    unique ID at this point.

    Parameters:
        class_name - name of entity class this entity instance
        will be spawned from.
        uid - unique ID of the new entity.
        kwargs - additional parameters, here just passed to activators
        and to init function on server.
        _new - if this is true, init function will be called on the
        spawned instance, because it marks it's newly created entity.
        There are cases when we don't want this though, like when loading
        saved entities from file. This applies for server only.

    Returns:
        Stored and activated entity instance.

    See Also:
        <base_server.init>
        <base_server.activate>
        <base_client.client_activate>
]]
function add(class_name, uid, kwargs, _new)
    -- debugging, we're leet
    uid = uid or 1337

    log(
        DEBUG,
        "Adding new scripting entity of type "
            .. class_name
            .. " with uid "
            .. uid
    )
    log(
        DEBUG,
        "   with arguments: "
            .. table.serialize(kwargs)
            .. ", "
            .. tostring(_new)
    )

    -- cannot recreate an entity
    assert(not get(uid))

    -- get the class
    local _class = entity_classes.get_class(class_name)

    -- spawn instance (it'll get returned)
    local r = _class()

    -- on client, just set uid. On server, we can also assume _new.
    if CLIENT then
        r.uid = uid
    else
        if _new then
            r:init(uid, kwargs)
        else
            r.uid = uid
        end
    end

    -- store it.
    __entities_store[r.uid] = r

    -- caching - needs another table, but it's faster
    for k, v in pairs(entity_classes.class_storage) do
        if r:is_a(v[1]) then
            if not __entities_store_by_class[k] then
               __entities_store_by_class[k] = {}
            end
            table.insert(__entities_store_by_class[k], r)
        end
    end

    -- done after setting the uid and placing in the global store,
    -- because c++ registration relies on both

    log(DEBUG, "Activating ..")

    if CLIENT then
        r:client_activate(kwargs)
    else
        r:activate(kwargs)
    end

    -- return it
    return r
end

--[[!
    Function: del
    Deletes an entity of given unique ID. First, it emits pre_deactivate
    signal for the entity, then it calls some deactivators
    (see <base_server.deactivate>, <base_client.client_deactivate>).
    Then it gets cleared from by_class cache and removed from storage.

    Parameters:
        uid - known unique ID of the entity.
]]
function del(uid)
    log(DEBUG, "Removing scripting entity: " .. uid)

    -- check for existence
    if not __entities_store[uid] then
        log(
            WARNING,
            "Cannot remove entity " .. uid .. " as it does not exist."
        )
        return nil
    end

    -- emit the signal
    signal.emit(__entities_store[uid], "pre_deactivate")

    -- call deactivators
    if CLIENT then
        __entities_store[uid]:client_deactivate()
    else
        __entities_store[uid]:deactivate()
    end

    -- caching - clear it up
    local ent = __entities_store[uid]
    for k, v in pairs(entity_classes.class_storage) do
        if ent:is_a(v[1]) then
            __entities_store_by_class[k] = table.filter_map(
                __entities_store_by_class[k],
                function(a, b) return (b ~= ent) end
            )
        end
    end

    -- and clear it up completely
    __entities_store[uid] = nil
end

--[[!
    Function: del_all
    Deletes all entities in the storage.
]]
function del_all()
    for k, v in pairs(__entities_store) do
        del(k)
    end
end

--[[!
    Global rendering method. Performed every frame, so performance
    is very important. It loops the entity storage, checks if an
    entity can render, does rendering tests if needed (to improve
    performance) and finally lets entity render if needed.

    Parameters:
        thirdperson - if this is true, we're in thirdperson mode.
        In that case, player model won't be rendered, because
        <render_hud_model> does that.
]]
function render_dynamic(thirdperson)
    log(INFO, "render_dynamic")

    -- get the player entity, return if it doesn't exist
    local  player = get_player_entity()
    if not player then
        return nil
    end

    -- loop the storage
    for uid, entity in pairs(__entities_store) do
        -- decide some skipping
        local skip = false

        -- skip unrenderable
        if entity.deactivated or not entity.render_dynamic then
            skip = true
        end

        if not skip then
            -- if we want rendering testing ..
            if entity.use_render_dynamic_test then
                -- and we don't have the tester, set it up
                if not entity.render_dynamic_test then
                    setup_dynamic_rendering_test(entity)
                end
                -- skip if we don't pass the test
                if not entity:render_dynamic_test() then
                    skip = true
                end
            end
        end

        -- finally, if we aren't skipping, render it
        if not skip then
            -- first argument is hudpass, false because we aren't rendering
            -- the HUD model, second is needhud, which is true if the model
            -- should be shown as HUD model and that happens if we're not in
            -- thirdperson and current entity is player.
            entity:render_dynamic(false, not thirdperson and entity == player)
        end
    end
end

--[[!
    Function: manage_triggering_collisions
    This function manages area trigger collisions. It's cached by time delay
    (see <actions.cache_by_delay>) with delay set to 0.1 seconds,
    so the performance is sufficient.
]]
manage_triggering_collisions = frame.cache_by_delay(function()
    -- get all area triggers and entities inherited from area triggers
    local ents = get_all_by_class("area_trigger")

    -- loop all clients
    for i, player in pairs(get_all_clients()) do
        -- skipping?
        local skip = false

        -- skip players that are editing - they're not colliding
        if is_player_editing(player) then
            skip = true
        end

        -- if not skipping ..
        if not skip then
            -- loop the triggers
            for n, entity in pairs(ents) do
                -- if player is colliding the trigger ..
                if geometry.is_player_colliding_entity(
                    player, entity
                ) then
                    -- call needed methods
                    if CLIENT then
                        entity:client_on_collision(player)
                    else
                        entity:on_collision(player)
                    end
                end
            end
        end
    end
end, 0.1)

--[[!
    Function: render_hud_model
    This is a function that renders HUD model for active player on client.
    It renders only in firstperson and only if the player is not editing.
]]
function render_hud_model()
    local player = get_player_entity()

    -- 4 = character.CLIENT_STATE.EDITING
    if player.hud_model_name and player.client_state ~= 4 then
        -- first argument is hudpass, true because we are rendering
        -- the HUD model, second is needhud, which is true because the
        -- model gets indeed shown as HUD model.
        player:render_dynamic(true, true)
    end
end

--[[!
    Function: load_entities
    Loads entities into server storage from a file named 'entities.lua'
    which is stored in map directory. The file contents are read into
    a serialized string which then gets deserialized, entities get
    looped and state data are set.

    If <__entities_sauer> is non-empty, it also loads entities whose
    definitions are stored there. That is useful for importing
    Sauerbraten maps.

    Performs some backwards compatibility adjustments for old sauer
    map formats. Entities created this way are then passed to all clients.

    State data get passed via kwargs to <entity_store.add>.

    The function won't do anything when run clientside.
]]
function load_entities()
    -- clientside behavior is undefined, so don't run.
    if not SERVER then
        return nil
    end

    log(DEBUG, "Reading entities.lua..")

    -- read the entities
    local entities_lua = CAPI.readfile("./entities.lua")

    log(
        DEBUG,
        "Loading entities .. "
            .. tostring(entities_lua)
            .. ", "
            .. type(entities_lua)
    )

    -- decode it
    local entities = {}
    if entities_lua then
        entities = table.deserialize(entities_lua)
    end

    -- only if there are sauer entities loaded
    if #__entities_sauer > 0 then
        log(DEBUG, "Loading sauer entities ..")

        log(DEBUG, "    Trying to load import Lua file ..")

        local import_lua = CAPI.readfile("./import.lua")
        local import_models = {}
        local import_sounds = {}

        if import_lua then
            local import_table = table.deserialize(import_lua)
            if import_table["models"] then
                import_models = import_table["models"]
            end
            if import_table["sounds"] then
                import_sounds = import_table["sounds"]
            end
        end
            

        -- get highest uuid from current table
        local huid = 2
        for i, entity in pairs(entities) do
            huid = math.max(huid, entity[1])
        end
        huid = huid + 1

        -- name conversions
        local sn = {}
        sn[1] = "light"
        sn[2] = "mapmodel"
        sn[3] = "world_marker"
        sn[4] = "envmap"
        sn[5] = "particle_effect"
        sn[6] = "ambient_sound"
        sn[7] = "spotlight"
        sn[19] = "teleporter"
        sn[20] = "world_marker"
        sn[23] = "jump_pad"

        -- load sauer entities
        for i, entity in pairs(__entities_sauer) do
            local et    = entity[1]
            local o     = entity[2]
            local attr1 = entity[3]
            local attr2 = entity[4]
            local attr3 = entity[5]
            local attr4 = entity[6]
            local attr5 = entity[7]

            if sn[et] then table.insert(entities, {
                huid, sn[et], {
                    attr1 = tostring(attr1), attr2 = tostring(attr2),
                    attr3 = tostring(attr3), attr4 = tostring(attr4),
                    attr5 = tostring(attr5),
                    radius = "0", position = "[%(1)i|%(2)i|%(3)i]" % {
                        o.x, o.y, o.z
                    }, animation = "130", model_name = "", attachments = "[]",
                    tags = "[]", persistent = "true"
                }
            }) end

            local ent = entities[#entities][3]

            -- 2 is MAPMODEL, 6 is SOUND, 3 is PLAYERSTART, 23 is JUMPPAD,
            -- 19 is TELEPORT, 20 is TELEDEST
            if et == 2 then
                if #import_models > attr2 then
                    ent["model_name"] = import_models[attr2 + 1]
                    ent["attr2"]      = "-1"
                else
                    ent["model_name"] = "@REPLACE@"
                end
            elseif et == 6 then
                if #import_sounds > attr1 then
                    local snd = import_sounds[attr1 + 1]
                    ent["sound_name"] = snd[1]
                    if #snd > 1 then
                        ent["volume"] = snd[2]
                    end
                    ent["attr1"] = "-1"
                else
                    ent["sound_name"] = "@REPLACE@"
                end
            elseif et == 3 then
                ent["tags"] = "[start_]"
            elseif et == 23 then
                ent["attr1"]                   = "0"
                ent["attr2"]                   = "-1"
                ent["attr3"]                   = "0"
                ent["attr4"]                   = "0"
                ent["pad_model"]               = ""
                ent["pad_rotate"]              = "false"
                ent["pad_pitch"]               = "0"
                ent["pad_sound"]               = ""
                ent["collision_radius_width"]  = "5"
                ent["collision_radius_height"] = "1"
                ent["model_name"]              = "areatrigger"
                ent["jump_velocity"]           = "[%(1)f|%(2)f|%(3)f]" % {
                    attr3 * 10, attr2 * 10, attr1 * 12.5
                }
            elseif et == 19 then
                ent["attr1"]                   = "0"
                ent["attr3"]                   = "0"
                ent["attr4"]                   = "0"
                ent["collision_radius_width"]  = "5"
                ent["collision_radius_height"] = "5"
                ent["destination"]             = tostring(attr1)
                ent["sound_name"]              = ""
                if attr2 < 0 then
                    ent["model_name"] = "areatrigger"
                else
                    if #import_models > attr2 then
                        ent["model_name"] = import_models[attr2 + 1]
                        ent["attr2"]      = "-1"
                    else
                        ent["model_name"] = "@REPLACE@"
                    end
                end
            elseif et == 20 then
                ent["attr2"] = "0"
                ent["tags"]  = "[teledest_%(1)i]" % { attr2 }
            end

            huid = huid + 1
        end

        -- clear up sauer entities
        __entities_sauer = {}
    end

    -- loop the table
    for i, entity in pairs(entities) do
        log(
            DEBUG, "load_entities: " .. table.serialize(entity)
        )

        -- entity unique ID
        local uid        = entity[1]
        -- entity class name
        local class_name = entity[2]
        -- entity state data
        local state_data = entity[3]

        log(
            DEBUG,
            "load_entities: "
                .. uid
                .. ", "
                .. class_name
                .. ", "
                .. table.serialize(state_data)
            )

        -- backwards comptaibility, rotate by 180 degrees
        -- for yawed entities
        if EVAR.mapversion <= 30 and state_data.attr1 then
            -- skip certain entities which have different attr1 than yaw
            if  class_name ~= "light"
            and class_name ~= "flickering_light"
            and class_name ~= "particle_effect"
            and class_name ~= "envmap" then
                -- set the yaw - rotate by 180°
                state_data.attr1 = (tonumber(state_data.attr1) + 180) % 360
            end
        end

        if EVAR.mapversion <= 31 and state_data.attr1 then
            if  class_name ~= "light"
            and class_name ~= "flickering_light"
            and class_name ~= "particle_effect"
            and class_name ~= "envmap"
            and class_name ~= "world_marker" then
                local yaw = (
                    math.floor(state_data.attr1) % 360 + 360
                ) % 360 + 7
                state_data.attr1 = yaw - (yaw % 15)
            end
        end

        -- add the entity, pass state data via kwargs
        add(class_name, uid, { state_data = table.serialize(state_data) })
    end

    log(DEBUG, "Loading entities complete")
end

--[[!
    Function: save_entities
    Creates a serialized string of all entities in the storage and returns it.
    Useful when saving entities to a file, you can then load them again.
]]
function save_entities()
    -- stores encoded entity serialized strings
    local r = {}
    log(DEBUG, "Saving entities ..:")

    -- loop the storage
    for uid, entity in pairs(__entities_store) do
        -- save only persistent entities
        if entity.persistent then
            log(DEBUG, "Saving entity " .. entity.uid)
            table.insert(r, table.serialize(
                { uid, tostring(entity), entity:create_state_data_dict() }))
        end
    end

    log(DEBUG, "Saving entities complete.")

    -- return as string
    return "{\n" .. table.concat(r, ",\n") .. "\n}\n"
end

--[[!
    Function: get_target_entity_uid
    Returns unique ID of currently targeted entity, or nil when
    nothing is targeted.
]]
get_target_entity_uid = CAPI.get_target_entity_uid

--[[!
    Function: get_selected_entity
    Returns currently selected entity, or nil of nothing
    is selected.
]]
get_selected_entity = CAPI.editing_getselent

--[[!
    Function: setup_dynamic_rendering_test
    Sets up dynamic rendering test function for an entity. Basically, creates
    render_dynamic_test member method in entity which is then using for testing
    if player can see the entity. This is meant to improve performance, as we
    don't have to render something that won't be visible anyway.

    This behavior can be disabled, see <base_static.use_render_dynamic_test>.

    Parameters:
        entity - the entity to set up testing method for.
]]
function setup_dynamic_rendering_test(entity)
    -- cache with delay of 1/3 second
    entity.render_dynamic_test = frame.cache_by_delay(function()
            -- player center
            local player_center = get_player_entity().center

            -- check the distance - skip rendering only if it's distant
            if entity.position:sub_new(player_center):length() > 256 then
                -- check for line of sight
                if not math.is_los(
                    player_center, entity.position
                ) then
                    -- do not render
                    return false
                end
            end

            -- render
            return true
    end, 1 / 3)
end

if CLIENT then
    --[[!
        Section: Client specific
        Some functions available for client only.
    ]]

    --[[!
        Function: set_player_uid
        Creates player_entity variable, which basically points at entity
        of given unique ID. It also sets controlled_here member of player
        entity to true, so all player's state variables with custom_synch
        set to true which are set on client will be updated locally without
        sending message even when actor_uid is -1, see
        <base_client.set_state_data>. 
    ]]
    function set_player_uid(uid)
        log(DEBUG, "Setting player uid to " .. tostring(uid))

        if uid then
            player_entity = get(uid)
            player_entity.controlled_here = true

            log(
                DEBUG,
                "Player controlled_here:"
                    .. tostring(player_entity.controlled_here)
            )

            -- assert it - must be valid
            assert(player_entity)
        end
    end

    --[[!
        Function: get_player_entity
        Returns player_entity, see <set_player_uid>.
    ]]
    function get_player_entity()
        return player_entity
    end

    --[[!
        Function: set_state_data
        Sets state data of entity with given unique ID. Basically
        just calls set_state_data on entity it gets using the unique ID.
        Performs changes only locally, so makes sense as response to
        server message.

        Parameters:
            uid - unique ID of the entity we're setting state data on.
            key_protocol_id - protocol ID of state variable we're setting.
            It gets converted to real name inside this function.
            value - the value we're setting.
    ]]
    function set_state_data(uid, key_protocol_id, value)
        local entity = get(uid)
        if entity then
            local key = message.to_protocol_name(
                tostring(entity), key_protocol_id
            )
            log(
                DEBUG,
                "set_state_data: "
                    .. uid
                    .. ", "
                    .. key_protocol_id
                    .. ", "
                    .. key
            )
            entity:set_state_data(key, value)
        end
    end

    --[[!
        Function: has_scenario_started
        Returns true if the scenario has started, false otherwise.
        If some entity is still uninitialized or player does not exist yet,
        returns false.
    ]]
    function has_scenario_started()
        log(INFO, "Testing whether the scenario started ..")

        -- not ready if we don't have player entity
        if not get_player_entity() then
            log(INFO, ".. no, player entity not created yet.")
            return false
        end

        log(INFO, ".. player entity created.")

        -- not ready if anything is uninitialized
        for uid, entity in pairs(__entities_store) do
            if not entity.initialized then
                log(
                    INFO,
                    ".. no, entity " .. entity.uid .. " is not initialized."
                )
                return false
            end
        end

        -- we're ready
        log(INFO, ".. yes, scenario is running.")
        return true
    end
else
    --[[!
        Section: Server specific
        Some functions available for erver only.
    ]]

    --[[!
        Function: generate_uid
        Generates a new unique ID for entity. Basically takes highest
        unique ID in the storage and returns a higher one.
        Unique ID is a simple number used for entity lookups and storage.
        It's also used when saving. Player (unless you added new entities
        while editing) has always the highest unique ID.
    ]]
    function generate_uid()
        -- what we'll return
        local r = 0

        -- get highest unique ID.
        for uid, entity in pairs(__entities_store) do
            r = math.max(r, uid)
        end

        -- r is at highest unique ID available. Increment it.
        r = r + 1

        log(DEBUG, "Generating new uid: " .. r)

        -- we're done, return
        return r
    end

    --[[!
        Function: new
        Creates a new serverside entity. The entity is then sent to
        every client available. The function generates an unique ID
        unless the unique ID is forced to value via arguments,
        then calls <entity_store.add> with proper arguments (the entity is new).

        It can either return the entity (default) or its unique ID
        (if overriden from arguments).

        Parameters:
            class - the entity class to create instance of.
            kwargs - additional parameter table, passed to <entity_store.add>.
            force_uid - forced unique ID, optional.
            If not forced, it gets generated.
            return_uid - boolean value, optional.
            If true, entity's unique ID is returned
            instead of actual entity instance.
    ]]
    function new(class, kwargs, force_uid, return_uid)
        -- force or generate
        force_uid = force_uid or generate_uid()

        log(DEBUG, "New entity: " .. force_uid)

        -- create instance
        local r = add(class, force_uid, kwargs, true)

        -- return the values
        return return_uid and r.uid or r
    end

    --[[!
        Function: new_npc
        Creates a new NPC (client). The changes get reflected to every client.
        The NPC is set as controlled_here, which on server means state
        variables with custom synching will not notify clients with message
        when updated serverside.

        Parameters:
            class - entity class the NPC should be of, usually <character>,
            but can be any other class inherited from <character>.

        Returns:
            The new generated character entity.
    ]]
    function new_npc(class)
        -- generate
        local npc = CAPI.npcadd(class)

        -- controlled here
        npc.controlled_here = true

        -- return it
        return npc
    end

    --[[!
        Function: send_entities
        Notifies a client of given number about all entities on the server.
        First, sends a message notifying about number of server entities
        and then sends complete notification (all state data) to the client.

        That includes all entities, static, dynamic and non-sauers.

        Parameters:
            cn - client number of the receiver.
    ]]
    function send_entities(cn)
        log(
            DEBUG, "Sending active entities to " .. cn
        )

        -- get table of unique IDs
        local uids = table.keys(__entities_store)
        -- sort it
        table.sort(uids)

        -- get number of entities
        local num = #uids

        -- notify client about number
        message.send(cn, CAPI.notify_numents, num)

        -- send complete notification for each entity
        for i, uid in pairs(uids) do
            __entities_store[uid]:send_complete_notification(cn)
        end
    end

    --[[!
        Function: set_state_data
        Sets state data of entity with given unique ID. Asks all clients
        to update their own data.

        Parameters:
            uid - unique ID of the entity we're setting state data on.
            key_protocol_id - protocol ID of state variable we're setting.
            It gets converted to real name inside this function.
            value - the value we're setting.
            actor_uid - unique ID of the actor (client that triggered
            the change) or -1 when it comes from the server.
    ]]
    function set_state_data(uid, key_protocol_id, value, actor_uid)
        local entity = get(uid)
        if entity then
            local key = message.to_protocol_name(
                tostring(entity), key_protocol_id
            )
            entity:set_state_data(key, value, actor_uid)
        end
    end
end
