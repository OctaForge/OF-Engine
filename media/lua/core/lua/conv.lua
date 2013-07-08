--[[! File: lua/core/lua/conv.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Provides color conversion functions. The conversion algorithms
        for rgb <=> hs{v,l} taken from http://mjijackson.com/2008/02/rgb-to-hs
        -an -rgb-to-hsv-color-model-conversion-algorithms-in-javascript.
]]

local M = {}

local band, bor, lsh, rsh = bit.band, bit.bor, bit.lshift, bit.rshift

--[[! Function: hex_to_rgb
    Converts an integral value to be treated as hexadecimal color code to
    r, g, b values (ranging 0-255). Returns three separate values.
]]
M.hex_to_rgb = function(hex)
    return rsh(hex, 16), band(rsh(hex, 8), 0xFF), band(hex, 0xFF)
end

--[[! Function: rgb_to_hex
    Converts r, g, b color values (0-255) to a hexadecimal color code.
]]
M.rgb_to_hex = function(r, g, b)
    return bor(b, lsh(g, 8), lsh(r, 16))
end

--[[! Function: rgb_to_hsl
    Takes the r, g, b values (0-255) and returns the matching h, s, l
    values (0-1).
]]
M.rgb_to_hsl = function(r, g, b)
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

--[[! Function: rgb_to_hsv
    Takes the r, g, b values (0-255) and returns the matching h, s, v
    values (0-1).
]]
M.rgb_to_hsv = function(r, g, b)
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

--[[! Function: hsl_to_rgb
    Takes the h, s, l values (0-1) and returns the matching r, g, b
    values (0-255).
]]
M.hsl_to_rgb = function(h, s, l)
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

--[[! Function: hsv_to_rgb
    Takes the h, s, v values (0-1) and returns the matching r, g, b
    values (0-255).
]]
M.hsv_to_rgb = function(h, s, v)
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

return M
