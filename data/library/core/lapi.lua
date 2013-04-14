return {
    Input = {
        Events = {
            Client = {
                mouse_move = function(yaw, pitch)
                    if not do_mousemove then
                        return { yaw = yaw, pitch = pitch }
                    end

                    return do_mousemove(yaw, pitch)
                end,
                click = function(num, down, px, py, pz, ent, x, y)
                    if client_click then
                        return client_click(num, down, math.Vec3(px, py, pz),
                            ent, x, y)
                    end

                    if ent and ent.client_click then
                        return ent:client_click(num, down,
                            math.Vec3(px, py, pz), x, y)
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
                click = function(num, down, x, y, z, ent)
                    if click then
                        return click(num, down, math.Vec3(x, y, z), ent)
                    end

                    if ent and ent.click then
                        ent:click(num, down, math.Vec3(x, y, z))
                    end
                end
            }
        }
    }
}
