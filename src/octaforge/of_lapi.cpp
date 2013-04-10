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

#define LAPI_REG(name) \
lua_pushcfunction(L, _lua_##name); \
lua_setfield(L, -2, #name);

#define LAPI_GET_ENT(name, _log, retexpr) \
lua_getfield(L, 1, "uid"); \
int uid = lua_tointeger(L, -1); \
lua_pop(L, 1); \
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

extern string homedir;

namespace lapi
{
    lua::State state;
    lua_State *L = NULL;
    types::String mod_dir;
    bool initialized;

    void panic(const lua::State& s, const char *msg)
    {
        logger::log(logger::ERROR, "OF::Lua: %s\n", msg);
    }

    void setup_binds();

    static int create_table(lua_State *L) {
        lua_createtable(L, luaL_optinteger(L, 1, 0), luaL_optinteger(L, 2, 0));
        return 1;
    }

    void init(const char *dir)
    {
        if (initialized) return;
            initialized  = true;

        mod_dir = dir;

        state.set_panic_handler(&panic);
        L = state.state();

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

        lua_pushcfunction(L, create_table); lua_setglobal(L, "createtable");

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

        if (luaL_loadfile(L, p.get_buf()) || lua_pcall(L, 0, 0, 0)) {
            fatal("%s", lua_tostring(L, -1));
        }
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
        api_all.push();
        lapi_binds::reg_base(L);
        lua_pop(L, 1);
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

        lua::Table package = state.registry().get<lua::Object>("_LOADED",
            "package");

        types::String pattern = types::String()
            .format(";./data/library/%s/?.lua", name);
        lua::Function find = state.get<lua::Object>("string", "find");

        if (!find.call<lua::Object>(package["path"], pattern).is_nil())
            return true;

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
        lua::Object str(L, -1);
        lua_pop(L,  1);
        package["path"] = str;

        return true;
    }
} /* end namespace lapi */
