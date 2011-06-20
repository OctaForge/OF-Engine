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
                gui.stretchedimage(image_path .. "check_base.png", 0.020, 0.020)
                -- hovering state false
                gui.stretchedimage(image_path .. "check_base.png", 0.020, 0.020, hover)
                -- idle state true
                gui.stretchedimage(image_path .. "check_checked.png", 0.020, 0.020)
                -- hovering state true
                gui.stretchedimage(image_path .. "check_checked.png", 0.020, 0.020, hover)
            end
        )
        gui.offset(0.02, 0, function()
            gui.label(label)
        end)
    end)
end

local function radio_base()
    -- idle state false
    gui.stretchedimage(image_path .. "radio_base.png", 0.020, 0.020)
    -- hovering state false
    gui.stretchedimage(image_path .. "radio_base.png", 0.020, 0.020, hover)
    -- idle state true
    gui.stretchedimage(image_path .. "radio_checked.png", 0.020, 0.020)
    -- hovering state true
    gui.stretchedimage(image_path .. "radio_checked.png", 0.020, 0.020, hover)
end

function radiobox(var, value, label)
    gui.hlist(0, function()
        gui.align(-1, 0)
        gui.toggle(
            function()
                return _G[var] and _G[var] == value
            end,
            function()
                _G[var] = value
            end,
            0, radio_base
        )
        gui.offset(0.02, 0, function()
            gui.label(label)
        end)
    end)
end

function resolutionbox(w, h)
    gui.hlist(0, function()
        gui.align(-1, 0)
        gui.toggle(
            function()
                return (scr_w == w and scr_h == h)
            end,
            function()
                _G["scr_w"] = w
                _G["scr_h"] = h
            end,
            0, radio_base
        )
        gui.offset(0.02, 0, function()
            gui.label(w .. "x" .. h)
        end)
    end)
end
