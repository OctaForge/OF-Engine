--[[ Luacy 0.1 parser

    Author: Daniel "q66" Kolesa <quaker66@gmail.com>
    Available under the terms of the MIT license.
]]

local lexer = require("luacy.lexer")
local codegen = require("luacy.codegen")

local tconc = table.concat

local syntax_error = lexer.syntax_error
local iskw = lexer.is_keyword

local assert_tok = function(ls, tok)
    local n = ls.token.name
    if tok == n then return end
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

local assert_append = function(ls, cs, tok)
    assert_tok(ls, tok)
    cs:append(tok)
end

local assert_append_kw = function(ls, cs, tok)
    assert_tok(ls, tok)
    cs:append_kw(tok)
end

local assert_next = function(ls, tok)
    assert_tok(ls, tok)
    ls:get()
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
        cs:append_kw(tok.value or tok.name)
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
            if ls:lookahead() == "=" then
                cs:append_kw(tok.value or tn)
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
    cs:append_kw("local")
    cs:append_kw(pname)
    cs:append("= 0;")
    while true do
        if tn == ":}" then break end
        assert_name(ls)
        local field = tok.value or tok.name
        tracked[field] = true
        cs:append_kw(pname)
        cs:append("=")
        if ls:lookahead() == "=" then
            ls:get()
            ls:get()
            parse_expr(ls, cs)
        else
            cs:append_kw(pname)
            cs:append("+1")
            ls:get()
        end
        cs:append(";")
        cs:append_kw(name)
        cs:append(".")
        cs:append_kw(field)
        cs:append("=")
        cs:append_kw(pname)
        cs:append(";")
        tn = tok.name
        if tn ~= "," and tn ~= ";" then break end
        tn = ls:get()
    end
    cs.tracked = nil
    cs:append_kw("return")
    cs:append_kw(name)
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
    cs:append_kw("end")
    ls:get()
    loopstack[#loopstack] = nil
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
            cs:append_kw(tracked[1])
            cs:append(".")
            cs:append_kw(varn)
            cs:append(")")
        else
            cs:append_kw(varn)
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
            cs:append_kw(tok.value or tok.name)
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
    ["<string>"] = function(ls, cs)
        cs:append(ls.token.value)
        ls:get()
    end,
    ["nil"] = function(ls, cs)
        cs:append_kw(ls.token.name)
        ls:get()
    end,
    ["{"] = parse_table,
    ["{:"] = parse_enum,
    ["function"] = function(ls, cs)
        local line = ls.line_number
        cs:append_kw("function")
        ls:get()
        parse_function_body(ls, cs, line)
    end,
    ["|"] = function(ls, cs)
        local tok = ls.token
        cs:append_kw("function")
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
            cs:append_kw("end")
            ls:get()
        else
            cs:append_kw("return")
            parse_expr(ls, cs)
            cs:append_kw("end")
        end
        loopstack[#loopstack] = nil
    end,
    ["if"] = function(ls, cs)
        local tok = ls.token
        cs:append("(")
        ls:get()
        parse_expr(ls, cs)
        assert_tok(ls, "then")
        cs:append_kw("and")
        ls:get()
        cs:append("{")
        parse_expr(ls, cs)
        cs:append("}")
        if tok.name == "else" then
            cs:append_kw("or")
            ls:get()
            cs:append("{")
            parse_expr(ls, cs)
            cs:append("}")
        else
            cs:append_kw("or")
            cs:append("{}")
        end
        cs:append(")[1]")
    end
}
sexps["true" ] = sexps["nil"]
sexps["false"] = sexps["nil"]
sexps["..."  ] = sexps["nil"]

local bitops = {
    ["&" ] = "band",   ["|" ] = "bor",     ["^^" ] = "bxor",
    ["<<"] = "lshift", [">>"] = "arshift", [">>>"] = "rshift",
    ["~" ] = "bnot"
}

local tinsert = table.insert

local use_bitop = function(cs, bitop)
    if not cs.enabled then return "", 0 end
    local  bo = bitops[bitop]
    if not bo then return nil end
    local buf = cs.buffer
    local bit_loaded = cs.bit_loaded
    local nins = 0
    if not bit_loaded then
        bit_loaded = {}
        cs.bit_loaded = bit_loaded
        tinsert(buf, 1, 'local bit = require(\"bit\");')
        nins = 1
    end
    local varn = bit_loaded[bitop]
    if not varn then
        varn = "___bit_" .. bo
        bit_loaded[bitop] = varn
        tinsert(buf, 2, tconc { "local ", varn, " = ", "bit.", bo, ";" })
        nins = nins + 1
    end
    if nins > 0 then cs:offset_saved(nins) end
    return varn, nins
end

local parse_simple_expr = function(ls, cs)
    local tn = ls.token.name
    local unp = Unary_Ops[tn]
    if unp then
        local bitun = use_bitop(cs, tn)
        if bitun then
            cs:append("(" .. bitun .. ")(")
            ls:get()
            parse_subexpr(ls, cs, unp)
            cs:append(")")
        else
            if iskw(tn) then
                cs:append_kw(tn)
            else
                cs:append(tn)
            end
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

parse_subexpr = function(ls, cs, mp)
    local tok  = ls.token
    local line = ls.line_number
    cs:save()
    parse_simple_expr(ls, cs)
    while true do
        local op = tok.name
        local p = Binary_Ops[op]
        if not op or not p or p < mp then break end
        local bitop = use_bitop(cs, op)
        if bitop then
            cs:append_saved("(" .. bitop .. ")(", true)
            cs:append(",")
        else
            cs:append_saved("(", true)
            if iskw(op) then
                cs:append_kw(op_to_lua[op] or op)
            else
                cs:append(op_to_lua[op] or op)
            end
        end
        ls:get()
        parse_subexpr(ls, cs, Right_Ass[op] and p or p + 1)
        cs:append(")")
    end
    cs:unsave()
end

parse_expr = function(ls, cs)
    parse_subexpr(ls, cs, 1)
end

local parse_name_list = function(ls, cs, list)
    local tok = ls.token
    while true do
        assert_name(ls)
        local v = tok.value or tok.name
        if list then list[#list + 1] = v end
        cs:append_kw(v)
        ls:get()
        if tok.name == "," then
            cs:append(tok.name)
            ls:get()
        else
            break
        end
    end
    return list
end

local block_follow = {
    ["else" ] = true, ["elseif"] = true, ["end"] = true,
    ["until"] = true, ["<eof>" ] = true
}

local parse_stat

parse_chunk = function(ls, cs)
    local tok = ls.token
    if block_follow[tok.name] then return end
    repeat
        local last = parse_stat(ls, cs)
        if tok.name == ";" then
            cs:append(tok.name)
            ls:get()
        end
    until last or block_follow[tok.name]
end

local assops = {
    ["+="] = "+", ["-="] = "-", ["*="] = "*", ["/="] = "/", ["%="] = "%",
    ["^="] = "^", ["..="] = "..",

    ["&=" ] = "&",  ["|=" ] = "|",  ["^^=" ] = "^^",
    ["<<="] = "<<", [">>="] = ">>", [">>>="] = ">>>"
}

local parse_assignment = function(ls, cs, buflen)
    local nbuflen = #cs.buffer
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
    else
        -- bitop stuff from expr parsing above
        local aop = assops[tok.name]
        if aop then
            cs:append("=")
            local bitop, nins = use_bitop(cs, aop)
            if nins and nins > 0 then
                buflen  = buflen  + nins
                nbuflen = nbuflen + nins
            end
            if bitop then
                cs:append(bitop .. "(")
            end
            local buffer = cs.buffer
            local wasspace = false
            for i = buflen + 1, nbuflen do
                local c = buffer[i]
                if c == "\n" then
                    if not wasspace then cs:append(" ") end
                    wasspace = true
                else
                    cs:append(c)
                    wasspace = false
                end
            end
            cs:append(bitop and "," or aop)
            ls:get()
            parse_expr(ls, cs)
            if bitop then cs:append(")") end
            return
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
    cs:append_kw(ls.token.name)
    ls:get()
end

local parse_cont_stat = function(ls, cs)
    local lbl = loopstack[#loopstack]
    if not lbl then
        syntax_error(ls, "no loop to continue")
    end
    cs:append_kw("goto")
    cs:append_kw(lbl)
    ls:get()
end

local parse_goto_stat = function(ls, cs)
    local tok = ls.token
    cs:append_kw(tok.name)
    ls:get()
    assert_name(ls)
    cs:append_kw(tok.value or tok.name)
    ls:get()
end

local parse_while_stat = function(ls, cs, line)
    local tok = ls.token
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append_kw(tok.name)
    ls:get()
    parse_expr(ls, cs)
    assert_append_kw(ls, cs, "do")
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, "end", "while", line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append_kw(tok.name)
    ls:get()
    loopstack[#loopstack] = nil
end

local parse_repeat_stat = function(ls, cs, line)
    local tok = ls.token
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append_kw(tok.name)
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, "until", "repeat", line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append_kw(tok.name)
    ls:get()
    parse_expr(ls, cs)
    loopstack[#loopstack] = nil
end

local parse_for_stat = function(ls, cs, line)
    local tok = ls.token
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append_kw(tok.name)
    ls:get()
    assert_name(ls)
    cs:append_kw(tok.value or tok.name)
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
        cs:append_kw("in")
        ls:get()
        parse_expr_list(ls, cs)
    else
        syntax_error(ls, "'=' or 'in' expected")
    end
    assert_append_kw(ls, cs, "do")
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, "end", "for", line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append_kw(tok.name)
    ls:get()
    loopstack[#loopstack] = nil
end

local parse_if_stat = function(ls, cs, line)
    local tok = ls.token
    cs:append_kw(tok.name)
    ls:get()
    local tok = ls.token
    parse_expr(ls, cs)
    assert_append_kw(ls, cs, "then")
    ls:get()
    parse_chunk(ls, cs)
    while tok.name == "elseif" do
        cs:append_kw(tok.name)
        ls:get()
        parse_expr(ls, cs)
        assert_append_kw(ls, cs, "then")
        ls:get()
        parse_chunk(ls, cs)
    end
    if tok.name == "else" then
        cs:append_kw(tok.name)
        ls:get()
        parse_chunk(ls, cs)
    end
    check_match(ls, "end", "if", line)
    cs:append_kw(tok.name)
    ls:get()
end

local parse_local_function_stat = function(ls, cs, line)
    local tok = ls.token
    assert_name(ls)
    cs:append_kw(tok.value or tok.name)
    ls:get()
    parse_function_body(ls, cs, line)
end

local prepn = function(names, name)
    local ret = {}
    for i = 1, #names do
        ret[i] = tconc { name, ".", names[i] }
    end
    return ret
end

local parse_local_stat = function(ls, cs)
    local ns = parse_name_list(ls, cs, {})
    local tok = ls.token
    if tok.name == "=" then
        cs:append(tok.name)
        ls:get()
        parse_expr_list(ls, cs)
    elseif tok.name == "in" then
        cs:append(";do local ___local_in=")
        ls:get()
        parse_expr(ls, cs)
        local pos = cs.last_append
        local nlist, ilist = tconc(ns, ","),
            tconc(prepn(ns, "___local_in"), ",")
        cs:append(";" .. nlist, pos + 1)
        cs:append("=", pos + 2)
        cs:append(ilist .. " end;", pos + 3)
    end
end

local parse_function_stat = function(ls, cs)
    local tok = ls.token
    local line = ls.line_number
    cs:append_kw(tok.name)
    ls:get()
    assert_name(ls)
    cs:append_kw(tok.value or tok.name)
    ls:get()
    if tok.name == ":" or tok.name == "." then
        cs:append(tok.name)
        ls:get()
        assert_name(ls)
        cs:append_kw(tok.value or tok.name)
        ls:get()
    end
    parse_function_body(ls, cs, line)
end

local parse_expr_stat = function(ls, cs)
    local buflen = #cs.buffer
    if not parse_primary_expr(ls, cs) then
        parse_assignment(ls, cs, buflen)
    end
end

local parse_return_stat = function(ls, cs)
    local tok = ls.token
    cs:append_kw(tok.name)
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
        cs:append_kw(tok.name)
        ls:get()
        parse_chunk(ls, cs)
        check_match(ls, "end", "do", line)
        cs:append_kw(tok.name)
        ls:get()
    end,
    ["for"] = parse_for_stat,
    ["repeat"] = parse_repeat_stat,
    ["function"] = parse_function_stat,
    ["local"] = function(ls, cs)
        local tok = ls.token
        cs:append_kw(tok.name)
        ls:get()
        if tok.name == "function" then
            local line = ls.line_number
            cs:append_kw(tok.name)
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
        if ls:lookahead() == "<name>" then
            return parse_goto_stat(ls, cs)
        else
            return parse_expr_stat(ls, cs)
        end
    end,
    ["::"] = function(ls, cs)
        local tok = ls.token
        cs:append("::")
        ls:get()
        assert_name(ls)
        cs:append(tok.value or tok.name)
        ls:get()
        assert_append(ls, cs, "::")
        ls:get()
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
            cs:append_kw("do")
            ls:get()
            local line = ls.line_number
            parse_chunk(ls, cs)
            check_match(ls, "end", "do", line)
            cs:append_kw(ls.token.name)
            ls:get()
            cs.enabled = true
        else
            parse_expr_stat(ls, cs)
        end
    end
}

parse_stat = function(ls, cs)
    local opt = stat_opts[ls.token.name]
    if opt then
        return opt(ls, cs, ls.line_number)
    else
        return parse_expr_stat(ls, cs)
    end
end

local parse = function(chunkname, input, debug)
    local ls = lexer.init(chunkname, input)
    local cs = codegen.init(ls, debug)
    ls.cs = cs
    ls:get()
    loopstack[#loopstack + 1] = false
    parse_chunk(ls, cs)
    loopstack[#loopstack] = nil
    return cs:build()
end

return { parse = parse }
