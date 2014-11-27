add_definitions(-DSERVER)
add_definitions(-DBINARY_ARCH=${OF_TARGET_ARCH} -DBINARY_OS=${OF_PLATFORM_BIN})
add_definitions(-DBINARY_ARCH_STR=\"${OF_TARGET_ARCH}\")
add_definitions(-DBINARY_OS_STR=\"${OF_PLATFORM_BIN}\")

if(OF_TARGET_WINDOWS)
    set(EXTRA_LIBS ${EXTRA_LIBS} opengl32 ws2_32 winmm)
elseif(OF_TARGET_LINUX)
    set(EXTRA_LIBS ${EXTRA_LIBS} dl)
elseif(OF_TARGET_SOLARIS)
    set(EXTRA_LIBS ${EXTRA_LIBS} socket nsl)
endif()

if(OF_BUILD_AMALG)
    set(SERVER_SOURCES ../shared/server_amalg)
else()
    set(SERVER_SOURCES
        ../octaforge/of_tools
        ../shared/tools
        ../engine/command
        ../engine/server
        ../game/game
        ../game/server
        ../game/client
        ../intensity/message_system
        ../intensity/server_system
        ../intensity/messages
        ../engine/world
        ../engine/worldio
        ../intensity/engine_additions
        ../engine/octa
        ../engine/physics
        ../engine/rendermodel
        ../engine/bih
        ../shared/geom
        ../engine/client
        ../engine/octaedit
        ../engine/octarender
        ../shared/stream
        ../shared/zip
        ../octaforge/of_lua
        ../octaforge/of_world
        ../octaforge/of_logger
        ../octaforge/of_entities)
endif()

set(SERVER_LIBS enet ${OPENGL_LIBRARIES} ${ZLIB_LIBRARIES} ${EXTRA_LIBS})

add_executable(${OF_SERVER_BINARY} ${SERVER_SOURCES})
target_link_libraries(${OF_SERVER_BINARY} ${SERVER_LIBS})
install(TARGETS ${OF_SERVER_BINARY} RUNTIME DESTINATION ${OF_BINARY_PATH})