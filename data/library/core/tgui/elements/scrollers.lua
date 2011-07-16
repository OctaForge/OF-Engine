module("tgui", package.seeall)

function scrollbox(width, height, body)
    gui.table(4, 0, function()
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.color(1, 1, 1, 0.1, width, height, function()
            gui.scroll(width - 0.020, height - 0.020, function()
                gui.fill(width - 0.020, height - 0.020, function()
                    body()
                end)
            end)
        end)
        gui.vscrollbar(0.020, 1, function()
            -- both arrows idle
            gui.fill(0.020, 0, function()
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "scrollbar_up.png", 0.020, 0.020)
                    -- vertical bar
                    gui.stretched_image(image_path .. "scrollbar_vertical.png", 0.020, height - 0.04)
                    -- down arrow
                    gui.stretched_image(image_path .. "scrollbar_down.png", 0.020, 0.020)
                end)
            end)

            -- up arrow hover
            gui.fill(0.020, 0, function()
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "scrollbar_up.png", 0.020, 0.020, hover)
                    -- vertical bar
                    gui.stretched_image(image_path .. "scrollbar_vertical.png", 0.020, height - 0.04)
                    -- down arrow
                    gui.stretched_image(image_path .. "scrollbar_down.png", 0.020, 0.020)
                end)
            end)

            -- up arrow selected
            gui.fill(0.020, 0, function()
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "scrollbar_up.png", 0.020, 0.020, selected)
                    -- vertical bar
                    gui.stretched_image(image_path .. "scrollbar_vertical.png", 0.020, height - 0.04)
                    -- down arrow
                    gui.stretched_image(image_path .. "scrollbar_down.png", 0.020, 0.020)
                end)
            end)

            -- down arrow hover
            gui.fill(0.020, 0, function()
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "scrollbar_up.png", 0.020, 0.020)
                    -- vertical bar
                    gui.stretched_image(image_path .. "scrollbar_vertical.png", 0.020, height - 0.04)
                    -- down arrow
                    gui.stretched_image(image_path .. "scrollbar_down.png", 0.020, 0.020, hover)
                end)
            end)

            -- down arrow selected
            gui.fill(0.020, 0, function()
                gui.vlist(0, function()
                    -- up arrow
                    gui.stretched_image(image_path .. "scrollbar_up.png", 0.020, 0.020)
                    -- vertical bar
                    gui.stretched_image(image_path .. "scrollbar_vertical.png", 0.020, height - 0.04)
                    -- down arrow
                    gui.stretched_image(image_path .. "scrollbar_down.png", 0.020, 0.020, selected)
                end)
            end)

            gui.scroll_button(function()
                -- scroll_button idle
                gui.stretched_image(image_path .. "scrollbar_button_vertical.png", 0.020, 0, function()
                    gui.clamp(0, 0, 1, 1)
                end)
                -- scroll_button hover
                gui.stretched_image(image_path .. "scrollbar_button_vertical.png", 0.020, 0, function()
                    gui.clamp(0, 0, 1, 1)
                    hover()
                end)
                -- scroll_button selected
                gui.stretched_image(image_path .. "scrollbar_button_vertical.png", 0.020, 0, function()
                    gui.clamp(0, 0, 1, 1)
                    selected()
                end)
            end)
        end)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.hscrollbar(0.020, 1, function()
            -- both arrows idle
            gui.fill(0, 0.020, function()
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretched_image(image_path .. "scrollbar_left.png", 0.020, 0.020)
                    -- horizontal bar
                    gui.stretched_image(image_path .. "scrollbar_horizontal.png", width - 0.04, 0.020)
                    -- right arrow
                    gui.stretched_image(image_path .. "scrollbar_right.png", 0.020, 0.020)
                end)
            end)

            -- left arrow hover
            gui.fill(0, 0.020, function()
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretched_image(image_path .. "scrollbar_left.png", 0.020, 0.020, hover)
                    -- horizontal bar
                    gui.stretched_image(image_path .. "scrollbar_horizontal.png", width - 0.04, 0.020)
                    -- right arrow
                    gui.stretched_image(image_path .. "scrollbar_right.png", 0.020, 0.020)
                end)
            end)

            -- left arrow selected
            gui.fill(0, 0.020, function()
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretched_image(image_path .. "scrollbar_left.png", 0.020, 0.020, selected)
                    -- horizontal bar
                    gui.stretched_image(image_path .. "scrollbar_horizontal.png", width - 0.04, 0.020)
                    -- right arrow
                    gui.stretched_image(image_path .. "scrollbar_right.png", 0.020, 0.020)
                end)
            end)

            -- right arrow hover
            gui.fill(0, 0.020, function()
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretched_image(image_path .. "scrollbar_left.png", 0.020, 0.020)
                    -- horizontal bar
                    gui.stretched_image(image_path .. "scrollbar_horizontal.png", width - 0.04, 0.020)
                    -- right arrow
                    gui.stretched_image(image_path .. "scrollbar_right.png", 0.020, 0.020, hover)
                end)
            end)

            -- right arrow selected
            gui.fill(0, 0.020, function()
                gui.hlist(0, function()
                    -- left arrow
                    gui.stretched_image(image_path .. "scrollbar_left.png", 0.020, 0.020)
                    -- horizontal bar
                    gui.stretched_image(image_path .. "scrollbar_horizontal.png", width - 0.04, 0.020)
                    -- right arrow
                    gui.stretched_image(image_path .. "scrollbar_right.png", 0.020, 0.020, selected)
                end)
            end)

            gui.scroll_button(function()
                -- scroll_button idle
                gui.stretched_image(image_path .. "scrollbar_button_horizontal.png", 0, 0.020, function()
                    gui.clamp(1, 1, 1, 1)
                end)
                -- scroll_button hover
                gui.stretched_image(image_path .. "scrollbar_button_horizontal.png", 0, 0.020, function()
                    gui.clamp(1, 1, 0, 0)
                    hover()
                end)
                -- scroll_button selected
                gui.stretched_image(image_path .. "scrollbar_button_horizontal.png", 0, 0.020, function()
                    gui.clamp(1, 1, 0, 0)
                    selected()
                end)
            end)
        end)
        gui.color(1, 1, 1, 0.1, 0.020, 0.020)
        gui.color(1, 1, 1, 0.2, 0.001, 0, function() gui.clamp(0, 0, 1, 1) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0, 0.001, function() gui.clamp(1, 1, 0, 0) end)
        gui.color(1, 1, 1, 0.2, 0.001, 0.001)
    end)
end
