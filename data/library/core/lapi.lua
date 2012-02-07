return {
    Math = {
        make_vec3 = function(x, y, z)
            return std.math.Vec3(x, y, z)
        end,
        make_vec4 = function(x, y, z, w)
            return std.math.Vec4(x, y, z, w)
        end
    },
    Graphics = {
        reset = engine.resetgl
    },
    Sound = {
        reset = sound.reset
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
                    entity_store.get_player_entity().yawing = dir
                end,
                pitch = function(dir, down)
                    if do_pitch then
                        return do_pitch(dir, down)
                    end
                    entity_store.get_player_entity().pitching = dir
                end,
                move = function(dir, down)
                    if do_movement then
                        return do_movement(dir, down)
                    end
                    entity_store.get_player_entity().move = dir
                end,
                strafe = function(dir, down)
                    if do_strafe then
                        return do_strafe(dir, down)
                    end
                    entity_store.get_player_entity().strafe = dir
                end,
                jump = function(down)
                    if do_jump then
                        return do_jump(down)
                    end
                    if down then
                        entity_store.get_player_entity():jump()
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
    GUI = {
        Names = {
            can_quit = "can_quit"
        },
        HUD = {
            edit = function()
                if not edithud then
                    return nil
                end

                return edithud()
            end,
            game = function()
                if not gamehud then
                    return nil
                end

                return gamehud()
            end
        },
        show = gui.show,
        hide = gui.hide,
        show_changes = gui.show_changes,
        show_message = gui.message
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
        },
        Entity = {
            Properties = {
                position     = "position",
                id           = "uid",
                cn           = "cn",
                facing_speed = "facing_speed",
                can_edit     = "can_edit",
                name         = "_name",
                collision_w  = "collision_radius_width",
                collision_h  = "collision_radius_height",
                initialized  = "initialized",
                rendering_hash_hint = "rendering_hash_hint"
            },
            create_state_data_dict = function(ent)
                return ent:create_state_data_dict()
            end,
            add_sauer = function(etype, pos, a1, a2, a3, a4)
                return entity_store.add_sauer(etype, pos, a1, a2, a3, a4)
            end,
            clear_actions = function(ent)
                return ent.action_system:clear()
            end,
            set_state_data = entity_store.set_state_data,
            make_player    = entity_store.set_player_uid,
            update_complete_state_data = function(ent, sd)
                return  ent:update_complete_state_data(sd)
            end,
            set_local_animation = function(ent, anim)
                return ent:set_local_animation (anim)
            end
        },
        Entities = {
            Classes = {
                get            = entity_classes.get_class,
                get_sauer_type = entity_classes.get_sauer_type
            },
            add        = entity_store.add,
            new        = entity_store.new,
            delete     = entity_store.del,
            delete_all = entity_store.del_all,
            save_all   = entity_store.save_entities,
            get        = entity_store.get,
            get_all    = entity_store.get_all,
            send       = entity_store.send_entities,
            gen_id     = entity_store.generate_uid,
            render     = entity_store.render_dynamic
        },
        scenario_started  = entity_store.has_scenario_started,
        render_hud        = entity_store.render_hud_model,
        manage_collisions = entity_store.manage_triggering_collisions,
        handle_frame      = std.frame.handle_frame,
        start_frame       = std.frame.start_frame
    },
    JSON = {
        encode = std.json.encode,
        decode = std.json.decode
    },
    Library = {
        is_unresettable = function(name)
            if name == "std" then
                return true
            end

            return false
        end,
        reset = std.library.reset
    }
}
