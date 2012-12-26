return {
    Math = {
        make_vec3 = function(x, y, z)
            return math.Vec3(x, y, z)
        end,
        make_vec4 = function(x, y, z, w)
            return math.Vec4(x, y, z, w)
        end
    },
    Input = {
        Events = {
            Client = {
                mouse_move = function(yaw, pitch)
                    if not do_mousemove then
                        return { yaw = yaw, pitch = pitch }
                    end

                    return do_mousemove(yaw, pitch)
                end,
                click = function(num, down, pos, ent, x, y)
                    if client_click then
                        return client_click(num, down, pos, ent, x, y)
                    end

                    if ent and ent.client_click then
                        return ent:client_click(num, down, pos, x, y)
                    end
                end,
                yaw = function(dir, down)
                    if do_yaw then
                        return do_yaw(dir, down)
                    end
                    ents.get_player().yawing = dir
                end,
                pitch = function(dir, down)
                    if do_pitch then
                        return do_pitch(dir, down)
                    end
                    ents.get_player().pitching = dir
                end,
                move = function(dir, down)
                    if do_movement then
                        return do_movement(dir, down)
                    end
                    ents.get_player().move = dir
                end,
                strafe = function(dir, down)
                    if do_strafe then
                        return do_strafe(dir, down)
                    end
                    ents.get_player().strafe = dir
                end,
                jump = function(down)
                    if do_jump then
                        return do_jump(down)
                    end
                    if down then
                        ents.get_player():jump()
                    end
                end
            },
            Server = {
                click = function(num, down, pos, ent)
                    if click then
                        return click(num, down, pos, ent)
                    end

                    if ent and ent.click then
                        ent:click(num, down, pos)
                    end
                end
            }
        },
        get_local_bind = function(name)
            return input.per_map_keys[name]
        end
    },
    World = {
        Events = {
            Client = {
                off_map = function(ent)
                    if not client_on_ent_offmap then
                        return nil
                    end

                    return client_on_ent_offmap(ent)
                end
            },
            Server = {
                off_map = function(ent)
                    if not on_ent_offmap then
                        return nil
                    end

                    return on_ent_offmap(ent)
                end,
                player_login = function(ent)
                end
            },
            text_message = function(uid, text)
                if handle_textmsg then
                    return handle_textmsg(uid, text)
                end

                return false
            end
        }
    }
}
