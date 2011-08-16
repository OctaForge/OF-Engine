--[[!
    File: base/base_world.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides various world-related functions, relating
        i.e. map names, map loading / saving, private edit mode,
        lightmaps or PVS.
]]

--[[!
    Package: world
    This module contains various functions for world manipulation.
]]
module("world", package.seeall)

--[[!
    Function: request_private_edit_mode
    Requests private edit mode on the server. Useful when playing
    in multiplayer. On local server, player always has this.
]]
request_private_edit_mode = CAPI.requestprivedit

--[[!
    Function: has_private_edit_mode
    Returns true if player is in private edit mode, false otherwise.
]]
has_private_edit_mode = CAPI.hasprivedit

--[[!
    Function: test_physics
    Prints out current camera and player physical state into the terminal
    (but not into the console). The format is like this:

    (start code)
        PHYS(pl): PHYSSTATE, air TIMEINAIR,
        floor: (X, Y, Z),
        vel: (X, Y, Z),
        g: (X, Y, Z)
        PHYS(cam): PHYSSTATE, air TIMEINAIR,
        floor: (X, Y, Z),
        vel: (X, Y, Z),
        g: (X, Y, Z)
    (end)

    where pl is player, cam is camera, PHYSSTATE is the current physical
    state (float, fall, slide, slope, floor, step up, step down, bounce),
    TIMEINAIR is time in milliseconds spent in  the air, floor is the
    current floor vector (usually 0, 0, 1), vel is the velocity and g is
    the current gravity falling.
]]
test_physics = CAPI.phystest

--[[!
    Function: enlarge
    Doubles the size of the map. See also <shrink>.
]]
enlarge = CAPI.mapenlarge

--[[!
    Function: shrink
    Shrinks the map into half of its original size. See also <enlarge>.
]]
shrink = CAPI.shrinkmap

--[[!
    Function: get_map_name
    Returns the current map name.
]]
get_map_name = CAPI.mapname

--[[!
    Function: get_map_script_name
    Returns relative path to the map script
    (data/base/MYMAP/map.lua).
]]
get_map_script_name = CAPI.mapcfgname

--[[!
    Function: get_map_previw_name
    Returns relative path to the map preview image
    (data/base/MYMAP/preview.png).
]]
get_map_preview_name = CAPI.get_map_preview_filename

