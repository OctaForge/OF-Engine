-- OctaScript standalone main entry
-- partially from lj-lang-toolkit

package.path = "./?.oct;./?/init.oct;./?/init.lua;" .. package.path

local bcsave = require("jit.bcsave")

local std = require("octascript.std")
local rt = require("octascript.rt")

require("octascript.std.native")

local compile = std.eval.compile
local assert_run = function(ok, err)
    if not ok then
        io.stderr:write(ret, "\n")
        os.exit(1)
    end
    return ok
end

local usage = function()
    io.stderr:write([[
OctaScript: luajit [options]... [script [args]...]

Available options:
  -b ...    Save or list bytecode.
    ]])
    os.exit(1)
end

local args = { ... }
local k = 1

local fname
while args[k] do
    local a = args[k]
    if string.sub(a, 1, 2) == "-b" then
        local j = 1
        if #a > 2 then
            args[j] = "-" .. string.sub(a, 3)
            j = j + 1
        else
            table.remove(args, j)
        end
        local fn = args[j]
        local f = assert_run(io.open(fn, "rb"))
        local tp = f:read("*all")
        f:close()
        local cname = "@" .. fn
        args[j] = assert_run(load(compile(cname, tp), cname, "b", rt.env))
        bcsave.start(unpack(args))
        os.exit(0)
    else
        if string.sub(a, 1, 1) == "-" then
            io.stderr:write("invalid option: ", a)
            usage()
        end
        fname = a
        break
    end
end

if not fname then usage() end
local f = assert_run(io.open(fname, "rb"))
local tp = f:read("*all")
f:close()
local lcode = compile("@" .. fname, tp)
local fn = assert_run(load(lcode, "@" .. fname, "b", rt.env))
fn(arg[1], unpack(args, k + 1))