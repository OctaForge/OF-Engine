--[[!
    File: library/core/base/base_editing.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides interface to map editing system.
]]

--[[!
    Package: edit
    A module containing everything you need to do various changes to
    the map, including procedural editing interface, materials and
    others.
]]
module("edit", package.seeall)

--[[!
    Function: add_npc
    Adds a NPC (a bot) onto a starting position
    in the world. Bots are considered actual clients.
    You can further define AI for bots.

    Note that this is server only command, so run it
    inside "if SERVER" block in your map script or in
    some other serverside function.

    Parameters:
        class - the entity class the NPC should be.
        Usual "player" works, but you'll mostly want
        to define a custom class.

    Returns:
        The NPC entity instance.

    See Also:
        <delete_npc>
]]
add_npc = CAPI.npcadd

--[[!
    Function: delete_npc
    Deletes a given NPC. See <add_npc>. Accepts
    return value of <add_npc> as an argument.

    Again, this is a server command.
]]
delete_npc = CAPI.npcdel

--[[!
    Function: new_entity
    Spawns a static entity in the world on position
    where edit cursor is aiming.

    Parameters:
        class - the entity class name.
]]
new_entity = CAPI.spawnent

--[[!
    Function: get_material
    Returns what material is on the position given by argument.
    Materials are represented by <MATERIAL_AIR>, <MATERIAL_WATER>,
    <MATERIAL_LAVA>, <MATERIAL_GLASS>, <MATERIAL_NOCLIP> and
    <MATERIAL_CLIP>.
]]
get_material = function(o)
    return CAPI.getmat(o.x, o.y, o.z)
end

--[[!
    Structure: procedural
    A table in <edit> module containing various functions
    used for procedural (scripted) map editing.
]]
procedural = {
    --[[!
        Function: erase_geometry
        Clears out all map geometry.
    ]]
    erase_geometry = CAPI.editing_erasegeometry,

    --[[!
        Function: create_cube
        Creates a cube with given parameters. Please note
        that not all positions are sufficient for creating
        cubes, you need to fit into the grid.

        For example, when you have coords 512, 512, 512
        and cube of size 64, it's fine, because it can fit in.

        But if you change the coords to 1, 1, 1, only cube of
        size 1 can fit there.

        The coordinates also have to fit in the world, so
        the positions can range from 0 to <world.get_size>.

        Parameters:
            x - the x position of the cube.
            y - the y position of the cube.
            z - the z position of the cube.
            gridsize - see <world.get_grid_size>.
    ]]
    create_cube = CAPI.editing_createcube,

    --[[!
        Function: delete_cube
        Parameters and rules are the same as for <create_cube>,
        but it actually deletes cubes instead of creating.
    ]]
    delete_cube = CAPI.editing_deletecube,

    --[[!
        Function: set_cube_texture
        First 4 arguments are the same with <create_cube>,
        fifth argument is the face, sixth is the texture slot number.
        See also <set_cube_material>.

        If we're standing at center of the map, with increasing
        X coordinate when strafing right and increasing Y coordinate
        when going forward, the faces go like this:

        Faces:
            0 - right side of the cube
            1 - left side of the cube
            2 - back side of the cube
            3 - front side of the cube
            4 - bottom side of the cube
            5 - top side of the cube
    ]]
    set_cube_texture = CAPI.editing_setcubetex,

    --[[!
        Function: set_cube_material
        First 4 arguments are the same with <create_cube>, fifth
        argument is the material index, see <edit.get_material>.
        See also <set_cube_texture>.
    ]]
    set_cube_material = CAPI.editing_setcubemat,

    --[[!
        Function: push_cube_corner
        First 5 arguments are the same with <set_cube_texture>,
        sixth argument is the corner index, seventh is the
        direction (see <edit.DIRECTION_FROM> and <edit.DIRECTION_TO>,
        where "from" is "into the cube").

        On all faces, 0 is top-left corner, 1 is top-right, 2 is
        bottom-left and 3 is bottom-right when facing them directly
        (that is, when we see the texture in right orientation).
    ]]
    push_cube_corner = CAPI.editing_pushcubecorner
}
