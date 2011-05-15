--[[!
    File: base/base_library.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features library management system.

    Section: Library management
]]

--[[!
    Package: library
    This module controls libraries of scripts. It allows to use a specific library
    in a script and include submodules among specific library.
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
    Function: use
    This sets a currently used library. Meant to be used from
    map scripts to set which library will be in use.
    It executes library's initializer and appends <package.path>.

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
    current = version

    local str = ";./data/library/%(1)s/?.lua" % { version }
    if not string.find(package.path, str) then
        package.path = package.path .. str
    end

    return require(version)
end

--[[!
    Function: include
    Includes a module, either from currently activated library,
    from core library or anywhere from <package.path>.

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
