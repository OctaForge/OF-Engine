bool getkeydown();
bool getkeyup();
bool getmousedown();
bool getmouseup();

namespace lapi_binds
{
    using namespace MessageSystem;

    #define QUOT(arg) #arg

    #define MOUSECLICK(num) \
    void _lua_mouse##num##click() \
    { \
        bool down = (addreleaseaction( \
            lapi::state.get<lua::Function>("CAPI", QUOT(mouse##num##click)) \
        ) != 0); \
        logger::log(logger::INFO, "mouse click: %i (down: %i)\n", num, down); \
\
        if (!(lapi::state.state() && ClientSystem::scenarioStarted())) \
            return; \
\
        TargetingControl::determineMouseTarget(true); \
        vec pos = TargetingControl::targetPosition; \
\
        CLogicEntity *tle = TargetingControl::targetLogicEntity; \
\
        int uid = -1; \
        if (tle && !tle->isNone()) uid = tle->getUniqueId(); \
\
        lua::Function f(lapi::state["client_click"]); \
        if (f.is_nil()) \
        { \
            if (tle && !tle->isNone()) \
            { \
                f = tle->lua_ref["client_click"]; \
                if (f.is_nil()) \
                    send_DoClick(num, (int)down, pos.x, pos.y, pos.z, uid); \
                else \
                { \
                    float x; \
                    float y; \
                    gui::getcursorpos(x, y); \
\
                    if (!f.call<bool>(tle->lua_ref, num, down, pos, x, y)) \
                        send_DoClick( \
                            num, (int)down, pos.x, pos.y, pos.z, uid \
                        ); \
                } \
                return; \
            } \
            send_DoClick(num, (int)down, pos.x, pos.y, pos.z, uid); \
        } \
        else \
        { \
            float x; \
            float y; \
            gui::getcursorpos(x, y); \
\
            if (!f.call<bool>( \
                num, down, pos, \
                ((tle && !tle->isNone()) ? tle->lua_ref : lua::Table()), \
                x, y \
            )) send_DoClick(num, (int)down, pos.x, pos.y, pos.z, uid); \
        } \
    }

    MOUSECLICK(1)
    MOUSECLICK(2)
    MOUSECLICK(3)
    #undef QUOT

    bool k_turn_left, k_turn_right, k_look_up, k_look_down;

    #define SCRIPT_DIR(name, v, p, d, s, os) \
    void _lua_##name() \
    { \
        if (ClientSystem::scenarioStarted()) \
        { \
            CLogicEntity *e = ClientSystem::playerLogicEntity; \
            e->lua_ref.get<lua::Function>( \
                "action_system", "clear" \
            )(e->lua_ref); \
\
            s = (addreleaseaction( \
                lapi::state.get<lua::Function>("CAPI", #name) \
            ) != 0); \
\
            lua::Function f = lapi::state[#v]; \
            if (f.is_nil()) \
            { \
                lapi::state.get<lua::Function>( \
                    "entity_store", "get_player_entity" \
                ).call<lua::Table>()[#p] = (s ? d : (os ? -(d) : 0)); \
            } \
            else f((s ? d : (os ? -(d) : 0)), s); \
        } \
    }

    SCRIPT_DIR(turn_left,  do_yaw, yawing, -1, k_turn_left,  k_turn_right);
    SCRIPT_DIR(turn_right, do_yaw, yawing, +1, k_turn_right, k_turn_left);
    SCRIPT_DIR(look_down, do_pitch, pitching, -1, k_look_down, k_look_up);
    SCRIPT_DIR(look_up,   do_pitch, pitching, +1, k_look_up,   k_look_down);

    // Old player movements
    SCRIPT_DIR(backward, do_movement, move, -1, player->k_down,  player->k_up);
    SCRIPT_DIR(forward, do_movement, move,  1, player->k_up,   player->k_down);
    SCRIPT_DIR(left,   do_strafe, strafe,  1, player->k_left, player->k_right);
    SCRIPT_DIR(right, do_strafe, strafe, -1, player->k_right, player->k_left);

    void _lua_jump()
    {
        if (ClientSystem::scenarioStarted())
        {
            CLogicEntity *e = ClientSystem::playerLogicEntity;
            e->lua_ref.get<lua::Function>(
                "action_system", "clear"
            )(e->lua_ref);

            bool down = (addreleaseaction(
                lapi::state.get<lua::Function>("CAPI", "jump")
            ) ? true : false);

            lua::Function f = lapi::state["do_jump"];
            if (f.is_nil())
            {
                if (down)
                {
                    lua::Table ple = lapi::state.get<lua::Function>(
                        "entity_store", "get_player_entity"
                    ).call<lua::Table>();
                    ple.get<lua::Function>("jump")(ple);
                }
            }
            else f(down);
        }
    }

    bool _lua_set_targeted_entity(int uid)
    {
        if (TargetingControl::targetLogicEntity)
            delete TargetingControl::targetLogicEntity;

        TargetingControl::targetLogicEntity = LogicSystem::getLogicEntity(uid);
        return (TargetingControl::targetLogicEntity != NULL);
    }

    void reg_input(lua::Table& t)
    {
        LAPI_REG(mouse1click);
        LAPI_REG(mouse2click);
        LAPI_REG(mouse3click);
        LAPI_REG(turn_left);
        LAPI_REG(turn_right);
        LAPI_REG(look_down);
        LAPI_REG(look_up);
        LAPI_REG(backward);
        LAPI_REG(forward);
        LAPI_REG(left);
        LAPI_REG(right);
        LAPI_REG(jump);
        LAPI_REG(set_targeted_entity);
    }
}
