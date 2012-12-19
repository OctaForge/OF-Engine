library.include("mapelements.world_areas")

module("platformer", package.seeall)

function vec3_from_axis(axis)
    local ret = math.Vec3(0, 0, 0)
    if axis == "+x" then
        ret.x =  1
    elseif axis == "-x" then
        ret.x = -1
    elseif axis == "+y" then
        ret.y =  1
    else
        ret.y = -1
    end
    return ret
end

function flip_axis(axis)
    return (axis[1] == "+" and "-" or "+") .. axis[2]
end

plugin = {
    properties = {
        platform_axis        = svars.State_String { client_set = true },
        platform_position    = svars.State_Integer { client_set = true },
        platform_camera_axis = svars.State_String { client_set = true }
    },

    get_platform_direction = function(self)
        return self.xmap_defined_position_data - 1
    end,

    set_platform_direction = function(self, direction)
        self.xmap_defined_position_data = direction + 1
    end,

    init = function(self)
        self.movement_speed = 75
    end,

    activate = function(self)
        if not CLIENT then return nil end
        self.platform_camera_distance  = 150
        self.platform_camera_smoothing = 0
        self.last_camera_position        = nil
        self.last_camera_smooth_position = nil
        self.platform_yaw = -1
        self.platform_fov = 50
        self:set_platform_direction(1)

        signal.connect(self, "client_respawn", function(_, self)
            self.platform_axis        = "+x"
            self.platform_position    = self.position.y
            self.platform_camera_axis = "+y"
            self.platform_move        = 0
        end)
    end,

    run = CLIENT and function(self, seconds)
        if self == ents.get_player() and not self:is_editing() then
            if self.spawn_stage == 0 then
                local position = self.position:copy()
                local velocity = self.velocity:copy()

                if self.platform_axis[2] == "x" then
                    if math.abs(position.y - self.platform_position) > 0.5 then
                        position.y = self.platform_position
                        velocity.y = 0
                    else
                        position = nil
                    end
                else
                    if math.abs(position.x - self.platform_position) > 0.5 then
                        position.x = self.platform_position
                        velocity.x = 0
                    else
                        position = nil
                    end
                end

                if position then
                    self.position = position:lerp(self.position, 1 - (seconds * 5))
                    self.velocity = velocity
                    log(WARNING, "Fixed platform position %(1)i" % { frame.get_time() })
                end
            end

            local platform_axis = vec3_from_axis(self.platform_axis)
            self.platform_yaw   = math.normalize_angle(
                platform_axis:mul(self:get_platform_direction()):to_yaw_pitch().yaw,
                self.yaw
            ) + 90
            self.yaw = math.magnet(
                math.lerp(
                    self.yaw,
                    self.platform_yaw,
                    seconds * 15
                ),
                self.platform_yaw,
                45
            )
            self.pitch = 0
            self.move  = (self.platform_move == 1 and (math.abs(self.platform_yaw - self.yaw) < 1)) and 1 or 0

            if GLOBAL_CAMERA_DISTANCE then
                self.platform_camera_distance = math.lerp(
                    self.platform_camera_distance,
                    GLOBAL_CAMERA_DISTANCE * 3,
                    seconds * 5
                )
            end

            local camera_position = platform_axis:mul(-self.platform_camera_distance * 0.15)
            if not self.last_camera_position then self.last_camera_position = camera_position end
            camera_position = self.last_camera_position:lerp(camera_position, seconds * 0.5)
            self.last_camera_position = camera_position:copy()
            camera_position:add(self.center)
            camera_position.z = camera_position.z + (self.radius * self.platform_camera_distance * 0.04)
            camera_position:add(vec3_from_axis(self.platform_camera_axis):mul(self.platform_camera_distance))

            if self.platform_camera_smoothing > 0 then
                camera_position = self.last_camera_smooth_position:lerp(
                    camera_position,
                    (1.6 * seconds) / self.platform_camera_smoothing
                )
                self.platform_camera_smoothing = self.platform_camera_smoothing - (seconds * 0.5)
            end
            self.last_camera_smooth_position = camera_position:copy()
        
            local direction = self.center:sub_new(camera_position)
            orientation = direction:to_yaw_pitch()
            camera_position.z = camera_position.z + (self.radius * self.platform_camera_distance * 0.02)
            camera.force(
                camera_position,
                orientation.yaw, orientation.pitch,
                0, self.platform_fov
            )
        end
    end or nil
}

function do_movement(move, down)
    local player = ents.get_player()
    if player:is_editing() then
        player.move = move
    end
    if health.is_valid_target(player) then
        if do_jump then
            do_jump(move == 1 and down)
        elseif move == 1 and down then
            player:jump()
        end
    end
end

function do_strafe(strafe, down)
    local player = ents.get_player()
    if player:is_editing() then
        player.strafe = strafe
    end
    if not health.is_valid_target(player) then return nil end

    if vec3_from_axis(player.platform_camera_axis)
        :cross_product(
            vec3_from_axis(player.platform_axis)
        ).z < 0
    then
        strafe = -strafe
    end

    if strafe ~= 0 then player:set_platform_direction(strafe) end
    player.platform_move = down and 1 or 0
end

function do_mousemove(yaw, pitch)
    return (ents.get_player():is_editing() and { yaw = yaw, pitch = pitch } or {})
end

axis_switcher = ents.register_class(plugins.bake(entity_static.area_trigger, {
    world_areas.plugin,
    {
        properties = {
            platform_axises = svars.State_Array(),
            platform_camera_axises = svars.State_Array()
        },

        init = function(self)
            self.platform_axises = { "+x", "+y" }
            self.platform_camera_axises = { "+y", "-x" }
        end,

        do_movement = function(self, move, down)
            if down then self:flip_axes(move) end
        end,

        flip_axes = function(self, up)
            local player = ents.get_player()

            for i, axis in pairs(self.platform_axises:to_array()) do
                if player.platform_axis[2] ~= axis[2] then
                    axis = ((up < 0) and
                        player.platform_camera_axis or
                        flip_axis(player.platform_camera_axis)
                    )
                    player:set_platform_direction(1)
                    player.platform_axis = axis
                    player.platform_position = (axis[1] == "x") and self.position.y or self.position.x
                    player.platform_camera_axis = self.platform_camera_axises[i]
                    player.platform_camera_smoothing = 1.0
                    return nil
                end
            end

            log(ERROR, "did not find player axis to flip, %(1)s" % { player.platform_axis })
        end
    }
}, "axis_switcher"))
