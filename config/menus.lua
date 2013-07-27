local signal = require("core.events.signal")
local gui = require("core.gui.core")

local world = gui.get_world()

gui.Button.states = {
    default = gui.Outline {
        r = 0, g = 0, b = 0, min_w = 0.2, min_h = 0.03,
        gui.Label { text = "Idle" }
    },

    hovering = gui.Outline {
        r = 0, g = 0, b = 255, min_w = 0.2, min_h = 0.03,
        gui.Label { text = "Hovering" }
    },

    clicked = gui.Color_Filler {
        min_w = 0.2, min_h = 0.03, r = 255, g = 0, b = 255,
        gui.Label { text = "Clicked" }
    }
}

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
            b:append(gui.Mover(), |mover| do
                mover:clamp(true, true, true, true)
                mover:append(gui.Color_Filler { r = 255, g = 0, b = 0, a = 200, min_h = 0.03 }, |r| do
                    r:clamp(true, true, true, true)
                    r:append(gui.Label { text = "Window title" }, |l| do
                        l:align(0, 0)
                    end)
                end)
            end)

            b:append(gui.H_Box(), |b| do
                b:append(gui.Button(), |b| do
                    b:set_menu(gui.Color_Filler {
                        min_w = 0.3, min_h = 0.5, r = 128, g = 0, b = 0, a = 192
                    })
                end)
                b:append(gui.Button(), |b| do
                    b:set_menu(gui.Color_Filler {
                        min_w = 0.3, min_h = 0.5, r = 0, g = 218, b = 0, a = 192
                    })
                end)
                b:append(gui.Button(), |b| do
                    b:set_menu(gui.Color_Filler {
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
                b:append(gui.Field { length = 30, value = "butts" }, |x|do
                    x:clamp(true, true, true, true)
                    ed = x
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

require("core.engine.cubescript").execute [[ bind ESCAPE [ lua [
    local world = require("core.gui.core").get_world()
    if not world:hide_window("main") then world:show_window("main") end
] ] ]]
