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
