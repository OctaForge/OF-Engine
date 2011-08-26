/*
 * of_lua.cpp, version 1
 * Source file for Lua scripting system
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#include "cube.h"
#include "engine.h"
#include "game.h"

#include <cmath>
#include "message_system.h"
#ifdef CLIENT
    #include "client_engine_additions.h"
    #include "client_system.h"
    #include "targeting.h"
    #include "textedit.h"
#endif
#include "editing_system.h"

#include "of_tools.h"
#include "of_localserver.h"
#include "of_world.h"
#include "of_entities.h"

vector<lua::LE_reg> CAPI;
#include "of_lua_definitions.h"

extern LE_reg *objbinds;
extern LE_reg *md5binds;
extern LE_reg *iqmbinds;
extern LE_reg *smdbinds;

extern string homedir;

namespace lua
{
    /* our binds */
    using namespace lua_binds;

    bool addcommand(LE_reg l) { CAPI.add(l); return true; }

    /* externed in header */
    lua_Engine engine;

    /*
     * PRIVATE METHODS
     */

    void lua_Engine::setup_libs()
    {
        /*
         * luaopen_ functions were never meant to be ran directly
         * instead of running them directly, push them into lua and call then
         */
        #define openlib(name) \
        lua_pushcfunction(m_handle, luaopen_##name); \
        lua_call(m_handle, 0, 0);

        openlib(base)
        openlib(table)
        openlib(string)
        openlib(math)
        openlib(package)
        openlib(debug)

        #undef openlib

        /* now set up package access */
        lua_getfield(m_handle, LUA_REGISTRYINDEX, "_LOADED");
        t_getraw("package");

        /* home directory paths */
        lua_pushfstring(
            m_handle, ";%sdata%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV
        );
        lua_pushfstring(
            m_handle, ";%sdata%clibrary%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV, PATHDIV
        );

        /* root directory paths */
        lua_pushliteral(m_handle, ";./data/library/core/?.lua");
        lua_pushliteral(m_handle, ";./data/library/core/?/init.lua");
        lua_pushliteral(m_handle, ";./data/?/init.lua");
        lua_pushliteral(m_handle, ";./data/library/?/init.lua");

        /* concat them */
        lua_concat(m_handle, 6);

        /* we got package and string on the stack, push the name */
        lua_pushliteral(m_handle, "path");

        /* shift, set */
        shift().t_set();

        /* reference seeall for later */
        t_getraw("seeall");
        int _ref = ref();

        /* pop the tables */
        pop(2);

        /* nil global package.path */
        lua_pushliteral(m_handle, "package");

        /* new package table, contains only 'seeall' */
        t_new();
        lua_pushliteral(m_handle, "seeall");
        getref(_ref).t_set();

        /* unref */
        unref(_ref);

        /* set global */
        setg();
    }

    void lua_Engine::setup_namespace(const char *n, const LE_reg *r)
    {
        logger::log(logger::DEBUG, "Setting up Lua embed namespace \"%s\"\n", n);

        int size = 0;
        for (; r->n; r++) size++;
        r = r - size;
        logger::log(logger::DEBUG, "Future namespace size: %i\n", size);

        lua_pushvalue(m_handle, LUA_REGISTRYINDEX);
        lua_pushstring(m_handle, "_LOADED");
        lua_rawget(m_handle, -2);
        lua_remove(m_handle, -2);

        logger::log(logger::DEBUG, "Trying to get if the embed namespace is already registered.\n");
        lua_getfield(m_handle, -1, n);

        if (!lua_istable(m_handle, -1))
        {
            lua_pop(m_handle, 1);

            logger::log(logger::DEBUG, "Namespace not found in _LOADED, trying global variable.\n");

            lua_pushvalue(m_handle, LUA_GLOBALSINDEX);
            lua_pushstring(m_handle, n);
            lua_rawget(m_handle, -2);

            if (lua_isnil(m_handle, -1))
            {
                lua_pop(m_handle, 1);
                lua_createtable(m_handle, 0, size);
                lua_pushstring(m_handle, n);
                lua_pushvalue(m_handle, -2);
                lua_settable(m_handle, -4);
            }
            else if (!lua_istable(m_handle, -1))
            {
                defformatstring(m)("name conflict for module %s", n);
                lua_pop(m_handle, 2);
                error(m);
            }

            lua_remove(m_handle, -2);

            logger::log(logger::DEBUG, "pushing the namespace into _LOADED.\n");
            lua_pushvalue(m_handle, -1);
            lua_setfield(m_handle, -3, n);
        }

        lua_remove(m_handle, -2);
        lua_insert(m_handle, -1);

        logger::log(logger::DEBUG, "Registering functions into namespace.\n");
        for (; r->n; r++)
        {
            logger::log(logger::INFO, "Registering: %s\n", r->n);
            lua_pushlightuserdata(m_handle, (void*)r);
            lua_pushcclosure(m_handle, l_disp, 1);
            lua_setfield(m_handle, -2, r->n);
        }
        r = r - size;

        logger::log(logger::DEBUG, "Namespace \"%s\" registration went properly, leaving on stack.\n", n);
    }

    void lua_Engine::setup_module(const char *n, bool t)
    {
        logger::log(logger::DEBUG, "Setting up module: %s%s.lua\n", m_scriptdir, n);
        defformatstring(f)("%s%s.lua", m_scriptdir, n);
        defformatstring(ft)("%s%s__test.lua", m_scriptdir, n);
        execf(f); if (m_runtests && !t) execf(ft);
    }

    lua_Engine& lua_Engine::bind()
    {
        if (!m_hashandle) return *this;

        logger::log(logger::DEBUG, "Setting up lua engine embedding\n");

        m_runtests = false;
        if (m_rantests) m_runtests = false;

        addcommand((LE_reg){ NULL, NULL });
        setup_namespace("CAPI", CAPI.getbuf());
        #define PUSHLEVEL(l) t_set(#l, logger::l);
        PUSHLEVEL(INFO)
        PUSHLEVEL(DEBUG)
        PUSHLEVEL(WARNING)
        PUSHLEVEL(ERROR)
        pop(1);

        setup_namespace("obj", objbinds);
        setup_namespace("md5", md5binds);
        setup_namespace("iqm", iqmbinds);
        setup_namespace("smd", smdbinds);
        pop(4);

        push("run_tests").push(m_runtests).setg();
        #ifdef CLIENT
        push("CLIENT").push(true).setg();
        push("SERVER").push(false).setg();
        #else
        push("CLIENT").push(false).setg();
        push("SERVER").push(true).setg();
        #endif
        push("OF_CFG_VERSION").push(OF_CFG_VERSION).setg();

        setup_module("init");

        if (m_runtests)
        {
            destroy();
            m_rantests = true;
            create();
        }

        return *this;
    }

    /*
     * LUA ENGINE STATIC METHODS
     */

    int lua_Engine::l_disp(lua_State *L)
    {
        lua_Engine l(L);
        LE_reg *r = (LE_reg*)lua_touserdata(L, lua_upvalueindex(1));

        r->f(l);

        return l.destroy();
    }

    /*
     * LUA ENGINE PUBLIC METHODS
     */

    /*
     * constructors, destructor
     */

    lua_Engine::lua_Engine() :
        m_handle(NULL),
        m_retcount(-1),
        m_hashandle(false),
        m_runtests(false),
        m_rantests(false),
        m_scriptdir("data/library/core/"),
        m_lasterror(NULL) {}

    lua_Engine::lua_Engine(lua_State *l) :
        m_handle(l),
        m_hashandle(true),
        m_runtests(false),
        m_rantests(false),
        m_scriptdir(NULL),
        m_lasterror(NULL) { m_retcount = gettop(); }

    lua_Engine::~lua_Engine()
    {
        /*
         * don't close handler if no scriptdir is specified,
         * because that means this class comes from existing handler
         */
        if (!m_scriptdir) destroy();
    }

    /*
     * Some template specializations (prototypes, templates defined in header too)
     */

    // getters without default value

    template<>
    double lua_Engine::get(int i)
    {
        if (!m_hashandle) return 0;
        else if (!lua_isnoneornil(m_handle, i))
        {
            double v = lua_tonumber(m_handle, i);
            if (!v && !lua_isnumber(m_handle, i))
                typeerror(i, "number");
            return v;
        }
        else return 0;
    }

    template<>
    float lua_Engine::get(int i)
    {
        if (!m_hashandle) return 0;
        else if (!lua_isnoneornil(m_handle, i))
        {
            float v = lua_tonumber(m_handle, i);
            if (!v && !lua_isnumber(m_handle, i))
                typeerror(i, "number");
            return v;
        }
        else return 0;
    }

    template<>
    bool lua_Engine::get(int i)
    {
        if (!m_hashandle) return false;
        else if (!lua_isnoneornil(m_handle, i))
        {
            bool v = lua_toboolean(m_handle, i);
            if (!v && !lua_isboolean(m_handle, i))
                typeerror(i, "boolean");
            return v;
        }
        else return false;
    }

    template<>
    const char *lua_Engine::get(int i)
    {
        if (m_hashandle && !lua_isnoneornil(m_handle, i))
        {
            const char *r = lua_tolstring(m_handle, i, 0);
            if (!r) typeerror(i, "string");
            return r;
        }
        return NULL;
    }

    template<>
    CLogicEntity *lua_Engine::get(int i)
    {
        CLogicEntity *ret;
        int id = 0;

        push_index(i);
        id = t_get<int>("uid");
        pop(1);

        ret = LogicSystem::getLogicEntity(id);
        logger::log(logger::INFO, "Lua: getting the CLE for UID %d\n", id);

        if (!ret)
        {
            defformatstring(err)("Cannot find CLE for entity %i", id);
            error(err);
        }
        return ret;
    }

    template<>
    vec lua_Engine::get(int i)
    {
        push_index(i);

        if (!is<void**>(-1))
        {
            vec v;
            pop(1);
            return v;
        }

        vec r(t_get<float>("x"), t_get<float>("y"), t_get<float>("z"));
        pop(1);
        return r;
    }

    template<>
    bvec lua_Engine::get(int i)
    {
        push_index(i);

        if (!is<void**>(-1))
        {
            bvec v;
            pop(1);
            return v;
        }

        bvec r(t_get<int>("r"), t_get<int>("g"), t_get<int>("b"));
        pop(1);
        return r;
    }

    // specializations for with-default getters

    template<>
    double lua_Engine::get(int i, double d)
    {
        if (!m_hashandle) return d;
        else if (!lua_isnoneornil(m_handle, i))
        {
            double v = lua_tonumber(m_handle, i);
            if (!v && !lua_isnumber(m_handle, i))
                typeerror(i, "number");
            return v;
        }
        else return d;
    }

    template<>
    float lua_Engine::get(int i, float d)
    {
        if (!m_hashandle) return d;
        else if (!lua_isnoneornil(m_handle, i))
        {
            float v = lua_tonumber(m_handle, i);
            if (!v && !lua_isnumber(m_handle, i))
                typeerror(i, "number");
            return v;
        }
        else return d;
    }

    template<>
    bool lua_Engine::get(int i, bool d)
    {
        if (!m_hashandle) return d;
        else if (!lua_isnoneornil(m_handle, i))
        {
            bool v = lua_toboolean(m_handle, i);
            if (!v && !lua_isboolean(m_handle, i))
                typeerror(i, "boolean");
            return v;
        }
        else return d;
    }

    template<>
    const char *lua_Engine::get(int i, const char *d)
    {
        if (m_hashandle && !lua_isnoneornil(m_handle, i))
        {
            const char *r = lua_tolstring(m_handle, i, 0);
            if (!r) typeerror(i, "string");
            return r;
        }
        return d;
    }

    template<>
    char *lua_Engine::get(int i, char *d)
    {
        if (m_hashandle && !lua_isnoneornil(m_handle, i))
        {
            char *r = (char*)lua_tolstring(m_handle, i, 0);
            if (!r) typeerror(i, "string");
            return r;
        }
        return d;
    }

    // specializations for pointers; temporary till stuff requiring this is rewritten

    template<>
    int *lua_Engine::get(int i)
    {
        if (!m_hashandle) return new int(0);
        else if (!lua_isnoneornil(m_handle, i))
        {
            int *v = new int(lua_tointeger(m_handle, i));
            if (!*v && !lua_isnumber(m_handle, i))
                typeerror(i, "integer");
            return v;
        }
        else return new int(0);
    }

    template<>
    double *lua_Engine::get(int i)
    {
        if (!m_hashandle) return new double(0);
        else if (!lua_isnoneornil(m_handle, i))
        {
            double *v = new double(lua_tonumber(m_handle, i));
            if (!*v && !lua_isnumber(m_handle, i))
                typeerror(i, "number");
            return v;
        }
        else return new double(0);
    }

    template<>
    float *lua_Engine::get(int i)
    {
        if (!m_hashandle) return new float(0);
        else if (!lua_isnoneornil(m_handle, i))
        {
            float *v = new float((float)lua_tonumber(m_handle, i));
            if (!*v && !lua_isnumber(m_handle, i))
                typeerror(i, "number");
            return v;
        }
        else return new float(0);
    }

    template<>
    char *lua_Engine::get(int i)
    {
        if (m_hashandle && !lua_isnoneornil(m_handle, i))
        {
            char *r = (char*)lua_tolstring(m_handle, i, 0);
            if (!r) typeerror(i, "string");
            return r;
        }
        return NULL;
    }

    // type checker specializations

    template<>
    bool lua_Engine::is<int>(int i)
    {
        if (!m_hashandle) return false;
        return lua_isnumber(m_handle, i);
    }

    template<>
    bool lua_Engine::is<double>(int i)
    {
        if (!m_hashandle) return false;
        return lua_isnumber(m_handle, i);
    }

    template<>
    bool lua_Engine::is<float>(int i)
    {
        if (!m_hashandle) return false;
        return lua_isnumber(m_handle, i);
    }

    template<>
    bool lua_Engine::is<bool>(int i)
    {
        if (!m_hashandle) return false;
        return lua_isboolean(m_handle, i);
    }

    template<>
    bool lua_Engine::is<const char*>(int i)
    {
        if (!m_hashandle) return false;
        return lua_isstring(m_handle, i);
    }

    template<>
    bool lua_Engine::is<void**>(int i)
    {
        if (!m_hashandle) return false;
        return lua_istable(m_handle, i);
    }

    template<>
    bool lua_Engine::is<void*>(int i)
    {
        if (!m_hashandle) return false;
        return lua_isfunction(m_handle, i);
    }

    /*
     * Handler manipulation functions
     */

    lua_Engine& lua_Engine::create()
    {
        if (m_hashandle) return *this;

        logger::log(logger::DEBUG, "Creating lua_Engine state handler.\n");

        m_handle = luaL_newstate();
        if (m_handle)
        {
            m_hashandle = true;

            logger::log(logger::DEBUG, "Handler created properly, finalizing.\n");
            setup_libs(); bind();
        }
        logger::log(logger::DEBUG, "Handler creation went properly.\n");

        return *this;
    }

    // also called in destructor
    int lua_Engine::destroy()
    {
        if (!m_hashandle) return -1;
        if (m_retcount >= 0) return lua_gettop(m_handle) - m_retcount;

        logger::log(logger::DEBUG, "Destroying lua_Engine class and its handler.\n");
        lua_close(m_handle);
        m_hashandle = false;
        return -1;
    }

    bool lua_Engine::hashandle()
    {
        return m_hashandle;
    }

    /*
     * push functions (c++ -> stack)
     */

    lua_Engine& lua_Engine::push_index(int i)
    {
        if (!m_hashandle) return *this;
        lua_pushvalue(m_handle, i);
        return *this;
    }

    lua_Engine& lua_Engine::push(int v)
    {
        if (!m_hashandle) return *this;
        lua_pushinteger(m_handle, v);
        return *this;
    }

    lua_Engine& lua_Engine::push(double v)
    {
        if (!m_hashandle) return *this;
        lua_pushnumber(m_handle, v);
        return *this;
    }

    lua_Engine& lua_Engine::push(float v)
    {
        if (!m_hashandle) return *this;
        lua_pushnumber(m_handle, v);
        return *this;
    }

    lua_Engine& lua_Engine::push(bool v)
    {
        if (!m_hashandle) return *this;
        lua_pushboolean(m_handle, v);
        return *this;
    }

    lua_Engine& lua_Engine::push(const char *v)
    {
        if (!m_hashandle) return *this;
        lua_pushstring(m_handle, v);
        return *this;
    }

    lua_Engine& lua_Engine::push(vec v)
    {
        if (!m_hashandle) return *this;
        getg("math").t_getraw("vec3");
        lua_remove(m_handle, -2);
        push(v.x);
        push(v.y);
        push(v.z);
        call(3, 1);
        return *this;
    }

    lua_Engine& lua_Engine::push(vec4 v)
    {
        if (!m_hashandle) return *this;
        getg("math").t_getraw("vec4");
        lua_remove(m_handle, -2);
        push(v.x);
        push(v.y);
        push(v.z);
        push(v.w);
        call(4, 1);
        return *this;
    }

    lua_Engine& lua_Engine::push()
    {
        if (!m_hashandle) return *this;
        lua_pushnil(m_handle);
        return *this;
    }

    lua_Engine& lua_Engine::shift()
    {
        if (!m_hashandle) return *this;
        lua_insert(m_handle, -2);
        return *this;
    }

    /*
     * Global manipulation functions
     */

    lua_Engine& lua_Engine::getg(const char *n)
    {
        if (!m_hashandle) return *this;
        lua_getglobal(m_handle, n);
        return *this;
    }

    lua_Engine& lua_Engine::setg()
    {
        if (!m_hashandle) return *this;
        lua_settable(m_handle, LUA_GLOBALSINDEX);
        return *this;
    }

    /*
     * call / run functions
     */

    lua_Engine& lua_Engine::call(int a, int r)
    {
        if (!m_hashandle) return *this;
        int c = lua_pcall(m_handle, (a >= 0 ? a : lua_gettop(m_handle) - 1), r, 0);
        if (c)
        {
            m_lasterror = geterror();
            logger::log(logger::ERROR, "%s\n", m_lasterror);
            return *this;
        }
        return *this;
    }

    lua_Engine& lua_Engine::call()
    {
        // do not use unless you're absolutely sure your stack contains only the function + its args
        return call(-1);
    }

    bool lua_Engine::exec(const char *s, bool msg)
    {
        bool ret = load(s, msg);
        if (!ret) return false;
        else
        {
            ret = lua_pcall(m_handle, 0, LUA_MULTRET, 0);
            if (ret)
            {
                m_lasterror = geterror();
                if (msg) logger::log(logger::ERROR, "%s\n", m_lasterror);
                return false;
            }
        }
        return true;
    }

    bool lua_Engine::execf(const char *s, bool msg)
    {
        bool ret = loadf(s, msg);
        if (!ret) return false;
        else
        {
            ret = lua_pcall(m_handle, 0, LUA_MULTRET, 0);
            if (ret)
            {
                m_lasterror = geterror();
                if (msg) logger::log(logger::ERROR, "%s\n", m_lasterror);
                return false;
            }
        }
        return true;
    }

    bool lua_Engine::loadf(const char *s, bool msg)
    {
        if (!m_hashandle) return false;

        bool ret = luaL_loadfile(m_handle, s);
        if (ret)
        {
            m_lasterror = geterror();
            if (msg) logger::log(logger::ERROR, "%s", m_lasterror);
        }
        return !ret;
    }

    bool lua_Engine::load(const char *s, bool msg)
    {
        if (!m_hashandle) return false;

        bool ret = luaL_loadstring(m_handle, s);
        if (ret)
        {
            m_lasterror = geterror();
            if (msg) logger::log(logger::ERROR, "%s", m_lasterror);
        }
        return !ret;
    }

    /*
     * Table manipulation functions
     */

    lua_Engine& lua_Engine::t_new()
    {
        if (!m_hashandle) return *this;
        lua_newtable(m_handle);
        return *this;
    }

    lua_Engine& lua_Engine::t_set()
    {
        if (!m_hashandle) return *this;
        lua_settable(m_handle, -3);
        return *this;
    }

    bool lua_Engine::t_next(int i)
    {
        if (!m_hashandle) return false;
        return lua_next(m_handle, i);
    }

    lua_Engine& lua_Engine::error(const char *m)
    {
        if (!m_hashandle) return *this;

        lua_Debug ar;
        if (lua_getstack(m_handle, 1, &ar))
        {
            lua_getinfo(m_handle, "Sl", &ar);
            if (ar.currentline > 0)
                lua_pushfstring(m_handle, "%s:%d: ", ar.short_src, ar.currentline);
        }
        else lua_pushliteral(m_handle, "");

        lua_pushstring(m_handle, m);
        lua_concat(m_handle, 2);
        logger::log(logger::ERROR, "%s\n", lua_tostring(m_handle, -1));
        lua_error(m_handle);
        return *this;
    }

    lua_Engine& lua_Engine::typeerror(int n, const char *t)
    {
        if (!m_hashandle) return *this;

        lua_Debug ar;
        const char *m = lua_pushfstring(m_handle, "%s expected, got %s", t, lua_typename(m_handle, lua_type(m_handle, n)));
        if (!lua_getstack(m_handle, 0, &ar))
        {
            defformatstring(e)("bad argument #%i (%s)", n, m);
            error(e);
            return *this;
        }
        lua_getinfo(m_handle, "n", &ar);
        if (!strcmp(ar.namewhat, "method"))
        {
            n--;
            if (!n)
            {
                defformatstring(e)("calling %s on bad self (%s)", ar.name, m);
                error(e);
                return *this;
            }
        }
        if (ar.name == NULL) ar.name = "?";
        defformatstring(e)("bad argument #%i to %s (%s)", n, ar.name, m);
        error(e);
        return *this;
    }

    const char *lua_Engine::geterror()
    {
        if (!m_hashandle) return NULL;
        const char *err = lua_tostring(m_handle, -1);
        if (!err) return "Unknown Lua error";
        return err;
    }

    const char *lua_Engine::geterror_last()
    {
        if (!m_hashandle) return NULL;
        return m_lasterror;
    }

    int lua_Engine::ref()
    {
        if (!m_hashandle) return 0;

        int ref;
        if (lua_isnil(m_handle, -1))
        {
            lua_pop(m_handle, 1);
            return -1;
        }
        lua_rawgeti(m_handle, LUA_REGISTRYINDEX, 0);
        ref = (int)lua_tointeger(m_handle, -1);
        lua_pop(m_handle, 1);
        if (ref != 0)
        {
            lua_rawgeti(m_handle, LUA_REGISTRYINDEX, ref);
            lua_rawseti(m_handle, LUA_REGISTRYINDEX, 0);
        }
        else
        {
            ref = (int)lua_objlen(m_handle, LUA_REGISTRYINDEX);
            ref++;
        }
        lua_rawseti(m_handle, LUA_REGISTRYINDEX, ref);
        return ref;
    }

    int lua_Engine::ref_keep_stack()
    {
        int r = ref();
        getref(r);
        return r;
    }

    lua_Engine& lua_Engine::getref(int r)
    {
        if (!m_hashandle) return *this;
        lua_rawgeti(m_handle, LUA_REGISTRYINDEX, r);
        return *this;
    }

    lua_Engine& lua_Engine::unref(int r)
    {
        if (!m_hashandle) return *this;
        if (r >= 0)
        {
            lua_rawgeti(m_handle, LUA_REGISTRYINDEX, 0);
            lua_rawseti(m_handle, LUA_REGISTRYINDEX, r); // t[r] = t[0]
            lua_pushinteger(m_handle, r);
            lua_rawseti(m_handle, LUA_REGISTRYINDEX, 0); // t[0] = r
        }
        return *this;
    }

    lua_Engine& lua_Engine::pop(int n)
    {
        if (!m_hashandle) return *this;
        if (!n) lua_pop(m_handle, lua_gettop(m_handle));
        else lua_pop(m_handle, n);
        return *this;
    }

    int lua_Engine::gettop()
    {
        if (!m_hashandle) return 0;
        return lua_gettop(m_handle);
    }

    bool lua_Engine::setup_library(const char *version)
    {
        /* check the version string so we're safe */
        getg("tonumber").push(version).call(1, 1);

        /* if we get nil, version string is invalid */
        if (is<void>(-1))
        {
            /* pop the nil first */
            pop(1);
            /* fail */
            return false;
        }
        /* we don't need the value, just pop it. */
        pop(1);

        /* get the required table */
        lua_getfield(m_handle, LUA_REGISTRYINDEX, "_LOADED");
        t_getraw("package").t_getraw("path");

        /* now check if path is not already included */
        getg("string").t_getraw("find");

        /* push a copy of package.path as arg to find */
        push_index(-3);
        /*
         * and pattern for checking - path to the library in
         * root directory - because it looks the same everywhere
         */
        lua_pushfstring(m_handle, ";./data/library/%s/?.lua", version);
        /* call and get 1 result */
        call(2, 1);
        /*
         * if it's not nil, it means it has found something, and
         * in such case we just return with success
         */
        if (!is<void>(-1))
        {
            /* pop all the elements */
            pop(5);
            /* success */
            return true;
        }
        /* on success, we pop just 2 elements */
        pop(2);

        /* home directory path */
        lua_pushfstring(
            m_handle, ";%sdata%clibrary%c%s%c?.lua",
            homedir, PATHDIV, PATHDIV, version, PATHDIV
        );

        /* root directory path */
        lua_pushfstring(m_handle, ";./data/library/%s/?.lua", version);

        /* concat them, including package.path */
        lua_concat(m_handle, 3);

        /* we got package and string on the stack, push the name */
        lua_pushliteral(m_handle, "path");

        /* shift, set */
        shift().t_set();

        /* pop the tables */
        pop(2);

        /* success! */
        return true;
    }
}
// end namespace lua
