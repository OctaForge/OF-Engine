#
# CMake for CubeCreate
# -------------------------
# this makes client binary.
#

# include vcpp, sdl and python headers
if (WIN32 AND NOT MINGW)
    include_directories(${PLATFORM_SDK_A}/Include)
    include_directories(${PLATFORM_SDK_B}/Include)
endif (WIN32 AND NOT MINGW)
include_directories(${SDL_INCLUDE_DIR} ${SDLMIXER_INCLUDE_DIR} ${SDLIMAGE_INCLUDE_DIR} ${PYTHON_INCLUDE_PATH} ${LUA_INCLUDE_DIR})
if (NOT (WIN32 OR MINGW))
	include_directories(${Boost_INCLUDE_DIRS})
endif (NOT (WIN32 OR MINGW))

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux") # there is no LINUX variable declared
   add_definitions (-fsigned-char)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

# include JSON.
include_directories(${CMAKE_SOURCE_DIR}/src/thirdparty/json)
# client def and executable build
add_definitions(-DCLIENT)
set(CLIENT_SOURCES
    ../engine/3dgui
    ../engine/blob
    ../engine/blend
    ../engine/menus
    ../engine/serverbrowser
    ../intensity/editing_system
    ../intensity/messages
    ../intensity/logging
    ../intensity/message_system
    ../intensity/system_manager
    ../intensity/python_wrap
    ../intensity/utility
    ../intensity/client_system
    ../intensity/client_engine_additions
    ../intensity/character_render
    ../intensity/intensity_physics
    ../intensity/intensity_physics_sauer
    ../fpsgame/fps
    ../fpsgame/server
    ../fpsgame/client
    ../fpsgame/entities
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
    ../intensity/steering
    ../intensity/network_system
    ../cubecreate/scripting_system_lua
    ../cubecreate/variable_system
    ../intensity/fpsclient_interface
    ../intensity/fpsserver_interface
    ../intensity/master
    ../intensity/intensity_gui
    ../shared/stream
    ../shared/zip
    ../engine/movie
    ../intensity/shared_module_members_boost
    ../fpsgame/scoreboard
    ${EXTRA_SOURCES}
)

# link libs to executable
set(CLIENT_LIBRARIES
    enet_${CC_BUILD_SUFFIX}
    ${LUA_LIBRARIES}
    ${PYTHON_LIBRARIES}
    ${SDL_LIBRARY}
    ${SDLMIXER_LIBRARY}
    ${SDLIMAGE_LIBRARY}
    ${SDLSOUND_LIBRARY}
    ${OPENGL_LIBRARIES}
    ${ZLIB_LIBRARIES}
    ${UTIL}
    json_${CC_BUILD_SUFFIX}
    ${Boost_PYTHON_LIBRARY}
)

if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
   set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} rt)
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

# additional libs on windows
if (MINGW OR WIN32)
    set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} opengl32 glu32 ws2_32 winmm)
    if (NOT MINGW)
        set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} msvcrt user32 imagehlp)
    endif (NOT MINGW)
endif (MINGW OR WIN32)

if(${CMAKE_SYSTEM_NAME} MATCHES "BSD") # there is no BSD variable declared
    set(CLIENT_LIBRARIES ${CLIENT_LIBRARIES} execinfo)
endif(${CMAKE_SYSTEM_NAME} MATCHES "BSD")

# finally build and link executable
add_executable(CC_Client_${CC_BUILD_SUFFIX} ${CLIENT_SOURCES})
target_link_libraries(CC_Client_${CC_BUILD_SUFFIX} ${CLIENT_LIBRARIES})
install(TARGETS CC_Client_${CC_BUILD_SUFFIX}
        RUNTIME DESTINATION bin
)
