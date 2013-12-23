local capi = require("capi")
local signal = require("core.events.signal")
local gui = require("core.gui.core")
local cs = require("core.engine.cubescript")

local connect = signal.connect

local world = gui.get_world()

local var_get = cs.var_get
local cs_execute = cs.execute

local gen_map_list = |img, vb| do
    local glob, loc = capi.get_all_map_names()
    vb:append(gui.Label { text = "Global maps", color = 0x88FF88 })
    local current_preview
    for i = 1, #glob do
        local map = glob[i]
        vb:append(gui.Button { label = glob[i], clamp_h = true,
            variant = "nobg", min_w = 0.2
        }, |btn| do
            signal.connect(btn, "hovering", || do
                if map != current_preview then
                    current_preview = map
                    img:set_tex("media/map/" .. map .. "/map")
                end
            end)
            signal.connect(btn, "leaving", || do
                current_preview = nil
                img:set_tex(nil)
            end)
            signal.connect(btn, "clicked", || do
                cs_execute("map " .. map)
            end)
        end)
    end
    vb:append(gui.Label { text = "Local maps", color = 0x8888FF })
    for i = 1, #loc do
        local map = loc[i]
        vb:append(gui.Button { label = loc[i], clamp_h = true,
            variant = "nobg", min_w = 0.2
        }, |btn| do
            signal.connect(btn, "hovering", || do
                if map != current_preview then
                    current_preview = map
                    img:set_tex("media/map/" .. map .. "/map")
                end
            end)
            signal.connect(btn, "leaving", || do
                current_preview = nil
                img:set_tex(nil)
            end)
            signal.connect(btn, "clicked", || do
                cs_execute("map " .. map)
            end)
        end)
    end
end

local gen_map_load = || do
    local s
    return gui.H_Box {
        gui.Outline { __init = |o| do
            o:append(gui.Spacer { pad_h = 0.005, pad_v = 0.005 }, |sp| do
                sp:append(gui.Scroller { clip_w = 0.6, clip_h = 0.5 }, |sc| do
                    s = sc
                    sc:append(gui.H_Box { padding = 0.01 }, |hb| do
                        local im
                        hb:append(gui.Spacer { pad_h = 0.02, pad_v = 0.02,
                            gui.Image { min_w = 0.3, min_h = 0.3,
                                __init = |img| do im = img end,
                                gui.Outline { clamp = true, color = 0x303030 }
                            }
                        })
                        hb:append(gui.V_Box(), |vb| do
                            gen_map_list(im, vb)
                        end)
                    end)
                end)
            end)
        end, color = 0x303030 },
        gui.V_Scrollbar { clamp_v = true, __init = |sb| do
            sb:append(gui.Scroll_Button())
            sb:bind_scroller(s)
        end }
    }
end

world:new_window("main", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("Main menu")
    win:append(gui.H_Box { clamp_h = true }, |b| do
        local stat
        b:append(gui.V_Box(), |b| do
            b:append(gui.Button { label = "Load map", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do stat:set_state("load_map") end)
            end)
            b:append(gui.Button { label = "Options", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do stat:set_state("options") end)
            end)
            b:append(gui.Button { label = "Credits", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do stat:set_state("credits") end)
            end)
            b:append(gui.Button { label = "Quit", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do cs_execute("quit") end)
            end)
        end)
        b:append(gui.Filler { min_w = 0.005, clamp_v = true })
        b:append(gui.State { state = "default" }, |st| do
            stat = st
            st:update_state("default", gui.Outline { min_w = 0.6, min_h = 0.5,
                color = 0x303030, gui.V_Box {
                    gui.Label { text = "Welcome to OctaForge!", scale = 1.5,
                        color = 0x88FF88
                    },
                    gui.Label { text = "Please start by clicking one of the "
                        .. "menu items." }
                }
            })
            st:update_state("load_map", gen_map_load())
            st:update_state("options", gui.Outline { min_w = 0.6, min_h = 0.5,
                color = 0x303030, gui.V_Box {
                    gui.Label { text = "Coming soon", scale = 1.5,
                        color = 0x88FF88 },
                    gui.Label { text = "No options for now :)" }
                }
            })
            st:update_state("credits", gui.Outline { min_w = 0.6, min_h = 0.5,
                color = 0x303030, gui.V_Box {
                    gui.Label { text = "OctaForge is brought to you by:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Daniel \f1"q66"\f7 Kolesa' },
                    gui.Label { text = "project leader and main programmer",
                        scale = 0.8 },
                    gui.Filler { min_h = 0.008, clamp_h = true },
                    gui.Label { text = 'Lee \f1"eihrul"\f7 Salzman' },
                    gui.Label { text = 'David \f1"dkreuter"\f7 Kreuter' },
                    gui.Label { text = 'Dale \f1"graphitemaster"\f7 Weiler' },
                    gui.Label { text = "code contributors", scale = 0.8 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = "Based on Tesseract created by:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Lee \f1"eihrul"\f7 Salzman' },
                    gui.Label { text = "and others",  scale = 0.8 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = "And Syntensity created by:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Alon \f1"kripken"\f7 Zakai' },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = "The original Cube 2 engine:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Wouter \f1"aardappel"\f7 van '
                        ..'Oortmerssen' },
                    gui.Label { text = 'Lee \f1"eihrul"\f7 Salzman' },
                    gui.Label { text = "and others",  scale = 0.8 },
                }
            })
        end)
    end)
end)

world:new_window("fullconsole", gui.Overlay, |win| do
    win:clamp(true, true, false, false)
    win:align(0, -1)
    capi.console_full_show(true)
    connect(win, "destroy", || capi.console_full_show(false))
    win:append(gui.Console {
        min_h = || var_get("fullconsize") / 100
    }, |con| do
        con:clamp(true, true, false, false)
    end)
end)

world:new_window("editstats", gui.Overlay, |win| do
    win:align(-1, 1)
    win:set_above_hud(true)
    win:append(gui.Filler { variant = "edithud" }, |fl| do
        fl:append(gui.Spacer { pad_h = 0.015, pad_v = 0.01 }, |sp| do
            sp:append(gui.Eval_Label { scale = -1,
                func = || cs_execute("getedithud") }):align(-1, 0)
        end)
    end)
end)
