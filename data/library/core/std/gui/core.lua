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
local EAPI  = _G["EAPI"]
local EV    = _G["EV"  ]

local nullptr = _G["nullptr"]

local update_var = function(varn, val)
    if not var.exists(varn) then
        return nil
    end

    local t = var.get_type(varn)
    if    t == -1 then
        return nil
    end

    EV[varn] = (t == 2) and tostring(val) or tonumber(val)
end

local needs_adjust = true

-- this is the "primary" world - accessed often, so avoid indexing
-- worlds[1] equals world
local world  = nil
local worlds = {}

local clicked  = nil
local hovering = nil
local focused  = nil

local was_clicked  = nil
local was_hovering = nil

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

local is_hovering = function(o)
    return (o == hovering)
end

local is_focused = function(o)
    return (o == focused)
end

local set_focus = function(o)
    focused = o
end

local clear_focus = function(o)
    if o == clicked  then clicked  = nil end
    if o == hovering then hovering = nil end
    if o == focused  then focused  = nil end
end

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

local TYPE_OBJECT             = 1
local TYPE_WORLD              = 2
local TYPE_BOX                = 3
local TYPE_TABLE              = 4
local TYPE_SPACER             = 5
local TYPE_FILLER             = 6
local TYPE_OFFSETTER          = 7
local TYPE_CLIPPER            = 8
local TYPE_CONDITIONAL        = 9
local TYPE_BUTTON             = 10
local TYPE_CONDITIONAL_BUTTON = 11
local TYPE_TOGGLE             = 12
local TYPE_SCROLLER           = 13
local TYPE_SCROLLBAR          = 14
local TYPE_SCROLL_BUTTON      = 15
local TYPE_SLIDER             = 16
local TYPE_SLIDER_BUTTON      = 17
local TYPE_RECTANGLE          = 18
local TYPE_IMAGE              = 19
local TYPE_SLOT_VIEWER        = 20
local TYPE_LABEL              = 21
local TYPE_TEXT_EDITOR        = 22
local TYPE_MOVER              = 23
local TYPE_RESIZER            = 24

local loop_children = function(self, fun, hidden)
    local ch = self.p_children
    local st = self.p_states

    if st then
        local s = self:choose_state()

        if s ~= self.i_current_state then
            self.i_current_state = s
            needs_adjust = true
        end

        local w = st[s]
        if w then
            local r = fun(w)
            if r ~= nil then return r end
        end
    end

    for i = 1, #ch do
        local o = ch[i]
        if o.p_visible or hidden then
            local r = fun(o)
            if    r ~= nil then return r end
        end
    end
end

local loop_children_r = function(self, fun, hidden)
    local ch = self.p_children
    local st = self.p_states

    for i = #ch, 1, -1 do
        local o = ch[i]
        if o.p_visible or hidden then
            local r = fun(ch[i])
            if    r ~= nil then return r end
        end
    end

    if st then
        local s = self:choose_state()

        if s ~= self.i_current_state then
            self.i_current_state = s
            needs_adjust = true
        end

        local w = st[s]
        if w then
            local r = fun(w)
            if r ~= nil then return r end
        end
    end
end

local loop_in_children = function(self, cx, cy, fun, hidden)
    return loop_children(self, function(o)
        local ox = cx - o.p_x
        local oy = cy - o.p_y

        if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end, hidden)
end

local loop_in_children_r = function(self, cx, cy, fun, hidden)
    return loop_children_r(self, function(o)
        local ox = cx - o.p_x
        local oy = cy - o.p_y

        if ox >= 0 and ox < o.p_w and oy >= 0 and oy < o.p_h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end, hidden)
end

local clip_area_intersect = function(self, c)
    self[1] = max(self[1], c[1])
    self[2] = max(self[2], c[2])
    self[3] = max(self[1], min(self[3], c[3]))
    self[4] = max(self[2], min(self[4], c[4]))
end

local clip_area_is_fully_clipped = function(self, x, y, w, h)
    return self[1] == self[3] or self[2] == self[4] or x >= self[3] or
           y >= self[4] or (x + w) <= self[1] or (y + h) <= self[2]
end

local clip_area_scissor = function(self)
    local scr_w, scr_h = EV.scr_w, EV.scr_h

    local margin = max((scr_w / scr_h - 1) / 2, 0)

    local sx1, sy1, sx2, sy2 =
        clamp(floor((self[1] + margin) / (1 + 2 * margin) * scr_w), 0, scr_w),
        clamp(floor( self[2] * scr_h), 0, scr_h),
        clamp(ceil ((self[3] + margin) / (1 + 2 * margin) * scr_w), 0, scr_w),
        clamp(ceil ( self[4] * scr_h), 0, scr_h)

    gl.Scissor(sx1, scr_h - sy2, sx2 - sx1, sy2 - sy1)
end

local clip_stack = {}

local clip_push = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then gl.Enable(gl.SCISSOR_TEST) end

    local c = { x, y, x + w, y + h }

    l = l + 1
    clip_stack[l] = c

    if l >= 2 then clip_area_intersect(c, clip_stack[l - 1]) end
    clip_area_scissor(c)
end

local clip_pop = function()
    table.remove(clip_stack)

    local l = #clip_stack
    if    l == 0 then gl.Disable(gl.SCISSOR_TEST)
    else clip_area_scissor(clip_stack[l])
    end
end

local is_fully_clipped = function(x, y, w, h)
    local l = #clip_stack
    if    l == 0 then return false end
    return clip_area_is_fully_clipped(clip_stack[l], x, y, w, h)
end

local quad = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    EAPI.varray_attrib2f(x,     y)     EAPI.varray_attrib2f(tx,      ty)
    EAPI.varray_attrib2f(x + w, y)     EAPI.varray_attrib2f(tx + tw, ty)
    EAPI.varray_attrib2f(x + w, y + h) EAPI.varray_attrib2f(tx + tw, ty + th)
    EAPI.varray_attrib2f(x,     y + h) EAPI.varray_attrib2f(tx,      ty + th)
end

local quadtri = function(x, y, w, h, tx, ty, tw, th)
    tx, ty, tw, th = tx or 0, ty or 0, tw or 1, th or 1
    EAPI.varray_attrib2f(x,     y)     EAPI.varray_attrib2f(tx,      ty)
    EAPI.varray_attrib2f(x + w, y)     EAPI.varray_attrib2f(tx + tw, ty)
    EAPI.varray_attrib2f(x,     y + h) EAPI.varray_attrib2f(tx,      ty + th)
    EAPI.varray_attrib2f(x + w, y + h) EAPI.varray_attrib2f(tx + tw, ty + th)
end

local Image

local Object
Object = table.Object:clone {
    name = "Object",
    type = TYPE_OBJECT,

    __get = function(self, n)
        n = "p_" .. n
        return rawget(self, n)
    end,

    __set = function(self, n, v)
        local pn = "p_" .. n
        if  rawget(self, pn) ~= nil then
            rawset(self, pn, v)
            signal.emit(self, n .. "_changed", v)
            needs_adjust = true
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

        -- in case some widget set visible to false beforehand
        self.p_visible = kwargs.visible ~= false and true or false
        self.__len     = Object.__len

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
                signal.connect(self, k, function(_, ...)
                    return v(...)
                end)
            end
        end

        local tgs = {}

        local t = kwargs.tags
        if t then for i = 1, #t do
            local v = t[i]
            tgs  [v] = v
        end end

        self.tags = setmetatable({
            add = function(t, tag)
                tgs[tag] = tag
            end,

            del = function(t, tag)
                tgs[tag] = nil
            end,

            get = function(t, tag)
                return tgs[tag]
            end
        }, {
            __index    = tgs,
            __newindex = function() end,
            __len      = function()
                local  i = 0
                for k, v in pairs(tgs) do i = i + 1 end
                return i
            end
        })

        -- pointer? works for some widgets only
        local p = kwargs.pointer
        if p then
            if type(p) == "string" then
                self.p_pointer = Image {
                    file = p,
                    min_filter = gl.NEAREST,
                    mag_filter = gl.NEAREST
                }
            else
                self.p_pointer = p
            end
        end

        -- tooltip? works for some widgets only too
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
        needs_adjust = true
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

            local fw = self.p_fw
            local fh = self.p_fh

            if not fw then self.p_fw, fw = w, w end
            if not fh then self.p_fh, fh = h, h end

            self.p_w = fw
            self.p_h = fh
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
        signal.emit(self, "click", cx / self.p_w, cy / self.p_w)
    end,

    find_child_by_type = function(self, otype, tag, recurse, exclude)
        recurse = recurse == nil and true or recurse
        return loop_children(self, function(o)
            if o ~= exclude and o.type == otype then
                return o
            end
        end, true) or (recurse and loop_children(self, function(o)
            if o ~= exclude then
                local found = Object.find_child_by_type(o, otype, tag)
                if    found ~= nil then return found end
            end
        end, true))
    end,

    find_child_by_tag = function(self, tag, recurse, exclude)
        recurse = recurse == nil and true or recurse
        return loop_children(self, function(o)
            if o ~= exclude and (not tag or o.tags[tag]) then
                return o
            end
        end, true) or (recurse and loop_children(self, function(o)
            if o ~= exclude then
                local found = Object.find_child_by_tag(o, tag)
                if    found ~= nil then return found end
            end
        end, true))
    end,

    find_sibling_by_type = function(self, otype)
        local prev = self
        local cur  = self.p_parent

        while cur do
            local o = Object.find_child_by_type(cur, otype, true, prev)
            if    o then return o end

            prev = cur
            cur  = cur.p_parent
        end
    end,

    find_sibling_by_tag = function(self, tag)
        local prev = self
        local cur  = self.p_parent

        while cur do
            local o = Object.find_child_by_tag(cur, tag, true, prev)
            if    o then return o end

            prev = cur
            cur  = cur.p_parent
        end
    end,

    remove = function(self, o)
        for i = 1, #self.p_children do
            if o == self.p_children[i] then
                table.remove(self.p_children, i):clear()
                needs_adjust = true
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
        needs_adjust = true
        return true
    end,

    destroy = function(self)
        self.p_parent:remove(self)
    end,

    hide_children = function(self)
        for i = 1, #self.p_children do
            self.p_children[i].visible = false
        end
        signal.emit(self, "children_hidden")
    end,

    show_children = function(self)
        for i = 1, #self.p_children do
            self.p_children[i].visible = true
        end
        signal.emit(self, "children_visible")
    end,

    align = function(self, h, v)
        assert_param(h, "number", 2)
        assert_param(v, "number", 3)

        self.i_adjust = bor(
            band(self.i_adjust, bnot(ALIGN_MASK)),
            blsh(clamp(h, -1, 1) + 2, ALIGN_HSHIFT),
            blsh(clamp(v, -1, 1) + 2, ALIGN_VSHIFT)
        )
        needs_adjust = true
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
            t ~= 0 and CLAMP_TOP    or 0
        )
        needs_adjust = true
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

    insert = function(self, pos, ...)
        local args = { ... }
        local len  = #args

        local children
        if type(args[len] == "function") then
            children = table.remove(args)
            len = len - 1
        end

        -- we want to prepend in correct order
        for i = len, 1, -1 do
            local o  = args[i]
            o.p_parent = self
            table.insert(self.p_children, pos, o)
        end

        if children then
            children(unpack(args))
        end

        return unpack(args)
    end,

    append = function(self, ...)
        local args = { ... }
        local len  = #args

        local children
        if type(args[len]) == "function" then
            children = table.remove(args)
            len = len - 1
        end

        for i = 1, len do
            local o  = args[i]
            o.p_parent = self
            local t = self.p_children
            t[#t + 1] = o
        end

        if children then
            children(unpack(args))
        end

        return unpack(args)
    end,

    prepend = function(self, ...)
        local args = { ... }
        local len  = #args

        local children
        if type(args[len] == "function") then
            children = table.remove(args)
            len = len - 1
        end

        -- we want to prepend in correct order
        for i = len, 1, -1 do
            local o  = args[i]
            o.p_parent = self
            table.insert(self.p_children, 1, o)
        end

        if children then
            children(unpack(args))
        end

        return unpack(args)
    end,

    replace = function(self, tag, obj)
        if type(tag) == "string" then
            local o = self:find_child_by_tag(tag)
            if o then o:replace(obj) end
            return nil
        end

        local ch = self.parent.children
        local idx
        for i = 1, #ch do
            if ch[i] == self then
                idx = i
            end
        end
        if idx then
            ch[idx]:clear()
            ch[idx] = tag
            needs_adjust = true
        end
    end
}

