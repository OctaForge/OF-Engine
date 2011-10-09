--[[!
    File: library/core/base/base_textures.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features texture handling interface. Some bits of
        documentation are taken from "Sauerbraten editing reference".
]]

--[[!
    Package: texture
    This module controls textures (their registration and manipulation) and
    texture blending for i.e. heightmap.
]]
module("texture", package.seeall)

--[[!
    Function: reset
    Resets the texture slots, so slots defined after this will start
    with index 0 again. You usually do this in a map script.
]]
reset = CAPI.texturereset

--[[!
    Function: add
    Binds a texture to texture current texture slot. Diffuse texture
    initiates the slot, any further types will then belong to last
    defined diffuse.

    (start table)
        +-------+-------------------------------------------------------------+
        | Type  | Purpose                                                     |
        +-------+-------------------------------------------------------------+
        | c / 0 | Primary diffuse texture (RGB).                              |
        +-------+-------------------------------------------------------------+
        | u / 1 | Generic secondary texture.                                  |
        +-------+-------------------------------------------------------------+
        |       | Decals (RGBA), blended into diffuse texture if running in   |
        | d     | fixed-function mode. To disable this combining, specify     |
        |       | secondary textures as generic with 1 or u.                  |
        +-------+-------------------------------------------------------------+
        | n     | Normal maps (XYZ).                                          |
        +-------+-------------------------------------------------------------+
        |       | Glow maps (RGB), blended into diffuse texture if running in |
        | g     | fixed-function mode. To disable thing combining, specify    |
        |       | secondary textures as generic with 1 or u.                  |
        +-------+-------------------------------------------------------------+
        | s     | Specularity maps (grayscale), puts in alpha channel         |
        |       | or diffuse (c / 0).                                         |
        +-------+-------------------------------------------------------------+
        | z     | Depth maps (Z), put in alpha channel of normal (n) maps.    |
        +-------+-------------------------------------------------------------+
        | e     | Environment maps (skybox).                                  |
        +-------+-------------------------------------------------------------+
    (end)

    Parameters:
        type - see table above. Specifying the primary diffuse texture advances
        to the next texture slot, while secondary types fill additional texture
        units in order specified in the .lua file. Allows secondary textures to
        be specified for a single texture slot, for use in shaders and other
        features, the combinations of multiple textures into a single texture
        are performed automatically in the shader rendering path.
        May also be a material name, in which case it behaves like 0 / c, but
        instead associates the slot with a material.
        filename - path to the texture relative to "data".
        rotation - 0 is none, 1 is 90° clockwise, 2 is 180°, 3 is 270°
        clockwise, 4 is X flip and 5 is Y flip. Optional.
        x - X offset in texels. Optional.
        y - Y offset in texels. Optional.
        scale - this will multiply the size of the texture as it appears
        on the world geometry. Optional.
        forcedintex - forced texture slot index, optional.
]]
add = CAPI.texture

--[[!
    Function: auto_grass
    If you call this after definition of the texture slot, it associates
    a grass texture given by argument (path) with the texture slot. For
    upward facing surfaces only.
]]
auto_grass = CAPI.autograss

--[[!
    Function: scroll
    Scrolls the current texture slot at X and Y Hz (given by arguments),
    along the X and Y axes of the texture respectively.

    For the in-game version, see <vslot.scroll>.
]]
scroll = CAPI.texscroll

--[[!
    Function: offset
    Offsets the current texture slot by X and Y texels (given by arguments)
    along the X and Y axes of the texture respectively.

    For the in-game version, see <vslot.offset>.
]]
offset = CAPI.texoffset

--[[!
    Function: rotate
    Rotates the current texture slot by argument N.
    For N meanings, see <add>.

    For the in-game version, see <vslot.rotate>.
]]
rotate = CAPI.texrotate

--[[!
    Function: scale
    Scales the current texture slot by argument N.
    For N meanings, see <add>.

    For the in-game version, see <vslot.scale>.
]]
scale = CAPI.texscale

--[[!
    Function: layer
    Defines a texture blending layer for the current texture slot.
    Accepts an argument N which is an integral value specifying
    index of the texture slot you want to use as bottom texture
    layer to blend with. Can be either positive (0 is the first
    slot) or negative (-1 is the previous slot).

    For the in-game version, see <vslot.layer>.
]]
layer = CAPI.texlayer

--[[!
    Function: alpha
    Sets the alpha transparency of the front / back facces of the
    current texture slot. First argument is transparency for the
    front faces and second argument for the back faces. Both
    are floating point numbers from 1.0 to 0.0 (1.0 being
    non-transparent and 0.0 invisible). Requires the "alpha"
    material to be applied over the geometry
    (see <edit.set_material>).

    For the in-game version, see <vslot.alpha>.
]]
alpha = CAPI.texalpha

