#
# CMake for CubeCreate
# --------------------------------------
# main CMakeLists.txt for checking stuff
#

# create project for CubeCreate
cmake_minimum_required(VERSION 2.6)
project(VLCVideo)

set(CC_LIB_SUFFIX "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")

# flags
if (${CMAKE_BUILD_TYPE} MATCHES "Debug")
    if (MSVC)
        add_definitions(/DWIN32 /D_DEBUG)
    else (MSVC)
        add_definitions(-D_DEBUG -g -Wall -Werror)
    endif (MSVC)
else (${CMAKE_BUILD_TYPE} MATCHES "Debug")
    if (MSVC)
        add_definitions(/DWIN32 /O2)
    else (MSVC)
        add_definitions(-g -Wall -Werror -O1)
    endif (MSVC)
endif (${CMAKE_BUILD_TYPE} MATCHES "Debug")

# find packages
find_package(PythonLibs REQUIRED)

# include dir with boost_python
link_directories(${CMAKE_SOURCE_DIR}/../../../../../lib)

# include python headers etc.
include_directories(${CMAKE_SOURCE_DIR}/../../../../intensity ${PYTHON_INCLUDE_PATH})

# build a shared lib
add_library(module SHARED
    module.cpp
)

set(MODULE_LIBRARIES
    vlc
    ${PYTHON_LIBRARIES}
)

if (MSVC)
    set(MODULE_LIBRARIES ${MODULE_LIBRARIES} boost_python_${CC_LIB_SUFFIX})
else (MSVC) # shared linking on nix and mingw
    set(MODULE_LIBRARIES ${MODULE_LIBRARIES} boost_python)
endif (MSVC)

# link the module.
target_link_libraries(module ${MODULE_LIBRARIES})
