--[[!
    File: base/base_engine.lua

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
    Function: quit
    Tries to quit the engine, showing
    a dialog when there are unsaved changes.
]]
quit = CAPI.quit

--[[!
    Function: force_quit
    Quits the engine in any case.
]]
force_quit = CAPI.force_quit

--[[!
    Function: resetgl
    Reloads the renderer.
]]
resetgl = CAPI.resetgl

--[[!
    Function: quit
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
    Returns:
        Name of OctaForge server log file.
]]
get_server_log_file = CAPI.getserverlogfile

--[[!
    Section: Engine variables
    Engine variables are variables defined in the engine or by the engine.

    They're stored in the engine in a vector, each of them is represented
    by a struct. They can have either integer, float or string value.
    They can as well have minimal value or maximal value if they're defined
    by the engine.

    Aliases are engine variables that are defined by scripting system and
    those have no minimal or maximal values. Aliases get saved into the
    configuration file, so they're loaded on next engine run - that can
    be overriden when creating the alias.

    Aliases are useful when i.e. manipulating with fields, using them,
    you can pre-set a value for future field (field doesn't then create
    its own engine variable, it just makes use of the alias).

    Engine variables are integrated into Lua with overriden metamethods on
    <_G>, so you can interact with them as with any other global variable in
    Lua (setting, getting).
]]

--[[!
    Variable: VAR_I
    This variable specifies engine variable with integer value.
]]
VAR_I = 0

--[[!
    Variable: VAR_F
    This variable specifies engine variable with float value.
]]
VAR_F = 1

--[[!
    Variable: VAR_S
    This variable specifies engine variable with string value.
]]
VAR_S = 2

--[[!
    Function: reset_var
    Resets value of an engine variable.

    Parameters:
        name - name of the engine variable to reset.
]]
reset_var = CAPI.resetvar

--[[!
    Function: new_var
    Creates a new alias.

    Parameters:
        name - name of the alias.
        type - see <VAR_I>, <VAR_F>, <VAR_S>.
        value - initial value for the alias.
        no_save - if true, the alias won't get written
        into config file, defaults to false.
        
]]
new_var = CAPI.newvar

--[[!
    Function: get_var
    Gets value of an engine variable. This gets called
    from overriden metamethods in _G, so you shouldn't
    ever need this.

    Parameters:
        name - engine variable name.

    Returns:
        Its value.
]]
get_var = CAPI.getvar

--[[!
    Function: set_var
    Sets value of an engine variable. This gets called
    from overriden metamethods in _G, so you shouldn't
    ever need this.

    Parameters:
        name - engine variable name.
        value - value to set.
]]
set_var = CAPI.setvar

--[[!
    Function: var_exists
    Gets if engine variable of specified name exists.
    Used in overriden metamethods in _G.

    Parameters:
        name - engine variable name.

    Returns:
        true if it exists, false otherwise.
]]
var_exists = CAPI.varexists
