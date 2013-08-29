--[[! File: lua/core/gui/core_widgets.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Text editor and fields.
]]

local capi = require("capi")
local math2 = require("core.lua.math")
local table2 = require("core.lua.table")
local string2 = require("core.lua.string")
local signal = require("core.events.signal")
local ffi = require("ffi")

local clipboard_set_text, clipboard_get_text, clipboard_has_text, text_draw,
text_get_bounds, text_get_position, text_is_visible, input_is_modifier_pressed,
input_textinput, input_keyrepeat, input_get_key_name, hudmatrix_push,
hudmatrix_translate, hudmatrix_flush, hudmatrix_scale, hudmatrix_pop,
shader_hudnotexture_set, shader_hud_set, gle_color3ub, gle_defvertexf,
gle_begin, gle_end, gle_attrib2f, text_font_push, text_font_pop, text_font_set,
text_font_get_w, text_font_get_h in capi

local max   = math.max
local min   = math.min
local abs   = math.abs
local clamp = math2.clamp
local floor = math.floor
local emit  = signal.emit
local tostring = tostring
local split = string2.split

local M = require("core.gui.core")

-- consts
local gl, key = M.gl, M.key

-- input event management
local is_clicked, is_focused = M.is_clicked, M.is_focused
local set_focus = M.set_focus

-- widget types
local register_class = M.register_class

-- scissoring
local clip_push, clip_pop = M.clip_push, M.clip_pop

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

-- text scale
local get_text_scale = M.get_text_scale

local mod = require("core.gui.constants").mod

local floor_to_fontw = function(n)
    local fw = text_font_get_w()
    return floor(n / fw) * fw
end

local floor_to_fonth = function(n)
    local fh = text_font_get_h()
    return floor(n / fh) * fh
end

local gen_ed_setter = function(name)
    local sname = name .. "_changed"
    return function(self, val)
        self._needs_calc = true
        self[name] = val
        emit(self, sname, val)
    end
end

local chunksize = 256
local ffi_new, ffi_cast, ffi_copy, ffi_string = ffi.new, ffi.cast, ffi.copy,
ffi.string

ffi.cdef [[
    void *memmove(void*, const void*, size_t);
    void *malloc(size_t nbytes);
    void free(void *ptr);
    typedef struct editline_t {
        char *text;
        int len, maxlen;
        int w, h;
    } editline_t;
]]
local C = ffi.C

