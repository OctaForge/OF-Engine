--[[! File: library/core/std/lua/lisp.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Implements a little Scheme-like Lisp. It's used in OF ingame console
        as default command handling mechanism. Credits go to Eric Man and his
        l2l lisp-to-lua compiler for inspiration and a few snippets.
]]

local List, Vector, Sym, Op, quote

local get_source = function(str)
    local nl = str:find("\n")

    local l
    if not nl then
        l = str
    else
        l = str:sub(1, nl - 1)
    end
 
    return "[string \"" .. ((#l < 45) and (l .. (nl and "..." or ""))
        or (l:sub(1, 45) .. "...")) .. "\"]"
end

local strstream = function(str)
    return string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)")
end

local is_newline = function(ch)
    return (ch == "\n" or ch == "\r")
end

local is_white = function(ch)
    return (ch == " " or ch == "\f" or ch == "\t" or ch == "\v")
end

local is_token = function(ch)
    return (not is_newline(ch)) and (not is_white(ch)) and ch ~= ")"
end

local syntax_error = function(ps, msg)
    rawerror(ps.source == "console" and msg
        or ("%s:%d: %s"):format(ps.source, ps.line_number, msg))
end

local next_char = function(ps) ps.current = ps.reader() end
local next_line = function(ps)
    local prev = ps.current
    assert(is_newline(ps.current))

    -- \n or \r
    next_char(ps)
    -- \n\r or \r\n
    if is_newline(ps.current) and ps.current ~= prev then
        next_char(ps)
    end

    ps.line_number = ps.line_number + 1
    if ps.line_number == 1/0 then
        syntax_error(ps, "chunk has too many lines")
    end
end

-- metatables

local List_MT = {
    __tostring = function(self)
        return table.concat { "List(", tolstring(self, quote), ")" }
    end,

    __len = function(self)
        local i = 0
        while x and x[1] do
            i = i + 1
            x = x[2]
        end
        return i
    end
}

local Vector_MT = {
    __tostring = function(self)
        return table.concat { "Vector(", tovstring(self, quote), ")" }
    end
}

local Sym_MT = {
    __tostring = function(self)
        return self.name
    end
}

local Op_MT = {
    __call = function(self, ...)
        return self.fun(...)
    end,

    __tostring = function(self)
        return self.name
    end
}

-- list -> tuple

local totuple
local totuple_def = function(a) return a end

totuple = function(lst, fun)
    fun = fun or totuple_def
    if lst then
        return fun(lst[1]), totuple(lst[2], fun)
    end
end

