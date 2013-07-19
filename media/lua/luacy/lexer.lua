--[[ Luacy 0.1 lexer

    Author: Daniel "q66" Kolesa <quaker66@gmail.com>
    Available under the terms of the MIT license.
]]

local tconc = table.concat
local tonumber = tonumber
local assert = assert
local strchar = string.char

local strstream
if package.preload["ffi"] then
    local ffi = require("ffi")
    local bytemap = {}
    for i = 0, 255 do bytemap[i] = strchar(i) end
    strstream = function(str)
        local len = #str
        local cstr = ffi.new("char[?]", len + 1, str)
        local i = -1
        return function()
            i = i + 1
            if i >= len then return nil end
            return bytemap[cstr[i]]
        end
    end
else
    strstream = function(str)
        return str:gmatch(".")
    end
end

local Keywords = {
    ["and"     ] = true, ["break"   ] = true, ["continue"] = true,
    ["debug"   ] = true, ["do"      ] = true, ["else"    ] = true,
    ["elseif"  ] = true, ["end"     ] = true, ["false"   ] = true,
    ["for"     ] = true, ["function"] = true, ["goto"    ] = true,
    ["if"      ] = true, ["in"      ] = true, ["local"   ] = true,
    ["nil"     ] = true, ["not"     ] = true, ["or"      ] = true,
    ["repeat"  ] = true, ["return"  ] = true, ["then"    ] = true,
    ["true"    ] = true, ["until"   ] = true, ["while"   ] = true
}

-- protected from the GC this way
local tokens = { "..", "...", "==", ">=", "<=", "~=", "::",
    "<number>", "<name>", "<string>", "<eof>"
}

local is_newline = function(c)
    return c == "\n" or c == "\r"
end

local is_white = function(c)
    return c == " " or c == "\t" or c == "\f" or c == "\v"
end

local is_alpha = function(ch)
    if not ch then return false end
    local   i = ch:byte()
    return (i >= 65 and i <= 90) or (i >= 97 and i <= 122)
end

local is_alnum = function(ch)
    if not ch then return false end
    local   i = ch:byte()
    return (i >= 48 and i <= 57) or (i >= 65 and i <= 90)
        or (i >= 97 and i <= 122)
end

local is_digit = function(ch)
    if not ch then return false end
    local   i = ch:byte()
    return (i >= 48 and i <= 57)
end

local is_hex_digit = function(ch)
    if not ch then return false end
    local i = ch:byte()
    return (i >= 48 and i <= 57) or (i >= 65 and i <= 70)
        or (i >= 97 and i <= 102)
end

local lex_error = function(ls, msg, tok)
    msg = ("%s:%d: %s"):format(ls.source, ls.line_number, msg)
    if tok then
        msg = msg .. " near '" .. tok .. "'"
    end
    error(msg, 0)
end

local syntax_error = function(ls, msg)
    lex_error(ls, msg, ls.token.value or ls.token.name)
end

local next_char = function(ls)
    local c = ls.reader()
    ls.current = c
    return c
end

local next_line = function(ls, cs)
    local old = ls.current
    assert(is_newline(old))
    local c = next_char(ls)
    if is_newline(c) and c ~= old then
        c = next_char(ls)
    end
    ls.line_number = ls.line_number + 1
    return c
end

