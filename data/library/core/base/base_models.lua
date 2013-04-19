--[[!
    File: library/core/base/base_models.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features model interface. Some bits of documentation
        are taken from "Sauerbraten model reference".
]]

local base = _G

--! Variable: ANIM_DEAD
ANIM_DEAD = 0
--! Variable: ANIM_DYING
ANIM_DYING = 1
--! Variable: ANIM_IDLE
ANIM_IDLE = 2
--! Variable: ANIM_FORWARD
ANIM_FORWARD = 3
--! Variable: ANIM_BACKWARD
ANIM_BACKWARD = 4
--! Variable: ANIM_LEFT
ANIM_LEFT = 5
--! Variable: ANIM_RIGHT
ANIM_RIGHT = 6
--! Variable: ANIM_HOLD1
ANIM_HOLD1 = 7
--! Variable: ANIM_HOLD2
ANIM_HOLD2 = 8
--! Variable: ANIM_HOLD3
ANIM_HOLD3 = 9
--! Variable: ANIM_HOLD4
ANIM_HOLD4 = 10
--! Variable: ANIM_HOLD5
ANIM_HOLD5 = 11
--! Variable: ANIM_HOLD6
ANIM_HOLD6 = 12
--! Variable: ANIM_HOLD7
ANIM_HOLD7 = 13
--! Variable: ANIM_ATTACK1
ANIM_ATTACK1 = 14
--! Variable: ANIM_ATTACK2
ANIM_ATTACK2 = 15
--! Variable: ANIM_ATTACK3
ANIM_ATTACK3 = 16
--! Variable: ANIM_ATTACK4
ANIM_ATTACK4 = 17
--! Variable: ANIM_ATTACK5
ANIM_ATTACK5 = 18
--! Variable: ANIM_ATTACK6
ANIM_ATTACK6 = 19
--! Variable: ANIM_ATTACK7
ANIM_ATTACK7 = 20
--! Variable: ANIM_PAIN
ANIM_PAIN = 21
--! Variable: ANIM_JUMP
ANIM_JUMP = 22
--! Variable: ANIM_SINK
ANIM_SINK = 23
--! Variable: ANIM_SWIM
ANIM_SWIM = 24
--! Variable: ANIM_EDIT
ANIM_EDIT = 25
--! Variable: ANIM_LAG
ANIM_LAG = 26
--! Variable: ANIM_TAUNT
ANIM_TAUNT = 27
--! Variable: ANIM_WIN
ANIM_WIN = 28
--! Variable: ANIM_LOSE
ANIM_LOSE = 29
--! Variable: ANIM_GUN_IDLE
ANIM_GUN_IDLE = 30
--! Variable: ANIM_GUN_SHOOT
ANIM_GUN_SHOOT = 31
--! Variable: ANIM_VWEP_IDLE
ANIM_VWEP_IDLE = 32
--! Variable: ANIM_VWEP_SHOOT
ANIM_VWEP_SHOOT = 33
--! Variable: ANIM_SHIELD
ANIM_SHIELD = 34
--! Variable: ANIM_POWERUP
ANIM_POWERUP = 35
--! Variable: ANIM_MAPMODEL
ANIM_MAPMODEL = 36
--! Variable: ANIM_TRIGGER
ANIM_TRIGGER = 37
--! Variable: NUMANIMS
NUMANIMS = 38

--! Variable: ANIM_INDEX
ANIM_INDEX = 0x7F
--! Variable: ANIM_LOOP
ANIM_LOOP = math.lsh(1, 7)
--! Variable: ANIM_START
ANIM_START = math.lsh(1, 8)
--! Variable: ANIM_END
ANIM_END = math.lsh(1, 9)
--! Variable: ANIM_REVERSE
ANIM_REVERSE = math.lsh(1, 10)
--! Variable: ANIM_SECONDARY
ANIM_SECONDARY = 11

--! Variable: ANIM_RAGDOLL
ANIM_RAGDOLL = math.lsh(1, 27)

--[[!
    Package: model
    This module controls models. OctaForge currently supports 5 model formats,
    md3, md5, smd, iqm and obj. This as well handles some variables for
    culling, shadowing etc., general model manipulation and ragdoll control.
]]
module("model", package.seeall)
--[[!
    Variable: CULL_VFC
    View frustrum culling flag for <render>.

    See also:
        <CULL_DIST>
        <CULL_OCCLUDED>
        <CULL_QUERY>
]]
CULL_VFC = math.lsh(1, 0)

