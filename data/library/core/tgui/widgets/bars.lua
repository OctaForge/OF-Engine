module("tgui", package.seeall)

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
