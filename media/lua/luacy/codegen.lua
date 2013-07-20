--[[ Luacy 0.1 codegen

    Author: Daniel "q66" Kolesa <quaker66@gmail.com>
    Available under the terms of the MIT license.
]]

local tconc = table.concat
local space = " "
local tinsert = table.insert

local init = function(ls, debug)
    return {
        ls = ls,
        buffer    = {},
        saved     = {},
        debug     = debug,
        enabled   = true,
        last_line = 1,
        append = function(self, str, pos)
            local linenum = self.ls.line_number
            local lastln  = self.last_line
            local buffer  = self.buffer
            local diff    = linenum - lastln
            if diff > 0 then
                for i = 1, diff do buffer[#buffer + 1] = "\n" end
                self.last_line = linenum
            end

            if not self.enabled then return nil end
            self.was_idkw = nil
            if pos then
                tinsert(buffer, pos, str)
            else
                buffer[#buffer + 1] = str
            end
            self.last_append = #buffer
        end,
        append_kw = function(self, str)
            local linenum = self.ls.line_number
            local lastln  = self.last_line
            local buffer  = self.buffer
            local diff    = linenum - lastln
            if diff > 0 then
                for i = 1, diff do buffer[#buffer + 1] = "\n" end
                self.last_line = linenum
                lastln = linenum
            end

            if not self.enabled then return nil end
            if   self.was_idkw == lastln then buffer[#buffer + 1] = space
            else self.was_idkw  = lastln end
            buffer[#buffer + 1] = str
            self.last_append = #buffer
        end,
        append_saved = function(self, str)
            if not self.enabled then return nil end
            local buffer = self.buffer
            local sbuf   = self.saved
            local apos   = (sbuf[#sbuf] or 0) + 1
            tinsert(buffer, apos, str)
        end,
        save = function(self)
            self.saved[#self.saved + 1] = #self.buffer
        end,
        unsave = function(self)
            self.saved[#self.saved] = nil
        end,
        offset_saved = function(self, off)
            local sbuf = self.saved
            for i = 1, #sbuf do sbuf[i] = sbuf[i] + off end
        end,
        build = function(self)
            return tconc(self.buffer)
        end
    }
end

return { init = init }