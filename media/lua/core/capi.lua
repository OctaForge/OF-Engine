--[[!<
    This file patches some of the core API.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")
local ffi = require("ffi")

local ffi_new = ffi.new

local gen_getwrap = function(fun, tp)
    local tpnm = tp .. "[1]"
    return function(ent)
        local stor = ffi_new(tpnm)
        if not fun(ent, stor) then return nil end
        return stor[0]
    end
end

capi.get_start_time = gen_getwrap(capi.get_start_time, "int")

local get_attr in capi
capi.get_attr = function(ent, id)
    local stor = ffi_new("int[1]")
    if not get_attr(ent, id, stor) then return nil end
    return stor[0]
end

local get_start_time in capi
capi.get_start_time = function(ent)
    local stor = ffi_new("int[1]")
    if not get_start_time(ent, stor) then return nil end
    return stor[0]
end

local get_extent_position, set_extent_position in capi

capi.get_extent_position = function(ent)
    local stor = ffi_new("double[3]")
    if not get_extent_position(ent, stor) then return nil end
    return { stor[0], stor[1], stor[2] }
end

capi.set_extent_position = function(ent, pos)
    set_extent_position(ent, pos[1], pos[2], pos[3])
end

capi.get_maxspeed = gen_getwrap(capi.get_maxspeed, "float")
capi.get_crouchtime = gen_getwrap(capi.get_crouchtime, "int")
capi.get_radius = gen_getwrap(capi.get_radius, "float")
capi.get_eyeheight = gen_getwrap(capi.get_eyeheight, "float")
capi.get_maxheight = gen_getwrap(capi.get_maxheight, "float")
capi.get_crouchheight = gen_getwrap(capi.get_crouchheight, "float")
capi.get_crouchspeed = gen_getwrap(capi.get_crouchspeed, "float")
capi.get_jumpvel = gen_getwrap(capi.get_jumpvel, "float")
capi.get_gravity = gen_getwrap(capi.get_gravity, "float")
capi.get_aboveeye = gen_getwrap(capi.get_aboveeye, "float")
capi.get_yaw = gen_getwrap(capi.get_yaw, "float")
capi.get_pitch = gen_getwrap(capi.get_pitch, "float")
capi.get_roll = gen_getwrap(capi.get_roll, "float")
capi.get_move = gen_getwrap(capi.get_move, "int")
capi.get_strafe = gen_getwrap(capi.get_strafe, "int")
capi.get_yawing = gen_getwrap(capi.get_yawing, "int")
capi.get_crouching = gen_getwrap(capi.get_crouching, "int")
capi.get_pitching = gen_getwrap(capi.get_pitching, "int")
capi.get_jumping = gen_getwrap(capi.get_jumping, "bool")
capi.get_blocked = gen_getwrap(capi.get_blocked, "bool")
capi.get_mapdefinedposdata = gen_getwrap(capi.get_mapdefinedposdata, "uint")
capi.get_clientstate = gen_getwrap(capi.get_clientstate, "int")
capi.get_physstate = gen_getwrap(capi.get_physstate, "int")
capi.get_inwater = gen_getwrap(capi.get_inwater, "int")
capi.get_timeinair = gen_getwrap(capi.get_timeinair, "int")

local get_dynent_position, set_dynent_position in capi

capi.get_dynent_position = function(ent)
    local stor = ffi_new("double[3]")
    if not get_dynent_position(ent, stor) then return nil end
    return { stor[0], stor[1], stor[2] }
end

capi.set_dynent_position = function(ent, pos)
    set_dynent_position(ent, pos[1], pos[2], pos[3])
end

local get_dynent_velocity, set_dynent_velocity in capi

capi.get_dynent_velocity = function(ent)
    local stor = ffi_new("double[3]")
    if not get_dynent_velocity(ent, stor) then return nil end
    return { stor[0], stor[1], stor[2] }
end

capi.set_dynent_velocity = function(ent, vel)
    set_dynent_velocity(ent, vel[1], vel[2], vel[3])
end

local get_dynent_falling, set_dynent_falling in capi

capi.get_dynent_falling = function(ent)
    local stor = ffi_new("double[3]")
    if not get_dynent_falling(ent, stor) then return nil end
    return { stor[0], stor[1], stor[2] }
end

capi.set_dynent_falling = function(ent, fl)
    set_dynent_falling(ent, fl[1], fl[2], fl[3])
end

if not SERVER then
    local get_target_entity_uid in capi
    capi.get_target_entity_uid = function()
        local stor = ffi_new("int[1]")
        if not get_target_entity_uid(stor) then return nil end
        return stor[0]
    end
end

capi.get_ping = gen_getwrap(capi.get_ping, "int")
capi.get_plag = gen_getwrap(capi.get_plag, "int")

local ffi_str = ffi.string

local strftime in capi
capi.strftime = function(fmt)
    local buf = ffi_new("char[512]")
    if not strftime(buf, 512, fmt) then return nil end
    return ffi_str(buf)
end

if not SERVER then
    local dynlight_add, dynlight_add_spot in capi

    capi.dynlight_add = function(ox, oy, oz, radius, r, g, b, fade, peak,
    flags, initrad, ir, ig, ib, ent)
        return dynlight_add(ox, oy, oz, radius, r, g, b, fade or 0, peak or 0,
            flags or 0, initrad or 0, ir or 0, ig or 0, ib or 0,
            ent and ent.uid or -1)
    end

    capi.dynlight_add_spot = function(ox, oy, oz, dx, dy, dz, radius, spot,
    r, g, b, fade, peak, flags, initrad, ir, ig, ib, ent)
        return dynlight_add_spot(ox, oy, oz, dx, dy, dz, radius, r, g, b,
            fade or 0, peak or 0, flags or 0, initrad or 0, ir or 0, ig or 0,
            ib or 0, ent and ent.uid or -1)
    end

    local getfps in capi

    capi.getfps = function()
        local stor = ffi_new("int[3]")
        getfps(stor)
        return stor[0], stor[1], stor[2]
    end

    local slot_get_name in capi

    capi.slot_get_name = function(idx, subslot)
        local str = slot_get_name(idx, subslot)
        if str != nil then return ffi_str(str) end
    end

    local input_get_key_name in capi

    capi.input_get_key_name = function(n)
        return ffi_str(input_get_key_name(n))
    end

    local camera_get_position, camera_get in capi

    capi.camera_get_position = function()
        local stor = ffi_new("float[3]")
        camera_get_position(stor)
        return stor[0], stor[1], stor[2]
    end

    capi.camera_get = function()
        local stor = ffi_new("float[6]")
        camera_get(stor)
        return stor[0], stor[1], stor[2], stor[3], stor[4], stor[5]
    end

    local text_get_res in capi

    capi.text_get_res = function(w, h)
        local stor = ffi_new("int[2]")
        text_get_res(w, h, stor)
        return stor[0], stor[1]
    end

    local text_get_bounds, text_get_boundsf in capi

    capi.text_get_bounds = function(text, maxw)
        local stor = ffi_new("int[2]")
        text_get_bounds(text, maxw, stor)
        return stor[0], stor[1]
    end

    capi.text_get_boundsf = function(text, maxw)
        local stor = ffi_new("float[2]")
        text_get_boundsf(text, maxw, stor)
        return stor[0], stor[1]
    end

    local text_get_position, text_get_positionf in capi

    capi.text_get_position = function(text, cursor, maxw)
        local stor = ffi_new("int[2]")
        text_get_position(text, cursor, maxw, stor)
        return stor[0], stor[1]
    end

    capi.text_get_positionf = function(text, cursor, maxw)
        local stor = ffi_new("float[2]")
        text_get_positionf(text, cursor, maxw, stor)
        return stor[0], stor[1]
    end
end
