---
-- base_logent_store.lua, version 1<br/>
-- Logic entity system for Lua - storage<br/>
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
local CAPI = require("CAPI")
local glob = require("cc.global")
local log = require("cc.logging")
local json = require("cc.json")
local lecl = require("cc.logent.classes")
local conv = require("cc.typeconv")
local msgsys = require("cc.msgsys")
local util = require("cc.utils")

--- This module takes care of logic entity storage.
-- @class module
-- @name cc.logent.store
module("cc.logent.store")

function cache_by_time_delay(func, delay)
    func.last_time = ((-delay) * 2)
    return function(...)
        if (glob.time - func.last_time) >= delay then
            func.last_cached_val = func(...)
            func.last_time = glob.time
        end
        return func.last_cached_val
    end
end

local __entities_store = {} -- local store of entities, parallels the c++ store
-- caching
local __entities_store_by_class = {}

function get(uid)
    log.log(log.DEBUG, "get: entity " .. base.tostring(uid))
    local r = __entities_store[base.tonumber(uid)]
    if r then
        log.log(log.DEBUG, "get: entity " .. base.tostring(uid) .. " found (" .. r.uid .. ")")
        return r
    else
        log.log(log.DEBUG, "get: could not find entity " .. base.tostring(uid))
        return nil
    end
end

function get_all_bytag(wtag)
    local r = {}
    for k, v in base.pairs(__entities_store) do
        if v:has_tag(wtag) then
            table.insert(r, v)
        end
    end
    return r
end

function get_bytag(wtag)
    local r = get_all_bytag(wtag)
    if #r == 1 then return r[1]
    elseif #r > 1 then
        log.log(log.WARNING, "Attempt to get a single entity with tag '" .. base.tostring(wtag) .. "', but several exist.")
        return nil
    else
        log.log(log.WARNING, "Attempt to get a single entity with tag '" .. base.tostring(wtag) .. "', but none exist.")
        return nil
    end
end

function get_all_byclass(cl)
    if base.type(cl) == "table" then
        cl = base.tostring(cl)
    end

    -- caching
    if __entities_store_by_class[cl] then
        return __entities_store_by_class[cl]
    else
        return {}
    end
end

