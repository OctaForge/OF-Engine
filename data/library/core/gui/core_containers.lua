--[[! File: library/core/gui/core_widgets.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Features container widgets for the OF GUI.
]]

local M = gui
local world = M.get_world()

-- consts
local gl, key = M.gl, M.key

-- input event management
local is_clicked, is_hovering, is_focused, clear_focus = M.is_clicked,
    M.is_hovering, M.is_focused, M.clear_focus

-- widget types
local register_class = M.register_class

-- children iteration
local loop_children, loop_children_r = M.loop_children, M.loop_children_r

-- scissoring
local clip_push, clip_pop = M.clip_push, M.clip_pop

-- base widgets
local Object = M.get_class("Object")

-- setters
local gen_setter = M.gen_setter

--[[! Struct: H_Box
    A horizontal box. Boxes are containers that hold multiple widgets that
    do not cover each other. It has one extra property, padding, specifying
    the padding between the items (the actual width is width of items
    extended by (nitems-1)*padding).
]]
M.H_Box = register_class("H_Box", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding = kwargs.padding or 0
        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        self.w, self.h = 0, 0

        loop_children(self, function(o)
            o.x = self.w
            o.y = 0
            o:layout()

            self.w = self.w + o.w
            self.h = max(self.h, o.y + o.h)
        end)
        self.w = self.w + self.padding * max(#self.children - 1, 0)
    end,

    adjust_children = function(self)
        if #self.children == 0 then
            return nil
        end

        local offset = 0
        loop_children(self, function(o)
            o.x = offset
            offset = offset + o.w

            o:adjust_layout(o.x, 0, o.w, self.h)
            offset = offset + self.padding
        end)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding"
})

--[[! Struct: V_Box
    See <H_Box>. This is a vertical variant.
]]
M.V_Box = register_class("V_Box", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding = kwargs.padding or 0
        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        self.w = 0
        self.h = 0

        loop_children(self, function(o)
            o.x = 0
            o.y = self.h
            o:layout()

            self.h = self.h + o.h
            self.w = max(self.w, o.x + o.w)
        end)
        self.h = self.h + self.padding * max(#self.children - 1, 0)
    end,

    adjust_children = function(self)
        if #self.children == 0 then
            return nil
        end

        local offset = 0
        loop_children(self, function(o)
            o.y = offset
            offset = offset + o.h

            o:adjust_layout(0, o.y, self.w, o.h)
            offset = offset + self.padding
        end)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding"
}, M.H_Box.type)

--[[! Struct: Table
    A table is a grid of elements. It has two properties, columns (specifies
    the number of columns the table will have at max) and again padding (which
    has the same meaning as in boxes). As you append, the children will
    automatically position themselves according to the max number of
    columns.
]]
M.Table = register_class("Table", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.columns = kwargs.columns or 0
        self.padding = kwargs.padding or 0

        return Object.__init(self, kwargs)
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
                row = row + 1
            end
        end)

        local p_w, p_h = 0, 0
        column, row    = 1, 1

        local offset = 0

        loop_children(self, function(o)
            o.x = offset
            o.y = p_h

            local wc, hr = widths[column], heights[row]
            o:adjust_layout(offset, p_h, wc, hr)
            offset = offset + wc

            p_w = max(p_w, offset)
            column = (column % columns) + 1

            if column == 1 then
                offset = 0
                p_h = p_h + hr
                row = row + 1
            end
        end)

        if column ~= 1 then
            p_h = p_h + heights[row]
        end

        self.w = p_w + padding * max(#widths  - 1, 0)
        self.h = p_h + padding * max(#heights - 1, 0)
    end,

    adjust_children = function(self)
        if #self.children == 0 then
            return nil
        end
        
        local widths, heights = self.widths, self.heights
        local columns = self.columns

        local cspace = self.w
        local rspace = self.h

        for i = 1, #widths do
            cspace = cspace - widths[i]
        end
        for i = 1, #heights do
            rspace = rspace - heights[i]
        end

        cspace = cspace / max(#widths  - 1, 1)
        rspace = rspace / max(#heights - 1, 1)

        local column , row     = 1, 1
        local offsetx, offsety = 0, 0

        loop_children(self, function(o)
            o.x = offsetx
            o.y = offsety

            local wc, hr = widths[column], heights[row]
            o.adjust_layout(o, offsetx, offsety, wc, hr)

            offsetx = offsetx + wc + cspace
            column = (column % columns) + 1

            if column == 1 then
                offsetx = 0
                offsety = offsety + hr + rspace
                row = row + 1
            end
        end)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding",

    --[[! Function: set_columns ]]
    set_columns = gen_setter "columns"
})

--[[! Struct: Clipper
    Clips the children inside of it by clip_w and clip_h.
]]
local Clipper = register_class("Clipper", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.clip_w = kwargs.clip_w or 0
        self.clip_h = kwargs.clip_h or 0
        self.virt_w = 0
        self.virt_h = 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        Object.layout(self)
    
        self.virt_w = self.w
        self.virt_h = self.h

        local cw, ch = self.clip_w, self.clip_h

        if cw ~= 0 then self.w = min(self.w, cw) end
        if ch ~= 0 then self.h = min(self.h, ch) end
    end,

    adjust_children = function(self)
        Object.adjust_children(self, 0, 0, self.virt_w, self.virt_h)
    end,

    draw = function(self, sx, sy)
        local cw, ch = self.clip_w, self.clip_h

        if (cw ~= 0 and self.virt_w > cw) or (ch ~= 0 and self.virt_h > ch)
        then
            clip_push(sx, sy, self.w, self.h)
            Object.draw(self, sx, sy)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end,

    --[[! Function: set_clip_w ]]
    set_clip_w = gen_setter "clip_w",

    --[[! Function: set_clip_h ]]
    set_clip_h = gen_setter "clip_h"
})
M.Clipper = Clipper
