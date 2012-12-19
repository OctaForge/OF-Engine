local world = gui.core.register_world(gui.core.World {
    pointer = "data/textures/ui/cursors/default.png", input = true
}, 1)

local main = world:append(gui.core.Rectangle {
    gui.core.V_Box {
        gui.core.Mover {
            gui.core.Rectangle {
                r = 255, g = 0, b = 0, a = 200,
                clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,

                min_h = 0.03,

                gui.core.Label {
                    text = "Window title",
                    align_h = 0, align_v = 0
                }
            },

            clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,

            tags = { "mover" }
        },

        gui.core.Label  { text = "This is some transparent text", a = 100 },
        gui.core.Label  { text = "Different text", r = 255, g = 0, b = 0 },

        gui.core.Spacer {
            gui.core.H_Box {
                gui.core.Button {
                    states = {
                        default = gui.core.Rectangle {
                            min_w = 0.2, min_h = 0.05,
                            r = 255, g = 255, b = 0,

                            gui.core.Label { text = "Idle state" }
                        },

                        hovering = gui.core.Rectangle {
                            min_w = 0.2, min_h = 0.05,
                            r = 255, g = 0, b = 0,

                            gui.core.Label { text = "Hover state" }
                        },

                        clicked = gui.core.Rectangle {
                            min_w = 0.2, min_h = 0.05,
                            r = 255, g = 0, b = 255,

                            gui.core.Label { text = "Clicked state" }
                        },
                    },

                    signals = {
                        click = function(self)
                            echo "you clicked a button."
                            self:find_sibling_by_tag("field").text = EV.abcdef
                        end
                    },

                    init = function(btn)
                        print "custom widget \"constructors\""
                    end,

                    tooltip = gui.core.Rectangle {
                        min_w = 0.2, min_h = 0.05,
                        r = 128, g = 128, b = 128, a = 128,
                        gui.core.Label { text = "A tooltip" }
                    }
                },

                gui.core.Spacer {
                    gui.core.Label { tags = { "field" } },

                    pad_h = 0.005
                }
            },

            pad_h = 0.005,
            pad_v = 0.005
        },

        gui.core.Spacer {
            gui.core.Rectangle {
                gui.core.Field {
                    var = "abcdef", value = "example value",
                    length = 50,
                    pointer = "data/textures/ui/cursors/edit.png"
                },
                r = 255, g = 192, b = 128, a = 192
            },

            pad_h = 0.005,
            pad_v = 0.005
        },

        gui.core.Spacer {
            gui.core.Rectangle {
                clip_children = true,
                r = 0, g = 255, b = 0, a = 200,

                min_w = 0.9, min_h = 0.5,

                gui.core.Rectangle {
                    r = 255, g = 0, b = 0, a = 160,
                    align_h = 0, align_v = 0,
                    min_w = 0.5, min_h = 0.4,
                    floating = true,
                    clip_children = true,

                    gui.core.Mover {
                        gui.core.Rectangle {
                            r = 255, g = 255, b = 0, a = 200,
                            clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,
                            align_v = -1,

                            min_h = 0.03,

                            gui.core.Label {
                                text = "Nested window title",
                                align_h = 0, align_v = 0
                            }
                        },

                        clamp_l = 1, clamp_r = 1, clamp_b = 0, clamp_t = 0,
                        align_v = -1,

                        tags = { "mdimov" }
                    },

                    gui.core.Rectangle {
                        clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,
                        r = 255, g = 255, b = 255, a = 0,

                        gui.core.Rectangle {
                            r = 255, g = 128, b = 128, a = 160,
                            align_h = 0, align_v = 0,
                            min_w = 0.4, min_h = 0.1,
                            floating = true,

                            gui.core.Mover {
                                gui.core.Rectangle {
                                    r = 255, g = 255, b = 0, a = 200,
                                    clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,
                                    align_v = -1,

                                    min_h = 0.03,

                                    gui.core.Label {
                                        text = "Yo dawg, i herd u liekd windows",
                                        align_h = 0, align_v = 0
                                    }
                                },

                                clamp_l = 1, clamp_r = 1, clamp_b = 0, clamp_t = 0,
                                align_v = -1,

                                tags = { "mdimovn1" }
                            },

                            init = function(rect)
                                rect:find_child_by_tag("mdimovn1"):link(rect)
                            end
                        },
                    },

                    init = function(rect)
                        rect:find_child_by_tag("mdimov"):link(rect)
                    end
                },

                gui.core.Rectangle {
                    r = 0, g = 0, b = 255, a = 192,
                    align_h = 0, align_v = 0,
                    min_w = 0.5, min_h = 0.3,
                    floating = true,
                    clip_children = true,

                    gui.core.Mover {
                        gui.core.Rectangle {
                            r = 255, g = 255, b = 0, a = 200,
                            clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,
                            align_v = -1,

                            min_h = 0.03,

                            gui.core.Label {
                                text = "Another nested window",
                                align_h = 0, align_v = 0
                            }
                        },

                        clamp_l = 1, clamp_r = 1, clamp_b = 0, clamp_t = 0,
                        align_v = -1,

                        tags = { "mdimov2" }
                    },

                    gui.core.Rectangle {
                        clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,
                        r = 255, g = 255, b = 255, a = 0,

                        gui.core.Rectangle {
                            r = 255, g = 128, b = 128, a = 160,
                            align_h = 0, align_v = 0,
                            min_w = 0.4, min_h = 0.1,
                            floating = true,

                            gui.core.V_Box {
                                gui.core.Mover {
                                    gui.core.Rectangle {
                                        r = 255, g = 255, b = 0, a = 200,
                                        clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,
                                        align_v = -1,

                                        min_h = 0.03,

                                        gui.core.Label {
                                            text = "so i put a window in ur window",
                                            align_h = 0, align_v = 0
                                        }
                                    },

                                    clamp_l = 1, clamp_r = 1, clamp_b = 0, clamp_t = 0,
                                    align_v = -1,

                                    tags = { "mdimovn2" }
                                },

                                gui.core.Label { text = "so u can use windows while u use windows" },

                                clamp_l = 1, clamp_r = 1, clamp_b = 0, clamp_t = 1, align_v = -1
                            },

                            init = function(rect)
                                rect:find_child_by_tag("mdimovn2"):link(rect)
                            end
                        },
                    },

                    init = function(rect)
                        rect:find_child_by_tag("mdimov2"):link(rect)
                    end
                },

                clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1
            },

            pad_h = 0.01,
            pad_v = 0.01,
            clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1
        },

        gui.core.Resizer {
            gui.core.Rectangle {
                r = 255, g = 0, b = 0, a = 200,
                clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,

                min_h = 0.005,
            },

            clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1,

            tags = { "resizer" },
            pointer = "data/textures/ui/cursors/updown.png"
        },

        clamp_l = 1, clamp_r = 1, clamp_b = 1, clamp_t = 1
    },

    r = 96, g = 96, b = 255, a = 128,

    align_h = 0,
    align_v = 0,

    floating = true,

    init = function(win)
        win:find_child_by_tag("mover"  ):link(win)
        win:find_child_by_tag("resizer"):link(win)
    end,

    signals = {
        visible_changed = function(self, v)
            if v == false then
                print "window hidden"
            else
                print "window shown"
            end
        end,

        destroy = function()
            print "DESTROY"
        end
    }
})

