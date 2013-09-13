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

local Color = gui.Color

-- buttons

local btnv = { __properties = { "label", "min_w", "min_h" } }
gui.Button.__variants = { default = btnv }

local btnv_init_clone = |self, btn| do
    local lbl = gui.Label { text = btn.label }
    self:append(lbl)
    signal.connect(btn, "label_changed", |b, t| do lbl:set_text(t) end)
end

local btn_build_variant = |color| gui.Gradient {
    color = 0x0, color2 = 0x303030, clamp_h = true, init_clone = |self, btn| do
        self:set_min_w(btn.min_w or 0)
        self:set_min_h(btn.min_h or 0)
        signal.connect(btn, "min_w_changed", |b, v| self:set_min_w(v))
        signal.connect(btn, "min_h_changed", |b, v| self:set_min_w(v))
    end, gui.Outline {
        color = color, clamp_h = true, gui.Spacer {
            pad_h = 0.01, pad_v = 0.005, init_clone = btnv_init_clone
        }
    }
}

local btn_build_variant_nobg = || gui.Filler {
    clamp_h = true, gui.Spacer {
        pad_h = 0.01, pad_v = 0.005, init_clone = btnv_init_clone
    }
}

btnv["default"     ] = btn_build_variant(0xFFFFFF)
btnv["hovering"    ] = btn_build_variant(0xE1E1E1)
btnv["clicked_left"] = btn_build_variant(0xC0C0C0)

local mbtnv, smbtnv =
    { __properties  = { "label" } },
    { __properties  = { "label" } }
gui.Menu_Button.__variants = { default = mbtnv, submenu = smbtnv }

mbtnv["default"     ] = btn_build_variant_nobg()
mbtnv["hovering"    ] = btn_build_variant_nobg()
mbtnv["menu"        ] = btn_build_variant(0xC0C0C0)
mbtnv["clicked_left"] = btn_build_variant(0xC0C0C0)

smbtnv["default"     ] = btn_build_variant_nobg()
smbtnv["hovering"    ] = btn_build_variant(0xC0C0C0)
smbtnv["menu"        ] = btn_build_variant(0xC0C0C0)
smbtnv["clicked_left"] = btn_build_variant(0xC0C0C0)

-- editors

gui.Text_Editor.__variants = {
    default = {
        gui.Color_Filler {
            color = 0x202020, clamp = true, gui.Outline { clamp = true }
        },
        __init = |ed| do
            ed:set_pad_l(0.005)
            ed:set_pad_r(0.005)
        end
    }
}
gui.Field.__variants     = gui.Text_Editor.__variants
gui.Key_Field.__variants = gui.Text_Editor.__variants

-- menus, tooltips

gui.Filler.__variants = {
    menu = {
        gui.Gradient { color = 0xFA000000, color2 = 0xFA080808, clamp = true,
            gui.Outline { color = 0xFFFFFF, clamp = true }
        }
    },
    tooltip = {
        __properties = { "label" },
        gui.Gradient {
            color = 0xFA000000, color2 = 0xFA080808, gui.Outline {
                color = 0xFFFFFF, clamp = true, gui.Spacer {
                    pad_h = 0.01, pad_v = 0.005, init_clone = |self, ttip| do
                        local lbl = gui.Label { text = ttip.label }
                        self:append(lbl)
                        signal.connect(ttip, "label_changed", |o, t| do
                            o:set_text(t) end)
                    end
                }
            }
        }
    }
}

-- checkboxes, radioboxes

local ckbox_build_variant = |color, tgl| gui.Color_Filler {
    color = 0x101010, min_w = 0.02, min_h = 0.02,
    gui.Outline {
        color = color, clamp = true, tgl and gui.Spacer {
            pad_h = 0.005, pad_v = 0.005, clamp = true, gui.Color_Filler {
                clamp = true, color = 0xC0C0C0,
                gui.Outline { color = color, clamp = true }
            }
        } or nil
    }
}

