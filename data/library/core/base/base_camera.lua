--[[!
    File: library/core/base/base_camera.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features camera control system for Lua.
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
        x - The X coord to force.
        y - The Y coord to force.
        z - The Z coord to force.
        yaw - The yaw to force.
        pitch - The pitch to force.
        roll - The roll to force.
        fov - The fov to force.
]]
force = CAPI.forcecam

--[[!
    Function: force_position
    Forces camera position.

    Parameters:
        x - X position.
        y - Y position.
        z - Z position.
]]
force_position = CAPI.forcepos

--[[!
    Function: force_yaw
    Forces camera yaw.

    Parameters:
        yaw - The yaw to force.
]]
force_yaw = CAPI.forceyaw

--[[!
    Function: force_pitch
    Forces camera pitch.

    Parameters:
        pitch - The pitch to force.
]]
force_pitch = CAPI.forcepitch

--[[!
    Function: force_roll
    Forces camera roll.

    Parameters:
        roll - The roll to force.
]]
force_roll = CAPI.forceroll

--[[!
    Function: force_fov
    Forces camera fov.

    Parameters:
        fov - The fov to force.
]]
force_fov = CAPI.forcefov

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
    Functions: center_on_entity
    Centers view on selected entity. Increment
    through selection by N. For example, N == 1
    means next, N == -1 means previous.

    You can set distance from the entity via
    engine variable called entautoviewdist.

    Parameters:
        N - the increment factor.
]]
center_on_entity = CAPI.entautoview
