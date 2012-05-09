--[[! File: library/core/std/lua/conv.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua conv module. Further accessible as "std.conv".
]]

return {
    --[[! Function: to
        Converts a value given by the second argument to a type given by
        the first argument.

        The specified type can be boolean, bool, number, float, integer,
        int, string, calltable, vec3, Vec4, vec4, Vec4.

        For boolean / bool, the input values can be number (0 false, anything
        else true), string (true is true, everything else is false) or a
        boolean itself (returns the boolean). For any other value, false
        is returned.

        For number / float the same rules as for Lua's tonumber function
        apply, except that also booleans can be converted (false is 0, true
        is 1).

        For integer / int, see above. The same rules apply, except that
        all floating point values will have the floating point cut out.

        For string, tostring function rules apply.

        For calltable, input must be function. The function then is converted
        to a callable table with the same semantics.

        For vec3 / Vec3, the input must be a table, otherwise nil is returned.
        The table can be either an array of 3 values, another vector (in that
        case a copy is returned) or an associative array with x, y, z keys.

        For vec4 / Vec4, same rules apply (but including the fourth component).

        Any other type results in nil.
    ]]
    to = function(name, value)
        if not name then
            return nil
        end

        if name == "boolean" or name == "bool" then
            return (
                (type(value) == "number"  and value ~= 0) or
                (type(value) == "string"  and value == "true") or
                (type(value) == "boolean" and value) or
                false
            )
        elseif name == "number" or name == "float" then
            return (type(value) == "boolean" and
                (value and 1 or 0) or _G["tonumber"](value)
            )
        elseif name == "integer" or name == "int" then
            return (type(value) == "boolean" and
                (value and 1 or 0) or std.math.floor(_G["tonumber"](value))
            )
        elseif name == "string" then
            return _G["tostring"](value)
        elseif name == "calltable" then
            return (type(value) == "function"
                and setmetatable({}, { __call = function(self, ...)
                    return value(...) end
                })
                or nil
            )
        elseif name == "vec3" or name == "Vec3" then
            if type(v) ~= "table" then
                return nil
            end
            if (v.is_a and v:is_a(std.math.Vec3)) or (v.x and v.y and v.z) then
                return std.math.Vec3(v)
            end
            return std.math.Vec3(v[1], v[2], v[3])
        elseif name == "vec4" or name == "Vec4" then
            if type(v) ~= "table" then
                return nil
            end
            if (v.is_a and v:is_a(std.math.Vec4)) or
               (v.x and v.y and v.z and v.w)
            then
                return std.math.Vec4(v)
            end
            return std.math.Vec4(v[1], v[2], v[3], v[4])
        end
    end,

    --[[! Function: rgb_to_hsl
        Takes r, g, b color values and returns the color as HSL, represented
        using an associative array (with h, s, l keys).
    ]]
    rgb_to_hsl = function (r, g, b)
        local r = r / 255
        local g = g / 255
        local b = b / 255
        local max = std.math.max(r, g, b)
        local min = std.math.min(r, g, b)
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
    end,

    --[[! Function: hsl_to_rgb
        Takes h, s, l color values and returns the color as RGB, represented
        using an associative array (with r, g, b keys).
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
                if t < ( 2 / 3 ) then
                    return p + ( q - p ) * ( 2 / 3 - t ) * 6
                end
                return p
            end

            local q = l < 0.5 and l * ( 1 + s ) or l + s - l * s
            local p = 2 * l - q

            r = hue2rgb(p, q, h + 1 / 3)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1 / 3)
        end

        return { r = r * 255, g = g * 255, b = b * 255 }
    end,

    --[[! Function: rgb_to_hsv
        Takes r, g, b color values and returns the color as HSV, represented
        using an associative array (with h, s, v keys).
    ]]
    rgb_to_hsv = function (r, g, b)
        local r = r / 255
        local g = g / 255
        local b = b / 255
        local max = std.math.max(r, g, b)
        local min = std.math.min(r, g, b)
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
    end,

    --[[! Function: hsv_to_rgb
        Takes h, s, v color values and returns the color as RGB, represented
        using an associative array (with r, g, b keys).
    ]]
    hsv_to_rgb = function (h, s, v)
        local r
        local g
        local b

        local i = std.math.floor(h * 6)
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
    end,

    --[[! Function: hex_to_rgb
        Converts a hex integer value to RGB. Returns an associative array
        with r, g, b keys.
    ]]
    hex_to_rgb = function(hex)
        return {
            r = std.math.band(std.math.rsh(hex, 16), 0xFF),
            g = std.math.band(std.math.rsh(hex,  8), 0xFF),
            b = std.math.band(hex, 0xFF)
        }
    end,

    --[[! Function: rgb_to_hex
        Converts given r, g, b values to a hex color value.
    ]]
    rgb_to_hex = function(r, g, b)
        return std.math.bor(b, std.math.lsh(g, 8), std.math.lsh(r, 16))
    end
}
