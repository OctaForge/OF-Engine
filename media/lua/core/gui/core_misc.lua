--[[!<
    Misc widgets.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local table2 = require("core.lua.table")

local find = table2.find
local tremove = table.remove
local type = type
local min, max = math.min, math.max

--! Module: core
local M = require("core.gui.core")
local world = M.get_world()

-- input event management
local is_clicked, clear_focus = M.is_clicked, M.clear_focus

-- widget types
local register_class = M.register_class

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

-- projection
local get_projection = M.get_projection

-- adjustment
local adjust = M.adjust

-- keys
local key = M.key

local ALIGN_MASK = adjust.ALIGN_MASK

--[[!
    Represents a state as a first class object. Has an arbitrary number of
    states.

    Properties:
        - state - the current state of the widget, can be either a string or
          a callable value that returns the state when called with self as
          an argument.
]]
M.State = register_class("State", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.state = kwargs.state
        return Widget.__ctor(self, kwargs)
    end,

    choose_state = function(self)
        local  state = self.state
        if not state then return end
        return (type(state) == "string") and state or state(self)
    end,

    --! Function: set_state
    set_state = gen_setter "state"
})

--[[!
    A widget using which you can move windows. The window must have the
    floating property set to true or it won't move. It doesn't have any
    appearance or states, those are defined by its children.

    If you have multiple movable windows, the mover will take care of
    moving the current window to the top. That means you don't have to care
    about re-stacking them.

    Properties:
        - window - a reference to the window this belongs to.
]]
M.Mover = register_class("Mover", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.window = kwargs.window
        return Widget.__ctor(self, kwargs)
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy, code)
        if code != key.MOUSELEFT then
            return Widget.click(self, cx, cy, code)
        end
        local  w = self.window
        if not w then return self:target(cx, cy) and self end
        local c = w.parent.children
        local n = find(c, w)
        local l = #c
        if n != l then c[l] = tremove(c, n) end
        return self:target(cx, cy) and self
    end,

    can_move = function(self, cx, cy)
        local win = self.window
        local wp = win.parent

        -- no parent means world; we don't need checking for non-mdi windows
        if not wp.parent then return true end

        local rx, ry, p = self.x, self.y, wp
        while true do
            rx, ry = rx + p.x, ry + py
            local  pp = p.parent
            if not pp then break end
            p    = pp
        end

        if cx < rx or cy < ry or cx > (rx + wp.w) or cy > (ry + wp.h) then
            -- avoid bugs; stop moving when cursor is outside
            clear_focus(self)
            return false
        end

        return true
    end,

    clicked = function(self, cx, cy, code)
        if code == key.MOUSELEFT then
            self.ox, self.oy = cx, cy
        end
    end,

    holding = function(self, cx, cy, code)
        local w = self.window
        if w and w.floating and code == key.MOUSELEFT and self:can_move() then
            -- dealign so that adjust_layout doesn't fuck with x/y
            w.adjust &= ~ALIGN_MASK
            w.x += cx - self.ox
            w.y += cy - self.oy
        end
        Widget.holding(self, cx, cy, code)
    end,

    --! Function: set_window
    set_window = gen_setter "window"
})

local Filler = M.Filler

--[[!
    A base widget class for progress bars. Not useful alone. For working
    variants, see $H_Progress_Bar and $V_Progress_Bar.

    Properties:
        - value - the current value, from 0.0 to 1.0. If set out of bounds,
          it will get clamped to nearest valid value (0.0 or 1.0).
        - bar - a widget representing the actual "bar" of the progress bar
          (aka the child that will take value * width or value * height of
          the progress bar).
        - label - either a format string or a callable value. When a format
          string, it represents the format of the label on the progress bar
          (by default it's `%d%%`, which will result in e.g. `75%`, the value
          is multiplied by 100 before formatting), when it's a callable value
          it'll be called with `self` and the value (not multiplied) as
          arguments, expecting the label string as a return value.
]]
M.Progress_Bar = register_class("Progress_Bar", Filler, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.value = kwargs.value or 0
        self.bar = kwargs.bar
        self.label = kwargs.label or "%d%%"
        return Filler.__ctor(self, kwargs)
    end,

    --[[!
        Generates a label for the progress bar and returns it. See the `label`
        attribute for semantics.
    ]]
    gen_label = function(self)
        local lbl = self.label
        if type(lbl) == "string" then return lbl:format(self.value * 100) end
        return lbl(self, self.value)
    end,

    --! Function: set_value
    set_value = gen_setter "value",
    --! Function: set_bar
    set_bar = gen_setter "bar",
    --! Function: set_label
    set_label = gen_setter "label"
})

--! A horizontal working variant of $Progress_Bar.
M.H_Progress_Bar = register_class("H_Progress_Bar", M.Progress_Bar, {
    adjust_children = function(self)
        local bar = self.bar
        if not bar then return Widget.adjust_children(self) end
        bar.x = 0
        bar.w = max(min(self.w, self.w * self.value), 0)
        bar.adjust &= ~adjust.ALIGN_HMASK
        Widget.adjust_children(self)
    end
})

--! A vertical working variant of $Progress_Bar.
M.V_Progress_Bar = register_class("V_Progress_Bar", M.Progress_Bar, {
    adjust_children = function(self)
        local bar = self.bar
        if not bar then return Widget.adjust_children(self) end
        bar.y = 0
        bar.h = max(min(self.h, self.h * self.value), 0)
        bar.adjust &= ~adjust.ALIGN_VMASK
        Widget.adjust_children(self)
    end
})
