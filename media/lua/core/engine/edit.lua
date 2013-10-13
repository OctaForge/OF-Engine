--[[! File: lua/core/engine/edit.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Editing functions including procedural geometry generation.
]]

local capi = require("capi")
local ffi = require("ffi")

local ffi_new = ffi.new

local M = {}

-- undocumented, not exposed for the time being
local matf = {:
    INDEX_SHIFT  = 0,
    VOLUME_SHIFT = 2,
    CLIP_SHIFT   = 5,
    FLAG_SHIFT   = 8,

    INDEX  = 3 << INDEX_SHIFT,
    VOLUME = 7 << VOLUME_SHIFT,
    CLIP   = 7 << CLIP_SHIFT,
    FLAGS  = 0xFF << FLAG_SHIFT
:}

--[[! Variable: material
    Represents material ids present in the engine. Contains values AIR,
    WATER, LAVA, GLASS, NOCLIP, CLIP, GAMECLIP, DEATH and ALPHA.
]]
M.material = {:
    AIR      = 0,
    WATER    = 1 << matf.VOLUME_SHIFT,
    LAVA     = 2 << matf.VOLUME_SHIFT,
    GLASS    = 3 << matf.VOLUME_SHIFT,

    NOCLIP   = 1 << matf.CLIP_SHIFT,
    CLIP     = 2 << matf.CLIP_SHIFT,
    GAMECLIP = 3 << matf.CLIP_SHIFT,

    DEATH    = 1 << matf.FLAG_SHIFT,
    ALPHA    = 4 << matf.FLAG_SHIFT
:}

--[[! Function: add_npc
    Adds a bot into the world onto the starting position. Bots are considered
    clients. You can define their AI via their entity class. This is purely
    serverside. Takes the entity class name the bot should be. Returns the bot
    entity.
]]
M.add_npc = capi.npcadd

--[[! Function: delete_npc
    Deletes a bot. Takes the entity, returns nothing. Purely serverside.
]]
M.delete_npc = function(ent) capi.npcdel(ent.uid) end

--[[! Function: new_entity
    Creates a new entity on the position where the edit cursor is aiming.
    Takes the entity class name as an argument. Also callable from cubescript
    as newent. Clientside.
]]
M.new_entity = capi.new_entity

--[[! Function: get_material
    Returns what material is on the position given by the argument.
    Materials are represented by <material> fields.
]]
M.get_material = function(o)
    return capi.getmat(o.x, o.y, o.z)
end

--[[! Function: map_erase
    Clears all the map geometry.
]]
M.map_erase = capi.edit_map_erase

--[[! Function: cube_create
    Creates a cube with the given parameters. Please note that not all
    positions are sufficient for creating cubes, you need to fit into the grid.

    For example, when you have coords 512, 512, 512 and cube of size 64, it's
    fine, because it can fit in. But if you change the coords to 1, 1, 1, only
    cube of size 1 can fit there.

    The coordinates also have to fit in the world, so mapsize. Takes the x,
    y, z coordinates and the gridsize (which is 1<<gridpower).

    Returns true on success, false on failure (same goes for all following
    functions).

    Note that this function and the following ones are safe and validated
    (they also sync client-server). There is a more "raw" set down below
    that operates directly with the structures - it's faster (and much
    more powerful), but often also less convenient.
]]
M.cube_create = capi.edit_cube_create

--[[! Function: cube_delete
    Parameters and rules are the same as for <cube_create>, but it actually
    deletes cubes instead of creating.
]]
M.cube_delete = capi.edit_cube_delete

--[[! Function: cube_set_texture
    First 4 arguments are the same as in <cube_create>, the fifth argument is
    the face, sixth is the texture slot number. See also <cube_set_material>.

    If we're standing in the center of the map, with increasing X coordinate
    when going right and increasing Y coordinate when going forward, the
    faces go like this:

    Faces:
        0 - right side of the cube
        1 - left side of the cube
        2 - back of the cube
        3 - front of the cube
        4 - bottom of the cube
        5 - top of the cube
]]
M.cube_set_texture = capi.edit_cube_set_texture

--[[! Function: cube_set_material
    First 4 arguments are the same as in <cube_create>, the fifth argument is
    the material index, see <get_material>. See also <cube_set_texture>.
]]
M.cube_set_material = capi.edit_cube_set_material

--[[! Function: cube_vrotate
    Like vrotate, arguments are x, y, z, gridsize, face followed
    by vrotate arguments.
]]
M.cube_vrotate = capi.cube_vrotate

