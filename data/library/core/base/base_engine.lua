--[[!
    File: library/core/base/base_engine.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features engine interface
        (quitting, engine variables, homedir etc.)
]]

--[[!
    Package: engine
    This module contains engine interface. Contains some core engine
    functions as well as engine variable system shared between engine
    and scripting.

    You can get engine varibles in scripting the same way as normal
    variables are handled, because _G environment table is overloaded
    to do so. You can also create new temporary variables in here.
]]
module("engine", package.seeall)

--[[!
    Function: glext
    Checks if a gl extension is available.

    Parameters:
        ext - the extension to check for.

    Returns:
        true if found, false otherwise.
]]
glext = _C.glext

--[[!
    Function: get_server_log_file
    Returns the name of OctaForge server log file.
]]
get_server_log_file = _C.getserverlogfile
