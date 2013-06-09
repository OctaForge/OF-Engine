--[[!
    File: lua/core/entities/ents.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Implements basic entity handling, that is, storage, entity class
        management and the basic entity classes; the other extended
        entity types have their own modules.
]]

local msg = require("core.network.msg")
local frame = require("core.events.frame")
local actions = require("core.events.actions")
local signal = require("core.events.signal")

local filter, filter_map, map, sort, keys, concat, find, serialize, deserialize
    = table.filter, table.filter_map, table.map, table.sort, table.keys,
      table.concat, table.find, table.serialize, table.deserialize

local Vec3, emit = math.Vec3, signal.emit
local max, floor = math.max, math.floor
local pairs = pairs
local assert = assert
local tonumber, tostring = tonumber, tostring

local M = {}

local Entity

-- clientside only
local player_entity

-- client and server
local highest_uid = 1

--[[! Variable: storage
    A table of entities. Stores all the entities for the currently loaded
    map; cleared out when not needed anymore. Entities here are stored by
    their uid (unique id - the key). Private to the module, not directly
    accessible.
]]
local storage = {}

--[[! Variable: storage_by_class
    Ditto. Used mainly for caching. Keys are entity class names and values
    are arrays of entities (instances of the given class). Again, private.
]]
local storage_by_class = {}

-- for Sauer entity import; used as intermediate storage during map loading,
-- cleared out immediately afterwards
local storage_sauer = {}

--[[! Variable: class_storage
    A table of entity classes. Stores all currently registered classes.
    Private to the module. Represents a name-class map.
]]
local class_storage = {}

--[[! Variable: names_to_ids
    A private associative table used to store mapping of state variable
    names and the associated ids, which are used in network transfers.
    Numbers take less space than names, they take less time to transfer.

    Structure:
    {
        entity_class_name1 = {
            state_variable_name1 = id1,
            state_variable_name2 = id2,
            state_variable_namen = idn
        },
        entity_class_name2 = ...
        entity_class_namen = ...
    }
]]
local names_to_ids = {}

--[[! Variable: ids_to_names
    Similar to <names_to_ids>. It maps things the other way, from ids
    to names. Used to translate the ids back to names.
]]
local ids_to_names = {}

local is_svar, is_svar_alias = svars.is_svar, svars.is_svar_alias

--[[! Function: gen_network_data
    Generates the required network data for an entity class. You pass the
    entity class name and an array of state variable names to generate network
    data for. This function fills the appropriate fields in <names_to_ids>
    and <ids_to_names>.
]]
local gen_network_data = function(cn, names)
    #log(DEBUG, "ents.generate_network_data: " .. cn)
    sort(names)

    local ntoi, iton = {}, {}
    for id = 1, #names do
        local name = names[id]
        ntoi[name], iton[id] = tostring(id), name
    end

    names_to_ids[cn], ids_to_names[cn] = ntoi, iton
end
M.gen_network_data = gen_network_data

--[[! Function: clear_network_data
    If an entity class name is provided, clears the network data generated
    by <gen_network_data> for the entity class. Otherwise clears it all.
]]
M.clear_network_data = function(cn)
    if cn == nil then
        #log(DEBUG, "ents.clear_network_data")
        names_to_ids, ids_to_names = {}, {}
    else
        #log(DEBUG, "ents.clear_network_data: " .. cn)
        names_to_ids[cn], ids_to_names[cn] = nil, nil
    end
end

--[[! Function: register_class
    Registers an entity class. Returns the class. Generates protocol data
    for its properties.
]]
M.register_class = function(cl)
    local cn = tostring(cl)

    #log(DEBUG, "ents.register_class: " .. cn)

    assert(not class_storage[cn],
        "an entity class with the same name already exists")

    class_storage[cn] = cl

    -- table of properties
    local pt = {}

    local base = cl
    while base do
        local props = base.properties
        if props then
            for n, v in pairs(props) do
                if not pt[n] and svars.is_svar(v) then
                    pt[n] = v
                end
            end
        end
        if base == Entity then break end
        base = base.__proto
    end

    local sv_names = keys(pt)
    sort(sv_names, function(n, m)
        if is_svar_alias(pt[n]) and not is_svar_alias(pt[m]) then
            return false
        end
        if not is_svar_alias(pt[n]) and is_svar_alias(pt[m]) then
            return true
        end
        return n < m
    end)

    #log(DEBUG, "ents.register_class: generating protocol data for { "
    #    .. concat(sv_names, ", ") .. " }")

    gen_network_data(cn, sv_names)

    #log(DEBUG, "ents.register_class: registering state variables")
    for i = 1, #sv_names do
        local name = sv_names[i]
        local var  = pt[name]
        #log(DEBUG, "    " .. name .. " (" .. tostring(var) .. ")")
        var:register(name, cl)
    end

    return cl
end

--[[! Function: get_class
    Returns the entity class with the given name. If it doesn't exist,
    logs an error message and returns nil. External as "entity_class_get".
]]
local get_class = function(cn)
    local  t = class_storage[cn]
    if not t then
        #log(ERROR, "ents.get_class: invalid class " .. cn)
    end
    return t
