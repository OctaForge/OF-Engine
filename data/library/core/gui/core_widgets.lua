--[[! File: library/core/gui/core_widgets.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        A basic widget set for the GUI. Doesn't include the very core of the
        whole system (Object, Named_Object, Tag, Window, Overlay, World).
        Forwards Tag, Window, Overlay, Space.

        This doesn't document every single overloaded method on every object.
        Only the ones with a special meaning are documented. There is no reason
        for everything to be documented as it has no actual use.
]]

local ffi = require("ffi")

local band  = math.band
local bnot  = math.bnot
local blsh  = math.lsh
local max   = math.max
local min   = math.min
local clamp = math.clamp
local floor = math.floor
local round = math.round
local _V    = _G["_V"]
local _C    = _G["_C"]
local emit  = signal.emit

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

-- editor support
local get_textediting, set_textediting
    = M.get_textediting, M.set_textediting

--[[! Variable: orient
    Defines the possible orientations on widgets - HORIZONTAL and VERTICAL.
]]
local orient = {
    HORIZONTAL = 0, VERTICAL = 1
}
M.orient = orient

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

--[[! Struct: Button
    A button has three states, "default", "hovering" and "clicked". On click
    it emits the "click" signal on itself (which is handled by <Object>, the
    button itself doesn't do anything).
]]
local Button = register_class("Button", Object, {
    choose_state = function(self)
        return is_clicked(self) and "clicked" or
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

--[[! Struct: Conditional_Button
    Derived from Button. It's similar, but provides more states - more
    specifically "false", "true", "hovering", "clicked". There is the
    "condition" property which works identically as in <Conditional>.
    If the condition is not met, the "false" state is used, otherwise
    one of the other three is used as in <Button>.
]]
M.Conditional_Button = register_class("Conditional_Button", Button, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.condition = kwargs.condition
        return Button.__init(self, kwargs)
    end,

    choose_state = function(self)
        return ((self.condition and self:p_condition()) and
            (is_clicked(self) and "clicked" or
                (is_hovering(self) and "hovering" or "true")) or "false")
    end,

    --[[! Function: clicked
        Makes sure the signal is sent only if the condition is met.
    ]]
    clicked = function(self, cx, cy)
        if self.condition and self:p_condition() then
            Object.clicked(self, cx, cy)
        end
    end,

    --[[! Function: set_condition ]]
    set_condition = gen_setter "condition"
})

--[[! Struct: Toggle
    Derived from Button. Toggles between two states depending on the
    "condition" property (if the condition returns something that evaluates
    to true, either the "toggled" or "toggled_hovering" state is used,
    otherwise "default" or "default_hovering" is used).
]]
M.Toggle = register_class("Toggle", Button, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.condition = kwargs.condition
        return Button.__init(self, kwargs)
    end,

    choose_state = function(self)
        local h = is_hovering(self)
        return (self.condition and self:p_condition() and
            (h and "toggled_hovering" or "toggled") or
            (h and "default_hovering" or "default"))
    end,

    --[[! Function: set_condition ]]
    set_condition = gen_setter "condition"
})

local Clipper = M.Clipper

--[[! Struct: Scroller
    Derived from Clipper. Provides a scrollable area without scrollbars.
    Scrollbars are separate widgets and are siblings of scrollers.
]]
M.Scroller = register_class("Scroller", Clipper, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.offset_h = 0
        self.offset_v = 0
        self.can_scroll = 0

        return Clipper.__init(self, kwargs)
    end,

    --[[! Function: clear
        In addition to the regular clear it takes care of unlinking
        the scrollbars.
    ]]
    clear = function(self)
        self:bind_h_scrollbar()
        self:bind_v_scrollbar()
        return Clipper.clear(self)
    end,

    layout = function(self)
        Clipper.layout(self)
        self.offset_h = min(self.offset_h, self:get_h_limit())
        self.offset_v = min(self.offset_v, self:get_v_limit())
    end,

    target = function(self, cx, cy)
        local oh, ov, vw, vh = self.offset_h, self.offset_v,
            self.virt_w, self.virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then return nil end
        return Object.target(self, cx + oh, cy + ov)
    end,

    hover = function(self, cx, cy)
        local oh, ov, vw, vh = self.offset_h, self.offset_v,
            self.virt_w, self.virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then
            self.can_scroll = false
            return nil
        end

        self.can_scroll = true
        return Object.hover(self, cx + oh, cy + ov) or self
    end,

    click = function(self, cx, cy)
        local oh, ov, vw, vh = self.offset_h, self.offset_v,
            self.virt_w, self.virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then return nil end
        return Object.click(self, cx + oh, cy + ov)
    end,

    --[[! Function: key_hover
        A mouse scroll wheel handler. It scrolls in the direction of its
        scrollbar. If both are present, vertical takes precedence. If none
        is present, scrolling won't work.
    ]]
    key_hover = function(self, code, isdown)
        local m4, m5 = key.MOUSE4, key.MOUSE5
        if code ~= m4 or code ~= m5 then
            return Object.key_hover(self, code, isdown)
        end

        local  sb = self.v_scrollbar or self.h_scrollbar
        if not sb or not self.can_scroll then return false end
        if not isdown then return true end

        local adjust = (code == m4 and -0.2 or 0.2) * sb.arrow_speed
        if self.v_scrollbar then
            self:scroll_v(adjust)
        else
            self:scroll_h(adjust)
        end

        return true
    end,

    draw = function(self, sx, sy)
        if (self.clip_w ~= 0 and self.virt_w > self.clip_w) or
           (self.clip_h ~= 0 and self.virt_h > self.clip_h)
        then
            clip_push(sx, sy, self.w, self.h)
            Object.draw(self, sx - self.offset_h, sy - self.offset_v)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end,

    --[[! Function: bind_h_scrollbar
        Binds a horizontal scrollbar object to the scroller. It sets up both
        sides appropriately. You can do this from the scrollbar side as well.
        Calling with nil unlinks the scrollbar and returns it.
    ]]
    bind_h_scrollbar = function(self, sb)
        if not sb then
            sb = self.h_scrollbar
            if not sb then return nil end
            sb.scroller, self.h_scrollbar = nil, nil
            return sb
        end
        self.h_scrollbar = sb
        sb.scroller = self
    end,

    --[[! Function: bind_v_scrollbar
        Binds a vertical scrollbar object to the scroller. It sets up both
        sides appropriately. You can do this from the scrollbar side as well.
        Calling with nil unlinks the scrollbar and returns it.
    ]]
    bind_v_scrollbar = function(self, sb)
        if not sb then
            sb = self.v_scrollbar
            if not sb then return nil end
            sb.scroller, self.v_scrollbar = nil, nil
            return sb
        end
        self.v_scrollbar = sb
        sb.scroller = self
    end,

    --[[! Function: get_h_limit
        Returns the horizontal offset limit, that is, the actual width of
        the contents minus the clipper width.
    ]]
    get_h_limit = function(self)
        return max(self.virt_w - self.w, 0)
    end,

    --[[! Function: get_v_limit
        See above.
    ]]
    get_v_limit = function(self)
        return max(self.virt_h - self.h, 0)
    end,

    --[[! Function: get_h_offset
        Returns the horizontal offset, that is, the portion of the actual
        size of the contents the scroller offsets by. It's computed as
        actual_offset / max(size_of_container, size_of_contents).
    ]]
    get_h_offset = function(self)
        return self.offset_h / max(self.virt_w, self.w)
    end,

    --[[! Function: get_v_offset
        See above.
    ]]
    get_v_offset = function(self)
        return self.offset_v / max(self.virt_h, self.h)
    end,

    --[[! Function: get_h_scale
        Returns the horizontal scale, that is,
        size_of_container / max(size_of_container, size_of_contents).
    ]]
    get_h_scale = function(self)
        return self.w / max(self.virt_w, self.w)
    end,

    --[[! Function: get_v_scale
        See above.
    ]]
    get_v_scale = function(self)
        return self.h / max(self.virt_h, self.h)
    end,

    --[[! Function: set_h_scroll
        Sets the horizontal scroll offset. Takes the "real" offset, that is,
        actual_offset as <get_h_offset> describes it (offset 1 would be the
        full screen height). Emits the h_scroll_changed signal on self with
        self:get_h_offset() as a parameter.
    ]]
    set_h_scroll = function(self, hs)
        self.offset_h = clamp(hs, 0, self:get_h_limit())
        emit(self, "h_scroll_changed", self:get_h_offset())
    end,

    --[[! Function: set_v_scroll
        See above.
    ]]
    set_v_scroll = function(self, vs)
        self.offset_v = clamp(vs, 0, self:get_v_limit())
        emit(self, "v_scroll_changed", self:get_v_offset())
    end,

    --[[! Function: scroll_h
        Like <set_h_scroll>, but works with deltas (adds the given value
        to the actual offset).
    ]]
    scroll_h = function(self, hs)
        self:set_h_scroll(self.offset_h + hs)
    end,

    --[[! Function: scroll_v
        See above.
    ]]
    scroll_v = function(self, vs)
        self:set_v_scroll(self.offset_v + vs)
    end
})

