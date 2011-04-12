---
-- base_models.lua, version 1<br/>
-- Model interface for cC Lua scripting system<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local base = _G
local string = require("string")
local math = require("math")
local CAPI = require("CAPI")

--- Model control for cC's Lua interface.
-- @class module
-- @name cc.model
module("cc.model")

-- in sync with iengine.h
CULL_VFC = math.lsh(1, 0)
CULL_DIST = math.lsh(1, 1)
CULL_OCCLUDED = math.lsh(1, 2)
CULL_QUERY = math.lsh(1, 3)
SHADOW = math.lsh(1, 4)
DYNSHADOW = math.lsh(1, 5)
LIGHT = math.lsh(1, 6)
DYNLIGHT = math.lsh(1, 7)
FULLBRIGHT = math.lsh(1, 8)
NORENDER = math.lsh(1, 9)

---
-- @class function
-- @name reset
reset = CAPI.mapmodelreset
---
-- @class function
-- @name num
num = CAPI.nummapmodels
---
-- @class function
-- @name clear
clear = CAPI.clearmodel
---
-- @class function
-- @name preload
preload = CAPI.preloadmodel
---
-- @class function
-- @name reload
reload = CAPI.reloadmodel
---
-- @class function
-- @name render
render = CAPI.rendermodel

---
function attachment(t, n)
    base.assert(not string.find(t, ","))
    base.assert(not string.find(n, ","))
    return t .. "," .. n
end

--- This table contains various generic
-- methods relating a single model.
-- @class table
-- @name mdl
mdl = {}
---
-- @class function
-- @name mdl.name
mdl.name = CAPI.mdlname
---
-- @class function
-- @name mdl.alphatest
mdl.alphatest = CAPI.mdlalphatest
---
-- @class function
-- @name mdl.alphablend
mdl.alphablend = CAPI.mdlalphablend
---
-- @class function
-- @name mdl.alphadepth
mdl.alphadepth = CAPI.mdlalphadepth
---
-- @class function
-- @name mdl.bb
mdl.bb = CAPI.mdlbb
---
-- @class function
-- @name mdl.extendbb
mdl.extendbb = CAPI.mdlextendbb
---
-- @class function
-- @name mdl.scale
mdl.scale = CAPI.mdlscale
---
-- @class function
-- @name mdl.spec
mdl.spec = CAPI.mdlspec
---
-- @class function
-- @name mdl.glow
mdl.glow = CAPI.mdlglow
---
-- @class function
-- @name mdl.glare
mdl.glare = CAPI.mdlglare
---
-- @class function
-- @name mdl.ambient
mdl.ambient = CAPI.mdlambient
---
-- @class function
-- @name mdl.cullface
mdl.cullface = CAPI.mdlcullface
---
-- @class function
-- @name mdl.depthoffset
mdl.depthoffset = CAPI.mdldepthoffset
---
-- @class function
-- @name mdl.fullbright
mdl.fullbright = CAPI.mdlfullbright
---
-- @class function
-- @name mdl.spin
mdl.spin = CAPI.mdlspin
---
-- @class function
-- @name mdl.envmap
mdl.envmap = CAPI.mdlenvmap
---
-- @class function
-- @name mdl.shader
mdl.shader = CAPI.mdlshader
---
-- @class function
-- @name mdl.collisionsonlyfortriggering
mdl.collisionsonlyfortriggering = CAPI.mdlcollisionsonlyfortriggering
---
-- @class function
-- @name mdl.trans
mdl.trans = CAPI.mdltrans
---
-- @class function
-- @name mdl.yaw
mdl.yaw = CAPI.mdlyaw
---
-- @class function
-- @name mdl.pitch
mdl.pitch = CAPI.mdlpitch
---
-- @class function
-- @name mdl.shadow
mdl.shadow = CAPI.mdlshadow
---
-- @class function
-- @name mdl.collide
mdl.collide = CAPI.mdlcollide
---
-- @class function
-- @name mdl.perentitycollisionboxes
mdl.perentitycollisionboxes = CAPI.mdlperentitycollisionboxes
---
-- @class function
-- @name mdl.ellipsecollide
mdl.ellipsecollide = CAPI.mdlellipsecollide
---
-- @class function
-- @name mdl.scriptbb
mdl.scriptbb = CAPI.scriptmdlbb
---
-- @class function
-- @name mdl.scriptcb
mdl.scriptcb = CAPI.scriptmdlcb
---
-- @class function
-- @name mdl.mesh
mdl.mesh = CAPI.mdlmesh

