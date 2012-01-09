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

void filltexlist();

extern int& nompedit, &worldsize;
#endif
namespace lapi_binds
{
#ifdef CLIENT
    void _lua_texturereset() { texturereset(0); }

    void _lua_texture(
        const char *t, const char *n, int r, int xo, int yo, float s, int fi
    )
    {
        texture(t ? t : "", n ? n : "", r, xo, yo, (s ? s : 1.0f), fi);
    }

    void _lua_materialreset()
    {
        if (!var::overridevars && !game::allowedittoggle()) return;
        loopi(MATF_VOLUME + 1) materialslots[i].reset();
    }

    void _lua_compactvslots()
    {
        if (nompedit && multiplayer()) return;
        compactvslots();
        allchanged   ();
    }

    void _lua_fixinsidefaces(int tex)
    {
        if (noedit(true) || (nompedit && multiplayer())) return;
        fixinsidefaces(
            worldroot, ivec(0, 0, 0), (worldsize >> 1),
            (tex && vslots.inrange(tex)) ? tex : DEFAULT_GEOM
        );
        allchanged();
    }

    void _lua_autograss(const char *g)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        delete[] s.autograss;
        s.autograss = ((g && g[0]) ? newstring(
            makerelpath("data", g, NULL, "<ffskip><premul>")
        ) : NULL);
    }

    void _lua_texscroll(float ss, float ts)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->scrollS = ss / 1000.0f;
        s.variants->scrollT = ts / 1000.0f;
        propagatevslot(s.variants, 1 << VSLOT_SCROLL);
    }

    void _lua_texoffset(int x, int y)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->xoffset = max(x, 0);
        s.variants->yoffset = max(y, 0);
        propagatevslot(s.variants, 1 << VSLOT_OFFSET);
    }

    void _lua_texrotate(int r)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->rotation = clamp(r, 0, 5);
        propagatevslot(s.variants, 1 << VSLOT_ROTATION);
    }

    void _lua_texscale(float sc)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->scale = ((sc <= 0) ? 1.0f : sc);
        propagatevslot(s.variants, 1 << VSLOT_SCALE);
    }

    void _lua_texlayer(int layer, const char *name, int lmm, float scale)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->layer = ((layer < 0) ? max(
            (slots.length() - 1 + layer), 0
        ) : layer);
        s.layermaskname = ((name && name[0]) ? newstring(
            path(makerelpath("data", name))
        ) : NULL);
        s.layermaskmode  = lmm;
        s.layermaskscale = ((scale <= 0) ? 1.0f : scale);
        propagatevslot(s.variants, 1 << VSLOT_LAYER);
    }

    void _lua_texalpha(float f, float b)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->alphafront = clamp(f, 0.0f, 1.0f);
        s.variants->alphaback  = clamp(b, 0.0f, 1.0f);
        propagatevslot(s.variants, 1 << VSLOT_ALPHA);
    }

    void _lua_texcolor(float r, float g, float b)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->colorscale = vec(
            clamp(r, 0.0f, 1.0f),
            clamp(g, 0.0f, 1.0f),
            clamp(b, 0.0f, 1.0f)
        );
        propagatevslot(s.variants, 1 << VSLOT_COLOR);
    }

    void _lua_texffenv(bool ffenv)
    {
        if (slots.empty()) return;
        slots.last()->ffenv = ffenv;
    }

    void _lua_reloadtex(const char *name)
    {
        reloadtex((char*)name);
    }

    void _lua_gendds(const char *in, const char *out)
    {
        gendds((char*)in, (char*)out);
    }

    void _lua_flipnormalmapy(const char *dst, const char *nst)
    {
        if (!dst) dst = "";
        if (!nst) nst = "";
        ImageData ns;
        if (!loadimage(nst, ns)) return;

        ImageData d(ns.w, ns.h, 3);

        uchar *dstrow =  d.data;
        uchar *srcrow = ns.data;

        loopi(d.h)
        {
            for (
                uchar *dst = dstrow,
                      *src = srcrow,
                      *end = &srcrow[ns.w * ns.bpp];
                src < end;
                dst += d.bpp, src += ns.bpp
            )
            {
                dst[0] = src[0];
                dst[1] = 255 - src[1];
                dst[2] = src[2];
            }
        }

        saveimage(dst, guessimageformat(dst, IMG_TGA), d);
    }

    void _lua_mergenormalmaps(const char *h, const char *n)
    {
        if (!h) h = "";
        if (!n) n = "";
        ImageData hs, ns;

        if (
            !loadimage(h, hs) || !loadimage(n, ns)
            || hs.w != ns.w || hs.h != ns.h
        ) return;

        ImageData d(ns.w, ns.h, 3);

        uchar *dstrow  =  d.data;
        uchar *src1row = hs.data;
        uchar *src2row = ns.data;
        loopi(d.h)
        {
            for (
                uchar *dst  = dstrow,
                      *end  = &dstrow[d.w * d.bpp],
                      *srch = src1row,
                      *srcn = src2row;
                dst < end;
                dst += d.bpp, srch += hs.bpp, srcn += ns.bpp
            )
            {
                *(bvec *)dst = bvec(((bvec *)srcn)->tovec().mul(2).add(
                    ((bvec *)srch)->tovec()
                ).normalize());
            }
            dstrow  +=  d.pitch;
            src1row += hs.pitch;
            src2row += ns.pitch;
        }

        saveimage(n, guessimageformat(n, IMG_TGA), d);
    }

    lua::Table _lua_parsepixels(const char *fn)
    {
        if (!fn) fn = "";

        ImageData d;
        if (!loadimage(fn, d)) return lapi::state.wrap<lua::Table>(lua::nil);

        lua::Table ret = lapi::state.new_table(0, 3);
        ret["w"] = d.w;
        ret["h"] = d.h;

        lua::Table    row = lapi::state.new_table(d.w);
        ret["data"] = row;

        for (int x = 0; x < d.w; ++x)
        {
            lua::Table   col = lapi::state.new_table(d.h);
            row[x + 1] = col;

            for (int y = 0; y < d.h; ++y)
            {
                uchar *p = d.data + y * d.pitch + x * d.bpp;

                Uint32 ret;
                switch (d.bpp)
                {
                    case 1:
                        ret = *p;
                        break;
                    case 2:
                        ret = *(Uint16*)p;
                        break;
                    case 3:
                        if (SDL_BYTEORDER == SDL_BIG_ENDIAN)
                            ret = (p[0] << 16 | p[1] << 8 | p[2]);
                        else
                            ret = (p[0] | p[1] << 8 | p[2] << 16);
                        break;
                    case 4:
                        ret = *(Uint32*)p;
                        break;
                    default:
                        ret = 0;
                        break;
                }

                uchar r, g, b;
                SDL_GetRGB(ret, ((SDL_Surface*)d.owner)->format, &r, &g, &b);

                lua::Table px = lapi::state.new_table(0, 3);
                px["r"   ] = (uint)r;
                px["g"   ] = (uint)g;
                px["b"   ] = (uint)b;
                col[y + 1] = px;
            }
        }

        return ret;
    }

    void _lua_filltexlist() { filltexlist        (); }
    int  _lua_getnumslots() { return slots.length(); }
