module("tgui", package.seeall)

function window(name, title, body, noclose, notitle, nofocus, realtime, onhide)
    noclose = noclose or function() return false end
    gui.new(name, function()
        gui.table(3, 0, function()
            if not notitle then
                -- upper left corner
                gui.stretchedimage(image_path .. "corner_upper_left.png", 0.01, 0.025)
                -- upper edge
                gui.stretchedimage(image_path .. "window_background.png", 0, 0.025, function()
                    gui.clamp(1, 1, 0, 0)
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
                                gui.stretchedimage(image_path .. "icons/icon_close.png", 0.024, 0.024)
                                -- hover state
                                gui.stretchedimage(image_path .. "icons/icon_close.png", 0.024, 0.024, hover)
                                -- selected state
                                gui.stretchedimage(image_path .. "icons/icon_close.png", 0.024, 0.024, selected)
                            end
                        )
                    end
                end)
                -- upper right corner
                gui.stretchedimage(image_path .. "corner_upper_right.png", 0.01, 0.025)
            else
                -- upper left corner
                gui.stretchedimage(image_path .. "corner_upper_left_small.png", 0.01, 0.01)
                -- upper edge
                gui.stretchedimage(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
                -- upper right corner
                gui.stretchedimage(image_path .. "corner_upper_right_small.png", 0.01, 0.01)
            end

            -- left edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- body
            gui.stretchedimage(image_path .. "window_background_alt.png", 0, 0, function()
                gui.clamp(1, 1, 1, 1)
                gui.space(0.01, 0.01, function()
                    gui.align(0, 0)
                    body()
                end)
            end)

            -- right edge
            gui.stretchedimage(image_path .. "window_background.png", 0.01, 0, function() gui.clamp(0, 0, 1, 1) end)

            -- lower left corner
            gui.stretchedimage(image_path .. "corner_lower_left.png", 0.01, 0.01)
            -- lower edge
            gui.stretchedimage(image_path .. "window_background.png", 0, 0.01, function() gui.clamp(1, 1, 0, 0) end)
            -- lower right corner
            gui.stretchedimage(image_path .. "corner_lower_right.png", 0.01, 0.01)
        end)
    end, nofocus and 1 or 0, realtime and 1 or 0, onhide)
end

window("message", "Unknown", function()
    gui.vlist(0, function()
        gui.tag("message", function() end)
        button("close", function() gui.hide("message") end)
    end)
end)

gui.message = function(title, text)
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

function space(name, body, hasfocus, onhide)
    gui.new(name, function()
        gui.align(-1, 0)
        gui.fill(scr_w / scr_h, 1, function()
            body()
        end)
    end, hasfocus and 0 or 1, 0, onhide)
end
