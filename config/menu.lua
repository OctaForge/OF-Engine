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
    win:set_floating(true)
    win:append(gui.Filler {
        gui.H_Box {
            clamp_l = true, clamp_r = true, clamp_b = true, clamp_t = true,
            gui.Gradient { min_w = 0.15, min_h = 0.05, horizontal = true,
                clamp_l = true, clamp_r = true, clamp_b = true, clamp_t = true,
                r2 = 255, g2 = 0, b2 = 0, r = 255, g = 255, b = 0
            },
            gui.Gradient { min_w = 0.15, min_h = 0.05, horizontal = true,
                clamp_l = true, clamp_r = true, clamp_b = true, clamp_t = true,
                r2 = 255, g2 = 255, b2 = 0, r = 0, g = 255, b = 0
            },
            gui.Gradient { min_w = 0.15, min_h = 0.05, horizontal = true,
                clamp_l = true, clamp_r = true, clamp_b = true, clamp_t = true,
                r2 = 0, g2 = 255, b2 = 0, r = 0, g = 0, b = 255
            },
            gui.Gradient { min_w = 0.15, min_h = 0.05, horizontal = true,
                clamp_l = true, clamp_r = true, clamp_b = true, clamp_t = true,
                r2 = 0, g2 = 0, b2 = 255, r = 143, g = 0, b = 255
            }
        }
    }, |r| do
        r:align(0, 0)
        r:append(gui.V_Box(), |b| do
            b:clamp(true, true, true, true)
            b:append(gui.Mover { window = win }, |mover| do
                mover:clamp(true, true, true, true)
                mover:append(gui.Color_Filler { r = 255, g = 0, b = 0, a = 200, min_h = 0.03 }, |r| do
                    r:clamp(true, true, true, true)
                    r:append(gui.Label { text = "Window title" }, |l| do
                        l:align(0, 0)
                    end)
                end)
            end)

            b:append(gui.H_Box(), |b| do
                b:append(gui.Menu_Button { label = "Menu 1" }, |b| do
                    b:set_menu_left(gui.Color_Filler {
                        min_w = 0.3, min_h = 0.5, r = 128, g = 0, b = 0, a = 192,
                        gui.V_Box {
                            gui.Menu_Button {
                                label = "Submenu 1",
                                menu_hover = gui.Color_Filler {
                                    min_w = 0.2, min_h = 0.3, r = 0, g = 192,
                                    b = 0, a = 192,
                                    gui.Menu_Button {
                                        label = "Subsubmenu 1",
                                        menu_hover = gui.Color_Filler {
                                            min_w = 0.2, min_h = 0.3, r = 192,
                                            g = 192, b = 0, a = 192,
                                            gui.Label { text = "Butts!" }
                                        },
                                        variant = "submenu"
                                    }
                                },
                                variant = "submenu"
                            },
                            gui.Menu_Button {
                                label = "Submenu 2",
                                menu_hover = gui.Color_Filler {
                                    min_w = 0.2, min_h = 0.3, r = 0, g = 0,
                                    b = 192, a = 192
                                },
                                variant = "submenu"
                            }
                        }
                    })
                end)
                b:append(gui.Menu_Button { label = "Menu 2" }, |b| do
                    b:set_menu_left(gui.Color_Filler {
                        min_w = 0.3, min_h = 0.5, r = 0, g = 218, b = 0, a = 192
                    })
                end)
                b:append(gui.Menu_Button { label = "Menu 3" }, |b| do
                    b:set_menu_left(gui.Color_Filler {
                        min_w = 0.3, min_h = 0.5, r = 0, g = 0, b = 128, a = 192
                    })
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

            local ed, lbl
            b:append(gui.H_Box(), |b| do
                b:append(gui.Outline(), |o| do
                    o:clamp(true, true, true, true)
                    o:append(gui.Field { clip_w = 0.4, clip_h = 0.3, value = [[
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
mollit anim id est laborum.
                    ]], multiline = true }, |x| do
                        x:clamp(true, true, true, true)
                        ed = x
                    end)
                end)
                b:append(gui.Label { text = "none" }, |l| do lbl = l end)
            end)

            b:append(gui.Spacer { pad_h = 0.005, pad_v = 0.005 }, |s| do
                s:append(gui.H_Box(), |b| do
                    b:append(gui.Button { label = "A button" }, |b| do
                        b:set_tooltip(gui.Color_Filler {
                            min_w = 0.2, min_h = 0.05, r = 128, g = 128, b = 128, a = 128
                        })
                        b.tooltip:append(gui.Label { text = "A tooltip" })
                        signal.connect(b, "click", || do
                            lbl:set_text(ed.value)
                        end)
                    end)
                    b:append(gui.Spacer { pad_h = 0.005 }, |s| do
                        s:append(gui.Label { text = "foo" })
                    end)
                end)
            end)
        end)
    end)
end)

local var_get = cs.var_get

world:new_window("fullconsole", gui.Overlay, |win| do
    win:clamp(true, true, false, false)
    win:align(0, -1)
    win:append(gui.Console {
        min_h = || var_get("fullconsize") / 100
    }, |con| do
        con:clamp(true, true, false, false)
    end)
end)

local cs_execute = cs.execute

cs_execute([=[
    edithudline1 = [edithud]
    edithudline2 = [format "cube %1%2" $selchildcount (if $showmat [selchildmat ": "])]
    edithudline3 = [format "wtr:%1k(%2%%) wvt:%3k(%4%%) evt:%5k eva:%6k" $editstatwtr $editstatvtr $editstatwvt $editstatvvt $editstatevt $editstateva]
    edithudline4 = [format "ond:%1 va:%2 gl:%3(%4) oq:%5 pvs:%6" $editstatocta $editstatva $editstatglde $editstatgeombatch $editstatoq $editstatpvs]
    getedithud = [ concatword (edithudline1) "^f7^n" (edithudline2) "^n" (edithudline3) "^n" (edithudline4) ]
]=])

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

cs_execute([=[
showui = [lua [
    return require("core.gui.core").get_world():show_window(@(escape $arg1))
]]
hideui = [lua [
    return require("core.gui.core").get_world():hide_window(@(escape $arg1))
]]
toggleui = [
    if (! (hideui $arg1)) [showui $arg1] []
]
holdui = [
    if (! $arg2) [hideui $arg1] [showui $arg1]
]
uivisible = [lua [
    return require("core.gui.core").get_world():window_visible(@(escape $arg1))
]]

toggleconsole = [toggleui fullconsole]

edittoggled = [
   if $editing [showui editstats] [hideui editstats]
]

bind ESCAPE [toggleui main]
]=])
