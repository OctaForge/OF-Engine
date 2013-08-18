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
local cs = require("core.engine.cubescript")
local math2 = require("core.lua.math")
local table2 = require("core.lua.table")
local signal = require("core.events.signal")
local ffi = require("ffi")

local clipboard_set_text, clipboard_get_text, clipboard_has_text, text_draw,
text_get_bounds, text_get_position, text_is_visible, input_is_modifier_pressed,
input_textinput, input_keyrepeat, input_get_key_name, hudmatrix_push,
hudmatrix_translate, hudmatrix_flush, hudmatrix_scale, hudmatrix_pop,
shader_hudnotexture_set, shader_hud_set, gle_color3ub, gle_defvertexf,
gle_begin, gle_end, gle_attrib2f, text_set_font in capi

local var_get = cs.var_get

local max   = math.max
local min   = math.min
local abs   = math.abs
local clamp = math2.clamp
local floor = math.floor
local emit  = signal.emit
local tostring = tostring

local M = require("core.gui.core")
local world = M.get_world()

-- consts
local gl, key = M.gl, M.key

-- input event management
local is_clicked, is_focused = M.is_clicked, M.is_focused
local set_focus = M.set_focus

-- widget types
local register_class = M.register_class

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

local mod = require("core.gui.constants").mod

