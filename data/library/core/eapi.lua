local ffi = require("ffi")

ffi.cdef [[
    typedef unsigned int uint;
    typedef unsigned char uchar;
    typedef unsigned long ulong;
    typedef unsigned short ushort;
]]

if CLIENT then ffi.cdef [[
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
