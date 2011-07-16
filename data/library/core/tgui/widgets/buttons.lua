module("tgui", package.seeall)

function button(label, action)
    gui.button(action, function()
        -- idle state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.hlist(0, function()
                gui.stretched_image(image_path .. "button_left_idle.png", 0.01, 0.03)
                gui.stretched_image(
                    image_path .. "button_middle_idle.png",
                    0.15, 0.03,
                    function()
                        gui.clamp(1, 1, 0, 0)
                    end
                )
                gui.stretched_image(image_path .. "button_right_idle.png", 0.01, 0.03)
            end)
            gui.label(label)
        end)

        -- hover state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.hlist(0, function()
                gui.stretched_image(image_path .. "button_left_idle.png", 0.01, 0.03, hover)
                gui.stretched_image(
                    image_path .. "button_middle_idle.png",
                    0.15, 0.03,
                    function()
                        gui.clamp(1, 1, 0, 0)
                        hover()
                    end
                )
                gui.stretched_image(image_path .. "button_right_idle.png", 0.01, 0.03, hover)
            end)
            gui.label(label)
        end)

        -- selected state
        gui.fill(0.2, 0.025, function()
            gui.clamp(1, 1, 0, 0)
            gui.hlist(0, function()
                gui.stretched_image(image_path .. "button_left_idle.png", 0.01, 0.03, selected)
                gui.stretched_image(
                    image_path .. "button_middle_idle.png",
                    0.15, 0.03,
                    function()
                        gui.clamp(1, 1, 0, 0)
                        selected()
                    end
                )
                gui.stretched_image(image_path .. "button_right_idle.png", 0.01, 0.03, selected)
            end)
            gui.label(label)
        end)
    end)
end

function button_no_bg(label, action)
    gui.button(action, function()
        gui.align(-1, 0)
        -- idle state
        gui.fill(0, 0, function()
            gui.clamp(1, 1, 0, 0)
            gui.color(0, 0, 0, 0, 0, 0.03, function() gui.clamp(1, 1, 0, 0) end)
            gui.label(label, 1, 1, 1, 1)
        end)

        -- hover state
        gui.fill(0, 0, function()
            gui.clamp(1, 1, 0, 0)
            gui.color(0, 0, 0, 0, 0, 0.03, function() gui.clamp(1, 1, 0, 0) end)
            gui.label(label, 1, 1, 0, 0)
        end)

        -- selected state
        gui.fill(0, 0, function()
            gui.clamp(1, 1, 0, 0)
            gui.color(0, 0, 0, 0, 0, 0.03, function() gui.clamp(1, 1, 0, 0) end)
            gui.label(label, 1, 0.5, 0, 0)
        end)
    end)
end
