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
    Variable: DIRECTION_FROM
    A variable usually passed as parameter to some of cube editing
    functions (see <push>). This means pushing will be performed
    away from player. See also <DIRECTION_TO>.
]]
DIRECTION_FROM =  1

--[[!
    Variable: DIRECTION_TO
    See <DIRECTION_FROM>.
]]
DIRECTION_TO   = -1

--[[!
    Variable: PUSH_FACE
    Passed as mode argument to <push>, it specifies what will
    actually be pushed. This means we'll push the whole face
    in specified direction (<DIRECTION_FROM>, <DIRECTION_TO>).
    There are 8 steps of face pushing, final step being deleted
    cube. See also <PUSH_CUBE> and <PUSH_CORNER>.
]]
PUSH_FACE   = 0

--[[!
    Variable: PUSH_CUBE
    See <PUSH_FACE>. This mode specifies a whole cube will be
    pushed in specified direction. Also see <PUSH_CORNER>.
]]
PUSH_CUBE   = 1

--[[!
    Variable: PUSH_CORNER
    See <PUSH_FACE> and <PUSH_CUBE>. This behaves simillar as face
    pushing, but just one cube corner, the one editing cursor aims
    at, will be pushed.
]]
PUSH_CORNER = 2

--[[!
    Variable: ROTATE_COUNTER_CLOCKWISE
    Passed as an argument to <rotate_world>, <rotate_entities>
    or more vague variant <rotate>. Means rotation will be counter
    clockwise. See also <ROTATE_CLOCKWISE>.
]]
ROTATE_COUNTER_CLOCKWISE = -1

--[[!
    Variable: ROTATE_CLOCKWISE
    Passed as an argument to <rotate_world>, <rotate_entities>
    or more vague variant <rotate>. Means rotation will be
    clockwise. See also <ROTATE_COUNTER_CLOCKWISE>.
]]
ROTATE_CLOCKWISE         =  1

--[[!
    Variable: MATERIAL_AIR
    This represents basically "no material". Air is everywhere
    where no material was previously set, even on places where
    geometry is present.

    See Also:
        <MATERIAL_WATER>
        <MATERIAL_LAVA>
        <MATERIAL_GLASS>
        <MATERIAL_NOCLIP>
        <MATERIAL_CLIP>
]]
MATERIAL_AIR = 0

--[[!
    Variable: MATERIAL_WATER
    This represents water material.

    See Also:
        <MATERIAL_AIR>
        <MATERIAL_LAVA>
        <MATERIAL_GLASS>
        <MATERIAL_NOCLIP>
        <MATERIAL_CLIP>
]]
MATERIAL_WATER = 1

--[[!
    Variable: MATERIAL_LAVA
    This represents lava material.

    See Also:
        <MATERIAL_AIR>
        <MATERIAL_WATER>
        <MATERIAL_GLASS>
        <MATERIAL_NOCLIP>
        <MATERIAL_CLIP>
]]
MATERIAL_LAVA = 2

--[[!
    Variable: MATERIAL_GLASS
    This represents glass material.

    See Also:
        <MATERIAL_AIR>
        <MATERIAL_WATER>
        <MATERIAL_LAVA>
        <MATERIAL_NOCLIP>
        <MATERIAL_CLIP>
]]
MATERIAL_GLASS = 3

--[[!
    Variable: MATERIAL_NOCLIP
    This represents noclip material. Any
    geometry cubes inside this material are
    treated as empty by collisions.

    See Also:
        <MATERIAL_AIR>
        <MATERIAL_WATER>
        <MATERIAL_LAVA>
        <MATERIAL_GLASS>
        <MATERIAL_CLIP>
]]
MATERIAL_NOCLIP = math.lsh(1, 3)

--[[!
    Variable: MATERIAL_CLIP
    This represents clip material. Anything
    inside this material is treated as solid
    by collisions, even empty space.

    See Also:
        <MATERIAL_AIR>
        <MATERIAL_WATER>
        <MATERIAL_LAVA>
        <MATERIAL_GLASS>
        <MATERIAL_NOCLIP>
]]
MATERIAL_CLIP = math.lsh(2, 3)

