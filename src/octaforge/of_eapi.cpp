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

#include "cube.h"
#include "texture.h"

/* prototypes */

#ifdef CLIENT
void quit      ();
void resetgl   ();
void resetsound();
#endif

extern "C" {
    /* Core primitives */

    void base_log(int level, const char *msg) {
        logger::log((logger::loglevel) level, "%s\n", msg);
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

#endif

    /* Engine variables */

    void var_reset(const char *name) {
        varsys::get(name)->reset();
    }

    void var_new_i(const char *name, int value) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);
        if (!ev)
            ev = varsys::reg_var(name, new varsys::Int_Alias(name, value));
        else if (ev->type() != varsys::TYPE_I) {
            logger::log(logger::ERROR,
                "Engine variable %s is not integral, cannot become %i.\n",
                value);
            return;
        }
        else varsys::set(ev, value, false, false);
    }

    void var_new_f(const char *name, float value) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);
        if (!ev)
            ev = varsys::reg_var(name, new varsys::Float_Alias(name, value));
        else if (ev->type() != varsys::TYPE_F) {
            logger::log(logger::ERROR,
                "Engine variable %s is not a float, cannot become %f.\n",
                value);
            return;
        }
        else varsys::set(ev, value, false, false);
    }

    void var_new_s(const char *name, const char *value) {
        if (!name ) return;
        if (!value) value = "";

        varsys::Variable *ev = varsys::get(name);
        if (!ev)
            ev = varsys::reg_var(name, new varsys::String_Alias(name, value));
        else if (ev->type() != varsys::TYPE_S) {
            logger::log(logger::ERROR,
                "Engine variable %s is not a string, cannot become %s.\n",
                value);
            return;
        }
        else varsys::set(ev, value, false);
    }

    void var_set_i(const char *name, int value) {
        if (!name) return;

        varsys::Variable *ev = varsys::get(name);

        if (!ev) {
            logger::log(logger::ERROR,
                "Engine variable %s does not exist.\n", name);
            return;
        }

        if (ev->type() != varsys::TYPE_I) {
            logger::log(logger::ERROR,
                "Engine variable %s is not integral, cannot become %i.\n",
                value);
            return;
        }

        if ((ev->flags() & varsys::FLAG_READONLY) != 0) {
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

        if (ev->type() != varsys::TYPE_F) {
            logger::log(logger::ERROR,
                "Engine variable %s is not a float, cannot become %f.\n",
                value);
            return;
        }

        if ((ev->flags() & varsys::FLAG_READONLY) != 0) {
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

        if (ev->type() != varsys::TYPE_S) {
            logger::log(logger::ERROR,
                "Engine variable %s is not a string, cannot become %s.\n",
                value);
            return;
        }

        if ((ev->flags() & varsys::FLAG_READONLY) != 0) {
            logger::log(logger::ERROR,
                "Engine variable %s is read-only.\n", name);
            return;
        }

        varsys::set(ev, value, true);
    }

    int var_get_i(const char *name) {
        if (!name) return 0;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type() != varsys::TYPE_I) return 0;

        return varsys::get_int(ev);
    }

    float var_get_f(const char *name) {
        if (!name) return 0.0f;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type() != varsys::TYPE_F) return 0.0f;

        return varsys::get_float(ev);
    }

    const char *var_get_s(const char *name) {
        if (!name) return NULL;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type() != varsys::TYPE_S) return NULL;

        return varsys::get_string(ev);
    }

    int var_get_min_i(const char *name) {
        if (!name) return 0;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type() != varsys::TYPE_I ||
            (ev->flags() & varsys::FLAG_ALIAS))
                return 0;

        return (((varsys::Int_Variable *)ev)->get_min());
    }

    float var_get_min_f(const char *name) {
        if (!name) return 0.0f;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type() != varsys::TYPE_F ||
            (ev->flags() & varsys::FLAG_ALIAS))
                return 0.0f;

        return (((varsys::Float_Variable *)ev)->get_min());
    }

    int var_get_max_i(const char *name) {
        if (!name) return 0;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type() != varsys::TYPE_I ||
            (ev->flags() & varsys::FLAG_ALIAS))
                return 0;

        return (((varsys::Int_Variable *)ev)->get_max());
    }

    float var_get_max_f(const char *name) {
        if (!name) return 0.0f;

        varsys::Variable *ev = varsys::get(name);
        if (!ev || ev->type() != varsys::TYPE_F ||
            (ev->flags() & varsys::FLAG_ALIAS))
                return 0.0f;

        return (((varsys::Float_Variable *)ev)->get_max());
    }

    int var_get_type(const char *name) {
        varsys::Variable *ev = varsys::get(name);
        if (!ev)
            return varsys::TYPE_N;
        return ev->type();
    }

    bool var_exists(const char *name) {
        return varsys::get(name) ? true : false;
    }

    bool var_persist_vars(bool persist) {
        bool was = varsys::persistvars;
        varsys::persistvars = persist;
        return was;
    }

    bool var_is_alias(const char *name) {
        varsys::Variable *ev = varsys::get(name);
        return (!ev || !(ev->flags() & varsys::FLAG_ALIAS)) ? false : true;
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

    void gui_draw_primitive(uint mode, int r, int g, int b, int a, bool mod,
        size_t nv, ...) {
        va_list  ap;
        va_start(ap, nv);

        if (mod) glBlendFunc(GL_ZERO, GL_SRC_COLOR);
        notextureshader->set();
        glDisable(GL_TEXTURE_2D);
        glColor4ub(r, g, b, a);
        glBegin(mode);

        for (size_t i = 0; i < nv; ++i) {
            float x = (float)va_arg(ap, double);
            float y = (float)va_arg(ap, double);
            glVertex2f(x, y);
        }

        glEnd();
        glEnable(GL_TEXTURE_2D);
        defaultshader->set();
        if (mod) glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        va_end(ap);
    }

    void gui_draw_text(const char *str, int left, int top,
        int r, int g, int b, int a, int cur, int maxw) {
        draw_text(str, left, top, r, g, b, a, cur, maxw);
    }

#endif
}
