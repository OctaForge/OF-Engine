#include "cube.h"
#include "engine.h"
#include "game.h"

#include "of_lua.h"
#include "of_tools.h"

#ifdef CLIENT
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

extern string homedir;

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

    static int create_table(lua_State *L) {
        lua_createtable(L, luaL_optinteger(L, 1, 0), luaL_optinteger(L, 2, 0));
        return 1;
    }

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

    static int set_external(lua_State *L) {
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
    }

    static int unset_external(lua_State *L) {
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
    }

    static int get_external(lua_State *L) {
        if (!push_external(luaL_checkstring(L, 1))) lua_pushnil(L);
        return 1;
    }

    struct Reg {
        const char *name;
        lua_CFunction fun;
    };
    typedef vector<Reg> cfuns;
    static cfuns *funs = NULL;

    bool reg_fun(const char *name, lua_CFunction fun, bool onst) {
        if (!L) {
            if (!funs) {
                funs = new cfuns;
            }
            funs->add((Reg){ name, fun });
            return true;
        }
        if (!onst) lua_getglobal(L, "_C");
        lua_pushcfunction(L, fun);
        lua_setfield(L, -2, name);
        if (!onst) lua_pop(L, 1);
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
            L, ";%sdata%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV
        );
        lua_pushfstring(
            L, ";%sdata%c?.lua",
            homedir, PATHDIV
        );
        lua_pushfstring(
            L, ";%sdata%clibrary%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV, PATHDIV
        );

        /* root paths */
        lua_pushliteral(L, ";./data/library/core/?.lua");
        lua_pushliteral(L, ";./data/library/core/?/init.lua");
        lua_pushliteral(L, ";./data/?/init.lua");
        lua_pushliteral(L, ";./data/?.lua");
        lua_pushliteral(L, ";./data/library/?/init.lua");

        lua_concat  (L,  8);
        lua_setfield(L, -2, "path"); lua_pop(L, 1);

        lua_pushcfunction(L, create_table);
        lua_setglobal    (L, "createtable");
        lua_pushcfunction(L,  set_external);
        lua_setglobal    (L, "set_external");
        lua_pushcfunction(L,  unset_external);
        lua_setglobal    (L, "unset_external");
        lua_pushcfunction(L,  get_external);
        lua_setglobal    (L, "get_external");

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

    void setup_binds()
    {
#ifdef CLIENT
        lua_pushboolean(L,  true); lua_setglobal(L, "CLIENT");
        lua_pushboolean(L, false); lua_setglobal(L, "SERVER");
#else
        lua_pushboolean(L, false); lua_setglobal(L, "CLIENT");
        lua_pushboolean(L,  true); lua_setglobal(L, "SERVER");
#endif
        lua_pushinteger(L, OF_CFG_VERSION); lua_setglobal(L, "OF_CFG_VERSION");

        assert(funs);
        lua_createtable(L, funs->length(), 0);
        loopv(*funs) {
            const Reg& reg = (*funs)[i];
            reg_fun(reg.name, reg.fun, true);
        }
        delete funs;
        funs = NULL;
        lua_getfield (L, LUA_REGISTRYINDEX, "_LOADED");
        lua_pushvalue(L, -2); lua_setfield (L, -2, "_C");
        lua_pop      (L,  1);
        lua_setglobal(L, "_C");
        load_module("init");
    }

    void reset() {}

    bool load_library(const char *name)
    {
        if (!name || strstr(name, "..")) return false;

        lua_getglobal(L, "package");

        lua_getglobal  (L, "string"); lua_getfield(L, -1, "find");
        lua_getfield   (L, -3, "path"); 
        lua_pushfstring(L, ";./data/library/%s/?.lua", name);
        lua_call       (L, 2, 1);

        if (!lua_isnil(L, -1)) {
            lua_pop(L, 3);
            return true;
        }
        lua_pop(L, 2);

        /* original path */
        lua_getfield(L, -1, "path");

        /* home directory path */
        lua_pushfstring(
            L, ";%sdata%clibrary%c%s%c?.lua",
            homedir, PATHDIV, PATHDIV, name, PATHDIV
        );

        /* root path */
        lua_pushfstring(L, ";./data/library/%s/?.lua", name);

        lua_concat  (L,  3);
        lua_setfield(L, -2, "path");

        return true;
    }
} /* end namespace lapi */