local map = function(vec, fun)
    local ret = {}
    for i = 1, #vec do
        ret[#ret + 1] = fun(vec[i])
    end
    return ret
end

-- list -> string
tolstring = function(lst, fun)
    return table.concat({ totuple(lst, fun) }, ", ")
end

-- vector -> string
tovstring = function(vec, fun)
    return table.concat(map(vec, fun), ", ")
end

-- parse tree -> lua
tolua = function   (a)
    local t  = type(a)
    local mt = getmetatable(a)

    if t == "string" then
        return "[[" .. a .. "]]"
    elseif t == "number" or mt == Sym_MT then
        return tostring(a)
    elseif mt == List_MT then
        local first = a[1]

        if not first then
            return nil
        end

        local fmt = getmetatable(first)

        if fmt == Sym_MT and getmetatable(rawget(Env, first.name)) == Op_MT then
            return rawget(Env, first.name)(totuple(a[2]))
        elseif fmt == Op_MT then
            return first(totuple(a[2]))
        end

        return table.concat { tolua(first), "(", tolstring(a[2], tolua), ")" }
    elseif mt == Vector_MT then
        return "{ " .. table.concat(map(a, tolua), ", ") .. " }"
    end

    return ""
end

-- environment
Env = setmetatable({
    -- lists
    List = function(val, ...)
        return setmetatable({ val, ... and List(...) or nil }, List_MT)
    end,

    -- vectors
    Vector = function(...)
        return setmetatable({ ... }, Vector_MT)
    end,

    -- symbols
    Sym = function(name)
        return setmetatable({ name = name }, Sym_MT)
    end,

    -- operators
    Op = function(name, fun)
        return setmetatable({ name = name, fun = fun }, Op_MT)
    end
}, {
    __index = function(self, name)
        return var.exists(name) and
            var.get(name) or rawget(self, name) or _G[name]
    end,

    __newindex = function(self, name, value)
        if var.exists(name) then
            var.set  (name, value)
        else
            rawset(self, name, value)
        end
    end
})

List   = rawget(Env, "List")
Vector = rawget(Env, "Vector")
Sym    = rawget(Env, "Sym")
Op     = rawget(Env, "Op")

-- primitives

local opconcat = function(op, ...)
    local args = { ... }
    local buf  = {}

    for i = 1, #args do
        buf[#buf + 1] = tolua(args[i])
    end

    return table.concat(buf, op)
end

local defop = function(name, map)
    map = map or name
    rawset(Env, name, Op(name, function(...)
        return table.concat { "(function() return " ..
            opconcat(" " .. map .. " ", ...) .. " end)()" }
    end))
end

defop("=", "==")
defop("+")
defop("-")
defop("*")
defop("/")
defop("%")
defop(">")
defop("<")
defop(">=")
defop("<=")
defop("!=", "~=")

rawset(Env, "#", Op("#", function(x)
    return "#" .. tolua(x)
end))

rawset(Env, "car", function(l) return l[1] end)
rawset(Env, "cdr", function(l) return l[2] end)

rawset(Env, "first", function(l) return l[1] end)
rawset(Env, "rest" , function(l) return l[2] end)

rawset(Env, "cons", function(a, b)
    return setmetatable({ a, b }, List_MT)
end)

-- later to handle blocks in functions
local parse_block = function(buf, ...)
    local arg = { ... }
    for i = 1, #arg do
        if i == #arg then
            buf[#buf + 1] = "return " .. tolua(arg[i])
            break
        end
        buf[#buf + 1] = tolua(arg[i])
    end
    buf[#buf + 1] = "end"
    return table.concat(buf, " ")
end

-- see Scheme
rawset(Env, "define", Op("define", function(a, ...)
    -- lambda form
    if getmetatable(a) == List_MT then
        local buf = { tostring(a[1]) ..
            " = function(" .. tolstring (a[2], tostring) .. ")" }
        return parse_block(buf, ...)
    end

    -- global variables
    return tostring(a) .. " = " .. tolua(...)
end))

-- set
rawset(Env, "set", Op("set", function(name, value)
    name = tostring(name)
    return "(function() " .. name ..
        " = " .. tolua(value) .. " return " .. name .. " end)()"
end))

-- let
rawset(Env, "let", Op("let", function(vars, ...)
    vars = { totuple(vars) }

    local names  = {}
    local values = {}
    for i = 1, #vars do
        names[#names + 1] = tostring(vars[i][1])
        values[#values + 1] = tolua(vars[i][2][1])
    end

    local buf = { "(function(" .. table.concat(names, ", ") .. ")" }
    return parse_block(buf, ...) .. ")(" .. table.concat(values, ", ") .. ")"
end))

-- if
rawset(Env, "if", Op("if", function(cond, texpr, fexpr)
    return table.concat { "(function() if ", tolua(cond), " then return ",
        tolua(texpr), " else return ", tolua(fexpr), " end end)()" }
end))

-- cond
rawset(Env, "cond", Op("cond", function(...)
    local buf  = { "(function()" }
    local args = { ... }

    local eif = false
    for i = 1, #args do
        if i == #args then
            if tostring(args[i][1]) == "else" then
                if #buf == 1 then
                    buf[#buf + 1] = "return " .. tolua(args[i][2][1])
                else
                    buf[#buf + 1] = "else return " .. tolua(args[i][2][1])
                    buf[#buf + 1] = "end"
                end
                break
            end
        end
        buf[#buf + 1] = (eif and "elseif " or "if ") .. tolua(args[i][1]) ..
            " then return " .. tolua(args[i][2][1])

        if i == #args and #buf > 1 then
            buf[#buf + 1] = "end"
        end

        eif = true
    end
    return table.concat(buf, " ") .. " end)()"
end))

-- quotes
quote = Op("quote", function(a)
    local t  = type(a)
    local mt = getmetatable(a)

    if t == "string" then
        return "[[" .. a .. "]]"
    elseif t == "number" then
        return tostring(a)
    elseif mt == Sym_MT or mt == Op_MT then
        return "Sym(\"" .. tostring(a) .. "\")"
    elseif mt == List_MT then
        return "List(" .. tolstring(a, quote) .. ")"
    elseif mt == Vector_MT then
        return "Vector(" .. tovstring(a, quote) .. ")"
    end
end)
rawset(Env, "quote", quote)

-- lambdas
rawset(Env, "lambda", Op("lambda", function(args, ...)
    local buf = { "function(" .. tolstring (args, tostring) .. ")" }
    return parse_block(buf, ...)
end))

-- begin
rawset(Env, "begin", Op("begin", function(...)
    local buf = { "(function()" }
    return parse_block(buf, ...) .. ")()"
end))

-- eval
rawset(Env, "eval", function(a)
    return setfenv(loadstring("return " .. tolua(a), tostring(a)), Env)()
end)

-- lua eval
rawset(Env, "lua", function(str)
    return setfenv(loadstring("return " .. str, tostring(str)), Env)()
end)

-- echo with var pretty print
rawset(Env, "echo", function(v)
    if getmetatable(v) == Sym_MT and var.exists(v.name) then
        v = v.name
        _G["echo"](v .. " = " .. var.get_pretty(v))
    else
        _G["echo"](tostring(v))
    end
end)

local compile, parse

-- compiles parse trees
compile = function(a, ...)
    return tolua(a) .. "\n" .. (... and compile(...)  or "")
end

-- parser
parse = function(ps, level, lpline, vlevel, vline)
    level  = level  or 0
    vlevel = vlevel or 0
    while true do
        local curr = ps.current

        if not curr then
            if level > 0 then
                syntax_error(ps, ps.source == "console" and ("missing ')'"
                    or "missing ')' (to close '(' at line " .. lpline .. ")"))
            elseif vlevel > 0 then
                syntax_error(ps, ps.source == "console" and ("missing '}'"
                    or "missing '}' (to close '{}' at line " .. vline .. ")"))
            end
            return nil
        elseif is_newline(curr) then
            next_line(ps)
        elseif is_white(curr) then
            next_char(ps)
        elseif curr == ";" then
            while ps.current and not is_newline(ps.current) do
                next_char(ps)
            end
        elseif curr == '"' or curr == "[" then
            local c = (curr == "[") and "]" or curr

            local buf = {}
            next_char(ps)

            while ps.current and ps.current ~= c do
                buf[#buf + 1] = ps.current
                if c == "\n" then
                    next_line(ps)
                else
                    next_char(ps)
                end
            end

            -- skip c
            next_char(ps)

            return table.concat(buf), parse(ps, level, lpline, vlevel, vline)
        elseif curr == "(" then
            next_char(ps)
            return Env.List(parse(ps, level + 1, ps.line_number,
                vlevel, vline)), parse(ps, level, lpline, vlevel, vline)
        elseif curr == ")" then
            if level == 0 then
                syntax_error(ps, "unexpected ')'")
            end
            next_char(ps)
            return nil
        elseif curr == "{" then
            next_char(ps)
            return Env.Vector(parse(ps, level, lpline, vlevel + 1,
                ps.line_number)), parse(ps, level, lpline, vlevel, vline)
        elseif curr == "}" then
            if vlevel == 0 then
                syntax_error(ps, "unexpected '}'")
            end
            next_char(ps)
            return nil
        elseif curr == "'" then
            next_char(ps)
            return Env.List(Env.Sym("quote"),
                parse(ps, level, lpline, vlevel, vline))
        else
            local buf = {}
            while ps.current and is_token(ps.current) do
                buf[#buf + 1] = ps.current
                next_char(ps)
            end
            buf = table.concat(buf)
            return tonumber(buf) or Env.Sym(buf), parse(ps, level,
                lpline, vlevel, vline)
        end
    end
end

local compilestr = function(str, con)
    if str:sub(1, 1) ~= "(" then
        str = "(" .. str .. ")"
    end
    local reader = strstream(str)
    return compile(parse({
        reader      = reader,
        current     = reader(),
        line_number = 1,
        source      = con and "console" or get_source(str)
    }))
end

return {
    compile_string = function(str, con)
        local  success, ret = pcall(compilestr, str, con)
        if not success then
            rawerror(ret)
        else
            return ret
        end
    end,
        
    load_string = function(str, con)
        local success, ret = pcall(compilestr, str, con)
        if not success then rawerror(ret) end
    
        ret, success = loadstring(ret)
        if not ret then rawerror(success) end

        return setfenv(ret, Env)
    end,
        
    run_string = function(str, con)
        local  success, ret = pcall(compilestr, str, con)
        if not success then rawerror(ret) end

        ret, success = loadstring(ret)
        if not ret then rawerror(success) end

        return setfenv(ret, Env)()
    end,

    register_func = function(name, fun)
        rawset(Env, name, fun)
    end,

    register_op = function(name, fun)
        rawset(Env, name, Op(name, fun))
    end,

    get_env = function()
        return Env
    end,

    is_list = function(a)
        return (getmetatable(a) == List_MT)
    end,

    is_vector = function(a)
        return (getmetatable(a) == Vector_MT)
    end,

    is_symbol = function(a)
        return (getmetatable(a) == Sym_MT)
    end,

    is_op = function(a)
        return (getmetatable(a) == Op_MT)
    end,

    quote    = quote,
    to_tuple = totuple,
    to_lua   = tolua
}
