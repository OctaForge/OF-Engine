#
# CMake for OctaForge
# -------------------------
# this makes server binary.
#

# include headers of SDL, Lua
include_directories(
    ${SDL_INCLUDE_DIR}
    ${SDLMIXER_INCLUDE_DIR}
    ${SDLIMAGE_INCLUDE_DIR}
    ${LUA_INCLUDE_DIR}
)
# include uuid on non-windows
if (NOT WIN32)
    include_directories(${UUID_INCLUDE_DIRS})
endif (NOT WIN32)

# for now, keep rtti / exceptions enabled, disable them later
#add_definitions(-fno-exceptions -fno-rtti)

# there is no LINUX variable declared
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
   add_definitions (-fsigned-char)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

# set server sources, configure preprocessor
add_definitions(-DSERVER)
set(SERVER_SOURCES
    ../octaforge/of_tools
    ../intensity/editing_system
    ../shared/tools
    ../engine/server
    ../engine/serverbrowser
    ../fpsgame/fps
    ../fpsgame/server
    ../fpsgame/client
    ../fpsgame/entities
    ../intensity/system_manager
    ../intensity/message_system
    ../intensity/server_system
    ../intensity/logging
    ../intensity/messages
    ../intensity/utility
    ../engine/world
    ../engine/worldio
    ../intensity/engine_additions
    ../engine/octa
    ../engine/physics
    ../engine/rendermodel
    ../engine/normal
    ../engine/bih
    ../shared/geom
    ../engine/client
    ../intensity/world_system
    ../engine/octaedit
    ../intensity/targeting
    ../intensity/network_system
    ../cubecreate/scripting_system_lua
    ../cubecreate/variable_system
    ../intensity/fpsserver_interface
    ../intensity/fpsclient_interface
    ../intensity/intensity_physics
    ../intensity/intensity_physics_sauer
    ../engine/octarender
    ../fpsgame/weapon
    ../shared/stream
    ../engine/pvs
    ../engine/blend
    ../shared/zip
    ../intensity/NPC
    ../octaforge/of_world
    ${EXTRA_SOURCES}
)

# link libs to executable
set(SERVER_LIBRARIES
    enet_${OF_BUILD_SUFFIX}
    ${LUA_LIBRARIES}
    ${SDL_LIBRARY}
    ${SDLMIXER_LIBRARY}
    ${SDLIMAGE_LIBRARY}
    ${ZLIB_LIBRARIES}
    ${UTIL}
)

# additional linking/compiling
if (WIN32)
    # this is for sdlmain
    add_definitions(-DNO_STDIO_REDIRECT)
    set(SERVER_LIBRARIES ${SERVER_LIBRARIES} ws2_32 opengl32 winmm rpcrt4)
else (WIN32)
    set(SERVER_LIBRARIES ${SERVER_LIBRARIES} ${UUID_LIBRARIES})
    # there is no BSD variable declared
    if (${CMAKE_SYSTEM_NAME} MATCHES "BSD")
        set(SERVER_LIBRARIES ${SERVER_LIBRARIES} execinfo)
    endif (${CMAKE_SYSTEM_NAME} MATCHES "BSD")
endif (WIN32)

# finally build and link executable
add_executable(OF_Server_${OF_BUILD_SUFFIX} ${SERVER_SOURCES})

if (WIN32)
    set_target_properties(OF_Server_${OF_BUILD_SUFFIX} PROPERTIES LINK_FLAGS "-static-libgcc -static-libstdc++")
endif (WIN32)

target_link_libraries(OF_Server_${OF_BUILD_SUFFIX} ${SERVER_LIBRARIES})
if (WIN32)
    install(TARGETS OF_Server_${OF_BUILD_SUFFIX}
            RUNTIME DESTINATION bin_win
    )
else (WIN32)
    install(TARGETS OF_Server_${OF_BUILD_SUFFIX}
            RUNTIME DESTINATION bin_unix
    )
endif (WIN32)
