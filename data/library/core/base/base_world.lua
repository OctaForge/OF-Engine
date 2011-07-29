--[[!
    File: base/base_world.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Warning
        This is scheduled for removal and replacement with nicer interface.
]]

--[[!
    Package: world
    This module contains various functions for world manipulation.
]]
module("world", package.seeall)

request_private_edit_mode = CAPI.requestprivedit
has_private_edit_mode = CAPI.hasprivedit

print_cube = CAPI.printcube
test_physics = CAPI.phystest

pvs = {
    generate = CAPI.genpvs,
    test     = CAPI.testpvs,
    clear    = CAPI.clearpvs,
    stats    = CAPI.pvsstats
}

enlarge = CAPI.mapenlarge
shrink = CAPI.shrinkmap

get_map_name = CAPI.mapname
get_map_script_name = CAPI.mapcfgname

get_map_preview_filename = CAPI.get_map_preview_filename
get_all_map_names = CAPI.get_all_map_names
get_size = CAPI.editing_getworldsize
get_grid_size = CAPI.editing_getgridsize

clear_lightmaps = CAPI.clearlightmaps
dump_lightmaps = CAPI.dumplms
calc_light = CAPI.calclight
patch_light = CAPI.patchlight
recalc = CAPI.recalc
remip  = CAPI.remip

has_map = CAPI.hasmap
map = CAPI.map
restart_map = CAPI.restart_map
export_entities = CAPI.export_entities

write_obj = CAPI.writeobj
