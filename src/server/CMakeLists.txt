add_definitions(-DSERVER)
add_definitions(-DBINARY_ARCH=${OF_TARGET_ARCH} -DBINARY_OS=${OF_PLATFORM_BIN})

if(WIN32)
    set(EXTRA_LIBS ${EXTRA_LIBS} opengl32 ws2_32 winmm)
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(EXTRA_LIBS ${EXTRA_LIBS} dl)
elseif(${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    set(EXTRA_LIBS ${EXTRA_LIBS} socket nsl)
endif()

set(SERVER_SOURCES
    ../octaforge/of_tools
    ../intensity/editing_system
    ../shared/tools
    ../engine/command
    ../engine/server
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
    ../engine/bih
    ../shared/geom
    ../shared/glemu
    ../engine/client
    ../engine/octaedit
    ../intensity/network_system
    ../engine/octarender
    ../shared/stream
    ../shared/zip
    ../octaforge/of_lua
    ../octaforge/of_world
    ../octaforge/of_logger
    ../octaforge/of_entities)

set(SERVER_LIBS enet ${OPENGL_LIBRARIES} ${ZLIB_LIBRARIES} ${EXTRA_LIBS})

add_executable(${OF_SERVER_BINARY} ${SERVER_SOURCES})
target_link_libraries(${OF_SERVER_BINARY} ${SERVER_LIBS})
install(TARGETS ${OF_SERVER_BINARY} RUNTIME DESTINATION ${OF_BINARY_PATH})