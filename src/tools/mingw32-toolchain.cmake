# OctaForge cmake toolchain file for doing Windows cross-builds
# on non-Windows systems. Modify the variables in this file for
# your OS if needed. These were tested on FreeBSD.
# Written using instructions here http://www.itk.org/Wiki/CmakeMingw

# OS name, won't change
set(CMAKE_SYSTEM_NAME Windows)
# Windows version, set as XP (NT 5.1) for now
set(CMAKE_SYSTEM_VERSION 5.1)
# architecture, won't change for now
set(CMAKE_SYSTEM_PROCESSOR x86)

# which compilers to use for C, C++, windres, change if needed
set(CMAKE_C_COMPILER mingw32-gcc)
set(CMAKE_CXX_COMPILER mingw32-g++)
SET(CMAKE_RC_COMPILER mingw32-windres)

# mingw environment location + search path for libs, change if needed
set(CMAKE_FIND_ROOT_PATH /usr/local/mingw32 ${CMAKE_SOURCE_DIR}/src)

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search 
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

