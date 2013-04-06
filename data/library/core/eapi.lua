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
]]

ffi.cdef [[
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

    void var_new_i(const char *name, int min, int def, int max,
        int flags);

    void var_new_f(const char *name, float min, float def, float max,
        int flags);

    void var_new_s(const char *name, const char *def, int flags);

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

    void gui_set_mainmenu(int v);

    void gui_text_bounds  (const char *str, int   &w, int   &h, int maxw);
    void gui_text_bounds_f(const char *str, float &w, float &h, int maxw);

    void gui_text_pos  (const char *str, int cur, int &cx, int &cy, int maxw);
    void gui_text_pos_f(const char *str, int cur,
        float &cx, float &cy, int maxw);

    int gui_text_visible(const char *str, float hitx, float hity, int maxw);

    void gui_draw_text(const char *str, int left, int top,
        int r, int g, int b, int a, int cur, int maxw);

    /* Textures */

    typedef struct Texture {
        char *name;
        int type, w, h, xs, ys, bpp, clamp;
        bool mipmap, canreduce;
        uint id;
        uchar *alphamask;
    } Texture;

    Texture *texture_load(const char *path);
    Texture *texture_get_notexture();
    void     texture_load_alpha_mask(Texture *tex);

    /* hudmatrix */

    void hudmatrix_push();
    void hudmatrix_pop();
    void hudmatrix_flush();
    void hudmatrix_reset();

    void hudmatrix_translate(float x, float y, float z);
    void hudmatrix_scale(float x, float y, float z);
    void hudmatrix_ortho(float l, float r, float b, float t, float zn, float zf);

    /* gl */

    enum {
        GL_ALPHA = 0x1906,
        GL_ALWAYS = 0x0207,
        GL_BLUE = 0x1905,
        GL_CLAMP_TO_BORDER = 0x812D,
        GL_CLAMP_TO_EDGE = 0x812F,
        GL_COMPARE_REF_TO_TEXTURE = 0x884E,
        GL_CONSTANT_ALPHA = 0x8003,
        GL_CONSTANT_COLOR = 0x8001,
        GL_DST_ALPHA = 0x0304,
        GL_DST_COLOR = 0x0306,
        GL_EQUAL = 0x0202,
        GL_GEQUAL = 0x0206,
        GL_GREATER = 0x0204,
        GL_GREEN = 0x1904,
        GL_LEQUAL = 0x0203,
        GL_LESS = 0x0201,
        GL_LINEAR = 0x2601,
        GL_LINEAR_MIPMAP_LINEAR = 0x2703,
        GL_LINEAR_MIPMAP_NEAREST = 0x2701,
        GL_LINES = 0x0001,
        GL_LINE_LOOP = 0x0002,
        GL_LINE_STRIP = 0x0003,
        GL_MAX_TEXTURE_LOD_BIAS = 0x84FD,
        GL_MIRRORED_REPEAT = 0x8370,
        GL_NEAREST = 0x2600,
        GL_NEAREST_MIPMAP_LINEAR = 0x2702,
        GL_NEAREST_MIPMAP_NEAREST = 0x2700,
        GL_NEVER = 0x0200,
        GL_NONE = 0x0,
        GL_NOTEQUAL = 0x0205,
        GL_ONE = 0x1,
        GL_ONE_MINUS_CONSTANT_ALPHA = 0x8004,
        GL_ONE_MINUS_CONSTANT_COLOR = 0x8002,
        GL_ONE_MINUS_DST_ALPHA = 0x0305,
        GL_ONE_MINUS_DST_COLOR = 0x0307,
        GL_ONE_MINUS_SRC1_ALPHA = 0x88FB,
        GL_ONE_MINUS_SRC1_COLOR = 0x88FA,
        GL_ONE_MINUS_SRC_ALPHA = 0x0303,
        GL_ONE_MINUS_SRC_COLOR = 0x0301,
        GL_POINTS = 0x0000,
        GL_POLYGON = 0x0009,
        GL_QUADS = 0x0007,
        GL_QUAD_STRIP = 0x0008,
        GL_RED = 0x1903,
        GL_REPEAT = 0x2901,
        GL_SRC1_ALPHA = 0x8589,
        GL_SRC1_COLOR = 0x88F9,
        GL_SRC_ALPHA = 0x0302,
        GL_SRC_ALPHA_SATURATE = 0x0308,
        GL_SRC_COLOR = 0x0300,
        GL_TEXTURE_BASE_LEVEL = 0x813C,
        GL_TEXTURE_COMPARE_FUNC = 0x884D,
        GL_TEXTURE_COMPARE_MODE = 0x884C,
        GL_TEXTURE_LOD_BIAS = 0x8501,
        GL_TEXTURE_MAG_FILTER = 0x2800,
        GL_TEXTURE_MAX_LEVEL = 0x813D,
        GL_TEXTURE_MAX_LOD = 0x813B,
        GL_TEXTURE_MIN_FILTER = 0x2801,
        GL_TEXTURE_MIN_LOD = 0x813A,
        GL_TEXTURE_SWIZZLE_A = 0x8E45,
        GL_TEXTURE_SWIZZLE_B = 0x8E44,
        GL_TEXTURE_SWIZZLE_G = 0x8E43,
        GL_TEXTURE_SWIZZLE_R = 0x8E42,
        GL_TEXTURE_WRAP_R = 0x8072,
        GL_TEXTURE_WRAP_S = 0x2802,
        GL_TEXTURE_WRAP_T = 0x2803,
        GL_TRIANGLES = 0x0004,
        GL_TRIANGLE_FAN = 0x0006,
        GL_TRIANGLE_STRIP = 0x0005,
        GL_ZERO = 0x0
    };

    void gl_shader_hud_set();
    void gl_shader_hudnotexture_set();

    void gl_scissor_enable();
    void gl_scissor_disable();
    void gl_scissor(int x, int y, int w, int h);
    void gl_blend_enable();
    void gl_blend_disable();
    void gl_blend_func(uint sf, uint df);
    void gl_bind_texture(Texture *tex);
    void gl_texture_param(uint pn, int pr);

    /* varray */

    void varray_begin(uint mode);
    int varray_end();
    void varray_disable();

    void varray_defvertex(int size);
    void varray_defcolor(int size);
    void varray_deftexcoord0(int size);
    void varray_deftexcoord1(int size);

    void varray_vertex1f(float x);
    void varray_vertex2f(float x, float y);
    void varray_vertex3f(float x, float y, float z);
    void varray_vertex4f(float x, float y, float z, float w);
    void varray_color1f(float x);
    void varray_color2f(float x, float y);
    void varray_color3f(float x, float y, float z);
    void varray_color4f(float x, float y, float z, float w);
    void varray_texcoord01f(float x);
    void varray_texcoord02f(float x, float y);
    void varray_texcoord03f(float x, float y, float z);
    void varray_texcoord04f(float x, float y, float z, float w);
    void varray_texcoord11f(float x);
    void varray_texcoord12f(float x, float y);
    void varray_texcoord13f(float x, float y, float z);
    void varray_texcoord14f(float x, float y, float z, float w);

    void varray_color3ub(uchar x, uchar y, uchar z);
    void varray_color4ub(uchar x, uchar y, uchar z, uchar w);

    void varray_attrib1f(float x);
    void varray_attrib2f(float x, float y);
    void varray_attrib3f(float x, float y, float z);
    void varray_attrib4f(float x, float y, float z, float w);
    void varray_attrib1d(double x);
    void varray_attrib2d(double x, double y);
    void varray_attrib3d(double x, double y, double z);
    void varray_attrib4d(double x, double y, double z, double w);
    void varray_attrib1b(char x);
    void varray_attrib2b(char x, char y);
    void varray_attrib3b(char x, char y, char z);
    void varray_attrib4b(char x, char y, char z, char w);
    void varray_attrib1ub(uchar x);
    void varray_attrib2ub(uchar x, uchar y);
    void varray_attrib3ub(uchar x, uchar y, uchar z);
    void varray_attrib4ub(uchar x, uchar y, uchar z, uchar w);
    void varray_attrib1s(short x);
    void varray_attrib2s(short x, short y);
    void varray_attrib3s(short x, short y, short z);
    void varray_attrib4s(short x, short y, short z, short w);
    void varray_attrib1us(ushort x);
    void varray_attrib2us(ushort x, ushort y);
    void varray_attrib3us(ushort x, ushort y, ushort z);
    void varray_attrib4us(ushort x, ushort y, ushort z, ushort w);
    void varray_attrib1i(int x);
    void varray_attrib2i(int x, int y);
    void varray_attrib3i(int x, int y, int z);
    void varray_attrib4i(int x, int y, int z, int w);
    void varray_attrib1ui(uint x);
    void varray_attrib2ui(uint x, uint y);
    void varray_attrib3ui(uint x, uint y, uint z);
    void varray_attrib4ui(uint x, uint y, uint z, uint w);
]] end

nullptr = ffi.cast("void*", nil)

return ffi.C
