--[[!
    File: base/base_models.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features model interface. Some bits of documentation
        are taken from "Sauerbraten model reference".
]]

local base = _G

--[[!
    Package: model
    This module controls models. OctaForge currently supports 4 model formats,
    md5, smd, iqm and obj. This as well handles some variables for culling,
    shadowing etc., general model manipulation and ragdoll control.
]]
module("model", package.seeall)

--[[!
    Variable: CULL_VFC
    View frustrum culling flag for <render>.

    See also:
        <CULL_DIST>
        <CULL_OCCLUDED>
        <CULL_QUERY>
]]
CULL_VFC = math.lsh(1, 0)

--[[!
    Variable: CULL_DIST
    Distance culling flag for <render>.

    See also:
        <CULL_VFC>
        <CULL_OCCLUDED>
        <CULL_QUERY>
]]
CULL_DIST = math.lsh(1, 1)

--[[!
    Variable: CULL_OCCLUDED
    Occlusion culling flag for <render>.

    See also:
        <CULL_VFC>
        <CULL_DIST>
        <CULL_QUERY>
]]
CULL_OCCLUDED = math.lsh(1, 2)

--[[!
    Variable: CULL_QUERY
    Hardware occlusion queries flag for <render>.

    See also:
        <CULL_VFC>
        <CULL_DIST>
        <CULL_OCCLUDED>
]]
CULL_QUERY = math.lsh(1, 3)

--[[!
    Variable: SHADOW
    A flag that enables shadowing of mapmodels for <render>.
]]
SHADOW = math.lsh(1, 4)

--[[!
    Variable: DYNSHADOW
    A flag that gives model a dynamic shadow for <render>.
]]
DYNSHADOW = math.lsh(1, 5)

--[[!
    Variable: LIGHT
    A flag for <render> that makes model lit. See also
    <DYNLIGHT>.
]]
LIGHT = math.lsh(1, 6)

--[[!
    Variable: DYNLIGHT
    See <LIGHT>, this is for dynlights (see <effects.dynamic_light>).
]]
DYNLIGHT = math.lsh(1, 7)

--[[!
    Variable: FULLBRIGHT
    A flag for <render> that gives the model fullbright.
]]
FULLBRIGHT = math.lsh(1, 8)

--[[!
    Variable: LIGHT_FAST
    A flag for <render> that gives the model a cheap lighting.
]]
LIGHT_FAST = math.lsh(1, 10)

--[[!
    Variable: HUD
    Use this <render> flag for HUD models. Affects some lighting
    capabilities.
]]
HUD = math.lsh(1, 11)

--[[!
    Variable: GHOST
    Use this <render> flag to make the model half opaque.
]]
GHOST = math.lsh(1, 12)

--[[!
    Function: clear
    Clears a model with a name given by the argument. Name is a
    path relative to the data/models directory (i.e. "foo/bar"
    means "data/models/foo/bar").
]]
clear = CAPI.clearmodel

--[[!
    Function: preload
    Preloads a model with a name given by the argument. Useful for
    pre-caching models you know will be loaded. Name is a path
    relative to the data/models directory (i.e. "foo/bar" means
    "data/models/foo/bar").
]]
preload = CAPI.preloadmodel

--[[!
    Function: reload
    See <clear>. The argument is the same, this basically clears
    and loads again.
]]
reload = CAPI.reloadmodel

--[[!
    Function: render
    Renders a model.

    Parameters:
        entity - the entity the model belongs to.
        name - name of the model we're loading. It's a path
        relative to the data/models directory (i.e. "foo/bar" means
        "data/models/foo/bar").
        animation - model animation, see <actions>, the ANIM_*
        variables.
        position - position of the model in the world represented
        as <vec3>.
        yaw - model yaw.
        pitch - model pitch.
        flags - various model flags for i.e. occlusion and lighting,
        see the flags above. Use <math.bor> to join them.
        base_time - entity's start_time property.
]]
render = CAPI.rendermodel

--[[!
    Function: find_animations
    Finds all animations of the model given by the argument (string,
    in the same format as in <render>) and returns them as an array
    of numbers (see <actions>, the ANIM_* variables).
]]
find_animations = CAPI.findanims