function get_all_clients()
    local ret = get_all_byclass("player")
    log.log(log.DEBUG, "logent store: get_all_clients: got %(1)s clients" % { #ret })
    return ret
end

function get_all_clientnums()
    return table.map(get_all_clients(), function(c) return c.cn end)
end

function is_player_editing(ply)
    if glob.CLIENT then
        ply = ply or get_plyent()
    end
    return ply and ply.cs == 4 -- cc.character.CSTATE.EDITING
end

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

function add(cn, uid, kwargs, _new)
    uid = uid or 1337 -- debugging

    log.log(log.DEBUG, "Adding new scripting logent of type " .. base.tostring(cn) .. " with uid " .. base.tostring(uid))
    log.log(log.DEBUG, "   with arguments: " .. json.encode(kwargs) .. ", " .. base.tostring(_new))

    base.assert(not get(uid)) -- cannot recreate

    local f, _class = lecl.get_class(cn)
    local r = _class()

    if glob.CLIENT then
        r.uid = uid
    else
        if _new then
            r:init(uid, kwargs)
        else
            r.uid = uid
        end
    end

    __entities_store[r.uid] = r
    base.assert(get(uid) == r)

    -- caching
    for k, v in base.pairs(lecl._logent_classes) do
        if base.tostring(r) == k then
            if not __entities_store_by_class[k] then
               __entities_store_by_class[k] = {}
            end
            table.insert(__entities_store_by_class[k], r)
        end
    end

    -- done after setting the uid and placing in the global store,
    -- because c++ registration relies on both

    log.log(log.DEBUG, "Activating ..")

    if glob.CLIENT then
        r:client_activate(kwargs)
    else
        r:activate(kwargs)
    end

    return r
end

function del(uid)
    log.log(log.DEBUG, "Removing scripting logent: " .. base.tostring(uid))

    if not __entities_store[base.tonumber(uid)] then
        log.log(log.WARNING, "Cannot remove entity " .. base.tostring(uid) .. " as it does not exist.")
        return nil
    end

    __entities_store[base.tonumber(uid)]:emit("pre_deactivate")

    if glob.CLIENT then
        __entities_store[base.tonumber(uid)]:client_deactivate()
    else
        __entities_store[base.tonumber(uid)]:deactivate()
    end

    -- caching
    local ent = __entities_store[base.tonumber(uid)]
    for k, v in base.pairs(lecl._logent_classes) do
        if base.tostring(ent) == k then
            __entities_store_by_class[k] = table.filterarray(
                __entities_store_by_class[k],
                function(a, b) return (b ~= ent) end
            )
        end
    end

    __entities_store[base.tonumber(uid)] = nil
end

function del_all()
    for k, v in base.pairs(__entities_store) do
        del(k)
    end
end

curr_timestamp = 0
glob.curr_timestamp = curr_timestamp

function start_frame()
    curr_timestamp = curr_timestamp + 1
    glob.curr_timestamp = curr_timestamp
end

glob.time = 0
glob.curr_timedelta = 1.0
glob.lastmillis = 0
glob.queued_actions = {}

function manage_actions(sec, lastmillis)
    log.log(log.INFO, "manage_actions: queued ..")

    local curr_actions = table.copy(glob.queued_actions) -- work on copy as these may add more
    glob.queued_actions = {}

    for k,v in base.pairs(curr_actions) do v() end

    glob.time = glob.time + sec
    glob.curr_timedelta = sec
    glob.lastmillis = lastmillis

    log.log(log.INFO, "manage_actions: " .. base.tostring(sec))

    local ents = table.values(__entities_store)
    for i = 1, #ents do
        local ent = ents[i]
        local skip = false
        if ent.deactivated then skip = true end
        if not ent.should_act then skip = true end
        if not skip then
            if glob.CLIENT then
                ent:client_act(sec)
            else
                ent:act(sec)
            end
        end
    end
end

function render_dynamic(tp)
    log.log(log.INFO, "render_dynamic")

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

function render_hud_models()
    local ply = get_plyent()
    if ply.hud_modelname and ply.cs ~= 4 then -- 4 = cc.character.CSTATE.EDITING
        ply:render_dynamic(true, true)
    end
end

if glob.CLIENT then

function set_player_uid(uid)
    log.log(log.DEBUG, "Setting player uid to " .. base.tostring(uid))

    if uid then
        player_logent = get(uid)
        player_logent._controlled_here = true
        log.log(log.DEBUG, "Player _controlled_here:" .. base.tostring(player_logent._controlled_here))

        base.assert(not uid or player_logent)
    end
end

function get_plyent() return player_logent end

function set_statedata(uid, kproid, val)
    ent = get(uid)
    if ent then
        local key = msgsys.fromproid(base.tostring(ent), kproid)
        log.log(log.DEBUG, "set_statedata: " .. base.tostring(uid) .. ", " .. base.tostring(kproid) .. ", " .. base.tostring(key))
        ent:_set_statedata(key, val)
    end
end

function test_scenario_started()
    log.log(log.INFO, "Testing whether the scenario started ..")

    if not get_plyent() then
        log.log(log.INFO, ".. no, player logent not created yet.")
        return false
    end

    log.log(log.INFO, ".. player entity created.")

    ents = table.values(__entities_store)
    for i = 1, #ents do
        if not ents[i].initialized then
            log.log(log.INFO, ".. no, entity " .. base.tostring(ents[i].uid) .. " is not initialized.")
            return false
        end
    end

    log.log(log.INFO, ".. yes, scenario is running.")
    return true
end

end

if glob.SERVER then

function get_newuid()
    local r = 0
    uids = table.keys(__entities_store)
    for i = 1, #uids do
        r = math.max(r, uids[i])
    end
    r = r + 1
    log.log(log.DEBUG, "Generating new uid: " .. base.tostring(r))
    return r
end

function new(cl, kwargs, fuid, ruid)
    fuid = fuid or get_newuid()
    log.log(log.DEBUG, "New logent: " .. base.tostring(fuid))

    local r = add(cl, fuid, kwargs, true)

    return ruid and r.uid or r
end

function new_npc(cl)
    local npc = CAPI.npcadd(cl)
    npc._controlled_here = true
    return npc
end

function send_entities(cn)
    log.log(log.DEBUG, "Sending active logents to " .. base.tostring(cn))

    local numents = 0
    local ids = {}
    for k, v in base.pairs(__entities_store) do
        numents = numents + 1
        table.insert(ids, k) -- create the keys table immediately to not iterate twice later
    end
    table.sort(ids)

    msgsys.send(cn, CAPI.notify_numents, numents)
    for i = 1, #ids do
        __entities_store[ids[i]]:send_notification_complete(cn)
    end
end

function set_statedata(uid, kproid, val, auid)
    local ent = get(uid)
    if ent then
        local key = msgsys.fromproid(base.tostring(ent), kproid)
        ent:_set_statedata(key, val, auid)
    end
end

function load_entities(sents)
    log.log(log.DEBUG, "Loading entities .. " .. base.tostring(sents) .. ", " .. base.type(sents))

    local ents = json.decode(sents)
    for i = 1, #ents do
        log.log(log.DEBUG, "load_entities: " .. json.encode(ents[i]))
        local uid = ents[i][1]
        local cls = ents[i][2]
        local state_data = ents[i][3]
        log.log(log.DEBUG, "load_entities: " .. base.tostring(uid) .. ", " .. base.tostring(cls) .. ", " .. json.encode(state_data))

        if base.mapversion <= 30 and state_data.attr1 then
            if cls ~= "light" and cls ~= "flickering_light" and cls ~= "particle_effect" and cls ~= "envmap" then
                state_data.attr1 = (base.tonumber(state_data.attr1) + 180) % 360
            end
        end

        add(cls, uid, { state_data = json.encode(state_data) })
    end

    log.log(log.DEBUG, "Loading entities complete")
end

end

function save_entities()
    local r = {}
    log.log(log.DEBUG, "Saving entities ..:")

    local vals = table.values(__entities_store)
    for i = 1, #vals do
        if vals[i]._persistent then
            log.log(log.DEBUG, "Saving entity " .. base.tostring(vals[i].uid))
            local uid = vals[i].uid
            local cls = base.tostring(vals[i])
            -- TODO: store as serialized here, to save some parse/unparsing
            local state_data = vals[i]:create_statedatadict()
            table.insert(r, json.encode({ uid, cls, state_data }))
        end
    end

    log.log(log.DEBUG, "Saving entities complete.")
    return "[\n" .. table.concat(r, ",\n") .. "\n]\n\n"
end

-- Caching per glob.timestamp

function cache_by_global_timestamp(func)
    return function(...)
        if func.last_timestamp ~= glob.curr_timestamp then
            func.last_cached_val = func(...)
            func.last_timestamp = global.curr_timestamp
        end
        return func.last_cached_val
    end
end

CAPI.gettargetpos = cache_by_global_timestamp(CAPI.gettargetpos)
CAPI.gettargetent = cache_by_global_timestamp(CAPI.gettargetent)

rendering = {}
function rendering.setup_dynamic_test(ent)
    local current = ent
    ent.render_dynamic_test = cache_by_time_delay(function()
        local plycenter = get_plyent().center
        if current.position:sub_new(plycenter):magnitude() > 256 then
            if not util.haslineofsight(plycenter, current.position) then return false end
        end
        return true
    end, 1 / 3)
end
