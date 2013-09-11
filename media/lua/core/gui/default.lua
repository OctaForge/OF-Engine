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

-- buttons

local btnv = { __properties = { "label" } }
gui.Button.__variants = { default = btnv }

local btnv_init_clone = |self, btn| do
    local lbl = gui.Label { text = btn.label }
    self:append(lbl)
    signal.connect(btn, "label_changed", |b, t| do lbl:set_text(t) end)
end

local btn_build_variant = |r, g, b| gui.Gradient {
    r = 0, g = 0, b = 0, r2 = 48, g2 = 48, b2 = 48, clamp_h = true,
    gui.Outline {
        r = r, g = g, b = b, clamp_h = true, gui.Spacer {
            pad_h = 0.01, pad_v = 0.005, init_clone = btnv_init_clone
        }
    }
}

local btn_build_variant_nobg = || gui.Filler {
    clamp_h = true, gui.Spacer {
        pad_h = 0.01, pad_v = 0.005, init_clone = btnv_init_clone
    }
}

btnv["default"     ] = btn_build_variant(255, 255, 255)
btnv["hovering"    ] = btn_build_variant(225, 225, 225)
btnv["clicked_left"] = btn_build_variant(192, 192, 192)

local mbtnv, smbtnv =
    { __properties  = { "label" } },
    { __properties  = { "label" } }
gui.Menu_Button.__variants = { default = mbtnv, submenu = smbtnv }

mbtnv["default"     ] = btn_build_variant_nobg()
mbtnv["hovering"    ] = btn_build_variant_nobg()
mbtnv["menu"        ] = btn_build_variant(192, 192, 192)
mbtnv["clicked_left"] = btn_build_variant(192, 192, 192)

smbtnv["default"     ] = btn_build_variant_nobg()
smbtnv["hovering"    ] = btn_build_variant(192, 192, 192)
smbtnv["menu"        ] = btn_build_variant(192, 192, 192)
smbtnv["clicked_left"] = btn_build_variant(192, 192, 192)

-- editors

gui.Text_Editor.__variants = {
    default = {
        gui.Color_Filler {
            r = 48, g = 48, b = 48, clamp = true, gui.Outline { clamp = true }
        },
        __init = |ed| do
            ed:set_pad_l(0.005)
            ed:set_pad_r(0.005)
        end
    }
}
gui.Field.__variants     = gui.Text_Editor.__variants
gui.Key_Field.__variants = gui.Text_Editor.__variants

-- menus

gui.Filler.__variants = {
    menu = {
        gui.Gradient {
            r = 8, g = 8, b = 8, r2 = 24, g2 = 24, b2 = 24, a = 250, a2 = 250,
            clamp = true, gui.Outline {
                r = 255, g = 255, b = 255, clamp = true
            }
        }
    }
}

-- checkboxes, radioboxes

local ckbox_build_variant = |r, g, b, tgl| gui.Color_Filler {
    r = 16, g = 16, b = 16, min_w = 0.02, min_h = 0.02,
    gui.Outline {
        r = r, g = g, b = b, clamp = true, tgl and gui.Spacer {
            pad_h = 0.005, pad_v = 0.005, clamp = true, gui.Color_Filler {
                clamp = true, r = 192, g = 192, b = 192,
                gui.Outline { r = r, g = g, b = b, clamp = true }
            }
        } or nil
    }
}

local rdbtn_build_variant = |r, g, b, tgl| gui.Circle {
    r = 16, g = 16, b = 16, min_w = 0.02, min_h = 0.02,
    gui.Circle {
        style = gui.Circle.OUTLINE, r = r, g = g, b = b, clamp = true,
        tgl and gui.Spacer {
            pad_h = 0.005, pad_v = 0.005, clamp = true, gui.Circle {
                clamp = true, r = 192, g = 192, b = 192,
                gui.Circle { style = gui.Circle.OUTLINE,
                    r = r, g = g, b = b, clamp = true
                }
            }
        } or nil
    }
}

local ckboxv, rdbtnv = {}, {}

gui.Toggle.__variants = {
    checkbox = ckboxv,
    radiobutton = rdbtnv
}

ckboxv["default"         ] = ckbox_build_variant(255, 255, 255)
ckboxv["default_hovering"] = ckbox_build_variant(225, 225, 225)
ckboxv["toggled"         ] = ckbox_build_variant(192, 192, 192, true)
ckboxv["toggled_hovering"] = ckbox_build_variant(225, 225, 225, true)
rdbtnv["default"         ] = rdbtn_build_variant(255, 255, 255)
rdbtnv["default_hovering"] = rdbtn_build_variant(225, 225, 225)
rdbtnv["toggled"         ] = rdbtn_build_variant(192, 192, 192, true)
rdbtnv["toggled_hovering"] = rdbtn_build_variant(225, 225, 225, true)

