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
    This part of tgui (Tabbed Graphical User Interface) takes care of the
    tabbed interface itself.
]]
module("tgui", package.seeall)

--[[!
    Variable: BAR_HORIZONTAL
    When creating a tab or bar button, this is used to specify
    the button / tab belongs to the horizontal bar. See also
    <BAR_VERTICAL>.
]]
BAR_HORIZONTAL = 1

--[[!
    Variable: BAR_VERTICAL
    When creating a tab or bar button, this is used to specify
    the button / tab belongs to the vertical bar. See also
    <BAR_HORIZONTAL>.
]]
BAR_VERTICAL   = 2

--[[!
    Variable: BAR_NORMAL
    When creating a tab or bar button, this is used to specify
    that the button / tab should show up only in normal mode,
    not in edit mode. See also <BAR_EDIT> and <BAR_ALL>.
]]
BAR_NORMAL = 1

--[[!
    Variable: BAR_EDIT
    When creating a tab or bar button, this is used to specify
    that the button / tab should show up only in edit mode,
    not in normal mode. See also <BAR_NORMAL> and <BAR_ALL>.
]]
BAR_EDIT   = 2

--[[!
    Variable: BAR_ALL
    When creating a tab or bar button, this is used to specify
    that the button / tab should show up in both normal and
    edit mode. See also <BAR_NORMAL> and <BAR_EDIT>.
]]
BAR_ALL    = 3

-- "space" here refers to "canvas" on the screen to place tabs
-- and bars onto. It's basically a huge window taking no focus.
local space_was_shown = false

--[[!
    Variable: __tab_storage
    This is an internal array of arrays. Each element specifies
    a tab. Tab array has this format

    (start code)
        { TITLE_STRING, DIRECTION, MODE, ICON, BODY_FUNCTION, SHOWN }
    (end)

    where TITLE_STRING is tab title, DIRECTION is either <BAR_HORIZONTAL>
    or <BAR_VERTICAL>, mode is <BAR_NORMAL>, <BAR_EDIT> or <BAR_ALL>,
    icon is name of the icon in data/textures/ui/tgui/icons without
    extension, body is a function that actually shows the contents
    and SHOWN is a boolean value specifying whether the tab is shown now.

    See also <__action_storage>.
]]
local __tab_storage = {}

--[[!
    Variable: __tab_curr_v
    Internal variable specifying the vertical tab
    currently shown. See also <__tab_curr_h>.
]]
local __tab_curr_v  = nil

--[[!
    Variable: __tab_curr_h
    Internal variable specifying the horizontal
    tab currently shown. See also <__tab_curr_v>.
]]
local __tab_curr_h  = nil

--[[!
    Variable: __action_storage
    Simillar to <__tab_storage>, but this stores information for
    action buttons on the horizontal / vertical bar, not full tabs.

    The array has this format

    (start code)
         { DIRECTION, MODE, ICON, ACTION }
    (end)

    See <__tab_storage> for meanings. Action here refers to
    a function that is executed when you click the button.
]]
local __action_storage = {}

--[[!
    Function: push_tab
    Pushes a tab into <__tab_storage>. Look there for argument
    descriptions. Default for SHOWN is "false". The body
    function takes no arguments. This function returns one
    value and that is integral ID of the tab (useful with
    <show_tab>).
]]
function push_tab(title, direction, mode, icon, body)
    table.insert(__tab_storage, { title, direction, mode, icon, body, false })
    return #__tab_storage
end

--[[!
    Function: show_tab
    Shows a tab with ID given by the argument (see <push_tab>).
]]
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

--[[!
    Function: show_custom_tab
    Shows a custom tab, that is a tab that is not registered in
    <__tab_storage>. Meaning of title, direction and body is
    the same as for registered tabs.
]]
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

--[[!
    Function: push_action
    Equivalent of <push_tab> for <__action_storage>.
    For argument meanings, see <__action_storage>.
]]
function push_action(direction, mode, icon, action)
    table.insert(__action_storage, { direction, mode, icon, action })
end

