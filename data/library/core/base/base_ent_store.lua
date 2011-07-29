--[[!
    File: base/base_ent_store.lua

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
    This module handles entity storage for instances, as well as various functions
    for controlling their properties and getting/creating.
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
    Function: get
    Returns an entity that has specified unique ID. If not found, nil
    is returned.

    Parameters:
        uid - the unique ID of the entity.
]]
function get(uid)
    logging.log(logging.DEBUG, "get: entity " .. tostring(uid))

    local r = __entities_store[tonumber(uid)]
    if    r then
        logging.log(logging.DEBUG, "get: entity " .. tostring(uid) .. " found (" .. r.uid .. ")")
        return r
    else
        logging.log(logging.DEBUG, "get: could not find entity " .. tostring(uid))
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
        logging.log(logging.WARNING, "Attempt to get a single entity with tag '" .. tostring(wtag) .. "', but several exist.")
        return nil
    else
        logging.log(logging.WARNING, "Attempt to get a single entity with tag '" .. tostring(wtag) .. "', but none exist.")
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
    local ret = get_all_by_class(player_class)

    logging.log(
        logging.INFO,
        "entity store: get_all_clients: got %(1)s clients" % { #ret }
    )

    return ret
end

--[[!
    Function: get_all_client_numbers
    Gets an array of all client numbers. It basically returns a re-mapped output of
    <get_all_clients> (see <table.map>).
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
    return player and player.client_state == 4 -- character.CLIENT_STATE.EDITING
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
        if not skip and (origin:sub_new(fun(entity)):magnitude() <= max_distance) then
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
        class_name - name of entity class this entity instance will be spawned from.
        uid - unique ID of the new entity.
        kwargs - additional parameters, here just passed to activators and to init function on server.
        _new - if this is true, init function will be called on the spawned instance, because it marks
        it's newly created entity. There are cases when we don't want this though, like when loading
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

    logging.log(logging.DEBUG, "Adding new scripting entity of type " .. class_name .. " with uid " .. uid)
    logging.log(logging.DEBUG, "   with arguments: " .. json.encode(kwargs) .. ", " .. tostring(_new))

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

    logging.log(logging.DEBUG, "Activating ..")

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
    Deletes an entity of given unique ID. First, it emits pre_deactivate signal
    for the entity, then it calls some deactivators (see <base_server.deactivate>,
    <base_client.client_deactivate>). Then it gets cleared from by_class cache
    and removed from storage.

    Parameters:
        uid - known unique ID of the entity.
]]
function del(uid)
    logging.log(logging.DEBUG, "Removing scripting entity: " .. tostring(uid))

    -- check for existence
    if not __entities_store[uid] then
        logging.log(logging.WARNING, "Cannot remove entity " .. tostring(uid) .. " as it does not exist.")
        return nil
    end

    -- emit the signal
    __entities_store[uid]:emit("pre_deactivate")

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
            __entities_store_by_class[k] = table.filter_array(
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
    Variable: current_timestamp
    Local variable storing current "timestamp". It gets
    added to every frame. Used for caching of various kinds.
    Publicly accessible via <GLOBAL_CURRENT_TIMESTAMP>.
]]
local current_timestamp = 0

--[[!
    Variable: GLOBAL_CURRENT_TIMESTAMP
    Global interface for <current_timestamp>.
]]
_G["GLOBAL_CURRENT_TIMESTAMP"] = current_timestamp

--[[!
    Function: start_frame
    Called per-frame in updateworld function in engine.
    Adds to <current_timestamp>.
]]
function start_frame()
    current_timestamp = current_timestamp + 1
    _G["GLOBAL_CURRENT_TIMESTAMP"] = current_timestamp
end

--[[!
    Variable: GLOBAL_TIME
    Global engine time. It gets added to every frame
    in <manage_actions>. It basically stores a number
    of seconds since the engine start.
]]
_G["GLOBAL_TIME"] = 0

--[[!
    Variable: GLOBAL_CURRENT_TIMEDELTA
    This stores how long time did <manage_actions> simulate
    during the frame. Floating point number, value in seconds.
]]
_G["GLOBAL_CURRENT_TIMEDELTA"] = 1.0

--[[!
    Variable: GLOBAL_LASTMILLIS
    Number of miliseconds since last counter reset. It's also
    stored as internal engine variable. If you want to know
    total number of miliseconds, multiply <GLOBAL_TIME>
    by 1000.
]]
_G["GLOBAL_LASTMILLIS"] = 0

--[[!
    Variable: GLOBAL_QUEUED_ACTIONS
    Table of actions queued globally, executed by <manage_actions>.
    It's simply an array of functions taking no arguments which
    you can safely insert to and queue your global actions.
]]
_G["GLOBAL_QUEUED_ACTIONS"] = {}

