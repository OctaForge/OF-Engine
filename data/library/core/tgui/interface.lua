module("tgui", package.seeall)

TAB_HORIZONTAL = 1
TAB_VERTICAL   = 2

TAB_DEFAULT = 1
TAB_EDIT    = 2

local space_was_shown = false

local __tab_storage = {}
local __tab_curr_v  = nil
local __tab_curr_h  = nil

function push_tab(title, direction, mode, icon, body)
    table.insert(__tab_storage, { title, direction, mode, icon, body, false })
    return #__tab_storage
end

function show_tab(id)
    local tab = __tab_storage[id]
    if    tab then
        local tname = (tab[2] == TAB_VERTICAL) and "vtab" or "htab"
        gui.show(tname)
        gui.replace(tname, "body",  tab[5])
        gui.replace(tname, "title", function()
            gui.align(0, 0)
            gui.label(tab[1])
        end)
        tab[6] = true

        if tab[2] == TAB_VERTICAL then
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
    local tab_name = (direction == TAB_HORIZONTAL) and "htab" or "vtab"
    gui.show   (tab_name)
    gui.replace(tab_name, "title", function()
        gui.align(0, 0)
        gui.label(title)
    end)
    gui.replace(tab_name, "body",  function()
        body()
    end)
end

function tab_area(edit)
    -- vertical tab area
    gui.space(0.01, 0.01, function()
        gui.align(-1, -1)

        -- draw its background first
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretchedimage(image_path .. "corner_upper_left_small.png", 0.01, 0.01)
            -- upper edge
            gui.stretchedimage(image_path .. "window_background.png", 0.05, 0.01)
            -- upper right corner
            gui.stretchedimage(image_path .. "corner_upper_right_small.png", 0.01, 0.01)
            -- left edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0.5)
            -- center
            gui.stretchedimage(image_path .. "window_background_alt.png", 0.05, 0.5)
            -- right edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0.5)
            -- lower left corner
            gui.stretchedimage(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretchedimage(image_path .. "window_background.png", 0.05, 0.01)
            -- lower right corner
            gui.stretchedimage(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)

        -- now draw the scroller
        gui.fill(0.07, 0.52, function()
            gui.scroll(0.05, 0.475, function()
                gui.align(0, 0)
                gui.fill(0.05, 0.475, function()
                    gui.vlist(0, function()
                        gui.align(0, -1)
                        for i, v in pairs(__tab_storage) do
                            if v[2] == TAB_VERTICAL and ((edit and v[3] == TAB_EDIT) or (not edit and v[3] == TAB_DEFAULT)) then
                                gui.button(
                                    function()
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
                                            gui.stretchedimage(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- hover
                                        gui.space(0, 0.005, function()
                                            gui.stretchedimage(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- selected
                                        gui.space(0, 0.005, function()
                                            gui.stretchedimage(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- shown over selected
                                        gui.cond(
                                            function()
                                                return v[6]
                                            end, function()
                                                gui.stretchedimage(
                                                    image_path .. "tab_icon_over.png",
                                                    0.05, 0.05
                                                )
                                            end
                                        )
                                    end
                                )
                            end
                        end
                    end)
                end)
            end)
            gui.vscrollbar(0.05, 0.5, function()
                -- both arrows idle
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_up.png", 0.05, 0.015)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_down.png", 0.05, 0.015)
                end)

                -- up arrow hover
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_up.png", 0.05, 0.015, hover)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_down.png", 0.05, 0.015)
                end)

                -- up arrow selected
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_up.png", 0.05, 0.015, selected)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_down.png", 0.05, 0.015)
                end)

                -- down arrow hover
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_up.png", 0.05, 0.015)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_down.png", 0.05, 0.015, hover)
                end)

                -- down arrow selected
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_up.png", 0.05, 0.015)
                    -- vertical bar
                    gui.fill(0.05, 0.475)
                    -- down arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_down.png", 0.05, 0.015, selected)
                end)
            end)
        end)
    end)

    -- horizontal tab area
    gui.space(0.01, 0.01, function()
        gui.align(1, 1)

        -- draw its background first
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretchedimage(image_path .. "corner_upper_left_small.png", 0.01, 0.01)
            -- upper edge
            gui.stretchedimage(image_path .. "window_background.png", 0.5, 0.01)
            -- upper right corner
            gui.stretchedimage(image_path .. "corner_upper_right_small.png", 0.01, 0.01)
            -- left edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0.05)
            -- center
            gui.stretchedimage(image_path .. "window_background_alt.png", 0.5, 0.05)
            -- right edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0.05)
            -- lower left corner
            gui.stretchedimage(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretchedimage(image_path .. "window_background.png", 0.5, 0.01)
            -- lower right corner
            gui.stretchedimage(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)

        -- now draw the scroller
        gui.fill(0.52, 0.07, function()
            gui.scroll(0.475, 0.05, function()
                gui.align(0, 0)
                gui.fill(0.475, 0.05, function()
                    gui.hlist(0, function()
                        gui.align(-1, 0)
                        for i, v in pairs(__tab_storage) do
                            if v[2] == TAB_HORIZONTAL and ((edit and v[3] == TAB_EDIT) or (not edit and v[3] == TAB_DEFAULT)) then
                                gui.button(
                                    function()
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
                                            gui.stretchedimage(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- hover
                                        gui.space(0.005, 0, function()
                                            gui.stretchedimage(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- selected
                                        gui.space(0.005, 0, function()
                                            gui.stretchedimage(
                                                image_path .. "icons/" .. v[4] .. ".png",
                                                0.04, 0.04
                                            )
                                        end)

                                        -- shown over selected
                                        gui.cond(
                                            function()
                                                return v[6]
                                            end, function()
                                                gui.stretchedimage(
                                                    image_path .. "tab_icon_over.png",
                                                    0.05, 0.05
                                                )
                                            end
                                        )
                                    end
                                )
                            end
                        end
                    end)
                end)
            end)
            gui.hscrollbar(0.05, 0.5, function()
                -- both arrows idle
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_left.png", 0.015, 0.05)
                    -- horizontal bar
                    gui.fill(0.475, 0.05)
                    -- right arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_right.png", 0.015, 0.05)
                end)

                -- left arrow hover
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_left.png", 0.015, 0.05, hover)
                    -- horizontal bar
                    gui.fill(0.475, 0.05)
                    -- right arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_right.png", 0.015, 0.05)
                end)

                -- left arrow selected
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_left.png", 0.015, 0.05, selected)
                    -- horizontal bar
                    gui.fill(0.475, 0.05)
                    -- right arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_right.png", 0.015, 0.05)
                end)

                -- right arrow hover
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_left.png", 0.015, 0.05)
                    -- horizontal bar
                    gui.fill(0.475, 0.05)
                    -- right arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_right.png", 0.015, 0.05, hover)
                end)

                -- right arrow selected
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_left.png", 0.015, 0.05)
                    -- horizontal bar
                    gui.fill(0.475, 0.05)
                    -- right arrow
                    gui.stretchedimage(image_path .. "button_scrollblock_right.png", 0.015, 0.05, selected)
                end)
            end)
        end)
    end)
