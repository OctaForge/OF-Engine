#
# CMake for OctaForge
# -------------------------
# this makes server binary.
#

# include vcpp, sdl headers
if (WIN32 AND NOT MINGW)
    include_directories(${PLATFORM_SDK_A}/Include)
    include_directories(${PLATFORM_SDK_B}/Include)
endif (WIN32 AND NOT MINGW)
include_directories(${SDL_INCLUDE_DIR} ${SDLMIXER_INCLUDE_DIR} ${SDLIMAGE_INCLUDE_DIR} ${LUA_INCLUDE_DIR})
if (NOT (WIN32 OR MINGW))
    include_directories(${UUID_INCLUDE_DIRS})
endif (NOT (WIN32 OR MINGW))

# for now, keep rtti / exceptions enabled, disable them later
#add_definitions(-fno-exceptions -fno-rtti)

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux") # there is no LINUX variable declared
   add_definitions (-fsigned-char)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

# include JSON.
include_directories(${CMAKE_SOURCE_DIR}/src/thirdparty/json)
# server def and executable build
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
    ${SDLSOUND_LIBRARY}
    ${ZLIB_LIBRARIES}
    ${UTIL}
    json_${OF_BUILD_SUFFIX}
)

if (NOT WIN32)
    set(SERVER_LIBRARIES ${SERVER_LIBRARIES} ${UUID_LIBRARIES})
endif (NOT WIN32)

# additional libs on windows
if (MINGW OR WIN32)
    set(SERVER_LIBRARIES ${SERVER_LIBRARIES} ws2_32 opengl32 winmm)
    if (NOT MINGW)
        set(SERVER_LIBRARIES ${SERVER_LIBRARIES} msvcrt)
    endif (NOT MINGW)
endif (MINGW OR WIN32)

if (${CMAKE_SYSTEM_NAME} MATCHES "BSD") # there is no BSD variable declared
    set(SERVER_LIBRARIES ${SERVER_LIBRARIES} execinfo)
endif (${CMAKE_SYSTEM_NAME} MATCHES "BSD")

# finally build and link executable
add_executable(OF_Server_${OF_BUILD_SUFFIX} ${SERVER_SOURCES})
target_link_libraries(OF_Server_${OF_BUILD_SUFFIX} ${SERVER_LIBRARIES})
install(TARGETS OF_Server_${OF_BUILD_SUFFIX}
        RUNTIME DESTINATION bin
)
