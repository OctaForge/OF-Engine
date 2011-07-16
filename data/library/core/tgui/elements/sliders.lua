module("tgui", package.seeall)

function hslider(var, minv, maxv)
     gui.hslider(var, minv, maxv, function()
        gui.clamp(1, 1, 0, 0)
        gui.hlist(0, function()
            gui.stretched_image(image_path .. "slider_horizontal_left.png", 0.01, 0.01)
            gui.stretched_image(
                image_path .. "slider_horizontal_middle.png",
                0.98, 0.01,
                function()
                    gui.clamp(1, 1, 0, 0)
                end
            )
            gui.stretched_image(image_path .. "slider_horizontal_right.png", 0.01, 0.01)
        end)
        gui.slider_button(function()
            -- idle state
            gui.color(0, 0, 0, 0, 0.06, 0, function()
                gui.hlist(0, function()
                    gui.stretched_image(image_path .. "slider_horizontal_left.png", 0.03, 0.03)
                    gui.stretched_image(image_path .. "slider_horizontal_right.png", 0.03, 0.03)
                end)
                gui.var_label(var)
            end)
            -- hover state
            gui.color(0, 0, 0, 0, 0.06, 0, function()
                gui.hlist(0, function()
                    gui.stretched_image(image_path .. "slider_horizontal_left.png", 0.03, 0.03)
                    gui.stretched_image(image_path .. "slider_horizontal_right.png", 0.03, 0.03)
                end)
                hover()
                gui.var_label(var)
            end)
            -- selected state
            gui.color(0, 0, 0, 0, 0.06, 0, function()
                gui.hlist(0, function()
                    gui.stretched_image(image_path .. "slider_horizontal_left.png", 0.03, 0.03)
                    gui.stretched_image(image_path .. "slider_horizontal_right.png", 0.03, 0.03)
                end)
                selected()
                gui.var_label(var)
            end)
        end)
     end)
end

function vslider(var, minv, maxv)
     gui.vslider(var, minv, maxv, function()
        gui.clamp(0, 0, 1, 1)
        gui.vlist(0, function()
            gui.stretched_image(image_path .. "slider_vertical_up.png", 0.01, 0.01)
            gui.stretched_image(
                image_path .. "slider_vertical_middle.png",
                0.01, 0.98,
                function()
                    gui.clamp(0, 0, 1, 1)
                end
            )
            gui.stretched_image(image_path .. "slider_vertical_down.png", 0.01, 0.01)
        end)
        gui.slider_button(function()
            -- idle state
            gui.color(0, 0, 0, 0, 0.06, 0, function()
                gui.hlist(0, function()
                    gui.stretched_image(image_path .. "slider_horizontal_left.png", 0.03, 0.03)
                    gui.stretched_image(image_path .. "slider_horizontal_right.png", 0.03, 0.03)
                end)
                gui.var_label(var)
            end)
            -- hover state
            gui.color(0, 0, 0, 0, 0.06, 0, function()
                gui.hlist(0, function()
                    gui.stretched_image(image_path .. "slider_horizontal_left.png", 0.03, 0.03)
                    gui.stretched_image(image_path .. "slider_horizontal_right.png", 0.03, 0.03)
                end)
                hover()
                gui.var_label(var)
            end)
            -- selected state
            gui.color(0, 0, 0, 0, 0.06, 0, function()
                gui.hlist(0, function()
                    gui.stretched_image(image_path .. "slider_horizontal_left.png", 0.03, 0.03)
                    gui.stretched_image(image_path .. "slider_horizontal_right.png", 0.03, 0.03)
                end)
                selected()
                gui.var_label(var)
            end)
        end)
     end)
end
