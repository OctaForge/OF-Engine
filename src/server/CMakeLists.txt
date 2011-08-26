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
if (NOT WIN32 AND NOT APPLE)
    include_directories(${UUID_INCLUDE_DIRS})
endif (NOT WIN32 AND NOT APPLE)

add_definitions(-fno-exceptions -fno-rtti)

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
    ../intensity/message_system
    ../intensity/server_system
    ../intensity/messages
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
    ../engine/octaedit
    ../intensity/targeting
    ../intensity/network_system
    ../octaforge/of_lua
    ../octaforge/of_vars
    ../engine/octarender
    ../fpsgame/weapon
    ../shared/stream
    ../engine/pvs
    ../engine/blend
    ../shared/zip
    ../octaforge/of_world
    ../octaforge/of_logger
    ../octaforge/of_entities
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
    if (NOT APPLE)
        set(SERVER_LIBRARIES ${SERVER_LIBRARIES} ${UUID_LIBRARIES})
    endif (NOT APPLE)
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