world:append(gui.core.Conditional {
    gui.core.Image {
        file = "data/textures/hud/crosshair.png",
        align_h = 0, align_v = 0
    },

    condition = function()
        local wh = signal.emit(_G, "cursor_exists") or
            not CAPI.is_mouselooking()

        if not wh and not (EV.hidehud == 1 or EAPI.gui_mainmenu) then
            return true
        end

        return false
    end,

    tags = { "crosshair" }, allow_focus = false,

    -- ensure "visible" is always true, we handle visibility ourselves
    -- using the conditional
    signals = {
        visible_changed = function(self, v) self.p_visible = true end
    }
})

world:append(gui.Window {
    title = "O hai!",
    gui.core.Label {
        text = "asdadasdadasdasd"
    }
})

signal.connect(world, "get_main", function(_, self)
    return main
end)

input.bind("ESCAPE", [[
    if not gui.hide("main") then
        gui.show("main")
    end
]])

--[=[

-- HUD stuff

function edithud()
    if edit.num_selected_entities() ~= 0 then
        return "%(1)s : %(2)s selected" % {
            edit.get_entity(),
            edit.num_selected_entities()
        }
    end
end

-- core binds

input.bind("ESCAPE", [[
    if not gui.hide("main") then
        gui.show("main")
    end
]])

-- non-edit tabs

local main_id = tgui.push_tab("Main", tgui.BAR_VERTICAL, tgui.BAR_NORMAL, "icon_maps", function()
    gui.vlist(0, function()
        gui.space(0.01, 0.01, function()
            gui.label("Welcome to OctaForge!", 1.5, 0, 0, 0.8, 0)
        end)
        gui.label("You're running OctaForge developer alpha release.", 1, 0, 1, 1, 1,   function() gui.align(-1, 0) end)
        gui.label("Thanks for downloading, we hope you'll like the", 1, 0, 1, 1, 1,     function() gui.align(-1, 0) end)
        gui.label("engine. Start off by browsing the icons on the left", 1, 0, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("and on the bottom, or run a map from table below", 1, 0, 1, 1, 1,    function() gui.align(-1, 0) end)
        gui.label("right away!", 1, 0, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.space(0.01, 0.01, function()
            gui.cond(
                function()
                    return world.has_map()
                end, function()
                    gui.vlist(0, function()
                        gui.label("Map: Running.", 1.2, 0, 0.8, 0, 0)
                        tgui.button("  stop", function() world.map() end)
                        tgui.button("  show output", function() gui.show("local_server_output") end)
                        tgui.button("  save map", function() world.save_map() end)
                        tgui.button("  restart map", function() world.restart_map() end)
                    end)
                    gui.vlist(0, function()
                        local glob, user = world.get_all_map_names()

                        gui.color(1, 1, 1, 0.05, 0, 0, function()
                            gui.clamp(1, 1, 1, 1)
                            gui.space(0, 0.005, function()
                                gui.clamp(1, 1, 0, 0)
                                gui.label("User maps")
                            end)
                        end)
                        tgui.scrollbox(0.5, 0.15, function()
                            gui.table(4, 0.01, function()
                                gui.align(-1, -1)
                                for i, map in pairs(user) do
                                    gui.button(
                                        function()
                                            world.map(map)
                                        end, function()
                                            local preview = world.get_map_preview_name(map)
                                               or tgui.image_path .. "icons/icon_no_preview.png"

                                            gui.stretched_image(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 0, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretched_image(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 0, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretched_image(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 0, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                        end
                                    )
                                end
                            end)
                        end)

                        gui.color(1, 1, 1, 0.05, 0, 0, function()
                            gui.clamp(1, 1, 1, 1)
                            gui.space(0, 0.005, function()
                                gui.clamp(1, 1, 0, 0)
                                gui.label("Global maps")
                            end)
                        end)
                        tgui.scrollbox(0.5, 0.15, function()
                            gui.table(4, 0.01, function()
                                gui.align(-1, -1)
                                for i, map in pairs(glob) do
                                    gui.button(
                                        function()
                                            world.map(map)
                                        end, function()
                                            local preview = world.get_map_preview_name(map)
                                               or tgui.image_path .. "icons/icon_no_preview.png"

                                            gui.stretched_image(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 0, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretched_image(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 0, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretched_image(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 0, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                        end
                                    )
                                end
                            end)
                        end)
                    end)
                end
            )
        end)
    end)
end)

tgui.push_tab("Screen resolution", tgui.BAR_VERTICAL, tgui.BAR_NORMAL, "icon_resolution", function()
    gui.vlist(0, function()
        gui.hlist(0, function()
            gui.label("Field of view: ")
            tgui.hslider("fov")
        end)
        gui.space(0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
        gui.table(5, 0.02, function()
            gui.vlist(0, function()
                gui.align(0, -1)
                gui.label("4:3")
                tgui.resolutionbox(320, 240)
                tgui.resolutionbox(640, 480)
                tgui.resolutionbox(800, 600)
                tgui.resolutionbox(1024, 768)
                tgui.resolutionbox(1152, 864)
                tgui.resolutionbox(1280, 960)
                tgui.resolutionbox(1400, 1050)
                tgui.resolutionbox(1600, 1200)
                tgui.resolutionbox(1792, 1344)
                tgui.resolutionbox(1856, 1392)
                tgui.resolutionbox(1920, 1440)
                tgui.resolutionbox(2048, 1536)
                tgui.resolutionbox(2800, 2100)
                tgui.resolutionbox(3200, 2400)
            end)
            gui.vlist(0, function()
                gui.align(0, -1)
                gui.label("16:10")
                tgui.resolutionbox(320, 200)
                tgui.resolutionbox(640, 400)
                tgui.resolutionbox(1024, 640)
                tgui.resolutionbox(1280, 800)
                tgui.resolutionbox(1440, 900)
                tgui.resolutionbox(1600, 1000)
                tgui.resolutionbox(1680, 1050)
                tgui.resolutionbox(1920, 1200)
                tgui.resolutionbox(2048, 1280)
                tgui.resolutionbox(2560, 1600)
                tgui.resolutionbox(3840, 2400)
            end)
            gui.vlist(0, function()
                gui.align(0, -1)
                gui.label("16:9")
                tgui.resolutionbox(1024, 600)
                tgui.resolutionbox(1280, 720)
                tgui.resolutionbox(1366, 768)
                tgui.resolutionbox(1600, 900)
                tgui.resolutionbox(1920, 1080)
                tgui.resolutionbox(2048, 1152)
                tgui.resolutionbox(3840, 2160)
            end)
            gui.vlist(0, function()
                gui.align(0, -1)
                gui.label("5:4")
                tgui.resolutionbox(600, 480)
                tgui.resolutionbox(1280, 1024)
                tgui.resolutionbox(1600, 1280)
                tgui.resolutionbox(2560, 2048)
            end)
            gui.vlist(0, function()
                gui.align(0, -1)
                gui.label("5:3")
                tgui.resolutionbox(800, 480)
                tgui.resolutionbox(1280, 768)
                gui.label("Custom")

                local was_persisting = var.persist_vars(false)
                var.new("custom_w", EAPI.VAR_S, tostring(EV.scr_w))
                var.new("custom_h", EAPI.VAR_S, tostring(EV.scr_h))
                var.persist_vars(was_persisting)
                gui.hlist(0, function()
                    tgui.field("custom_w", 4, function() EV.scr_w = tonumber(EV.custom_w) end)
                    tgui.field("custom_h", 4, function() EV.scr_h = tonumber(EV.custom_h) end)
                end)
            end)
        end)
    end)
end)

local about_id = tgui.push_tab("About", tgui.BAR_HORIZONTAL, tgui.BAR_NORMAL, "icon_about", function()
    gui.vlist(0, function()
        gui.label("Copyright 2011 OctaForge developers.", 1, 0, 0, 1, 0)
        gui.label("Released under MIT license.", 1, 0, 1, 0, 0)
        gui.label("Uses Cube 2 engine. Cube 2:", 1, 0, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("  - Wouter van Oortmerssen (aardappel)", 1, 0, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("  - Lee Salzman (eihrul)", 1, 0, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("Based on Syntensity created by Alon Zakai (kripken)", 1, 0, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("Uses Lua scripting language, zlib, SDL, OpenGL.", 1, 0, 1, 1, 1, function() gui.align(-1, 0) end)
    end)
end)

-- edit tabs

tgui.push_tab("Textures", tgui.BAR_HORIZONTAL, tgui.BAR_EDIT, "icon_texgui", function()
    texture.fill_slot_list()
    gui.fill(1, 0.7, function()
        tgui.scrollbox(1, 0.7, function()
            gui.table(9, 0.01, function()
                gui.align(-1, -1)
                for i = 1, texture.get_slots_number() do
                    gui.button(
                        function()
                            texture.set_slot(i - 1)
                        end, function()
                            gui.slot_viewer(i - 1, 0.095, 0.095)
                            gui.slot_viewer(i - 1, 0.095, 0.095, function()
                                gui.mod_color(1, 0.5, 0.5, 0.095, 0.095)
                            end)
                            gui.slot_viewer(i - 1, 0.095, 0.095, function()
                                gui.mod_color(0.5, 0.5, 1, 0.095, 0.095)
                            end)
                        end
                    )
                end
            end)
        end)
    end)
end)

tgui.push_tab("Export entities", tgui.BAR_HORIZONTAL, tgui.BAR_EDIT, "icon_save", function()
    gui.vlist(0, function()
        local was_persisting = var.persist_vars(true)
        var.new("newexportfilename", EAPI.VAR_S, "entities.lua")
        var.persist_vars(was_persisting)
        gui.hlist(0, function()
            gui.label("filename: ")
            tgui.field("newexportfilename", 30)
        end)
        tgui.button("export", function() world.export_entities(newexportfilename) end)
    end)
end)

tgui.push_action(tgui.BAR_VERTICAL, tgui.BAR_ALL, "icon_exit", function() EAPI.base_quit() end)

-- show main menu tab
gui.show("main")
tgui.show_tab( main_id)
tgui.show_tab(about_id)

]=]