local Scroll_Button

--[[! Struct: Scrollbar
    A base scrollbar widget class. This one is not of much use. Has two
    properties, arrow_size (determines the length of the arrow part of
    the scrollbar) and arrow_speed (mouse scroll is by 0.2 * arrow_speed,
    arrow scroll is by frame_time * arrow_speed), both of which default to 0.
]]
local Scrollbar = register_class("Scrollbar", Object, {
    orient = -1,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.arrow_size  = kwargs.arrow_size  or 0
        self.arrow_speed = kwargs.arrow_speed or 0
        self.arrow_dir   = 0

        return Object.__init(self, kwargs)
    end,

    --[[! Function: clear
        In addition to the regular clear it takes care of unlinking
        the scroller.
    ]]
    clear = function(self)
        self:bind_scroller()
        return Object.clear(self)
    end,

    --[[! Function: bind_scroller
        This one does nothing, it's further overloaded in horizontal and
        vertical variants. It takes care of linking a scroller to itself
        as well as linking this scrollbar to the scroller. Calling with
        nil unlinks the scroller and returns it.
    ]]
    bind_scroller = function(self, sc) end,

    choose_direction = function(self, cx, cy)
        return 0
    end,

    --[[! Function: hover
        Scrollbars can be hovered on.
    ]]
    hover = function(self, cx, cy)
        return Object.hover(self, cx, cy) or self
    end,

    --[[! Function: hover
        Scrollbars can be clicked on assuming none of the children want
        to be clicked on.
    ]]
    click = function(self, cx, cy)
        return Object.click(self, cx, cy) or
                     (self:target(cx, cy) and self or nil)
    end,

    scroll_to = function(self, cx, cy) end,

    --[[! Function: key_hover
        Mouse scrolling on a scrollbar results in the scroller being scrolled
        by 0.2 in the right direction depending on the scrollbar type.
    ]]
    key_hover = function(self, code, isdown)
        local m4, m5 = key.MOUSE4, key.MOUSE5
        if code ~= m4 or code ~= m5 then
            return Object.key_hover(self, code, isdown)
        end

        local  sc = self.scroller
        if not sc or not sc.can_scroll then return false end
        if not isdown then return true end

        local adjust = (code == m4 and -0.2 or 0.2) * self.arrow_speed
        if self.orient == 1 then
            sc:scroll_v(adjust)
        else
            sc:scroll_h(adjust)
        end

        return true
    end,

    --[[! Function: clicked
        Clicking inside the scrollbar area but outside the arrow area jumps
        in the scroller.
    ]]
    clicked = function(self, cx, cy)
        local id = self:choose_direction(cx, cy)
        self.arrow_dir = id

        if id == 0 then
            self:scroll_to(cx, cy)
        else
            self:hovering(cx, cy)
        end

        return Object.clicked(self, cx, cy)
    end,

    arrow_scroll = function(self) end,

    --[[! Function: hovering
        When the arrow area is pressed, the scroller will keep scrolling
        in the appropriate direction. Also controls the scroll button.
    ]]
    hovering = function(self, cx, cy)
        if is_clicked(self) then
            if self.arrow_dir ~= 0 then
                self:arrow_scroll()
            end
        else
            local button = self:find_child(Scroll_Button.type, nil, false)
            if button and is_clicked(button) then
                self.arrow_dir = 0
                button:hovering(cx - button.x, cy - button.y)
            else
                self.arrow_dir = self:choose_direction(cx, cy)
            end
        end
    end,

    move_button = function(self, o, fromx, fromy, tox, toy) end,

    --[[! Function: set_arrow_size ]]
    set_arrow_size = gen_setter "arrow_size",

    --[[! Function: set_arrow_speed ]]
    set_arrow_speed = gen_setter "arrow_speed"
})
M.Scrollbar = Scrollbar