--[[!
    Function: toggle_mode
    Toggles editing mode. Does not accept
    arguments and does not return.
]]
toggle_mode = CAPI.edittoggle

--[[!
    Function: cancel_selection
    Cancels any explicit selection you currently have.
]]
cancel_selection = CAPI.cancelsel

--[[!
    Function: extend_selection
    Extends current selection to include the editing cursor.
]]
extend_selection = CAPI.selextend

--[[!
    Function: push_selection
    Pushes current geometry selection (without the geometry!)
    in direction specified by argument (see <DIRECTION_FROM>
    and <DIRECTION_TO> for details). Used by <push> as part
    of more generalized pushing mechanism.
    See also <push_entities>.
]]
push_selection   = CAPI.pushsel

--[[!
    Function: push_entities
    Pushes selected entities in direction specified by argument
    (see <DIRECTION_FROM> and <DIRECTION_TO> for details). Used
    by <push> as part of more generalized pushing mechanism.
    See also <push_selection>.
]]
push_entities    = CAPI.entpush

--[[!
    Function: has_selection
    Returns the number of explicitly selected cubes,
    or 0 if cubes are selected only implicitly.
]]
has_selection    = CAPI.havesel

--[[!
    Function: reorient
    Changes the side of the white box so it's on the
    same side where editing cursor is currently pointing.
]]
reorient         = CAPI.reorient

--[[!
    Function: in_selection
    Returns true if there is a selected entity in cube
    selection. Also used by for example <select_entities>
    to select all entities in explicit cube selection.
]]
in_selection     = CAPI.insel

--[[!
    Function: nearest_entity
    Used by <select_entities> to select the
    nearest entity to editing cursor.
]]
nearest_entity   = CAPI.nearestent

--[[!
    Function: copy_world
    Copies a selected piece of world geometry. Used
    by more vague <copy> function. See also <copy_entities>.
]]
copy_world      = CAPI.copy

--[[!
    Function: copy_entities
    Copies entities in current world selection. Used
    by more vague <copy> function. See also <copy_world>.
]]
copy_entities   = CAPI.entcopy

--[[!
    Function: delete_world
    Deletes part of world (in selection). Used by
    more vague <delete_selection> and <cut_selection>
    functions. See also <delete_entities>.
]]
delete_world    = CAPI.delcube

--[[!
    Function: delete_entities
    Deletes entities in current selection. Used by
    more vague <delete_selection> and <cut_selection>
    functions. See also <delete_world>.
]]
delete_entities = CAPI.delent

--[[!
    Function: paste_world
    Pastes copied geometry from clipboard. Used by
    more vague <paste>. See also <paste_entities>.
]]
paste_world     = CAPI.paste

--[[!
    Function: paste_entities
    Pastes copied entities from clipboard. Used by
    more vague <paste>. See also <paste_world>.
]]
paste_entities  = CAPI.entpaste

--[[!
    Function: rotate_world
    Rotates a piece of selected world geometry
    in direction given by argument, either clockwise
    or counter-clockwise (see <ROTATE_CLOCKWISE> and
    <ROTATE_COUNTER_CLOCKWISE>).See also <rotate_entities>.
]]
rotate_world    = CAPI.rotate

--[[!
    Function: rotate_entities
    Rotates a selected entities in direction given by argument
    relatively to current cube selection, either clockwise
    or counter-clockwise (see <ROTATE_CLOCKWISE> and
    <ROTATE_COUNTER_CLOCKWISE>).See also <rotate_world>.
]]
rotate_entities = CAPI.entrotate

--[[!
    Function: drop_entities
    Drops currently selected entities
    according to <entdrop> variable.
]]
drop_entities   = CAPI.dropent

--[[!
    Function: loop_entities
    Loops through and executes a function given by argument
    for all selected entities.  
]]
loop_entities   = CAPI.entloop

