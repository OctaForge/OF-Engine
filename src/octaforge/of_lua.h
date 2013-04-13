#ifndef OF_LAPI_H
#define OF_LAPI_H

namespace lua
{
    extern lua_State *L;
    bool reg_fun      (const char *name, lua_CFunction fun, bool onst = false);
    void init         (const char *dir = "data/library/core");
    void reset        ();
    bool load_library (const char *name);
    void push_external(const char *name);
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

#endif
