add_definitions(-DCLIENT)
add_definitions(-DBINARY_ARCH=${OF_TARGET_ARCH} -DBINARY_OS=${OF_PLATFORM_BIN})

if(NOT DEFINED WIN32 AND NOT DEFINED APPLE)
    set(EXTRA_LIBS ${EXTRA_LIBS} SDL2 SDL2_image SDL2_mixer -pthread)
elseif(APPLE)
    set(EXTRA_LIBS ${EXTRA_LIBS} ${SDL2_LIBRARY} ${SDL2_IMAGE_LIBRARY}
        ${SDL2_MIXER_LIBRARY})
elseif(WIN32)
    set(EXTRA_LIBS ${EXTRA_LIBS} SDL2 SDL_image SDL2_mixer opengl32
        ws2_32 winmm)
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(EXTRA_LIBS ${EXTRA_LIBS} dl rt)
elseif(${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    set(EXTRA_LIBS ${EXTRA_LIBS} socket nsl)
endif()

set(CLIENT_SOURCES
    ../octaforge/of_tools
    ../engine/blend
    ../engine/serverbrowser
    ../intensity/editing_system
    ../intensity/messages
    ../intensity/message_system
    ../intensity/client_system
    ../fpsgame/fps
    ../fpsgame/server
    ../fpsgame/client
    ../fpsgame/render
    ../fpsgame/weapon
    ../shared/tools
    ../shared/geom
    ../shared/glemu
    ../engine/command
    ../engine/aa
    ../engine/rendertext
    ../engine/material
    ../engine/octaedit
    ../engine/grass
    ../engine/physics
    ../engine/rendergl
    ../engine/renderlights
    ../engine/worldio
    ../engine/texture
    ../engine/console
    ../engine/world
    ../engine/renderva
    ../engine/normal
    ../engine/rendermodel
    ../engine/main
    ../engine/bih
    ../engine/octa
    ../engine/light
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
    ../intensity/targeting
    ../intensity/network_system
    ../shared/stream
    ../shared/zip
    ../engine/movie
    ../octaforge/of_lua
    ../octaforge/of_localserver
    ../octaforge/of_world
    ../octaforge/of_logger
    ../octaforge/of_entities)

set(CLIENT_LIBS enet ${OPENGL_LIBRARIES} ${ZLIB_LIBRARIES} ${EXTRA_LIBS})

add_executable(${OF_CLIENT_BINARY} ${CLIENT_SOURCES})
target_link_libraries(${OF_CLIENT_BINARY} ${CLIENT_LIBS})
install(TARGETS ${OF_CLIENT_BINARY} RUNTIME DESTINATION ${OF_BINARY_PATH})