/* replutil.c - a collection of REPL related utilities for Octascript
 *
 * Copyright (C) 2014 Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * NCSA licensed
 */

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include "lua.h"
#include "luaconf.h"
#include "lauxlib.h"

#define luaL_newlib(L, l) (lua_newtable(L), luaL_register(L, NULL, l))

/* SIGNAL HANDLING */

#define OCT_SIG "oct_sig"

static lua_State *GL = NULL;

static void oct_sighandler(int sig) {
    (void)sig;
    lua_getfield(GL, LUA_REGISTRYINDEX, OCT_SIG);
    lua_call(GL, 0, 0);
}

static int oct_signal(lua_State *L) {
    if (lua_isnone(L, 1) || lua_isnil(L, 1)) {
        lua_pushnil(L);
        signal(SIGINT, SIG_DFL);
    } else {
        luaL_checktype(L, 1, LUA_TFUNCTION);
        lua_pushvalue(L, 1);
        signal(SIGINT, oct_sighandler);
        GL = L;
    }
    lua_setfield(L, LUA_REGISTRYINDEX, OCT_SIG);
    return 0;
}

/* IO EXTENSIONS */

#if defined(OCT_POSIX)
#include <unistd.h>
static int oct_isatty(lua_State *L) {
    if (lua_gettop(L) == 0) {
        lua_pushboolean(L, isatty(0));
    } else {
        lua_pushboolean(L, isatty(fileno(
            *(FILE**)luaL_checkudata(L, 1, "FILE*"))));
    }
    return 1;
}
#elif defined(OCT_WIN)
static int oct_isatty(lua_State *L) {
    if (lua_gettop(L) == 0) {
        lua_pushboolean(L, _isatty(_fileno(stdin)));
    } else {
        lua_pushboolean(L, _isatty(_fileno(
            *(FILE**)luaL_checkudata(L, 1, "FILE*"))));
    }
    return 1;
}
#else
static int oct_isatty(lua_State *L) {
    lua_pushboolean(L, 1);
    return 1;
}
#endif

/* READLINE */

#ifdef OCT_READLINE
#include <readline/readline.h>
#include <readline/history.h>
static int oct_readline(lua_State *L) {
    char *rd = readline(luaL_optstring(L, 1, NULL));
    if (!rd) {
        return 0;
    } else {
        lua_pushstring(L, rd);
        free(rd);
        return 1;
    }
}
static int oct_add_history(lua_State *L) {
    add_history(luaL_checkstring(L, 1));
    return 0;
}
#else
#define OCT_MAX_INPUT 512
static int oct_readline(lua_State *L) {
    char buf[OCT_MAX_INPUT];
    const char *str = luaL_optstring(L, 1, NULL);
    fputs(str, stdout);
    fflush(stdout);
    if (!fgets(buf, OCT_MAX_INPUT, stdin)) {
        return 0;
    } else {
        size_t len = strlen(buf);
        lua_pushlstring(L, buf, (buf[len - 1] == '\n') ? (len - 1) : len);
        return 1;
    }
}
static int oct_add_history(lua_State *L) {
    return 0;
}
#endif

static luaL_Reg lvxutil_lib[] = {
    { "signal"     , oct_signal      },
    { "isatty"     , oct_isatty      },
    { "readline"   , oct_readline    },
    { "add_history", oct_add_history },
    { NULL, NULL }
};

int luaopen_replutil(lua_State *L) {
    luaL_newlib(L, lvxutil_lib);

    lua_pushstring(L, OCT_SIG);
    lua_createtable(L, 0, 0);

    lua_settable(L, LUA_REGISTRYINDEX);

    return 1;
}