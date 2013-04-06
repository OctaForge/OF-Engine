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
    /* Input handling */

#ifdef CLIENT

    int input_get_modifier_state() {
        return (int) SDL_GetModState();
    }

    /* GUI */

    void gui_set_mainmenu(int v) {
        mainmenu = v;
    }

    void gui_text_bounds(const char *str, int &w, int &h, int maxw) {
        text_bounds(str, w, h, maxw);
    }

    void gui_text_bounds_f(const char *str, float &w, float &h, int maxw) {
        text_boundsf(str, w, h, maxw);
    }

    void gui_text_pos(const char *str, int cur, int &cx, int &cy, int maxw) {
        text_pos(str, cur, cx, cy, maxw);
    }

    void gui_text_pos_f(const char *str, int cur, float &cx, float &cy,
        int maxw) {
        text_posf(str, cur, cx, cy, maxw);
    }

    int gui_text_visible(const char *str, float hitx, float hity, int maxw) {
        return text_visible(str, hitx, hity, maxw);
    }

    void gui_draw_text(const char *str, int left, int top,
        int r, int g, int b, int a, int cur, int maxw) {
        draw_text(str, left, top, r, g, b, a, cur, maxw);
    }

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
