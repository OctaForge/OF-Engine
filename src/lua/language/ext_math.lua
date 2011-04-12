---
-- ext_math.lua, version 1<br/>
-- Extensions for math module of Lua<br/>
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

--- Left bitshift surrogate.
-- @param v Left side of the shift.
-- @param n Right side of the shift.
-- @return The shifted value.
-- @class function
-- @name math.lsh
math.lsh = CAPI.lsh

--- Right bitshift surrogate.
-- @param v Left side of the shift.
-- @param n Right side of the shift.
-- @return The shifted value.
-- @class function
-- @name math.rsh
math.rsh = CAPI.rsh

--- Bitwise OR surrogate.
-- @param ... A variable number of arguments to perform bitwise OR on.
-- @return The result of bitwise OR between arguments.
-- @class function
-- @name math.bor
math.bor = CAPI.bor

--- Bitwise AND surrogate.
-- @param ... A variable number of arguments to perform bitwise AND on.
-- @return The result of bitwise AND between arguments.
-- @class function
-- @name math.band
math.band = CAPI.band

--- Bitwise NOT surrogate.
-- @param v A number value to make bitwise NOT for.
-- @return The result of bitwise NOT with argument.
-- @class function
-- @name math.bnot
math.bnot = CAPI.bnot

--- Round a floating point number to integral number.
-- @param v The floating point number to round.
-- @return A rounded integral value.
function math.round(v)
    return (type(v) == "number"
        and math.floor(v + 0.5)
        or nil
    )
end

--- Clamp a numerical value.
-- @param v The value to clamp.
-- @param l Lowest value result can have.
-- @param h Highest value result can have.
-- @return Clamped value.
function math.clamp(v, l, h)
    return math.max(l, math.min(v, h))
end

--- Calculate sign of a number.
-- @param v The number to calculate sign for.
-- @return 1 if number is bigger than 0, -1 if smaller and 0 if equals 0.
function math.sign(v)
    return (v < 0 and -1 or (v > 0 and 1 or 0))
end
