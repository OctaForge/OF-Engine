--[[! File: library/core/std/lua/json.lua

    About: Author
        Craig Mason-Jones, reformatted / modified by q66 <quaker66@gmail.com>.

    About: Copyright
        Copyright (c) 2010 Craig Mason-Jones

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua JSON support. Fast JSON encoder and decoder for general usage.
]]

--[[! Variable: Simplifiers
    Stores JSON simplifiers. It's basically an array of tables. The tables are
    arrays as well, with two elements, first one being a function that accepts
    a value and returns true if the value should be simplified and second one
    being a function that accepts a value and returns a simplified one.

    Useful if you want to save something big, but you don't need to encode it
    all in a raw way. For example, instead of full entities, simplify them to
    their unique IDs.
]]
local Simplifiers = {}

-- private functions
local isencodable
local isarr
local strenc
local isencodable
local encode
local decode
local register
local null

--[[! Function: encode
    Encodes a Lua object / variable and returns it as JSON string.
]]
encode = function(v)
    -- Handle nil values
    if not v then return "null" end
    local enc = v

    -- OctaForge - make use of register storage
    for i = 1, #Simplifiers do
        if Simplifiers[i][1](enc) then
            enc = Simplifiers[i][2](enc)
        end
    end

    local vtype = type(enc)

    if vtype == "string" then
        -- Need to handle encoding in string
        return '"' .. strenc(enc) .. '"'
    elseif vtype == "number" or vtype == "boolean" then
        return tostring(enc)
    elseif vtype == "table" then
        local r = {}
        local barray, maxc = isarr(enc)
        if barray then
            for i = 1, maxc do
                table.insert(r, encode(enc[i]))
            end
        else -- An object, not an array
            for i, j in pairs(enc) do
                -- do not even attempt otherwise
                if not (
                    type(i) == "string" and string.sub(i, 1, 2) == "__"
                ) then
                    if isencodable(i) and isencodable(j) then
                        table.insert(r, '"' .. strenc(i) .. '":' .. encode(j))
                    end
                end
            end
        end
        if barray then
            return "[" .. table.concat(r, ",") .."]"
        else
            return "{" .. table.concat(r, ",") .. "}"
        end
    end

    return "null"
end

--[[! Function: register
    Registers a simplifier, see <Simplifiers>. Takes the checker function and
    a simplifier function.
]]
register = function(check, simplifier)
    table.insert(Simplifiers, { check, simplifier })
end

--[[! Function: decode
    Decodes a JSON string and returns the value as a Lua type, mostly a table.
]]
decode = function(s)
    -- Function is re-defined below after token and other items are created.
    -- Just defined here for code neatness.
    return null
end

--[[! Function: null
    The null function allows one to specify a null value in an associative
    array (which is otherwise discarded if you set the value with "nil"
    in Lua).

    Simply set:
        (start code)
            t = { first = JSON.null }
        (end)
]]
null = function()
    return null -- so JSON.null() will also return null ;-)
end

local qrep = {["\\"]="\\\\", ['"']='\\"',['\n']='\\n',['\t']='\\t'}

strenc = function(s)
    return tostring(s):gsub('["\\\n\t]',qrep)
end

isarr = function(t)
    -- Next we count all the elements, ensuring that any non-indexed
    -- elements are not-encodable  (with the possible exception of 'n')
    local midx = 0
    for k, v in pairs(t) do
        -- k,v is an indexed pair
        if type(k) == "number" and math.floor(k) == k and 1 <= k then
            -- All array elements must be encodable
            if not isencodable(v) then return false end
            midx = math.max(midx,k)
        else
            if k == "n" then
                -- False if n does not hold the number of elements
                if v ~= table.getn(t) then return false end
            else -- Else of (k=='n')
                if isencodable(v) then return false end
            end    -- End of (k~='n')
        end -- End of k,v not an indexed pair
    end    -- End of loop across all pairs
    return true, midx
end

isencodable = function(o)
    local t = type(o)
    return (
        t == "string"
        or t == "boolean"
        or t == "number"
        or t == "nil"
        or t == "table"
    ) or (
        t == "function"
        and o == null
    )