end
M.get_class = get_class
set_external("entity_class_get", get_class)

--[[! Function: get_all_classes
    Returns <class_storage>. Use with care.
]]
M.get_all_classes = function()
    return class_storage
end

--[[! Function: get
    Retrieves an entity, given its uuid. If not found, nil. External as
    "entity_get".
]]
M.get = function(uid)
    local r = storage[uid]
    if r then
        #log(DEBUG, "ents.get: success (" .. uid .. ")")
        return r
    else
        #log(DEBUG, "ents.get: no such entity (" .. uid .. ")")
    end
end
set_external("entity_get", M.get)

--[[! Function: get_all
    Returns the whole storage. Use with care. External as "entities_get_all".
]]
M.get_all = function()
    return storage
end
set_external("entities_get_all", M.get_all)

--[[! Function: get_all_by_tag
    Returns an array of entities with a common tag.
]]
M.get_by_tag = function(tag)
    local r = {}
    local l = 1
    for uid, ent in pairs(storage) do
        if ent:has_tag(tag) then
            r[l] = ent
            l = l + 1
        end
    end
    return r
end

--[[! Function: get_by_class
    Returns an array of entities with a common class.
]]
M.get_by_class = function(cl)
    return storage_by_class[tostring(cl)] or {}
end

--[[! Function: get_players
    Gets an array of players (all of the currently set player class).
]]
local get_players = function()
    return storage_by_class[_V.player_class] or {}
end
M.get_players = get_players

--[[! Function: get_player
    Gets the current player, clientside only.
]]
M.get_player = CLIENT and function()
    return player_entity
end or nil

