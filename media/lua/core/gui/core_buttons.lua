--[[! File: lua/core/gui/core_buttons.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        All kinds of button widgets.
]]

local M = require("core.gui.core")

-- input event management
local is_clicked, is_hovering = M.is_clicked, M.is_hovering
local get_menu = M.get_menu

-- widget types
local register_class = M.register_class

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

-- keys
local key = M.key

local clicked_states = {
    [key.MOUSELEFT   ] = "clicked_left",
    [key.MOUSEMIDDLE ] = "clicked_middle",
    [key.MOUSERIGHT  ] = "clicked_right",
    [key.MOUSEBACK   ] = "clicked_back",
    [key.MOUSEFORWARD] = "clicked_forward"
}

--[[! Struct: Button
    A button has five states, "default", "hovering", "clicked_left",
    "clicked_right" and "clicked_middle". On click it emits the "click" signal
    on itself (which is handled by <Widget>, the button itself doesn't do
    anything).
]]
local Button = register_class("Button", Widget, {
    choose_state = function(self)
        return clicked_states[is_clicked(self)] or
            (is_hovering(self) and "hovering" or "default")
    end,

    --[[! Function: hover
        Buttons can take be hovered on. Assuming self:target(cx, cy) returns
        anything, this returns itself. That means if a child can be targeted,
        the hovered widget will be the button itself.
    ]]
    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    --[[! Function: click
        See <hover>.
    ]]
    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end
})
M.Button = Button

--[[! Struct: Menu_Button
    Like <Button>, but adds a new state, "menu", when a menu is currently
    opened using this button.
]]
M.Menu_Button = register_class("Menu_Button", Button, {
    choose_state = function(self)
        return get_menu(self) != nil and "menu" or Button.choose_state(self)
    end
})

--[[! Struct: Toggle
    Derived from Button. Toggles between two states depending on the
    "condition" property (if the condition returns something that evaluates
    to true, either the "toggled" or "toggled_hovering" state is used,
    otherwise "default" or "default_hovering" is used).
]]
M.Toggle = register_class("Toggle", Button, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.condition = kwargs.condition
        return Button.__ctor(self, kwargs)
    end,

    choose_state = function(self)
        local h = is_hovering(self)
        return (self.condition and self:condition() and
            (h and "toggled_hovering" or "toggled") or
            (h and "default_hovering" or "default"))
    end,

    --[[! Function: set_condition ]]
    set_condition = gen_setter "condition"
})
