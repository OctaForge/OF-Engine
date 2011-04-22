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
-- TODO: make more detailed later
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

--- Reset mapmodel counter - start counting slots from N. DEPRECATED.
-- @param n Number from which to start counting.
-- @class function
-- @name reset
reset = CAPI.mapmodelreset

--- Get number of mapmodels. DEPRECATED.
-- @return Number of mapmodels.
-- @class function
-- @name num
num = CAPI.nummapmodels

--- Clear a mapmodel. DEPRECATED.
-- @param n Name of the mapmodel.
-- @class function
-- @name clear
clear = CAPI.clearmodel

--- Preload a mapmodel. Basically, cache it before loading the world.
-- @param n Name of the mapmodel.
-- @class function
-- @name preload
preload = CAPI.preloadmodel

--- Reload a mapmodel.
-- @param n Name of the mapmodel.
-- @class function
-- @name reload
reload = CAPI.reloadmodel

--- Render a model.
-- @param ent Entity which the model belongs to.
-- @param mdl Model name.
-- @param anim Model animation (integer, see base_actions.lua)
-- @param x X coord of the model.
-- @param y Y coord of the model.
-- @param z Z coord of the model.
-- @param yaw Model yaw.
-- @param pitch Model pitch.
-- @param roll Model roll.
-- @param flags Model flags (integer) using bitwise operators, see beginning of this file for flags.
-- @param basetime Entity starttime property.
-- @param 
-- @class function
-- @name render
render = CAPI.rendermodel

--- Create attachment string.
-- @param t Tag of the model.
-- @param n Name of the attachment.
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

--- Get current model slot's name. DEPRECATED.
-- @class function
-- @name mdl.name
mdl.name = CAPI.mdlname

--- Set alpha testing cut-off threshold T at which alpha-channel skins will discard pixels
-- where alpha is less than T. T is a floating point value in the range of 0 to 1 (defaults to 0.9)
-- @param cutoff Cut-off threshold.
-- @class function
-- @name mdl.alphatest
mdl.alphatest = CAPI.mdlalphatest

--- Control whether a model with alpha channel skin will alpha blend (defaults to 1)
-- @param blend 1 to enable, 0 to disable.
-- @class function
-- @name mdl.alphablend
mdl.alphablend = CAPI.mdlalphablend

--- Control model alpha depth.
-- @param depth Model alpha depth.
-- @class function
-- @name mdl.alphadepth
mdl.alphadepth = CAPI.mdlalphadepth

--- Control model bounding box. If not set,
-- bounding box is generated from model's geometry.
-- @param rad Bounding box radius.
-- @param h Bounding box height.
-- @param eyeheight Fraction of model's height to be used as eyeheight (defaults to 0.9)
-- @class function
-- @name mdl.bb
mdl.bb = CAPI.mdlbb

--- Extend model bounding box.
-- @param x X coord.
-- @param y Y coord.
-- @param z Z coord.
-- @class function
-- @name mdl.extendbb
mdl.extendbb = CAPI.mdlextendbb

--- Set model scale.
-- @param p Number of percent of its default
-- size (i.e. 200 will make the model two times bigger)
-- @class function
-- @name mdl.scale
mdl.scale = CAPI.mdlscale

--- Set model specular intensity. When not given, default 100 gets applied.
-- 100 is good for shiny objects, -1 means specularity is off.
-- @param spec Specular intensity.
-- @class function
-- @name mdl.spec
mdl.spec = CAPI.mdlspec

--- Set model glowmap scale. -1 means glowmap is off. Default is 300.
-- @param g Glowmap scale.
-- @class function
-- @name mdl.glow
mdl.glow = CAPI.mdlglow

--- Scale amount of glare generated by spec light and glare. Defaults to 1 1.
-- @param s Floating point value specifying scale of glare generated by spec light.
-- @param g Floating point value specifying scale of glare generated by glare.
-- @class function
-- @name mdl.glare
mdl.glare = CAPI.mdlglare

--- Set percent of ambient light used for shading.
-- Not given or 0 sets default of 30%, -1 means no ambient.
-- @param p Percentage of ambient light used for shading.
-- @class function
-- @name mdl.ambient
mdl.ambient = CAPI.mdlambient

--- Control back face culling.
-- @param n 1 means enabled, 0 disabled.
-- @class function
-- @name mdl.cullface
mdl.cullface = CAPI.mdlcullface