--[[! Function: cube_voffset
    Like voffset, arguments are x, y, z, gridsize, face followed
    by voffset arguments.
]]
M.cube_voffset = capi.cube_voffset

--[[! Function: cube_vscroll
    Like vscroll, arguments are x, y, z, gridsize, face followed
    by vscroll arguments.
]]
M.cube_vscroll = capi.cube_vscroll

--[[! Function: cube_vscale
    Like vscale, arguments are x, y, z, gridsize, face followed
    by vscale arguments.
]]
M.cube_vscale = capi.cube_vscale

--[[! Function: cube_vlayer
    Like vlayer, arguments are x, y, z, gridsize, face followed
    by vlayer arguments.
]]
M.cube_vlayer = capi.cube_vlayer

--[[! Function: cube_vdecal
    Like vdecal, arguments are x, y, z, gridsize, face followed
    by vdecal arguments.
]]
M.cube_vdecal = capi.cube_vdecal

--[[! Function: cube_valpha
    Like valpha, arguments are x, y, z, gridsize, face followed
    by valpha arguments.
]]
M.cube_valpha = capi.cube_valpha

--[[! Function: cube_vcolor
    Like vcolor, arguments are x, y, z, gridsize, face followed
    by vcolor arguments.
]]
M.cube_vcolor = capi.cube_vcolor

--[[! Function: cube_vrefract
    Like vrefract, arguments are x, y, z, gridsize, face followed
    by vrefract arguments.
]]
M.cube_vrefract = capi.cube_vrefract

--[[! Function: cube_push_corner
    First 5 arguments are the same with <cube_set_texture>, the sixth argument
    is the corner index, the seventh is the direction (1 into the cube,
    -1 from the cube).

    On all faces, 0 is top-left corner, 1 is top-right, 2 is bottom-left and 3
    is bottom-right when facing them directly (that is, when we see the texture
    in the right orientation).
]]
M.cube_push_corner = capi.edit_cube_push_corner

--[[! Function: remip
    Remips the map.
]]
M.remip = capi.edit_raw_remip

ffi.cdef [[
    typedef struct selinfo_t {
        int corner;
        int cx, cxs, cy, cys;
        struct { int x, y, z; } position, selection;
        int grid_size, orientation;
    } selinfo_t;

    typedef struct vslot_t {
        int flags;
        int rotation;
        int offset_x, offset_y;
        float scroll_s, scroll_t;
        float scale;
        int layer, decal;
        float alpha_front, alpha_back;
        float r, g, b;
        float refract_scale;
        float refract_r, refract_g, refract_b;
    } vslot_t;
]]

local edit_raw_edit_face, edit_raw_delete_cube, edit_raw_edit_texture,
edit_raw_edit_material, edit_raw_flip, edit_raw_rotate, edit_raw_edit_vslot,
edit_get_world_size in capi

local clamp = require("core.lua.math").clamp

