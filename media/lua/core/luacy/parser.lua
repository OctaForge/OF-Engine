--[[ Luacy 0.1 parser

    Author: Daniel "q66" Kolesa <quaker66@gmail.com>
    Available under the terms of the MIT license.
]]

local lexer = require("core.luacy.lexer")
local codegen = require("core.luacy.codegen")

local tconc = table.concat

local syntax_error = lexer.syntax_error
local iskw = lexer.is_keyword

local assert_tok = function(ls, tok)
    local n = ls.token.name
    if tok == n then return nil end
    syntax_error(ls, "'" .. tok .. "' expected")
end

local Name_Keywords = {
    ["<name>"] = true, ["goto"] = true, ["continue"] = true, ["debug"] = true
}

local assert_name = function(ls)
    local n = ls.token.name
    if not Name_Keywords[n] then
        syntax_error(ls, "'<name>' expected")
    end
end

local assert_append = function(ls, cs, tok, ...)
    assert_tok(ls, tok)
    cs:append(tok, ...)
end

local assert_next = function(ls, tok)
    assert_tok(ls, tok)
    ls:get()
end

local check_match = function(ls, a, b, line)
    if not ls.token.name == a then
        if line == ls.line_number then
            syntax_error(ls, "'" .. ls.token.name .. "' expected")
        else
            syntax_error(ls, "'" .. a .. "' expected (to close '" .. b
                .. "' at line " .. line .. ")")
        end
    end
end

local loopstack = {}

local Binary_Ops = {
    ["or"] = 1,  ["and"] = 2,
    ["<" ] = 3,  ["<=" ] = 3,  [">"  ] = 3, [">="] = 3,
    ["=="] = 3,  ["~=" ] = 3,  ["!=" ] = 3,
    [".."] = 4,
    ["|" ] = 5,  ["^^" ] = 6,  ["&"  ] = 7,
    ["<<"] = 8,  [">>" ] = 8,  [">>>"] = 8,
    ["+" ] = 9,  ["-"  ] = 9,
    ["*" ] = 10, ["/"  ] = 10, ["%"  ] = 10,
    -- unary here --
    ["^" ] = 12
}

local Right_Ass = {
    [".."] = true, ["^"] = true
}

local Unary_Ops = {
    ["-"] = 11, ["not"] = 11, ["~"] = 11, ["#"] = 11
}

local parse_expr
local parse_chunk

local parse_expr_list = function(ls, cs)
    local tok = ls.token
    while true do
        parse_expr(ls, cs)
        if tok.name == "," then
            cs:append(tok.name)
            ls:get()
        else
            break
        end
    end
end

local parse_arg_list = function(ls, cs)
    local tok = ls.token
    while true do
        if tok.name == "..." then
            cs:append(tok.name)
            ls:get()
            break
        elseif not Name_Keywords[tok.name] then
            syntax_error(ls, "<name> or '...' expected")
        end
        cs:append(tok.value or tok.name, true)
        ls:get()
        if tok.name == "," then
            cs:append(tok.name)
            ls:get()
        else
            break
        end
    end
end

local tstart, tend = "{", "}"

local parse_table = function(ls, cs)
    local line = ls.line_number
    local tok = ls.token
    cs:append(tstart)
    ls:get()
    local tn = tok.name
    while true do
        if tn == tend then break
        elseif Name_Keywords[tn] then
            local line = ls.line_number
            if ls:lookahead() == "=" then
                cs:append(tok.value or tn, true, line)
                ls:get()
                cs:append("=")
                ls:get()
            end
            parse_expr(ls, cs)
        elseif tn == "[" then
            cs:append(tn)
            ls:get()
            parse_expr(ls, cs)
            assert_append(ls, cs, "]")
            ls:get()
            assert_append(ls, cs, "=")
            ls:get()
            parse_expr(ls, cs)
        else
            parse_expr(ls, cs)
        end
        tn = tok.name
        if tn ~= "," and tn ~= ";" then break end
        cs:append(tn)
        ls:get()
        tn = tok.name
    end
    check_match(ls, tend, tstart, line)
    cs:append(tend)
    ls:get()
end