--- Set depth offset for model.
-- @param d Depth offset (integer).
-- @class function
-- @name mdl.depthoffset
mdl.depthoffset = CAPI.mdldepthoffset

--- Use a constant lighting level instead of normal lighting.
-- @param n Fullbright lighting scale, float from 0 to 1.
-- @class function
-- @name mdl.fullbright
mdl.fullbright = CAPI.mdlfullbright

--- Simple spin animation that changes yaw and pitch in N degrees per second.
-- @param yaw Change of yaw in degrees per second.
-- @param pitch Change of pitch in degrees per second.
-- @class function
-- @name mdl.spin
mdl.spin = CAPI.mdlspin

--- Set the envmap used for model. If not set, closest envmap entity or skybox will be used.
-- If mei is non-zero, blue channel of the masks is interpreted as chrome map.
-- mei (maximum envmap intensity) and mmei (minimum envmap intensity, defaults to 0) are
-- floats ranging from 0 to 1 and specify the range in which the envmapping intensity will vary
-- based on view angle. The intensity after scaling into this range is then multiplied by chrome map.
-- @param mei Maximum envmap intensity.
-- @param mmei Minimum envmap intensity.
-- @param path Path to the envmap texture. 
-- @class function
-- @name mdl.envmap
mdl.envmap = CAPI.mdlenvmap

--- Set the shader to use for rendering the model (defaults to stdmodel).
-- @param sn Shader name.
-- @class function
-- @name mdl.shader
mdl.shader = CAPI.mdlshader

--- Control "collision only for triggering" property.
-- @param v 1 to enable, 0 to disable.
-- @class function
-- @name mdl.collisionsonlyfortriggering
mdl.collisionsonlyfortriggering = CAPI.mdlcollisionsonlyfortriggering

--- Translate the model's center by x, y, z where x, y, z are in model units (may use floating point).
-- @param x X in model units.
-- @param y Y in model units.
-- @param z Z in model units.
-- @class function
-- @name mdl.trans
mdl.trans = CAPI.mdltrans

--- Set yaw of the model.
-- @param a The yaw angle.
-- @class function
-- @name mdl.yaw
mdl.yaw = CAPI.mdlyaw

--- Set pitch of the model.
-- @param p The pitch angle.
-- @class function
-- @name mdl.pitch
mdl.pitch = CAPI.mdlpitch

--- Enable or disable model shadow.
-- @param v 1 to enable, 0 to disable.
-- @class function
-- @name mdl.shadow
mdl.shadow = CAPI.mdlshadow

--- Enable or disable model collision.
-- @param v 1 to enable, 0 to disable.
-- @class function
-- @name mdl.collide
mdl.collide = CAPI.mdlcollide

--- Control the "per entity collision boxes" property.
-- @param v 1 to enable, 0 to disable.
-- @class function
-- @name mdl.perentitycollisionboxes
mdl.perentitycollisionboxes = CAPI.mdlperentitycollisionboxes

--- Enable elliptic collision for model (good for i.e. trees)
-- @param v 1 to enable, 0 to disable.
-- @class function
-- @name mdl.ellipsecollide
mdl.ellipsecollide = CAPI.mdlellipsecollide

--- Set scripting bounding box.
-- @param n Model name.
-- @class function
-- @name mdl.scriptbb
mdl.scriptbb = CAPI.scriptmdlbb

--- Set scripting collision box.
-- @param n Model name.
-- @class function
-- @name mdl.scriptcb
mdl.scriptcb = CAPI.scriptmdlcb

--- Return a Lua table with mesh info.
-- Contains "length" element which contains tris length
-- and data of each tri. Basically looks like this:<br/>
-- table -> {<br/>
--     length -> 3<br/>
--     0 -> { a -> A, b -> B, c -> C }<br/>
--     1 -> { a -> A, b -> B, c -> C }<br/>
--     2 -> { a -> A, b -> B, c -> C }<br/>
-- }<br/>
-- @param n Model name.
-- @return The table with mesh info.
-- @class function
-- @name mdl.mesh
mdl.mesh = CAPI.mdlmesh

--- This table contains all methods meant
-- for manipulating with obj model format.
-- @class table
-- @name obj
obj = {}

--- Load a model.
-- @param mdl Model name.
-- @class function
-- @name obj.load
obj.load = CAPI.objload

--- Set model skin.
-- @param n Name of the mesh.
-- @param t Name of the texture.
-- @param m Name of masks.
-- @param x Envmap max intensity.
-- @param i Envmap min intensity.
-- @class function
-- @name obj.skin
obj.skin = CAPI.objskin

