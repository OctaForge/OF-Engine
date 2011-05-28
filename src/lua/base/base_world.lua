--[[!
    File: base/base_world.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Warning
        This is scheduled for removal and replacement with nicer interface.

    Section: Utilities
]]

local env    = _G
local CAPI   = require("CAPI")
local gui    = require("gui")
local string = require("string")
local table  = require("table")

--[[!
    Package: world
    This module contains various functions for world manipulation, like editing system,
    vslots, some entity management, editing helper functions etc. This file is
    SCHEDULED FOR REMOVAL and will be replaced with better interface.
]]
module("world", package.seeall)

--- Check for collision
-- @class function
-- @name iscolliding
-- @param x X coordinate
-- @param y Y coordinate
-- @param z Z coordinate
-- @param rd Radius
-- @param ignore Entity to be ignored for this test (entity id)
iscolliding = CAPI.iscolliding

--- Set the gravity
-- @class function
-- @name setgravity
-- @param gr Gravity
setgravity = CAPI.setgravity

--- Get material
-- @class function
-- @name getmat
-- @param x X coordinate
-- @param y Y coordinate
-- @param z Z coordinate
-- @return Material id
getmat = CAPI.getmat

---
-- @class function
-- @name entautoview
entautoview = CAPI.entautoview

---
-- @class function
-- @name entflip
entflip = CAPI.entflip

---
-- @class function
-- @name entrotate
entrotate = CAPI.entrotate

---
-- @class function
-- @name entpush
entpush = CAPI.entpush

---
-- @class function
-- @name attachent
attachent = CAPI.attachent

---
-- @class function
-- @name newent
newent = CAPI.newent

---
-- @class function
-- @name delent
delent = CAPI.delent

---
-- @class function
-- @name dropent
dropent = CAPI.dropent

---
-- @class function
-- @name entcopy
entcopy = CAPI.entcopy

---
-- @class function
-- @name entpaste
entpaste = CAPI.entpaste
---
-- @class function
-- @name enthavesel
enthavesel = CAPI.enthavesel

---
-- @class function
-- @name entselect
entselect = CAPI.entselect

---
-- @class function
-- @name entloop
entloop = CAPI.entloop

---
-- @class function
-- @name insel
insel = CAPI.insel

---
-- @class function
-- @name entget
entget = CAPI.entget

---
-- @class function
-- @name entindex
entindex = CAPI.entindex

---
-- @class function
-- @name entset
entset = CAPI.entset

---
-- @class function
-- @name nearestent
nearestent = CAPI.nearestent
---
-- @class function
-- @name intensityentcopy
intensityentcopy = CAPI.intensityentcopy

---
-- @class function
-- @name intensitypasteent
intensitypasteent = CAPI.intensitypasteent

--- Create a new map
-- Generally not used, emptymap is normally forked
-- @class function
-- @name newmap
-- @param sz Size
newmap = CAPI.newmap

--- Enlarge the map
-- @class function
-- @name mapenlarge
mapenlarge = CAPI.mapenlarge

--- Shrink the map
-- @class function
-- @name shrinkmap
shrinkmap = CAPI.shrinkmap

--- Get the name of the map
-- @class function
-- @name mapname
-- @return The map name
mapname = CAPI.mapname

---
-- @class function
-- @name finish_dragging
finish_dragging = CAPI.finish_dragging

--- Get the name of the map's config file
-- @class function
-- @name mapcfgname
-- @return The map's config file
mapcfgname = CAPI.mapcfgname

---
-- @class function
-- @name writeobj
writeobj = CAPI.writeobj

--- Get the version number of the map
-- @class function
-- @name getmapversion
-- @return The map's version number
getmapversion = CAPI.getmapversion

--- Toggle edit mode
-- @class function
-- @name edittoggle
edittoggle = CAPI.edittoggle

---
-- @class function
-- @name entcancel
entcancel = CAPI.entcancel

---
-- @class function
-- @name cubecancel
cubecancel = CAPI.cubecancel

---
-- @class function
-- @name cancelsel
cancelsel = CAPI.cancelsel

---
-- @class function
-- @name reorient
reorient = CAPI.reorient

---
-- @class function
-- @name selextend
selextend = CAPI.selextend

---
-- @class function
-- @name havesel
havesel = CAPI.havesel

---
-- @class function
-- @name clearundos
clearundos = CAPI.clearundos

---
-- @class function
-- @name copy
copy = CAPI.copy

---
-- @class function
-- @name pastehilite
pastehilite = CAPI.pastehilite

---
-- @class function
-- @name paste
paste = CAPI.paste

