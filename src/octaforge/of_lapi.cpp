#include "cube.h"
#include "engine.h"
#include "game.h"

#include "of_lapi.h"
#include "of_tools.h"

#ifdef CLIENT
    #include "client_system.h"
    #include "targeting.h"
#endif
#include "editing_system.h"
#include "message_system.h"

#include "of_entities.h"
#include "of_world.h"
#include "of_localserver.h"

#define LAPI_REG(name) t[#name] = &_lua_##name

#define LAPI_GET_ENT(name, tname, _log, retexpr) \
int uid = tname.get<int>("uid"); \
\
CLogicEntity *name = LogicSystem::getLogicEntity(uid); \
if (!name) \
{ \
    logger::log( \
        logger::ERROR, "Cannot find CLE for entity %i (%s).\n", uid, _log \
    ); \
    retexpr; \
}

#define LAPI_EMPTY(name) int _lua_##name(lua_State *L) \
{ logger::log(logger::DEBUG, "stub: CAPI."#name"\n"); return 0; }

#include "of_lapi_base.h"

#undef LAPI_EMPTY
#undef LAPI_GET_ENT
#undef LAPI_REG

using namespace types;
using namespace filesystem;
using namespace lua;

extern string homedir;

namespace lapi
{
    State  state;
    String mod_dir;
    bool initialized;

    void panic(const State& s, const char *msg)
    {
        logger::log(logger::ERROR, "OF::Lua: %s\n", msg);
    }

    void setup_binds();

    static int create_table(lua_State *L) {
        lua_createtable(L, luaL_optinteger(L, 1, 0), luaL_optinteger(L, 2, 0));
        return 1;
    }

    static int to_udata_gc(lua_State *L) {
        luaL_unref(L, LUA_REGISTRYINDEX,
            *((int*)luaL_checkudata(L, 1, "Reference")));
        return 0;
    }

    static int to_udata_get(lua_State *L) {
        lua_rawgeti(L, LUA_REGISTRYINDEX,
            *((int*)luaL_checkudata(L, 1, "Reference")));
        return 1;
    }

    static int to_udata_set(lua_State *L) {
        int *ud = (int*)luaL_checkudata(L, 1, "Reference");
        luaL_unref(L, LUA_REGISTRYINDEX, *ud);

        lua_pushvalue(L, 2);
        *ud = luaL_ref(L, LUA_REGISTRYINDEX);
        return 0;
    }

    static int to_udata_tostring(lua_State *L) {
        int *ud = (int*)luaL_checkudata(L, 1, "Reference");

        lua_getglobal(L, "tostring");
        lua_rawgeti  (L, LUA_REGISTRYINDEX, *ud);
        lua_call     (L, 1, 1);

        const char *str = lua_tostring(L, -1);
        lua_pop(L, 1);

        lua_pushfstring(L, "reference: %p (%s)", ud, str);
        return 1;
    }

    static int to_udata(lua_State *L) {
        lua_pushvalue(L, 1);
        int ref = luaL_ref(L, LUA_REGISTRYINDEX);

        int *ud = (int*)lua_newuserdata(L, sizeof(void*));
        *ud = ref;

        if (luaL_newmetatable(L, "Reference")) {
            lua_pushliteral  (L, "__gc");
            lua_pushcfunction(L, &to_udata_gc);
            lua_settable     (L, -3);

            lua_pushliteral  (L, "__tostring");
            lua_pushcfunction(L, &to_udata_tostring);
            lua_settable     (L, -3);

            lua_pushliteral  (L, "__index");
            lua_createtable  (L, 0, 2);

            lua_pushliteral  (L, "get");
            lua_pushcfunction(L, &to_udata_get);
            lua_settable     (L, -3);

            lua_pushliteral  (L, "set");
            lua_pushcfunction(L, &to_udata_set);
            lua_settable     (L, -3);

            lua_settable     (L, -3);
        }

        lua_setmetatable(L, -2);

        return 1;
    }

    static int raw_error(lua_State *L) {
        lua_error(L);
        return 0;
    }

    void init(const char *dir)
    {
        if (initialized) return;
            initialized  = true;

        mod_dir = dir;

        state.set_panic_handler(&panic);

        state.open_base   ();
        state.open_table  ();
        state.open_string ();
        state.open_math   ();
        state.open_package();
        state.open_debug  ();
        state.open_os     ();
        state.open_io     ();

        lua_pushcfunction(state.state(), luaopen_ffi);
        lua_call         (state.state(), 0, 0);

        lua_pushcfunction(state.state(), luaopen_bit);
        lua_call         (state.state(), 0, 0);

        lua_State *L  = state.state();
        Table loaded  = state.registry()["_LOADED"];
        Table package = loaded["package"];

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

        lua_concat(L,  8);
        Object str(L, -1);
        lua_pop   (L,  1);
        package["path"] = str;

        /* table allocation */
        state["createtable"] = &create_table;

        /* reference management functions */
        state["toref"] = &to_udata;

        /* raw error without line number info etc. */
        state["rawerror"] = &raw_error;

        setup_binds();
    }

    void load_module(const char *name)
    {
        logger::log(
            logger::DEBUG, "Loading OF Lua module: %s%c%s.lua.\n",
            mod_dir.get_buf(), filesystem::separator(), name
        );

        types::String p(mod_dir);
        p += filesystem::separator();
        p += name;
        p += ".lua";

        auto err = state.do_file(p, lua::ERROR_TRACEBACK);
        if (types::get<0>(err))
            logger::log(logger::ERROR, "%s\n", types::get<1>(err));
    }

    void setup_binds()
    {
#ifdef CLIENT
        state["CLIENT"] = true;
        state["SERVER"] = false;
#else
        state["CLIENT"] = false;
        state["SERVER"] = true;
#endif
        state["OF_CFG_VERSION"] = OF_CFG_VERSION;

        lua::Table api_all = state.new_table();
        lapi_binds::reg_base(api_all);
        state.register_module("CAPI", api_all);
        load_module("init");
    }

    void reset()
    {
        /*for (
            Table::pit it = state.globals().pbegin();
            it != state.globals().pend();
            ++it
        )
        {
            const char *key = (*it).first.to<const char*>();
            if (!key) continue;

            if (state.get<Function>(
                "LAPI", "Library", "is_unresettable"
            ).call<bool>(key)) continue;

            Type type = (*it).second.type();
            Object o(state.registry().get<Object>("_LOADED", key));

            if (strcmp(key, "_G") && type == TYPE_TABLE && o.is_nil())
                state[key] = nil;
        }

        state.get<Function>("LAPI", "Library", "reset")();

        load_module("init");*/
    }

    bool load_library(const char *name)
    {
        if (!name || strstr(name, "..")) return false;

        Table package = state.registry().get<Object>("_LOADED", "package");

        String pattern = String().format(";./data/library/%s/?.lua", name);
        Function  find = state.get<Object>("string", "find");

        if (!find.call<Object>(package["path"], pattern).is_nil())
            return true;

        lua_State *L  = state.state();

        /* original path */
        package["path"].push();

        /* home directory path */
        lua_pushfstring(
            L, ";%sdata%clibrary%c%s%c?.lua",
            homedir, PATHDIV, PATHDIV, name, PATHDIV
        );

        /* root path */
        lua_pushfstring(L, ";./data/library/%s/?.lua", name);

        lua_concat(L,  3);
        Object str(L, -1);
        lua_pop   (L,  1);
        package["path"] = str;

        return true;
    }
} /* end namespace lapi */

namespace lua {
    void push(lua_State *L, bool v) {
        lua_pushboolean(L, v);
    }

    void push(lua_State *L, lua_CFunction v) {
        lua_pushcfunction(L, v);
    }

    void push(lua_State *L, const char *v) {
        lua_pushstring(L, v);
    }

    void push(lua_State *L, lua_Number v) {
        lua_pushnumber(L, v);
    }

    void push(lua_State *L, lua_Integer n) {
        lua_pushinteger(L, n);
    }

    void push(lua_State *L, lua_CFunction f, int n) {
        lua_pushcclosure(L, f, n);
    }

    void push(lua_State *L, const char *s, size_t l) {
        lua_pushlstring(L, s, l);
    }

    void push(lua_State *L) {
        lua_pushnil(L);
    }
}