--[[!
    Function: select_entities
    Selects all entities that match expression given by
    argument (which is a function - the function has to
    return true for the entity to get selected).

    Example:
        (start code)
            -- selects all entities in
            -- current cube selection
            edit.select_entities(function()
                return edit.in_selection()
            end)
        (end)
]]
select_entities = CAPI.entselect

--[[!
    Function: unselect_world
    Unselects all selected cubes.
    See also <unselect_entities>.
]]
unselect_world    = CAPI.cubecancel

--[[!
    Function: unselect_entities
    Unselects all selected entities.
    See also <unselect_world>.
]]
unselect_entities = CAPI.entcancel

--[[!
    Function: num_selected_entities
    Returns number of currently selected entities.
]]
num_selected_entities = CAPI.enthavesel

--[[!
    Function: flip_world
    Flips (mirrors) selected cubes front to back
    relative to the side of the white box
    (default: x). See also <flip_entities>.
]]
flip_world    = CAPI.flip

--[[!
    Function: flip_entities
    Flips the selected entities. Cube selection
    serves as both reference point and orientation
    to flip around. See also <flip_world>.
]]
flip_entities = CAPI.entflip

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
    Function: copy_entity
    Copes a single entity using the state data system.
    Used by more vague <copy>. See also <paste_entity>.
]]
copy_entity  = CAPI.intensityentcopy

--[[!
    Function: paste_entity
    Pastes an entity previously copied by <copy_entity>.
    Used by more vague <paste>.
]]
paste_entity = CAPI.intensitypasteent

--[[!
    Function: get_entity
    Returns a string containing info about currently
    selected or hovered entity. DEPRECATED for API v2,
    for now can be used. The string is in format

    (start code)
        SAUER_TYPE ATTR1 ATTR2 ATTR3 ATTR4 ATTR5
    (end)
]]
get_entity = CAPI.entget

--[[!
    Function: set_entity
    Sets entity properties. For arguments, see return
    value of <get_entity>.

    Accepted arguments are sauer_type, attr1, attr2,
    attr3, attr4 and attr5.
]]
set_entity = CAPI.entset

--[[!
    Function: attach_entity
    Re-attaches entity that can be attached to other
    entity. Used in case of i.e. <spotlight>, where
    you can use this to ensure proper attaching when
    you move the <spotlight>.
]]
attach_entity = CAPI.attachent

--[[!
    Function: get_entity_index
    Returns unique sauer entity index. Does not equal
    entity unique ID. DEPRECATED for API v2.
]]
get_entity_index = CAPI.entindex

--[[!
    Function: highlight_paste
    Execute this before <paste_entities>
    to make them highlighted after pasting.
]]
highlight_paste = CAPI.pastehilite

--[[!
    Function: undo
    Takes back last editing action.
    See also <redo> and <clear_undos>.
]]
undo = CAPI.undo

--[[!
    Function: redo
    Repeats a last action reverted by <undo>.
]]
redo = CAPI.redo

--[[!
    Function: clear_undos
    Clears a list of undoable action.
]]
clear_undos = CAPI.clearundos

--[[!
    Function: edit_face
    Edits a geometry face using given direction
    and mode. See <DIRECTION_FROM>, <DIRECTION_TO>,
    <PUSH_FACE>, <PUSH_CUBE>, <PUSH_CORNER>.
    Used by more vague <push>.

    Parameters:
        direction - the direction we're editing face in.
        mode - the mode of face editing.
]]
edit_face = CAPI.editface

--[[!
    Function: fix_inside_faces
    Fixes textures on inside faces. Optional argument
    is texture slot number.
]]
fix_inside_faces = CAPI.fixinsidefaces

--[[!
    Function: set_material
    Sets a material on current selection. Argument
    is a string containing the material name (like, "water").
]]
set_material = CAPI.editmat

--[[!
    Function: material_reset
    Resets the material texture slots for the subsequent
    <texture.add> commands. See <cfg/default_map_settings.lua>.
]]
material_reset = CAPI.materialreset

