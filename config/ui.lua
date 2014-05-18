local capi = require("capi")
local signal = require("core.events.signal")
local gui = require("core.gui.core")
local cs = require("core.engine.cubescript")

local abs = math.abs

local connect = signal.connect

local world = gui.get_world()

local var_get = cs.var_get
local cs_execute = cs.execute

local gen_map_list = |img, vb| do
    local glob, loc = capi.get_all_map_names()
    vb:append(gui.Label { text = "Global maps", color = 0x88FF88 })
    local current_preview
    for i = 1, #glob do
        local map = glob[i]
        vb:append(gui.Button { label = glob[i], clamp_h = true,
            variant = "nobg", min_w = 0.2
        }, |btn| do
            signal.connect(btn, "hovering", || do
                if map != current_preview then
                    current_preview = map
                    img:set_tex("media/map/" .. map .. "/map")
                end
            end)
            signal.connect(btn, "leaving", || do
                current_preview = nil
                img:set_tex(nil)
            end)
            signal.connect(btn, "clicked", || do
                cs_execute("map " .. map)
            end)
        end)
    end
    vb:append(gui.Label { text = "Local maps", color = 0x8888FF })
    for i = 1, #loc do
        local map = loc[i]
        vb:append(gui.Button { label = loc[i], clamp_h = true,
            variant = "nobg", min_w = 0.2
        }, |btn| do
            signal.connect(btn, "hovering", || do
                if map != current_preview then
                    current_preview = map
                    img:set_tex("media/map/" .. map .. "/map")
                end
            end)
            signal.connect(btn, "leaving", || do
                current_preview = nil
                img:set_tex(nil)
            end)
            signal.connect(btn, "clicked", || do
                cs_execute("map " .. map)
            end)
        end)
    end
end

local gen_map_load = || do
    local s
    return gui.H_Box {
        gui.Outline { __init = |o| do
            o:append(gui.Spacer { pad_h = 0.005, pad_v = 0.005 }, |sp| do
                sp:append(gui.Scroller { clip_w = 0.6, clip_h = 0.5 }, |sc| do
                    s = sc
                    sc:append(gui.H_Box { padding = 0.01 }, |hb| do
                        local im
                        hb:append(gui.Spacer { pad_h = 0.02, pad_v = 0.02,
                            gui.Image { min_w = 0.3, min_h = 0.3,
                                __init = |img| do im = img end,
                                gui.Outline { clamp = true, color = 0x303030 }
                            }
                        })
                        hb:append(gui.V_Box(), |vb| do
                            gen_map_list(im, vb)
                        end)
                    end)
                end)
            end)
        end, color = 0x303030 },
        gui.V_Scrollbar { clamp_v = true, __init = |sb| do
            sb:append(gui.Scroll_Button())
            sb:bind_scroller(s)
        end }
    }
end