--- Set model bump map.
-- @param n Name of the mesh.
-- @parma b Name of the bump map texture.
-- @param s Name of the skin.
-- @class function
-- @name obj.bumpmap
obj.bumpmap = CAPI.objbumpmap

--- Set model env map.
-- @param n Name of the mesh.
-- @param e Name of the env map.
-- @class function
-- @name obj.envmap
obj.envmap = CAPI.objenvmap

--- Set model specular intensity. See mdlspec.
-- @param n Mesh name.
-- @param s Specular intensity.
-- @see mdl.spec
-- @class function
-- @name obj.spec
obj.spec = CAPI.objspec

--- Set model pitch. Controls how a model responds to its pitch.
-- Clamping is applied like this: clamp(pitch * s + o, m, n)
-- @param b Name of the bone which the pitch anim is applied to, as well as all bones in the sub-tree below it.
-- @param s Pitch in degrees is scaled by this.
-- @param o The pitch offset.
-- @param m Minimal pitch offset clamp.
-- @param n Maximal pitch offset clamp.
-- @class function
-- @name obj.pitch
obj.pitch = CAPI.objpitch

--- Set model ambience. See mdlambient.
-- @param n Mesh name.
-- @param a Ambience.
-- @see mdl.ambient
-- @class function
-- @name obj.ambient
obj.ambient = CAPI.objambient

--- See mdlglow.
-- @param n Mesh name.
-- @param g Glow factor.
-- @see mdl.glow
-- @class function
-- @name obj.glow
obj.glow = CAPI.objglow

--- See mdlglare.
-- @param n Mesh name.
-- @param s Spec glare.
-- @param g Glow glare.
-- @see mdl.glare
-- @class function
-- @name obj.glare
obj.glare = CAPI.objglare

--- See mdlalphatest.
-- @param n Mesh name.
-- @param c Cutoff.
-- @see mdl.alphatest
-- @class function
-- @name obj.alphatest
obj.alphatest = CAPI.objalphatest

--- See mdlalphablend.
-- @param n Mesh name.
-- @param b Alpha blend switch.
-- @see mdl.alphablend
-- @class function
-- @name obj.alphablend
obj.alphablend = CAPI.objalphablend

--- See mdlcullface.
-- @param n Mesh name.
-- @param c Back face culling switch.
-- @see mdl.cullface
-- @class function
-- @name obj.cullface
obj.cullface = CAPI.objcullface

--- See mdlfullbright.
-- @param n Mesh name.
-- @param f Fullbright factor.
-- @see mdl.fullbright
-- @class function
-- @name obj.fullbright
obj.fullbright = CAPI.objfullbright

--- See mdlshader.
-- @param n Mesh name.
-- @param s Shader name.
-- @see mdl.shader
-- @class function
-- @name obj.shader
obj.shader = CAPI.objshader

--- Scroll a model skin at X and Y Hz along the X and Y axes of the skin.
-- @param n Mesh name.
-- @param X X axis scroll frequency.
-- @param Y Y axis scroll frequency.
-- @class function
-- @name obj.scroll
obj.scroll = CAPI.objscroll

--- Toggle model noclip.
-- @param n Mesh name.
-- @param c 1 to make model noclip, 0 otherwise.
-- @class function
-- @name obj.noclip
obj.noclip = CAPI.objnoclip

--- This table contains all methods meant
-- for manipulating with md5 model format.
-- @class table
-- @name md5
md5 = {}

--- Set model directory.
-- @param dir Directory.
-- @class function
-- @name md5.dir
md5.dir = CAPI.md5dir

--- Load a model. Skelname is optional name that can be assigned
-- to the skeleton specified in the md5mesh for skeleton sharing,
-- but need not be specified if you do not wish to share the skeleton.
-- This skeleton name must be specified for both the model supplying
-- a skeleton and ana attached model intending to use the skeleton.
-- @param mdl Model name.
-- @param skelname Skeleton name.
-- @class function
-- @name md5.load
md5.load = CAPI.md5load

--- Assign a tag name to bone.
-- @param n Bone name.
-- @param t Tag name.
-- @class function
-- @name md5.tag
md5.tag = CAPI.md5tag

