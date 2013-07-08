--[[! File: lua/core/gui/core_widgets.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Widgets related to scrolling - scrollers, scrollbars and so on.
]]

local frame = require("core.events.frame")
local math2 = require("core.lua.math")
local signal = require("core.events.signal")

local band  = bit.band
local bnot  = bit.bnot
local blsh  = bit.lshift
local max   = math.max
local min   = math.min
local clamp = math2.clamp
local emit  = signal.emit

local M = require("core.gui.core")
local world = M.get_world()

-- consts
local key = M.key

-- input event management
local is_clicked, is_hovering = M.is_clicked, M.is_hovering

-- widget types
local register_class = M.register_class

-- scissoring
local clip_push, clip_pop = M.clip_push, M.clip_pop

-- base widgets
local Object = M.get_class("Object")

-- setters
local gen_setter = M.gen_setter

-- orientation
local orient = M.orient

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
            (frame.get_frame_time() / 1000))
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
            (frame.get_frame_time() / 1000))
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