--[[!
    Function: attachment
    Given two strings, first one being a model tag and second one
    being a model attachment, this function returns a full
    attachment string that can be then used in "attachments"
    property of entities.
]]
function attachment(t, n)
    assert(not string.find(t, ","))
    assert(not string.find(n, ","))
    return t .. "," .. n
end

--[[!
    Function: get_bounding_box
    Returns a Lua table in format

    (start code)
        {
            center = center,
            radius = radius
        }
    (end)

    where "center" and "radius" are <vec3>'s representing
    bounding box of a model with a name given by the argument.

    If the model can't be loaded, nil gets returned.
]]
get_bounding_box = CAPI.scriptmdlbb

--[[!
    Function: get_collision_box
    See <get_bounding_box>.
]]
get_collision_box = CAPI.scriptmdlcb

--[[!
    Function: get_model_info
    Returns a Lua table with the information about
    model with a name given by the argument.

    The return value is a table and contains the amount
    of triangles and information about each triangle.

    Example:
        (start code)
            {
                length = 3
                0 = { a = A, b = B, c = C }
                1 = { a = A, b = B, c = C }
                2 = { a = A, b = B, c = C }
            }
        (end)
]]
get_model_info = CAPI.mdlmesh

--[[!
    Class: all
    This contains various functions meant to be used in MODELFORMAT.lua
    that affect the whole model, not just a single mesh of it.
]]
all = {
    --[[!
        Function: get_name
        Returns the name of currently loading model.
    ]]
    get_name = CAPI.mdlname,

    --[[!
        Function: alpha_test
        Controls the cut-off threshold given by the argument at which alpha
        channel skins will discard pixels where alpha is less than the given
        cut-off. The cut-off is a floating point value in range of 0 to 1,
        defaulting to 0.9.
    ]]
    alpha_test = CAPI.mdlalphatest,

    --[[!
        Function: alpha_blend
        Controls whether a model with an alpha-channel skin will alpha blend
        (defaults to true).
    ]]
    alpha_blend = CAPI.mdlalphablend,

    --[[!
        Function: alpha_depth
        Controls the model alpha depth (defaults to true).
    ]]
    alpha_depth = CAPI.mdlalphadepth,

    --[[!
        Controls the model bounding box. If not set, bounding box
        is generated from the model's geometry.

        Parameters:
            radius - bounding box radius.
            height - bounding box height.
            eye_height - fraction of the model's height to be used
            as eye height (defaults to 0.9).
    ]]
    bounding_box = CAPI.mdlbb,

    --[[!
        Function: extend_bounding_box
        Accepts a <vec3> argument that is then added (<vec3.add>) to
        the calculated bounding box vector.
    ]]
    extend_bounding_box = CAPI.extendbb,

    --[[!
        Function: scale
        Scales the model's size to be ARG percent of its default size.
    ]]
    scale = CAPI.mdlscale,

    --[[!
        Function: specularity
        ARG is the specular intensity (not given or 0 defaults to 100),
        good for metal/plastics or anything shiny, use lower values
        like 50 for wood etc., -1 means off entirely.
    ]]
    specularity = CAPI.mdlspec,

    --[[!
        Function: glow
        ARG is the glowmap scale (not given or 0 defaults to 300, -1
        means off entirely), such that the glow is ARG percent of the
        diffuse skin color.
    ]]
    glow = CAPI.mdlglow,

    --[[!
        Function: glare
        ARG1 and ARG2 are floating point values that scale the amount
        of glare generated by specular light and glare, respectively
        (defaults to 1 and 1).
    ]]
    glare = CAPI.mdlglare,

    --[[!
        Function: ambient
        ARG is the percent of the ambient light that should be used
        for shading. Not given or 0 defaults to 30%, -1 means no ambient.
    ]]
    ambient = CAPI.mdlambient,

    --[[!
        Function: cull_back_faces
        Providing it false argument disables back face culling for the
        model. If unspecified, it's left true.
    ]]
    cull_back_faces = CAPI.mdlcullface,

    --[[!
        Function: depth_offset
        True boolean argument ARG turns on depth offset, it's left off
        by default.
    ]]
    depth_offset = CAPI.mdldepthoffset,

    --[[!
        Function: fullbright
        Argument N makes the model use constant lighting level of N
        instead of normal lighting. N is a floating point value
        on a scale of 0 to 1.
    ]]
    fullbright = CAPI.mdlfullbright,

    --[[!
        Function: spin
        Simple spin animation that yaws the model by ARG degrees per
        second.
    ]]
    spin = CAPI.mdlspin,

    --[[!
        Function: envmap
        Sets the environment map used for the model. If unspecified, the
        model will use the closest "envmap" entity or skybox, if none is
        available.

        Parameters:
            max, min - if min is non-zero, then the blue channel of the
            masks is interpreted as a chrome map. Max (maximum envmap
            intensity) and min (minimum envmap intensity, defaults to 0)
            are floating point values in the range of 0 to 1 and specify
            a range in which the envmapping intensity will vary based on
            a viewing angle (a Fresnel term that is maximal at glancing
            angles, minimal when viewed dead-on). The intensity, after
            scaled into this range, is then multiplied by the chrome map.
            path - envmap path, optional, same as for <skybox>.
    ]]
    envmap = CAPI.mdlenvmap,

    --[[!
        Function: shader
        Argument specifies the name of the shader to use for rendering
        the model (defaults to "stdmodel").
    ]]
    shader = CAPI.mdlshader,

    --[[!
        Function: translate_center
        Translates the model's center by argument, which is a <vec3>
        with x, y, z represented in model units (may use floating point).
    ]]
    translate_center = CAPI.mdltrans,

    --[[!
        Function: yaw
        Offsets the model's yaw by ARG degrees. See also <pitch>.
    ]]
    yaw = CAPI.mdlyaw,

    --[[!
        Function: pitch
        Offsets the model's pitch by ARG degrees. See also <yaw>.
    ]]
    pitch = CAPI.mdlpitch,

    --[[!
        Function: shadow
        Controls whether a <mapmodel> will cast shadows (defaults
        to true).
    ]]
    shadow = CAPI.mdlshadow,

    --[[!
        Function: collide
        Controls whether the model will collide with the environment.
        Defaults to true.
    ]]
    collide = CAPI.mdlcollide,

    --[[!
        Function: circular_collision
        Controls whether the collision box will be cylinder rather
        than a block. Defaults to false.
    ]]
    circular_collision = CAPI.mdlellipsecollide,

    --[[!
        Function: entity_collision_box
        Controls whether the model's entity will control its
        collision box. Used by <area_trigger> (which inherits
        from <mapmodel>). Defaults to false.
    ]]
    entity_collision_box = CAPI.mdlperentitycollisionboxes
}