---
-- @class table
-- @name obj
obj = {}
---
-- @class function
-- @name obj.load
obj.load = CAPI.objload
---
-- @class function
-- @name obj.skin
obj.skin = CAPI.objskin
---
-- @class function
-- @name obj.bumpmap
obj.bumpmap = CAPI.objbumpmap
---
-- @class function
-- @name obj.envmap
obj.envmap = CAPI.objenvmap
---
-- @class function
-- @name obj.spec
obj.spec = CAPI.objspec
---
-- @class function
-- @name obj.pitch
obj.pitch = CAPI.objpitch
---
-- @class function
-- @name obj.ambient
obj.ambient = CAPI.objambient
---
-- @class function
-- @name obj.glow
obj.glow = CAPI.objglow
---
-- @class function
-- @name obj.glare
obj.glare = CAPI.objglare
---
-- @class function
-- @name obj.alphatest
obj.alphatest = CAPI.objalphatest
---
-- @class function
-- @name obj.alphablend
obj.alphablend = CAPI.objalphablend
---
-- @class function
-- @name obj.cullface
obj.cullface = CAPI.objcullface
---
-- @class function
-- @name obj.fullbright
obj.fullbright = CAPI.objfullbright
---
-- @class function
-- @name obj.shader
obj.shader = CAPI.objshader
---
-- @class function
-- @name obj.scroll
obj.scroll = CAPI.objscroll
---
-- @class function
-- @name obj.noclip
obj.noclip = CAPI.objnoclip

--- This table contains all methods meant
-- for manipulating with md5 model format.
-- @class table
-- @name md5
md5 = {}
---
-- @class function
-- @name md5.dir
md5.dir = CAPI.md5dir
---
-- @class function
-- @name md5.load
md5.load = CAPI.md5load
---
-- @class function
-- @name md5.tag
md5.tag = CAPI.md5tag
---
-- @class function
-- @name md5.pitch
md5.pitch = CAPI.md5pitch
---
-- @class function
-- @name md5.adjust
md5.adjust = CAPI.md5adjust
---
-- @class function
-- @name md5.skin
md5.skin = CAPI.md5skin
---
-- @class function
-- @name md5.spec
md5.spec = CAPI.md5spec
---
-- @class function
-- @name md5.ambient
md5.ambient = CAPI.md5ambient
---
-- @class function
-- @name md5.glow
md5.glow = CAPI.md5glow
---
-- @class function
-- @name md5.glare
md5.glare = CAPI.md5glare
---
-- @class function
-- @name md5.alphatest
md5.alphatest = CAPI.md5alphatest
---
-- @class function
-- @name md5.alphablend
md5.alphablend = CAPI.md5alphablend
---
-- @class function
-- @name md5.cullface
md5.cullface = CAPI.md5cullface
---
-- @class function
-- @name md5.envmap
md5.envmap = CAPI.md5envmap
---
-- @class function
-- @name md5.bumpmap
md5.bumpmap = CAPI.md5bumpmap
---
-- @class function
-- @name md5.fullbright
md5.fullbright = CAPI.md5fullbright
---
-- @class function
-- @name md5.shader
md5.shader = CAPI.md5shader
---
-- @class function
-- @name md5.scroll
md5.scroll = CAPI.md5scroll
---
-- @class function
-- @name md5.animpart
md5.animpart = CAPI.md5animpart
---
-- @class function
-- @name md5.anim
md5.anim = CAPI.md5anim
---
-- @class function
-- @name md5.link
md5.link = CAPI.md5link
---
-- @class function
-- @name md5.noclip
md5.noclip = CAPI.md5noclip