--[[!
    Function: tab_area
    This serves as a body function for <space> (in
    edit mode) or <main> (in normal mode). It shows
    the horizontal and vertical button bars. Tabs then
    are separate windows. It also properly manages
    button events and other things.

    Parameters:
        edit - a boolean value specifying whether this is
        editmode tab area.
]]
function tab_area(edit)
    -- draw the background
    local function draw_bg(horizontal)
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretched_image(
                get_image_path("corner_upper_left_small.png"),
                0.01, 0.01
            )
            -- upper edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                horizontal and 0.5 or 0.05, 0.01
            )
            -- upper right corner
            gui.stretched_image(
                get_image_path("corner_upper_right_small.png"),
                0.01, 0.01
            )
            -- left edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                0.01, horizontal and 0.05 or 0.5
            )
            -- center
            gui.stretched_image(
                get_image_path("window_background_alt.png"),
                horizontal and 0.5  or 0.05,
                horizontal and 0.05 or 0.5
            )
            -- right edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                0.01, horizontal and 0.05 or 0.5
            )
            -- lower left corner
            gui.stretched_image(
                get_image_path("corner_lower_left.png"),
                0.01, 0.01
            )
            -- lower edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                horizontal and 0.5 or 0.05, 0.01
            )
            -- lower right corner
            gui.stretched_image(
                get_image_path("corner_lower_right.png"),
                0.01, 0.01
            )
        end)
    end

    -- draw a tab button
    local function draw_tab_button(horizontal, tab)
        local tn = horizontal and "htab" or "vtab"
    
        gui.button(
            function()
                if  tab[6] then
                    tab[6] = false
                    gui.hide(tn)

                    if horizontal then
                        __tab_curr_h = nil
                    else
                        __tab_curr_v = nil
                    end

                    return nil
                end

                gui.show(tn)
                gui.replace(tn, "body",  tab[5])
                gui.replace(tn, "title", function()
                    gui.align(0, 0)
                    gui.label(tab[1])
                end)

                tab[6] = true
                if horizontal then
                    if __tab_curr_h then
                       __tab_curr_h[6] = false
                    end
                    __tab_curr_h = tab
                    
                else
                    if __tab_curr_v then
                       __tab_curr_v[6] = false
                    end
                    __tab_curr_v = tab
                end
            end, function()
                -- idle
                local xs = horizontal and 0.005 or 0
                local ys = horizontal and 0     or 0.005
            
                gui.space(xs, ys, function()
                    gui.stretched_image(
                        get_icon_path(tab[4] .. ".png"),
                        0.04, 0.04
                    )
                end)

                -- hover
                gui.space(xs, ys, function()
                    gui.stretched_image(
                        get_icon_path(tab[4] .. ".png"),
                        0.04, 0.04
                    )
                end)

                -- selected
                gui.space(xs, ys, function()
                    gui.stretched_image(
                        get_icon_path(tab[4] .. ".png"),
                        0.04, 0.04
                    )
                end)

                -- shown over selected
                gui.cond(
                    function()
                        return tab[6]
                    end, function()
                        gui.stretched_image(
                            get_image_path("tab_icon_over.png"),
                            0.05, 0.05
                        )
                    end
                )
            end
        )
    end

    -- draw an action button
    local function draw_action_button(action)
        gui.button(action[4], function()
            -- idle
            gui.space(0, 0.005, function()
                gui.stretched_image(
                    get_icon_path(action[3] .. ".png"),
                    0.04, 0.04
                )
            end)

            -- hover
            gui.space(0, 0.005, function()
                gui.stretched_image(
                    get_icon_path(action[3] .. ".png"),
                    0.04, 0.04
                )
            end)

            -- selected
            gui.space(0, 0.005, function()
                gui.stretched_image(
                    get_icon_path(action[3] .. ".png"),
                    0.04, 0.04
                )
                gui.stretched_image(
                    get_image_path("tab_icon_over.png"),
                    0.05, 0.05
                )
            end)
        end)
    end

    -- draw a scrollbar
    local function draw_scrollbar(horizontal)
        local sb = horizontal and gui.hscrollbar or gui.vscrollbar
        local lf = horizontal and gui.hlist      or gui.vlist
        sb(
            horizontal and 0.5 or 0.05,
            horizontal and 0.05 or 0.5,
            function()
                -- both arrows idle
                lf(0, function()
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                                horizontal and "left" or "up" 
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015
                    )
                    gui.fill(
                        horizontal and 0.475 or 0.05,
                        horizontal and 0.05  or 0.475
                    )
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                            horizontal and "right" or "down"
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015
                    )
                end)

                -- up / left arrow hover
                lf(0, function()
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                                horizontal and "left" or "up" 
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015,
                        hover
                    )
                    gui.fill(
                        horizontal and 0.475 or 0.05,
                        horizontal and 0.05  or 0.475
                    )
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                            horizontal and "right" or "down"
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015
                    )
                end)

                -- up / left arrow selected
                lf(0, function()
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                                horizontal and "left" or "up" 
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015,
                        selected
                    )
                    gui.fill(
                        horizontal and 0.475 or 0.05,
                        horizontal and 0.05  or 0.475
                    )
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                            horizontal and "right" or "down"
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015
                    )
                end)

                -- down / right arrow hover
                lf(0, function()
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                                horizontal and "left" or "up" 
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015
                    )
                    gui.fill(
                        horizontal and 0.475 or 0.05,
                        horizontal and 0.05  or 0.475
                    )
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                            horizontal and "right" or "down"
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015,
                        hover
                    )
                end)

                -- down / right arrow selected
                lf(0, function()
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                                horizontal and "left" or "up" 
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015
                    )
                    gui.fill(
                        horizontal and 0.475 or 0.05,
                        horizontal and 0.05  or 0.475
                    )
                    gui.stretched_image(
                        get_image_path("button_scrollblock_%(1)s.png" % {
                            horizontal and "right" or "down"
                        }),
                        horizontal and 0.015 or 0.05,
                        horizontal and 0.05  or 0.015,
                        selected
                    )
                end)
            end
        )
    end

    -- vertical tab area
    gui.space(0.01, 0.01, function()
        gui.align(-1, -1)
        draw_bg(false)

        -- now draw the scroller
        gui.fill(0.07, 0.52, function()
            gui.scroll(0.05, 0.475, function()
                gui.align(0, 0)
                gui.fill(0.05, 0.475, function()
                    gui.vlist(0, function()
                        gui.align(0, -1)
                        for i, v in pairs(__tab_storage) do
                            if v[2] == BAR_VERTICAL
                            and (
                                (edit and v[3] == BAR_EDIT)
                             or (not edit and v[3] == BAR_NORMAL)
                             or v[3] == BAR_ALL
                            ) then
                                draw_tab_button(false, v)
                            end
                        end
                        for i, v in pairs(__action_storage) do
                            if v[1] == BAR_VERTICAL
                            and (
                                (edit and v[2] == BAR_EDIT)
                             or (not edit and v[2] == BAR_NORMAL)
                             or v[2] == BAR_ALL
                            ) then
                                draw_action_button(v)
                            end
                        end
                    end)
                end)
            end)
            draw_scrollbar(false)
        end)
    end)

    -- horizontal tab area
    gui.space(0.01, 0.01, function()
        gui.align(1, 1)
        draw_bg(true)

        -- now draw the scroller
        gui.fill(0.52, 0.07, function()
            gui.scroll(0.475, 0.05, function()
                gui.align(0, 0)
                gui.fill(0.475, 0.05, function()
                    gui.hlist(0, function()
                        gui.align(-1, 0)
                        for i, v in pairs(__tab_storage) do
                            if v[2] == BAR_HORIZONTAL
                            and (
                                (edit and v[3] == BAR_EDIT)
                             or (not edit and v[3] == BAR_NORMAL)
                             or v[3] == BAR_ALL
                            ) then
                                draw_tab_button(true, v)
                            end
                        end
                        for i, v in pairs(__action_storage) do
                            if v[1] == BAR_HORIZONTAL
                            and (
                                (edit and v[2] == BAR_EDIT)
                             or (not edit and v[2] == BAR_NORMAL)
                             or v[2] == BAR_ALL
                            ) then
                                draw_action_button(v)
                            end
                        end
                    end)
                end)
            end)
            draw_scrollbar(true)
        end)
    end)