local parse_enum = function(ls, cs)
    local line = ls.line_number
    local tok = ls.token
    local name  = "___enum_tbl"
    local pname = "___enum_cnt"
    cs:append("(function(")
    cs:append(name)
    cs:append(")")
    ls:get()
    local tn = tok.name
    local tracked = { name }
    cs.tracked = tracked
    cs:append("local", true)
    cs:append(pname, true)
    cs:append("= 0;")
    while true do
        if tn == ":}" then break end
        assert_name(ls)
        local field = tok.value or tok.name
        tracked[field] = true
        local line = ls.line_number
        ls:get()
        cs:append(pname, true, line)
        cs:append("=", nil, line)
        if tok.name == "=" then
            ls:get()
            parse_expr(ls, cs)
            line = cs.last_append
        else
            cs:append(pname, true, line)
            cs:append("+ 1", true, line)
        end
        cs:append(";", nil, line)
        cs:append(name, true, line)
        cs:append(".", nil, line)
        cs:append(field, true, line)
        cs:append("=", nil, line)
        cs:append(pname, true, line)
        cs:append(";", nil, line)
        tn = tok.name
        if tn ~= "," and tn ~= ";" then break end
        tn = ls:get()
    end
    cs.tracked = nil
    cs:append("return", true)
    cs:append(name, true)
    check_match(ls, ":}", "{:", line)
    cs:append(" end)({})")
    ls:get()
end

