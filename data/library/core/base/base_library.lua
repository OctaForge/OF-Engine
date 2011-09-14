--[[!
    File: library/core/base/base_library.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features library management system.
]]

--[[!
    Package: library
    This module controls libraries of scripts. It allows to use a
    specific library in a script and include submodules among specific library.
]]
module("library", package.seeall)

--[[!
    Variable: current
    This variable stores currently used library version string.
    It comes in handy when getting from scripts. It can be nil
    if only core library is being used or string otherwise.
]]
current = nil

--[[!
    Variable: unresettable
    This specifies a list of modules that cannot be reset on
    map restarts. Besides this, there is also an internal
    list inside the engine, which takes care of some of
    core Lua modules.
]]
unresettable = {
    "actions",
    "camera",
    "console",
    "edit",
    "effects",
    "engine",
    "entity",
    "entity_animated",
    "geometry",
    "gui",
    "json",
    "library",
    "model",
    "shader",
    "signals",
    "sound",
    "state_variables",
    "texture",
    "vslot",
    "world",

    "class",
    "convert",

    "logger",
    "logging",
    "base.base_actions",
    "base.base_camera",
    "base.base_console",
    "base.base_editing",
    "base.base_effects",
    "base.base_engine",
    "base.base_ent",
    "base.base_ent_anim",
    "base.base_geometry",
    "base.base_gui",
    "base.base_json",
    "base.base_library",
    "base.base_models",
    "base.base_shaders",
    "base.base_signals",
    "base.base_sound",
    "base.base_svars",
    "base.base_textures",
    "base.base_vslots",
    "base.base_world",

    "language",
    "language.mod_class",
    "language.mod_conv",
    "language.mod_math",
    "language.mod_string",
    "language.mod_table",

    "tgui",
    "tgui.widgets.buttons",
    "tgui.widgets.cherad",
    "tgui.widgets.fields",
    "tgui.init",
    "tgui.elements.windows",
    "tgui.elements.scrollers",
    "tgui.elements.sliders",
    "tgui.interface",
    "tgui.config"
}

--[[!
    Function: use
    This sets a currently used library. Meant to be used from
    map scripts to set which library will be in use.
    It executes library's initializer and appends the search path
    for both home directory and root directory in a safe way
    (through internal C API).

    Parameters:
        version - The library version string. It's the name
        of library's directory in data/library.

    Returns:
        Result of require() called on library's initializer.
        This is mostly irrelevant, as you don't have to do
        anything with the return value usually.

    See Also:
        <include>
]]
function use(version)
    if not CAPI.setup_library(version) then
        current = nil
        return nil
    end

    current = version
    return require(version)
end

--[[!
    Function: include
    Includes a module, either from currently activated library,
    from core library or anywhere from 'data' (for example,
    library.include("textures.foo") executes initializer script
    with path 'data/textures/foo/init.lua').

    Parameters:
        name - Name of the module to include. Dot specifies
        subdirectory delimiter.

    Returns:
        Result of require() called on the module, that
        is a table with module contents if the module calls
        module() inside.
        This is mostly irrelevant, as you don't have to do
        anything with the return value usually.

    See Also:
        <use>
]]
function include(name)
    return require(name)
end
