--[[! File: library/core/std/lua/conv.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Extends the abilities of the "to*" functions. The conversion algorithms
        for rgb <=> hs{v,l} taken from http://mjijackson.com/2008/02/rgb-to-hs
        -an -rgb-to-hsv-color-model-conversion-algorithms-in-javascript.

        The naming conventions match Lua's here (as the extend the globally
        available functions).
]]

local _tonumber = tonumber

--[[! Function: tonumber
    Extends the abilities of tonumber, it can now convert boolean values
    (true matches 1, false 0).
]]
tonumber = function(value, base)
    return (type(value) == "boolean")
        and (value and 1 or 0)
        or _tonumber(value, base)
end

--[[! Function: tointeger
    Same as tonumber, but floors the result.
]]
tointeger = function(value)
    return math.floor(tonumber(value))
end

--[[! Function: toboolean
    Converts a value to boolean. Non-zero numerical values will produce true,
    zero false. String value "true" converts to true, any other to false.
    Booleans remain unchanged. Any other value results in false.
]]
toboolean = function(value)
    return (type(value) == "number"  and value ~= 0      or false)
        or (type(value) == "string"  and value == "true" or false)
        or (type(value) == "boolean" and value           or false)
        or false
end

--[[! Function: tocalltable
    Converts a function to callable table. Retains semantics, allows storage
    of other data in itself.
]]
tocalltable = function(value)
    return setmetatable({}, {
        __call = function(self, ...) return value(...) end
    })
end

--[[! Function: tovec3
    Converts a table value to OF-defined Vec3 from the math module. The table
    has to contain the appropriate named members (x, y, z, only x is checked).
    If the x member fails to be a number, it is treated as an array (x is the
    first index, y second, z third). If the value doesn't fulfill any of these
    conditions, further behavior remains undefined.
]]
tovec3 = function(value)
    return (type(v.x) == "number")
        and math.Vec3(v)
        or  math.Vec3(v[1], v[2], v[3])
end

--[[! Function: tovec3
    Converts a table value to OF-defined Vec4 from the math module. The table
    has to contain the appropriate named members (x, y, z, w, only x is
    checked). If the x member fails to be a number, it is treated as an
    array (x is the first index, y second, z third, w fourth). If the
    value doesn't fulfill any of these conditions, further behavior
    remains undefined.
]]
tovec4 = function(value)
    return (type(v.x) == "number")
        and math.Vec4(v)
        or  math.Vec4(v[1], v[2], v[3], v[4])
end

--[[! Function: hextorgb
    Converts an integral value to be treated as hexadecimal color code to
    r, g, b values (ranging 0-255). Returns three separate values.
]]
hextorgb = function(hex)
    local band = math.band
    local rsh  = math.rsh
    return rsh(hex, 16), band(rsh(hex, 8), 0xFF), band(hex, 0xFF)
end

--[[! Function: rgbtohex
    Converts r, g, b color values (0-255) to a hexadecimal color code.
]]
rgbtohex = function(r, g, b)
    local lsh = math.lsh
    return math.bor(b, lsh(g, 8), lsh(r, 16))
end

--[[! Function: rgbtohsl
    Takes the r, g, b values (0-255) and returns the matching h, s, l
    values (0-1).
]]
rgbtohsl = function(r, g, b)
    r, g, b = (r / 255), (g / 255), (b / 255)
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local h, s
    local l = (mx + mn) / 2

    if mx == mn then
        h = 0
        s = 0
    else
        local d = mx - mn
        s = l > 0.5 and d / (2 - mx - mn) or d / (mx + mn)
        if     mx == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif mx == g then h = (b - r) / d + 2
        elseif mx == b then h = (r - g) / d + 4 end
        h = h / 6
    end

    return h, s, l
end

--[[! Function: rgbtohsv
    Takes the r, g, b values (0-255) and returns the matching h, s, v
    values (0-1).
]]
rgbtohsv = function(r, g, b)
    r, g, b = (r / 255), (g / 255), (b / 255)
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local h, s
    local v = mx

    local d = mx - mn
    s = (mx == 0) and 0 or (d / mx)

    if mx == mn then
        h = 0
    else
        if     mx == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif mx == g then h = (b - r) / d + 2
        elseif mx == b then h = (r - g) / d + 4 end
        h = h / 6
    end

    return h, s, v
end

--[[! Function: hsltorgb
    Takes the h, s, l values (0-1) and returns the matching r, g, b
    values (0-255).
]]
hsltorgb = function(h, s, l)
    local r, g, b

    if s == 0 then
        r = l
        g = l
        b = l
    else
        local hue2rgb = function(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < (1 / 6) then return p + (q - p) * 6 * t end
            if t < (1 / 2) then return q end
            if t < (2 / 3) then return p + (q - p) * (2 / 3 - t) * 6 end
            return p
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q

        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end

    return (r * 255), (g * 255), (b * 255)
end

--[[! Function: hsvtorgb
    Takes the h, s, v values (0-1) and returns the matching r, g, b
    values (0-255).
]]
hsvtorgb = function(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    if i % 6 == 0 then
        r, g, b = v, t, p
    elseif i % 6 == 1 then
        r, g, b = q, v, p
    elseif i % 6 == 2 then
        r, g, b = p, v, t
    elseif i % 6 == 3 then
        r, g, b = p, q, v
    elseif i % 6 == 4 then
        r, g, b = t, p, v
    elseif i % 6 == 5 then
        r, g, b = v, p, q
    end

    return (r * 255), (g * 255), (b * 255)
end
