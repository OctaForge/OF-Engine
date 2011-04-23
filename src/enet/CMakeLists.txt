#
# CMake for OctaForge
# -------------------------------------
# this builds enet udp network library.
#

# includes.
if (WIN32 AND NOT MINGW)
    include_directories(${PLATFORM_SDK_A}/Include)
    include_directories(${PLATFORM_SDK_B}/Include)
endif (WIN32 AND NOT MINGW)
include_directories(include)

# a cpp flag for enet.
add_definitions (-DHAS_SOCKLEN_T=1)
# build with -Wno-error.
set(CMAKE_CXX_FLAGS $CMAKE_CXX_FLAGS "-Wno-error")

# finally build the library.
add_library(enet_${OF_BUILD_SUFFIX}
            callbacks.c
            host.c
            list.c
            packet.c
            peer.c
            protocol.c
            unix.c
            win32.c
)

install(TARGETS enet_${OF_BUILD_SUFFIX}
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
)