end

-- Radical performance improvement for decode from Eike Decker!
do
    -- initialize some values to be used in decoding function
    
    -- initializes a table to contain a byte=>table mapping
    -- the table contains tokens (byte values) as keys and maps them on other
    -- token tables (mostly, the boolean value 'true' is used to indicate
    -- termination of a token sequence)
    -- the token table's purpose is, that it allows scanning a sequence of
    -- bytes until something interesting has been found (e.g. a token that
    -- is not expected)
    -- name is a descriptor for the table to be printed in error messages
    local function init_token_table (tt)
        local struct = {}
        local value
        struct.link = function(self, other_tt)
            value = other_tt
            return struct
        end
        struct.to = function(self, chars)
            for i=1,#chars do 
                tt[chars:byte(i)] = value
            end
            return struct
        end
        return function(name)
            tt.name = name
            return struct
        end
    end
    
    -- keep "named" byte values at hands
    local 
        c_esc,
        c_e,
        c_l,
        c_r,
        c_u,
        c_f,
        c_a,
        c_s,
        c_slash = ("\\elrufas/"):byte(1,9)
    
    -- token tables - tt_doublequote_string = strDoubleQuot,
    -- tt_singlequote_string = strSingleQuot
    local 
        tt_object_key,
        tt_object_colon,
        tt_object_value,
        tt_doublequote_string,
        tt_singlequote_string,
        tt_array_value,
        tt_array_seperator,
        tt_numeric,
        tt_boolean,
        tt_null,
        tt_comment_start,
        tt_comment_middle,
        tt_ignore --< tt_ignore is special - marked tokens will be tt_ignored
            = {},{},{},{},{},{},{},{},{},{},{},{},{}
    
    -- strings to be used in certain token tables
    local strchars = "" -- all valid string characters (all except newlines)
    local allchars = "" -- all characters that are valid in comments
    --local escapechar = {}
    for i=0,0xff do 
        local c = string.char(i)
        if c~="\n" and c~="\r" then strchars = strchars .. c end
        allchars = allchars .. c
        --escapechar[i] = "\\" .. string.char(i)
    end
    
