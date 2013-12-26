--[[!<
    Implements basic entity handling, that is, storage, entity class management
    and the basic entity classes; the other extended entity types have their
    own modules.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")
local logging = require("core.logger")
local log = logging.log
local DEBUG   = logging.DEBUG
local INFO    = logging.INFO
local ERROR   = logging.ERROR
local WARNING = logging.WARNING

local msg = require("core.network.msg")
local frame = require("core.events.frame")
local actions = require("core.events.actions")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local cs = require("core.engine.cubescript")

local table2 = require("core.lua.table")

local set_external = capi.external_set

local filter, filter_map, map, sort, concat, find, serialize, deserialize
    = table2.filter, table2.filter_map, table2.map, table2.sort,
      table.concat, table2.find, table2.serialize, table2.deserialize

local Vec3, emit = require("core.lua.math").Vec3, signal.emit
local max, floor = math.max, math.floor
local pairs = pairs
local assert = assert
local tonumber, tostring = tonumber, tostring

--! Module: ents
local M = {}

local Entity

-- clientside only
local player_entity

-- client and server
local highest_uid = 1

-- basic storage for entities, keys are unique ids and values are entities
local storage = {}

-- for caching, keys are class names and values are arrays of entities
local storage_by_class = {}

-- for Sauer entity import; used as intermediate storage during map loading,
-- cleared out immediately afterwards
local storage_sauer = {}

-- stores all registered entity classes
local class_storage = {}

--[[
    Stores mapping of state variable names and the associated ids, which
    are used for network transfers; numbers take less space than names,
    so they take less time to transfer.
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

-- see above, used for back-translation
local ids_to_names = {}

local is_svar, is_svar_alias = svars.is_svar, svars.is_svar_alias

--[[!
    Generates the required network data for an entity class. You pass the
    entity class name and an array of state variable names to generate network
    data for.
]]
M.gen_network_data = function(cn, names)
    debug then log(DEBUG, "ents.generate_network_data: " .. cn)
    sort(names)

    local ntoi, iton = {}, {}
    for id = 1, #names do
        local name = names[id]
        ntoi[name], iton[id] = tostring(id), name
    end

    names_to_ids[cn], ids_to_names[cn] = ntoi, iton
end
local gen_network_data = M.gen_network_data

--[[!
    If an entity class name is provided, clears the network data generated
    by $gen_network_data for the entity class. Otherwise clears it all.
]]
M.clear_network_data = function(cn)
    if cn == nil then
        debug then log(DEBUG, "ents.clear_network_data")
        names_to_ids, ids_to_names = {}, {}
    else
        debug then log(DEBUG, "ents.clear_network_data: " .. cn)
        names_to_ids[cn], ids_to_names[cn] = nil, nil
    end
end

local plugin_slots = {
    "__init_svars", "__activate", "__deactivate", "__run", "__render"
}
local plugin_slotset = {
    ["__init_svars"] = true, ["__activate"] = true, ["__deactivate"] = true,
    ["__run"       ] = true, ["__render"  ] = true
}

local ipairs, pairs = ipairs, pairs
local assert, type = assert, type

local modprefix = "_PLUGINS_"

local register_plugins = function(cl, plugins, name)
    debug then log(DEBUG, "ents.register_class: registering plugins")
    local cldata = {}
    local properties

    local clname = cl.name
    for i, slot in ipairs(plugin_slots) do
        local slotname = modprefix .. clname .. slot
        assert(not cl[slotname])

        local cltbl = { cl[slot] }
        for j, plugin in ipairs(plugins) do
            local sl = plugin[slot]
            local tp = type(sl)
            if sl and tp == "function" or tp == "table" or tp == "userdata"
            then cltbl[#cltbl + 1] = sl end
        end

        if not (#cltbl == 0 or (#cltbl == 1 and cltbl[1] == cl[slot])) then
            cldata[slotname] = cltbl
            cldata[slot] = function(...)
                for i, fn in ipairs(cltbl) do fn(...) end
            end
        end
    end

    for i, plugin in ipairs(plugins) do
        for name, elem in pairs(plugin) do
            if not plugin_slotset[name] then
                if name == "__properties" then
                    assert(type(elem) == "table")
                    if not properties then
                        properties = elem
                    else
                        for propn, propv in pairs(elem) do
                            properties[propn] = propv
                        end
                    end
                else
                    cldata[name] = elem
                end
            end
        end
    end

    local ret = cl:clone(cldata)
    ret.name           = name
    ret.__properties   = properties
    ret.__raw_class    = cl
    ret.__parent_class = cl.__proto
    ret.__plugins      = plugins
    return ret
end

--[[!
    Registers an entity class. The registered class is always a clone of
    the given class. You can access the original class via the `__raw_class`
    member of the new clone. You can access the parent of `__raw_class` using
    `__parent_class`. This also generates protocol data for its properties and
    registers these.

    Allows to provide an array of plugins to inject into the entity class
    (before the actual registration, so that the plugins can provide their own
    state variables).

    Because this is a special clone, do NOT derive from it. Instead derive
    from `__raw_class`. This function doesn't return anything for a reason.
    If you really need this special clone, use $get_class.

    A plugin is pretty much an associative table of things to inject. It
    can contain slots - those are functions or callable values with keys
    `__init_svars`, `__activate`, `__deactivate`, `__run`, `__render` - slots
    never override elements of the same name in the original class, instead
    they're called after it in the order of plugin array. Then it can contain
    any non-slot member, those are overriden without checking (the last plugin
    takes priority). Plugins can provide their own state variables via the
    `__properties` table, like entities. The `__properties` tables of plugins
    are all merged together and the last plugin takes priority.

    The original plugin array is accessible from the clone as `__plugins`.

    Note that plugins can NOT change the entity class name. If any such
    element is found, it's ignored.

    Arguments:
        - cl - the entity class.
        - plugins - an optional array of plugins (or name).
        - name - optional entity class name, if not provided the `name` field
          of the entity class name is used; it can also be the second argument
          if you are not providing plugins.
]]
M.register_class = function(cl, plugins, name)
    if not name then
        if type(plugins) == "string" then
            name, plugins = plugins, nil
        else
            name = cl.name
        end
    end
    assert(name)

    debug then log(DEBUG, "ents.register_class: " .. name)

    assert(not class_storage[name],
        "an entity class with the same name already exists")

    if plugins then
        cl = register_plugins(cl, plugins, name)
    else
        cl = cl:clone {
            name = name,
            __raw_class = cl,
            __parent_class = cl.__proto
        }
    end

    class_storage[name] = cl

    -- table of properties
    local pt = {}
    local sv_names = {}

    local base = cl
    while base do
        local props = base.__properties
        if props then
            for n, v in pairs(props) do
                if not pt[n] and svars.is_svar(v) then
                    pt[n] = v
                    sv_names[#sv_names + 1] = n
                end
            end
        end
        if base == Entity then break end
        base = base.__proto
    end

    sort(sv_names, function(n, m)
        if is_svar_alias(pt[n]) and not is_svar_alias(pt[m]) then
            return false
        end
        if not is_svar_alias(pt[n]) and is_svar_alias(pt[m]) then
            return true
        end
        return n < m
    end)

    debug then log(DEBUG, "ents.register_class: generating protocol data for "
        .. "{ " .. concat(sv_names, ", ") .. " }")

    gen_network_data(name, sv_names)

    debug then log(DEBUG, "ents.register_class: registering state variables")
    for i = 1, #sv_names do
        local name = sv_names[i]
        local var  = pt[name]
        debug then log(DEBUG, "    " .. name .. " (" .. var.name .. ")")
        var:register(name, cl)
    end
end

--[[!
    Returns the entity class with the given name. If it doesn't exist,
    logs an error message and returns nil. External as `entity_class_get`.

    Use with caution! See $register_class for the possible dangers of
    using this. It's still useful sometimes, so it's in the API.
]]
M.get_class = function(cn)
    local  t = class_storage[cn]
    if not t then
        log(ERROR, "ents.get_class: invalid class " .. cn)
    end
    return t
end
local get_class = M.get_class
set_external("entity_class_get", get_class)

--[[!
    Returns the internal entity class storage (name->class mapping), use
    with care.
]]
M.get_all_classes = function()
    return class_storage
end

--[[!
    Retrieves an entity, given its unique id. If not found, nil. External as
    `entity_get`.
]]
M.get = function(uid)
    local r = storage[uid]
    if r then
        debug then log(DEBUG, "ents.get: success (" .. uid .. ")")
        return r
    else
        debug then log(DEBUG, "ents.get: no such entity (" .. uid .. ")")
    end
end
set_external("entity_get", M.get)
local get_ent = M.get

--[[!
    Returns the whole storage. Use with care. External as `entities_get_all`.
]]
M.get_all = function()
    return storage
end
set_external("entities_get_all", M.get_all)

--! Returns an array of entities with a common tag.
M.get_by_tag = function(tag)
    local r = {}
    local l = 1
    for i = 1, highest_uid do
        local ent = storage[i]
        if ent and ent:has_tag(tag) then
            r[l] = ent
            l = l + 1
        end
    end
    return r
end

--! Returns an array of entities with a common class.
M.get_by_class = function(cl)
    return storage_by_class[cl] or {}
end

local player_class = "Player"

--! Sets the player class (by name) on the server (invalid on the client).
M.set_player_class = SERVER and function(cl)
    player_class = cl
end or nil

local vg = cs.var_get

--! Gets an array of players (all of the currently set player class).
M.get_players = function()
    return storage_by_class[SERVER and player_class or player_entity.name]
        or {}
end
local get_players = M.get_players

--! Gets the current player, clientside only.
M.get_player = (not SERVER) and function()
    return player_entity
end or nil

if SERVER then
    set_external("entity_get_player_class", function()
        return player_class
    end)
end

--[[!
    Finds all entities whose maximum distance from pos equals
    max_distance. You can filter them more using optional kwargs.
    Returns an array of entity-distance pairs.

    Kwargs:
        max_distance - the maximum distance from the given position.
        class - either an actual entity class or a name.
        tag - a tag the entities must have.
        sort - by default, the resulting array is sorted by distance
        from lowest to highest. This can be either a function (passed
        to {{$table.sort}}, refer to its documentation), a boolean value
        false (which means it won't be sorted) or nil (which means
        it will be sorted using the default method).
        pos_fun - a function taking an entity and returning a position
        in form of {{$geom.Vec3}}. By default simply returns entity's position,
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

    if type(cl) == "table" then cl = cl.name end

    local ret = {}
    for uid = 1, highest_uid do
        local ent = storage[uid]
        if ent and ((not cl or cl == ent.name) and (not tg or ent:has_tag(tg)))
        then
            local dist = #(pos - fn(ent))
            if dist <= md then
                ret[#ret + 1] = { ent, dist }
            end
        end
    end

    if sr != false then
        sort(ret, sr or function(a, b) return a[2] < b[2] end)
    end
    return ret
end

--[[!
    Inserts an entity of the given class or class name into the storage.
    The entity will get assigned an uid and activated. Kwargs will be passed
    to the activation calls and init call on the server. If `new` is true,
    `__init_svars` method will be called on the server on the entity instead
    of just assigning an uid. That means it's a newly created entity. Sometimes
    we don't want this behavior, for example when loading an entity from a
    file. External as `entity_add`.
]]
local add = function(cn, uid, kwargs, new)
    uid = uid or 1337

    local cl = type(cn) == "table" and cn or class_storage[cn]
    if not cl then
        log(ERROR, "ents.add: no such entity class: " .. tostring(cn))
        assert(false)
    end

    debug then log(DEBUG, "ents.add: " .. cl.name .. " (" .. uid .. ")")
    assert(not storage[uid])

    if uid > highest_uid then
        highest_uid = uid
    end

    local r = cl()
    r.uid = uid
    storage[uid] = r

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

    if SERVER and new then
        local ndata
        if kwargs then
            ndata = kwargs.newent_data
            kwargs.newent_data = nil
            if ndata then ndata = deserialize(ndata) end
        end
        r:__init_svars(kwargs, ndata or {})
    end

    debug then log(DEBUG, "ents.add: activate")
    r:__activate(kwargs)
    debug then log(DEBUG, "ents.add: activated")
    return r
end
M.add = add
set_external("entity_add", add)

local add_sauer = function(et, x, y, z, attr1, attr2, attr3, attr4, attr5)
    storage_sauer[#storage_sauer + 1] = {
        et, Vec3(x, y, z), attr1, attr2, attr3, attr4, attr5
    }
end
M.add_sauer = add_sauer
set_external("entity_add_sauer", add_sauer)

--[[!
    Removes an entity of the given uid. First emits the `pre_deactivate`
    signal on it, then deactivates it and then clears it out from both
    storages. External as `entity_remove`.

    See also:
        - $remove_all
]]
M.remove = function(uid)
    debug then log(DEBUG, "ents.remove: " .. uid)

    local e = storage[uid]
    if not e then
        log(WARNING, "ents.remove: does not exist.")
        return
    end

    emit(e, "pre_deactivate")
    e:__deactivate()

    for k, v in pairs(class_storage) do
        if e:is_a(v) then
            storage_by_class[k] = filter_map(storage_by_class[k],
                function(a, b) return (b != e) end)
        end
    end
    storage[uid] = nil
end
set_external("entity_remove", M.remove)

set_external("entity_clear_actions", function(uid)
    get_ent(uid):clear_actions()
end)

set_external("entity_is_initialized", function(uid)
    return get_ent(uid).initialized
end)

--[[!
    Removes all entities from both storages. It's equivalent to looping
    over the whole storage and removing each entity individually, but
    much faster. External as `entities_remove_all`.

    See also:
        - $remove
]]
M.remove_all = function()
    for i = 1, highest_uid do
        local e = storage[i]
        if e then
            emit(e, "pre_deactivate")
            e:__deactivate()
        end
    end
    storage = {}
    storage_by_class = {}
end
set_external("entities_remove_all", M.remove_all)

--[[!
    Serverside. Reads a file called `entities.lua` in the map directory,
    serializes it and loads entities from it. The file contains a regular
    Lua serialized table.

    It also attempts to load previously queued Sauer entities. On the client
    this function does nothing.

    The server then sends the entities to all clients.

    Format:
        `{ { uid, "entity_class", sdata }, { ... }, ... }`

    See also:
        - $save
]]
M.load = function()
    if not SERVER then return end

    debug then log(DEBUG, "ents.load: reading")
    local el = capi.readfile("./entities.lua")

    local entities = {}
    if not el then
        debug then log(DEBUG, "ents.load: nothing to read")
    else
        entities = deserialize(el)
    end

    if #storage_sauer > 0 then
        debug then log(DEBUG, "ents.load: loading sauer entities:\n"
            .. "    reading import.lua for imported models and sounds")

        local il, im, is = capi.readfile("./import.lua"), {}, {}
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
            [6] = "Sound",           [7] = "Spot_Light"
        }

        for i = 1, #storage_sauer do
            local e = storage_sauer[i]
            local et = e[1]
            local o, attr1, attr2, attr3, attr4, attr5
                = e[2], e[3], e[4], e[5], e[6], e[7]
            if sn[et] then
                entities[#entities + 1] = {
                    huid, sn[et], {
                        attr1 = tostring(attr1), attr2 = tostring(attr2),
                        attr3 = tostring(attr3), attr4 = tostring(attr4),
                        attr5 = tostring(attr5),

                        position = ("[%i|%i|%i]"):format(o.x, o.y, o.z),
                        model_name = "", attachments = "[]",
                        tags = "[]", persistent = "true"
                    }
                }

                local ent = entities[#entities][3]

                if et == 2 then
                    ent.model_name = (#im <= attr2) and
                        ("@REPLACE_" .. attr2 .. "@") or im[attr2 + 1]
                    ent.attr2 = ent.attr3
                    ent.attr3 = "0"
                    ent.animation = "[mapmodel,loop]"
                    ent.animation_flags = "0"
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
                end

                huid = huid + 1
            else
                log(WARNING, ("unsupported sauer entity: %d: (%f, %f,"
                    .. " %f) %d %d %d %d %d"):format(et, o.x, o.y, o.z, attr1,
                    attr2, attr3, attr4, attr5))
            end
        end

        storage_sauer = {}
    end

    debug then log(DEBUG, "ents.load: loading all entities")
    for i = 1, #entities do
        local e = entities[i]
        local uid, cn = e[1], e[2]
        debug then log(DEBUG, "    " .. uid .. ", " .. cn)
        add(cn, uid, { state_data = serialize(e[3]) })
    end
    debug then log(DEBUG, "ents.load: done")
end

--[[!
    Serializes all loaded entities into format that can be read by $load.
    External as `entities_save_all`.
]]
M.save = function()
    local r = {}
    debug then log(DEBUG, "ents.save: saving")

    for uid = 1, highest_uid do
        local entity = storage[uid]
        if entity and entity:get_attr("persistent") then
            local en = entity.name
            debug then log(DEBUG, "    " .. uid .. ", " .. en)
            r[#r + 1] = serialize({ uid, en, entity:build_sdata() })
        end
    end

    debug then log(DEBUG, "ents.save: done")
    return "{\n" .. concat(r, ",\n") .. "\n}\n"
end
set_external("entities_save_all", M.save)

--[[!
    The base entity class. Every other entity class inherits from this.
    This class is fully functional, but it has no physical form (it's only
    kept in storage, handles its sdata and does the required syncing and
    calls).

    Every entity class needs a name. You need to specify a unique one as
    the `name` member of the class (see the code). Typically, the name will
    be the same with the name of the actual class variable.

    The base entity class has two basic properties.

    Properties:
        - tags [{{$svars.State_Array}}] - every entity can have an unlimited
        amount of tags (they're strings). You can use tags to search for
        entities later, other use cases include e.g. marking of player starts.
        - persistent [{{$svars.State_Booleann}}] - if the entity is persistent,
        it will be saved during map save; if not, it's only temporary (and it
        will disappear when the map ends)
]]
M.Entity = table2.Object:clone {
    name = "Entity",

    --[[!
        If this is true for the entity class, it will call the $__run method
        every frame. That is often convenient, but in most static entities
        undesirable. It's true by default.
    ]]
    __per_frame = true,

    --[[!
        Here you store the state variables. Every inherited entity class
        also inherits its parent's properties in addition to the newly
        defined ones. If you don't want any new properties in your
        entity class, do not create this table.
    ]]
    __properties = {
        tags       = svars.State_Array(),
        persistent = svars.State_Boolean()
    },

    --! Makes entity objects return their name on tostring.
    __tostring = function(self)
        return self.name
    end,

    --[[!
        Performs entity setup. Creates its action queue, caching tables,
        de-deactivates the entity, triggers svar setup and locks.
    ]]
    setup = function(self)
        debug then log(DEBUG, "Entity: setup")

        if self.setup_complete then return end

        self.action_queue = actions.Action_Queue(self)
        -- for caching
        self.svar_values, self.svar_value_timestamps = {}, {}
        -- no longer deactivated
        self.deactivated = false

        -- lock
        self.setup_complete = true
    end,

    --[[!
        The default entity deactivator. Clears the action queue, unregisters
        the entity and makes it deactivated. On the server it also sends a
        message to all clients to do the same.
    ]]
    __deactivate = function(self)
        self:clear_actions()
        capi.unregister_entity(self.uid)

        self.deactivated = true

        if SERVER then
            msg.send(msg.ALL_CLIENTS, capi.le_removal, self.uid)
        end
    end,

    --[[!
        Called per frame unless $__per_frame is false. All inherited classes
        must call this in their own overrides. The argument specifies how
        long to manage the action queue (how much will the counters change
        internally), specified in milliseconds.
    ]]
    __run = function(self, millis)
        self.action_queue:run(millis)
    end,

    --! Enqueues an action into the entity's queue.
    enqueue_action = function(self, act)
        self.action_queue:enqueue(act)
    end,

    --! Clears the entity's action queue.
    clear_actions = function(self)
        self.action_queue:clear()
    end,

    --[[!
        Tags an entity. Modifies the `tags` property. Checks for existence
        of the tag first.
    ]]
    add_tag = function(self, tag)
        if not self:has_tag(tag) then
            self:get_attr("tags"):append(tag)
        end
    end,

    --! Removes the given tag. Checks for its existence first.
    remove_tag = function(self, tag)
        debug then log(DEBUG, "Entity: remove_tag (" .. tag .. ")")

        if not self:has_tag(tag) then return end
        self:set_attr("tags", filter(self:get_attr("tags"):to_array(),
            |i, t| t != tag))
    end,

    --[[!
        Checks if the entity is tagged with the given tag. Returns true if
        found, false if not found.
    ]]
    has_tag = function(self, tag)
        debug then log(DEBUG, "Entity: has_tag (" .. tag .. ")")
        return find(self:get_attr("tags"):to_array(), tag) != nil
    end,

    --[[!
        Builds sdata (state data, property mappings) from the properties the
        entity has.

        Kwargs:
            - target_cn [nil] - the client number to check state variables
            against (see <State_Variable.should_send>). If that is nil,
            no checking happens and stuff is done for all clients.
            - compressed [false] - if true, this function will return the
            sdata in a serialized format (string) with names converted
            to protocol IDs, otherwise raw table.
    ]]
    build_sdata = function(self, kwargs)
        kwargs = kwargs or {}
        local tcn, comp
        if not kwargs then
            tcn, comp = msg.ALL_CLIENTS, false
        else
            tcn, comp = kwargs.target_cn or msg.ALL_CLIENTS,
                        kwargs.compressed or false
        end

        debug then log(DEBUG, "Entity.build_sdata: " .. tcn .. ", "
            .. tostring(comp))

        local r, sn = {}, self.name
        for k, var in pairs(self.__proto) do
            if is_svar(var) and var.has_history
            and not (tcn >= 0 and not var:should_send(self, tcn)) then
                local name = var.name
                local val = self:get_attr(name)
                if val != nil then
                    local wval = var:to_wire(val)
                    debug then log(DEBUG, "    adding " .. name .. ": "
                        .. wval)
                    local key = (not comp) and name
                        or tonumber(names_to_ids[sn][name])
                    r[key] = wval
                    debug then log(DEBUG, "    currently " .. serialize(r))
                end
            end
        end

        debug then log(DEBUG, "Entity.build_sdata result: " .. serialize(r))
        if not comp then
            return r
        end

        r = serialize(r)
        debug then log(DEBUG, "Entity.build_sdata compressed: " .. r)
        return r:sub(2, #r - 1)
    end,

    --! Updates the complete state data on an entity from serialized input.
    set_sdata_full = function(self, sdata)
        debug then log(DEBUG, "Entity.set_sdata_full: " .. self.uid .. ", "
            .. sdata)

        sdata = sdata:sub(1, 1) != "{" and "{" .. sdata .. "}" or sdata
        local raw = deserialize(sdata)
        assert(type(raw) == "table")

        self.initialized = true

        local sn = self.name
        for k, v in pairs(raw) do
            k = tonumber(k) and ids_to_names[sn][k] or k
            debug then log(DEBUG, "    " .. k .. " = " .. tostring(v))
            self:set_sdata(k, v, nil, true)
            debug then log(DEBUG, "    ... done.")
        end
        debug then log(DEBUG, "Entity.set_sdata_full: complete")
    end,

    --[[! Function: entity_setup
        Takes care of a proper entity setup (calls $setup, inits the change
        queue and makes the entity initialized). Called by $__init_svars and
        $__activate.
    ]]
    entity_setup = SERVER and function(self)
        if not self.initialized then
            debug then log(DEBUG, "Entity.entity_setup: setup")
            self:setup()

            self.svar_change_queue = {}
            self.svar_change_queue_complete = false

            self.initialized = true
            debug then log(DEBUG, "Entity.entity_setup: setup complete")
        end
    end or nil,

    --[[! Function: __init_svars
        Initializes the entity before activation on the server. It's
        used to set default svar values (unless `client_set`).

        Arguments:
             - kwargs - used to query whether the entity is persistent (to
               set the persistent property), in child entities it can be used
               for more things.
             - ndata - an array of extra newent arguments in wire format.
    ]]
    __init_svars = SERVER and function(self, kwargs, ndata)
        debug then log(DEBUG, "Entity.__init_svars")

        self:entity_setup()

        self:set_attr("tags", {})
        self:set_attr("persistent", kwargs and kwargs.persistent or false)
    end or nil,

    --[[!
        The entity activator. It's called on its creation. It calls
        $setup.

        Client note: The entity is not initialized before complete
        sdata is received.

        On the server, the kwargs are queried for sdata and
        a $set_sdata_full happens.
    ]]
    __activate = function(self, kwargs)
        debug then log(DEBUG, "Entity.__activate")
        if SERVER then
            self:entity_setup()
        else
            self:setup()
        end

        if not self.sauer_type then
            debug then log(DEBUG, "Entity.__activate: non-sauer entity: "
                .. self.name)
            capi.setup_nonsauer(self)
            if SERVER then
                self:flush_queued_svar_changes()
            end
        end

        if SERVER then
            local sd = kwargs and kwargs.state_data or nil
            if sd then self:set_sdata_full(sd) end
            self:send_notification_full(msg.ALL_CLIENTS)
            self.sent_notification_full = true
            
        else
            self.initialized = false
        end
    end,

    --[[!
        Triggered automatically right before the `_changed` signal. It first
        checks if there is a setter function for the given svar and does
        nothing if there isn't. Triggers a setter call on the client or on the
        server when there is no change queue and queues a change otherwise.

        Arguments:
            - var - the state variable.
            - name - the state variable name.
            - val - the value to set.
    ]]
    sdata_changed = function(self, var, name, val)
        local sfun = var.setter_fun
        if not sfun then return end
        if not (SERVER and self.svar_change_queue) then
            debug then log(INFO, "Calling setter function for " .. name)
            sfun(self.uid, val)
            debug then log(INFO, "Setter called")

            self.svar_values[name] = val
            self.svar_value_timestamps[name] = frame.get_frame()
        else
            self:queue_svar_change(name, val)
        end
    end,

    --[[! Function: set_sdata
        The entity state data setter. Has different variants for the client
        and the server.

        If this is on the client and the change didn't come from here (or if
        the property is `client_set`), it performs a local update. The local
        update first calls $sdata_changed and then triggers the `_changed`
        signal (before setting). The new value is passed to the signal
        during the emit along with a boolean equaling to `actor_uid != -1`.

        On the server it triggers a local change in the same manner.

        Arguments:
            - key - the key.
            - val - the value.
            - actor_uid - unique ID of the change source. On the client, -1
              means it's the client itself, on the server it means all clients.
              If the change came from this client on the client and the entity
              doesn't use a custom syncing method, this sends a notification
              to the server.
            - iop - on the server, a boolean value, if it's true it makes
              this an internal server operaton; that always forces the value
              to convert from wire format (otherwise converts only when setting
              on a specific client number).
    ]]
    set_sdata = (not SERVER) and function(self, key, val, actor_uid)
        debug then log(DEBUG, "Entity.set_sdata: " .. key .. " = "
            .. serialize(val) .. " for " .. self.uid)

        local var  = self["_SV_" .. key]
        local csfh = var.custom_sync and self.controlled_here
        local cset = var.client_set

        local nfh = actor_uid != -1

        -- from client-side script, send a server request unless the var
        -- is controlled here (synced using some other method)
        -- if this variable is set on the client, send a notification
        if not nfh and not csfh then
            debug then log(DEBUG, "    sending server request/notification.")
            -- TODO: supress sending of the same val, at least for some SVs
            msg.send(var.reliable and capi.statedata_changerequest
                or capi.statedata_changerequest_unreliable,
                self.uid, names_to_ids[self.name][var.name],
                var:to_wire(val))
        end

        -- from a server or set clientside, update now
        if nfh or cset or csfh then
            debug then log(INFO, "    local update")
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
        debug then log(DEBUG, "Entity.set_sdata: " .. key .. " = "
            .. serialize(val) .. " for " .. self.uid)

        local var = self["_SV_" .. key]

        if not var then
            log(WARNING, "Entity.set_sdata: ignoring sdata setting"
                .. " for an unknown variable " .. key)
            return
        end

        if actor_uid and actor_uid != -1 then
            val = var:from_wire(val)
            if not var.client_write then
                log(ERROR, "Entity.set_sdata: client " .. actor_uid
                    .. " tried to change " .. key)
                return
            end
        elseif iop then
            val = var:from_wire(val)
        end

        self:sdata_changed(var, key, val)
        emit(self, key .. "_changed", val, actor_uid)
        if self.sdata_update_cancel then
            self.sdata_update_cancel = nil
            return
        end

        self.svar_values[key] = val
        debug then log(INFO, "Entity.set_sdata: new sdata: " .. tostring(val))

        local csfh = var.custom_sync and self.controlled_here
        if not iop and var.client_read and not csfh then
            if not self.sent_notification_full then
                return
            end

            local args = {
                nil, var.reliable and capi.statedata_update
                    or capi.statedata_update_unreliable,
                self.uid,
                names_to_ids[self.name][key],
                var:to_wire(val),
                (var.client_set and actor_uid and actor_uid != -1)
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

    --[[!
        Cancels a state data update (on the server). Useful when called
        from `_changed` signal slots.
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
        debug then log(DEBUG, "Entity.send_notification_full: " .. cn .. ", "
            .. uid)

        local scn, sname = self.cn, self.name
        for i = 1, #cns do
            local n = cns[i]
            msg.send(n, capi.le_notification_complete,
                scn and scn or acn, uid, sname, self:build_sdata(
                    { target_cn = n, compressed = true }))
        end

        debug then log(DEBUG, "Entity.send_notification_full: done")
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
        if not changes then return end
        self.svar_change_queue = nil

        for k, v in pairs(changes) do
            local rv = self.svar_values[k]
            debug then log(DEBUG, "Entity: flushing queued svar change: "
                .. k .. " == " .. tostring(v) .. " (real: "
                .. tostring(rv) .. ")")
            self:set_attr(k, rv)
        end

        self.svar_change_queue_complete = true
    end or nil,

    --[[!
        Returns the next attached entity. This implementation doesn't do
        anything though - you need to overload it for your entity type
        accordingly. The core entity system doesn't manage attached
        entities at all. See also $get_attached_prev.
    ]]
    get_attached_next = function(self)
    end,

    --[[!
        Returns the previous attached entity. Like $get_attached_next,
        you need to overload this.
    ]]
    get_attached_prev = function(self)
    end,

    --[[!
        Given a GUI property name (`gui_name` or `name` if not defined in the
        svar), this returns the property value in a wire (string) format.

        See also:
            - $get_attr
            - $get_gui_attrs
            - $set_gui_attr
    ]]
    get_gui_attr = function(self, prop)
        local var = self["_SV_GUI_" .. prop]
        if not var or not var.has_history then return nil end
        local val = self:get_attr(var.name)
        if val != nil then
            return var:to_wire(val)
        end
    end,

    --[[!
        Like $get_gui_attr, but returns all available attributes as an
        array of key-value pairs. The second argument (defaults to true)
        specifies whether to sort the result by attribute name.
    ]]
    get_gui_attrs = function(self, sortattrs)
        if sortattrs == nil then sortattrs = true end
        local r = {}
        for k, var in pairs(self) do
            if is_svar(var) and var.has_history and var.gui_name != false then
                local name = var.name
                local val = self:get_attr(name)
                if val != nil then
                    r[#r + 1] = { var.gui_name or name, var:to_wire(val) }
                end
            end
        end
        if sortattrs then sort(r, function(a, b) return a[1] < b[1] end) end
        return r
    end,

    --[[!
        Given a GUI property name and a value in a wire format, this sets
        the property on the entity.

        See also:
            - $set_attr
            - $get_gui_attr
    ]]
    set_gui_attr = function(self, prop, val)
        local var = self["_SV_GUI_" .. prop]
        if not var or not var.has_history then return end
        self:set_attr(var.name, var:from_wire(val))
    end,

    --[[!
        Returns the entity property of the given name.

        See also:
            - $set_attr
            - $get_gui_attr
    ]]
    get_attr = function(self, prop)
        local fun = self["__get_" .. prop]
        if fun then return fun(self) end
        return nil
    end,

    --[[! Function: set_attr
        Sets the entity property of the given name to the given value.

        Arguments:
             - prop - the property name.
             - val - the value.
             - nd - optionally provides a non-wire default value that takes
               preference (if it's provided, it's converted from wire format
               and if that succeeds, it's used in place of the actual value).

        See also:
            - $get_attr
            - $set_gui_attr
    ]]
    set_attr = function(self, prop, val, nd)
        if nd then
            local var = self["_SV_" .. prop]
            if var then
                local nw = var:from_wire(nd)
                if nw != nil then val = nw end
            end
        end
        local fun = self["__set_" .. prop]
        return fun and fun(self, val) or nil
    end
}
Entity = M.Entity

--[[!
    See {{$Entity.get_gui_attr}}. Externally accessible as
    `entity_get_gui_attr`. See also $set_gui_attr.
]]
M.get_gui_attr = function(ent, prop)
    return ent:get_gui_attr(prop)
end
set_external("entity_get_gui_attr", M.get_gui_attr)

--[[!
    See {{$Entity.set_gui_attr}}. Externally accessible as
    `entity_set_gui_attr`. See also $get_gui_attr.
]]
M.set_gui_attr = function(ent, prop, val)
    return ent:set_gui_attr(prop, val)
end
set_external("entity_set_gui_attr", M.set_gui_attr)

--[[!
    See {{$Entity.get_attr}}. Externally accessible as `entity_get_attr`. An
    external called `entity_get_attr_uid` works with uid instead of an entity.
    See also $set_attr.
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

--[[!
    See {{$Entity.set_attr}}. Externally accessible as `entity_set_attr`. An
    external called `entity_set_attr_uid` works with uid instead of an entity.
    See also $get_attr.
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
    An external. Calls {{$Entity.get_attached_next}} on the given entity first,
    if that returns then this returns true + the attached entities, otherwise
    calls {{$Entity.get_attached_prev}} and if that returns, then this returns
    false + the attached entities, if that also fails then it returns nil.
]]
set_external("entity_get_attached", function(ent)
    local ents = { ent:get_attached_next() }
    if #ents > 0 then
        return true, unpack(ents)
    end
    ents = { ent:get_attached_prev() }
    if #ents > 0 then
        return false, unpack(ents)
    end
end)

--[[! Function: entity_get_class_name
    An external that returns the name of the class of the given entity.
]]
set_external("entity_get_class_name", function(ent)
    return ent.name
end)

--[[! Function: render
    Main render hook. External as `game_render`. Calls individual `render`
    method on each entity (if defined). Clientside only. See also $render_hud.
]]
M.render = (not SERVER) and function(tp, fpsshadow)
    debug then log(INFO, "game_render")
    local  player = player_entity
    if not player then return end

    for uid = 1, highest_uid do
        local entity = storage[uid]
        if entity and not entity.deactivated then
            local rd = entity.__render
            -- first arg to rd is hudpass, false because we aren't rendering
            -- the HUD model, second is needhud, which is true if the model
            -- should be shown as HUD model and that happens if we're not in
            -- thirdperson and the current entity is the player
            -- third is whether we're rendering a first person shadow
            if  rd then
                rd(entity, false, not tp and entity == player, fpsshadow)
            end
        end
    end
end or nil
local render = M.render
set_external("game_render", render)

--[[! Function: render_hud
    Renders the player HUD model if needed. External as `game_render_hud`.
    Clientside only. See also $render.
]]
M.render_hud = (not SERVER) and function()
    debug then log(INFO, "game_render_hud")
    local  player = player_entity
    if not player then return end

    if player:get_attr("hud_model_name") and not player:get_editing() then
        player:__render(true, true, false)
    end
end or nil
local render_hud = M.render_hud
set_external("game_render_hud", render_hud)

--[[! Function: init_player
    Assigns the player entity using the given uid. External as `player_init`,
    clientside.
]]
M.init_player = (not SERVER) and function(uid)
    assert(uid)
    debug then log(DEBUG, "Initializing player with uid " .. uid)

    player_entity = storage[uid]
    assert(player_entity)
    player_entity.controlled_here = true
end or nil
local init_player = M.init_player
set_external("player_init", init_player)

--[[!
    Converts the protocol ID to a real key and sets the state data on the
    entity with the given unique ID.

    External as `entity_set_sdata`.

    Arguments:
        - uid - an unique ID.
        - kpid - a key in protocol ID format.
        - value - a value.
        - auid - optional (on the server only) actor unique ID, an unique ID
          of the client that triggered the change. When set to -1, it means
          the server triggered it.
]]
M.set_sdata = function(uid, kpid, value, auid)
    local ent = storage[uid]
    if ent then
        local key = ids_to_names[ent.name][kpid]
        debug then log(DEBUG, "set_sdata: " .. uid .. ", " .. kpid .. ", "
            .. key)
        ent:set_sdata(key, value, auid)
    end
end
set_external("entity_set_sdata", M.set_sdata)

set_external("entity_set_sdata_full", function(uid, sd)
    get_ent(uid):set_sdata_full(sd)
end)

--[[ Function: scene_is_ready
    On the client, used to check if the current scene is ready and we can
    actually start (checks whether the player exists and whether all the
    entities are initialized). External as `scene_is_ready`.
!]]
M.scene_is_ready = (not SERVER) and function()
    debug then log(INFO, "Scene ready?")

    if player_entity == nil then
        debug then log(INFO, "...not ready, player entity missing.")
        return false
    end

    debug then log(INFO, "...player ready, trying other entities.")
    for uid = 1, highest_uid do
        local ent = storage[uid]
        if ent and not ent.initialized then
            debug then log(INFO, "...entity " .. uid .. " not ready.")
            return false
        end
    end

    debug then log(INFO, "...yes!")
    return true
end or nil
set_external("scene_is_ready", M.scene_is_ready)

--[[! Function: gen_uid
    Generates a new entity unique ID. It's larger than the previous largest
    by one. Serverside. External as `entity_gen_uid`.
]]
M.gen_uid = SERVER and function()
    debug then log(DEBUG, "Generating an UID, last highest UID: "
        .. highest_uid)
    return highest_uid + 1
end or nil
local gen_uid = M.gen_uid
set_external("entity_gen_uid", gen_uid)

--! Returns the highest entity unique ID used.
M.get_highest_uid = function()
    return highest_uid
end

--[[! Function: new
    Creates a new entity on the server. External as `entity_new`.

    Arguments:
        - cl - the entity class.
        - kwargs - passed directly to $add.
        - fuid - optional forced unique ID, otherwise $gen_uid.

    Returns:
         The new entity.
]]
M.new = SERVER and function(cl, kwargs, fuid)
    fuid = fuid or gen_uid()
    debug then log(DEBUG, "New entity: " .. fuid)
    return add(cl, fuid, kwargs, true)
end or nil
set_external("entity_new", M.new)

--[[! Function: send
    Notifies a client of the number of entities on the server and then
    send a complete notification for each of them. Takes the client number.
    Works only serverside. External as `entities_send_all`.
]]
M.send = SERVER and function(cn)
    debug then log(DEBUG, "Sending active entities to " .. cn)
    local nents, uids = 0, {}
    for uid = 1, highest_uid do
        if storage[uid] then
            nents = nents + 1
            uids[nents] = uid
        end
    end
    sort(uids)
    msg.send(cn, capi.notify_numents, nents)
    for i = 1, nents do
        storage[uids[i]]:send_notification_full(cn)
    end
end or nil
set_external("entities_send_all", M.send)

return M