--[[! Struct: Scroll_Button
    A scroll button you can put inside a scrollbar and drag. The scrollbar
    will adjust the button width (in case of horizontal scrollbar) and height
    (in case of vertical scrollbar) depending on the scroller contents.

    A scroll button has three states, "default", "hovering" and "clicked".
]]
Scroll_Button = register_class("Scroll_Button", Object, {
    __init = function(self, kwargs)
        self.offset_h = 0
        self.offset_v = 0

        return Object.__init(self, kwargs)
    end,

    choose_state = function(self)
        return is_clicked(self) and "clicked" or
            (is_hovering(self) and "hovering" or "default")
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self or nil
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self or nil
    end,

    hovering = function(self, cx, cy)
        local p = self.parent
        if is_clicked(self) and p and p.type == Scrollbar.type then
            p:move_button(self, self.offset_h, self.offset_v, cx, cy)
        end
    end,

    clicked = function(self, cx, cy)
        self.offset_h = cx
        self.offset_v = cy

        return Object.clicked(self, cx, cy)
    end
})
M.Scroll_Button = Scroll_Button

local ALIGN_HMASK = 0x3
local ALIGN_VMASK = 0xC

--[[! Struct: H_Scrollbar
    A specialization of <Scrollbar>. Has the "orient" member set to
    the HORIZONTAL field of <orient>. Overloads some of the Scrollbar
    methods specifically for horizontal scrolling.

    Has five states - "default", "(left|right)_hovering",
    "(left|right)_clicked".
]]
M.H_Scrollbar = register_class("H_Scrollbar", Scrollbar, {
    orient = orient.HORIZONTAL,

    bind_scroller = function(self, sc)
        if not sc then
            sc = self.scroller
            if not sc then return nil end
            sc.h_scrollbar = nil
            return sc
        end
        self.scroller = sc
        sc.h_scrollbar = self
    end,

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
        return (cx < as) and -1 or (cx >= (self.w - as) and 1 or 0)
    end,

    arrow_scroll = function(self)
        local  scroll = self.scroller
        if not scroll then return nil end

        scroll:scroll_h(self.arrow_dir * self.arrow_speed *
            frame.get_frame_time())
    end,

    scroll_to = function(self, cx, cy)
        local  scroll = self.scroller
        if not scroll then return nil end

        local  btn = self:find_child(Scroll_Button.type, nil, false)
        if not btn then return nil end

        local as = self.arrow_size

        local bscale = (max(self.w - 2 * as, 0) - btn.w) /
            (1 - scroll:get_h_scale())

        local offset = (bscale > 0.001) and (cx - as) / bscale or 0

        scroll.set_h_scroll(scroll, offset * scroll.virt_w)
    end,

    adjust_children = function(self)
        local  scroll = self.scroller
        if not scroll then return nil end

        local  btn = self:find_child(Scroll_Button.type, nil, false)
        if not btn then return nil end

        local as = self.arrow_size

        local sw, btnw = self.w, btn.w

        local bw = max(sw - 2 * as, 0) * scroll:get_h_scale()
        btn.w  = max(btnw, bw)

        local bscale = (scroll:get_h_scale() < 1) and
            (max(sw - 2 * as, 0) - btn.w) / (1 - scroll:get_h_scale()) or 1

        btn.x = as + scroll:get_h_offset() * bscale
        btn.adjust = band(btn.adjust, bnot(ALIGN_HMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.x + tox - fromx, o.y + toy)
    end
}, Scrollbar.type)

--[[! Struct: V_Scrollbar
    See <H_Scrollbar> above. Has different states, "default",
    "(up|down)_hovering" and "(up|down)_clicked".
]]
M.V_Scrollbar = register_class("V_Scrollbar", Scrollbar, {
    orient = orient.VERTICAL,

    bind_scroller = function(self, sc)
        if not sc then
            sc = self.scroller
            if not sc then return nil end
            sc.v_scrollbar = nil
            return sc
        end
        self.scroller = sc
        sc.v_scrollbar = self
    end,

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
        return (cy < as) and -1 or (cy >= (self.h - as) and 1 or 0)
    end,

    arrow_scroll = function(self)
        local  scroll = self.scroller
        if not scroll then return nil end

        scroll:scroll_v(self.arrow_dir * self.arrow_speed *
            frame.get_frame_time())
    end,

    scroll_to = function(self, cx, cy)
        local  scroll = self.scroller
        if not scroll then return nil end

        local  btn = self:find_child(Scroll_Button.type, nil, false)
        if not btn then return nil end

        local as = self.arrow_size

        local bscale = (max(self.h - 2 * as, 0) - btn.h) /
            (1 - scroll:get_v_scale())

        local offset = (bscale > 0.001) and
            (cy - as) / bscale or 0

        scroll:set_v_scroll(offset * scroll.virt_h)
    end,

    adjust_children = function(self)
        local  scroll = self.scroller
        if not scroll then return nil end

        local  btn = self:find_child(Scroll_Button.type, nil, false)
        if not btn then return nil end

        local as = self.arrow_size

        local sh, btnh = self.h, btn.h

        local bh = max(sh - 2 * as, 0) * scroll:get_v_scale()

        btn.h = max(btnh, bh)

        local bscale = (scroll:get_v_scale() < 1) and
            (max(sh - 2 * as, 0) - btn.h) / (1 - scroll:get_v_scale()) or 1

        btn.y = as + scroll:get_v_offset() * bscale
        btn.adjust = band(btn.adjust, bnot(ALIGN_VMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.x + tox, o.y + toy - fromy)
    end
}, Scrollbar.type)

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
local Slider = register_class("Slider", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.min_value = kwargs.min_value or 0
        self.max_value = kwargs.max_value or 0
        self.value     = kwargs.value     or 0

        if kwargs.var then
            local varn = kwargs.var
            self.var = varn

            if not var.exists(varn) then
                var.new(varn, var.INT, self.value)
            end
            local mn, mx = var.get_min(varn), var.get_max(varn)
            self.min_value = clamp(self.min_value, mn, mx)
            self.max_value = clamp(self.max_value, mn, mx)
        end

        self.arrow_size = kwargs.arrow_size or 0
        self.step_size  = kwargs.step_size  or 1
        self.step_time  = kwargs.step_time  or 1000

        self.last_step = 0
        self.arrow_dir = 0

        return Object.__init(self, kwargs)
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

        return Object.key_hover(self, code, isdown)
    end,

    choose_direction = function(self, cx, cy)
        return 0
    end,

    --[[! Function: hover
        The slider can be hovered on unless some of its children want the
        hover instead.
    ]]
    hover = function(self, cx, cy)
        return Object.hover(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    --[[! Function: hover
        The slider can be clicked on unless some of its children want the
        click instead.
    ]]
    click = function(self, cx, cy)
        return Object.click(self, cx, cy) or
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

        return Object.clicked(self, cx, cy)
    end,

    arrow_scroll = function(self)
        local tmillis = _C.get_millis(true)
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
            if self.arrow_dir ~= 0 then
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
Slider_Button = register_class("Slider_Button", Object, {
    __init = function(self, kwargs)
        self.offset_h = 0
        self.offset_v = 0

        return Object.__init(self, kwargs)
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

        return Object.clicked(self, cx, cy)
    end,

    layout = function(self)
        local lastw = self.w
        local lasth = self.h

        Object.layout(self)

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
        btn.adjust = band(btn.adjust, bnot(ALIGN_HMASK))

        Object.adjust_children(self)
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
        btn.adjust = band(btn.adjust, bnot(ALIGN_VMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self.scroll_to(self, o.x + o.h / 2 + tox, o.y + toy - fromy)
    end
}, Slider.type)

local Filler = M.Filler

local check_alpha_mask = function(tex, x, y)
    if not tex:get_alphamask() then
        _C.texture_load_alpha_mask(tex)
        if not tex:get_alphamask() then
            return true
        end
    end

    local xs, ys = tex:get_xs(), tex:get_ys()
    local tx, ty = clamp(floor(x * xs), 0, xs - 1),
                   clamp(floor(y * ys), 0, ys - 1)

    local m = tex:get_alphamask(ty * ((xs + 7) / 8))
    if band(m, blsh(1, tx % 8)) ~= 0 then
        return true
    end

    return false
end

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
        local n = table.find(c, w)
        local l = #c
        if n ~= l then c[l], c[n] = w, c[l] end
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

--[[! Struct: Text_Editor
    Implements a text editor widget. It's a basic editor that supports
    scrolling of text and some extra features like key filter, password
    and so on. It supports copy-paste that interacts with native system
    clipboard. It doesn't have any states.
]]
local Text_Editor = register_class("Text_Editor", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        local length = kwargs.length or 0
        local height = kwargs.height or 1
        local scale  = kwargs.scale  or 1

        self.keyfilter  = kwargs.key_filter
        self.init_value = kwargs.value
        self.scale = kwargs.scale or 1

        self.offset_h, self.offset_v = 0, 0
        self.filename = nil

        -- cursor position - ensured to be valid after a region() or
        -- currentline()
        self.cx, self.cy = 0, 0
        -- selection mark, mx = -1 if following cursor - avoid direct access,
        -- instead use region()
        self.mx, self.my = -1, -1
        -- maxy = -1 if unlimited lines, 1 if single line editor
        self.maxx, self.maxy = (length < 0 and -1 or length),
            (height <= 0 and 1 or -1)

        self.scrolly = 0 -- vertical scroll offset

        self.line_wrap = length < 0
        -- required for up/down/hit/draw/bounds
        self.pixel_width  = abs(length) * _V.fontw
        -- -1 for variable size, i.e. from bounds
        self.pixel_height = -1

        self.password = kwargs.password or false

        -- must always contain at least one line
        self.lines = { kwargs.value or "" }

        if length < 0 and height <= 0 then
            local w, h = _C.text_get_bounds(self.lines[1], self.pixel_width)
            self.pixel_height = h
        else
            self.pixel_height = _V.fonth * max(height, 1)
        end

        return Object.__init(self, kwargs)
    end,

    clear = function(self)
        if self == get_textediting() then
            set_textediting()
        end
        refreshrepeat = refreshrepeat + 1
        return Object:clear()
    end,

    edit_clear = function(self, init)
        self.cx, self.cy = 0, 0
        self:mark()
        if init == false then
            self.lines = {}
        else
            self.lines = { init or "" }
        end
    end,

    mark = function(self, enable)
        self.mx = enable and self.cx or -1
        self.my = self.cy
    end,

    select_all = function(self)
        self.cx, self.cy = 0, 0
        self.mx, self.my = 1 / 0, 1 / 0
    end,

    -- constrain results to within buffer - s = start, e = end, return true if
    -- a selection range also ensures that cy is always within lines[] and cx
    -- is valid
    region = function(self)
        local sx, sy, ex, ey

        local  n = #self.lines
        assert(n ~= 0)

        local cx, cy, mx, my = self.cx, self.cy, self.mx, self.my

        if cy < 0 then cy = 0 elseif cy >= n then cy = n - 1 end
        local len = #self.lines[cy + 1]
        if cx < 0 then cx = 0 elseif cx > len then cx = len end
        if mx >= 0 then
            if my < 0 then my = 0 elseif my >= n then my = n - 1 end
            len = #self.lines[my + 1]
            if mx > len then mx = len end
        end
        sx, sy = (mx >= 0) and mx or cx, (mx >= 0) and my or cy -- XXX
        ex, ey = cx, cy
        if sy >  ey then sy, ey, sx, ex = ey, sy, ex, sx
        elseif sy == ey and sx > ex then sx, ex = ex, sx end

        self.cx, self.cy, self.mx, self.my = cx, cy, mx, my

        return ((sx ~= ex) or (sy ~= ey)), sx, sy, ex, ey
    end,

    -- also ensures that cy is always within lines[] and cx is valid
    current_line = function(self)
        local  n = #self.lines
        assert(n ~= 0)

        if     self.cy <  0 then self.cy = 0
        elseif self.cy >= n then self.cy = n - 1 end

        local len = #self.lines[self.cy + 1]

        if     self.cx < 0   then self.cx = 0
        elseif self.cx > len then self.cx = len end

        return self.lines[self.cy + 1]
    end,

    to_string = function(self)
        return table.concat(self.lines, "\n")
    end,

    selection_to_string = function(self)
        local buf = {}
        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            local y = sy + i - 1
            local line = self.lines[y + 1]
            local len  = #line
            if y == sy then line = line:sub(sx + 1) end
            buf[#buf + 1] = line
            buf[#buf + 1] = "\n"
        end

        if #buf > 0 then
            return table.concat(buf)
        end
    end,

    remove_lines = function(self, start, count)
        for i = 1, count do
            table.remove(self.lines, start)
        end
    end,

    -- removes the current selection (if any),
    -- returns true if selection was removed
    del = function(self)
        local b, sx, sy, ex, ey = self:region()
        if not b then
            self:mark()
            return false
        end

        if sy == ey then
            if sx == 0 and ex == #self.lines[ey + 1] then
                self:remove_lines(sy + 1, 1)
            else self.lines[sy + 1]:del(sx + 1, ex - sx)
            end
        else
            if ey > sy + 1 then
                self:remove_lines(sy + 2, ey - (sy + 1))
                ey = sy + 1
            end

            if ex == #self.lines[ey + 1] then
                self:remove_lines(ey + 1, 1)
            else
                self.lines[ey + 1]:del(1, ex)
            end

            if sx == 0 then
                self:remove_lines(sy + 1, 1)
            else
                self.lines[sy + 1]:del(sx + 1, #self.lines[sy] - sx)
            end
        end

        if #self.lines == 0 then self.lines = { "" } end
        self:mark()
        self.cx, self.cy = sx, sy

        local current = self:current_line()
        if self.cx > #current and self.cy < #self.lines - 1 then
            self.lines[self.cy + 1] = table.concat {
                self.lines[self.cy + 1], self.lines[self.cy + 2] }
            self:remove_lines(self.cy + 2, 1)
        end

        return true
    end,

    insert = function(self, ch)
        if #ch > 1 then
            for c in ch:gmatch(".") do
                self:insert(c)
            end
            return nil
        end

        self:del()
        local current = self:current_line()

        if ch == "\n" then
            if self.maxy == -1 or self.cy < (self.maxy - 1) then
                local newline = current:sub(self.cx + 1)
                self.lines[self.cy + 1] = current:sub(1, self.cx)
                self.cy = min(#self.lines, self.cy + 1)
                table.insert(self.lines, self.cy + 1, newline)
            else
                current = current:sub(1, self.cx)
                self.lines[self.cy + 1] = current
            end
            self.cx = 0
        else
            local len = #current
            if self.maxx >= 0 and len > self.maxx - 1 then
                len = self.maxx - 1
            end
            if self.cx <= len then
                self.lines[self.cy + 1] = current:insert(self.cx, ch)
                self.cx = self.cx + 1
            end
        end
    end,

    movement_mark = function(self)
        self:scroll_on_screen()
        if band(_C.input_get_modifier_state(), mod.SHIFT) ~= 0 then
            if not self:region() then self:mark(true) end
        else
            self:mark(false)
        end
    end,

    scroll_on_screen = function(self)
        self:region()
        self.scrolly = clamp(self.scrolly, 0, self.cy)
        local h = 0
        for i = self.cy + 1, self.scrolly + 1, -1 do
            local width, height = _C.text_get_bounds(self.lines[i],
                self.line_wrap and self.pixel_width or -1)
            if h + height > self.pixel_height then
                self.scrolly = i
                break
            end
            h = h + height
        end
    end,

    edit_key = function(self, code)
        local mod_keys
        if ffi.os == "OSX" then
            mod_keys = mod.GUI
        else
            mod_keys = mod.CTRL
        end

        if code == key.UP then
            self:movement_mark()
            if self.line_wrap then
                local str = self:current_line()
                local x, y = _C.text_get_position(str, self.cx + 1,
                    self.pixel_width)
                if y > 0 then
                    self.cx = _C.text_is_visible(str, x, y - FONTH,
                        self.pixel_width)
                    self:scroll_on_screen()
                    return nil
                end
            end
            self.cy = self.cy - 1
            self:scroll_on_screen()
        elseif code == key.DOWN then
            self:movement_mark()
            if self.line_wrap then
                local str = self:current_line()
                local x, y = _C.text_get_position(str, self.cx,
                    self.pixel_width)
                local width, height = _C.text_get_bounds(str,
                    self.pixel_width)
                y = y + _V.fonth
                if y < height then
                    self.cx = _C.text_is_visible(str, x, y, self.pixel_width)
                    self:scroll_on_screen()
                    return nil
                end
            end
            self.cy = self.cy + 1
            self:scroll_on_screen()
        elseif code == key.MOUSE4 then
            self.scrolly = self.scrolly - 3
        elseif code == key.MOUSE5 then
            self.scrolly = self.scrolly + 3
        elseif code == key.PAGEUP then
            self:movement_mark()
            if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                self.cy = 0
            else
                self.cy = self.cy - self.pixel_height / _V.fonth
            end
            self:scroll_on_screen()
        elseif code == key.PAGEDOWN then
            self:movement_mark()
            if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                self.cy = 1 / 0
            else
                self.cy = self.cy + self.pixel_height / _V.fonth
            end
            self:scroll_on_screen()
        elseif code == key.HOME then
            self:movement_mark()
            self.cx = 0
            if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                self.cy = 0
            end
            self:scroll_on_screen()
        elseif code == key.END then
            self:movement_mark()
            self.cx = 1 / 0
            if band(_C.input_get_modifier_state(), mod_keys) ~= 0 then
                self.cy = 1 / 0
            end
            self:scroll_on_screen()
        elseif code == key.LEFT then
            self:movement_mark()
            if     self.cx > 0 then self.cx = self.cx - 1
            elseif self.cy > 0 then
                self.cx = 1 / 0
                self.cy = self.cy - 1
            end
            self:scroll_on_screen()
        elseif code == key.RIGHT then
            self:movement_mark()
            if self.cx < #self.lines[self.cy + 1] then
                self.cx = self.cx + 1
            elseif self.cy < #self.lines - 1 then
                self.cx = 0
                self.cy = self.cy + 1
            end
            self:scroll_on_screen()
        elseif code == key.DELETE then
            if not self:del() then
                local current = self:current_line()
                if self.cx < #current then
                    self.lines[self.cy + 1] = current:del(self.cx + 1, 1)
                elseif self.cy < #self.lines - 1 then
                    -- combine with next line
                    self.lines[self.cy + 1] = table.concat {
                        current, self.lines[self.cy + 2] }
                    self:remove_lines(self.cy + 2, 1)
                end
            end
            self:scroll_on_screen()
        elseif code == key.BACKSPACE then
            if not self:del() then
                local current = self:current_line()
                if self.cx > 0 then
                    self.lines[self.cy + 1] = current:del(self.cx, 1)
                    self.cx = self.cx - 1
                elseif self.cy > 0 then
                    -- combine with previous line
                    self.cx = #self.lines[self.cy]
                    self.lines[self.cy] = table.concat {
                        self.lines[self.cy], current }
                    self:remove_lines(self.cy + 1, 1)
                    self.cy = self.cy - 1
                end
            end
            self:scroll_on_screen()
        elseif code == key.RETURN then
            -- maintain indentation
            local str = self:current_line()
            self:insert("\n")
            for c in str:gmatch "." do if c == " " or c == "\t" then
                self:insert(c) else break
            end end
            self:scroll_on_screen()
        elseif code == key.TAB then
            local b, sx, sy, ex, ey = self:region()
            if b then
                for i = sy, ey do
                    if band(_C.input_get_modifier_state(), mod.SHIFT) ~= 0 then
                        local rem = 0
                        for j = 1, min(4, #self.lines[i + 1]) do
                            if self.lines[i + 1]:sub(j, j) == " " then
                                rem = rem + 1
                            else
                                if self.lines[i + 1]:sub(j, j) == "\t"
                                and j == 0 then
                                    rem = rem + 1
                                end
                                break
                            end
                        end
                        self.lines[i + 1] = self.lines[i + 1]:del(1, rem)
                        if i == self.my then self.mx = self.mx
                            - (rem > self.mx and self.mx or rem) end
                        if i == self.cy then self.cx = self.cx -  rem end
                    else
                        self.lines[i + 1] = "\t" .. self.lines[i + 1]
                        if i == self.my then self.mx = self.mx + 1 end
                        if i == self.cy then self.cx = self.cx + 1 end
                    end
                end
            elseif band(_C.input_get_modifier_state(), mod.SHIFT) ~= 0 then
                if self.cx > 0 then
                    local cy = self.cy
                    local lines = self.lines
                    if lines[cy + 1]:sub(1, 1) == "\t" then
                        lines[cy + 1] = lines[cy + 1]:sub(2)
                        self.cx = self.cx - 1
                    else
                        for j = 1, min(4, #lines[cy + 1]) do
                            if lines[cy + 1]:sub(1, 1) == " " then
                                lines[cy + 1] = lines[cy + 1]:sub(2)
                                self.cx = self.cx - 1
                            end
                        end
                    end
                end
            else
                self:insert("\t")
            end
            self:scroll_on_screen()
        elseif code == key.A then
            if band(_C.input_get_modifier_state(), mod_keys) == 0 then
                return nil
            end
            self:select_all()
            self:scroll_on_screen()
        elseif code == key.C or code == key.X then
            if band(_C.input_get_modifier_state(), mod_keys) == 0
            or not self:region() then
                return nil
            end
            self:copy()
            if code == key.X then self:del() end
            self:scroll_on_screen()
        elseif code == key.V then
            if band(_C.input_get_modifier_state(), mod_keys) == 0 then
                return nil
            end
            self:paste()
            self:scroll_on_screen()
        else
            self:scroll_on_screen()
        end
    end,

    set_file = function(self, filename)
        self.filename = filename
    end,

    get_file = function(self)
        return self.filename
    end,

    load_file = function(self, fn)
        if fn then
            self.filename = path(fn, true) -- XXX
        end

        if not self.filename then return nil end

        self.cx = 0
        self.cy = 0

        self:mark(false)
        self.lines = {}

        local f = io.open(self.filename, "r")
        if    f then
            local maxx, maxy = self.maxx, self.maxy
            local lines = f:read("*all"):split("\n")
            if maxy > -1 and #lines > maxy then
                lines = { unpack(lines, 1, maxy) }
            end
            if maxx > -1 then
                lines = table.map(lines, function(line)
                    return line:sub(1, maxx)
                end)
            end
            f:close()
            self.lines = lines
        end
        if #lines == 0 then
            lines = { "" }
        end
    end,

    save_file = function(self, fn)
        if fn then
            self.filename = path(fn, true) -- XXX
        end

        if not self.filename then return nil end

        local  f = io.open(self.filename, "w")
        if not f then return nil end
        local lines = self.lines
        for i = 1, #lines do
            f:write(lines[i])
            f:write("\n")
        end
        f:close()
    end,

    hit = function(self, hitx, hity, dragged)
        local max_width = self.line_wrap and self.pixel_width or -1
        local h = 0
        for i = self.scrolly + 1, #self.lines do
            local width, height = _C.text_get_bounds(self.lines[i], max_width)
            if h + height > self.pixel_height then break end
            if hity >= h and hity <= h + height then
                local x = _C.text_is_visible(self.lines[i], hitx, hity - h,
                    max_width)
                if dragged then
                    self.mx, self.my = x, i - 1
                else
                    self.cx, self.cy = x, i - 1
                end
                break
            end
            h = h + height
        end
    end,

    limit_scroll_y = function(self)
        local max_width = self.line_wrap and self.pixel_width or -1
        local slines = #self.lines
        local ph = self.pixel_height
        while slines > 0 and ph > 0 do
            local width, height = _C.text_get_bounds(self.lines[slines],
                max_width)
            if height > ph then break end
            ph = ph - height
            slines = slines - 1
        end
        return slines
    end,

    exec = function(sel)
        assert(pcall(assert(loadstring(sel and self:selection_to_string() or
            self:to_string()))))
    end,

    copy = function(self)
        if not self:region() then return nil end
        local str = self:selection_to_string()
        if str then _C.clipboard_set_text(str) end
    end,

    paste = function(self)
        if not _C.clipboard_has_text() then return false end
        if self:region() then self:del() end
        local  str = _C.clipboard_get_text()
        if not str then return false end
        self:insert(str)
        return true
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    commit = function(self) end,

    hovering = function(self, cx, cy)
        if is_clicked(self) and is_focused(self) then
            local dx = abs(cx - self.offset_h)
            local dy = abs(cy - self.offset_v)
            local fw, fh = _V["fontw"], _V["fonth"]
            local th = fh * _V.uitextrows
            local sc = self.scale
            local dragged = max(dx, dy) > (fh / 8) * sc / th

            self:hit(floor(cx * th / sc - fw / 2),
                floor(cy * th / sc), dragged)
        end
    end,

    clicked = function(self, cx, cy)
        set_focus(self)
        self:mark()
        self.offset_h = cx
        self.offset_v = cy

        return Object.clicked(self, cx, cy)
    end,

    key_hover = function(self, code, isdown)
        if code == key.LEFT   or code == key.RIGHT or
           code == key.UP     or code == key.DOWN  or
           code == key.MOUSE4 or code == key.MOUSE5
        then
            if isdown then self:edit_key(code) end
            return true
        end
        return Object.key_hover(self, code, isdown)
    end,

    key = function(self, code, isdown)
        if Object.key(self, code, isdown) then return true end
        if not is_focused(self) then return false end

        if code == key.ESCAPE or ((code == key.RETURN
        or code == key.KP_ENTER or code == key.TAB) and self.maxy == 1) then
            set_focus(nil)
            return true
        end

        if isdown then self:edit_key(code) end
        return true
    end,

    reset_value = function(self)
        local ival = self.init_value
        if ival and ival ~= self.lines[1] then
            self:edit_clear(ival)
        end
    end,

    layout = function(self)
        Object.layout(self)

        if not is_focused(self) then
            self:reset_value()
        end

        if self.line_wrap and self.maxy == 1 then
            local w, h = _C.text_get_bounds(self.lines[1], self.pixel_width)
            self.pixel_height = h
        end

        self.w = max(self.w, (self.pixel_width + _V.fontw) *
            self.scale / (_V.fonth * _V.uitextrows))

        self.h = max(self.h, self.pixel_height *
            self.scale / (_V.fonth * _V.uitextrows)
        )
    end,

    draw = function(self, sx, sy)
        _C.hudmatrix_push()

        _C.hudmatrix_translate(sx, sy, 0)
        local s = self.scale / (_V.fonth * _V.uitextrows)
        _C.hudmatrix_scale(s, s, 1)
        _C.hudmatrix_flush()

        local x, y, hit = _V.fontw / 2, 0, is_focused(self)
        local max_width = self.line_wrap and self.pixel_width or -1
        local selection, sx, sy, ex, ey = self:region()

        self.scrolly = clamp(self.scrolly, 0, #self.lines - 1)

        if selection then
            -- convert from cursor coords into pixel coords
            local psx, psy = _C.text_get_position(self.lines[sy + 1], sx,
                max_width)
            local pex, pey = _C.text_get_position(self.lines[ey + 1], ex,
                max_width)
            local maxy = #self.lines
            local h = 0
            for i = self.scrolly + 1, maxy do
                local width, height = _C.text_get_bounds(self.lines[i],
                    max_width)
                if h + height > self.pixel_height then
                    maxy = i
                    break
                end
                if i == sy + 1 then
                    psy = psy + h
                end
                if i == ey + 1 then
                    pey = pey + h
                    break
                end
                h = h + height
            end
            maxy = maxy - 1

            if ey >= self.scrolly and sy <= maxy then
                -- crop top/bottom within window
                if  sy < self.scrolly then
                    sy = self.scrolly
                    psy = 0
                    psx = 0
                end
                if  ey > maxy then
                    ey = maxy
                    pey = self.pixel_height - _V.fonth
                    pex = self.pixel_width
                end

                _C.shader_hudnotexture_set()
                _C.gle_color3ub(0xA0, 0x80, 0x80)
                _C.gle_defvertex(2)
                _C.gle_begin(gl.QUADS)
                if psy == pey then
                    _C.gle_attrib2f(x + psx, y + psy)
                    _C.gle_attrib2f(x + pex, y + psy)
                    _C.gle_attrib2f(x + pex, y + pey + _V.fonth)
                    _C.gle_attrib2f(x + psx, y + pey + _V.fonth)
                else
                    _C.gle_attrib2f(x + psx,              y + psy)
                    _C.gle_attrib2f(x + psx,              y + psy + _V.fonth)
                    _C.gle_attrib2f(x + self.pixel_width, y + psy + _V.fonth)
                    _C.gle_attrib2f(x + self.pixel_width, y + psy)
                    if (pey - psy) > _V.fonth then
                        _C.gle_attrib2f(x,                    y + psy + _V.fonth)
                        _C.gle_attrib2f(x + self.pixel_width, y + psy + _V.fonth)
                        _C.gle_attrib2f(x + self.pixel_width, y + pey)
                        _C.gle_attrib2f(x,                    y + pey)
                    end
                    _C.gle_attrib2f(x,       y + pey)
                    _C.gle_attrib2f(x,       y + pey + _V.fonth)
                    _C.gle_attrib2f(x + pex, y + pey + _V.fonth)
                    _C.gle_attrib2f(x + pex, y + pey)
                end
                _C.gle_end()
                _C.shader_hud_set()
            end
        end

        local h = 0
        for i = self.scrolly + 1, #self.lines do
            local width, height = _C.text_get_bounds(self.lines[i], max_width)
            if h + height > self.pixel_height then
                break
            end
            _C.text_draw(self.password and ("*"):rep(#self.lines[i])
                or self.lines[i], x, y + h, 255, 255, 255, 255,
                (hit and (self.cy == i - 1)) and self.cx or -1, max_width)

            -- line wrap indicator
            if self.line_wrap and height > _V.fonth then
                _C.shader_hudnotexture_set()
                _C.gle_color3ub(0x80, 0xA0, 0x80)
                _C.gle_defvertex(2)
                _C.gle_begin(gl.gl.TRIANGLE_STRIP)
                _C.gle_attrib2f(x,                y + h + _V.fonth)
                _C.gle_attrib2f(x,                y + h + height)
                _C.gle_attrib2f(x - _V.fontw / 2, y + h + _V.fonth)
                _C.gle_attrib2f(x - _V.fontw / 2, y + h + height)
                _C.gle_end()
                _C.shader_hud_set()
            end
            h = h + height
        end

        _C.hudmatrix_pop()

        return Object.draw(self, sx, sy)
    end,

    is_field = function() return true end
})
M.Text_Editor = Text_Editor

--[[! Struct: Field
    Represents a field, a specialization of <Text_Editor>. It has the same
    properties with one added, "value". It represents the current value in
    the field. You can also provide "var" via kwargs which is the name of
    the engine variable this field will write into, but it's not a property.
    If the variable doesn't exist the field will auto-create it.
]]
M.Field = register_class("Field", Text_Editor, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.value = kwargs.value or ""
        if kwargs.var then
            local varn = kwargs.var
            self.var = varn

            if not var.exists(varn) then
                var.new(varn, var.STRING, self.value)
            end
        end

        return Text_Editor.__init(self, kwargs)
    end,

    commit = function(self)
        local val = self.lines[1]
        self.value = val
        -- trigger changed signal
        emit(self, "value_changed", val)

        local varn = self.var
        if varn then update_var(varn, val) end
    end,

    --[[! Function: key_hover
        Here it just tries to call <key>. If that returns false, it just
        returns Object.key_hover(self, code, isdown).
    ]]
    key_hover = function(self, code, isdown)
        return self:key(code, isdown) or Object.key_hover(self, code, isdown)
    end,

    --[[! Function: key
        An input key handler. If a key call on Object returns true, it just
        returns that. If the widget is not focused, it returns false. Otherwise
        it tries to handle the escape key (unsets focus), the enter and tab
        keys (those update the value) and then it tries <Text_Editor.key>.
        Returns true in any case unless it returns false in the beginning.
    ]]
    key = function(self, code, isdown)
        if Object.key(self, code, isdown) then return true end
        if not is_focused(self) then return false end

        if code == key.ESCAPE then
            set_focus(nil)
            return true
        elseif code == key.KP_ENTER or
               code == key.RETURN   or
               code == key.TAB
        then
            self:commit()
            set_focus(nil)
            return true
        end

        if isdown then
            self:edit_key(code)
        end
        return true
    end,

    --[[! Function: reset_value
        Resets the field value to the last saved value, effectively canceling
        any sort of unsaved changes.
    ]]
    reset_value = function(self)
        local str = self.value
        if self.lines[1] ~= str then self:edit_clear(str) end
    end,

    --[[! Function: set_value ]]
    set_value = gen_setter "value"
})

local textediting   = nil
local refreshrepeat = 0

set_external("input_text", function(str)
    if not textediting then return false end
    local filter = textediting.keyfilter
    if not filter then
        textediting:insert(str)
    else
        local buf = {}
        for ch in str:gmatch(".") do
            if filter:find(ch) then buf[#buf + 1] = ch end
        end
        textediting:insert(table.concat(buf))
    end
    return true
end)

M.set_text_handler(function()
    local wastextediting = (textediting ~= nil)

    if textediting and not is_focused(textediting) then
        textediting:commit()
    end

    if not focused or not focused:is_field() then
        textediting = nil
    else
        textediting = focused
    end

    if refreshrepeat ~= 0 or (textediting ~= nil) ~= wastextediting then
        local c = textediting ~= nil
        _C.input_textinput(c, blsh(1, 1)) -- TI_GUI
        _C.input_keyrepeat(c, blsh(1, 1)) -- KR_GUI
        refreshrepeat = 0
    end
end)
