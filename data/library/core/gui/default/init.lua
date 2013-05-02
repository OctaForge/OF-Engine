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
local widgets = gui.widgets

local FILTER_NEAREST = widgets.FILTER_NEAREST

local Button = function(kwargs)
    if not kwargs.label_only then
        return widgets.Button {
            signals = kwargs.signals,
            tooltip = kwargs.tooltip,
            pointer = kwargs.pointer,
            states = {
                default = widgets.Filler {
                    clamp_l = true, clamp_r = true,
                    widgets.H_Box {
                        widgets.Stretched_Image {
                            file = gip("corner_top_left.png"),
                            min_w = 0.01, min_h = 0.03
                        },
                        widgets.Stretched_Image {
                            file = gip("edge.png"),
                            min_w = 0.15, min_h = 0.03,
                            clamp_l = true, clamp_r = true,
                        },
                        widgets.Stretched_Image {
                            file = gip("corner_top_right.png"),
                            min_w = 0.01, min_h = 0.03
                        }
                    },
                    widgets.Label { text = kwargs.label }
                },
                hovering = widgets.Filler {
                    clamp_l = true, clamp_r = true,
                    widgets.H_Box {
                        widgets.Stretched_Image {
                            file = gip("corner_top_left.png"),
                            min_w = 0.01, min_h = 0.03
                        },
                        widgets.Stretched_Image {
                            file = gip("edge.png"),
                            min_w = 0.15, min_h = 0.03,
                            clamp_l = true, clamp_r = true,
                        },
                        widgets.Stretched_Image {
                            file = gip("corner_top_right.png"),
                            min_w = 0.01, min_h = 0.03
                        }
                    },
                    widgets.Label { text = kwargs.label }
                },
                clicked = widgets.Filler {
                    clamp_l = true, clamp_r = true,
                    widgets.H_Box {
                        widgets.Stretched_Image {
                            file = gip("corner_top_left.png"),
                            min_w = 0.01, min_h = 0.03
                        },
                        widgets.Stretched_Image {
                            file = gip("edge.png"),
                            min_w = 0.15, min_h = 0.03,
                            clamp_l = true, clamp_r = true,
                        },
                        widgets.Stretched_Image {
                            file = gip("corner_top_right.png"),
                            min_w = 0.01, min_h = 0.03
                        }
                    },
                    widgets.Label { text = kwargs.label }
                }
            },
        }
    end
end
M.Button = Button

local Window = function(kwargs)
    kwargs = kwargs or {}

    local title = kwargs.title

    local t = widgets.Table {
        columns = 3,
        padding = 0
    }

    if title then
        t:append(widgets.Image {
            file = gip("corner_top_left.png"), pointer = gcp("tl_br.png"),
            min_w = -6, min_h = -30
        })

        local img = t:append(widgets.Image {
            file = gip("edge.png"),
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
        })
        img:append(widgets.Mover {
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true,

            widgets.Rectangle {
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true,
                a = 0,

                widgets.Label { text = title, align_h = -1 },
                widgets.H_Box {
                    widgets.Spacer {
                        widgets.Image {
                            file = gip("btn_min.png"),
                            min_filter = FILTER_NEAREST, mag_filter = FILTER_NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002
                    },
                    widgets.Spacer {
                        widgets.Image {
                            file = gip("btn_max.png"),
                            min_filter = FILTER_NEAREST, mag_filter = FILTER_NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002
                    },
                    widgets.Spacer {
                        widgets.Image {
                            file = gip("btn_close.png"),
                            min_filter = FILTER_NEAREST, mag_filter = FILTER_NEAREST
                        },
                        pad_h = 0.002, pad_v = 0.002,
                    },

                    align_h = 1
                }
            }
        })

        t:append(widgets.Image {
            file = gip("corner_top_right.png"), pointer = gcp("tr_bl.png"),
            min_w = -6, min_h = -30
        })
    else
        t:append(widgets.Image {
            file = gip("corner_top_left_small.png"),
            pointer = gcp("tl_br.png"), min_w = -6, min_h = -6
        })

        local img = t:append(widgets.Image {
            file = gip("edge.png"),
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
        })
        img:append(widgets.Mover {
            clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
        })

        t:append(widgets.Image {
            file = gip("corner_top_right_small.png"),
            pointer = gcp("tr_bl.png"), min_w = "6p", min_h = "6p"
        })
    end

    t:append(widgets.Image {
        file = gip("edge.png"), pointer = gcp("leftright.png"),
        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })
    t:append(widgets.Image {
        file = gip("edge.png"),

        widgets.Table {
            columns = 3, padding = 0,

            widgets.Image { file = gip("corner_in_top_left.png") },
            widgets.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },
            widgets.Image { file = gip("corner_in_top_right.png") },

            widgets.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },
            widgets.Image {
                file = gip("edge_in.png"), unpack(kwargs)
            },
            widgets.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },

            widgets.Image { file = gip("corner_in_bottom_left.png") },
            widgets.Image {
                file = gip("edge_in.png"),
                clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
            },
            widgets.Image { file = gip("corner_in_bottom_right.png") }
        },

        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })
    t:append(widgets.Image {
        file = gip("edge.png"), pointer = gcp("leftright.png"),
        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })

    t:append(widgets.Image {
        file = gip("corner_bottom_left.png"), pointer = gcp("tr_bl.png"),
        min_w = -6, min_h = -6
    })
    t:append(widgets.Image {
        file = gip("edge.png"), pointer = gcp("updown.png"),
        clamp_l = true, clamp_r = true, clamp_t = true, clamp_b = true
    })
    t:append(widgets.Image {
        file = gip("corner_bottom_right.png"), pointer = gcp("tl_br.png"),
        min_w = -6, min_h = -6
    })

    return t
end
M.Window = Window

return M
