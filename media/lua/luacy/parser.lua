--[[ Luacy 0.1 parser

    Author: Daniel "q66" Kolesa <quaker66@gmail.com>
    Available under the terms of the MIT license.
]]

local lexer = require("luacy.lexer")
local codegen = require("luacy.codegen")

local tconc = table.concat

local syntax_error = lexer.syntax_error
local iskw = lexer.is_keyword

local strchar = string.char

local bytemap = {}
for i = 0, 255 do bytemap[i] = strchar(i) end

local BYTE_MAX = 255

-- copy here for fast optimized lookups
local Tokens = {
    ["and"     ] = 256, ["break"   ] = 257, ["continue"] = 258,
    ["debug"   ] = 259, ["do"      ] = 260, ["else"    ] = 261,
    ["elseif"  ] = 262, ["end"     ] = 263, ["false"   ] = 264,
    ["for"     ] = 265, ["function"] = 266, ["goto"    ] = 267,
    ["if"      ] = 268, ["in"      ] = 269, ["local"   ] = 270,
    ["nil"     ] = 271, ["not"     ] = 272, ["or"      ] = 273,
    ["repeat"  ] = 274, ["return"  ] = 275, ["then"    ] = 276,
    ["true"    ] = 277, ["until"   ] = 278, ["while"   ] = 279,

    [".."] = 280, ["..."] = 281, ["=="] = 282, [">="] = 283,
    ["<="] = 284, ["~=" ] = 285, ["!="] = 286, ["::"] = 287,
    ["{:"] = 288, [":}" ] = 289, ["^^"] = 290, ["<<"] = 291,
    [">>"] = 292, [">>>"] = 293,

    ["<number>"] = 294, ["<string>"] = 295, ["<name>"] = 296, ["<eof>"] = 297
}

local Token_Arr = {
    "and", "break", "continue", "debug", "do", "else", "elseif", "end",
    "false", "for", "function", "goto", "if", "in", "local", "nil", "not",
    "or", "repeat", "return", "then", "true", "until", "while",

    "..", "...", "==", ">=", "<=", "~=", "!=", "::", "{:", ":}", "^^", "<<",
    ">>", ">>>",

    "<number>", "<string>", "<name>", "<eof>"
}

local toktostr = function(tok)
    return (tok <= 255) and bytemap[tok] or Token_Arr[tok - BYTE_MAX]
end

local assert_tok = function(ls, tok)
    local n = ls.token.id
    if tok == n then return nil end
    syntax_error(ls, "'" .. toktostr(tok) .. "' expected")
end

local Name_Keywords = {
    [Tokens["<name>"]]   = true, [Tokens["goto"]]  = true,
    [Tokens["continue"]] = true, [Tokens["debug"]] = true
}

local assert_name = function(ls)
    local n = ls.token.id
    if not Name_Keywords[n] then
        syntax_error(ls, "'<name>' expected")
    end
end

local assert_append = function(ls, cs, tok, ...)
    assert_tok(ls, tok)
    cs:append(toktostr(tok), ...)
end

local assert_next = function(ls, tok)
    assert_tok(ls, tok)
    ls:get()
end

local check_match = function(ls, a, b, line)
    if not ls.token.id == a then
        if line == ls.line_number then
            syntax_error(ls, "'" .. toktostr(ls.token.id) .. "' expected")
        else
            syntax_error(ls, "'" .. toktostr(a) .. "' expected (to close '"
                .. toktostr(b) .. "' at line " .. line .. ")")
        end
    end
end

local loopstack = {}

local Binary_Ops = {
    [Tokens["or"]] = 1, [Tokens["and"]] = 2,

    [Tokens["<="]] = 3, [Tokens[">="]] = 3, [60] = 3, [62] = 3, -- <, >
    [Tokens["=="]] = 3, [Tokens["~="]] = 3, [Tokens["!="]] = 3,

    [Tokens[".."]] = 4,

    [Tokens["^^"]] = 6, [124] = 5, [38] = 7, -- |, &
    [Tokens["<<"]] = 8, [Tokens[">>"]] = 8, [Tokens[">>>"]] = 8,

    [43] = 9,  [45] = 9,             -- +, -
    [42] = 10, [47] = 10, [37] = 10, -- *, /, %

    -- unary here --

    [94] = 12 -- ^
}

