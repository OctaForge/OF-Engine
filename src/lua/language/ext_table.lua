---
-- ext_table.lua, version 1<br/>
-- Extensions for table module of Lua<br/>
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

--- Remap a table (array).
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { 1, 2, 3, 4, 5 }<br/>
-- local b = table.map(a, function(i) return tostring(i) end)<br/>
-- </code>
-- Resulting table is full of strings in the snippet.
-- @param t Table to remap.
-- @param f Function taking an element as argument and returning remapped version.
-- @return Re-mapped table. Won't overwrite the original.
function table.map(t, f)
    local r = {}
    for i = 1, #t do
        r[i] = f(t[i])
    end
    return r
end

--- Merge two dictionaries together.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { a = 5, b = 10 }<br/>
-- local b = { c = 15, d = 20 }<br/>
-- table.mergedicts(a, b)<br/>
-- </code>
-- @param ta Table to merge the other one into.
-- @param tb Table to merge into the first one.
-- @return The first table (modified). Original table gets overwritten.
function table.mergedicts(ta, tb)
    for a, b in pairs(tb) do
        ta[a] = b
    end
    return ta
end

--- Merge two arrays together.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { 5, 10, 15 }<br/>
-- local b = { 20, 25, 30 }<br/>
-- table.mergearrays(a, b)<br/>
-- </code>
-- @param ta Table to merge the other one into.
-- @param tb Table to merge into the first one.
-- @return The first table (modified). Original table gets overwritten.
function table.mergearrays(ta, tb)
    for i = 1, #tb do
        table.insert(ta, tb[i])
    end
    return ta
end

--- Copy a table.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { a = 5, b = 10 }<br/>
-- local b = { 5, 10, 15 }<br/>
-- local c = table.copy(a)<br/>
-- local d = table.copy(b)<br/>
-- </code>
-- @param t Table to copy.
-- @return A copied table.
function table.copy(t)
    local r = {}
    for a, b in pairs(t) do
        r[a] = b
    end
    return r
end

--- Filter a table.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { a = 5, b = 10 }<br/>
-- local b = table.filter(a, function (k, v) return ((v <= 5) and true or false) end)<br/>
-- </code>
-- @param t Table to filter.
-- @param f Function taking key, value and returning true if element matches condition. (false otherwise)
-- @return Filtered table.
function table.filter(t, f)
    local r = {}
    for a, b in pairs(t) do
        if f(a, b) then
            r[a] = b
        end
    end
    return r
end

--- Filter an array.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { 5, 10, 15 }<br/>
-- local b = table.filterarray(a, function (i, v) return ((i <= 2) and true or false) end)<br/>
-- </code>
-- @param t Array to filter.
-- @param f Function taking index, value and returning true if element matches condition. (false otherwise)
-- @return Filtered array.
function table.filterarray(t, f)
    local r = {}
    for a = 1, #t do
        if f(a, t[a]) then
            table.insert(r, t[a])
        end
    end
    return r
end

--- Find a key / index to known value in table.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { a = 5, b = 10 }<br/>
-- local b = { 5, 10, 15 }<br/>
-- local k = table.find(a, 10)<br/>
-- local i = table.find(a, 15)<br/>
-- </code>
-- @param t Table to find element in.
-- @param v Value to find index / key for.
-- @return Key or index of value in table or nil if not found.
function table.find(t, v)
    for a, b in pairs(t) do
        if v == b then
            return a
        end
    end
    return nil
end

--- Get table of keys of associative table.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { a = 5, b = 10 }<br/>
-- local b = table.keys(a)<br/>
-- -- b contains "a" and "b" elements now
-- </code>
-- @param t Table to get keys from.
-- @return Table of keys.
function table.keys(t)
    local r = {}
    for a, b in pairs(t) do
        table.insert(r, tostring(a))
    end
    return r
end

--- Get table of values of associative table.
-- <br/><br/>Usage:<br/><br/>
-- <code>
-- local a = { a = 5, b = 10 }<br/>
-- local b = table.values(a)<br/>
-- -- b contains 5 and 10 elements now
-- </code>
-- @param t Table to get values from.
-- @return Table of values.
function table.values(t)
    local r = {}
    for a, b in pairs(t) do
        table.insert(r, b)
    end
    return r
end
