--[[! File: lua/core/gui/core_misc.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Misc widgets.
]]

local table2 = require("core.lua.table")

local find = table2.find

local M = require("core.gui.core")
local world = M.get_world()

-- input event management
local is_clicked, clear_focus = M.is_clicked, M.clear_focus

-- widget types
local register_class = M.register_class

-- base widgets
local Object = M.get_class("Object")

-- setters
local gen_setter = M.gen_setter

--[[! Struct: Conditional
    Conditional has two states, "true" and "false". It has a property,
    "condition", which is a function. If that function exists and returns
    a value that can be evaluated as true, the "true" state is set, otherwise
    the "false" state is set.
]]
M.Conditional = register_class("Conditional", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.condition = kwargs.condition
        return Object.__init(self, kwargs)
    end,

    choose_state = function(self)
        return (self.condition and self:p_condition()) and "true" or "false"
    end,

    --[[! Function: set_condition ]]
    set_condition = gen_setter "condition"
})

--[[! Struct: Mover
    An object using which you can move windows. The window must have the
    floating property set to true or it won't move. It doesn't have any
    appearance or states, those are defined by its children.

    If you have multiple movable windows, the mover will take care of
    moving the current window to the top. That means you don't have to care
    about re-stacking them.
]]
M.Mover = register_class("Mover", Object, {
    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        local  w = self:get_window()
        if not w then
            return self:target(cx, cy) and self
        end
        local c = w.parent.children
        local n = find(c, w)
        local l = #c
        if n != l then c[l], c[n] = w, c[l] end
        return self:target(cx, cy) and self
    end,

    can_move = function(self, cx, cy)
        local wp = self.window.parent

        -- no parent means world; we don't need checking for non-mdi windows
        if not wp.parent then
            return true
        end

        local rx, ry, p = self.x, self.y, wp
        while p do
            rx = rx + p.x
            ry = ry + p.y
            local  pp = p.parent
            if not pp then break end
            p    = pp
        end

        -- world has no parents :( but here we can re-use it
        local w = p.w
        -- transform x position of the cursor (which ranges from 0 to 1)
        -- into proper UI positions (that are dependent on screen width)
        --local cx = cursor_x * w - (w - 1) / 2
        --local cy = cursor_y

        if cx < rx or cy < ry or cx > (rx + wp.w) or cy > (ry + wp.h) then
            -- avoid bugs; stop moving when cursor is outside
            clear_focus(self)
            return false
        end

        return true
    end,

    pressing = function(self, cx, cy)
        local  w = self:get_window()
        if not w then
            return Object.pressing(self, cx, cy)
        end
        if w and w.floating and is_clicked(self) and self:can_move() then
            w.fx, w.x = w.fx + cx, w.x + cx
            w.fy, w.y = w.fy + cy, w.y + cy
        end
    end
})
