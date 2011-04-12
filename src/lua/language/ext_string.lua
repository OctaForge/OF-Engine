---
-- ext_string.lua, version 1<br/>
-- Extensions for string module of Lua<br/>
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

-- String interpolation: http://lua-users.org/wiki/StringInterpolation
-- modified to match _ and numbers
function _cc_interp(s, tab)
    return (
        string.gsub(
            s, '%%%(([a-zA-Z_0-9]*)%)([-0-9%.]*[cdeEfgGiouxXsq])',
            function(k, fmt)
                k = tonumber(k) and tonumber(k) or k
                return (tab[k]
                    and
                        string.format("%" .. fmt, tab[k])
                    or
                        "%(" .. k .. ")" .. fmt
                )
            end
        )
    )
end
getmetatable("").__mod = _cc_interp

--- Split string into table of tokens, based on http://lua-users.org/wiki/SplitJoin.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = "abc|def|ghi|jkl"<br/>
-- local b = string.split(a, '|')<br/>
-- assert(table.concat(b) == "abcdefghijkl")<br/>
-- </code>
-- @param s String to split.
-- @param d Delimiter to use.
-- @return Table of string tokens.
function string.split(s, d)
    d = d and tostring(d) or ","
    local r = {}
    string.gsub(tostring(s),
                string.format("([^%s]+)", d),
                function(t) r[#r + 1] = t end)
    return r
end

--- Parse a string template (string with embedded lua code), inspired by luadoc parser system.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- foo = "bar"<br/>
-- bar = "blah"<br/>
-- -- this returns "bar: blah"<br/>
-- -- first, gets parsed to "bar : <$0 return bar $0>"<br/>
-- -- then, it gets parsed to "bar : blah" (value of bar)<br/>
-- assert(string.template("bar : <$0 return <$1=foo$1> $0>") == "bar : blah")<br/>
-- </code>
-- @param s String input.
-- @param l Level to parse string from. Everything with higher or equal level gets parsed. Defaults to 0.
-- @return Parsed code.
function string.template(s, l)
    l = l or 0
    s = string.gsub(s, "<$" .. l .. "(.-)$" .. l .. ">", "<?lua %1 ?>")

    -- r - table to concaterate as retval; sp - start position
    local r = {}; local sp = 1
    -- it iterates if new matches are found. After last match, loop ends
    while true do
        -- ip - where the match begins, fp - where the match ends (numbers)
        -- dm - not used, ex - "=" or "", in case of "=", match is expression
        -- cd - the code / expression to run
        local ip, fp, dm, ex, cd = string.find(s, "<%?(%w*)[ \t]*(=?)(.-)%?>", sp)
        -- no match? stop the loop
        if not ip then break end

        -- insert everything from start position to match beginning into return table
        table.insert(r, string.sub(s, sp, ip - 1))
        -- expression? insert a return value of "return EXPRESSION"
        -- command? insert a return value of the code.
        if ex == "=" then
            local ret = tostring(loadstring("return " .. cd)())
            if ret ~= "nil" then table.insert(r, ret) end
        else
            -- make sure there is no more embedded code by looping it.
            local p = string.template(cd, l + 1)
            while p ~= cd do cd = p; p = string.template(p, l + 1) end

            -- done, insert.
            local rs = loadstring(cd)()
            if rs then table.insert(r, tostring(rs)) end
        end
        -- set start position for next iteration as position of first character after last match.
        sp = fp + 1
    end

    -- make sure everything after last match is inserted too
    table.insert(r, string.sub(s, sp, -1))
    -- return concaterated output
    return table.concat(r)
end
