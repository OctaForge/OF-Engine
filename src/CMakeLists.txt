#
# CMake for OctaForge
# ----------------------------------
# just includes, links and proceeds.
#

# internal things
include_directories(shared engine fpsgame intensity cubecreate octaforge enet/include)
link_directories(${CMAKE_SOURCE_DIR}/src/enet)

# further proceed
add_subdirectory(thirdparty)
add_subdirectory(enet)
add_subdirectory(server)
add_subdirectory(client)

