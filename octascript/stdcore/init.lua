--[[
    OctaScript standard library

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.
]]

local parser = require('octascript.parser')
local generator = require('octascript.generator')
local util = require("octascript.util")

local rt = require("octascript.rt")
local rt_env = rt.env

local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local random = math.random

local stbl = { [true] = 1, [false] = 0 }

local array_mt = rt.array_mt
local array = array_mt.__index

local setmt = setmetatable

local std_math = {
    --[[
        Rounds a given number and returns it. The second argument can be used
        to specify the number of places past the floating point, defaulting to
        0 (rounding to integers).
    ]]
    round = function(v, d)
        local m = 10 ^ (d or 0)
        return floor(v * m + 0.5) / m
    end,

    --[[
        Clamps a number value given by the first argument between third and
        second argument. Globally available.
    ]]
    clamp = function(val, low, high)
        return max(low, min(val, high))
    end,

    --[[
        Performs a linear interpolation between the two numerical values,
        given a weight.
    ]]
    lerp = function(first, other, weight)
        return first + weight * (other - first)
    end,

    --[[
        If the distance between the two numerical values is in given radius,
        the second value is returned, otherwise the first is returned.
    ]]
    magnet = function(value, other, radius)
        return (abs(value - other) <= radius) and other or value
    end,

    --[[
        Returns the sign (1 for positive, 0 for zero, -1 for negative) of
        a number.
    ]]
    sign = function(value)
        return stbl[value > 0] - stbl[value < 0]
    end,

    random = function(m, n)
        if not m and not n then
            return random()
        elseif not n then
            return random(m - 1)
        else
            return random(m, n - 1)
        end
    end
}

for k, v in pairs(math) do
    if not std_math[k] then std_math[k] = v end
end

local tconc = table.concat

local str_esc = setmetatable({
    ["\n"] = "\\n", ["\r"] = "\\r",
    ["\a"] = "\\a", ["\b"] = "\\b",
    ["\f"] = "\\f", ["\t"] = "\\t",
    ["\v"] = "\\v", ["\\"] = "\\\\",
    ['"' ] = '\\"', ["'" ] = "\\'"
}, {
    __index = function(self, c) return string.format("\\%03d", c:byte()) end
})

local str_sub = string.sub
local str_byte = string.byte
local str_find = string.find
local str_match = string.match
local str_gmatch = string.gmatch

local unpack = unpack

local std_string = {
    --[[
        Splits a given string with optional delimiter (defaults to ",")
    ]]
    split = function(self, delim)
        delim = delim or ","
        local r, i = {}, 0
        for ch in str_gmatch(self, "([^" .. delim .. "]+)") do
            r[i] = ch
            i = i + 1
        end
        r.__size = i
        r = setmt(r, array_mt)
        return r
    end,

    byte = function(self, i, j)
        return str_byte(self, i and i + 1 or 1, j)
    end,

    find_match = function(self, pat, init)
        init = init and ((init >= 0) and (init + 1) or init) or 1
        return str_match(self, pat, init)
    end,

    -- TODO: find a solution for this without an alloc...
    find = function(self, pat, init, plain)
        init = init and ((init >= 0) and (init + 1) or init) or 1
        local ret = { str_find(self, pat, init, plain) }
        if not ret[1] then
            return nil
        end
        if not ret[3] then
            return ret[1] - 1, ret[2]
        end
        return ret[1] - 1, unpack(ret, 2)
    end,

    sub = function(self, i, j)
        i = i and ((i >= 0) and (i + 1) or i) or nil
        return str_sub(self, i, j)
    end,

    --[[
        Removes a substring in a string, returns the new string.
    ]]
    remove = function(self, start, endn)
        local slen = self:len()
        endn = (endn == nil or endn == 0) and slen or endn
        return tconc { str_sub(self, 1, start), str_sub(self, endn + 1) }
    end,

    --[[
        Inserts a substring into a string, returns the new string.
    ]]
    insert = function(self, idx, new)
        return tconc { str_sub(self, 1, idx), new, str_sub(self, idx + 1) }
    end,

    --[[
        Escapes a string. Works similarly to the OctaScript %q format but it
        tries to be more compact (e.g. uses \r instead of \13), doesn't insert
        newlines in the result (\n instead) and automatically decides if to
        delimit the result with ' or " depending on the number of nested '
        and " (uses the one that needs less escaping).
    ]]
    escape = function(self)
        local nsq, ndq = 0, 0
        for c in self:gmatch("'") do nsq = nsq + 1 end
        for c in self:gmatch('"') do ndq = ndq + 1 end
        local sd = (ndq > nsq) and "'" or '"'
        return sd .. self:gsub("[\\" .. sd .. "%z\001-\031]", str_esc) .. sd
    end
}