---
-- @class function
-- @name undo
undo = CAPI.undo

---
-- @class function
-- @name redo
redo = CAPI.redo

---
-- @class function
-- @name pushsel
pushsel = CAPI.pushsel

---
-- @class function
-- @name editface
editface = CAPI.editface

---
-- @class function
-- @name delcube
delcube = CAPI.delcube

---
-- @class function
-- @name compactvslosts
compactvslosts = CAPI.compactvslosts

---
-- @class function
-- @name fixinsidefaces
fixinsidefaces = CAPI.fixinsidefaces

---
-- @class function
-- @name vdelta
vdelta = CAPI.vdelta

---
-- @class function
-- @name vrotate
vrotate = CAPI.vrotate

---
-- @class function
-- @name voffset
voffset = CAPI.voffset

---
-- @class function
-- @name vscroll
vscroll = CAPI.vscroll

---
-- @class function
-- @name vscale
vscale = CAPI.vscale

---
-- @class function
-- @name vlayer
vlayer = CAPI.vlayer

---
-- @class function
-- @name valpha
valpha = CAPI.valpha

---
-- @class function
-- @name vcolor
vcolor = CAPI.vcolor

---
-- @class function
-- @name vreset
vreset = CAPI.vreset

---
-- @class function
-- @name vshaderparam
vshaderparam = CAPI.vshaderparam

---
-- @class function
-- @name replace
replace = CAPI.replace

---
-- @class function
-- @name replacesel
replacesel = CAPI.replacesel

---
-- @class function
-- @name flip
flip = CAPI.flip

---
-- @class function
-- @name rotate
rotate = CAPI.rotate

---
-- @class function
-- @name editmat
editmat = CAPI.editmat

---
-- @class function
-- @name npcadd
npcadd = CAPI.npcadd

---
-- @class function
-- @name npcdel
npcdel = CAPI.npcdel

---
-- @class function
-- @name getentclass
getentclass = CAPI.getentclass

---
-- @class function
-- @name prepareentityclasses
prepareentityclasses = CAPI.prepareentityclasses

---
-- @class function
-- @name numentityclasses
numentityclasses = CAPI.numentityclasses

---
-- @class function
-- @name spawnent
spawnent = CAPI.spawnent

---
-- @class function
-- @name requestprivedit
requestprivedit = CAPI.requestprivedit

---
-- @class function
-- @name hasprivedit
hasprivedit = CAPI.hasprivedit

---
-- @class function
-- @name resetlightmaps
resetlightmaps = CAPI.resetlightmaps

---
-- @class function
-- @name calclight
calclight = CAPI.calclight

---
-- @class function
-- @name patchlight
patchlight = CAPI.patchlight

---
-- @class function
-- @name clearlightmaps
clearlightmaps = CAPI.clearlightmaps

---
-- @class function
-- @name dumplms
dumplms = CAPI.dumplms

---
-- @class function
-- @name recalc
recalc = CAPI.recalc

---
-- @class function
-- @name printcube
printcube = CAPI.printcube

---
-- @class function
-- @name remip
remip = CAPI.remip

---
-- @class function
-- @name phystest
phystest = CAPI.phystest
---
-- @class function
-- @name genpvs
genpvs = CAPI.genpvs
---
-- @class function
-- @name testpvs
testpvs = CAPI.testpvs
---
-- @class function
-- @name clearpvs
clearpvs = CAPI.clearpvs
---
-- @class function
-- @name pvsstats
pvsstats = CAPI.pvsstats
---
-- @class function
-- @name editing_getworldsize
editing_getworldsize = CAPI.editing_getworldsize
---
-- @class function
-- @name editing_getgridsize
editing_getgridsize = CAPI.editing_getgridsize
---
-- @class function
-- @name editing_erasegeometry
editing_erasegeometry = CAPI.editing_erasegeometry
---
-- @class function
-- @name editing_createcube
editing_createcube = CAPI.editing_createcube
---
-- @class function
-- @name editing_deletecube
editing_deletecube = CAPI.editing_deletecube
---
-- @class function
-- @name editing_setcubetex
editing_setcubetex = CAPI.editing_setcubetex
---
-- @class function
-- @name editing_setcubemat
editing_setcubemat = CAPI.editing_setcubemat
---
-- @class function
-- @name editing_pushcubecorner
editing_pushcubecorner = CAPI.editing_pushcubecorner
---
-- @class function
-- @name editing_getselent
editing_getselent = CAPI.editing_getselent
---
-- @class function
-- @name restart_map
restart_map = CAPI.restart_map
---
-- @class function
-- @name export_entities
export_entities = CAPI.export_entities
--- Run a map.
-- @param m Map name, or nil. If nil, current map gets stopped.
-- @class function
-- @name map
map = CAPI.map
--- Get if we are running a map.
-- @return True if yes, false otherwise.
-- @class function
-- @name hasmap
hasmap = CAPI.hasmap
---
-- @class table
-- @name hmap
-- @field brush Brush manipulation tools.
-- @field brush.index Current brush index.
-- @field brush.max Max selectable brush index.
hmap = {
    brush = {
        index = -1,
        max = -1 -- make sure to bump this up if you add more brushes
    }
}

