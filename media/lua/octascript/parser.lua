--[[
    OctaScript

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.
]]

local astgen = require("octascript.ast")
local lexer = require("octascript.lexer")

local syntax_error = lexer.syntax_error
local iskw = lexer.is_keyword

local assert_tok = function(ls, tok)
    local n = ls.token.name
    if tok == n then return end
    syntax_error(ls, "'" .. tok .. "' expected")
end

local assert_next = function(ls, tok)
    assert_tok(ls, tok)
    ls:get()
end

local test_next = function(ls, tok)
    if ls.token.name == tok then
        ls:get()
        return true
    end
    return false
end

local check_match = function(ls, a, b, line)
    if ls.token.name ~= a then
        if line == ls.line_number then
            syntax_error(ls, "'" .. a .. "' expected")
        else
            syntax_error(ls, "'" .. a .. "' expected (to close '" .. b
                .. "' at line " .. line .. ")")
        end
    end
    ls:get()
end

local BinaryOps = {
    ["or"] = 1,  ["and"] = 2,
    ["<" ] = 3,  ["<=" ] = 3,  [">"  ] = 3, [">="] = 3,
    ["=="] = 3,  ["!=" ] = 3,
    ["~" ] = 4,
    ["|" ] = 5,  ["^"  ] = 6,  ["&"  ] = 7,
    ["<<"] = 8,  [">>" ] = 8,  [">>>"] = 8,
    ["+" ] = 9,  ["-"  ] = 9,
    ["*" ] = 10, ["/"  ] = 10, ["%"  ] = 10,
    -- unary here --
    ["**"] = 12
}

local RightAss = {
    ["~"] = true, ["**"] = true
}

local UnaryOps = {
    ["-"] = 11, ["not"] = 11, ["~"] = 11, ["#"] = 11
}

local parse_expr
local parse_stat, parse_chunk, parse_block, parse_body

