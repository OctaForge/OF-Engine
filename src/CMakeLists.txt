#
# CMake for OctaForge
# ----------------------------------
# just includes, links and proceeds.
#

# internal things
include_directories(
    ofstdlib shared engine fpsgame
    intensity cubecreate octaforge
    libraries/lua/include
    libraries/enet/include
)
link_directories(${CMAKE_SOURCE_DIR}/src/libraries/lua
                 ${CMAKE_SOURCE_DIR}/src/libraries/enet
)

# further proceed
add_subdirectory(libraries)
add_subdirectory(server)
add_subdirectory(client)
