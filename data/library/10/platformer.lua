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
        self:set_attr("movement_speed", 75)
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

        signal.connect(self, "client_respawn", function(self)
            self:set_attr("platform_axis", "+x")
            self:set_attr("platform_position", self:get_attr("position").y)
            self:set_attr("platform_camera_axis", "+y")
            self.platform_move        = 0
        end)
    end,

    run = CLIENT and function(self, seconds)
        if self == ents.get_player() and not self:get_editing() then
            if entity:get_attr("spawn_stage") == 0 then
                local position = self:get_attr("position"):copy()
                local velocity = self:get_attr("velocity"):copy()

                if self:get_attr("platform_axis")[2] == "x" then
                    if math.abs(position.y - self:get_attr("platform_position")) > 0.5 then
                        position.y = self:get_attr("platform_position")
                        velocity.y = 0
                    else
                        position = nil
                    end
                else
                    if math.abs(position.x - self:get_attr("platform_position")) > 0.5 then
                        position.x = self:get_attr("platform_position")
                        velocity.x = 0
                    else
                        position = nil
                    end
                end

                if position then
                    self:set_attr("position", position:lerp(self:get_attr("position"), 1 - (seconds * 5)))
                    self:set_attr("velocity", velocity)
                    #log(WARNING, "Fixed platform position %(1)i" % { frame.get_time() })
                end
            end

            local platform_axis = vec3_from_axis(self:get_attr("platform_axis"))
            self.platform_yaw   = math.normalize_angle(
                platform_axis:mul(self:get_platform_direction()):to_yaw_pitch().yaw,
                self:get_attr("yaw"))
            self:set_attr("yaw", math.magnet(
                math.lerp(
                    self:get_attr("yaw"),
                    self.platform_yaw,
                    seconds * 15
                ),
                self.platform_yaw,
                45
            ))
            self:set_attr("pitch", 0)
            self:set_attr("move", (self.platform_move == 1 and (math.abs(self.platform_yaw - self:get_attr("yaw")) < 1)) and 1 or 0)

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
            camera_position:add(self:get_center())
            camera_position.z = camera_position.z + (self:get_attr("radius") * self.platform_camera_distance * 0.04)
            camera_position:add(vec3_from_axis(self:get_attr("platform_camera_axis")):mul(self.platform_camera_distance))

            if self.platform_camera_smoothing > 0 then
                camera_position = self.last_camera_smooth_position:lerp(
                    camera_position,
                    (1.6 * seconds) / self.platform_camera_smoothing
                )
                self.platform_camera_smoothing = self.platform_camera_smoothing - (seconds * 0.5)
            end
            self.last_camera_smooth_position = camera_position:copy()
        
            local direction = self:get_center():sub_new(camera_position)
            orientation = direction:to_yaw_pitch()
            camera_position.z = camera_position.z + (self:get_attr("radius") * self.platform_camera_distance * 0.02)
            camera.force(
                camera_position.x, camera_position.y, camera_position.z,
                orientation:get_attr("yaw"), orientation:get_attr("pitch"), 0, self.platform_fov)
        end
    end or nil
}

function do_movement(move, down)
    local player = ents.get_player()
    if player:get_editing() then
        player:set_attr("move", move)
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
    if player:get_editing() then
        player:set_attr("strafe", strafe)
    end
    if not health.is_valid_target(player) then return nil end

    if vec3_from_axis(player:get_attr("platform_camera_axis"))
        :cross_product(
            vec3_from_axis(player:get_attr("platform_axis"))
        ).z < 0
    then
        strafe = -strafe
    end

    if strafe ~= 0 then player:set_platform_direction(strafe) end
    player.platform_move = down and 1 or 0
end

function do_mousemove(yaw, pitch)
    if _V.editing ~= 0 then
        return yaw, pitch
    end
end

axis_switcher = ents.register_class(plugins.bake(ents.Obstacle, {
    world_areas.plugin,
    {
        properties = {
            platform_axises = svars.State_Array(),
            platform_camera_axises = svars.State_Array()
        },

        init = function(self)
            self:set_attr("platform_axises", { "+x", "+y" })
            self:set_attr("platform_camera_axises", { "+y", "-x" })
        end,

        do_movement = function(self, move, down)
            if down then self:flip_axes(move) end
        end,

        flip_axes = function(self, up)
            local player = ents.get_player()

            for i, axis in pairs(self:get_attr("platform_axises"):to_array()) do
                if player:get_attr("platform_axis")[2] ~= axis[2] then
                    axis = ((up < 0) and
                        player:get_attr("platform_camera_axis") or
                        flip_axis(player:get_attr("platform_camera_axis"))
                    )
                    player:set_platform_direction(1)
                    player:set_attr("platform_axis", axis)
                    player:set_attr("platform_position", (axis[1] == "x") and self:get_attr("position").y or self:get_attr("position").x)
                    player:set_attr("platform_camera_axis", self:get_attr("platform_camera_axises")[i])
                    player.platform_camera_smoothing = 1.0
                    return nil
                end
            end

            #log(ERROR, "did not find player axis to flip, %(1)s" % { player:get_attr("platform_axis") })
        end
    }
}, "axis_switcher"))
