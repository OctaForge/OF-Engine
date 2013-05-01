-- external locals
local band  = math.band
local bor   = math.bor
local bnot  = math.bnot
local blsh  = math.lsh
local brsh  = math.rsh
local max   = math.max
local min   = math.min
local clamp = math.clamp
local floor = math.floor
local ceil  = math.ceil
local round = math.round
local ffi   = require("ffi")
local _V    = _G["_V"]

local M = {}

local consts = require("gui.constants")

--[[! Variable: gl
    Forwarded from the "constants" module.
]]
local gl = consts.gl
M.gl = gl

--[[! Variable: key
    Forwarded from the "constants" module.
]]
local key = consts.key
M.key = key

--[[! Variable: mod
    Forwarded from the "constants" module.
]]
local mod = consts.mod
M.mod = mod

local update_later = {}

local update_var = function(varn, val)
    if not var.exists(varn) then
        return nil
    end
    update_later[#update_later + 1] = { varn, val }
end
M.update_var = update_var

-- initialized after World is created
local world    = nil
local clicked  = nil
local hovering = nil
local focused  = nil

local hover_x = 0
local hover_y = 0
local click_x = 0
local click_y = 0

local cursor_x = 0.5
local cursor_y = 0.5

local prev_cx = 0.5
local prev_cy = 0.5

local is_clicked = function(o)
    return (o == clicked)
end
M.is_clicked = is_clicked

local is_hovering = function(o)
    return (o == hovering)
end
M.is_hovering = is_hovering

local is_focused = function(o)
    return (o == focused)
end
M.is_focused = is_focused

local set_focus = function(o)
    focused = o
end
M.set_focus = set_focus

local clear_focus = function(o)
    if o == clicked  then clicked  = nil end
    if o == hovering then hovering = nil end
    if o == focused  then focused  = nil end
end
M.clear_focus = clear_focus

local ALIGN_MASK    = 0xF

local ALIGN_HMASK   = 0x3
local ALIGN_HSHIFT  = 0
local ALIGN_HNONE   = 0
local ALIGN_LEFT    = 1
local ALIGN_HCENTER = 2
local ALIGN_RIGHT   = 3

local ALIGN_VMASK   = 0xC
local ALIGN_VSHIFT  = 2
local ALIGN_VNONE   = blsh(0, 2)
local ALIGN_BOTTOM  = blsh(1, 2)
local ALIGN_VCENTER = blsh(2, 2)
local ALIGN_TOP     = blsh(3, 2)

local CLAMP_MASK    = 0xF0
local CLAMP_LEFT    = 0x10
local CLAMP_RIGHT   = 0x20
local CLAMP_BOTTOM  = 0x40
local CLAMP_TOP     = 0x80

local NO_ADJUST     = bor(ALIGN_HNONE, ALIGN_VNONE)

local wtypes_by_name = {}
local wtypes_by_type = {}

local lastwtype = 0
local register_class = function(name, base, obj, ftype)
    if not ftype then
        lastwtype = lastwtype + 1
        ftype = lastwtype
    end
    base = base or wtypes_by_type[1]
    obj = obj or {}
    obj.type = ftype
    obj.name = name
    obj = base:clone(obj)
    wtypes_by_name[name] = obj
    wtypes_by_type[ftype] = obj
    return obj
end
M.register_class = register_class

local get_class = function(n)
    if type(n) == "string" then
        return wtypes_by_name[n]
    else
        return wtypes_by_type[n]
    end
end
M.get_class = get_class

local loop_children = function(self, fun)
    local ch = self.p_children
    local st = self.p_states

    if st then
        local s = self:choose_state()

        if s ~= self.i_current_state then
            self.i_current_state = s
        end

        local w = st[s]
        if w then
            local r = fun(w)
            if r ~= nil then return r end
        end
    end

    for i = 1, #ch do
        local r = fun(ch[i])
        if    r ~= nil then return r end
    end
end
M.loop_children = loop_children

local loop_children_r = function(self, fun)
    local ch = self.p_children
    local st = self.p_states

    for i = #ch, 1, -1 do
        local r = fun(ch[i])
        if    r ~= nil then return r end
    end

    if st then
        local s = self:choose_state()

        if s ~= self.i_current_state then
            self.i_current_state = s
        end

        local w = st[s]
        if w then
            local r = fun(w)
            if r ~= nil then return r end
        end
    end
end
M.loop_children_r = loop_children_r

local loop_in_children = function(self, cx, cy, fun)
    return loop_children(self, function(o)
        local ox = cx - o.p_x
        local oy = cy - o.p_y

        if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end)
end
M.loop_in_children = loop_in_children

local loop_in_children_r = function(self, cx, cy, fun)
    return loop_children_r(self, function(o)
        local ox = cx - o.p_x
        local oy = cy - o.p_y

        if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end)
end
M.loop_in_children_r = loop_in_children_r

local clip_stack = {}

local clip_area_intersect = function(self, c)
    self[1] = max(self[1], c[1])
    self[2] = max(self[2], c[2])
    self[3] = max(self[1], min(self[3], c[3]))
    self[4] = max(self[2], min(self[4], c[4]))
end
M.clip_area_intersect = clip_area_intersect

local clip_area_is_fully_clipped = function(self, x, y, w, h)
    return self[1] == self[3] or self[2] == self[4] or x >= self[3] or
           y >= self[4] or (x + w) <= self[1] or (y + h) <= self[2]
end
M.clip_area_is_fully_clipped = clip_area_is_fully_clipped

local clip_area_scissor = function(self)
    self = self or clip_stack[#clip_stack]
    local scr_w, scr_h = _V.scr_w, _V.scr_h

    local margin = max((scr_w / scr_h - 1) / 2, 0)

    local sx1, sy1, sx2, sy2 =
        clamp(floor((self[1] + margin) / (1 + 2 * margin) * scr_w), 0, scr_w),
        clamp(floor( self[2] * scr_h), 0, scr_h),
        clamp(ceil ((self[3] + margin) / (1 + 2 * margin) * scr_w), 0, scr_w),
        clamp(ceil ( self[4] * scr_h), 0, scr_h)

    _C.gl_scissor(sx1, scr_h - sy2, sx2 - sx1, sy2 - sy1)
end
M.clip_area_scissor = clip_area_scissor

local clip_push = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then _C.gl_scissor_enable() end

    local c = { x, y, x + w, y + h }

    l = l + 1
    clip_stack[l] = c

    if l >= 2 then clip_area_intersect(c, clip_stack[l - 1]) end
    clip_area_scissor(c)
end
M.clip_push = clip_push

local clip_pop = function()
    table.remove(clip_stack)

    local l = #clip_stack
    if    l == 0 then _C.gl_scissor_disable()
    else clip_area_scissor(clip_stack[l])
    end
end
M.clip_pop = clip_pop

local is_fully_clipped = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then return false end
    return clip_area_is_fully_clipped(clip_stack[l], x, y, w, h)
end
M.is_fully_clipped = is_fully_clipped

local quad = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    _C.gle_attrib2f(x,     y)     _C.gle_attrib2f(tx,      ty)
    _C.gle_attrib2f(x + w, y)     _C.gle_attrib2f(tx + tw, ty)
    _C.gle_attrib2f(x + w, y + h) _C.gle_attrib2f(tx + tw, ty + th)
    _C.gle_attrib2f(x,     y + h) _C.gle_attrib2f(tx,      ty + th)
end
M.draw_quad = quad

local quadtri = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    _C.gle_attrib2f(x,     y)     _C.gle_attrib2f(tx,      ty)
    _C.gle_attrib2f(x + w, y)     _C.gle_attrib2f(tx + tw, ty)
    _C.gle_attrib2f(x,     y + h) _C.gle_attrib2f(tx,      ty + th)
    _C.gle_attrib2f(x + w, y + h) _C.gle_attrib2f(tx + tw, ty + th)
end
M.draw_quadtri = quadtri

local Object, Window
Object = register_class("Object", table.Object, {
    __get = function(self, n)
        n = "p_" .. n
        return rawget(self, n)
    end,

    __set = function(self, n, v)
        local pn = "p_" .. n
        if  rawget(self, pn) ~= nil then
            rawset(self, pn, v)
            signal.emit(self, n .. "_changed", v)
            return true
        end
    end,

    __init = function(self, kwargs)
        kwargs        = kwargs or {}
        self.p_parent = nil

        local instances = rawget(self.__proto, "instances")
        if not instances then
            instances = {}
            rawset(self.__proto, "instances", instances)
        end
        instances[self] = self

        self.p_x = 0
        self.p_y = 0
        self.p_w = 0
        self.p_h = 0

        self.i_adjust   = bor(ALIGN_HCENTER, ALIGN_VCENTER)
        self.p_children = { unpack(kwargs) }
        self.__len      = Object.__len

        -- alignment and clamping
        local align_h = kwargs.align_h or 0
        local align_v = kwargs.align_v or 0
        local clamp_l = kwargs.clamp_l or 0
        local clamp_r = kwargs.clamp_r or 0
        local clamp_b = kwargs.clamp_b or 0
        local clamp_t = kwargs.clamp_t or 0

        self.p_floating    = kwargs.floating or false
        self.p_allow_focus = kwargs.allow_focus == nil and true or false

        self:align(align_h, align_v)
        self:clamp(clamp_l, clamp_r, clamp_b, clamp_t)

        -- append any required children
        for i, v in ipairs(kwargs) do
            v.p_parent = self
        end

        -- states
        self.i_current_state = nil
        local states = {}

        local ks = kwargs.states
        if ks then
            for k, v in pairs(ks) do
                states[k] = v
                states[k].p_parent = self
            end
        end

        local dstates = rawget(self.__proto, "states")
        if dstates then
            for k, v in pairs(dstates) do
                if not states[k] then
                    local cl = v:deep_clone()
                    states[k] = cl
                    cl.p_parent = self
                end
            end
        end

        self.p_states = states

        -- and connect signals
        if kwargs.signals then
            for k, v in pairs(kwargs.signals) do
                signal.connect(self, k, v)
            end
        end

        -- tooltip? widget specific
        local t = kwargs.tooltip
        if t then
            self.p_tooltip = t
        end

        -- and init
        if  kwargs.init then
            kwargs.init(self)
        end
    end,

    __len = function(self)
        return #self.p_children
    end,

    clear = function(self)
        clear_focus(self)

        local children = self.p_children
        if children then
            for i = 1, #children do
                local ch = children[i]
                ch:clear()
            end
            self.p_children = nil
        end

        signal.emit(self, "destroy")
        local insts = rawget(self.__proto, "instances")
        if insts then
            insts[self] = nil
        end
    end,

    deep_clone = function(self)
        local ch, rch = {}, self.children
        local cl = self:clone { children = ch }
        for i = 1, #rch do
            local chcl = rch[i]:deep_clone()
            chcl.p_parent = cl
            ch[i] = chcl
        end
        return cl
    end,

    update_state = function(self, sname, sval)
        local states = rawget(self, "states")
        if not states then
            states = {}
            rawset(self, "states", states)
        end

        local oldstate = states[sname]
        states[sname] = sval

        local insts = rawget(self, "instances")
        if insts then for v in pairs(insts) do
            local sts = v.p_states
            if sts then
                local st = sts[sname]
                -- update only on widgets actually using the default state
                if st and st.__proto == oldstate then
                    local nst = sval:deep_clone()
                    nst.p_parent = v
                    sts[sname] = nst
                    st:clear()
                end
            end
        end end

        oldstate:clear()
    end,

    update_states = function(self, states)
        for k, v in pairs(states) do
            self:update_state(k, v)
        end
    end,

    choose_state = function(self) return nil end,

    layout = function(self)
        self.p_w = 0
        self.p_h = 0

        loop_children(self, function(o)
            o.p_x = 0
            o.p_y = 0
            o:layout()
            self.p_w = max(self.p_w, o.p_x + o.p_w)
            self.p_h = max(self.p_h, o.p_y + o.p_h)
        end)
    end,

    adjust_children_to = function(self, px, py, pw, ph)
        loop_children(self, function(o) o:adjust_layout(px, py, pw, ph) end)
    end,

    adjust_children = function(self)
        Object.adjust_children_to(self, 0, 0, self.p_w, self.p_h)
    end,

    adjust_layout = function(self, px, py, pw, ph)
        local x, y, w, h, a = self.p_x, self.p_y,
            self.p_w, self.p_h, self.i_adjust

        local adj = band(a, ALIGN_HMASK)

        if adj == ALIGN_LEFT then
            x = px
        elseif adj == ALIGN_HCENTER then
            x = px + (pw - w) / 2
        elseif adj == ALIGN_RIGHT then
            x = px + pw - w
        end

        adj = band(a, ALIGN_VMASK)

        if adj == ALIGN_BOTTOM then
            y = py
        elseif adj == ALIGN_VCENTER then
            y = py + (ph - h) / 2
        elseif adj == ALIGN_TOP then
            y = py + ph - h
        end

        if band(a, CLAMP_MASK) ~= 0 then
            if band(a, CLAMP_LEFT ) ~= 0 then x = px end
            if band(a, CLAMP_RIGHT) ~= 0 then
                w = px + pw - x
            end

            if band(a, CLAMP_BOTTOM) ~= 0 then y = py end
            if band(a, CLAMP_TOP   ) ~= 0 then
                h = py + ph - y
            end
        end

        self.p_x, self.p_y, self.p_w, self.p_h = x, y, w, h

        if self.p_floating then
            local fx = self.p_fx
            local fy = self.p_fy

            if not fx then self.p_fx, fx = x, x end
            if not fy then self.p_fy, fy = y, y end

            self.p_x = fx
            self.p_y = fy
        end

        self:adjust_children()
    end,

    target = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c = o:target(ox, oy)
            if c then return c end
        end)
    end,

    key = function(self, code, isdown)
        return loop_children_r(self, function(o)
            if o:key(code, isdown) then return true end
        end) or false
    end,

    key_hover = function(self, code, isdown)
        local p = self.p_parent
        if p then return p:key_hover(code, isdown) end
        return false
    end,

    draw = function(self, sx, sy)
        sx = sx or self.p_x
        sy = sy or self.p_y

        loop_children(self, function(o)
            local ox = o.p_x
            local oy = o.p_y
            local ow = o.p_w
            local oh = o.p_h
            if not is_fully_clipped(sx + ox, sy + oy, ow, oh) then
                o:draw(sx + ox, sy + oy)
            end
        end)
    end,

    hover = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o:hover(ox, oy)
            if    c == o then
                hover_x = ox
                hover_y = oy
            end
            if c then return c end
        end)
    end,

    hovering = function(self, cx, cy)
    end,

    pressing = function(self, cx, cy)
    end,

    click = function(self, cx, cy)
        return loop_in_children_r(self, cx, cy, function(o, ox, oy)
            local c  = o:click(ox, oy)
            if    c == o then
                click_x = ox
                click_y = oy
            end
            if c then return c end
        end)
    end,

    clicked = function(self, cx, cy)
        update_later[#update_later + 1] = { self, "click",
            cx / self.p_w, cy / self.p_w }
    end,

    takes_input = function(self) return true end,

    find_child = function(self, otype, name, recurse, exclude)
        recurse = (recurse == nil) and true or recurse
        local o = loop_children(self, function(o)
            if o ~= exclude and o.type == otype and
            (not name or name == o.p_obj_name) then
                return o
            end
        end)
        if o then return o end
        if recurse then
            o = loop_children(self, function(o)
                if o ~= exclude then
                    local found = o:find_child(otype, name)
                    if    found ~= nil then return found end
                end
            end)
        end
        return o
    end,

    find_sibling = function(self, otype, name)
        local prev = self
        local cur  = self.p_parent

        while cur do
            local o = cur:find_child(otype, name, true, prev)
            if    o then return o end

            prev = cur
            cur  = cur.p_parent
        end
    end,

    remove = function(self, o)
        for i = 1, #self.p_children do
            if o == self.p_children[i] then
                table.remove(self.p_children, i):clear()
                return true
            end
        end
        return false
    end,

    remove_nth = function(self, n)
        if #self.p_children < n then
            return false
        end
        table.remove(self.p_children, n):clear()
        return true
    end,

    destroy = function(self)
        self.p_parent:remove(self)
    end,

    destroy_children = function(self)
        local ch = self.p_children
        for i = 1, #ch do
            ch[i]:clear()
        end
        self.p_children = {}
        signal.emit(self, "children_destroy")
    end,

    align = function(self, h, v)
        assert_param(h, "number", 2)
        assert_param(v, "number", 3)

        self.i_adjust = bor(
            band(self.i_adjust, bnot(ALIGN_MASK)),
            blsh(clamp(h, -1, 1) + 2, ALIGN_HSHIFT),
            blsh(clamp(v, -1, 1) + 2, ALIGN_VSHIFT))
    end,

    clamp = function(self, l, r, b, t)
        assert_param(l, "number", 2)
        assert_param(r, "number", 3)
        assert_param(b, "number", 4)
        assert_param(t, "number", 5)

        self.i_adjust = bor(
            band(self.i_adjust, bnot(CLAMP_MASK)),
            l ~= 0 and CLAMP_LEFT   or 0,
            r ~= 0 and CLAMP_RIGHT  or 0,
            b ~= 0 and CLAMP_BOTTOM or 0,
            t ~= 0 and CLAMP_TOP    or 0)
    end,

    get_alignment = function(self)
        local a   = self.i_adjust
        local adj = band(a, ALIGN_HMASK)
        local hal = (adj == ALIGN_LEFT) and -1 or
            (adj == ALIGN_HCENTER and 0 or 1)

        adj = band(a, ALIGN_VMASK)
        local val = (adj == ALIGN_BOTTOM) and 1 or
            (adj == ALIGN_VCENTER and 0 or -1)

        return hal, val
    end,

    get_clamping = function(self)
        local a   = self.i_adjust
        local adj = band(a, CLAMP_MASK)
        if    adj == 0 then
            return 0, 0, 0, 0
        end

        return band(a, CLAMP_LEFT  ), band(a, CLAMP_RIGHT),
               band(a, CLAMP_BOTTOM), band(a, CLAMP_TOP)
    end,

    insert = function(self, pos, obj, fun)
        table.insert(self.p_children, pos, obj)
        obj.p_parent = self
        if fun then fun(obj) end
        return obj
    end,

    append = function(self, obj, fun)
        local children = self.p_children
        children[#children + 1] = obj
        obj.p_parent = self
        if fun then fun(obj) end
        return obj
    end,

    prepend = function(self, obj, fun)
        table.insert(self.p_children, 1, obj)
        obj.p_parent = self
        if fun then fun(obj) end
        return obj
    end,

    set_state = function(self, state, obj)
        local states = self.p_states
        local ostate = states[state]
        if ostate then ostate:clear() end
        states[state] = obj
        obj.p_parent = self
        return obj
    end,

    is_field = function() return false end,

    get_window = function(self)
        local  w = self.i_win
        if not w then
            w = self.p_parent
            while w and w.type ~= Window.type do
                w = w.p_parent
            end
            self.i_win = w
        end
        return w
    end
})
M.Object = Object

local Named_Object = register_class("Named_Object", Object, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_obj_name = kwargs.name
        return Object.__init(self, kwargs)
    end
})
M.Named_Object = Named_Object

