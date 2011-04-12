/*
 * luabind_tex.hpp, version 1
 * Texture methods for Lua
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

/* PROTOTYPES */

#ifdef CLIENT
void texturereset(int n);
void texture(const char *type, const char *name, int rot, int xoffset, int yoffset, float scale, int forcedindex);

extern MSlot materialslots[MATF_VOLUME+1];
enum
{
    IMG_BMP = 0,
    IMG_TGA = 1,
    IMG_PNG = 2,
    NUMIMG
};

void fixinsidefaces(cube *c, const ivec &o, int size, int tex);
void propagatevslot(VSlot &dst, const VSlot &src, int diff, bool edit = false);
void propagatevslot(VSlot *root, int changed);
void reloadtex(char *name);
void gendds(char *infile, char *outfile);
int guessimageformat(const char *filename, int format = IMG_BMP);
void saveimage(const char *filename, int format, ImageData &image, bool flip = false);
#endif

namespace lua_binds
{
    LUA_BIND_CLIENT(convpngtodds, {
        const char *arg1 = e.get<const char*>(1);
        const char *arg2 = e.get<const char*>(2);
        assert(Utility::validateRelativePath(arg1));
        assert(Utility::validateRelativePath(arg2));
        IntensityTexture::convertPNGtoDDS(arg1, arg2);
    })

    LUA_BIND_CLIENT(combineimages, {
        const char *arg1 = e.get<const char*>(1);
        const char *arg2 = e.get<const char*>(2);
        const char *arg3 = e.get<const char*>(3);
        assert(Utility::validateRelativePath(arg1));
        assert(Utility::validateRelativePath(arg2));
        assert(Utility::validateRelativePath(arg3));
        IntensityTexture::combineImages(arg1, arg2, arg3);
    })

    LUA_BIND_STD_CLIENT(texturereset, texturereset, 0)

    // XXX: arg7 may not be given, in which case it is undefined, and turns into 0.
    LUA_BIND_STD_CLIENT(texture, texture,
                        e.get<const char*>(1),
                        e.get<const char*>(2),
                        e.get<int>(3),
                        e.get<int>(4),
                        e.get<int>(5),
                        (float)e.get(6, 1.0),
                        e.get<int>(7))

    LUA_BIND_CLIENT(materialreset, {
        if (!var::overridevars && !game::allowedittoggle()) return;
        loopi(MATF_VOLUME+1) materialslots[i].reset();
    })

    LUA_BIND_CLIENT(compactvslosts, {
        if (GETIV(nompedit) && multiplayer()) return;
        compactvslots();
        allchanged();
    })

    LUA_BIND_CLIENT(fixinsidefaces, {
        if (noedit(true) || (GETIV(nompedit) && multiplayer())) return;
        int tex = e.get<int>(1);
        fixinsidefaces(worldroot, ivec(0, 0, 0), GETIV(mapsize)>>1, tex && vslots.inrange(tex) ? tex : DEFAULT_GEOM);
        allchanged();
    })

    LUA_BIND_CLIENT(autograss, {
        if (slots.empty()) return;
        Slot &s = *slots.last();
        DELETEA(s.autograss);
        s.autograss = e.get<char*>(1) ? newstring(makerelpath("data", e.get<char*>(1))) : NULL;
    })

    LUA_BIND_CLIENT(texscroll, {
        if (slots.empty()) return;
        Slot &s = *slots.last();
        s.variants->scrollS = e.get<float>(1)/1000.0f;
        s.variants->scrollT = e.get<float>(2)/1000.0f;
        propagatevslot(s.variants, 1<<VSLOT_SCROLL);
    })

    LUA_BIND_CLIENT(texoffset, {
        if (slots.empty()) return;
        Slot &s = *slots.last();
        s.variants->xoffset = max(e.get<int>(1), 0);
        s.variants->yoffset = max(e.get<int>(2), 0);
        propagatevslot(s.variants, 1<<VSLOT_OFFSET);
    })

    LUA_BIND_CLIENT(texrotate, {
        if (slots.empty()) return;
        Slot &s = *slots.last();
        s.variants->rotation = clamp(e.get<int>(1), 0, 5);
        propagatevslot(s.variants, 1<<VSLOT_ROTATION);
    })

