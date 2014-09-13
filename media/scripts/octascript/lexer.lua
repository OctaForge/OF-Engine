--[[
    OctaScript

    Copyright (C) 2014 Daniel "q66" Kolesa

    See COPYING.txt for licensing.
]]

local tconc = table.concat
local tonumber = tonumber
local tostring = tostring
local assert = assert
local strchar = string.char

local bytemap = {}
for i = 0, 255 do bytemap[i] = strchar(i) end

local ffi = require("ffi")

local uint64, int64 = ffi.typeof("uint64_t"), ffi.typeof("int64_t")
local complex = ffi.typeof("complex")

local strstream = function(str)
    local len = #str
    local cstr = ffi.new("char[?]", len + 1, str)
    local i = -1
    return function()
        i = i + 1
        if i >= len then return nil end
        return cstr[i]
    end
end

local Keywords = {
    ["and"     ] = true, ["as"      ] = true, ["break"   ] = true,
    ["by"      ] = true, ["continue"] = true, ["do"      ] = true,
    ["else"    ] = true, ["elif"    ] = true, ["end"     ] = true,
    ["false"   ] = true, ["for"     ] = true, ["from"    ] = true,
    ["func"    ] = true, ["goto"    ] = true, ["if"      ] = true,
    ["import"  ] = true, ["in"      ] = true, ["none"    ] = true,
    ["noscope" ] = true, ["not"     ] = true, ["null"    ] = true,
    ["or"      ] = true, ["rec"     ] = true, ["repeat"  ] = true,
    ["return"  ] = true, ["then"    ] = true, ["to"      ] = true,
    ["true"    ] = true, ["until"   ] = true, ["var"     ] = true,
    ["while"   ] = true
}

-- protected from the gc
local Tokens = {
    "..", "...", "==", ">=", "<=", "~=" , "!=", "::", "{:", ":}" , "^^", "<<",
    ">>", ">>>", "<name>", "<string>", "<number>", "<eof>",

    "..=", "|=", "&=", "^^=", "<<=", ">>=", ">>>=", "+=", "-=", "*=", "/=",
    "%=", "^="
}

local is_newline = function(c)
    return c == 10 or c == 13 -- LF CR
end

local is_white = function(c)
    return c == 32 or c == 9 or c == 11 or c == 12 -- space, \t, \v, \f
end

local is_alpha = function(c)
    if not c then return false end
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
end

local is_alnum = function(c)
    if not c then return false end
    return (c >= 48 and c <= 57) or (c >= 65 and c <= 90)
        or (c >= 97 and c <= 122)
end

local is_digit = function(c)
    if not c then return false end
    return (c >= 48 and c <= 57)
end

local is_hex_digit = function(c)
    if not c then return false end
    return (c >= 48 and c <= 57) or (c >= 65 and c <= 70)
        or (c >= 97 and c <= 102)
end

local max_custom_len = 79
local max_fname_len = 72
local max_str_len = 63

local chname_to_source = function(source)
    local c = source:sub(1, 1)
    local srclen = #source
    if c == "@" then
        if srclen <= (max_fname_len + 1) then
            return source:sub(2)
        else
            return "..." .. source:sub(srclen - max_fname_len + 1)
        end
    elseif c == "=" then
        return source:sub(2, max_custom_len + 1)
    else
        return '[string "' .. source:sub(1, max_str_len)
            .. ((srclen > max_str_len) and '..."]' or '"]')
    end
end

local lex_error = function(ls, msg, tok)
    msg = ("OFS_ERROR%s:%d: %s"):format(ls.source, ls.line_number, msg)
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
    if ls.queue_line then
        ls.queued_line = (ls.queued_line or 0) + 1
    end
    ls.line_number = ls.line_number + 1
    return c
end

