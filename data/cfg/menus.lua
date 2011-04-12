-- HUD stuff

function edithud()
    if cc.world.enthavesel() ~= 0 then
        return "%(1)s : %(2)s selected" % { cc.world.entget(), cc.world.enthavesel() }
    end
end

-- Entity GUI

cc.gui.new("entities", function()
    for i = 1, cc.world.numentityclasses() do
        local entityclass = cc.world.getentclass(i - 1)
        cc.gui.button(entityclass, "cc.world.spawnent(%(1)q)" % { entityclass })
    end
end)

-- Export entities

cc.engine_variables.new("newexportfilename", cc.engine_variables.VAR_S, "entities.json")

cc.gui.new("exportentities", function()
    cc.gui.list(function()
        cc.gui.text("filename: ")
        cc.gui.field("newexportfilename", 30, "")
    end)
    cc.gui.bar()
    cc.gui.button("export", "cc.world.export_entities(newexportfilename)")
end)

-- Messages

cc.gui.new("message", function()
    cc.gui.text(message_title)
    cc.gui.bar()
    cc.gui.text(message_content)
    cc.gui.bar()
    cc.gui.button("close", "cc.gui.clear(1)")
end)

cc.gui.new("input_dialog", function()
    cc.gui.text(input_title)
    cc.gui.bar()
    cc.gui.text(input_content)
    cc.gui.bar()
    cc.engine_variables.new("new_input_data", cc.engine_variables.VAR_S, input_data)
    cc.gui.field("new_input_data", 30, [=[input_data = new_input_data]=])
    cc.gui.bar()
    -- TODO: input callback support
    cc.gui.button("submit", [=[cc.gui.input_callback()]=])
    cc.gui.button("cancel", [=[cc.gui.clear(1)]=])
end)

cc.gui.new("can_quit", function()
    cc.gui.text("Editing changes have been made. If you quit")
    cc.gui.text("now then they will be lost. Are you sure you")
    cc.gui.text("want to quit?")
    cc.gui.bar()
    cc.gui.button("yes", [=[cc.engine.force_quit()]=])
    cc.gui.button("no", [=[cc.gui.clear(1)]=])
end)

-- Standard menu definitions

cc.console.binds.add("ESCAPE", [[
    cc.gui.menu_key_click_trigger()
    if cc.gui.clear() ~= 1 then
        cc.console.save_mouse_pos() -- Useful for New Light GUI and so forth.
        cc.gui.show("main")
    end
]])

-- Main menu

function setup_main_menu()
    cc.gui.new("main", function()
        cc.gui.text("Welcome to CubeCreate development release. (1)")
        cc.gui.bar()
        cc.gui.show_plugins()
        cc.gui.text("Credits: Cube 2, Syntensity, Love, Lua, SDL, Python, zlib.")
        cc.gui.text("Licensed under MIT/X11.")
        cc.gui.bar()
        cc.gui.list(function()
            cc.gui.text("mini-console: ")
            cc.gui.field("minicon_entry", 36)
            cc.gui.bar()
            cc.gui.button("exec", [==[if minicon_entry then loadstring(minicon_entry)() end]==])
        end)
        cc.gui.bar()
        cc.gui.button("quit", [=[cc.engine.quit()]=], "exit")
    end)
end

setup_main_menu()