function hmap.brush._handle(x, y)
    env.brushx = x
    env.brushy = y
end

function hmap.brush._verts(lst)
    for y = 1, #lst do
        local bv = lst[y]
        for x = 1, #bv do
            CAPI.brushvert(x, y, bv[x])
        end
    end
end

---
-- @class function
-- @name hmap.brush.select
function hmap.brush.select(n)
    hmap.brush.index = n + hmap.brush.index
    if hmap.brush.index < 0 then hmap.brush.index = hmap.brush.max end
    if hmap.brush.index > hmap.brush.max then hmap.brush.index = 0 end
    local brushname = hmap["brush_" .. hmap.brush.index]()
    echo(brushname)
end

---
-- @class function
-- @name hmap.brush.new
function hmap.brush.new(nm, x, y, vrts)
    hmap.brush.max = hmap.brush.max + 1
    hmap["brush_" .. hmap.brush.max] = function()
        local brushname = nm
        CAPI.clearbrush()
        if x and y and vrts then
            hmap.brush._handle(x, y)
            hmap.brush._verts(vrts)
        end
        return brushname
    end
end

---
-- @class function
-- @name hmap.cancel
hmap.cancel = CAPI.hmapcancel
---
-- @class function
-- @name hmap.select
hmap.select = CAPI.hmapselect

--- entity type of current selection
function enttype()
    return string.split(entget(), " ")[1]
end

--- access the given attribute of selected ent
function entgetattr(a)
    return string.split(entget(), " ")[a + 2]
end

--- clear ents of given type
function clearents(t)
    if env.editing ~= 0 then
        entcancel()
        entselect([[return %(1)q ~= world.enttype()]] % { t })
        echo("Deleted %(1)s %(2)s entities." % { env.tostring(enthavesel()), t })
        delent()
    end
end

---
-- replace all ents that match current selection
-- with the values given
function replaceents(what, a1, a2, a3, a4)
    if env.editing ~= 0 then
        entfind(env.unpack(string.split(entget(), " ")))
        entset(what, a1, a2, a3, a4)
        echo("Replaced %(1)s entities." % { env.tostring(enthavesel()) })
    end
end

---
function selentedit()
    entset(env.unpack(string.split(entget(), " ")))
end

---
function selreplaceents()
    replaceents(env.unpack(string.split(entget(), " ")))
end

---
function selentfindall()
    entfind(env.unpack(string.split(entget(), " ")))
end

---
-- modify given attribute of ent by a given amount
-- @p arg1 attribute
-- @p arg2 value
function entsetattr(arg1, arg2)
    entloop([[
        local a0 = world.entgetattr(0)
        local a1 = world.entgetattr(1)
        local a2 = world.entgetattr(2)
        local a3 = world.entgetattr(3)
        local a4 = world.entgetattr(4)
        a%(1)s = a%(1)s + %(2)s
        world.entset(world.enttype(), a0, a1, a2, a3, a4)
    ]] % { arg1, arg2 })
end

-- entity primary actions
function ent_action_base(a) entsetattr(0, a) end
function ent_action_mapmodel(a) entsetattr(1, a) end
function ent_action_spotlight(a) entsetattr(0, a * 5) end
function ent_action_light(a) entsetattr(0, a * 5) end
function ent_action_playerstart(a) entsetattr(0, a * 15) end
function ent_action_envmap(a) entsetattr(0, a * 5) end
function ent_action_particles(a) entsetattr(0, a) end
function ent_action_sound(a) entsetattr(0, a) end
function ent_action_cycle(a, aa, aaa) entsetattr(a > -1 and aa or aaa) end

-- copy and paste

-- 3 types of copying and pasting
-- 1. select only cubes      -> paste only cubes
-- 2. select cubes and ents  -> paste cubes and ents. same relative positions
-- 3. select only ents       -> paste last selected ent. if ents are selected, replace attrs as paste

entcopybuf = {}