end

space("space", function()
        gui.hide("vtab")
        gui.hide("htab")
        tab_area(true)
    end, false, function()
        gui.hide("vtab")
        gui.hide("htab")
    end
)

space("main", function()
        space_was_shown = gui.hide("space")
        gui.hide("vtab")
        gui.hide("htab")
        tab_area(false)
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
            gui.stretchedimage(image_path .. "corner_upper_left.png", 0.01, 0.025)
            -- upper edge
            gui.stretchedimage(image_path .. "window_background.png", 0, 0.025, function()
                gui.clamp(1, 1, 0, 0)
                gui.tag("title", function() end)
                gui.button(
                    function()
                        gui.hide("vtab")
                    end, function()
                        gui.align(1, 0)
                        -- idle state
                        gui.stretchedimage(image_path .. "close_icon.png", 0.024, 0.024)
                        -- hover state
                        gui.stretchedimage(image_path .. "close_icon.png", 0.024, 0.024, hover)
                        -- selected state
                        gui.stretchedimage(image_path .. "close_icon.png", 0.024, 0.024, selected)
                    end
                )
            end)
            -- upper right corner
            gui.stretchedimage(image_path .. "corner_upper_right.png", 0.01, 0.025)

            -- left edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- body
            gui.stretchedimage(image_path .. "window_background_alt.png", 0, 0, function()
                gui.clamp(1, 1, 1, 1)
                gui.space(0.01, 0.01, function()
                    gui.tag("body", function() end)
                end)
            end)

            -- right edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- lower left corner
            gui.stretchedimage(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretchedimage(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- lower right corner
            gui.stretchedimage(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)
    end)
end, 1, 0, function()
    if __tab_curr_v then
        __tab_curr_v[6] = false
    end
end)

gui.new("htab", function()
    gui.align(1, 1)
    gui.table(2, 0, function()
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretchedimage(image_path .. "corner_upper_left.png", 0.01, 0.025)
            -- upper edge
            gui.stretchedimage(image_path .. "window_background.png", 0, 0.025, function()
                gui.clamp(1, 1, 0, 0)
                gui.tag("title", function() end)
                gui.button(
                    function()
                        gui.hide("htab")
                    end, function()
                        gui.align(1, 0)
                        -- idle state
                        gui.stretchedimage(image_path .. "close_icon.png", 0.024, 0.024)
                        -- hover state
                        gui.stretchedimage(image_path .. "close_icon.png", 0.024, 0.024, hover)
                        -- selected state
                        gui.stretchedimage(image_path .. "close_icon.png", 0.024, 0.024, selected)
                    end
                )
            end)
            -- upper right corner
            gui.stretchedimage(image_path .. "corner_upper_right.png", 0.01, 0.025)

            -- left edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- body
            gui.stretchedimage(image_path .. "window_background_alt.png", 0, 0, function()
                gui.clamp(1, 1, 1, 1)
                gui.space(0.01, 0.01, function()
                    gui.tag("body", function() end)
                end)
            end)

            -- right edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- lower left corner
            gui.stretchedimage(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretchedimage(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- lower right corner
            gui.stretchedimage(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)
        gui.fill(0.01, 0)

        -- space on the bottom
        gui.fill(0,    0.09, function() gui.clamp(1, 1, 0, 0) end)
        gui.fill(0,    0.09, function() gui.clamp(1, 1, 0, 0) end)
    end)
end, 1, 0, function()
    if __tab_curr_h then
        __tab_curr_h[6] = false
    end
end)