--- Set model pitch. Controls how a model responds to its pitch.
-- Clamping is applied like this: clamp(pitch * s + o, m, n)
-- @param mn Mesh name.
-- @param b Name of the bone which the pitch anim is applied to, as well as all bones in the sub-tree below it.
-- @param s Pitch in degrees is scaled by this.
-- @param o The pitch offset.
-- @param m Minimal pitch offset clamp.
-- @param n Maximal pitch offset clamp.
-- @class function
-- @name md5.pitch
md5.pitch = CAPI.md5pitch

--- Set adjustment for the model.
-- @param n Model name.
-- @param yaw Yaw.
-- @param pitch Pitch.
-- @param roll Roll.
-- @param tx X translation of model center.
-- @param ty Y translation of model center.
-- @param tz Z translation of model center.
-- @class function
-- @name md5.adjust
md5.adjust = CAPI.md5adjust

--- Set model skin.
-- @param n Name of the mesh.
-- @param t Name of the texture.
-- @param m Name of masks.
-- @param x Envmap max intensity.
-- @param i Envmap min intensity.
-- @class function
-- @name md5.skin
md5.skin = CAPI.md5skin

--- Set model specular intensity. See mdlspec.
-- @param n Mesh name.
-- @param s Specular intensity.
-- @see mdl.spec
-- @class function
-- @name md5.spec
md5.spec = CAPI.md5spec

--- Set model ambience. See mdlambient.
-- @param n Mesh name.
-- @param a Ambience.
-- @see mdl.ambient
-- @class function
-- @name md5.ambient
md5.ambient = CAPI.md5ambient

--- See mdlglow.
-- @param n Mesh name.
-- @param g Glow factor.
-- @see mdl.glow
-- @class function
-- @name md5.glow
md5.glow = CAPI.md5glow

--- See mdlglare.
-- @param n Mesh name.
-- @param s Spec glare.
-- @param g Glow glare.
-- @see mdl.glare
-- @class function
-- @name md5.glare
md5.glare = CAPI.md5glare

--- See mdlalphatest.
-- @param n Mesh name.
-- @param c Cutoff.
-- @see mdl.alphatest
-- @class function
-- @name md5.alphatest
md5.alphatest = CAPI.md5alphatest

--- See mdlalphablend.
-- @param n Mesh name.
-- @param b Alpha blend switch.
-- @see mdl.alphablend
-- @class function
-- @name md5.alphablend
md5.alphablend = CAPI.md5alphablend

--- See mdlcullface.
-- @param n Mesh name.
-- @param c Back face culling switch.
-- @see mdl.cullface
-- @class function
-- @name md5.cullface
md5.cullface = CAPI.md5cullface

--- Set model env map.
-- @param n Name of the mesh.
-- @param e Name of the env map.
-- @class function
-- @name md5.envmap
md5.envmap = CAPI.md5envmap

--- Set model bump map.
-- @param n Name of the mesh.
-- @parma b Name of the bump map texture.
-- @param s Name of the skin.
-- @class function
-- @name md5.bumpmap
md5.bumpmap = CAPI.md5bumpmap

--- See mdlfullbright.
-- @param n Mesh name.
-- @param f Fullbright factor.
-- @see mdl.fullbright
-- @class function
-- @name md5.fullbright
md5.fullbright = CAPI.md5fullbright

--- See mdlshader.
-- @param n Mesh name.
-- @param s Shader name.
-- @see mdl.shader
-- @class function
-- @name md5.shader
md5.shader = CAPI.md5shader

--- Scroll a model skin at X and Y Hz along the X and Y axes of the skin.
-- @param n Mesh name.
-- @param X X axis scroll frequency.
-- @param Y Y axis scroll frequency.
-- @class function
-- @name md5.scroll
md5.scroll = CAPI.md5scroll

--- Start a new animation part that will include a bone specified by
-- argument and all its sub-bones. This effectively splits animations up
-- at the bone specified by argument, such that each animation part
-- animates as it were a separate model. Note that a new animation part
-- has no animations (does not inherit any from previous animation part).
-- After a load, an implicit animation part is started that involves all bones
-- not used by other animation parts. Each model currently may only have two
-- animation parts, including the implicit animation part, so this command
-- may only be used once and only once per mesh loaded. However, you do not
-- need to specify any animation parts explicitly and acn just use default part
-- for all animations, if you do not wish the animations to be split up / blended
-- together.
-- @param b The bone name.
-- @class function
-- @name md5.animpart
md5.animpart = CAPI.md5animpart

