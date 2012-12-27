--[[! File: library/core/eapi.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        The Lua part of the OctaForge EAPI (Engine API). Declares all the
        symbols used by the scripting system from the engine. Accessible
        as a global variable EAPI.
]]

ffi.cdef [[
    typedef unsigned int uint;
    typedef unsigned char uchar;
    typedef unsigned long ulong;
    typedef unsigned short ushort;

    int lastmillis;
    int totalmillis;

    /* core primitives */

    enum {
        BASE_LOG_INFO = 0,
        BASE_LOG_DEBUG,
        BASE_LOG_WARNING,
        BASE_LOG_ERROR,
        BASE_LOG_INIT,
        BASE_LOG_OFF
    };

    void base_log (int level, const char *msg);
    void base_echo(const char *msg);
    bool base_should_log(int level);

    void base_quit();
]]

if CLIENT then ffi.cdef [[
    void base_reset_renderer();
    void base_reset_sound   ();

    void *base_gl_get_proc_address(const char *proc);

    void base_shader_notexture_set();
    void base_shader_default_set  ();

    enum {
        BASE_CHANGE_GFX     = 1 << 0,
        BASE_CHANGE_SOUND   = 1 << 1,
        BASE_CHANGE_SHADERS = 1 << 2
    };
]] end

ffi.cdef [[
    /* zlib compression */

    ulong zlib_compress_bound(ulong src_len);

    int zlib_compress(uchar *dest, ulong *dest_len, const uchar *src,
        ulong src_len, int level);

    int zlib_uncompress(uchar *dest, ulong *dest_len, const uchar *src,
        ulong src_len);

    enum {
        VAR_I =  0,
        VAR_F =  1,
        VAR_S =  2
    };

    enum {
        VAR_PERSIST   = 1 << 0,
        VAR_OVERRIDE  = 1 << 1,
        VAR_HEX       = 1 << 2
    };

    void var_reset(const char *name);

    void var_new_i(const char *name, int value);
    void var_new_f(const char *name, float value);
    void var_new_s(const char *name, const char *value);

    void var_new_i_full(const char *name, int min, int def, int max,
        int flags);

    void var_new_f_full(const char *name, float min, float def, float max,
        int flags);

    void var_new_s_full(const char *name, const char *def, int flags);

    void var_set_i(const char *name, int value);
    void var_set_f(const char *name, float value);
    void var_set_s(const char *name, const char *value);

    int         var_get_i(const char *name);
    float       var_get_f(const char *name);
    const char *var_get_s(const char *name);

    int   var_get_min_i(const char *name);
    float var_get_min_f(const char *name);

    int   var_get_max_i(const char *name);
    float var_get_max_f(const char *name);

    int         var_get_def_i(const char *name);
    float       var_get_def_f(const char *name);
    const char *var_get_def_s(const char *name);

    int var_get_type(const char *name);

    bool var_exists   (const char *name);
    bool var_is_alias (const char *name);
    bool var_is_hex   (const char *name);
    bool var_emits    (const char *name);
    void var_emits_set(const char *name, bool v);

    bool var_changed();
    void var_changed_set(bool ch);
]]

