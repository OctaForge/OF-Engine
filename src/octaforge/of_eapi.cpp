/* of_eapi.cpp, version 1
 * Defines all the symbols the scripting system will call via the LuaJIT FFI.
 * There is no explicit binding API for these; as long as they are defined
 * in the executable, the scripting system can find them. They have to be
 * extern "C" so that the names are unmangled.
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2012 q66
 */

#include "engine.h"

/* prototypes */

extern "C" {
#ifdef CLIENT
    /* Textures */

    Texture *texture_load(const char *path) {
        return textureload(path, 3, true, false);
    }

    Texture *texture_get_notexture() {
        return notexture;
    }

    void texture_load_alpha_mask(Texture *tex) {
        loadalphamask(tex);
    }
#endif
}
