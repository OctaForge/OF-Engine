local signal = require("core.events.signal")
local gui = require("core.gui.core")
local cs = require("core.engine.cubescript")

local world = gui.get_world()

--[[
local test_states = function()
    gui.Button:update_class_states {
        default = gui.Color_Filler {
            min_w = 0.2, min_h = 0.05, r = 64, g = 32, b = 192,
            gui.Label { text = "Different idle" }
        },
    
        hovering = gui.Color_Filler {
            min_w = 0.2, min_h = 0.05, r = 0, g = 50, b = 150,
            gui.Label { text = "Different hovering" }
        },
    
        clicked = gui.Color_Filler {
            min_w = 0.2, min_h = 0.05, r = 128, g = 192, b = 225,
            gui.Label { text = "Different clicked" }
        }
    }
end

local append_hud = function()
    gui.get_hud():append(gui.Color_Filler { r = 255, b = 0, g = 0, min_w = 0.3, min_h = 0.4 }, function(r) r:align(-1, 0) end)
end
]]

local i = 0

world:new_window("main", gui.Window, |win| do
    win:set_variant("noborder")
    win:set_floating(true)
    local r = win

    r:align(0, 0)
    r:append(gui.V_Box(), |b| do
        b:append(gui.H_Box(), |b| do
            b:append(gui.Menu_Button { label = "Menu 1" }, |b| do
                signal.connect(b, "clicked", || do
                    b:show_menu(gui.Color_Filler {
                        min_w = 0.3, min_h = 0.5, r = 0, g = 218, b = 0, a = 192
                    }, true)
                end)
            end)
            b:append(gui.Menu_Button { label = "Menu 2" }, |mb| do
                local menu = gui.Color_Filler {
                    min_w = 0.3, min_h = 0.5, r = 8, g = 8, b = 8, a = 240
                }
                signal.connect(mb, "hovering", || mb:show_menu(menu))
            end)
            b:append(gui.Menu_Button { label = "Menu 3" }, |b| do
                signal.connect(b, "clicked", || do
                    b:show_menu(gui.Color_Filler {
                        min_w = 0.3, min_h = 0.5, r = 8, g = 8, b = 8, a = 240,
                        gui.V_Box {
                            clamp_l = true, clamp_r = true,
                            gui.Menu_Button {
                                label = "Submenu 1",
                                clamp_l = true, clamp_r = true,
                                __init = |mb| do
                                    local menu = gui.Color_Filler {
                                        min_w = 0.2, min_h = 0.3, r = 8, g = 8,
                                        b = 8, a = 240,
                                        gui.Menu_Button {
                                            label = "Subsubmenu 1",
                                            clamp_l = true, clamp_r = true,
                                            __init = |mb| do
                                                local menu = gui.Color_Filler {
                                                    min_w = 0.2, min_h = 0.3,
                                                    r = 8, g = 8, b = 8, a = 240,
                                                    gui.Label { text = "Butts!" }
                                                }
                                                signal.connect(mb, "hovering", || mb:show_menu(menu))
                                            end,
                                            variant = "submenu"
                                        }
                                    }
                                    signal.connect(mb, "hovering", || mb:show_menu(menu))
                                end,
                                variant = "submenu"
                            },
                            gui.Menu_Button {
                                label = "Submenu 2",
                                clamp_l = true, clamp_r = true,
                                __init = |mb| do
                                    local menu = gui.Color_Filler {
                                        min_w = 0.2, min_h = 0.3, r = 0, g = 0,
                                        b = 192, a = 192
                                    }
                                    signal.connect(mb, "hovering", || mb:show_menu(menu))
                                end,
                                variant = "submenu"
                            }
                        }
                    })
                end)
            end)
        end)

        b:append(gui.Label { text = "This is some transparent text", a = 100 })
        b:append(gui.Label { text = "Different text", r = 255, g = 0, b = 0 })
        b:append(gui.Eval_Label {
            func = || do
                i = i + 1
                return i
            end
        })

        local ed
        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0.005 }, |s| do
            s:append(gui.Field { clip_w = 0.4, clip_h = 0.3, value = [[
Lorem ipsum dolor sit amet, consectetur
adipisicing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation
ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit
in voluptate velit esse cillum dolore eu fugiat
nulla pariatur. Excepteur sint occaecat cupidatat
non proident, sunt in culpa qui officia deserunt
mollit anim id est laborum.
Lorem ipsum dolor sit amet, consectetur
adipisicing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation
ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit
in voluptate velit esse cillum dolore eu fugiat
nulla pariatur. Excepteur sint occaecat cupidatat
non proident, sunt in culpa qui officia deserunt
mollit anim id est laborum.]], multiline = true }, |x| do
                ed = x
            end)
        end)

        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0.005 }, |s| do
            s:append(gui.Button { label = "A button" }, |b| do
                local ttip = gui.Color_Filler {
                    min_w = 0.2, min_h = 0.05, r = 128, g = 128, b = 128, a = 128
                }
                ttip:append(gui.Label { text = "Reset editor" })
                signal.connect(b, "clicked",  || ed:reset_value())
                signal.connect(b, "hovering", || b:show_tooltip(ttip))
            end)
        end)
    end)
end)

local var_get = cs.var_get
local cs_execute = cs.execute

world:new_window("fullconsole", gui.Overlay, |win| do
    win:clamp(true, true, false, false)
    win:align(0, -1)
    win:append(gui.Console {
        min_h = || var_get("fullconsize") / 100
    }, |con| do
        con:clamp(true, true, false, false)
    end)
end)

world:new_window("editstats", gui.Overlay, |win| do
    win:align(-1, 1)
    win:set_above_hud(true)
    win:append(gui.V_Box(), |box| do
        box:append(gui.Spacer { pad_h = 0.02, pad_v = 0.02 }, |sp| do
            sp:append(gui.Eval_Label { scale = 1,
                func = || cs_execute("getedithud") }):align(-1, 0)
        end)
    end)
end)