local Right_Ass = {
    [Tokens[".."]] = true, [94] = true -- ^
}

-- -, ~, #
local Unary_Ops = {
    [45] = 11, [Tokens["not"]] = 11, [126] = 11, [35] = 11
}

local parse_expr
local parse_chunk

local parse_expr_list = function(ls, cs)
    local tok = ls.token
    while true do
        parse_expr(ls, cs)
        if tok.id == 44 then -- ,
            cs:append(",")
            ls:get()
        else
            break
        end
    end
end

local parse_arg_list = function(ls, cs)
    local tok = ls.token
    while true do
        if tok.id == Tokens["..."] then
            cs:append("...")
            ls:get()
            break
        elseif not Name_Keywords[tok.id] then
            syntax_error(ls, "<name> or '...' expected")
        end
        cs:append(tok.value or toktostr(tok.id), true)
        ls:get()
        if tok.id == 44 then -- ,
            cs:append(",")
            ls:get()
        else
            break
        end
    end
end

local parse_table = function(ls, cs)
    local line = ls.line_number
    local tok = ls.token
    cs:append("{")
    ls:get()
    local tid = tok.id
    while true do
        if tid == 125 then break -- }
        elseif Name_Keywords[tid] then
            local line = ls.line_number
            if ls:lookahead() == 61 then -- =
                cs:append(tok.value or toktostr(tid), true, line)
                ls:get()
                cs:append("=")
                ls:get()
            end
            parse_expr(ls, cs)
        elseif tid == 91 then -- [
            cs:append("[")
            ls:get()
            parse_expr(ls, cs)
            assert_append(ls, cs, 93) -- ]
            ls:get()
            assert_append(ls, cs, 61) -- =
            ls:get()
            parse_expr(ls, cs)
        else
            parse_expr(ls, cs)
        end
        tid = tok.id
        if tid ~= 44 and tid ~= 59 then break end -- , ;
        cs:append(toktostr(tid))
        ls:get()
        tid = tok.id
    end
    check_match(ls, 125, 123, line) -- } {
    cs:append("}")
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
    local tid = tok.id
    local tracked = { name }
    cs.tracked = tracked
    cs:append("local", true)
    cs:append(pname, true)
    cs:append("= 0;")
    while true do
        if tid == Tokens[":}"] then break end
        assert_name(ls)
        local field = tok.value or toktostr(tok.id)
        tracked[field] = true
        local line = ls.line_number
        ls:get()
        cs:append(pname, true, line)
        cs:append("=", nil, line)
        if tok.id == 61 then -- =
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
        tid = tok.id
        if tid ~= 44 and tid ~= 59 then break end -- , ;
        tid = ls:get()
    end
    cs.tracked = nil
    cs:append("return", true)
    cs:append(name, true)
    check_match(ls, Tokens[":}"], Tokens["{:"], line)
    cs:append(" end)({})")
    ls:get()
end

local parse_function_body = function(ls, cs, line)
    assert_append(ls, cs, 40) -- (
    ls:get()
    if ls.token.id ~= 41 then parse_arg_list(ls, cs) end -- )
    assert_append(ls, cs, 41)
    ls:get()
    loopstack[#loopstack + 1] = false
    parse_chunk(ls, cs)
    check_match(ls, Tokens["end"], Tokens["function"], line)
    cs:append("end", true)
    ls:get()
end

local parse_call = function(ls, cs)
    local tok = ls.token
    local tid = tok.id
    if tid == 40 then -- (
        local line = ls.line_number
        if line ~= ls.last_line then syntax_error(ls,
            "ambiguous syntax (function call x new statement)")
        end
        cs:append("(")
        ls:get()
        tid = tok.id
        if tid == 41 then -- )
            cs:append(")")
            ls:get()
        else
            parse_expr_list(ls, cs)
            check_match(ls, 41, 40, line)
            cs:append(")")
            ls:get()
        end
    elseif tid == 123 then -- {
        parse_table(ls, cs)
    elseif tid == Tokens["<string>"] then
        cs:append(tok.value)
        ls:get()
    else
        syntax_error(ls, "function arguments expected")
    end
end

local parse_prefix_expr = function(ls, cs)
    local tok = ls.token
    local tid = tok.id
    if tid == 40 then -- (
        local line = ls.line_number
        cs:append("(")
        ls:get()
        parse_expr(ls, cs)
        check_match(ls, 41, 40, line)
        cs:append(")")
        ls:get()
    elseif Name_Keywords[tid] then
        local tracked = cs.tracked
        local varn = tok.value or toktostr(tid)
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
        local id = tok.id
        if id == 46 or id == 58 then -- ., :
            cs:append(toktostr(id))
            ls:get()
            assert_name(ls)
            cs:append(tok.value or toktostr(tok.id), true)
            ls:get()
            call = false
            if id == 58 then
                parse_call(ls, cs)
                call = true
            end
        elseif id == 91 then -- [
            cs:append("[")
            ls:get()
            parse_expr(ls, cs)
            assert_append(ls, cs, 93) -- ]
            ls:get()
            call = false
        elseif id == 40 or id == Tokens["<string>"] or id == 123 then -- (, {
            parse_call(ls, cs)
            call = true
        else
            return call
        end
    end
end

local parse_subexpr

local sexps = {
    [Tokens["<number>"]] = function(ls, cs)
        cs:append("(")
        cs:append(ls.token.value)
        cs:append(")")
        ls:get()
    end,
    [Tokens["<string>"]] = function(ls, cs)
        cs:append(ls.token.value)
        ls:get()
    end,
    [Tokens["nil"]] = function(ls, cs)
        cs:append(toktostr(ls.token.id), true)
        ls:get()
    end,
    [123] = parse_table, -- {
    [Tokens["{:"]] = parse_enum,
    [Tokens["function"]] = function(ls, cs)
        local line = ls.line_number
        cs:append("function", true)
        ls:get()
        parse_function_body(ls, cs, line)
    end,
    [124] = function(ls, cs) -- |
        local tok = ls.token
        cs:append("function", true)
        cs:append("(")
        ls:get()
        if tok.id ~= 124 then parse_arg_list(ls, cs) end
        assert_tok(ls, 124)
        cs:append(")")
        ls:get()
        loopstack[#loopstack + 1] = false
        if tok.id == Tokens["do"] then
            local line = ls.line_number
            ls:get()
            parse_chunk(ls, cs)
            check_match(ls, Tokens["end"], Tokens["do"], line)
            cs:append("end", true)
            ls:get()
        else
            cs:append("return", true)
            parse_expr(ls, cs)
            cs:append("end", true)
        end
    end,
    [Tokens["if"]] = function(ls, cs)
        local tok = ls.token
        cs:append("(")
        ls:get()
        parse_expr(ls, cs)
        assert_tok(ls, Tokens["then"])
        cs:append("and", true)
        ls:get()
        cs:append("{")
        parse_expr(ls, cs)
        cs:append("}", nil, cs.last_append)
        if tok.id == Tokens["else"] then
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
sexps[Tokens["true" ]] = sexps[Tokens["nil"]]
sexps[Tokens["false"]] = sexps[Tokens["nil"]]
sexps[Tokens["..."  ]] = sexps[Tokens["nil"]]

local bitunops = {
    [126] = "bit.bnot" -- ~
}

local parse_simple_expr = function(ls, cs)
    local tid = ls.token.id
    local unp = Unary_Ops[tid]
    if unp then
        local bitun = bitunops[tid]
        if bitun then
            cs:append(bitun, true)
            cs:append("(")
            ls:get()
            parse_subexpr(ls, cs, unp)
            cs:append(")", cs.last_append)
        else
            local str = toktostr(tid)
            cs:append(str, iskw(str))
            ls:get()
            parse_subexpr(ls, cs, unp)
        end
    else
        (sexps[tid] or parse_primary_expr)(ls, cs)
    end
end

local op_to_lua = {
    [Tokens["!="]] = "~="
}

local bitops = {
    [Tokens["^^" ]] = "bxor",   [38] = "band", [124] = "bor",
    [Tokens["<<" ]] = "lshift", [Tokens[">>"]] = "rshift",
    [Tokens[">>>"]] = "arshift"
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
        local op = tok.id
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
            local opstr = toktostr(op)
            cs:append(op_to_lua[op] or opstr, iskw(opstr))
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
        cs:append(tok.value or toktostr(tok.id), true)
        ls:get()
        if tok.id == 44 then -- ,
            cs:append(",")
            ls:get()
        else
            break
        end
    end
end

local block_follow = {
    [Tokens["else" ]] = true, [Tokens["elseif"]] = true,
    [Tokens["end"  ]] = true, [Tokens["until" ]] = true,
    [Tokens["<eof>"]] = true
}

local parse_stat

parse_chunk = function(ls, cs)
    local last = false
    local tok = ls.token
    while not last and not block_follow[tok.id] do
        last = parse_stat(ls, cs)
        if tok.id == 59 then -- ;
            cs:append(";")
            ls:get()
        end
    end
end

local parse_assignment = function(ls, cs)
    local tok = ls.token
    if tok.id == 44 then -- ,
        cs:append(",")
        ls:get()
        while true do
            parse_primary_expr(ls, cs)
            if tok.id ~= 44 then break end
            cs:append(",")
            ls:get()
        end
    end
    assert_append(ls, cs, 61) -- =
    ls:get()
    parse_expr_list(ls, cs)
end

local parse_break_stat = function(ls, cs)
    if not loopstack[#loopstack] then
        syntax_error(ls, "no loop to break")
    end
    cs:append("break", true)
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
    cs:append("goto", true)
    ls:get()
    assert_name(ls)
    cs:append(tok.value or toktostr(tok.id), true)
    ls:get()
end

local parse_while_stat = function(ls, cs, line)
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append("while", true)
    ls:get()
    parse_expr(ls, cs)
    assert_append(ls, cs, Tokens["do"], true)
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, Tokens["end"], Tokens["while"], line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append("end", true)
    ls:get()
end

local parse_repeat_stat = function(ls, cs, line)
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append("repeat", true)
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, Tokens["until"], Tokens["repeat"], line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append("until", true)
    ls:get()
    parse_expr(ls, cs)
end

local parse_for_stat = function(ls, cs, line)
    local tok = ls.token
    local lbl = "___loop_end"
    loopstack[#loopstack + 1] = lbl
    cs:append("for", true)
    ls:get()
    assert_name(ls)
    cs:append(tok.value or toktostr(tok.id), true)
    ls:get()
    if tok.id == 61 then -- =
        cs:append("=")
        ls:get()
        parse_expr(ls, cs)
        assert_append(ls, cs, 44) -- ,
        ls:get()
        parse_expr(ls, cs)
        if tok.id == 44 then
            cs:append(",")
            ls:get()
            parse_expr(ls, cs)
        end
    elseif tok.id == 44 or tok.id == Tokens["in"] then
        if tok.id == 44 then
            cs:append(",")
            ls:get()
            parse_name_list(ls, cs)
            assert_tok(ls, Tokens["in"])
        end
        cs:append("in", true)
        ls:get()
        parse_expr_list(ls, cs)
    else
        syntax_error(ls, "'=' or 'in' expected")
    end
    assert_append(ls, cs, Tokens["do"], true)
    ls:get()
    parse_chunk(ls, cs)
    check_match(ls, Tokens["end"], Tokens["for"], line)
    cs:append("::")
    cs:append(lbl)
    cs:append("::")
    cs:append("end", true)
    ls:get()
end

local parse_if_stat = function(ls, cs, line)
    cs:append("if", true)
    ls:get()
    local tok = ls.token
    parse_expr(ls, cs)
    assert_append(ls, cs, Tokens["then"], true)
    ls:get()
    parse_chunk(ls, cs)
    while tok.id == Tokens["elseif"] do
        cs:append("elseif", true)
        ls:get()
        parse_expr(ls, cs)
        assert_append(ls, cs, Tokens["then"], true)
        ls:get()
        parse_chunk(ls, cs)
    end
    if tok.id == Tokens["else"] then
        cs:append("else", true)
        ls:get()
        parse_chunk(ls, cs)
    end
    check_match(ls, Tokens["end"], Tokens["if"], line)
    cs:append("end", true)
    ls:get()
end

local parse_local_function_stat = function(ls, cs, line)
    local tok = ls.token
    assert_name(ls)
    cs:append(tok.value or toktostr(tok.id), true)
    ls:get()
    parse_function_body(ls, cs, line)
end

local parse_local_stat = function(ls, cs)
    parse_name_list(ls, cs)
    if ls.token.id == 61 then -- =
        cs:append("=")
        ls:get()
        parse_expr_list(ls, cs)
    end
end

local parse_function_stat = function(ls, cs)
    local tok = ls.token
    local line = ls.line_number
    cs:append("function", true)
    ls:get()
    assert_name(ls)
    cs:append(tok.value or toktostr(tok.id), true)
    ls:get()
    if tok.id == 58 or tok.id == 46 then -- :, .
        cs:append(toktostr(tok.id))
        ls:get()
        assert_name(ls)
        cs:append(tok.value or toktostr(tok.id), true)
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
    cs:append("return", true)
    ls:get()
    if tok.id == 59 or block_follow[tok.id] then -- ;
        return true
    end
    parse_expr_list(ls, cs)
    return true
end

local stat_opts = {
    [Tokens["if"]] = parse_if_stat,
    [Tokens["while"]] = parse_while_stat,
    [Tokens["do"]] = function(ls, cs, line)
        cs:append("do", true)
        ls:get()
        parse_chunk(ls, cs)
        check_match(ls, Tokens["end"], Tokens["do"], line)
        cs:append("end", true)
        ls:get()
    end,
    [Tokens["for"]] = parse_for_stat,
    [Tokens["repeat"]] = parse_repeat_stat,
    [Tokens["function"]] = parse_function_stat,
    [Tokens["local"]] = function(ls, cs)
        local tok = ls.token
        cs:append("local", true)
        ls:get()
        if tok.id == Tokens["function"] then
            local line = ls.line_number
            cs:append("function", true)
            ls:get()
            return parse_local_function_stat(ls, cs, line)
        else
            return parse_local_stat(ls, cs)
        end
    end,
    [Tokens["return"]] = parse_return_stat,
    [Tokens["break"]] = parse_break_stat,
    [Tokens["continue"]] = function(ls, cs)
        local lah = ls:lookahead()
        if lah == 59 or block_follow[lah] then -- ;
            parse_cont_stat(ls, cs)
        else
            parse_expr_stat(ls, cs)
        end
    end,
    [Tokens["goto"]] = function(ls, cs)
        ((ls:lookahead() == Tokens["<name>"]) and parse_goto_stat
            or parse_expr_stat)(ls, cs)
    end,
    [Tokens["debug"]] = function(ls, cs)
        local lah = ls:lookahead()
        if lah == Tokens["then"] then
            cs.enabled = cs.debug
            ls:get()
            ls:get()
            parse_stat(ls, cs)
            cs.enabled = true
        elseif lah == Tokens["do"] then
            cs.enabled = cs.debug
            ls:get()
            cs:append("do", true)
            ls:get()
            local line = ls.line_number
            parse_chunk(ls, cs)
            check_match(ls, Tokens["end"], Tokens["do"], line)
            cs:append("end", true)
            ls:get()
            cs.enabled = true
        else
            parse_expr_stat(ls, cs)
        end
    end
}

parse_stat = function(ls, cs)
    return (stat_opts[ls.token.id] or parse_expr_stat)(ls, cs, ls.line_number)
end

local parse = function(fname, input, debug)
    local ls = lexer.init(fname, input)
    local cs = codegen.init(ls, debug)
    ls.cs = cs
    ls:get()
    loopstack[#loopstack + 1] = false
    parse_chunk(ls, cs)
    assert_tok(ls, Tokens["<eof>"])
    return cs:build()
end

return { parse = parse }