for k, v in pairs(string) do
    if not std_string[k] and k ~= "match" then std_string[k] = v end
end

local band, bor, lsh, rsh = bit.band, bit.bor, bit.lshift, bit.rshift

local std_conv = {
    tostring = tostring,
    tonumber = tonumber,

    --[[
        Converts an integral value to be treated as hexadecimal color code to
        r, g, b values (ranging 0-255). Returns three separate values.
    ]]
    hex_to_rgb = function(hex)
        return rsh(hex, 16), band(rsh(hex, 8), 0xFF), band(hex, 0xFF)
    end,

    --[[
        Converts r, g, b color values (0-255) to a hexadecimal color code.
    ]]
    rgb_to_hex = function(r, g, b)
        return bor(b, lsh(g, 8), lsh(r, 16))
    end,

    --[[
        Takes the r, g, b values (0-255) and returns the matching h, s, l
        values (0-1).
    ]]
    rgb_to_hsl = function(r, g, b)
        r, g, b = (r / 255), (g / 255), (b / 255)
        local mx = max(r, g, b)
        local mn = min(r, g, b)
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
    end,

    --[[
        Takes the r, g, b values (0-255) and returns the matching h, s, v
        values (0-1).
    ]]
    rgb_to_hsv = function(r, g, b)
        r, g, b = (r / 255), (g / 255), (b / 255)
        local mx = max(r, g, b)
        local mn = min(r, g, b)
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
    end,

    --[[
        Takes the h, s, l values (0-1) and returns the matching r, g, b
        values (0-255).
    ]]
    hsl_to_rgb = function(h, s, l)
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
    end,

    --[[
        Takes the h, s, v values (0-1) and returns the matching r, g, b
        values (0-255).
    ]]
    hsv_to_rgb = function(h, s, v)
        local r, g, b

        local i = floor(h * 6)
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
}

debug.getmetatable("").__index = std_string

local pairs = pairs

local std = {
    coroutine = {
        yield   = coroutine.yield,
        wrap    = coroutine.wrap,
        status  = coroutine.status,
        resume  = coroutine.resume,
        running = coroutine.running,
        create  = coroutine.create
    },
    io = {
        input   = io.input,
        tmpfile = io.tmpfile,
        read    = io.read,
        output  = io.output,
        open    = io.open,
        close   = io.close,
        write   = io.write,
        popen   = io.popen,
        flush   = io.flush,
        type    = io.type,
        lines   = io.lines,
        stdin   = io.stdin,
        stdout  = io.stdout,
        stderr  = io.stderr
    },
    jit = require("jit"),
    bit = require("bit"),
    package = {
        cond_env   = {},
        loaded     = {
            ["capi"   ] = package.loaded.capi,
            ["std.ffi"] = package.loaded.ffi
        },
        preload    = {
            ["std.ffi"] = package.preload.ffi
        },
        path       = package.path,
        loadlib    = package.loadlib,
        cpath      = package.cpath,
        searchpath = package.searchpath,
        config     = package.config
    },
    debug = require("debug"),
    table = {
        rawget   = rawget,
        rawset   = rawset,
        pairs    = pairs,
        next     = next,
        setmt    = setmetatable,
        getmt    = getmetatable,
        unpack   = unpack,

        merge = function(ta, tb)
            local r = {}
            for a, b in pairs(ta) do r[a] = b end
            for a, b in pairs(tb) do r[a] = b end
            return r
        end,

        copy = function(t)
            local r = {}
            for a, b in pairs(t) do r[a] = b end
            return r
        end,

        filter = function(t, f)
            local r = {}
            for a, b in pairs(t) do if f(a, b) then r[a] = b end end
            return r
        end
    },
    math   = std_math,
    os     = require("os"),
    string = std_string,
    conv   = std_conv,
    environ = {
        get = getfenv,
        set = setfenv,
        globals = rt_env
    },
    eval = {},
    gc = {
        collect = collectgarbage,
        info    = gcinfo
    },
    util = {
        _LUA_VERSION = _VERSION,
        _VERSION     = "OctaScript 0.1",
        proxy        = newproxy,
        rawequal     = rawequal,
        assert       = assert,
        select       = select
    },
    ["jit.opt"] = require("jit.opt"),
    ["jit.util"] = require("jit.util")
}