--- This assigns a new animation to the current animation part of last loaded model.
-- First argument specifies the animation to define. Any of following names can be used:
-- dying, dead, pain, idle, forward, backward, left, right, hold 1 ... hold 7,
-- attack1 ... attack7, jump, sink, swim, edit, lag, taunt, win, lose, gun shoot,
-- gun idle, vwep shoot, vwep idle, mapmodel, trigger. Second argument specifies the
-- animation file. Third argument is optional and specifies frames per second for the
-- animation, defaulting to 10. Fourth argument is optional and specifies priority
-- for the animation, defaulting to 0. A character can have up to 2 animations
-- sumultaneously playing - a primary animation and a secondary animation.
-- If a character model defines the primary animation, it will be used, otherwise
-- secondary animation will be used if it's available. Primary animations are:
-- dying, dead, pain, hold 1 ... hold 7, attack 1 ... attack 7, edit, lag, taunt, win, lose.
-- Secondary animations are: idle, forward, backward, left, right, jump, sink, swim.
-- @param animname Animation name.
-- @param animfile Animation file.
-- @param animfps Animation frames per second.
-- @param animpri Animation priority.
-- @class function
-- @name md5.anim
md5.anim = CAPI.md5anim

--- This links two models together. Every model you load has an ID. The first model you load
-- has ID 0, the second has ID 1, and so on, those IDs are now used to identify the models
-- and link them together. First argument specifies ID of the parent, second the child ID.
-- Third argument specifies name of the tag that specifies at which vertex the models should
-- be linked. Rest of arguments are optional translation for this link.
-- @param p Parent ID.
-- @param c Child ID.
-- @param t Tag.
-- @param x X translation. (optional)
-- @param y Y translation. (optional)
-- @param z Z translation. (optional)
-- @class function
-- @name md5.link
md5.link = CAPI.md5link

--- Toggle model noclip.
-- @param n Mesh name.
-- @param c 1 to make model noclip, 0 otherwise.
-- @class function
-- @name md5.noclip
md5.noclip = CAPI.md5noclip

--- This table contains all methods meant
-- for manipulating with iqm model format.
-- @class table
-- @name iqm
iqm = {}

--- Set model directory.
-- @param dir Directory.
-- @class function
-- @name iqm.dir
iqm.dir = CAPI.iqmdir

--- Load a model.
-- @param mdl Model name.
-- @class function
-- @name iqm.load
iqm.load = CAPI.iqmload

--- Assign a tag name to bone.
-- @param n Bone name.
-- @param t Tag name.
-- @class function
-- @name iqm.tag
iqm.tag = CAPI.iqmtag

--- Set model pitch. Controls how a model responds to its pitch.
-- Clamping is applied like this: clamp(pitch * s + o, m, n)
-- @param mn Mesh name.
-- @param b Name of the bone which the pitch anim is applied to, as well as all bones in the sub-tree below it.
-- @param s Pitch in degrees is scaled by this.
-- @param o The pitch offset.
-- @param m Minimal pitch offset clamp.
-- @param n Maximal pitch offset clamp.
-- @class function
-- @name iqm.pitch
iqm.pitch = CAPI.iqmpitch

--- Set adjustment for the model.
-- @param n Model name.
-- @param yaw Yaw.
-- @param pitch Pitch.
-- @param roll Roll.
-- @param tx X translation of model center.
-- @param ty Y translation of model center.
-- @param tz Z translation of model center.
-- @class function
-- @name iqm.adjust
iqm.adjust = CAPI.iqmadjust

--- Set model skin.
-- @param n Name of the mesh.
-- @param t Name of the texture.
-- @param m Name of masks.
-- @param x Envmap max intensity.
-- @param i Envmap min intensity.
-- @class function
-- @name iqm.skin
iqm.skin = CAPI.iqmskin

--- Set model specular intensity. See mdlspec.
-- @param n Mesh name.
-- @param s Specular intensity.
-- @see mdl.spec
-- @class function
-- @name iqm.spec
iqm.spec = CAPI.iqmspec

--- Set model ambience. See mdlambient.
-- @param n Mesh name.
-- @param a Ambience.
-- @see mdl.ambient
-- @class function
-- @name iqm.ambient
iqm.ambient = CAPI.iqmambient

--- See mdlglow.
-- @param n Mesh name.
-- @param g Glow factor.
-- @see mdl.glow
-- @class function
-- @name iqm.glow
iqm.glow = CAPI.iqmglow

--- See mdlglare.
-- @param n Mesh name.
-- @param s Spec glare.
-- @param g Glow glare.
-- @see mdl.glare
-- @class function
-- @name iqm.glare
iqm.glare = CAPI.iqmglare

