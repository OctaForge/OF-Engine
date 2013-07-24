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

void deleteparticles();
void deletedecals();
void clearanims();

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
    typedef vector<Reg> apifuns;
    static apifuns *funs = NULL;

    struct CReg {
        const char *name, *sig;
        void *fun;
    };
    typedef vector<CReg> capifuns;
    static capifuns *cfuns = NULL;

    bool reg_fun(const char *name, lua_CFunction fun) {
        if (!funs) funs = new apifuns;
        funs->add((Reg){ name, fun });
        return true;
    }

    bool reg_cfun(const char *name, const char *sig, void *fun) {
        if (!cfuns) cfuns = new capifuns;
        cfuns->add((CReg){ name, sig, fun });
        return true;
    }

    void init(const char *dir)
    {
        if (L) return;
        copystring(mod_dir, dir);

        L = luaL_newstate();
        lua_atpanic(L, panic);
        luaL_openlibs(L);

        lua_getglobal(L, "package");

        /* home directory paths */
#ifndef WIN32
        lua_pushfstring(L, ";%smedia/?/init.lua", homedir);
        lua_pushfstring(L, ";%smedia/?.lua", homedir);
        lua_pushfstring(L, ";%smedia/lua/?/init.lua", homedir);
        lua_pushfstring(L, ";%smedia/lua/?.lua", homedir);
#else
        lua_pushfstring(L, ";%smedia\\?\\init.lua", homedir);
        lua_pushfstring(L, ";%smedia\\?.lua", homedir);
        lua_pushfstring(L, ";%smedia\\lua\\?\\init.lua", homedir);
        lua_pushfstring(L, ";%smedia\\lua\\?.lua", homedir);
#endif

        /* root paths */
        lua_pushliteral(L, ";./media/?/init.lua");
        lua_pushliteral(L, ";./media/?.lua");
        lua_pushliteral(L, ";./media/lua/?/init.lua");
        lua_pushliteral(L, ";./media/lua/?.lua");

        lua_concat  (L,  8);
        lua_setfield(L, -2, "path"); lua_pop(L, 1);

        /* string pinning */
        lua_newtable(L);
        lua_setfield(L, LUA_REGISTRYINDEX, "__pinstrs");

        setup_binds();
    }

    void load_module(const char *name)
    {
        defformatstring(p, "%s%c%s.lua", mod_dir, PATHDIV, name);
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

    static int capi_newindex(lua_State *L) {
        luaL_error(L, "attempt to write into the C API");
        return 0;
    }

    static int capi_get(lua_State *L) {
        lua_pushvalue(L, lua_upvalueindex(1));
        return 1;
    }

    void setup_binds()
    {
#ifndef SERVER
        lua_pushboolean(L, false);
#else
        lua_pushboolean(L, true);
#endif
        lua_setglobal(L, "SERVER");

        assert(funs);
        lua_getfield(L, LUA_REGISTRYINDEX, "_PRELOAD");
        int numfields = funs->length();
        int numcfields = cfuns ? cfuns->length() : 0;
        int tnf = numfields + numcfields;
        lua_createtable(L, tnf, 0);
        for (int i = 0; i < numfields; ++i) {
            const Reg &reg = (*funs)[i];
            lua_pushcfunction(L, reg.fun);
            lua_setfield(L, -2, reg.name);
        }
        lua_getglobal(L, "require");
        lua_pushliteral(L, "ffi");
        lua_call(L, 1, 1);
        lua_getfield(L, -1, "cdef");
        lua_pushliteral(L, "typedef unsigned char uchar;\n"
                           "typedef unsigned short ushort;\n"
                           "typedef unsigned int uint;\n"
                           "typedef signed long long int llong;\n"
                           "typedef unsigned long long int ullong;\n");
        lua_call(L, 1, 0);
        lua_getfield(L, -1, "cast");
        lua_replace(L, -2);
        for (int i = 0; i < numcfields; ++i) {
            const CReg &reg = (*cfuns)[i];     /* cast */
            lua_pushvalue(L, -1);              /* cast, cast */
            lua_pushstring(L, reg.sig);        /* cast, cast, sig */
            lua_pushlightuserdata(L, reg.fun); /* cast, cast, sig, udata */
            lua_call(L, 2, 1);                 /* cast, fptr */
            lua_setfield(L, -3, reg.name);     /* cast */
        }
        lua_pop(L, 1);
        lua_createtable(L, 0, 2);              /* _C, C_mt */
        lua_pushinteger(L, tnf);               /* _C, C_mt, C_num */
        lua_pushcclosure(L, capi_tostring, 1); /* _C, C_mt, C_tostring */
        lua_setfield(L, -2, "__tostring");     /* _C, C_mt */
        lua_pushcfunction(L, capi_newindex);   /* _C, C_mt, C_newindex */
        lua_setfield(L, -2, "__newindex");     /* _C, C_mt */
        lua_pushboolean(L, false);             /* _C, C_mt, C_metatable */
        lua_setfield(L, -2, "__metatable");    /* _C, C_mt */
        lua_setmetatable(L, -2);               /* _C */
        lua_pushcclosure(L, capi_get, 1);      /* C_get */
        lua_setfield(L, -2, "capi");
        load_module("init");
    }

    void reset() {
#ifndef SERVER
        deleteparticles();
        deletedecals();
        clearanims();
#endif
        externals.clear();
        clearsleep(false, true);
        lua_close(L);
        L = NULL;
        init();
#ifndef SERVER
        tools::execfile("config/menus.lua");
#endif
    }

    void close() {
        lua_close(L);
        delete funs;
        delete cfuns;
    }

#define PINHDR \
    lua_pushliteral(L, "__pinstrs");       /* k1 */ \
    lua_rawget     (L, LUA_REGISTRYINDEX); /* v1 */ \
    lua_pushstring (L, str);               /* v1, str */ \
    lua_pushvalue  (L, -1);                /* v1, str, str */ \
    lua_rawget     (L, -3);                /* v1, str, cnt */

    void pin_string(lua_State *L, const char *str) {
        PINHDR;
        int cnt = lua_tointeger(L, -1); lua_pop(L, 1); /* v1, str */
        lua_pushinteger(L, cnt + 1);                   /* v1, str, cnt + 1 */
        lua_rawset(L, -3);                             /* v1 */
        lua_pop(L, 1);
    }

    void unpin_string(lua_State *L, const char *str) {
        PINHDR;
        ASSERT(lua_isnumber(L, -1));
        int cnt = lua_tointeger(L, -1); lua_pop(L, 1); /* v1, str */
        if (cnt == 1) lua_pushnil(L);                  /* v1, str, nil */
        else lua_pushinteger(L, cnt - 1);              /* v1, str, cnt - 1 */
        lua_rawset(L, -3);                             /* v1 */
        lua_pop(L, 1);
    }

#undef PINHDR

    void pin_string(const char *str) {
        pin_string(L, str);
    }

    void unpin_string(const char *str) {
        unpin_string(L, str);
    }
} /* end namespace lua */