#else
    LAPI_EMPTY(texturereset)
    LAPI_EMPTY(texture)
    LAPI_EMPTY(materialreset)
    LAPI_EMPTY(compactvslots)
    LAPI_EMPTY(fixinsidefaces)
    LAPI_EMPTY(autograss)
    LAPI_EMPTY(texscroll)
    LAPI_EMPTY(texoffset)
    LAPI_EMPTY(texrotate)
    LAPI_EMPTY(texscale)
    LAPI_EMPTY(texlayer)
    LAPI_EMPTY(texalpha)
    LAPI_EMPTY(texcolor)
    LAPI_EMPTY(texffenv)
    LAPI_EMPTY(reloadtex)
    LAPI_EMPTY(gendds)
    LAPI_EMPTY(flipnormalmapy)
    LAPI_EMPTY(mergenormalmaps)
    LAPI_EMPTY(parsepixels)
    LAPI_EMPTY(filltexlist)
    LAPI_EMPTY(getnumslots)
#endif

    void reg_tex(lua::Table& t)
    {
        LAPI_REG(texturereset);
        LAPI_REG(texture);
        LAPI_REG(materialreset);
        LAPI_REG(compactvslots);
        LAPI_REG(fixinsidefaces);
        LAPI_REG(autograss);
        LAPI_REG(texscroll);
        LAPI_REG(texoffset);
        LAPI_REG(texrotate);
        LAPI_REG(texscale);
        LAPI_REG(texlayer);
        LAPI_REG(texalpha);
        LAPI_REG(texcolor);
        LAPI_REG(texffenv);
        LAPI_REG(reloadtex);
        LAPI_REG(gendds);
        LAPI_REG(flipnormalmapy);
        LAPI_REG(mergenormalmaps);
        LAPI_REG(parsepixels);
        LAPI_REG(filltexlist);
        LAPI_REG(getnumslots);
    }
}
