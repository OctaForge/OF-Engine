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

/* workaround for -std=c++0x */

#ifdef WIN32
#ifdef __GNUC__
#ifdef __STRICT_ANSI__
#undef __STRICT_ANSI__
#endif
#endif
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

#include "OFTL/new.h"
#include "OFTL/utils.h"
#include "OFTL/traits.h"
#include "OFTL/algorithm.h"
#include "OFTL/functional.h"
#include "OFTL/string.h"
#include "OFTL/hashmap.h"
#include "OFTL/map.h"
#include "OFTL/vector.h"
#include "OFTL/shared_ptr.h"
#include "OFTL/random.h"
#include "OFTL/filesystem.h"
#include "OFTL/lua.h"

using algorithm::min;
using algorithm::max;
using algorithm::swap;
using algorithm::clamp;

#ifdef WIN32
  #define WIN32_LEAN_AND_MEAN
  #include "windows.h"
  #ifndef _WINDOWS
    #define _WINDOWS
  #endif
  #ifndef __GNUC__
    #include <eh.h>
    #include <dbghelp.h>
  #else
    #include <sys/types.h>
  #endif
  #define ZLIB_DLL
#endif

#ifndef STANDALONE
#include <SDL.h>
#include <SDL_image.h>

#define GL_GLEXT_LEGACY
#define __glext_h__
#define NO_SDL_GLEXT
#include <SDL_opengl.h>
#undef __glext_h__
#include "GL/glext.h"
#endif

#include <enet/enet.h>

#include <zlib.h>

#ifdef __sun__
#undef sun
#ifdef queue
  #undef queue
#endif
#define queue __squeue
#endif

#ifdef swap
#undef swap
#endif
#ifdef max
#undef max
#endif
#ifdef min
#undef min
#endif

#include "tools.h"
#include "geom.h"
#include "ents.h"

#include "iengine.h"
#include "igame.h"

#endif

