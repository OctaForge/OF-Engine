local signal = require("core.events.signal")
local gui = require("core.gui.core")
local cs = require("core.engine.cubescript")

local world = gui.get_world()

local i = 0

world:new_window("main", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("Main menu")
    win:append(gui.V_Box(), |b| do
        b:append(gui.H_Box(), |b| do
            b:append(gui.Menu_Button { label = "Menu 1" }, |b| do
                signal.connect(b, "clicked", || do
                    b:show_menu(gui.Filler { min_w = 0.3, min_h = 0.5, variant = "menu" }, true)
                end)
            end)
            b:append(gui.Menu_Button { label = "Menu 2" }, |mb| do
                local menu = gui.Filler { min_w = 0.3, min_h = 0.5, variant = "menu" }
                signal.connect(mb, "hovering", || mb:show_menu(menu))
            end)
            b:append(gui.Menu_Button { label = "Menu 3" }, |b| do
                signal.connect(b, "clicked", || do
                    b:show_menu(gui.Filler {
                        min_w = 0.3, min_h = 0.5, variant = "menu",
                        gui.V_Box { clamp_h = true,
                            gui.Menu_Button {
                                label = "Submenu 1", clamp_h = true,
                                __init = |mb| do
                                    local menu = gui.Filler {
                                        min_w = 0.2, min_h = 0.3, variant = "menu",
                                        gui.Menu_Button {
                                            label = "Subsubmenu 1", clamp_h = true,
                                            __init = |mb| do
                                                local menu = gui.Filler {
                                                    min_w = 0.2, min_h = 0.3, variant = "menu",
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
                                label = "Submenu 2", clamp_h = true, variant = "submenu",
                                __init = |mb| do
                                    local menu = gui.Filler { min_w = 0.2, min_h = 0.3, variant = "menu" }
                                    signal.connect(mb, "hovering", || mb:show_menu(menu))
                                end
                            }
                        }
                    })
                end)
            end)
        end)

        b:append(gui.Label { text = "This is some transparent text", color = 0x64FFFFFF })
        b:append(gui.Label { text = "Different text", color = 0xFF0000 })
        b:append(gui.Eval_Label {
            func = || do
                i = i + 1
                return i
            end
        })

        local ed
        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0.005 }, |s| do
            s:append(gui.Grid { columns = 2 }, |gr| do
                gr:append(gui.Field { clip_w = 0.4, clip_h = 0.3, value = [[
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
                gr:append(gui.V_Scrollbar { clamp_v = true },
                    |sb| sb:bind_scroller(ed))
                gr:append(gui.H_Scrollbar { clamp_h = true },
                    |sb| sb:bind_scroller(ed))
            end)
        end)

        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0.005 }, |s| do
            s:append(gui.H_Box { padding = 0.01 }, |hb| do
                local tvar, tvar2 = false, false
                hb:append(gui.Toggle { variant = "checkbox", condition = || tvar }, |t| do
                    signal.connect(t, "released", || do tvar = not tvar end)
                end)
                hb:append(gui.Label { text = "A checkbox" })
                hb:append(gui.Toggle { variant = "checkbox", condition = || tvar2 }, |t| do
                    signal.connect(t, "released", || do tvar2 = not tvar2 end)
                end)
                hb:append(gui.Label { text = "Another one" })
            end)
        end)

        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0.005 }, |s| do
            s:append(gui.V_Box { padding = 0.01 }, |vb| do
                local tvar = 1
                vb:append(gui.H_Box { padding = 0.01 }, |hb| do
                    hb:append(gui.Toggle { variant = "radiobutton",
                        condition = || tvar == 1
                    }, |t| do
                        signal.connect(t, "released", || do tvar = 1 end)
                    end)
                    hb:append(gui.Label { text = "Radiobutton 1" })
                end)
                vb:append(gui.H_Box { padding = 0.01 }, |hb| do
                    hb:append(gui.Toggle { variant = "radiobutton",
                        condition = || tvar == 2
                    }, |t| do
                        signal.connect(t, "released", || do tvar = 2 end)
                    end)
                    hb:append(gui.Label { text = "Radiobutton 2" })
                end)
                vb:append(gui.H_Box { padding = 0.01 }, |hb| do
                    hb:append(gui.Toggle { variant = "radiobutton",
                        condition = || tvar == 3
                    }, |t| do
                        signal.connect(t, "released", || do tvar = 3 end)
                    end)
                    hb:append(gui.Label { text = "Radiobutton 3" })
                end)
            end)
        end)

        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0.005 }, |s| do
            s:append(gui.Button { label = "A button" }, |b| do
                local ttip = gui.Filler {
                    variant = "tooltip", label = "Reset editor"
                }
                signal.connect(b, "released", || ed:reset_value())
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
            sp:append(gui.Eval_Label { scale = -1,
                func = || cs_execute("getedithud") }):align(-1, 0)
        end)
    end)
end)
