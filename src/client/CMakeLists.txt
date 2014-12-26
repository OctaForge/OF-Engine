add_definitions(-DBINARY_ARCH=${OF_TARGET_ARCH} -DBINARY_OS=${OF_PLATFORM_BIN})
add_definitions(-DBINARY_ARCH_STR=\"${OF_TARGET_ARCH}\")
add_definitions(-DBINARY_OS_STR=\"${OF_PLATFORM_BIN}\")

if(NOT OF_TARGET_WINDOWS AND NOT OF_TARGET_OSX)
    set(EXTRA_LIBS ${EXTRA_LIBS} SDL2 SDL2_image SDL2_mixer -pthread)
elseif(OF_TARGET_OSX)
    set(EXTRA_LIBS ${EXTRA_LIBS} ${SDL2_LIBRARY} ${SDL2_IMAGE_LIBRARY}
        ${SDL2_MIXER_LIBRARY})
elseif(OF_TARGET_WINDOWS)
    set(EXTRA_LIBS ${EXTRA_LIBS} SDL2 SDL_image SDL2_mixer opengl32
        ws2_32 winmm)
endif()

if(OF_TARGET_LINUX OR ${CMAKE_SYSTEM_NAME} MATCHES "GNU")
    set(EXTRA_LIBS ${EXTRA_LIBS} dl rt)
elseif(OF_TARGET_SOLARIS)
    set(EXTRA_LIBS ${EXTRA_LIBS} socket nsl)
endif()

if(OF_OVR)
    if(OF_TARGET_LINUX)
        if(OF_TARGET_X64)
            link_directories(../LibOVR/Lib/Linux/Release/x86_64)
        else()
            link_directories(../LibOVR/Lib/Linux/Release/i386)
        endif()
        set(EXTRA_LIBS ${EXTRA_LIBS} ovr udev Xinerama)
    else()
        message(WARNING "Oculus Rift only supported on Linux at this point")
    endif()
endif()

if(OF_BUILD_AMALG)
    set(CLIENT_SOURCES ../shared/client_amalg)
else()
    set(CLIENT_SOURCES
        ../shared/crypto
        ../shared/geom
        ../shared/glemu
        ../shared/stream
        ../shared/tools
        ../shared/zip
        ../engine/aa
        ../engine/bih
        ../engine/blend
        ../engine/client
        ../engine/command
        ../engine/console
        ../engine/dynlight
        ../engine/grass
        ../engine/light
        ../engine/main
        ../engine/material
        ../engine/movie
        ../engine/normal
        ../engine/octa
        ../engine/octaedit
        ../engine/octarender
        ../engine/ovr
        ../engine/physics
        ../engine/pvs
        ../engine/rendergl
        ../engine/renderlights
        ../engine/rendermodel
        ../engine/renderparticles
        ../engine/rendersky
        ../engine/rendertext
        ../engine/renderva
        ../engine/server
        ../engine/serverbrowser
        ../engine/shader
        ../engine/sound
        ../engine/stain
        ../engine/texture
        ../engine/water
        ../engine/world
        ../engine/worldio
        ../game/client
        ../game/entities
        ../game/game
        ../game/render
        ../game/server
        ../octaforge/of_logger
        ../octaforge/of_lua)
endif()

set(CLIENT_LIBS enet ${OPENGL_LIBRARIES} ${ZLIB_LIBRARIES} ${EXTRA_LIBS})

add_executable(${OF_CLIENT_BINARY} ${CLIENT_SOURCES})
target_link_libraries(${OF_CLIENT_BINARY} ${CLIENT_LIBS})
install(TARGETS ${OF_CLIENT_BINARY} RUNTIME DESTINATION ${OF_BINARY_PATH})