local pkg = std.package
local loaded = pkg.loaded

for k, v in pairs(std) do
    loaded["std." .. k] = v
end

loaded["std"] = std

local compile = function(fname, src)
    local succ, tree = pcall(parser.parse, fname, src, pkg.cond_env)
    if not succ then error(select(2, util.error(tree))) end
    local succ, bcode = pcall(generator, tree, fname)
    if not succ then error(select(2, util.error(bcode))) end
    return bcode
end
std.eval.compile = compile

local io_open, load, error = io.open, load, error
local spath = package.searchpath

local octfile_read = function(path)
    local file, err = io_open(path, "rb")
    if not file then return nil, err end
    local tp = file:read("*all")
    file:close()
    return tp
end

pkg.loaders = setmt({
    [0] = function(modname)
        local v = pkg.preload[modname]
        if not v then
            return ("\tno field package.preload['%s']"):format(modname)
        end
        return v
    end,
    function(modname, ppath, spfunc, stfunc)
        local  fname, err = (spfunc or spath)(modname, ppath or pkg.path)
        if not fname then return err end
        local tp, err = (stfunc or octfile_read)(fname)
        if not tp then return err end
        local chunkname = "@" .. fname
        local f, err = load(compile(chunkname, tp), chunkname, "b", rt_env)
        if not f then
            error("error loading module '" .. modname .. "' from file '"
                .. fname .. "':\n" .. err, 2)
        end
        return f
    end,
    function(modname, ppath)
        local  fname, err = spath(modname, ppath or pkg.cpath)
        if not fname then return err end
        local smodname = string.gsub(string.match(modname, "[^-]*%-(.*)")
            or modname, "%.", "_")
        local f, err = package.loadlib(fname, "luaopen_" .. smodname)
        if not f then
            error("error loading module '" .. modname .. "' from file '"
                .. fname .. "':\n" .. err, 2)
        end
        return f
    end,
    function(modname, ppath)
        local rmodname, smodname = string.match(modname, "([^.]*)%.(.*)")
        if not rmodname then
            rmodname = modname
            smodname = ""
        end
        local  fname, err = spath(rmodname, ppath or pkg.cpath)
        if not fname then return err end
        smodname = string.gsub(smodname, "%.", "_")
        local f, err = package.loadlib(fname, "luaopen_" .. smodname)
        if not f then
            error("error loading module '" .. modname .. "' from file '"
                .. fname .. "':\n" .. err, 2)
        end
        return f
    end,
    __size = 4
}, array_mt)

package.loaders[2] = function(modname)
    return pkg.loaders[1](modname, package.path)
end
package.loaders[3] = function(modname)
    return pkg.loaders[2](modname, package.cpath)
end
package.loaders[4] = function(modname)
    return pkg.loaders[3](modname, package.cpath)
end

local type = type
local tconc = table.concat
local setfenv = setfenv

