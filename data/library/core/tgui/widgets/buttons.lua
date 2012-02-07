--[[!
    File: library/core/tgui/widgets/buttons.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides complex buttons for tgui.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    complex buttons.
]]
module("tgui", package.seeall)

--[[!
    Function: button
    Creates a default button which has a standard background given by
    the GUI skin. You specify the label (which is a string) and the
    action that is run on click (which is a function).

    See also <button_no_bg>.
]]
function button(label, action)
    gui.button(action, function()
        -- idle state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("button_left_idle.png"),
                    0.01, 0.03
                )
                gui.stretched_image(
                    get_image_path("button_middle_idle.png"),
                    0.15, 0.03,
                    function()
                        gui.clamp(1, 1, 0, 0)
                    end
                )
                gui.stretched_image(
                    get_image_path("button_right_idle.png"),
                    0.01, 0.03
                )
            end)
            gui.label(label)
        end)

        -- hover state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("button_left_idle.png"),
                    0.01, 0.03, hover
                )
                gui.stretched_image(
                    get_image_path("button_middle_idle.png"),
                    0.15, 0.03,
                    function()
                        gui.clamp(1, 1, 0, 0)
                        hover()
                    end
                )
                gui.stretched_image(
                    get_image_path("button_right_idle.png"),
                    0.01, 0.03, hover
                )
            end)
            gui.label(label)
        end)

        -- selected state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.hlist(0, function()
                gui.stretched_image(
                    get_image_path("button_left_idle.png"),
                    0.01, 0.03, selected
                )
                gui.stretched_image(
                    get_image_path("button_middle_idle.png"),
                    0.15, 0.03,
                    function()
                        gui.clamp(1, 1, 0, 0)
                        selected()
                    end
                )
                gui.stretched_image(
                    get_image_path("button_right_idle.png"),
                    0.01, 0.03, selected
                )
            end)
            gui.label(label)
        end)
    end)
end

--[[!
    Function: button_no_bg
    This is the same as <button>, but there is no background
    drawn, just the label. Useful for i.e. lists.
]]
function button_no_bg(label, action)
    gui.button(action, function()
        gui.align(-1, 0)
        -- idle state
        gui.fill(0, 0, function()
            gui.clamp(1, 1, 0, 0)
            gui.color(0, 0, 0, 0, 0, 0.03, function()
                gui.clamp(1, 1, 0, 0)
            end)
            gui.label(label, 1, 0, 1, 1, 1)
        end)

        -- hover state
        gui.fill(0, 0, function()
            gui.clamp(1, 1, 0, 0)
            gui.color(0, 0, 0, 0, 0, 0.03, function()
                gui.clamp(1, 1, 0, 0)
            end)
            gui.label(label, 1, 0, 1, 0, 0)
        end)

        -- selected state
        gui.fill(0, 0, function()
            gui.clamp(1, 1, 0, 0)
            gui.color(0, 0, 0, 0, 0, 0.03, function()
                gui.clamp(1, 1, 0, 0)
            end)
            gui.label(label, 1, 0, 0.5, 0, 0)
        end)
    end)
end
