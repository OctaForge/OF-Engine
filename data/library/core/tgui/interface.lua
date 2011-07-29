--[[!
    File: tgui/interface.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Tabbed interface system for TGUI.
]]

--[[!
    Package: tgui
    Tabbed Graphical User Interface. Default UI system for OctaForge, taking
    tabbed approach of controlling.
]]
module("tgui", package.seeall)

BAR_HORIZONTAL = 1
BAR_VERTICAL   = 2

BAR_NORMAL = 1
BAR_EDIT   = 2
BAR_ALL    = 3

local space_was_shown = false

local __tab_storage = {}
local __tab_curr_v  = nil
local __tab_curr_h  = nil

local __action_storage = {}

function push_tab(title, direction, mode, icon, body)
    table.insert(__tab_storage, { title, direction, mode, icon, body, false })
    return #__tab_storage
end

function show_tab(id)
    local tab = __tab_storage[id]
    if    tab then
        local tname = (tab[2] == BAR_VERTICAL) and "vtab" or "htab"
        gui.show(tname)
        gui.replace(tname, "body",  tab[5])
        gui.replace(tname, "title", function()
            gui.align(0, 0)
            gui.label(tab[1])
        end)
        tab[6] = true

        if tab[2] == BAR_VERTICAL then
            if  __tab_curr_v then
                __tab_curr_v[6] = false
            end
            __tab_curr_v = tab
        else
            if  __tab_curr_h then
                __tab_curr_h[6] = false
            end
            __tab_curr_h = tab
        end
    end
end

function show_custom_tab(title, direction, body)
    local tab_name = (direction == BAR_HORIZONTAL) and "htab" or "vtab"
    gui.show   (tab_name)
    gui.replace(tab_name, "title", function()
        gui.align(0, 0)
        gui.label(title)
    end)
    gui.replace(tab_name, "body",  function()
        body()
    end)
end

function push_action(direction, mode, icon, action)
    table.insert(__action_storage, { direction, mode, icon, action })
end

