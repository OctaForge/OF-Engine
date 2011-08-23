--[[!
    File: tgui/config.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides utility functions for tgui, on-hover and on-selected
        color modulating functions and inclusion of all tgui sub-modules.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    utility functions, on-hover and on-selected color modulation and
    submodule inclusion.
]]
module("tgui", package.seeall)

--[[!
    Variable: image_path
    Specifies to-root/home relative path for tgui skin images.
    By default, it's "data/textures/ui/tgui". See also
    <get_image_path> and <get_icon_path>. Change this
    to change pixmap path.
]]
image_path = "data/textures/ui/tgui/"

--[[!
    Function: get_image_path
    Gets a path to an image inside <image_path>. You can
    specify either just a file or a path relative to
    <image_path>. See also <get_icon_path>.
]]
function get_image_path(name)
    return table.concat({ image_path, name })
end

--[[!
    Function: get_icon_path
    Gets a path to an icon inside "icons" directory
    inside <image_path>. You can specify either just
    a file or a path relative to the icons directory.
    See also <get_image_path>.
]]
function get_icon_path(name)
    return table.concat({ image_path, "icons/", name })
end

--[[!
    Function: hover
    Modulates color of a parent. By default makes things
    slightly darker. Use this for on-hover events.
    See also <selected>.
]]
function hover()
    gui.mod_color(0.8, 0.8, 0.8, 0, 0, function()
        gui.clamp(1, 1, 1, 1)
    end)
end

--[[!
    Function: selected
    Modulates color of a parent. By default makes things
    noticeably darker. Use this for on-selected events.
    See also <hover>.
]]
function selected()
    gui.mod_color(0.5, 0.5, 0.5, 0, 0, function()
        gui.clamp(1, 1, 1, 1)
    end)
end

require("tgui.widgets.buttons")
require("tgui.widgets.cherad")
require("tgui.widgets.fields")
require("tgui.elements.sliders")
require("tgui.elements.scrollers")
require("tgui.elements.windows")

require("tgui.interface")
