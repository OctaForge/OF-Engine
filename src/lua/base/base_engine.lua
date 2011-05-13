--[[!
    File: base/base_engine.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features engine interface (quitting, engine variables, homedir etc.)

    Section: Engine interface
]]

--[[!
    Package: engine
    This module contains engine interface. Contains some core engine functions as
    well as engine variable system shared between engine and scripting.

    You can get engine varibles in scripting the same way as normal variables are
    handled, because _G environment table is overloaded to do so. You can also
    create new temporary variables in here.
]]
module("engine", package.seeall)

--- Quit the engine, showing a dialog when there are unsaved changes.
-- @class function
-- @name quit
quit = CAPI.quit

--- Quit the engine without asking for anything.
-- @class function
-- @name force_quit
force_quit = CAPI.force_quit

--- Reload graphics subsystem of the engine. 
-- @class function
-- @name resetgl
resetgl = CAPI.resetgl

--- Check for available OpenGL extension.
-- @param ext The extension to check for.
-- @return 1 if extension is available, 0 otherwise. (TODO: change to booleans)
-- @class function
-- @name glext
glext = CAPI.glext

--- Get current frame rate.
-- @return Frame rate.
-- @class function
-- @name getfps
getfps = CAPI.getfps

--- Take a screenshot.
-- @param name Screenshot will get saved as name.png.
-- @class function
-- @name screenshot
screenshot = CAPI.screenshot

--- Record an ingame video. WARNING: videos are huge!
-- Controlled by engine variables (moview, movieh,
-- moviesound, moviefps, moviesync, movieaccel,
-- movieaccelyuv, movieaccelblit)
-- @param name Movie will get recorded into name.avi.
-- @class function
-- @name movie
movie = CAPI.movie

-- Get OF home directory.
-- @return OF home directory.
-- @class function
-- @name gethomedir
gethomedir = CAPI.gethomedir

-- Get OF server log file.
-- @return OF server log file path.
-- @class function
-- @name getserverlogfile
getserverlogfile = CAPI.getserverlogfile

VAR_I = 0
VAR_F = 1
VAR_S = 2

resetvar = CAPI.resetvar
newvar = CAPI.newvar
getvar = CAPI.getvar
setvar = CAPI.setvar
varexists = CAPI.varexists
