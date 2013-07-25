--[[! File: lua/core/gui/default.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Some default menus.
]]

local capi = require("capi")
local signal = require("core.events.signal")
local gui = require("core.gui.core")

local world = gui.get_world()

world:new_window("changes", gui.Window, function(win)
    win:append(gui.Color_Filler { r = 0, g = 0, b = 0, a = 192,
    min_w = 0.3, min_h = 0.2 }, function(r)
        r:clamp(true, true, true, true)
        win:append(gui.V_Box { padding = 0.01 }, function(box)
            box:append(gui.Label { text = "Changes" })
            box:append(gui.Label { text = "Apply changes?" })
            for i, v in ipairs(gui.changes_get()) do
                box:append(gui.Label { text = v })
            end
            box:append(gui.H_Box { padding = 0.01 }, function(hb)
                hb:append(gui.Button(), function(btn)
                    btn:update_state("default",
                        btn:update_state("hovering",
                            btn:update_state("clicked", gui.Color_Filler {
                                r = 64, g = 64, b = 64,
                                min_w = 0.2, min_h = 0.05,
                                gui.Label { text = "OK" } })))
                    signal.connect(btn, "click", function()
                        world:hide_window("changes")
                        gui.changes_apply()
                    end)
                end)
                hb:append(gui.Button(), function(btn)
                    btn:update_state("default",
                        btn:update_state("hovering",
                            btn:update_state("clicked", gui.Color_Filler {
                                r = 64, g = 64, b = 64,
                                min_w = 0.2, min_h = 0.05,
                                gui.Label { text = "Cancel" } })))
                    signal.connect(btn, "click", function()
                        world:hide_window("changes")
                        gui.changes_clear()
                    end)
                end)
            end)
        end)
    end)
end)

world:new_window("textures", gui.Window, function(win)
    win:append(gui.Color_Filler { r = 0, g = 0, b = 0, a = 192,
    min_w = 0.3, min_h = 0.2 }, function(r)
        r:clamp(true, true, true, true)
        win:append(gui.V_Box { padding = 0.01 }, function(box)
            box:append(gui.Label { text = "Textures" })
            box:append(gui.Grid { columns = 9, padding = 0.01 }, function(t)
                for i = 1, capi.slot_get_count() do
                    t:append(gui.Button(), function(btn)
                        btn:update_state("default",
                            btn:update_state("hovering",
                                btn:update_state("clicked", gui.Slot_Viewer {
                                    index = i - 1, min_w = 0.095,
                                    min_h = 0.095 })))
                        signal.connect(btn, "click", function()
                            capi.slot_set(i - 1)
                        end)
                    end)
                end
            end)
            box:append(gui.Button(), function(btn)
                btn:update_state("default",
                    btn:update_state("hovering",
                        btn:update_state("clicked", gui.Color_Filler {
                            r = 64, g = 64, b = 64,
                            min_w = 0.2, min_h = 0.05,
                            gui.Label { text = "Close" } })))
                signal.connect(btn, "click", function()
                    world:hide_window("textures")
                end)
            end)
        end)
    end)
end)
