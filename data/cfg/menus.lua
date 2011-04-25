-- HUD stuff

function edithud()
    if of.world.enthavesel() ~= 0 then
        return "%(1)s : %(2)s selected" % { of.world.entget(), of.world.enthavesel() }
    end
end

-- Entity GUI

of.gui.new("entities", function()
    for i = 1, of.world.numentityclasses() do
        local entityclass = of.world.getentclass(i - 1)
        of.gui.button(entityclass, "of.world.spawnent(%(1)q)" % { entityclass })
    end
end)

-- Export entities

of.gui.new("exportentities", function()
    of.engine_variables.new("newexportfilename", of.engine_variables.VAR_S, "entities.json")
    of.gui.list(function()
        of.gui.text("filename: ")
        of.gui.field("newexportfilename", 30, "")
    end)
    of.gui.bar()
    of.gui.button("export", "of.world.export_entities(newexportfilename)")
end)

-- Messages

of.gui.new("message", function()
    of.gui.text(message_title)
    of.gui.bar()
    of.gui.text(message_content)
    of.gui.bar()
    of.gui.button("close", "of.gui.clear(1)")
end)

of.gui.new("input_dialog", function()
    of.gui.text(input_title)
    of.gui.bar()
    of.gui.text(input_content)
    of.gui.bar()
    of.engine_variables.new("new_input_data", of.engine_variables.VAR_S, input_data)
    of.gui.field("new_input_data", 30, [=[input_data = new_input_data]=])
    of.gui.bar()
    -- TODO: input callback support
    of.gui.button("submit", [=[of.gui.input_callback()]=])
    of.gui.button("cancel", [=[of.gui.clear(1)]=])
end)

of.gui.new("can_quit", function()
    of.gui.text("Editing changes have been made. If you quit")
    of.gui.text("now then they will be lost. Are you sure you")
    of.gui.text("want to quit?")
    of.gui.bar()
    of.gui.button("yes", [=[of.engine.force_quit()]=])
    of.gui.button("no", [=[of.gui.clear(1)]=])
end)

-- Standard menu definitions

of.console.binds.add("ESCAPE", [[
    of.gui.menu_key_click_trigger()
    if of.gui.clear() ~= 1 then
        of.console.save_mouse_pos() -- Useful for New Light GUI and so forth.
        of.gui.show("main")
    end
]])

-- Main menu

function setup_main_menu()
    of.gui.new("main", function()
        of.gui.text("Welcome to OctaForge development release. (1)")
        of.gui.text("Enter generic_dev if you aren't sure of mapname.")
        of.gui.bar()
        of.gui.show_plugins()
        of.gui.text("Credits: Cube 2, Syntensity, Love, Lua, SDL, Python, zlib.")
        of.gui.text("Licensed under MIT/X11.")
        of.gui.bar()
        of.gui.list(function()
            of.gui.text("mini-console: ")
            of.gui.field("minicon_entry", 36)
            of.gui.bar()
            of.gui.button("exec", [==[if minicon_entry then loadstring(minicon_entry)() end]==])
        end)
        of.gui.bar()
        of.gui.button("quit", [=[of.engine.quit()]=], "exit")
    end)
end

setup_main_menu()