local parse_expr_list = function(ls, ast, exprs)
    local tok = ls.token
    exprs = exprs or {}
    if #exprs == 0 or test_next(ls, ",") then
        while true do
            exprs[#exprs + 1] = parse_expr(ls, ast)
            if not test_next(ls, ",") then
                break
            end
        end
    end
    local exp = exprs[#exprs]
    local k = exp.kind
    if exp.parenthesized and (k == "CallExpression" or k == "SendExpression"
                                                    or k == "Vararg")
    then
        exp.parenthesized = nil
        exprs[#exprs] = ast.ParenthesizedExpression(exp)
    end
    return exprs
end

local parse_params = function(ls, ast, ns)
    local args = {}
    if ns then
        args[1] = ast:var_declare("self")
    end
    if ls.token.name ~= ")" then
        repeat
            if ls.token.name == "<name>" then
                local name = ls.token.value
                ls:get()
                args[#args + 1] = ast:var_declare(name)
            elseif ls.token.name == "..." then
                ls:get()
                ls.fs.varargs = true
                args[#args + 1] = ast.Vararg()
                break
            else
                syntax_error(ls, "<name> or \"...\" expected")
            end
        until not test_next(ls, ",")
    end
    return args
end

local parse_table = function(ls, ast)
    local line = ls.line_number
    local tok = ls.token
    assert_next(ls, "{")
    local hkeys, hvals, avals = {}, {}, {}
    while tok.name ~= "}" do
        local key
        if tok.name == "[" then
            local line = ls.line_number
            ls:get()
            key = parse_expr(ls, ast)
            check_match(ls, "]", "[", line)
            assert_next(ls, "=")
        elseif tok.name == "<name>" and ls:lookahead() == "=" then
            local val = ls.token.value
            ls:get()
            key = ast.Literal(val)
            assert_next(ls, "=")
        end
        local val = parse_expr(ls, ast)
        if key then
            hkeys[#hkeys + 1] = key
            hvals[#hvals + 1] = val
        else
            avals[#avals + 1] = val
        end
        if not test_next(ls, ",") and not test_next(ls, ";") then
            break
        end
    end
    check_match(ls, "}", "{", line)
    return ast.Table(avals, hkeys, hvals, line)
end

local parse_enum = function(ls, ast)
    local line = ls.line_number
    local tok = ls.token
    assert_next(ls, "{:")
    ast:scope_begin()
    local hkeys, hvals = {}, {}
    while tok.name ~= ":}" do
        assert_tok(ls, "<name>")
        local val
        local nm = ls.token.value
        ast.current.vars[nm] = true
        ls:get()
        if test_next(ls, "=") then
            val = parse_expr(ls, ast)
        else
            val = false
        end
        hkeys[#hkeys + 1] = nm
        hvals[#hvals + 1] = val
        if not test_next(ls, ",") and not test_next(ls, ";") then
            break
        end
    end
    if hvals[1] == false then
        hvals[1] = ast.Literal(1)
    end
    ast:scope_end()
    check_match(ls, ":}", "{:", line)
    return ast.Enum(hkeys, hvals, line)
end

local parse_args = function(ls, ast)
    local tok = ls.token
    local tn = tok.name
    local args
    if tn == "(" then
        local line = ls.line_number
        if line ~= ls.last_line then syntax_error(ls,
            "ambiguous syntax (function call x new statement)")
        end
        ls:get()
        tn = tok.name
        if tn == ")" then
            args = {}
        else
            args = parse_expr_list(ls, ast)
        end
        check_match(ls, ")", "(", line)
    elseif tn == "{" then
        args = { (parse_table(ls, ast)) }
    elseif tn == "<string>" then
        local val = tok.value
        ls:get()
        args = { ast.Literal(val) }
    else
        syntax_error(ls, "function arguments expected")
    end
    return args
end

local parse_cond_expr

local parse_cond_sexpr = function(ls, ast)
    if ls.token.name == "not" then
        ls:get()
        return not parse_cond_expr(ls, ast, 3)
    elseif ls.token.name == "(" then
        local line = ls.line_number
        ls:get()
        local ret = parse_cond_expr(ls, ast)
        check_match(ls, ")", "(", line)
        return ret
    else
        assert_tok(ls, "<name>")
        local nm = ls.token.value
        ls:get()
        return not not ls.cond_env[nm]
    end
end

parse_cond_expr = function(ls, ast, mp)
    mp = mp or 1
    local lhs = parse_cond_sexpr(ls, ast)
    while true do
        local op, p = ls.token.name
        if op == "or" then
            p = 1
        elseif op == "and" then
            p = 2
        else
            break
        end
        if p < mp then break end
        ls:get()
        if op == "and" then
            local rhs = parse_cond_expr(ls, ast, p + 1)
            lhs = lhs and rhs
        elseif op == "or" then
            local rhs = parse_cond_expr(ls, ast, p + 1)
            lhs = lhs or rhs
        end
    end
    return lhs
end

local whitelist = {}
for k, v in pairs(_G) do whitelist[k] = true end

local parse_prefix_expr = function(ls, ast)
    local tok = ls.token
    local tn = tok.name
    if tn == "(" then
        local line = ls.line_number
        ls:get()
        local exp = parse_expr(ls, ast)
        check_match(ls, ")", "(", line)
        exp.parenthesized = true
        return exp, "expr"
    elseif tn == "@[" then
        local line = ls.line_number
        ls:get()
        local cond = parse_cond_expr(ls, ast)
        assert_next(ls, ",")
        local exp1 = parse_expr(ls, ast)
        local exp2
        if ls.token.name == "," then
            ls:get()
            exp2 = parse_expr(ls, ast)
        else
            exp2 = ast.Literal(nil, ls.line_number)
        end
        check_match(ls, "]", "@[", line)
        return cond and exp1 or exp2
    elseif tn == "<name>" then
        local val = tok.value
        if not whitelist[val] and not ast.current.vars[val] then
            syntax_error(ls, "attempt to use undeclared variable '"
                .. val .. "'")
        end
        ls:get()
        return ast.Identifier(val), "var"
    else
        syntax_error(ls, "unexpected symbol")
    end
end

local parse_primary_expr = function(ls, ast)
    local line = ls.line_number
    local exp, tp = parse_prefix_expr(ls, ast)
    local tok = ls.token
    while true do
        local nm = tok.name
        if nm == "." then
            ls:get()
            assert_tok(ls, "<name>")
            local key = ast.Identifier(ls.token.value)
            ls:get()
            exp, tp = ast.MemberExpression(exp, key, false), "indexed"
        elseif nm == ":" then
            ls:get()
            assert_tok(ls, "<name>")
            local key = ls.token.value
            ls:get()
            local args = parse_args(ls, ast)
            exp, tp = ast.SendExpression(exp, key, args), "call"
        elseif nm == "[" then
            local line = ls.line_number
            ls:get()
            local key = parse_expr(ls, ast)
            check_match(ls, "]", "[", line)
            exp, tp = ast.MemberExpression(exp, key, true), "indexed"
        elseif nm == "(" or nm == "<string>" or nm == "{" then
            exp, tp = ast.CallExpression(exp, parse_args(ls, ast), line), "call"
        else
            return exp, tp
        end
    end
end

local parse_subexpr

local sexps = {
    ["<number>"] = function(ls, ast)
        local r = ast.Literal(ls.token.value, ls.line_number)
        ls:get()
        return r
    end,
    ["nil"] = function(ls, ast)
        ls:get()
        return ast.Literal(nil)
    end,
    ["true"] = function(ls, ast)
        ls:get()
        return ast.Literal(true)
    end,
    ["false"] = function(ls, ast)
        ls:get()
        return ast.Literal(false)
    end,
    ["..."] = function(ls, ast)
        if not ls.fs.varargs then
            syntax_error(ls, "cannot use \"...\" outside a vararg function")
        end
        ls:get()
        return ast.Vararg()
    end,
    ["{"] = parse_table,
    ["{:"] = parse_enum,
    ["func"] = function(ls, ast)
        local line = ls.line_number
        ls:get()
        local args, body, proto = parse_body(ls, ast, line, false)
        return ast.FunctionExpression(body, args, proto.varargs,
            proto.first_line, proto.last_line)
    end,
    ["\\"] = function(ls, ast)
        local line, lline = ls.line_number
        local prev_fs = ls.fs
        local proto = { varargs = false }
        ls.fs = proto
        ast:scope_begin()
        ls:get()
        local args
        if ls.token.name ~= "->" then
            args = parse_params(ls, ast, false)
        else
            args = {}
        end
        local bline = ls.line_number
        assert_next(ls, "->")
        lline = bline
        local body = { ast.ReturnStatement({ parse_expr(ls, ast) }, bline) }
        ast:scope_end()
        ls.fs = prev_fs
        return ast.FunctionExpression(body, args, proto.varargs, line, lline)
    end,
    ["if"] = function(ls, ast)
        ls:get()
        local cond = parse_expr(ls, ast)
        assert_next(ls, "then")
        local texpr = parse_expr(ls, ast)
        return ast.IfExpression(cond, texpr, test_next(ls, "else")
            and parse_expr(ls, ast) or ast.Literal(nil))
    end
}
sexps["<string>"] = sexps["<number>"]

local unop_func = {
    ["~"] = "__rt_bnot"
}

local gen_unexp = function(ast, op, exp, line)
    local func = unop_func[op]
    if func then
        return ast.CallExpression(ast.Identifier(func, line), { exp }, line)
    else
        return ast.UnaryExpression(op, exp, line)
    end
end

local parse_simple_expr = function(ls, ast)
    local line = ls.line_number
    local tn = ls.token.name
    local unp = UnaryOps[tn]
    if unp then
        ls:get()
        return gen_unexp(ast, tn, parse_subexpr(ls, ast, unp), line)
    else
        return (sexps[tn] or parse_primary_expr)(ls, ast)
    end
end

local op_to_lua = {
    ["!="] = "~=", ["**"] = "^", ["~"] = ".."
}

local bitop_func = {
    ["|"  ] = "__rt_bor",
    ["&"  ] = "__rt_band",
    ["^"  ] = "__rt_bxor",
    ["<<" ] = "__rt_lshift",
    [">>>"] = "__rt_rshift",
    [">>" ] = "__rt_arshift"
}

local gen_binexp = function(ast, op, lhs, rhs, line)
    local func = bitop_func[op]
    if func then
        return ast.CallExpression(ast.Identifier(func, line), { lhs, rhs }, line)
    else
        return ast.BinaryExpression(op_to_lua[op] or op, lhs, rhs, line)
    end
end

parse_subexpr = function(ls, ast, mp)
    local tok  = ls.token
    local line = ls.line_number
    local lhs  = parse_simple_expr(ls, ast)
    while true do
        local op = tok.name
        local p = BinaryOps[op]
        if not op or not p or p < mp then break end
        ls:get()
        lhs = gen_binexp(ast, op, lhs, parse_subexpr(ls, ast, RightAss[op]
            and p or p + 1), line)
    end
    return lhs
end

parse_expr = function(ls, ast)
    return parse_subexpr(ls, ast, 1)
end

local block_follow = {
    ["else" ] = true, ["elif" ] = true, ["end"] = true,
    ["until"] = true, ["<eof>"] = true
}

local parse_for_stat = function(ls, ast, line)
    ls:get()
    assert_tok(ls, "<name>")
    local varn = ls.token.value
    ls:get()
    ast:scope_begin()
    local vars = { ast:var_declare(varn) }
    while test_next(ls, ",") do
        assert_tok(ls, "<name>")
        vars[#vars + 1] = ast:var_declare(ls.token.value)
        ls:get()
    end
    assert_next(ls, "in")
    local exp = parse_expr(ls, ast)
    if #vars == 1 and test_next(ls, "to") then
        local init = exp
        local last = parse_expr(ls, ast)
        local step
        if test_next(ls, "by") then
            step = parse_expr(ls, ast)
        else
            step = ast.Literal(1)
        end
        assert_next(ls, "do")
        local body = parse_block(ls, ast)
        check_match(ls, "end", "for", line)
        return ast.ForStatement(vars[1], init, last, step, body,
            line)
    end
    local exps = parse_expr_list(ls, ast, { exp })
    assert_next(ls, "do")
    local body = parse_block(ls, ast)
    check_match(ls, "end", "for", line)
    ast:scope_end()
    return ast.ForInStatement(vars, exps, body, line)
end

local parse_repeat_stat = function(ls, ast, line)
    ast:scope_begin()
    ls:get()
    local body = parse_block(ls, ast)
    check_match(ls, "until", "repeat", line)
    local cond = parse_expr(ls, ast)
    ast:scope_end()
    return ast.RepeatStatement(cond, body, line)
end

local assops = {
    ["+=" ] = "+" , ["-=" ] = "-" , ["*="] = "*", ["/="] = "/", ["%="] = "%",
    ["**="] = "**", ["~=" ] = "~",

    ["&=" ] = "&",  ["|=" ] = "|",  ["^="  ] = "^",
    ["<<="] = "<<", [">>="] = ">>", [">>>="] = ">>>"
}

local parse_assignment
parse_assignment = function(ls, ast, vlist, var, vk)
    local line = ls.line_number
    if vk ~= "var" and vk ~= "indexed" then
        syntax_error(ls, "lvalue expected")
    end
    vlist[#vlist + 1] = var
    if ls.token.name == "," then
        ls:get()
        local nv, nvk = parse_primary_expr(ls, ast)
        return parse_assignment(ls, ast, vlist, nv, nvk)
    elseif #vlist == 1 and assops[ls.token.name] then
        local op = ls.token.name
        ls:get()
        local line2 = ls.line_number
        return ast.AssignmentExpression(vlist, {
            gen_binexp(ast, assops[op], vlist[1], parse_expr(ls, ast), line2)
        }, line)
    end
    assert_next(ls, "=")
    return ast.AssignmentExpression(vlist, parse_expr_list(ls, ast), line)
end

local parse_expr_stat = function(ls, ast)
    local line = ls.line_number
    local var, vk = parse_primary_expr(ls, ast)
    if vk == "call" then
        return ast.ExpressionStatement(var, line)
    end
    local vlist = {}
    return parse_assignment(ls, ast, vlist, var, vk)
end

local parse_return_stat = function(ls, ast)
    local line = ls.line_number
    ls:get()
    local exprs
    local tok = ls.token
    if tok.name == ";" or block_follow[tok.name] then
        exprs = {}
    else
        exprs = parse_expr_list(ls, ast)
    end
    return ast.ReturnStatement(exprs, line), true
end

local parse_local = function(ls, ast, line)
    ls:get()
    local vl = {}
    repeat
        assert_tok(ls, "<name>")
        vl[#vl + 1] = ls.token.value
        ls:get()
    until not test_next(ls, ",")
    if ls.token.name == "in" then
        ls:get()
        return ast.LocalMemberDeclaration(ast, vl, parse_expr(ls, ast), line)
    end
    return ast.LocalDeclaration(ast, vl, test_next(ls, "=")
        and parse_expr_list(ls, ast) or {}, line)
end

local parse_rec = function(ls, ast, line)
    ls:get()
    assert_next(ls, "func")
    assert_tok(ls, "<name>")
    local name = ls.token.value
    ls:get()
    local args, body, proto = parse_body(ls, ast, line, false)
    return ast.FunctionDeclaration(ast:var_declare(name), body, args,
        proto.varargs, true, proto.first_line, proto.last_line)
end

local parse_function_stat = function(ls, ast, line)
    local ns = false
    ls:get()
    assert_tok(ls, "<name>")
    local v = ast.Identifier(ls.token.value)
    local ov = v
    ls:get()
    while ls.token.name == "." do
        v = parse_expr_field(ls, ast, v)
    end
    if ls.token.name == ":" then
        ns = true
        v = parse_expr_field(ls, ast, v)
    end
    if v == ov then
        ast.current.vars[v.name] = true
    end
    local args, body, proto = parse_body(ls, ast, line, ns)
    return ast.FunctionDeclaration(v, body, args, proto.varargs, false,
        proto.first_line, proto.last_line)
end

local parse_while_stat = function(ls, ast, line)
    ls:get()
    local cond = parse_expr(ls, ast)
    ast:scope_begin()
    assert_next(ls, "do")
    local body = parse_block(ls, ast)
    check_match(ls, "end", "while", line)
    ast:scope_end()
    return ast.WhileStatement(cond, body, line)
end

local parse_if_stat = function(ls, ast, line)
    local tests, blocks = {}, {}
    ls:get()
    tests[#tests + 1] = parse_expr(ls, ast)
    assert_next(ls, "do")
    blocks[#blocks + 1] = parse_block(ls, ast)
    while ls.token.name == "elif" do
        ls:get()
        tests[#tests + 1] = parse_expr(ls, ast)
        assert_next(ls, "do")
        blocks[#blocks + 1] = parse_block(ls, ast)
    end
    local elseb
    if ls.token.name == "else" then
        ls:get()
        elseb = parse_block(ls, ast)
    end
    check_match(ls, "end", "if", line)
    return ast.IfStatement(tests, blocks, elseb, line)
end

local parse_label = function(ls, ast, line)
    ls:get()
    assert_tok(ls, "<name>")
    local name = ls.token.value
    ls:get()
    assert_next(ls, "::")
    return ast.LabelStatement(name, line)
end

local parse_goto_stat = function(ls, ast, line)
    ls:get()
    assert_tok(ls, "<name>")
    local name = ls.token.value
    ls:get()
    return ast.GotoStatement(name, line)
end

local parse_import_stat = function(ls, ast, line)
    ls:get()
    local modname = {}
    repeat
        assert_tok(ls, "<name>")
        modname[#modname + 1] = ls.token.value
        ls:get()
    until not test_next(ls, ".")
    return ast.ImportStatement(ast:var_declare(table.concat(modname, ".")),
        nil, line)
end

local parse_from_stat = function(ls, ast, line)
    ls:get()
    local modname = {}
    repeat
        assert_tok(ls, "<name>")
        modname[#modname + 1] = ls.token.value
        ls:get()
    until not test_next(ls, ".")
    assert_next(ls, "import")
    local fnames = {}
    repeat
        assert_tok(ls, "<name>")
        local field = { ls.token.value }
        ls:get()
        if ls.token.name == "as" then
            ls:get()
            assert_tok(ls, "<name>")
            field[2] = ast:var_declare(ls.token.value)
            ls:get()
        else
            field[2] = ast:var_declare(field[1])
        end
        fnames[#fnames + 1] = field
    until not test_next(ls, ",")
    return ast.ImportStatement(table.concat(modname, "."), fnames, line)
end

local stat_opts = {
    ["if"] = parse_if_stat,
    ["while"] = parse_while_stat,
    ["do"] = function(ls, ast, line)
        ls:get()
        local body = parse_block(ls, ast)
        check_match(ls, "end", "do", line)
        return ast.DoStatement(body, line)
    end,
    ["for"] = parse_for_stat,
    ["repeat"] = parse_repeat_stat,
    ["func"] = parse_function_stat,
    ["var"] = parse_local,
    ["rec"] = parse_rec,
    ["return"] = parse_return_stat,
    ["break"] = function(ls, ast, line)
        ls:get()
        return ast.BreakStatement(line), true
    end,
    ["continue"] = function(ls, ast, line)
        ls:get()
        return ast.ContinueStatement(line), true
    end,
    ["goto"] = parse_goto_stat,
    ["import"] = parse_import_stat,
    ["from"] = parse_from_stat,
    ["::"] = parse_label,
    ["@["] = function(ls, ast)
        local line = ls.line_number
        local noscope = false
        ls:get()
        local cond = parse_cond_expr(ls, ast)
        if ls.token.name == "," then
            ls:get()
            assert_next(ls, "noscope")
            noscope = true
        end
        check_match(ls, "]", "@[", line)
        if noscope then
            assert_tok(ls, "do")
        end
        if ls.token.name == "do" then
            local line = ls.line_number
            if not noscope then
                ast:scope_begin()
            end
            ls:get()
            local tblock, tlast = parse_chunk(ls, ast)
            if not noscope then
                ast:scope_end()
            end
            local fblock, flast
            if ls.token.name == "else" then
                if not noscope then
                    ast:scope_begin()
                end
                ls:get()
                fblock, flast = parse_chunk(ls, ast)
                if not noscope then
                    ast:scope_end()
                end
            end
            check_match(ls, "end", "do", line)
            if not noscope then
                if cond then
                    if tblock then
                        return ast.DoStatement(tblock, line)
                    end
                else
                    if fblock then
                        return ast.DoStatement(fblock, line)
                    end
                end
            end
            if cond then
                return tblock, tlast, true
            else
                return fblock, flast, true
            end
        end
        local stat, last = parse_stat(ls, ast)
        if cond then
            return stat, last
        end
        return nil, false
    end
}

parse_stat = function(ls, ast)
    local opt = stat_opts[ls.token.name]
    if opt then
        return opt(ls, ast, ls.line_number)
    else
        return parse_expr_stat(ls, ast)
    end
end

local gen_memb = function(ast, name)
    return ast.MemberExpression(ast.Identifier("__rt_bit"),
        ast.Identifier(name), false)
end

local gen_rt = function(ls, ast)
    local ret = {}
    ret[#ret + 1] = ast.LocalDeclaration(ast, { "__rt_bit" }, {
        ast.CallExpression(ast.Identifier("require"), { ast.Literal("bit") }) })
    ret[#ret + 1] = ast.LocalDeclaration(ast, {
        "__rt_bnot", "__rt_bor", "__rt_band", "__rt_bxor", "__rt_lshift",
        "__rt_rshift", "__rt_arshift"
    }, {
        gen_memb(ast, "bnot"), gen_memb(ast, "bor"), gen_memb(ast, "band"),
        gen_memb(ast, "bxor"), gen_memb(ast, "lshift"),
        gen_memb(ast, "rshift"), gen_memb(ast, "arshift")
    })
    return ret
end

parse_chunk = function(ls, ast, toplevel)
    local tok = ls.token
    if block_follow[tok.name] then return {} end
    local body = toplevel and gen_rt(ls, ast) or {}
    local last
    repeat
        local stmt, unp
        stmt, last, unp = parse_stat(ls, ast)
        if stmt then
            if unp then
                for i, stat in ipairs(stmt) do
                    body[#body + 1] = stat
                end
            else
                body[#body + 1] = stmt
            end
        end
        if tok.name == ";" then
            ls:get()
        end
    until last or block_follow[tok.name]
    if toplevel then
        return ast.Chunk(body, ls.source, 0, ls.line_number)
    end
    return body, last
end

parse_body = function(ls, ast, line, ns)
    local prev_fs = ls.fs
    ls.fs = { varargs = false }
    ast:scope_begin()
    ls.fs.first_line = line
    local pline = ls.line_number
    assert_next(ls, "(")
    local args = parse_params(ls, ast, ns)
    check_match(ls, ")", "(", pline)
    --assert_next(ls, "do")
    local body = parse_block(ls, ast)
    ast:scope_end()
    local proto = ls.fs
    ls.fs.last_line = ls.line_number
    check_match(ls, "end", "func", line)
    ls.fs = prev_fs
    return args, body, proto
end

parse_block = function(ls, ast)
    ast:scope_begin()
    local block, last = parse_chunk(ls, ast)
    ast:scope_end()
    return block
end

local parse = function(chunkname, input, cond_env)
    local ast = astgen.new()
    local ls = lexer.init(chunkname, input)
    ls:get()
    ls.cond_env = cond_env
    ls.fs = { varargs = true }
    ast:scope_begin()
    local args = { ast.Vararg() }
    local chunk = parse_chunk(ls, ast, true)
    ast:scope_end()
    return chunk
end

return { parse = parse }
