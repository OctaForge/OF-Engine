#
# CMake for CubeCreate
# ----------------------------------
# just includes, links and proceeds.
#

# internal things
include_directories(shared engine fpsgame intensity cubecreate enet/include include)
link_directories(${CMAKE_SOURCE_DIR}/src/enet)
if (MINGW OR WIN32)
	include_directories(windows/boost)
	link_directories(${CMAKE_SOURCE_DIR}/src/windows/boost_python)
endif (MINGW OR WIN32)

# further proceed.
add_subdirectory(thirdparty)
add_subdirectory(enet)
add_subdirectory(server)
add_subdirectory(client)

