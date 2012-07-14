local band = math.band
local bor  = math.bor
local bnot = math.bnot
local blsh = math.lsh
local brsh = math.rsh
local EAPI = _G["EAPI"]

local clipboard = {}

Editor = table.classify({
    __init = function(self, name, mode, init_value, password)
        -- editor mode - 1 - keep while focused, 2 - keep while used in gui,
        -- 3 - keep forever (i.e. until mode changes)
        self.mode = mode

        self.active   = true
        self.rendered = false

        self.name     = name
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
        self.maxx = -1
        self.maxy = -1

        self.scrolly = 0 -- vertical scroll offset

        self.line_wrap = false
        self.pixel_width  = -1 -- required for up/down/hit/draw/bounds
        self.pixel_height = -1 -- -1 for variable size, i.e. from bounds

        self.password = password or false

        -- must always contain at least one line
        self.lines = { init_value or "" }
    end,

    __tostring = function(self)
        return table.concat(self.lines, "\n")
    end,

    clear = function(self, init)
        self.cx = 0
        self.cy = 0

        self:mark(false)

        if init == false then
            self.lines = {}
        else
            self.lines = { init or "" }
        end
    end,

    set_file = function(self, filename)
        self.filename = filename
    end,

    load_file = function(self)
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
                lines = table.slice(lines, 1, maxy)
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

    save_file = function(self)
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
    region = function(self, kwargs)
        kwargs = kwargs or {}

        local n = #self.lines
        assert(n ~= 0)

        if     self.cy <  0 then self.cy = 0
        elseif self.cy >= n then self.cy = n - 1 end

        local len = #self.lines[self.cy + 1]

        if     self.cx < 0   then self.cx = 0
        elseif self.cx > len then self.cx = len end

        if self.mx >= 0 then
            if     self.my <  0 then self.my = 0
            elseif self.my >= n then self.my = n - 1 end

            local len = #self.lines[self.my + 1]
            if self.mx > len then self.mx = len end
        end

        kwargs.sx = (self.mx >= 0) and self.mx or self.cx
        kwargs.sy = (self.mx >= 0) and self.my or self.cy -- XXX

        kwargs.ex = self.cx
        kwargs.ey = self.cy

        if kwargs.sy > kwargs.ey then
            local t1 = kwargs.sy
            local t2 = kwargs.sx

            kwargs.sy = kwargs.ey
            kwargs.ey = t1
            kwargs.sx = kwargs.ex
            kwargs.ex = t2
        elseif kwargs.sy == kwargs.ey and kwargs.sx > kwargs.ex then
            local t = kwargs.sx
            kwargs.sx = kwargs.ex
            kwargs.ex = t
        end

        return (kwargs.sx ~= kwargs.ex) or (kwargs.sy ~= kwargs.ey)
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

        local kwargs = {}
        self:region(kwargs)

        for i = 1, 1 + kwargs.ey - kwargs.sy do
            if b.maxy ~= -1 and #b.lines >= b.maxy then break end

            local y = kwargs.sy + i
            local line = self.lines[y]

            if y - 1 == kwargs.sy then line = line:sub(kwargs.sx + 1) end
            table.insert(b.lines, line)
        end

        if #b.lines == 0 then b.lines = { "" } end
    end,

    selection_to_string = function(self)
        local buf    = {}
        local kwargs = {}
        self:region(kwargs)

        for i = 1, 1 + kwargs.ey - kwargs.sy do
            local y = kwargs.sy + i
            local line = self.lines[y]

            if y - 1 == kwargs.sy then line = line:sub(kwargs.sx + 1) end

            table.insert(buf, line)
            table.insert(buf, "\n")
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
        local kwargs = {}
        if not self:region(kwargs) then
            self:mark(false)
            return false
        end

        if kwargs.sy == kwargs.ey then
            if kwargs.sx == 0 and kwargs.ex == #self.lines[kwargs.ey + 1] then
                self:remove_lines(kwargs.sy + 1, 1)
            else self.lines[kwargs.sy + 1]:del(
                kwargs.sx + 1, kwargs.ex - kwargs.sx)
            end
        else
            if kwargs.ey > kwargs.sy + 1 then
                self:remove_lines(kwargs.sy + 2, kwargs.ey - (kwargs.sy + 1))
                kwargs.ey = kwargs.sy + 1
            end

            if kwargs.ex == #self.lines[kwargs.ey + 1] then
                self:remove_lines(kwargs.ey + 1, 1)
            else
                self.lines[kwargs.ey + 1]:del(1, kwargs.ex)
            end

            if kwargs.sx == 0 then
                self:remove_lines(kwargs.sy + 1, 1)
            else
                self.lines[kwargs.sy + 1]:del(kwargs.sx + 1,
                    #self.lines[kwargs.sy] - kwargs.sx)
            end
        end

        if #self.lines == 0 then self.lines = { "" } end
        self:mark(false)

        self.cx = kwargs.sx
        self.cy = kwargs.sy

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
                table.insert(self.cy, b.lines[i])
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

    key = function(self, code, cooked)
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
                    y = y + EVAR.fonth
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
                    self.cy = self.cy - self.pixel_height / EVAR.fonth
                end
                self:scroll_on_screen()
            end),

            case(EAPI.INPUT_KEY_PAGEDOWN, function()
                self:movement_mark()
                if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
                    self.cy = 1 / 0
                else
                    self.cy = self.cy + self.pixel_height / EVAR.fonth
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
                    self.cx = self.cx - 1
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
                local kwargs = {}
                if self:region(kwargs) then
                    for i = kwargs.sy, kwargs.ey do
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
                elseif cooked ~= 0 then
                    self:insert(string.char(cooked))
                end
                self:scroll_on_screen()
            end),

            case({ EAPI.INPUT_KEY_A, EAPI.INPUT_KEY_X, EAPI.INPUT_KEY_C, EAPI.INPUT_KEY_V }, function()
                if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 or cooked == 0 then
                    return nil
                end
                self:insert(string.char(cooked))
                self:scroll_on_screen()
            end),

            default(function()
                self:insert(string.char(cooked))
                self:scroll_on_screen()
            end))

        if band(EAPI.input_get_modifier_state(), mod_keys) ~= 0 then
            if code == EAPI.INPUT_KEY_A then
                self:select_all()
            elseif code == EAPI.INPUT_KEY_X or code == EAPI.INPUT_KEY_C then
                clipboard = {}

                local kwargs = {}
                self:region(kwargs)

                for i = 1, 1 + kwargs.ey - kwargs.sy do
                    local y = kwargs.sy + i
                    local line = self.lines[y]

                    if y - 1 == kwargs.sy then line = line:sub(kwargs.sx + 1) end
                    table.insert(clipboard, line)
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
                        table.insert(self.cy, clipboard[i])
                    end
                end end
            end
            self:scroll_on_screen()
        end
    end,

    draw = function(self, x, y, color, hit)
        local max_width = self.line_wrap and self.pixel_width or -1

        local kwargs = {}
        local selection = self:region(kwargs)

        self.scrolly = math.clamp(self.scrolly, 0, #self.lines - 1)

        if selection then
            -- convert from cursor coords into pixel coords
            local psx, psy, pex, pey = ffi.new "int[1]", ffi.new "int[1]",
                                       ffi.new "int[1]", ffi.new "int[1]"
            EAPI.gui_text_pos(self.lines[kwargs.sy + 1], kwargs.sx, psx, psy, max_width)
            EAPI.gui_text_pos(self.lines[kwargs.ey + 1], kwargs.ex, pex, pey, max_width)
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
                if i == kwargs.sy + 1 then
                    psy = psy + h
                end
                if i == kwargs.ey + 1 then
                    pey = pey + h
                    break
                end
                h = h + height
            end
            maxy = maxy - 1

            if kwargs.ey >= self.scrolly and kwargs.sy <= maxy then
                -- crop top/bottom within window
                if  kwargs.sy < self.scrolly then
                    kwargs.sy = self.scrolly
                    psy = 0
                    psx = 0
                end
                if  kwargs.ey > maxy then
                    kwargs.ey = maxy
                    pey = self.pixel_height - EVAR.fonth
                    pex = self.pixel_width
                end

                if psy == pey then
                    EAPI.gui_draw_primitive(EAPI.GUI_QUADS, 0xA0, 0x80, 0x80,
                        255, false, 4,
                        x + psx, y + psy,
                        x + pex, y + psy,
                        x + pex, y + pey + EVAR.fonth,
                        x + psx, y + pey + EVAR.fonth)
                else
                    if pey - psy > EVAR.fonth then
                        EAPI.gui_draw_primitive(EAPI.GUI_QUADS,
                            0xA0, 0x80, 0x80, 255, false, 12,
                            x + psx,              y + psy,
                            x + psx,              y + psy + EVAR.fonth,
                            x + self.pixel_width, y + psy + EVAR.fonth,
                            x + self.pixel_width, y + psy,

                            x,                    y + psy + EVAR.fonth,
                            x + self.pixel_width, y + psy + EVAR.fonth,
                            x + self.pixel_width, y + pey,
                            x,                    y + pey,

                            x,                    y + pey,
                            x,                    y + pey + EVAR.fonth,
                            x + pex,              y + pey + EVAR.fonth,
                            x + pex,              y + pey)
                    else
                        EAPI.gui_draw_primitive(EAPI.GUI_QUADS,
                            0xA0, 0x80, 0x80, 255, false, 8,
                            x + psx,              y + psy,
                            x + psx,              y + psy + EVAR.fonth,
                            x + self.pixel_width, y + psy + EVAR.fonth,
                            x + self.pixel_width, y + psy,

                            x,                    y + pey,
                            x,                    y + pey + EVAR.fonth,
                            x + pex,              y + pey + EVAR.fonth,
                            x + pex,              y + pey)
                    end
                end
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
            if self.line_wrap and height > EVAR.fonth then
                EAPI.gui_draw_primitive(EAPI.GUI_TRIANGLE_STRIP,
                    0x80, 0xA0, 0x80, 255, false, 4,
                    x,                  y + h + EVAR.fonth,
                    x,                  y + h + height,
                    x - EVAR.fontw / 2, y + h + EVAR.fonth,
                    x - EVAR.fontw / 2, y + h + height)
            end

            h = h + height
        end
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
    end
}, "Editor")

