-- Things for default.cfg, meant to be executed on every start for some bindings etc. to work.

-- universal scrollwheel + modifier commands:

defaultmodifier = 0
modifier = defaultmodifier

function domodifier(m)
    modifier = m
    input.on_release(function() modifier = defaultmodifier end)
end

function universaldelta(n)
    if EV.editing ~= 0 then
        _G["delta_edit_" .. modifier](n)
    else
        _G["delta_game_" .. modifier](n)
    end
end

function delta_edit_0(a)
    if EV.blendpaintmode ~= 0 then
        texture.scroll_blend_brush(a)
    else
        edit.push(a, edit.PUSH_CUBE)
    end
end

multiplier = 1
multiplier2 = 16

function delta_edit_1(a) EV.gridpower = EV.gridpower + a end
function delta_edit_2(a) edit.push(a, edit.PUSH_FACE) end
function delta_edit_3(a) edit.push(a, edit.PUSH_CORNER) end
function delta_edit_4(a) edit.rotate(a) end
function delta_edit_5(a) texture.scroll_slots(a) end
function delta_edit_6(a) edit.select_height_brush(a) end
function delta_edit_7(a) camera.center_on_entity(a) end

function delta_edit_8(a)
    vslot.delta(function()
        vslot.offset(a * multiplier2, 0)
    end)
end

function delta_edit_9(a)
    vslot.delta(function()
        vslot.offset(0, a * multiplier2)
    end)
end
function delta_edit_10(a)
    vslot.delta(function()
        vslot.rotate(a)
    end)
end

function delta_edit_11(a)
    vslot.delta(function()
        vslot.scale(a < 0 and 0.5 or 2)
    end)
end

function delta_game_0(a)
    camera[a == 1 and "zoom_out" or "zoom_in"]()
end

function set(k, v) _G[k] = v end

-- aliases

local rotate = function(ch)
    local n = string.byte(ch)
    if (n >= 65 and n <= 90) then
        n = n + 13
        n = n > 90 and n - 26 or n
    elseif (n >= 97 and n <= 122) then
        n = n + 13
        n = n > 122 and n - 26 or n
    end
    return string.char(n)
end

local rot
rot = function(lst)
    if not lst then return nil end

    if lisp.is_symbol(lst[1]) or lisp.is_op(lst[1]) then
        lst[1].name = lst[1].name:gsub(".", function(ch) return rotate(ch) end)
    elseif type(lst[1]) == "string" then
        lst[1] = lst[1]:gsub(".", function(ch) return rotate(ch) end)
    elseif lisp.is_list(lst[1]) then
        rot(lst[1])
    end

    rot(lst[2])
end

lisp.register_op("sshot", function(str)
    return "engine.screenshot \"" .. tostring(str) .. "\""
end)

lisp.register_func("eval13", function(lst)
    rot(lst)
    return setfenv(loadstring("return " .. lisp.to_lua(lst),
        tostring(lst)), Env)()
end)
