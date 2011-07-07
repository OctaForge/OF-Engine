--[[!
    File: tgui/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file takes care of loading all tgui elements and several pre-defined
        windows.

    Section: tgui initialization
]]

--[[!
    Package: tgui
    Tabbed Graphical User Interface. Default UI system for OctaForge, taking
    tabbed approach of controlling.
]]
module("tgui", package.seeall)

require("tgui.config")

--[[!
    Section: Pre-defined windows
    Some windows that directly relate to tgui's interface style.
    They might get defined by other interfaces as well.
]]

--[[!
    Property: can_quit

    Title:
        Really quit?

    Description:
        This is a window that gets shown when editing changes are
        made and the user attempts to exit OctaForge.
]]
window("can_quit", "Really quit?", function()
    gui.vlist(0, function()
        gui.hlist(0, function()
            gui.stretchedimage(image_path .. "icons/icon_question.png", 0.08, 0.08)
            gui.space(0.005, 0)
            gui.vlist(0, function()
                gui.label("Editing changes have been made. If you quit")
                gui.label("now then they will be lost. Are you sure you")
                gui.label("want to quit?")
            end)
        end)

        gui.hlist(0, function()
            gui.align(0, 0)
            button("yes", function() engine.force_quit()  end)
            button("no",  function() gui.hide("can_quit") end)
        end)
    end)
end)

--[[!
    Property: local_server_output

    Title:
        Server log

    Description:
        This is a window that contains local server log when running
        local maps. Shown on button click.
]]
window("local_server_output", "Server log", function()
    gui.vlist(0, function()
        local logfile = engine.get_server_log_file()
        gui.editor(logfile, -80, 20)
        gui.textinit(logfile, logfile)
        button("refresh", function()
            gui.textfocus(logfile)
            gui.textload(logfile)
        end)
    end)
end)

--[[!
    Property: changes

    Title:
        Settings changed

    Description:
        This gets shown when user makes changes in settings that require
        reload of either graphics system or sound system.
]]
window("changes", "Settings changed", function()
    gui.vlist(0, function()
        gui.hlist(0, function()
            gui.stretchedimage(image_path .. "icons/icon_warning.png", 0.08, 0.08)
            gui.space(0.005, 0)
            gui.vlist(0, function()
                gui.label("The following settings have changed")
                gui.label("and require reload:")
                gui.space(0.01, 0.01, function()
                    gui.tag("changes", function() end)
                end)
            end)
        end)
        gui.space(0.01, 0.01, function()
            gui.hlist(0, function()
                button("Apply", function()
                    gui.applychanges()
                    gui.hide("changes")
                end)
                button("Clear", function()
                    gui.clearchanges()
                    gui.hide("changes")
                end)
            end)
        end)
    end)
end, function() return true end)

--[[!
    Property: scoreboard
    Title:
        No title

    Description:
        This is a scoreboard window. It makes use of get_scoreboard_text
        global function to get a table in format

        (start code)
            {
                { player_uid, text_to_supply },
                { player_uid, text_to_supply },
                .......
            }
        (end)

        It appends lag / ping info to supplied text if showpj engine
        variable is 1 or player is lagged.

        It also shows network stats. Those are got from C API.
        See <sb_laststatus> and <sb_net_stats>.

        Scoreboard window has realtime and nofocus flags, meaning
        it's per-frame updated.
]]
tgui.window("scoreboard", nil, function()
    gui.vlist(0, function()
        if not get_scoreboard_text then
            gui.label("No scoreboard text defined.")
            gui.label("Crate global function get_scoreboard_text")
            gui.label("In order to achieve what you need, see docs")
            gui.label("if something is not clear.")
        else
            local t = get_scoreboard_text()
            for i, v in pairs(t) do
                local lt = v[2]

                if v[1] ~= -1 then
                    local entity = entity_store.get(v[1])
                    if entity and entity:is_a(character.character) then
                        if showpj == 1 then
                            if entity.client_state == character.CLIENT_STATE.LAGGED then
                                lt = lt .. "LAG"
                            else
                                lt = lt .. entity.plag
                            end
                        end
                        if showpj == 0 and entity.client_state == character.CLIENT_STATE.LAGGED then
                            lt = lt .. "LAG"
                        else
                            lt = lt .. entity.ping
                        end
                    end
                end
                gui.label(lt)
            end
        end
    end)
end, true, true, true)

--[[!
    Function: show_changes

    This is basically an interface to <changes>. It shows the window
    and fills it with list of changed items.

    This gets then supplied to <gui> module, so multiple UI systems
    can supply their own functions and engine can call them safely.
]]
function show_changes()
    gui.show("changes")
    gui.replace("changes", "changes", function()
        gui.vlist(0, function()
            for i, change in pairs(gui.getchanges()) do
                gui.label(change, 1, 1, 1, 1, function() gui.align(-1, 0) end)
            end
        end)
    end)
end
gui.show_changes = show_changes

--[[!
    Function: show_entity_properties_tab

    This is a custom horizontal tab shown when user right-clicks
    an entity. It shows a list of properties and allows to modify
    them. It gets supplied to <gui> module as well, so multiple
    UI systems can supply their own functions and engine can call
    them safely.
]]
function show_entity_properties_tab()
    local num_entgui_fields = 0

    local  uid = entity_store.get_target_entity_uid()
    if not uid then
        logging.log(logging.DEBUG, "No entity to show GUI for.")
    end

    local  entity = entity_store.get(uid)
    if not entity then
        logging.log(logging.DEBUG, "No entity to show GUI for.")
    end

    local sorted_keys    = {}
    local state_data     = {}
    local state_data_raw = entity:create_state_data_dict()

    for key, value in pairs(state_data_raw) do
        local gui_name  = state_variables.__getguin(uid, key)
        state_data[key] = { gui_name, value }

        table.insert(sorted_keys, key)

        num_entgui_fields = num_entgui_fields + 1
    end

    table.sort(sorted_keys)

    gui.show   ("htab")
    gui.replace("htab", "title", function()
        gui.align(0, 0)
        gui.label("%(1)i: %(2)s" % { uid, entity._class or "unknown" })
    end)
    gui.replace("htab", "body",  function()
        scrollbox(0.7, 0.4, function()
            gui.vlist(0, function()
                for i = 1, num_entgui_fields do
                    local key   = sorted_keys[i]
                    local pair  = state_data [key]
                    local name  = "__tmp_" .. key
                    gui.hlist(0, function()
                        gui.align(-1, 0)
                        gui.fill(0.15, 0, function()
                            gui.align(-1, 0)
                            gui.label(pair[1] .. ": ", 1, 1, 1, 1, function() gui.align(-1, 0) end)
                        end)
                        engine.new_var(name, engine.VAR_S, pair[2], true)
                        field(name, #pair[2] + 25, function()
                            local nv = _G[name]
                            if nv ~= pair[2] then
                                pair[2] = nv
                                entity_store.get(entity.uid)[key]
                                    = state_variables.__get(entity.uid, key):from_wire(nv)
                            end
                        end)
                    end)
                end
            end)
        end)
    end)
end
gui.show_entity_properties_gui = show_entity_properties_tab


window("console", "Console", function()
    gui.tag("sizer", function() end)
end)

function show_console_bg(x1, y1, x2, y2)
    local bw = x2 - x1
    local bh = y2 - y1
    local aspect = bw / bh
    local sh = bh
    local sw = sh * aspect
    sw = sw / bw * (scr_w / scr_h)
    sh = sh / bh
    print(sw, sh)

    gui.show("console")
    gui.replace("console", "sizer", function()
        gui.fill(sw - 0.1, sh - 0.1)
    end)
end
