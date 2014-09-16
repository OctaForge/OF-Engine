--[[
    OctaScript standard library

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.
]]

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
    eval = {
        load       = load,
        dofile     = dofile,
        loadfile   = loadfile,
        loadstring = loadstring
    },
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
}

for k, v in pairs(std) do
    loaded["std." .. k] = v
end
