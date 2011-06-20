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

    Section: Entity storage system
]]

--[[!
    Package: entity_store
    This module handles entity storage for instances, as well as various functions
    for controlling their properties and getting/creating.
]]
module("entity_store", package.seeall)

-- caching by time delay
function cache_by_time_delay(func, delay)
    func.last_time = ((-delay) * 2)
    return function(...)
        if (GLOBAL_TIME - func.last_time) >= delay then
            func.last_cached_val = func(...)
            func.last_time = GLOBAL_TIME
        end
        return func.last_cached_val
    end
end

-- local store of entities, parallels the c++ store
local __entities_store = {}
-- caching
local __entities_store_by_class = {}

--- Access a logent from the store, knowing its unique ID.
-- @param uid Unique ID of the logent to get.
-- @return The logent if found, nil otherwise.
function get(uid)
    logging.log(logging.DEBUG, "get: entity " .. tostring(uid))
    local r = __entities_store[tonumber(uid)]
    if r then
        logging.log(logging.DEBUG, "get: entity " .. tostring(uid) .. " found (" .. r.uid .. ")")
        return r
    else
        logging.log(logging.DEBUG, "get: could not find entity " .. tostring(uid))
        return nil
    end
end

function get_all()
    return __entities_store
end

--- Get a table of logents from store which share the same tag.
-- @param wtag The tag to use for searching.
-- @return Table of logents (empty table if none found)
function get_all_bytag(wtag)
    local r = {}
    for k, v in pairs(__entities_store) do
        if v:has_tag(wtag) then
            table.insert(r, v)
        end
    end
    return r
end

--- Get a single logent of known tag.
-- @param wtag The tag to use for searching.
-- @return Logent with known tag (and none if not found or more than one found)
function get_bytag(wtag)
    local r = get_all_bytag(wtag)
    if #r == 1 then return r[1]
    elseif #r > 1 then
        logging.log(logging.WARNING, "Attempt to get a single entity with tag '" .. tostring(wtag) .. "', but several exist.")
        return nil
    else
        logging.log(logging.WARNING, "Attempt to get a single entity with tag '" .. tostring(wtag) .. "', but none exist.")
        return nil
    end
end

--- Get a table of logents of the same class.
-- @param cl Class to use for searching.
-- @return Table of logents (empty table if none found)
function get_all_byclass(cl)
    if type(cl) == "table" then
        cl = tostring(cl)
    end

    -- caching
    if __entities_store_by_class[cl] then
        return __entities_store_by_class[cl]
    else
        return {}
    end
end

