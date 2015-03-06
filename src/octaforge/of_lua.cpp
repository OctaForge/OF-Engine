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
    /* some initial stuff */

    static string mod_dir = "";

    static int externals = LUA_REFNIL;

    struct Reg {
        const char *name;
        lua_CFunction fun;
        Reg(const char *n, lua_CFunction f): name(n), fun(f) {};
    };
    typedef vector<Reg> apifuns;
    static apifuns *funs = NULL;

    struct CReg {
        const char *name, *sig;
        void *fun;
        CReg(const char *n, const char *s, void *f): name(n), sig(s), fun(f) {};
    };
    typedef vector<CReg> capifuns;
    static capifuns *cfuns = NULL;

    /* stream API */

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

    /* actual state */

    static void setup_binds(State *s, bool dedicated);

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

    static int lua_panic(lua_State *L) {
        lua_getfield(L, LUA_REGISTRYINDEX, "octascript_traceback");
        lua_pushfstring(L, "error in call to the Lua API (%s)",
            lua_tostring(L, -2));
        lua_call(L, 1, 1);
        fatal("%s", lua_tostring(L, -1));
        return 0;
    }


    State::State(bool dedicated, const char *dir) {
        copystring(mod_dir, dir);

        state = luaL_newstate();
        if (!state) return;
        lua_atpanic(state, lua_panic);
        luaL_openlibs(state);

        lua_getglobal(state, "package");

        /* home directory paths */
#ifndef WIN32
        lua_pushfstring(state, ";%smedia/?/init.oct", homedir);
        lua_pushfstring(state, ";%smedia/?/init.lua", homedir);
        lua_pushfstring(state, ";%smedia/?.oct", homedir);
        lua_pushfstring(state, ";%smedia/?.lua", homedir);
        lua_pushfstring(state, ";%smedia/scripts/lang/octascript/?/init.oct", homedir);
        lua_pushfstring(state, ";%smedia/scripts/lang/octascript/?/init.lua", homedir);
        lua_pushfstring(state, ";%smedia/scripts/lang/octascript/?.oct", homedir);
        lua_pushfstring(state, ";%smedia/scripts/lang/octascript/?.lua", homedir);
        lua_pushfstring(state, ";%smedia/scripts/?/init.oct", homedir);
        lua_pushfstring(state, ";%smedia/scripts/?/init.lua", homedir);
        lua_pushfstring(state, ";%smedia/scripts/?.oct", homedir);
        lua_pushfstring(state, ";%smedia/scripts/?.lua", homedir);
#else
        lua_pushfstring(state, ";%smedia\\?\\init.oct", homedir);
        lua_pushfstring(state, ";%smedia\\?\\init.lua", homedir);
        lua_pushfstring(state, ";%smedia\\?.oct", homedir);
        lua_pushfstring(state, ";%smedia\\?.lua", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\lang\\octascript\\?\\init.oct", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\lang\\octascript\\?\\init.lua", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\lang\\octascript\\?.oct", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\lang\\octascript\\?.lua", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\?\\init.oct", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\?\\init.lua", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\?.oct", homedir);
        lua_pushfstring(state, ";%smedia\\scripts\\?.lua", homedir);
#endif

        /* root paths */
        lua_pushliteral(state, ";./media/?/init.oct");
        lua_pushliteral(state, ";./media/?/init.lua");
        lua_pushliteral(state, ";./media/?.oct");
        lua_pushliteral(state, ";./media/?.lua");
        lua_pushliteral(state, ";./media/scripts/lang/octascript/?/init.oct");
        lua_pushliteral(state, ";./media/scripts/lang/octascript/?/init.lua");
        lua_pushliteral(state, ";./media/scripts/lang/octascript/?.oct");
        lua_pushliteral(state, ";./media/scripts/lang/octascript/?.lua");
        lua_pushliteral(state, ";./media/scripts/?/init.oct");
        lua_pushliteral(state, ";./media/scripts/?/init.lua");
        lua_pushliteral(state, ";./media/scripts/?.oct");
        lua_pushliteral(state, ";./media/scripts/?.lua");

        lua_concat  (state, 24);
        lua_setfield(state, -2, "path"); lua_pop(state, 1);

        /* stream functions */
        luaL_newmetatable(state, "Stream");
        lua_pushvalue    (state, -1);
        lua_setfield     (state, -2, "__index");
        luaL_register    (state, NULL, streamlib);
        lua_pop          (state, 1);

        setup_binds(this, dedicated);
    }

    State::~State() {
        lua_close(state);
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
            "struct ucharbuf; typedef struct ucharbuf ucharbuf;\n");
        lua_call(L, 1, 0);
        lua_getfield(L, -1, "cast");
        lua_replace(L, -2);
    }

    static void setup_binds(State *s, bool dedicated) {
        lua_pushboolean(s->state, dedicated);
        lua_setglobal(s->state, "SERVER");

        assert(funs);
        lua_getfield(s->state, LUA_REGISTRYINDEX, "_PRELOAD");
        int numfields = funs->length();
        int numcfields = cfuns ? cfuns->length() : 0;
        int tnf = numfields + numcfields;
        lua_createtable(s->state, tnf, 0);
        for (int i = 0; i < numfields; ++i) {
            const Reg &reg = (*funs)[i];
            lua_pushcfunction(s->state, reg.fun);
            lua_setfield(s->state, -2, reg.name);
        }
        setup_ffi(s->state);
        for (int i = 0; i < numcfields; ++i) {
            const CReg &reg = (*cfuns)[i];     /* cast */
            lua_pushvalue(s->state, -1);              /* cast, cast */
            lua_pushstring(s->state, reg.sig);        /* cast, cast, sig */
            lua_pushlightuserdata(s->state, reg.fun); /* cast, cast, sig, udata */
            lua_call(s->state, 2, 1);                 /* cast, fptr */
            lua_setfield(s->state, -3, reg.name);     /* cast */
        }
        lua_pop(s->state, 1);
        lua_createtable(s->state, 0, 2);              /* _C, C_mt */
        lua_pushinteger(s->state, tnf);               /* _C, C_mt, C_num */
        lua_pushcclosure(s->state, capi_tostring, 1); /* _C, C_mt, C_tostring */
        lua_setfield(s->state, -2, "__tostring");     /* _C, C_mt */
        lua_pushcfunction(s->state, capi_newindex);   /* _C, C_mt, C_newindex */
        lua_setfield(s->state, -2, "__newindex");     /* _C, C_mt */
        lua_pushboolean(s->state, false);             /* _C, C_mt, C_metatable */
        lua_setfield(s->state, -2, "__metatable");    /* _C, C_mt */
        lua_setmetatable(s->state, -2);               /* _C */
        lua_pushcclosure(s->state, capi_get, 1);      /* C_get */
        lua_setfield(s->state, -2, "capi");
        lua_pop(s->state, 1); /* _PRELOAD */

        /* load octascript early on */
        lua_getfield(s->state, LUA_REGISTRYINDEX, "_LOADED");
        lua_getglobal(s->state, "require");
        lua_pushliteral(s->state, "lang");
        lua_call(s->state, 1, 1);
        lua_getfield(s->state, -1, "compile");
        lua_setfield(s->state, LUA_REGISTRYINDEX, "octascript_compile");
        lua_getfield(s->state, -1, "env");
        lua_setfield(s->state, LUA_REGISTRYINDEX, "octascript_env");
        lua_getfield(s->state, -1, "traceback");
        lua_setfield(s->state, LUA_REGISTRYINDEX, "octascript_traceback");
        lua_pop(s->state, 2);

        s->load_module("init");
    }

    bool State::push_external(const char *name) {
        if (externals == LUA_REFNIL) return false;
        lua_rawgeti(state, LUA_REGISTRYINDEX, externals);
        lua_getfield(state, -1, name);
        if (lua_isnil(state, -1)) {
            lua_pop(state, 2);
            return false;
        }
        lua_replace(state, -2);
        return true;
    }

    static int vcall_external(State *s, const char *name, const char *args,
    int retn, va_ref *ar) {
        if (!s->push_external(name)) return -1;
        int nargs = 0;
        while (*args) {
            switch (*args++) {
                case 's':
                    lua_pushstring(s->state, va_arg(ar->ap, const char *));
                    ++nargs; break;
                case 'S': {
                    const char *str = va_arg(ar->ap, const char *);
                    lua_pushlstring(s->state, str, va_arg(ar->ap, int));
                    ++nargs; break;
                }
                case 'd': case 'i':
                    lua_pushinteger(s->state, va_arg(ar->ap, int));
                    ++nargs; break;
                case 'f':
                    lua_pushnumber(s->state, va_arg(ar->ap, double));
                    ++nargs; break;
                case 'b':
                    lua_pushboolean(s->state, va_arg(ar->ap, int));
                    ++nargs; break;
                case 'p':
                    lua_pushlightuserdata(s->state, va_arg(ar->ap, void *));
                    ++nargs; break;
                case 'c':
                    lua_pushcfunction(s->state, va_arg(ar->ap, lua_CFunction));
                    ++nargs; break;
                case 'C': {
                    lua_CFunction cf = va_arg(ar->ap, lua_CFunction);
                    int nups = va_arg(ar->ap, int);
                    lua_pushcclosure(s->state, cf, nups);
                    nargs -= nups - 1; break;
                }
                case 'n':
                    lua_pushnil(s->state);
                    ++nargs; break;
                case 'v':
                    lua_pushvalue(s->state, va_arg(ar->ap, int));
                    ++nargs; break;
                case 'm':
                    if (!s->push_external("buf_get_msgpack")) {
                        lua_pushnil(s->state);
                    } else {
                        lua_getfield(s->state, LUA_REGISTRYINDEX, "octascript_traceback");
                        lua_insert(s->state, -2);
                        lua_pushlightuserdata(s->state, va_arg(ar->ap, void *));
                        if (lua_pcall(s->state, 1, 1, -3)) {
                            logger::log(logger::ERROR, "%s", lua_tostring(s->state, -1));
                            lua_pop(s->state, 2);
                            lua_pushnil(s->state); // dummy result (nil)
                        } else {
                            lua_remove(s->state, -2);
                        }
                    }
                    ++nargs; break;
                default:
                    assert(false);
                    break;
            }
        }
        int n1 = lua_gettop(s->state) - nargs - 1;
        lua_getfield(s->state, LUA_REGISTRYINDEX, "octascript_traceback");
        lua_insert(s->state, -nargs - 2);
        if (lua_pcall(s->state, nargs, retn, -nargs - 2)) {
            logger::log(logger::ERROR, "%s", lua_tostring(s->state, -1));
            lua_pop(s->state, 2);
            return -1;
        }
        lua_remove(s->state, n1 - lua_gettop(s->state) - 1);
        return lua_gettop(s->state) - n1;
    }

    bool State::call_external(const char *name, const char *args, ...) {
        va_ref ar;
        va_start(ar.ap, args);
        bool ret = vcall_external(this, name, args, 0, &ar) >= 0;
        va_end(ar.ap);
        return ret;
    }

    static int vcall_external_ret(State *s, const char *name,
    const char *args, const char *retargs, va_ref *ar) {
        int nr = LUA_MULTRET;
        if (retargs && *retargs == 'N') {
            ++retargs;
            nr = va_arg(ar->ap, int);
        }
        int nrets = vcall_external(s, name, args, nr, ar);
        if (nrets < 0) return -1;
        int idx = nrets;
        if (retargs) while (*retargs) {
            switch (*retargs++) {
                case 'S': {
                    const char *lstr = lua_tostring(s->state, -idx--);
                    char *fstr = va_arg(ar->ap, char *);
                    if  (!lstr) fstr[0] = '\0';
                    else memcpy(fstr, lstr, strlen(lstr) + 1);
                    break;
                }
                case 's':
                    *va_arg(ar->ap, const char **) = lua_tostring(s->state, -idx--);
                    break;
                case 'd': case 'i':
                    *va_arg(ar->ap, int *) = lua_tointeger(s->state, -idx--);
                    break;
                case 'f':
                    *va_arg(ar->ap, float *) = lua_tonumber(s->state, -idx--);
                    break;
                case 'F':
                    *va_arg(ar->ap, double *) = lua_tonumber(s->state, -idx--);
                    break;
                case 'b':
                    *va_arg(ar->ap, bool *) = lua_toboolean(s->state, -idx--);
                    break;
                case 'm': {
                    const char **r = va_arg(ar->ap, const char **);
                    size_t *l = va_arg(ar->ap, size_t *);
                    *r = lua_tolstring(s->state, -idx--, l);
                    break;
                }
                case 'v':
                    idx--;
                    break;
                default:
                    assert(false);
                    break;
            }
        }
        return nrets;
    }

    int State::call_external_ret_nopop(const char *name, const char *args,
    const char *retargs, ...) {
        va_ref ar;
        va_start(ar.ap, retargs);
        int ret = vcall_external_ret(this, name, args, retargs, &ar);
        va_end(ar.ap);
        return ret;
    }

    bool State::call_external_ret(const char *name, const char *args,
    const char *retargs, ...) {
        va_ref ar;
        va_start(ar.ap, retargs);
        int ret = vcall_external_ret(this, name, args, retargs, &ar);
        if (ret > 0) lua_pop(state, ret);
        va_end(ar.ap);
        return ret >= 0;
    }

    void State::pop_external_ret(int n) { if (n > 0) lua_pop(state, n); }

    void State::load_module(const char *name)  {
        defformatstring(p, "%s/%s.oct", mod_dir, name);
        path(p);
        logger::log(logger::DEBUG, "Loading OF Lua module: %s.\n", p);
        lua_getfield(state, LUA_REGISTRYINDEX, "octascript_traceback");
        if (load_file(p) || lua_pcall(state, 0, 0, -2)) {
            fatal("%s", lua_tostring(state, -1));
        }
        lua_pop(state, 1);
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

    int State::load_file(const char *fname) {
        int fnameidx = lua_gettop(state) + 1;
        vector<char> buf;
        if (!fname) {
            lua_pushliteral(state, "=stdin");
            char buff[1024];
            size_t nread;
            while ((nread = fread(buff, 1, sizeof(buff), stdin))) {
                buf.reserve(nread);
                memcpy(buf.getbuf() + buf.length(), buff, nread);
                buf.advance(nread);
            }
        } else {
            lua_pushfstring(state, "@%s", fname);
            stream *f = openfile(fname, "rb");
            if (!f) return err_file(state, "open", fnameidx);
            size_t size = f->size();
            if (size <= 0) {
                delete f;
                return err_file(state, "read", fnameidx);
            }
            buf.growbuf(size);
            size_t asize = f->read(buf.getbuf(), size);
            if (size != asize) {
                delete f;
                return err_file(state, "read", fnameidx);
            }
            buf.advance(asize);
            delete f;
        }
        lua_getfield(state, LUA_REGISTRYINDEX, "octascript_compile");
        lua_pushvalue(state, fnameidx);
        lua_pushlstring(state, buf.getbuf(), buf.length());
        int ret = lua_pcall(state, 2, 1, 0);
        if (ret) return ret;
        reads rd;
        const char *lstr = lua_tolstring(state, -1, &rd.size);
        char *dups = new char[rd.size];
        rd.str = dups;
        memcpy(dups, lstr, rd.size);
        size_t s;
        const char *fnl = lua_tolstring(state, fnameidx, &s);
        const char *fn = newstring(fnl, s);
        lua_pop(state, 2);
        ret = lua_load(state, read_str, &rd, fn);
        if (!ret) {
            lua_getfield(state, LUA_REGISTRYINDEX, "octascript_env");
            lua_setfenv(state, -2);
        }
        delete[] dups;
        delete[] fn;
        return ret;
    }

    int State::load_string(const char *str, const char *ch) {
        lua_getfield(state, LUA_REGISTRYINDEX, "octascript_compile");
        if (!ch || !ch[0]) {
            lua_pushstring(state, str);
            lua_pushvalue(state, -1);
        } else {
            lua_pushstring(state, ch);
            lua_pushstring(state, str);
        }
        int ret = lua_pcall(state, 2, 1, 0);
        if (ret) return ret;
        reads rd;
        const char *lstr = lua_tolstring(state, -1, &rd.size);
        char *dups = new char[rd.size];
        rd.str = dups;
        memcpy(dups, lstr, rd.size);
        lua_pop(state, 1);
        ret = lua_load(state, read_str, &rd, ch ? ch : rd.str);
        if (!ret) {
            lua_getfield(state, LUA_REGISTRYINDEX, "octascript_env");
            lua_setfenv(state, -2);
        }
        delete[] dups;
        return ret;
    }

    bool State::exec_file(const char *cfgfile, bool msg)
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
        lua_getfield(state, LUA_REGISTRYINDEX, "octascript_traceback");
        if (load_string(buf, chunk) || lua_pcall(state, 0, 0, -2)) {
            if (msg) {
                fatal("%s", lua_tostring(state, -1));
            }
            lua_pop(state, 2);
            delete[] buf;
            return false;
        }
        lua_pop(state, 1);
        delete[] buf;
        return true;
    }

    /* Other external stuff */

    State *L = NULL;

    LUAICOMMAND(external_hook, {
        lua_pushvalue(L, 1);
        externals = luaL_ref(L, LUA_REGISTRYINDEX);
        return 0;
    })

    bool reg_fun(const char *name, lua_CFunction fun) {
        if (!funs) funs = new apifuns;
        funs->add(Reg(name, fun));
        return true;
    }

    bool reg_cfun(const char *name, const char *sig, void *fun) {
        if (!cfuns) cfuns = new capifuns;
        cfuns->add(CReg(name, sig, fun));
        return true;
    }


    bool init(bool dedicated, const char *dir)
    {
        if (L) return true;
        L = new State(dedicated, dir);
        if (!L->state) {
            delete L;
            L = NULL;
            return false;
        }
        return true;
    }

    LUAICOMMANDN(reload_core, LL, {
        L->load_module("init");
        return 0;
    })

    void reset() {

#ifndef STANDALONE
        deleteparticles();
        deletestains();
        clearanims();
#endif
        L->call_external("state_restore", "");
#ifndef STANDALONE
        L->exec_file("config/ui.oct");
#endif
    }

    void close() {
        delete L;
        delete funs;
        delete cfuns;
    }

    void assert_stack() {
        assert(!lua_gettop(L->state));
    }

    CLUAICOMMAND(raw_alloc, void *, (size_t nbytes), return (void*) new uchar[nbytes];)
    CLUAICOMMAND(raw_free, void, (void *ptr), delete[] (uchar*)ptr;)
    CLUAICOMMAND(raw_move, void, (void *dst, const void *src, size_t nbytes), memmove(dst, src, nbytes);)

    ICOMMAND(lua, "s", (char *str), {
        lua_getfield(L->state, LUA_REGISTRYINDEX, "octascript_traceback");
        if (L->load_string(str)) {
            lua_pushfstring(L->state, "error in call to the Lua API (%s)",
                lua_tostring(L->state, -2));
            lua_call(L->state, 1, 1);
            logger::log(logger::ERROR, "%s", lua_tostring(L->state, -1));
            lua_pop(L->state, 1);
            return;
        }
        if (lua_pcall(L->state, 0, 1, -2)) {
            logger::log(logger::ERROR, "%s", lua_tostring(L->state, -1));
            lua_pop(L->state, 2);
            return;
        }
        if (lua_isnumber(L->state, -1)) {
            int a = lua_tointeger(L->state, -1);
            float b = lua_tonumber(L->state, -1);
            lua_pop(L->state, 2);
            if ((float)a == b) {
                intret(a);
            } else {
                floatret(b);
            }
        } else if (lua_isstring(L->state, -1)) {
            const char *s = lua_tostring(L->state, -1);
            lua_pop(L->state, 2);
            result(s);
        } else if (lua_isboolean(L->state, -1)) {
            bool b = lua_toboolean(L->state, -1);
            lua_pop(L->state, 2);
            intret(b);
        } else {
            lua_pop(L->state, 2);
        }
    })

    ICOMMAND(scriptaction, "sV", (tagval *args, int nargs), {
        if (nargs <= 0) return;
        const char *actname = args[0].getstr();
        if (!L->push_external("input_action_call")) return;
        lua_getfield(L->state, LUA_REGISTRYINDEX, "octascript_traceback");
        lua_insert(L->state, -2);
        lua_pushstring(L->state, actname);
        for (int i = 1; i < nargs; ++i) {
            tagval &v = args[i];
            switch (v.type) {
                case VAL_INT:
                    lua_pushinteger(L->state, v.getint()); break;
                case VAL_FLOAT:
                    lua_pushnumber(L->state, v.getfloat()); break;
                case VAL_STR:
                    lua_pushstring(L->state, v.getstr()); break;
                default:
                    const char *str = v.getstr();
                    if (str && str[0]) lua_pushstring(L->state, str);
                    else lua_pushnil(L->state);
                    break;
            }
        }
        if (lua_pcall(L->state, nargs, 0, -nargs - 2)) {
            logger::log(logger::ERROR, "%s", lua_tostring(L->state, -1));
            lua_pop(L->state, 2);
        } else {
            lua_pop(L->state, 1);
        }
    })

    LUAICOMMAND(cubescript, {
        tagval v;
        executeret(luaL_checkstring(L, 1), v);
        switch (v.type) {
            case VAL_INT:
                lua_pushinteger(L, v.getint()); break;
            case VAL_FLOAT:
                lua_pushnumber(L, v.getfloat()); break;
            case VAL_STR:
                lua_pushstring(L, v.getstr()); break;
            default:
                const char *str = v.getstr();
                if (str && str[0]) lua_pushstring(L, str);
                else lua_pushnil(L);
                break;
        }
        return 1;
    })
} /* end namespace lua */