-- windows

gui.Window.__variants = {
    borderless = {
        gui.Gradient {
            r = 8, g = 8, b = 8, r2 = 32, g2 = 32, b2 = 32, a = 230, a2 = 230,
            clamp = true, gui.Outline {
                r = 255, g = 255, b = 255, clamp = true,
                gui.Spacer {
                    pad_h = 0.005, pad_v = 0.005, init_clone = |self, win| do
                        win:set_container(self)
                    end
                }
            }
        }
    },
    regular = {
        __properties = { "title" },
        gui.Filler {
            clamp = true,
            gui.V_Box {
                clamp = true,
                gui.Gradient {
                    r = 32, g = 32, b = 32, r2 = 8, g2 = 8, b2 = 8,
                    a = 230, a2 = 230, clamp_h = true,
                    gui.Spacer {
                        pad_h = 0.004, pad_v = 0.004,
                        init_clone = |self, win| do
                            local lbl = gui.Label { text = win.title
                                or win.obj_name }
                            self:append(lbl)
                            signal.connect(win, "title_changed",
                                |w, t| do lbl:set_text(t or w.obj_name) end)
                        end
                    },
                    gui.Spacer { pad_h = 0.009, align_h = 1,
                        gui.Button {
                            variant = false, states = {
                                default = gui.Gradient {
                                    r = 0, g = 0, b = 0, r2 = 48, g2 = 48,
                                    b2 = 48, min_w = 0.015, min_h = 0.015,
                                    gui.Outline { clamp = true }
                                },
                                hovering = gui.Gradient {
                                    r = 0, g = 0, b = 0, r2 = 48, g2 = 48,
                                    b2 = 48, min_w = 0.015, min_h = 0.015,
                                    gui.Outline { clamp = true,
                                        r = 225, g = 225, b = 225
                                    }
                                },
                                clicked_left = gui.Gradient {
                                    r = 0, g = 0, b = 0, r2 = 48, g2 = 48,
                                    b2 = 48, min_w = 0.015, min_h = 0.015,
                                    gui.Outline { clamp = true,
                                        r = 192, g = 192, b = 192
                                    }
                                }
                            },
                            init_clone = |self, win| do
                                signal.connect(self, "clicked", || win:hide())
                            end
                        }
                    }
                },
                gui.Gradient {
                    r = 8, g = 8, b = 8, r2 = 32, g2 = 32, b2 = 32,
                    a = 230, a2 = 230, clamp = true, gui.Spacer {
                        pad_h = 0.005, pad_v = 0.005,
                        init_clone = |self, win| do
                            win:set_container(self)
                        end
                    }
                },
                states = {
                    default = gui.Color_Filler { min_w = 0.05, min_h = 0.07 }
                }
            },
            gui.Outline { r = 255, g = 255, b = 255, clamp = true }
        }
    }
}

-- default windows

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
                hb:append(gui.Button { label = "OK" }, function(btn)
                    signal.connect(btn, "clicked", function()
                        world:hide_window("changes")
                        gui.changes_apply()
                    end)
                end)
                hb:append(gui.Button { label = "Cancel" }, function(btn)
                    signal.connect(btn, "clicked", function()
                        world:hide_window("changes")
                        gui.changes_clear()
                    end)
                end)
            end)
        end)
    end)
end)

world:new_window("texture", gui.Window, function(win)
    win:append(gui.Color_Filler { r = 0, g = 0, b = 0, a = 192,
    min_w = 0.3, min_h = 0.2 }, function(r)
        r:clamp(true, true, true, true)
        win:append(gui.V_Box { padding = 0.01 }, function(box)
            box:append(gui.Label { text = "Textures" })
            box:append(gui.Grid { columns = 9, padding = 0.01 }, function(t)
                for i = 1, capi.slot_get_count() do
                    t:append(gui.Button, function(btn)
                        btn:update_state("default",
                            btn:update_state("hovering",
                                btn:update_state("clicked", gui.Slot_Viewer {
                                    index = i - 1, min_w = 0.095,
                                    min_h = 0.095 })))
                        signal.connect(btn, "clicked", function()
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
                signal.connect(btn, "clicked", function()
                    world:hide_window("texture")
                end)
            end)
        end)
    end)
end)
