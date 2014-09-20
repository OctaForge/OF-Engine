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

local stbl = { [true] = 1, [false] = 0 }

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
    __index = function(self, c) return ("\\%03d"):format(c:byte()) end
})

local std_string = {
    --[[
        Splits a given string with optional delimiter (defaults to ",")
    ]]
    split = function(self, delim)
        delim = delim or ","
        local r, i = {}, 1
        for ch in self:gmatch("([^" .. delim .. "]+)") do
            r[i] = ch
            i = i + 1
        end
        return r
    end,

    --[[
        Removes a substring in a string, returns the new string.
    ]]
    remove = function(self, start, count)
        return tconc { self:sub(1, start - 1), self:sub(start + count) }
    end,

    --[[
        Inserts a substring into a string, returns the new string.
    ]]
    insert = function(self, idx, new)
        return tconc { self:sub(1, idx - 1), new, self:sub(idx) }
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
    if not std_string[k] then std_string[k] = v end
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
            ["capi"] = package.loaded.capi,
            ["ffi" ] = package.loaded.ffi
        },
        preload    = package.preload,
        path       = package.path,
        loadlib    = package.loadlib,
        cpath      = package.cpath,
        searchpath = package.searchpath,
        config     = package.config
    },
    debug = require("debug"),
    table = {
        foreach  = table.foreach,
        foreachi = table.foreachi,
        sort     = table.sort,
        remove   = table.remove,
        maxn     = table.maxn,
        concat   = table.concat,
        insert   = table.insert,
        rawget   = rawget,
        rawset   = rawset,
        pairs    = pairs,
        ipairs   = ipairs,
        next     = next,
        setmt    = setmetatable,
        getmt    = getmetatable,
        unpack   = unpack
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

local compile = function(fname, src, allowg)
    local succ, tree = pcall(parser.parse, fname, src, pkg.cond_env, allowg)
    if not succ then error(select(2, util.error(tree))) end
    local succ, bcode = pcall(generator, tree, fname)
    if not succ then error(select(2, util.error(bcode))) end
    return bcode
end
std.eval.compile = compile

local io_open, load, error = io.open, load, error
local spath = package.searchpath

pkg.loaders = {
    function(modname)
        local v = pkg.preload[modname]
        if not v then
            return ("\tno field package.preload['%s']"):format(modname)
        end
        return v
    end,
    function(modname, ppath)
        local  fname, err = spath(modname, ppath or pkg.path)
        if not fname then return err end
        local file = io_open(fname, "rb")
        local toparse = file:read("*all")
        file:close()
        local chunkname = "@" .. fname
        local f, err
        if fname:sub(#fname - 3) == ".lua" then
            f, err = load(toparse, chunkname)
        else
            f, err = load(compile(chunkname, toparse), chunkname, "b", rt_env)
        end
        if not f then
            error("error loading module '" .. modname .. "' from file '"
                .. fname .. "':\n" .. err, 2)
        end
        return f
    end
}

local type = type
local tconc = table.concat
local setfenv = setfenv

local find_loader = function(modname, env)
    local err = { ("module '%s' not found\n"):format(modname) }
    local loaders = pkg.loaders
    for i = 1, #loaders do
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
    local ret = loader(modname)
    if ret ~= nil then
        loaded[modname] = ret
        return ret
    elseif loaded[modname] == nil then
        loaded[modname] = true
        return true
    end
    return loaded[modname]
end

local pcall = pcall
local io_read = io.read

local isbcode = function(s)
    return s:sub(1, 3) == "\x1B\x4C\x4A"
end

std.eval.load = function(ld, chunkname, mode, env, allowg)
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
        local ret, parsed = pcall(compile, chunkname, ld, allowg)
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

local loadfile_f = function(fname, mode, env, allowg)
    env = env or rt_env
    local  file, chunkname = read_file(fname)
    if not file then return file, chunkname end
    if mode ~= "t" and isbcode(file) then
        return load(file, chunkname, mode, env)
    else
        local ret, parsed = pcall(compile, chunkname, file, allowg)
        if not ret then return nil, parsed end
        return load(parsed, chunkname, "b", env)
    end
end
std.eval.loadfile = loadfile_f

std.eval.dofile = function(fname, mode, env, allowg)
    local  func, err = loadfile_f(fname, mode, env, allowg)
    if not func then error(err, 0) end
    return func()
end

return std
