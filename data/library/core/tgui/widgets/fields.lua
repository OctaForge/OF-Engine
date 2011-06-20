module("tgui", package.seeall)

function field(...)
    local args = { ... }
    gui.table(3, 0, function()
        gui.color(1, 1, 1, 1, 0.001, 0.001)
        gui.color(1, 1, 1, 1, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 1, 0.001, 0.001)

        gui.color(1, 1, 1, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.field(unpack(args))
        gui.color(1, 1, 1, 1, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)

        gui.color(1, 1, 1, 1, 0.001, 0.001)
        gui.color(1, 1, 1, 1, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 1, 0.001, 0.001)
    end)
end
