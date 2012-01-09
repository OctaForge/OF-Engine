#ifdef CLIENT
bool getkeydown();
bool getkeyup();
bool getmousedown();
bool getmouseup();
#endif
namespace lapi_binds
{
#ifdef CLIENT
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
        float x; \
        float y; \
        gui::getcursorpos(x, y); \
\
        if (!lapi::state.get<lua::Function>( \
            "LAPI", "Input", "Events", "Client", "click" \
        ).call<bool>( \
            num, down, pos, \
            ((tle && !tle->isNone()) ? tle->lua_ref : \
                lapi::state.wrap<lua::Table>(lua::nil) \
            ), \
            x, y \
        )) send_DoClick(num, (int)down, pos.x, pos.y, pos.z, uid); \
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
            lapi::state.get<lua::Function>( \
                "LAPI", "World", "Entity", "clear_actions" \
            )(e->lua_ref); \
\
            s = (addreleaseaction( \
                lapi::state.get<lua::Function>("CAPI", #name) \
            ) != 0); \
\
            lapi::state.get<lua::Function>( \
                "LAPI", "Input", "Events", "Client", #v \
            )((s ? d : (os ? -(d) : 0)), s); \
        } \
    }

    SCRIPT_DIR(turn_left,  yaw, yawing, -1, k_turn_left,  k_turn_right);
    SCRIPT_DIR(turn_right, yaw, yawing, +1, k_turn_right, k_turn_left);
    SCRIPT_DIR(look_down, pitch, pitching, -1, k_look_down, k_look_up);
    SCRIPT_DIR(look_up,   pitch, pitching, +1, k_look_up,   k_look_down);

    // Old player movements
    SCRIPT_DIR(backward, move, move, -1, player->k_down,  player->k_up);
    SCRIPT_DIR(forward, move, move,  1, player->k_up,   player->k_down);
    SCRIPT_DIR(left,   strafe, strafe,  1, player->k_left, player->k_right);
    SCRIPT_DIR(right, strafe, strafe, -1, player->k_right, player->k_left);

    void _lua_jump()
    {
        if (ClientSystem::scenarioStarted())
        {
            CLogicEntity *e = ClientSystem::playerLogicEntity;
            lapi::state.get<lua::Function>(
                "LAPI", "World", "Entity", "clear_actions"
            )(e->lua_ref);

            bool down = (addreleaseaction(
                lapi::state.get<lua::Function>("CAPI", "jump")
            ) ? true : false);

            lapi::state.get<lua::Function>(
                "LAPI", "Input", "Events", "Client", "jump"
            )(down);
        }
    }

    bool _lua_set_targeted_entity(int uid)
    {
        if (TargetingControl::targetLogicEntity)
            delete TargetingControl::targetLogicEntity;

        TargetingControl::targetLogicEntity = LogicSystem::getLogicEntity(uid);
        return (TargetingControl::targetLogicEntity != NULL);
    }
#else
    LAPI_EMPTY(mouse1click)
    LAPI_EMPTY(mouse2click)
    LAPI_EMPTY(mouse3click)
    LAPI_EMPTY(turn_left)
    LAPI_EMPTY(turn_right)
    LAPI_EMPTY(look_down)
    LAPI_EMPTY(look_up)
    LAPI_EMPTY(backward)
    LAPI_EMPTY(forward)
    LAPI_EMPTY(left)
    LAPI_EMPTY(right)
    LAPI_EMPTY(jump)
    LAPI_EMPTY(set_targeted_entity)
#endif

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
