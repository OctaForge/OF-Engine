local capi = require("capi")
local ffi = require("ffi")
local cs = require("core.engine.cubescript")
local edit = require("core.engine.edit")
local input = require("core.engine.input")
local changes = require("core.engine.changes")
local signal = require("core.events.signal")
local ents = require("core.entities.ents")
local svars = require("core.entities.svars")
local gui = require("core.gui.core")

local root = gui.get_root()

local Color = gui.Color
local connect = signal.connect
local max = math.max
local tostring = tostring
local sort = table.sort

-- buttons

local btnp  = { "label", "min_w", "min_h" }
local btnv  = { __properties = btnp }
local btnvb = { __properties = btnp }
gui.Button.__variants = { default = btnv, nobg = btnvb }

local btnv_init_clone = |self, btn| do
    local lbl = gui.Label { text = btn.label }
    self:append(lbl)
    connect(btn, "label_changed", |b, t| do lbl:set_text(t) end)
end

local btn_build_variant = |color| gui.Gradient {
    color = 0x202020, color2 = 0x101010, clamp_h = true,
    init_clone = |self, btn| do
        self:set_min_w(btn.min_w or 0)
        self:set_min_h(btn.min_h or 0)
        connect(btn, "min_w_changed", |b, v| self:set_min_w(v))
        connect(btn, "min_h_changed", |b, v| self:set_min_w(v))
    end, gui.Outline {
        color = color, clamp_h = true, gui.Spacer {
            pad_h = 0.01, pad_v = 0.005, init_clone = btnv_init_clone
        }
    }
}

local btn_build_variant_nobg = || gui.Filler {
    clamp_h = true, init_clone = |self, btn| do
        self:set_min_w(btn.min_w or 0)
        self:set_min_h(btn.min_h or 0)
        connect(btn, "min_w_changed", |b, v| self:set_min_w(v))
        connect(btn, "min_h_changed", |b, v| self:set_min_w(v))
    end, gui.Spacer {
        pad_h = 0.01, pad_v = 0.005, init_clone = btnv_init_clone
    }
}

btnv["default"     ] = btn_build_variant(0x303030)
btnv["hovering"    ] = btn_build_variant(0x505050)
btnv["clicked_left"] = btn_build_variant(0x404040)

btnvb["default"     ] = btn_build_variant_nobg()
btnvb["hovering"    ] = btn_build_variant(0x404040)
btnvb["clicked_left"] = btn_build_variant(0x303030)

local mbtnv, vmbtnv, smbtnv =
    { __properties  = { "label" } },
    { __properties  = { "label" } },
    { __properties  = { "label" } }
gui.Menu_Button.__variants = { default = mbtnv, visible = vmbtnv,
    submenu = smbtnv }

mbtnv["default"     ] = btn_build_variant_nobg()
mbtnv["hovering"    ] = btn_build_variant_nobg()
mbtnv["menu"        ] = btn_build_variant(0x404040)
mbtnv["clicked_left"] = btn_build_variant(0x404040)

vmbtnv["default"     ] = btn_build_variant(0x303030)
vmbtnv["hovering"    ] = btn_build_variant(0x505050)
vmbtnv["menu"        ] = btn_build_variant(0x404040)
vmbtnv["clicked_left"] = btn_build_variant(0x404040)

smbtnv["default"     ] = btn_build_variant_nobg()
smbtnv["hovering"    ] = btn_build_variant(0x404040)
smbtnv["menu"        ] = btn_build_variant(0x404040)
smbtnv["clicked_left"] = btn_build_variant(0x404040)

-- (v)slot viewer buttons

local slotbtn_init_clone = |self, btn| do
    self:set_min_w(btn.min_w or 0)
    self:set_min_h(btn.min_h or 0)
    self:set_index(btn.index or 0)
    connect(btn, "min_w_changed", |b, v| self:set_min_w(v))
    connect(btn, "min_h_changed", |b, v| self:set_min_h(v))
    connect(btn, "index_changed", |b, v| self:set_index(v))