function tab_area(edit, gui_name, info_area)
    -- vertical tab area
    gui.space(0.01, 0.01, function()
        gui.align(-1, -1)

        -- draw its background first
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretched_image(image_path .. "corner_upper_left_small.png", 0.01, 0.01)
            -- upper edge
            gui.stretched_image(image_path .. "window_background.png", 0.05, 0.01)
            -- upper right corner
            gui.stretched_image(image_path .. "corner_upper_right_small.png", 0.01, 0.01)
            -- left edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0.5)
            -- center
            gui.stretched_image(image_path .. "window_background_alt.png", 0.05, 0.5)
            -- right edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0.5)
            -- lower left corner
            gui.stretched_image(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretched_image(image_path .. "window_background.png", 0.05, 0.01)
            -- lower right corner
            gui.stretched_image(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)

        -- now draw the scroller
        gui.fill(0.07, 0.52, function()
            gui.scroll(0.05, 0.475, function()
                gui.align(0, 0)
                gui.fill(0.05, 0.475, function()
                    gui.vlist(0, function()
                        gui.align(0, -1)
                        for i, v in pairs(__tab_storage) do
                            if v[2] == BAR_VERTICAL and ((edit and v[3] == BAR_EDIT) or (not edit and v[3] == BAR_NORMAL) or v[3] == BAR_ALL) then
                                gui.button(
                                    function()
                                        if  v[6] then
                                            v[6] = false
                                            gui.hide("vtab")
                                            __tab_curr_v = nil
                                            return nil
                                        end
                                        gui.show("vtab")
                                        gui.replace("vtab", "body",  v[5])
                                        gui.replace("vtab", "title", function()
                                            gui.align(0, 0)
                                            gui.label(v[1])
                                        end)
                                        v[6] = true
                                        if  __tab_curr_v then
                                            __tab_curr_v[6] = false
                                        end
                                        __tab_curr_v = v
                                    end, function()
                                        -- idle
                                        gui.space(0, 0.005, function()
                                            gui.stretched_image(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- hover
                                        gui.space(0, 0.005, function()
                                            gui.stretched_image(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- selected
                                        gui.space(0, 0.005, function()
                                            gui.stretched_image(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- shown over selected
                                        gui.cond(
                                            function()
                                                return v[6]
                                            end, function()
                                                gui.stretched_image(
                                                    image_path .. "tab_icon_over.png",
                                                    0.05, 0.05
                                                )
                                            end
                                        )
                                    end
                                )
                            end
                        end
                        for i, v in pairs(__action_storage) do
                            if v[1] == BAR_VERTICAL and ((edit and v[2] == BAR_EDIT) or (not edit and v[2] == BAR_NORMAL) or v[2] == BAR_ALL) then
                                gui.button(v[4], function()
                                    -- idle
                                    gui.space(0, 0.005, function()
                                        gui.stretched_image(
                                            image_path .. "icons/" .. v[3] .. ".png",
                                            0.04, 0.04
                                        )
                                    end)

                                    -- hover
                                    gui.space(0, 0.005, function()
                                        gui.stretched_image(
                                            image_path .. "icons/" .. v[3] .. ".png",
                                            0.04, 0.04
                                        )
                                    end)

                                    -- selected
                                    gui.space(0, 0.005, function()
                                        gui.stretched_image(
                                            image_path .. "icons/" .. v[3] .. ".png",
                                            0.04, 0.04
                                        )
                                        gui.stretched_image(
                                            image_path .. "tab_icon_over.png",
                                            0.05, 0.05
                                        )
                                    end)
                                end)
                            end
                        end
                    end)
                end)
            end)
            gui.vscrollbar(0.05, 0.5, function()
                -- both arrows idle
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "button_scrollblock_up.png", 0.05, 0.015)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretched_image(image_path .. "button_scrollblock_down.png", 0.05, 0.015)
                end)

                -- up arrow hover
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "button_scrollblock_up.png", 0.05, 0.015, hover)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretched_image(image_path .. "button_scrollblock_down.png", 0.05, 0.015)
                end)

                -- up arrow selected
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "button_scrollblock_up.png", 0.05, 0.015, selected)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretched_image(image_path .. "button_scrollblock_down.png", 0.05, 0.015)
                end)

                -- down arrow hover
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "button_scrollblock_up.png", 0.05, 0.015)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretched_image(image_path .. "button_scrollblock_down.png", 0.05, 0.015, hover)
                end)

                -- down arrow selected
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "button_scrollblock_up.png", 0.05, 0.015)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretched_image(image_path .. "button_scrollblock_down.png", 0.05, 0.015, selected)
                end)
            end)
        end)
    end)

    -- horizontal tab area
    gui.space(0.01, 0.01, function()
        gui.align(1, 1)
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretched_image(image_path .. "corner_upper_left_small.png", 0.01, 0.01)
            -- upper edge
            gui.stretched_image(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- upper right corner
            gui.stretched_image(image_path .. "corner_upper_right_small.png", 0.01, 0.01)
            -- left edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0.05)
            -- center
            gui.stretched_image(image_path .. "window_background_alt.png", 0, 0.05, function()
                gui.clamp(1, 1, 0, 0)
                -- create a horizontal list, left part storing the scrollbox
                gui.hlist(0, function()
                    -- store the scrollbox in a fill so the scrollbar works properly
                    gui.fill(0.47, 0.05, function()
                        -- now draw the scroller
                        gui.scroll(0.47, 0.05, function()
                            gui.align(0, 0)
                            gui.fill(0.47, 0.05, function()
                                gui.hlist(0, function()
                                    gui.align(-1, 0)
                                    for i, v in pairs(__tab_storage) do
                                        if v[2] == BAR_HORIZONTAL and ((edit and v[3] == BAR_EDIT) or (not edit and v[3] == BAR_NORMAL) or v[3] == BAR_ALL) then
                                            gui.button(
                                                function()
                                                    if  v[6] then
                                                        v[6] = false
                                                        gui.hide("htab")
                                                        __tab_curr_h = nil
                                                        return nil
                                                    end
                                                    gui.show("htab")
                                                    gui.replace("htab", "body",  v[5])
                                                    gui.replace("htab", "title", function()
                                                        gui.align(0, 0)
                                                        gui.label(v[1])
                                                    end)
                                                    v[6] = true
                                                    if  __tab_curr_h then
                                                        __tab_curr_h[6] = false
                                                    end
                                                    __tab_curr_h = v
                                                end, function()
                                                    -- idle
                                                    gui.space(0.005, 0, function()
                                                        gui.stretched_image(
                                                            image_path .. "icons/" .. v[4] .. ".png",
                                                            0.04, 0.04
                                                        )
                                                    end)

                                                    -- hover
                                                    gui.space(0.005, 0, function()
                                                        gui.stretched_image(
                                                            image_path .. "icons/" .. v[4] .. ".png",
                                                            0.04, 0.04
                                                        )
                                                    end)

                                                    -- selected
                                                    gui.space(0.005, 0, function()
                                                        gui.stretched_image(
                                                            image_path .. "icons/" .. v[4] .. ".png",
                                                            0.04, 0.04
                                                        )
                                                    end)

                                                    -- shown over selected
                                                    gui.cond(
                                                        function()
                                                            return v[6]
                                                        end, function()
                                                            gui.stretched_image(
                                                                image_path .. "tab_icon_over.png",
                                                                0.05, 0.05
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    end
                                    for i, v in pairs(__action_storage) do
                                        if v[1] == BAR_HORIZONTAL and ((edit and v[2] == BAR_EDIT) or (not edit and v[2] == BAR_NORMAL) or v[2] == BAR_ALL) then
                                            gui.button(v[4], function()
                                                -- idle
                                                gui.space(0, 0.005, function()
                                                    gui.stretched_image(
                                                        image_path .. "icons/" .. v[3] .. ".png",
                                                        0.04, 0.04
                                                    )
                                                end)

                                                -- hover
                                                gui.space(0, 0.005, function()
                                                    gui.stretched_image(
                                                        image_path .. "icons/" .. v[3] .. ".png",
                                                        0.04, 0.04
                                                    )
                                                end)

                                                -- selected
                                                gui.space(0, 0.005, function()
                                                    gui.stretched_image(
                                                        image_path .. "icons/" .. v[3] .. ".png",
                                                        0.04, 0.04
                                                    )
                                                    gui.stretched_image(
                                                        image_path .. "tab_icon_over.png",
                                                        0.05, 0.05
                                                    )
                                                end)
                                            end)
                                        end
                                    end
                                end)
                            end)
                        end)
                        gui.hscrollbar(0.05, 0.5, function()
                            -- both arrows idle
                            gui.hlist(0, function()
                                -- left arrow
                                gui.stretched_image(image_path .. "button_scrollblock_left.png", 0.015, 0.05)
                                -- horizontal bar
                                gui.fill(0.47, 0.05)
                                -- right arrow
                                gui.stretched_image(image_path .. "button_scrollblock_right.png", 0.015, 0.05)
                            end)

                            -- left arrow hover
                            gui.hlist(0, function()
                                -- left arrow
                                gui.stretched_image(image_path .. "button_scrollblock_left.png", 0.015, 0.05, hover)
                                -- horizontal bar
                                gui.fill(0.47, 0.05)
                                -- right arrow
                                gui.stretched_image(image_path .. "button_scrollblock_right.png", 0.015, 0.05)
                            end)

                            -- left arrow selected
                            gui.hlist(0, function()
                                -- left arrow
                                gui.stretched_image(image_path .. "button_scrollblock_left.png", 0.015, 0.05, selected)
                                -- horizontal bar
                                gui.fill(0.47, 0.05)
                                -- right arrow
                                gui.stretched_image(image_path .. "button_scrollblock_right.png", 0.015, 0.05)
                            end)

                            -- right arrow hover
                            gui.hlist(0, function()
                                -- left arrow
                                gui.stretched_image(image_path .. "button_scrollblock_left.png", 0.015, 0.05)
                                -- horizontal bar
                                gui.fill(0.47, 0.05)
                                -- right arrow
                                gui.stretched_image(image_path .. "button_scrollblock_right.png", 0.015, 0.05, hover)
                            end)

                            -- right arrow selected
                            gui.hlist(0, function()
                                -- left arrow
                                gui.stretched_image(image_path .. "button_scrollblock_left.png", 0.015, 0.05)
                                -- horizontal bar
                                gui.fill(0.47, 0.05)
                                -- right arrow
                                gui.stretched_image(image_path .. "button_scrollblock_right.png", 0.015, 0.05, selected)
                            end)
                        end)
                    end)
                    -- this part will be storing FPS information etc.
                    gui.fill(0, 0, function()
                        if type(info_area) == "function" then
                            gui.tag("info_area", info_area)
                            gui.cond(
                                function()
                                    gui.replace(gui_name, "info_area", info_area)
                                end,
                                function() end
                            )
                        end
                    end)
                end)
            end)
            -- right edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0.05)
            -- lower left corner
            gui.stretched_image(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretched_image(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- lower right corner
            gui.stretched_image(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)
    end)
end

local lastfps = 0
local prevfps = { 0, 0, 0 }
local curfps  = { 0, 0, 0 }

function show_info_area()
    if not world.has_map() then
        return nil
    end

    local info_label = ""

    if showfps ~= 0 then
        local totalmillis = GLOBAL_TIME * 1000

        if (totalmillis - lastfps) >= statrate then
            prevfps = { curfps[1], curfps[2], curfps[3] }
            lastfps = totalmillis - (totalmillis % statrate)
        end

        local nextfps = { engine.get_fps() }
        for i = 1, 3 do
            if prevfps[i] == curfps[i] then
                curfps[i] = nextfps[i]
            end
        end

        if showfpsrange ~= 0 then
            info_label = " fps %(1)i+%(2)i-%(3)i " % { curfps[1], curfps[2], curfps[3] }
        else
            info_label = " fps %(1)i " % { curfps[1] }
        end
    end

    local wall_clock_val = engine.get_wall_clock()
    if wall_clock_val then
        info_label = info_label .. "\n %(1)s " % { wall_clock_val }
    end

    gui.label(info_label, 0.8)
end

space("space", function()
        gui.hide("vtab")
        gui.hide("htab")
        tab_area(true, "space", show_info_area)
    end, false, function()
        gui.hide("vtab")
        gui.hide("htab")
    end
)

space("main", function()
        space_was_shown = gui.hide("space")
        gui.hide("vtab")
        gui.hide("htab")
        tab_area(false, "main", show_info_area)
    end, true, function()
        gui.hide("vtab")
        gui.hide("htab")
        if space_was_shown then
            gui.show("space")
            space_was_shown = false
        end
    end
)

gui.new("vtab", function()
    gui.align(-1, -1)
    gui.table(2, 0, function()
        -- space on the top
        gui.fill(0.09, 0.01)
        gui.fill(0,    0.01, function() gui.clamp(1, 1, 0, 0) end)

        -- space on the left
        gui.fill(0.09, 0, function() gui.clamp(0, 0, 1, 1) end)

        gui.table(3, 0, function()
            -- upper left corner
            gui.stretched_image(image_path .. "corner_upper_left.png", 0.01, 0.025)
            -- upper edge
            gui.stretched_image(image_path .. "window_background.png", 0, 0.025, function()
                gui.clamp(1, 1, 0, 0)
                gui.tag("title", function() end)
                gui.button(
                    function()
                        gui.hide("vtab")
                    end, function()
                        gui.align(1, 0)
                        -- idle state
                        gui.stretched_image(image_path .. "icons/icon_close.png", 0.024, 0.024)
                        -- hover state
                        gui.stretched_image(image_path .. "icons/icon_close.png", 0.024, 0.024, hover)
                        -- selected state
                        gui.stretched_image(image_path .. "icons/icon_close.png", 0.024, 0.024, selected)
                    end
                )
            end)
            -- upper right corner
            gui.stretched_image(image_path .. "corner_upper_right.png", 0.01, 0.025)

            -- left edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- body
            gui.stretched_image(image_path .. "window_background_alt.png", 0, 0, function()
                gui.clamp(1, 1, 1, 1)
                gui.space(0.01, 0.01, function()
                    gui.tag("body", function() end)
                end)
            end)

            -- right edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- lower left corner
            gui.stretched_image(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretched_image(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- lower right corner
            gui.stretched_image(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)
    end)
end, 1, 0, function()
    if __tab_curr_v then
        __tab_curr_v[6] = false
        __tab_curr_v    = nil
    end
end)

gui.new("htab", function()
    gui.align(1, 1)
    gui.table(2, 0, function()
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretched_image(image_path .. "corner_upper_left.png", 0.01, 0.025)
            -- upper edge
            gui.stretched_image(image_path .. "window_background.png", 0, 0.025, function()
                gui.clamp(1, 1, 0, 0)
                gui.tag("title", function() end)
                gui.button(
                    function()
                        gui.hide("htab")
                    end, function()
                        gui.align(1, 0)
                        -- idle state
                        gui.stretched_image(image_path .. "icons/icon_close.png", 0.024, 0.024)
                        -- hover state
                        gui.stretched_image(image_path .. "icons/icon_close.png", 0.024, 0.024, hover)
                        -- selected state
                        gui.stretched_image(image_path .. "icons/icon_close.png", 0.024, 0.024, selected)
                    end
                )
            end)
            -- upper right corner
            gui.stretched_image(image_path .. "corner_upper_right.png", 0.01, 0.025)

            -- left edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- body
            gui.stretched_image(image_path .. "window_background_alt.png", 0, 0, function()
                gui.clamp(1, 1, 1, 1)
                gui.space(0.01, 0.01, function()
                    gui.tag("body", function() end)
                end)
            end)

            -- right edge
            gui.stretched_image(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- lower left corner
            gui.stretched_image(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretched_image(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- lower right corner
            gui.stretched_image(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)
        gui.fill(0.01, 0)

        -- space on the bottom
        gui.fill(0,    0.09, function() gui.clamp(1, 1, 0, 0) end)
        gui.fill(0,    0.09, function() gui.clamp(1, 1, 0, 0) end)
    end)
end, 1, 0, function()
    if __tab_curr_h then
        __tab_curr_h[6] = false
        __tab_curr_h    = nil
    end
end)