--- See mdlalphatest.
-- @param n Mesh name.
-- @param c Cutoff.
-- @see mdl.alphatest
-- @class function
-- @name iqm.alphatest
iqm.alphatest = CAPI.iqmalphatest

--- See mdlalphablend.
-- @param n Mesh name.
-- @param b Alpha blend switch.
-- @see mdl.alphablend
-- @class function
-- @name iqm.alphablend
iqm.alphablend = CAPI.iqmalphablend

--- See mdlcullface.
-- @param n Mesh name.
-- @param c Back face culling switch.
-- @see mdl.cullface
-- @class function
-- @name iqm.cullface
iqm.cullface = CAPI.iqmcullface

--- Set model env map.
-- @param n Name of the mesh.
-- @param e Name of the env map.
-- @class function
-- @name iqm.envmap
iqm.envmap = CAPI.iqmenvmap

--- Set model bump map.
-- @param n Name of the mesh.
-- @parma b Name of the bump map texture.
-- @param s Name of the skin.
-- @class function
-- @name iqm.bumpmap
iqm.bumpmap = CAPI.iqmbumpmap

--- See mdlfullbright.
-- @param n Mesh name.
-- @param f Fullbright factor.
-- @see mdl.fullbright
-- @class function
-- @name iqm.fullbright
iqm.fullbright = CAPI.iqmfullbright

--- See mdlshader.
-- @param n Mesh name.
-- @param s Shader name.
-- @see mdl.shader
-- @class function
-- @name iqm.shader
iqm.shader = CAPI.iqmshader

--- Scroll a model skin at X and Y Hz along the X and Y axes of the skin.
-- @param n Mesh name.
-- @param X X axis scroll frequency.
-- @param Y Y axis scroll frequency.
-- @class function
-- @name iqm.scroll
iqm.scroll = CAPI.iqmscroll

--- Start a new animation part that will include a bone specified by
-- argument and all its sub-bones. This effectively splits animations up
-- at the bone specified by argument, such that each animation part
-- animates as it were a separate model. Note that a new animation part
-- has no animations (does not inherit any from previous animation part).
-- After a load, an implicit animation part is started that involves all bones
-- not used by other animation parts. Each model currently may only have two
-- animation parts, including the implicit animation part, so this command
-- may only be used once and only once per mesh loaded. However, you do not
-- need to specify any animation parts explicitly and acn just use default part
-- for all animations, if you do not wish the animations to be split up / blended
-- together.
-- @param b The bone name.
-- @class function
-- @name iqm.animpart
iqm.animpart = CAPI.iqmanimpart

--- This assigns a new animation to the current animation part of last loaded model.
-- First argument specifies the animation to define. Any of following names can be used:
-- dying, dead, pain, idle, forward, backward, left, right, hold 1 ... hold 7,
-- attack1 ... attack7, jump, sink, swim, edit, lag, taunt, win, lose, gun shoot,
-- gun idle, vwep shoot, vwep idle, mapmodel, trigger. Second argument specifies the
-- animation file. Third argument is optional and specifies frames per second for the
-- animation, defaulting to 10. Fourth argument is optional and specifies priority
-- for the animation, defaulting to 0. A character can have up to 2 animations
-- sumultaneously playing - a primary animation and a secondary animation.
-- If a character model defines the primary animation, it will be used, otherwise
-- secondary animation will be used if it's available. Primary animations are:
-- dying, dead, pain, hold 1 ... hold 7, attack 1 ... attack 7, edit, lag, taunt, win, lose.
-- Secondary animations are: idle, forward, backward, left, right, jump, sink, swim.
-- @param animname Animation name.
-- @param animfile Animation file.
-- @param animfps Animation frames per second.
-- @param animpri Animation priority.
-- @class function
-- @name iqm.anim
iqm.anim = CAPI.iqmanim

--- This links two models together. Every model you load has an ID. The first model you load
-- has ID 0, the second has ID 1, and so on, those IDs are now used to identify the models
-- and link them together. First argument specifies ID of the parent, second the child ID.
-- Third argument specifies name of the tag that specifies at which vertex the models should
-- be linked. Rest of arguments are optional translation for this link.
-- @param p Parent ID.
-- @param c Child ID.
-- @param t Tag.
-- @param x X translation. (optional)
-- @param y Y translation. (optional)
-- @param z Z translation. (optional)
-- @class function
-- @name iqm.link
iqm.link = CAPI.iqmlink