--[[!
    Function: print_cube
    Prints out information about the cube player is currently
    pointing at into the console in format

    (start code)
        = CUBE_POINTER = (X_POS, Y_POS, Z_POS) @ CUBE_SIZE
         x AABBCCDD
         y AABBCCDD
         z AABBCCDD
    (end)

    where AA, BB, CC, DD are numbers from 00 to 80 and represent
    how much of face corners on given axis is filled with geometry.

    Example:
        (start code)
            = 0x123456780 = (512, 512, 512) @ 32
             x 80808080
             y 80808080
             z 80706050
        (end)

        represents cube with gridpower 5, in the middle of the map,
        with all faces full except the top face, which has top-left
        corner unchanged, top-right pushed by 1 step, bottom-left
        by 2 steps and bottom-right by 3 steps.
]]
print_cube = CAPI.printcube

--[[!
    Function: get_material
    Returns what material is on the position given by argument.
    Materials are represented by <MATERIAL_AIR>, <MATERIAL_WATER>,
    <MATERIAL_LAVA>, <MATERIAL_GLASS>, <MATERIAL_NOCLIP> and
    <MATERIAL_CLIP>.
]]
get_material = CAPI.getmat

--[[!
    Function: push
    Generic pushing function.

    If we have no entities selected or geometry is selected,
    it checks whether we're moving and if yes, it'll push
    selection in direction given by argument (see <push_selection>).

    If we're not moving, it'll <unselect_entities> and <edit_face>
    with given direction and mode.

    If nothing but entities is selected, they're pushed
    in given direction.

    Parameters:
        direction - see <DIRECTION_FROM> and <DIRECTION_TO>.
        mode - see <PUSH_FACE>, <PUSH_CUBE> and <PUSH_CORNER>.
]]
function push(direction, mode)
    -- mode when no entity is selected or geometry is selected
    if has_selection() ~= 0 or num_selected_entities() == 0 then
        -- if we're moving selection
        if _G["moving"] ~= 0 then
            push_selection(direction)
        else
            unselect_entities()
            -- edit geometry face using given
            -- direction and mode (see docs above)
            edit_face(direction, mode)
        end
    else
        push_entities(direction)
    end
end

--[[!
    Function: rotate
    Generic rotation function. Executes both <rotate_world>
    and <rotate_entities> and passes them argument (direction).
]]
function rotate(n)
    rotate_world(n)
    rotate_entities(n)
end

--[[!
    Variable: entity_copy_buffer
    Local and internal variable, storing entity attrs
    (see <get_entity>). Used with <replace_selected_entity>,
    <copy> and <paste>.
]]
local entity_copy_buffer = {}

--[[!
    Function: replace_selected_entity
    Sets attrs of currently selected entities from
    <entity_copy_buffer>.

    If no entity is selected, it uses <paste_entity>
    to paste copied entity using the state data system
    and then sets the attrs from <entity_copy_buffer>.

    See also <set_entity>.
]]
function replace_selected_entity()
    if num_selected_entities() == 0 then
        -- use our spawner here
        paste_entity()
    end
    set_entity(unpack(entity_copy_buffer))
end

--[[!
    Function: copy
    Generic copy function. There are 3 types of copying
    and pasting. Here's a list of them:

    1. only cubes selected -> only cubes pasted
    2. cubes and entities selected -> cubes and entities pasted, same
    relative positions.
    3. only entities selected -> last selected entity pasted using
    the state data system (see <replace_selected_entity>).

    If geometry is selected or no entities are selected, types 1
    and 2 are used. Otherwise, type 3 is used.
]]
function copy()
    if has_selection() ~= 0 or num_selected_entities() == 0 then
        entity_copy_buffer = {}
        copy_entities()
        copy_world()
    else
        entity_copy_buffer = string.split(get_entity(), " ")
        copy_entity()
    end
end

