--[[! File: lua/core/gui/core_widgets.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Sliders for the OF GUI.
]]

local capi = require("capi")
local cs = require("core.engine.cubescript")
local math2 = require("core.lua.math")
local signal = require("core.events.signal")

local get_millis in capi

local max   = math.max
local min   = math.min
local abs   = math.abs
local clamp = math2.clamp
local round = math2.round
local emit  = signal.emit

local M = require("core.gui.core")
local world = M.get_world()

-- consts
local key = M.key

-- input event management
local is_clicked, is_hovering = M.is_clicked, M.is_hovering

-- widget types
local register_class = M.register_class

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

-- orientation
local orient = M.orient

local Slider_Button

--[[! Struct: Slider
    Implements a base class for either horizontal or vertical slider. Has
    several properties - min_value (the minimal slider value), max_value,
    value (the current one), arrow_size (sliders can arrow-scroll like
    scrollbars), step_size (determines the size of one slider step,
    defaults to 1), step_time (the time to perform a step during
    arrow scroll).

    Changes of "value" performed internally emit the "value_changed" signal
    with the new value as an argument.

    Via kwargs field "var" you can set the engine variable the slider
    will be bound to. It's not a property, and it'll auto-create the
    variable if it doesn't exist. You don't have to bind the slider
    at all though. If you do, the min and max values will be bound
    to the variable.
]]
local Slider = register_class("Slider", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.min_value = kwargs.min_value or 0
        self.max_value = kwargs.max_value or 0
        self.value     = kwargs.value     or 0

        if kwargs.var then
            local varn = kwargs.var
            self.var = varn
            cs.var_new_checked(varn, cs.var_type.int, self.value)
            local mn, mx = cs.var_get_min(varn), cs.var_get_max(varn)
            self.min_value = clamp(self.min_value, mn, mx)
            self.max_value = clamp(self.max_value, mn, mx)
        end

        self.arrow_size = kwargs.arrow_size or 0
        self.step_size  = kwargs.step_size  or 1
        self.step_time  = kwargs.step_time  or 1000

        self.last_step = 0
        self.arrow_dir = 0

        return Widget.__init(self, kwargs)
    end,

    --[[! Function: do_step
        Jumps by n steps on the slider.
    ]]
    do_step = function(self, n)
        local mn, mx, ss = self.min_value, self.max_value, self.step_size

        local maxstep = abs(mx - mn) / ss
        local curstep = (self.value - min(mn, mx)) / ss
        local newstep = clamp(curstep + n, 0, maxstep)

        local val = min(mx, mn) + newstep * ss
        self.value = val
        emit(self, "value_changed", val)

        local varn = self.var
        if varn then M.update_var(varn, val) end
    end,

    --[[! Function: set_step
        Sets the nth step.
    ]]
    set_step = function(self, n)
        local mn, mx, ss = self.min_value, self.max_value, self.step_size

        local steps   = abs(mx - mn) / ss
        local newstep = clamp(n, 0, steps)

        local val = min(mx, mn) + newstep * ss
        self.value = val
        emit(self, "value_changed", val)

        local varn = self.var
        if varn then M.update_var(varn, val) end
    end,

    --[[! Function: key_hover
        You can change the slider value using the up, left keys (goes back
        by one step), down, right keys (goes forward by one step) and mouse
        scroll (goes forward/back by 3 steps).
    ]]
    key_hover = function(self, code, isdown)
        if code == key.UP or code == key.LEFT then
            if isdown then self:do_step(-1) end
            return true
        elseif code == key.MOUSE4 then
            if isdown then self:do_step(-3) end
            return true
        elseif code == key.DOWN or code == key.RIGHT then
            if isdown then self:do_step(1) end
            return true
        elseif code == key.MOUSE5 then
            if isdown then self:do_step(3) end
            return true
        end

        return Widget.key_hover(self, code, isdown)
    end,

    choose_direction = function(self, cx, cy)
        return 0
    end,

    --[[! Function: hover
        The slider can be hovered on unless some of its children want the
        hover instead.
    ]]
    hover = function(self, cx, cy)
        return Widget.hover(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    --[[! Function: hover
        The slider can be clicked on unless some of its children want the
        click instead.
    ]]
    click = function(self, cx, cy)
        return Widget.click(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    scroll_to = function(self, cx, cy) end,

    --[[! Function: clicked
        Clicking inside the slider area but outside the arrow area jumps
        in the slider.
    ]]
    clicked = function(self, cx, cy)
        local ad = self.choose_direction(self, cx, cy)
        self.arrow_dir = ad

        if ad == 0 then
            self:scroll_to(cx, cy)
        else
            self:hovering(cx, cy)
        end

        return Widget.clicked(self, cx, cy)
    end,

    arrow_scroll = function(self)
        local tmillis = get_millis(true)
        if (self.last_step + self.step_time) > tmillis then
            return nil
        end

        self.last_step = tmillis
        self.do_step(self, self.arrow_dir)
    end,

    --[[! Function: hovering
        When the arrow area is pressed, the slider will keep going
        in the appropriate direction. Also controls the slider button.
    ]]
    hovering = function(self, cx, cy)
        if is_clicked(self) then
            if self.arrow_dir != 0 then
                self:arrow_scroll()
            end
        else
            local button = self:find_child(Slider_Button.type, nil, false)

            if button and is_clicked(button) then
                self.arrow_dir = 0
                button.hovering(button, cx - button.x, cy - button.y)
            else
                self.arrow_dir = self:choose_direction(cx, cy)
            end
        end
    end,

    move_button = function(self, o, fromx, fromy, tox, toy) end,

    --[[! Function: set_min_value ]]
    set_min_value = gen_setter "min_value",

    --[[! Function: set_max_value ]]
    set_max_value = gen_setter "max_value",

    --[[! Function: set_value ]]
    set_value = gen_setter "value",

    --[[! Function: set_step_size ]]
    set_step_size = gen_setter "step_size",

    --[[! Function: set_step_time ]]
    set_step_time = gen_setter "step_time"
})
M.Slider = Slider

--[[! Struct: Slider_Button
    A slider button you can put inside a slider and drag. The slider
    will adjust the button width (in case of horizontal slider) and height
    (in case of vertical slider) depending on the slider size and values.

    A slider button has three states, "default", "hovering" and "clicked".
]]
Slider_Button = register_class("Slider_Button", Widget, {
    __init = function(self, kwargs)
        self.offset_h = 0
        self.offset_v = 0

        return Widget.__init(self, kwargs)
    end,

    choose_state = function(self)
        return is_clicked(self) and "clicked" or
            (is_hovering(self) and "hovering" or "default")
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    hovering = function(self, cx, cy)
        local p = self.parent

        if is_clicked(self) and p and p.type == Slider.type then
            p:move_button(self, self.offset_h, self.offset_v, cx, cy)
        end
    end,

    clicked = function(self, cx, cy)
        self.offset_h = cx
        self.offset_v = cy

        return Widget.clicked(self, cx, cy)
    end,

    layout = function(self)
        local lastw = self.w
        local lasth = self.h

        Widget.layout(self)

        if is_clicked(self) then
            self.w = lastw
            self.h = lasth
        end
    end
})
M.Slider_Button = Slider_Button

--[[! Struct: H_Slider
    A specialization of <Slider>. Has the "orient" member set to
    the HORIZONTAL field of <orient>. Overloads some of the Slider
    methods specifically for horizontal direction.

    Has five states - "default", "(left|right)_hovering",
    "(left|right)_clicked".
]]
M.H_Slider = register_class("H_Slider", Slider, {
    orient = orient.HORIZONTAL,

    choose_state = function(self)
        local ad = self.arrow_dir

        if ad == -1 then
            return is_clicked(self) and "left_clicked" or
                (is_hovering(self) and "left_hovering" or "default")
        elseif ad == 1 then
            return is_clicked(self) and "right_clicked" or
                (is_hovering(self) and "right_hovering" or "default")
        end
        return "default"
    end,

    choose_direction = function(self, cx, cy)
        local as = self.arrow_size
        return cx < as and -1 or (cx >= (self.w - as) and 1 or 0)
    end,

    scroll_to = function(self, cx, cy)
        local  btn = self:find_child(Slider_Button.type, nil, false)
        if not btn then return nil end

        local as = self.arrow_size

        local sw, bw = self.w, btn.w

        self.set_step(self, round((abs(self.max_value - self.min_value) /
            self.step_size) * clamp((cx - as - bw / 2) /
                (sw - 2 * as - bw), 0.1, 1)))
    end,

    adjust_children = function(self)
        local  btn = self:find_child(Slider_Button.type, nil, false)
        if not btn then return nil end

        local mn, mx, ss = self.min_value, self.max_value, self.step_size

        local steps   = abs(mx - mn) / self.step_size
        local curstep = (self.value - min(mx, mn)) / ss

        local as = self.arrow_size

        local width = max(self.w - 2 * as, 0)

        btn.w = max(btn.w, width / steps)
        btn.x = as + (width - btn.w) * curstep / steps
        btn.adjust = btn.adjust & ~ALIGN_HMASK

        Widget.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.x + o.w / 2 + tox - fromx, o.y + toy)
    end
}, Slider.type)

