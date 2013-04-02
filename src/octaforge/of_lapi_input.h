#ifdef CLIENT
bool getkeydown();
bool getkeyup();
bool getmousedown();
bool getmouseup();
#endif
namespace lapi_binds
{
#ifdef CLIENT
    bool _lua_set_targeted_entity(int uid)
    {
        if (TargetingControl::targetLogicEntity)
            delete TargetingControl::targetLogicEntity;

        TargetingControl::targetLogicEntity = LogicSystem::getLogicEntity(uid);
        return (TargetingControl::targetLogicEntity != NULL);
    }

    bool _lua_is_modifier_pressed()
    {
        return (SDL_GetModState() != KMOD_NONE);
    }

    void _lua_keyrepeat(bool on, int mask)
    {
        keyrepeat(on, mask);
    }

    void _lua_textinput(bool on, int mask)
    {
        textinput(on, mask);
    }
#else
    LAPI_EMPTY(set_targeted_entity)
    LAPI_EMPTY(is_modifier_pressed)
    LAPI_EMPTY(textinput)
    LAPI_EMPTY(keyrepeat)
#endif

    void reg_input(lua::Table& t)
    {
        LAPI_REG(set_targeted_entity);
        LAPI_REG(is_modifier_pressed);
        LAPI_REG(textinput);
        LAPI_REG(keyrepeat);
    }
}
