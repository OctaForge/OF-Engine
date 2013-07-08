--[[! File: lua/core/engine/camera.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Camera related functions. All the force functions take effect for
        one frame only.
]]

local capi = require("capi")

if SERVER then return {} end

return {
    --[[! Function: get
        Gets information about the camera. Returns its position (as a vec3)
        followed by yaw, pitch and roll (as multiple return values).
    ]]
    get = capi.camera_get,

    --[[! Function: get_position
        Returns the camera position (as a vec3).
    ]]
    get_position = capi.camera_get_position,

    --[[! Function: get_yaw
        Returns the camera yaw.
    ]]
    get_yaw = capi.camera_get_yaw,

    --[[! Function: get_pitch
        Returns the camera pitch.
    ]]
    get_pitch = capi.camera_get_pitch,

    --[[! Function: get_roll
        Returns the camera roll.
    ]]
    get_roll = capi.camear_get_roll,

    --[[! Function: force
        Forces the camera. Takes x, y, z, yaw, pitch, roll, fov in that order.
        All must be supplied except fov, which is optional.
    ]]
    force = capi.camera_force,

    --[[! Function: force_position
        Forces the camera position. Takes x, y, z.
    ]]
    force_position = capi.camera_force_position,

    --[[! Function: force_yaw
        Forces the camera yaw.
    ]]
    force_yaw = capi.camera_force_yaw,

    --[[! Function: force_pitch
        Forces the camera pitch.
    ]]
    force_pitch = capi.camera_force_pitch,

    --[[! Function: force_roll
        Forces the camera roll.
    ]]
    force_roll = capi.camera_force_roll,

    --[[! Function: force_fov
        Forces the camera field of view.
    ]]
    force_fov = capi.camera_force_fov
}
