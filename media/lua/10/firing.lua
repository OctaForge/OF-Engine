module("firing", package.seeall)

guns = {}

function register_gun(gun, comment, hud)
    local index = #guns + 1
    comment = comment or tostring(index)

    guns[index]   = gun
    gun.gun_index = index
    gun.comment   = comment
    gun.hud       = hud

    return index
end

function click(button, down, x, y, z, entity)
    local player = ents.get_player()

    if button == 1 then
        if down then
            if player:get_attr("can_move") then
                player:start_shooting(x, y, z)
            end
        else
            -- TODO: autostop shooting when can_move changes to false (connect to signal)
            player:stop_shooting(x, y, z)
        end
    elseif button == 3 and down then
        cycle_gun_index(player, player:get_attr("gun_indexes"):to_array())
    end
end

function cycle_gun_index(entity, indexes)
    local curr = entity:get_attr("current_gun_index") + 1
    if    curr > #indexes then
          curr = 1
    end
    entity:set_attr("current_gun_index", curr)
end

function find_target(shooter, visual_origin, targeting_origin, fallback_target, range, scatter)
    -- targeting from the camera - where the player aimed the mouse
    local direction = math.Vec3():from_yaw_pitch(shooter:get_attr("yaw"), shooter:get_attr("pitch"))
    if math.is_nan(direction.x) then return { target = fallback_target } end
    if scatter then direction:add(math.norm_vec3():mul(scatter)):normalize() end

    local target = geometry.get_ray_collision_world   (targeting_origin, direction, range)
    local temp   = geometry.get_ray_collision_entities(targeting_origin, target,  shooter)
    local target_entity = nil

    if temp then
        target = temp.collision_position
        target_entity = temp.entity
    end

    -- check for hitting an entity from the gun source
    temp = geometry.get_ray_collision_entities(visual_origin, target, shooter)
    if temp then
        target = temp.collision_position
        target_entity = temp.entity
    end

    -- check for hitting the scenery from the gun source
    direction  = target:sub_new(visual_origin)
    local dist = direction:length()
    if dist > 2 then
        local target2 = geometry.get_ray_collision_world(visual_origin, direction:normalize(), dist)
        if target2:is_close_to(visual_origin, dist - 2) then
            target = target2
            target_entity = nil
        end
    end

    return {
        target = target,
        target_entity = target_entity
    }
end

