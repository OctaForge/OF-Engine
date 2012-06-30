-- external locals
local band = math.band
local bor  = math.bor
local bnot = math.bnot
local blsh = math.lsh
local brsh = math.rsh

local delayed_update_new = function(arg, value)
    if type(arg) == "string" then
        return { var = arg, val = value }
    else
        return { fun = arg }
    end
end

local delayed_update_run = function(self)
    if  self.fun then
        self.fun()
    else
        local t = var.get_type(self.var)
        if    t == -1 then return nil end

        EVAR[self.var] = ((t == 3) and
            tostring(self.val) or tonumber(self.val))
    end
end

local updatelater = CAPI.create_table(4)

local updateval = function(varn, val, onchange)
    if not var.exists(varn) then
        return nil
    end

    table.insert(updatelater, delayed_update_new(varn, val))
    if onchange then
        table.insert(updatelater, delayed_update_new(onchange))
    end
end

local needsadjust = true

local world = nil

local selected = nil
local hovering = nil
local focused  = nil

local wasselected = nil
local washovering = nil

local hoverx  = 0
local hovery  = 0
local selectx = 0
local selecty = 0

local isselected = function(o)
    return (o == selected)
end

local ishovering = function(o)
    return (o == hovering)
end

local isfocused = function(o)
    return (o == focused)
end

local setfocus = function(o)
    focused = o
end

local clearfocus = function(o)
    if o == selected then selected = nil end
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

local TYPE_MISC         = 0
local TYPE_SCROLLER     = 1
local TYPE_SCROLLBAR    = 2
local TYPE_SCROLLBUTTON = 3
local TYPE_SLIDER       = 4
local TYPE_SLIDERBUTTON = 5
local TYPE_IMAGE        = 6
local TYPE_TAG          = 7
local TYPE_WINDOW       = 8
local TYPE_WINDOWMOVER  = 9
local TYPE_TEXTEDITOR   = 10

local ORIENT_HORIZ = 0
local ORIENT_VERT  = 1

local loopchildren = function(self, fun)
    local numforks = self.forks
    local ch = self.children

    if numforks > 0 then
        local i = self.choosefork(self)

        if i ~= self.curfork then
            self.curfork = i
            needsadjust = true
        end

        if i > 0 and #ch >= i then
            local r = fun(ch[i])
            if    r ~= nil then
                return r
            end
        end
    end

    for i = numforks + 1, #ch do
        local r = fun(ch[i])
        if    r ~= nil then return r end
    end
end

local loopchildrenrev = function(self, fun)
    local numforks = self.forks
    local ch = self.children

    for i = #ch, numforks + 1, -1 do
        local r = fun(ch[i])
        if    r ~= nil then return r end
    end

    if numforks > 0 then
        local i = self.choosefork(self)

        if i ~= self.curfork then
            self.curfork = i
            needsadjust = true
        end

        if i > 0 and #ch >= i then
            local r = fun(ch[i])
            if    r ~= nil then
                return r
            end
        end
    end
end

local loopinchildren = function(self, cx, cy, fun)
    return loopchildren(self, function(o)
        local ox = cx - o.x
        local oy = cy - o.y

        if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end)
end

local loopinchildrenrev = function(self, cx, cy, fun)
    return loopchildrenrev(self, function(o)
        local ox = cx - o.x
        local oy = cy - o.y

        if ox >= 0 and ox < o.w and oy >= 0 and oy < o.h then
            local r = fun(o, ox, oy)
            if    r ~= nil then return r end
        end
    end)
end

local Object
Object = table.classify({
    connect             = signal.connect,
    disconnect          = signal.disconnect,
    disconnect_all      = signal.disconnect_all,
    emit                = signal.emit,
    add_post_emit_event = signal.add_post_emit_event,

    forks = 0,

    __init = function(self)
        self.parent = nil

        self.x = 0
        self.y = 0
        self.w = 0
        self.h = 0

        self.adjust   = bor(ALIGN_HCENTER, ALIGN_VCENTER)
        self.children = CAPI.create_table(4)
        self.curfork  = 0
    end,

    resize = function(self, w, h)
        self.w = w or self.w
        self.h = h or self.h

        needsadjust = true
    end,

    clear = function(self)
        clearfocus(self)

        for i = 1, #self.children do
            local ch = self.children[i]
            ch.clear(ch)
        end
        self.children = nil
    end,

    init       = function(self)          end,
    choosefork = function(self) return 0 end,

    layout = function(self)
        self.w = 0
        self.h = 0

        local m = math.max
        loopchildren(self, function(o)
            o.x = 0
            o.y = 0
            o.layout(o)
            self.w = m(self.w, o.x + o.w)
            self.h = m(self.h, o.y + o.h)
        end)
    end,

    adjustchildrento = function(self, px, py, pw, ph)
        loopchildren(self, function(o) o.adjustlayout(o, px, py, pw, ph) end)
    end,

    adjustchildren = function(self)
        Object.adjustchildrento(self, 0, 0, self.w, self.h)
    end,

    adjustlayout = function(self, px, py, pw, ph)
        local w    = self.w
        local h    = self.h
        local x    = self.x
        local y    = self.y

        local a    = self.adjust

        local adj = band(a, ALIGN_HMASK)

        if adj == ALIGN_LEFT then
            self.x = px
        elseif adj == ALIGN_HCENTER then
            self.x = px + (pw - w) / 2
        elseif adj == ALIGN_RIGHT then
            self.x = px + pw - w
        end

        adj = band(a, ALIGN_VMASK)

        if adj == ALIGN_BOTTOM then
            self.y = py
        elseif adj == ALIGN_VCENTER then
            self.y = py + (ph - h) / 2
        elseif adj == ALIGN_TOP then
            self.y = py + ph - h
        end

        if band(a, CLAMP_MASK) ~= 0 then
            if band(a, CLAMP_LEFT ) ~= 0 then self.x = px end
            if band(a, CLAMP_RIGHT) ~= 0 then
                self.w = px + pw - x
            end

            if band(a, CLAMP_BOTTOM) ~= 0 then self.y = py end
            if band(a, CLAMP_TOP   ) ~= 0 then
                self.h = py + ph - y
            end
        end

        self.adjustchildren(self)
    end,

    target = function(self, cx, cy)
        return loopinchildrenrev(self, cx, cy, function(o, ox, oy)
            local c = o.target(o, ox, oy)
            if c then return c end
        end)
    end,

    key = function(self, code, isdown, cooked)
        return loopchildrenrev(self, function(o)
            if o.key(o, code, isdown, cooked) then
                return true
            end
        end) or false
    end,

    draw = function(self, sx, sy)
        sx = sx or self.x
        sy = sy or self.y

        loopchildren(self, function(o)
            local ox = o.x
            local oy = o.y
            local ow = o.w
            local oh = o.h
            if not CAPI.isfullyclipped(sx + ox, sy + oy, ow, oh) then
                o.draw(o, sx + ox, sy + oy)
            end
        end)
    end,

    hover = function(self, cx, cy)
        return loopinchildrenrev(self, cx, cy, function(o, ox, oy)
            local c  = o.hover(o, ox, oy)
            if    c == o then
                hoverx = ox
                hovery = oy
            end
            if c then return c end
        end)
    end,

    hovering = function(self, cx, cy)
    end,

    selecting = function(self, cx, cy)
    end,

    select = function(self, cx, cy)
        return loopinchildrenrev(self, cx, cy, function(o, ox, oy)
            local c  = o.select(o, ox, oy)
            if    c == o then
                selectx = ox
                selecty = oy
            end
            if c then return c end
        end)
    end,

    allowselect = function(self, o)
        return false
    end,

    selected = function(self, cx, cy)
    end,

    gettype = function(self)
        return TYPE_MISC
    end,

    getname = function(self)
        return ""
    end,

    findname = function(self, otype, name, recurse, exclude)
        recurse = recurse == nil and true or recurse
        return loopchildren(self, function(o)
            if o ~= exclude and o.gettype(o) == otype and
            (not name or o.getname(o) == name) then
                return o
            end
        end) or (recurse and loopchildren(self, function(o)
            if o ~= exclude then
                local found = Object.findname(o, otype, name)
                if    found ~= nil then return found end
            end
        end))
    end,

    findsibling = function(self, otype, name)
        local prev = self
        local cur  = self.parent

        while cur do
            local o = Object.findname(cur, otype, name, true, prev)
            if    o then return o end

            prev = cur
            cur  = cur.parent
        end
    end,

    remove = function(self, o)
        for i = 1, #self.children do
            if o == self.children[i] then
                table.remove(self.children, i)
                return nil
            end
        end
    end
}, "Object")