--[[!
    Variable: CULL_DIST
    Distance culling flag for <render>.

    See also:
        <CULL_VFC>
        <CULL_OCCLUDED>
        <CULL_QUERY>
]]
CULL_DIST = math.lsh(1, 1)

--[[!
    Variable: CULL_OCCLUDED
    Occlusion culling flag for <render>.

    See also:
        <CULL_VFC>
        <CULL_DIST>
        <CULL_QUERY>
]]
CULL_OCCLUDED = math.lsh(1, 2)

--[[!
    Variable: CULL_QUERY
    Hardware occlusion queries flag for <render>.

    See also:
        <CULL_VFC>
        <CULL_DIST>
        <CULL_OCCLUDED>
]]
CULL_QUERY = math.lsh(1, 3)

--[[!
    Variable: FULLBRIGHT
    A flag for <render> that gives the model fullbright.
]]
FULLBRIGHT = math.lsh(1, 4)

--[[!
    Variable: NORENDER
]]
NORENDER = math.lsh(1, 5)

--[[!
    Variable: MAPMODEL
]]
MAPMODEL = math.lsh(1, 6)

--[[!
    Variable: NOBATCH
]]
NOBATCH = math.lsh(1, 7)

--[[!
    Function: clear
    Clears a model with a name given by the argument. Name is a
    path relative to the data/models directory (i.e. "foo/bar"
    means "data/models/foo/bar").
]]
clear = _C.clearmodel

--[[!
    Function: preload
    Preloads a model with a name given by the argument. Useful for
    pre-caching models you know will be loaded. Name is a path
    relative to the data/models directory (i.e. "foo/bar" means
    "data/models/foo/bar").
]]
preload = _C.preloadmodel

--[[!
    Function: reload
    See <clear>. The argument is the same, this basically clears
    and loads again.
]]
reload = _C.reloadmodel

--[[!
    Function: render
    Renders a model.

    Parameters:
        entity - the entity the model belongs to.
        name - name of the model we're loading. It's a path
        relative to the data/models directory (i.e. "foo/bar" means
        "data/models/foo/bar").
        animation - model animation, see <actions>, the ANIM_*
        variables.
        position - position of the model in the world represented
        as <vec3>.
        yaw - model yaw.
        pitch - model pitch.
        flags - various model flags for i.e. occlusion and lighting,
        see the flags above. Use <math.bor> to join them.
        base_time - entity's start_time property.
]]
render = function(ent, mdl, anim, pos, yaw, pitch, flags, basetime, trans)
    _C.model_render(ent, mdl, anim, pos.x, pos.y, pos.z, yaw, pitch,
        flags, basetime, trans)
end

--[[!
    Function: find_animations
    Finds all animations of the model given by the argument (string,
    in the same format as in <render>) and returns them as an array
    of numbers (see <actions>, the ANIM_* variables).
]]
find_animations = _C.findanims

--[[!
    Function: attachment
    Given two strings, first one being a model tag and second one
    being a model attachment, this function returns a full
    attachment string that can be then used in "attachments"
    property of entities.
]]
function attachment(t, n)
    assert(not string.find(t, ","))
    assert(not string.find(n, ","))
    return t .. "," .. n
end

--[[!
    Function: get_bounding_box
    Returns a Lua table in format

    (start code)
        {
            center = center,
            radius = radius
        }
    (end)

    where "center" and "radius" are <vec3>'s representing
    bounding box of a model with a name given by the argument.

    If the model can't be loaded, nil gets returned.
]]
get_bounding_box = _C.model_get_boundbox

--[[!
    Function: get_collision_box
    See <get_bounding_box>.
]]
get_collision_box = _C.model_get_collisionbox

--[[!
    Function: get_model_info
    Returns a Lua table with the information about
    model with a name given by the argument.

    The return value is a table and contains the amount
    of triangles and information about each triangle.

    Example:
        (start code)
            {
                length = 3
                0 = { a = A, b = B, c = C }
                1 = { a = A, b = B, c = C }
                2 = { a = A, b = B, c = C }
            }
        (end)
]]
get_model_info = _C.model_get_mesh
