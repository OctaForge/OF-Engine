#ifndef OF_LAPI_H
#define OF_LAPI_H

namespace lua
{
    extern lua_State *L;
    bool reg_fun      (const char *name, lua_CFunction fun);
    void init         (const char *dir = "media/lua/core");
    void reset        ();
    bool push_external(const char *name);
    bool push_external(lua_State *L, const char *name);
    void pin_string   (const char *str);
    void unpin_string (const char *str);
    void pin_string   (lua_State *L, const char *str);
    void unpin_string (lua_State *L, const char *str);
}

#define LUACOMMAND(name, fun) \
    static bool __dummy_##name = lua::reg_fun(#name, fun);

#define LUAICOMMANDN(name, state, body) \
    template<int N> struct _lfn_##name; \
    template<> struct _lfn_##name<__LINE__> { \
        static bool init; static int fun(lua_State*); \
    }; \
    bool _lfn_##name<__LINE__>::init = lua::reg_fun(#name, \
         _lfn_##name<__LINE__>::fun); \
    int  _lfn_##name<__LINE__>::fun(lua_State *state) { \
        body; \
    }

#define LUAICOMMAND(name, body) LUAICOMMANDN(name, L, body)

#define LUA_GET_ENT(name, _log, retexpr) \
    lua_getfield(L, 1, "uid"); \
    int uid = lua_tointeger(L, -1); \
    lua_pop(L, 1); \
    CLogicEntity *name = LogicSystem::getLogicEntity(uid); \
    if (!name) { \
        logger::log(logger::ERROR, "Cannot find CLE for entity %i (%s).\n", \
            uid, _log); \
        retexpr; \
    }

#endif
