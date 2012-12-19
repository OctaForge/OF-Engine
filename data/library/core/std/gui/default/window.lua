--[[! File: library/core/std/gui/default/window.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        The default "window".
]]

local config = require "std.gui.default.config"
local core   = gui.core

local gip, gcp = config.get_image_path, config.get_cursor_path

return function(kwargs)
    kwargs = kwargs or {}

    local title = kwargs.title

    local t = core.Table {
        columns = 3,
        padding = 0,
        floating = true
    }

    if title then
        t:append(core.Image {
            file = gip("corner_top_left.png"),
            pointer = gcp("tl_br.png"),
            min_w = -6, min_h = -30
        })

        local img = t:append(core.Image {
            file = gip("edge.png"),
            clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
        })
        img:append(core.Mover {
            clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1,

            core.Rectangle {
                clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1, a = 0,

                core.Label {
                    text = title, align_h = -1
                },

                core.H_Box {
                    core.Spacer {
                        core.Image {
                            file = gip("btn_min.png"),
                            min_filter = gl.NEAREST,
                            mag_filter = gl.NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002
                    },
                    core.Spacer {
                        core.Image {
                            file = gip("btn_max.png"),
                            min_filter = gl.NEAREST,
                            mag_filter = gl.NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002
                    },
                    core.Spacer {
                        core.Image {
                            file = gip("btn_close.png"),
                            min_filter = gl.NEAREST,
                            mag_filter = gl.NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002,
                    },

                    align_h = 1
                }
            }
        }):link(t)

        t:append(core.Image {
            file = gip("corner_top_right.png"),
            pointer = gcp("tr_bl.png"),
            min_w = -6, min_h = -30
        })
    else
        t:append(core.Image {
            file = gip("corner_top_left_small.png"),
            pointer = gcp("tl_br.png"),
            min_w = -6, min_h = -6
        })

        local img = t:append(core.Image {
            file = gip("edge.png"),
            clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
        })
        img:append(core.Mover {
            clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
        }):link(t)

        t:append(core.Image {
            file = gip("corner_top_right_small.png"),
            pointer = gcp("tr_bl.png"),
            min_w = "6p", min_h = "6p"
        })
    end

    t:append(core.Image {
        file = gip("edge.png"),
        clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1,
        pointer = gcp("leftright.png")
    })
    t:append(core.Image {
        file = gip("edge.png"),

        core.Table {
            columns = 3,
            padding = 0,

            core.Image { file = gip("corner_in_top_left.png") },
            core.Image {
                file = gip("edge_in.png"),
                clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
            },
            core.Image { file = gip("corner_in_top_right.png") },

            core.Image {
                file = gip("edge_in.png"),
                clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
            },
            core.Image {
                file = gip("edge_in.png"),
                unpack(kwargs)
            },
            core.Image {
                file = gip("edge_in.png"),
                clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
            },

            core.Image { file = gip("corner_in_bottom_left.png") },
            core.Image {
                file = gip("edge_in.png"),
                clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
            },
            core.Image { file = gip("corner_in_bottom_right.png") }
        },

        clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1
    })
    t:append(core.Image {
        file = gip("edge.png"),
        clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1,
        pointer = gcp("leftright.png")
    })

    t:append(core.Image {
        file = gip("corner_bottom_left.png"),
        pointer = gcp("tr_bl.png"),
        min_w = -6, min_h = -6
    })
    t:append(core.Image {
        file = gip("edge.png"),
        clamp_l = 1, clamp_r = 1, clamp_t = 1, clamp_b = 1,
        pointer = gcp("updown.png")
    })
    t:append(core.Image {
        file = gip("corner_bottom_right.png"),
        pointer = gcp("tl_br.png"),
        min_w = -6, min_h = -6
    })

    return t
end
