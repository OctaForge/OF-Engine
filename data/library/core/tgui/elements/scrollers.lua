--[[!
    File: library/core/tgui/elements/scrollers.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides complex scroller widget for tgui.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    complex scrollers with horizontal and vertical scrollbars.
]]
module("tgui", package.seeall)

--[[!
    Function: scrollbox
    Creates a scrollbox, that is <gui.scroll> with vertical and
    horizontal scroll bars.

    Parameters:
        width - scrollbox width in percent, from 0.0 to 1.0.
        height - scrollbox height in percent, from 0.0 to 1.0.
        body - function defining scrollbox contents.
]]
function scrollbox(width, height, body)
    local function draw_scrollbar(horizontal)
        local sf = horizontal and gui.hscrollbar or gui.vscrollbar
        local lf = horizontal and gui.hlist      or gui.vlist
        sf(0.020, 1, function()
            -- both arrows idle
            gui.fill(
                horizontal and 0 or 0.020,
                horizontal and 0.020 or 0,
                function()
                    lf(0, function()
                        -- up / left arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_left.png"
                                or  "scrollbar_up.png"
                            ),
                            0.020, 0.020
                        )
                        -- vertical bar
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_horizontal.png"
                                or  "scrollbar_vertical.png"
                            ),
                            horizontal
                                and (width - 0.04)
                                or 0.020,
                            horizontal
                                and 0.020
                                or (height - 0.04)
                        )
                        -- down / right arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_right.png"
                                or  "scrollbar_down.png"
                            ),
                            0.020, 0.020
                        )
                    end)
                end
            )

            -- up / left arrow hover
            gui.fill(
                horizontal and 0 or 0.020,
                horizontal and 0.020 or 0,
                function()
                    lf(0, function()
                        -- up / left arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_left.png"
                                or  "scrollbar_up.png"
                            ),
                            0.020, 0.020, hover
                        )
                        -- vertical bar
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_horizontal.png"
                                or  "scrollbar_vertical.png"
                            ),
                            horizontal
                                and (width - 0.04)
                                or 0.020,
                            horizontal
                                and 0.020
                                or (height - 0.04)
                        )
                        -- down / right arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_right.png"
                                or  "scrollbar_down.png"
                            ),
                            0.020, 0.020
                        )
                    end)
                end
            )

            -- up / left arrow selected
            gui.fill(
                horizontal and 0 or 0.020,
                horizontal and 0.020 or 0,
                function()
                    lf(0, function()
                        -- up / left arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_left.png"
                                or  "scrollbar_up.png"
                            ),
                            0.020, 0.020, selected
                        )
                        -- vertical bar
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_horizontal.png"
                                or  "scrollbar_vertical.png"
                            ),
                            horizontal
                                and (width - 0.04)
                                or 0.020,
                            horizontal
                                and 0.020
                                or (height - 0.04)
                        )
                        -- down / right arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_right.png"
                                or  "scrollbar_down.png"
                            ),
                            0.020, 0.020
                        )
                    end)
                end
            )

            -- down / right arrow hover
            gui.fill(
                horizontal and 0 or 0.020,
                horizontal and 0.020 or 0,
                function()
                    lf(0, function()
                        -- up / left arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_left.png"
                                or  "scrollbar_up.png"
                            ),
                            0.020, 0.020
                        )
                        -- vertical bar
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_horizontal.png"
                                or  "scrollbar_vertical.png"
                            ),
                            horizontal
                                and (width - 0.04)
                                or 0.020,
                            horizontal
                                and 0.020
                                or (height - 0.04)
                        )
                        -- down / right arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_right.png"
                                or  "scrollbar_down.png"
                            ),
                            0.020, 0.020, hover
                        )
                    end)
                end
            )

            -- down / right arrow selected
            gui.fill(
                horizontal and 0 or 0.020,
                horizontal and 0.020 or 0,
                function()
                    lf(0, function()
                        -- up / left arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_left.png"
                                or  "scrollbar_up.png"
                            ),
                            0.020, 0.020
                        )
                        -- vertical bar
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_horizontal.png"
                                or  "scrollbar_vertical.png"
                            ),
                            horizontal
                                and (width - 0.04)
                                or 0.020,
                            horizontal
                                and 0.020
                                or (height - 0.04)
                        )
                        -- down / right arrow
                        gui.stretched_image(
                            get_image_path(horizontal
                                and "scrollbar_right.png"
                                or  "scrollbar_down.png"
                            ),
                            0.020, 0.020, selected
                        )
                    end)
                end
            )

            gui.scroll_button(function()
                local w = horizontal and 0     or 0.020
                local h = horizontal and 0.020 or 0
                -- scroll_button idle
                gui.stretched_image(
                    get_image_path(horizontal
                        and "scrollbar_button_horizontal.png"
                        or  "scrollbar_button_vertical.png"
                    ), w, h, function()
                        if horizontal then
                            gui.clamp(1, 1, 0, 0)
                        else
                            gui.clamp(0, 0, 1, 1)
                        end
                    end
                )
                -- scroll_button hover
                gui.stretched_image(
                    get_image_path(horizontal
                        and "scrollbar_button_horizontal.png"
                        or  "scrollbar_button_vertical.png"
                    ), w, h, function()
                        if horizontal then
                            gui.clamp(1, 1, 0, 0)
                        else
                            gui.clamp(0, 0, 1, 1)
                        end
                        hover()
                    end
                )
                -- scroll_button selected
                gui.stretched_image(
                    get_image_path(horizontal
                        and "scrollbar_button_horizontal.png"
                        or  "scrollbar_button_vertical.png"
                    ), w, h, function()
                        if horizontal then
                            gui.clamp(1, 1, 0, 0)
                        else
                            gui.clamp(0, 0, 1, 1)
                        end
                        selected()
                    end
                )
            end)
        end)
    end

    gui.table(4, 0, function()
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.color(1, 1, 1, 0.1, width, height, function()
            gui.scroll(  width - 0.020, height - 0.020, function()
                gui.fill(width - 0.020, height - 0.020, function()
                    body()
                end)
            end)
        end)

        draw_scrollbar(false)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        draw_scrollbar(true)
        gui.color(1, 1, 1, 0.1, 0.020, 0.020)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
    end)
end