--[[!
    Function: color
    Sets the color multiplier of the current texture slot
    to color R, G, B where R, G, B are floating point values
    given by arguments and ranging from 0.0 to 1.0 (0.0 disables
    the color channel and 1.0 makes full use of it).

    For the in-game version, see <vslot.color>.
]]
color = CAPI.texcolor

--[[!
    Function: ffenv
    Makes the current texture slot reflect environment map in
    fixed function mode. Requires setting a shader (<shader.set>)
    to some that reflects the environment, even though it's not
    used in fixed function mode. Toggled with an argument, which
    is a boolean value. True means reflection enabled, false disabled.
]]
ffenv = CAPI.texffenv

--[[!
    Function: reload
    Reloads a texture given by the argument specifying the
    texture name. The path is relative to the "data" directory.
]]
reload = CAPI.reloadtex

--[[!
    Function: generate_dds
    Generates a dds file for a given texture.

    Parameters:
        if - input file.
        of - output file.
]]
generate_dds = CAPI.gendds

--[[!
    Function: flip_normalmap_y
    Normalmaps generally come in two kinds, left-handed or
    right-handed coordinate systems.

    If you are trying to use normalmaps authored for other
    engines, you may find that the lighting goes the wrong
    way along one axis, this can be fixed by flipping the Y
    coordinate of the normal.

    The function loads normalmap given by the first argument
    (must be 24bit .tga) and writes out flipped normalmap with
    filename given by second argument (also tga).

    Paths are relative to the "data" directory.
]]
flip_normalmap_y = CAPI.flipnormalmapy

--[[!
    Function: merge_normalmaps
    Normalmaps authored for Quake 4 often come as a base
    normal map with separate height offset *_h.tga. This
    is NOT a height file as used for parallax, instead its
    detail to be blended onto the normals. This function
    takes normalmap N and a _h file H (both given by args
    and both must be 24bit .tga) and outputs a combined
    normalmap N (it *overwrites* N).
]]
merge_normalmaps = CAPI.mergenormalmaps

--[[!
    Function: scroll_slots
    Scrolls the texture slots on a surface. Works only
    with a surface selected. Argument N specifies the
    direction and amount of textures to scroll by (for
    example, -2 scrolls two texture slots back).

    Bind to "y" key + mouse scroll by default.
    See also <bring_to_top>.
]]
scroll_slots = CAPI.edittex

--[[!
    Function: bring_to_top
    Brings the texture on the current selection to the
    top of the texture list, so when you select something
    different and then use <scroll_slots> with argument 1,
    it'll set that texture to the selected surface.
]]
bring_to_top = CAPI.gettex

--[[!
    Function: set_slot
    Given a texture slot index, the texture slot is then
    set to the selected surface.
]]
set_slot = CAPI.settex

--[[!
    Function: replace_all
    Replaces the last texture edit across the whole map.
    Only those faces with textures matching the one that
    was last edited will be replaced. See also
    <replace_selection>.
]]
replace_all = CAPI.replace

--[[!
    Function: replace_selection
    Replaces the last texture edit within the currently selected
    region. Only those faces with textures matching the one that
    was last edited will be replaced. See also <replace_all>.
]]
replace_selection = CAPI.replacesel

--[[!
    Function: get_current_index
    Returns the current texture slot index (that is, the
    one that was last set, for example with <scroll_slots>
    or <set_slot>). See also <get_selected_index> and
    <get_replaced_index>.
]]
get_current_index = CAPI.getcurtex

--[[!
    Function: get_selected_index
    Returns the index of the currently selected texture
    slot (that is, inside the geometry selection in the
    edit mode). See also <get_current_index> and
    <get_replaced_index>.
]]
get_selected_index = CAPI.getseltex

--[[!
    Function: get_replaced_index
    Returns the index of the texture slot that was last applied
    using either <replace_all> or <replace_selection>. See also
    <get_current_index> and <get_selected_index>.
]]
get_replaced_index = CAPI.getreptex

--[[!
    Function: get_slot_name
    Given at least one argument which is a texture slot index,
    the function returns the path to its diffuse texture.

    If a second argument is given, it returns the path to
    the subslot texture. 0 always means diffuse texture, any
    number bigger than that refers to a subslot. Subslot
    indexes depend on the order they were defined in. For
    example, if you define diffuse, then normal, then spec,
    then parallax, normal will have index 1, spec will have
    index 2, parallax 3, diffuse 0.
]]
get_slot_name = CAPI.gettexname

--[[!
    Function: fill_slot_list
    Fills the internal list with slot indexes. Required
    for <get_slots_number> to work.
]]
fill_slot_list = CAPI.filltexlist

--[[!
    Function: get_slots_number
    Returns the number of the texture slots
    defined in the map.
]]
get_slots_number = CAPI.getnumslots