end

gui.Button.__variants.vslot = {
    __properties = { "index", "min_w", "min_h" },
    default = gui.VSlot_Viewer { init_clone = slotbtn_init_clone },
    hovering = gui.VSlot_Viewer { init_clone = slotbtn_init_clone,
        gui.Outline { clamp = true, color = 0x606060 } },
    clicked_left = gui.VSlot_Viewer { init_clone = slotbtn_init_clone,
        gui.Outline { clamp = true, color = 0x505050 } }
}

gui.Button.__variants.slot = {
    __properties = { "index", "min_w", "min_h" },
    default = gui.Slot_Viewer { init_clone = slotbtn_init_clone },
    hovering = gui.Slot_Viewer { init_clone = slotbtn_init_clone,
        gui.Outline { clamp = true, color = 0x606060 } },
    clicked_left = gui.Slot_Viewer { init_clone = slotbtn_init_clone,
        gui.Outline { clamp = true, color = 0x505050 } }
}

-- editors

gui.Text_Editor.__variants = {
    default = {
        gui.Color_Filler {
            color = 0x80202020, clamp = true, gui.Outline { clamp = true,
                color = 0x303030
            }
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
        gui.Color_Filler { color = 0xF0101010, clamp = true,
            gui.Outline { color = 0x303030, clamp = true }
        }
    },
    edithud = {
        gui.Gradient { color = 0xF0303030, color2 = 0xF0101010, clamp = true,
            gui.Outline { color = 0x404040, clamp = true }
        }
    },
    tooltip = {
        __properties = { "label" },
        gui.Gradient {
            color = 0xF0202020, color2 = 0xF0101010, gui.Outline {
                color = 0x303030, clamp = true, gui.Spacer {
                    pad_h = 0.01, pad_v = 0.005, init_clone = |self, ttip| do
                        local lbl = gui.Label { text = ttip.label }
                        self:append(lbl)
                        connect(ttip, "label_changed", |o, t| do
                            lbl:set_text(t) end)
                    end
                }
            }
        }
    }
}

-- checkboxes, radioboxes

local ckbox_build_variant = |color, tgl| gui.Color_Filler {
    color = 0x202020, min_w = 0.02, min_h = 0.02,
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
    color = 0x202020, min_w = 0.02, min_h = 0.02,
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

ckboxv["default"         ] = ckbox_build_variant(0x303030)
ckboxv["default_hovering"] = ckbox_build_variant(0x505050)
ckboxv["default_focused" ] = ckbox_build_variant(0x606060)
ckboxv["toggled"         ] = ckbox_build_variant(0x404040, true)
ckboxv["toggled_hovering"] = ckbox_build_variant(0x505050, true)
ckboxv["toggled_focused" ] = ckbox_build_variant(0x606060, true)
rdbtnv["default"         ] = rdbtn_build_variant(0x303030)
rdbtnv["default_hovering"] = rdbtn_build_variant(0x505050)
rdbtnv["default_focused" ] = rdbtn_build_variant(0x606060)
rdbtnv["toggled"         ] = rdbtn_build_variant(0x404040, true)
rdbtnv["toggled_hovering"] = rdbtn_build_variant(0x505050, true)
rdbtnv["toggled_focused" ] = rdbtn_build_variant(0x606060, true)

-- scrollbars

local sb_buildh = |lac, rac| gui.Outline {
    clamp_h = true, color = 0x303030,
    gui.Filler { min_w = 0.02, min_h = 0.02, align_h = -1,
        gui.Triangle { style = gui.Triangle.OUTLINE, color = lac,
            min_w = 0.01, min_h = 0.01, angle = 90
        }
    },
    gui.Filler { min_w = 0.02, min_h = 0.02, align_h = 1,
        gui.Triangle { style = gui.Triangle.OUTLINE, color = rac,
            min_w = 0.01, min_h = 0.01, angle = -90
        }
    }
}

local sb_buildv = |lac, rac| gui.Filler {
    clamp_v = true,
    gui.Filler { min_w = 0.02, min_h = 0.02, align_v = -1,
        gui.Triangle { style = gui.Triangle.OUTLINE, color = lac,
            min_w = 0.01, min_h = 0.01
        }
    },
    gui.Filler { min_w = 0.02, min_h = 0.02, align_v = 1,
        gui.Triangle { style = gui.Triangle.OUTLINE, color = rac,
            min_w = 0.01, min_h = 0.01, angle = 180
        }
    }
}

gui.Scroll_Button.__variants = {
    default = {
        default = gui.Color_Filler {
            color = 0x181818, clamp = true, min_w = 0.015, min_h = 0.015,
            gui.Outline { clamp = true, color = 0x404040 }
        },
        hovering = gui.Color_Filler {
            color = 0x181818, clamp = true, min_w = 0.015, min_h = 0.015,
            gui.Outline { clamp = true, color = 0x606060 }
        },
        clicked_left = gui.Color_Filler {
            color = 0x181818, clamp = true, min_w = 0.015, min_h = 0.015,
            gui.Outline { clamp = true, color = 0x505050 }
        }
    }
}

gui.H_Scrollbar.__variants = {
    default = {
        default            = sb_buildh(0x404040, 0x404040),
        left_hovering      = sb_buildh(0x606060, 0x404040),
        left_clicked_left  = sb_buildh(0x505050, 0x404040),
        right_hovering     = sb_buildh(0x404040, 0x606060),
        right_clicked_left = sb_buildh(0x404040, 0x505050),
        __init = |self| do self:set_arrow_size(0.02) end
    }
}

gui.V_Scrollbar.__variants = {
    default = {
        default           = sb_buildv(0x404040, 0x404040),
        up_hovering       = sb_buildv(0x606060, 0x404040),
        up_clicked_left   = sb_buildv(0x505050, 0x404040),
        down_hovering     = sb_buildv(0x404040, 0x606060),
        down_clicked_left = sb_buildv(0x404040, 0x505050),
        __init = |self| do self:set_arrow_size(0.02) end
    }
}

-- sliders

gui.Slider_Button.__variants = gui.Scroll_Button.__variants
gui.H_Slider.__variants = gui.H_Scrollbar.__variants
gui.V_Slider.__variants = gui.V_Scrollbar.__variants

-- progress bars

gui.H_Progress_Bar.__variants = {
    default = {
        gui.Color_Filler { color = 0xF0101010, clamp = true,
            gui.Outline { color = 0x404040, clamp = true },
            init_clone = |self, pb| do
                local bar = gui.Gradient { color = 0xF0353535,
                    color2 = 0xF0252525, clamp_v = true,
                    gui.Outline { color = 0x404040, clamp = true }
                }
                local lbl = gui.Label { text = pb:gen_label(), scale = 0.8 }
                pb:set_bar(bar)
                self:append(bar)
                self:append(lbl)
                connect(pb, "value_changed", |o, v| do
                    lbl:set_text(pb:gen_label())
                end)
            end
        }
    }
}

gui.V_Progress_Bar.__variants = {
    default = {
        gui.Color_Filler { color = 0xF0101010, clamp = true,
            gui.Outline { color = 0x404040, clamp = true },
            init_clone = |self, pb| do
                local bar = gui.Gradient { color = 0xF0353535,
                    color2 = 0xF0252525, clamp_h = true, horizontal = true,
                    gui.Outline { color = 0x404040, clamp = true }
                }
                local lbl = gui.Label { text = pb:gen_label(), scale = 0.8 }
                pb:set_bar(bar)
                self:append(bar)
                self:append(lbl)
                connect(pb, "value_changed", |o, v| do
                    lbl:set_text(pb:gen_label())
                end)
            end
        }
    }
}

-- windows

local window_build_titlebar = || gui.Gradient {
    color = 0xF0202020, color2 = 0xF0101010, clamp_h = true,
    gui.Spacer {
        pad_h = 0.004, pad_v = 0.004,
        init_clone = |self, win| do
            local lbl = gui.Label { text = win.title or win.obj_name }
            self:append(lbl)
            connect(win, "title_changed", |w, t| do
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
                        default = gui.Color_Filler {
                            color = 0x101010, min_w = 0.015,
                            min_h = 0.015, gui.Outline { clamp = true,
                                color = 0x606060 }
                        },
                        hovering = gui.Color_Filler {
                            color = 0x101010, min_w = 0.015,
                            min_h = 0.015, gui.Outline { clamp = true,
                                color = 0x808080 }
                        },
                        clicked_left = gui.Color_Filler {
                            color = 0x101010, min_w = 0.015,
                            min_h = 0.015, gui.Outline { clamp = true,
                                color = 0x707070 }
                        }
                    },
                    init_clone = |self, win| do
                        connect(self, "clicked", || win:hide())
                    end
                }
            }
        },
        gui.Color_Filler {
            color = 0xF0101010, clamp = true, gui.Spacer {
                pad_h = 0.005, pad_v = 0.005, init_clone = |self, win| do
                    win:set_container(self)
                end
            }
        },
        states = {
            default = gui.Color_Filler { min_w = 0.05, min_h = 0.07 }
        }
    },
    gui.Outline { color = 0x303030, clamp = true }
}

