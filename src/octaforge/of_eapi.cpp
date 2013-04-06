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
    /* Engine variables */

    void var_reset(const char *name) {
        resetvar((char*)name);
    }

    void var_new_i(const char *name, int min, int def, int max,
        int flags) {
        if (!name) return;
        ident *id = getident(name);
        if (!id) {
            int *st = new int;
            *st = variable(name, min, def, max, st, NULL, flags | IDF_ALLOC);
        } else {
            logger::log(logger::ERROR, "variable %s already exists\n", name);
        }
    }

    void var_new_f(const char *name, float min, float def, float max,
        int flags) {
        if (!name) return;
        ident *id = getident(name);
        if (!id) {
            float *st = new float;
            *st = fvariable(name, min, def, max, st, NULL, flags | IDF_ALLOC);
        } else {
            logger::log(logger::ERROR, "variable %s already exists\n", name);
        }
    }

    void var_new_s(const char *name, const char *def, int flags) {
        if (!name) return;
        ident *id = getident(name);
        if (!id) {
            char **st = new char*;
            *st = svariable(name, def, st, NULL, flags | IDF_ALLOC);
        } else {
            logger::log(logger::ERROR, "variable %s already exists\n", name);
        }
    }

    void var_set_i(const char *name, int value) {
        setvar(name, value);
    }

    void var_set_f(const char *name, float value) {
        setfvar(name, value);
    }

    void var_set_s(const char *name, const char *value) {
        setsvar(name, value);
    }

    int var_get_i(const char *name) {
        return getvar(name);
    }

    float var_get_f(const char *name) {
        return getfvar(name);
    }

    const char *var_get_s(const char *name) {
        return getsvar(name);
    }

    int var_get_min_i(const char *name) {
        return getvarmin(name);
    }

    float var_get_min_f(const char *name) {
        return getfvarmin(name);
    }

    int var_get_max_i(const char *name) {
        return getvarmax(name);
    }

    float var_get_max_f(const char *name) {
        return getfvarmax(name);
    }

    int var_get_def_i(const char *name) {
        ident *id = getident(name);
        if (!id || id->type != ID_VAR) return 0;
        return id->overrideval.i;
    }

    float var_get_def_f(const char *name) {
        ident *id = getident(name);
        if (!id || id->type != ID_FVAR) return 0.0f;
        return id->overrideval.f;
    }

    const char *var_get_def_s(const char *name) {
        ident *id = getident(name);
        if (!id || id->type != ID_SVAR) return NULL;
        return id->overrideval.s;
    }

    int var_get_type(const char *name) {
        ident *id = getident(name);
        if (!id || id->type > ID_SVAR)
            return -1;
        return id->type;
    }

    bool var_exists(const char *name) {
        ident *id = getident(name);
        return (!id || id->type > ID_SVAR)
            ? false : true;
    }

    bool var_is_hex(const char *name) {
        ident *id = getident(name);
        return (!id || !(id->flags&IDF_HEX)) ? false : true;
    }

    bool var_emits(const char *name) {
        ident *id = getident(name);
        return (!id || !(id->flags&IDF_SIGNAL)) ? false : true;
    }

    void var_emits_set(const char *name, bool v) {
        ident *id = getident(name);
        if (!id) return;
        if (v) id->flags |= IDF_SIGNAL;
        else id->flags &= ~IDF_SIGNAL;
    }

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

    /* hudmatrix */

    void hudmatrix_push () { pushhudmatrix (); }
    void hudmatrix_pop  () { pophudmatrix  (); }
    void hudmatrix_flush() { flushhudmatrix(); }
    void hudmatrix_reset() { resethudmatrix(); }

    void hudmatrix_translate(float x, float y, float z) { hudmatrix.translate(vec(x, y, z)); }
    void hudmatrix_scale(float x, float y, float z) { hudmatrix.scale(vec(x, y, z)); }
    void hudmatrix_ortho(float l, float r, float b, float t, float zn, float zf) {
        hudmatrix.ortho(l, r, b, t, zn, zf);
    }

    /* gl */

    void gl_shader_hud_set() {
        hudshader->set();
    }

    void gl_shader_hudnotexture_set() {
        hudnotextureshader->set();
    }

    void gl_scissor_enable() {
        glEnable(GL_SCISSOR_TEST);
    }

    void gl_scissor_disable() {
        glDisable(GL_SCISSOR_TEST);
    }

    void gl_scissor(int x, int y, int w, int h) {
        glScissor(x, y, w, h);
    }

    void gl_blend_enable() {
        glEnable(GL_BLEND);
    }

    void gl_blend_disable() {
        glDisable(GL_BLEND);
    }

    void gl_blend_func(uint sf, uint df) {
        glBlendFunc(sf, df);
    }

    void gl_bind_texture(Texture *tex) {
        glBindTexture(GL_TEXTURE_2D, tex->id);
    }

    void gl_texture_param(uint pn, int pr) {
        glTexParameteri(GL_TEXTURE_2D, pn, pr);
    }

    /* varray */

    void varray_begin(uint mode) { varray::begin(mode); }
    int varray_end() { return varray::end(); }
    void varray_disable() { varray::disable(); }

    #define EAPI_VARRAY_DEFATTRIB(name) \
        void varray_def##name(int size) { varray::def##name(size, GL_FLOAT); }

    EAPI_VARRAY_DEFATTRIB(vertex)
    EAPI_VARRAY_DEFATTRIB(color)
    EAPI_VARRAY_DEFATTRIB(texcoord0)
    EAPI_VARRAY_DEFATTRIB(texcoord1)

    #define EAPI_VARRAY_INITATTRIB(name) \
        void varray_##name##1f(float x) { varray::name##f(x); } \
        void varray_##name##2f(float x, float y) { varray::name##f(x, y); } \
        void varray_##name##3f(float x, float y, float z) { varray::name##f(x, y, z); } \
        void varray_##name##4f(float x, float y, float z, float w) { varray::name##f(x, y, z, w); }

    EAPI_VARRAY_INITATTRIB(vertex)
    EAPI_VARRAY_INITATTRIB(color)
    EAPI_VARRAY_INITATTRIB(texcoord0)
    EAPI_VARRAY_INITATTRIB(texcoord1)

    #define EAPI_VARRAY_INITATTRIBN(name, suffix, type) \
        void varray_##name##3##suffix(type x, type y, type z) { varray::name##suffix(x, y, z); } \
        void varray_##name##4##suffix(type x, type y, type z, type w) { varray::name##suffix(x, y, z, w); }

    EAPI_VARRAY_INITATTRIBN(color, ub, uchar)

    #define EAPI_VARRAY_ATTRIB(suffix, type) \
        void varray_attrib##1##suffix(type x) { varray::attrib##suffix(x); } \
        void varray_attrib##2##suffix(type x, type y) { varray::attrib##suffix(x, y); } \
        void varray_attrib##3##suffix(type x, type y, type z) { varray::attrib##suffix(x, y, z); } \
        void varray_attrib##4##suffix(type x, type y, type z, type w) { varray::attrib##suffix(x, y, z, w); }

    EAPI_VARRAY_ATTRIB(f, float)
    EAPI_VARRAY_ATTRIB(d, double)
    EAPI_VARRAY_ATTRIB(b, char)
    EAPI_VARRAY_ATTRIB(ub, uchar)
    EAPI_VARRAY_ATTRIB(s, short)
    EAPI_VARRAY_ATTRIB(us, ushort)
    EAPI_VARRAY_ATTRIB(i, int)
    EAPI_VARRAY_ATTRIB(ui, uint)
#endif
}