end

--[[!
    Property: space
    This provides a "space" for edit mode. It's basically a window which
    is as big as the screen and contains the button bars created with
    <tab_area>. For non-edit mode, see <main>.
]]
space("space", function()
        gui.hide("vtab")
        gui.hide("htab")
        tab_area(true)
    end, false, function()
        gui.hide("vtab")
        gui.hide("htab")
    end
)

--[[!
    Property: main
    This provides a "space" for normal mode. It's basically a window which
    is as big as the screen and contains the button bars created with
    <tab_area>. For edit mode, see <space>. This is also displayed only
    when you want main menu displayed, not all the time. By default
    you toggle it with the ESC key.
]]
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

--[[!
    Property: vtab
    The vertical tab (the one belonging to buttons from vertical bar).
    It's a window holding two replaceable tags, title and body, and
    <tab_area> then makes use of it by dynamically replacing the title
    and body depending on what tab is currently meant to be shown.
    See also <htab>.
]]
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
            gui.stretched_image(
                get_image_path("corner_upper_left.png"), 0.01, 0.025
            )
            -- upper edge
            gui.stretched_image(
                get_image_path("window_background.png"), 0, 0.025, function()
                    gui.clamp(1, 1, 0, 0)
                    gui.window_mover(function()
                        gui.clamp(1, 1, 0, 0)
                        gui.color(0, 0, 0, 0, 0, 0, function()
                            gui.clamp(1, 1, 0, 0)
                            gui.tag("title", function() end)
                        end)
                    end)
                    gui.button(
                        function()
                            gui.hide("vtab")
                        end, function()
                            gui.align(1, 0)
                            -- idle state
                            gui.stretched_image(
                                get_icon_path("icon_close.png"),
                                0.024, 0.024
                            )
                            -- hover state
                            gui.stretched_image(
                                get_icon_path("icon_close.png"),
                                0.024, 0.024, hover
                            )
                            -- selected state
                            gui.stretched_image(
                                get_icon_path("icon_close.png"),
                                0.024, 0.024, selected
                            )
                        end
                    )
                end
            )
            -- upper right corner
            gui.stretched_image(
                get_image_path("corner_upper_right.png"), 0.01, 0.025
            )

            -- left edge
            gui.stretched_image(
                get_image_path("window_background.png"), 0.01, 0,
                function() gui.clamp(0, 0, 1, 1) end
            )
            -- body
            gui.stretched_image(
                get_image_path("window_background_alt.png"), 0, 0, function()
                    gui.clamp(1, 1, 1, 1)
                    gui.space(0.01, 0.01, function()
                        gui.tag("body", function() end)
                    end)
                end
            )
            -- right edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                0.01, 0, function() gui.clamp(0, 0, 1, 1) end
            )

            -- lower left corner
            gui.stretched_image(
                get_image_path("corner_lower_left.png"), 0.01, 0.01
            )
            -- lower edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                0, 0.01, function() gui.clamp(1, 1, 0, 0) end
            )
            -- lower right corner
            gui.stretched_image(
                get_image_path("corner_lower_right.png"), 0.01, 0.01
            )
        end)
    end)
