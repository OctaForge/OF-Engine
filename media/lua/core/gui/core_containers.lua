--[[!<
    Container GUI widgets.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local max = math.max
local min = math.min

local createtable = require("capi").table_create

--! Module: core
local M = require("core.gui.core")

-- consts
local gl, key = M.gl, M.key

-- widget types
local register_class = M.register_class

-- children iteration
local loop_children, loop_children_r = M.loop_children, M.loop_children_r

-- scissoring
local clip_push, clip_pop = M.clip_push, M.clip_pop

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

-- adjustment
local adjust = M.adjust

local CLAMP_LEFT, CLAMP_RIGHT, CLAMP_TOP, CLAMP_BOTTOM in adjust
local clampsv = function(adj)
    return ((adj & CLAMP_TOP) != 0) and ((adj & CLAMP_BOTTOM) != 0)
end
local clampsh = function(adj)
    return ((adj & CLAMP_LEFT) != 0) and ((adj & CLAMP_RIGHT) != 0)
end

--[[!
    A horizontal box. Boxes are containers that hold multiple widgets that
    do not cover each other.

    Properties:
        - padding - the padding between the items (the actual width is the
          width of the items extended by (nitems - 1) * padding).
        - expand - a boolean, if true, items clamped from both left and
          right will divide the remaining space the other items didn't
          fill between themselves, in the other case clamping will have
          no effect and the items will be aligned evenly through the list.
        - homogenous - the box will attempt to reserve an equal amount of
          space for every item in the box, items that clamp will be clamped
          inside of their space and the other items will be aligned depending
          on their own alignment. Takes precedence over "expand". Only one can
          be in effect and both default to false.

    See also:
        - $V_Box
        - $Grid
]]
M.H_Box = register_class("H_Box", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding    = kwargs.padding    or 0
        self.expand     = kwargs.expand     or false
        self.homogenous = kwargs.homogenous or false
        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        self.w, self.h = 0, 0
        local subw = 0
        local ncl, ex = 0, self.expand
        loop_children(self, function(o)
            o.x = subw
            o.y = 0
            o:layout()
            subw += o.w
            self.h = max(self.h, o.y + o.h)
            if ex and clampsh(o.adjust) then ncl += 1 end
        end)
        self.w = subw + self.padding * max(#self.vstates + 
            #self.children - 1, 0)
        self.subw, self.ncl = subw, ncl
    end,

    adjust_children_regular = function(self, no, hmg)
        local offset, space = 0, (self.w - self.subw) / max(no - 1, 1)
        loop_children(self, function(o)
            o.x = offset
            offset += o.w + space
            o:adjust_layout(o.x, 0, o.w, self.h)
        end)
    end,

    adjust_children_homogenous = function(self, no)
        local pad = self.padding
        local offset, space = 0, (self.w - self.subw - (no - 1) * pad)
            / max(no, 1)
        loop_children(self, function(o)
            o.x = offset
            offset += o.w + space + pad
            o:adjust_layout(o.x, 0, o.w + space, self.h)
        end)
    end,

    adjust_children_expand = function(self, no)
        local pad = self.padding
        local dpad = pad * max(no - 1, 0)
        local offset, space = 0, ((self.w - self.subw) / self.ncl - dpad)
        loop_children(self, function(o)
            o.x = offset
            o:adjust_layout(o.x, 0, o.w + (clampsh(o.adjust) and space or 0),
                self.h)
            offset += o.w + pad
        end)
    end,

    adjust_children = function(self)
        local nch, nvs = #self.children, #self.vstates
        if nch == 0 and nvs == 0 then return end
        if self.homogenous then
            return self:adjust_children_homogenous(nch + nvs)
        elseif self.expand and self.ncl != 0 then
            return self:adjust_children_expand(nch + nvs)
        end
        return self:adjust_children_regular(nch + nvs)
    end,

    --! Function: set_padding
    set_padding = gen_setter "padding",

    --! Function: set_expand
    set_expand = gen_setter "expand",

    --! Function: set_homogenous
    set_homogenous = gen_setter "homogenous"
})

--[[!
    See $H_Box. This is a vertical variant, for its properties top/bottom
    clamping is relevant rather than left/right.
]]
M.V_Box = register_class("V_Box", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding    = kwargs.padding    or 0
        self.expand     = kwargs.expand     or false
        self.homogenous = kwargs.homogenous or false
        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        self.w, self.h = 0, 0
        local subh = 0
        local ncl, ex = 0, self.expand
        loop_children(self, function(o)
            o.x = 0
            o.y = subh
            o:layout()
            subh += o.h
            self.w = max(self.w, o.x + o.w)
            if ex and clampsv(o.adjust) then ncl += 1 end
        end)
        self.h = subh + self.padding * max(#self.vstates +
            #self.children - 1, 0)
        self.subh, self.ncl = subh, ncl
    end,

    adjust_children_regular = function(self, no)
        local offset, space = 0, (self.h - self.subh) / max(no - 1, 1)
        loop_children(self, function(o)
            o.y = offset
            offset += o.h + space
            o:adjust_layout(0, o.y, self.w, o.h)
        end)
    end,

    adjust_children_homogenous = function(self, no)
        local pad = self.padding
        local offset, space = 0, (self.h - self.subh - (no - 1) * pad)
            / max(no, 1)
        loop_children(self, function(o)
            o.y = offset
            offset += o.h + space + pad
            o:adjust_layout(0, o.y, self.w, o.h + space)
        end)
    end,

    adjust_children_expand = function(self, no)
        local pad = self.padding
        local dpad = pad * max(no - 1, 0)
        local offset, space = 0, ((self.h - self.subh) / self.ncl - dpad)
        loop_children(self, function(o)
            o.y = offset
            o:adjust_layout(0, o.y, self.w,
                o.h + (clampsv(o.adjust) and space or 0))
            offset += o.h + pad
        end)
    end,

    adjust_children = function(self)
        local nch, nvs = #self.children, #self.vstates
        if nch == 0 and nvs == 0 then return end
        if self.homogenous then
            return self:adjust_children_homogenous(nch + nvs)
        elseif self.expand and self.ncl != 0 then
            return self:adjust_children_expand(nch + nvs)
        end
        return self:adjust_children_regular(nch + nvs)
    end,

    --! Function: set_padding
    set_padding = gen_setter "padding",

    --! Function: set_expand
    set_expand = gen_setter "expand",

    --! Function: set_homogenous
    set_homogenous = gen_setter "homogenous"
}, M.H_Box.type)

--[[!
    A grid of elements. As you append, the children will automatically
    position themselves according to the max number of columns.

    Properties:
        - columns - the number of columns the grid will have at maximum,
          defaulting to 0.
        - padding - the padding between grid items (both horizontal and
          vertical).

    See also:
        - $H_Box
]]
M.Grid = register_class("Grid", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.columns = kwargs.columns or 0
        self.padding = kwargs.padding or 0
        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        local widths, heights = createtable(4), createtable(4)
        self.widths, self.heights = widths, heights

        local column, row = 1, 1
        local columns, padding = self.columns, self.padding

        loop_children(self, function(o)
            o:layout()

            if #widths < column then
                widths[#widths + 1] = o.w
            elseif o.w > widths[column] then
                widths[column] = o.w
            end

            if #heights < row then
                heights[#heights + 1] = o.h
            elseif o.h > heights[row] then
                heights[row] = o.h
            end

            column = (column % columns) + 1
            if column == 1 then
                row += 1
            end
        end)

        local subw, subh = 0, 0
        for i = 1, #widths  do subw +=  widths[i] end
        for i = 1, #heights do subh += heights[i] end
        self.w = subw + padding * max(#widths  - 1, 0)
        self.h = subh + padding * max(#heights - 1, 0)
        self.subw, self.subh = subw, subh
    end,

    adjust_children = function(self)
        if #self.children == 0 and #self.vstates == 0 then return end
        local widths, heights = self.widths, self.heights
        local column , row     = 1, 1
        local offsetx, offsety = 0, 0
        local cspace = (self.w - self.subw) / max(#widths  - 1, 1)
        local rspace = (self.h - self.subh) / max(#heights - 1, 1)
        local columns = self.columns

        loop_children(self, function(o)
            o.x = offsetx
            o.y = offsety

            local wc, hr = widths[column], heights[row]
            o:adjust_layout(offsetx, offsety, wc, hr)

            offsetx += wc + cspace
            column = (column % columns) + 1

            if column == 1 then
                offsetx = 0
                offsety += hr + rspace
                row += 1
            end
        end)
    end,

    --! Function: set_padding
    set_padding = gen_setter "padding",

    --! Function: set_columns
    set_columns = gen_setter "columns"
})

--[[!
    Clips the children inside of it by its properties.

    Properties:
        - clip_w - the width of the clipper.
        - clip_h - the height of the clipper.
]]
M.Clipper = register_class("Clipper", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.clip_w = kwargs.clip_w or 0
        self.clip_h = kwargs.clip_h or 0
        self.virt_w = 0
        self.virt_h = 0

        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        Widget.layout(self)
    
        self.virt_w = self.w
        self.virt_h = self.h

        local cw, ch = self.clip_w, self.clip_h

        if cw != 0 then self.w = min(self.w, cw) end
        if ch != 0 then self.h = min(self.h, ch) end
    end,

    adjust_children = function(self)
        Widget.adjust_children(self, 0, 0, self.virt_w, self.virt_h)
    end,

    draw = function(self, sx, sy)
        local cw, ch = self.clip_w, self.clip_h

        if (cw != 0 and self.virt_w > cw) or (ch != 0 and self.virt_h > ch)
        then
            clip_push(sx, sy, self.w, self.h)
            Widget.draw(self, sx, sy)
            clip_pop()
        else
            return Widget.draw(self, sx, sy)
        end
    end,

    --! Function: set_clip_w
    set_clip_w = gen_setter "clip_w",

    --! Function: set_clip_h
    set_clip_h = gen_setter "clip_h"
})