--- This table contains all methods meant
-- for manipulating with iqm model format.
-- @class table
-- @name iqm
iqm = {}
---
-- @class function
-- @name iqm.dir
iqm.dir = CAPI.iqmdir
---
-- @class function
-- @name iqm.load
iqm.load = CAPI.iqmload
---
-- @class function
-- @name iqm.tag
iqm.tag = CAPI.iqmtag
---
-- @class function
-- @name iqm.pitch
iqm.pitch = CAPI.iqmpitch
---
-- @class function
-- @name iqm.adjust
iqm.adjust = CAPI.iqmadjust
---
-- @class function
-- @name iqm.skin
iqm.skin = CAPI.iqmskin
---
-- @class function
-- @name iqm.spec
iqm.spec = CAPI.iqmspec
---
-- @class function
-- @name iqm.ambient
iqm.ambient = CAPI.iqmambient
---
-- @class function
-- @name iqm.glow
iqm.glow = CAPI.iqmglow
---
-- @class function
-- @name iqm.glare
iqm.glare = CAPI.iqmglare
---
-- @class function
-- @name iqm.alphatest
iqm.alphatest = CAPI.iqmalphatest
---
-- @class function
-- @name iqm.alphablend
iqm.alphablend = CAPI.iqmalphablend
---
-- @class function
-- @name iqm.cullface
iqm.cullface = CAPI.iqmcullface
---
-- @class function
-- @name iqm.envmap
iqm.envmap = CAPI.iqmenvmap
---
-- @class function
-- @name iqm.bumpmap
iqm.bumpmap = CAPI.iqmbumpmap
---
-- @class function
-- @name iqm.fullbright
iqm.fullbright = CAPI.iqmfullbright
---
-- @class function
-- @name iqm.shader
iqm.shader = CAPI.iqmshader
---
-- @class function
-- @name iqm.scroll
iqm.scroll = CAPI.iqmscroll
---
-- @class function
-- @name iqm.animpart
iqm.animpart = CAPI.iqmanimpart
---
-- @class function
-- @name iqm.anim
iqm.anim = CAPI.iqmanim
---
-- @class function
-- @name iqm.link
iqm.link = CAPI.iqmlink
---
-- @class function
-- @name iqm.noclip
iqm.noclip = CAPI.iqmnoclip

--- This table contains all methods meant
-- for manipulating with smd model format.
-- @class table
-- @name smd
smd = {}
---
-- @class function
-- @name smd.dir
smd.dir = CAPI.smddir
---
-- @class function
-- @name smd.load
smd.load = CAPI.smdload
---
-- @class function
-- @name smd.tag
smd.tag = CAPI.smdtag
---
-- @class function
-- @name smd.pitch
smd.pitch = CAPI.smdpitch
---
-- @class function
-- @name smd.adjust
smd.adjust = CAPI.smdadjust
---
-- @class function
-- @name smd.skin
smd.skin = CAPI.smdskin
---
-- @class function
-- @name smd.spec
smd.spec = CAPI.smdspec
---
-- @class function
-- @name smd.ambient
smd.ambient = CAPI.smdambient
---
-- @class function
-- @name smd.glow
smd.glow = CAPI.smdglow
---
-- @class function
-- @name smd.glare
smd.glare = CAPI.smdglare
---
-- @class function
-- @name smd.alphatest
smd.alphatest = CAPI.smdalphatest
---
-- @class function
-- @name smd.alphablend
smd.alphablend = CAPI.smdalphablend
---
-- @class function
-- @name smd.cullface
smd.cullface = CAPI.smdcullface
---
-- @class function
-- @name smd.envmap
smd.envmap = CAPI.smdenvmap
---
-- @class function
-- @name smd.bumpmap
smd.bumpmap = CAPI.smdbumpmap
---
-- @class function
-- @name smd.fullbright
smd.fullbright = CAPI.smdfullbright
---
-- @class function
-- @name smd.shader
smd.shader = CAPI.smdshader
---
-- @class function
-- @name smd.scroll
smd.scroll = CAPI.smdscroll
---
-- @class function
-- @name smd.animpart
smd.animpart = CAPI.smdanimpart
---
-- @class function
-- @name smd.anim
smd.anim = CAPI.smdanim
---
-- @class function
-- @name smd.link
smd.link = CAPI.smdlink
---
-- @class function
-- @name smd.noclip
smd.noclip = CAPI.smdnoclip

--- This table contains
-- ragdoll manipulation methods.
-- @class table
-- @name rd
rd = {}
---
-- @class function
-- @name rd.name
rd.vert = CAPI.rdvert
---
-- @class function
-- @name rd.name
rd.eye = CAPI.rdeye
---
-- @class function
-- @name rd.name
rd.tri = CAPI.rdtri
---
-- @class function
-- @name rd.name
rd.joint = CAPI.rdjoint
---
-- @class function
-- @name rd.name
rd.limitdist = CAPI.rdlimitdist
---
-- @class function
-- @name rd.name
rd.limitrot = CAPI.rdlimitrot
---
-- @class function
-- @name rd.name
rd.animjoints = CAPI.rdanimjoints
