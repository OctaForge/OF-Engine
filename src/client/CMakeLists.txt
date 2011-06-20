#
# CMake for OctaForge
# -------------------------
# this makes client binary.
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

# there is no LINUX variable declared
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
   add_definitions (-fsigned-char)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

# keep rtti enabled for dynamic_casts
add_definitions(-fno-exceptions)

# set client sources, configure preprocessor
add_definitions(-DCLIENT)
set(CLIENT_SOURCES
    ../octaforge/of_tools
    ../engine/ui
    ../engine/blob
    ../engine/blend
    ../engine/serverbrowser
    ../intensity/editing_system
    ../intensity/messages
    ../intensity/message_system
    ../intensity/client_system
    ../intensity/client_engine_additions
    ../fpsgame/fps
    ../fpsgame/server
    ../fpsgame/client
    ../fpsgame/render
    ../fpsgame/weapon
    ../shared/tools
    ../shared/geom
    ../engine/rendertext
    ../engine/material
    ../engine/octaedit
    ../engine/grass
    ../engine/physics
    ../engine/rendergl
    ../engine/worldio
    ../engine/texture
    ../engine/console
    ../engine/world
    ../engine/glare
    ../engine/renderva
    ../engine/normal
    ../engine/rendermodel
    ../engine/shadowmap
    ../engine/main
    ../engine/bih
    ../engine/octa
    ../engine/lightmap
    ../engine/water
    ../engine/shader
    ../engine/rendersky
    ../engine/renderparticles
    ../engine/octarender
    ../engine/server
    ../engine/client
    ../engine/dynlight
    ../engine/decal
    ../engine/sound
    ../engine/pvs
    ../intensity/engine_additions
    ../intensity/world_system
    ../intensity/targeting
    ../intensity/network_system
    ../cubecreate/scripting_system_lua
    ../octaforge/of_vars
    ../shared/stream
    ../shared/zip
    ../engine/movie
    ../fpsgame/scoreboard
    ../octaforge/of_localserver
    ../octaforge/of_world
    ../octaforge/of_logger
    ../octaforge/of_entities
    ${EXTRA_SOURCES}
)

# link libs to executable
set(CLIENT_LIBRARIES
    enet_${OF_BUILD_SUFFIX}
    ${LUA_LIBRARIES}
    ${SDL_LIBRARY}
    ${SDLMIXER_LIBRARY}
    ${SDLIMAGE_LIBRARY}
    ${OPENGL_LIBRARIES}
    ${ZLIB_LIBRARIES}
    ${UTIL}
)

# additional linking/compiling
if (WIN32)
    # this is for sdlmain
    add_definitions(-DNO_STDIO_REDIRECT)
    set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} opengl32 glu32 ws2_32 winmm rpcrt4)
else (WIN32)
    set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} ${UUID_LIBRARIES})
    # under Linux, link client to rt, too
    if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} rt)
    endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    # there is no BSD variable declared
    if (${CMAKE_SYSTEM_NAME} MATCHES "BSD")
        set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} execinfo)
    endif (${CMAKE_SYSTEM_NAME} MATCHES "BSD")
endif (WIN32)

# finally build and link executable
add_executable(OF_Client_${OF_BUILD_SUFFIX} ${CLIENT_SOURCES})

if (WIN32)
    set_target_properties(OF_Client_${OF_BUILD_SUFFIX} PROPERTIES LINK_FLAGS "-static-libgcc -static-libstdc++")
endif (WIN32)

target_link_libraries(OF_Client_${OF_BUILD_SUFFIX} ${CLIENT_LIBRARIES})
if (WIN32)
    install(TARGETS OF_Client_${OF_BUILD_SUFFIX}
            RUNTIME DESTINATION bin_win
    )
else (WIN32)
    install(TARGETS OF_Client_${OF_BUILD_SUFFIX}
            RUNTIME DESTINATION bin_unix
    )
endif (WIN32)
