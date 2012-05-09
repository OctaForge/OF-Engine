--[[!
    File: library/core/tgui/elements/windows.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides complex windows for tgui.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    complex windows.
]]
module("tgui", package.seeall)

--[[!
    Function: window
    Creates a window with pre-defined skin, titlebar (which you can use
    to drag the window around) and some custom body.

    You can afterwards use <gui.show> to display the window
    and <gui.hide> to hide it. Internally, <gui.new> is used.

    Parameters:
        name - window name.
        title - window title string.
        body - a function specifying window contents.
        noclose - optional boolean value, setting it to true
        results in hidden close button.
        notitle - optional boolean value, setting it to true
        results in hidden titlebar (just thin border).
        nofocus - optional boolean value, setting it to true
        results in that the window will be controllable only
        in non-mouselook mode (i.e. won't take focus by default).
        onhide - an optional callback function called when the
        window gets hidden.
        alignx - an optional X alignment (-1 means left, 0 center,
        1 right).
        aligny - an optional Y alignment (-1 means top, 0 center,
        1 bottom).
        
]]
function window(
    name, title, body, noclose, notitle,
    nofocus, onhide, alignx, aligny
)
    alignx = alignx or 0
    aligny = aligny or 0
    noclose = noclose or function() return false end
    gui.new(name, function()
        gui.align(alignx, aligny)
        gui.table(3, 0, function()
            if not notitle then
                -- upper left corner
                gui.stretched_image(get_image_path("corner_upper_left.png"), 0.01, 0.025)
                -- upper edge
                gui.clamp(1, 1, 0, 0)
                gui.stretched_image(get_image_path("window_background.png"), 0, 0.025, function()
                    gui.clamp(1, 1, 0, 0)
                    gui.window_mover(function()
                        gui.clamp(1, 1, 0, 0)
                        gui.color(0, 0, 0, 0, 0, 0, function()
                            gui.clamp(1, 1, 0, 0)
                            gui.tag("title", function()
                                gui.align(0, 0)
                                gui.label(title)
                            end)
                        end)
                    end)
                    if not noclose() then
                        gui.button(
                            function()
                                gui.hide(name)
                            end, function()
                                gui.align(1, 0)
                                -- idle state
                                gui.stretched_image(get_icon_path("icon_close.png"), 0.024, 0.024)
                                -- hover state
                                gui.stretched_image(get_icon_path("icon_close.png"), 0.024, 0.024, hover)
                                -- selected state
                                gui.stretched_image(get_icon_path("icon_close.png"), 0.024, 0.024, selected)
                            end
                        )
                    end
                end)
                -- upper right corner
                gui.stretched_image(get_image_path("corner_upper_right.png"), 0.01, 0.025)
            else
                -- upper left corner
                gui.stretched_image(get_image_path("corner_upper_left_small.png"), 0.01, 0.01)
                -- upper edge
                gui.stretched_image(get_image_path("window_background.png"), 0, 0.01, function()
                    gui.clamp(1, 1, 0, 0)
                    gui.window_mover(function()
                        gui.clamp(1, 1, 0, 0)
                        gui.color(0, 0, 0, 0, 0, 0.01, function()
                            gui.clamp(1, 1, 0, 0)
                        end)
                    end)
                end)
                -- upper right corner
                gui.stretched_image(get_image_path("corner_upper_right_small.png"), 0.01, 0.01)
            end

            -- left edge
            gui.stretched_image(get_image_path("window_background.png"), 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- body
            gui.stretched_image(get_image_path("window_background_alt.png"), 0, 0, function()
                gui.clamp(1, 1, 1, 1)
                gui.space(0.01, 0.01, function()
                    gui.align(0, 0)
                    body()
                end)
            end)

            -- right edge
            gui.stretched_image(get_image_path("window_background.png"), 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- lower left corner
            gui.stretched_image(get_image_path("corner_lower_left.png"), 0.01, 0.01)
            -- lower edge
            gui.stretched_image(get_image_path("window_background.png"), 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- lower right corner
            gui.stretched_image(get_image_path("corner_lower_right.png"), 0.01, 0.01)
        end)
    end, nofocus, onhide)
end

--[[!
    Function: space
    Creates a "space" which is basically a big transparent
    window over the whole screen. Used as a "canvas" for
    icon bars in the edit mode and the main menu.

    Parameters:
        name - space name.
        body - space body.
        hasfocus - optional boolean value, setting it to true
        results in the space catching focus, which is sometimes
        needed (mainmenu).
        onhide - optional callback function called when the
        space gets hidden.
]]
function space(name, body, hasfocus, onhide)
    gui.new(name, function()
        gui.align(-1, 0)
        gui.fill(EVAR.scr_w / EVAR.scr_h, 1, function() body() end)
    end, not hasfocus, onhide)
end
