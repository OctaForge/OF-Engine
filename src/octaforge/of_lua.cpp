#include <errno.h>

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "of_lua.h"
#include "of_tools.h"

#ifndef SERVER
    #include "client_system.h"
    #include "targeting.h"
#endif
#include "message_system.h"

#include "of_world.h"
#include "of_localserver.h"

#define LAPI_EMPTY(name) int _lua_##name(lua_State *L) \
{ logger::log(logger::DEBUG, "stub: _C."#name"\n"); return 0; }

#include "of_lua_api.h"

#undef LAPI_EMPTY

void deleteparticles();
void deletedecals();
void clearanims();

namespace lua
{
    static int load_file(lua_State *L, const char *fname);

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

    static int external_handler = LUA_REFNIL;

    static bool push_external(lua_State *L, const char *name) {
        if (external_handler == LUA_REFNIL) return false;
        lua_rawgeti(L, LUA_REGISTRYINDEX, external_handler);
        lua_pushstring(L, name);
        lua_call(L, 1, 1);
        return !lua_isnil(L, -1);
    }

    static int vcall_external_i(lua_State *L, const char *name,
    const char *args, int retn, va_list ap) {
        if (!push_external(L, name)) return -1;
        int nargs = 0;
        while (*args) {
            switch (*args++) {
                case 's':
                    lua_pushstring(L, va_arg(ap, const char*));
                    ++nargs; break;
                case 'S': {
                    const char *str = va_arg(ap, const char*);
                    lua_pushlstring(L, str, va_arg(ap, int));
                    ++nargs; break;
                }
                case 'd': case 'i':
                    lua_pushinteger(L, va_arg(ap, int));
                    ++nargs; break;
                case 'f':
                    lua_pushnumber(L, va_arg(ap, double));
                    ++nargs; break;
                case 'b':
                    lua_pushboolean(L, va_arg(ap, int));
                    ++nargs; break;
                case 'p':
                    lua_pushlightuserdata(L, va_arg(ap, void*));
                    ++nargs; break;
                case 'c':
                    lua_pushcfunction(L, va_arg(ap, lua_CFunction));
                    ++nargs; break;
                case 'C': {
                    lua_CFunction cf = va_arg(ap, lua_CFunction);
                    int nups = va_arg(ap, int);
                    lua_pushcclosure(L, cf, nups);
                    nargs -= nups - 1; break;
                }
                case 'n':
                    lua_pushnil(L);
                    ++nargs; break;
                case 'v':
                    lua_pushvalue(L, va_arg(ap, int));
                    ++nargs; break;
                default:
                    assert(false);
                    break;
            }
        }
        int n1 = lua_gettop(L) - nargs - 1;
        lua_call(L, nargs, retn);
        return lua_gettop(L) - n1;
    }

    bool vcall_external(lua_State *L, const char *name, const char *args,
    va_list ap) {
        return vcall_external_i(L, name, args, 0, ap) >= 0;
    }

    bool vcall_external(const char *name, const char *args, va_list ap) {
        return vcall_external(L, name, args, ap) >= 0;
    }

    bool call_external(lua_State *L, const char *name, const char *args, ...) {
        va_list ap;
        va_start(ap, args);
        bool ret = vcall_external(L, name, args, ap);
        va_end(ap);
        return ret;
    }

    bool call_external(const char *name, const char *args, ...) {
        va_list ap;
        va_start(ap, args);
        bool ret = vcall_external(name, args, ap);
        va_end(ap);
        return ret;
    }

    int vcall_external_ret(lua_State *L, const char *name, const char *args,
    const char *retargs, va_list ap) {
        int nr = LUA_MULTRET;
        if (retargs && *retargs == 'N') {
            ++retargs;
            nr = va_arg(ap, int);
        }
        int nrets = vcall_external_i(L, name, args, nr, ap);
        if (nrets < 0) return -1;
        int idx = nrets;
        if (retargs) while (*retargs) {
            switch (*retargs++) {
                case 's':
                    *va_arg(ap, const char**) = lua_tostring(L, -(idx--));
                    break;
                case 'd': case 'i':
                    *va_arg(ap, int*) = lua_tointeger(L, -idx--);
                    break;
                case 'f':
                    *va_arg(ap, float*) = lua_tonumber(L, -idx--);
                    break;
                case 'F':
                    *va_arg(ap, double*) = lua_tonumber(L, -idx--);
                    break;
                case 'b':
                    *va_arg(ap, bool*) = lua_toboolean(L, -idx--);
                    break;
                default:
                    assert(false);
                    break;
            }
        }
        return nrets;
    }

    int vcall_external_ret(const char *name, const char *args,
    const char *retargs, va_list ap) {
        return vcall_external_ret(L, name, args, retargs, ap);
    }

    int call_external_ret(lua_State *L, const char *name, const char *args,
    const char *retargs, ...) {
        va_list ap;
        va_start(ap, retargs);
        int ret = vcall_external_ret(L, name, args, retargs, ap);
        va_end(ap);
        return ret;
    }

    int call_external_ret(const char *name, const char *args,
    const char *retargs, ...) {
        va_list ap;
        va_start(ap, retargs);
        int ret = vcall_external_ret(name, args, retargs, ap);
        va_end(ap);
        return ret;
    }

    void pop_external_ret(lua_State *L, int n) { if (n > 0) lua_pop(L, n); }
    void pop_external_ret(int n) { pop_external_ret(L, n); }

    LUAICOMMAND(external_hook, {
        lua_pushvalue(L, 1);
        external_handler = luaL_ref(L, LUA_REGISTRYINDEX);
        return 0;
    })

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
        defformatstring(p, "%s/%s.lua", mod_dir, name);
        path(p);
        logger::log(logger::DEBUG, "Loading OF Lua module: %s.\n", p);
        if (load_file(L, p) || lua_pcall(L, 0, 0, 0)) {
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

    static void setup_ffi(lua_State *L) {
        lua_getglobal(L, "require");
        lua_pushliteral(L, "ffi");
        lua_call(L, 1, 1);
        lua_getfield(L, -1, "cdef");
        lua_pushliteral(L, "typedef unsigned char uchar;\n"
            "typedef unsigned short ushort;\n"
            "typedef unsigned int uint;\n"
            "typedef signed long long int llong;\n"
            "typedef unsigned long long int ullong;\n"
            "typedef struct Texture {\n"
            "    char *name;\n"
            "    int type, w, h, xs, ys, bpp, clamp;\n"
            "    bool mipmap, canreduce;\n"
            "    uint32_t id;\n"
            "    uchar *alphamask;\n"
            "} Texture;\n"
            "struct particle_t; typedef struct particle_t particle_t;\n"
            "struct selinfo_t; typedef struct selinfo_t selinfo_t;\n"
            "struct vslot_t; typedef struct vslot_t vslot_t;\n"
            "struct cube_t; typedef struct cube_t cube_t;\n");
        lua_call(L, 1, 0);
        lua_getfield(L, -1, "cast");
        lua_replace(L, -2);
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
        setup_ffi(L);
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
        lua_pop(L, 1); /* _PRELOAD */

        /* load luacy early on */
        lua_getfield(L, LUA_REGISTRYINDEX, "_LOADED");
        lua_getglobal(L, "require");
        lua_pushliteral(L, "luacy");
        lua_call(L, 1, 1);
        lua_getfield(L, -1, "parse");
        lua_setfield(L, LUA_REGISTRYINDEX, "luacy_parse");
        lua_pop(L, 2);

        load_module("init");
    }

    void reset() {
#ifndef SERVER
        deleteparticles();
        deletedecals();
        clearanims();
#endif
        external_handler = LUA_REFNIL;
        lua_close(L);
        L = NULL;
        init();
#ifndef SERVER
        tools::execfile("config/ui.lua");
#endif
    }

    void close() {
        lua_close(L);
        delete funs;
        delete cfuns;
    }

    struct reads {
        const char *str;
        size_t size;
    };

    static const char *read_str(lua_State *L, void *data, size_t *size) {
        reads *rd = (reads*)data;
        (void)L;
        if (rd->size == 0) return NULL;
        *size = rd->size;
        rd->size = 0;
        return rd->str;
    }

    static int err_file(lua_State *L, const char *what, int fnameidx) {
        const char *errstr = strerror(errno);
        const char *fname = lua_tostring(L, fnameidx) + 1;
        lua_pushfstring(L, "cannot %s %s: %s", what, fname, errstr);
        lua_remove(L, fnameidx);
        return LUA_ERRFILE;
    }

    static int load_file(lua_State *L, const char *fname) {
        int fnameidx = lua_gettop(L) + 1;
        vector<char> buf;
        if (!fname) {
            lua_pushliteral(L, "=stdin");
            char buff[1024];
            size_t nread;
            while ((nread = fread(buff, 1, sizeof(buff), stdin))) {
                buf.reserve(nread);
                memcpy(buf.getbuf() + buf.length(), buff, nread);
                buf.advance(nread);
            }
        } else {
            lua_pushfstring(L, "@%s", fname);
            stream *f = openfile(fname, "rb");
            if (!f) return err_file(L, "open", fnameidx);
            f->seek(0, SEEK_END);
            size_t size = f->tell();
            buf.growbuf(size);
            f->seek(0, SEEK_SET);
            size_t asize = f->read(buf.getbuf(), size);
            if (size != asize) {
                delete f;
                return err_file(L, "read", fnameidx);
            }
            buf.advance(asize);
            delete f;
        }
        lua_getfield(L, LUA_REGISTRYINDEX, "luacy_parse");
        lua_pushvalue(L, fnameidx);
        lua_pushlstring(L, buf.getbuf(), buf.length());
        lua_pushboolean(L, logger::should_log(logger::DEBUG));
        int ret = lua_pcall(L, 3, 1, 0);
        if (ret) return ret;
        reads rd;
        const char *lstr = lua_tolstring(L, -1, &rd.size);
        rd.str = newstring(lstr, rd.size);
        size_t s;
        const char *fnl = lua_tolstring(L, fnameidx, &s);
        const char *fn = newstring(fnl, s);
        lua_pop(L, 2);
        ret = lua_load(L, read_str, &rd, fn);
        delete[] rd.str;
        delete[] fn;
        return ret;
    }

    static int load_string(lua_State *L, const char *str, const char *ch) {
        lua_getfield(L, LUA_REGISTRYINDEX, "luacy_parse");
        lua_pushstring(L, str);
        lua_pushvalue(L, -1);
        lua_pushboolean(L, logger::should_log(logger::DEBUG));
        int ret = lua_pcall(L, 3, 1, 0);
        if (ret) return ret;
        reads rd;
        const char *lstr = lua_tolstring(L, -1, &rd.size);
        rd.str = newstring(lstr, rd.size);
        lua_pop(L, 1);
        ret = lua_load(L, read_str, &rd, ch ? ch : rd.str);
        delete[] rd.str;
        return ret;
    }

    int load_string(const char *str, const char *ch) {
        return load_string(L, str, ch);
    }
} /* end namespace lua */
