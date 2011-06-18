-- HUD stuff

function edithud()
    if world.enthavesel() ~= 0 then
        return "%(1)s : %(2)s selected" % { world.entget(), world.enthavesel() }
    end
end

-- core binds

console.binds.add("ESCAPE", [[
    gui.menu_key_click_trigger()
    if not gui.hide("main") then
        gui.show("main")
    end
]])

-- non-edit tabs

local main_id = tgui.push_tab("Main", tgui.TAB_VERTICAL, tgui.TAB_DEFAULT, "icon_mainmenu", function()
    gui.vlist(0, function()
        gui.space(0.01, 0.01, function()
            gui.label("Welcome to OctaForge!", 1.5, 0, 0.8, 0)
        end)
        gui.label("You're running OctaForge developer alpha release.", 1, 1, 1, 1,   function() gui.align(-1, 0) end)
        gui.label("Thanks for downloading, we hope you'll like the", 1, 1, 1, 1,     function() gui.align(-1, 0) end)
        gui.label("engine. Start off by browsing the icons on the left", 1, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("and on the bottom, or run a map from table below", 1, 1, 1, 1,    function() gui.align(-1, 0) end)
        gui.label("right away!", 1, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.space(0.01, 0.01, function()
            gui.cond(
                function()
                    return world.hasmap()
                end, function()
                    gui.vlist(0, function()
                        gui.label("Map: Running.", 1.2, 0.8, 0, 0)
                        tgui.button("  stop", function() world.map() end)
                        tgui.button("  show output", function() gui.show("local_server_output") end)
                        tgui.button("  save map", function() network.do_upload() end)
                        tgui.button("  restart map", function() world.restart_map() end)
                    end)
                    gui.vlist(0, function()
                        local glob, user = world.get_all_map_names()

                        gui.label("User maps")
                        tgui.scrollbox(0.5, 0.15, function()
                            gui.table(4, 0.01, function()
                                gui.align(-1, -1)
                                for i, map in pairs(user) do
                                    gui.button(
                                        function()
                                            world.map(map)
                                        end, function()
                                            local preview = world.get_map_preview_filename(map)
                                               or tgui.image_path .. "icons/icon_no_preview.png"

                                            gui.stretchedimage(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretchedimage(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretchedimage(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                        end
                                    )
                                end
                            end)
                        end)

                        gui.label("Global maps")
                        tgui.scrollbox(0.5, 0.15, function()
                            gui.table(4, 0.01, function()
                                gui.align(-1, -1)
                                for i, map in pairs(glob) do
                                    gui.button(
                                        function()
                                            world.map(map)
                                        end, function()
                                            local preview = world.get_map_preview_filename(map)
                                               or tgui.image_path .. "icons/icon_no_preview.png"

                                            gui.stretchedimage(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretchedimage(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 1, 1, 1, function() gui.align(0, 1) end)
                                                end)
                                            end)
                                            gui.stretchedimage(preview, 0.1, 0.1, function()
                                                gui.space(0, 0.01, function()
                                                    gui.align(0, 1)
                                                    gui.label(map, 1, 1, 1, 1, function() gui.align(0, 1) end)
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

local about_id = tgui.push_tab("About", tgui.TAB_HORIZONTAL, tgui.TAB_DEFAULT, "icon_about", function()
    gui.vlist(0, function()
        gui.label("Copyright 2011 OctaForge developers.", 1, 0, 1, 0)
        gui.label("Released under MIT license.", 1, 1, 0, 0)
        gui.label("Uses Cube 2 engine. Cube 2:", 1, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("  - Wouter van Oortmerssen (aardappel)", 1, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("  - Lee Salzman (eihrul)", 1, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("Based on Syntensity created by Alon Zakai (kripken)", 1, 1, 1, 1, function() gui.align(-1, 0) end)
        gui.label("Uses Lua scripting language, zlib, SDL, OpenGL.", 1, 1, 1, 1, function() gui.align(-1, 0) end)
    end)
end)

-- edit tabs

tgui.push_tab("Textures", tgui.TAB_HORIZONTAL, tgui.TAB_EDIT, "icon_about", function()
    texture.filltexlist()
    gui.fill(1, 0.7, function()
        tgui.scrollbox(1, 0.7, function()
            gui.table(9, 0.01, function()
                gui.align(-1, -1)
                for i = 1, texture.getnumslots() do
                    gui.button(function() texture.set(i - 1) end, function()
                        gui.slotview(i - 1, 0.095, 0.095)
                        gui.slotview(i - 1, 0.095, 0.095, function()
                            gui.modcolor(1, 0.5, 0.5, 0.095, 0.095)
                        end)
                        gui.slotview(i - 1, 0.095, 0.095, function()
                            gui.modcolor(0.5, 0.5, 1, 0.095, 0.095)
                        end)
                    end)
                end
            end)
        end)
    end)
end)

tgui.push_tab("Entities", tgui.TAB_HORIZONTAL, tgui.TAB_EDIT, "icon_about", function()
    CAPI.prepareentityclasses()

    gui.fill(0.3, 0.7, function()
        tgui.scrollbox(0.3, 0.7, function()
            gui.vlist(0, function()
                gui.align(-1, -1)
                for i = 1, world.numentityclasses() do
                    local entityclass = world.getentclass(i - 1)
                    tgui.button_no_bg(entityclass, function() world.spawnent(entityclass) end)
                end
            end)
        end)
    end)
end)

tgui.push_tab("Export entities", tgui.TAB_HORIZONTAL, tgui.TAB_EDIT, "icon_about", function()
    gui.vlist(0, function()
        engine.newvar("newexportfilename", engine.VAR_S, "entities.json")
        gui.hlist(0, function()
            gui.label("filename: ")
            tgui.field("newexportfilename", 30)
        end)
        tgui.button("export", function() world.export_entities(newexportfilename) end)
    end)
end)

print(id)

-- show main menu tab
gui.show("main")
tgui.show_tab( main_id)
tgui.show_tab(about_id)
