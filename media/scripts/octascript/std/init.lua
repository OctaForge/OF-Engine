--[[
    OctaScript standard library

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.
]]

local parser = require('octascript.parser')
local generator = require('octascript.generator')
local util = require("octascript.util")

local rt = require("octascript.rt")

rawset(_G, "__rt_core", rt)

local loaded = package.loaded

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
        preload    = package.preload,
        path       = package.path,
        loaded     = package.loaded,
        loadlib    = package.loadlib,
        cpath      = package.cpath,
        searchpath = package.searchpath,
        loaders    = package.loaders,
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
    math   = require("math"),
    os     = require("os"),
    string = require("string"),
    conv   = {
        tostring = tostring,
        tonumber = tonumber
    },
    environ = {
        get = getfenv,
        set = setfenv
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

for k, v in pairs(std) do
    loaded["std." .. k] = v
end

local pkg = std.package

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

package.loaders[2] = function(modname, ppath)
    local  fname, err = spath(modname, ppath or package.path)
    if not fname then return err end
    local file = io_open(fname, "rb")
    local toparse = file:read("*all")
    file:close()
    local chunkname = "@" .. fname
    local f, err
    if fname:sub(#fname - 3) == ".lua" then
        f, err = load(toparse, chunkname)
    else
        f, err = load(compile(chunkname, toparse), chunkname, "b")
    end
    if not f then
        error("error loading module '" .. modname .. "' from file '"
            .. fname .. "':\n" .. err, 2)
    end
    return f
end

local tconc, type = table.concat, type
local pcall = pcall
local io_read = io.read

local isbcode = function(s)
    return s:sub(1, 3) == "\x1B\x4C\x4A"
end

std.eval.load = function(ld, chunkname, mode, env)
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
std.eval.loadstring = std.eval.load

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

std.eval.dofile = function(fname)
    local  func, err = loadfile_f(fname)
    if not func then error(err, 0) end
    return func()
end

rt.import = require

return std
