local ffi = require("ffi")

ffi.cdef [[
    typedef unsigned int uint;
    typedef unsigned char uchar;
    typedef unsigned long ulong;
    typedef unsigned short ushort;
]]

if CLIENT then ffi.cdef [[
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
]] end

nullptr = ffi.cast("void*", nil)

return ffi.C
