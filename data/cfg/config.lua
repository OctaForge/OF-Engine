-- Things for default.cfg, meant to be executed on every start for some bindings etc. to work.

-- universal scrollwheel + modifier commands:

defaultmodifier = 0
modifier = defaultmodifier

function domodifier(m)
    modifier = m
    input.on_release(function() modifier = defaultmodifier end)
end

function universaldelta(n)
    if editing ~= 0 then
        _G["delta_edit_" .. modifier](n)
    else
        _G["delta_game_" .. modifier](n)
    end
end

function delta_edit_0(a)
    if blendpaintmode ~= 0 then
        texture.blendbrush.scroll(a)
    else
        edit.push(a, edit.PUSH_CUBE)
    end
end

multiplier = 1
multiplier2 = 16

function delta_edit_1(a) gridpower = gridpower + a end
function delta_edit_2(a) edit.push(a, edit.PUSH_FACE) end
function delta_edit_3(a) edit.push(a, edit.PUSH_CORNER) end
function delta_edit_4(a) edit.rotate(a) end
function delta_edit_5(a) texture.edit(a) end
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