--[[!
    Function: manage_actions
    This is sort of Lua's "mainloop". It is executed per-frame from
    C++, so performance is very important here. It first executes
    actions that were queued into <GLOBAL_QUEUED_ACTIONS>, but works
    on copy, as actions can actually add more actions into the queue.

    Then, it applies changes to certain global variables (see
    <GLOBAL_TIME>, <GLOBAL_CURRENT_TIMEDELTA>, <GLOBAL_LASTMILLIS>).

    Finally, it loops whole entity storage and runs either act or
    client_act (see <base_root.act> and <base_client.client_act>)
    on each entity that has should_act set to true (or at least acts
    for either client or server, see <base_root.should_act>).

    Parameters:
        seconds - number in seconds specifying how long to simulate, this
        also affects <GLOBAL_TIME> and <GLOBAL_CURRENT_TIMEDELTA>.
        lastmillis - internal lastmillis variable passed from the engine
        (see <GLOBAL_LASTMILLIS>).
]]
function manage_actions(seconds, lastmillis)
    logging.log(logging.INFO, "manage_actions: queued ..")

    -- work on copy as actions might add more actions.
    local curr_actions = table.copy(GLOBAL_QUEUED_ACTIONS)
    -- clear up the queue
    _G["GLOBAL_QUEUED_ACTIONS"] = {}

    -- execute the actions
    for k, v in pairs(curr_actions) do
        v()
    end

    -- set the globals
    _G["GLOBAL_TIME"] = GLOBAL_TIME + seconds
    _G["GLOBAL_CURRENT_TIMEDELTA"] = seconds
    _G["GLOBAL_LASTMILLIS"] = lastmillis

    logging.log(logging.INFO, "manage_actions: " .. seconds)

    -- act!
    for uid, entity in pairs(__entities_store) do
        local skip = false

        -- do not act on deactivated or on those which
        -- shouldn't really act
        if entity.deactivated or not entity.should_act then
            skip = true
        end

        -- check if we have clientside or serverside
        -- acting, in that case do skipping if needed
        if type(entity.should_act) == "table" and (
            (CLIENT and not entity.should_act.client) or
            (SERVER and not entity.should_act.server)
        ) then
            skip = true
        end

        -- if we can act, then act, on either client or server.
        if not skip then
            if CLIENT then
                entity:client_act(seconds)
            else
                entity:act(seconds)
            end
        end
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
    logging.log(logging.INFO, "render_dynamic")

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
    (see <utility.cache_by_time_delay>) with delay set to 0.1 seconds, so the performance
    is sufficient.
]]
manage_triggering_collisions = utility.cache_by_time_delay(convert.tocalltable(function()
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
                if utility.is_player_colliding_entity(player, entity) then
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
end), 1 / 10)

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
    Function: save_entities
    Creates a JSON string of all entities in the storage and returns it.
    Useful when saving entities to a file, you can then load them again.
]]
function save_entities()
    -- stores encoded entity JSON strings
    local r = {}
    logging.log(logging.DEBUG, "Saving entities ..:")

    -- loop the storage
    for uid, entity in pairs(__entities_store) do
        -- save only persistent entities
        if entity.persistent then
            logging.log(logging.DEBUG, "Saving entity " .. tostring(vals[i].uid))

            local class_name = tostring(entity)

            -- TODO: store as serialized here, to save some parse/unparsing
            -- create state data dictionary
            local state_data = entity:create_state_data_dict()

            -- insert encoded entity as JSON string
            table.insert(r, json.encode({ uid, cls, state_data }))
        end
    end

    logging.log(logging.DEBUG, "Saving entities complete.")

    -- return as string
    return "[\n" .. table.concat(r, ",\n") .. "\n]\n"
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
    entity.render_dynamic_test = utility.cache_by_time_delay(
        -- callable table
        convert.tocalltable(function()
            -- player center
            local player_center = get_player_entity().center

            -- check the distance - skip rendering only if it's distant
            if entity.position:sub_new(player_center):magnitude() > 256 then
                -- check for line of sight
                if not utility.haslineofsight(player_center, entity.position) then
                    -- do not render
                    return false
                end
            end

            -- render
            return true
        end),
        1 / 3
    )
end

