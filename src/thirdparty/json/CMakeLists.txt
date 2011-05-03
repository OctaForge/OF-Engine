#
# CMake for OctaForge
# -----------------------------------------
# this builds a JSON library.
#

# has just one sources, build, link.
add_library(json_${OF_BUILD_SUFFIX}
    JSON.cpp JSONValue.cpp
)