--[[!
    Function: paste
    See <copy>. If <entity_copy_buffer> is empty, it attempts
    to paste using paste types 1 and 2, performing <highlight_paste>
    and <reorient> before doing so.

    The pasting itself is done on key release.
    If no entities or no geometry are selected, any
    explicit selection is cancelled using <cancel_selection>.

    If the buffer is filled, <replace_selected_entity> is performed.
    Then the explicit selection cancelling follows the same rules
    as said above.
]]
function paste()
    local cancel_paste = (
        has_selection()         == 0
     or num_selected_entities() == 0
    )

    if table.concat(entity_copy_buffer) == "" then
        highlight_paste()
        -- temp - real fix will be in octaedit
        reorient()

        CAPI.onrelease(function()
            delete_world()
            paste_world()
            paste_entities()
            if cancel_paste then
                cancel_selection()
            end
        end)
    else
        replace_selected_entity()
        if cancel_paste then
            cancel_selection()
        end
    end
end

--[[!
    Function: flip
    Generic flip function. Executes both
    <flip_world> and <flip_entities>.
]]
function flip()
    flip_world()
    flip_entities()
end

--[[!
    Function: delete_selection
    If no entities are selected, it attempts to delete
    currently selected geometry (<delete_world>).
    Otherwise <delete_entities> gets called.
]]
function delete_selection()
    if num_selected_entities() == 0 then
        delete_world()
    else
        delete_entities()
    end
end

--[[!
    Function: cut_selection
    Cuts piece of selected geometry along with entities
    (if any are in selection).

    Moving the editing cursor will result in move of the cut piece.
    Releasing the key this is bind to afterwards will result in
    paste of the piece on its final place.

    If no explicit selection is made when cutting, it cuts the
    cube editing cursor is aiming at. The selection gets cancelled
    after placing the cube on its final place.

    Do not use it without keybind, as it uses <input.on_release>.
]]
function cut_selection()
    local had_selection = has_selection()
    _G["moving"] = 1

    -- assure that we're actually moving
    if _G["moving"] ~= 0 then
        -- copy and delete
        copy_world()
        copy_entities()
        delete_world()
        delete_entities()
        CAPI.onrelease(function()
            -- on release, stop moving
            _G["moving"] = 0
            -- and paste back stuff
            paste_world()
            paste_entities()
            if had_selection == 0 then
                cancel_selection()
            end
        end)
    end
end

--[[!
    Function: drag
    Selects cubes and entities by dragging the
    selection cursor. Usually mapped to left mouse
    button in edit mode.
]]
function drag()
    cancel_selection()
    _G["entmoving"] = 2
    CAPI.onrelease(function()
        CAPI.finish_dragging()
        _G["entmoving"] = 0
    end)

    if _G["entmoving"] == 0 then
        _G["dragging"] = 1
        CAPI.onrelease(function()
            _G["dragging"] = 0
        end)
    end
end

--[[!
    Function: move_selection
    Moves current selection. Usually mapped to right
    mouse button in edit mode (unless in heightmap mode).
]]
function move_selection()
    _G["entmoving"] = 2
    CAPI.onrelease(function()
        CAPI.finish_dragging()
        _G["entmoving"] = 0
    end)

    if _G["entmoving"] == 0 then
        extend_selection()
        reorient()
        _G["moving"] = 1
        CAPI.onrelease(function()
            _G["moving"] = 0
        end)
    end
end

--[[!
    Function: select_corners
    Selects corners of cubes. Usually mapped to the middle
    mouse button in edit mode. When used in height map mode,
    it calls <select_height_map>.
]]
function select_corners()
    if _G["hmapedit"] ~= 0 then
        select_height_map()
    else
        cancel_selection()
        _G["entmoving"] = 2
        CAPI.onrelease(function()
            CAPI.finish_dragging()
            _G["entmoving"] = 0
        end)

        if _G["entmoving"] == 0 then
            _G["selectcorners"] = 1
            _G["dragging"]      = 1
            CAPI.onrelease(function()
                _G["selectcorners"] = 0
                _G["dragging"]      = 0
            end)
        end
    end
end

--[[!
    Variable: height_brush_index
    An internal variable specifying
    current height brush index.
]]
local height_brush_index = -1

--[[!
    Variable: max_height_brushes
    An internal variable specifying
    total number of height brushes.
]]
local max_height_brushes = -1

