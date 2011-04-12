-- Things for default.cfg, meant to be executed on every start for some bindings etc. to work.

-- universal scrollwheel + modifier commands:

defaultmodifier = 0
modifier = defaultmodifier

function domodifier(m)
    modifier = m
    cc.console.onrelease("modifier = defaultmodifier")
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
        cc.blend.brush.scroll(a)
    else
        cc.world.editfacewentpush(a, 1)
    end
end

multiplier = 1
multiplier2 = 1

function delta_edit_1(a) gridpower = gridpower + a end
function delta_edit_2(a) cc.world.editfacewentpush(a, 0) end
function delta_edit_3(a) cc.world.editfacewentpush(a, 2) end
function delta_edit_4(a) cc.world.editrotate(a) end
function delta_edit_5(a) cc.world.entsetattr(0, a) end
function delta_edit_6(a) cc.texture.edit(a) end
function delta_edit_9(a) cc.world.hmap.brush.select(a) end
function delta_edit_10(a) cc.world.entautoview(a) end

function delta_edit_11(a) cc.world.entsetattr(0, multiplier * a) end
function delta_edit_12(a) cc.world.entsetattr(1, multiplier * a) end
function delta_edit_13(a) cc.world.entsetattr(2, multiplier * a) end
function delta_edit_14(a) cc.world.entsetattr(3, multiplier * a) end

function delta_edit_15(a) cc.world.vdelta([[cc.world.voffset(%(1)i * %(2)i, 0)]] % { a, multiplier2 }) end
function delta_edit_16(a) cc.world.vdelta([[cc.world.voffset(0, %(1)i * %(2)i)]] % { a, multiplier2 }) end
function delta_edit_17(a) cc.world.vdelta([[cc.world.vrotate(%(1)i)]] % { a }) end
function delta_edit_18(a) cc.world.vdelta([[cc.world.vscale(%(1)i < 0 and 0.5 or 2)]] % { a }) end

function delta_game_0(a) cc.camera[a == 1 and "camdec" or "caminc"]() end
