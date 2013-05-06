--[[! File: library/core/gui/default/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Default extended GUI set for OctaForge.
]]

#log(DEBUG, ":::::: Default UI set.")

local images  = "data/ui/themes/default/"
local cursors = images .. "cursors/"
local icons   = images .. "icons/"

local get_image_path = function(p)
    return images .. p
end

local get_cursor_path = function(p)
    return cursors .. p
end

local get_icon_path = function(p)
    return icons .. p
end

local M = {}

local gip, gcp = get_image_path, get_cursor_path

local FILTER_NEAREST = gui.FILTER_NEAREST

local Window = function(kwargs)
    kwargs = kwargs or {}

    local title = kwargs.title

    local t = gui.Table {
        columns = 3,
        padding = 0
    }

    if title then
        t:append(gui.Image {
            file = gip("corner_top_left.png"), pointer = gcp("tl_br.png"),
            min_w = -6, min_h = -30
        })

        local img = t:append(gui.Image {
            file = gip("edge.png"),
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
        })
        img:append(gui.Mover {
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true,

            gui.Rectangle {
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true,
                a = 0,

                gui.Label { text = title, align_h = -1 },
                gui.H_Box {
                    gui.Spacer {
                        gui.Image {
                            file = gip("btn_min.png"),
                            min_filter = FILTER_NEAREST, mag_filter = FILTER_NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002
                    },
                    gui.Spacer {
                        gui.Image {
                            file = gip("btn_max.png"),
                            min_filter = FILTER_NEAREST, mag_filter = FILTER_NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002
                    },
                    gui.Spacer {
                        gui.Image {
                            file = gip("btn_close.png"),
                            min_filter = FILTER_NEAREST, mag_filter = FILTER_NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002,
                    },

                    align_h = 1
                }
            }
        })

        t:append(gui.Image {
            file = gip("corner_top_right.png"), pointer = gcp("tr_bl.png"),
            min_w = -6, min_h = -30
        })
    else
        t:append(gui.Image {
            file = gip("corner_top_left_small.png"),
            pointer = gcp("tl_br.png"), min_w = -6, min_h = -6
        })

        local img = t:append(gui.Image {
            file = gip("edge.png"),
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
        })
        img:append(gui.Mover {
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
        })

        t:append(gui.Image {
            file = gip("corner_top_right_small.png"),
            pointer = gcp("tr_bl.png"), min_w = "6p", min_h = "6p"
        })
    end

    t:append(gui.Image {
        file = gip("edge.png"), pointer = gcp("leftright.png"),
        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })
    t:append(gui.Image {
        file = gip("edge.png"),

        gui.Table {
            columns = 3, padding = 0,

            gui.Image { file = gip("corner_in_top_left.png") },
            gui.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },
            gui.Image { file = gip("corner_in_top_right.png") },

            gui.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },
            gui.Image {
                file = gip("edge_in.png"), unpack(kwargs)
            },
            gui.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },

            gui.Image { file = gip("corner_in_bottom_left.png") },
            gui.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },
            gui.Image { file = gip("corner_in_bottom_right.png") }
        },

        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })
    t:append(gui.Image {
        file = gip("edge.png"), pointer = gcp("leftright.png"),
        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })

    t:append(gui.Image {
        file = gip("corner_bottom_left.png"), pointer = gcp("tr_bl.png"),
        min_w = -6, min_h = -6
    })
    t:append(gui.Image {
        file = gip("edge.png"), pointer = gcp("updown.png"),
        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })
    t:append(gui.Image {
        file = gip("corner_bottom_right.png"), pointer = gcp("tl_br.png"),
        min_w = -6, min_h = -6
    })

    return t
end
M.Test_Window = Window

return M
