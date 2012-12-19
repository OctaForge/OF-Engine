--[[! File: library/core/std/gui/default/config.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Shared configuration file for the default UI set.
]]

local images  = "data/ui/themes/default/"
local cursors = images .. "cursors/"
local icons   = images .. "icons/"

return {
    get_image_path = function(p)
        return images .. p
    end,
    
    get_cursor_path = function(p)
        return cursors .. p
    end,
    
    get_icon_path = function(p)
        return icons .. p
    end
}
