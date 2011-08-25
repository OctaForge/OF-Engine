--[[!
    File: tgui/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file takes care of loading all tgui elements and several
        pre-defined windows.
]]

--[[!
    Package: tgui
    This part of tgui (Tabbed Graphical User Interface) takes care of
    several pre-defined windows.
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
    -- main body list
    gui.vlist(0, function()
        -- icon + text
        gui.hlist(0, function()
            -- icon
            gui.stretched_image(
                get_icon_path("icon_question.png"),
                0.08, 0.08
            )
            -- space between icon and text
            gui.space(0.005, 0)
            -- text
            gui.label([[Editing changes have been made. If you quit
now then they will be lost. Are you sure you
want to quit?]])
        end)
        -- yes / no selection
        gui.hlist(0, function()
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
        local maps. Shown on button click. TODO: MAKE IT WORK
]]
window("local_server_output", "Server log", function()
    -- main body list
    gui.vlist(0, function()
        -- get the logfile
        local logfile = engine.get_server_log_file()

        -- init the editor
        gui.editor     ("local_server_output", -80, 20)
        gui.init_editor("local_server_output", logfile)
        button("refresh", function()
            -- refreshing
            gui.focus_editor("local_server_output")
            gui.load_editor (logfile)
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
    -- main body list
    gui.vlist(0, function()
        -- icon + text
        gui.hlist(0, function()
            -- icon
            gui.stretched_image(
                get_icon_path("icon_warning.png"),
                0.08, 0.08
            )
            -- space between icon and text
            gui.space(0.005, 0)
            -- text container
            gui.vlist(0, function()
                gui.label("The following settings have changed")
                gui.label("and require reload:")
                gui.space(0.01, 0.01, function()
                    gui.tag("changes", function() end)
                end)
            end)
        end)
        -- button bar
        gui.hlist(0, function()
            button("Apply", function()
                gui.apply_changes()
                gui.hide("changes")
            end)
            button("Clear", function()
                gui.clear_changes()
                gui.hide("changes")
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

        Scoreboard window has realtime and nofocus flags, meaning
        it's per-frame updated.
]]
window("scoreboard", nil, function()
    gui.vlist(0, function()
        if not get_scoreboard_text then
            -- default behavior
            gui.label([[No scoreboard text defined.
Crate global function get_scoreboard_text
In order to achieve what you need, see docs
if something is not clear.]])
        else
            -- get scoreboard text - it's a table
            local t = get_scoreboard_text()
            -- loop it
            for i, v in pairs(t) do
                -- this is the text
                local lt = v[2]

                -- get the entity if possible
                if v[1] ~= -1 then
                    local entity = entity_store.get(v[1])
                    -- append information about lags when needed
                    if entity and entity:is_a(character.character) then
                        if showpj == 1 then
                            if entity.client_state ==
                               character.CLIENT_STATE.LAGGED then
                                lt = lt .. "LAG"
                            else
                                lt = lt .. entity.plag
                            end
                        end
                        if showpj == 0 and entity.client_state ==
                                           character.CLIENT_STATE.LAGGED then
                            lt = lt .. "LAG"
                        else
                            lt = lt .. entity.ping
                        end
                    end
                end
                -- create a label now
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
            for i, change in pairs(gui.get_changes()) do
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
    -- number of fields for current entity GUI
    local num_entgui_fields = 0

    -- first try if we're targeting at entity
    local  uid = entity_store.get_target_entity_uid()
    if not uid then
        logging.log(logging.DEBUG, "No entity to show GUI for.")
    end

    -- then try if it's gettable
    local  entity = entity_store.get(uid)
    if not entity then
        logging.log(logging.DEBUG, "No entity to show GUI for.")
    end

    -- sorted_keys is an array of keys sorted by name
    local sorted_keys    = {}
    -- state_data is non-raw SD with gui names
    local state_data     = {}
    -- raw state data dictionary
    local state_data_raw = entity:create_state_data_dict()

    -- loop raw data, create "real" state_data 
    for key, value in pairs(state_data_raw) do
        local gui_name  = state_variables.__get_gui_name(uid, key)
        state_data[key] = { gui_name, value }

        table.insert(sorted_keys, key)

        num_entgui_fields = num_entgui_fields + 1
    end

    -- sort the keys
    table.sort(sorted_keys)

    -- it's in horizontal tab
    gui.show("htab")

    -- tab title
    gui.replace("htab", "title", function()
        gui.align(0, 0)
        gui.label("%(1)i: %(2)s" % { uid, entity._class or "unknown" })
    end)

    -- tab body
    gui.replace("htab", "body",  function()
        -- we're in scrollbox to avoid size issues
        scrollbox(0.7, 0.4, function()
            -- vertical list as contents of the box
            gui.vlist(0, function()
                -- loop the number of fields
                for i = 1, num_entgui_fields do
                    -- SV key
                    local key   = sorted_keys[i]
                    -- pair GUI name / value
                    local pair  = state_data [key]
                    -- name of engine variable alias
                    local name  = "__tmp_" .. key

                    -- name + field - store in a hlist
                    gui.hlist(0, function()
                        -- align to the left
                        gui.align(-1, 0)
                        -- make sure to have the same space
                        -- for all labels - XXX: is it big enough?
                        gui.fill(0.15, 0, function()
                            -- again, left align
                            gui.align(-1, 0)
                            -- and label
                            gui.label(
                                pair[1] .. ": ",
                                1, 1, 1, 1,
                                function()
                                    gui.align(-1, 0)
                                end
                            )
                        end)

                        -- pre-create an alias with initial value
                        engine.new_var(
                            name, engine.VAR_S, pair[2], true
                        )

                        -- a field for the value - XXX: long enough?
                        field(name, #pair[2] + 25, function()
                            local nv = _G[name]
                            if nv ~= pair[2] then
                                pair[2] = nv
                                entity_store.get(entity.uid)[key]
                                    = state_variables.__get(
                                        entity.uid, key
                                    ):from_wire(nv)
                            end
                        end)
                    end)
                end
            end)
        end)
    end)
end

--[[!
    Property: entities

    Title:
        Entities

    Description:
        This ia a window that shows a list of insertable static
        entities. Clicking on each entity button makes it spawn
        on previously saved position (see <input.save_mouse_position>).

        Function named <show_entities_list> does that and shows
        this window.
]]
window("entities", "Entities", function()
    gui.fill(0.3, 0.7, function()
        tgui.scrollbox(0.3, 0.7, function()
            gui.vlist(0, function()
                gui.align(-1, -1)
                for i, class in pairs(entity_classes.list()) do
                    tgui.button_no_bg(class, function()
                        edit.new_entity(class)
                        gui.hide("entities")
                    end)
                end
            end)
        end)
    end)
end)

--[[!
    Function: show_entities_list
    Shows <entities>. Before that it saves mouse position
    using <input.save_mouse_position> so the insertion
    function knows where to put it.
]]
function show_entities_list()
    input.save_mouse_position()
    gui.show("entities")
end

--[[!
    Property: message

    Title:
        Unknown

    Description:
        Pre-defined message box window. Contains two replaceable
        tags, "title" and "message", and a close button.

        Used by <show_message>.
]]
window("message", "Unknown", function()
    gui.vlist(0, function()
        gui.tag("message", function() end)
        button("close", function() gui.hide("message") end)
    end)
end)

--[[!
    Function: show_message
    Shows a <message> window. Replaces its title and
    message using the arguments (which are strings).
    Also callable as "gui.message" to allow easy
    replacement of tgui without recompiling the engine.
]]
function show_message(title, text)
    gui.show("message")
    gui.replace("message", "message", function()
        gui.align(0, 0)
        gui.label(text)
    end)
    gui.replace("message", "title", function()
        gui.align(0, 0)
        gui.label(title)
    end)
end
gui.message = show_message

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
