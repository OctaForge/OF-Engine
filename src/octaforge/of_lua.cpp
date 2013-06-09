#include "cube.h"
#include "engine.h"
#include "game.h"

#include "of_lua.h"
#include "of_tools.h"

#ifndef SERVER
    #include "client_system.h"
    #include "targeting.h"
#endif
#include "editing_system.h"
#include "message_system.h"

#include "of_world.h"
#include "of_localserver.h"

#define LAPI_REG(name) LUACOMMAND(name, _lua_##name)
#define LAPI_EMPTY(name) int _lua_##name(lua_State *L) \
{ logger::log(logger::DEBUG, "stub: _C."#name"\n"); return 0; }

#include "of_lua_api.h"

#undef LAPI_EMPTY
#undef LAPI_REG

namespace lua
{
    lua_State *L = NULL;
    static string mod_dir = "";

    static int panic(lua_State *L) {
        lua_pushfstring(L, "error in call to the Lua API (%s)",
            lua_tostring(L, -1));
        fatal("%s", lua_tostring(L, -1));
        return 0;
    }

    void setup_binds();

    LUAICOMMAND(table_create, {
        lua_createtable(L, luaL_optinteger(L, 1, 0), luaL_optinteger(L, 2, 0));
        return 1;
    });

    static hashtable<const char*, int> externals;

    bool push_external(lua_State *L, const char *name) {
        int *ref = externals.access(name);
        if  (ref) {
            lua_rawgeti(L, LUA_REGISTRYINDEX, *ref);
            return true;
        }
        return false;
    }

    bool push_external(const char *name) {
        return push_external(L, name);
    }

    LUAICOMMAND(external_set, {
        const char *name = luaL_checkstring(L, 1);
        int *ref = externals.access(name);
        if  (ref) {
            lua_rawgeti(L, LUA_REGISTRYINDEX, *ref);
            luaL_unref (L, LUA_REGISTRYINDEX, *ref);
        } else {
            lua_pushnil(L);
        }
        /* let's pin the name so the garbage collector doesn't free it */
        lua_pushvalue(L, 1); lua_setfield(L, LUA_REGISTRYINDEX, name);
        /* and now we can ref */
        lua_pushvalue(L, 2);
        externals.access(name, luaL_ref(L, LUA_REGISTRYINDEX));
        return 1;
    });

    LUAICOMMAND(external_unset, {
        const char *name = luaL_checkstring(L, 1);
        int *ref = externals.access(name);
        if (!ref) {
            lua_pushboolean(L, false);
            return 1;
        }
        /* unpin the name */
        lua_pushnil(L); lua_setfield(L, LUA_REGISTRYINDEX, name);
        /* and unref */
        luaL_unref(L, LUA_REGISTRYINDEX, *ref);
        lua_pushboolean(L, externals.remove(name));
        return 1;
    });

    LUAICOMMAND(external_get, {
        if (!push_external(luaL_checkstring(L, 1))) lua_pushnil(L);
        return 1;
    });

    struct Reg {
        const char *name;
        lua_CFunction fun;
    };
    typedef vector<Reg> cfuns;
    static cfuns *funs = NULL;

    bool reg_fun(const char *name, lua_CFunction fun) {
        if (!funs) {
            funs = new cfuns;
        }
        funs->add((Reg){ name, fun });
        return true;
    }

    void init(const char *dir)
    {
        if (L) return;
        copystring(mod_dir, dir);

        L = luaL_newstate();
        lua_atpanic(L, panic);

        #define MODOPEN(name) \
            lua_pushcfunction(L, luaopen_##name); \
            lua_call(L, 0, 0);

        MODOPEN(base)
        MODOPEN(table)
        MODOPEN(string)
        MODOPEN(math)
        MODOPEN(package)
        MODOPEN(debug)
        MODOPEN(os)
        MODOPEN(io)
        MODOPEN(ffi)
        MODOPEN(bit)

        lua_getglobal(L, "package");

        /* home directory paths */
        lua_pushfstring(
            L, ";%smedia%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV
        );
        lua_pushfstring(
            L, ";%smedia%c?.lua",
            homedir, PATHDIV
        );
        lua_pushfstring(
            L, ";%smedia%clua%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV, PATHDIV
        );
        lua_pushfstring(
            L, ";%smedia%clua%c?.lua",
            homedir, PATHDIV, PATHDIV
        );

        /* root paths */
        lua_pushliteral(L, ";./media/?/init.lua");
        lua_pushliteral(L, ";./media/?.lua");
        lua_pushliteral(L, ";./media/lua/?/init.lua");
        lua_pushliteral(L, ";./media/lua/?.lua");

        lua_concat  (L,  8);
        lua_setfield(L, -2, "path"); lua_pop(L, 1);

        setup_binds();
    }

    void load_module(const char *name)
    {
        defformatstring(p)("%s%c%s.lua", mod_dir, PATHDIV, name);
        logger::log(logger::DEBUG, "Loading OF Lua module: %s.\n", p);
        if (luaL_loadfile(L, p) || lua_pcall(L, 0, 0, 0)) {
            fatal("%s", lua_tostring(L, -1));
        }
    }

    static int capi_tostring(lua_State *L) {
        lua_pushfstring(L, "C API: %d entries",
                lua_tointeger(L, lua_upvalueindex(1)));
        return 1;
    }

    void setup_binds()
    {
#ifndef SERVER
        lua_pushboolean(L,  true); lua_setglobal(L, "CLIENT");
        lua_pushboolean(L, false); lua_setglobal(L, "SERVER");
#else
        lua_pushboolean(L, false); lua_setglobal(L, "CLIENT");
        lua_pushboolean(L,  true); lua_setglobal(L, "SERVER");
#endif

        assert(funs);
        lua_newuserdata(L, 0);                 /* _C */
        lua_createtable(L, 0, 2);              /* _C, C_mt */
        int numfields = funs->length();
        lua_createtable(L, numfields, 0);      /* _C, C_mt, C_tbl */
        for (int i = 0; i < numfields; ++i) {
            const Reg& reg = (*funs)[i];
            lua_pushcfunction(L, reg.fun);
            lua_setfield(L, -2, reg.name);
        }
        delete funs;
        funs = NULL;
        lua_setfield(L, -2, "__index");        /* _C, C_mt */
        lua_pushinteger(L, numfields);         /* _C, C_mt, C_num */
        lua_pushcclosure(L, capi_tostring, 1); /* _C, C_mt, C_tostring */
        lua_setfield(L, -2, "__tostring");     /* _C, C_mt */
        lua_pushboolean(L, 0);                 /* _C, C_mt, C_metatable */
        lua_setfield(L, -2, "__metatable");    /* _C, C_mt */
        lua_setmetatable(L, -2);               /* _C */
        lua_getfield (L, LUA_REGISTRYINDEX, "_LOADED");
        lua_pushvalue(L, -2); lua_setfield (L, -2, "_C");
        lua_pop      (L,  1);
        lua_setglobal(L, "_C");
        load_module("init");
        lua_getglobal(L, "require");
        lua_pushliteral(L, "gui");
        lua_call(L, 1, 0);
    }

    void reset() {}
} /* end namespace lua */
