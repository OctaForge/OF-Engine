#include <errno.h>

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "of_lua.h"

void deleteparticles();
void deletestains();
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

    static int external_handler = LUA_REFNIL;

    static bool push_external(lua_State *L, const char *name) {
        if (external_handler == LUA_REFNIL) return false;
        lua_rawgeti(L, LUA_REGISTRYINDEX, external_handler);
        lua_pushstring(L, name);
        lua_call(L, 1, 1);
        return !lua_isnil(L, -1);
    }

    struct va_ref { va_list ap; };

    static int vcall_external_i(lua_State *L, const char *name,
    const char *args, int retn, va_ref *ar) {
        if (!push_external(L, name)) return -1;
        int nargs = 0;
        while (*args) {
            switch (*args++) {
                case 's':
                    lua_pushstring(L, va_arg(ar->ap, const char*));
                    ++nargs; break;
                case 'S': {
                    const char *str = va_arg(ar->ap, const char*);
                    lua_pushlstring(L, str, va_arg(ar->ap, int));
                    ++nargs; break;
                }
                case 'd': case 'i':
                    lua_pushinteger(L, va_arg(ar->ap, int));
                    ++nargs; break;
                case 'f':
                    lua_pushnumber(L, va_arg(ar->ap, double));
                    ++nargs; break;
                case 'b':
                    lua_pushboolean(L, va_arg(ar->ap, int));
                    ++nargs; break;
                case 'p':
                    lua_pushlightuserdata(L, va_arg(ar->ap, void*));
                    ++nargs; break;
                case 'c':
                    lua_pushcfunction(L, va_arg(ar->ap, lua_CFunction));
                    ++nargs; break;
                case 'C': {
                    lua_CFunction cf = va_arg(ar->ap, lua_CFunction);
                    int nups = va_arg(ar->ap, int);
                    lua_pushcclosure(L, cf, nups);
                    nargs -= nups - 1; break;
                }
                case 'n':
                    lua_pushnil(L);
                    ++nargs; break;
                case 'v':
                    lua_pushvalue(L, va_arg(ar->ap, int));
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

    static bool vcall_external(lua_State *L, const char *name,
    const char *args, va_ref *ar) {
        return vcall_external_i(L, name, args, 0, ar) >= 0;
    }

    static bool vcall_external(const char *name, const char *args,
    va_ref *ar) {
        return vcall_external(L, name, args, ar) >= 0;
    }

    bool call_external(lua_State *L, const char *name, const char *args, ...) {
        va_ref ar;
        va_start(ar.ap, args);
        bool ret = vcall_external(L, name, args, &ar);
        va_end(ar.ap);
        return ret;
    }

    bool call_external(const char *name, const char *args, ...) {
        va_ref ar;
        va_start(ar.ap, args);
        bool ret = vcall_external(name, args, &ar);
        va_end(ar.ap);
        return ret;
    }

    static int vcall_external_ret(lua_State *L, const char *name,
    const char *args, const char *retargs, va_ref *ar) {
        int nr = LUA_MULTRET;
        if (retargs && *retargs == 'N') {
            ++retargs;
            nr = va_arg(ar->ap, int);
        }
        int nrets = vcall_external_i(L, name, args, nr, ar);
        if (nrets < 0) return -1;
        int idx = nrets;
        if (retargs) while (*retargs) {
            switch (*retargs++) {
                case 's':
                    *va_arg(ar->ap, const char**) = lua_tostring(L, -(idx--));
                    break;
                case 'd': case 'i':
                    *va_arg(ar->ap, int*) = lua_tointeger(L, -idx--);
                    break;
                case 'f':
                    *va_arg(ar->ap, float*) = lua_tonumber(L, -idx--);
                    break;
                case 'F':
                    *va_arg(ar->ap, double*) = lua_tonumber(L, -idx--);
                    break;
                case 'b':
                    *va_arg(ar->ap, bool*) = lua_toboolean(L, -idx--);
                    break;
                default:
                    assert(false);
                    break;
            }
        }
        return nrets;
    }

    static int vcall_external_ret(const char *name, const char *args,
    const char *retargs, va_ref *ar) {
        return vcall_external_ret(L, name, args, retargs, ar);
    }

    int call_external_ret(lua_State *L, const char *name, const char *args,
    const char *retargs, ...) {
        va_ref ar;
        va_start(ar.ap, retargs);
        int ret = vcall_external_ret(L, name, args, retargs, &ar);
        va_end(ar.ap);
        return ret;
    }

    int call_external_ret(const char *name, const char *args,
    const char *retargs, ...) {
        va_ref ar;
        va_start(ar.ap, retargs);
        int ret = vcall_external_ret(name, args, retargs, &ar);
        va_end(ar.ap);
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

    /* streams! */

    static int s_push_ret(lua_State *L, bool succ, const char *fname = NULL) {
        int en = errno;
        if (succ) {
            lua_pushboolean(L, true);
            return 1;
        } else {
            lua_pushnil(L);
            if (fname) lua_pushfstring(L, "%s: %s", fname, strerror(en));
            else       lua_pushfstring(L, "%s",            strerror(en));
            lua_pushinteger(L, en);
            return 3;
        }
    }

    static stream *s_get_stream(lua_State *L, int n = 1) {
        stream *f = *((stream**)luaL_checkudata(L, n, "Stream"));
        if    (!f) luaL_error(L, "attempt to use a closed stream");
        return  f;
    }

    static bool s_test_eof(lua_State *L, stream *f) {
        lua_pushlstring(L, NULL, 0);
        return f->tell() == f->size();
    }

    static bool s_read_line(lua_State *L, stream *f) {
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        for (;;) {
            char *p = luaL_prepbuffer(&b);
            if (!f->getline(p, LUAL_BUFFERSIZE)) {
                luaL_pushresult(&b);
                return (lua_objlen(L, -1) > 0);
            }
            size_t l = strlen(p);
            if (!l || p[l - 1] != '\n') luaL_addsize(&b, l);
            else {
                luaL_addsize(&b, l - 1);
                luaL_pushresult(&b);
                return true;
            }
        }
    }

    static bool s_read_chars(lua_State *L, stream *f, size_t n) {
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        size_t rlen = LUAL_BUFFERSIZE, nr;
        do {
            char *p = luaL_prepbuffer(&b);
            rlen = min(rlen, n);
            nr = f->read(p, rlen * sizeof(char));
            luaL_addsize(&b, nr);
            n -= nr;
        } while (n > 0 && nr == rlen);
        luaL_pushresult(&b);
        return (!n || lua_objlen(L, -1) > 0);
    }

    static int s_wrap_read_line(lua_State *L) {
        stream *f = *((stream**)lua_touserdata(L, lua_upvalueindex(1)));
        if  (!f) luaL_error(L, "stream is already closed");
        return s_read_line(L, f);
    }

    static int stream_lines(lua_State *L) {
        s_get_stream(L);
        lua_pushvalue(L, 1);
        lua_pushcclosure(L, s_wrap_read_line, 1);
        return 1;
    }

    static int stream_read(lua_State *L) {
        bool success;
        int n;
        int nargs = lua_gettop(L) - 1;
        stream *f = s_get_stream(L);
        if (!nargs) {
            success = s_read_line(L, f);
            n = 3;
        } else {
            luaL_checkstack(L, nargs + LUA_MINSTACK, "too many arguments");
            success = true;
            for (n = 2; nargs-- && success; ++n) {
                if (lua_type(L, n) == LUA_TNUMBER) {
                    size_t l = (size_t)lua_tointeger(L, n);
                    success = (!l) ? s_test_eof(L, f) : s_read_chars(L, f, l);
                } else {
                    const char *p = lua_tostring(L, n);
                    luaL_argcheck(L, p && *p == '*', n, "invalid operation");
                    switch (*(p + 1)) {
                        case 'l': success = s_read_line(L, f); break;
                        case 'a':
                            s_read_chars(L, f, ~((size_t)0));
                            success = true;
                            break;
                        default: return luaL_argerror(L, n, "invalid format");
                    }
                }
            }
        }
        if (!success) {
            lua_pop(L, 1);
            lua_pushnil(L);
        }
        return n - 2;
    }

    static int stream_write(lua_State *L) {
        bool status = true;
        int nargs = lua_gettop(L) - 1;
        stream *f = s_get_stream(L);
        for (int arg = 2; nargs--; ++arg) {
            if (lua_type(L, arg) == LUA_TNUMBER) {
                status = status && (f->printf(LUA_NUMBER_FMT,
                    lua_tonumber(L, arg)) > 0);
            } else {
                size_t l;
                const char *s = luaL_checklstring(L, arg, &l);
                l *= sizeof(char);
                status = status && (f->write(s, l) == l);
            }
        }
        return s_push_ret(L, status);
    }

    static int stream_seek(lua_State *L) {
        static const int          mode[] = { SEEK_SET, SEEK_CUR, SEEK_END };
        static const char * const name[] = { "set", "cur", "end", NULL    };
        stream *f   = s_get_stream(L);
        int  op     = luaL_checkoption(L, 2, "cur", name);
        long offset = luaL_optlong    (L, 3, 0);
        if (f->seek(offset, mode[op])) return s_push_ret(L, false);
        lua_pushinteger(L, f->tell());
        return 1;
    }

    static int stream_close(lua_State *L) {
        stream *f = s_get_stream(L);
        if (f->decref()) delete f;
        *((stream**)lua_touserdata(L, 1)) = NULL;
        lua_pushboolean(L, true);
        return 1;
    }

    static stream **io_newfile(lua_State *L) {
        stream **ud = (stream**)lua_newuserdata(L, sizeof(stream*));
        *ud = NULL;
        luaL_getmetatable(L, "Stream");
        lua_setmetatable (L, -2);
        return ud;
    }

    #define STREAMOPENPARAMS(fname, mode, ud) \
        const char *fname = luaL_checkstring(L, 1); \
        const char *mode  = luaL_optstring  (L, 2, "r"); \
        stream **ud = io_newfile(L);

    #define STREAMOPEN2ARGS(name, fun) \
        LUAICOMMAND(name, { \
            STREAMOPENPARAMS(fname, mode, ud) \
            return (!(*ud = fun(fname, mode))) ? s_push_ret(L, 0, fname) : 1; \
        });

    STREAMOPEN2ARGS(stream_open_raw, openrawfile)
#ifndef STANDALONE
    STREAMOPEN2ARGS(stream_open_zip, openzipfile)
#endif
    STREAMOPEN2ARGS(stream_open, openfile)

    #undef STREAMOPEN2ARGS

    LUAICOMMAND(stream_open_gz, {
        STREAMOPENPARAMS(fname, mode, ud)
        stream *file = NULL;
        if (!lua_isnoneornil(L, 3)) {
            file = s_get_stream(L, 3);
            if (file->refcount < 0) file->refcount = 0;
            file->incref();
        }
        int level = luaL_optinteger(L, 4, Z_BEST_COMPRESSION);
        return (!(*ud = opengzfile(fname, mode, file, level)))
            ? s_push_ret(L, 0, fname) : 1;
    });

    LUAICOMMAND(stream_open_utf8, {
        STREAMOPENPARAMS(fname, mode, ud)
        stream *file = NULL;
        if (!lua_isnoneornil(L, 3)) {
            file = s_get_stream(L, 3);
            if (file->refcount < 0) file->refcount = 0;
            file->incref();
        }
        return (!(*ud = openutf8file(fname, mode, file)))
            ? s_push_ret(L, 0, fname) : 1;
    });

    #undef STREAMOPENPARAMS

    LUAICOMMAND(stream_type, {
        luaL_checkany(L, 1);
        void *ud = lua_touserdata(L, 1);
        lua_getfield(L, LUA_REGISTRYINDEX, "Stream");
        if (!ud || !lua_getmetatable(L, 1) || !lua_rawequal(L, -2, -1))
            lua_pushnil(L);
        else if (!*((stream**)ud)) lua_pushliteral(L, "closed stream");
        else                       lua_pushliteral(L, "stream");
        return 1;
    });

    static int stream_meta_gc(lua_State *L) {
        stream *f = *((stream**)luaL_checkudata(L, 1, "Stream"));
        if (f && f->decref()) delete f;
        return 0;
    }

    static int stream_meta_tostring(lua_State *L) {
        stream *f = *((stream**)luaL_checkudata(L, 1, "Stream"));
        if    (!f) lua_pushliteral(L, "stream (closed)");
        else       lua_pushfstring(L, "stream (%p)",  f);
        return 1;
    }

    static const luaL_Reg streamlib[] = {
        { "close",      stream_close         },
        { "lines",      stream_lines         },
        { "read",       stream_read          },
        { "seek",       stream_seek          },
        { "write",      stream_write         },
        { "__gc",       stream_meta_gc       },
        { "__tostring", stream_meta_tostring },
        { NULL,         NULL}
    };

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
        lua_pushfstring(L, ";%smedia/?/init.oct", homedir);
        lua_pushfstring(L, ";%smedia/?/init.lua", homedir);
        lua_pushfstring(L, ";%smedia/?.oct", homedir);
        lua_pushfstring(L, ";%smedia/?.lua", homedir);
        lua_pushfstring(L, ";%smedia/scripts/lang/octascript/?/init.oct", homedir);
        lua_pushfstring(L, ";%smedia/scripts/lang/octascript/?/init.lua", homedir);
        lua_pushfstring(L, ";%smedia/scripts/lang/octascript/?.oct", homedir);
        lua_pushfstring(L, ";%smedia/scripts/lang/octascript/?.lua", homedir);
        lua_pushfstring(L, ";%smedia/scripts/?/init.oct", homedir);
        lua_pushfstring(L, ";%smedia/scripts/?/init.lua", homedir);
        lua_pushfstring(L, ";%smedia/scripts/?.oct", homedir);
        lua_pushfstring(L, ";%smedia/scripts/?.lua", homedir);
#else
        lua_pushfstring(L, ";%smedia\\?\\init.oct", homedir);
        lua_pushfstring(L, ";%smedia\\?\\init.lua", homedir);
        lua_pushfstring(L, ";%smedia\\?.oct", homedir);
        lua_pushfstring(L, ";%smedia\\?.lua", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\lang\\octascript\\?\\init.oct", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\lang\\octascript\\?\\init.lua", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\lang\\octascript\\?.oct", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\lang\\octascript\\?.lua", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\?\\init.oct", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\?\\init.lua", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\?.oct", homedir);
        lua_pushfstring(L, ";%smedia\\scripts\\?.lua", homedir);
#endif

        /* root paths */
        lua_pushliteral(L, ";./media/?/init.oct");
        lua_pushliteral(L, ";./media/?/init.lua");
        lua_pushliteral(L, ";./media/?.oct");
        lua_pushliteral(L, ";./media/?.lua");
        lua_pushliteral(L, ";./media/scripts/lang/octascript/?/init.oct");
        lua_pushliteral(L, ";./media/scripts/lang/octascript/?/init.lua");
        lua_pushliteral(L, ";./media/scripts/lang/octascript/?.oct");
        lua_pushliteral(L, ";./media/scripts/lang/octascript/?.lua");
        lua_pushliteral(L, ";./media/scripts/?/init.oct");
        lua_pushliteral(L, ";./media/scripts/?/init.lua");
        lua_pushliteral(L, ";./media/scripts/?.oct");
        lua_pushliteral(L, ";./media/scripts/?.lua");

        lua_concat  (L, 24);
        lua_setfield(L, -2, "path"); lua_pop(L, 1);

        /* stream functions */
        luaL_newmetatable(L, "Stream");
        lua_pushvalue    (L, -1);
        lua_setfield     (L, -2, "__index");
        luaL_register    (L, NULL, streamlib);
        lua_pop          (L, 1);

        setup_binds();
    }

    void load_module(const char *name)
    {
        defformatstring(p, "%s/%s.oct", mod_dir, name);
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
        luaL_error(L, "attempt to write into the C API (%s)", lua_tostring(L, 2));
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
            "struct cube_t; typedef struct cube_t cube_t;\n"
            "struct ucharbuf; typedef struct ucharbuf ucharbuf;\n"
            "struct physent; typedef struct physent physent;\n"
            "struct extentity; typedef struct extentity extentity;\n");
        lua_call(L, 1, 0);
        lua_getfield(L, -1, "cast");
        lua_replace(L, -2);
    }

    void setup_binds()
    {
#ifndef STANDALONE
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

        /* load octascript early on */
        lua_getfield(L, LUA_REGISTRYINDEX, "_LOADED");
        lua_getglobal(L, "require");
        lua_pushliteral(L, "lang");
        lua_call(L, 1, 1);
        lua_getfield(L, -1, "compile");
        lua_setfield(L, LUA_REGISTRYINDEX, "octascript_compile");
        lua_getfield(L, -1, "env");
        lua_setfield(L, LUA_REGISTRYINDEX, "octascript_env");
        lua_pop(L, 2);

        load_module("init");
    }

    void reset() {
#ifndef STANDALONE
        deleteparticles();
        deletestains();
        clearanims();
#endif
        external_handler = LUA_REFNIL;
        lua_close(L);
        L = NULL;
        init();
#ifndef STANDALONE
        lua::execfile("config/ui.oct");
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
            size_t size = f->size();
            if (size <= 0) {
                delete f;
                return err_file(L, "read", fnameidx);
            }
            buf.growbuf(size);
            size_t asize = f->read(buf.getbuf(), size);
            if (size != asize) {
                delete f;
                return err_file(L, "read", fnameidx);
            }
            buf.advance(asize);
            delete f;
        }
        lua_getfield(L, LUA_REGISTRYINDEX, "octascript_compile");
        lua_pushvalue(L, fnameidx);
        lua_pushlstring(L, buf.getbuf(), buf.length());
        int ret = lua_pcall(L, 2, 1, 0);
        if (ret) return ret;
        reads rd;
        const char *lstr = lua_tolstring(L, -1, &rd.size);
        char *dups = new char[rd.size];
        rd.str = dups;
        memcpy(dups, lstr, rd.size);
        size_t s;
        const char *fnl = lua_tolstring(L, fnameidx, &s);
        const char *fn = newstring(fnl, s);
        lua_pop(L, 2);
        ret = lua_load(L, read_str, &rd, fn);
        if (!ret) {
            lua_getfield(L, LUA_REGISTRYINDEX, "octascript_env");
            lua_setfenv(L, -2);
        }
        delete[] dups;
        delete[] fn;
        return ret;
    }

    static int load_string(lua_State *L, const char *str, const char *ch) {
        lua_getfield(L, LUA_REGISTRYINDEX, "octascript_compile");
        lua_pushstring(L, str);
        lua_pushvalue(L, -1);
        int ret = lua_pcall(L, 2, 1, 0);
        if (ret) return ret;
        reads rd;
        const char *lstr = lua_tolstring(L, -1, &rd.size);
        char *dups = new char[rd.size];
        rd.str = dups;
        memcpy(dups, lstr, rd.size);
        lua_pop(L, 1);
        ret = lua_load(L, read_str, &rd, ch ? ch : rd.str);
        if (!ret) {
            lua_getfield(L, LUA_REGISTRYINDEX, "octascript_env");
            lua_setfenv(L, -2);
        }
        delete[] dups;
        return ret;
    }

    int load_string(const char *str, const char *ch) {
        return load_string(L, str, ch);
    }

    bool execfile(const char *cfgfile, bool msg)
    {
        string s;
        copystring(s, cfgfile);
        char *buf = loadfile(path(s), NULL);
        if(!buf)
        {
            if(msg) {
                logger::log(logger::ERROR, "could not read \"%s\"", cfgfile);
            }
            return false;
        }
        defformatstring(chunk, "@%s", cfgfile);
        if (lua::load_string(buf,  chunk) || lua_pcall(lua::L, 0, 0, 0)) {
            if (msg) {
                logger::log(logger::ERROR, "%s", lua_tostring(lua::L, -1));
            }
            lua_pop(lua::L, 1);
            delete[] buf;
            return false;
        }
        delete[] buf;
        return true;
    }

    CLUAICOMMAND(raw_alloc, void *, (size_t nbytes), return (void*) new uchar[nbytes];)
    CLUAICOMMAND(raw_free, void, (void *ptr), delete[] (uchar*)ptr;)
    CLUAICOMMAND(raw_move, void, (void *dst, const void *src, size_t nbytes), memmove(dst, src, nbytes);)
} /* end namespace lua */