--[[! Struct: V_Slider
    See <H_Slider> above. Has different states, "default", "(up|down)_hovering"
    and "(up|down)_clicked".
]]
M.V_Slider = register_class("V_Slider", Slider, {
    choose_state = function(self)
        local ad = self.arrow_dir

        if ad == -1 then
            return is_clicked(self) and "up_clicked" or
                (is_hovering(self) and "up_hovering" or "default")
        elseif ad == 1 then
            return is_clicked(self) and "down_clicked" or
                (is_hovering(self) and "down_hovering" or "default")
        end
        return "default"
    end,

    choose_direction = function(self, cx, cy)
        local as = self.arrow_size
        return cy < as and -1 or (cy >= (self.h - as) and 1 or 0)
    end,

    scroll_to = function(self, cx, cy)
        local  btn = self:find_child(Slider_Button.type, nil, false)
        if not btn then return nil end

        local as = self.arrow_size

        local sh, bh = self.h, btn.h
        local mn, mx = self.min_value, self.max_value

        self.set_step(self, round(((max(mx, mn) - min(mx, mn)) /
            self.step_size) * clamp((cy - as - bh / 2) /
                (sh - 2 * as - bh), 0.1, 1)))
    end,

    adjust_children = function(self)
        local  btn = self:find_child(Slider_Button.type, nil, false)
        if not btn then return nil end

        local mn, mx, ss = self.min_value, self.max_value, self.step_size

        local steps   = (max(mx, mn) - min(mx, mn)) / ss + 1
        local curstep = (self.value - min(mx, mn)) / ss

        local as = self.arrow_size

        local height = max(self.h - 2 * as, 0)

        btn.h = max(btn.h, height / steps)
        btn.y = as + (height - btn.h) * curstep / steps
        btn.adjust = btn.adjust & ~ALIGN_VMASK

        Widget.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self.scroll_to(self, o.x + o.h / 2 + tox, o.y + toy - fromy)
    end
}, Slider.type)