--- Get a table of all clients (== all logents of currently set player class)
-- @return Table of clients. (empty if no clients found, that means we're probably in menu)
function get_all_clients()
    local ret = get_all_byclass(type(player_class) == "string" and player_class or "player")
    logging.log(logging.INFO, "logent store: get_all_clients: got %(1)s clients" % { #ret })
    return ret
end

--- Get a table of all client numbers.
-- @return Table of client numbers. (empty if no clients found, that means we're probably in menu)
function get_all_clientnums()
    return table.map(get_all_clients(), function(c) return c.cn end)
end

--- Get whether player is editing.
-- @return True if player is editing, false otherwise.
function is_player_editing(ply)
    if CLIENT then
        ply = ply or get_plyent()
    end
    return ply and ply.cs == 4 -- character.CSTATE.EDITING
end

--- Get table of entities close to a position.
-- @param origin The position they should be close to.
-- @param maxdist Distance after which the entities are considered "far"
-- @param cl If set, only entities of that class will be returned.
-- @param wtag If set, only entities of that tag will be returned.
-- @param unsorted If not set, table will contain entities sorted by distance (from nearest to farest).
-- @return Table of entities.
function get_all_close(origin, maxdist, cl, wtag, unsorted)
    local r = {}

    local ents = cl and get_all_byclass(cl) or table.values(__entities_store)
    for i = 1, #ents do
        local oe = ents[i]

        local skip = false
        if wtag and not oe:has_tag(wtag) then skip = true end
        if not oe.position then skip = true end

        if not skip then
            local dist = origin:sub_new(oe.position):magnitude()
            if dist <= maxdist then
                table.insert(r, { oe, dist })
            end
        end
    end

    if not unsorted then
        table.sort(r, function(a, b) return a[2] < b[2] end)
    end

    return r
end

--- Add a logic entity. The entity will get stored and activated.
-- @param cn Class of the new entity.
-- @param uid Unique ID of the entity.
-- @param kwargs Additional parameters to pass to constructor (contents depend on entity type).
-- @param _new Works only serverside, if set, init() of the entity will get called instead of just setting uid.
-- @return The newly created entity.
function add(cn, uid, kwargs, _new)
    uid = uid or 1337 -- debugging

    logging.log(logging.DEBUG, "Adding new scripting logent of type " .. tostring(cn) .. " with uid " .. tostring(uid))
    logging.log(logging.DEBUG, "   with arguments: " .. json.encode(kwargs) .. ", " .. tostring(_new))

    assert(not get(uid)) -- cannot recreate

    local _class = entity_classes.get_class(cn)
    local r = _class()

    if CLIENT then
        r.uid = uid
    else
        if _new then
            r:init(uid, kwargs)
        else
            r.uid = uid
        end
    end

    __entities_store[r.uid] = r
    assert(get(uid) == r)

    -- caching
    for k, v in pairs(entity_classes._logent_classes) do
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

    return r
end

--- Delete an entity of known uid.
-- @param uid Unique ID of the entity which we're deleting.
function del(uid)
    logging.log(logging.DEBUG, "Removing scripting logent: " .. tostring(uid))

    if not __entities_store[tonumber(uid)] then
        logging.log(logging.WARNING, "Cannot remove entity " .. tostring(uid) .. " as it does not exist.")
        return nil
    end

    __entities_store[tonumber(uid)]:emit("pre_deactivate")

    if CLIENT then
        __entities_store[tonumber(uid)]:client_deactivate()
    else
        __entities_store[tonumber(uid)]:deactivate()
    end

    -- caching
    local ent = __entities_store[tonumber(uid)]
    for k, v in pairs(entity_classes._logent_classes) do
        if tostring(ent) == k then
            __entities_store_by_class[k] = table.filterarray(
                __entities_store_by_class[k],
                function(a, b) return (b ~= ent) end
            )
        end
    end

    __entities_store[tonumber(uid)] = nil
end

--- Delete all entities in the store.
function del_all()
    for k, v in pairs(__entities_store) do
        del(k)
    end
end

curr_timestamp = 0
_G["GLOBAL_CURRENT_TIMESTAMP"] = curr_timestamp

function start_frame()
    curr_timestamp = curr_timestamp + 1
    _G["GLOBAL_CURRENT_TIMESTAMP"] = curr_timestamp
end

_G["GLOBAL_TIME"] = 0
_G["GLOBAL_CURRENT_TIMEDELTA"] = 1.0
_G["GLOBAL_LASTMILLIS"] = 0
_G["GLOBAL_QUEUED_ACTIONS"] = {}

--- Manage action queue. This is performed every frame,
-- so its performance is important. It loops the entity
-- store and runs either client_act or act (depending
-- on if we're on server or client) for every entity
-- that has acting enabled, it also sets global time.
-- This is called from C.
-- @param sec The length of seconds to simulate.
-- @param lastmillis Number of miliseconds since last reset.
function manage_actions(sec, lastmillis)
    logging.log(logging.INFO, "manage_actions: queued ..")

    local curr_actions = table.copy(GLOBAL_QUEUED_ACTIONS) -- work on copy as these may add more
    _G["GLOBAL_QUEUED_ACTIONS"] = {}

    for k,v in pairs(curr_actions) do v() end

    _G["GLOBAL_TIME"] = GLOBAL_TIME + sec
    _G["GLOBAL_CURRENT_TIMEDELTA"] = sec
    _G["GLOBAL_LASTMILLIS"] = lastmillis

    logging.log(logging.INFO, "manage_actions: " .. tostring(sec))

    local ents = table.values(__entities_store)
    for i = 1, #ents do
        local ent = ents[i]

        local skip = false
        if ent.deactivated then
            skip = true
        end
        if not ent.should_act then
            skip = true
        end
        if type(ent.should_act) == "table" and (
            (CLIENT and not ent.should_act.client) or
            (SERVER and not ent.should_act.server)
        ) then
            skip = true
        end

        if not skip then
            if CLIENT then
                ent:client_act(sec)
            else
                ent:act(sec)
            end
        end
    end
end

--- Global dynamic render method. This is performed every frame,
-- so its performance is important. It loops the entity store
-- and performs render_dynamic for every entity that should
-- have this ran (characters, mapmodels, etc).
-- If we're in thirdperson mode, player won't be rendered,
-- because that's done in render_hud_models.
-- @param tp True if we're in thirdperson mode, false otherwise.
-- @see render_hud_models
function render_dynamic(tp)
    logging.log(logging.INFO, "render_dynamic")

    local ply = get_plyent()
    if not ply then return nil end

    local ents = table.values(__entities_store)
    for i = 1, #ents do
        local ent = ents[i]
        local skip = false
        if ent.deactivated or not ent.render_dynamic then skip = true end
        if not skip then
            if ent.use_render_dynamic_test then
                if not ent.render_dynamic_test then
                    rendering.setup_dynamic_test(ent)
                end
                if not ent:render_dynamic_test() then skip = true end
            end
        end
        if not skip then
            ent:render_dynamic(false, not tp and ent == ply)
        end
    end
end

manage_triggering_collisions = cache_by_time_delay(convert.tocalltable(function()
    local ents = get_all_byclass("area_trigger")
    for i, player in pairs(get_all_clients()) do
        if is_player_editing(player) then return nil end

        for n, entity in pairs(ents) do
            if world.is_player_colliding_entity(player, entity) then
                if CLIENT then
                    entity:client_on_collision(player)
                else
                    entity:on_collision(player)
                end
            end
        end
    end
end), 1 / 10)

--- Render HUD models. Called when we're in thirdperson mode.
-- Takes care of rendering player HUD model if player is not
-- in edit mode and has hud model name set.
-- @see render_dynamic
function render_hud_models()
    local ply = get_plyent()
    if ply.hud_modelname and ply.cs ~= 4 then -- 4 = character.CSTATE.EDITING
        ply:render_dynamic(true, true)
    end
end

if CLIENT then

--- Set player uid. Clientside only function. Creates player_logent method, which is
-- global and can be accessed by get_plyent afterwards.
-- @param uid The unique ID of player's logic entity.
-- @see get_plyent
function set_player_uid(uid)
    logging.log(logging.DEBUG, "Setting player uid to " .. tostring(uid))

    if uid then
        player_logent = get(uid)
        player_logent._controlled_here = true
        logging.log(logging.DEBUG, "Player _controlled_here:" .. tostring(player_logent._controlled_here))

        assert(not uid or player_logent)
    end
end

--- Get player logic entity. Clientside only.
-- @return Player logic entity.
-- @see set_player_uid
function get_plyent() return player_logent end

--- Set entity state data. Protocol ID gets translated to actual name.
-- This performs changes only locally, so makes sense only as response
-- to server command. This is clientside only function.
-- @param uid Unique ID of the entity.
-- @param kproid Protocol ID of state data.
-- @param val Value to set.
function set_statedata(uid, kproid, val)
    ent = get(uid)
    if ent then
        local key = message.fromproid(tostring(ent), kproid)
        logging.log(logging.DEBUG, "set_statedata: " .. tostring(uid) .. ", " .. tostring(kproid) .. ", " .. tostring(key))
        ent:_set_statedata(key, val)
    end
end

--- Test if scenario has started. If some entity is still uninitialized
-- or player does not exist yet, it means scenario is not started.
-- This is clientside only function.
-- @return True if it has, false otherwise.
function test_scenario_started()
    logging.log(logging.INFO, "Testing whether the scenario started ..")

    if not get_plyent() then
        logging.log(logging.INFO, ".. no, player logent not created yet.")
        return false
    end

    logging.log(logging.INFO, ".. player entity created.")

    ents = table.values(__entities_store)
    for i = 1, #ents do
        if not ents[i].initialized then
            logging.log(logging.INFO, ".. no, entity " .. tostring(ents[i].uid) .. " is not initialized.")
            return false
        end
    end

    logging.log(logging.INFO, ".. yes, scenario is running.")
    return true
end

end

if SERVER then

--- Generate new unique ID. Used when adding entities. Serverside only function.
-- @return Newly generated unique ID.
function get_newuid()
    local r = 0
    uids = table.keys(__entities_store)
    for i = 1, #uids do
        r = math.max(r, uids[i])
    end
    r = r + 1
    logging.log(logging.DEBUG, "Generating new uid: " .. tostring(r))
    return r
end

--- Create new serverside entity. Optionally generates unique ID (if not forced)
-- @param cl Class to generate new entity of.
-- @param kwargs Parameters passed to entity constructor, specific to class.
-- @param fuid If set, unique ID of new entity is forced to it. Otherwise generated.
-- @param ruid If true, new entity's unique ID is returned, otherwise entity is returned.
-- @return Depending on last argument, either new entity or its unique ID are returned.
function new(cl, kwargs, fuid, ruid)
    fuid = fuid or get_newuid()
    logging.log(logging.DEBUG, "New logent: " .. tostring(fuid))

    local r = add(cl, fuid, kwargs, true)

    return ruid and r.uid or r
end

--- Create new serverside NPC. The change gets reflected to all clients.
-- @param cl Class of the NPC.
-- @return The new NPC entity.
function new_npc(cl)
    local npc = CAPI.npcadd(cl)
    npc._controlled_here = true
    return npc
end

--- Send all data of currently active serverside entities to client.
-- Includes both inmap entities like mapmodels and non-map entities
-- like players and non-sauers.
-- @param cn Client number belonging to client we're sending to.
function send_entities(cn)
    logging.log(logging.DEBUG, "Sending active logents to " .. tostring(cn))

    local numents = 0
    local ids = {}
    for k, v in pairs(__entities_store) do
        numents = numents + 1
        table.insert(ids, k) -- create the keys table immediately to not iterate twice later
    end
    table.sort(ids)

    message.send(cn, CAPI.notify_numents, numents)
    for i = 1, #ids do
        __entities_store[ids[i]]:send_notification_complete(cn)
    end
end

--- Set serverside entity state data and then asking clients to update.
-- Protocol IDs get translated to normal names.
-- @param uid Unique ID of the entity.
-- @param kproid Protocol ID of state data.
-- @param val Value to set.
-- @param auid Unique ID of the actor (client that triggered the change) or -1 when it comes from server.
function set_statedata(uid, kproid, val, auid)
    local ent = get(uid)
    if ent then
        local key = message.fromproid(tostring(ent), kproid)
        ent:_set_statedata(key, val, auid)
    end
end

--- Load entities from JSON table and notify clients to add them later.
-- Serverside only function.
-- @param sents JSON table of entities as a string, decoded later.
function load_entities(sents)
    logging.log(logging.DEBUG, "Loading entities .. " .. tostring(sents) .. ", " .. type(sents))

    local ents = json.decode(sents)
    for i = 1, #ents do
        logging.log(logging.DEBUG, "load_entities: " .. json.encode(ents[i]))
        local uid = ents[i][1]
        local cls = ents[i][2]
        local state_data = ents[i][3]
        logging.log(logging.DEBUG, "load_entities: " .. tostring(uid) .. ", " .. tostring(cls) .. ", " .. json.encode(state_data))

        if mapversion <= 30 and state_data.attr1 then
            if cls ~= "light" and cls ~= "flickering_light" and cls ~= "particle_effect" and cls ~= "envmap" then
                state_data.attr1 = (tonumber(state_data.attr1) + 180) % 360
            end
        end

        add(cls, uid, { state_data = json.encode(state_data) })
    end

    logging.log(logging.DEBUG, "Loading entities complete")
end

end

--- Create encoded JSON table (string) of all entities in store and return.
-- Used when saving entities on the disk to load them next time.
-- @return Encoded JSON table (string) of the entities.
function save_entities()
    local r = {}
    logging.log(logging.DEBUG, "Saving entities ..:")

    local vals = table.values(__entities_store)
    for i = 1, #vals do
        if vals[i]._persistent then
            logging.log(logging.DEBUG, "Saving entity " .. tostring(vals[i].uid))
            local uid = vals[i].uid
            local cls = tostring(vals[i])
            -- TODO: store as serialized here, to save some parse/unparsing
            local state_data = vals[i]:create_statedatadict()
            table.insert(r, json.encode({ uid, cls, state_data }))
        end
    end

    logging.log(logging.DEBUG, "Saving entities complete.")
    return "[\n" .. table.concat(r, ",\n") .. "\n]\n\n"
end

-- get targeted entity unique ID
get_target_entity_uid = CAPI.get_target_entity_uid

-- Caching per GLOBAL_CURRENT_TIMESTAMP
function cache_by_global_timestamp(func)
    return function(...)
        if func.last_timestamp ~= GLOBAL_CURRENT_TIMESTAMP then
            func.last_cached_val = func(...)
            func.last_timestamp = GLOBAL_CURRENT_TIMESTAMP
        end
        return func.last_cached_val
    end
end

CAPI.gettargetpos = cache_by_global_timestamp(CAPI.gettargetpos)
CAPI.gettargetent = cache_by_global_timestamp(CAPI.gettargetent)

rendering = {}

--- Set up dynamic render test. This is meant to increase performance,
-- because it skips render_dynamic for all entities that are out of
-- sight of the player.
-- @param ent Entity to set up dynamic render test for.
function rendering.setup_dynamic_test(ent)
    local current = ent
    ent.render_dynamic_test = cache_by_time_delay(convert.tocalltable(function()
        local plycenter = get_plyent().center
        if current.position:subnew(plycenter):magnitude() > 256 then
            if not utility.haslineofsight(plycenter, current.position) then return false end
        end
        return true
    end), 1 / 3)
end
