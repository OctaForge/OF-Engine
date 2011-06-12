-- tabbed graphical user interface by q66
module("tgui", package.seeall)

function hover()    gui.modcolor(1, 0.75, 0.75, 0, 0, function() gui.clamp(1, 1, 1, 1) end) end
function selected() gui.modcolor(0.75, 0.75, 1, 0, 0, function() gui.clamp(1, 1, 1, 1) end) end
function disabled() gui.modcolor(0.2, 0.2, 0.2, 0, 0, function() gui.clamp(1, 1, 1, 1) end) end

function window(name, title, body, noclose, notitle, nofocus, realtime, onhide)
    gui.new(name, function()
        gui.table(3, 0, function()
            -- nifty separator - left
            gui.color(0, 0, 0, 1, 0.001, 0.001)
            -- nifty separator - middle
            gui.color(0, 0, 0, 1, 0, 0.001, function() gui.clamp(1, 1, 1, 1) end)
            -- nifty separator - right
            gui.color(0, 0, 0, 1, 0.001, 0.001)

            if not notitle then
                -- upper left corner
                gui.color(0, 0, 0, 1, 0.001, 0.025)
                -- upper edge
                gui.color(0, 0, 0, 1, 0, 0.025, function()
                    gui.clamp(1, 1, 1, 1)
                    gui.tag("title", function()
                        gui.align(0, 0)
                        gui.label(title)
                    end)
                    if not noclose() then
                        gui.button(
                            function()
                                gui.hide(name)
                            end, function()
                                gui.align(1, 0)
                                -- idle state
                                gui.color(1, 1, 1, 0.2, 0.024, 0.024)
                                -- hover state
                                gui.color(1, 1, 1, 0.3, 0.024, 0.024)
                                -- selected state
                                gui.color(1, 1, 1, 0.8, 0.024, 0.024)
                            end
                        )
                    end
                end)
                -- upper right corner
                gui.color(0, 0, 0, 1, 0.001, 0.025)
            end

            -- nifty separator - left
            gui.color(0, 0, 0, 1, 0.001, 0.001)
            -- nifty separator - middle
            gui.color(0, 0, 0, 1, 0, 0.001, function() gui.clamp(1, 1, 1, 1) end)
            -- nifty separator - right
            gui.color(0, 0, 0, 1, 0.001, 0.001)

            -- left edge
            gui.color(0, 0, 0, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- body
            gui.color(0, 0, 0, 0.5, 0, 0, function()
                gui.clamp(1, 1, 1, 1)
                gui.space(0.01, 0.01, function()
                    body()
                end)
            end)

            -- right edge
            gui.color(0, 0, 0, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- bottom left corner
            gui.color(0, 0, 0, 1, 0.001, 0.001)
            -- bottom edge
            gui.color(0, 0, 0, 1, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
            -- bottom right corner
            gui.color(0, 0, 0, 1, 0.001, 0.001)
        end)
    end, nofocus and 1 or 0, realtime and 1 or 0, onhide)
end

function space(body)
    gui.new("space", function()
        gui.align(-1, 0)
        gui.fill(scr_w / scr_h, 1, function()
            body()
        end)
    end, 1, 0)
end

function hbar()
    gui.space(0.002, 0.002, function()
        gui.color(0, 0, 0, 1, 1, 0.002)
    end)
end

function vbar()
    gui.space(0.002, 0.002, function()
        gui.color(0, 0, 0, 1, 0.002, 0)
    end)
end

function field(...)
    local args = { ... }
    gui.table(3, 0, function()
        gui.color(1, 1, 1, 1, 0.001, 0.001)
        gui.color(1, 1, 1, 1, 0, 0.001, function() gui.clamp(1, 1, 1, 1) end)
        gui.color(1, 1, 1, 1, 0.001, 0.001)

        gui.color(1, 1, 1, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.field(unpack(args))
        gui.color(1, 1, 1, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)

        gui.color(1, 1, 1, 1, 0.001, 0.001)
        gui.color(1, 1, 1, 1, 0, 0.001, function() gui.clamp(1, 1, 1, 1) end)
        gui.color(1, 1, 1, 1, 0.001, 0.001)
    end)
end

function button(label, action)
    gui.button(action, function()
        -- idle state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.list(true, 0, function()
                gui.color(0, 0, 0, 1, 0.01, 0.025)
                gui.color(1, 0, 0, 1, 0.15, 0.025, function() gui.clamp(1, 1, 0, 0) end)
                gui.color(0, 0, 0, 1, 0.01, 0.025)
            end)
            gui.label(label)
        end)

        -- hover state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.list(true, 0, function()
                gui.color(1, 0, 0, 1, 0.01, 0.025)
                gui.color(0, 0, 1, 1, 0.15, 0.025, function() gui.clamp(1, 1, 0, 0) end)
                gui.color(1, 0, 0, 1, 0.01, 0.025)
            end)
            gui.label(label)
        end)

        -- selected state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.list(true, 0, function()
                gui.color(0, 0, 1, 1, 0.01, 0.025)
                gui.color(1, 0, 0, 1, 0.15, 0.025, function() gui.clamp(1, 1, 0, 0) end)
                gui.color(0, 0, 1, 1, 0.01, 0.025)
            end)
            gui.label(label)
        end)
    end)
end

function checkbox(var, label)
    gui.list(true, 0, function()
        gui.align(-1, 0)
        gui.toggle(
            function()
                return _G[var] and _G[var] ~= 0
            end,
            function()
                _G[var] = (type(_G[var]) == "number")
                        and ((_G[var] == 0)
                            and 1 or 0
                        ) or (not _G[var])
            end,
            0,
            function()
                -- idle state false
                gui.color(0.5, 0, 0, 1, 0.025, 0.025)
                -- hovering state false
                gui.color(1,   0, 0, 1, 0.025, 0.025)
                -- idle state true
                gui.color(0, 0.5, 0, 1, 0.025, 0.025)
                -- hovering state true
                gui.color(0, 1,   0, 1, 0.025, 0.025)
            end
        )
        gui.offset(0.02, 0, function()
            gui.label(label)
        end)
    end)
end

function scrollbox(width, height, body)
    gui.list(true, 0, function()
        gui.scroll(width - 0.025, height, function()
            gui.fill(width - 0.025, height)
            body()
        end)
        gui.vscrollbar(0.025, 1, function()
            -- both arrows idle
            gui.fill(0.025, 0, function()
                gui.list(false, 0, function()
                    -- up arrow
                    gui.color(1, 0, 0, 1, 0.025, 0.025)
                    -- vertical bar
                    gui.color(0, 0, 0, 1, 0.025, height - 0.05)
                    -- down arrow
                    gui.color(1, 0, 0, 1, 0.025, 0.025)
                end)
            end)

            -- up arrow hover
            gui.fill(0.025, 0, function()
                gui.list(false, 0, function()
                    -- up arrow
                    gui.color(0, 0.5, 0, 1, 0.025, 0.025)
                    -- vertical bar
                    gui.color(0, 0, 0, 1, 0.025, height - 0.05)
                    -- down arrow
                    gui.color(1, 0, 0, 1, 0.025, 0.025)
                end)
            end)

            -- up arrow selected
            gui.fill(0.025, 0, function()
                gui.list(false, 0, function()
                    -- up arrow
                    gui.color(0, 1, 0, 1, 0.025, 0.025)
                    -- vertical bar
                    gui.color(0, 0, 0, 1, 0.025, height - 0.05)
                    -- down arrow
                    gui.color(1, 0, 0, 1, 0.025, 0.025)
                end)
            end)

            -- down arrow hover
            gui.fill(0.025, 0, function()
                gui.list(false, 0, function()
                    -- up arrow
                    gui.color(1, 0, 0, 1, 0.025, 0.025)
                    -- vertical bar
                    gui.color(0, 0, 0, 1, 0.025, height - 0.05)
                    -- down arrow
                    gui.color(0, 0.5, 0, 1, 0.025, 0.025)
                end)
            end)

            -- down arrow selected
            gui.fill(0.025, 0, function()
                gui.list(false, 0, function()
                    -- up arrow
                    gui.color(1, 0, 0, 1, 0.025, 0.025)
                    -- vertical bar
                    gui.color(0, 0, 0, 1, 0.025, height - 0.05)
                    -- down arrow
                    gui.color(0, 1, 0, 1, 0.025, 0.025)
                end)
            end)

            gui.scrollbutton(function()
                -- scrollbutton idle
                gui.color(1, 1, 1, 1, 0.025, 0.025, function() gui.clamp(0, 0, 1, 1) end)
                -- scrollbutton hover
                gui.color(0.5, 0, 0, 1, 0.025, 0.025, function() gui.clamp(0, 0, 1, 1) end)
                -- scrollbutton selected
                gui.color(0, 0, 1, 1, 0.025, 0.025, function() gui.clamp(0, 0, 1, 1) end)
            end)
        end)
    end)
end
