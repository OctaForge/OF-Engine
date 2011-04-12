#
# CMake for CubeCreate
# --------------------------------------
# main CMakeLists.txt for checking stuff
#

# create project for CubeCreate
cmake_minimum_required(VERSION 2.6)
project(CubeCreate)

# suffix for libraries and binaries in format OS-ARCH (i.e. Linux-x86_64)
set(CC_BUILD_SUFFIX "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")

# always override install prefix
set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR})

if (UNIX) # LINUX, BSD or MAC OS X

    if (APPLE) # if we build on Mac OS X, we need different stuff

        # preprocessor OS flag - linux for now.
        add_definitions(-DLINUX)
        # default c++ flags.
        set(CMAKE_CXX_FLAGS "-g -O1 -Wall")
        # we build for i386
        set(CMAKE_OSX_ARCHITECTURES "i386")
        # some extra OS X sources
        set(EXTRA_SOURCES ../osx_dev/macutils.mm ../osx_dev/SDLMain.m)

    else (APPLE) # if it's not Mac OS X, we just use standard flags for bsd, linux or whatever

        # preprocessor OS flag.
        add_definitions(-DLINUX)
        # default c++ flags.
        set(CMAKE_CXX_FLAGS "-g -O1 -Wall")
        # we require util library on bsd and linux
        set(UTIL util)

    endif (APPLE)

else (UNIX) # this is windows. Well, not really, but mostly yes (TODO: check?)

    if (MINGW) # if we're using mingw, set standard stuff on windows

        # preprocessor OS flags
        add_definitions(-DWINDOWS)
        add_definitions(-DWIN32)
        # default c++ flags.
        set(CMAKE_CXX_FLAGS "-g -O2 -Wall")
        # additional dependencies for windows.
        set(CC_ADDITIONAL_DEPS ${CMAKE_SOURCE_DIR}/src/windows)
        # we have to include headers and link libraries from the directory - only zlib is there atm
        include_directories(${CC_ADDITIONAL_DEPS}/include)
        link_directories(${CC_ADDITIONAL_DEPS}/lib)
        # append additional deps to cmake prefix path
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${CC_ADDITIONAL_DEPS})

    else (MINGW) # in that case, vc++ is most likely used

        # preprocessor OS flags
        add_definitions(-DWINDOWS)
        # default C++ flags
        set(CMAKE_CXX_FLAGS "/DWIN32 /O2 /EHsc")
        # additional dependencies for windows.
        set(CC_ADDITIONAL_DEPS ${CMAKE_SOURCE_DIR}/src/windows)
        # we have to include headers and link libraries from the directory - only zlib is there atm
        include_directories(${CC_ADDITIONAL_DEPS}/include)
        link_directories(${CC_ADDITIONAL_DEPS}/lib)
        # append additional deps to cmake prefix path
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${CC_ADDITIONAL_DEPS})
        # windows SDK stuff
        file(TO_CMAKE_PATH "C:\\Program Files\\Microsoft SDKs\\Windows\\v6.0A" PLATFORM_SDK_A)
        if (${CMAKE_SYSTEM_PROCESSOR} STREQUAL "AMD64")
            file(TO_CMAKE_PATH "C:\\Program Files (x86)\\Microsoft Visual Studio 9.0\\VC" PLATFORM_SDK_B)
        else (${CMAKE_SYSTEM_PROCESSOR} STREQUAL "AMD64")
            file(TO_CMAKE_PATH "C:\\Program Files\\Microsoft Visual Studio 9.0\\VC" PLATFORM_SDK_B)
        endif (${CMAKE_SYSTEM_PROCESSOR} STREQUAL "AMD64")

    endif (MINGW)

endif (UNIX)

# FIND PACKAGES

# first, find Python. CMake should automatically decide. Fail if not found
find_package(PythonLibs REQUIRED)

# under Windows, add a few defs for boost and append new things into prefix path
if (MINGW OR WIN32)
    add_definitions(-DBOOST_PYTHON_STATIC_LIB)
    add_definitions(-DBOOST_AUTO_LINK_NOMANGLE)
    add_definitions(-DBOOST_PYTHON_SOURCE)
    add_definitions(-DBOOST_PYTHON_NO_LIB)
    add_definitions(-DBOOST_ALL_NO_LIB)

    if (MINGW)
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${CC_ADDITIONAL_DEPS}/SDL_mingw)
    else (MINGW)
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${CC_ADDITIONAL_DEPS}/SDL_vcpp)
    endif (MINGW)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${CC_ADDITIONAL_DEPS}/SDL_mixer)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${CC_ADDITIONAL_DEPS}/SDL_image)
endif (MINGW OR WIN32)

# find other packages
find_package(OpenGL REQUIRED)
find_package(SDL REQUIRED)
find_package(SDL_mixer REQUIRED)
find_package(SDL_image REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Lua51 REQUIRED)
if (NOT (MINGW OR WIN32))
	find_package(Boost COMPONENTS python REQUIRED)
endif (NOT (MINGW OR WIN32))

# PROCEED TO NEXT DIR
add_subdirectory(src)
