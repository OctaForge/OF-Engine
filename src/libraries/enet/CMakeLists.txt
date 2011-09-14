#
# CMake for OctaForge
# -------------------------------------
# this builds enet udp network library.
#

# includes.
include_directories(include)

add_definitions(-DHAS_SOCKLEN_T=1)
set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} "-Wno-error")

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
