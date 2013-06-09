local signal = require("core.events.signal")
local gui = require("gui.core")

local world = gui.get_world()

gui.Button.states = {
    default = gui.Rectangle {
        min_w = 0.2, min_h = 0.05, r = 255, g = 255, b = 0,
        gui.Label { text = "Idle" }
    },

    hovering = gui.Rectangle {
        min_w = 0.2, min_h = 0.05, r = 255, g = 0, b = 0,
        gui.Label { text = "Hovering" }
    },

    clicked = gui.Rectangle {
        min_w = 0.2, min_h = 0.05, r = 255, g = 0, b = 255,
        gui.Label { text = "Clicked" }
    }
}

_G["test_update_states"] = function()
    gui.Button:update_class_states {
        default = gui.Rectangle {
            min_w = 0.2, min_h = 0.05, r = 64, g = 32, b = 192,
            gui.Label { text = "Different idle" }
        },
    
        hovering = gui.Rectangle {
            min_w = 0.2, min_h = 0.05, r = 0, g = 50, b = 150,
            gui.Label { text = "Different hovering" }
        },
    
        clicked = gui.Rectangle {
            min_w = 0.2, min_h = 0.05, r = 128, g = 192, b = 225,
            gui.Label { text = "Different clicked" }
        }
    }
end

_G["append_hud"] = function()
    gui.get_hud():append(gui.Rectangle { r = 255, b = 0, g = 0, min_w = 0.3, min_h = 0.4 }, function(r) r:align(-1, 0) end)
end

local i = 0

world:new_window("main", gui.Window, function(win)
    win:set_floating(true)
    win:append(gui.Rectangle { r = 96, g = 96, b = 255, a = 128 }, function(r)
        r:align(0, 0)
        r:append(gui.V_Box(), function(b)
            b:clamp(true, true, true, true)
            b:append(gui.Mover(), function(mover)
                mover:clamp(true, true, true, true)
                mover:append(gui.Rectangle { r = 255, g = 0, b = 0, a = 200, min_h = 0.03 }, function(r)
                    r:clamp(true, true, true, true)
                    r:append(gui.Label { text = "Window title" }, function(l)
                        l:align(0, 0)
                    end)
                end)
            end)
            b:append(gui.Label { text = "This is some transparent text", a = 100 })
            b:append(gui.Label { text = "Different text", r = 255, g = 0, b = 0 })
            b:append(gui.Eval_Label {
                func = function()
                    i = i + 1
                    return i
                end
            })

            b:append(gui.Spacer { pad_h = 0.005, pad_v = 0.005 }, function(s)
                s:append(gui.H_Box(), function(b)
                    b:append(gui.Button { label = "A button" }, function(b)
                        b:set_tooltip(gui.Rectangle {
                            min_w = 0.2, min_h = 0.05, r = 128, g = 128, b = 128, a = 128
                        })
                        b.tooltip:append(gui.Label { text = "A tooltip" })
                        signal.connect(b, "click", function()
                            echo "you clicked a button"
                        end)
                    end)
                    b:append(gui.Spacer { pad_h = 0.005 }, function(s)
                        s:append(gui.Label { text = "foo" })
                    end)
                end)
            end)
        end)
    end)
end)

_C.cubescript([[ bind ESCAPE [ lua [
    local world = require("gui.core").get_world()
    if not world:hide_window("main") then world:show_window("main") end
] ] ]])
