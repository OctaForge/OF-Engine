--[[!
    File: library/core/tgui/widgets/cherad.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides checkboxes and radioboxes.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    checkboxes, radioboxes and derived.
]]
module("tgui", package.seeall)

--[[!
    Function: checkbox
    Creates a checkbox, that is sort of button that toggles a variable
    from 0 to 1 and vice versa. See also <radiobox>.

    Parameters:
        var - name of the variable to toggle (either global or engine var).
        label - checkbox label.
]]
function checkbox(var, label)
    gui.hlist(0, function()
        gui.align(-1, 0)
        gui.toggle(
            function()
                return EV[var] and EV[var] ~= 0
            end,
            function()
                EV[var] = (type(EV[var]) == "number")
                        and ((EV[var] == 0)
                            and 1 or 0
                        ) or (not EV[var])
            end,
            0,
            function()
                -- idle state false
                gui.stretched_image(
                    get_image_path("check_base.png"), 0.020, 0.020
                )
                -- hovering state false
                gui.stretched_image(
                    get_image_path("check_base.png"), 0.020, 0.020, hover
                )
                -- idle state true
                gui.stretched_image(
                    get_image_path("check_checked.png"), 0.020, 0.020
                )
                -- hovering state true
                gui.stretched_image(
                    get_image_path("check_checked.png"), 0.020, 0.020, hover
                )
            end
        )
        gui.offset(0.02, 0, function()
            gui.label(label)
        end)
    end)
end

--[[!
    Function: radio_base
    A local function serving as a graphical base for <radiobox> and
    <resolutionbox>.
]]
local function radio_base()
    -- idle state false
    gui.stretched_image(get_image_path("radio_base.png"), 0.020, 0.020)
    -- hovering state false
    gui.stretched_image(get_image_path("radio_base.png"), 0.020, 0.020, hover)
    -- idle state true
    gui.stretched_image(get_image_path("radio_checked.png"), 0.020, 0.020)
    -- hovering state true
    gui.stretched_image(get_image_path("radio_checked.png"), 0.020, 0.020, hover)
end

--[[!
    Function: radiobox
    Creates a radiobox, which is simillar to <checkbox>, but it allows you
    to select which value of the variable is considered "true" and that
    way create a group of radioboxes to toggle between.
    See also <radio_base> and <resolutionbox>.

    Parameters:
        var - name of the variable to toggle (either global or engine var).
        value - the value of the variable that is required for the radiobox
        to display in "true" state, also the value the radiobox sets on click.
        label - radiobox label.
]]
function radiobox(var, value, label)
    gui.hlist(0, function()
        gui.align(-1, 0)
        gui.toggle(
            function()
                return EV[var] and EV[var] == value
            end,
            function()
                EV[var] = value
            end,
            0, radio_base
        )
        gui.offset(0.02, 0, function()
            gui.label(label)
        end)
    end)
end

--[[!
    Function: resolutionbox
    Looks like <radiobox> and is meant for switching screen
    resolutions. The resolutionbox will have a label in
    format "SCR_WxSCR_H".

    Parameters:
        w - screen width that is required for the resolutionbox to
        display in "true" state, also the value the resolutionbox
        sets on click.
        h - see above, just this is screen height.
]]
function resolutionbox(w, h)
    gui.hlist(0, function()
        gui.align(-1, 0)
        gui.toggle(
            function()
                return (EV.scr_w == w and EV.scr_h == h)
            end,
            function()
                EV["scr_w"] = w
                EV["scr_h"] = h
            end,
            0, radio_base
        )
        gui.offset(0.02, 0, function()
            gui.label(w .. "x" .. h)
        end)
    end)
end
