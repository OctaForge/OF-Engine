--[[!
    File: library/core/language/mod_conv.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file implements a conversion module for OctaForge Lua API.
        It features type conversion functions and color converion functions
        (RGB/HSV/HSL/hex).
]]

--[[!
    Package: convert
    A conversion library for OctaForge Lua API. Contains several
    basic type conversion methods, some of them globally-wrapped,
    and some color conversion functions.
]]
module("convert", package.seeall)

--[[!
    Function: toboolean
    Converts number or string to boolean.

    Parameters:
        v - Number or string to convert.

    Returns:
        A boolean value.
]]
function toboolean(v)
    return (
        (type(v) == "number" and v ~= 0) or
        (type(v) == "string" and v == "true") or
        (type(v) == "boolean" and v) or
        false
    )
end

--[[!
    Function: tointeger
    Converts a type to integral value.

    Parameters:
        v - A value to convert.

    Returns:
        An integer value.
]]
function tointeger(v)
    return math.floor(tonumber(v))
end

--[[!
    Function: todec2str
    Converts a floating point value to
    string representing float with max
    two decimal positions. Returns
    0 if the number is lower than 0.01.

    Parameters:
        v - A value to convert.

    Returns:
        A converted value.
]]
function todec2str(v)
    v = v or 0
    if math.abs(v) < 0.01 then return "0" end
    local r = tostring(v)
    local p = string.find(r, "%.")
    return not p and r or string.sub(r, 1, p + 2)
end

--[[!
    Function: tonumber
    Converts a type to number value.

    Parameters:
        v - A value to convert.

    Returns:
        A number value.
]]
function tonumber(v)
    return (type(v) == "boolean" and
        (v and 1 or 0) or _G["tonumber"](v)
    )
end

--[[!
    Function: tostring
    Converts a type to string value.

    Parameters:
        v - A value to convert.

    Returns:
        A string value.
]]
tostring = _G["tostring"];

--[[!
    Function: tocalltable
    Makes function a callable table.

    Parameters:
        f - A function

    Returns:
        A callable table - table
        that can be called in the
        same way as function,
        but can have members, too.
]]
function tocalltable(f)
    return (type(f) == "function"
        and setmetatable({}, { __call = f })
        or nil
    )
end

--[[!
    Function: tovec3
    Converts array of 3 numbers to vec3.

    Parameters:
        v - Array of 3 numbers. If this is already
        vec3, it simply gets ignored and returned back.

    Returns:
        New vec3 of those numbers.
]]
function tovec3(v)
    if v.is_a and v:is_a(math.vec3) then return v end
    return math.vec3(v[1], v[2], v[3])
end

--[[!
    Function: tovec4
    Converts array of 3 numbers to vec4.

    Parameters:
        v - Array of 4 numbers. If this is already
        vec4, it simply gets ignored and returned back.

    Returns:
        New vec4 of those numbers.
]]
function tovec4(v)
    if v.is_a and v:is_a(math.vec4) then return v end
    return math.vec4(v[1], v[2], v[3], v[4])
end

--[[!
    Function: rgb_to_hsl
    Converts RGB color value to HSL. Conversion formula
    adapted from <http://en.wikipedia.org/wiki/HSL_color_space>.

    Parameters:
        r - Red component ranging from 0 to 255.
        g - Green component ranging from 0 to 255.
        b - Blue component ranging from 0 to 255.

    Returns:
        Table with color converted to HSL -

        (start code)
            { h = h_value, s = s_value, l = l_value }
        (end)

    See Also:
        <hsl_to_rgb>
]]
rgb_to_hsl = function (r, g, b)
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

--[[!
    Function: hsl_to_rgb
    Converts HSL color value to RGB. Conversion formula
    adapted from <http://en.wikipedia.org/wiki/HSL_color_space>.

    Parameters:
        h - Hue value.
        s - Saturation value.
        l - Lightness value.

    Returns:
        Table with color converted to RGB -

        (start code)
            { r = r_value, g = g_value, b = b_value }
        (end)

    See Also:
        <rgb_to_hsl>
]]
hsl_to_rgb = function (h, s, l)
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

--[[!
    Function: rgb_to_hsv
    Converts RGB color value to HSV. Conversion formula
    adapted from <http://en.wikipedia.org/wiki/HSV_color_space>.

    Parameters:
        r - Red component ranging from 0 to 255.
        g - Green component ranging from 0 to 255.
        b - Blue component ranging from 0 to 255.

    Returns:
        Table with color converted to HSV -

        (start code)
            { h = h_value, s = s_value, v = v_value }
        (end)

    See Also:
        <hsv_to_rgb>
]]
rgb_to_hsv = function (r, g, b)
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

--[[!
    Function: hsv_to_rgb
    Converts HSV color value to RGB. Conversion formula
    adapted from <http://en.wikipedia.org/wiki/HSV_color_space>.

    Parameters:
        h - Hue value.
        s - Saturation value.
        v - Value.

    Returns:
        Table with color converted to RGB -

        (start code)
            { r = r_value, g = g_value, b = b_value }
        (end)

    See Also:
        <rgb_to_hsv>
]]
hsv_to_rgb = function (h, s, v)
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

--[[!
    Function: hex_to_rgb
    Converts hex color value to RGB.

    Parameters:
        hex - Hexadecimal color value.

    Returns:
        Table with color converted to RGB -

        (start code)
            { r = r_value, g = g_value, b = b_value }
        (end)

    See Also:
        <rgb_to_hex>
]]
hex_to_rgb = function(hex)
    return {
        r = math.band(math.rsh(hex, 16), 0xFF),
        g = math.band(math.rsh(hex,  8), 0xFF),
        b = math.band(hex, 0xFF)
    }
end

--[[!
    Function: rgb_to_hex
    Converts RGB color value to hex.

    Parameters:
        r - Red component ranging from 0 to 255.
        g - Green component ranging from 0 to 255.
        b - Blue component ranging from 0 to 255.

    Returns:
        A hex value as string.

    See Also:
        <hex_to_rgb>
]]
rgb_to_hex = function(r, g, b)
    local rgb = math.bor(b, math.lsh(g, 8), math.lsh(r, 16))
    return string.format("0x%X", rgb)
end