--[[!
    Function: clear_blend_brushes
    Clears all blend brushes.
]]
clear_blend_brushes = CAPI.clearblendbrushes

--[[!
    Function: remove_blend_brush
    Removes a blend brush with a name given by the argument.
]]
remove_blend_brush = CAPI.delblendbrush

--[[!
    Function: add_blend_brush
    Adds a blend brush with a name given by the first
    argument and a filename (image) given by the second
    argument (in format "data/..../x.extension").
]]
add_blend_brush = CAPI.addblendbrush

--[[!
    Function: next_blend_brush
    Moves to the next blend brush. Optional argument specifies
    direction (1 means next, -1 means previous). By default
    goes forward.
]]
next_blend_brush = CAPI.nextblendbrush

--[[!
    Function: set_blend_brush
    Sets a blend brush with a name given by
    the argument as current.
]]
set_blend_brush = CAPI.setblendbrush

--[[!
    Function: get_blend_brush_name
    Returns a name of the blend brush with an index given
    by the argument. See <get_current_blend_brush>.
]]
get_blend_brush_name = CAPI.getblendbrushname

--[[!
    Function: get_current_blend_brush
    Returns the current blend brush index.
]]
get_current_blend_brush = CAPI.curblendbrush

--[[!
    Function: rotate_blend_brush
    Rotates the current blend brush. By default this
    is bind to MOUSE2.
]]
rotate_blend_brush = CAPI.rotateblendbrush

--[[!
    Function: scroll_blend_brush
    Scrolls blend brushes. Prints output in format
    "blend brush set to NAME" into the console when
    scrolling. See also <next_blend_brush>.
    Optional argument works the same way as
    for <next_blend_brush>.
]]
function scroll_blend_brush(dir)
    next_blend_brush(dir)
    echo("blend brush set to: %(1)s" % {
        get_blend_brush_name(get_current_blend_brush())
    })
end

--[[!
    Function: paint_blend_map
    Paints blend map in selected mode (see
    <set_blend_paint_mode>). By default this
    is bind to MOUSE1.
]]
paint_blend_map = CAPI.paintblendmap

--[[!
    Function: clear_selected_blend_map
    Clears all the texture blending in the current
    selection. See also <clear_blend_map>.
]]
clear_selected_blend_map = CAPI.clearblendmapsel

--[[!
    Function: clear_blend_map
    Clears all the texture blending in the whole
    map. See also <clear_selected_blend_map>.
]]
clear_blend_map = CAPI.clearblendmap

--[[!
    Function: invert_selected_blend_map
    Inverts the blended layers in the current
    selection. See also <invert_blend_map>.
]]
invert_selected_blend_map = CAPI.invertblendmapsel

--[[!
    Function: invert_blend_map
    Inverts the blended layers in the whole
    map. See also <invert_selected_blend_map>.
]]
invert_blend_map = CAPI.invertblendmap

--[[!
    Function: show_blend_map
    If for some reason the blend map gets messed up
    while editing, you can use this function cause the
    blend map to reshow without doing a full <world.calc_light>.
]]
show_blend_map = CAPI.showblendmap

--[[!
    Function: optimize_blend_map
    Optimizes the blend map without affecting the appearance.
    Do this before releasing your map, along with things like
    full lighting recalc and PVS.
]]
optimize_blend_map = CAPI.optimizeblendmap

--[[!
    Variable: blend_paint_modes
    A local table storing available texture blend paint modes.
    Used by <set_blend_paint_mode>. Usual paint mode is dig (2).
    The number mentioned in parenthesis is a value for <blendpaintmode>
    engine variable that sets the paint mode (see <set_blend_paint_mode>).

    Modes:
        off (0) - texture blending is disabled.
        replace (1) - replaces / clears a layer.
        dig (2) - min(dest, src), digs where black is the dig pattern.
        fill (3) - max(dest, src), fills where white is the fill pattern.
        inverted_dig (4) - min(dest, invert(src)), digs where white is the
        dig pattern.
        inverted_fill (5) - max(dest, invert(src)), fills where black is the
        fill pattern.
        
]]
local blend_paint_modes = {
    "off",
    "replace",
    "dig",
    "fill",
    "inverted dig",
    "inverted fill"
}

--[[!
    Function: set_blend_paint_mode
    Sets the current blend paint mode. The argument "mode" specifies a value
    for <blendpaintmode> engine variable. For available values and better
    description, see <blend_paint_modes>. If no argument is provided,
    texture blending gets turned off.
]]
function set_blend_paint_mode(mode)
    _G["blendpaintmode"] = m or 0
    echo("blend paint mode set to %(1)s" % {
        blend_paint_modes[_G["blendpaintmode"] + 1]
    })
end