    LUA_BIND_CLIENT(texscale, {
        if(slots.empty()) return;
        Slot &s = *slots.last();
        s.variants->scale = e.get<float>(1) <= 0 ? 1 : e.get<float>(1);
        propagatevslot(s.variants, 1<<VSLOT_SCALE);
    })

    LUA_BIND_CLIENT(texlayer, {
        if (slots.empty()) return;
        Slot &s = *slots.last();

        int layer = e.get<int>(1);
        char *name = e.get<char*>(2);
        float scale = e.get<float>(4);

        s.variants->layer = layer < 0 ? max(slots.length()-1+layer, 0) : layer;
        s.layermaskname = name ? newstring(path(makerelpath("data", name))) : NULL; 
        s.layermaskmode = e.get<int>(3);
        s.layermaskscale = scale <= 0 ? 1 : scale;
        propagatevslot(s.variants, 1<<VSLOT_LAYER);
    })

    LUA_BIND_CLIENT(texalpha, {
        if (slots.empty()) return;
        Slot &s = *slots.last();
        s.variants->alphafront = clamp(e.get<float>(1), 0.0f, 1.0f);
        s.variants->alphaback = clamp(e.get<float>(2), 0.0f, 1.0f);
        propagatevslot(s.variants, 1<<VSLOT_ALPHA);
    })

    LUA_BIND_CLIENT(texcolor, {
        if (slots.empty()) return;
        Slot &s = *slots.last();
        s.variants->colorscale = vec(clamp(e.get<float>(1), 0.0f, 1.0f),
                                     clamp(e.get<float>(2), 0.0f, 1.0f),
                                     clamp(e.get<float>(3), 0.0f, 1.0f));
        propagatevslot(s.variants, 1<<VSLOT_COLOR);
    })

    LUA_BIND_CLIENT(texffenv, {
        if (slots.empty()) return;
        Slot &s = *slots.last();
        s.ffenv = (e.get<int>(1) > 0);
    })

    LUA_BIND_STD_CLIENT(reloadtex, reloadtex, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(gendds, gendds, e.get<char*>(1), e.get<char*>(2))

    // TODO: REMOVE
    #define readwritetex(t, s, body) \
    { \
        uchar *dstrow = t.data; \
        uchar *srcrow = s.data; \
        loop(y, t.h) \
        { \
            for(uchar *dst = dstrow, *src = srcrow, *end = &srcrow[s.w*s.bpp]; src < end; dst += t.bpp, src += s.bpp) \
            { \
                body; \
            } \
            dstrow += t.pitch; \
            srcrow += s.pitch; \
        } \
    }

    #define read2writetex(t, s1, src1, s2, src2, body) \
    { \
        uchar *dstrow = t.data; \
        uchar *src1row = s1.data; \
        uchar *src2row = s2.data; \
        loop(y, t.h) \
        { \
            for(uchar *dst = dstrow, *end = &dstrow[t.w*t.bpp], *src1 = src1row, *src2 = src2row; dst < end; dst += t.bpp, src1 += s1.bpp, src2 += s2.bpp) \
            { \
                body; \
            } \
            dstrow += t.pitch; \
            src1row += s1.pitch; \
            src2row += s2.pitch; \
        } \
    }

    LUA_BIND_CLIENT(flipnormalmapy, {
        ImageData ns;
        if(!loadimage(e.get<char*>(2), ns)) return;
        ImageData d(ns.w, ns.h, 3);
        readwritetex(d, ns,
            dst[0] = src[0];
            dst[1] = 255 - src[1];
            dst[2] = src[2];
        );
        saveimage(e.get<char*>(1), guessimageformat(e.get<char*>(1), IMG_TGA), d);
    })

    LUA_BIND_CLIENT(mergenormalmaps, {
        char *normalfile = e.get<char*>(2);
        ImageData hs;
        ImageData ns;

        if(!loadimage(e.get<char*>(1), hs) || !loadimage(normalfile, ns) || hs.w != ns.w || hs.h != ns.h) return;
        ImageData d(ns.w, ns.h, 3);
        read2writetex(d, hs, srch, ns, srcn,
            *(bvec *)dst = bvec(((bvec *)srcn)->tovec().mul(2).add(((bvec *)srch)->tovec()).normalize());
        );
        saveimage(normalfile, guessimageformat(normalfile, IMG_TGA), d);
    })

}
