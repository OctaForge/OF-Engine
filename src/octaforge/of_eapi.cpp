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

#ifdef CLIENT
void quit      ();
void resetgl   ();
void resetsound();

void newfont(const char *name, const char *tex, int defaultw, int defaulth);
void fontoffset(const char *c);
void fontscale(int scale);
void fonttex(const char *s);
void fontchar(
    int x, int y, int w, int h, int offsetx, int offsety, int advance
);
void fontskip(int n);
void fontalias(const char *dst, const char *src);
#endif

bool gui_mainmenu = true;

extern "C" {
    /* Core primitives */

    void base_log(int level, const char *msg) {
        logger::log((logger::loglevel)level, "%s\n", msg);
    }

    bool base_should_log(int level) {
        return logger::should_log((logger::loglevel)level);
    }

    void base_echo(const char *msg) {
        conoutf("\f1%s", msg);
    }

#ifdef CLIENT

    void base_quit() {
        quit();
    }

    void base_reset_renderer() {
        resetgl();
    }

    void base_reset_sound() {
        resetsound();
    }

    void *base_gl_get_proc_address(const char *proc) {
        return SDL_GL_GetProcAddress(proc);
    }

    void base_shader_notexture_set() {
        notextureshader->set();
    }

    void base_shader_default_set() {
        defaultshader->set();
    }

#endif

    /* zlib compression */

    ulong zlib_compress_bound(ulong src_len) {
        return compressBound(src_len);
    }

    int zlib_compress(uchar *dest, ulong *dest_len, const uchar *src,
        ulong src_len, int level) {
        return compress2(dest, dest_len, src, src_len, level);
    }

    int zlib_uncompress(uchar *dest, ulong *dest_len, const uchar *src,
        ulong src_len) {
        return uncompress(dest, dest_len, src, src_len);
    }

    /* Engine variables */

    void var_reset(const char *name) {
        varsys::reset(varsys::get(name));
    }

    void var_new_i(const char *name, int value) {
        if (!name) return;
        printf("new!\n");

        varsys::Variable *ev = varsys::get(name);
        if (!ev) {
            varsys::reg_int(name, value);
        }
        else if (ev->type != varsys::TYPE_I) {
            logger::log(logger::ERROR,
                "Creation of engine variable \"%s\" failed: already exists "
                "and is of different type.\n", ev->name);
        }
        else if (ev->flags != varsys::FLAG_ALIAS) {
            logger::log(logger::ERROR,
                "Engine variable \"%s\" already exists and has different "
                "flags.", ev->name);
        }
    }

    void var_new_f(const char *name, float value) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);
        if (!ev) {
            varsys::reg_float(name, value);
        }
        else if (ev->type != varsys::TYPE_F) {
            logger::log(logger::ERROR,
                "Creation of engine variable \"%s\" failed: already exists "
                "and is of different type.\n", ev->name);
        }
        else if (ev->flags != varsys::FLAG_ALIAS) {
            logger::log(logger::ERROR,
                "Engine variable \"%s\" already exists and has different "
                "flags.", ev->name);
        }
    }

    void var_new_s(const char *name, const char *value) {
        if (!name ) return;
        if (!value) value = "";

        varsys::Variable *ev = varsys::get(name);
        if (!ev) {
            varsys::reg_string(name, value);
        }
        else if (ev->type != varsys::TYPE_S) {
            logger::log(logger::ERROR,
                "Creation of engine variable \"%s\" failed: already exists "
                "and is of different type.\n", ev->name);
        }
        else if (ev->flags != varsys::FLAG_ALIAS) {
            logger::log(logger::ERROR,
                "Engine variable \"%s\" already exists and has different "
                "flags.", ev->name);
        }
    }

    void var_new_i_full(const char *name, int min, int def, int max,
        int flags) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);
        if (!ev) {
            varsys::reg_int(name, flags, NULL, NULL, min, def, max);
        }
        else if (ev->type != varsys::TYPE_I) {
            logger::log(logger::ERROR,
                "Creation of engine variable \"%s\" failed: already exists "
                "and is of different type.\n", ev->name);
        }
        else if (ev->flags != flags) {
            logger::log(logger::ERROR,
                "Engine variable \"%s\" already exists and has different "
                "flags.", ev->name);
        }
    }

    void var_new_f_full(const char *name, float min, float def, float max,
        int flags) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);
        if (!ev) {
            varsys::reg_float(name, flags, NULL, NULL, min, def, max);
        }
        else if (ev->type != varsys::TYPE_F) {
            logger::log(logger::ERROR,
                "Creation of engine variable \"%s\" failed: already exists "
                "and is of different type.\n", ev->name);
        }
        else if (ev->flags != flags) {
            logger::log(logger::ERROR,
                "Engine variable \"%s\" already exists and has different "
                "flags.", ev->name);
        }
    }

    void var_new_s_full(const char *name, const char *def, int flags) {
        if (!name) return;
        if (!def ) def = "";

        varsys::Variable *ev = varsys::get(name);
        if (!ev) {
            varsys::reg_string(name, flags, NULL, NULL, def);
        }
        else if (ev->type != varsys::TYPE_S) {
            logger::log(logger::ERROR,
                "Creation of engine variable \"%s\" failed: already exists "
                "and is of different type.\n", ev->name);
        }
        else if (ev->flags != flags) {
            logger::log(logger::ERROR,
                "Engine variable \"%s\" already exists and has different "
                "flags.", ev->name);
        }
    }

    void var_set_i(const char *name, int value) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);

        if (!ev) {
            logger::log(logger::ERROR,
                "Engine variable %s does not exist.\n", name);
            return;
        }

        if (ev->type != varsys::TYPE_I) {
            logger::log(logger::ERROR,
                "Engine variable %s is not integral, cannot become %i.\n",
                value);
            return;
        }

        if ((ev->flags & varsys::FLAG_READONLY) != 0) {
            logger::log(logger::ERROR,
                "Engine variable %s is read-only.\n", name);
            return;
        }

        varsys::set(ev, value, true, true);
    }

    void var_set_f(const char *name, float value) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);

        if (!ev) {
            logger::log(logger::ERROR,
                "Engine variable %s does not exist.\n", name);
            return;
        }

        if (ev->type != varsys::TYPE_F) {
            logger::log(logger::ERROR,
                "Engine variable %s is not a float, cannot become %f.\n",
                value);
            return;
        }

        if ((ev->flags & varsys::FLAG_READONLY) != 0) {
            logger::log(logger::ERROR,
                "Engine variable %s is read-only.\n", name);
            return;
        }

        varsys::set(ev, value, true, true);
    }

    void var_set_s(const char *name, const char *value) {
        if (!name ) return;
        if (!value) value = "";

        varsys::Variable *ev = varsys::get(name);

        if (!ev) {
            logger::log(logger::ERROR,
                "Engine variable %s does not exist.\n", name);
            return;
        }

        if (ev->type != varsys::TYPE_S) {
            logger::log(logger::ERROR,
                "Engine variable %s is not a string, cannot become %s.\n",
                value);
            return;
        }

        if ((ev->flags & varsys::FLAG_READONLY) != 0) {
            logger::log(logger::ERROR,
                "Engine variable %s is read-only.\n", name);
            return;
        }

        varsys::set(ev, value, true);
    }

    int var_get_i(const char *name) {
        if (!name) return 0;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_I) return 0;

        return varsys::get_int(ev);
    }

    float var_get_f(const char *name) {
        if (!name) return 0.0f;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_F) return 0.0f;

        return varsys::get_float(ev);
    }

    const char *var_get_s(const char *name) {
        if (!name) return NULL;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_S) return NULL;

        return varsys::get_string(ev);
    }

    int var_get_min_i(const char *name) {
        if (!name) return 0;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_I ||
            (ev->flags & varsys::FLAG_ALIAS))
                return 0;

        return (((varsys::Int_Variable *)ev)->min_v);
    }

    float var_get_min_f(const char *name) {
        if (!name) return 0.0f;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_F ||
            (ev->flags & varsys::FLAG_ALIAS))
                return 0.0f;

        return (((varsys::Float_Variable *)ev)->min_v);
    }

    int var_get_max_i(const char *name) {
        if (!name) return 0;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_I ||
            (ev->flags & varsys::FLAG_ALIAS))
                return 0;

        return (((varsys::Int_Variable *)ev)->max_v);
    }

    float var_get_max_f(const char *name) {
        if (!name) return 0.0f;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_F ||
            (ev->flags & varsys::FLAG_ALIAS))
                return 0.0f;

        return (((varsys::Float_Variable *)ev)->max_v);
    }

    int var_get_def_i(const char *name) {
        if (!name) return 0;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_I ||
            (ev->flags & varsys::FLAG_ALIAS))
                return 0;

        return (((varsys::Int_Variable *)ev)->def_v);
    }

    float var_get_def_f(const char *name) {
        if (!name) return 0.0f;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_F ||
            (ev->flags & varsys::FLAG_ALIAS))
                return 0.0f;

        return (((varsys::Float_Variable *)ev)->def_v);
    }

    const char *var_get_def_s(const char *name) {
        if (!name) return NULL;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type != varsys::TYPE_S ||
            (ev->flags & varsys::FLAG_ALIAS))
                return NULL;

        return (((varsys::String_Variable *)ev)->def_v);
    }

    int var_get_type(const char *name) {
        varsys::Variable *ev = varsys::get(name);
        if (!ev) return -1;
        return ev->type;
    }

    bool var_exists(const char *name) {
        return varsys::get(name) ? true : false;
    }

    bool var_is_alias(const char *name) {
        varsys::Variable *ev = varsys::get(name);
        return (!ev || !(ev->flags & varsys::FLAG_ALIAS)) ? false : true;
    }

    bool var_is_hex(const char *name) {
        varsys::Variable *ev = varsys::get(name);
        return (!ev || !(ev->flags & varsys::FLAG_HEX)) ? false : true;
    }

    bool var_emits(const char *name) {
        varsys::Variable *ev = varsys::get(name);
        return (!ev || !(ev->emits)) ? false : true;
    }

    void var_emits_set(const char *name, bool v) {
        varsys::Variable *ev = varsys::get(name);
        if (!ev || (ev->flags & varsys::FLAG_ALIAS)) return;
        ev->emits = v;
    }

    bool var_changed() {
        return varsys::changed;
    }

    void var_changed_set(bool ch) {
        varsys::changed = ch;
    }

    /* Input handling */

#ifdef CLIENT

    int input_get_modifier_state() {
        return (int) SDL_GetModState();
    }

    /* GUI */

    void gui_set_mainmenu(bool v) {
        gui_mainmenu = v;
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

    /* Deprecated GUI stuff */

    void gui_font(const char *name, const char *text, int dw, int dh) {
        newfont(name, text, dw, dh);
    }

    void gui_font_offset(const char *c) {
        fontoffset(c);
    }

    void gui_font_tex(const char *t) {
        fonttex(t);
    }

    void gui_font_scale(int s) {
        fontscale(s);
    }

    void gui_font_char(int x, int y, int w, int h, int ox, int oy, int adv) {
        fontchar(x, y, w, h, ox, oy, adv);
    }

    void gui_font_skip(int n) {
        fontskip(n);
    }

    void gui_font_alias(const char *dst, const char *src) {
        fontalias(dst, src);
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
