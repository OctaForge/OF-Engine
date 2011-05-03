#
# CMake for OctaForge
# -------------------------------------
# this builds enet udp network library.
#

# includes.
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