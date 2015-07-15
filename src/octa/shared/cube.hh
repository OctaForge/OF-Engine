#ifndef __CUBE_H__
#define __CUBE_H__

#define _FILE_OFFSET_BITS 64

#ifdef __GNUC__
#define gamma __gamma
#endif

#ifdef WIN32
#define _USE_MATH_DEFINES
#endif
#include <math.h>

#ifdef __GNUC__
#undef gamma
#endif

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdarg.h>
#include <limits.h>
#include <float.h>
#include <assert.h>
#include <time.h>

#include "ostd/types.hh"
#include "ostd/new.hh"
#include "ostd/algorithm.hh"

extern "C" {
#ifdef __APPLE__
  #include "LuaJIT/lua.h"
  #include "LuaJIT/lualib.h"
  #include "LuaJIT/lauxlib.h"
#else
  #include "lua.h"
  #include "lualib.h"
  #include "lauxlib.h"
#endif
}

#ifdef WIN32
  #define WIN32_LEAN_AND_MEAN
  #ifdef _WIN32_WINNT
  #undef _WIN32_WINNT
  #endif
  #define _WIN32_WINNT 0x0500
  #include "windows.h"
  #ifndef _WINDOWS
    #define _WINDOWS
  #endif
  #ifndef __GNUC__
    #include <eh.h>
    #include <dbghelp.h>
    #include <intrin.h>
  #endif
  #define ZLIB_DLL
#endif

#ifndef STANDALONE
  #ifdef __APPLE__
    #include "SDL2/SDL.h"
    #include "SDL2/SDL_opengl.h"
    #ifdef OSX_USE_LAUNCHER
      #define main SDL_main
    #endif
  #else
    #include <SDL.h>
    #include <SDL_opengl.h>
  #endif
#endif

#include <enet/enet.h>

#include <zlib.h>

#include "tools.hh"
#include "geom.hh"
#include "ents.hh"
#include "command.hh"

#ifndef STANDALONE
#include "glexts.hh"
#include "glemu.hh"
#endif

#include "iengine.hh"
#include "igame.hh"

#include "of_logger.hh"
#include "of_lua.hh"

#endif