function entreplace()
    if enthavesel() == 0 then
        CAPI.save_mouse_pos() -- place new entity right here
        intensitypasteent() -- using our newent here
    end
    entsetattr(env.unpack(entcopybuf))
end

function editcopy()
    if havesel() ~= 0 or enthavesel() == 0 then
        entcopybuf = {}
        entcopy()
        copy()
    else
        entcopybuf = string.split(entget(), " ")
        intensityentcopy()
    end
end

function editpaste()
    local cancelpaste = not (enthavesel() or havesel())
    if table.concat(entcopybuf) == "" then
        pastehilite()
        reorient() -- temp - teal fix will be in octaedit
        CAPI.onrelease([[
            world.delcube()
            world.paste()
            world.entpaste()
            if %(1)s then world.cancelsel() end
        ]] % { env.tostring(cancelpaste) })
    else
        entreplace()
        if cancelpaste then cancelsel() end
    end
end

-- selection

function equaltype(t)
    return (
        t == '*' and true
        or (enttype() == t)
    )
end

function equalattr(n, v)
    return (
        v == '*' and true
        or (entgetattr(n) == v)
    )
end

---
-- select ents with given properties
-- '*' is wildcard
function entfind(...)
    local arg = { ... }
    if #arg == 1 then
        entselect([[return world.equaltype(%(1)s)]] % { arg[1] })
    elseif #arg == 2 then
        entselect([[
            return (world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
            )]] % { arg[1], arg[2] })
    elseif #arg == 3 then
        entselect([[
            return (world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
                and world.equalattr(0, %(3)s)
            )]] % { arg[1], arg[2], arg[3] })
    elseif #arg == 4 then
        entselect([[
            return (world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
                and world.equalattr(0, %(3)s)
                and world.equalattr(0, %(4)s)
            )]] % { arg[1], arg[2], arg[3], arg[4] })
    elseif #arg == 5 then
        entselect([[
            return (world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
                and world.equalattr(0, %(3)s)
                and world.equalattr(0, %(4)s)
                and world.equalattr(0, %(5)s)
            )]] % { arg[1], arg[2], arg[3], arg[4], arg[5] })
    end
end

function entfindinsel(...)
    local arg = { ... }
    if #arg == 1 then
        entselect([[return world.insel() and world.equaltype(%(1)s)]] % { arg[1] })
    elseif #arg == 2 then
        entselect([[
            return (world.insel() and world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
            )]] % { arg[1], arg[2] })
    elseif #arg == 3 then
        entselect([[
            return (world.insel() and world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
                and world.equalattr(0, %(3)s)
            )]] % { arg[1], arg[2], arg[3] })
    elseif #arg == 4 then
        entselect([[
            return (world.insel() and world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
                and world.equalattr(0, %(3)s)
                and world.equalattr(0, %(4)s)
            )]] % { arg[1], arg[2], arg[3], arg[4] })
    elseif #arg == 5 then
        entselect([[
            return (world.insel() and world.equaltype(%(1)s)
                and world.equalattr(0, %(2)s)
                and world.equalattr(0, %(3)s)
                and world.equalattr(0, %(4)s)
                and world.equalattr(0, %(5)s)
            )]] % { arg[1], arg[2], arg[3], arg[4], arg[5] })
    end
end

function lse()
    lse_line = ""
    lse_count = 0
    entloop([[
        world.lse_line = world.lse_line .. "		"
        world.lse_count = world.lse_count + 1
        if world.lse_count > 4 then
            echo(world.lse_line)
            world.lse_line = ""
            world.lse_count = 0
        end
    ]])
    if lse_count > 0 then echo(lse_line) end
    echo("%(1)i entities selected" % { enthavesel() })
end

function clearallents()
    entfind("*")
    delent()
end

function enttoggle() env.entmoving = 1; env.entmoving = 0 end
function entaddmove() env.entmoving = 2 end

function drag() env.dragging = 1; CAPI.onrelease([[dragging = 0]]) end
function corners() env.selectcorners = 1; env.dragging = 1; CAPI.onrelease([[selectcorners = 0; dragging = 0]]) end
function entadd() entaddmove(); env.entmoving = 0 end
function editmove() env.moving = 1; CAPI.onrelease([[moving = 0]]); return env.moving end
function entdrag() entaddmove(); CAPI.onrelease([[world.finish_dragging(); entmoving = 0]]); return env.entmoving end
function editdrag() cancelsel(); if entdrag() == 0 then drag() end end
function selcorners()
    if env.hmapedit ~= 0 then
        hmap.select()
    else
        cancelsel()
        if entdrag() == 0 then corners() end
    end
