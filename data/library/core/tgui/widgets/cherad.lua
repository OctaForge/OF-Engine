module("tgui", package.seeall)

function checkbox(var, label)
    gui.hlist(0, function()
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