local editors = {}

local EDITORFOCUSED = 1
local EDITORUSED    = 2
local EDITORFOREVER = 3

local currentfocus = function()
    return #editors ~= 0 and editors[#editors] or nil
end

local useeditor = function(name, mode, focus, initval, password)
    password = password or false

    for i = 1, #editors do if editors[i].name == name then
        local e = editors[i]
        if focus then
            table.insert(editors, e)
            table.remove(editors, i)
            e.active = true
            return e
        end
    end end
    local e = Editor(name, mode, initval, password)
    if focus then table.insert(editors, e)
    else table.insert(editors, 1, e) end
    return e
end

local focuseditor = function(e)
    table.remove(editors, table.find(editors, e))
    table.insert(editors, e)
end

local removeeditor = function(e)
    table.remove(editors, table.find(editors, e))
end

-- returns list of all editors
CAPI.textlist = function()
    return table.filter(editors, function(i, v) return v.name end)
end

-- returns the start of the buffer
CAPI.textshow = function()
    local  top = currentfocus()
    if not top then return nil end

    return table.concat(top.lines, "\n")
end

-- focus on a (or create a persistent) specific editor,
-- else return current name
CAPI.textfocus = function(arg1, arg2)
    if type(arg1) == "string" then
        arg2 = arg2 or 0
        useeditor(arg1, arg2 <= 0 and EDITORFOREVER or arg2, true)
    elseif #editors > 0 then
        return editors[#editors].name
    end
end

-- return to the previous editor
CAPI.textprev = function()
    local  top = currentfocus()
    if not top then return nil end

    table.insert(editors, 1, top)
    table.remove(editors)
end

-- 1 = keep while focused, 2 = keep while used in gui,
-- 3 = keep forever (i.e. until mode changes)) topmost editor,
-- return current setting if no args
CAPI.textmode = function(i)
    local  top = currentfocus()
    if not top then return nil end

    if i then
        top.mode = i
    else
        return top.mode
    end
