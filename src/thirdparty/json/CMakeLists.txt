#
# CMake for OctaForge
# -----------------------------------------
# this builds a JSON library.
#

# has just one sources, build, link.
add_library(json_${OF_BUILD_SUFFIX}
    JSON.cpp JSONValue.cpp
)
target_link_libraries(json_${OF_BUILD_SUFFIX})
install(TARGETS json_${OF_BUILD_SUFFIX}
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
)
