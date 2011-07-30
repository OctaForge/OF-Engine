--[[!
    File: base/base_editing.lua

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

DIRECTION_FROM =  1
DIRECTION_TO   = -1

PUSH_FACE   = 0
PUSH_CUBE   = 1
PUSH_CORNER = 2

toggle_mode = CAPI.edittoggle

cancel_selection = CAPI.cancelsel
extend_selection = CAPI.selextend
push_selection   = CAPI.pushsel
has_selection    = CAPI.havesel
reorient         = CAPI.reorient
in_selection     = CAPI.insel
nearest_entity   = CAPI.nearestent

copy_world      = CAPI.copy
copy_entities   = CAPI.entcopy
delete_cube     = CAPI.delcube
delete_entities = CAPI.delent
paste_world     = CAPI.paste
paste_entities  = CAPI.entpaste
rotate_world    = CAPI.rotate
rotate_entities = CAPI.entrotate
push_entities   = CAPI.entpush
drop_entities   = CAPI.dropent
loop_entities   = CAPI.entloop
select_entities = CAPI.entselect
unselect_world    = CAPI.cubecancel
unselect_entities = CAPI.entcancel

has_selected_entity = CAPI.enthavesel

flip_world    = CAPI.flip
flip_entities = CAPI.entflip

add_npc = CAPI.npcadd
delete_npc = CAPI.npcdel

new_entity = CAPI.spawnent

copy_entity  = CAPI.intensityentcopy
paste_entity = CAPI.intensitypasteent

get_entity = CAPI.entget
set_entity = CAPI.entset
attach_entity = CAPI.attachent
get_entity_index = CAPI.entindex

highlight_paste = CAPI.pastehilite

undo = CAPI.undo
redo = CAPI.redo
clear_undos = CAPI.clearundos

edit_face = CAPI.editface
fix_inside_faces = CAPI.fixinsidefaces

set_material = CAPI.editmat
material_reset = CAPI.materialreset

function push(direction, mode)
    -- mode when no entity is selected or geometry is selected
    if has_selection() ~= 0 or has_selected_entity() == 0 then
        -- if we're moving selection
        if _G["moving"] ~= 0 then
            -- push selection in direction
            push_selection(direction)
        else
            -- unselect all entities
            unselect_entities()
            -- edit geometry face using given
            -- direction and mode (see docs above)
            edit_face(direction, mode)
        end
    else
        -- push entities in given direction
        push_entities(direction)
    end
end

function rotate(n)
    rotate_world(n)
    rotate_entities(n)
end

-- copy and paste

-- 3 types of copying and pasting
-- 1. select only cubes      -> paste only cubes
-- 2. select cubes and ents  -> paste cubes and ents. same relative positions
-- 3. select only ents       -> paste last selected ent. if ents are selected, replace attrs as paste

local entity_copy_buffer = {}

function replace_selected_entity()
    if has_selected_entity() == 0 then
        -- use our spawner here
        paste_entity()
    end
    set_entity(unpack(entity_copy_buffer))
end

function copy()
    if has_selection() ~= 0 or has_selected_entity() == 0 then
        entity_copy_buffer = {}
        copy_entities()
        copy_world()
    else
        entity_copy_buffer = string.split(get_entity(), " ")
        copy_entity()
    end
end

function paste()
    local cancel_paste = (
        has_selection()       == 0
     or has_selected_entity() == 0
    )

    if table.concat(entity_copy_buffer) == "" then
        highlight_paste()
        -- temp - real fix will be in octaedit
        reorient()

        CAPI.onrelease(function()
            delete_cube()
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

function flip()
    flip_world()
    flip_entities()
end

function delete_selection()
    if has_selected_entity() == 0 then
        delete_cube()
    else
        delete_entities()
    end
end

function cut_selection()
    local had_selection = has_selection()
    _G["moving"] = 1
    if _G["moving"] ~= 0 then
        copy_world()
        copy_entities()
        delete_cube()
        delete_entities()
        CAPI.onrelease(function()
            _G["moving"] = 0
            paste_world()
            paste_entities()
            if had_selection == 0 then
                cancel_selection()
            end
        end)
    end
end

function move()
    _G["moving"] = 1
    CAPI.onrelease(function()
        _G["moving"] = 0
    end)
    return _G["moving"]
end

function drag_world()
    _G["dragging"] = 1
    CAPI.onrelease(function()
        _G["dragging"] = 0
    end)
end

function drag_entity()
    _G["entmoving"] = 2
    CAPI.onrelease(function()
        CAPI.finish_dragging()
        _G["entmoving"] = 0
    end)
    return _G["entmoving"]
end

function drag()
    cancel_selection()
    if drag_entity() == 0 then
        drag_world()
    end
end

function move_selection()
    if drag_entity() == 0 then
        extend_selection()
        reorient()
        move()
    end
end

function select_corners()
    if _G["hmapedit"] ~= 0 then
        select_height_map()
    else
        cancel_selection()
        if drag_entity() == 0 then
            _G["selectcorners"] = 1
            _G["dragging"]      = 1
            CAPI.onrelease(function()
                _G["selectcorners"] = 0
                _G["dragging"]      = 0
            end)
        end
    end
end

local height_brush_index = -1
local max_height_brushes = -1

local brushes = {}

local function height_brush_handle(x, y)
    _G["brushx"] = x
    _G["brushy"] = y
end

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

cancel_height_map = CAPI.hmapcancel
select_height_map  = CAPI.hmapselect

procedural = {
    erase_geometry = CAPI.editing_erasegeometry,
    create_cube = CAPI.editing_createcube,
    delete_cube = CAPI.editing_deletecube,
    set_cube_texture = CAPI.editing_setcubetex,
    set_cube_material = CAPI.editing_setcubemat,
    push_cube_corner = CAPI.editing_pushcubecorner
}
