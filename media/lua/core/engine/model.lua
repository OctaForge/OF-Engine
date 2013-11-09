--[[! File: lua/core/engine/model.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        Lua model API.
]]

local M = {}
if SERVER then return M end

local capi = require("capi")

local ran = capi.model_register_anim

--[[! Variable: anims
    An enumeration of all basic (pre-defined) animations available in the
    engine. Possible values are "mapmodel", "edit", "lag", "idle",
    "run_X", "jump", "jump_X", "sink", "swim", "crouch", "crouch_X",
    "crouch_jump", "crouch_jump_X", "crouch_sink", "crouch_swim" where
    "X" is either "N", "NE", "E", "SE", "S", "SW", "W", "NW" (specifying
    the direction - e.g. NE means north-east).

    There is also INDEX, which can be used with bitwise AND to retrieve
    just the animation from a combined animation/control integer.
]]
local anims = {
    mapmodel = ran "mapmodel", edit = ran "edit", lag = ran "lag",
    idle = ran "idle", INDEX = 0x1FF
}
M.anims = anims

local variants = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
local gen_anim_variants = function(bname, onlysuffix)
    if not onlysuffix then anims[bname] = ran(bname) end
    for i, v in ipairs(variants) do
        local nm = bname .. "_" .. v
        anims[nm] = ran(nm)
    end
end

gen_anim_variants("run", true)
gen_anim_variants "jump"

anims.sink = ran "sink"
anims.swim = ran "swim"

gen_anim_variants "crouch"
gen_anim_variants "crouch_jump"

anims.crouch_sink = ran "crouch_sink"
anims.crouch_swim = ran "crouch_swim"

--[[! Variable: anim_control
    Provides means to control the animation direction and looping. Contains
    LOOP, CLAMP, REVERSE, LOOPERV, CLAMPREV, START, END.
]]
M.anim_control = {:
    LOOP     = 1 << 9,
    CLAMP    = 1 << 10,
    REVERSE  = 1 << 11,
    LOOPREV  = LOOP  | REVERSE,
    CLAMPREV = CLAMP | REVERSE,
    START    = LOOP  | CLAMP,
    END      = LOOP  | CLAMP | REVERSE
:}

M.anim_flags = {:
    NOSKIN     = 1 << 0,
    SETTIME    = 1 << 1,
    FULLBRIGHT = 1 << 2,
    NORENDER   = 1 << 3,
    RAGDOLL    = 1 << 4,
    SETSPEED   = 1 << 5,
    NOPITCH    = 1 << 6
:}

--[[! Variable: render_flags
    Contains flags for model rendering. CULL_VFC is a view frustrum culling
    flag, CULL_DIST is a distance culling flag, CULL_OCCLUDED is an occlusion
    culling flag, CULL_QUERY is hw occlusion queries flag, FULLBRIGHT makes
    the model fullbright, NORENDER disables rendering, MAPMODEL is a mapmodel
    flag, NOBATCH disables batching on the model.
]]
M.render_flags = {:
    CULL_VFC   = 1 << 0, CULL_DIST  = 1 << 1, CULL_OCCLUDED = 1 << 2,
    CULL_QUERY = 1 << 3, FULLBRIGHT = 1 << 4, NORENDER      = 1 << 5,
    MAPMODEL   = 1 << 6, NOBATCH    = 1 << 7
:}

--[[! Function: register_anim
    Registers an animation of the given name. Returns the animation number
    that you can then use. If an animation of the same name already exists,
    it just returns its number. It also returns a second boolean value that
    is true when the animation was actually newly registered and false when
    it just re-returned an already existing animation.
]]
M.register_anim = ran

--[[! Function: get_anim
    Returns the animation number for the given animation name. If no such
    animation exists, returns nil.
]]
M.get_anim = capi.model_get_anim

--[[! Function: find_anims
    Finds animations whose names match the given pattern. It's a regular
    Lua pattern. It also accepts integers (as in animation numbers). It
    returns an array of all animation numbers that match the input. The
    result is sorted.
]]
local find_anims = capi.model_find_anims

--[[! Function: clear
    Clears a model with a name given by the argument (which is relative
    to media/model) and reloads.
]]
M.clear = capi.model_clear

--[[! Function: preload
    Adds a model into the preload queue for faster loading. Name is
    again relative to media/model.
]]
M.preload = capi.model_preload

local mrender = capi.model_render

--[[! Function: render
    Renders a model. Takes the entity which owns the model, the model name
    (relative to media/model), animation (see above), animation flags,
    position (vec3), yaw, pitch, roll, flags (see render_flags), basetime
    (start_time) and color (vec4).
]]
M.render = function(ent, mdl, anim, animflags, pos, yaw, pitch, roll, flags,
btime, trans)
    local r, g, b, a = 1, 1, 1, 1
    if trans then
        r, g, b, a = trans.r, trans.g, trans.b, trans.a
    end
    mrender(ent.uid, mdl, anim[1], anim[2], animflags, pos.x, pos.y, pos.z,
        yaw, pitch, roll, flags, btime, r, g, b, a)
end

--[[! Function: get_bounding_box
    Returns the bounding box of the given model as two vec3, center and
    radius.
]]
M.get_bounding_box = capi.model_get_boundbox

--[[! Function: get_collision_box
    Returns the collision box of the given model as two vec3, center and
    radius.
]]
M.get_collision_box = capi.model_get_collisionbox

--[[! Function: get_mesh
    Returns the mesh information about the given model as a table.
    It contains information about each triangle. The return value
    is a table (an array) which contains tables (representing triangles).
    The triangles are associative arrays with members a, b, c where a,
    b, c are vec3.
]]
M.get_mesh = capi.model_get_mesh

return M
