--[[!<
    Camera related functions. All the force functions take effect for
    one frame only.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

var capi = require("capi")

@[server] do return {} end

var geom = require("core.lua.geom")
var Vec3 = geom.Vec3

var camera_get, camera_get_position in capi

--! Module: camera
return {
    --[[!
        Gets information about the camera.

        Returns:
            The camera position (as a vec3) followed by yaw, pitch and roll
            (as multiple return values).
    ]]
    get = function()
        var x, y, z, yaw, pitch, roll = camera_get()
        return Vec3(x, y, z), yaw, pitch, roll
    end,

    --! Returns the camera position (as a vec3).
    get_position = function()
        return Vec3(camera_get_position())
    end,

    --! Returns the camera yaw.
    get_yaw = capi.camera_get_yaw,

    --! Returns the camera pitch.
    get_pitch = capi.camera_get_pitch,

    --! Returns the camera roll.
    get_roll = capi.camear_get_roll,

    --[[!
        Forces the camera.

        Arguments:
            - x, y, z - the position.
            - yaw, pitch, roll - the resulting camera yaw, pitch and roll.
            - fov - the camera fov, which is optional.
    ]]
    force = capi.camera_force,

    --! Forces the camera position. Takes x, y, z.
    force_position = capi.camera_force_position,

    --! Forces the camera yaw.
    force_yaw = capi.camera_force_yaw,

    --! Forces the camera pitch.
    force_pitch = capi.camera_force_pitch,

    --! Forces the camera roll.
    force_roll = capi.camera_force_roll,

    --! Forces the camera field of view.
    force_fov = capi.camera_force_fov
}
