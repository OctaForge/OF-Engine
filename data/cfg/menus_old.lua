-- HUD stuff

function edithud()
    if world.enthavesel() ~= 0 then
        return "%(1)s : %(2)s selected" % { world.entget(), world.enthavesel() }
    end
end

-- Entity GUI

gui.new("entities", function()
    for i = 1, world.numentityclasses() do
        local entityclass = world.getentclass(i - 1)
        gui.button(entityclass, "world.spawnent(%(1)q)" % { entityclass })
    end
end)

-- Export entities

gui.new("exportentities", function()
    engine.newvar("newexportfilename", engine_variables.VAR_S, "entities.json")
    gui.list(function()
        gui.text("filename: ")
        gui.field("newexportfilename", 30, "")
    end)
    gui.bar()
    gui.button("export", "world.export_entities(newexportfilename)")
end)

-- Messages

gui.new("message", function()
    gui.text(message_title)
    gui.bar()
    gui.text(message_content)
    gui.bar()
    gui.button("close", "gui.clear(1)")
end)

gui.new("can_quit", function()
    gui.text("Editing changes have been made. If you quit")
    gui.text("now then they will be lost. Are you sure you")
    gui.text("want to quit?")
    gui.bar()
    gui.button("yes", [=[engine.force_quit()]=])
    gui.button("no", [=[gui.clear(1)]=])
end)

gui.new("local_server_output", function()
    gui.noautotab(function()
        gui.bar()
        gui.editor(engine.gethomedir() .. "/" .. engine.getserverlogfile(), -80, 20)
        gui.bar()
        gui.stayopen(function()
            gui.button("refresh", [[
                gui.textfocus(engine.gethomedir() .. "/" .. engine.getserverlogfile())
                gui.textload(engine.gethomedir() .. "/" .. engine.getserverlogfile())
                gui.show("-1")
            ]])
        end)
    end)
end)

-- Standard menu definitions

console.binds.add("ESCAPE", [[
    gui.menu_key_click_trigger()
    if gui.clear() ~= 1 then
        console.save_mouse_pos() -- Useful for New Light GUI and so forth.
        gui.show("main")
    end
]])

-- Main menu

function setup_main_menu()
    gui.new("main", function()
        gui.text("Welcome to OctaForge development release.")
        gui.text("Enter 'empty' if you aren't sure of mapname.")
        gui.bar()
        if world.hasmap() then
            gui.text("Map: Running.")
            gui.stayopen(function() gui.button("  stop", [[world.map()]]) end)
            gui.button("  show output", [[gui.show("local_server_output")]])
            gui.stayopen(function() gui.button("  save map", [[network.do_upload()]]) end)
            gui.button("  restart map", [[world.restart_map()]])
        else
            gui.text("Map: Not runnning.")
            gui.list(function()
                gui.text("Run map: base/")
                gui.field("local_server_location", 30, "")
            end)
            gui.stayopen(function() gui.button("  start", [[world.map(local_server_location)]]) end)
            gui.button("  show output", [[ gui.show("local_server_output") ]])
        end
        gui.bar()
        gui.text("Credits: Cube 2, Syntensity, Love, Lua, SDL, Python, zlib.")
        gui.text("Licensed under MIT/X11.")
        gui.bar()
        gui.list(function()
            gui.text("mini-console: ")
            gui.field("minicon_entry", 36)
            gui.bar()
            gui.button("exec", [==[if minicon_entry then loadstring(minicon_entry)() end]==])
        end)
        gui.bar()
        gui.button("quit", [=[engine.quit()]=], "exit")
    end)
end

setup_main_menu()
