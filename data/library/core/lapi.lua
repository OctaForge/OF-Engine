return {
    Input = {
        Events = {
            Client = {
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
            }
        }
    }
}