World = table.subclass(Object, {
    focuschildren = function(self)
        return loopchildren(self, function(o)
            if not o.nofocus or not CAPI.is_mouselooking() then
                return true
            end
        end) or false
    end,

    layout = function(self)
        Object.layout(self)

        local     margin = max((EVAR.scr_w / EVAR.scr_h - 1) / 2, 0)
        self.x = -margin
        self.y = 0
        self.w = 2 * margin + 1
        self.h = 1

        self.adjustchildren(self)
    end
})

local List = table.subclass(Object, {
    __init = function(self, horizontal, space)
        self.horizontal = horizontal or false
        self.space      = space      or 0

        return Object.__init(self)
    end,

    layout = function(self)
        self.w = 0
        self.h = 0

        local m = math.max
        if self.horizontal then
            loopchildren(self, function(o)
                o.x = self.w
                o.y = 0
                o.layout(o)

                self.w = self.w + o.w
                self.h = m(self.h, o.y + o.h)
            end)
            self.w = self.w + self.space * m(#self.children - 1, 0)
        else
            loopchildren(self, function(o)
                o.x = 0
                o.y = self.h
                o.layout(o)

                self.h = self.h + o.h
                self.w = m(self.w, o.x + o.w)
            end)
            self.h = self.h + self.space * m(#self.children - 1, 0)
        end
    end,

    adjustchildren = function(self)
        if #self.children == 0 then
            return nil
        end

        local offset = 0
        if self.horizontal then
            loopchildren(self, function(o)
                o.x = offset
                offset = offset + o.w

                o.adjustlayout(o, o.x, 0, offset - o.x, self.h)
                offset = offset + self.space
            end)
        else
            loopchildren(self, function(o)
                o.y = offset
                offset = offset + o.h

                o.adjustlayout(o, 0, o.y, self.w, offset - o.y)
                offset = offset + self.space
            end)
        end
    end
})

local Table = table.subclass(Object, {
    __init = function(self, columns, space)
        self.columns = columns or 0
        self.space   = space   or 0

        return Object.__init(self)
    end,

    layout = function(self)
        self.widths  = CAPI.create_table(4)
        self.heights = CAPI.create_table(4)

        local column = 1
        local row    = 1

        local m = math.max

        loopchildren(self, function(o)
            o.layout(o)

            if #self.widths < column then
                table.insert(self.widths, o.w)
            elseif o.w > self.widths[column] then
                self.widths[column] = o.w
            end

            if #self.heights < row then
                table.insert(self.heights, o.h)
            elseif o.h > self.heights[row] then
                self.heights[row] = o.h
            end

            column = (column % self.columns) + 1
            if column == 1 then
                row = row + 1
            end
        end)

        self.w = 0
        self.h = 0
        column = 1
        row    = 1

        local offset = 0

        loopchildren(self, function(o)
            o.x = offset
            o.y = self.h

            o.adjustlayout(
                o, o.x, o.y, self.widths[column], self.heights[row]
            )
            offset = offset + self.widths[column]

            self.w = m(self.w, offset)
            column = (column % self.columns) + 1

            if column == 1 then
                offset = 0
                self.h = self.h + self.heights[row]
                row    = row + 1
            end
        end)

        if column ~= 1 then
            self.h = self.h + self.heights[row]
        end

        self.w = self.w + self.space * m(#self.widths  - 1, 0)
        self.h = self.h + self.space * m(#self.heights - 1, 0)
    end,

    adjustchildren = function(self)
        if #self.children == 0 then
            return nil
        end

        local cspace = self.w
        local rspace = self.h

        for i = 1, #self.widths do
            cspace = cspace - self.widths[i]
        end
        for i = 1, #self.heights do
            rspace = rspace - self.heights[i]
        end

        cspace = cspace / max(#self.widths  - 1, 1)
        rspace = rspace / max(#self.heights - 1, 1)

        local column = 1
        local row    = 1

        local offsetx = 0
        local offsety = 0

        loopchildren(self, function(o)
            o.x = offsetx
            o.y = offsety

            o.adjustlayout(
                o, offsetx, offsety, self.widths[column],
                self.heights[row]
            )

            offsetx = offsetx + self.widths[column] + cspace
            column = (column % self.columns) + 1

            if column == 1 then
                offsetx = 0
                offsety = offsety + self.heights[row] + rspace
                row = row + 1
            end
        end)
    end
})

local Spacer = table.subclass(Object, {
    __init = function(self, spacew, spaceh)
        self.spacew = spacew or 0
        self.spaceh = spaceh or 0

        return Object.__init(self)
    end,

    layout = function(self)
        self.w = self.spacew
        self.h = self.spaceh

        loopchildren(self, function(o)
            o.x = self.spacew
            o.y = self.spaceh
            o.layout(o)

            self.w = max(self.w, o.x + o.w)
            self.h = max(self.h, o.y + o.h)
        end)

        self.w = self.w + self.spacew
        self.h = self.h + self.spaceh
    end,

    adjustchildren = function(self)
        Object.adjustchildrento(
            self, self.spacew, self.spaceh,
            self.w - 2 * self.spacew,
            self.h - 2 * self.spaceh
        )
    end
})

local Filler = table.subclass(Object, {
    __init = function(self, minw, minh)
        self.minw = minw or 0
        self.minh = minh or 0

        return Object.__init(self)
    end,

    layout = function(self)
        Object.layout(self)

        self.w = max(self.w, self.minw)
        self.h = max(self.h, self.minh)
    end
})

local Offsetter = table.subclass(Object, {
    __init = function(self, offsetx, offsety)
        self.offsetx = offsetx or 0
        self.offsety = offsety or 0

        return Object.__init(self)
    end,

    layout = function(self)
        Object.layout(self)

        loopchildren(self, function(o)
            o.x = o.x + self.offsetx
            o.y = o.y + self.offsety
        end)

        self.w = self.w + self.offsetx
        self.h = self.h + self.offsety
    end,

    adjustchildren = function(self)
        Object.adjustchildrento(
            self,
            self.offsetx,
            self.offsety,
            self.w - self.offsetx,
            self.h - self.offsety
        )
    end
})

local Clipper = table.subclass(Object, {
    __init = function(self, clipw, cliph)
        self.clipw = clipw or 0
        self.cliph = cliph or 0

        self.virtw = 0
        self.virth = 0

        return Object.__init(self)
    end,

    layout = function(self)
        Object.layout(self)
    
        self.virtw = self.w
        self.virth = self.h

        if self.clipw ~= 0 then self.w = min(self.w, self.clipw) end
        if self.cliph ~= 0 then self.h = min(self.h, self.cliph) end
    end,

    adjustchildren = function(self)
        Object.adjustchildrento(self, 0, 0, self.virtw, self.virth)
    end,

    draw = function(self, sx, sy)
        if (self.clipw ~= 0 and self.virtw > self.clipw) or
           (self.cliph ~= 0 and self.virth > self.cliph)
        then
            CAPI.pushclip(sx, sy, self.w, self.h)
            Object.draw(self, sx, sy)
            CAPI.popclip()
        else
            return Object.draw(self, sx, sy)
        end
    end
})

local Conditional = table.subclass(Object, {
    __init = function(self, cond)
        self.cond = cond
        return Object.__init(self)
    end,

    forks = 2,

    choosefork = function(self)
        return (self.cond and self.cond(self)) and 1 or 2
    end
})

local Button = table.subclass(Object, {
    __init = function(self, onselect)
        self.onselect = onselect
        self.queued   = false

        return Object.__init(self)
    end,

    forks = 3,

    choosefork = function(self)
        return isselected(self) and 3 or (ishovering(self) and 2 or 1)
    end,

    hover = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    selected = function(self, cx, cy)
        if self.onselect then self.onselect() end
    end
})

local Conditional_Button = table.subclass(Button, {
    __init = function(cond, onselect)
        Button.__init(self, onselect)
        self.cond = cond
    end,

    forks = 4,

    choosefork = function(self)
        return (
            self.cond and self.cond(self) and (2 + Button.choosefork(self)) or 1
        )
    end,

    selected = function(self, cx, cy)
        if self.cond and self.cond(self) then
            Button.selected(self, cx, cy)
        end
    end
})

-- ???
-- VAR(uitogglehside, 1, 0, 0);
-- VAR(uitogglevside, 1, 0, 0);

local Toggle = table.subclass(Button, {
    __init = function(self, cond, onselect, split)
        Button.__init(self, onselect)

        self.cond  = cond
        self.split = split or 0
    end,

    forks = 4,

    choosefork = function(self)
        return (
            (self.cond and self.cond(self) and 3 or 1) +
            (ishovering(self) and 2 or 1)
        )
    end,

    hover = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        if self.target(self, cx, cy) then
            var.set(
                "uitogglehside", (cx < self.w * self.split) and 0 or 1
            )
            var.set(
                "uitogglevside", (cy < self.h * self.split) and 0 or 1
            )
            return self
        end
    end
})

local Scroller = table.subclass(Clipper, {
    __init = function (self, clipw, cliph)
        self.offsetx   = 0
        self.offsety   = 0
        self.canscroll = 0

        Clipper.__init(self, clipw, cliph)
    end,

    target = function(self, cx, cy)
        if ((cx + self.offsetx) >= self.virtw) or
           ((cy + self.offsety) >= self.virth)
        then return nil end

        return Object.target(self, cx + self.offsetx, cy + self.offsety)
    end,

    hover = function(self, cx, cy)
        if ((cx + self.offsetx) >= self.virtw) or
           ((cy + self.offsety) >= self.virth)
        then
            self.canscroll = false
            return nil
        end

        self.canscroll = true
        return Object.hover(self, cx + self.offsetx, cy + self.offsety)
    end,

    select = function(self, cx, cy)
        if ((cx + self.offsetx) >= self.virtw) or
           ((cy + self.offsety) >= self.virth)
        then return nil end

        return Object.select(self, cx + self.offsetx, cy + self.offsety)
    end,

    key = function(self, code, isdown, cooked)
        if Object.key(self, code, isdown, cooked) then
            return true
        end

        if not self.canscroll then
            return false
        end

        if code == EAPI.INPUT_KEY_MOUSE4 or code == EAPI.INPUT_KEY_MOUSE5 then
            local  sb = Object.findsibling(self, TYPE_SCROLLBAR, nil)
            if not sb then
                return false
            end

            local adjust = (
                code == EAPI.INPUT_KEY_MOUSE4 and -0.2 or 0.2
            ) * sb.arrowspeed

            if sb.getorient(sb) == ORIENT_VERT then
                self.addvscroll(self, adjust)
            else
                self.addhscroll(self, adjust)
            end

            return true
        end

        return false
    end,

    draw = function(self, sx, sy)
        if (self.clipw ~= 0 and self.virtw > self.clipw) or
           (self.cliph ~= 0 and self.virth > self.cliph)
        then
            CAPI.pushclip(sx, sy, self.w, self.h)
            Object.draw(self, sx - self.offsetx, sy - self.offsety)
            CAPI.popclip()
        else
            return Object.draw(self, sx, sy)
        end
    end,

    hlimit = function(self) return max(self.virtw - self.w, 0) end,
    vlimit = function(self) return max(self.virth - self.h, 0) end,

    hoffset = function(self) return self.offsetx / max(self.virtw, self.w) end,
    voffset = function(self) return self.offsety / max(self.virth, self.h) end,

    hscale = function(self) return self.w / max(self.virtw, self.w) end,
    vscale = function(self) return self.h / max(self.virth, self.h) end,

    addhscroll = function(self, hscroll)
        self.sethscroll(self, self.offsetx + hscroll)
    end,
    addvscroll = function(self, vscroll)
        self.setvscroll(self, self.offsety + vscroll)
    end,

    sethscroll = function(self, hscroll)
        self.offsetx = clamp(hscroll, 0, self.hlimit(self))
    end,
    setvscroll = function(self, vscroll)
        self.offsety = clamp(vscroll, 0, self.vlimit(self))
    end,

    gettype = function(self) return TYPE_SCROLLER end
})

local Scrollbar = table.subclass(Object, {
    __init = function(self, arrowsize, arrowspeed)
        self.arrowsize  = arrowsize  or 0
        self.arrowspeed = arrowspeed or 0
        self.arrowdir   = 0

        Object.__init(self)
    end,

    forks = 5,

    choosefork = function(self)
        if self.arrowdir == -1 then
            return isselected(self) and 3 or (ishovering(self) and 2 or 1)
        elseif self.arrowdir == 1 then
            return isselected(self) and 5 or (ishovering(self) and 4 or 1)
        end
        return 1
    end,

    choosedir = function(self, cx, cy)
        return 0
    end,

    hover = function(self, cx, cy)
        local o = Object.hover(self, cx, cy)
        if    o then return o end
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        local o = Object.select(self, cx, cy)
        if    o then return o end
        return self.target(self, cx, cy) and self
    end,

    gettype = function(self)
        return TYPE_SCROLLBAR
    end,

    scrollto = function(self, cx, cy)
    end,

    selected = function(self, cx, cy)
        self.arrowdir = self.choosedir(self, cx, cy)

        if self.arrowdir == 0 then
            self.scrollto(self, cx, cy)
        else
            self.hovering(self, cx, cy)
        end
    end,

    arrowscroll = function(self)
    end,

    hovering = function(self, cx, cy)
        if isselected(self) then
            if self.arrowdir ~= 0 then
                self.arrowscroll(self)
            end
        else
            local button = Object.findname(self, TYPE_SCROLLBUTTON, nil, false)
            if button and isselected(button) then
                self.arrowdir = 0
                button.hovering(button, cx - button.x, cy - button.y)
            else
                self.arrowdir = self.choosedir(self, cx, cy)
            end
        end
    end,

    allowselect = function(self, o)
        return (table.find(self.children, o) >= 1)
    end
})

local Scroll_Button = table.subclass(Object, {
    __init = function(self)
        self.offsetx = 0
        self.offsety = 0

        Object.__init(self)
    end,

    forks = 3,

    choosefork = function(self)
        return isselected(self) and 3 or (ishovering(self) and 2 or 1)
    end,

    hover = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    hovering = function(self, cx, cy)
        if isselected(self) and self.parent and self.parent:gettype() == TYPE_SCROLLBAR then
            self.parent.movebutton(self.parent, self, self.offsetx, self.offsety, cx, cy)
        end
    end,

    selected = function(self, cx, cy)
        self.offsetx = cx
        self.offsety = cy
    end,

    gettype = function(self)
        return TYPE_SCROLLBUTTON
    end
})

local Horizontal_Scrollbar = table.subclass(Scrollbar, {
    choosedir = function(self, cx, cy)
        if cx < self.arrowsize then
            return -1
        elseif cx >= (self.w - self.arrowsize) then
            return 1
        else
            return 0
        end
    end,

    getorient = function(self) return ORIENT_HORIZ end,

    arrowscroll = function(self)
        local  scroll = Object.findsibling(self, TYPE_SCROLLER, nil)
        if not scroll then return nil end

        scroll.addhscroll(
            scroll, self.arrowdir * self.arrowspeed * frame.get_frame_time()
        )
    end,

    scrollto = function(self, cx, cy)
        local  scroll = Object.findsibling(self, TYPE_SCROLLER, nil)
        if not scroll then return nil end

        local  btn = Object.findname(self, TYPE_SCROLLBUTTON, nil, false)
        if not btn then return nil end

        local bscale = (max(self.w - 2 * self.arrowsize, 0) - btn.w) /
            (1 - scroll.hscale(scroll))

        local offset = (bscale > 0.001) and
            (cx - self.arrowsize) / bscale or 0

        scroll.sethscroll(scroll, offset * scroll.virtw)
    end,

    adjustchildren = function(self)
        local  scroll = Object.findsibling(self, TYPE_SCROLLER, nil)
        if not scroll then return nil end

        local  btn = Object.findname(self, TYPE_SCROLLBUTTON, nil, false)
        if not btn then return nil end

        local bw = max(self.w - 2 * self.arrowsize, 0) * scroll.hscale(scroll)
        btn.w    = max(btn.w, bw)

        local bscale = (scroll.hscale(scroll) < 1) and
            (max(self.w - 2 * self.arrowsize, 0) - btn.w) /
                (1 - scroll.hscale(scroll)) or 1

        btn.x = self.arrowsize + scroll.hoffset(scroll) * bscale
        btn.adjust = band(btn.adjust, bnot(ALIGN_HMASK))

        Object.adjustchildren(self)
    end,

    movebutton = function(self, o, fromx, fromy, tox, toy)
        self.scrollto(self, o.x + tox - fromx, o.y + toy)
    end
})

local Vertical_Scrollbar = table.subclass(Scrollbar, {
    choosedir = function(self, cx, cy)
        if cy < self.arrowsize then
            return -1
        elseif cy >= (self.h - self.arrowsize) then
            return 1
        else
            return 0
        end
    end,

    getorient = function(self) return ORIENT_VERT end,

    arrowscroll = function(self)
        local  scroll = Object.findsibling(self, TYPE_SCROLLER, nil)
        if not scroll then return nil end

        scroll.addvscroll(
            scroll, self.arrowdir * self.arrowspeed * frame.get_frame_time()
        )
    end,

    scrollto = function(self, cx, cy)
        local  scroll = Object.findsibling(self, TYPE_SCROLLER, nil)
        if not scroll then return nil end

        local  btn = Object.findname(self, TYPE_SCROLLBUTTON, nil, false)
        if not btn then return nil end

        local bscale = (max(self.h - 2 * self.arrowsize, 0) - btn.h) /
            (1 - scroll.vscale(scroll))

        local offset = (bscale > 0.001) and
            (cy - self.arrowsize) / bscale or 0

        scroll.setvscroll(scroll, offset * scroll.virth)
    end,

    adjustchildren = function(self)
        local  scroll = Object.findsibling(self, TYPE_SCROLLER, nil)
        if not scroll then return nil end

        local  btn = Object.findname(self, TYPE_SCROLLBUTTON, nil, false)
        if not btn then return nil end

        local bh = max(self.h - 2 * self.arrowsize, 0) * scroll.vscale(scroll)

        btn.h = max(btn.h, bh)

        local bscale = (scroll.vscale(scroll) < 1) and
            (max(self.h - 2 * self.arrowsize, 0) - btn.h) /
                (1 - scroll.vscale(scroll)) or 1

        btn.y = self.arrowsize + scroll.voffset(scroll) * bscale
        btn.adjust = band(btn.adjust, bnot(ALIGN_VMASK))

        Object.adjustchildren(self)
    end,

    movebutton = function(self, o, fromx, fromy, tox, toy)
        self.scrollto(self, o.x + tox, o.y + toy - fromy)
    end
})

local Slider = table.subclass(Object, {
    __init = function(
        self, varn, vmin, vmax, onchange, arrowsize, stepsize, steptime
    )
        self.var  = varn
        self.vmin = vmin or 0
        self.vmax = vmax or 0
        self.onchange  = onchange
        self.arrowsize = arrowsize or 0
        self.stepsize  = stepsize  or 1
        self.steptime  = steptime  or 1000

        self.laststep = 0
        self.arrowdir = 0

        if not varn then
            return nil
        end

        if not var.exists(varn) then
            var.new(varn, EAPI.VAR_I, vmin)
        end

        if vmin == 0 and vmax == 0 and not var.is_alias(varn) then
            self.vmin = var.get_min(varn)
            self.vmax = var.get_max(varn)
        end

        return Object.__init(self)
    end,

    dostep = function(self, n)
        local maxstep = abs(self.vmax - self.vmin) / self.stepsize
        local curstep = ((EVAR[self.var] or 0) - min(self.vmin, self.vmax)) /
            self.stepsize
        local newstep = clamp(curstep + n, 0, maxstep)

        updateval(
            self.var,
            min(self.vmax, self.vmin) + (newstep * self.stepsize), 
            onchange
        )
    end,

    setstep = function(self, n)
        local steps   = abs(self.vmax - self.vmin) / self.stepsize
        local newstep = clamp(n, 0, steps)

        updateval(
            self.var,
            min(self.vmax, self.vmin) + (newstep * self.stepsize), 
            onchange
        )
    end,

    key = function(self, code, isdown, cooked)
        if Object.key(self, code, isdown, cooked) then
            return true
        end

        local scroll = function()
            if code == EAPI.INPUT_KEY_UP or code == EAPI.INPUT_KEY_LEFT then
                self.dostep(self, -1)
                return true
            elseif code == EAPI.INPUT_KEY_MOUSE4 then
                self.dostep(self, -3)
                return true
            elseif code == EAPI.INPUT_KEY_DOWN or code == EAPI.INPUT_KEY_RIGHT then
                self.dostep(self, 1)
                return true
            elseif code == EAPI.INPUT_KEY_MOUSE5 then
                self.dostep(self, 3)
                return true
            end

            return false
        end

        if ishovering(self) then return scroll() end

        loopchildren(self, function(o)
            if ishovering(o) then
                return scroll()
            end
        end)

        return false
    end,

    forks = 5,

    choosefork = function(self)
        if self.arrowdir == -1 then
            return isselected(self) and 3 or (ishovering(self) and 2 or 1)
        elseif self.arrowdir == 1 then
            return isselected(self) and 5 or (ishovering(self) and 4 or 1)
        end
        return 1
    end,

    choosedir = function(self, cx, cy)
        return 0
    end,

    hover = function(self, cx, cy)
        local o = Object.hover(self, cx, cy)
        if    o then return o end
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        local o = Object.select(self, cx, cy)
        if    o then return o end
        return self.target(self, cx, cy) and self
    end,

    gettype = function(self)
        return TYPE_SLIDER
    end,

    scrollto = function(self, cx, cy)
    end,

    selected = function(self, cx, cy)
        self.arrowdir = self.choosedir(self, cx, cy)

        if self.arrowdir == 0 then
            self.scrollto(self, cx, cy)
        else
            self.hovering(self, cx, cy)
        end
    end,

    arrowscroll = function(self)
        if (self.laststep + self.steptime) > EAPI.totalmillis then
            return nil
        end

        self.laststep = EAPI.totalmillis
        self.dostep(self, self.arrowdir)
    end,

    hovering = function(self, cx, cy)
        if isselected(self) then
            if self.arrowdir ~= 0 then
                self.arrowscroll(self)
            end
        else
            local button = Object.findname(self, TYPE_SLIDERBUTTON, nil, false)
            if button and isselected(button) then
                self.arrowdir = 0
                button.hovering(button, cx - button.x, cy - button.y)
            else
                self.arrowdir = self.choosedir(self, cx, cy)
            end
        end
    end,

    allowselect = function(self, o)
        return (table.find(self.children, o) >= 1)
    end
})

local Slider_Button = table.subclass(Object, {
    __init = function(self)
        self.offsetx = 0
        self.offsety = 0

        Object.__init(self)
    end,

    forks = 3,

    choosefork = function(self)
        return isselected(self) and 3 or (ishovering(self) and 2 or 1)
    end,

    hover = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    hovering = function(self, cx, cy)
        if isselected(self) and self.parent and self.parent:gettype() == TYPE_SLIDER then
            self.parent.movebutton(self.parent, self, self.offsetx, self.offsety, cx, cy)
        end
    end,

    selected = function(self, cx, cy)
        self.offsetx = cx
        self.offsety = cy
    end,

    layout = function(self)
        local lastw = self.w
        local lasth = self.h

        Object.layout(self)

        if isselected(self) then
            self.w = lastw
            self.h = lasth
        end
    end,

    gettype = function(self)
        return TYPE_SLIDERBUTTON
    end
})

local Horizontal_Slider = table.subclass(Slider, {
    choosedir = function(self, cx, cy)
        if cx < self.arrowsize then
            return -1
        elseif cx >= (self.w - self.arrowsize) then
            return 1
        else
            return 0
        end
    end,

    scrollto = function(self, cx, cy)
        local  btn = Object.findname(self, TYPE_SLIDERBUTTON, nil, false)
        if not btn then return nil end

        local pos = clamp((cx - self.arrowsize - btn.w / 2) /
            (self.w - 2 * self.arrowsize - btn.w), 0.1, 1)

        local steps = abs(self.vmax - self.vmin) / self.stepsize
        local step  = round(steps * pos)

        self.setstep(self, step)
    end,

    adjustchildren = function(self)
        local  btn = Object.findname(self, TYPE_SLIDERBUTTON, nil, false)
        if not btn then return nil end

        local steps   = abs(self.vmax - self.vmin) / self.stepsize
        local curstep = ((EVAR[self.var] or 0) - min(self.vmax, self.vmin)) /
            self.stepsize

        local width = max(self.w - 2 * self.arrowsize, 0)

        btn.w = max(btn.w, width / steps)
        btn.x = self.arrowsize + (width - btn.w) * curstep / steps
        btn.adjust = band(btn.adjust, bnot(ALIGN_HMASK))

        Object.adjustchildren(self)
    end,

    movebutton = function(self, o, fromx, fromy, tox, toy)
        self.scrollto(self, o.x + o.w / 2 + tox - fromx, o.y + toy)
    end
})

local Vertical_Slider = table.subclass(Slider, {
    choosedir = function(self, cx, cy)
        if cy < self.arrowsize then
            return -1
        elseif cy >= (self.h - self.arrowsize) then
            return 1
        else
            return 0
        end
    end,

    scrollto = function(self, cx, cy)
        local  btn = Object.findname(self, TYPE_SLIDERBUTTON, nil, false)
        if not btn then return nil end

        local pos = clamp((cy - self.arrowsize - btn.h / 2) /
            (self.h - 2 * self.arrowsize - btn.h), 0.1, 1)

        local steps = (max(self.vmax, self.vmin) - min(self.vmax, self.vmin)) /
            self.stepsize

        local step = round(steps * pos)

        self.setstep(self, step)
    end,

    adjustchildren = function(self)
        local  btn = Object.findname(self, TYPE_SLIDERBUTTON, nil, false)
        if not btn then return nil end

        local steps = (max(self.vmax, self.vmin) - min(self.vmax, self.vmin)) /
            self.stepsize + 1

        local curstep = ((EVAR[self.var] or 0) - min(self.vmax, self.vmin)) /
            self.stepsize

        local height = max(self.h - 2 * self.arrowsize, 0)

        btn.h = max(btn.h, height / steps)
        btn.y = self.arrowsize + (height - btn.h) * curstep / steps
        btn.adjust = band(btn.adjust, bnot(ALIGN_VMASK))

        Object.adjustchildren(self)
    end,

    movebutton = function(self, o, fromx, fromy, tox, toy)
        self.scrollto(self, o.x + o.h / 2 + tox, o.y + toy - fromy)
    end
})

local RECT_SOLID    = 0
local RECT_MODULATE = 1

local Rectangle = table.subclass(Filler, {
    __init = function(self, rtype, r, g, b, a, minw, minh)
        Filler.__init(self, minw, minh)

        self.rtype = rtype
        self.color = math.Vec4(r, g, b, a)
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    draw = function(self, sx, sy)
        CAPI.draw_rect(
            sx, sy, self.w, self.h, self.color, self.rtype == RECT_MODULATE
        )

        return Object.draw(self, sx, sy)
    end

})

local Image = table.subclass(Filler, {
    __init = function(self, tex, minw, minh)
        Filler.__init(self, minw, minh)
        self.tex = tex
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        if CAPI.texture_get_bpp(self.tex) < 32 then
            return self
        end

        return CAPI.texture_check_alpha_mask(
            self.tex, cx / self.w, cy / self.h
        ) and self
    end,

    draw = function(self, sx, sy)
        CAPI.texture_draw(self.tex, function(fun)
            fun(sx, sy, self.w, self.h)
        end)

        return Object.draw(self, sx, sy)
    end,

    gettype = function(self)
        return TYPE_IMAGE
    end
})

local Cropped_Image = table.subclass(Image, {
    __init = function(self, tex, minw, minh, cropx, cropy, cropw, croph)
        Image.__init (self, tex, minw, minh)

        self.cropx = cropx or 0
        self.cropy = cropy or 0
        self.cropw = cropw or 1
        self.croph = croph or 1
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        if CAPI.texture_get_bpp(self.tex) < 32 then
            return self
        end

        return CAPI.texture_check_alpha_mask(
            self.tex,
            self.cropx + cx / self.w * self.cropw,
            self.cropy + cy / self.h * self.croph
        ) and self
    end,

    draw = function(self, sx, sy)
        CAPI.texture_draw(self.tex, function(fun)
            fun(
                sx, sy, self.w, self.h,
                self.cropx, self.cropy, self.cropw, self.croph
            )
        end)

        return Object.draw(self, sx, sy)
    end
})

local Stretched_Image = table.subclass(Image, {
    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        if CAPI.texture_get_bpp(self.tex) < 32 then
            return self
        end

        local mx = 0
        local my = 0

        if self.w <= self.minw then
            mx = cx / self.w
        elseif cx < self.minw / 2 then
            mx = cx / self.minw
        elseif cx >= self.w - self.minw / 2 then
            mx = 1 - (self.w - cx) / self.minw
        else
            mx = 0.5
        end

        if self.h <= self.minh then
            my = cy / self.h
        elseif cy < self.minh / 2 then
            my = cy / self.minh
        elseif cy >= self.h - self.minh / 2 then
            my = 1 - (self.h - cy) / self.minh
        else
            my = 0.5
        end

        return CAPI.texture_check_alpha_mask(self.tex, mx, my) and self
    end,

    draw = function(self, sx, sy)
        CAPI.texture_draw(self.tex, function(fun)
            local splitw = (self.minw ~= 0 and min(
                self.minw, self.w
            ) or self.w) / 2

            local splith = (self.minh ~= 0 and min(
                self.minh, self.h
            ) or self.h) / 2

            local vy = sy
            local ty = 0

            for i = 1, 3 do
                local vh = 0
                local th = 0

                if i == 1 then
                    if splith < self.h - splith then
                        vh = splith
                        th = 0.5
                    else
                        vh = self.h
                        th = 1
                    end
                elseif i == 2 then
                    vh = self.h - 2 * splith
                    th = 0
                elseif i == 3 then
                    vh = splith
                    th = 0.5
                end

                local vx = sx
                local tx = 0

                for j = 1, 3 do
                    local vw = 0
                    local tw = 0

                    if j == 1 then
                        if splitw < self.w - splitw then
                            vw = splitw
                            tw = 0.5
                        else
                            vw = self.w
                            tw = 1
                        end
                    elseif j == 2 then
                        vw = self.w - 2 * splitw
                        tw = 0
                    elseif j == 3 then
                        vw = splitw
                        tw = 0.5
                    end

                    fun(vx, vy, vw, vh, tx, ty, tw, th)
                    vx = vx + vw
                    tx = tx + tw

                    if tx >= 1 then
                        break
                    end
                end

                vy = vy + vh
                ty = ty + th

                if ty >= 1 then
                    break
                end
            end
        end)

        return Object.draw(self, sx, sy)
    end
})

local Bordered_Image = table.subclass(Image, {
    __init = function(self, tex, texborder, screenborder)
        Image.__init (self, tex)

        self.texborder    = texborder or 0
        self.screenborder = screenborder or 0
    end,

    layout = function(self)
        Object.layout(self)

        self.w = max(self.w, 2 * self.screenborder)
        self.h = max(self.h, 2 * self.screenborder)
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o then return o end

        if CAPI.texture_get_bpp(self.tex) < 32 then
            return self
        end

        local mx = 0
        local my = 0

        if cx < self.screenborder then
            mx = cx / self.screenborder * self.texborder
        elseif cx >= self.w - self.screenborder then
            mx = 1 - self.texborder + (cx - (self.w - self.screenborder)) /
                self.screenborder * self.texborder
        else
            mx = self.texborder + (cx - self.screenborder) /
                (self.w - 2 * self.screenborder) * (1 - 2 * self.texborder)
        end

        if cy < self.screenborder then
            my = cy / self.screenborder * self.texborder
        elseif cy >= self.h - self.screenborder then
            my = 1 - self.texborder + (cy - (self.h - self.screenborder)) /
                self.screenborder * self.texborder
        else
            my = self.texborder + (cy - self.screenborder) /
                (self.h - 2 * self.screenborder) * (1 - 2 * self.texborder)
        end

        return CAPI.texture_check_alpha_mask(self.tex, mx, my) and self
    end,

    draw = function(self, sx, sy)
        CAPI.texture_draw(self.tex, function(fun)
            local vy = sy
            local ty = 0

            for i = 1, 3 do
                local vh = 0
                local th = 0

                if i == 2 then
                    vh = self.h - 2 * self.screenborder
                    th = 1 - 2 * self.texborder
                else
                    vh = self.screenborder
                    th = self.texborder
                end

                local vx = sx
                local tx = 0

                for j = 1, 3 do
                    local vw = 0
                    local tw = 0

                    if j == 2 then
                        vw = self.w - 2 * self.screenborder
                        tw = 1 - 2 * self.texborder
                    else
                        vw = self.screenborder
                        tw = self.texborder
                    end

                    fun(vx, vy, vw, vh, tx, ty, tw, th)
                    vx = vx + vw
                    tx = tx + tw
                end

                vy = vy + vh
                ty = ty + th
            end
        end)

        return Object.draw(self, sx, sy)
    end
})

local Slot_Viewer = table.subclass(Filler, {
    __init = function(self, slotnum, minw, minh)
        Filler.__init(self, minw, minh)
        self.slotnum = slotnum or 0
    end,

    target = function(self, cx, cy)
        local o = Object.target(self, cx, cy)
        if    o or not CAPI.hastexslot(self.slotnum) then return o end
        return CAPI.checkvslot(self.slotnum) and self
    end,

    draw = function(self, sx, sy)
        CAPI.texture_draw_slot(self.slotnum, self.w, self.h, sx, sy)
        return Object.draw(self, sx, sy)
    end
})

-- ???: default size of text in terms of rows per screenful
-- VARP(uitextrows, 1, 40, 200);

local Label = table.subclass(Object, {
    __init = function(self, str, scale, wrap, r, g, b)
        self.str   = str
        self.scale = scale or  1
        self.wrap  = wrap  or -1
        self.color = math.Vec3(r or 1, g or 1, b or 1)

        self._w = ffi.new("int[1]")
        self._h = ffi.new("int[1]")

        return Object.__init(self)
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    drawscale = function(self)
        return self.scale / (EVAR["fonth"] * EVAR["uitextrows"])
    end,

    draw = function(self, sx, sy)
        CAPI.draw_text(
            self.str, sx, sy, self.drawscale(self), self.color, self.wrap
        )
        return Object.draw(self, sx, sy)
    end,

    layout = function(self)
        Object.layout(self)

        local k = self.drawscale(self)

        EAPI.gui_text_bounds(self.str, self._w, self._h,
            self.wrap <= 0 and -1 or self.wrap / k)

        if self.wrap <= 0 then
            self.w = max(self.w, self._w[0] * k)
        else
            self.w = max(self.w, min(self.wrap, self._w[0] * k))
        end

        self.h = max(self.h, self._h[0] * k)
    end
})

local EDIT_IDLE    = 0
local EDIT_FOCUSED = 1
local EDIT_COMMIT  = 2

local textediting   = nil
local refreshrepeat = 0

local EDITORFOCUSED = 1
local EDITORUSED    = 2
local EDITORFOREVER = 3

local Text_Editor = table.subclass(Object, {
    __init = function(
        self, name, length, height, scale, initval, mode, keyfilter, password
    )
        length = length or 0
        height = height or 0
        scale  = scale  or 1
        mode   = mode   or EDITORUSED

        self.state      = EDIT_IDLE
        self.lastaction = EAPI.totalmillis
        self.scale      = scale
        self.keyfilter  = keyfilter

        self.offsetx = 0
        self.offsety = 0

        self.edit = CAPI.editor_use(
            name, mode or EDITORUSED, false, initval, password
        )

        CAPI.editor_linewrap_set(self.edit, length < 0)

        CAPI.editor_maxx_set(self.edit, length <  0 and -1 or length)
        CAPI.editor_maxy_set(self.edit, height <= 0 and  1 or -1)

        CAPI.editor_pixelwidth_set(
            self.edit, abs(length) * EVAR["fontw"]
        )

        self._w = ffi.new("int[1]")
        self._h = ffi.new("int[1]")

        if length < 0 and height <= 0 then
            EAPI.gui_text_bounds(CAPI.editor_line_get(self.edit, 1), self._w,
                self._h, CAPI.editor_pixelwidth_get(self.edit))
            CAPI.editor_pixelheight_set(self.edit, self._h[0])
        else
            CAPI.editor_pixelheight_set(
                self.edit, EVAR["fonth"] * max(height, 1)
            )
        end

        return Object.__init(self)
    end,

    clear = function(self)
        if  CAPI.editor_mode_get(self.edit) ~= EDITORFOREVER then
            CAPI.editor_remove  (self.edit)
        end

        if self == textediting then
            textediting = nil
        end

        refreshrepeat = refreshrepeat + 1
    end,

    target = function(self, cx, cy)
        return Object.target(self, cx, cy) or self
    end,

    hover = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    commit = function(self)
        self.state = EDIT_IDLE
    end,

    hovering = function(self, cx, cy)
        if isselected(self) and isfocused(self) then
            local dragged = (
                max(abs(cx - self.offsetx), abs(cy - self.offsety)) >
                    (EVAR["fontw"] / 4) * self.scale /
                        (EVAR["fonth"] * EVAR.uitextrows)
            )
            CAPI.editor_hit(
                self.edit,
                floor(cx * (EVAR["fonth"] * EVAR.uitextrows) /
                    self.scale - EVAR["fontw"] / 2
                ),
                floor(cy * (EVAR["fonth"] * EVAR.uitextrows) /
                    self.scale
                ),
                dragged
            )
        end
    end,

    selected = function(self, cx, cy)
        CAPI.editor_focus(self.edit)
        self.state = EDIT_FOCUSED
        setfocus(self)
        CAPI.editor_mark(self.edit)
        self.offsetx = cx
        self.offsety = cy
    end,

    key = function(self, code, isdown, cooked)
        if Object.key(self, code, isdown, cooked) then return true end
        if not isfocused(self) then return false end

        local ret  = switch(code,
            case(EAPI.INPUT_KEY_RETURN, function()
                if not cooked then return true end
            end),
            case(EAPI.INPUT_KEY_TAB, function()
                if CAPI.editor_maxy_get(self.edit) == 1 then
                    setfocus(nil)
                    return true
                end
            end),
            case(EAPI.INPUT_KEY_ESCAPE, function()
                setfocus(nil)
                return true
            end),
            case(EAPI.INPUT_KEY_KP_ENTER, function()
                if cooked ~= 0 and CAPI.editor_maxy_get(self.edit) == 1 then
                    setfocus(nil)
                end
                return true
            end),
            case({  EAPI.INPUT_KEY_HOME,
                    EAPI.INPUT_KEY_END,
                    EAPI.INPUT_KEY_PAGEUP,
                    EAPI.INPUT_KEY_PAGEDOWN,
                    EAPI.INPUT_KEY_DELETE,
                    EAPI.INPUT_KEY_BACKSPACE,
                    EAPI.INPUT_KEY_UP,
                    EAPI.INPUT_KEY_DOWN,
                    EAPI.INPUT_KEY_LEFT,
                    EAPI.INPUT_KEY_RIGHT,
                    EAPI.INPUT_KEY_LSHIFT,
                    EAPI.INPUT_KEY_RSHIFT,
                    EAPI.INPUT_KEY_LCTRL,
                    EAPI.INPUT_KEY_RCTRL,
                    EAPI.INPUT_KEY_LMETA,
                    EAPI.INPUT_KEY_RMETA,
                    EAPI.INPUT_KEY_MOUSE4,
                    EAPI.INPUT_KEY_MOUSE5 }, function()
                    return nil
                end
            ),
            case({  EAPI.INPUT_KEY_A,
                    EAPI.INPUT_KEY_X,
                    EAPI.INPUT_KEY_C,
                    EAPI.INPUT_KEY_V }, function()
                if CAPI.is_modifier_pressed() then return nil end
                if cooked == 0 or code < 32 then
                    return false
                end
                if self.keyfilter and not string.find(
                    self.keyfilter, string.char(cooked)
                ) then
                    return true
                end
            end),
            default(function()
                if cooked == 0 or code < 32 then
                    return false
                end
                if self.keyfilter and not string.find(
                    self.keyfilter, string.char(cooked)
                ) then
                    return true
                end
            end)
        )
        if ret ~= nil then return ret end

        if isdown then
            CAPI.editor_key(self.edit, code, cooked)
        end
        return true
    end,

    layout = function(self)
        Object.layout(self)

        if CAPI.editor_linewrap_get(self.edit) and
            CAPI.editor_maxy_get(self.edit) == 1
        then
            local r = EAPI.gui_text_bounds(CAPI.editor_line_get(self.edit, 1),
                self._w, self._h, CAPI.editor_pixelwidth_get(self.edit))
            CAPI.editor_pixelheight_set(self.edit, self._h[0])
        end

        self.w = max(self.w, (CAPI.editor_pixelwidth_get(self.edit) +
            EVAR["fontw"]) * self.scale / (EVAR["fonth"] * EVAR.uitextrows))

        self.h = max(self.h, CAPI.editor_pixelheight_get(self.edit) *
            self.scale / (EVAR["fonth"] * EVAR.uitextrows)
        )
    end,

    draw = function(self, sx, sy)
        CAPI.editor_draw(self.edit, sx, sy, self.scale, isfocused(self))
        return Object.draw(self, sx, sy)
    end,

    gettype = function(self)
        return TYPE_TEXTEDITOR
    end
})

local Field = table.subclass(Text_Editor, {
    __init = function(
        self, var, length, onchange, scale, initval, keyfilter, password
    )
        Text_Editor.__init(
            self, var, length, 0, scale, initval, EDITORUSED,
            keyfilter, password
        )
        self.var = var
        self.onchange = onchange
    end,

    commit = function(self)
        self.state = EDIT_COMMIT
        self.lastaction = EAPI.totalmillis
        updateval(self.var, CAPI.editor_line_get(self.edit, 1), self.onchange)
    end,

    key = function(self, code, isdown, cooked)
        if Object.key(self, code, isdown, cooked) then return true end
        if not isfocused(self) then return false end

        local ret  = switch(code,
            case(EAPI.INPUT_KEY_ESCAPE, function()
                self.state = EDIT_COMMIT
                return true
            end),
            case({  EAPI.INPUT_KEY_KP_ENTER,
                    EAPI.INPUT_KEY_RETURN,
                    EAPI.INPUT_KEY_TAB }, function()
                if cooked == 0 then return false end
                self.commit(self)
                setfocus(nil)
                return true
            end),
            case({  EAPI.INPUT_KEY_HOME,
                    EAPI.INPUT_KEY_END,
                    EAPI.INPUT_KEY_DELETE,
                    EAPI.INPUT_KEY_BACKSPACE,
                    EAPI.INPUT_KEY_LEFT,
                    EAPI.INPUT_KEY_RIGHT },
                function() return nil end
            ),
            default(function()
                if cooked == 0 or code < 32 then
                    return false
                end
                if self.keyfilter and not string.find(
                    self.keyfilter, string.char(cooked)
                ) then
                    return true
                end
            end)
        )
        if ret ~= nil then return ret end
        if isdown then
            CAPI.editor_key(self.edit, code, cooked)
        end
        return true
    end,

    layout = function(self)
        if self.state == EDIT_COMMIT or var.changed() and
            self.lastaction ~= EAPI.totalmillis
        then
            CAPI.editor_clear(self.edit, tostring(EVAR[self.var]))
            self.state = EDIT_IDLE
        end

        Text_Editor.layout(self)
    end
})

local Named_Object = table.subclass(Object, {
    getname = function(self)
        return self.objname
    end,

    __init = function(self, name)
        self.objname = name or ""
        return Object.__init(self)
    end
})

local Tag = table.subclass(Named_Object, {
    gettype = function(self)
        return TYPE_TAG
    end
})

local Window = table.subclass(Named_Object, {
    __init = function(self, name, onhide, nofocus)
        Named_Object.__init(self, name)

        self.onhide  = onhide
        self.nofocus = nofocus or false

        self.customx = 0
        self.customy = 0
    end,

    hidden = function(self)
        if self.onhide then self.onhide(self) end
        resetcursor()
    end,

    adjustlayout = function(self, px, py, pw, ph)
        Object.adjustlayout(self, px, py, pw, ph)

        if  self.customx == 0 then self.customx = self.x end
        if  self.customy == 0 then self.customy = self.y end

        local diffx = self.customx - self.x
        local diffy = self.customy - self.y

        if diffx ~= 0 or diffy ~= 0 then
            self.x = self.customx
            self.y = self.customy
        end
    end,

    gettype = function(self)
        return TYPE_WINDOW
    end
})

local Window_Mover = table.subclass(Object, {
    forks      = 1,
    choosefork = function(self) return 1 end,

    init = function(self)
        local par = self.parent

        while not (par:gettype() == TYPE_WINDOW) do
            if not par.parent then break end
            par  = par.parent
        end

        if par:gettype() == TYPE_WINDOW then
            self.win = par
        end
    end,

    hover = function(self, cx, cy)
        return self.target(self, cx, cy) and self
    end,

    select = function(self, cx, cy)
        local n = table.find(world.children, self.win)
        local l = #world.children

        if n ~= l then
            local o = world.children[l]
            world.children[l] = self.win
            world.children[n] = o
        end

        return self.target(self, cx, cy) and self
    end,

    selecting = function(self, cx, cy)
        if  self.win and isselected(self) then
            self.win.customx = self.win.customx + cx
            self.win.customy = self.win.customy + cy

            self.win.x = self.win.x + cx
            self.win.y = self.win.y + cy
        end
    end,

    gettype = function(self)
        return TYPE_WINDOWMOVER
    end

})

local build = CAPI.create_table(4)

local buildwindow = function(name, contents, onhide, nofocus)
    local win = Window(name, onhide, nofocus)

    table.insert(build, win)
    contents(win)
    table.remove(build)

    return win
end

local hideui = function(name)
    local win = Object.findname(world, TYPE_WINDOW, name, false)
    if  win then
        win.hidden(win)
        Object.remove(world, win)
    end

    return (win ~= nil)
end

local addui = function(o, children)
    if #build ~= 0 then
        o.parent   = build[#build]
        table.insert(build[#build].children, o)
    end

    if children then
        table.insert(build, o)
        children(o)
        table.remove(build)
    end

    o.init(o)
end

local showui = function(name, contents, onhide, nofocus)
    name = name or ""

    if not contents then
        log(ERROR, "showui(\"%(1)s\"): contents is nil\n" % { name })
        return false
    end

    if #build ~= 0 then
        return false
    end

    local oldwin = Object.findname(world, TYPE_WINDOW, name, false)
    if  oldwin then
        oldwin.hidden(oldwin)
        Object.remove(world, oldwin)
    end

    local win = buildwindow(name, contents, onhide, nofocus)
    table.insert(world.children, win)
    win.parent = world

    return true
end

local replaceui = function(wname, tname, contents)
    wname = wname or ""
    tname = tname or ""

    if not contents then
        log(ERROR, "replaceui(\"%(1)s\", \"%(2)s\"): contents is nil\n" % {
            wname, tname
        })
        return false
    end

    if #build ~= 0 then
        return false
    end

    local  win = Object.findname(world, TYPE_WINDOW, wname, false)
    if not win then
        return false
    end

    local  tg = Object.findname(win,TYPE_TAG, tname)
    if not tg then
        return false
    end

    tg.children = CAPI.create_table(4)
    table.insert(build, tg)
    contents(tg)
    table.remove(build)

    return true
end

local uialign = function(h, v)
    if #build ~= 0 then
        build[#build].adjust = bor(
            band(build[#build].adjust, bnot(ALIGN_MASK)),
            blsh (clamp(h, -1, 1) + 2, ALIGN_HSHIFT),
            blsh (clamp(v, -1, 1) + 2, ALIGN_VSHIFT)
        )
        needsadjust = true
    end
end

local uiclamp = function(l, r, b, t)
    if #build ~= 0 then
        build[#build].adjust = bor(
            band(build[#build].adjust, bnot(CLAMP_MASK)),
            l and l ~= 0 and CLAMP_LEFT   or 0,
            r and r ~= 0 and CLAMP_RIGHT  or 0,
            b and b ~= 0 and CLAMP_BOTTOM or 0,
            t and t ~= 0 and CLAMP_TOP    or 0
        )
        needsadjust = true
    end
end

local uiwinmover = function(children)
    addui(Window_Mover(), children)
end

local uitag = function(name, children)
    addui(Tag(name or ""), children)
end

local uivlist = function(space, children)
    addui(List(false, space), children)
end

local uihlist = function(space, children)
    addui(List(true, space), children)
end

local uitable = function(columns, space, children)
    addui(Table(columns, space), children)
end

local uispace = function(h, v, children)
    addui(Spacer(h, v), children)
end

local uifill = function(h, v, children)
    addui(Filler(h, v), children)
end

local uiclip = function(h, v, children)
    addui(Clipper(h, v), children)
end

local uiscroll = function(h, v, children)
    addui(Scroller(h, v), children)
end

local uihscrollbar = function(h, v, children)
    addui(Horizontal_Scrollbar(h, v), children)
end

local uivscrollbar = function(h, v, children)
    addui(Vertical_Scrollbar(h, v), children)
end

local uiscrollbutton = function(children)
    addui(Scroll_Button(), children)
end

local uihslider = function(
    var, vmin, vmax, onchange, arrowsize, stepsize, steptime, children
)
    addui(Horizontal_Slider(
        var, vmin, vmax, onchange, arrowsize, stepsize, steptime
    ), children)
end

local uivslider = function(
    var, vmin, vmax, onchange, arrowsize, stepsize, steptime, children
)
    addui(Vertical_Slider(
        var, vmin, vmax, onchange, arrowsize, stepsize, steptime
    ), children)
end

local uisliderbutton = function(children)
    addui(Slider_Button(), children)
end

local uioffset = function(h, v, children)
    addui(Offsetter(h, v), children)
end

local uibutton = function(cb, children)
    addui(Button(cb), children)
end

local uicond = function(cb, children)
    addui(Conditional(cb), children)
end

local uicondbutton = function(cond, cb, children)
    addui(Conditional_Button(cond, cb), children)
end

local uitoggle = function(cond, cb, split, children)
    addui(Toggle(cond, cb, split), children)
end

local uiimage = function(path, minw, minh, children)
    addui(Image(CAPI.texture_load(path), minw, minh), children)
end

local uislotview = function(slot, minw, minh, children)
    addui(Slot_Viewer(slot, minw, minh), children)
end

local uialtimage = function(path)
    if #build == 0 or not (build[#build]:gettype() == TYPE_IMAGE) then
        return nil
    end

    local img = build[#build]
    if    img and not CAPI.texture_loaded(img.tex) then
          img.tex = CAPI.texture_load(path)
    end
end

local uicolor = function(r, g, b, a, minw, minh, children)
    addui(Rectangle(RECT_SOLID, r, g, b, a, minw, minh), children)
end

local uimodcolor = function(r, g, b, minw, minh, children)
    addui(Rectangle(RECT_MODULATE, r, g, b, 1, minw, minh), children)
end

local uistretchedimage = function(path, minw, minh, children)
    addui(Stretched_Image(
        CAPI.texture_load(path), minw, minh
    ), children)
end

local uicroppedimage = function(path, minw, minh, cx, cy, cw, ch, children)
    local tex = CAPI.texture_load(path)
    addui(Cropped_Image(
        tex, minw, minh,
        CAPI.texture_border_size_get(tex, cx, false),
        CAPI.texture_border_size_get(tex, cy, true),
        CAPI.texture_border_size_get(tex, cw, false),
        CAPI.texture_border_size_get(tex, ch, true)
    ), children)
end

local uiborderedimage = function(path, tb, sb, children)
    local tex = CAPI.texture_load(path)
    addui(Bordered_Image(
        tex, CAPI.texture_border_size_get(tex, tb), sb
    ), children)
end

local uilabel = function(lbl, scale, wrap, r, g, b, children)
    addui(Label(lbl, scale, wrap, r, g, b), children)
end

local uitexteditor = function(
    name, length, height, scale, initval, keep, filter, children
)
    addui(Text_Editor(
        name, length, height, scale, initval,
        keep and EDITORFOREVER or EDITORUSED, filter
    ), children)
end

local uifield = function(varn, length, onchange, scale, filter, pwd, children)
    if not var then return nil end

    if not var.exists(varn) then
        var.new(varn, EAPI.VAR_S, "")
    end

    addui(Field(varn,
        length, onchange, scale, EVAR[varn], filter, pwd), children)
end

-- ???
--FVAR(cursorsensitivity, 1e-3f, 1, 1000);

local cursorx = 0.5
local cursory = 0.5

local prev_cx = 0.5
local prev_cy = 0.5

resetcursor = function()
    if entity_store.is_player_editing() or #world.children == 0 then
        cursorx = 0.5
        cursory = 0.5
    end
end

movecursor = function(dx, dy)
    if (#world.children == 0 or not world.focuschildren(world)) and
        CAPI.is_mouselooking()
    then
        return false
    end

    local scale = 500 / EVAR.cursorsensitivity

    cursorx = clamp(cursorx + dx * (EVAR.scr_h / (EVAR.scr_w * scale)), 0, 1)
    cursory = clamp(cursory + dy / scale, 0, 1)

    return true
end

hascursor = function(targeting)
    if not world.focuschildren(world) then
        return false
    end

    if #world.children ~= 0 then
        if not targeting then return true end
        if world and world.target(world, cursorx * world.w, cursory * world.h) then
            return true
        end
    end

    return false
end

getcursorpos = function()
    if #world.children ~= 0 or not CAPI.is_mouselooking() then
        return cursorx, cursory
    else
        return 0.5, 0.5
    end
end

keypress = function(code, isdown, cooked)
    if not hascursor() then
        return false
    end

    if code == -1 then
        if isdown then
            selected = world.select(world, cursorx * world.w, cursory * world.h)
            if  selected then
                selected.selected(selected, selectx, selecty)
            end
        else
            selected = nil
        end
        return true
    else
        return world.key(world, code, isdown, cooked)
    end
end

-- ???
-- VAR(mainmenu, 1, 1, 0);

local clearmainmenu = function(self)
    if  EVAR.mainmenu ~= 0 and (CAPI.isconnected() or CAPI.haslocalclients()) then
        EVAR.mainmenu  = 0

        hideui("main")
        hideui("vtab")
        hideui("htab")
    end
end

local setup = function()
    if  world then
        world = nil
        build = CAPI.create_table(4)
    end
    world = World()
end

local space = false

local update = function()
    for i = 1, #updatelater do
        delayed_update_run(updatelater[i])
    end
    updatelater = CAPI.create_table(4)

    if EVAR.mainmenu ~= 0 and not CAPI.isconnected(true) and
        #world.children == 0
    then
        LAPI.GUI.show("main")
    end

    if (entity_store.is_player_editing() and EVAR.mainmenu == 0) and not space then
        LAPI.GUI.show("space")
        hideui("vtab")
        hideui("htab")
        space = true
        resetcursor()
    elseif (not entity_store.is_player_editing() and EVAR.mainmenu ~= 0) and space
    then
        hideui("space")
        hideui("vtab")
        hideui("htab")
        space = false
        resetcursor()
    end

    if needsadjust then
        world.layout(world)
        needsadjust = false
    end
    var.changed(false)

    washovering = hovering
    wasselected = selected

    if hascursor() then
        hovering = world.hover(world, cursorx * world.w, cursory * world.h)
        if  hovering then
            hovering.hovering(hovering, hoverx, hovery)
        end

        -- hacky
        if selected then selected.selecting(
            selected,
            (cursorx - prev_cx) * (EVAR.scr_w / EVAR.scr_h),
            (cursory - prev_cy)
        ) end
    else
        hovering = nil
        selected = nil
    end

    if washovering ~= hovering or wasselected ~= selected then
        world.layout(world)
    end

    local wastextediting = (textediting ~= nil)

    if   textediting and not isfocused(textediting) and 
         textediting.state == EDIT_FOCUSED
    then textediting.commit(textediting)
    end

    if not focused or focused.gettype(focused) ~= TYPE_TEXTEDITOR then
        textediting = nil
    else
        textediting = focused
    end

    if refreshrepeat ~= 0 or (textediting ~= nil) ~= wastextediting then
        CAPI.enable_unicode(textediting ~= nil)
        CAPI.keyrepeat(textediting ~= nil or entity_store.is_player_editing())
        refreshrepeat = 0
    end

    prev_cx = cursorx
    prev_cy = cursory
end

local render_helper = function()
    world.draw(world)
end

local render = function()
    if #world.children == 0 then
        return nil
    end

    CAPI.draw_ui(world.x, world.y, world.w, world.h, render_helper)
end

local needsapply = {}

local change_new = function(desc, ctype)
    if EVAR["applydialog"] == 0 then return nil end

    for i, v in pairs(needsapply) do
        if v.desc == desc then return nil end end

    table.insert(needsapply, { ctype = ctype, desc = desc })
    LAPI.GUI.show_changes() end

local changes_clear = function(ctype)
    ctype = ctype or bor(EAPI.BASE_CHANGE_GFX, EAPI.BASE_CHANGE_SOUND)

    needsapply = table.filter(needsapply, function(i, v)
        if band(v.ctype, ctype) == 0 then
            return true end

        v.ctype = band(v.ctype, bnot(ctype))
        if v.ctype == 0 then
            return false end

        return true end) end

local changes_apply = function()
    local changetypes = 0
    for i, v in pairs(needsapply) do
        changetypes = bor(changetypes, v.ctype) end

    if band(changetypes, EAPI.BASE_CHANGE_GFX) ~= 0 then
        table.insert(updatelater,
            delayed_update_new(EAPI.base_reset_renderer)) end

    if band(changetypes, EAPI.BASE_CHANGE_SOUND) ~= 0 then
        table.insert(updatelater,
            delayed_update_new(EAPI.base_reset_sound)) end end

local changes_get = function()
    return table.map(needsapply, function(v) return v.desc end) end

CAPI.hideui = hideui
CAPI.showui = showui
CAPI.replaceui = replaceui
CAPI.uialign = uialign
CAPI.uiclamp = uiclamp
CAPI.uiwinmover = uiwinmover
CAPI.uitag = uitag
CAPI.uivlist = uivlist
CAPI.uihlist = uihlist
CAPI.uitable = uitable
CAPI.uispace = uispace
CAPI.uifill = uifill
CAPI.uifunfill = uifunfill
CAPI.uiclip = uiclip
CAPI.uiscroll = uiscroll
CAPI.uihscrollbar = uihscrollbar
CAPI.uivscrollbar = uivscrollbar
CAPI.uiscrollbutton = uiscrollbutton
CAPI.uihslider = uihslider
CAPI.uivslider = uivslider
CAPI.uisliderbutton = uisliderbutton
CAPI.uioffset = uioffset
CAPI.uibutton = uibutton
CAPI.uicond = uicond
CAPI.uicondbutton = uicondbutton
CAPI.uitoggle = uitoggle
CAPI.uiimage = uiimage
CAPI.uislotview = uislotview
CAPI.uialtimage = uialtimage
CAPI.uicolor = uicolor
CAPI.uimodcolor = uimodcolor
CAPI.uistretchedimage = uistretchedimage
CAPI.uicroppedimage = uicroppedimage
CAPI.uiborderedimage = uiborderedimage
CAPI.uilabel = uilabel
CAPI.uifunlabel = uifunlabel
CAPI.uitexteditor = uitexteditor
CAPI.uifield = uifield

CAPI.clearchanges = changes_clear
CAPI.applychanges = changes_apply
CAPI.getchanges   = changes_get

return {
    resetcursor   = resetcursor,
    movecursor    = movecursor,
    hascursor     = hascursor,
    getcursorpos  = getcursorpos,
    keypress      = keypress,
    setup         = setup,
    update        = update,
    render        = render,
    clearmainmenu = clearmainmenu,
    change_new    = change_new,
    changes_clear = changes_clear,
    changes_apply = changes_apply,
    changes_get   = changes_get,
    get_world = function() return world end
}
