#
# CMake for OctaForge
# --------------------------------------
# main CMakeLists.txt - performs checks
#

# create project for OctaForge
cmake_minimum_required(VERSION 2.6)
project(OctaForge)

# suffix for libraries and binaries in format OS-ARCH (i.e. Linux-x86_64)
set(OF_BUILD_SUFFIX "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")

# always override install prefix
set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR})

# set default build flags for all OSes.
set(CMAKE_CXX_FLAGS "-g -O2 -Wall")

if (UNIX) # All kinds of POSIX compatible OSes (Linux, BSD, Mac for now)
    # This is common for all POSIX compatible OSes.
    add_definitions(-DLINUX)

    if (APPLE) # build on Mac OS X requires additional configuration
        # we build for i386
        set(CMAKE_OSX_ARCHITECTURES "i386")
        # some extra OS X sources
        set(EXTRA_SOURCES ../osx_dev/macutils.mm ../osx_dev/SDLMain.m)
    else (APPLE) # these are other POSIX compatible OSes, most likely Linux, BSD
        # we require util library on bsd and linux
        set(UTIL util)
    endif (APPLE)
else (UNIX) # this is windows. Well, not really, but mostly yes (TODO: check?)
    # preprocessor OS flags
    add_definitions(-DWINDOWS)
    add_definitions(-DWIN32)
    # link and include from extra dir.
    include_directories(${CMAKE_SOURCE_DIR}/src/include)
    link_directories(${CMAKE_SOURCE_DIR}/src/lib)
    # append cmake prefix path so it finds required libraries on Windows
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${CMAKE_SOURCE_DIR}/src)
    # build wuuid and sdlmain into client and server on Windows
    set(EXTRA_SOURCES ../lib/src/wuuid ../lib/src/SDL_win32_main.cpp)
endif (UNIX)

# find other packages
find_package(OpenGL REQUIRED)
find_package(SDL REQUIRED)
find_package(SDL_mixer REQUIRED)
find_package(SDL_image REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Lua51 REQUIRED)
if (NOT WIN32)
    find_package(PkgConfig)
    pkg_check_modules(UUID uuid)
endif (NOT WIN32)

# PROCEED TO NEXT DIR
add_subdirectory(src)