--[[! Struct: Selection
    Represents a selection structure that can be used for procedural editing.
    It's faster and more powerful than the functions above but also more
    dangerous.

    It has several fields:
        corner - the face corner the pointer is the closest to, for a face
        from above 0 is to the origin and 2 is across from 1 (you fill one
        row and then fill the next row starting from the same side)
        position - has 3 integer fields, x, y, z, represents the current
        cube origin.
        selection - has 3 integer fields x, y, z and represents the selection
        size in cubes (1, 1, 1 is one cube)
        grid_size - the current grid size (1 << gridpower)
        orientation - the face orientation, if 0, 0, 0 is in the lower left
        and the cube extends from us in the other axis, then:
            0 - facing us
            1 - away from us
            2 - left
            3 - right
            4 - down
            5 - up
]]
M.Selection = ffi.metatype("selinfo_t", {
    __eq = function(self, other)
        local pos, sel = self.position, self.selection
        local opos, osel = other.position, other.selection
        return  pos.x == opos.x and pos.y == opos.y and pos.z == opos.z
            and sel.x == osel.x and sel.y == osel.y and sel.z == osel.z
            and self.grid_size == other.grid_size
            and self.orientation == other.orientation
    end,

    __index = {
        --[[! Function: edit_face
            Edits a face of the selection. The argument "dir" specifies the
            direction (-1 extrudes, 1 pushes back into, for corners/edges
            1 is into the cube, -1 is back out), the argument "mode" specifies
            whether to extrude/push back cubes (1) or corners (2).

            The argument "local" specifies whether the change was initiated
            here (so whether to notify others). It defaults to true but you
            can force it as false if you know what you're doing and it's really
            what you want.

            The argument "local" is present on all editing methods here.
        ]]
        edit_face = function(self, dir, mode, loc)
            if loc != false then loc = true end
            edit_raw_edit_face(dir, mode, self, loc)
        end,

        --[[! Function: delete
            Deletes the selection.
        ]]
        delete = function(self, loc)
            if loc != false then loc = true end
            edit_raw_delete_cube(self, loc)
        end,

        --[[! Function: edit_texture
            Changes the texture for the given face. Takes the texture slot
            id and optionally a boolean specifying whether to change the
            texture on all faces (false by default).
        ]]
        edit_texture = function(self, tex, all_faces, loc)
            if loc != false then loc = true end
            edit_raw_edit_texture(tex, all_faces or false, self, loc)
        end,

        --[[! Function: edit_texture
            Edits the material in the current selection. Takes the material id.
        ]]
        edit_material = function(self, mat, loc)
            if loc != false then loc = true end
            edit_raw_edit_material(mat, self, loc)
        end,

        --[[! Function: flip
            Flips the selection.
        ]]
        flip = function(self, loc)
            if loc != false then loc = true end
            edit_raw_flip(self, loc)
        end,

        --[[! Function: rotate
            Rotates the selection, the argument is the same as with normal
            rotation in cubescript.
        ]]
        rotate = function(self, cw, loc)
            if loc != false then loc = true end
            edit_raw_rotate(cw, self, loc)
        end,

        --[[! Function: edit_vslot
            Edits the vslot in the given selection. Takes the vslot
            and optionally an all_faces boolean (defaults to false).
        ]]
        edit_vslot = function(self, vs, all_faces, loc)
            if loc != false then loc = true end
            edit_raw_edit_vslot(vs, all_faces or false, self, loc)
        end,

        --[[! Function: get_size
            Returns the selection size in terms of number of cubes.
        ]]
        get_size = function(self)
            local sel = self.selection
            return sel.x * sel.y * sel.z
        end,

        --[[! Function: validate
            Validates the selection and returns true if it's valid and
            false if it's not.
        ]]
        validate = function(self)
            local world_size = edit_get_world_size()
            local grid = self.grid_size
            if grid <= 0 or grid >= world_size then return false end
            local o, s = self.position, self.selection
            if o.x >= world_size or o.y >= world_size
            or o.z >= world_size then return false end
            if o.x < 0 then s.x, o.x = s.x - (grid - 1 - o.x) / grid, 0 end
            if o.y < 0 then s.y, o.y = s.y - (grid - 1 - o.y) / grid, 0 end
            if o.z < 0 then s.z, o.z = s.z - (grid - 1 - o.z) / grid, 0 end
            s.x = clamp(s.x, 0, (world_size - o.x) / grid)
            s.y = clamp(s.y, 0, (world_size - o.y) / grid)
            s.z = clamp(s.z, 0, (world_size - o.z) / grid)
            return s.x > 0 and s.y > 0 and s.z > 0
        end
    }
})

--[[! Variable: vslot_flags
    Represents all flags that can be enabled on a vslot used later with
    the procedural API. Contains SCALE, ROTATION, OFFSET, SCROLL, LAYER,
    ALPHA, COLOR, REFRACTION and DECAL, mapping to the respective vcommand
    actions.
]]
M.vslot_flags = {:
    SCALE      = 1 << 1,
    ROTATION   = 1 << 2,
    OFFSET     = 1 << 3,
    SCROLL     = 1 << 4,
    LAYER      = 1 << 5,
    ALPHA      = 1 << 6,
    COLOR      = 1 << 7,
    REFRACTION = 1 << 9,
    DECAL      = 1 << 10
:}

--[[! Struct: VSlot
    Represents a vslot for the procedural API. You can enable flags on it
    (see <vslot_flags>). Every flag has its associated field (or fields)
    in the structure. The fields are rotation (int), offset_x, offset_y
    (both ints), scroll_s, scroll_t (floats), scale (float), layer, decal
    (ints), alpha_front, alpha_back, r, g, b, refract_scale, refract_r,
    refract_g, refract_b (all floats).

    These values map to the respective vcommand parameters.
]]
M.VSlot = ffi.metatype("vslot_t", {
    __index = {
    }
})

return M
