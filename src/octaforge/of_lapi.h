#ifndef OF_LAPI_H
#define OF_LAPI_H

#include "OFTL/lua.h"

namespace lapi
{
    extern lua::State state;
    extern lua_State *L;

    void init        (const char *dir = "data/library/core");
    void reset       ();
    bool load_library(const char *name);
}

namespace lua {
    void push(lua_State *L, bool v);
    void push(lua_State *L, lua_CFunction v);
    void push(lua_State *L, const char *v);
    void push(lua_State *L, lua_Number v);
    void push(lua_State *L, lua_Integer n);
    void push(lua_State *L, lua_CFunction f, int n);
    void push(lua_State *L, const char *s, size_t l);
    void push(lua_State *L);
}

#endif