local editline_MT = {
    __new = function(self, x)
        return ffi_new(self):set(x or "")
    end,
    __tostring = function(self)
        return ffi_string(self.text, self.len)
    end,
    __gc = function(self)
        self:clear()
    end,
    __index = {
        empty = function(self) return self.len <= 0 end,
        clear = function(self)
            C.free(self.text)
            self.text = nil
            self.len, self.maxlen = 0, 0
        end,
        grow = function(self, total, nocopy)
            if total + 1 <= self.maxlen then return false end
            self.maxlen = (total + chunksize) - total % chunksize
            local newtext = ffi_cast("char*", C.malloc(self.maxlen))
            if not nocopy then
                ffi_copy(newtext, self.text, self.len + 1)
            end
            C.free(self.text)
            self.text = newtext
            return true
        end,
        set = function(self, str)
            self:grow(#str, true)
            ffi_copy(self.text, str)
            self.len = #str
            return self
        end,
        prepend = function(self, str)
            local slen = #str
            self:grow(self.len + slen)
            C.memmove(self.text + slen, self.text, self.len + 1)
            ffi_copy(self.text, str)
            self.len += slen
            return self
        end,
        append = function(self, str)
            self:grow(self.len + #str)
            ffi_copy(self.text + self.len, str)
            self.len += #str
            return self
        end,
        del = function(self, start, count)
            if not self.text then return self end
            if start < 0 then
                count, start = count + start, 0
            end
            if count <= 0 or start >= self.len then return self end
            if start + count > self.len then count = self.len - start - 1 end
            C.memmove(self.text + start, self.text + start + count,
                self.len + 1 - (start + count))
            self.len -= count
            return self
        end,
        chop = function(self, newlen)
            if not self.text then return self end
            self.len = clamp(newlen, 0, self.len)
            self.text[self.len] = 0
            return self
        end,
        insert = function(self, str, start, count)
            if not count or count <= 0 then count = #str end
            start = clamp(start, 0, self.len)
            self:grow(self.len + count)
            if self.len == 0 then self.text[0] = 0 end
            C.memmove(self.text + start + count, self.text + start,
                self.len - start + 1)
            ffi_copy(self.text + start, str, count)
            self.len += count
            return self
        end,
        combine_lines = function(self, src)
            if #src == 0 then self:set("")
            else for i, v in ipairs(src) do
                if i != 1 then self:append("\n") end
                if i == 1 then self:set(v.text, v.len)
                else self:insert(v.text, self.len, v.len) end
            end end
            return self
        end,
        calc_bounds = function(self, maxw)
            local w, h = text_get_bounds(tostring(self), maxw)
            self.w, self.h = w, h
            return w, h
        end,
        get_bounds = function(self)
            return self.w, self.h
        end
    }
}
local editline = ffi.metatype("editline_t", editline_MT)

--[[! Struct: Text_Editor
    Implements a text editor widget. It's a basic editor that supports
    scrolling of text and some extra features like key filter and so on.
    It supports copy-paste that interacts with native system clipboard.
    It doesn't have any states.

    Its properties clip_w and clip_h specify the editor bounds in standard
    UI units. The "multiline" property is a boolean and it specifies whether
    the editor has one or multiple lines - if it's single-line, clip_h is
    ignored and the height is instead calculated from line text bounds.

    There are also properties "font" (which is a string specifying which
    font is used for this editor and is optional), key_filter (a string
    of characters that can be used in the editor), value (the initial
    value and the fallback value on reset), scale (the text scale,
    defaults to 1) and line_wrap (by default false, makes the text wrap
    when it has reached maximum width).

    The editor implements the same interface and internal members as Scroller,
    allowing scrollbars to be used with it.
]]
local Text_Editor = register_class("Text_Editor", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        self.clip_w = kwargs.clip_w or 0
        self.clip_h = kwargs.clip_h or 0

        self.virt_w, self.virt_h = 0, 0
        self.text_w, self.text_h = 0, 0

        self.offset_h, self.offset_v = 0, 0
        self.can_scroll = false

        local mline = kwargs.multiline != false and true or false
        self.multiline = mline

        self.key_filter = kwargs.key_filter
        self.value = kwargs.value or ""

        local font = kwargs.font
        self.font  = font
        self.scale = kwargs.scale or 1

        -- cursor position - ensured to be valid after a region() or
        -- currentline()
        self.cx, self.cy = 0, 0
        -- selection mark, mx = -1 if following cursor - avoid direct access,
        -- instead use region()
        self.mx, self.my = -1, -1

        self.line_wrap = kwargs.line_wrap or false

        -- must always contain at least one line
        self.lines = { editline(kwargs.value or "") }

        self._needs_calc = true
        self._needs_offset = false

        return Widget.__init(self, kwargs)
    end,

    clear = function(self)
        self:set_focus(nil)
        self:bind_h_scrollbar()
        self:bind_v_scrollbar()
        return Widget.clear(self)
    end,

    edit_clear = function(self, init)
        self._needs_calc = true
        self.cx, self.cy = 0, 0
        self.offset_h, self.offset_v = 0, 0
        self:mark()
        if init == false then
            self.lines = {}
        else
            local lines = {}
            if type(init) != "table" then
                init = split(init, "\n")
            end
            for i = 1, #init do lines[i] = editline(init[i]) end
            self.lines = lines
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

    is_empty = function(self)
        local lines = self.lines
        return #lines == 1 and lines[1].text[0] == 0
    end,

    -- constrain results to within buffer - s = start, e = end, return true if
    -- a selection range also ensures that cy is always within lines[] and cx
    -- is valid
    region = function(self)
        local sx, sy, ex, ey

        local n = #self.lines
        local cx, cy, mx, my = self.cx, self.cy, self.mx, self.my

        if  cy < 0 then
            cy = 0
        elseif cy >= n then
            cy = n - 1
        end
        local len = self.lines[cy + 1].len
        if  cx < 0 then
            cx = 0
        elseif cx > len then
            cx = len
        end
        if mx >= 0 then
            if  my < 0 then
                my = 0
            elseif my >= n then
                my = n - 1
            end
            len = self.lines[my + 1].len
            if  mx > len then
                mx = len
            end
        end
        sx, sy = (mx >= 0) and mx or cx, (mx >= 0) and my or cy
        ex, ey = cx, cy
        if sy > ey then
            sy, ey = ey, sy
            sx, ex = ex, sx
        elseif sy == ey and sx > ex then
            sx, ex = ex, sx
        end

        self.cx, self.cy, self.mx, self.my = cx, cy, mx, my

        return ((sx != ex) or (sy != ey)), sx, sy, ex, ey
    end,

    -- also ensures that cy is always within lines[] and cx is valid
    current_line = function(self)
        local  n = #self.lines
        assert(n != 0)

        if     self.cy <  0 then self.cy = 0
        elseif self.cy >= n then self.cy = n - 1 end

        local len = self.lines[self.cy + 1].len

        if     self.cx < 0   then self.cx = 0
        elseif self.cx > len then self.cx = len end

        return self.lines[self.cy + 1]
    end,

    to_string = function(self)
        return tostring(editline():combine_lines(self.lines))
    end,

    selection_to_string = function(self)
        local buf = {}
        local sx, sy, ex, ey = select(2, self:region())

        for i = 1, 1 + ey - sy do
            local y = sy + i - 1
            local line = tostring(self.lines[y + 1])
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
        self._needs_calc = true
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

        self._needs_calc = true

        if sy == ey then
            if sx == 0 and ex == self.lines[ey + 1].len then
                self:remove_lines(sy + 1, 1)
            else self.lines[sy + 1]:del(sx, ex - sx)
            end
        else
            if ey > sy + 1 then
                self:remove_lines(sy + 2, ey - (sy + 1))
                ey = sy + 1
            end

            if ex == self.lines[ey + 1].len then
                self:remove_lines(ey + 1, 1)
            else
                self.lines[ey + 1]:del(0, ex)
            end

            if sx == 0 then
                self:remove_lines(sy + 1, 1)
            else
                self.lines[sy + 1]:del(sx, self.lines[sy].len - sx)
            end
        end

        if #self.lines == 0 then self.lines = { editline() } end
        self:mark()
        self.cx, self.cy = sx, sy

        local current = self:current_line()
        if self.cx > current.len and self.cy < #self.lines - 1 then
            current:append(tostring(self.lines[self.cy + 2]))
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

        self._needs_calc = true

        self:del()
        local current = self:current_line()

        if ch == "\n" then
            if self.multiline then
                local newline = editline(tostring(current):sub(self.cx + 1))
                current:chop(self.cx)
                self.cy = min(#self.lines, self.cy + 1)
                table.insert(self.lines, self.cy + 1, newline)
            else
                current:chop(self.cx)
            end
            self.cx = 0
        else
            if self.cx <= current.len then
                current:insert(ch, self.cx, 1)
                self.cx = self.cx + 1
            end
        end
    end,

    movement_mark = function(self)
        self._needs_offset = true
        if input_is_modifier_pressed(mod.SHIFT) then
            if not self:region() then self:mark(true) end
        else
            self:mark(false)
        end
    end,

    edit_key = function(self, code)
        local mod_keys = (ffi.os == "OSX") and mod.GUI or mod.CTRL
        if code == key.UP then
            self:movement_mark()
            if self.line_wrap then
                local str = tostring(self:current_line())
                text_font_push()
                text_font_set(self.font)
                local x, y = text_get_position(str, self.cx + 1, self.pw)
                if y > 0 then
                    self.cx = text_is_visible(str, x, y - text_font_get_h(),
                        self.pw)
                    self._needs_offset = true
                    text_font_pop()
                    return nil
                end
                text_font_pop()
            end
            self.cy = self.cy - 1
            self._needs_offset = true
        elseif code == key.DOWN then
            self:movement_mark()
            if self.line_wrap then
                local str = tostring(self:current_line())
                text_font_push()
                text_font_set(self.font)
                local x, y = text_get_position(str, self.cx, self.pw)
                local width, height = text_get_bounds(str, self.pw)
                y = y + text_font_get_h()
                if y < height then
                    self.cx = text_is_visible(str, x, y, self.pw)
                    self._needs_offset = true
                    text_font_pop()
                    return nil
                end
                text_font_pop()
            end
            self.cy = self.cy + 1
            self._needs_offset = true
        elseif code == key.MOUSEWHEELUP or code == key.MOUSEWHEELDOWN then
            if self.can_scroll then
                local sb = self.v_scrollbar
                local fac = 6 * text_font_get_h() * self:draw_scale()
                self:scroll_v((code == key.MOUSEWHEELUP and -fac or fac)
                    * (sb and sb.arrow_speed or 0.5))
            end
        elseif code == key.PAGEUP then
            self:movement_mark()
            if input_is_modifier_pressed(mod_keys) then
                self.cy = 0
            else
                self.cy = self.cy - self.ph / text_font_get_h()
            end
            self._needs_offset = true
        elseif code == key.PAGEDOWN then
            self:movement_mark()
            if input_is_modifier_pressed(mod_keys) then
                self.cy = 1 / 0
            else
                self.cy = self.cy + self.ph / text_font_get_h()
            end
            self._needs_offset = true
        elseif code == key.HOME then
            self:movement_mark()
            self.cx = 0
            if input_is_modifier_pressed(mod_keys) then
                self.cy = 0
            end
            self._needs_offset = true
        elseif code == key.END then
            self:movement_mark()
            self.cx = 1 / 0
            if input_is_modifier_pressed(mod_keys) then
                self.cy = 1 / 0
            end
            self._needs_offset = true
        elseif code == key.LEFT then
            self:movement_mark()
            if     self.cx > 0 then self.cx = self.cx - 1
            elseif self.cy > 0 then
                self.cx = 1 / 0
                self.cy = self.cy - 1
            end
            self._needs_offset = true
        elseif code == key.RIGHT then
            self:movement_mark()
            if self.cx < self.lines[self.cy + 1].len then
                self.cx = self.cx + 1
            elseif self.cy < #self.lines - 1 then
                self.cx = 0
                self.cy = self.cy + 1
            end
            self._needs_offset = true
        elseif code == key.DELETE then
            if not self:del() then
                self._needs_calc = true
                local current = self:current_line()
                if self.cx < current.len then
                    current:del(self.cx, 1)
                elseif self.cy < #self.lines - 1 then
                    -- combine with next line
                    current:append(tostring(self.lines[self.cy + 2]))
                    self:remove_lines(self.cy + 2, 1)
                end
            end
            self._needs_offset = true
        elseif code == key.BACKSPACE then
            if not self:del() then
                self._needs_calc = true
                local current = self:current_line()
                if self.cx > 0 then
                    current:del(self.cx - 1, 1)
                    self.cx = self.cx - 1
                elseif self.cy > 0 then
                    -- combine with previous line
                    self.cx = self.lines[self.cy].len
                    self.lines[self.cy]:append(tostring(current))
                    self:remove_lines(self.cy + 1, 1)
                    self.cy = self.cy - 1
                end
            end
            self._needs_offset = true
        elseif code == key.RETURN then
            -- maintain indentation
            self._needs_calc = true
            local str = tostring(self:current_line())
            self:insert("\n")
            for c in str:gmatch "." do if c == " " or c == "\t" then
                self:insert(c) else break
            end end
            self._needs_offset = true
        elseif code == key.TAB then
            local b, sx, sy, ex, ey = self:region()
            if b then
                self._needs_calc = true
                for i = sy, ey do
                    if input_is_modifier_pressed(mod.SHIFT) then
                        local rem = 0
                        for j = 1, min(4, self.lines[i + 1].len) do
                            if tostring(self.lines[i + 1]):sub(j, j) == " "
                            then
                                rem = rem + 1
                            else
                                if tostring(self.lines[i + 1]):sub(j, j)
                                == "\t" and j == 0 then
                                    rem = rem + 1
                                end
                                break
                            end
                        end
                        self.lines[i + 1]:del(0, rem)
                        if i == self.my then self.mx = self.mx
                            - (rem > self.mx and self.mx or rem) end
                        if i == self.cy then self.cx = self.cx -  rem end
                    else
                        self.lines[i + 1]:prepend("\t")
                        if i == self.my then self.mx = self.mx + 1 end
                        if i == self.cy then self.cx = self.cx + 1 end
                    end
                end
            elseif input_is_modifier_pressed(mod.SHIFT) then
                if self.cx > 0 then
                    self._needs_calc = true
                    local cy = self.cy
                    local lines = self.lines
                    if tostring(lines[cy + 1]):sub(1, 1) == "\t" then
                        lines[cy + 1]:del(0, 1)
                        self.cx = self.cx - 1
                    else
                        for j = 1, min(4, #lines[cy + 1]) do
                            if tostring(lines[cy + 1]):sub(1, 1) == " " then
                                lines[cy + 1]:del(0, 1)
                                self.cx = self.cx - 1
                            end
                        end
                    end
                end
            else
                self:insert("\t")
            end
            self._needs_offset = true
        elseif code == key.A then
            if not input_is_modifier_pressed(mod_keys) then
                self._needs_offset = true
                return nil
            end
            self:select_all()
            self._needs_offset = true
        elseif code == key.C or code == key.X then
            if not input_is_modifier_pressed(mod_keys)
            or not self:region() then
                self._needs_offset = true
                return nil
            end
            self:copy()
            if code == key.X then self:del() end
            self._needs_offset = true
        elseif code == key.V then
            if not input_is_modifier_pressed(mod_keys) then
                self._needs_offset = true
                return nil
            end
            self:paste()
            self._needs_offset = true
        else
            self._needs_offset = true
        end
    end,

    hit = function(self, hitx, hity, dragged)
        local k = self:draw_scale()
        local max_width = self.line_wrap and self.pw or -1
        text_font_push()
        text_font_set(self.font)
        local fd = self:get_first_drawable_line()
        if fd then
            local h = 0
            hitx, hity = (hitx - self.offset_h) / k, hity / k
            for i = fd, #self.lines do
                if h > self.ph then break end
                local linestr = tostring(self.lines[i])
                local width, height = self.lines[i]:get_bounds()
                if hity >= h and hity <= h + height then
                    local x = text_is_visible(linestr, hitx, hity - h,
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
        end
        text_font_pop()
    end,

    copy = function(self)
        if not self:region() then return nil end
        self._needs_calc = true
        local str = self:selection_to_string()
        if str then clipboard_set_text(str) end
    end,

    paste = function(self)
        if not clipboard_has_text() then return false end
        self._needs_calc = true
        if self:region() then self:del() end
        local  str = clipboard_get_text()
        if not str then return false end
        self:insert(str)
        return true
    end,

    target = function(self, cx, cy)
        return Widget.target(self, cx, cy) or self
    end,

    hover = function(self, cx, cy)
        local oh, ov, vw, vh = self.offset_h, self.offset_v,
            self.virt_w, self.virt_h
        self.can_scroll = ((cx + oh) < vw) and ((cy + ov) < vh)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        local oh, ov, vw, vh = self.offset_h, self.offset_v,
            self.virt_w, self.virt_h
        self.can_scroll = ((cx + oh) < vw) and ((cy + ov) < vh)
        return self:target(cx, cy) and self
    end,

    commit = function(self)
        self:set_focus(nil)
    end,

    holding = function(self, cx, cy, code)
        if code == key.MOUSELEFT then
            local w, h, vd = self.w, self.h, 0
            if cy > h then
                vd = cy - h
            elseif cy < 0 then
                vd = cy
            end
            cx, cy = clamp(cx, 0, w), clamp(cy, 0, h)
            if vd != 0 then
                self:scroll_v(vd)
            end
            self:hit(cx, cy, max(abs(cx - self._oh), abs(cy - self._ov))
                > (text_font_get_h() / 8 * self:draw_scale()))
        end
    end,

    set_focus = function(self, ed)
        if is_focused(ed) then return nil end
        set_focus(ed)
        local ati = ed and ed:allow_text_input()
        input_textinput(ati, 1 << 1) -- TI_GUI
        input_keyrepeat(ati, 1 << 1) -- KR_GUI
    end,

    clicked = function(self, cx, cy, code)
        self:set_focus(self)
        self:mark()
        self._oh, self._ov = cx, cy

        return Widget.clicked(self, cx, cy, code)
    end,

    key_hover = function(self, code, isdown)
        if code == key.LEFT         or code == key.RIGHT or
           code == key.UP           or code == key.DOWN  or
           code == key.MOUSEWHEELUP or code == key.MOUSEWHEELDOWN
        then
            if isdown then self:edit_key(code) end
            return true
        end
        return Widget.key_hover(self, code, isdown)
    end,

    key = function(self, code, isdown)
        if Widget.key(self, code, isdown) then return true end
        if not is_focused(self) then return false end

        if code == key.ESCAPE then
            if isdown then self:set_focus(nil) end
            return true
        elseif code == key.RETURN or code == key.TAB then
            if not self.multiline then
                if isdown then self:commit() end
                return true
            end
        elseif code == key.KP_ENTER then
            if isdown then self:commit() end
            return true
        end
        if isdown then self:edit_key(code) end
        return true
    end,

    allow_text_input = function(self) return true end,

    text_input = function(self, str)
        if Widget.text_input(self, str) then return true end
        if not is_focused(self) or not self:allow_text_input() then
            return false
        end
        local filter = self.key_filter
        if not filter then
            self:insert(str)
        else
            local buf = {}
            for ch in str:gmatch(".") do
                if filter:find(ch) then buf[#buf + 1] = ch end
            end
            self:insert(table.concat(buf))
        end
        return true
    end,

    --[[! Function: reset_value
        Resets the field value to the last saved value, effectively canceling
        any sort of unsaved changes.
    ]]
    reset_value = function(self)
        local str = self.value or ""
        local strlines = split(str, "\n")
        local lines = self.lines
        local cond = #strlines != #lines
        if not cond then
            for i = 1, #strlines do
                if strlines[i] != tostring(lines[i]) then
                    cond = true
                    break
                end
            end
        end
        if cond then self:edit_clear(strlines) end
    end,

    draw_scale = function(self)
        local scale = self.scale
        return (abs(scale) * get_text_scale(scale < 0)) / text_font_get_h()
    end,

    calc_dimensions = function(self, maxw)
        if not self._needs_calc then
            return self.text_w, self.text_h
        end
        self._needs_calc = false
        local lines = self.lines
        local w, h = 0, 0
        local ov = 0
        local k = self:draw_scale()
        for i = 1, #lines do
            local tw, th = lines[i]:calc_bounds(maxw)
            w, h = w + tw, h + th
        end
        w, h = w * k, h * k
        self.text_w, self.text_h = w, h
        return w, h
    end,

    get_first_drawable_line = function(self)
        local lines = self.lines
        local ov = self.offset_v / self:draw_scale()
        for i = 1, #lines do
            local tw, th = lines[i]:get_bounds()
            ov -= th
            if ov < 0 then return i end
        end
    end,

    get_last_drawable_line = function(self)
        local lines = self.lines
        local ov = (self.offset_v + self.h) / self:draw_scale()
        for i = 1, #lines do
            local tw, th = lines[i]:get_bounds()
            ov -= th
            if ov <= 0 then return i end
        end
    end,

    fix_h_offset = function(self, k, maxw, del)
        local fontw = text_font_get_w() * k
        local x, y = text_get_position(tostring(self.lines[self.cy + 1]),
            self.cx, maxw)

        x *= k
        local w, oh = self.w, self.offset_h
        if (x + fontw + (del and 0 or oh)) > w then
           self.offset_h = w - x - fontw
        elseif (x + oh) < 0 then
            self.offset_h = -x
        elseif (x + fontw) <= w and oh >= -fontw then
            self.offset_h = 0
        end
    end,

    fix_v_offset = function(self, k)
        local lines = self.lines

        local cy = self.cy + 1
        local oov = self.offset_v

        local yoff = 0
        for i = 1, cy do
            local tw, th = lines[i]:get_bounds()
            yoff += th
        end

        if yoff <= (oov / k) then
            self.offset_v += yoff * k - oov - text_font_get_h() * k
        elseif yoff > ((oov + self.h) / k) then
            self.offset_v += yoff * k - (oov + self.h)
        end
    end,

    layout = function(self)
        Widget.layout(self)

        local old_text_w = self.text_w

        text_font_push()
        text_font_set(self.font)
        if not is_focused(self) then
            self:reset_value()
        end

        local lw, ml = self.line_wrap, self.multiline
        local k = self:draw_scale()
        local pw, ph = self.clip_w / k
        if ml then
            ph = self.clip_h / k
        else
            local w, h = text_get_bounds(tostring(self.lines[1]),
                lw and pw or -1)
            ph = h
        end

        local maxw = lw and pw or -1
        local tw, th = self:calc_dimensions(maxw)

        self.virt_w = max(self.w, tw)
        self.virt_h = max(self.h, th)

        self.w = max(self.w, pw * k)
        self.h = max(self.h, ph * k)
        self.pw, self.ph = pw, ph

        if self._needs_offset then
            self:region()
            self:fix_h_offset(k, maxw, old_text_w > tw)
            self:fix_v_offset(k)
            self._needs_offset = false
        end

        text_font_pop()
    end,

    get_clip = function(self)
        return self.clip_w, (self.multiline and self.clip_h or self.h)
    end,

    draw_selection = function(self, first_drawable, x)
        local selection, sx, sy, ex, ey = self:region()
        if not selection then return nil end
        local max_width = self.line_wrap and self.pw or -1
        -- convert from cursor coords into pixel coords
        local psx, psy = text_get_position(tostring(self.lines[sy + 1]), sx,
            max_width)
        local pex, pey = text_get_position(tostring(self.lines[ey + 1]), ex,
            max_width)
        local maxy = #self.lines
        local h = 0
        for i = first_drawable, maxy do
            if h > self.ph then
                maxy = i
                break
            end
            local width, height = text_get_bounds(tostring(self.lines[i]),
                max_width)
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

        if ey >= first_drawable - 1 and sy <= maxy then
            local fonth = text_font_get_h()
            -- crop top/bottom within window
            if  sy < first_drawable - 1 then
                sy = first_drawable - 1
                psy = 0
                psx = 0
            end
            if  ey > maxy then
                ey = maxy
                pey = self.ph - fonth
                pex = self.pw
            end

            shader_hudnotexture_set()
            gle_color3ub(0xA0, 0x80, 0x80)
            gle_defvertexf(2)
            gle_begin(gl.QUADS)
            if psy == pey then
                gle_attrib2f(x + psx, psy)
                gle_attrib2f(x + pex, psy)
                gle_attrib2f(x + pex, pey + fonth)
                gle_attrib2f(x + psx, pey + fonth)
            else
                gle_attrib2f(x + psx,     psy)
                gle_attrib2f(x + psx,     psy + fonth)
                gle_attrib2f(x + self.pw, psy + fonth)
                gle_attrib2f(x + self.pw, psy)
                if (pey - psy) > fonth then
                    gle_attrib2f(x,           psy + fonth)
                    gle_attrib2f(x + self.pw, psy + fonth)
                    gle_attrib2f(x + self.pw, pey)
                    gle_attrib2f(x,           pey)
                end
                gle_attrib2f(x,       pey)
                gle_attrib2f(x,       pey + fonth)
                gle_attrib2f(x + pex, pey + fonth)
                gle_attrib2f(x + pex, pey)
            end
            gle_end()
            shader_hud_set()
        end
    end,

    draw_line_wrap = function(self, h, height)
        if not self.line_wrap then return nil end
        local fonth = text_font_get_h()
        shader_hudnotexture_set()
        gle_color3ub(0x3C, 0x3C, 0x3C)
        gle_defvertexf(2)
        gle_begin(gl.LINE_STRIP)
        gle_attrib2f(0, h + fonth)
        gle_attrib2f(0, h + height)
        gle_end()
        shader_hud_set()
    end,

    draw = function(self, sx, sy)
        text_font_push()
        text_font_set(self.font)

        local cw, ch = self:get_clip()
        local fontw  = text_font_get_w()
        local clip = (cw != 0 and (self.virt_w + fontw) > cw)
                  or (ch != 0 and  self.virt_h          > ch)

        if clip then clip_push(sx, sy, cw, ch) end

        hudmatrix_push()

        hudmatrix_translate(sx, sy, 0)
        local k = self:draw_scale()
        hudmatrix_scale(k, k, 1)
        hudmatrix_flush()

        local hit = is_focused(self)

        local pwidth = self.pw
        local max_width = self.line_wrap and pwidth or -1

        local fd = self:get_first_drawable_line()
        if fd then
            local xoff = self.offset_h / k

            self:draw_selection(fd, xoff)

            local h = 0
            local fonth = text_font_get_h()
            for i = fd, #self.lines do
                local line = tostring(self.lines[i])
                local width, height = text_get_bounds(line,
                    max_width)
                if h >= self.ph then break end
                text_draw(line, xoff, h, 255, 255, 255, 255,
                    (hit and (self.cy == i - 1)) and self.cx or -1, max_width)

                if height > fonth then self:draw_line_wrap(h, height) end
                h = h + height
            end
        end

        hudmatrix_pop()

        Widget.draw(self, sx, sy)
        if clip then clip_pop() end

        text_font_pop()
    end,

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

    get_h_limit = function(self) return max(self.virt_w - self.w, 0) end,
    get_v_limit = function(self) return max(self.virt_h - self.h, 0) end,

    get_h_offset = function(self)
        return self.offset_h / max(self.virt_w, self.w)
    end,

    get_v_offset = function(self)
        return self.offset_v / max(self.virt_h, self.h)
    end,

    get_h_scale = function(self) return self.w / max(self.virt_w, self.w) end,
    get_v_scale = function(self) return self.h / max(self.virt_h, self.h) end,

    set_h_scroll = function(self, hs)
        self.offset_h = clamp(hs, 0, self:get_h_limit())
        emit(self, "h_scroll_changed", self:get_h_offset())
    end,

    set_v_scroll = function(self, vs)
        self.offset_v = clamp(vs, 0, self:get_v_limit())
        emit(self, "v_scroll_changed", self:get_v_offset())
    end,

    scroll_h = function(self, hs) self:set_h_scroll(self.offset_h + hs) end,
    scroll_v = function(self, vs) self:set_v_scroll(self.offset_v + vs) end,

    set_clip_w     = gen_ed_setter "clip_w",
    set_clip_h     = gen_ed_setter "clip_h",

    set_multiline  = gen_ed_setter "multiline",

    set_key_filter = gen_setter "key_filter",

    set_value = function(self, val)
        val = tostring(val)
        self.value = val
        emit("value_changed", val)
        self:reset_value()
    end,

    set_font      = gen_ed_setter "font",
    set_line_wrap = gen_ed_setter "line_wrap"
})
M.Text_Editor = Text_Editor

--[[! Struct: Field
    Represents a field, a specialization of <Text_Editor>. It has the same
    properties. The "value" property changed meaning - now it stores the
    current value - there is no fallback for fields (it still is the default
    value though).

    Fields are also by default not multiline. You can still explicitly
    override this in kwargs or by setting the property.
]]
M.Field = register_class("Field", Text_Editor, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        kwargs.multiline = kwargs.multiline or false
        return Text_Editor.__init(self, kwargs)
    end,

    commit = function(self)
        Text_Editor.commit(self)
        local val = tostring(self.lines[1])
        self.value = val
        -- trigger changed signal
        emit(self, "value_changed", val)
    end,

    --[[! Function: key_hover
        Here it just tries to call <key>. If that returns false, it just
        returns Widget.key_hover(self, code, isdown).
    ]]
    key_hover = function(self, code, isdown)
        return self:key(code, isdown) or Widget.key_hover(self, code, isdown)
    end
})

--[[! Struct: Key_Field
    Derived from <Field>. Represents a keyfield - it catches keypresses and
    inserts key names. Useful when creating an e.g. keybinding GUI.
]]
M.Key_Field = register_class("Key_Field", M.Field, {
    allow_text_input = function(self) return false end,

    key_insert = function(self, code)
        local keyname = input_get_key_name(code)
        if keyname then
            if not self:is_empty() then self:insert(" ") end
            self:insert(keyname)
        end
    end,

    --[[! Function: key_raw
        Overloaded. Commits on the escape key, inserts the name otherwise.
    ]]
    key_raw = function(code, isdown)
        if Widget.key_raw(code, isdown) then return true end
        if not is_focused(self) or not isdown then return false end
        if code == key.ESCAPE then self:commit()
        else self:key_insert(code) end
        return true
    end
})