local find_loader = function(modname, env)
    local err = { ("module '%s' not found\n"):format(modname) }
    local loaders = pkg.loaders
    for i = 0, loaders.__size - 1 do
        local v = loaders[i](modname)
        local vt = type(v)
        if vt == "function" then
            return v
        elseif vt == "string" then
            err[#err + 1] = v
        end
    end
    return nil, tconc(err)
end

rt.import = function(modname, loaded)
    loaded = loaded or pkg.loaded
    local v = loaded[modname]
    if v ~= nil then return v end
    local loader, err = find_loader(modname, rt_env)
    if not loader then
        error(err, 2)
    end
    local fv = {}
    -- pre-write: for circular imports
    loaded[modname] = fv
    local ret = loader(modname, fv)
    if ret ~= nil then
        -- abandon previous table
        loaded[modname] = ret
        return ret
    end
    return fv
end

local pcall = pcall
local io_read = io.read

local isbcode = function(s)
    return s:sub(1, 3) == "\x1B\x4C\x4A"
end

std.eval.load = function(ld, chunkname, mode, env)
    env = env or rt_env
    if type(ld) ~= "string" then
        local buf = {}
        local ret = ld()
        while ret do
            buf[#buf + 1] = ret
            ret = ld()
        end
        ld = tconc(buf)
        chunkname = chunkname or "=(load)"
    else
        chunkname = chunkname or ld
    end
    if mode ~= "t" and isbcode(ld) then
        return load(ld, chunkname, mode, env)
    else
        local ret, parsed = pcall(compile, chunkname, ld)
        if not ret then return nil, parsed end
        return load(parsed, chunkname, "b", env)
    end
end

local read_file = function(fname)
    if not fname then
        return io_read("*all"), "=stdin"
    end
    local  file, err = io_open(fname, "rb")
    if not file then return file, err end
    local cont = file:read("*all")
    file:close()
    return cont, "@" .. fname
end

local loadfile_f = function(fname, mode, env)
    env = env or rt_env
    local  file, chunkname = read_file(fname)
    if not file then return file, chunkname end
    if mode ~= "t" and isbcode(file) then
        return load(file, chunkname, mode, env)
    else
        local ret, parsed = pcall(compile, chunkname, file)
        if not ret then return nil, parsed end
        return load(parsed, chunkname, "b", env)
    end
end
std.eval.loadfile = loadfile_f

std.eval.dofile = function(fname, mode, env)
    local  func, err = loadfile_f(fname, mode, env)
    if not func then error(err, 0) end
    return func()
end

-- array utilities
-- optimized by accessing internals

array.map = function(self, f)
    local sz = self.__size
    local r = { __size = sz }
    for i = 0, sz - 1 do
        r[i] = f(self[i])
    end
    return setmt(r, array_mt)
end

array.filter = function(self, f)
    local r = {}
    local j = 0
    for i = 0, self.__size - 1 do
        local v = self[i]
        if f(v) then
            r[j] = v
            j = j + 1
        end
    end
    r.__size = j
    return setmt(r, array_mt)
end

array.compact = function(self, f)
    local sz, comp = self.__size, 0
    for i = 0, sz - 1 do
        local v = self[i]
        if not f(v) then
            comp = comp + 1
        elseif comp > 0 then
            self[i - comp] = v
        end
    end
    for i = sz - 1, sz - comp, -1 do
        self[i] = nil
    end
    self.__size = sz - comp
    return self
end

array.find = function(self, v)
    for i = 0, self.__size - 1 do
        if self[i] == v then
            return i
        end
    end
    return nil
end

array.find_r = function(self, v)
    for i = self.__size - 1, 0 do
        if self[i] == v then
            return i
        end
    end
    return nil
end

array.foldr = function(self, fun, z)
    local idx = 0
    if  z == nil then
        z   = self[0]
        idx = 1
    end
    for i = idx, self.__size - 1 do
        z = fun(z, self[i])
    end
    return z
end

array.foldl = function(self, fun, z)
    local sz = self.__size
    if z == nil then
        z  = self[sz - 1]
        sz = sz - 1
    end
    for i = sz - 1, 0, -1 do
        z = fun(z, self[i])
    end
    return z
end

array.from_table = function(tbl, n)
    tbl.__size = n
    return setmt(tbl, array_mt)
end

std["array"] = array
loaded["std.array"] = array

return std