if CLIENT then
    --[[!
        Section: Client specific
        Some functions available for client only.
    ]]

    --[[!
        Function: set_player_uid
        Creates player_entity variable, which basically points at entity of given unique ID.
        It also sets controlled_here member of player entity to true, so all player's state
        variables with custom_synch set to true which are set on client will be updated locally
        without sending message even when actor_uid is -1, see <base_client.set_state_data>. 
    ]]
    function set_player_uid(uid)
        logging.log(logging.DEBUG, "Setting player uid to " .. tostring(uid))

        if uid then
            player_entity = get(uid)
            player_entity.controlled_here = true

            logging.log(logging.DEBUG, "Player controlled_here:" .. tostring(player_entity.controlled_here))

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
            local key = message.to_protocol_name(tostring(entity), key_protocol_id)
            logging.log(logging.DEBUG, "set_state_data: " .. uid .. ", " .. key_protocol_id .. ", " .. key)
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
        logging.log(logging.INFO, "Testing whether the scenario started ..")

        -- not ready if we don't have player entity
        if not get_player_entity() then
            logging.log(logging.INFO, ".. no, player entity not created yet.")
            return false
        end

        logging.log(logging.INFO, ".. player entity created.")

        -- not ready if anything is uninitialized
        for uid, entity in pairs(__entities_store) do
            if not entity.initialized then
                logging.log(logging.INFO, ".. no, entity " .. entity.uid .. " is not initialized.")
                return false
            end
        end

        -- we're ready
        logging.log(logging.INFO, ".. yes, scenario is running.")
        return true
    end
else
    --[[!
        Section: Server specific
        Some functions available for erver only.
    ]]

    --[[!
        Function: generate_uid
        Generates a new unique ID for entity. Basically takes highest unique ID in the storage
        and returns higher one. Unique ID is a simple number used for entity lookups and storage.
        It's also used when saving. Player (unless you added new entities while editing) has
        always highest unique ID.
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

        logging.log(logging.DEBUG, "Generating new uid: " .. tostring(r))

        -- we're done, return
        return r
    end

    --[[!
        Function: new
        Creates a new serverside entity. The entity is then sent to every client available.
        The function generates an unique ID, unless the unique ID is forced to value
        via arguments, then calls <entity_store.add> with proper arguments (the entity is new).

        It can either return the entity (default) or its unique ID (if overriden from arguments).

        Parameters:
            class - the entity class to create instance of.
            kwargs - additional parameter table, passed to <entity_store.add>.
            force_uid - forced unique ID, optional. If not forced, it gets generated.
            return_uid - boolean value, optional. If true, entity's unique ID is returned
            instead of actual entity instance.
    ]]
    function new(class, kwargs, force_uid, return_uid)
        -- force or generate
        force_uid = force_uid or generate_uid()

        logging.log(logging.DEBUG, "New entity: " .. force_uid)

        -- create instance
        local r = add(class, force_uid, kwargs, true)

        -- return the values
        return return_uid and r.uid or r
    end

    --[[!
        Function: new_npc
        Creates a new NPC (client). The changes get reflected to every client.
        The NPC is set as controlled_here, which on server means state variables
        with custom synching will not notify clients with message when updated
        serverside.

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
        logging.log(logging.DEBUG, "Sending active entities to " .. tostring(cn))

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
            actor_uid - unique ID of the actor (client that triggered the change)
            or -1 when it comes from the server.
    ]]
    function set_state_data(uid, key_protocol_id, value, actor_uid)
        local entity = get(uid)
        if entity then
            local key = message.to_protocol_name(tostring(entity), key_protocol_id)
            entity:set_state_data(key, value, actor_uid)
        end
    end

    --[[!
        Function: load_entities
        Loads entities into server storage from previously saved JSON string.
        The string gets decoded, entities get looped, state data are set.

        Performs some backwards compatibility adjustments for old sauer map formats.
        Entities created this way are then passed to all clients.

        State data get passed via kwargs to <entity_store.add>.

        Parameters:
            entities_json - JSON string which is later decoded into proper table
            of entity data.
    ]]
    function load_entities(entities_json)
        logging.log(logging.DEBUG, "Loading entities .. " .. tostring(entities_json) .. ", " .. type(entities_json))

        -- decode it
        local entities = json.decode(entities_json)

        -- loop the table
        for i, entity in pairs(entities) do
            logging.log(logging.DEBUG, "load_entities: " .. json.encode(entity))

            -- entity unique ID
            local uid        = entity[1]
            -- entity class name
            local class_name = entity[2]
            -- entity state data
            local state_data = entity[3]

            logging.log(
                logging.DEBUG,
                "load_entities: "
                    .. uid
                    .. ", "
                    .. class_name
                    .. ", "
                    .. json.encode(state_data)
                )

            -- backwards comptaibility, rotate by 180 degrees for yawed entities
            if mapversion <= 30 and state_data.attr1 then
                -- skip certain entities which have different attr1 than yaw
                if  class_name ~= "light"
                and class_name ~= "flickering_light"
                and class_name ~= "particle_effect"
                and class_name ~= "envmap" then
                    -- set the yaw - rotate by 180°
                    state_data.attr1 = (tonumber(state_data.attr1) + 180) % 360
                end
            end

            -- add the entity, pass state data via kwargs
            add(class_name, uid, { state_data = json.encode(state_data) })
        end

        logging.log(logging.DEBUG, "Loading entities complete")
    end
end
