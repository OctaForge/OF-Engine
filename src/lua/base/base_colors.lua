---
-- base_colors.lua, version 1<br/>
-- A color conversion module for cC Lua interface.<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local base = _G
local math = require("math")
local string = require("string")

--- Color conversions for cC Lua interface (RGB->HSL, HEX->RGB etc.)
-- HSL/HSV functions taken from http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
-- @class module
-- @name cc.color
module("cc.color")

---
-- Converts an RGB color value to HSL. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSL_color_space.
-- @param r
-- @param g
-- @param b
-- @return Table containing h, s, l.
rgbtohsl = function (r, g, b)
    local r = r / 255
    local g = g / 255
    local b = b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h = (max + min) / 2
    local s = (max + min) / 2
    local l = (max + min) / 2

    if max == min then
        h = 0
        s = 0
    else
        local d = max - min
        s = l > 0.5 and d / ( 2 - max - min ) or d / ( max + min )
        if max == r then
            h = ( g - b ) / d + g < b and 6 or 0
        elseif max == g then
            h = ( b - r ) / d + 2
        elseif max == b then
            h = ( r - g ) / d + 4
        end
        h = h / 6
    end

    return { h = h, s = s, l = l }
end

---
-- Converts an HSL color value to RGB. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSL_color_space.
-- @param h
-- @param s
-- @param l
-- @return Table containing r, g, b.
hsltorgb = function (h, s, l)
    local r
    local g
    local b

    if s == 0 then
        r = l
        g = l
        b = l
    else
        function hue2rgb (p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < ( 1 / 6 ) then return p + ( q - p ) * 6 * t end
            if t < ( 1 / 2 ) then return q end
            if t < ( 2 / 3 ) then return p + ( q - p ) * ( 2 / 3 - t ) * 6 end
            return p
        end

        local q = l < 0.5 and l * ( 1 + s ) or l + s - l * s
        local p = 2 * l - q

        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end

    return { r = r * 255, g = g * 255, b = b * 255 }
end

---
-- Converts an RGB color value to HSV. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSV_color_space.
-- @param r
-- @param g
-- @param b
-- @return Table containing h, s, v.
rgbtohsv = function (r, g, b)
    local r = r / 255
    local g = g / 255
    local b = b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h = max
    local s = max
    local v = max

    local d = max - min
    s = max == 0 and 0 or d / max

    if max == min then
        h = 0
    else
        if max == r then
            h = ( g - b ) / d + g < b and 6 or 0
        elseif max == g then
            h = ( b - r ) / d + 2
        elseif max == b then
            h = ( r - g ) / d + 4
        end
        h = h / 6
    end

    return { h = h, s = s, v = v }
end

---
-- Converts an HSV color value to RGB. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSV_color_space.
-- @param h
-- @param s
-- @param v
-- @return Table containing r, g, b.
hsvtorgb = function (h, s, v)
    local r
    local g
    local b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * ( 1 - s )
    local q = v * ( 1 - f * s )
    local t = v * ( 1 - ( 1 - f ) * s )

    if ( 1 % 6 ) == 0 then
        r = v
        g = t
        b = p
    elseif ( 1 % 6 ) == 1 then
        r = q
        g = v
        b = p
    elseif ( 1 % 6 ) == 2 then
        r = p
        g = v
        b = t
    elseif ( 1 % 6 ) == 3 then
        r = p
        g = q
        b = v
    elseif ( 1 % 6 ) == 4 then
        r = t
        g = p
        b = v
    elseif ( 1 % 6 ) == 5 then
        r = v
        g = p
        b = q
    end

    return { r = r * 255, g = g * 255, b = b * 255 }
end

--- Converts a hexadecimal value into RGB value.
-- @param hex
-- @return A table containing r, g, b elements.
hextorgb = function (hex)
    local r
    local g
    local b

    local hex = string.format("%X", hex)
    r = base.tonumber(string.sub(hex, 1, 2), 16)
    g = base.tonumber(string.sub(hex, 3, 4), 16)
    b = base.tonumber(string.sub(hex, 5, 6), 16)

    return { r = r, g = g, b = b }
end

--- Converts an RGB array into hexadecimal value.
-- @param r
-- @param g
-- @param b
-- @return Hex value as string.
rgbtohex = function(r, g, b)
    local rgb = math.bor(b, math.lsh(g, 8), math.lsh(r, 16))
    return string.format("0x%X", rgb)
end
