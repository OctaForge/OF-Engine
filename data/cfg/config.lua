-- Things for default.cfg, meant to be executed on every start for some bindings etc. to work.

-- universal scrollwheel + modifier commands:

defaultmodifier = 0
modifier = defaultmodifier

function domodifier(m)
    modifier = m
    console.onrelease(function() modifier = defaultmodifier end)
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
        world.editfacewentpush(a, 1)
    end
end

multiplier = 1
multiplier2 = 16

function delta_edit_1(a) gridpower = gridpower + a end
function delta_edit_2(a) world.editfacewentpush(a, 0) end
function delta_edit_3(a) world.editfacewentpush(a, 2) end
function delta_edit_4(a) world.editrotate(a) end
function delta_edit_5(a) world.entsetattr(0, a) end
function delta_edit_6(a) texture.edit(a) end
function delta_edit_9(a) world.hmap.brush.select(a) end
function delta_edit_10(a) world.entautoview(a) end

function delta_edit_11(a) world.entsetattr(0, multiplier * a) end
function delta_edit_12(a) world.entsetattr(1, multiplier * a) end
function delta_edit_13(a) world.entsetattr(2, multiplier * a) end
function delta_edit_14(a) world.entsetattr(3, multiplier * a) end

function delta_edit_15(a) world.vdelta([[world.voffset(%(1)i * %(2)i, 0)]] % { a, multiplier2 }) end
function delta_edit_16(a) world.vdelta([[world.voffset(0, %(1)i * %(2)i)]] % { a, multiplier2 }) end
function delta_edit_17(a) world.vdelta([[world.vrotate(%(1)i)]] % { a }) end
function delta_edit_18(a) world.vdelta([[world.vscale(%(1)i < 0 and 0.5 or 2)]] % { a }) end

function delta_game_0(a) camera[a == 1 and "zoom_out" or "zoom_in"]() end

function set(k, v) _G[tostring(k)] = v end
