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
glext = CAPI.glext

--[[!
    Function: get_fps
    Gets current framerate.

    Returns:
        This function returns three values.
        First is the actual framerate,
        second is best difference, third
        is worst difference.
]]
get_fps = CAPI.getfps

--[[!
    Function: get_wall_clock
    Gets wall clock label text.

    Returns:
        Wall clock label text, or nil
        if disabled.
]]
get_wall_clock = CAPI.getwallclock

--[[!
    Function: screenshot
    Takes a screenshot and saves it in OF home directory.

    Parameters:
        name - if specified, saves under the name, otherwise
        saves as screenshot_TOTALMILLIS.png.
]]
screenshot = CAPI.screenshot

--[[!
    Function: movie
    Starts/stops recording of video with in-game recorder.
    These are saved uncompressed, so they're big.
    You can control settings with variables:
    <moview>, <movieh>, <moviesound>, <moviefps>, <moviesync>,
    <movieaccel>, <movieaccelyuv>, <movieaccelblit>.

    Parameters:
        name - Name of the resulting avi file in OF home directory.
        If not specified, stops the recording.
]]
movie = CAPI.movie

--[[!
    Function: get_server_log_file
    Returns the name of OctaForge server log file.
]]
get_server_log_file = CAPI.getserverlogfile

--[[!
    Function: write_config
    Writes an OctaForge configuration file into filename
    given by argument. The file gets written into OctaForge
    home directory.
]]
write_config = CAPI.writecfg

--[[!
    Function: add_zip
    Adds a zip file into engine VFS. First argument specifies
    name of the zip file in either OF home or root directory,
    second argument specifies mount directory (optional) and
    third one is an optional string specifying what to strip
    from the beginning. You don't need to specify zip extension.
    Without specified mount point, the zip will get mounted
    directly into OF home directory, so it makes sense to
    put "data" directory in it. See also <remove_zip>.
]]
add_zip = CAPI.addzip

--[[!
    Function: remove_zip
    Removes a previously mounted zip file from the engine VFS.
    Takes an argument specifying name of the zip. See also <add_zip>.
]]
remove_zip = CAPI.removezip