--- Toggle model noclip.
-- @param n Mesh name.
-- @param c 1 to make model noclip, 0 otherwise.
-- @class function
-- @name iqm.noclip
iqm.noclip = CAPI.iqmnoclip

--- This table contains all methods meant
-- for manipulating with smd model format.
-- @class table
-- @name smd
smd = {}

--- Set model directory.
-- @param dir Directory.
-- @class function
-- @name smd.dir
smd.dir = CAPI.smddir

--- Load a model.
-- @param mdl Model name.
-- @class function
-- @name smd.load
smd.load = CAPI.smdload

--- Assign a tag name to bone.
-- @param n Bone name.
-- @param t Tag name.
-- @class function
-- @name smd.tag
smd.tag = CAPI.smdtag

--- Set model pitch. Controls how a model responds to its pitch.
-- Clamping is applied like this: clamp(pitch * s + o, m, n)
-- @param mn Mesh name.
-- @param b Name of the bone which the pitch anim is applied to, as well as all bones in the sub-tree below it.
-- @param s Pitch in degrees is scaled by this.
-- @param o The pitch offset.
-- @param m Minimal pitch offset clamp.
-- @param n Maximal pitch offset clamp.
-- @class function
-- @name smd.pitch
smd.pitch = CAPI.smdpitch

--- Set adjustment for the model.
-- @param n Model name.
-- @param yaw Yaw.
-- @param pitch Pitch.
-- @param roll Roll.
-- @param tx X translation of model center.
-- @param ty Y translation of model center.
-- @param tz Z translation of model center.
-- @class function
-- @name smd.adjust
smd.adjust = CAPI.smdadjust

--- Set model skin.
-- @param n Name of the mesh.
-- @param t Name of the texture.
-- @param m Name of masks.
-- @param x Envmap max intensity.
-- @param i Envmap min intensity.
-- @class function
-- @name smd.skin
smd.skin = CAPI.smdskin

--- Set model specular intensity. See mdlspec.
-- @param n Mesh name.
-- @param s Specular intensity.
-- @see mdl.spec
-- @class function
-- @name smd.spec
smd.spec = CAPI.smdspec

--- Set model ambience. See mdlambient.
-- @param n Mesh name.
-- @param a Ambience.
-- @see mdl.ambient
-- @class function
-- @name smd.ambient
smd.ambient = CAPI.smdambient

--- See mdlglow.
-- @param n Mesh name.
-- @param g Glow factor.
-- @see mdl.glow
-- @class function
-- @name smd.glow
smd.glow = CAPI.smdglow

--- See mdlglare.
-- @param n Mesh name.
-- @param s Spec glare.
-- @param g Glow glare.
-- @see mdl.glare
-- @class function
-- @name smd.glare
smd.glare = CAPI.smdglare

--- See mdlalphatest.
-- @param n Mesh name.
-- @param c Cutoff.
-- @see mdl.alphatest
-- @class function
-- @name smd.alphatest
smd.alphatest = CAPI.smdalphatest

--- See mdlalphablend.
-- @param n Mesh name.
-- @param b Alpha blend switch.
-- @see mdl.alphablend
-- @class function
-- @name smd.alphablend
smd.alphablend = CAPI.smdalphablend

--- See mdlcullface.
-- @param n Mesh name.
-- @param c Back face culling switch.
-- @see mdl.cullface
-- @class function
-- @name smd.cullface
smd.cullface = CAPI.smdcullface

--- Set model env map.
-- @param n Name of the mesh.
-- @param e Name of the env map.
-- @class function
-- @name smd.envmap
smd.envmap = CAPI.smdenvmap

--- Set model bump map.
-- @param n Name of the mesh.
-- @parma b Name of the bump map texture.
-- @param s Name of the skin.
-- @class function
-- @name smd.bumpmap
smd.bumpmap = CAPI.smdbumpmap

--- See mdlfullbright.
-- @param n Mesh name.
-- @param f Fullbright factor.
-- @see mdl.fullbright
-- @class function
-- @name smd.fullbright
smd.fullbright = CAPI.smdfullbright

--- See mdlshader.
-- @param n Mesh name.
-- @param s Shader name.
-- @see mdl.shader
-- @class function
-- @name smd.shader
smd.shader = CAPI.smdshader

--- Scroll a model skin at X and Y Hz along the X and Y axes of the skin.
-- @param n Mesh name.
-- @param X X axis scroll frequency.
-- @param Y Y axis scroll frequency.
-- @class function
-- @name smd.scroll
smd.scroll = CAPI.smdscroll