--[[!
    Function: get_all_map_names
    Returns two arrays of strings, representing map
    names. First array represents global maps (in
    root directory), second array represents local
    maps (in user's home directory).
]]
get_all_map_names = CAPI.get_all_map_names

--[[!
    Function: get_size
    Returns the world size. Empty map by default has
    size of 1024. You can later <enlarge> or <shrink>.
]]
get_size = CAPI.editing_getworldsize

--[[!
    Function: get_grid_size
    Returns current grid size. It's 1 << <gridpower>,
    where <gridpower> is what you change with G+scroll
    and it has values from 0 to 12. Default-sized cubes
    use <gridpower> 3 (that is, gridsize 24). You can
    compute grid size from <gridpower> by calling

    (start code)
        math.lsh(1, gridpower)
    (end)
]]
get_grid_size = CAPI.editing_getgridsize

--[[!
    Function: clear_lightmaps
    Clears out all lightmaps in current level.
]]
clear_lightmaps = CAPI.clearlightmaps

--[[!
    Function: dump_lightmaps
    Dumps all lightmaps into a set of bmp files.
]]
dump_lightmaps = CAPI.dumplms

--[[!
    Function: calc_light
    Calculates all lightmaps. Takes some time depending
    on map size and settings. Lightmaps are then saved
    inside the map file. The function takes one argument
    specifying qualtity level.

    Quality levels:
        1  - 8xAA, world and mapmodel shadows (slow).
        0  - or also if not given, controlled by <lmshadows> and <lmaa>.
        -1 - no AA, world shadows only (fast).
]]
calc_light = CAPI.calclight

--[[!
    Function: patch_light
    See <calc_light>. This doesn't do full calculation, but it
    calculates lightmaps only for newly created cubes. This will
    however create some quirks (like, new cubes won't cast shadows
    on already lit surfaces) and is generally considered inefficient,
    so before releasing map it's recommended to perform full calculation.
    The argument given to this function has the same meaning.
]]
patch_light = CAPI.patchlight

--[[!
    Function: recalc
    Recalculates scene geometry, regenerates any envmaps to reflect
    the changed geometry and fixes all bumpenvmapped surfaces to properly
    use closest available envmaps. Also called by <calc_light>.
]]
recalc = CAPI.recalc

--[[!
    Function: remip
    Optimizes map geometry, so it doesn't lose quality
    but the number of needed triangles is minimal.
]]
remip  = CAPI.remip

--[[!
    Function: has_map
    Returns true if a map is running, false otherwise.
]]
has_map = CAPI.hasmap

--[[!
    Function: map
    If a string argument is given, it runs a map of name given
    by the argument. If nothing is given, any running map gets
    stopped.
]]
map = CAPI.map

--[[!
    Function: restart_map
    Restarts current map.
]]
restart_map = CAPI.restart_map

--[[!
    Function: save_map
    Saves current map file and entities.
]]
save_map = CAPI.do_upload

--[[!
    Function: export_entities
    Exports the entities (see entities.json file brought with
    default empty map) into a file given by argument. The path
    in the argument is relative to user's home directory.
]]
export_entities = CAPI.export_entities

--[[!
    Function: write_obj
    Writes out current map as ARGUMENT.obj inside user's home
    directory, so the engine could be potentially used as basic
    modeller, but the obj files aren't well optimized and don't
    store texture / lighting information.
]]
write_obj = CAPI.writeobj

--[[!
    Structure: pvs
    This is part of <world>. Please note that the <pvs> engine variable
    must be set to 1 for PVS culling to actually be enabled (the variable
    is however by default on).

    Text taken from the Sauerbraten editing reference:

    Cube 2 provides a precomputed visibility culling system as described in the
    technical paper "Conservative Volumetric Visibility with Occluder Fusion"
    by Schaufler et al (see paper for technical details). Basically, it divides
    the world into small cube-shaped "view cells" of empty space that the
    player might possibly occupy, and for each of these view cells calculates
    what other parts of the octree might be visible from it. Since this is
    calculated ahead of time, the engine can cheaply look up at runtime whether
    some part of the octree is possibly visible from the player's current view
    cell. Once pre-calculated, this PVS (potential visibility set) data is
    stored within your map and saved along with it, so that it may be reused
    during gameplay. This data is only valid for a particular map/octree,
    and if you change your map, you must recalculate it or otherwise expect
    culling errors. It is recommended you do this only after you are sure you
    are finished working on your map and ready to release it, as it can take a
    very long time to compute this data. If you have a multi-core processor or
    multi-processor system, it can use multiple threads to speed up the
    pre-calculation (<pvsthreads> engine variable, essentially N
    processors/cores will calculate N times faster).

    The number of pre-calculated view cells stored with your map will show up
    in the edit HUD stats under the "pvs:" stat. It is recommended you keep
    this number to less than 10,000, or otherwise the amount of storage used
    for the PVS data in your map can become excessive. For very large SP maps,
    up to 15,000 view cells is acceptable. The number of view cells is best
    controlled by use of the "clip" material, or by setting the view cell
    size (default is 32, equal to a <gridpower> 5 cube). View cell sizes of 64
    or 128 are worth trying if your map still has an excessive number of view
    cells, but try to use the default view cell size of 32 if it stays
    reasonable. Note that if you have a map with a lot of open space, there
    will be a lot of view cells, and so the initial pre-calculation may take
    a long time. You can use the "clip" material, if necessary, to mark empty
    space the player can't go into, and the PVS calculation will skip computing
    view cells for these areas. Filling places the player can't go with solid
    cubes/sealing the map will similarly reduce the number of possible view
    cells.

    Visibility from a view cell, to some other part of the octree, is
    determined by looking for large square or block-shaped surfaces and seeing
    if they block the view from the view cell to each part of the octree. So
    surfaces like large walls, ceilings, solid buildings, or even mountains
    and hills, that have large solid cross-sections to them will make the best
    occluders, and allow the PVS system to cull away large chunks of the octree
    that are behind them, with respect to the current view cell. Avoid putting
    holes running entirely through these structures, or this will prevent large
    cross-section of them from being used as an occluder (since the player
    could possibly see through them). You can use the <test> command to check
    how well your occluders are working while building them. If your map is an
    open arena-style map, then using the PVS system will have little to no
    effect, since few things are blocking visibility, and it is not worth
    using the PVS system for such maps.

    Note that there is already an occlusion culling system based on hardware
    occlusion queries, in addition to the PVS system, so the main function
    of the PVS system is to provide occlusion culling for older 3D hardware
    that does not support occlusion queries, and also to speed up occlusion
    queries by reducing the amount of such queries (which can be expensive
    themselves) even for 3D hardware that supports them. If PVS is used
    effectively (a map with lots of good occluders), it should always provide
    some speed-up regardless of whether or not the 3D hardware supports
    occlusion queries. However, if you are doing open arena-style maps
    for which there are few good occluders, then it is recommended you skip
    using the PVS system (as it will just take up memory without providing
    a speedup) and rely upon the hardware occlusion queries instead.
]]
pvs = {
    --[[!
        Function: generate
        Generates PVS data for current version of the map. Optional argument
        can specify view cell size. If unspecified, default view cell size
        is used (that is, 32). It's recommended to always use the default
        cell size where reasonable.
    ]]
    generate = CAPI.genpvs,

    --[[!
        Function: test
        Generates PVS data for only the current view cell you're inside
        (of size optionally given by argument, or default if not specified)
        and locks the view cell to it as if <lockpvs> with value 1 was used.
        This allows you to quickly test the effectiveness of occlusion in
        your map without generating full PVS data so that you can more easily
        otpimize your map for PVS before actual expensive pre-calculation is
        done. Use <lockpvs> with value 0 to release the lock on the view
        cell when you're done testing. Note that this will not overwrite any
        existing PVS data already calculated for the map.
    ]]
    test     = CAPI.testpvs,

    --[[!
        Function: clear
        Clears out any PVS data present in the map. Use this i.e. if you're
        editing a map with PVS data already generated to avoid culling errors.
    ]]
    clear    = CAPI.clearpvs,

    --[[!
        Function: stats
        Prints out some PVS status information into the console, such as
        the number of view cells, amount of storage osed for the view cells
        and the average amount of storage used for each individual view cell.
    ]]
    stats    = CAPI.pvsstats
}