--[[!
    Variable: brushes
    An internal table storing all available
    height brushes. Used for later lookups.
    It's an associative array with string keys
    and function values, each function setting
    up different kind of brush.
]]
local brushes = {}

--[[!
    Function: height_brush_handle
    An internal function used for creation of "brush handle",
    that is a "center" of height brush that you define.

    Like, if you define a height brush that is 6 units wide
    and 4 units long, you'll want to specify handle position
    at 2, 1 (indexes start at 0). Specifying i.e. 0, 0 or
    5, 3 will make the handle be at brush corners.

    You pass the position using two arguments to this
    function (which represent x and y).

    See also <height_brush_verts>.
]]
local function height_brush_handle(x, y)
    _G["brushx"] = x
    _G["brushy"] = y
end

--[[!
    Function: height_brush_verts
    An internal function used for creation of actual brush
    verts. You give it a table in format

    (start code)
        {
            { 1, 1, 1 }
            { 1, 0, 1 }
            { 1, 1, 1 }
        }
    (end)

    This example will set up verts for brush that makes a squared
    border. Setting the 0 to 1 would make actual square. You can
    go up to 8, 8 means biggest height increase and 0 means no
    height increase.

    If you're making just a dot, use a table in format

    (start code)
        { 1 }
    (end)

    Please note that for "line", you'll have to use a standard
    way of defining brush verts, this one works for dots only.

    See also <height_brush_handle>.
]]
local function height_brush_verts(list)
    for y, brush_vert in pairs(list)  do
        -- this is 1 point brush
        if type(brush_vert) ~= "table" then
            CAPI.brushvert(0, 0, 1)
            break
        end

        -- any other brush - array of arrays
        for x, v in pairs(brush_vert) do
            CAPI.brushvert(x - 1, y - 1, v)
        end
    end
end

--[[!
    Function: select_height_brush
    Selects a height brush from <brushes>. It increments
    <height_brush_index> (but makes sure it doesn't overrun
    <max_height_brushes>). By default, it prints the brush
    name into the console, but doesn't have to.

    Parameters:
        num - a number specifying by how many to increment
        the brush index. You'll want 1 usually.
        silent - if this is specified and true, the function
        won't print out the brush name (useful for setting
        default brush, see <cfg/brush.lua>).
]]
function select_height_brush(num, silent)
    height_brush_index = height_brush_index + num

    if  height_brush_index < 0 then
        height_brush_index = max_height_brushes
    end

    if  height_brush_index > max_height_brushes then
        height_brush_index = 0
    end

    local brush_name = brushes["brush_" .. height_brush_index]()

    if not silent then
        echo(brush_name)
    end
end

--[[!
    Function: new_height_brush
    Creates a new height brush. It increments <max_height_brushes>
    and saves a function into <brushes> (with key being in format
    "brush_NUM" where num is the newly set <max_height_brushes>).

    The function clears current brush, sets up brush handle (see
    <height_brush_handle>) and brush verts (see <height_brush_verts>)
    and returns the brush name.

    Parameters:
        name - the brush name.
        x - handle x position.
        y - handle y position.
        verts - the table as specified in <height_brush_verts>.
]]
function new_height_brush(name, x, y, verts)
    max_height_brushes = max_height_brushes + 1
    brushes["brush_" ..  max_height_brushes] = function()
        CAPI.clearbrush()

        if x then
            height_brush_handle(x, y)
            height_brush_verts (verts)
        end

        return name
    end
end

--[[!
    Function: cancel_height_map
    Returns the heightmap texture selection to default
    (that is, select all textures). See <select_height_map>.
]]
cancel_height_map = CAPI.hmapcancel

--[[!
    Function: select_height_map
    Selects the texture and orientation of the highlighted cube
    (by default mapped to mouse buttons while in heightmap mode
    or the H key).

    If <hmapselall> is set to 1, then all textures are automatically
    selected, and this command will simply select the orientation.

    All cubes of equal or larger size that match the selection will
    be considered part of the heightmap.
]]
select_height_map = CAPI.hmapselect

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
