#
# CMake for OctaForge
# -------------------------------------
# this builds lua (in generic mode, no
# external deps nor optional features
# like dynamic library opening).
#

# includes.
include_directories(include)

set(LUA_CORE_SOURCES
    lapi.c
    lcode.c
    ldebug.c
    ldo.c
    ldump.c
    lfunc.c
    lgc.c
    llex.c
    lmem.c
    lobject.c
    lopcodes.c
    lparser.c
    lstate.c
    lstring.c
    ltable.c
    ltm.c
    lundump.c
    lvm.c
    lzio.c
)

set(LUA_LIB_SOURCES
    lauxlib.c
    lbaselib.c
    ldblib.c
    liolib.c
    lmathlib.c
    loslib.c
    ltablib.c
    lstrlib.c
    loadlib.c
    linit.c
)

add_library(lua_${OF_BUILD_SUFFIX} ${LUA_CORE_SOURCES} ${LUA_LIB_SOURCES})
