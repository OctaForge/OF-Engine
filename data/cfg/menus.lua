package.path = package.path .. ";./data/cfg/?/init.lua"
require("tgui")

function edithud()
    if world.enthavesel() ~= 0 then
        return "%(1)s : %(2)s selected" % { world.entget(), world.enthavesel() }
    end
end

console.binds.add("ESCAPE", [[
    gui.menu_key_click_trigger()
    if not gui.hide("main") then
        console.save_mouse_pos() -- Useful for New Light GUI and so forth.
        gui.show("main")
    end
]])

tgui.window("main", "Main menu", function()
    gui.list(false, 0, function()
        gui.align(-1, 0)
        gui.label("Welcome to OctaForge developer alpha release.")
        gui.label("Enter 'empty' if you aren't sure of mapname.")

        gui.cond(
            function()
                return world.hasmap()
            end, function()
                gui.list(false, 0.02, function()
                    gui.label("Map: Running.")
                    tgui.button("  stop", function() world.map() end)
                    tgui.button("  show output", function() gui.show("local_server_output") end)
                    tgui.button("  save map", function() network.do_upload() end)
                    tgui.button("  restart map", function() world.restart_map() end)
                end)
                gui.list(false, 0, function()
                    gui.label("Map: Not running.")
                    gui.list(true, -0.02, function()
                        gui.label("Run map: base/")
                        tgui.field("local_server_location", 30)
                    end)
                    gui.list(true, -0.02, function()
                        tgui.button("  start", function() world.map(local_server_location) end)
                        tgui.button("  show output", function() gui.show("local_server_output") end)
                    end)
                end)
            end
        )

        gui.label("Credits: Cube 2, Syntensity, Love, Lua, SDL, Python, zlib.")
        gui.label("Licensed under MIT/X11.")

        gui.list(true, 0.02, function()
            gui.label("mini-console: ")
            tgui.field("minicon_entry", 36)
            tgui.button("exec", function() if minicon_entry then loadstring(minicon_entry)() end end)
        end)

        tgui.button("quit", function() engine.quit() end)
    end)
end, function() return (mainmenu == 1) end)

tgui.window("texgui", "Textures", function()
    texture.filltexlist()
    gui.fill(0.95, 0.7, function()
        tgui.scrollbox(0.95, 0.7, function()
            gui.table(8, 0.01, function()
                gui.align(-1, -1)
                for i = 1, texture.getnumslots() do
                    gui.button(function() texture.set(i - 1) end, function()
                        gui.slotview(i - 1, 0.1, 0.1)
                        gui.slotview(i - 1, 0.1, 0.1, function()
                            gui.modcolor(1, 0.5, 0.5, 0.1, 0.1)
                        end)
                        gui.slotview(i - 1, 0.1, 0.1, function()
                            gui.modcolor(0.5, 0.5, 1, 0.1, 0.1)
                        end)
                    end)
                end
            end)
        end)
    end)
end)

tgui.space(function()
    gui.align(0, 0)
    gui.color(1, 0, 0, 0.5, 0.5, 0.5)
end)