end

-- saves the topmost (filename is optional)
CAPI.textsave = function(fn)
    local  top = currentfocus()
    if not top then return nil end

    if fn then top:set_file(path(fn, true)) end -- XXX
    top:save_file()
end

CAPI.textload = function(fn)
    local  top = currentfocus()
    if not top then return nil end

    if fn then
        top:set_file(path(fn, true)) -- XXX
        top:load_file()
    elseif top.filename then
        return top.filename
    end
end

CAPI.textinit = function(name, s1, s2)
    local  top = currentfocus()
    if not top then return nil end

    local ed
    for i = 1, #editors do
        if editors[i].name == name then
            ed = editors[i]
            break
        end
    end
    if ed and not ed.filename and s1 and -- and ed.rendered
        (#ed.lines == 0 or (#ed.lines == 1 and s2 == ed.lines[1])) then
        ed:set_file(path(s1, true)) -- XXX
        ed:load_file()
    end
end

CAPI.textcopy = function()
    local  top = currentfocus()
    if not top then return nil end

    clipboard = {}

    local kwargs = {}
    top:region(kwargs)

    for i = 1, 1 + kwargs.ey - kwargs.sy do
        local y = kwargs.sy + i
        local line = top.lines[y]

        if y - 1 == kwargs.sy then line = line:sub(kwargs.sx + 1) end
        table.insert(clipboard, line)
    end

    if #clipboard == 0 then clipboard = { "" } end
end

CAPI.textpaste = function()
    local  top = currentfocus()
    if not top then return nil end

    top:del()

    if #clipboard == 1 or top.maxy == 1 then
        local current = top:current_line()
        local str  = clipboard[1]
        local slen = #str

        if top.maxx >= 0 and slen + top.cx > top.maxx then
            slen = top.maxx - top.cx
        end

        if slen > 0 then
            local len = #current
            if top.maxx >= 0 and slen + top.cx + len > top.maxx then
                len = math.max(0, top.maxx - (top.cx + slen))
            end

            current = current:insert(top.cx + 1, slen)
            top.cx = top.cx + slen
        end

        top.lines[top.cy + 1] = current
    else for i = 1, #clipboard do
        if i == 1 then
            top.cy = top.cy + 1
            local newline = top.lines[top.cy]:sub(top.cx + 1)
            top.lines[top.cy] = top.lines[top.cy]:sub(
                1, top.cx):insert(top.cy + 1, newline)
        elseif i >= #clipboard then
            top.cx = #clipboard[i]
            top.lines[top.cy + 1] = table.concat {
                clipboard[i], top.lines[top.cy + 1] }
        elseif top.maxy < 0 or #top.lines < top.maxy then
            top.cy = top.cy + 1
            table.insert(top.cy, clipboard[i])
        end
    end end
end

CAPI.textmark = function(i)
    local  top = currentfocus()
    if not top then return nil end

    if i then
        top:mark(i == 1)
    else
        return top:region() and 1 or 2
    end
end

CAPI.textselectall = function()
    local  top = currentfocus()
    if not top then return nil end

    top:select_all()
end

CAPI.textclear = function()
    local  top = currentfocus()
    if not top then return nil end

    top:clear()
end

CAPI.textcurrentline = function()
    local  top = currentfocus()
    if not top then return nil end

    return top:current_line()
end

CAPI.textexec = function(sel)
    local  top = currentfocus()
    if not top then return nil end

    local ret, err = pcall(loadstring(
        sel and top:selection_to_string() or tostring(top)))
    if not ret then log(ERROR, err) end
end

return {
    Editor = Editor,
    currentfocus = currentfocus,
    useeditor = useeditor,
    focuseditor = focuseditor,
    removeeditor = removeeditor,
    EDITORFOCUSED = EDITORFOCUSED,
    EDITORUSED = EDITORUSED,
    EDITORFOREVER = EDITORFOREVER
}
