#ifndef OF_LAPI_H
#define OF_LAPI_H

namespace lua
{
    extern lua_State *L;
    bool reg_fun   (const char *name, lua_CFunction fun);
    bool reg_cfun  (const char *name, const char *sig, void *fun);
    void init      (const char *dir = "media/lua/core");
    void reset     ();
    void close     ();
    int load_string(const char *str, const char *ch = NULL);

    bool call_external(lua_State *L, const char *name, const char *args, ...);
    bool call_external(              const char *name, const char *args, ...);

    int call_external_ret(lua_State *L, const char *name, const char *args,
        const char *retargs, ...);
    int call_external_ret(              const char *name, const char *args,
        const char *retargs, ...);

    void pop_external_ret(lua_State *L, int n);
    void pop_external_ret(int n);
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

#define CLUACOMMAND(nm, rett, argt, fun) \
    static bool __dummyc_##nm = lua::reg_cfun(#nm, #rett "(*)" #argt, \
        (void*)fun);

#define CLUAICOMMAND(nm, rett, argt, body) \
    template<int N> struct _lcfn_##nm; \
    template<> struct _lcfn_##nm<__LINE__> { \
        static bool init; static rett fun argt; \
    }; \
    bool _lcfn_##nm<__LINE__>::init = lua::reg_cfun(#nm, #rett "(*)" #argt, \
         (void*)_lcfn_##nm<__LINE__>::fun); \
    rett _lcfn_##nm<__LINE__>::fun argt { \
        body; \
    }

#define LUA_GET_ENT(name, uid, _log, retexpr) \
    CLogicEntity *name = LogicSystem::getLogicEntity(uid); \
    if (!name) { \
        logger::log(logger::ERROR, "Cannot find CLE for entity %i (%s).", \
            uid, _log); \
        retexpr; \
    }

#endif
