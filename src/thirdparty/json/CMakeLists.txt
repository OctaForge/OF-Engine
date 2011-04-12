#
# CMake for CubeCreate
# -----------------------------------------
# this builds a JSON library.
#

# has just one sources, build, link.
add_library(json_${CC_BUILD_SUFFIX}
    JSON.cpp JSONValue.cpp
)
target_link_libraries(json_${CC_BUILD_SUFFIX})
install(TARGETS json_${CC_BUILD_SUFFIX}
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
)
