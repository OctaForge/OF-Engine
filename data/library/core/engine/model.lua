--[[! File: library/core/engine/model.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua model API.
]]

local M = {}

local reganim = _C.model_register_anim

--[[! Variable: anims
    An enumeration of all basic (pre-defined) animations available in the
    engine. Possible values are DEAD, DYING, IDLE, FORWARD, BACKWARD, LEFT,
    RIGHT, JUMP, SINK, SWIM, EDIT, LAG, MAPMODEL.

    Then there are modifiers, INDEX, LOOP, START, END, REVERSE, SECONDARY
    that you won't find much use for and a special anim type RAGDOLL.
]]
M.anims = {
    DEAD = reganim "dead", DYING = reganim "dying", IDLE = reganim "idle",
    FORWARD = reganim "forward", BACKWARD = reganim "backward",
    LEFT = reganim "left", RIGHT = reganim "right", JUMP = reganim "jump",
    SINK = reganim "sink", SWIM = reganim "swim", EDIT = reganim "edit",
    LAG = reganim "lag", MAPMODEL = reganim "mapmodel",

    INDEX = 0x7F,
    LOOP = math.lsh(1, 7),
    START = math.lsh(1, 8),
    END = math.lsh(1, 9),
    REVERSE = math.lsh(1, 10),
    SECONDARY = 11,

    RAGDOLL = math.lsh(1, 27)
}

--[[! Variable: render_flags
    Contains flags for model rendering. CULL_VFC is a view frustrum culling
    flag, CULL_DIST is a distance culling flag, CULL_OCCLUDED is an occlusion
    culling flag, CULL_QUERY is hw occlusion queries flag, FULLBRIGHT makes
    the model fullbright, NORENDER disables rendering, MAPMODEL is a mapmodel
    flag, NOBATCH disables batching on the model.
]]
M.render_flags = {
    CULL_VFC = math.lsh(1, 0), CULL_DIST = math.lsh(1, 1),
    CULL_OCCLUDED = math.lsh(1, 2), CULL_QUERY = math.lsh(1, 3),
    FULLBRIGHT = math.lsh(1, 4), NORENDER = math.lsh(1, 5),
    MAPMODEL = math.lsh(1, 6), NOBATCH = math.lsh(1, 7)
}

--[[! Function: register_anim
    Registers an animation of the given name. Returns the animation number
    that you can then use. Currently up to 127 animations can be registered.
    If an animation of the same name already exists, it just returns its
    number.
]]
M.register_anim = reganim

--[[! Function: get_anim
    Returns the animation number for the given animation name. If no such
    animation exists, returns nil.
]]
M.get_anim = _C.model_get_anim

--[[! Function: find_anims
    Finds animations whose names match the given pattern. It's a regular
    Lua pattern. It also accepts integers (as in animation numbers). It
    returns an array of all animation numbers that match the input. The
    result is sorted.
]]
local find_anims = _C.model_find_anims

--[[! Function: clear
    Clears a model with a name given by the argument (which is relative
    to data/models).
]]
M.clear = _C.model_clear

--[[! Function: preload
    Adds a model into the preload queue for faster loading. Name is
    again relative to data/models.
]]
M.preload = _C.model_preload

--[[! Function: reload
    Reloads the given model. Basically clears and loads again.
]]
M.reload = _C.model_reload

local mrender = _C.model_render

--[[! Function: render
    Renders a model. Takes the entity which owns the model, the model name
    (relative to data/models), animation (see above), position (vec3), yaw,
    pitch, flags (see render_flags), basetime (start_time) and trans (which
    is model transparency that ranges from 0 to 1 and defaults to 1).
]]
M.render = function(ent, mdl, anim, pos, yaw, pitch, flags, basetime, trans)
    mrender(ent, mdl, anim, pos.x, pos.y, pos.z, yaw, pitch, flags,
        basetime, trans)
end

--[[! Function: get_bounding_box
    Returns the bounding box of the given model as two vec3, center and
    radius.
]]
M.get_bounding_box = _C.model_get_boundbox

--[[! Function: get_collision_box
    Returns the collision box of the given model as two vec3, center and
    radius.
]]
M.get_collision_box = _C.model_get_collisionbox

--[[! Function: get_mesh
    Returns the mesh information about the given model as a table.
    It contains information about each triangle. The return value
    is a table (an array) which contains tables (representing triangles).
    The triangles are associative arrays with members a, b, c where a,
    b, c are vec3.
]]
M.get_mesh = _C.model_get_mesh

return M
