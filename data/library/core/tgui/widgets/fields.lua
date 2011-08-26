--[[!
    File: tgui/widgets/fields.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides a field widget.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    a skinned field widget.
]]
module("tgui", package.seeall)

--[[!
    Function: field
    See <gui.field>. The arguments etc. are exactly the same,
    but this one is skinned.
]]
function field(...)
    local args = { ... }
    gui.table(3, 0, function()
        gui.color(1, 1, 1, 1, 0.001, 0.001)
        gui.color(1, 1, 1, 1, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 1, 0.001, 0.001)

        gui.color(1, 1, 1, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.field(unpack(args))
        gui.color(1, 1, 1, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)

        gui.color(1, 1, 1, 1, 0.001, 0.001)
        gui.color(1, 1, 1, 1, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 1, 0.001, 0.001)
    end)
end
