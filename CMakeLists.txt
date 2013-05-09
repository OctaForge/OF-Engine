# OCtaForge CMakeLists.txt
# written for all platforms OF covers
#
# author: Daniel 'q66' Kolesa <quaker66@gmail.com>
# license: MIT

cmake_minimum_required(VERSION 2.6)
project(OctaForge)

option(OF_LUAJIT_LOCAL "LuaJIT is stored locally in platform_OS" OFF)
option(OF_SDL2_LOCAL "SDL2 is stored locally in platform_OS" OFF)

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(OF_TARGET_ARCH "x64")
else()
    set(OF_TARGET_ARCH "x86")
endif()

if(WIN32)
    if(MSVC)
        set(OF_CXX_FLAGS "/EHsc /MT")
    else()
        set(OF_CXX_FLAGS "-fomit-frame-pointer -Wall -fsigned-char")
    endif()
    include_directories(src/platform_windows/include)
    set(OF_PLATFORM_SRC "windows")
    set(OF_PLATFORM_BIN "win")
elseif(APPLE)
    set(OF_CXX_FLAGS "-fomit-frame-pointer -Wall -fsigned-char")
    include_directories(src/platform_osx/include)
    set(OF_PLATFORM_SRC "osx")
    set(OF_PLATFORM_BIN "darwin")
    set(CMAKE_FRAMEWORK_PATH src/platform_osx/Frameworks)
    set(CMAKE_OSX_DEPLOYMENT_TARGET 10.6)
else()
    set(OF_CXX_FLAGS "-fomit-frame-pointer -Wall -fsigned-char")
    if(CMAKE_SYSTEM_NAME MATCHES "Linux")
        set(OF_PLATFORM_SRC "linux")
        set(OF_PLATFORM_BIN "linux")
    elseif(CMAKE_SYSTEM_NAME MATCHES "FreeBSD")
        set(OF_PLATFORM_SRC "freebsd")
        set(OF_PLATFORM_BIN "freebsd")
    elseif(CMAKE_SYSTEM_NAME MATCHES "SunOS")
        set(OF_PLATFORM_SRC "solaris")
        set(OF_PLATFORM_BIN "solaris")
    else()
        message(FATAL_ERROR "Unsupported operating system.")
    endif()
endif()

include_directories(src/platform_${OF_PLATFORM_SRC}/include)
if(OF_TARGET_ARCH STREQUAL "x64")
    link_directories(${CMAKE_SOURCE_DIR}/src/platform_${OF_PLATFORM_SRC}/lib64)
else()
    link_directories(${CMAKE_SOURCE_DIR}/src/platform_${OF_PLATFORM_SRC}/lib32)
endif()

if(WIN32)
    add_definitions(-DWIN32 -DWINDOWS)
    if(OF_TARGET_ARCH STREQUAL "x64")
        add_definitions(-DWIN64)
    endif()
endif()

set(OF_C_FLAGS "${OF_CXX_FLAGS}")
if(NOT DEFINED MSVC)
    set(OF_CXX_FLAGS "${OF_CXX_FLAGS} -fno-exceptions -fno-rtti")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OF_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OF_CXX_FLAGS}")

add_subdirectory(src)