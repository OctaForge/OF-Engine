module("firing", package.seeall)

guns = {}

function register_gun(gun, comment, hud)
    local index = #guns
    comment = comment or tostring(index)

    guns[index]   = gun
    gun.gun_index = index
    gun.comment   = comment
    gun.hud       = hud

    return index
end

function client_click(button, down, position, entity)
    local player = entity_store.get_plyent()

    if button == 1 then
        if down then
            if player.canmove then
                player:start_shooting(position)
            end
        else
            -- TODO: autostop shooting when canmove changes to false (connect to signal)
            player:stop_shooting(position)
        end
    elseif button == 3 and down then
        cycle_gun_index(player, player.gun_indexes:as_array())
    end
end

function cycle_gun_index(entity, indexes)
    local curr = table.find(indexes, entity.current_gun_index) + 1
    if curr >= #indexes then
        curr = 1
    end
    entity.current_gun_index = indexes[curr]
end

function find_target(shooter, visual_origin, targeting_origin, range, scatter)
    -- targeting from the camera - where the player aimed the mouse
    local direction = math.vec3():fromyawpitch(shooter.yaw, shooter.pitch)
    if scatter then direction:add(math.vec3_norm():mul(scatter)):normalize() end

    local target = utility.get_ray_collision_world   (targeting_origin, direction, range)
    local temp   = utility.get_ray_collision_entities(targeting_origin, target,  shooter)
    local target_entity = nil

    if temp then
        target = temp.collision_position
        target_entity = temp.entity
    end

    -- check for hitting an entity from the gun source
    temp = utility.get_ray_collision_entities(visual_origin, target, shooter)
    if temp then
        target = temp.collision_position
        target_entity = temp.entity
    end

    -- check for hitting the scenery from the gun source
    direction  = target:subnew(visual_origin)
    local dist = direction:magnitude()
    if dist > 2 then
        local target2 = utility.get_ray_collision_world(visual_origin, direction:normalize(), dist)
        if target2:iscloseto(visual_origin, dist - 2) then
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
            firing_info = state_variables.state_array_float({ clientset = true, hashistory = false })
        },

        activate = function(self)
            self:connect(state_variables.get_onmodify_prefix() .. "firing_info", self.on_firing_info)
        end,

        client_activate = function(self)
            self:connect(state_variables.get_onmodify_prefix() .. "firing_info", self.on_firing_info)
        end,

        on_firing_info = function(self, info)
            -- do not shoot if just killed (even though canmove = false didn't arrive yet)
            if not health.is_valid_target(self) then return nil end

            if #info ~= 5 then return nil end
            local gun_index = info[1]
            local target_pos = math.vec3(info[2], info[3], info[4])
            local target_ent = entity_store.get(info[5])
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
            current_gun_index = state_variables.state_integer({ clientset = true }),
            gun_indexes = state_variables.state_array_integer(),
            gun_switch_sound = state_variables.state_string()
        },

        gun_ammos = {},

        init = function(self)
            for k, gun in pairs(guns) do
                local tag = "*" .. gun.origin_tag
                if gun.origin_tag and not table.find(self.attachments:as_array(), tag) then
                    self.attachments:push(tag)
                end
            end

            self.gun_indexes = {}
            self.gun_switch_sound = ""
        end,

        activate = function(self)
            self:connect(
                state_variables.get_onmodify_prefix() .. "gun_indexes",
                function(self, indexes)
                    if #indexes > 0 then
                        self.current_gun_index = indexes[1] -- sets initial value
                    end
                end
            )
        end,

        client_activate = function(self)
            self.gun_delay = 0
            self.last_handled_shot_counter = 0
            self.now_firing = false

            self:connect(
                state_variables.get_onmodify_prefix() .. "current_gun_index",
                function(self)
                    if self.gun_switch_sound ~= "" then
                        sound.play(self.gun_switch_sound, self.position:copy())
                    end
                end
            )
        end,

        client_act = function(self, seconds)
            if self ~= entity_store.get_plyent() then return nil end

            self.gun_delay = math.max(self.gun_delay - seconds, 0)

            local gun = guns[self.current_gun_index]
            if gun then
                if self.now_firing and self.gun_delay == 0 then
                    if  self.gun_ammos[self.current_gun_index]
                    and self.gun_ammos[self.current_gun_index] <= 0 then
                        self:queue_action(action_out_of_ammo())
                        self:stop_shooting(gun)
                    else
                        gun:do_shot(self, utility.gettargetpos(), utility.gettargetent())
                        if  self.gun_ammos[self.current_gun_index]
                        and self.gun_ammos[self.current_gun_index] ~= 0 then
                            self.gun_ammos[self.current_gun_index] = -1
                        end
                        self.gun_delay = self.gun_delay + gun.delay
                        if not gun.repeating then
                            self:stop_shooting(gun)
                        end

                        if not GLOBAL_GAME_HUD then
                            gui.showhudimage(gun.hud, 0.80, 0.88, 0.05, 0.05)
                        else
                            local params = GLOBAL_GAME_HUD:get_firing_params(gun)
                            gui.showhudimage(
                                params.gun.icon,
                                params.gun.x, params.gun.y,
                                params.gun.w, params.gun.h
                            )
                            if params.ammo1 then
                                gui.showhudimage(
                                    params.ammo1.icon,
                                    params.ammo1.x, params.ammo1.y,
                                    params.ammo1.w, params.ammo1.h
                                )
                            end
                            if params.ammo2 then
                                gui.showhudimage(
                                    params.ammo2.icon,
                                    params.ammo2.x, params.ammo2.y,
                                    params.ammo2.w, params.ammo2.h
                                )
                            end
                        end
                    end
                end
            end
        end,

        start_shooting = function(self, position)
            self.now_firing = true
        end,

        stop_shooting = function(self, position)
            local gun = guns[self.current_gun_index]

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

