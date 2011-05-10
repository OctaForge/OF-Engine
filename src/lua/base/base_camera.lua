--[[!
    File: base/base_camera.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features camera control system for Lua.

    Section: Camera interface
]]

--[[!
    Package: camera
    Camera interface. Allows user to force camera or its components,
    reset, zoom, get ...
]]
module("camera", package.seeall)


--[[!
    Function: force
    Forces camera components to fixed values.

    Parameters:
        yaw - The yaw to force.
        pitch - The pitch to force.
        roll - The roll to force.
        fov - The fov to force.
]]
force = CAPI.forcecam

--[[!
    Function: forcepos
    Forces camera position.

    Parameters:
        x - X position.
        y - Y position.
        z - Z position.
]]
forcepos = CAPI.forcepos

--[[!
    Function: forceyaw
    Forces camera yaw.

    Parameters:
        yaw - The yaw to force.
]]
forceyaw = CAPI.forceyaw

--[[!
    Function: forcepitch
    Forces camera pitch.

    Parameters:
        pitch - The pitch to force.
]]
forcepitch = CAPI.forcepitch

--[[!
    Function: forceroll
    Forces camera roll.

    Parameters:
        roll - The roll to force.
]]
forceroll = CAPI.forceroll

--[[!
    Function: forcefov
    Forces camera fov.

    Parameters:
        fov - The fov to force.
]]
forcefov = CAPI.forcefov

--[[!
    Function: reset
    Resets the camera. This cancels all forced
    values and goes back to fully dynamic camera.
]]
reset = CAPI.resetcam

--[[!
    Function: get
    Gets camera information.

    Returns:
        Table with camera information.

    Table contents:
        position - a vec3
        yaw - in degrees
        pitch - in degrees
        roll - in degrees
]]
get = CAPI.getcam

--[[!
    Function: zoom_in
    Zooms the camera in in thirdperson mode.
]]
zoom_in = CAPI.caminc

--[[!
    Function: zoom_out
    Zooms the camera out in thirdperson mode.
]]
zoom_out = CAPI.camdec

--[[!
    Function: mouselook
    Toggles mouse looking.
]]
mouselook = CAPI.mouselook

--[[!
    Function: character_view
    Toggles character viewing.
]]
character_view = CAPI.characterview