end, false, function()
    if __tab_curr_v then
        __tab_curr_v[6] = false
        __tab_curr_v    = nil
    end
end)

--[[!
    Property: htab
    The horizontal tab (the one belonging to buttons from horizontal bar).
    It's a window holding two replaceable tags, title and body, and
    <tab_area> then makes use of it by dynamically replacing the title
    and body depending on what tab is currently meant to be shown.
    See also <vtab>.
]]
gui.new("htab", function()
    gui.align(1, 1)
    gui.table(2, 0, function()
        gui.table(3, 0, function()
            -- upper left corner
            gui.stretched_image(
                get_image_path("corner_upper_left.png"), 0.01, 0.025
            )
            -- upper edge
            gui.stretched_image(
                get_image_path("window_background.png"), 0, 0.025, function()
                    gui.clamp(1, 1, 0, 0)
                    gui.window_mover(function()
                        gui.clamp(1, 1, 0, 0)
                        gui.color(0, 0, 0, 0, 0, 0, function()
                            gui.clamp(1, 1, 0, 0)
                            gui.tag("title", function() end)
                        end)
                    end)
                    gui.button(
                        function()
                            gui.hide("htab")
                        end, function()
                            gui.align(1, 0)
                            -- idle state
                            gui.stretched_image(
                                get_icon_path("icon_close.png"),
                                0.024, 0.024
                            )
                            -- hover state
                            gui.stretched_image(
                                get_icon_path("icon_close.png"),
                                0.024, 0.024, hover
                            )
                            -- selected state
                            gui.stretched_image(
                                get_icon_path("icon_close.png"),
                                0.024, 0.024, selected
                            )
                        end
                    )
                end
            )
            -- upper right corner
            gui.stretched_image(
                get_image_path("corner_upper_right.png"), 0.01, 0.025
            )

            -- left edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                0.01, 0, function() gui.clamp(0, 0, 1, 1) end
            )
            -- body
            gui.stretched_image(
                get_image_path("window_background_alt.png"), 0, 0, function()
                    gui.clamp(1, 1, 1, 1)
                    gui.space(0.01, 0.01, function()
                        gui.tag("body", function() end)
                    end)
                end
            )
            -- right edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                0.01, 0, function() gui.clamp(0, 0, 1, 1) end
            )

            -- lower left corner
            gui.stretched_image(
                get_image_path("corner_lower_left.png"), 0.01, 0.01
            )
            -- lower edge
            gui.stretched_image(
                get_image_path("window_background.png"),
                0, 0.01, function() gui.clamp(1, 1, 0, 0) end
            )
            -- lower right corner
            gui.stretched_image(
                get_image_path("corner_lower_right.png"), 0.01, 0.01
            )
        end)
        gui.fill(0.01, 0)

        -- space on the bottom
        gui.fill(0, 0.09, function() gui.clamp(1, 1, 0, 0) end)
        gui.fill(0, 0.09, function() gui.clamp(1, 1, 0, 0) end)
    end)
end, false, function()
    if __tab_curr_h then
        __tab_curr_h[6] = false
        __tab_curr_h    = nil
    end
end)