local rdbtn_build_variant = |color, tgl| gui.Circle {
    color = 0x101010, min_w = 0.02, min_h = 0.02,
    gui.Circle {
        style = gui.Circle.OUTLINE, color = color, clamp = true,
        tgl and gui.Spacer {
            pad_h = 0.005, pad_v = 0.005, clamp = true, gui.Circle {
                clamp = true, color = 0xC0C0C0, gui.Circle {
                    style = gui.Circle.OUTLINE, color = color,
                    clamp = true
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

ckboxv["default"         ] = ckbox_build_variant(0xFFFFFF)
ckboxv["default_hovering"] = ckbox_build_variant(0xE1E1E1)
ckboxv["toggled"         ] = ckbox_build_variant(0xC0C0C0, true)
ckboxv["toggled_hovering"] = ckbox_build_variant(0xE1E1E1, true)
rdbtnv["default"         ] = rdbtn_build_variant(0xFFFFFF)
rdbtnv["default_hovering"] = rdbtn_build_variant(0xE1E1E1)
rdbtnv["toggled"         ] = rdbtn_build_variant(0xC0C0C0, true)
rdbtnv["toggled_hovering"] = rdbtn_build_variant(0xE1E1E1, true)

-- scrollbars

local sb_buildh = |labgc, lac, rabgc, rac| gui.Color_Filler {
    clamp_h = true, color = 0x101010, gui.Outline { clamp = true },
    gui.Color_Filler { color = labgc, min_w = 0.02, min_h = 0.02,
        align_h = -1, gui.Outline { clamp = true },
        gui.Triangle { color = lac, min_w = 0.012, min_h = 0.012, angle = 90,
            gui.Triangle { style = gui.Triangle.OUTLINE, color = lac,
                min_w = 0.012, min_h = 0.012, angle = 90
            }
        }
    },
    gui.Color_Filler { color = rabgc, min_w = 0.02, min_h = 0.02,
        align_h = 1, gui.Outline { clamp = true },
        gui.Triangle { color = lac, min_w = 0.012, min_h = 0.012, angle = -90,
            gui.Triangle { style = gui.Triangle.OUTLINE, color = lac,
                min_w = 0.012, min_h = 0.012, angle = -90
            }
        }
    }
}

local sb_buildv = |labgc, lac, rabgc, rac| gui.Color_Filler {
    clamp_v = true, color = 0x101010, gui.Outline { clamp = true },
    gui.Color_Filler { color = labgc, min_w = 0.02, min_h = 0.02,
        align_v = -1, gui.Outline { clamp = true },
        gui.Triangle { color = lac, min_w = 0.012, min_h = 0.012,
            gui.Triangle { style = gui.Triangle.OUTLINE, color = lac,
                min_w = 0.012, min_h = 0.012
            }
        }
    },
    gui.Color_Filler { color = rabgc, min_w = 0.02, min_h = 0.02,
        align_v = 1, gui.Outline { clamp = true },
        gui.Triangle { color = lac, min_w = 0.012, min_h = 0.012, angle = 180,
            gui.Triangle { style = gui.Triangle.OUTLINE, color = lac,
                min_w = 0.012, min_h = 0.012, angle = 180
            }
        }
    }
}

gui.Scroll_Button.__variants = {
    default = {
        default = gui.Color_Filler {
            color = 0x202020, clamp = true, min_w = 0.02, min_h = 0.02,
            gui.Outline { clamp = true }
        },
        hovering = gui.Color_Filler {
            color = 0x606060, clamp = true, min_w = 0.02, min_h = 0.02,
            gui.Outline { clamp = true }
        },
        clicked_left = gui.Color_Filler {
            color = 0x404040, clamp = true, min_w = 0.02, min_h = 0.02,
            gui.Outline { clamp = true }
        }
    }
}

gui.H_Scrollbar.__variants = {
    default = {
        default            = sb_buildh(0x101010, 0xC0C0C0, 0x101010, 0xC0C0C0),
        left_hovering      = sb_buildh(0x404040, 0xC0C0C0, 0x101010, 0xC0C0C0),
        left_clicked_left  = sb_buildh(0x202020, 0xC0C0C0, 0x101010, 0xC0C0C0),
        right_hovering     = sb_buildh(0x101010, 0xC0C0C0, 0x404040, 0xC0C0C0),
        right_clicked_left = sb_buildh(0x101010, 0xC0C0C0, 0x202020, 0xC0C0C0),
        gui.Scroll_Button(),
        __init = |self| do self:set_arrow_size(0.02) end
    }
}

gui.V_Scrollbar.__variants = {
    default = {
        default           = sb_buildv(0x101010, 0xC0C0C0, 0x101010, 0xC0C0C0),
        up_hovering       = sb_buildv(0x404040, 0xC0C0C0, 0x101010, 0xC0C0C0),
        up_clicked_left   = sb_buildv(0x202020, 0xC0C0C0, 0x101010, 0xC0C0C0),
        down_hovering     = sb_buildv(0x101010, 0xC0C0C0, 0x404040, 0xC0C0C0),
        down_clicked_left = sb_buildv(0x101010, 0xC0C0C0, 0x202020, 0xC0C0C0),
        gui.Scroll_Button(),
        __init = |self| do self:set_arrow_size(0.02) end
    }
}

-- windows

local window_build_titlebar = || gui.Gradient {
    color = 0xE6303030, color2 = 0xE6000000, clamp_h = true,
    gui.Spacer {
        pad_h = 0.004, pad_v = 0.004,
        init_clone = |self, win| do
            local lbl = gui.Label { text = win.title or win.obj_name }
            self:append(lbl)
            signal.connect(win, "title_changed", |w, t| do
                lbl:set_text(t or w.obj_name) end)
        end
    }
}

local window_build_regular = |mov| gui.Filler {
    clamp = true,
    gui.V_Box {
        clamp = true,
        gui.Filler { clamp_h = true,
            mov and gui.Mover { clamp_h = true,
                init_clone = |self, win| do
                    self:set_window(win)
                end,
                window_build_titlebar()
            } or window_build_titlebar(),
            gui.Spacer { pad_h = 0.009, align_h = 1,
                gui.Button {
                    variant = false, states = {
                        default = gui.Gradient {
                            color = 0x0, color2 = 0x303030, min_w = 0.015,
                            min_h = 0.015, gui.Outline { clamp = true }
                        },
                        hovering = gui.Gradient {
                            color = 0x0, color2 = 0x303030, min_w = 0.015,
                            min_h = 0.015, gui.Outline { clamp = true,
                                color = 0xE1E1E1 }
                        },
                        clicked_left = gui.Gradient {
                            color = 0x0, color2 = 0x303030, min_w = 0.015,
                            min_h = 0.015, gui.Outline { clamp = true,
                                color = 0xC0C0C0 }
                        }
                    },
                    init_clone = |self, win| do
                        signal.connect(self, "clicked", || win:hide())
                    end
                }
            }
        },
        gui.Gradient {
            color = 0xE6000000, color2 = 0xE6080808, clamp = true, gui.Spacer {
                pad_h = 0.005, pad_v = 0.005, init_clone = |self, win| do
                    win:set_container(self)
                end
            }
        },
        states = {
            default = gui.Color_Filler { min_w = 0.05, min_h = 0.07 }
        }
    },
    gui.Outline { color = 0xFFFFFF, clamp = true }
}

gui.Window.__variants = {
    borderless = {
        gui.Gradient {
            color = 0xE6000000, color2 = 0xE6080808, clamp = true,
            gui.Outline { color = 0xFFFFFF, clamp = true, gui.Spacer {
                pad_h = 0.005, pad_v = 0.005, init_clone = |self, win| do
                    win:set_container(self)
                end
            } }
        }
    },
    regular = { __properties = { "title" }, window_build_regular(false) },
    movable = { __properties = { "title" }, window_build_regular(true)  }
}

-- default windows

world:new_window("changes", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("Changes")
    signal.connect(win, "destroy", || gui.changes_clear())
    win:append(gui.V_Box(), |b| do
        b:append(gui.Label { text = "Apply changes?" })
        b:append(gui.Spacer { pad_v = 0.01, pad_h = 0.005, clamp_h = true,
            gui.Line { clamp_h = true } })
        for i, v in ipairs(gui.changes_get()) do
            b:append(gui.Label { text = v })
        end
        b:append(gui.Spacer { pad_v = 0.01, pad_h = 0.005, clamp_h = true,
            gui.Line { clamp_h = true } })
        b:append(gui.Spacer { pad_v = 0.005, pad_h = 0.005, clamp_h = true,
            gui.H_Box { padding = 0.01,
                gui.Button { label = "OK", min_w = 0.15,
                    signals = { clicked = || do
                        world:hide_window("changes")
                        gui.changes_apply()
                    end }
                },
                gui.Button { label = "Cancel", min_w = 0.15,
                    signals = { clicked = || do
                        world:hide_window("changes")
                        gui.changes_clear()
                    end }
                }
            }
        })
    end)
end)

world:new_window("texture", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("Textures")

    win:append(gui.Grid { columns = 2 }, |gr| do
        local scr
        gr:append(gui.Scroller { clip_w = 0.9, clip_h = 0.6 }, |sc| do
            sc:append(gui.Spacer { pad_h = 0.01, pad_v = 0.01 }, |sp| do
                sp:append(gui.Grid { columns = 8, padding = 0.01 }, |gr| do
                    for i = 1, capi.slot_texmru_num() do
                        local mru = capi.slot_texmru(i - 1)
                        gr:append(gui.Button { variant = false }, |btn| do
                            btn:update_state("default",
                                btn:update_state("hovering",
                                    btn:update_state("clicked",
                                        gui.VSlot_Viewer { index = mru,
                                            min_w = 0.095, min_h = 0.095
                                        })))
                            signal.connect(btn, "clicked",
                                || capi.slot_set(mru))
                        end)
                    end
                end)
            end)
            scr = sc
        end)
        gr:append(gui.V_Scrollbar { clamp_v = true, arrow_speed = 0.5 },
            |sb| sb:bind_scroller(scr))
        gr:append(gui.H_Scrollbar { clamp_h = true, arrow_speed = 0.5 },
            |sb| sb:bind_scroller(scr))
    end)
end)