local read_binary_number = function(ls, tok)
    local c = ls.current
    local buf = {}
    while is_alnum(c) or c == 95 do -- _
        if c ~= 95 then
            buf[#buf + 1] = bytemap[c]:lower()
        end
        c = next_char(ls)
    end
    local num
    if (buf[#buf] == "l") and (buf[#buf - 1] == "l") then
        local n, mi
        if buf[#buf - 2] == "u" then
            n, mi = uint64(0), #buf - 3
        else
            n, mi = int64(0), #buf - 2
        end
        local i = 1
        while i <= mi and buf[i] do
            if buf[i] == "0" or buf[i] == "1" then
                n = 2 * n + tonumber(buf[i])
                i = i + 1
            else
                n = nil
                break
            end
        end
        num = n
    else
        num = tonumber(tconc(buf), 2)
    end
    if not num then
        lex_error(ls, "malformed number", "0b" .. str)
    end
    tok.value = num
end

local read_number = function(ls, tok, buf, allow_bin)
    local c = ls.current
    assert(is_digit(c))
    if c == 48 then
        buf[#buf + 1] = bytemap[c]
        c = next_char(ls)
        if allow_bin and (c == 66 or c == 98) then -- B, b
            next_char(ls)
            return read_binary_number(ls, tok)
        end
    end
    while is_digit(c) or c == 46 do -- .
        buf[#buf + 1] = bytemap[c]
        c = next_char(ls)
    end
    if c == 69 or c == 101 then -- E, e
        buf[#buf + 1] = bytemap[c]
        c = next_char(ls)
        if c == 43 or c == 45 then -- +, -
            buf[#buf + 1] = bytemap[c]
            c = next_char(ls)
        end
    end
    while is_alnum(c) or c == 95 do -- _
        buf[#buf + 1] = bytemap[c]:lower()
        c = next_char(ls)
    end
    local num
    if buf[#buf] == "i" then
        buf[#buf] = nil
        local img = tonumber(tconc(buf))
        if img then num = complex(0, img) end
    elseif (buf[#buf] == "l") and (buf[#buf - 1] == "l") then
        local n, mi
        if buf[#buf - 2] == "u" then
            n, mi = uint64(0), #buf - 3
        else
            n, mi = int64(0), #buf - 2
        end
        local mul, i
        if buf[1] == "0" and buf[2] == "x" then
            mul, i = 16, 3
        else
            mul, i = 10, 1
        end
        while i <= mi and buf[i] do
            if is_hex_digit(buf[i]:byte()) then
                n = mul * n + tonumber("0x" .. buf[i])
                i = i + 1
            else
                n = nil
                break
            end
        end
        num = n
    else
        num = tonumber(tconc(buf))
    end
    if not num then
        lex_error(ls, "malformed number", tconc(buf))
    end
    tok.value = num
end

local esc_error = function(ls, str, msg)
    lex_error(ls, msg, "\\" .. str)
end

local read_hex_esc = function(ls)
    local buf = { "0x" }
    local err = "x"
    for i = 2, 3 do
        local c = next_char(ls)
        if not is_hex_digit(c) then
            esc_error(ls, err, "hexadecimal digit expected")
        end
        local x = bytemap[c]
        err = err .. x
        buf[i] = x
    end
    return string.char(tonumber(tconc(buf)))
end

local read_dec_esc = function(ls)
    local buf = {}
    local c = ls.current
    for i = 1, 3 do
        buf[i] = bytemap[c]
        c = next_char(ls)
        if not is_digit(c) then break end
    end
    local s = tconc(buf)
    local n = tonumber(s)
    if n > 255 then
        esc_error(ls, s, "decimal escape too large")
    end
    return string.char(n)
end

local esc_opts = {
    [97] = "\a",
    [98] = "\b",
    [102] = "\f",
    [110] = "\n",
    [114] = "\r",
    [116] = "\t",
    [118] = "\v"
}

local read_string = function(ls, tok, raw)
    local delim = ls.current
    local buf = {}
    local c = next_char(ls)
    local long = false
    if c == delim then
        c = next_char(ls)
        if c == delim then
            c = next_char(ls)
            long = true
        else
            tok.value = ""
            return
        end
    end
    while true do
        if not c then lex_error(ls, "unfinished string", "<eof>")
        elseif is_newline(c) then
            if not long then
                lex_error(ls, "unfinished string", tconc(buf))
            end
            buf[#buf + 1] = bytemap[c]
            c = next_char(ls)
        elseif c == 92 then -- \
            c = next_char(ls)
            if raw then
                buf[#buf + 1] = "\\"
                if is_newline(c) then
                    buf[#buf + 1] = "\n"
                    c = next_char(ls)
                end
            else
                local esc = esc_opts[c]
                if esc then
                    buf[#buf + 1] = esc
                    c = next_char(ls)
                elseif c == 120 then -- x
                    buf[#buf + 1] = read_hex_esc(ls)
                    c = next_char(ls)
                elseif is_newline(c) then
                    c = next_line(ls)
                elseif c == 92 or c == 34 or c == 39 then -- \, ", '
                    buf[#buf + 1] = bytemap[c]
                    c = next_char(ls)
                elseif c == 122 then -- z
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
            end
        elseif c == delim then
            if not long then
                break
            end
            c = next_char(ls)
            if c == delim then
                c = next_char(ls)
                if c == delim then
                    break
                end
                buf[#buf + 1] = bytemap[c]
            end
            buf[#buf + 1] = bytemap[c]
        else
            buf[#buf + 1] = bytemap[c]
            c = next_char(ls)
        end
    end
    next_char(ls)
    tok.value = tconc(buf)
end

local read_comment = function(ls)
    local nest = 0
    local c = ls.current
    while true do
        if c == 47 then -- /
            c = next_char(ls)
            if c == 42 then -- *
                c = next_char(ls)
                nest = nest + 1
            end
        elseif c == 42 then -- *
            c = next_char(ls)
            if c == 47 then -- /
                c = next_char(ls)
                if nest == 0 then
                    return
                end
                nest = nest - 1
            end
        else
            c = (is_newline(c) and next_line or next_char)(ls)
        end
    end
end

local lextbl = {
    [10] = function(ls) next_line(ls) end, -- LF
    [32] = function(ls) next_char(ls) end, -- space
    [45] = function(ls) -- -
        local c = next_char(ls)
        if c == 61 then -- =
            next_char(ls)
            return "-="
        elseif c == 62 then -- >
            next_char(ls)
            return "->"
        else return "-" end
    end,
    [61] = function(ls) -- =
        local c = next_char(ls)
        if c ~= 61 then return "="
        else next_char(ls); return "==" end
    end,
    [60] = function(ls) -- <
        local c = next_char(ls)
        if c == 60 then
            c = next_char(ls)
            if c ~= 61 then return "<<"
            else next_char(ls); return "<<=" end
        elseif c == 61 then next_char(ls); return "<="
        else return "<" end
    end,
    [62] = function(ls) -- >
        local c = next_char(ls)
        if c == 62 then
            c = next_char(ls)
            if c == 62 then
                c = next_char(ls)
                if c ~= 61 then return ">>>"
                else next_char(ls); return ">>>=" end
            elseif c == 61 then
                next_char(ls)
                return ">>="
            else
                return ">>"
            end
        elseif c == 61 then next_char(ls); return ">="
        else return ">" end
    end,
    [126] = function(ls) -- ~
        local c = next_char(ls)
        if c ~= 61 then return "~"
        else next_char(ls); return "~=" end
    end,
    [33] = function(ls) -- !
        local c = next_char(ls)
        if c ~= 61 then return "!"
        else next_char(ls); return "!=" end
    end,
    [94] = function(ls) -- ^
        local c = next_char(ls)
        if c ~= 64 then return "^"
        else next_char(ls); return "^=" end
    end,
    [123] = function(ls) -- {
        local c = next_char(ls)
        if c ~= 58 then return "{" -- :
        else next_char(ls); return "{:" end
    end,
    [37] = function(ls) -- %
        local c = next_char(ls)
        if c ~= 61 then return "%"
        else next_char(ls); return "%=" end
    end,
    [38] = function(ls) -- &
        local c = next_char(ls)
        if c ~= 61 then return "&"
        else next_char(ls); return "&=" end
    end,
    [42] = function(ls) -- *
        local c = next_char(ls)
        if c == 61 then
            next_char(ls)
            return "*="
        elseif c == 42 then
            c = next_char(ls)
            if c ~= 61 then return "**"
            else next_char(ls); return "**=" end
        else
            return "*"
        end
    end,
    [43] = function(ls) -- +
        local c = next_char(ls)
        if c ~= 61 then return "+"
        else next_char(ls); return "+=" end
    end,
    [47] = function(ls) -- /
        local c = next_char(ls)
        if c == 61 then
            next_char(ls)
            return "/="
        elseif c == 47 then
            while ls.current and not is_newline(ls.current) do
                next_char(ls)
            end
        elseif c == 42 then -- *
            next_char(ls)
            read_comment(ls)
        else
            return "/"
        end
    end,
    [124] = function(ls) -- |
        local c = next_char(ls)
        if c ~= 61 then return "|"
        else next_char(ls); return "|=" end
    end,
    [58] = function(ls) -- :
        local c = next_char(ls)
        if     c == 125 then next_char(ls); return ":}" -- }
        elseif c == 58 then next_char(ls); return "::"
        else return ":" end
    end,
    [34] = function(ls, tok) -- "
        read_string(ls, tok, false)
        return "<string>"
    end,
    [46] = function(ls, tok) -- .
        local c = next_char(ls)
        if c == 46 then
            c = next_char(ls)
            if c == 46 then
                next_char(ls)
                return "..."
            elseif c == 61 then -- =
                next_char(ls)
                return "..="
            else
                return ".."
            end
        elseif not is_digit(c) then
            return "."
        end
        read_number(ls, tok, { "." })
        return "<number>"
    end,
    [48] = function(ls, tok) -- 0
        read_number(ls, tok, {}, true)
        return "<number>"
    end,
    [64] = function(ls, tok) -- @
        local c = next_char(ls)
        if c == 91 then -- [
            next_char(ls)
            return "@["
        end
        return "@"
    end
}
lextbl[13] = lextbl[10] -- CR, LF
lextbl[12] = lextbl[32] -- \f, space
lextbl[9 ] = lextbl[32] -- \t
lextbl[11] = lextbl[32] -- \v
lextbl[39] = lextbl[34] -- ', "
lextbl[49] = lextbl[48] -- 1, 0
lextbl[50] = lextbl[48] -- 2
lextbl[51] = lextbl[48] -- 3
lextbl[52] = lextbl[48] -- 4
lextbl[53] = lextbl[48] -- 5
lextbl[54] = lextbl[48] -- 6
lextbl[55] = lextbl[48] -- 7
lextbl[56] = lextbl[48] -- 8
lextbl[57] = lextbl[48] -- 9

local lex_default = function(ls, tok)
    local c = ls.current
    local saved_c
    if c == 82 or c == 114 then -- R, r
        saved_c = c
        c = next_char(ls)
        if c == 34 or c == 39 then -- ", '
            read_string(ls, tok, true)
            return "<string>"
        end
    end
    if c == 95 or is_alpha(c) or (saved_c and is_digit(c)) then -- _
        local buf = { bytemap[saved_c] }
        repeat
            buf[#buf + 1] = bytemap[c]
            c = next_char(ls)
            if not c then break end
        until not (c == 95 or is_alnum(c))
        local str = tconc(buf)
        if Keywords[str] then
            return str
        elseif str:sub(1, 5) == "__rt_" then
            lex_error(ls, "invalid identifier (__rt_ prefix is reserved)", str)
        else
            tok.value = str
            return "<name>"
        end
    elseif saved_c then
        tok.value = bytemap[saved_c]
        return "<name>"
    else
        local c = bytemap[ls.current]
        next_char(ls)
        return c
    end
end

local lex = function(ls, tok)
    while true do
        local c = ls.current
        if c == nil then return "<eof>" end
        local opt = lextbl[c]
        local v
        if opt then v = opt(ls, tok)
        else        v = lex_default(ls, tok) end
        if v then return v end
    end
end

local State_MT = {
    __index = {
        get = function(ls)
            ls.last_line = ls.line_number

            local tok, lah = ls.token, ls.ltoken
            if lah.name then
                local ql = ls.queued_line
                if ql then ls.line_number = ls.line_number + ql end
                tok.name, tok.value = lah.name, lah.value
                lah.name, lah.value = nil, nil
            else
                tok.value = nil
                tok.name = lex(ls, tok)
            end
            return tok.name
        end,

        lookahead = function(ls)
            ls.queue_line = true
            local lah = ls.ltoken
            assert(not lah.name)
            local name = lex(ls, lah)
            ls.queue_line = false
            local ql = ls.queued_line
            if ql then ls.line_number = ls.line_number - ql end
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
    if c == 35 then -- #
        repeat
            c = rdr()
        until not c or is_newline(c)
        local e = c
        c = rdr()
        if (e == 10 and c == 13) or (e == 13 and c == 10) then -- LF, CR
            c = rdr()
        end
    end
    return c
end

local init = function(chunkname, input)
    local reader  = type(input) == "string" and strstream(input) or input
    local current = skip_shebang(reader)
    return setmetatable({
        reader      = reader,
        token       = { name = nil, value = nil },
        ltoken      = { name = nil, value = nil },
        source      = chname_to_source(chunkname),
        current     = current,
        line_number = 1,
        last_line   = 1
    }, State_MT)
end

return {
    init = init,
    syntax_error = syntax_error,
    is_keyword = function(kw)
        return Keywords[kw] ~= nil
    end
}