local parse_function_body = function(ls, cs, line)
    assert_append(ls, cs, "(")
    ls:get()
    if ls.token.name ~= ")" then parse_arg_list(ls, cs) end
    assert_append(ls, cs, ")")
    ls:get()
    loopstack[#loopstack + 1] = false
    parse_chunk(ls, cs)
    check_match(ls, "end", "function", line)
    cs:append("end", true)
    ls:get()
end

local parse_call = function(ls, cs)
    local tok = ls.token
    local tn = tok.name
    if tn == "(" then
        local line = ls.line_number
        if line ~= ls.last_line then syntax_error(ls,
            "ambiguous syntax (function call x new statement)")
        end
        cs:append(tn)
        ls:get()
        tn = tok.name
        if tn == ")" then
            cs:append(tn)
            ls:get()
        else
            parse_expr_list(ls, cs)
            check_match(ls, ")", "(", line)
            cs:append(")")
            ls:get()
        end
    elseif tn == "{" then
        parse_table(ls, cs)
    elseif tn == "<string>" then
        cs:append(tok.value)
        ls:get()
    else
        syntax_error(ls, "function arguments expected")
    end
end

local parse_prefix_expr = function(ls, cs)
    local tok = ls.token
    local tn = tok.name
    if tn == "(" then
        local line = ls.line_number
        cs:append("(")
        ls:get()
        parse_expr(ls, cs)
        check_match(ls, ")", "(", line)
        cs:append(")")
        ls:get()
    elseif Name_Keywords[tn] then
        local tracked = cs.tracked
        local varn = tok.value or tn
        if tracked and tracked[varn] then
            cs:append("(")
            cs:append(tracked[1], true)
            cs:append(".")
            cs:append(varn, true)
            cs:append(")")
        else
            cs:append(varn, true)
        end
        ls:get()
    else
        syntax_error(ls, "unexpected symbol")
    end
end

local parse_primary_expr = function(ls, cs)
    parse_prefix_expr(ls, cs)
    local tok = ls.token
    local call = false
    while true do
        local nm = tok.name
        if nm == "." or nm == ":" then
            cs:append(nm)
            ls:get()
            assert_name(ls)
            cs:append(tok.value or tok.name, true)
            ls:get()
            call = false
            if nm == ":" then
                parse_call(ls, cs)
                call = true
            end
        elseif nm == "[" then
            cs:append(nm)
            ls:get()
            parse_expr(ls, cs)
            assert_append(ls, cs, "]")
            ls:get()
            call = false
        elseif nm == "(" or nm == "<string>" or nm == "{" then
            parse_call(ls, cs)
            call = true
        else
            return call
        end
    end
end

local parse_subexpr

local sexps = {
    ["<number>"] = function(ls, cs)
        cs:append("(")
        cs:append(ls.token.value)
        cs:append(")")
        ls:get()
    end,
    ["nil"] = function(ls, cs)
        cs:append(ls.token.name, true)
        ls:get()
    end,
    ["{"] = parse_table,
    ["{:"] = parse_enum,
    ["function"] = function(ls, cs)
        local line = ls.line_number
        cs:append("function", true)
        ls:get()
        parse_function_body(ls, cs, line)
    end,
    ["|"] = function(ls, cs)
        local tok = ls.token
        cs:append("function", true)
        cs:append("(")
        ls:get()
        if tok.name ~= "|" then parse_arg_list(ls, cs) end
        assert_tok(ls, "|")
        cs:append(")")
        ls:get()
        loopstack[#loopstack + 1] = false
        if tok.name == "do" then
            local line = ls.line_number
            ls:get()
            parse_chunk(ls, cs)
            check_match(ls, "end", "do", line)
            cs:append("end", true)
            ls:get()
        else
            cs:append("return", true)
            parse_expr(ls, cs)
            cs:append("end", true)
        end
    end,
    ["if"] = function(ls, cs)
        local tok = ls.token
        cs:append("(")
        ls:get()
        parse_expr(ls, cs)
        assert_tok(ls, "then")
        cs:append("and", true)
        ls:get()
        cs:append("{")
        parse_expr(ls, cs)
        cs:append("}", nil, cs.last_append)
        if tok.name == "else" then
            cs:append("or", true)
            ls:get()
            cs:append("{")
            parse_expr(ls, cs)
            cs:append("}", nil, cs.last_append)
        else
            local lastapp = cs.last_append
            cs:append("or", true, lastapp)
            cs:append("{}", nil, lastapp)
        end
        cs:append(")[1]", nil, cs.last_append)
    end
}
sexps["<string>"] = sexps["<number>"]
sexps["true" ] = sexps["nil"]
sexps["false"] = sexps["nil"]
sexps["..."  ] = sexps["nil"]

local bitunops = {
    ["~"] = "bit.bnot"
}

local parse_simple_expr = function(ls, cs)
    local tn = ls.token.name
    local unp = Unary_Ops[tn]
    if unp then
        local bitun = bitunops[tn]
        if bitun then
            cs:append(bitun, true)
            cs:append("(")
            ls:get()
            parse_subexpr(ls, cs, unp)
            cs:append(")", cs.last_append)
        else
            cs:append(tn, iskw(tn))
            ls:get()
            parse_subexpr(ls, cs, unp)
        end
    else
        (sexps[tn] or parse_primary_expr)(ls, cs)
    end
end

local op_to_lua = {
    ["!="] = "~="
}

local bitops = {
    ["&" ] = "band",   ["|" ] = "bor",    ["^^" ] = "bxor",
    ["<<"] = "lshift", [">>"] = "rshift", [">>>"] = "arshift"
}

local tinsert = table.insert
local cs_insert = function(cs, tbl, idx, val)
    if not cs.enabled then return nil end
    tinsert(tbl, idx, val)
end

local use_bitop = function(cs, bitop)
    if not cs.enabled then return "", 0 end
    local  bo = bitops[bitop]
    if not bo then return nil end
    local firstl = cs.lines[1]
    local bit_loaded = cs.bit_loaded
    local nins = 0
    if not bit_loaded then
        bit_loaded = {}
        cs.bit_loaded = bit_loaded
        tinsert(firstl, 1, 'local bit = require(\"bit\");')
        nins = 1
    end
    local varn = bit_loaded[bitop]
    if not varn then
        varn = "___bit_" .. bo
        bit_loaded[bitop] = varn
        tinsert(firstl, 2, tconc { "local ", varn, " = ", "bit.", bo, ";" })
        nins = nins + 1
    end
    return varn, nins
end

parse_subexpr = function(ls, cs, mp)
    mp = mp or 1
    local tok  = ls.token
    local line = ls.line_number
    local ln   = cs.lines[line]
    local nln  = ln and #ln + 1 or 1
    parse_simple_expr(ls, cs)
    while true do
        local op = tok.name
        local p = Binary_Ops[op]
        if not op or not p or p < mp then break end
        local bitop, nins = use_bitop(cs, op)
        if bitop then
            local idx = nln
            if line == 1 then idx = idx + nins end
            cs_insert(cs, ln or cs.lines[line], idx, "(" .. bitop .. ")(")
            cs:append(",")
        else
            cs_insert(cs, ln or cs.lines[line], nln, "(")
            cs:append(op_to_lua[op] or op, iskw(op))
        end
        ls:get()
        parse_subexpr(ls, cs, Right_Ass[op] and p or p + 1)
        cs:append(")", nil, cs.last_append)
    end
end

parse_expr = function(ls, cs)
    parse_subexpr(ls, cs)
end

local parse_name_list = function(ls, cs)
    local tok = ls.token
    while true do
        assert_name(ls)
        cs:append(tok.value or tok.name, true)
        ls:get()
        if tok.name == "," then
            cs:append(tok.name)
            ls:get()
        else
            break
        end
    end
end

local block_follow = {
    ["else" ] = true, ["elseif"] = true, ["end"] = true,
    ["until"] = true, ["<eof>" ] = true
}

local parse_stat

parse_chunk = function(ls, cs)
    local last = false
    local tok = ls.token
    while not last and not block_follow[tok.name] do
        last = parse_stat(ls, cs)
        if tok.name == ";" then
            cs:append(tok.name)
            ls:get()
        end
    end
end

local parse_assignment = function(ls, cs)
    local tok = ls.token
    if tok.name == "," then
        cs:append(tok.name)
        ls:get()
        while true do
            parse_primary_expr(ls, cs)
            if tok.name ~= "," then break end
            cs:append(tok.name)
            ls:get()
        end
    end
    assert_append(ls, cs, "=")
    ls:get()
    parse_expr_list(ls, cs)
end

local parse_break_stat = function(ls, cs)
    if not loopstack[#loopstack] then
        syntax_error(ls, "no loop to break")
    end
    cs:append(ls.token.name, true)
    ls:get()
end

local parse_cont_stat = function(ls, cs)
    local lbl = loopstack[#loopstack]
    if not lbl then
        syntax_error(ls, "no loop to continue")
    end
    cs:append("goto", true)
    cs:append(lbl, true)
    ls:get()
end

local parse_goto_stat = function(ls, cs)
    local tok = ls.token
    cs:append(tok.name, true)
    ls:get()
    assert_name(ls)
    cs:append(tok.value or tok.name, true)
    ls:get()
end

local parse_while_stat = function(ls, cs, line)
    local tok = ls.token
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append(tok.name, true)
    ls:get()
    parse_expr(ls, cs)
    assert_append(ls, cs, "do", true)
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, "end", "while", line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append(tok.name, true)
    ls:get()
end

local parse_repeat_stat = function(ls, cs, line)
    local tok = ls.token
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append(tok.name, true)
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, "until", "repeat", line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append(tok.name, true)
    ls:get()
    parse_expr(ls, cs)
end

local parse_for_stat = function(ls, cs, line)
    local tok = ls.token
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append(tok.name, true)
    ls:get()
    assert_name(ls)
    cs:append(tok.value or tok.name, true)
    ls:get()
    if tok.name == "=" then
        cs:append(tok.name)
        ls:get()
        parse_expr(ls, cs)
        assert_append(ls, cs, ",")
        ls:get()
        parse_expr(ls, cs)
        if tok.name == "," then
            cs:append(",")
            ls:get()
            parse_expr(ls, cs)
        end
    elseif tok.name == "," or tok.name == "in" then
        if tok.name == "," then
            cs:append(",")
            ls:get()
            parse_name_list(ls, cs)
            assert_tok(ls, "in")
        end
        cs:append("in", true)
        ls:get()
        parse_expr_list(ls, cs)
    else
        syntax_error(ls, "'=' or 'in' expected")
    end
    assert_append(ls, cs, "do", true)
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, "end", "for", line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append(tok.name, true)
    ls:get()
end

local parse_if_stat = function(ls, cs, line)
    local tok = ls.token
    cs:append(tok.name, true)
    ls:get()
    local tok = ls.token
    parse_expr(ls, cs)
    assert_append(ls, cs, "then", true)
    ls:get()
    parse_chunk(ls, cs)
    while tok.name == "elseif" do
        cs:append(tok.name, true)
        ls:get()
        parse_expr(ls, cs)
        assert_append(ls, cs, "then", true)
        ls:get()
        parse_chunk(ls, cs)
    end
    if tok.name == "else" then
        cs:append(tok.name, true)
        ls:get()
        parse_chunk(ls, cs)
    end
    check_match(ls, "end", "if", line)
    cs:append(tok.name, true)
    ls:get()
end

local parse_local_function_stat = function(ls, cs, line)
    local tok = ls.token
    assert_name(ls)
    cs:append(tok.value or tok.name, true)
    ls:get()
    parse_function_body(ls, cs, line)
end

local parse_local_stat = function(ls, cs)
    parse_name_list(ls, cs)
    local tok = ls.token
    if tok.name == "=" then
        cs:append(tok.name)
        ls:get()
        parse_expr_list(ls, cs)
    end
end

local parse_function_stat = function(ls, cs)
    local tok = ls.token
    local line = ls.line_number
    cs:append(tok.name, true)
    ls:get()
    assert_name(ls)
    cs:append(tok.value or tok.name, true)
    ls:get()
    if tok.name == ":" or tok.name == "." then
        cs:append(tok.name)
        ls:get()
        assert_name(ls)
        cs:append(tok.value or tok.name, true)
        ls:get()
    end
    parse_function_body(ls, cs, line)
end

local parse_expr_stat = function(ls, cs)
    if not parse_primary_expr(ls, cs) then
        parse_assignment(ls, cs)
    end
end

local parse_return_stat = function(ls, cs)
    local tok = ls.token
    cs:append(tok.name, true)
    ls:get()
    if tok.name == ";" or block_follow[tok.name] then
        return true
    end
    parse_expr_list(ls, cs)
    return true
end

local stat_opts = {
    ["if"] = parse_if_stat,
    ["while"] = parse_while_stat,
    ["do"] = function(ls, cs, line)
        local tok = ls.token
        cs:append(tok.name, true)
        ls:get()
        parse_chunk(ls, cs)
        check_match(ls, "end", "do", line)
        cs:append(tok.name, true)
        ls:get()
    end,
    ["for"] = parse_for_stat,
    ["repeat"] = parse_repeat_stat,
    ["function"] = parse_function_stat,
    ["local"] = function(ls, cs)
        local tok = ls.token
        cs:append(tok.name, true)
        ls:get()
        if tok.name == "function" then
            local line = ls.line_number
            cs:append(tok.name, true)
            ls:get()
            return parse_local_function_stat(ls, cs, line)
        else
            return parse_local_stat(ls, cs)
        end
    end,
    ["return"] = parse_return_stat,
    ["break"] = parse_break_stat,
    ["continue"] = function(ls, cs)
        local lah = ls:lookahead()
        if lah == ";" or block_follow[lah] then
            parse_cont_stat(ls, cs)
        else
            parse_expr_stat(ls, cs)
        end
    end,
    ["goto"] = function(ls, cs)
        ((ls:lookahead() == "<name>") and parse_goto_stat
            or parse_expr_stat)(ls, cs)
    end,
    ["debug"] = function(ls, cs)
        local lah = ls:lookahead()
        if lah == "then" then
            cs.enabled = cs.debug
            ls:get()
            ls:get()
            parse_stat(ls, cs)
            cs.enabled = true
        elseif lah == "do" then
            cs.enabled = cs.debug
            ls:get()
            cs:append("do", true)
            ls:get()
            local line = ls.line_number
            parse_chunk(ls, cs)
            check_match(ls, "end", "do", line)
            cs:append(ls.token.name, true)
            ls:get()
            cs.enabled = true
        else
            parse_expr_stat(ls, cs)
        end
    end
}

parse_stat = function(ls, cs)
    (stat_opts[ls.token.name] or parse_expr_stat)(ls, cs, ls.line_number)
end

local parse = function(fname, input, debug)
    local ls = lexer.init(fname, input)
    local cs = codegen.init(ls, debug)
    ls.cs = cs
    ls:get()
    loopstack[#loopstack + 1] = false
    parse_chunk(ls, cs)
    return cs:build()
end

return { parse = parse }