local read_number = function(ls, tok, buf)
    local exp = { "E", "e" }
    local first = ls.current
    assert(is_digit(first))
    buf[#buf + 1] = first
    local c = next_char(ls)
    if first == "0" and (c == "X" or c == "x") then
        buf[#buf + 1] = c
        c = next_char(ls)
        exp = { "P", "p" }
    end
    while true do
        if c == exp[1] or c == exp[2] then
            buf[#buf + 1] = c
            c = next_char(ls)
            if c == "+" or c == "-" then
                buf[#buf + 1] = c
                c = next_char(ls)
            end
        end
        if is_hex_digit(c) or c == "." then
            buf[#buf + 1] = c
            c = next_char(ls)
        else
            break
        end
    end
    local str = tconc(buf)
    if not tonumber(str) then
        lex_error(ls, "malformed number", str)
    end
    -- keep it in string form - passed to lua directly
    tok.value = str
end

local skip_sep = function(ls, buf)
    local cnt = 0
    local s = ls.current
    assert(s == "[" or s == "]")
    buf[#buf + 1] = s
    local c = next_char(ls)
    while c == "=" do
        buf[#buf + 1] = c
        c = next_char(ls)
        cnt = cnt + 1
    end
    return c == s and cnt or ((-cnt) - 1)
end

local read_long_string = function(ls, tok, sep, buf)
    buf = buf or {}
    local c = ls.current
    if tok then buf[#buf + 1] = c end
    c = next_char(ls)
    if is_newline(c) then c = next_line(ls) end
    while true do
        if not c then
            lex_error(ls, tok and "unfinished long string"
                or "unfinished long comment", "<eof>")
        elseif c == "]" then
            if skip_sep(ls, buf) == sep then
                if tok then buf[#buf + 1] = ls.current end
                c = next_char(ls)
                break
            end
            c = ls.current
        elseif c == "\n" or c == "\r" then
            if tok then buf[#buf + 1] = "\n" end
            c = next_line(ls)
        else
            if tok then buf[#buf + 1] = c end
            c = next_char(ls)
        end
    end
    if tok then tok.value = tconc(buf) end
end

local esc_error = function(ls, str, msg)
    lex_error(ls, msg, "\\" .. str)
end

local read_hex_esc = function(ls)
    local buf = { "0x" }
    for i = 2, 3 do
        local c = next_char(ls)
        if not is_hex_digit(c) then
            esc_error(ls, "x" .. c, "hexadecimal digit expected")
        end
        buf[i] = c
    end
    return "\\" .. tonumber(tconc(buf))
end

local read_dec_esc = function(ls)
    local buf = {}
    local c = ls.current
    for i = 1, 3 do
        buf[i] = c
        c = next_char(ls)
        if not is_digit(c) then break end
    end
    local s = tconc(buf)
    local n = tonumber(s)
    if n > 255 then
        esc_error(ls, s, "decimal escape too large")
    end
    return "\\" .. n
end

local esc_opts = {
    ["a"] = "\\a",
    ["b"] = "\\b",
    ["f"] = "\\f",
    ["n"] = "\\n",
    ["r"] = "\\r",
    ["t"] = "\\t",
    ["v"] = "\\v"
}

local read_string = function(ls, tok)
    local delim = ls.current
    local buf = { delim }
    local c = next_char(ls)
    while c ~= delim do
        if not c then lex_error(ls, "unfinished string", "<eof>")
        elseif c == "\n" or c == "\r" then
            lex_error(ls, "unfinished string", tconc(buf))
        elseif c == "\\" then
            c = next_char(ls)
            local esc = esc_opts[c]
            if esc then
                buf[#buf + 1] = esc
                c = next_char(ls)
            elseif c == "x" then
                buf[#buf + 1] = read_hex_esc(ls)
                c = next_char(ls)
            elseif c == "\n" or c == "\r" then
                c = next_line(ls)
                buf[#buf + 1] = "\\\n"
            elseif c == "\\" or c == '"' or c == "'" then
                buf[#buf + 1] = "\\" .. c
                c = next_char(ls)
            elseif c == "z" then
                c = next_char(ls)
                while is_white(c) do
                    c = (is_newline(c) and next_line or next_char)(ls)
                end
            elseif c ~= nil then
                if not is_digit(c) then
                    esc_error(ls, c, "invalid escape sequence")
                end
                buf[#buf + 1] = read_dec_esc(ls)
                c = ls.current
            end
        else
            buf[#buf + 1] = c
            c = next_char(ls)
        end
    end
    buf[#buf + 1] = c
    next_char(ls)
    tok.value = tconc(buf)
end

local lextbl = {
    ["\n"] = function(ls) next_line(ls) end,
    [" " ] = function(ls) next_char(ls) end,
    ["-" ] = function(ls)
        local c = next_char(ls)
        if c ~= "-" then return "-" end
        c = next_char(ls)
        if c == "[" then
            local sep = skip_sep(ls, {})
            if sep >= 0 then
                read_long_string(ls, nil, sep)
                return nil
            end
        end
        while ls.current and not is_newline(ls.current) do next_char(ls) end
    end,
    ["["] = function(ls, tok)
        local buf = {}
        local sep = skip_sep(ls, buf)
        if sep >= 0 then
            read_long_string(ls, tok, sep, buf)
            return "<string>"
        elseif sep == -1 then return "["
        else lex_error(ls, "invalid long string delimiter", tconc(buf)) end
    end,
    ["="] = function(ls)
        local c = next_char(ls)
        if c ~= "=" then return "="
        else next_char(ls); return "==" end
    end,
    ["<"] = function(ls)
        local c = next_char(ls)
        if     c == "<" then next_char(ls); return "<<"
        elseif c == "=" then next_char(ls); return "<="
        else return "<" end
    end,
    [">"] = function(ls)
        local c = next_char(ls)
        if c == ">" then
            c = next_char(ls)
            if c ~= ">" then return ">>"
            else next_char(ls); return ">>>" end
        elseif c == "=" then next_char(ls); return ">="
        else return ">" end
    end,
    ["~"] = function(ls)
        local c = next_char(ls)
        if c ~= "=" then return "~"
        else next_char(ls); return "~=" end
    end,
    ["!"] = function(ls)
        local c = next_char(ls)
        if c ~= "=" then return "!"
        else next_char(ls); return "!=" end
    end,
    ["^"] = function(ls)
        local c = next_char(ls)
        if c ~= "^" then return "^"
        else next_char(ls); return "^^" end
    end,
    ["{"] = function(ls)
        local c = next_char(ls)
        if c ~= ":" then return "{"
        else next_char(ls); return "{:" end
    end,
    [":"] = function(ls)
        local c = next_char(ls)
        if     c == "}" then next_char(ls); return ":}"
        elseif c == ":" then next_char(ls); return "::"
        else return ":" end
    end,
    ['"'] = function(ls, tok)
        read_string(ls, tok)
        return "<string>"
    end,
    ["."] = function(ls, tok)
        local c = next_char(ls)
        if c == "." then
            c = next_char(ls)
            if c == "." then
                next_char(ls)
                return "..."
            else
                return ".."
            end
        elseif not is_digit(c) then
            return "."
        end
        read_number(ls, tok, { "." })
        return "<number>"
    end,
    ["0"] = function(ls, tok)
        read_number(ls, tok, {})
        return "<number>"
    end
}
lextbl["\r"] = lextbl["\n"]
lextbl["\f"] = lextbl[" "]
lextbl["\t"] = lextbl[" "]
lextbl["\v"] = lextbl[" "]
lextbl["'" ] = lextbl['"']
lextbl["1" ] = lextbl["0"]
lextbl["2" ] = lextbl["0"]
lextbl["3" ] = lextbl["0"]
lextbl["4" ] = lextbl["0"]
lextbl["5" ] = lextbl["0"]
lextbl["6" ] = lextbl["0"]
lextbl["7" ] = lextbl["0"]
lextbl["8" ] = lextbl["0"]
lextbl["9" ] = lextbl["0"]

local lex_default = function(ls, tok)
    local c = ls.current
    if c == "_" or is_alpha(c) then
        local buf = {}
        repeat
            buf[#buf + 1] = c
            c = next_char(ls)
            if not c then break end
        until not (c == "_" or is_alnum(c))
        local str = tconc(buf)
        if Keywords[str] then
            return str
        else
            tok.value = str
            return "<name>"
        end
    else
        local c = ls.current
        next_char(ls)
        return c
    end
end

local lex = function(ls, tok)
    while true do
        local c = ls.current
        if c == nil then return "<eof>" end
        local v = (lextbl[c] or lex_default)(ls, tok)
        if v then return v end
    end
end

local State_MT = {
    __index = {
        get = function(ls)
            ls.last_line = ls.line_number

            local tok, lah = ls.token, ls.ltoken
            if lah.name then
                tok.name, tok.value = lah.name, lah.value
                lah.name, lah.value = nil, nil
            else
                tok.value = nil
                tok.name = lex(ls, tok)
            end
            return tok.name
        end,

        lookahead = function(ls)
            local lah = ls.ltoken
            assert(not lah.name)
            local name = lex(ls, lah)
            lah.name = name
            return name
        end
    }
}

local skip_bom = function(rdr)
    local c = rdr()
    if c ~= 0xEF then return c end
    c = rdr()
    if c ~= 0xBB then return c end
    c = rdr()
    if c ~= 0xBF then return c end
    return rdr()
end

local skip_shebang = function(rdr)
    local c = skip_bom(rdr)
    if c == "#" then
        repeat
            c = rdr()
        until c == "\n" or c == "\r" or not c
        local e = c
        c = rdr()
        if (e == "\n" and c == "\r") or (e == "\r" and c == "\n") then
            c = rdr()
        end
    end
    return c
end

local init = function(fname, input)
    local reader  = type(input) == "string" and strstream(input) or input
    local current = skip_shebang(reader)
    return setmetatable({
        reader      = reader,
        token       = { name = nil, value = nil },
        ltoken      = { name = nil, value = nil },
        source      = fname,
        current     = current,
        line_number = 1,
        last_line   = 1
    }, State_MT)
end

return {
    init = init,
    syntax_error = syntax_error,
    is_keyword = function(kw) return Keywords[kw] end
}