local World = Object:clone {
    name = "World",
    type = TYPE_WORLD,

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_input = kwargs.input == true and true or false

        return Object.__init(self, kwargs)
    end,

    focus_children = function(self)
        return loop_children(self, function(o)
            if o.p_allow_focus or not CAPI.is_mouselooking() then
                return true
            end
        end) or false
    end,

    layout = function(self)
        Object.layout(self)

        local       margin = max((EV.scr_w / EV.scr_h - 1) / 2, 0)
        self.p_x = -margin
        self.p_y = 0
        self.p_w = 2 * margin + 1
        self.p_h = 1

        self.adjust_children(self)

        local p = self.p_pointer
        if    p then
              p:layout()
              p:adjust_children()
        end
    end
}

local H_Box = Object:clone {
    name = "H_Box",
    type = TYPE_BOX,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_padding = kwargs.padding or 0
        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        self.p_w, self.p_h = 0, 0

        loop_children(self, function(o)
            o.p_x = self.p_w
            o.p_y = 0
            o:layout()

            self.p_w = self.p_w + o.p_w
            self.p_h = max(self.p_h, o.p_y + o.p_h)
        end)
        self.p_w = self.p_w + self.p_padding * max(#self.p_children - 1, 0)
    end,

    adjust_children = function(self)
        if #self.p_children == 0 then
            return nil
        end

        local offset = 0
        loop_children(self, function(o)
            o.p_x = offset
            offset = offset + o.p_w

            o:adjust_layout(o.p_x, 0, o.p_w, self.p_h)
            offset = offset + self.p_padding
        end)
    end
}

local V_Box = Object:clone {
    name = "V_Box",
    type = TYPE_BOX,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_padding = kwargs.padding or 0
        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        self.p_w = 0
        self.p_h = 0

        loop_children(self, function(o)
            o.p_x = 0
            o.p_y = self.p_h
            o:layout()

            self.p_h = self.p_h + o.p_h
            self.p_w = max(self.p_w, o.p_x + o.p_w)
        end)
        self.p_h = self.p_h + self.p_padding * max(#self.p_children - 1, 0)
    end,

    adjust_children = function(self)
        if #self.p_children == 0 then
            return nil
        end

        local offset = 0
        loop_children(self, function(o)
            o.p_y = offset
            offset = offset + o.p_h

            o:adjust_layout(0, o.p_y, self.p_w, o.p_h)
            offset = offset + self.p_padding
        end)
    end
}

local Table = Object:clone {
    name = "Table",
    type = TYPE_TABLE,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_columns = kwargs.columns or 0
        self.p_padding = kwargs.padding or 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        local widths, heights = createtable(4), createtable(4)
        self.widths, self.heights = widths, heights

        local column, row = 1, 1
        local columns, padding = self.p_columns, self.p_padding

        loop_children(self, function(o)
            o:layout()

            if #widths < column then
                widths[#widths + 1] = o.p_w
            elseif o.p_w > widths[column] then
                widths[column] = o.p_w
            end

            if #heights < row then
                heights[#heights + 1] = o.p_h
            elseif o.p_h > heights[row] then
                heights[row] = o.p_h
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
            o.p_x = offset
            o.p_y = p_h

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

        self.p_w = p_w + padding * max(#widths  - 1, 0)
        self.p_h = p_h + padding * max(#heights - 1, 0)
    end,

    adjust_children = function(self)
        if #self.p_children == 0 then
            return nil
        end
        
        local widths, heights = self.widths, self.heights
        local columns = self.p_columns

        local cspace = self.p_w
        local rspace = self.p_h

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
            o.p_x = offsetx
            o.p_y = offsety

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
    end
}

local Spacer = Object:clone {
    name = "Spacer",
    type = TYPE_SPACER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_pad_h = kwargs.pad_h or 0
        self.p_pad_v = kwargs.pad_v or 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        local ph, pv = self.pad_h, self.pad_v
        local w , h  = ph, pv

        loop_children(self, function(o)
            o.p_x = ph
            o.p_y = pv
            o:layout()

            w = max(w, o.p_x + o.p_w)
            h = max(h, o.p_y + o.p_h)
        end)

        self.p_w = w + ph
        self.p_h = h + pv
    end,

    adjust_children = function(self)
        local ph, pv = self.p_pad_h, self.p_pad_v
        Object.adjust_children_to(self, ph, pv, self.p_w - 2 * ph,
            self.p_h - 2 * pv)
    end
}

local Filler = Object:clone {
    name = "Filler",
    type = TYPE_FILLER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_min_w = kwargs.min_w or 0
        self.p_min_h = kwargs.min_h or 0

        self.p_clip_children = kwargs.clip_children or false

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        Object.layout(self)

        local min_w = self.p_min_w
        local min_h = self.p_min_h

        if  min_w == -1 then
            local w = self.p_parent
            while w.p_parent do
                  w = w.p_parent
            end
            min_w = w.p_w
        end
        if  min_h == -1 then
            min_h = 1
        end

        self.p_w = max(self.p_w, min_w)
        self.p_h = max(self.p_h, min_h)
    end,

    draw = function(self, sx, sy)
        if self.p_clip_children then
            clip_push(sx, sy, self.p_w, self.p_h)
            Object.draw(self, sx, sy)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end
}

local Offsetter = Object:clone {
    name = "Offsetter",
    type = TPYPE_OFFSETTER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_offset_h = kwargs.offset_h or 0
        self.p_offset_v = kwargs.offset_v or 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        Object.layout(self)

        local oh, ov = self.p_offset_h, self.p_offset_v

        loop_children(self, function(o)
            o.p_x = o.p_x + oh
            o.p_y = o.p_y + ov
        end)

        self.p_w = self.p_w + oh
        self.p_h = self.p_h + ov
    end,

    adjust_children = function(self)
        local oh, ov = self.p_offset_h, self.p_offset_v
        Object.adjust_children_to(self, oh, ov, self.p_w - oh, self.p_h - ov)
    end
}

local Clipper = Object:clone {
    name = "Clipper",
    type = TYPE_CLIPPER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_clip_w = kwargs.clip_w or 0
        self.p_clip_h = kwargs.clip_h or 0
        self.i_virt_w = 0
        self.i_virt_h = 0

        return Object.__init(self, kwargs)
    end,

    layout = function(self)
        Object.layout(self)
    
        self.i_virt_w = self.p_w
        self.i_virt_h = self.p_h

        local cw, ch = self.p_clip_w, self.p_clip_h

        if cw ~= 0 then self.p_w = min(self.p_w, cw) end
        if ch ~= 0 then self.p_h = min(self.p_h, ch) end
    end,

    adjust_children = function(self)
        Object.adjust_children_to(self, 0, 0, self.i_virt_w, self.i_virt_h)
    end,

    draw = function(self, sx, sy)
        local cw, ch = self.p_clip_w, self.p_clip_h

        if (cw ~= 0 and self.i_virt_w > cw) or (ch ~= 0 and self.i_virt_h > ch)
        then
            clip_push(sx, sy, self.p_w, self.p_h)
            Object.draw(self, sx, sy)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end
}

local Conditional = Object:clone {
    name = "Conditional",
    type = TYPE_CONDITIONAL,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_condition = kwargs.condition
        return Object.__init(self, kwargs)
    end,

    choose_state = function(self)
        return (self.p_condition and self:p_condition()) and "true" or "false"
    end
}

local Button = Object:clone {
    name = "Button",
    type = TYPE_BUTTON,

    choose_state = function(self)
        return is_clicked(self) and "clicked" or
            (is_hovering(self) and "hovering" or "default")
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end
}

local Conditional_Button = Button:clone {
    name = "Conditional_Button",
    type = TYPE_CONDITIONAL_BUTTON,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_condition = kwargs.condition
        return Button.__init(self, kwargs)
    end,

    choose_state = function(self)
        return ((self.p_condition and self:p_condition()) and
            (is_clicked(self) and "true_clicked" or
                (is_hovering(self) and "true_hovering" or "true")) or "false")
    end,

    clicked = function(self, cx, cy)
        if self.p_condition and self:p_condition() then
            Object.clicked(self, cx, cy)
        end
    end
}

local Toggle = Button:clone {
    name = "Toggle",
    type = TYPE_TOGGLE,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_condition = kwargs.condition
        return Button.__init(self, kwargs)
    end,

    choose_state = function(self)
        local h = is_hovering(self)
        return (self.p_condition and self:p_condition() and
            (h and "toggled_hovering" or "toggled") or
            (h and "default_hovering" or "default"))
    end,
}

local H_Scrollbar
local V_Scrollbar

local Scroller = Clipper:clone {
    name = "Scroller",
    type = TYPE_SCROLLER,

    __init = function (self, kwargs)
        kwargs = kwargs or {}

        self.i_offset_h = 0
        self.i_offset_v = 0
        self.i_can_scroll = 0

        return Clipper.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        local oh, ov, vw, vh = self.i_offset_h, self.i_offset_v,
            self.i_virt_w, self.i_virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then return nil end

        return Object.target(self, cx + oh, cy + ov)
    end,

    hover = function(self, cx, cy)
        local oh, ov, vw, vh = self.i_offset_h, self.i_offset_v,
            self.i_virt_w, self.i_virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then
            self.i_can_scroll = false
            return nil
        end

        self.i_can_scroll = true
        return Object.hover(self, cx + oh, cy + ov)
    end,

    click = function(self, cx, cy)
        local oh, ov, vw, vh = self.i_offset_h, self.i_offset_v,
            self.i_virt_w, self.i_virt_h

        if ((cx + oh) >= vw) or ((cy + ov) >= vh) then return nil end

        return Object.click(self, cx + oh, cy + ov)
    end,

    key_hover = function(self, code, isdown)
        local m4, m5 = EAPI.INPUT_KEY_MOUSE4, EAPI.INPUT_KEY_MOUSE5
        if code ~= m4 or code ~= m5 then
            return Object.key_hover(self, code, isdown)
        end

        if not self.i_can_scroll or not isdown then
            return false
        end

        local  sb = Object.find_sibling_by_type(self, TYPE_SCROLLBAR)
        if not sb then return false end

        local adjust = (code == m4 and -0.2 or 0.2) * sb.p_arrow_speed
        if sb.__proto == V_Scrollbar then
            self:scroll_v(adjust)
        else
            self:scroll_h(adjust)
        end

        return true
    end,

    draw = function(self, sx, sy)
        if (self.p_clip_w ~= 0 and self.i_virt_w > self.p_clip_w) or
           (self.p_clip_h ~= 0 and self.i_virt_h > self.p_clip_h)
        then
            clip_push(sx, sy, self.p_w, self.p_h)
            Object.draw(self, sx - self.i_offset_h, sy - self.i_offset_v)
            clip_pop()
        else
            return Object.draw(self, sx, sy)
        end
    end,

    get_h_limit = function(self)
        return max(self.i_virt_w - self.p_w, 0)
    end,

    get_v_limit = function(self)
        return max(self.i_virt_h - self.p_h, 0)
    end,

    get_h_offset = function(self)
        return self.i_offset_h / max(self.i_virt_w, self.p_w)
    end,

    get_v_offset = function(self)
        return self.i_offset_v / max(self.i_virt_h, self.p_h)
    end,

    get_h_scale = function(self)
        return self.p_w / max(self.i_virt_w, self.p_w)
    end,

    get_v_scale = function(self)
        return self.p_h / max(self.i_virt_h, self.p_h)
    end,

    set_h_scroll = function(self, hs)
        self.i_offset_h = clamp(hs, 0, self:get_h_limit())
    end,

    set_v_scroll = function(self, vs)
        self.i_offset_v = clamp(vs, 0, self:get_v_limit())
    end,

    scroll_h = function(self, hs)
        self:set_h_scroll(self.i_offset_h + hs)
    end,

    scroll_v = function(self, vs)
        self:set_v_scroll(self.i_offset_v + vs)
    end
}

local Scrollbar = Object:clone {
    name = "Scrollbar",
    type = TYPE_SCROLLBAR,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_arrow_size  = kwargs.arrow_size  or 0
        self.p_arrow_speed = kwargs.arrow_speed or 0
        self.i_arrow_dir   = 0

        return Object.__init(self, kwargs)
    end,

    choose_direction = function(self, cx, cy)
        return 0
    end,

    hover = function(self, cx, cy)
        return Object.hover(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    click = function(self, cx, cy)
        return Object.click(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    scroll_to = function(self, cx, cy) end,

    key_hover = function(self, code, isdown)
        local m4, m5 = EAPI.INPUT_KEY_MOUSE4, EAPI.INPUT_KEY_MOUSE5
        if code ~= m4 or code ~= m5 then
            return Object.key_hover(self, code, isdown)
        end

        if not not isdown then return false end

        local  sc = Object.find_sibling_by_type(self, TYPE_SCROLLER)
        if not sc or not sc.i_can_scroll then return false end

        local adjust = (code == m4 and -0.2 or 0.2) * self.p_arrow_speed
        if self.__proto == V_Scrollbar then
            sc:scroll_v(adjust)
        else
            sc:scroll_h(adjust)
        end

        return true
    end,

    clicked = function(self, cx, cy)
        local id = self:choose_direction(cx, cy)
        self.i_arrow_dir = id

        if id == 0 then
            self:scroll_to(cx, cy)
        else
            self:hovering(cx, cy)
        end

        return Object.clicked(self, cx, cy)
    end,

    arrow_scroll = function(self) end,

    hovering = function(self, cx, cy)
        if is_clicked(self) then
            if self.i_arrow_dir ~= 0 then
                self:arrow_scroll()
            end
        else
            local button = Object.find_child_by_type(self,
                TYPE_SCROLL_BUTTON, false)
            if button and is_clicked(button) then
                self.i_arrow_dir = 0
                button:hovering(cx - button.p_x, cy - button.p_y)
            else
                self.i_arrow_dir = self:choose_direction(cx, cy)
            end
        end
    end,

    move_button = function(self, o, fromx, fromy, tox, toy) end
}

local Scroll_Button = Object:clone {
    name = "Scroll_Button",
    type = TYPE_SCROLL_BUTTON,

    __init = function(self, kwargs)
        self.i_offset_h = 0
        self.i_offset_v = 0

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
        local p = self.p_parent
        if is_clicked(self) and p and p.type == TYPE_SCROLLBAR then
            p:move_button(self, self.i_offset_h, self.i_offset_v, cx, cy)
        end
    end,

    clicked = function(self, cx, cy)
        self.i_offset_h = cx
        self.i_offset_v = cy

        return Object.clicked(self, cx, cy)
    end
}

H_Scrollbar = Scrollbar:clone {
    name = "H_Scrollbar",

    choose_state = function(self)
        local ad = self.i_arrow_dir

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
        local as = self.p_arrow_size
        return (cx < as) and -1 or (cx >= (self.p_w - as) and 1 or 0)
    end,

    arrow_scroll = function(self)
        local  scroll = Object.find_sibling_by_type(self, TYPE_SCROLLER)
        if not scroll then return nil end

        scroll:scroll_h(self.i_arrow_dir * self.p_arrow_speed *
            frame.get_frame_time())
    end,

    scroll_to = function(self, cx, cy)
        local  scroll = Object.find_sibling_by_type(self, TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = Object.find_child_by_type(self, TYPE_SCROLL_BUTTON, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local bscale = (max(self.p_w - 2 * as, 0) - btn.p_w) /
            (1 - scroll:get_h_scale())

        local offset = (bscale > 0.001) and (cx - as) / bscale or 0

        scroll.set_h_scroll(scroll, offset * scroll.i_virt_w)
    end,

    adjust_children = function(self)
        local  scroll = Object.find_sibling_by_type(self, TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = Object.find_child_by_type(self, TYPE_SCROLL_BUTTON, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sw, btnw = self.p_w, btn.p_w

        local bw = max(sw - 2 * as, 0) * scroll:get_h_scale()
        btn.p_w  = max(btnw, bw)

        local bscale = (scroll:get_h_scale() < 1) and
            (max(sw - 2 * as, 0) - btn.p_w) / (1 - scroll:get_h_scale()) or 1

        btn.p_x = as + scroll:get_h_offset() * bscale
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_HMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.p_x + tox - fromx, o.p_y + toy)
    end
}

V_Scrollbar = Scrollbar:clone {
    name = "V_Scrollbar",

    choose_state = function(self)
        local ad = self.i_arrow_dir

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
        local as = self.p_arrow_size
        return (cy < as) and -1 or (cy >= (self.p_h - as) and 1 or 0)
    end,

    arrow_scroll = function(self)
        local  scroll = Object.find_sibling_by_type(self, TYPE_SCROLLER)
        if not scroll then return nil end

        scroll:scroll_v(self.i_arrow_dir * self.p_arrow_speed *
            frame.get_frame_time())
    end,

    scroll_to = function(self, cx, cy)
        local  scroll = Object.find_sibling_by_type(self, TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = Object.find_child_by_type(self, TYPE_SCROLL_BUTTON, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local bscale = (max(self.p_h - 2 * as, 0) - btn.p_h) /
            (1 - scroll:get_v_scale())

        local offset = (bscale > 0.001) and
            (cy - as) / bscale or 0

        scroll:set_v_scroll(offset * scroll.i_virt_h)
    end,

    adjust_children = function(self)
        local  scroll = Object.find_sibling_by_type(self, TYPE_SCROLLER)
        if not scroll then return nil end

        local  btn = Object.find_child_by_type(self, TYPE_SCROLL_BUTTON, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sh, btnh = self.p_h, btn.p_h

        local bh = max(sh - 2 * as, 0) * scroll:get_v_scale()

        btn.p_h = max(btnh, bh)

        local bscale = (scroll:get_v_scale() < 1) and
            (max(sh - 2 * as, 0) - btn.p_h) / (1 - scroll:get_v_scale()) or 1

        btn.p_y = as + scroll:get_v_offset() * bscale
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_VMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.p_x + tox, o.p_y + toy - fromy)
    end
}

local Slider = Object:clone {
    name = "Slider",
    type = TYPE_SLIDER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_min_value = kwargs.min_value or 0
        self.p_max_value = kwargs.max_value or 0
        self.p_value     = kwargs.value     or 0

        if kwargs.var then
            local varn = kwargs.var
            self.i_var = varn

            if not var.exists(varn) then
                var.new(varn, EAPI.VAR_I, self.p_value)
            end

--            if not var.is_alias(varn) then
                local mn, mx = var.get_min(varn), var.get_max(varn)
                self.p_min_value = clamp(self.p_min_value, mn, mx)
                self.p_max_value = clamp(self.p_max_value, mn, mx)
--            end
        end

        self.p_arrow_size = kwargs.arrow_size or 0
        self.p_step_size  = kwargs.step_size  or 1
        self.p_step_time  = kwargs.step_time  or 1000

        self.i_last_step = 0
        self.i_arrow_dir = 0

        return Object.__init(self, kwargs)
    end,

    do_step = function(self, n)
        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local maxstep = abs(mx - mn) / ss
        local curstep = (self.p_value - min(mn, mx)) / ss
        local newstep = clamp(curstep + n, 0, maxstep)

        local val = min(mx, mn) + newstep * ss
        self.value = val

        local varn = self.i_var
        if varn then update_var(varn, val) end
    end,

    set_step = function(self, n)
        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local steps   = abs(mx - mn) / ss
        local newstep = clamp(n, 0, steps)

        local val = min(mx, mn) + newstep * ss
        self.value = val

        local varn = self.i_var
        if varn then update_var(varn, val) end
    end,

    key_hover = function(self, code, isdown)
        if code == EAPI.INPUT_KEY_UP or code == EAPI.INPUT_KEY_LEFT then
            if isdown then self:do_step(-1) end
            return true
        elseif code == EAPI.INPUT_KEY_MOUSE4 then
            if isdown then self:do_step(-3) end
            return true
        elseif code == EAPI.INPUT_KEY_DOWN or code == EAPI.INPUT_KEY_RIGHT then
            if isdown then self:do_step(1) end
            return true
        elseif code == EAPI.INPUT_KEY_MOUSE5 then
            if isdown then self:do_step(3) end
            return true
        end

        return Object.key_hover(self, code, isdown)
    end,

    choose_direction = function(self, cx, cy)
        return 0
    end,

    hover = function(self, cx, cy)
        return Object.hover(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    click = function(self, cx, cy)
        return Object.click(self, cx, cy) or
                     (self:target(cx, cy) and self)
    end,

    scroll_to = function(self, cx, cy) end,

    clicked = function(self, cx, cy)
        local ad = self.choose_direction(self, cx, cy)
        self.i_arrow_dir = ad

        if ad == 0 then
            self:scroll_to(cx, cy)
        else
            self:hovering(cx, cy)
        end

        return Object.clicked(self, cx, cy)
    end,

    arrow_scroll = function(self)
        if (self.i_last_step + self.p_step_time) > EAPI.totalmillis then
            return nil
        end

        self.i_last_step = EAPI.totalmillis
        self.do_step(self, self.i_arrow_dir)
    end,

    hovering = function(self, cx, cy)
        if is_clicked(self) then
            if self.i_arrow_dir ~= 0 then
                self:arrow_scroll()
            end
        else
            local button = Object.find_child_by_type(self,
                TYPE_SLIDER_BUTTON, false)

            if button and is_clicked(button) then
                self.i_arrow_dir = 0
                button.hovering(button, cx - button.p_x, cy - button.p_y)
            else
                self.i_arrow_dir = self:choose_direction(cx, cy)
            end
        end
    end,

    move_button = function(self, o, fromx, fromy, tox, toy) end
}

local Slider_Button = Object:clone {
    name = "Slider_Button",
    type = TYPE_SLIDER_BUTTON,

    __init = function(self, kwargs)
        self.i_offset_h = 0
        self.i_offset_v = 0

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
        local p = self.p_parent

        if is_clicked(self) and p and p.type == TYPE_SLIDER then
            p:move_button(self, self.i_offset_h, self.i_offset_v, cx, cy)
        end
    end,

    clicked = function(self, cx, cy)
        self.i_offset_h = cx
        self.i_offset_v = cy

        return Object.clicked(self, cx, cy)
    end,

    layout = function(self)
        local lastw = self.p_w
        local lasth = self.p_h

        Object.layout(self)

        if is_clicked(self) then
            self.p_w = lastw
            self.p_h = lasth
        end
    end
}

local H_Slider = Slider:clone {
    name = "H_Slider",

    choose_state = function(self)
        local ad = self.i_arrow_dir

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
        local as = self.p_arrow_size
        return cx < as and -1 or (cx >= (self.p_w - as) and 1 or 0)
    end,

    scroll_to = function(self, cx, cy)
        local  btn = Object.find_child_by_type(self, TYPE_SLIDER_BUTTON, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sw, bw = self.p_w, btn.p_w

        self.set_step(self, round((abs(self.p_max_value - self.p_min_value) /
            self.p_step_size) * clamp((cx - as - bw / 2) /
                (sw - 2 * as - bw), 0.1, 1)))
    end,

    adjust_children = function(self)
        local  btn = Object.find_child_by_type(self, TYPE_SLIDER_BUTTON, false)
        if not btn then return nil end

        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local steps   = abs(mx - mn) / self.p_step_size
        local curstep = (self.p_value - min(mx, mn)) / ss

        local as = self.p_arrow_size

        local width = max(self.p_w - 2 * as, 0)

        btn.p_w = max(btn.p_w, width / steps)
        btn.p_x = as + (width - btn.p_w) * curstep / steps
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_HMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self:scroll_to(o.p_x + o.p_w / 2 + tox - fromx, o.p_y + toy)
    end
}

local V_Slider = Slider:clone {
    name = "V_Slider",

    choose_state = function(self)
        local ad = self.i_arrow_dir

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
        local as = self.p_arrow_size
        return cy < as and -1 or (cy >= (self.p_h - as) and 1 or 0)
    end,

    scroll_to = function(self, cx, cy)
        local  btn = Object.find_child_by_type(self, TYPE_SLIDER_BUTTON, false)
        if not btn then return nil end

        local as = self.p_arrow_size

        local sh, bh = self.p_h, btn.p_h
        local mn, mx = self.p_min_value, self.p_max_value

        self.set_step(self, round(((max(mx, mn) - min(mx, mn)) /
            self.p_step_size) * clamp((cy - as - bh / 2) /
                (sh - 2 * as - bh), 0.1, 1)))
    end,

    adjust_children = function(self)
        local  btn = Object.find_child_by_type(self, TYPE_SLIDER_BUTTON, false)
        if not btn then return nil end

        local mn, mx, ss = self.p_min_value, self.p_max_value, self.p_step_size

        local steps   = (max(mx, mn) - min(mx, mn)) / ss + 1
        local curstep = (self.p_value - min(mx, mn)) / ss

        local as = self.p_arrow_size

        local height = max(self.p_h - 2 * as, 0)

        btn.p_h = max(btn.p_h, height / steps)
        btn.p_y = as + (height - btn.p_h) * curstep / steps
        btn.i_adjust = band(btn.i_adjust, bnot(ALIGN_VMASK))

        Object.adjust_children(self)
    end,

    move_button = function(self, o, fromx, fromy, tox, toy)
        self.scroll_to(self, o.p_x + o.p_h / 2 + tox, o.p_y + toy - fromy)
    end
}

local Rectangle = Filler:clone {
    name = "Rectangle",
    type = TYPE_RECTANGLE,

    __init = function(self, kwargs)
        kwargs       = kwargs or {}
        self.p_solid = kwargs.solid == false and false or true
        self.p_r     = kwargs.r or 255
        self.p_g     = kwargs.g or 255
        self.p_b     = kwargs.b or 255
        self.p_a     = kwargs.a or 255

        return Filler.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw = function(self, sx, sy)
        local w, h, solid = self.p_w, self.p_h, self.p_solid

        if not solid then gl.BlendFunc(gl.ZERO, gl.SRC_COLOR) end
        EAPI.base_shader_hudnotexture_set()
        EAPI.varray_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        EAPI.varray_defvertex(2, gl.FLOAT)
        EAPI.varray_begin(gl.TRIANGLE_STRIP)

        EAPI.varray_attrib2f(sx,     sy)
        EAPI.varray_attrib2f(sx + w, sy)
        EAPI.varray_attrib2f(sx,     sy + h)
        EAPI.varray_attrib2f(sx + w, sy + h)

        EAPI.varray_end()
        EAPI.varray_color4f(1, 1, 1, 1)
        EAPI.base_shader_hud_set()
        if not solid then
            gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        end

        return Filler.draw(self, sx, sy)
    end
}

local notexture = EAPI.texture_get_notexture()

local check_alpha_mask = function(tex, x, y)
    if tex.alphamask == nullptr then
        EAPI.texture_load_alpha_mask(tex)
        if tex.alphamask == nullptr then
            return true
        end
    end

    local tx, ty = clamp(floor(x * tex.xs), 0, tex.xs - 1),
                   clamp(floor(y * tex.ys), 0, tex.ys - 1)

    local m = tex.alphamask[floor(ty * ((tex.xs + 7) / 8))]
    if band(m, blsh(1, tx % 8)) ~= 0 then
        return true
    end

    return false
end

Image = Filler:clone {
    name = "Image",
    type = TYPE_IMAGE,

    __init = function(self, kwargs)
        kwargs    = kwargs or {}
        local tex = kwargs.file and EAPI.texture_load(kwargs.file)

        local af = kwargs.alt_file
        if  tex == notexture and af then
            tex = EAPI.texture_load(af)
        end

        self.i_tex = tex
        self.p_min_filter = kwargs.min_filter
        self.p_mag_filter = kwargs.mag_filter

        self.p_r     = kwargs.r or 255
        self.p_g     = kwargs.g or 255
        self.p_b     = kwargs.b or 255
        self.p_a     = kwargs.a or 255

        return Filler.__init(self, kwargs)
    end,

    get_tex = function()
        return ffi.string(self.i_tex.name)
    end,

    get_tex_raw = function()
        return self.i_tex
    end,

    set_tex = function(file, alt)
        local tex = EAPI.texture_load(file)
        if    tex == notexture and alt then
              tex = EAPI.texture_load(alt)
        end
        self.i_tex   = tex
        needs_adjust = true
    end,

    set_tex_raw = function(tex)
        self.i_tex   = tex
        needs_adjust = true
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex
        return (tex.bpp < 32 or check_alpha_mask(tex, cx / self.p_w,
                                                      cy / self.p_h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        gl.BindTexture(gl.TEXTURE_2D, tex.id)

        if minf and minf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magf)
        end

        EAPI.varray_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        EAPI.varray_defvertex(2, gl.FLOAT)
        EAPI.varray_deftexcoord0(2, gl.FLOAT)
        EAPI.varray_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.p_w, self.p_h)
        EAPI.varray_end()

        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local min_w = self.p_min_w
        local min_h = self.p_min_h

        if min_w and min_w < 0 then
            min_w = abs(min_w) / EV.scr_h
        end

        if min_h and min_h < 0 then
            min_h = abs(min_h) / EV.scr_h
        end

        if  min_w == -1 then
            local w = self.parent
            while w.parent do
                  w = w.parent
            end
            min_w = w.p_w
        end
        if  min_h == -1 then
            min_h = 1
        end

        if  min_w == 0 or min_h == 0 then
            local tex, scrh = self.i_tex, EV.scr_h
            if  min_w == 0 then
                min_w = tex.w / scrh
            end
            if  min_h == 0 then
                min_h = tex.h / scrh
            end
        end

        self.p_w = max(self.p_w, min_w)
        self.p_h = max(self.p_h, min_h)
    end
}

local get_border_size = function(tex, size, vert)
    if size >= 0 then
        return size
    end

    return abs(n) / (vert and tex.ys or tex.xs)
end

local Cropped_Image = Image:clone {
    name = "Cropped_Image",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        Image.__init(self, kwargs)
        local tex = self.i_tex

        self.p_crop_x = get_border_size(tex, kwargs.crop_x or 0, false)
        self.p_crop_y = get_border_size(tex, kwargs.crop_y or 0, true)
        self.p_crop_w = get_border_size(tex, kwargs.crop_w or 1, false)
        self.p_crop_h = get_border_size(tex, kwargs.crop_h or 1, true)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex
        return (tex.bpp < 32 or check_alpha_mask(tex,
            self.p_crop_x + cx / self.p_w * self.p_crop_w,
            self.p_crop_y + cy / self.p_h * self.p_crop_h)) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        gl.BindTexture(gl.TEXTURE_2D, tex.id)

        if minf and minf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magf)
        end

        EAPI.varray_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        EAPI.varray_defvertex(2, gl.FLOAT)
        EAPI.varray_deftexcoord0(2, gl.FLOAT)
        EAPI.varray_begin(gl.TRIANGLE_STRIP)
        quadtri(sx, sy, self.p_w, self.p_h,
            self.p_crop_x, self.p_crop_y, self.p_crop_w, self.p_crop_h)
        EAPI.varray_end()

        return Object.draw(self, sx, sy)
    end
}

local Stretched_Image = Image:clone {
    name = "Stretched_Image",

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end
        if self.i_tex.bpp < 32 then return self end

        local mx, my, mw, mh, pw, ph = 0, 0, self.p_min_w, self.p_min_h,
                                             self.p_w,     self.p_h

        if     pw <= mw          then mx = cx / pw
        elseif cx <  mw / 2      then mx = cx / mw
        elseif cx >= pw - mw / 2 then mx = 1 - (pw - cx) / mw
        else   mx = 0.5 end

        if     ph <= mh          then my = cy / ph
        elseif cy <  mh / 2      then my = cy / mh
        elseif cy >= ph - mh / 2 then my = 1 - (ph - cy) / mh
        else   my = 0.5 end

        return check_alpha_mask(self.i_tex, mx, my) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        gl.BindTexture(gl.TEXTURE_2D, tex.id)

        if minf and minf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magf)
        end

        EAPI.varray_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        EAPI.varray_defvertex(2, gl.FLOAT)
        EAPI.varray_deftexcoord0(2, gl.FLOAT)
        EAPI.varray_begin(gl.QUADS)

        local mw, mh, pw, ph = self.p_min_w, self.p_min_h, self.p_w, self.p_h

        local splitw = (mw ~= 0 and min(mw, pw) or pw) / 2
        local splith = (mh ~= 0 and min(mh, ph) or ph) / 2
        local vy, ty = sy, 0

        for i = 1, 3 do
            local vh, th = 0, 0
            if i == 1 then
                if splith < ph - splith then
                    vh, th = splith, 0.5
                else
                    vh, th = ph, 1
                end
            elseif i == 2 then
                vh, th = ph - 2 * splith, 0
            elseif i == 3 then
                vh, th = splith, 0.5
            end

            local vx, tx = sx, 0

            for j = 1, 3 do
                local vw, tw = 0, 0
                if j == 1 then
                    if splitw < pw - splitw then
                        vw, tw = splitw, 0.5
                    else
                        vw, tw = pw, 1
                    end
                elseif j == 2 then
                    vw, tw = pw - 2 * splitw, 0
                elseif j == 3 then
                    vw, tw = splitw, 0.5
                end
                quad(vx, vy, vw, vh, tx, ty, tw, th)
                vx, tx = vx + vw, tx + tw
                if  tx >= 1 then break end
            end
            vy, ty = vy + vh, ty + th
            if  ty >= 1 then break end
        end

        EAPI.varray_end()

        return Object.draw(self, sx, sy)
    end
}

local Bordered_Image = Image:clone {
    name = "Bordered_Image",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        Image.__init(self, kwargs)

        self.p_tex_border    = get_border_size(self.i_tex,
                                               kwargs.tex_border or 0)
        self.p_screen_border = kwargs.screen_border or 0
    end,

    layout = function(self)
        Object.layout(self)

        local sb = self.p_screen_border
        self.p_w = max(self.p_w, 2 * sb)
        self.p_h = max(self.p_h, 2 * sb)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex

        if tex.bpp < 32 then
            return self
        end

        local mx, my, tb, sb = 0, 0, self.p_tex_border, self.p_screen_border
        local pw, ph = self.p_w, self.p_h

        if     cx <  sb      then mx = cx / sb * tb
        elseif cx >= pw - sb then mx = 1 - tb + (cx - (pw - sb)) / sb * tb
        else   mx = tb + (cx - sb) / (pw - 2 * sb) * (1 - 2 * tb) end

        if     cy <  sb      then my = cy / sb * tb
        elseif cy >= ph - sb then my = 1 - tb + (cy - (ph - sb)) / sb * tb
        else   my = tb + (cy - sb) / (ph - 2 * sb) * (1 - 2 * tb) end

        return check_alpha_mask(tex, mx, my) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        gl.BindTexture(gl.TEXTURE_2D, tex.id)

        if minf and minf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magf)
        end

        EAPI.varray_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        EAPI.varray_defvertex(2, gl.FLOAT)
        EAPI.varray_deftexcoord0(2, gl.FLOAT)
        EAPI.varray_begin(gl.QUADS)

        local vy, ty = sy, 0
        for i = 1, 3 do
            local vh, th = 0, 0
            if i == 2 then
                vh, th = self.p_h - 2 * sb, 1 - 2 * tb
            else
                vh, th = sb, tb
            end
            local vx, tx = sx, 0
            for j = 1, 3 do
                local vw, tw = 0, 0
                if j == 2 then
                    vw, tw = self.p_w - 2 * sb, 1 - 2 * tb
                else
                    vw, tw = sb, tb
                end
                quad(vx, vy, vw, vh, tx, ty, tw, th)
                vx, tx = vx + vw, tx + tw
            end
            vy, ty = vy + vh, ty + th
        end

        EAPI.varray_end()

        return Object.draw(self, sx, sy)
    end
}

local Tiled_Image = Image:clone {
    name = "Tiled_Image",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_tile_w = kwargs.tile_w or 0
        self.p_tile_h = kwargs.tile_h or 0

        return Image.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        local tex = self.i_tex

        if tex.bpp < 32 then return self end

        local tw, th = self.p_tile_w, self.p_tile_h
        local dx, dy = cx % tw, cy % th

        return check_alpha_mask(tex, dx / tw, dy / th) and self
    end,

    draw = function(self, sx, sy)
        local minf, magf, tex = self.p_min_filter,
                                self.p_mag_filter, self.i_tex

        gl.BindTexture(gl.TEXTURE_2D, tex.id)

        if minf and minf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minf)
        end
        if magf and magf ~= 0 then
            gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magf)
        end

        EAPI.varray_color4ub(self.p_r, self.p_g, self.p_b, self.p_a)

        local pw, ph, tw, th = self.p_w, self.p_h, self.p_tile_w, self.p_tile_h

        -- we cannot use the built in OpenGL texture
        -- repeat with clamped textures
        if tex.clamp ~= 0 then
            local dx, dy = 0, 0
            EAPI.varray_defvertex(2, gl.FLOAT)
            EAPI.varray_deftexcoord0(2, gl.FLOAT)
            EAPI.varray_begin(gl.QUADS)
            while dx < pw do
                while dy < ph do
                    local dw, dh = min(tw, pw - dx), min(th, ph - dy)
                    quad(sx + dx, sy + dy, dw, dh, 0, 0, dw / tw, dh / th)
                    dy = dy + th
                end
                dx, dy = dy + tw, 0
            end
            EAPI.varray_end()
        else
            EAPI.varray_defvertex(2, gl.FLOAT)
            EAPI.varray_deftexcoord0(2, gl.FLOAT)
            EAPI.varray_begin(gl.TRIANGLE_STRIP)
            quadtri(sx, sy, pw, ph, 0, 0, pw / tw, ph / th)
            EAPI.varray_end()
        end

        return Object.draw(self, sx, sy)
    end
}

local Slot_Viewer = Filler:clone {
    name = "Slot_Viewer",

    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.p_slot = kwargs.slot or 0

        return Filler.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o or not CAPI.hastexslot(self.p_slot) then return o end
        return CAPI.checkvslot(self.p_slot) and self
    end,

    draw = function(self, sx, sy)
        CAPI.texture_draw_slot(self.p_slot, self.p_w, self.p_h, sx, sy)
        return Object.draw(self, sx, sy)
    end
}

-- default size of text in terms of rows per screenful
var.new("uitextrows", var.INT, 1, 40, 200, var.PERSIST)

local Label = Object:clone {
    name = "Label",

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_text  = kwargs.text  or ""
        self.p_scale = kwargs.scale or  1
        self.p_wrap  = kwargs.wrap  or -1
        self.p_r     = kwargs.r or 255
        self.p_g     = kwargs.g or 255
        self.p_b     = kwargs.b or 255
        self.p_a     = kwargs.a or 255

        self.i_w = ffi.new("int[1]")
        self.i_h = ffi.new("int[1]")

        return Object.__init(self, kwargs)
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw_scale = function(self)
        return self.p_scale / (EV["fonth"] * EV["uitextrows"])
    end,

    draw = function(self, sx, sy)
        EAPI.hudmatrix_push()

        local k = self:draw_scale()
        EAPI.hudmatrix_scale(k, k, 1)
        EAPI.hudmatrix_flush()

        local w = self.p_wrap
        EAPI.gui_draw_text(self.p_text, sx / k, sy / k,
            self.p_r, self.p_g, self.p_b, self.p_a, -1, w <= 0 and -1 or w / k)

        EAPI.varray_color4f(1, 1, 1, 1)
        EAPI.hudmatrix_pop()

        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local k = self:draw_scale()

        EAPI.gui_text_bounds(self.p_text, self.i_w, self.i_h,
            self.p_wrap <= 0 and -1 or self.p_wrap / k)

        if self.p_wrap <= 0 then
            self.p_w = max(self.p_w, self.i_w[0] * k)
        else
            self.p_w = max(self.p_w, min(self.p_wrap, self.i_w[0] * k))
        end

        self.p_h = max(self.p_h, self.i_h[0] * k)
    end
}

local textediting   = nil
local refreshrepeat = 0

local clipboard = {}

local Text_Editor = Object:clone {
    name = "Text_Editor",
    type = TYPE_TEXT_EDITOR,

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        local length = kwargs.length or 0
        local height = kwargs.height or 1
        local scale  = kwargs.scale  or 1

        self.lastaction = EAPI.totalmillis
        self.scale      = scale

        self.i_offset_h = 0
        self.i_offset_v = 0

        self.name     = kwargs.name
        self.filename = nil

        -- cursor position - ensured to be valid after a region() or
        -- currentline()
        self.cx = 0
        self.cy = 0
        -- selection mark, mx = -1 if following cursor - avoid direct access,
        -- instead use region()
        self.mx = -1
        self.my = -1
        -- maxy = -1 if unlimited lines, 1 if single line editor
        self.maxx = length <  0 and -1 or length
        self.maxy = height <= 0 and  1 or -1

        self.scrolly = 0 -- vertical scroll offset

        self.line_wrap = length < 0
        -- required for up/down/hit/draw/bounds
        self.pixel_width  = math.abs(length) * EV.fontw
        -- -1 for variable size, i.e. from bounds
        self.pixel_height = -1

        self.password = kwargs.is_password or false

        -- must always contain at least one line
        self.lines = { kwargs.value or "" }

        self._w = ffi.new("int[1]")
        self._h = ffi.new("int[1]")

        if length < 0 and height <= 0 then
            EAPI.gui_text_bounds(self.lines[1], self._w,
                self._h, self.pixel_width)
            self.pixel_height = self._h[0]
        else
            self.pixel_height = EV.fonth * math.max(height, 1)
        end

        return Object.__init(self, kwargs)
    end,

    clear = function(self)
        if self == textediting then
            textediting = nil
        end

        refreshrepeat = refreshrepeat + 1

        return Object:clear()
    end,

    edit_clear = function(self, init)
        self.cx = 0
        self.cy = 0

        self:mark(false)

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
        self.cx = 0
        self.cy = 0
        self.mx = 1 / 0
        self.my = 1 / 0
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
        if     sy >  ey             then sy, ey, sx, ex = ey, sy, ex, sx
        elseif sy == ey and sx > ex then sx, ex         = ex, sx end

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

    copy_selection_to = function(self, b)
        if self == b then return nil end

        b:clear(false)
        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            if b.maxy ~= -1 and #b.lines >= b.maxy then break end

            local y = sy + i
            local line = self.lines[y]

            if y - 1 == sy then line = line:sub(sx + 1) end
            b.lines[#b.lines + 1] = line
        end

        if #b.lines == 0 then b.lines = { "" } end
    end,

    to_string = function(self)
        return table.concat(self.lines, "\n")
    end,

    selection_to_string = function(self)
        local buf = {}
        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            local y = sy + i
            local line = self.lines[y]

            if y - 1 == sy then line = line:sub(sx + 1) end

            buf[#buf + 1] = line
            buf[#buf + 1] = "\n"
        end

        return table.concat(buf)
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
            self:mark(false)
            return false
        end

        if sy == ey then
            if sx == 0 and ex == #self.lines[ey + 1] then
                self:remove_lines(sy + 1, 1)
            else self.lines[sy + 1]:del(
                sx + 1, ex - sx)
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
                self.lines[sy + 1]:del(sx + 1,
                    #self.lines[sy] - sx)
            end
        end

        if #self.lines == 0 then self.lines = { "" } end
        self:mark(false)

        self.cx = sx
        self.cy = sy

        local current = self:current_line()
        if self.cx > #current and self.cy < #self.lines - 1 then
            self.lines[self.cy + 1] = table.concat {
                self.lines[self.cy + 1], self.lines[self.cy + 2] }
            self:remove_lines(self.cy + 2, 1)
        end

        return true
    end,

    insert = function(self, ch)
        self:del()
        local current = self:current_line()

        if ch == "\n" then
            if self.maxy == -1 or self.cy < self.maxy - 1 then
                local newline = current:sub(self.cx + 1)
                current = current:sub(1, self.cx)
                self.cy = math.min(#self.lines, self.cy + 1)
                table.insert(self.lines, self.cy + 1, newline)
            else
                current = current:sub(1, self.cx)
            end
            self.cx = 0
        else
            local len = #current
            if self.maxx >= 0 and len > self.maxx - 1 then
                len = self.maxx - 1 end
            if self.cx <= len then
                self.cx = self.cx + 1
                if #ch > 1 then
                    current = current:insert(self.cx, ch:sub(1, 1))
                    self.lines[self.cy + 1] = current
                    self:insert(ch:sub(2))
                else
                    current = current:insert(self.cx, ch)
                    self.lines[self.cy + 1] = current
                end
            end
        end
    end,

    insert_all_from = function(self, b)
        if self == b then return nil end

        self:del()

        if #b.lines == 1 or self.maxy == 1 then
            local current = self:current_line()
            local str  = b.lines[1]
            local slen = #str

            if self.maxx >= 0 and slen + self.cx > self.maxx then
                slen = self.maxx - self.cx
            end

            if slen > 0 then
                local len = #current
                if self.maxx >= 0 and slen + self.cx + len > self.maxx then
                    len = math.max(0, self.maxx - (self.cx + slen))
                end

                current = current:insert(self.cx + 1, slen)
                self.cx = self.cx + slen
            end

            self.lines[self.cy + 1] = current
        else for i = 1, #b.lines do
            if i == 1 then
                self.cy = self.cy + 1
                local newline = self.lines[self.cy]:sub(self.cx + 1)
                self.lines[self.cy] = self.lines[self.cy]:sub(
                    1, self.cx):insert(self.cy + 1, newline)
            elseif i >= #b.lines then
                self.cx = #b.lines[i]
                self.lines[self.cy + 1] = table.concat {
                    b.lines[i], self.lines[self.cy + 1] }
            elseif self.maxy < 0 or #self.lines < self.maxy then
                self.cy = self.cy + 1
                table.insert(self.lines, self.cy, b.lines[i])
            end
        end end
    end,

    movement_mark = function(self)
        self:scroll_on_screen()
        if band(EAPI.input_get_modifier_state(),
            EAPI.INPUT_MOD_SHIFT) ~= 0 then
                if not self:region() then self:mark(true) end
        else
            self:mark(false)
        end
    end,

    scroll_on_screen = function(self)
        self:region()
        self.scrolly = math.clamp(self.scrolly, 0, self.cy)
        local h = 0
        for i = self.cy + 1, self.scrolly + 1, -1 do
            local width, height = ffi.new "int[1]", ffi.new "int[1]"
            EAPI.gui_text_bounds(self.lines[i], width, height,
                self.line_wrap and self.pixel_width or -1)
            height = height[0]
            if h + height > self.pixel_height then
                self.scrolly = i
                break
            end
            h = h + height
        end
    end,

    input = function(self, str)
        for ch in str:gmatch(".") do self:insert(ch) end
    end,

    edit_key = function(self, code)
        local mod_keys
        if ffi.os == "OSX" then
            mod_keys = EAPI.INPUT_MOD_META
        else
            mod_keys = EAPI.INPUT_MOD_CTRL
        end

        switch(code,
            case(EAPI.INPUT_KEY_UP, function()
                self:movement_mark()
                if self.line_wrap then
                    local x, y = ffi.new "int[1]", ffi.new "int[1]"
                    local str = self:current_line()
                    EAPI.gui_text_pos(str, self.cx + 1, x, y, self.pixel_width)
                    if y > 0 then
                        self.cx = EAPI.gui_text_visible(str, x, y - FONTH,
                            self.pixel_width)
                        self:scroll_on_screen()
                        return nil
                    end
                end
                self.cy = self.cy - 1
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_DOWN, function()
                self:movement_mark()
                if self.line_wrap then
                    local str = self:current_line()
                    local x, y = ffi.new "int[1]", ffi.new "int[1]"
                    local width, height = ffi.new "int[1]", ffi.new "int[1]"
                    EAPI.gui_text_pos(str, self.cx, x, y, self.pixel_width)
                    EAPI.gui_text_bounds(str, width, height, self.pixel_width)
                    x, y, height = x[0], y[0], height[0]
                    y = y + EV.fonth
                    if y < height then
                        self.cx = EAPI.gui_text_visible(str, x, y, self.pixel_width)
                        self:scroll_on_screen()
                        return nil
                    end
                end
                self.cy = self.cy + 1
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_MOUSE4, function()
                self.scrolly = self.scrolly - 3
            end),

            case(EAPI.INPUT_KEY_MOUSE5, function()
                self.scrolly = self.scrolly + 3
            end),

            case(EAPI.INPUT_KEY_PAGEUP, function()
                self:movement_mark()
                if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 0
                else
                    self.cy = self.cy - self.pixel_height / EV.fonth
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_PAGEDOWN, function()
                self:movement_mark()
                if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 1 / 0
                else
                    self.cy = self.cy + self.pixel_height / EV.fonth
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_HOME, function()
                self:movement_mark()
                self.cx = 0
                if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 0
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_END, function()
                self:movement_mark()
                self.cx = 1 / 0
                if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 1 / 0
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_LEFT, function()
                self:movement_mark()
                if     self.cx > 0 then self.cx = self.cx - 1
                elseif self.cy > 0 then
                    self.cx = 1 / 0
                    self.cy = self.cy - 1
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_RIGHT, function()
                self:movement_mark()
                if self.cx < #self.lines[self.cy + 1] then
                    self.cx = self.cx + 1
                elseif self.cy < #self.lines - 1 then
                    self.cx = 0
                    self.cy = self.cy + 1
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_DELETE, function()
                if not self:del() then
                    local current = self:current_line()
                    if self.cx < #current then
                        current = current:del(self.cx + 1, 1)
                    elseif self.cy < #self.lines - 1 then
                        -- combine with next line
                        current = table.concat {
                            current, self.lines[self.cy + 2] }
                        self:remove_lines(self.cy + 2, 1)
                    end
                    self.lines[self.cy + 1] = current
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_BACKSPACE, function()
                if not self:del() then
                    local current = self:current_line()
                    if self.cx > 0 then
                        self.cx = self.cx - 1
                        self.lines[self.cy + 1] = current:del(self.cx + 1, 1)
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
            end),

            case({  EAPI.INPUT_KEY_LSHIFT, EAPI.INPUT_KEY_RSHIFT,
                    EAPI.INPUT_KEY_LCTRL,  EAPI.INPUT_KEY_RCTRL,
                    EAPI.INPUT_KEY_LMETA,  EAPI.INPUT_KEY_RMETA },
                function() end),

            case(EAPI.INPUT_KEY_RETURN, function()
                -- maintain indentation
                local str = self:current_line()
                self:insert "\n"
                for c in str:gmatch "." do if c == " " or c == "\t" then
                    self:insert(c) else break
                end end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_TAB, function()
                local b, sx, sy, ex, ey = self:region()
                if b then
                    for i = sy, ey do
                        if band(EAPI.input_get_modifier_state(), EAPI.INPUT_MOD_SHIFT) ~= 0 then
                            local rem = 0
                            for j = 1, math.min(4, #self.lines[i + 1]) do
                                if self.lines[i + 1]:sub(j, j) == " " then
                                    rem = rem + 1
                                else
                                    if self.lines[i + 1]:sub(j, j) == "\t" and j == 0 then
                                        rem = rem + 1
                                    end
                                    break
                                end
                            end
                            self.lines[i + 1] = self.lines[i + 1]:del(1, rem)
                            if i == self.my then self.mx = self.mx - (rem > self.mx and self.mx or rem) end
                            if i == self.cy then self.cx = self.cx -  rem end
                        else
                            self.lines[i + 1] = "\t" .. self.lines[i + 1]
                            if i == self.my then self.mx = self.mx + 1 end
                            if i == self.cy then self.cx = self.cx + 1 end
                        end
                    end
                end
                self:scroll_on_screen()
            end),

            case({ EAPI.INPUT_KEY_A, EAPI.INPUT_KEY_X, EAPI.INPUT_KEY_C, EAPI.INPUT_KEY_V }, function()
                if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
                    return nil
                end
                self:scroll_on_screen()
            end),

            default(function()
                self:scroll_on_screen()
            end))

        if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
            if code == EAPI.INPUT_KEY_A then
                self:select_all()
            elseif code == EAPI.INPUT_KEY_X or code == EAPI.INPUT_KEY_C then
                clipboard = {}

                local sx, sy, ex, ey = select(2, self:region())

                for i = 1, 1 + ey - sy do
                    local y = sy + i
                    local line = self.lines[y]

                    if y - 1 == sy then line = line:sub(sx + 1) end
                    clipboard[#clipboard + 1] = line
                end

                if #clipboard == 0 then clipboard = { "" } end

                if code == EAPI.INPUT_KEY_X then self:del() end
            elseif code == EAPI.INPUT_KEY_V then
                self:del()

                if #clipboard == 1 or self.maxy == 1 then
                    local current = self:current_line()
                    local str  = clipboard[1]
                    local slen = #str

                    if self.maxx >= 0 and slen + self.cx > self.maxx then
                        slen = self.maxx - self.cx
                    end

                    if slen > 0 then
                        local len = #current
                        if self.maxx >= 0 and slen + self.cx + len > self.maxx then
                            len = math.max(0, self.maxx - (self.cx + slen))
                        end

                        current = current:insert(self.cx + 1, slen)
                        self.cx = self.cx + slen
                    end

                    self.lines[self.cy + 1] = current
                else for i = 1, #clipboard do
                    if i == 1 then
                        self.cy = self.cy + 1
                        local newline = self.lines[self.cy]:sub(self.cx + 1)
                        self.lines[self.cy] = self.lines[self.cy]:sub(
                            1, self.cx):insert(self.cy + 1, newline)
                    elseif i >= #clipboard then
                        self.cx = #clipboard[i]
                        self.lines[self.cy + 1] = table.concat {
                            clipboard[i], self.lines[self.cy + 1] }
                    elseif self.maxy < 0 or #self.lines < self.maxy then
                        self.cy = self.cy + 1
                        table.insert(self.lines, self.cy, clipboard[i])
                    end
                end end
            end
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
            local width, height = ffi.new "int[1]", ffi.new "int[1]"
            EAPI.gui_text_bounds(self.lines[i], width, height, max_width)
            height = height[0]
            if h + height > self.pixel_height then break end
            if hity >= h and hity <= h + height then
                local x = EAPI.gui_text_visible(self.lines[i], hitx, hity - h, max_width)
                if dragged then
                    self.mx = x
                    self.my = i - 1
                else
                    self.cx = x
                    self.cy = i - 1
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
            local width, height = ffi.new "int[1]", ffi.new "int[1]"
            EAPI.gui_text_bounds(self.lines[slines], width, height, max_width)
            height = height[0]
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
        clipboard = {}

        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            local y = sy + i
            local line = self.lines[y]

            if y - 1 == sy then line = line:sub(sx + 1) end
            clipboard[#clipboard + 1] = line
        end

        if #clipboard == 0 then clipboard = { "" } end
    end,

    paste = function(self)
        self:del()

        if #clipboard == 1 or self.maxy == 1 then
            local current = self:current_line()
            local str  = clipboard[1]
            local slen = #str

            if self.maxx >= 0 and slen + self.cx > self.maxx then
                slen = self.maxx - self.cx
            end

            if slen > 0 then
                local len = #current
                if self.maxx >= 0 and slen + self.cx + len > self.maxx then
                    len = math.max(0, self.maxx - (self.cx + slen))
                end

                current = current:insert(self.cx + 1, slen)
                self.cx = self.cx + slen
            end

            self.lines[self.cy + 1] = current
        else for i = 1, #clipboard do
            if i == 1 then
                self.cy = self.cy + 1
                local newline = self.lines[self.cy]:sub(self.cx + 1)
                self.lines[self.cy] = self.lines[self.cy]:sub(
                    1, self.cx):insert(self.cy + 1, newline)
            elseif i >= #clipboard then
                self.cx = #clipboard[i]
                self.lines[self.cy + 1] = table.concat {
                    clipboard[i], self.lines[self.cy + 1] }
            elseif self.maxy < 0 or #self.lines < self.maxy then
                self.cy = self.cy + 1
                table.insert(self.lines, self.cy, clipboard[i])
            end
        end end
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
            local dragged = (
                max(abs(cx - self.i_offset_h), abs(cy - self.i_offset_v)) >
                    (EV["fontw"] / 4) * self.scale /
                        (EV["fonth"] * EV.uitextrows)
            )
            self:hit(
                floor(cx * (EV["fonth"] * EV.uitextrows) /
                    self.scale - EV["fontw"] / 2
                ),
                floor(cy * (EV["fonth"] * EV.uitextrows) /
                    self.scale
                ),
                dragged
            )
        end
    end,

    clicked = function(self, cx, cy)
        set_focus(self)
        self:mark()
        self.i_offset_h = cx
        self.i_offset_v = cy

        return Object.clicked(self, cx, cy)
    end,

    key_hover = function(self, code, isdown)
        if code == EAPI.INPUT_KEY_LEFT   or code == EAPI.INPUT_KEY_RIGHT or
           code == EAPI.INPUT_KEY_UP     or code == EAPI.INPUT_KEY_DOWN  or
           code == EAPI.INPUT_KEY_MOUSE4 or code == EAPI.INPUT_KEY_MOUSE5
        then
            if isdown then self:edit_key(code) end
            return true
        end
        return Object.key_hover(self, code, isdown)
    end,

    key = function(self, code, isdown)
        if Object.key(self, code, isdown) then return true end
        if not is_focused(self) then return false end

        if code == EAPI.INPUT_KEY_RETURN or code == EAPI.INPUT_KEY_KP_ENTER
        then
            if self.maxy == 1 then
                set_focus(nil)
                return true
            end
        elseif code == EAPI.INPUT_KEY_HOME      or
               code == EAPI.INPUT_KEY_END       or
               code == EAPI.INPUT_KEY_PAGEUP    or
               code == EAPI.INPUT_KEY_PAGEDOWN  or
               code == EAPI.INPUT_KEY_DELETE    or
               code == EAPI.INPUT_KEY_BACKSPACE or
               code == EAPI.INPUT_KEY_LSHIFT    or
               code == EAPI.INPUT_KEY_RSHIFT    or
               code == EAPI.INPUT_KEY_LCTRL     or
               code == EAPI.INPUT_KEY_RCTRL     or
               code == EAPI.INPUT_KEY_LMETA     or
               code == EAPI.INPUT_KEY_RMETA
        then local pass
        else
            local axcv = (code == EAPI.INPUT_KEY_A) or
                         (code == EAPI.INPUT_KEY_X) or
                         (code == EAPI.INPUT_KEY_C) or
                         (code == EAPI.INPUT_KEY_V)

            if not (axcv and CAPI.is_modifier_pressed()) then
                return false
            end
        end

        if isdown then self:edit_key(code) end
        return true
    end,

    reset_value = function(self) end,

    layout = function(self)
        Object.layout(self)

        if not is_focused(self) then
            self:reset_value()
        end

        if self.line_wrap and self.maxy == 1 then
            local r = EAPI.gui_text_bounds(self.lines[1],
                self._w, self._h, self.pixel_width)
            self.pixel_height = self._h[0]
        end

        self.p_w = max(self.p_w, (self.pixel_width + EV.fontw) *
            self.scale / (EV.fonth * EV.uitextrows))

        self.p_h = max(self.p_h, self.pixel_height *
            self.scale / (EV.fonth * EV.uitextrows)
        )
    end,

    draw = function(self, sx, sy)
        EAPI.hudmatrix_push()

        EAPI.hudmatrix_translate(sx, sy, 0)
        local s = self.scale / (EV.fonth * EV.uitextrows)
        EAPI.hudmatrix_scale(s, s, 1)
        EAPI.hudmatrix_flush()

        local x, y, color, hit = EV.fontw / 2, 0, 0xFFFFFF, is_focused(self)

        local max_width = self.line_wrap and self.pixel_width or -1

        local selection, sx, sy, ex, ey = self:region()

        self.scrolly = math.clamp(self.scrolly, 0, #self.lines - 1)

        if selection then
            -- convert from cursor coords into pixel coords
            local psx, psy, pex, pey = ffi.new "int[1]", ffi.new "int[1]",
                                       ffi.new "int[1]", ffi.new "int[1]"
            EAPI.gui_text_pos(self.lines[sy + 1], sx, psx, psy, max_width)
            EAPI.gui_text_pos(self.lines[ey + 1], ex, pex, pey, max_width)
            psx, psy, pex, pey = psx[0], psy[0], pex[0], pey[0]
            local maxy = #self.lines
            local h = 0
            for i = self.scrolly + 1, maxy do
                local width, height = ffi.new "int[1]", ffi.new "int[1]"
                EAPI.gui_text_bounds(self.lines[i], width, height, max_width)
                width, height = width[0], height[0]
                if h + height > self.pixel_height then
                    maxy = i - 1
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
                    pey = self.pixel_height - EV.fonth
                    pex = self.pixel_width
                end

                EAPI.base_shader_hudnotexture_set()
                EAPI.varray_color3ub(0xA0, 0x80, 0x80)
                EAPI.varray_defvertex(2, gl.FLOAT)
                EAPI.varray_begin(gl.QUADS)
                if psy == pey then
                    EAPI.varray_attrib2f(x + psx, y + psy)
                    EAPI.varray_attrib2f(x + pex, y + psy)
                    EAPI.varray_attrib2f(x + pex, y + pey + EV.fonth)
                    EAPI.varray_attrib2f(x + psx, y + pey + EV.fonth)
                else
                    EAPI.varray_attrib2f(x + psx,              y + psy)
                    EAPI.varray_attrib2f(x + psx,              y + psy + EV.fonth)
                    EAPI.varray_attrib2f(x + self.pixel_width, y + psy + EV.fonth)
                    EAPI.varray_attrib2f(x + self.pixel_width, y + psy)
                    if (pey - psy) > EV.fonth then
                        EAPI.varray_attrib2f(x,                    y + psy + EV.fonth)
                        EAPI.varray_attrib2f(x + self.pixel_width, y + psy + EV.fonth)
                        EAPI.varray_attrib2f(x + self.pixel_width, y + pey)
                        EAPI.varray_attrib2f(x,                    y + pey)
                    end
                    EAPI.varray_attrib2f(x,       y + pey)
                    EAPI.varray_attrib2f(x,       y + pey + EV.fonth)
                    EAPI.varray_attrib2f(x + pex, y + pey + EV.fonth)
                    EAPI.varray_attrib2f(x + pex, y + pey)
                end
                EAPI.varray_end()
                EAPI.base_shader_hud_set()
            end
        end

        local h = 0
        for i = self.scrolly + 1, #self.lines do
            local width, height = ffi.new "int[1]", ffi.new "int[1]"
            EAPI.gui_text_bounds(self.lines[i], width, height, max_width)
            height = height[0]
            if h + height > self.pixel_height then
                break
            end
            local r, g, b = hextorgb(color)
            EAPI.gui_draw_text(self.password and ("*"):rep(#self.lines[i])
                or self.lines[i], x, y + h, r, g, b, 0xFF,
                (hit and (self.cy == i - 1)) and self.cx or -1, max_width)

            -- line wrap indicator
            if self.line_wrap and height > EV.fonth then
                EAPI.base_shader_hudnotexture_set()
                EAPI.varray_color3ub(0x80, 0xA0, 0x80)
                EAPI.varray_defvertex(2, gl.FLOAT)
                EAPI.varray_begin(gl.GL_TRIANGLE_STRIP)
                EAPI.varray_attrib2f(x,                y + h + EV.fonth)
                EAPI.varray_attrib2f(x,                y + h + height)
                EAPI.varray_attrib2f(x - EV.fontw / 2, y + h + EV.fonth)
                EAPI.varray_attrib2f(x - EV.fontw / 2, y + h + height)
                EAPI.varray_end()
                EAPI.base_shader_hud_set()
            end

            h = h + height
        end

        EAPI.hudmatrix_pop()

        return Object.draw(self, sx, sy)
    end
}

local Field = Text_Editor:clone {
    name = "Field",

    __init = function(self, kwargs)
        kwargs   = kwargs or {}

        self.p_value = kwargs.value or ""

        if kwargs.var then
            local varn = kwargs.var
            self.i_var = varn

            if not var.exists(varn) then
                var.new(varn, EAPI.VAR_S, self.p_value)
            end
        end

        return Text_Editor.__init(self, kwargs)
    end,

    commit = function(self)
        local val = self.lines[1]
        self.value = val

        local varn = self.i_var
        if varn then update_var(varn, val) end
    end,

    key_hover = function(self, code, isdown)
               return self:key(code, isdown)
    end,

    key = function(self, code, isdown)
        if Object.key(self, code, isdown) then return true end
        if not is_focused(self) then return false end

        if code == EAPI.INPUT_KEY_ESCAPE then
            set_focus(nil)
            return true
        elseif code == EAPI.INPUT_KEY_KP_ENTER or
               code == EAPI.INPUT_KEY_RETURN   or
               code == EAPI.INPUT_KEY_TAB
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

    reset_value = function(self)
        local str = self.p_value
        if self.lines[1] ~= str then self:edit_clear(str) end
    end
}

local Mover = Object:clone {
    name = "Mover",
    type = TYPE_MOVER,

    link = function(self, win)
        self.win = win
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        local w = self.win
        local u = w.p_parent
        local c = u.p_children
        local n = table.find(c, w)
        local l = #c

        if n ~= l then
            local o = c[l]
            c[l] = w
            c[n] = o
        end

        return self:target(cx, cy) and self
    end,

    can_move = function(self)
        local wp = self.win.p_parent

        -- no parent means world; we don't need checking for non-mdi windows
        if not wp.p_parent then
            return true
        end

        local rx, ry, p = self.p_x, self.p_y, wp
        while p do
            rx = rx + p.p_x
            ry = ry + p.p_y
            local  pp = p.p_parent
            if not pp then break end
            p    = pp
        end

        -- world has no parents :( but here we can re-use it
        local w = p.p_w
        -- transform x position of the cursor (which ranges from 0 to 1)
        -- into proper UI positions (that are dependent on screen width)
        local cx = cursor_x * w - (w - 1) / 2
        local cy = cursor_y

        if cx < rx or cy < ry or cx > (rx + wp.p_w) or cy > (ry + wp.p_h) then
            -- avoid bugs; stop moving when cursor is outside
            clicked = nil
            return false
        end

        return true
    end,

    pressing = function(self, cx, cy)
        local w = self.win
        if w and w.p_floating and is_clicked(self) and self:can_move() then
            w.p_fx, w.p_x = w.p_fx + cx, w.p_x + cx
            w.p_fy, w.p_y = w.p_fy + cy, w.p_y + cy
        end
    end
}

local Resizer = Object:clone {
    name = "Resizer",
    type = TYPE_RESIZER,

    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.p_horizontal = kwargs.horizontal ~= false and true or false
        self.p_vertical   = kwargs.vertical   ~= false and true or false

        return Object.__init(self, kwargs)
    end,

    link = function(self, win)
        self.win = win
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        local w = self.win
        local u = w.p_parent
        local c = u.p_children
        local n = table.find(c, w)
        local l = #c

        if n ~= l then
            local o = c[l]
            c[l] = w
            c[n] = o
        end

        return self:target(cx, cy) and self
    end,

    can_resize = function(self)
        local wp = self.win.p_parent

        if not wp.p_parent then
            return true
        end

        local rx, ry, p = self.p_x, self.p_y, wp
        while p do
            rx = rx + p.p_x
            ry = ry + p.p_y
            local  pp = p.p_parent
            if not pp then break end
            p    = pp
        end

        local w = p.p_w

        local cx = cursor_x * w - (w - 1) / 2
        local cy = cursor_y

        if cx < rx or cy < ry or cx > (rx + wp.p_w) or cy > (ry + wp.p_h) then
            clicked = nil
            return false
        end

        return true
    end,

    pressing = function(self, cx, cy)
        local w = self.win
        if w and w.p_floating and is_clicked(self) and self:can_resize() then
            if self.p_horizontal then
                w.p_fw, w.p_w = w.p_fw + cx, w.p_w + cx
            end
            if self.p_vertical then
                w.p_fh, w.p_h = w.p_fh + cy, w.p_h + cy
            end
            needs_adjust = true
        end
    end
}

local ext = external

ext.cursor_reset = function()
    if EV.editing ~= 0 or #world.p_children == 0 then
        cursor_x = 0.5
        cursor_y = 0.5
    end
end

var.new("cursorsensitivity", var.FLOAT, 0.001, 1, 1000)

ext.cursor_move = function(dx, dy)
    if (#world.p_children == 0 or not world.focus_children(world)) and
        CAPI.is_mouselooking()
    then
        return false
    end

    local scale = 500 / EV.cursorsensitivity

    cursor_x = clamp(cursor_x + dx * (EV.scr_h / (EV.scr_w * scale)), 0, 1)
    cursor_y = clamp(cursor_y + dy / scale, 0, 1)

    return true
end

local cursor_exists = function(targeting)
    if not world.focus_children(world) then
        return false
    end

    if #world.p_children ~= 0 then
        if not targeting then return true, true end
        if world and world.target(world, cursor_x * world.p_w, cursor_y * world.p_h) then
            return true
        end
    end

    return false
end
ext.cursor_exists = cursor_exists

ext.cursor_get_position = function()
    if #world.p_children ~= 0 or not CAPI.is_mouselooking() then
        return cursor_x, cursor_y
    else
        return 0.5, 0.5
    end
end

ext.input_text = function(str)
    if textediting then
        textediting:input(str)
        return true
    end
    return false
end

ext.input_keypress = function(code, isdown)
    if not cursor_exists() then return false end

    if code == EAPI.INPUT_KEY_MOUSE5 or code == EAPI.INPUT_KEY_MOUSE4 or
       code == EAPI.INPUT_KEY_LEFT   or code == EAPI.INPUT_KEY_RIGHT  or
       code == EAPI.INPUT_KEY_DOWN   or code == EAPI.INPUT_KEY_UP
    then
        if (focused  and  focused:key_hover(code, isdown)) or
           (hovering and hovering:key_hover(code, isdown))
        then return true end
        return false
    elseif code == EAPI.INPUT_KEY_MOUSE1 then
        if isdown then
            clicked = world:click(cursor_x * world.p_w, cursor_y * world.p_h)
            if clicked then clicked:clicked(click_x, click_y) end
        else
            clicked = nil
        end
        return true
    end

    local  ret = world:key(code, isdown)
    if     ret == nil and _ then return _(self, code, down) end
    return ret
end

ext.gui_clear = function()
    if  EAPI.gui_mainmenu and CAPI.isconnected() then
        EAPI.gui_set_mainmenu(false)

        world:hide_children()
        worlds = { world }
    end

    if not _ then return nil end
    return _(self)
end

local register_world = function(w, pos)
    if pos then
        worlds[math.min(pos, #worlds + 1)] = w
        world = w
    else
        worlds[#worlds + 1] = w
    end

    return w
end

local main

ext.gl_render = function()
    for i = 1, #worlds do
        local w = worlds[i]

        if #w.p_children ~= 0 then
            EAPI.hudmatrix_ortho(w.p_x, w.p_x + w.p_w, w.p_y + w.p_h, w.p_y, -1, 1)
            EAPI.hudmatrix_reset()
            EAPI.base_shader_hud_set()

            gl.Enable(gl.BLEND)
            gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

            EAPI.varray_color3f(1, 1, 1)
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

            local wh = cursor_exists() or
                not CAPI.is_mouselooking()

            if wh then
                local  pointer = hovering and hovering.pointer or w.p_pointer
                if     pointer then
                    local d    = w.p_w
                    local x, y = cursor_x * d - max((d - 1) / 2, 0), cursor_y

                    if pointer.type == TYPE_IMAGE then
                        local tex, scrh = pointer.i_tex, EV.scr_h
                        local wh, hh    = tex.w / scrh / 2, tex.h / scrh / 2

                        pointer:draw(x - wh, y - hh)
                    else
                        pointer:draw(x, y)
                    end
                end
            end

            gl.Disable(gl.BLEND)
            EAPI.varray_disable()
        end
    end

    if not _ then return nil end
    return _(self)
end

local needsapply = {}

var.new("applydialog", var.INT, 0, 1, 1, var.PERSIST)

ext.change_add = function(desc, ctype)
    if EV["applydialog"] == 0 then return nil end

    for i, v in pairs(needsapply) do
        if v.desc == desc then return nil end
    end

    needsapply[#needsapply + 1] = { ctype = ctype, desc = desc }
    LAPI.GUI.show_changes()
end

ext.changes_clear = function(ctype)
    ctype = ctype or bor(EAPI.BASE_CHANGE_GFX, EAPI.BASE_CHANGE_SOUND)

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
end

ext.changes_apply = function()
    local changetypes = 0
    for i, v in pairs(needsapply) do
        changetypes = bor(changetypes, v.ctype)
    end

    if band(changetypes, EAPI.BASE_CHANGE_GFX) ~= 0 then
        EAPI.base_reset_renderer()
    end

    if band(changetypes, EAPI.BASE_CHANGE_SOUND) ~= 0 then
        EAPI.base_reset_sound()
    end

    if band(changetypes, EAPI.BASE_CHANGE_SHADERS) ~= 0 then
        CAPI.resetshaders()
    end
end

ext.changes_get = function()
    return table.map(needsapply, function(v) return v.desc end)
end

ext.frame_start = function()
    if not main then main = signal.emit(world, "get_main") end

    if EAPI.gui_mainmenu and not CAPI.isconnected(true) and not main.p_visible then
        main.visible = true
    end

    if needs_adjust then
        world:layout()
        needs_adjust = false
    end

    was_hovering = hovering
    was_clicked  = clicked

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

    if was_hovering ~= hovering or was_clicked ~= clicked then
        world:layout(world)
    end

    if hovering then
        local pointer = hovering.pointer
        if    pointer then
              pointer:layout()
              pointer:adjust_children()
        end
    
        local tooltip = hovering.tooltip
        if    tooltip then
              tooltip:layout()
              tooltip:adjust_children()
        end
    end

    local wastextediting = (textediting ~= nil)

    if textediting and not is_focused(textediting) then
        textediting:commit()
    end

    if not focused or focused.type ~= TYPE_TEXT_EDITOR then
        textediting = nil
    else
        textediting = focused
    end

    if refreshrepeat ~= 0 or (textediting ~= nil) ~= wastextediting then
        local c = textediting ~= nil
        CAPI.textinput(c, blsh(1, 1)) -- TI_GUI
        CAPI.keyrepeat(c, blsh(1, 1)) -- KR_GUI
        refreshrepeat = 0
    end

    prev_cx = cursor_x
    prev_cy = cursor_y

    if not _ then return nil end
    return _(self)
end

local f = function(_, self, ...)
    needs_adjust = true
    if _ then _(self, ...) end
end

signal.connect(EV, "scr_w_changed", f)
signal.connect(EV, "scr_h_changed", f)
signal.connect(EV, "uitextrows_changed", f)

return {
    register_world = register_world,
    get_world = function(n)
        if not n then return world end
        return worlds[n]
    end,

    Object = Object,
    World = World,
    H_Box = H_Box,
    V_Box = V_Box,
    Table = Table,
    Spacer = Spacer,
    Filler = Filler,
    Offsetter = Offsetter,
    Clipper = Clipper,
    Conditional = Conditional,
    Button = Button,
    Conditional_Button = Conditional_Button,
    Toggle = Toggle,
    Scroller = Scroller,
    Scrollbar = Scrollbar,
    Scroll_Button = Scroll_Button,
    H_Scrollbar = H_Scrollbar,
    V_Scrollbar = V_Scrollbar,
    Slider = Slider,
    Slider_Button = Slider_Button,
    H_Slider = H_Slider,
    V_Slider = V_Slider,
    Rectangle = Rectangle,
    Image = Image,
    Cropped_Image = Cropped_Image,
    Stretched_Image = Stretched_Image,
    Bordered_Image = Bordered_Image,
    Tiled_Image = Tiled_Image,
    Slot_Viewer = Slot_Viewer,
    Label = Label,
    Text_Editor = Text_Editor,
    Field = Field,
    Mover = Mover,
    Resizer = Resizer
}