end
function editextend() if entdrag() == 0 then selextend(); reorient(); editmove() end end
-- Use second mouse button to show our edit entities dialog, if hovering
function editextend_intensity()
    if env.has_mouse_target == 0 then
        editextend()
    else
        gui.prepentgui()
        gui.show("entity")
    end
end

function edit_entity(a)
    if CAPI.set_mouse_targeting_ent(a) ~= 0 then
        gui.prepentgui()
        gui.show("entity")
    else
        echo("No such entity")
    end
end

function edit_client(a)
    if CAPI.set_mouse_target_client(a) ~= 0 then
        gui.prepentgui()
        gui.show("entity")
    else
        echo("No such client")
    end
end

function editmovecorner(a)
    if havesel() ~= 0 then
        if editmove() == 0 then
            selcorners()
        end
        CAPI.onrelease([[moving = 0; dragging = 0]])
    else
        selcorners()
    end
end

function editmovedrag(a)
    if havesel() ~= 0 then
        if editmove() == 0 then
            editdrag()
        end
        CAPI.onrelease([[moving = 0; dragging = 0]])
    else
        editdrag()
    end
end

-- other editing commands

function editfacewentpush(a, aa)
    if havesel() ~= 0 or enthavesel() == 0 then
        if env.moving ~= 0 then
            pushsel(a)
        else
            entcancel()
            editface(a, aa)
        end
    else
        if env.entmoving ~= 0 then
            entpush(a)
        else
            _G["ent_action_" .. enttype()]()
        end
    end
end

entswithdirection = { "playerstart", "mapmodel" }

function entdirection(a, aa)
    if enthavesel() ~= 0 and havesel() == 0 then
        if table.find(entswithdirection, enttype()) then
            if a > 0 then
                entsetattr(0, aa)
                if entgetattr(0) > 360 then entsetattr(0, -360) end
            else
                entsetattr(0, -aa)
                if entgetattr(0) < 0 then entsetattr(0, 360) end
            end
        end
        return true
    else return false end
end

function editdel() if enthavesel() == 0 then delcube() end; delent() end
function editflip() flip(); entflip() end

function editrotate(a)
    if not entdirection(a, 15) then
        rotate(a)
        entrotate(a)
    end
end

function editcut()
    local hadselection = havesel()
    env.moving = 1
    if env.moving ~= 0 then
        copy();   entcopy()
        delcube(); delent()
        CAPI.onrelease([[
            moving = 0
            world.paste()
            world.entpaste()
            if %(1)s == 0 then
                world.cancelsel()
            end
        ]] % { hadselection })
    end
end

function passthrough(a)
    env.passthroughsel = a
    if a and a ~= 0 then
        passthroughcube_bak = env.passthroughcube
        env.passthroughcube = 1
    else
        env.passthroughcube = passthroughcube_bak
    end
    entcancel()
    if env.setting_entediting and env.setting_entediting ~= 0 then
        env.entediting = env.tonumber(not a or a == 0)
    end
end

function air() editmat("air") end
function water() editmat("water") end
function clip() editmat("clip") end
function glass() editmat("glass") end
function noclip() editmat("noclip") end
function lava() editmat("lava") end
function alpha() editmat("alpha") end

function getsundir()
    local cam = CAPI.getcam()
    env.sunlightyaw = cam.yaw
    env.sunlightpitch = cam.pitch
end

function is_player_colliding_entity(player, entity)
    if entity.collision_radius_width and entity.collision_radius_width ~= 0 then
        -- z
        if player.position.z >= entity.position.z + 2 * entity.collision_radius_height or
           player.position.z + player.eyeheight + player.aboveeye <= entity.position.z then return false end

        -- x
        if player.position.x - player.radius >= entity.position.x + entity.collision_radius_width or
           player.position.x + player.radius <= entity.position.x - entity.collision_radius_width then return false end

        -- y
        if player.position.y - player.radius >= entity.position.y + entity.collision_radius_width or
           player.position.y + player.radius <= entity.position.y - entity.collision_radius_width then return false end

        return true
    else
        -- z
        if player.position.z >= entity.position.z + entity.eyeheight + entity.aboveeye or
           player.position.z + player.eyeheight + player.aboveeye <= entity.position.z then return false end

        -- x
        if player.position.x - player.radius >= entity.position.x + entity.radius or
           player.position.x + player.radius <= entity.position.x - entity.radius then return false end

        -- y
        if player.position.y - player.radius >= entity.position.y + entity.radius or
           player.position.y + player.radius <= entity.position.y - entity.radius then return false end

        return true
    end
end