plugins = {
    -- network protocol for firing events
    protocol = {
        properties = {
            firing_info = svars.State_Array_Float { client_set = true, has_history = false }
        },

        activate = function(self)
            signal.connect(self,"firing_info_changed", self.on_firing_info)
        end,

        on_firing_info = function(self, info)
            -- do not shoot if just killed (even though can_move = false didn't arrive yet)
            if not health.is_valid_target(self) then return nil end

            if #info ~= 5 then return nil end
            local gun_index = info[1]
            local target_pos = math.Vec3(info[2], info[3], info[4])
            local target_ent = ents.get(info[5])
            local gun = guns[gun_index]

            if CLIENT then
                if gun.handle_client_effect then
                    gun:handle_client_effect(self, gun:get_origin(self), target_pos, target_ent)
                end
            else
                if gun.handle_server_logic then
                    gun:handle_server_logic(self, gun:get_origin(self), target_pos, target_ent)
                end
            end
        end
    },

    -- manages a player firing a gun - delay, repeat etc.
    player = {
        properties = {
            current_gun_index = svars.State_Integer { client_set = true },
            gun_indexes = svars.State_Array_Integer(),
            gun_switch_sound = svars.State_String()
        },

        gun_ammos = {},

        init = function(self)
            for k, gun in pairs(guns) do
                local tag = "*" .. gun.origin_tag
                if gun.origin_tag and not table.find(self:get_attr("attachments"):to_array(), tag) then
                    self:get_attr("attachments"):append(tag)
                end
            end

            self:set_attr("gun_indexes", {})
            self:set_attr("gun_switch_sound", "")
        end,

        activate = function(self)
            if SERVER then
                signal.connect(self,
                    "gun_indexes_changed",
                    function(self, indexes)
                        if #indexes > 0 then
                            self:set_attr("current_gun_index", indexes[1]) -- sets initial value
                        end
                    end
                )
            else
                self.gun_delay = 0
                self.last_handled_shot_counter = 0
                self.now_firing = false

                signal.connect(self,
                    "current_gun_index_changed",
                    function(self)
                        if self:get_attr("gun_switch_sound") ~= "" then
                            sound.play(self:get_attr("gun_switch_sound"), self:get_attr("position"):copy())
                        end
                    end
                )
            end
        end,

        run = CLIENT and function(self, seconds)
            if self ~= ents.get_player() then return nil end

            self.gun_delay = math.max(self.gun_delay - seconds, 0)

            local gun = guns[self:get_attr("current_gun_index")]
            if gun then
                if self.now_firing and self.gun_delay == 0 then
                    if  self.gun_ammos[self:get_attr("current_gun_index")]
                    and self.gun_ammos[self:get_attr("current_gun_index")] <= 0 then
                        self:queue_action(action_out_of_ammo())
                        self:stop_shooting(gun)
                    else
                        gun:do_shot(
                            self,
                            input.get_target_position(),
                            input.get_target_entity()
                        )
                        if  self.gun_ammos[self:get_attr("current_gun_index")]
                        and self.gun_ammos[self:get_attr("current_gun_index")] ~= 0 then
                            self.gun_ammos[self:get_attr("current_gun_index")] = -1
                        end
                        self.gun_delay = self.gun_delay + gun.delay
                        if not gun.repeating then
                            self:stop_shooting(gun)
                        end

                        --if not GLOBAL_GAME_HUD then
                            if gun.hud then
                                --gui.hud_image(gun.hud, 0.80, 0.88, 0.05, 0.05)
                            end
                        --[[else
                            local params = GLOBAL_GAME_HUD:get_firing_params(gun)
                            --gui.hud_image(
                            --    params.gun.icon,
                            --    params.gun.x, params.gun.y,
                            --    params.gun.w, params.gun.h
                            --)
                            if params.ammo1 then
                                --gui.hud_image(
                                --    params.ammo1.icon,
                                --    params.ammo1.x, params.ammo1.y,
                                --    params.ammo1.w, params.ammo1.h
                                --)
                            end
                            if params.ammo2 then
                                --gui.hud_image(
                                --    params.ammo2.icon,
                                --    params.ammo2.x, params.ammo2.y,
                                --    params.ammo2.w, params.ammo2.h
                                --)
                            end
                        end]]
                    end
                end
            end
        end or nil,

        start_shooting = function(self, x, y, z)
            self.now_firing = true
        end,

        stop_shooting = function(self, x, y, z)
            local gun = guns[self:get_attr("current_gun_index")]

            if gun.repeating then
                self.gun_delay = 0
            end

            if gun.stop_shooting then
                gun:stop_shooting(self)
            end

            self.now_firing = false
        end
    }
}

gun = table.Object:clone {}

gun.handle_start_logic   = nil
gun.handle_client_effect = nil

function gun:do_shot(shooter, target_position, target_entity)
    -- do not shoot if just killed (even though can_move = false didn't arrive yet)
    if not health.is_valid_target(shooter) then return nil end

    if self.handle_start_logic then
        if not self:handle_start_logic(shooter, self:get_origin(shooter), target_position, target_entity) then
            return nil
        end
    end

    shooter:set_attr("firing_info", {
        self.gun_index,
        target_position.x,
        target_position.y,
        target_position.z,
        target_entity and target_entity.uid or -1
    })
end

function gun:get_origin(shooter)
    return _C.get_attachment_position(shooter, self.origin_tag)
end

function gun:do_recoil(shooter, magnitude)
    if CLIENT and shooter ~= ents.get_player() then return nil end

    if shooter:get_attr("can_move") then
        local dir = math.Vec3():from_yaw_pitch(
            shooter:get_attr("yaw"), shooter:get_attr("pitch")
        ):normalize(1)
         :mul(-magnitude)
        shooter:get_attr("velocity"):add(dir)
    end
end

local ATTACK1 = model.register_anim("attack1")
local ATTACK2 = model.register_anim("attack2")
local ATTACK3 = model.register_anim("attack3")

action_shoot1 = ents.Local_Animation_Action:clone {
    name = "action_shoot"
}
action_shoot1.local_animation = ATTACK1
action_shoot1.cancellable = false

-- convenience
action_shoot = action_shoot1

action_shoot2 = ents.Local_Animation_Action:clone {
    name = "action_shoot"
}
action_shoot2.local_animation = ATTACK2
action_shoot2.cancellable = false

action_shoot3 = ents.Local_Animation_Action:clone {
    name = "action_shoot"
}
action_shoot3.local_animation = ATTACK3
action_shoot3.cancellable = false

action_shoot2_repeating = ents.Local_Animation_Action:clone {
    name = "action_shoot"
}
action_shoot2_repeating.local_animation = math.bor(
    ATTACK2,
    model.anims.LOOP
)
action_shoot2_repeating.cancellable = false

action_out_of_ammo = actions.Action:clone {
    name = "action_out_of_ammo"
}
action_out_of_ammo.seconds_left       = 0.5
action_out_of_ammo.cancellable        = false
action_out_of_ammo.can_multiply_queue = false

function action_out_of_ammo:start()
    local player = ents.get_player()

    local message = player.out_of_ammo_msg or "(Out of ammo)"
    local color   = player.out_of_ammo_msg_color or 0xAA8833
    local dur     = player.out_of_ammo_msg_duration or 1.5
    local size    = player.out_of_ammo_msg_size or 0.5
    local snd     = player.out_of_ammo_sound or ""

    game_manager.get_singleton():add_hud_message(message, color, dur, size)
    if snd ~= "" then
        sound.play(snd)
    end
end