--[[! Struct: Text_Editor
    Implements a text editor widget. It's a basic editor that supports
    scrolling of text and some extra features like key filter, password
    and so on. It supports copy-paste that interacts with native system
    clipboard. It doesn't have any states.
]]
local Text_Editor = register_class("Text_Editor", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}

        local length = kwargs.length or 0
        local height = kwargs.height or 1
        local scale  = kwargs.scale  or 1
        local font   = kwargs.font

        self.keyfilter  = kwargs.key_filter
        self.init_value = kwargs.value
        self.font  = font
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
        self.pixel_width  = abs(length) * var_get("fontw")
        -- -1 for variable size, i.e. from bounds
        self.pixel_height = -1

        self.password = kwargs.password or false

        -- must always contain at least one line
        self.lines = { kwargs.value or "" }

        if length < 0 and height <= 0 then
            font = text_set_font(font)
            local w, h = text_get_bounds(self.lines[1], self.pixel_width)
            text_set_font(font)
            self.pixel_height = h
        else
            self.pixel_height = var_get("fonth") * max(height, 1)
        end

        return Widget.__init(self, kwargs)
    end,

    clear = function(self)
        self:set_focus(nil)
        return Widget:clear()
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

    is_empty = function(self)
        local lines = self.lines
        return #lines == 1 and lines[1] == ""
    end,

    -- constrain results to within buffer - s = start, e = end, return true if
    -- a selection range also ensures that cy is always within lines[] and cx
    -- is valid
    region = function(self)
        local sx, sy, ex, ey

        local  n = #self.lines
        assert(n != 0)

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

        return ((sx != ex) or (sy != ey)), sx, sy, ex, ey
    end,

    -- also ensures that cy is always within lines[] and cx is valid
    current_line = function(self)
        local  n = #self.lines
        assert(n != 0)

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
                self.lines[self.cy + 1] = current:insert(self.cx + 1, ch)
                self.cx = self.cx + 1
            end
        end
    end,

    movement_mark = function(self)
        self:scroll_on_screen()
        if input_is_modifier_pressed(mod.SHIFT) then
            if not self:region() then self:mark(true) end
        else
            self:mark(false)
        end
    end,

    scroll_on_screen = function(self)
        local font = text_set_font(self.font)
        self:region()
        self.scrolly = clamp(self.scrolly, 0, self.cy)
        local h = 0
        for i = self.cy + 1, self.scrolly + 1, -1 do
            local width, height = text_get_bounds(self.lines[i],
                self.line_wrap and self.pixel_width or -1)
            if h + height > self.pixel_height then
                self.scrolly = i
                break
            end
            h = h + height
        end
        text_set_font(font)
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
                local font = text_set_font(self.font)
                local x, y = text_get_position(str, self.cx + 1,
                    self.pixel_width)
                if y > 0 then
                    self.cx = text_is_visible(str, x, y - FONTH,
                        self.pixel_width)
                    self:scroll_on_screen()
                    text_set_font(font)
                    return nil
                end
                text_set_font(font)
            end
            self.cy = self.cy - 1
            self:scroll_on_screen()
        elseif code == key.DOWN then
            self:movement_mark()
            if self.line_wrap then
                local str = self:current_line()
                local font = text_set_font(self.font)
                local x, y = text_get_position(str, self.cx,
                    self.pixel_width)
                local width, height = text_get_bounds(str,
                    self.pixel_width)
                y = y + var_get("fonth")
                if y < height then
                    self.cx = text_is_visible(str, x, y, self.pixel_width)
                    self:scroll_on_screen()
                    text_set_font(font)
                    return nil
                end
                text_set_font(font)
            end
            self.cy = self.cy + 1
            self:scroll_on_screen()
        elseif code == key.MOUSE4 then
            self.scrolly = self.scrolly - 3
        elseif code == key.MOUSE5 then
            self.scrolly = self.scrolly + 3
        elseif code == key.PAGEUP then
            self:movement_mark()
            if input_is_modifier_pressed(mod_keys) then
                self.cy = 0
            else
                self.cy = self.cy - self.pixel_height / var_get("fonth")
            end
            self:scroll_on_screen()
        elseif code == key.PAGEDOWN then
            self:movement_mark()
            if input_is_modifier_pressed(mod_keys) then
                self.cy = 1 / 0
            else
                self.cy = self.cy + self.pixel_height / var_get("fonth")
            end
            self:scroll_on_screen()
        elseif code == key.HOME then
            self:movement_mark()
            self.cx = 0
            if input_is_modifier_pressed(mod_keys) then
                self.cy = 0
            end
            self:scroll_on_screen()
        elseif code == key.END then
            self:movement_mark()
            self.cx = 1 / 0
            if input_is_modifier_pressed(mod_keys) then
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
                    if input_is_modifier_pressed(mod.SHIFT) then
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
            elseif input_is_modifier_pressed(mod.SHIFT) then
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
            if not input_is_modifier_pressed(mod_keys) then
                return nil
            end
            self:select_all()
            self:scroll_on_screen()
        elseif code == key.C or code == key.X then
            if not input_is_modifier_pressed(mod_keys)
            or not self:region() then
                return nil
            end
            self:copy()
            if code == key.X then self:del() end
            self:scroll_on_screen()
        elseif code == key.V then
            if not input_is_modifier_pressed(mod_keys) then
                return nil
            end
            self:paste()
            self:scroll_on_screen()
        else
            self:scroll_on_screen()
        end
    end,

    hit = function(self, hitx, hity, dragged)
        local max_width = self.line_wrap and self.pixel_width or -1
        local h = 0
        local font = text_set_font(self.font)
        for i = self.scrolly + 1, #self.lines do
            local width, height = text_get_bounds(self.lines[i],
                max_width)
            if h + height > self.pixel_height then break end
            if hity >= h and hity <= h + height then
                local x = text_is_visible(self.lines[i], hitx, hity - h,
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
        text_set_font(font)
    end,

    limit_scroll_y = function(self)
        local font = text_set_font(self.font)
        local max_width = self.line_wrap and self.pixel_width or -1
        local slines = #self.lines
        local ph = self.pixel_height
        while slines > 0 and ph > 0 do
            local width, height = text_get_bounds(self.lines[slines],
                max_width)
            if height > ph then break end
            ph = ph - height
            slines = slines - 1
        end
        text_set_font(font)
        return slines
    end,

    copy = function(self)
        if not self:region() then return nil end
        local str = self:selection_to_string()
        if str then clipboard_set_text(str) end
    end,

    paste = function(self)
        if not clipboard_has_text() then return false end
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
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    commit = function(self)
        self:set_focus(nil)
    end,

    hovering = function(self, cx, cy)
        if is_clicked(self) and is_focused(self) then
            local dx = abs(cx - self.offset_h)
            local dy = abs(cy - self.offset_v)
            local fw, fh = var_get("fontw"), var_get("fonth")
            local th = fh * var_get("uitextrows")
            local sc = self.scale
            local dragged = max(dx, dy) > (fh / 8) * sc / th

            self:hit(floor(cx * th / sc - fw / 2),
                floor(cy * th / sc), dragged)
        end
    end,

    set_focus = function(self, ed)
        if is_focused(ed) then return nil end
        set_focus(ed)
        local ati = ed and ed:allow_text_input()
        input_textinput(ati, 1 << 1) -- TI_GUI
        input_keyrepeat(ati, 1 << 1) -- KR_GUI
    end,

    clicked = function(self, cx, cy)
        self:set_focus(self)
        self:mark()
        self.offset_h = cx
        self.offset_v = cy

        return Widget.clicked(self, cx, cy)
    end,

    key_hover = function(self, code, isdown)
        if code == key.LEFT   or code == key.RIGHT or
           code == key.UP     or code == key.DOWN  or
           code == key.MOUSE4 or code == key.MOUSE5
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
            if self.maxy == 1 then
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
        local filter = self.keyfilter
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

    reset_value = function(self)
        local ival = self.init_value
        if ival and ival != self.lines[1] then
            self:edit_clear(ival)
        end
    end,

    layout = function(self)
        Widget.layout(self)

        local font = text_set_font(self.font)
        if not is_focused(self) then
            self:reset_value()
        end

        if self.line_wrap and self.maxy == 1 then
            local w, h = text_get_bounds(self.lines[1], self.pixel_width)
            self.pixel_height = h
        end

        self.w = max(self.w, (self.pixel_width + var_get("fontw")) *
            self.scale / (var_get("fonth") * var_get("uitextrows")))

        self.h = max(self.h, self.pixel_height *
            self.scale / (var_get("fonth") * var_get("uitextrows"))
        )
        text_set_font(font)
    end,

    draw = function(self, sx, sy)
        local font = text_set_font(self.font)
        hudmatrix_push()

        hudmatrix_translate(sx, sy, 0)
        local s = (self.scale * var_get("uitextscale")) / var_get("fonth")
        hudmatrix_scale(s, s, 1)
        hudmatrix_flush()

        local x, y, hit = var_get("fontw") / 2, 0, is_focused(self)
        local max_width = self.line_wrap and self.pixel_width or -1
        local selection, sx, sy, ex, ey = self:region()

        self.scrolly = clamp(self.scrolly, 0, #self.lines - 1)

        if selection then
            -- convert from cursor coords into pixel coords
            local psx, psy = text_get_position(self.lines[sy + 1], sx,
                max_width)
            local pex, pey = text_get_position(self.lines[ey + 1], ex,
                max_width)
            local maxy = #self.lines
            local h = 0
            for i = self.scrolly + 1, maxy do
                local width, height = text_get_bounds(self.lines[i],
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
                local fonth = var_get("fonth")
                -- crop top/bottom within window
                if  sy < self.scrolly then
                    sy = self.scrolly
                    psy = 0
                    psx = 0
                end
                if  ey > maxy then
                    ey = maxy
                    pey = self.pixel_height - fonth
                    pex = self.pixel_width
                end

                shader_hudnotexture_set()
                gle_color3ub(0xA0, 0x80, 0x80)
                gle_defvertexf(2)
                gle_begin(gl.QUADS)
                if psy == pey then
                    gle_attrib2f(x + psx, y + psy)
                    gle_attrib2f(x + pex, y + psy)
                    gle_attrib2f(x + pex, y + pey + fonth)
                    gle_attrib2f(x + psx, y + pey + fonth)
                else
                    gle_attrib2f(x + psx,              y + psy)
                    gle_attrib2f(x + psx,              y + psy + fonth)
                    gle_attrib2f(x + self.pixel_width, y + psy + fonth)
                    gle_attrib2f(x + self.pixel_width, y + psy)
                    if (pey - psy) > fonth then
                        gle_attrib2f(x, y + psy + fonth)
                        gle_attrib2f(x + self.pixel_width,
                                        y + psy + fonth)
                        gle_attrib2f(x + self.pixel_width, y + pey)
                        gle_attrib2f(x, y + pey)
                    end
                    gle_attrib2f(x,       y + pey)
                    gle_attrib2f(x,       y + pey + fonth)
                    gle_attrib2f(x + pex, y + pey + fonth)
                    gle_attrib2f(x + pex, y + pey)
                end
                gle_end()
                shader_hud_set()
            end
        end

        local h = 0
        for i = self.scrolly + 1, #self.lines do
            local width, height = text_get_bounds(self.lines[i],
                max_width)
            if h + height > self.pixel_height then
                break
            end
            text_draw(tostring(self.password and ("*"):rep(#self.lines[i])
                or self.lines[i]), x, y + h, 255, 255, 255, 255,
                (hit and (self.cy == i - 1)) and self.cx or -1, max_width)

            local fonth = var_get("fonth")
            -- line wrap indicator
            if self.line_wrap and height > fonth then
                local fontw = var_get("fontw")
                shader_hudnotexture_set()
                gle_color3ub(0x80, 0xA0, 0x80)
                gle_defvertexf(2)
                gle_begin(gl.gl.TRIANGLE_STRIP)
                gle_attrib2f(x,                y + h + fonth)
                gle_attrib2f(x,                y + h + height)
                gle_attrib2f(x - fontw / 2, y + h + fonth)
                gle_attrib2f(x - fontw / 2, y + h + height)
                gle_end()
                shader_hud_set()
            end
            h = h + height
        end

        hudmatrix_pop()
        text_set_font(font)

        return Widget.draw(self, sx, sy)
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
        kwargs.height = kwargs.height or 0

        self.value = kwargs.value or ""
        if kwargs.var then
            local varn = kwargs.var
            self.var = varn
            cs.var_new_checked(varn, cs.var_type.string, self.value)
        end

        return Text_Editor.__init(self, kwargs)
    end,

    commit = function(self)
        Text_Editor.commit(self)
        local val = self.lines[1]
        self.value = val
        -- trigger changed signal
        emit(self, "value_changed", val)

        local varn = self.var
        if varn then M.update_var(varn, val) end
    end,

    --[[! Function: key_hover
        Here it just tries to call <key>. If that returns false, it just
        returns Widget.key_hover(self, code, isdown).
    ]]
    key_hover = function(self, code, isdown)
        return self:key(code, isdown) or Widget.key_hover(self, code, isdown)
    end,

    --[[! Function: reset_value
        Resets the field value to the last saved value, effectively canceling
        any sort of unsaved changes.
    ]]
    reset_value = function(self)
        local str = self.value
        if self.lines[1] != str then self:edit_clear(str) end
    end,

    --[[! Function: set_value ]]
    set_value = gen_setter "value"
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