gui.Window.__variants = {
    borderless = {
        gui.Color_Filler {
            color = 0xF0101010, clamp = true,
            gui.Outline { color = 0x303030, clamp = true, gui.Spacer {
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

local progress_bar, progress_label
local progress_win = gui.Window { __init = |win| do
    win:append(gui.V_Box(), |b| do
        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0.01 }, |sp| do
            progress_label = sp:append(gui.Label())
        end)
        b:append(gui.Spacer { pad_h = 0.02, pad_v = 0.01 }, |sp| do
            progress_bar = sp:append(gui.H_Progress_Bar { min_w = 0.4,
                min_h = 0.03 })
        end)
    end)
end }

local set_ext = require("core.externals").set

set_ext("progress_render", function(v, text)
    progress_bar:set_value(v)
    progress_label:set_text(text)
    gui.__draw_window(progress_win)
end)

local bg_win = function(mapname, mapinfo, mapshot, caption)
    local win = gui.Window()
    win:set_input_grab(false)
    win:align(0, 1)
    win:append(gui.V_Box(), |b| do
        if mapname then
            b:append(gui.Label { text = mapname, scale = 1.5 })
        end
        if mapinfo then b:append(gui.Label { text = mapinfo }) end
        if mapshot then
            b:append(gui.Spacer { pad_h = 0.02, pad_v = 0.02 }, |sp| do
                sp:append(gui.Image { min_w = 0.2, min_h = 0.2 },
                    |img| do img.texture = mapshot end)
            end)
        end
        if caption then
            b:append(gui.Label { text = caption, scale = 1.5 })
        end
        b:append(gui.Filler { min_h = 0.05 })
    end)
    return win
end

local hw_tex_size = 0
local max_tex_size = cs.var_get("maxtexsize")

connect(cs, "maxtexsize_changed", |self, val| do max_tex_size = val end)

local get_logo = function(root, win)
    if  hw_tex_size == 0 then
        hw_tex_size = cs.var_get("hwtexsize")
    end
    local sz = ((max_tex_size ~= 0) and math.min(max_tex_size, hw_tex_size)
                                     or hw_tex_size)
    local w, h = root:get_pixel_w(), root:get_pixel_h()
    local logo
    if (sz >= 1024) and ((w > 1280) or (h > 800)) then
        logo = "<premul>media/interface/logo_1024"
    else
        logo = "<premul>media/interface/logo"
    end
    win.x, win.y, win.parent, win._root = 0, 0, root, root
    local proj = win:get_projection()
    proj:calc()
    local lw = math.min(proj.pw, proj.ph)
    return logo, lw, lw / 2
end

local bg_under = function(root)
    local win = gui.Overlay()
    local logo, lw, lh = get_logo(root, win)
    win:append(gui.Image { file = "media/interface/background",
        min_w = 1/0, min_h = 1/0 })
    win:append(gui.Image { file = "media/interface/shadow",
        min_w = 1/0, min_h = 1/0 })
    win:append( gui.Image { file = logo, min_w = lw, min_h = lh,
                            align_v = -1 })
    return win
end

set_ext("background_render", function(caption, mapname, mapinfo, mapshot)
    local root = gui.get_root()
    root:calc_text_scale()
    root:layout_dim()
    gui.__draw_window(bg_under(root))
    gui.__draw_window(bg_win(mapname, mapinfo, mapshot
        and ffi.cast("Texture*", mapshot) or nil, caption))
end)

--[[! Variable: applydialog
    An engine variable that controls whether the "apply" dialog will show
    on changes that need restart of some engine subsystem. Defaults to 1.
]]
cs.var_new_checked("applydialog", cs.var_type.int, 0, 1, 1,
    cs.var_flags.PERSIST)
cs.var_new("hidechanges", cs.var_type.int, 0, 0, 1)

connect(changes, "add", |self, ctype, desc| do
    if cs.var_get("applydialog") == 0 then return end
    changes.add(ctype, desc)
    if cs.var_get("hidechanges") == 0 then
        root:show_window("changes")
    end
end)

connect(root, "reset", || cs.var_set("hidechanges", 0))

root:new_window("changes", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("Changes")
    connect(win, "destroy", || changes.clear())
    win:append(gui.V_Box(), |b| do
        b:append(gui.Spacer { pad_h = 0.01, pad_v = 0,
            gui.Label { text = "The following settings have changed:" } })
        b:append(gui.Spacer { pad_v = 0.01, pad_h = 0.005, clamp_h = true,
            gui.Line { clamp_h = true, color = 0x303030 } })
        for i, v in ipairs(changes.get()) do
            b:append(gui.Label { text = v })
        end
        b:append(gui.Filler { clamp_h = true, min_h = 0.01 })
        b:append(gui.Spacer { pad_v = 0.005, pad_h = 0.005, clamp_h = true,
            gui.H_Box { padding = 0.01,
                gui.Button { label = "OK", min_w = 0.15,
                    signals = { clicked = || do
                        changes.apply()
                        root:hide_window("changes")
                    end }
                },
                gui.Button { label = "Cancel", min_w = 0.15,
                    signals = { clicked = || do
                        root:hide_window("changes")
                    end }
                }
            }
        })
    end)
end)

root:new_window("texture", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("Textures")
    win:append(gui.H_Box(), |hb| do
        local s
        hb:append(gui.Outline(), |o| do
            o:append(gui.Spacer { pad_h = 0.005, pad_v = 0.005 }, |sp| do
                sp:append(gui.Scroller { clip_w = 0.9, clip_h = 0.6 }, |sc| do
                    sc:append(gui.Grid { columns = 8, padding = 0.01 }, |gr| do
                        for i = 1, capi.slot_texmru_num() do
                            local mru = capi.slot_texmru(i - 1)
                            gr:append(gui.Button { variant = "vslot",
                                index = mru, min_w = 0.095, min_h = 0.095
                            }, |b| do
                                connect(b, "clicked", || capi.slot_set(mru))
                            end)
                        end
                    end)
                    s = sc
                end)
            end)
        end)
        hb:append(gui.V_Scrollbar { clamp_v = true }, |sb| do
            sb:append(gui.Scroll_Button())
            sb:bind_scroller(s)
        end)
    end)
end)

local fields = {
    [svars.State_Boolean] = function(hb, nm, ent, dv)
        local tvar = (dv == "true")
        local ret
        hb:append(gui.Filler { min_w = 0.4 }, |f| do
            f:append(gui.Toggle { variant = "checkbox", condition = || tvar,
                align_h = -1
            }, |t| do
                ret = t
                signal.connect(t, "released", || do
                    tvar = not tvar
                    ent:set_gui_attr(nm, tostring(tvar))
                end)
            end)
        end)
        return ret
    end
}
local field_def = function(hb, nm, ent, dv)
    return hb:append(gui.Field { clip_w = 0.4, value = dv }, |ed| do
        connect(ed, "value_changed", |ed, v| do
            ent:set_gui_attr(nm, v)
        end)
    end)
end

root:new_window("entity", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    local  ent = capi.get_selected_entity()
    if not ent then
        ent = ents.get_player()
    end
    if not ent then
        win:set_title("Entity editing: none")
        win:append(gui.Spacer { pad_h = 0.04, pad_v = 0.03,
            gui.Label { text = "No selected entity" }
        })
        return
    end
    win:set_title(("Entity editing: %s (%d)"):format(ent.name, ent.uid))
    local props = {}
    local sdata = {}
    local sdata_raw = ent:build_sdata()

    local nfields = 0
    local prefix = "_SV_"
    for k, v in pairs(sdata_raw) do
        local sv = ent[prefix .. k]
        local gn = sv.gui_name
        if gn != false then
            nfields += 1
            sdata[k] = { gn or k, v, sv }
            props[nfields] = k
        end
    end
    sort(props)

    win:append(gui.H_Box(), |hb| do
        local s
        hb:append(gui.Outline { color = 0x303030 }, |o| do
            o:append(gui.Spacer { pad_h = 0.005, pad_v = 0.005 }, |sp| do
                sp:append(gui.Scroller { clip_w = 0.9, clip_h = 0.6 }, |sc| do
                    sc:append(gui.V_Box(), |vb| do
                        local fpf, pf
                        for i = 1, nfields do
                            local nm = props[i]
                            local sd = sdata[nm]
                            local gn, dv, sv = sd[1], sd[2], sd[3]
                            vb:append(gui.H_Box { align_h = 1 }, |hb| do
                                hb:append(gui.Label { text = " "..sd[1]..": " })
                                local fld = fields[sv.__proto] or field_def
                                local fd = fld(hb, gn, ent, dv)
                                if pf then pf:set_tab_next(fd) end
                                pf = fd
                                if not fpf then fpf = fd end
                            end)
                            if fpf and pf and pf != fpf then
                                pf:set_tab_next(fpf)
                            end
                        end
                    end)
                    s = sc
                end)
            end)
        end)
        hb:append(gui.V_Scrollbar { clamp_v = true }, |sb| do
            sb:append(gui.Scroll_Button())
            sb:bind_scroller(s)
        end)
    end)
end)

root:new_window("entity_new", gui.Window, |win| do
    input.save_mouse_position()
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("New entity")

    local cnames = {}
    for k, v in pairs(ents.get_all_prototypes()) do
        if v:is_a(ents.Static_Entity) then
            cnames[#cnames + 1] = k
        end
    end
    sort(cnames)

    win:append(gui.H_Box(), |hb| do
        local s
        hb:append(gui.Outline { color = 0x303030 }, |o| do
            o:append(gui.Spacer { pad_h = 0.005, pad_v = 0.005 }, |sp| do
                sp:append(gui.Scroller { clip_w = 0.6, clip_h = 0.6 }, |sc| do
                    sc:append(gui.V_Box(), |vb| do
                        for i = 1, #cnames do
                            local n = cnames[i]
                            vb:append(gui.Button {
                                variant = "nobg", min_w = 0.3, label = n
                            }, |btn| do
                                connect(btn, "clicked", || do
                                    edit.new_entity(n)
                                    root:hide_window("entity_new")
                                end)
                            end)
                        end
                    end)
                    s = sc
                end)
            end)
        end)
        hb:append(gui.V_Scrollbar { clamp_v = true }, |sb| do
            sb:append(gui.Scroll_Button())
            sb:bind_scroller(s)
        end)
    end)
end)