--[[! Function: get_by_distance
    Finds all entities whose maximum distance from pos equals
    max_distance. You can filter them more using optional kwargs.
    Returns an array of entity-distance pairs.

    Kwargs:
        max_distance - the maximum distance from the given position.
        class - either an actual entity class or a name.
        tag - a tag the entities must have.
        sort - by default, the resulting array is sorted by distance
        from lowest to highest. This can be either a function (passed
        to table.sort, refer to its documentation), a boolean value
        false (which means it won't be sorted) or nil (which means
        it will be sorted using the default method).
        pos_fun - a function taking an entity and returning a position
        in form of <math.Vec3>. By default simply returns entity's position,
        the position is then used for subtraction from the given position.
]]
M.get_by_distance = function(pos, kwargs)
    kwargs = kwargs or {}

    local md = kwargs.max_distance
    if not md then return nil end

    local cl, tg, sr = kwargs.class, kwargs.tag, kwargs.sort
    local fn = kwargs.pos_fun or function(e)
        return e:get_attr("position"):copy()
    end

    if type(cl) == "table" then cl = tostring(cl) end

    local ret = {}
    for uid, ent in pairs(storage) do
        if (not cl or cl == tostring(ent)) and (not tg or ent:has_tag(tg)) then
            local dist = #(pos - fn(ent))
            if dist <= md then
                ret[#ret + 1] = { ent, dist }
            end
        end
    end

    if sr ~= false then
        sort(ret, sr or function(a, b) return a[2] < b[2] end)
    end
    return ret
end

--[[! Function: add
    Inserts an entity of the given class or class name into the storage.
    The entity will get assigned an uid and activated. Kwargs will be
    passed to the activation calls and init call on the server. If
    "new" is true, "init" method will be called on the server on
    the entity instead of just assigning an uid. That means it's
    a newly created entity. Sometimes we don't want this behavior,
    for example when loading an entity from a file.
    External as "entity_add".
]]
local add = function(cn, uid, kwargs, new)
    uid = uid or 1337

    #log(DEBUG, "ents.add: " .. tostring(cn) .. " (" .. uid .. ")")
    assert(not storage[uid])

    if uid > highest_uid then
        highest_uid = uid
    end

    local cl = type(cn) == "table" and cn or class_storage[cn]

    local r = cl()
    if CLIENT or not new then
        r.uid = uid
    else
        r:init(uid, kwargs)
    end

    storage[r.uid] = r

    -- caching
    for k, v in pairs(class_storage) do
        if r:is_a(v) then
            local sbc = storage_by_class[k]
            if not sbc then
                storage_by_class[k] = { r }
            else
                sbc[#sbc + 1] = r
            end
        end
    end

    #log(DEBUG, "ents.add: activate")
    r:activate(kwargs)
    #log(DEBUG, "ents.add: activated")
    return r
end
M.add = add
set_external("entity_add", add)

--[[! Function: add_sauer
    Appends a request to add a Sauer entity to the sauer storage queue.
    Used for migration of in-map Sauer entities to OctaForge entities.

    External as entity_add_sauer.
]]
local add_sauer = function(et, x, y, z, attr1, attr2, attr3, attr4, attr5)
    storage_sauer[#storage_sauer + 1] = {
        et, Vec3(x, y, z), attr1, attr2, attr3, attr4, attr5
    }
end
M.add_sauer = add_sauer
set_external("entity_add_sauer", add_sauer)

--[[! Function: remove
    Removes an entity of the given uid. First emits pre_deactivate signal
    on it, then deactivates it and then clears it out from both storages.
    External as "entity_remove".
]]
M.remove = function(uid)
    #log(DEBUG, "ents.remove: " .. uid)

    local e = storage[uid]
    if not e then
        #log(WARNING, "ents.remove: does not exist.")
        return nil
    end

    emit(e, "pre_deactivate")
    e:deactivate()

    for k, v in pairs(class_storage) do
        if e:is_a(v) then
            storage_by_class[k] = filter_map(storage_by_class[k],
                function(a, b) return (b ~= e) end)
        end
    end

    storage[uid] = nil
    if uid == highest_uid then
        for i = highest_uid - 1, 1, -1 do
            if storage[i] then
                highest_uid = i
                break
            end
        end
    end
end
set_external("entity_remove", M.remove)

--[[! Function: remove_all
    Removes all entities from both storages. It's equivalent to looping
    over the whole storage and removing each entity individually, but
    much faster. External as "entities_remove_all".
]]
M.remove_all = function()
    for uid, e in pairs(storage) do
        emit(e, "pre_deactivate")
        e:deactivate()
    end
    storage = {}
    storage_by_class = {}
    highest_uid = 1
end
set_external("entities_remove_all", M.remove_all)

--[[! Function: load
    Serverside. Reads a file called "entities.lua" in the map directory,
    serializes it and loads entities from it. The file contains a regular
    Lua serialized table.

    It also attempts to load previously queued Sauer entities. On the client
    this function does nothing.

    The server then sends the entities to all clients.

    Format:
        { { uid, "entity_class", sdata }, { ... }, ... }
]]
M.load = function()
    if not SERVER then return nil end

    #log(DEBUG, "ents.load: reading")
    local el = _C.readfile("./entities.lua")

    local entities = {}
    if not el then
        #log(DEBUG, "ents.load: nothing to read")
    else
        print("DES", el)
        entities = deserialize(el)
        print("ENTS", entities)
    end

    if #storage_sauer > 0 then
        #log(DEBUG, "ents.load: loading sauer entities")
        #log(DEBUG, "    reading import.lua for imported models and sounds")

        local il, im, is = _C.readfile("./import.lua"), {}, {}
        if il then
            local it = deserialize(il)
            local itm, its = it.models, it.sounds
            if itm then im = itm end
            if its then is = its end
        end

        local huid = max(2, highest_uid)
        huid = huid + 1

        local sn = {
            [1] = "Light",           [2] = "Mapmodel",
            [3] = "Oriented_Marker", [4] = "Envmap",
            [5] = "Particle_Effect", [6] = "Sound",
            [7] = "Spot_Light",

            [19] = "teleporter", [20] = "World_Marker", [23] = "jump_pad"
        }

        for i = 1, #storage_sauer do
            local e = storage_sauer[i]
            local et = e[1]
            if sn[et] then
                local o, attr1, attr2, attr3, attr4, attr5
                    = e[2], e[3], e[4], e[5], e[6], e[7]

                entities[#entities + 1] = {
                    huid, sn[et], {
                        attr1 = tostring(attr1), attr2 = tostring(attr2),
                        attr3 = tostring(attr3), attr4 = tostring(attr4),
                        attr5 = tostring(attr5),

                        radius = "0", position = ("[%i|%i|%i]"):format(
                            o.x, o.y, o.z),

                        animation = "130", model_name = "", attachments = "[]",
                        tags = "[]", persistent = "true"
                    }
                }

                local ent = entities[#entities][3]

                if et == 2 then
                    ent.model_name = (#im <= attr2) and
                        ("@REPLACE_" .. attr2 .. "@") or im[attr2 + 1]
                    ent.attr2 = ent.attr3
                    ent.attr3 = "0"
                elseif et == 6 then
                    if #is > attr1 then
                        local snd = is[attr1 + 1]
                        ent.sound_name = snd[1]
                        ent.attr1, ent.attr2 = ent.attr2, ent.attr3
                        if #snd > 1 then
                            ent.attr3 = snd[2]
                        else
                            ent.attr3 = ent.attr4
                        end
                    else
                        ent.attr1, ent.attr2, ent.attr3
                            = ent.attr2, ent.attr3, ent.attr4
                        ent.sound_name = "@REPLACE@"
                    end
                    ent.attr4, ent.attr5 = nil, nil
                elseif et == 3 then
                    ent.tags = "[start_]"
                elseif et == 23 then
                    ent.attr1, ent.attr2, ent.attr3, ent.attr4
                        = "0", "-1", "0", "0"
                    ent.pad_model, ent.pad_rotate, ent.pad_pitch, ent.pad_sound
                        = "", "false", "0", ""
                    ent.model_name, ent.jump_velocity
                        = "areatrigger", ("[%f|%f|%f]"):format(
                            attr3 * 10, attr2 * 10, attr1 * 12.5)
                elseif et == 19 then
                    ent.attr1, ent.attr3, ent.attr4 = "0", "0", "0"
                    ent.destination, ent.sound_name = tostring(attr1), ""
                    if attr2 < 0 then
                        ent.model_name = "areatrigger"
                    else
                        if #im > attr2 then
                            ent.model_name, ent.attr2 = im[attr2 + 1], "-1"
                        else
                            ent.model_name = "@REPLACE@"
                        end
                    end
                elseif et == 20 then
                    ent.attr2, ent.tags = "0", ("[teledest_%i]"):format(attr2)
                end

                huid = huid + 1
            end
        end

        storage_sauer = {}
    end

    #log(DEBUG, "ents.load: loading all entities")
    for i = 1, #entities do
        local e = entities[i]
        local uid, cn = e[1], e[2]
        #log(DEBUG, "    " .. uid .. ", " .. cn)
        add(cn, uid, { sdata = serialize(e[3]) })
    end
    #log(DEBUG, "ents.load: done")
end

--[[! Function: save
    Serializes all loaded entities into format that can be read by <load>.
    External as "entities_save_all".
]]
M.save = function()
    local r = {}
    #log(DEBUG, "ents.save: saving")

    for uid, entity in pairs(storage) do
        if entity:get_attr("persistent") then
            local en = tostring(entity)
            #log(DEBUG, "    " .. uid .. ", " .. en)
            r[#r + 1] = serialize({ uid, en, entity:build_sdata() })
        end
    end

    #log(DEBUG, "ents.save: done")
    return "{\n" .. concat(r, ",\n") .. "\n}\n"
end
set_external("entities_save_all", M.save)

--[[! Class: Entity
    The base entity class. Every other entity class inherits from this.
    This class is fully functional, but it has no physical form (it's only
    kept in storage, handles its sdata and does the required syncing and
    calls).

    Every entity class needs a name. You need to specify a unique one as
    a "name" member of the class (see the code). Typically, the name will
    be the same with the name of the actual class variable.

    The base entity class has two basic properties.

    Properties:
        tags [<svars.State_Array>] - each entity can have an unlimited amount
        of tags (they're strings). You can use tags to search for entities
        later, other use cases include i.e. marking of player starts.
        persistent [<svars.State_Boolean>] - if the entity is persistent, it
        will be saved during map save; if not, it's only temporary (and it
        will disappear when the map ends)
]]
Entity = table.Object:clone {
    name = "Entity",

    --[[! Variable: per_frame
        If this is true for the entity class, it will call the <run> method
        each frame. That is often convenient, but in most static entities
        undesirable.
    ]]
    per_frame = true,

    --[[! Variable: properties
        Here you store the state variables. Each inherited entity class
        also inherits its parent's properties in addition to the newly
        defined ones. If you don't want any new properties in your
        entity class, do not create this table.
    ]]
    properties = {
        tags       = svars.State_Array(),
        persistent = svars.State_Boolean()
    },

    --[[! Function: __tostring
        Makes entity objects return their names on tostring.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[! Function: setup
        Performs the entity setup. Creates the action system, caching tables,
        de-deactivates the entity, triggers svar setup and locks.
    ]]
    setup = function(self)
        #log(DEBUG, "Entity: setup")

        if self.setup_complete then return nil end

        self.action_system = actions.Action_System(self)
        -- for caching
        self.svar_values, self.svar_value_timestamps = {}, {}
        -- no longer deactivated
        self.deactivated = false

        -- lock
        self.setup_complete = true
    end,

    --[[! Function: deactivate
        The default entity deactivator. Clears the action system, unregisters
        the entity and makes it deactivated. On the server, it also sends a
        message to all clients to do the same.
    ]]
    deactivate = function(self)
        self:clear_actions()
        _C.unregister_entity(self.uid)

        self.deactivated = true

        if SERVER then
            msg.send(msg.ALL_CLIENTS, _C.le_removal, self.uid)
        end
    end,

    --[[! Function: run
        Called per-frame unless <per_frame> is false. All inherited classes
        must call this in their own overrides. The argument specifies how
        long to manage the action system (how much will the counters change
        internally), specified in seconds (usually a fraction of a second).
    ]]
    run = function(self, seconds)
        self.action_system:run(seconds)
    end,

    --[[! Function: queue_action
        Queues an action into the entity's queue.
    ]]
    queue_action = function(self, act)
        self.action_system:queue(act)
    end,

    --[[! Function: clear_actions
        Clears the entity's action system.
    ]]
    clear_actions = function(self)
        self.action_system:clear()
    end,

    --[[! Function: add_tag
        Tags an entity. Modifies the "tags" property. Checks for existence
        of the tag first.
    ]]
    add_tag = function(self, tag)
        if not self:has_tag(tag) then
            self:get_attr("tags"):append(tag)
        end
    end,

    --[[! Function: remove_tag
        Removes the given tag. Checks for its existence first.
    ]]
    remove_tag = function(self, tag)
        #log(DEBUG, "Entity: remove_tag (" .. tag .. ")")

        if not self:has_tag(tag) then return nil end
        self:set_attr("tags", filter(self:get_attr("tags"):to_array(),
            function(i, t)
                return t ~= tag
            end))
    end,

    --[[! Function: has_tag
        Checks if the entity is tagged with the given tag. Returns true if
        found, false if not found.
    ]]
    has_tag = function(self, tag)
        #log(DEBUG, "Entity: has_tag (" .. tag .. ")")
        return find(self:get_attr("tags"):to_array(), tag) ~= nil
    end,

    --[[! Function: build_sdata
        Builds sdata (state data, property mappings) from the properties the
        entity has.

        Kwargs:
            target_cn [nil] - the client number to check state variables
            against (see <State_Variable.should_send>). If that is nil,
            no checking happens and stuff is done for all clients.
            compressed [false] - if true, this function will return the
            sdata in a serialized format (string) with names converted
            to protocol IDs, otherwise raw table.
    ]]
    build_sdata = function(self, kwargs)
        local tcn, comp
        if not kwargs then
            tcn, comp = msg.ALL_CLIENTS, false
        else
            tcn, comp = kwargs.target_cn or msg.ALL_CLIENTS,
                        kwargs.compressed or false
        end

        #log(DEBUG, "Entity.build_sdata: " .. tcn .. ", " .. tostring(comp))

        local r, sn = {}, tostring(self)
        for k, var in pairs(self.__proto) do
            if is_svar(var) and var.has_history
            and not (tcn >= 0 and not var:should_send(self, tcn)) then
                local name = var.name
                local val = self:get_attr(name)
                if val ~= nil then
                    local wval = var:to_wire(val)
                    #log(DEBUG, "    adding " .. name .. ": " .. wval)
                    local key = (not comp) and name
                        or tonumber(names_to_ids[sn][name])
                    r[key] = wval
                    #log(DEBUG, "    currently " .. serialize(r))
                end
            end
        end

        #log(DEBUG, "Entity.build_sdata result: " .. serialize(r))
        if not comp then
            return r
        end

        r = serialize(r)
        #log(DEBUG, "Entity.build_sdata compressed: " .. r)
        return r:sub(2, #r - 1)
    end,

    --[[! Function: set_sdata_full
        Updates the complete state data on an entity from serialized input.
    ]]
    set_sdata_full = function(self, sdata)
        #log(DEBUG, "Entity.set_sdata_full: " .. self.uid .. ", " .. sdata)

        sdata = sdata:sub(1, 1) ~= "{" and "{" .. sdata .. "}" or sdata
        local raw = deserialize(sdata)
        assert(type(raw) == "table")

        self.initialized = true

        local sn = tostring(self)
        for k, v in pairs(raw) do
            k = tonumber(k) and ids_to_names[sn][k] or k
            #log(DEBUG, "    " .. k .. " = " .. tostring(v))
            self:set_sdata(k, v, nil, true)
            #log(DEBUG, "    ... done.")
        end
        #log(DEBUG, "Entity.set_sdata_full: complete")
    end,

    --[[! Function: entity_setup
        Takes care of a proper entity setup (calls <setup>, inits the change
        queue and makes the entity initialized). Called by <init> and
        <activate>.
    ]]
    entity_setup = SERVER and function(self)
        if not self.initialized then
            #log(DEBUG, "Entity.entity_setup: setup")
            self:setup()

            self.svar_change_queue = {}
            self.svar_change_queue_complete = false

            self.initialized = true
            #log(DEBUG, "Entity.entity_setup: setup complete")
        end
    end or nil,

    --[[! Function: init
        Initializes the entity before activation on the server. It's
        used to set default svar values (unless client_set).

        The kwargs parameter is used here to query whether the entity
        is persistent (to set the persistent property). In child entities,
        it can be used for more things.
    ]]
    init = SERVER and function(self, uid, kwargs)
        #log(DEBUG, "Entity.init: " .. uid)
        assert(type(uid) == "number")

        self.uid = uid
        self:entity_setup()

        self:set_attr("tags", {})
        self:set_attr("persistent", kwargs and kwargs.persistent or false)
    end or nil,

    --[[! Function: activate
        The entity activator. It's called on its creation. It calls
        <setup>.

        Client note: The entity is not initialized before complete
        sdata are received.

        On the server, the kwargs are queried for sdata and
        a <set_sdata_full> happens.
    ]]
    activate = function(self, kwargs)
        #log(DEBUG, "Entity.activate")
        if SERVER then
            self:entity_setup()
        else
            self:setup()
        end

        if not self.sauer_type then
            #log(DEBUG, "Entity.activate: non-sauer entity: "..tostring(self))
            _C.setup_nonsauer(self)
            if SERVER then
                self:flush_queued_svar_changes()
            end
        end

        if SERVER then
            local sd = kwargs and kwargs.sdata or nil
            if sd then self:set_sdata_full(sd) end
            self:send_notification_full(msg.ALL_CLIENTS)
            self.sent_notification_full = true
            
        else
            self.initialized = false
        end
    end,

    --[[! Function: sdata_changed
        Triggered automatically right before the _changed signal. Takes
        the state variable, its name and the value to set. It first checks
        if there is a setter function for the given svar and does nothing
        if there isn't. Triggers a setter call on the client or on the
        server when there is no change queue and queues a change otherwise.
    ]]
    sdata_changed = function(self, var, name, val)
        local sfun = var.setter_fun
        if not sfun then return nil end
        if CLIENT or not self.svar_change_queue then
            #log(INFO, "Calling setter function for " .. name)
            sfun(self, val)
            #log(INFO, "Setter called")

            self.svar_values[name] = val
            self.svar_value_timestamps[name] = frame.get_frame()
        else
            self:queue_svar_change(name, val)
        end
    end,

    --[[! Function: set_sdata
        The entity state data setter. Has different variants for the client
        and the server.

        Client:
            Takes 4 arguments (self, key, value, actor_uid). The first 3
            are obvious, the fourth specifies an uid of the change source.
            If -1, it was the client itself. If the change came from this
            client and the entity doesn't use a custom syncing method,
            sends a request/notification to the server.

            Otherwise (or if the property is client_set) it does a local
            update. The local update first calls <sdata_changed> and then
            triggers the _changed signal (before the setting). The new
            value is passed to the signal during the emit along with a
            boolean equaling to actor_uid ~= -1.

        Server:
            Takes 5 arguments (self, key, vactor, actor_uid, iop). The
            arguments are sort of the same as on the client. If actor_uid
            is -1, it means all clients. The fifth argument is a boolean
            value and if it's true, it makes this an internal server
            operation; that always forces the value to convert from
            wire format (otherwise converts only when setting on a
            specific client number). The signal and <sdata_changed>
            are triggered in the same manner.
    ]]
    set_sdata = CLIENT and function(self, key, val, actor_uid)
        #log(DEBUG, "Entity.set_sdata: " .. key .. " = " .. serialize(val)
        #    .. " for " .. self.uid)

        local var  = self["_SV_" .. key]
        local csfh = var.custom_sync and self.controlled_here
        local cset = var.client_set

        local nfh = actor_uid ~= -1

        -- from client-side script, send a server request unless the var
        -- is controlled here (synced using some other method)
        -- if this variable is set on the client, send a notification
        if not nfh and not csfh then
            #log(DEBUG, "    sending server request/notification.")
            -- TODO: supress sending of the same val, at least for some SVs
            msg.send(var.reliable and _C.statedata_changerequest
                or _C.statedata_changerequest_unreliable,
                self.uid, names_to_ids[tostring(self)][var.name],
                var:to_wire(val))
        end

        -- from a server or set clientside, update now
        if nfh or cset or csfh then
            #log(INFO, "    local update")
            -- from the server, in wire format
            if nfh then
                val = var:from_wire(val)
            end
            -- TODO: avoid assertions
            assert(var:validate(val))
            self:sdata_changed(var, key, val)
            emit(self, key .. "_changed", val, nfh)
            self.svar_values[key] = val
        end
    end or function(self, key, val, actor_uid, iop)
        #log(DEBUG, "Entity.set_sdata: " .. key .. " = " .. serialize(val)
        #    .. " for " .. self.uid)

        local var = self["_SV_" .. key]

        if not var then
            #log(WARNING, "Entity.set_sdata: ignoring sdata setting"
                .. " for an unknown variable " .. key)
            return nil
        end

        if actor_uid and actor_uid ~= -1 then
            val = var:from_wire(val)
            if not var.client_write then
                #log(ERROR, "Entity.set_sdata: client " .. actor_uid
                    .. " tried to change " .. key)
                return nil
            end
        elseif iop then
            val = var:from_wire(val)
        end

        self:sdata_changed(var, key, val)
        emit(self, key .. "_changed", val, actor_uid)
        if self.sdata_update_cancel then
            self.sdata_update_cancel = nil
            return nil
        end

        self.svar_values[key] = val
        #log(INFO, "Entity.set_sdata: new sdata: " .. tostring(val))

        local csfh = var.custom_sync and self.controlled_here
        if not iop and var.client_read and not csfh then
            if not self.sent_notification_full then
                return nil
            end

            local args = {
                nil, var.reliable and _C.statedata_update
                    or _C.statedata_update_unreliable,
                self.uid,
                names_to_ids[tostring(self)][key],
                var:to_wire(val),
                (var.client_set and actor_uid and actor_uid ~= -1)
                    and storage[actor_uid].cn or msg.ALL_CLIENTS
            }

            local cns = map(get_players(), function(p) return p.cn end)
            for i = 1, #cns do
                local n = cns[i]
                if var:should_send(self, n) then
                    args[1] = n
                    msg.send(unpack(args))
                end
            end
        end
    end,

    --[[! Function: cancel_sdata_update
        Cancels a state data update (on the server). Useful when called
        from FOO_changed signal slots.
    ]]
    cancel_sdata_update = function(self)
        self.sdata_update_cancel = true
    end,

    --[[! Function: send_notification_full
        On the server, sends a full notification to a specific client
        or all clients.
    ]]
    send_notification_full = SERVER and function(self, cn)
        local acn = msg.ALL_CLIENTS
        cn = cn or acn

        local cns = (cn == acn) and map(get_players(), function(p)
            return p.cn end) or { cn }

        local uid = self.uid
        #log(DEBUG, "Entity.send_notification_full: " .. cn .. ", " .. uid)

        local scn, sname = self.cn, tostring(self)
        for i = 1, #cns do
            local n = cns[i]
            msg.send(n, _C.le_notification_complete,
                scn and scn or acn, uid, sname, self:build_sdata(
                    { target_cn = n, compressed = true }))
        end

        #log(DEBUG, "Entity.send_notification_full: done")
    end or nil,

    --[[! Function: queue_svar_change
        Queues a svar change (Happens before full update, when the
        entity is being created). Server only.
    ]]
    queue_svar_change = SERVER and function(self, key, val)
        self.svar_change_queue[key] = val
    end or nil,

    --[[! Function: flush_queued_svar_changes
        Flushes the SV change queue (applies all the changes). After this,
        there is no change queue anymore.
    ]]
    flush_queued_svar_changes = SERVER and function(self)
        local changes = self.svar_change_queue
        if not changes then return nil end
        self.svar_change_queue = nil

        for k, v in pairs(changes) do
            local rv = self.svar_values[k]
            #log(DEBUG, "Entity: flushing queued svar change: "
            #    .. k .. " == " .. tostring(v) .. " (real: "
            #        .. tostring(rv) .. ")")
            self:set_attr(k, rv)
        end

        self.svar_change_queue_complete = true
    end or nil,

    --[[! Function: get_attached_next
        Returns the next attached entity. This implementation doesn't do
        anything though - you need to overload it for your entity type
        accordingly. The core entity system doesn't manage attached
        entities at all.
    ]]
    get_attached_next = function(self)
    end,

    --[[! Function: get_attached_prev
        Returns the previous attached entity. Like <get_attached_next>,
        you need to overload this.
    ]]
    get_attached_prev = function(self)
    end,

    --[[! Function: get_gui_attr
        Given a GUI property name (gui_name or name if not defined in the
        svar), this returns the property value in a wire (string) format.
    ]]
    get_gui_attr = function(self, prop)
        local var = self["_SV_GUI_" .. prop]
        if not var or not var.has_history then return nil end
        local val = self:get_attr(var.name)
        if val ~= nil then
            return var:to_wire(val)
        end
    end,

    --[[! Function: get_gui_attrs
        Like <get_gui_attr>, but returns all available attributes as an
        array of key-value pairs. The second argument (defaults to true)
        specifies whether to sort the result by attribute name.
    ]]
    get_gui_attrs = function(self, sortattrs)
        if sortattrs == nil then sortattrs = true end
        local r = {}
        for k, var in pairs(self) do
            if is_svar(var) and var.has_history then
                local name = var.name
                local val = self:get_attr(name)
                if val ~= nil then
                    r[#r + 1] = { var.gui_name or name, var:to_wire(val) }
                end
            end
        end
        if sortattrs then sort(r, function(a, b) return a[1] < b[1] end) end
        return r
    end,

    --[[! Function: set_gui_attr
        Given a GUI property name and a value in a wire format, this sets
        the property on the entity.
    ]]
    set_gui_attr = function(self, prop, val)
        local var = self["_SV_GUI_" .. prop]
        if not var or not var.has_history then return nil end
        self:set_attr(var.name, var:from_wire(val))
    end,

    --[[! Function: get_attr
        Returns the entity property of the given name.
    ]]
    get_attr = function(self, prop)
        local fun = self["__get_" .. prop]
        return fun and fun(self) or nil
    end,

    --[[! Function: set_attr
        Sets the entity property of the given name to the given value.
    ]]
    set_attr = function(self, prop, val)
        local fun = self["__set_" .. prop]
        return fun and fun(self, val) or nil
    end
}

M.Entity = Entity

--[[! Function: get_gui_attr
    See <Entity.get_gui_attr>. Externally accessible as entity_get_gui_attr.
]]
M.get_gui_attr = function(ent, prop)
    return ent:get_gui_attr(prop)
end
set_external("entity_get_gui_attr", M.get_gui_attr)

--[[! Function: set_gui_attr
    See <Entity.set_gui_attr>. Externally accessible as entity_set_gui_attr.
]]
M.set_gui_attr = function(ent, prop, val)
    return ent:set_gui_attr(prop, val)
end
set_external("entity_set_gui_attr", M.set_gui_attr)

--[[! Function: get_attr
    See <Entity.get_attr>. Externally accessible as entity_get_attr. An
    external called entity_get_attr_uid works with uid instead of an entity.
]]
M.get_attr = function(ent, prop)
    return ent:get_attr(prop)
end
set_external("entity_get_attr", M.get_attr)
set_external("entity_get_attr_uid", function(uid, prop)
    local ent = storage[uid]
    if not ent then return nil end
    return ent:get_attr(prop)
end)

--[[! Function: set_attr
    See <Entity.set_attr>. Externally accessible as entity_set_attr. An
    external called entity_set_attr_uid works with uid instead of an entity.
]]
M.set_attr = function(ent, prop, val)
    return ent:set_attr(prop, val)
end
set_external("entity_set_attr", M.set_attr)
set_external("entity_set_attr_uid", function(uid, prop, val)
    local ent = storage[uid]
    if not ent then return nil end
    return ent:set_attr(prop, val)
end)

--[[! Function: entity_get_attached
    An external. Calls get_attached_next on the given entity first, if that
    returns a valid value then it returns the given entity and the attached
    entity. Otherwise calls get_attached_prev and if that returns, it returns
    the result and the entity. If that also fails, returns nil.
]]
set_external("entity_get_attached", function(ent)
    local ea = ent:get_attached_next()
    if ea then
        return ent, ea
    end
    ea = ent:get_attached_prev()
    if ea then
        return ea, ent
    end
end)

--[[! Function: entity_get_class_name
    An external that returns the name of the class of the given entity.
]]
set_external("entity_get_class_name", function(ent)
    return ent.name
end)

--[[! Function: render
    Main render hook. External as game_render. Calls individual render
    method on each entity (if defined). Clientside only.
]]
local render = CLIENT and function(tp)
    #log(INFO, "game_render")
    local  player = player_entity
    if not player then return nil end

    for uid, entity in pairs(storage) do
        if not entity.deactivated then
            local rd = entity.render
            -- first arg to rd is hudpass, false because we aren't rendering
            -- the HUD model, second is needhud, which is true if the model
            -- should be shown as HUD model and that happens if we're not in
            -- thirdperson and the current entity is the player
            if  rd then
                rd(entity, false, not tp and entity == player)
            end
        end
    end
end or nil
M.render = render
set_external("game_render", render)

--[[! Function: render_hud
    Renders the player HUD model if needed. External as game_render_hud.
    Clientside only.
]]
local render_hud = CLIENT and function()
    #log(INFO, "game_render_hud")
    local  player = player_entity
    if not player then return nil end

    if player:get_attr("hud_model_name") and not player:get_editing() then
        player:render(true, true)
    end
end or nil
M.render_hud = render_hud
set_external("game_render_hud", render_hud)

--[[! Function: init_player
    Assigns the player entity using the given uid. External as player_init,
    clientside.
]]
local init_player = CLIENT and function(uid)
    assert(uid)
    #log(DEBUG, "Initializing player with uid " .. uid)

    player_entity = storage[uid]
    assert(player_entity)
    player_entity.controlled_here = true
end or nil
M.init_player = init_player
set_external("player_init", init_player)

--[[! Function: set_sdata
    Given an unique id, a key (in protocol ID format) and a value, this
    function converts the protocol ID to the real key and sets the state
    data on the entity with the given uid.

    On the server you can optionally provide "actor unique id", an unique id
    of the client that triggered the change. When set to -1, it means the
    server triggered it.

    External as entity_set_sdata.
]]
M.set_sdata = function(uid, kpid, value, auid)
    local ent = storage[uid]
    if ent then
        local key = ids_to_names[tostring(ent)][kpid]
        #log(DEBUG, "set_sdata: " .. uid .. ", " .. kpid .. ", " .. key)
        ent:set_sdata(key, value, auid)
    end
end
set_external("entity_set_sdata", M.set_sdata)

--[[ Function: scene_is_ready
    On the client, used to check if the current scene is ready and we can
    actually start (checks whether the player exists and whether all the
    entities are initialized). External as scene_is_ready.
!]]
M.scene_is_ready = CLIENT and function()
    #log(INFO, "Scene ready?")

    if player_entity == nil then
        #log(INFO, "...not ready, player entity missing.")
        return false
    end

    #log(INFO, "...player ready, trying other entities.")
    for uid, ent in pairs(storage) do
        if not ent.initialized then
            #log(INFO, "...entity " .. uid .. " not ready.")
            return false
        end
    end

    #log(INFO, "...yes!")
    return true
end or nil
set_external("scene_is_ready", M.scene_is_ready)

--[[! Function: gen_uid
    Generates a new entity unique ID. It's larger than the previous largest
    by one. Serverside. External as "entity_gen_uid".
]]
local gen_uid = SERVER and function()
    #log(DEBUG, "Generating an UID, last highest UID: " .. highest_uid)
    return highest_uid + 1
end or nil
M.gen_uid = gen_uid
set_external("entity_gen_uid", gen_uid)

--[[! Function: new
    Creates a new entity on the server. Takes the entity class, kwargs
    (will be passed directly to <add>) and optionally the unique ID to
    force (otherwise <gen_uid>). Returns the entity. External as "entity_new".
]]
M.new = SERVER and function(cl, kwargs, fuid)
    fuid = fuid or gen_uid()
    #log(DEBUG, "New entity: " .. fuid)
    return add(cl, fuid, kwargs, true)
end or nil
set_external("entity_new", M.new)

--[[! Function: send
    Notifies a client of the number of entities on the server and then
    send a complete notification for each of them. Takes the client number.
    Works only serverside. External as "entities_send_all".
]]
M.send = SERVER and function(cn)
    #log(DEBUG, "Sending active entities to " .. cn)
    local uids = keys(storage)
    sort(uids)

    local n = #uids
    msg.send(cn, _C.notify_numents, n)

    for i = 1, n do
        storage[uids[i]]:send_notification_full(cn)
    end
end or nil
set_external("entities_send_all", M.send)

return M