--[[!
    Class: md5
    This table contains every function related somehow to MD5 (id tech 4)
    model format. <iqm> and <smd> have equivalent functions. Please note
    that these functions are meant to be called only from md5.lua script
    for a model.

    Text taken from Sauerbraten model reference:
        MD5 models require a proper configuration to function; make sure your
        exporter properly exports mesh names in the MD5 file so that these can
        be referenced in the configuration file (the Blender exporter does not
        export these, but a fixed Blender MD5 exporter can be gotten from the
        Cube wiki, <http://cube.wikispaces.com/Blender+to+MD5+to+Sauerbraten>).

        Make sure no more than 4 blend weights are used per vertex, any extra
        blend weights will be dropped silently. The skeleton should use no more
        than 256 bones, and less than 70 or so bones should be used if you wish
        the model to be skeletally animated on the GPU. To optimize animation
        of the model on both CPU and GPU, keep the number of blend weights per
        vertex to a minimum. Also, similar combinations of blend weights are
        cached while animating, especially on the CPU, such that if two or
        more vertices use the same blend weights, blending calculations only
        have to be done once for all the vertices - so try and minimize the
        number of distinct combinations of blend weights if possible.

        When animating skeletal models, you should model the animations as a
        single piece for the entire body. In the configuration file, you can
        choose a bone at which to split the model into an upper and lower part
        (via <animation_part>), which allows, for example, the upper body
        movement of one animation to be combined with the lower body movement
        of another animation automatically. The bone at which you split the
        animation up should ideally be a root bone, of which the upper body
        and lower body are separate sub-trees. Rigging the model in this way
        also allows for pitch animation (which also requires selecting a bone
        to pitch at) to take place such as bending at the waist, which
        similarly requires the upper body to be a sub-tree of the bone at
        which the pitch animation will occur.

        The included MD5 support allows for two methods of attaching models to
        another: via tags (by assigning a tag name to a bone with <tag>), or
        by animating multiple models against a common, named skeleton that
        will be shared among all of them (useful for modeling clothing
        attachments and similar items). To use a shared skeleton, you simply
        export all the models with the same skeleton. Animations only need to
        be specified for the base model. A name for the skeleton is specified
        via the <load> command, for both the model exporting the skeleton and
        the models using it. When one of the models is attached to the one
        supplying the skeleton internally, the tag setup is instead ignored
        and the skeleton/animations of the base model are used to animate the
        attachment as if it were a sub-mesh of the base model itself. 
]]
md5 = {
    --[[!
        Function: set_directory
        Sets a model search directory. The name given by the argument works
        the same as for <model.render>.
    ]]
    set_directory = _G["md5"].dir,

    --[[!
        Function: load
        Loads a model, skelname is an optional name that can be assigned
        to the skeleton specified in the md5mesh function for skeleton
        sharing, but isn't needed to be specified if you wish to not
        share the skeleton. The skeleton name must be specified for both
        the model supplying a skeleton and an attached model intending
        to use the skeleton.

        Parameters:
            model - the model filename relative to the model directory
            (either the one with md5.lua or specified by <set_directory>).
            Requires the extension to be specified.
            skelname - see above.
    ]]
    load = _G["md5"].load,

    --[[!
        Function: tag
        Assugns a tag to a bone for either use with <link> or attachment
        of other models via tags.

        Paarameters:
            bone - bone name.
            tag - tag name.
            tr - optional translation (vec3).
            rot - optional rotation (vec3).
    ]]
    tag = _G["md5"].tag,

    --[[!
        Function: pitch
        Sets the model pitch. Controls how a model responds to its pitch.
        Clamping is applied like this: clamp(pitch * scale + offset, min, max).
        By default, all models have scale 1, offset 0, min -360, max 360.

        Parameters:
            name - mesh name.
            bone - name of the bone which the pitch animation is applied to,
            as well as all bones in the sub-tree below it.
            scale - pitch in degrees is scaled by this.
            offset - pitch offset.
            min - minimal pitch offset clamp.
            max - maximal pitch offset clamp.
    ]]
    pitch = _G["md5"].pitch,

    --[[!
        Function: pitch_target
        Sets the pitch target.

        Parameters:
            name - mesh name.
            anim - animation file.
            fo - frame offset (integer).
            min - minimal pitch (float).
            max - maximal pitch (float).
    ]]
    pitch_target = _G["md5"].pitchtarget,

    --[[!
        Function: pitch_correct
        Sets the pitch correct.

        Parameters:
            name - mesh name.
            target - target name.
            scale - pitch scale (float).
            min - minimal pitch (float).
            max - maximal pitch (float).
    ]]
    pitch_correct = _G["md5"].pitchcorrect,

    --[[!
        Function: adjust
        Adjusts the bone with the specified rotations,
        in degrees, on any animations loaded after this
        function is called.

        Parameters:
            bone - bone name.
            yaw - mesh yaw.
            pitch - mesh pitch.
            roll - mesh roll.
            tr - optional translation (<vec3>).
    ]]
    adjust = _G["md5"].adjust,

    --[[!
        Function: skin
        Loads a texture and assigns it to a mesh
        of the last loaded model (<load>).

        Parameters:
            name - mesh name.
            texture - texture filename relative to
            the mesh directory.
            masks - optional, sets a texture for
            spec (red channel) / glow (green channel)
            maps.
            envmax and envmin - maximum envmap intensity, a floating
            point value in the range of 0 to 1 specifying the range in
            which the envmapping intensity will vary based on a viewing
            angle (a Fresnel term that is maximal at glancing angles,
            minimal when viewed dead-on). The intensity, after scaled
            into this range, is then multiplied by the chrome map.
    ]]
    skin = _G["md5"].skin,

    --[[!
        Function: specularity
        A mesh-specific (name passed with the first argument) version
        of <all.specularity>.
    ]]
    specularity = _G["md5"].spec,

    --[[!
        Function: ambient
        A mesh-specific (name passed with the first argument) version
        of <all.ambient>.
    ]]
    ambient = _G["md5"].ambient,

    --[[!
        Function: glow
        A mesh-specific (name passed with the first argument) version
        of <all.glow>.
    ]]
    glow = _G["md5"].glow,

    --[[!
        Function: glare
        A mesh-specific (name passed with the first argument) version
        of <all.glare>.
    ]]
    glare = _G["md5"].glare,

    --[[!
        Function: alpha_test
        A mesh-specific (name passed with the first argument) version
        of <all.alpha_test>.
    ]]
    alpha_test = _G["md5"].alphatest,

    --[[!
        Function: alpha_blend
        A mesh-specific (name passed with the first argument) version
        of <all.alpha_blend>.
    ]]
    alpha_blend = _G["md5"].alphablend,

    --[[!
        Function: cull_back_faces
        A mesh-specific (name passed with the first argument) version
        of <all.cull_back_faces>.
    ]]
    cull_back_faces = _G["md5"].cullface,

    --[[!
        Function: envmap
        Sets the environment map used for the model, where first
        argumetn specifies a pathname for the envmap (same as for
        <skybox>). If unspecified, the mesh will use the closest
        "envmap" entity, or skybox, if none is available (unless
        overriden by <all.envmap>).
    ]]
    envmap = _G["md5"].envmap,

    --[[!
        Function: bumpmap
        Enables bumpmapping for a given mesh in the last loaded model
        (see <load>).

        Parameters:
            name - mesh name.
            skin - see <skin>, this is the skin texture that will be
            used when user's 3D card supports bumpmapping, otherwise
            the one supplied by <skin> will be used and no bumpmapping
            is done. These two skins may be the same. However a diffuse
            skin for bumpmapping should generally have little to no
            directional shading baked into it, whereas flat diffuse
            skins (no bumpmapping) generally should, and this allows
            you to provide a separate skin for the bumpmapping case.
            normalmap - a normal map texture which is used to shade
            the supplied diffuse skin texture.
    ]]
    bumpmap = _G["md5"].bumpmap,

    --[[!
        Function: fullbright
        A mesh-specific (name passed with the first argument) version
        of <all.fullbright>.
    ]]
    fullbright = _G["md5"].fullbright,

    --[[!
        Function: shader
        A mesh-specific (name passed with the first argument) version
        of <all.shader>.
    ]]
    shader = _G["md5"].shader,

    --[[!
        Function: scroll
        Scrolls a model skin at X and Y Hz along the X and Y axes
        of the skin.

        Parameters:
            name - mesh name.
            x - x scroll frequency.
            y - y scroll frequency.
    ]]
    scroll = _G["md5"].scroll,

    --[[!
        Function: animation_part
        Starts a new animation part that will include bone given
        by the argument and all its sub-bones. This effectively
        splits animations up at the given bone, such that each
        animation part animates as it was a separate model. Note
        that a new animation part has no animations (does not
        inherit any from the previous animation part). After a
        <load>, an implicit animation part is started that
        involves all bones not used by other animation parts.

        Each model currently may have 2 animation parts, including
        the implicit default part, so this function may only be
        used once and only once per mesh loaded. However, you do
        not need to specify any animation parts explicitly and can
        just use the default part for all animations if you do not
        wish the animations to be split up / blended together.
    ]]
    animation_part = _G["md5"].animpart,

    --[[!
        Function: animation
        This assigns a new animation to the current animation part
        of the last loaded mesh (<load>).

        Parameters:
            animation - name of the animation to define.
            filename - md5 animation filename.
            fps - optional argument specifying frames per second at
            which to run the animation. If none is specified or is
            0, 10 FPS is the default.
            priority - optional argument specifying a priority for
            the animation (defaults to 0).

        Animation names:
            - dying
            - dead
            - pain
            - idle
            - forward
            - backward
            - left
            - right
            - hold1 .. hold7
            - attack1 .. attack7
            - jump
            - sink
            - swim
            - edit
            - lag
            - taunt
            - win
            - lose
            - gunshoot
            - gunidle
            - vwepshoot
            - vwepidle
            - mapmodel
            - trigger

        A character model will have up to 2 animations simultaneously
        playing, a primary animation and a secondary animation. If a
        character model defines the primary animation, it will be used,
        otherwise the secondary will be used if it is available.

        Primary animations:
            - dying
            - dead
            - pain
            - hold1 .. hold7
            - attack1 .. attack7
            - edit
            - lag
            - taunt
            - win
            - lose

        Secondary animations:
            - idle
            - forward
            - backward
            - left
            - right
            - jump
            - sink
            - swim
    ]]
    animation = _G["md5"].anim,

    --[[!
        Function: link
        Links two meshes together. Every mesh you <load> has an ID.
        The first mesh you load has the ID 0, the second has the ID
        1 and so on, so these IDs are now used to identify the meshes
        and link them together.

        Parameters:
            parent - ID of the parent model.
            child - ID of the child model.
            tag - name of the tag specifying at which vertex the meshes
            should be linked.
            tr - optional translation for the link (<vec3>).
    ]]
    link = _G["md5"].link,

    --[[!
        Function: noclip
        Toggles mesh noclip.

        Parameters:
            name - mesh name.
            noclip - boolean value, defaults to false (solid).
    ]]
    noclip = _G["md5"].noclip
}

--[[!
    Class: iqm
    The Inter-Quake Model format (<http://lee.fov120.com/iqm/>). Used
    identically with <md5>, the only difference is the class name
    and that you define things in iqm.lua instead of md5.lua.

    See also <smd>.
]]
iqm = {
    set_directory   = _G["iqm"].dir,
    load            = _G["iqm"].load,
    tag             = _G["iqm"].tag,
    pitch           = _G["iqm"].pitch,
    pitch_target    = _G["iqm"].pitchtarget,
    pitch_correct   = _G["iqm"].pitchcorrect,
    adjust          = _G["iqm"].adjust,
    skin            = _G["iqm"].skin,
    specularity     = _G["iqm"].spec,
    ambient         = _G["iqm"].ambient,
    glow            = _G["iqm"].glow,
    glare           = _G["iqm"].glare,
    alpha_test      = _G["iqm"].alphatest,
    alpha_blend     = _G["iqm"].alphablend,
    cull_back_faces = _G["iqm"].cullface,
    envmap          = _G["iqm"].envmap,
    bumpmap         = _G["iqm"].bumpmap,
    fullbright      = _G["iqm"].fullbright,
    shader          = _G["iqm"].shader,
    scroll          = _G["iqm"].scroll,
    animation_part  = _G["iqm"].animpart,
    animation       = _G["iqm"].anim,
    link            = _G["iqm"].link,
    noclip          = _G["iqm"].noclip
}

--[[!
    Class: smd
    The Source engine SMD format. Used identically with <md5>, the only
    difference is the class name and that you define things in smd.lua
    instead of md5.lua.

    See also <iqm>.
]]
smd = {
    set_directory   = _G["smd"].dir,
    load            = _G["smd"].load,
    tag             = _G["smd"].tag,
    pitch           = _G["smd"].pitch,
    pitch_target    = _G["smd"].pitchtarget,
    pitch_correct   = _G["smd"].pitchcorrect,
    adjust          = _G["smd"].adjust,
    skin            = _G["smd"].skin,
    specularity     = _G["smd"].spec,
    ambient         = _G["smd"].ambient,
    glow            = _G["smd"].glow,
    glare           = _G["smd"].glare,
    alpha_test      = _G["smd"].alphatest,
    alpha_blend     = _G["smd"].alphablend,
    cull_back_faces = _G["smd"].cullface,
    envmap          = _G["smd"].envmap,
    bumpmap         = _G["smd"].bumpmap,
    fullbright      = _G["smd"].fullbright,
    shader          = _G["smd"].shader,
    scroll          = _G["smd"].scroll,
    animation_part  = _G["smd"].animpart,
    animation       = _G["smd"].anim,
    link            = _G["smd"].link,
    noclip          = _G["smd"].noclip
}

--[[!
    Class: obj
    The Wavefront OBJ format. Functions are called in model's
    obj.lua, see also <md5>, <iqm> and <smd>. The set is simillar
    to <md5>, but as obj models don't support animation, it's
    more limited.
]]
obj = {
    --[[!
        Function: load
        See <md5.load>. Uses only the first argument.
    ]]
    load = _G["obj"].load,
    --[[!
        Function: skin
        Identical with <md5.skin>.
    ]]
    skin = _G["obj"].skin,
    --[[!
        Function: bumpmap
        Identical with <md5.bumpmap>.
    ]]
    bumpmap = _G["obj"].bumpmap,
    --[[!
        Function: envmap
        Identical with <md5.envmap>.
    ]]
    envmap = _G["obj"].envmap,
    --[[!
        Function: specularity
        Identical with <md5.specularity>.
    ]]
    specularity = _G["obj"].spec,
    --[[!
        Function: pitch
        Identical with <md5.pitch>, except
        that the first argument is omitted.
        The function accepts just 4 arguments.
    ]]
    pitch = _G["obj"].pitch,
    --[[!
        Function: ambient
        Identical with <md5.ambient>.
    ]]
    ambient = _G["obj"].ambient,
    --[[!
        Function: glow
        Identical with <md5.glow>.
    ]]
    glow = _G["obj"].glow,
    --[[!
        Function: glare
        Identical with <md5.glare>.
    ]]
    glare = _G["obj"].glare,
    --[[!
        Function: alpha_test
        Identical with <md5.alpha_test>.
    ]]
    alpha_test = _G["obj"].alphatest,
    --[[!
        Function: alpha_blend
        Identical with <md5.alpha_blend>.
    ]]
    alpha_blend = _G["obj"].alphablend,
    --[[!
        Function: cull_back_faces
        Identical with <md5.cull_back_faces>.
    ]]
    cull_back_faces = _G["obj"].cullface,
    --[[!
        Function: fullbright
        Identical with <md5.fullbright>.
    ]]
    fullbright = _G["obj"].fullbright,
    --[[!
        Function: shader
        Identical with <md5.shader>.
    ]]
    shader = _G["obj"].shader,
    --[[!
        Function: scroll
        Identical with <md5.scroll>.
    ]]
    scroll = _G["obj"].scroll,
    --[[!
        Function: noclip
        Identical with <md5.noclip>.
    ]]
    noclip = _G["obj"].noclip
}

--[[!
    Class: ragdoll
    Provides functions required for defining ragdolls
    with skeletal models (<md5>, <iqm>, <smd>).

    There is a ragdoll editor for Sauerbraten, see this
    page <http://cube.wikispaces.com/Creating+Ragdolls>
    for more information. The ragdoll editor writes out
    the commands in cubescript, so you'll have to further
    process the output to get Lua code. Please note that
    even when the page refers to "currently only <md5>
    models", <smd> and <iqm> are also supported (not by
    the ragdoll editor though, so you'll have to convert
    your model to md5 for ragdoll editing).

    There will soon be an OF-specific ragdoll editor
    in our Github tools repository.
]]
ragdoll = {
    --[[!
        Function: vertex
        Defines a ragdoll vertex. First argument is
        a <vec3> specifying the coordinates, second
        argument is a radius (a floating point value).
        The radius is optional.
    ]]
    vertex = CAPI.rdvert,

    --[[!
        Function: eye
        Specifies a ragdoll eye (integral value).
    ]]
    eye = CAPI.rdeye,

    --[[!
        Function: triangle
        Defines a ragdoll triangle from 3 vertices specified
        by arguments (integral values, the vertex numbers start
        at 0, where 0 is the first defined one).
    ]]
    triangle = CAPI.rdtri,

    --[[!
        Function: joint
        Defines a ragdoll joint, knowing a bone (first argument)
        and a triangle (second argument). There are 3 more optional
        arguments specifying vertices. All arguments are integral
        values.
    ]]
    joint = CAPI.rdjoint,

    --[[!
        Function: limit_distance
        Limits a distance between two vertices specified by
        the first two arguments. Final two arguments are floating
        point values specifying minimal and maximal distance.
    ]]
    limit_distance = CAPI.rdlimitdist,

    --[[!
        Function: limit_rotation
        Limits a rotation between two triangles specified by
        the first two arguments. Third argument is a floating
        point value specifying the maximum rotation angle.
        Last 4 arguments make a quaternion used to create
        the 3x3 rotation matrix.
    ]]
    limit_rotation = CAPI.rdlimitrot,
    animate_joints = CAPI.rdanimjoints
}
