--[[!
    File: lua/core/base/base_world.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

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
request_private_edit_mode = _C.requestprivedit

--[[!
    Function: has_private_edit_mode
    Returns true if player is in private edit mode, false otherwise.
]]
has_private_edit_mode = _C.hasprivedit

--[[!
    Function: get_map_previw_name
    Returns relative path to the map preview image
    (media/map/MYMAP/preview.png).
]]
get_map_preview_name = _C.get_map_preview_filename

--[[!
    Function: get_all_map_names
    Returns two arrays of strings, representing map
    names. First array represents global maps (in
    root directory), second array represents local
    maps (in user's home directory).
]]
get_all_map_names = _C.get_all_map_names

--[[!
    Function: restart_map
    Restarts current map.
]]
restart_map = _C.restart_map

--[[!
    Function: save_map
    Saves current map file and entities.
]]
save_map = _C.do_upload