if CLIENT then ffi.cdef [[
    /* Input handling */

    enum {
        INPUT_MOD_NONE   = 0x0000,
        INPUT_MOD_LSHIFT = 0x0001,
        INPUT_MOD_RSHIFT = 0x0002,
        INPUT_MOD_LCTRL  = 0x0040,
        INPUT_MOD_RCTRL  = 0x0080,
        INPUT_MOD_LALT   = 0x0100,
        INPUT_MOD_RALT   = 0x0200,
        INPUT_MOD_LMETA  = 0x0400,
        INPUT_MOD_RMETA  = 0x0800,
        INPUT_MOD_NUM    = 0x1000,
        INPUT_MOD_CAPS   = 0x2000,
        INPUT_MOD_MODE   = 0x4000
    };

    enum {
        INPUT_MOD_CTRL  = INPUT_MOD_LCTRL  | INPUT_MOD_RCTRL,
        INPUT_MOD_SHIFT = INPUT_MOD_LSHIFT | INPUT_MOD_RSHIFT,
        INPUT_MOD_ALT   = INPUT_MOD_LALT   | INPUT_MOD_RALT,
        INPUT_MOD_META  = INPUT_MOD_LMETA  | INPUT_MOD_RMETA
    };

    enum {
        INPUT_KEY_MOUSE1 = -1,
        INPUT_KEY_MOUSE2 = -3,
        INPUT_KEY_MOUSE3 = -2,
        INPUT_KEY_MOUSE4 = -4,
        INPUT_KEY_MOUSE5 = -5,
        INPUT_KEY_MOUSE6 = -6,
        INPUT_KEY_MOUSE7 = -7,
        INPUT_KEY_MOUSE8 = -8,
        INPUT_KEY_BACKSPACE = 8,
        INPUT_KEY_TAB = 9,
        INPUT_KEY_CLEAR = 12,
        INPUT_KEY_RETURN = 13,
        INPUT_KEY_PAUSE = 19,
        INPUT_KEY_ESCAPE = 27,
        INPUT_KEY_SPACE = 32,
        INPUT_KEY_EXCLAIM = 33,
        INPUT_KEY_QUOTEDBL = 34,
        INPUT_KEY_HASH = 35,
        INPUT_KEY_DOLLAR = 36,
        INPUT_KEY_AMPERSAND = 38,
        INPUT_KEY_QUOTE = 39,
        INPUT_KEY_LEFTPAREN = 40,
        INPUT_KEY_RIGHTPAREN = 41,
        INPUT_KEY_ASTERISK = 42,
        INPUT_KEY_PLUS = 43,
        INPUT_KEY_COMMA = 44,
        INPUT_KEY_MINUS = 45,
        INPUT_KEY_PERIOD = 46,
        INPUT_KEY_SLASH = 47,
        INPUT_KEY_0 = 48,
        INPUT_KEY_1 = 49,
        INPUT_KEY_2 = 50,
        INPUT_KEY_3 = 51,
        INPUT_KEY_4 = 52,
        INPUT_KEY_5 = 53,
        INPUT_KEY_6 = 54,
        INPUT_KEY_7 = 55,
        INPUT_KEY_8 = 56,
        INPUT_KEY_9 = 57,
        INPUT_KEY_COLON = 58,
        INPUT_KEY_SEMICOLON = 59,
        INPUT_KEY_LESS = 60,
        INPUT_KEY_EQUALS = 61,
        INPUT_KEY_GREATER = 62,
        INPUT_KEY_QUESTION = 63,
        INPUT_KEY_AT = 64,
        INPUT_KEY_LEFTBRACKET = 91,
        INPUT_KEY_BACKSLASH = 92,
        INPUT_KEY_RIGHTBRACKET = 93,
        INPUT_KEY_CARET = 94,
        INPUT_KEY_UNDERSCORE = 95,
        INPUT_KEY_BACKQUOTE = 96,
        INPUT_KEY_A = 97,
        INPUT_KEY_B = 98,
        INPUT_KEY_C = 99,
        INPUT_KEY_D = 100,
        INPUT_KEY_E = 101,
        INPUT_KEY_F = 102,
        INPUT_KEY_G = 103,
        INPUT_KEY_H = 104,
        INPUT_KEY_I = 105,
        INPUT_KEY_J = 106,
        INPUT_KEY_K = 107,
        INPUT_KEY_L = 108,
        INPUT_KEY_M = 109,
        INPUT_KEY_N = 110,
        INPUT_KEY_O = 111,
        INPUT_KEY_P = 112,
        INPUT_KEY_Q = 113,
        INPUT_KEY_R = 114,
        INPUT_KEY_S = 115,
        INPUT_KEY_T = 116,
        INPUT_KEY_U = 117,
        INPUT_KEY_V = 118,
        INPUT_KEY_W = 119,
        INPUT_KEY_X = 120,
        INPUT_KEY_Y = 121,
        INPUT_KEY_Z = 122,
        INPUT_KEY_DELETE = 127,
        INPUT_KEY_KP0 = 256,
        INPUT_KEY_KP1 = 257,
        INPUT_KEY_KP2 = 258,
        INPUT_KEY_KP3 = 259,
        INPUT_KEY_KP4 = 260,
        INPUT_KEY_KP5 = 261,
        INPUT_KEY_KP6 = 262,
        INPUT_KEY_KP7 = 263,
        INPUT_KEY_KP8 = 264,
        INPUT_KEY_KP9 = 265,
        INPUT_KEY_KP_PERIOD = 266,
        INPUT_KEY_KP_DIVIDE = 267,
        INPUT_KEY_KP_MULTIPLY = 268,
        INPUT_KEY_KP_MINUS = 269,
        INPUT_KEY_KP_PLUS = 270,
        INPUT_KEY_KP_ENTER = 271,
        INPUT_KEY_KP_EQUALS = 272,
        INPUT_KEY_UP = 273,
        INPUT_KEY_DOWN = 274,
        INPUT_KEY_RIGHT = 275,
        INPUT_KEY_LEFT = 276,
        INPUT_KEY_INSERT = 277,
        INPUT_KEY_HOME = 278,
        INPUT_KEY_END = 279,
        INPUT_KEY_PAGEUP = 280,
        INPUT_KEY_PAGEDOWN = 281,
        INPUT_KEY_F1 = 282,
        INPUT_KEY_F2 = 283,
        INPUT_KEY_F3 = 284,
        INPUT_KEY_F4 = 285,
        INPUT_KEY_F5 = 286,
        INPUT_KEY_F6 = 287,
        INPUT_KEY_F7 = 288,
        INPUT_KEY_F8 = 289,
        INPUT_KEY_F9 = 290,
        INPUT_KEY_F10 = 291,
        INPUT_KEY_F11 = 292,
        INPUT_KEY_F12 = 293,
        INPUT_KEY_F13 = 294,
        INPUT_KEY_F14 = 295,
        INPUT_KEY_F15 = 296,
        INPUT_KEY_NUMLOCK = 300,
        INPUT_KEY_CAPSLOCK = 301,
        INPUT_KEY_SCROLLOCK = 302,
        INPUT_KEY_RSHIFT = 303,
        INPUT_KEY_LSHIFT = 304,
        INPUT_KEY_RCTRL = 305,
        INPUT_KEY_LCTRL = 306,
        INPUT_KEY_RALT = 307,
        INPUT_KEY_LALT = 308,
        INPUT_KEY_RMETA = 309,
        INPUT_KEY_LMETA = 310,
        INPUT_KEY_LSUPER = 311,
        INPUT_KEY_RSUPER = 312,
        INPUT_KEY_MODE = 313,
        INPUT_KEY_COMPOSE = 314,
        INPUT_KEY_HELP = 315,
        INPUT_KEY_PRINT = 316,
        INPUT_KEY_SYSREQ = 317,
        INPUT_KEY_BREAK = 318,
        INPUT_KEY_MENU = 319
    };

    int input_get_modifier_state();

    /* GUI */

    bool gui_mainmenu;
    void gui_set_mainmenu(bool v);

    void gui_text_bounds  (const char *str, int   &w, int   &h, int maxw);
    void gui_text_bounds_f(const char *str, float &w, float &h, int maxw);

    void gui_text_pos  (const char *str, int cur, int &cx, int &cy, int maxw);
    void gui_text_pos_f(const char *str, int cur,
        float &cx, float &cy, int maxw);

    int gui_text_visible(const char *str, float hitx, float hity, int maxw);

    void gui_draw_text(const char *str, int left, int top,
        int r, int g, int b, int a, int cur, int maxw);

    /* Deprecated GUI stuff */

    void gui_font(const char *name, const char *text, int dw, int dh);
    void gui_font_offset(const char *c);
    void gui_font_tex(const char *t);
    void gui_font_scale(int s);
    void gui_font_char(int x, int y, int w, int h, int ox, int oy, int adv);
    void gui_font_skip(int n);
    void gui_font_alias(const char *dst, const char *src);

    /* OpenGL types */

    typedef unsigned int GLenum;
    typedef unsigned char GLboolean;
    typedef unsigned int GLbitfield;
    typedef signed char GLbyte;
    typedef short GLshort;
    typedef int GLint;
    typedef int GLsizei;
    typedef unsigned char GLubyte;
    typedef unsigned short GLushort;
    typedef unsigned int GLuint;
    typedef float GLfloat;
    typedef float GLclampf;
    typedef double GLdouble;
    typedef double GLclampd;
    typedef void GLvoid;
    typedef long GLintptr;
    typedef long GLsizeiptr;
    typedef char GLchar;
    typedef char GLcharARB;
    typedef void *GLhandleARB;
    typedef long GLintptrARB;
    typedef long GLsizeiptrARB;
    typedef unsigned short GLhalfARB;
    typedef unsigned short GLhalf;

    /* Textures */

    typedef struct Texture {
        char *name;
        int type, w, h, xs, ys, bpp, clamp;
        bool mipmap, canreduce;
        GLuint id;
        uchar *alphamask;
    } Texture;

    Texture *texture_load(const char *path);
    Texture *texture_get_notexture();
    void     texture_load_alpha_mask(Texture *tex);
]] end

nullptr = ffi.cast("void*", nil)

return ffi.C
