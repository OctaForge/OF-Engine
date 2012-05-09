--[[!
    File: library/core/tgui/elements/sliders.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides complex slider widget for tgui.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    complex sliders, both horizontal and vertical.
]]
module("tgui", package.seeall)

--[[!
    Function: hslider
    Creates a horizontal slider. The button on the slider meant
    for dragging will show current slider value.
    See also <vslider>.

    Parameters:
        var - a string value specifying which engine variable to
        read / write from / to.
        minv - optional argument. When unspecified, the slider
        tries to read the minimal value from the engine variable
        specified previously. Using this, you can override. Useful
        for i.e. when you're writing into alias which doesn't have
        minimal and maximal value.
        maxv - see above, only for maximal value.
]]
function hslider(var, minv, maxv, onchange, arrowsize, stepsize, steptime)
     gui.hslider(
        var, minv, maxv, onchange, arrowsize, stepsize, steptime, function()
            gui.clamp(1, 1, 0, 0)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("slider_horizontal_left.png"),
                    0.01, 0.01
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_middle.png"),
                    0.98, 0.01,
                    function()
                        gui.clamp(1, 1, 0, 0)
                    end
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_right.png"),
                    0.01, 0.01
                )
            end)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("slider_horizontal_left.png"),
                    0.01, 0.01
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_middle.png"),
                    0.98, 0.01,
                    function()
                        gui.clamp(1, 1, 0, 0)
                    end
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_right.png"),
                    0.01, 0.01
                )
            end)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("slider_horizontal_left.png"),
                    0.01, 0.01
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_middle.png"),
                    0.98, 0.01,
                    function()
                        gui.clamp(1, 1, 0, 0)
                    end
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_right.png"),
                    0.01, 0.01
                )
            end)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("slider_horizontal_left.png"),
                    0.01, 0.01
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_middle.png"),
                    0.98, 0.01,
                    function()
                        gui.clamp(1, 1, 0, 0)
                    end
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_right.png"),
                    0.01, 0.01
                )
            end)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("slider_horizontal_left.png"),
                    0.01, 0.01
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_middle.png"),
                    0.98, 0.01,
                    function()
                        gui.clamp(1, 1, 0, 0)
                    end
                )
                gui.stretched_image(
                    get_image_path("slider_horizontal_right.png"),
                    0.01, 0.01
                )
            end)
            gui.slider_button(function()
                -- idle state
                gui.color(0, 0, 0, 0, 0.06, 0, function()
                    gui.hlist(0, function()
                        gui.stretched_image(
                            get_image_path("slider_horizontal_left.png"),
                            0.03, 0.03
                        )
                        gui.stretched_image(
                            get_image_path("slider_horizontal_right.png"),
                            0.03, 0.03
                        )
                    end)
                    --gui.function_label(function() return _G[var] end)
                end)
                -- hover state
                gui.color(0, 0, 0, 0, 0.06, 0, function()
                    gui.hlist(0, function()
                        gui.stretched_image(
                            get_image_path("slider_horizontal_left.png"),
                            0.03, 0.03
                        )
                        gui.stretched_image(
                            get_image_path("slider_horizontal_right.png"),
                            0.03, 0.03
                        )
                    end)
                    hover()
                    --gui.function_label(function() return _G[var] end)
                end)
                -- selected state
                gui.color(0, 0, 0, 0, 0.06, 0, function()
                    gui.hlist(0, function()
                        gui.stretched_image(
                            get_image_path("slider_horizontal_left.png"),
                            0.03, 0.03
                        )
                        gui.stretched_image(
                            get_image_path("slider_horizontal_right.png"),
                            0.03, 0.03
                        )
                    end)
                    selected()
                    --gui.function_label(function() return _G[var] end)
                end)
            end)
        end
    )
end

--[[!
    Function: vslider
    Creates a vertical slider. The button on the slider meant
    for dragging will show current slider value.
    See also <hslider>.

    Parameters:
        var - a string value specifying which engine variable to
        read / write from / to.
        minv - optional argument. When unspecified, the slider
        tries to read the minimal value from the engine variable
        specified previously. Using this, you can override. Useful
        for i.e. when you're writing into alias which doesn't have
        minimal and maximal value.
        maxv - see above, only for maximal value.
]]
function vslider(var, minv, maxv, onchange, arrowsize, stepsize, steptime)
     gui.vslider(
        var, minv, maxv, onchange, arrowsize, stepsize, steptime, function()
            gui.clamp(0, 0, 1, 1)
            gui.vlist(0, function()
                gui.stretched_image(
                    get_image_path("slider_vertical_up.png"),
                    0.01, 0.01
                )
                gui.stretched_image(
                    get_image_path("slider_vertical_middle.png"),
                    0.01, 0.98,
                    function()
                        gui.clamp(0, 0, 1, 1)
                    end
                )
                gui.stretched_image(
                    get_image_path("slider_vertical_down.png"),
                    0.01, 0.01
                )
            end)
            gui.slider_button(function()
                -- idle state
                gui.color(0, 0, 0, 0, 0.06, 0, function()
                    gui.hlist(0, function()
                        gui.stretched_image(
                            get_image_path("slider_horizontal_left.png"),
                            0.03, 0.03
                        )
                        gui.stretched_image(
                            get_image_path("slider_horizontal_right.png"),
                            0.03, 0.03
                        )
                    end)
                    --gui.function_label(var)
                end)
                -- hover state
                gui.color(0, 0, 0, 0, 0.06, 0, function()
                    gui.hlist(0, function()
                        gui.stretched_image(
                            get_image_path("slider_horizontal_left.png"),
                            0.03, 0.03
                        )
                        gui.stretched_image(
                            get_image_path("slider_horizontal_right.png"),
                            0.03, 0.03
                        )
                    end)
                    hover()
                    --gui.function_label(var)
                end)
                -- selected state
                gui.color(0, 0, 0, 0, 0.06, 0, function()
                    gui.hlist(0, function()
                        gui.stretched_image(
                            get_image_path("slider_horizontal_left.png"),
                            0.03, 0.03
                        )
                        gui.stretched_image(
                            get_image_path("slider_horizontal_right.png"),
                            0.03, 0.03
                        )
                    end)
                    selected()
                    --gui.function_label(var)
                end)
            end)
        end
    )
end