--- Start a new animation part that will include a bone specified by
-- argument and all its sub-bones. This effectively splits animations up
-- at the bone specified by argument, such that each animation part
-- animates as it were a separate model. Note that a new animation part
-- has no animations (does not inherit any from previous animation part).
-- After a load, an implicit animation part is started that involves all bones
-- not used by other animation parts. Each model currently may only have two
-- animation parts, including the implicit animation part, so this command
-- may only be used once and only once per mesh loaded. However, you do not
-- need to specify any animation parts explicitly and acn just use default part
-- for all animations, if you do not wish the animations to be split up / blended
-- together.
-- @param b The bone name.
-- @class function
-- @name smd.animpart
smd.animpart = CAPI.smdanimpart

--- This assigns a new animation to the current animation part of last loaded model.
-- First argument specifies the animation to define. Any of following names can be used:
-- dying, dead, pain, idle, forward, backward, left, right, hold 1 ... hold 7,
-- attack1 ... attack7, jump, sink, swim, edit, lag, taunt, win, lose, gun shoot,
-- gun idle, vwep shoot, vwep idle, mapmodel, trigger. Second argument specifies the
-- animation file. Third argument is optional and specifies frames per second for the
-- animation, defaulting to 10. Fourth argument is optional and specifies priority
-- for the animation, defaulting to 0. A character can have up to 2 animations
-- sumultaneously playing - a primary animation and a secondary animation.
-- If a character model defines the primary animation, it will be used, otherwise
-- secondary animation will be used if it's available. Primary animations are:
-- dying, dead, pain, hold 1 ... hold 7, attack 1 ... attack 7, edit, lag, taunt, win, lose.
-- Secondary animations are: idle, forward, backward, left, right, jump, sink, swim.
-- @param animname Animation name.
-- @param animfile Animation file.
-- @param animfps Animation frames per second.
-- @param animpri Animation priority.
-- @class function
-- @name smd.anim
smd.anim = CAPI.smdanim

--- This links two models together. Every model you load has an ID. The first model you load
-- has ID 0, the second has ID 1, and so on, those IDs are now used to identify the models
-- and link them together. First argument specifies ID of the parent, second the child ID.
-- Third argument specifies name of the tag that specifies at which vertex the models should
-- be linked. Rest of arguments are optional translation for this link.
-- @param p Parent ID.
-- @param c Child ID.
-- @param t Tag.
-- @param x X translation. (optional)
-- @param y Y translation. (optional)
-- @param z Z translation. (optional)
-- @class function
-- @name smd.link
smd.link = CAPI.smdlink

--- Toggle model noclip.
-- @param n Mesh name.
-- @param c 1 to make model noclip, 0 otherwise.
-- @class function
-- @name smd.noclip
smd.noclip = CAPI.smdnoclip

--- This table contains
-- ragdoll manipulation methods.
-- @class table
-- @name rd
rd = {}

--- Specify a ragdoll vert.
-- @param x X coord.
-- @param y Y coord.
-- @param z Z coord.
-- @param r Radius.
-- @class function
-- @name rd.name
rd.vert = CAPI.rdvert

--- Specify rd eye.
-- @param v Ragdoll eye (integer)
-- @class function
-- @name rd.name
rd.eye = CAPI.rdeye

--- Specify a ragdoll tri.
-- @param v1 V1
-- @param v2 V2
-- @param v3 V3
-- @class function
-- @name rd.name
rd.tri = CAPI.rdtri

--- Specify a ragdoll joint.
-- @param n N
-- @param t T
-- @param v1 V1
-- @param v2 V2
-- @param v3 V3
-- @class function
-- @name rd.name
rd.joint = CAPI.rdjoint

--- Set ragdoll distance limit.
-- @param v1 V1
-- @param v2 V2
-- @param mindist Minimal distance.
-- @param maxdist Maximal distance.
-- @class function
-- @name rd.name
rd.limitdist = CAPI.rdlimitdist

--- Limit rotation in ragdoll.
-- @param t1 T1
-- @param t2 T2
-- @param m Maximal angle.
-- @param qx qx
-- @param qy qy
-- @param qz qz
-- @param qw qw
-- @class function
-- @name rd.name
rd.limitrot = CAPI.rdlimitrot

--- Turn on/off ragdoll joint animation.
-- @param v 1 or 0.
-- @class function
-- @name rd.name
rd.animjoints = CAPI.rdanimjoints