--[[    
    charstounescape = "\"\'\\bfnrt/";
    unescapechars = "\"'\\\b\f\n\r\t\/";
    for i=1,#charstounescape do
        escapechar[ charstounescape:byte(i) ] = unescapechars:sub(i,i)
    end
]]--

    -- obj key reader, expects the end of the object or a quoted string as key
    init_token_table (tt_object_key) "object (' or \" or } or , expected)" 
        :link(tt_singlequote_string) :to "'"
        :link(tt_doublequote_string) :to '"'
        :link(true)                                    :to "}"
        :link(tt_object_key)                 :to ","
        :link(tt_comment_start)            :to "/"
        :link(tt_ignore)                         :to " \t\r\n"
    
    
    -- after the key, a colon is expected (or comment)
    init_token_table (tt_object_colon) "object (: expected)" 
        :link(tt_object_value)             :to ":"    
        :link(tt_comment_start)            :to "/" 
        :link(tt_ignore)                         :to" \t\r\n"
        
    -- as values, anything is possible, numbers,
    -- arrays, objects, boolean, null, strings
    init_token_table (tt_object_value)
    "object ({ or [ or ' or \" or number or boolean or null expected)"
        :link(tt_object_key)                 :to "{" 
        :link(tt_array_seperator)        :to "[" 
        :link(tt_singlequote_string) :to "'" 
        :link(tt_doublequote_string) :to '"' 
        :link(tt_numeric)                        :to "0123456789.-" 
        :link(tt_boolean)                        :to "tf" 
        :link(tt_null)                             :to "n" 
        :link(tt_comment_start)            :to "/" 
        :link(tt_ignore)                         :to " \t\r\n"
        
    -- token tables for reading strings
    init_token_table (tt_doublequote_string) "double quoted string"
        :link(tt_ignore)                         :to (strchars)
        :link(c_esc)                                 :to "\\"
        :link(true)                                    :to '"'
        
    init_token_table (tt_singlequote_string) "single quoted string"
        :link(tt_ignore)                         :to (strchars)
        :link(c_esc)                                 :to "\\" 
        :link(true)                                    :to "'"
        
    -- array reader that expects termination of the
    -- array or a comma that indicates the next value
    init_token_table (tt_array_value) "array (, or ] expected)"
        :link(tt_array_seperator)        :to "," 
        :link(true)                                    :to "]"
        :link(tt_comment_start)            :to "/" 
        :link(tt_ignore)                         :to " \t\r\n"
    
    -- a value, pretty similar to tt_object_value
    init_token_table (tt_array_seperator)
    "array ({ or [ or ' or \" or number or boolean or null expected)"
        :link(tt_object_key)                 :to "{" 
        :link(tt_array_seperator)        :to "[" 
        :link(tt_singlequote_string) :to "'" 
        :link(tt_doublequote_string) :to '"'    
        :link(tt_comment_start)            :to "/" 
        :link(tt_numeric)                        :to "0123456789.-" 
        :link(tt_boolean)                        :to "tf" 
        :link(tt_null)                             :to "n" 
        :link(tt_ignore)                         :to " \t\r\n"
    
    -- valid number tokens
    init_token_table (tt_numeric) "number"
        :link(tt_ignore)                         :to "0123456789.-Ee"
        
    -- once a comment has been started with /, a * is expected
    init_token_table (tt_comment_start) "comment start (* expected)"
        :link(tt_comment_middle)         :to "*"
        
    -- now everything is allowed, watch out for * though.
    -- The next char is then checked manually
    init_token_table (tt_comment_middle) "comment end"
        :link(tt_ignore)                         :to (allchars)
        :link(true)                                    :to "*"
        
    decode = function(js_string)
        local pos = 1 -- position in the string
        
        -- read the next byte value
        local next_byte = function()
            pos = pos + 1
            return js_string:byte(pos-1)
        end
        
        -- in case of error, report the location using line numbers
        local location = function() 
            local n = ("\n"):byte()
            local line,lpos = 1,0
            for i=1,pos do 
                if js_string:byte(i) == n then
                    line,lpos = line + 1,1
                else
                    lpos = lpos + 1
                end
            end
            return "Line "..line.." character "..lpos
        end
        
        -- debug func
        --local function status (str)
        --    print(str.." ("..s:sub(math.max(1,p-10),p+10)..")")
        --end
        
        -- read the next token, according to the passed token table
        local next_token = function(tok)
            while pos <= #js_string do
                local b = js_string:byte(pos) 
                local t = tok[b]
                if not t then 
                    error("Unexpected character at "..location()..": "..
                        string.char(b).." ("..b..") when reading "
                        ..tok.name.."\nContext: \n"..
                        js_string:sub(math.max(1,pos-30),pos+30)
                        .."\n"..(" "):rep(pos+math.min(-1,30-pos)).."^")
                end
                pos = pos + 1
                if t~=tt_ignore then return t end
            end
            error(
                "unexpected termination of JSON while looking for "..tok.name
            )
        end
        
        -- read a string, double and single quoted ones
        local read_string = function(tok)
            local start = pos
            --local returnString = {}
            repeat
                local t = next_token(tok)
                if t == c_esc then 
                --table.insert(returnString, js_string:sub(start, pos-2))
                --table.insert(returnString, escapechar[js_string:byte(pos)])
                    pos = pos + 1
                    --start = pos
                end -- jump over escaped chars, no matter what
            until t == true
            return (loadstring("return " .. js_string:sub(start-1, pos-1) ) ())

            -- We consider the situation where no
            -- escaped chars were encountered separately,
            -- and use the fastest possible return in this case.
            
            --if 0 == #returnString then
            --    return js_string:sub(start,pos-2)
            --else
            --    table.insert(returnString, js_string:sub(start,pos-2))
            --    return table.concat(returnString,"");
            --end
            --return js_string:sub(start,pos-2)
        end
        
        local read_num = function()
            local start = pos
            while pos <= #js_string do
                local b = js_string:byte(pos)
                if not tt_numeric[b] then break end
                pos = pos + 1
            end
            return tonumber(js_string:sub(start-1,pos-1))
        end
        
        -- read_bool and read_null are both making an assumption that
        -- I have not tested: I would expect that the string extraction
        -- is more expensive than actually  making manual comparision
        -- of the byte values
        local read_bool = function() 
            pos = pos + 3
            local a,b,c,d = js_string:byte(pos-3,pos)
            if a == c_r and b == c_u and c == c_e then return true end
            pos = pos + 1
            if a ~= c_a or b ~= c_l or c ~= c_s or d ~= c_e then 
                error(
                    "Invalid boolean: "..js_string:sub(math.max(1,pos-5),pos+5)
                ) 
            end
            return false
        end
        
        -- same as read_bool: only last 
        local read_null = function()
            pos = pos + 3
            local u,l1,l2 = js_string:byte(pos-3,pos-1)
            if u == c_u and l1 == c_l and l2 == c_l then return nil end
            error("Invalid value (expected null):"
                ..js_string:sub(pos-4,pos-1)..
                " ("..js_string:byte(pos-1).."="
                ..js_string:sub(pos-1,pos-1).." / "..c_l..")"
            )
        end
        
        local read_object_value,read_object_key
        local read_array,read_value,read_comment
    
        -- read a value depending on what token was returned,
        -- might require info what was used (in case of comments)
        read_value = function(t,fromt)
            if t == tt_object_key         then return read_object_key({}) end
            if t == tt_array_seperator    then return read_array({}) end
            if t == tt_singlequote_string or 
               t == tt_doublequote_string then return read_string(t) end
            if t == tt_numeric            then return read_num() end
            if t == tt_boolean            then return read_bool() end    
            if t == tt_null               then return read_null() end
            if t == tt_comment_start      then
                return read_value(read_comment(fromt))
            end
            error(
                "unexpected termination - "
                ..js_string:sub(math.max(1,pos-10),pos+10)
            )
        end
        
        -- read comments until something noncomment like surfaces,
        -- using the token reader which was 
        -- used when stumbling over this comment
        read_comment = function(fromt)
            while true do
                next_token(tt_comment_start)
                while true do
                    local t = next_token(tt_comment_middle)
                    if next_byte() == c_slash then
                        local t = next_token(fromt)
                        if t~= tt_comment_start then return t end
                        break
                    end
                end
            end
        end
        
        -- read arrays, empty array expected as o arg
        read_array = function(o,i)
            --if not i then status "arr open" end
            i = i or 1
            -- loop until ...
            while true do
                o[i] = read_value(
                    next_token(tt_array_seperator),tt_array_seperator
                )
                local t = next_token(tt_array_value)
                if t == tt_comment_start then
                    t = read_comment(tt_array_value)
                end
                if t == true then    -- ... we found a terminator token
                    --status "arr close"
                    return o 
                end
                i = i + 1            
            end
        end
        
        -- object value reading
        read_object_value = function(o)
            local t = next_token(tt_object_value)
            return read_value(t,tt_object_value)
        end
        
        -- object key reading, might also terminate the object
        read_object_key = function(o)
            while true do
                local t = next_token(tt_object_key)
                if t == tt_comment_start then
                    t = read_comment(tt_object_key)
                end
                if t == true then return o end
                if t == tt_object_key then return read_object_key(o) end
                local k = read_string(t)
                
                if next_token(tt_object_colon) == tt_comment_start then
                    t = read_comment(tt_object_colon)
                end
                
                local v = read_object_value(o)
                o[k] = v
            end
        end
        
        -- now let's read data from our string and pretend it's an object value
        local r = read_object_value()
        if pos <= #js_string then
            -- not sure about what to do with dangling characters
            --error("Dangling characters in JSON code ("..location()..")")
        end
        
        return r
    end
end

return
{
    encode   = encode,
    decode   = decode,
    register = register,
    null     = null
}
