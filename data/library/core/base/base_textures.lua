--[[!
    File: library/core/base/base_textures.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features texture handling interface. Some bits of
        documentation are taken from "Sauerbraten editing reference".
]]

--[[!
    Package: texture
    This module controls textures (their registration and manipulation) and
    texture blending for i.e. heightmap.
]]
module("texture", package.seeall)

--[[!
    Function: fill_slot_list
    Fills the internal list with slot indexes. Required
    for <get_slots_number> to work.
]]
fill_slot_list = CAPI.filltexlist

--[[!
    Function: get_slots_number
    Returns the number of the texture slots
    defined in the map.
]]
get_slots_number = CAPI.getnumslots
