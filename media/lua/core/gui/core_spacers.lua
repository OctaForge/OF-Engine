--[[!<
    Spacers are widgets that have something to do with space management -
    that is, actual spacers, offsetters, fillers etc.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local max  = math.max
local min  = math.min
local abs  = math.abs
local huge = math.huge

--! Module: core
local M = require("core.gui.core")

local capi = require("capi")

-- widget types
local register_class = M.register_class

-- children iteration
local loop_children, loop_children_r = M.loop_children, M.loop_children_r

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

--[[!
    A spacer will give a widget some padding.

    Properties:
        - pad_h, pad_v - the padding values, both default to 0.
]]
M.Spacer = register_class("Spacer", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.pad_h = kwargs.pad_h or 0
        self.pad_v = kwargs.pad_v or 0

        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        local ph, pv = self.pad_h, self.pad_v
        local w , h  = ph, pv

        loop_children(self, function(o)
            o.x = ph
            o.y = pv
            o:layout()

            w = max(w, o.x + o.w)
            h = max(h, o.y + o.h)
        end)

        self.w = w + ph
        self.h = h + pv
    end,

    adjust_children = function(self)
        local ph, pv = self.pad_h, self.pad_v
        Widget.adjust_children(self, ph, pv, self.w - 2 * ph,
            self.h - 2 * pv)
    end,

    --! Function: set_pad_h
    set_pad_h = gen_setter "pad_h",

    --! Function: set_pad_v
    set_pad_v = gen_setter "pad_v"
})

--[[!
    A filler will fill at least min_w space horizontally and min_h space
    vertically. It's invisible.

    Negative min_w and min_h values are in pixels.
    They can also be functions, in which case their return value is used
    (the widget is passed as an argument for the call).

    Infinite values of min_w and min_h are treated as full width or full
    height.

    Properties:
        - min_w, min_h - minimal dimensions of the filler.
        - clip_children - when true, it clips children inside (if they have
          parts outside of the filler, they won't be viisble), defaults
          to false (useful for MDI windows for example).
]]
M.Filler = register_class("Filler", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.min_w = kwargs.min_w or 0
        self.min_h = kwargs.min_h or 0

        self.clip_children = kwargs.clip_children or false

        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        Widget.layout(self)

        local min_w = self.min_w
        local min_h = self.min_h
        if type(min_w) == "function" then min_w = min_w(self) end
        if type(min_h) == "function" then min_h = min_h(self) end

        local r = self:get_root()

        if min_w < 0 then min_w = abs(min_w) / r:get_pixel_h() end
        if min_h < 0 then min_h = abs(min_h) / r:get_pixel_h() end

        local proj = r:get_projection()
        if min_w == huge then min_w = proj.pw end
        if min_h == huge then min_h = proj.ph end

        self.w = max(self.w, min_w)
        self.h = max(self.h, min_h)
    end,

    --[[!
        Makes sure the filler can take input. Makes it useful for, say, button
        surfaces (when they should be invisible). See also {{$Widget.target}}.
    ]]
    target = function(self, cx, cy)
        return Widget.target(self, cx, cy) or self
    end,

    draw = function(self, sx, sy)
        if self.clip_children then
            self:get_root():clip_push(sx, sy, self.w, self.h)
            Widget.draw(self, sx, sy)
            self:get_root():clip_pop()
        else
            return Widget.draw(self, sx, sy)
        end
    end,

    --! Function: set_min_w
    set_min_w = gen_setter "min_w",

    --! Function: set_min_h
    set_min_h = gen_setter "min_h",

    --! Function: set_clip_children
    set_clip_children = gen_setter "clip_children"
})
local Filler = M.Filler

--[[!
    Like $Filler, but its min_w and min_h work in terms of text units.
    By default uses regular text scale factor.

    Note that this widget doesn't support extra min_w and min_h values
    like $Filler - it operates strictly in terms of text units. Function
    based bounds are supported.

    Properties:
        - console_text - if true (false by default), this will use console
          scaling factor rather than regular text scaling factor.
]]
M.Text_Filler = register_class("Text_Filler", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.console_text = kwargs.console_text or false
        return Filler.__ctor(self, kwargs)
    end,

    layout = function(self)
        Widget.layout(self)

        local min_w = self.min_w
        local min_h = self.min_h
        if type(min_w) == "function" then min_w = min_w(self) end
        if type(min_h) == "function" then min_h = min_h(self) end

        local scalef = self:get_root():get_text_scale(self.console_text)
        self.w = max(self.w, min_w * scalef * 0.5)
        self.h = max(self.h, min_h * scalef)
    end,
})

--[[!
    Offsets a widget.

    Properties:
        - offset_h, offset_v - the offset values.
]]
M.Offsetter = register_class("Offsetter", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.offset_h = kwargs.offset_h or 0
        self.offset_v = kwargs.offset_v or 0

        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        Widget.layout(self)

        local oh, ov = self.offset_h, self.offset_v

        loop_children(self, function(o)
            o.x = o.x + oh
            o.y = o.y + ov
        end)

        self.w = self.w + oh
        self.h = self.h + ov
    end,

    adjust_children = function(self)
        local oh, ov = self.offset_h, self.offset_v
        Widget.adjust_children(self, oh, ov, self.w - oh, self.h - ov)
    end,

    --! Function: set_offset_h
    set_offset_h = gen_setter "offset_h",

    --! Function: set_offset_v
    set_offset_v = gen_setter "offset_v"
})