world:new_window("main", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("Main menu")
    win:append(gui.H_Box { clamp_h = true }, |b| do
        local stat
        b:append(gui.V_Box(), |b| do
            b:append(gui.Button { label = "Load map", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do stat:set_state("load_map") end)
            end)
            b:append(gui.Button { label = "Options", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do stat:set_state("options") end)
            end)
            b:append(gui.Button { label = "Credits", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do stat:set_state("credits") end)
            end)
            b:append(gui.Button { label = "Quit", clamp_h = true,
                variant = "nobg"
            }, |btn| do
                connect(btn, "clicked", || do cs_execute("quit") end)
            end)
        end)
        b:append(gui.Filler { min_w = 0.005, clamp_v = true })
        b:append(gui.State { state = "default" }, |st| do
            stat = st
            st:update_state("default", gui.Outline { min_w = 0.6, min_h = 0.5,
                color = 0x303030, gui.V_Box {
                    gui.Label { text = "Welcome to OctaForge!", scale = 1.5,
                        color = 0x88FF88
                    },
                    gui.Label { text = "Please start by clicking one of the "
                        .. "menu items." }
                }
            })
            st:update_state("load_map", gen_map_load())
            st:update_state("options", gui.Outline { min_w = 0.6, min_h = 0.5,
                color = 0x303030, gui.V_Box {
                    gui.Label { text = "Coming soon", scale = 1.5,
                        color = 0x88FF88 },
                    gui.Label { text = "No options for now :)" }
                }
            })
            st:update_state("credits", gui.Outline { min_w = 0.6, min_h = 0.5,
                color = 0x303030, gui.V_Box {
                    gui.Label { text = "OctaForge is brought to you by:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Daniel \f1"q66"\f7 Kolesa' },
                    gui.Label { text = "project leader and main programmer",
                        scale = 0.8 },
                    gui.Filler { min_h = 0.008, clamp_h = true },
                    gui.Label { text = 'Lee \f1"eihrul"\f7 Salzman' },
                    gui.Label { text = 'David \f1"dkreuter"\f7 Kreuter' },
                    gui.Label { text = 'Dale \f1"graphitemaster"\f7 Weiler' },
                    gui.Label { text = "code contributors", scale = 0.8 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = "Based on Tesseract created by:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Lee \f1"eihrul"\f7 Salzman' },
                    gui.Label { text = "and others",  scale = 0.8 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = "And Syntensity created by:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Alon \f1"kripken"\f7 Zakai' },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = "The original Cube 2 engine:",
                        color = 0x88FF88 },
                    gui.Filler { min_h = 0.01, clamp_h = true },
                    gui.Label { text = 'Wouter \f1"aardappel"\f7 van '
                        ..'Oortmerssen' },
                    gui.Label { text = 'Lee \f1"eihrul"\f7 Salzman' },
                    gui.Label { text = "and others",  scale = 0.8 },
                }
            })
        end)
    end)
end)

world:new_window("fullconsole", gui.Overlay, |win| do
    win:clamp(true, true, false, false)
    win:align(0, -1)
    capi.console_full_show(true)
    connect(win, "destroy", || capi.console_full_show(false))
    win:append(gui.Console {
        min_h = || var_get("fullconsize") / 100
    }, |con| do
        con:clamp(true, true, false, false)
    end)
end)

world:new_window("editstats", gui.Overlay, |win| do
    win:align(-1, 1)
    win:set_above_hud(true)
    win:append(gui.Filler { variant = "edithud" }, |fl| do
        fl:append(gui.Spacer { pad_h = 0.015, pad_v = 0.01 }, |sp| do
            sp:append(gui.Eval_Label { scale = -1,
                func = || cs_execute("getedithud") }):align(-1, 0)
        end)
    end)
end)

local genblock = |val, color, tcolor| || gui.Color_Filler {
    color = color, min_w = 0.18, min_h = 0.18,
    gui.Label {
        text = tostring(val), scale = 3.5, color = tcolor
    }
}

local blocktypes = {
    [0] = || gui.Color_Filler {
        color = 0xccc0b3, min_w = 0.18, min_h = 0.18
    },
    [2   ] = genblock(2,    0xEEE4DA, 0x776E65),
    [4   ] = genblock(4,    0xEDE0C8, 0x776E65),
    [8   ] = genblock(8,    0xF2B179, 0xF9F6F2),
    [16  ] = genblock(16,   0xF59563, 0xF9F6F2),
    [32  ] = genblock(32,   0xF67C5F, 0xF9F6F2),
    [64  ] = genblock(64,   0xF65E3B, 0xF9F6F2),
    [128 ] = genblock(128,  0xEDCF72, 0xF9F6F2),
    [256 ] = genblock(256,  0xEDCC61, 0xF9F6F2),
    [512 ] = genblock(512,  0xEDC850, 0xF9F6F2),
    [1024] = genblock(1024, 0xEDC53F, 0xF9F6F2),
    [2048] = genblock(2048, 0xEDC22E, 0xF9F6F2),
    [4096] = genblock(4096, 0x3C3A32, 0xF9F6F2)
}

local tiles   = {}
local cleanup = {}

local totalscore = 0
local gamestate  = 0

local cleanuptiles = || do
    for i, v in ipairs(cleanup) do cleanup[i]:destroy() end
end

local seedtiles = || do
    local t1, t2 = math.random(1, 16)
    repeat t2 = math.random(1, 16) until t2 != t1
    local vals = { 2, 4 }
    local tv1, tv2 = vals[math.random(1, 2)],
                     vals[math.random(1, 2)]
    for i = 1, 16 do
        if i == t1 then
            tiles[i] = tv1
        elseif i == t2 then
            tiles[i] = tv2
        else
            tiles[i] = 0
        end
    end
end

local randtile = |grid| do
    local emptyfields = {}
    for i = 1, 16 do
        if tiles[i] == 0 then emptyfields[#emptyfields + 1] = i end
    end
    if #emptyfields == 0 then return end
    local n = emptyfields[math.random(1, #emptyfields)]
    tiles[n] = ({ 2, 4 })[math.random(1, 2)]
    grid:remove(n)
    grid:insert(n, blocktypes[tiles[n]]())
    if #emptyfields == 1 then
        -- check game over (yes if nothing is mergeable)
        if gamestate == 0 then
            gamestate = -1
            for a = 1, 2 do
                local ia, ib, ic, ja, jb, jc
                if a == 1 then
                    ia, ib, ic = 0, 12, 4
                    ja, jb, jc = 1, 3, 1
                else
                    ia, ib, ic = 0, 3, 1
                    ja, jb, jc = 1, 13, 4
                end
                for i = ia, ib, ic do
                    for j = ja + i, jb + i, jc do
                        if tiles[j] == tiles[j + jc] then
                            gamestate = 0
                            break
                        end
                    end
                    if gamestate >= 0 then break end
                end
                if gamestate >= 0 then break end
            end
            if gamestate == 0 then
                for i = 1, #tiles do
                    if tiles[i] == 2048 then
                        gamestate = 1
                        break
                    end
                end
            end
        end
    end
end

local pendinganims = 0

local guimovetile = |grid, i, j, step, hdir, vdir| do
    local o = grid:remove(j, true)
    local oadj = o.adjust
    grid:insert(j, blocktypes[0]())
    local n = (j - i) / step
    local dist = 0.205 * n
    local dirn, mspeed, dx, dy
    if hdir != 0 then
        dirn, mspeed = "speedup,x", 3 * n * hdir
        dx, dy = dist, 0
    else
        dirn, mspeed = "speedup,y", 3 * n * vdir
        dx, dy = 0, dist
    end
    grid.parent:append(gui.Animator {
        move_func = dirn, move_speed = mspeed,
        move_dist_x = dx, move_dist_y = dy, o
    }, |m| do
        m:clamp(true, true, true, true)
        connect(m, "anim,start", || do
            pendinganims += 1
        end)
        connect(m, "anim,end", || do
            m:set_visible(false)
            cleanup[#cleanup + 1] = m
            grid:remove(i)
            grid:insert(i, blocktypes[tiles[i]]())
            pendinganims -= 1
            if pendinganims == 0 then
                randtile(grid)
            end
            grid:layout()
        end)
        m:start()
        grid.parent:append(m)
    end)
    o.floating = true
    o.adjust   = 0
end

local movetile = |grid, off, hdir, vdir| do
    local dir = (hdir != 0) and hdir or (vdir * 4)
    local lbeg, lend, lstart
    if dir < 0 then
        if hdir != 0 then
            lbeg, lend, lstart = 2, 4, 1
        else
            lbeg, lend, lstart = 5, 13, 1
        end
    else
        if hdir != 0 then
            lbeg, lend, lstart = 3, 1, 4
        else
            lbeg, lend, lstart = 9, 1, 13
        end
    end
    local jm = false
    for i = lbeg, lend, -dir do
        local nnz
        for j = i + dir, lstart, dir do
            if tiles[j + off] != 0 then
                nnz = j
                break
            end
        end
        if nnz and not jm and tiles[nnz + off] == tiles[i + off] then
            jm = true
            tiles[nnz + off] += tiles[i + off]
            tiles[i + off] = 0
            guimovetile(grid, nnz + off, i + off, -dir, hdir, vdir)
            totalscore += tiles[nnz + off]
        elseif tiles[i + off] != 0 then
            jm = false
            local fz
            for j = i + dir, lstart, dir do
                if tiles[j + off] == 0 then fz = j end
            end
            if fz then
                tiles[fz + off] = tiles[i + off]
                tiles[i + off] = 0
                guimovetile(grid, fz + off, i + off, -dir, hdir, vdir)
            end
        end
    end
end

local movetiles = |grid, h, v| do
    if h != 0 then
        movetile(grid, 0,  h, 0)
        movetile(grid, 4,  h, 0)
        movetile(grid, 8,  h, 0)
        movetile(grid, 12, h, 0)
    end
    if v != 0 then
        movetile(grid, 0, 0, v)
        movetile(grid, 1, 0, v)
        movetile(grid, 2, 0, v)
        movetile(grid, 3, 0, v)
    end
    cleanuptiles()
end

local gamestates = {
    [-1] = "2048 (game over, score: %d)",
    [ 0] = "2048 (score: %d)",
    [ 1] = "2048 (you won! score: %d)"
}

local seededtiles = false
world:new_window("2048", gui.Window, |win| do
    win:set_floating(true)
    win:set_variant("movable")
    win:set_title("2048 (score: 0)")
    connect(win, "destroy", || do totalscore = 0 end)
    win:append(gui.Color_Filler { color = 0xBBADA0 }, |cf| do
        cf:clamp(true, true, true, true)
        win:append(gui.Spacer { pad_h = 0.025, pad_v = 0.025 }, |sp| do
            sp:append(gui.Grid { columns = 4, padding = 0.025 }, |grid| do
                cf.key = function(self, code, isdown)
                    if isdown then
                        if code == gui.key.LEFT then
                            movetiles(grid, -1,  0)
                        elseif code == gui.key.RIGHT then
                            movetiles(grid,  1,  0)
                        elseif code == gui.key.UP then
                            movetiles(grid,  0, -1)
                        elseif code == gui.key.DOWN then
                            movetiles(grid,  0,  1)
                        end
                    end
                    if gamestate < 0 then cf.key = nil end
                    win:set_title(gamestates[gamestate]:format(totalscore))
                    return gui.Widget.key(self, code, isdown)
                end
                if gamestate < 0 then
                    totalscore, gamestate, seededtiles, tiles = 0, 0, false, {}
                end
                if not seededtiles then
                    seedtiles()
                    seededtiles = true
                end
                for i = 1, #tiles do
                    grid:append(blocktypes[tiles[i]]())
                end
            end)
        end)
    end)
end)