gun = class.new()

gun.handle_start_logic   = nil
gun.handle_client_effect = nil

function gun:do_shot(shooter, target_position, target_entity)
    -- do not shoot if just killed (even though canmove = false didn't arrive yet)
    if not health.is_valid_target(shooter) then return nil end

    if self.handle_start_logic then
        if not self:handle_start_logic(shooter, self:get_origin(shooter), target_position, target_entity) then
            return nil
        end
    end

    shooter.firing_info = {
        self.gun_index,
        target_position.x,
        target_position.y,
        target_position.z,
        target_entity and target_entity.uid or -1
    }
end

function gun:get_origin(shooter)
    return CAPI.getattachmentpos(shooter, self.origin_tag)
end

function gun:do_recoil(shooter, magnitude)
    if CLIENT and shooter ~= entity_store.get_plyent() then return nil end

    if shooter.canmove then
        local dir = math.vec3():fromyawpitch(
            shooter.yaw, shooter.pitch
        ):normalize(1)
         :mul(-magnitude)
        shooter.velocity:add(dir)
    end
end

action_shoot1 = class.new(entity_animated.action_localanim)
action_shoot1.localanim      = actions.ANIM_ATTACK1
action_shoot1.canbecancelled = false
function action_shoot1:__tostring() return "action_shoot" end

-- convenience
action_shoot = action_shoot1

action_shoot2 = class.new(entity_animated.action_localanim)
action_shoot2.localanim      = actions.ANIM_ATTACK2
action_shoot2.canbecancelled = false
function action_shoot2:__tostring() return "action_shoot" end

action_shoot3 = class.new(entity_animated.action_localanim)
action_shoot3.localanim      = actions.ANIM_ATTACK3
action_shoot3.canbecancelled = false
function action_shoot3:__tostring() return "action_shoot" end


action_shoot2_repeating = class.new(entity_animated.action_localanim)
action_shoot2_repeating.localanim = math.bor(
    actions.ANIM_ATTACK2,
    actions.ANIM_LOOP
)
action_shoot2_repeating.canbecancelled = false
function action_shoot2_repeating:__tostring() return "action_shoot" end

action_out_of_ammo = class.new(actions.action)
action_out_of_ammo.secondsleft    = 0.5
action_out_of_ammo.canbecancelled = false
action_out_of_ammo.canmulqueue    = false

function action_out_of_ammo:__tostring() return "action_out_of_ammo" end
function action_out_of_ammo:dostart()
    local player = entity_store.get_plyent()

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
