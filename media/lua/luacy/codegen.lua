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
        lines = {},
        debug = debug,
        enabled = true,
        append = function(cs, str, idkw, line)
            line = line or cs.ls.line_number
            cs.last_append = line
            local lines = cs.lines
            if #lines < line then
                cs:expand(line)
            end
            if not cs.enabled then return nil end
            if idkw == true then idkw = line end
            if idkw then
                if cs.was_idkw == idkw then
                    tinsert(lines[line], space)
                else
                    cs.was_idkw = idkw
                end
            else
                cs.was_idkw = nil
            end
            tinsert(lines[line], str)
        end,
        expand = function(cs, num)
            local lines = cs.lines
            while #lines < num do
                lines[#lines + 1] = { "" }
            end
        end,
        build = function(cs)
            local lines = cs.lines
            for i = 1, #lines do
                lines[i] = tconc(lines[i], "")
            end
            return tconc(lines, "\n")
        end
    }
end

return { init = init }