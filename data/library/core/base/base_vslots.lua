--[[!
    File: library/core/base/base_vslots.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file provides a nice interface with Cube 2's vslot system.
]]

--[[!
    Package: vslot
    VSlots are "virtual slots". In Cube 2, you have texture (normal) slots
    and virtual slots, which are, unlike texture slots, saved in the map and
    refer to area, not a single texture. That allows you to set properties
    like coloring or alpha to the selected area, not only texture.
]]
module("vslot", package.seeall)

--[[!
    Function: delta
    Executes vslot commands in its body that way
    they only add to the current value. For example,

    (start code)
        vslots.delta(function() vslots.rotate(1) end)
    (end)

    will add 1 to the current rotation, instead of setting it to 1.
    It affects <rotate> (adds), <offset> (adds), <scale> (multiplies),
    <shader_param> (overrides) and <color> (multiplies).

    Parameters:
        body - a string containing Lua code to execute.
]]
delta = CAPI.vdelta

--[[!
    Function: rotate
    Performs texture rotation for the current selection. See <texture.rotate>.

    Parameters:
        see <texture.rotate>.
]]
rotate = CAPI.vrotate

--[[!
    Function: offset
    Performs texture offset for the current selection. See <texture.offset>.

    Parameters:
        see <texture.offset>.
]]
offset = CAPI.voffset

--[[!
    Function: scroll
    Performs texture scrolling for the current selection. See <texture.scroll>.

    Parameters:
        see <texture.scroll>.
]]
scroll = CAPI.vscroll

--[[!
    Function: scale
    Performs texture scaling for the current selection. See <texture.scale>.

    Parameters:
        see <texture.scale>.
]]
scale = CAPI.vscale

--[[!
    Function: layer
    Creates virtual layer for texture blending for the selection.
    See <texture.layer>.

    Parameters:
        see <texture.layer>.
]]
layer = CAPI.vlayer

--[[!
    Function: alpha
    Sets texture alpha for the current selection. See <texture.alpha>

    Parameters:
        see <texture.alpha>.
]]
alpha = CAPI.valpha

--[[!
    Function: color
    Changes texture tint for the current selection. See <texture.color>.

    Parameters:
        see <texture.color>.
]]
color = CAPI.vcolor

--[[!
    Function: reset
    Resets vslots in the same way as <texture.reset>.
]]
reset = CAPI.vreset

--[[!
    Function: shader_param
    Sets the texture shader parameter for the current selection.
    See <shader.set_param>.

    Parameters:
        See <shader.set_param>.
]]
shader_param = CAPI.vshaderparam

--[[!
    Function: compact_vslots
    Compacts vslots, you should never need it, because they are
    automatically compacted when they reach value of <autocompactvslots>.
]]
compact_vslots = CAPI.compactvslosts