local Tag = register_class("Tag", Named_Object)
M.Tag = Tag

Window = register_class("Window", Named_Object)
M.Window = Window

local Overlay = register_class("Overlay", Window, {
    takes_input = function(self) return false end,

    target = function() end,
    hover  = function() end,
    click  = function() end
}, Window.type)
M.Overlay = Overlay

local main_visible = false

local World = register_class("World", Object, {
    __init = function(self)
        self.p_guis = {}
        self.p_guis_visible = {}
        return Object.__init(self)
    end,

    takes_input = function(self)
        return loop_children_r(self, function(o)
            if o:takes_input() then return true end
        end) or false
    end,

    hover = function(self, cx, cy)
        local ch = self.p_children
        for i = #ch, 1, -1 do
            local o = ch[i]
            local ox = cx - o.p_x
            local oy = cy - o.p_y
            if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
                local c  = o:hover(ox, oy)
                if    c == o then
                    hover_x = ox
                    hover_y = oy
                end
                return c
            end
        end
    end,

    click = function(self, cx, cy)
        local ch = self.p_children
        for i = #ch, 1, -1 do
            local o = ch[i]
            local ox = cx - o.p_x
            local oy = cy - o.p_y
            if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
                local c  = o:click(ox, oy)
                if    c == o then
                    click_x = ox
                    click_y = oy
                end
                return c
            end
        end
    end,

    layout = function(self)
        Object.layout(self)

        local sw, sh = _V.scr_w, _V.scr_h
        self.p_size  = sh
        local faspect = _V.aspect
        if faspect ~= 0 then sw = ceil(sh * faspect) end

        local margin = max((sw/sh - 1) / 2, 0)
        self.p_x = -margin
        self.p_y = 0
        self.p_w = 2 * margin + 1
        self.p_h = 1
        self.p_margin = margin

        self.adjust_children(self)
    end,

    build_gui = function(self, name, fun, noinput)
        local old = self:find_child(Window.type, name, false)
        if old then self:remove(old) end

        local win = noinput and Overlay { name = name }
            or Window { name = name }
        win.p_parent = self

        local children = self.p_children
        children[#children + 1] = win

        if fun then fun(win) end
        return win
    end,

    new_gui = function(self, name, fun, noinput)
        self.p_guis_visible[name] = false
        self.p_guis[name] = function()
            self:build_gui(name, fun, noinput)
            self.p_guis_visible[name] = true
        end
    end,

    show_gui = function(self, name)
        local  g = self.p_guis[name]
        if not g then return false end
        g()
        return true
    end,

    get_gui = function(self, name)
        return self.p_guis[name]
    end,

    hide_gui = function(self, name)
        local old = self:find_child(Window.type, name, false)
        if old then self:remove(old) end
        self.p_guis_visible[name] = false
        return old ~= nil
    end,

    replace_gui = function(self, wname, tname, obj, fun)
        local win = self:find_child(Window.type, wname, false)
        if not win then return false end
        local tag = self:find_child(Tag.type, tname)
        if not tag then return false end
        tag:destroy_children()
        tag:append(obj)
        if fun then fun(obj) end
        return true
    end,

    gui_visible = function(self, name)
        return self.p_guis_visible[name]
    end
})
M.World = World

world = World()

local cursor_reset = function()
    if _V.editing ~= 0 or #world.p_children == 0 then
        cursor_x = 0.5
        cursor_y = 0.5
    end
end
M.cursor_reset = cursor_reset
set_external("cursor_reset", cursor_reset)

var.new("cursorsensitivity", var.FLOAT, 0.001, 1, 1000)

local cursor_mode = function()
    return _V.editing == 0 and _V.freecursor or _V.freeeditcursor
end

local cursor_move = function(dx, dy)
    local cmode = cursor_mode()
    if cmode == 2 or (world:takes_input() and cmode >= 1) then
        local scale = 500 / _V.cursorsensitivity
        cursor_x = clamp(cursor_x + dx * (_V.scr_h / (_V.scr_w * scale)), 0, 1)
        cursor_y = clamp(cursor_y + dy / scale, 0, 1)
        if cmode == 2 then
            if cursor_x ~= 1 and cursor_x ~= 0 then dx = 0 end
            if cursor_y ~= 1 and cursor_y ~= 0 then dy = 0 end
            return false, dx, dy
        end
        return true, dx, dy
    end
    return false, dx, dy
end
M.cursor_move = cursor_move
set_external("cursor_move", cursor_move)

local cursor_exists = function(draw)
    if _V.mainmenu ~= 0 then return true end
    local cmode = cursor_mode()
    if cmode == 2 or (world:takes_input() and cmode >= 1) then
        if draw then return true end
        if world:target(cursor_x * world.p_w, cursor_y * world.p_h) then
            return true
        end
    end
    return false
end
M.cursor_exists = cursor_exists
set_external("cursor_exists", cursor_exists)

local cursor_get_position = function()
    local cmode = cursor_mode()
    if cmode == 2 or (world:takes_input() and cmode >= 1) then
        return cursor_x, cursor_y
    else
        return 0.5, 0.5
    end
end
M.cursor_get_position = cursor_get_position
set_external("cursor_get_position", cursor_get_position)

set_external("input_keypress", function(code, isdown)
    if not cursor_exists() then return false end

    if code == key.MOUSE5 or code == key.MOUSE4 or
       code == key.LEFT   or code == key.RIGHT  or
       code == key.DOWN   or code == key.UP
    then
        if (focused  and  focused:key_hover(code, isdown)) or
           (hovering and hovering:key_hover(code, isdown))
        then return true end
        return false
    elseif code == key.MOUSE1 then
        if isdown then
            clicked = world:click(cursor_x * world.p_w, cursor_y * world.p_h)
            if clicked then clicked:clicked(click_x, click_y) end
        else
            clicked = nil
        end
        return true
    end

    return world:key(code, isdown)
end)

set_external("gui_clear", function()
    if  _V.mainmenu ~= 0 and _C.isconnected() then
        var.set("mainmenu", 0, true, false) -- no clamping, readonly var
        world:destroy_children()
    end
end)

set_external("gl_render", function()
    local w = world
    if #w.p_children ~= 0 then
        _C.hudmatrix_ortho(w.p_x, w.p_x + w.p_w, w.p_y + w.p_h, w.p_y, -1, 1)
        _C.hudmatrix_reset()
        _C.shader_hud_set()

        _C.gl_blend_enable()
        _C.gl_blend_func(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

        _C.gle_color3f(1, 1, 1)
        w:draw()

        local tooltip = hovering and hovering.tooltip
        if    tooltip then
            local margin = max((w.p_w - 1) / 2, 0)
            local left, right = -margin, 1 + 2 * margin
            local x, y = left + cursor_x * right + 0.01, cursor_y + 0.01

            local tw, th = tooltip.p_w, tooltip.p_h
            if (x + tw * 0.95) > (right - margin) then
                x = x - tw + 0.02
                if x <= -margin then x = -margin + 0.02 end
            end
            if (y + th * 0.95) > 1 then
                y = y - th + 0.02
                if y < 0 then y = 0 end
            end

            tooltip:draw(x, y)
        end

        _C.gl_scissor_disable()
        _C.gle_disable()
    end
end)

local needsapply = {}

var.new("applydialog", var.INT, 0, 1, 1, var.PERSIST)

set_external("change_add", function(desc, ctype)
    if _V["applydialog"] == 0 then return nil end

    for i, v in pairs(needsapply) do
        if v.desc == desc then return nil end
    end

    needsapply[#needsapply + 1] = { ctype = ctype, desc = desc }
    LAPI.GUI.show_changes()
end)

local CHANGE_GFX     = blsh(1, 0)
local CHANGE_SOUND   = blsh(1, 1)
local CHANGE_SHADERS = blsh(1, 2)

set_external("changes_clear", function(ctype)
    ctype = ctype or bor(CHANGE_GFX, CHANGE_SOUND, CHANGE_SHADERS)

    needsapply = table.filter(needsapply, function(i, v)
        if band(v.ctype, ctype) == 0 then
            return true
        end

        v.ctype = band(v.ctype, bnot(ctype))
        if v.ctype == 0 then
            return false
        end

        return true
    end)
end)

set_external("changes_apply", function()
    local changetypes = 0
    for i, v in pairs(needsapply) do
        changetypes = bor(changetypes, v.ctype)
    end

    if band(changetypes, CHANGE_GFX) ~= 0 then
        update_later[#update_later + 1] = { cubescript, "resetgl" }
    end

    if band(changetypes, CHANGE_SOUND) ~= 0 then
        update_later[#update_later + 1] = { cubescript, "resetsound" }
    end

    if band(changetypes, CHANGE_SHADERS) ~= 0 then
        update_later[#update_later + 1] = { cubescript, "resetshaders" }
    end
end)

set_external("changes_get", function()
    return table.map(needsapply, function(v) return v.desc end)
end)

local text_handler
M.set_text_handler = function(f) text_handler = f end

set_external("frame_start", function()
    for i = 1, #update_later do
        local ul = update_later[i]
        local first = ul[1]
        local t = type(first)
        if t == "string" then
            _V[first] = ul[2]
        elseif t == "function" then
            first(unpack(ul, 2))
        else
            signal.emit(first, ul[2], unpack(ul, 3))
        end
    end
    update_later = {}
    if not world:gui_visible("main") and _V.mainmenu ~= 0 and not _C.isconnected(true) then
        world:show_gui("main")
    end

    if cursor_exists() then
        local w, h = world.p_w, world.p_h

        hovering = world.hover(world, cursor_x * w, cursor_y * h)
        if  hovering then
            hovering.hovering(hovering, hover_x, hover_y)
        end

        -- hacky
        if clicked then clicked:pressing(
            (cursor_x - prev_cx) * w,
            (cursor_y - prev_cy)
        ) end
    else
        hovering = nil
        clicked  = nil
    end

    world:layout()

    if hovering then
        local tooltip = hovering.tooltip
        if    tooltip then
              tooltip:layout()
              tooltip:adjust_children()
        end
    end

    if text_handler then text_handler() end

    prev_cx = cursor_x
    prev_cy = cursor_y
end)

M.get_world = function()
    return world
end

return M
