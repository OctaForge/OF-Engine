module("tgui", package.seeall)

image_path = "data/textures/ui/tgui/"

function get_image_path(name)
    return table.concat({ image_path, name })
end

function get_icon_path(name)
    return table.concat({ image_path, "icons/", name })
end

function hover()    gui.mod_color(0.8, 0.8, 0.8, 0, 0, function() gui.clamp(1, 1, 1, 1) end) end
function selected() gui.mod_color(0.5, 0.5, 0.5, 0, 0, function() gui.clamp(1, 1, 1, 1) end) end

require("tgui.widgets.buttons")
require("tgui.widgets.bars")
require("tgui.widgets.cherad")
require("tgui.widgets.fields")
require("tgui.elements.sliders")
require("tgui.elements.scrollers")
require("tgui.elements.windows")

require("tgui.interface")
