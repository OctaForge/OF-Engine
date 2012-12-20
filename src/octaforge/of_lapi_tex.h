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

extern int nompedit, worldsize;
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
        if (!varsys::overridevars && !game::allowedittoggle()) return;
        loopi((MATF_VOLUME|MATF_INDEX)+1) materialslots[i].reset();
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
        s.autograss = ((g && g[0]) ? newstring(makerelpath("data", g)) : NULL);
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

    void _lua_texlayer(int layer)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->layer = ((layer < 0) ? max(
            (slots.length() - 1 + layer), 0
        ) : layer);
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

    void _lua_texrefract(float k, float r, float g, float b)
    {
        if (slots.empty()) return;
        Slot& s = *slots.last();

        s.variants->refractscale = clamp(k, 0.0f, 1.0f);
        if (s.variants->refractscale > 0 && (r > 0 || g > 0 || b > 0))
            s.variants->refractcolor = vec(clamp(r, 0.0f, 1.0f),
                                           clamp(g, 0.0f, 1.0f),
                                           clamp(b, 0.0f, 1.0f));
        else
            s.variants->refractcolor = vec(1, 1, 1);
        propagatevslot(s.variants, 1 << VSLOT_REFRACT);
    }

    void _lua_reloadtex(const char *name)
    {
        reloadtex((char*)name);
    }

    void _lua_gendds(const char *in, const char *out)
    {
        gendds((char*)in, (char*)out);
    }

    void _lua_flipnormalmapy(const char *dst, const char *nst) // jpg/png/tga-> tga
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

#define readwritetex(t, s, body) \
    { \
        uchar *dstrow = t.data, *srcrow = s.data; \
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

    // jpg/png/tga-> tga
    void _lua_normalizenormalmap(const char *destfile, const char *normalfile)
    {
        ImageData ns;
        if(!loadimage(normalfile, ns)) return;
        ImageData d(ns.w, ns.h, 3);
        readwritetex(d, ns,
            *(bvec *)dst = bvec(src[0], src[1], src[2]).normalize();
        );
        saveimage(destfile, guessimageformat(destfile, IMG_TGA), d);
    }

    void _lua_removealphachannel(const char *destfile, const char *rgbafile)
    {
        ImageData ns;
        if(!loadimage(rgbafile, ns)) return;
        ImageData d(ns.w, ns.h, 3);
        readwritetex(d, ns,
            dst[0] = src[0];
            dst[1] = src[1];
            dst[2] = src[2];
        );
        saveimage(destfile, guessimageformat(destfile, IMG_TGA), d);
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

    bool _lua_hastexslot(int slotnum) { return texmru.inrange(slotnum); }
    bool _lua_checkvslot(int slotnum)
    {
        VSlot &vslot = lookupvslot(texmru[slotnum], false);
        if(vslot.slot->sts.length() && (vslot.slot->loaded || vslot.slot->thumbnail))
            return true;

        return false;
    }

    VAR(thumbtime, 0, 25, 1000);
    static int lastthumbnail = 0;

    void drawslot(Slot &slot, VSlot &vslot, float w, float h, float sx, float sy)
    {
        Texture *tex = notexture, *glowtex = NULL, *layertex = NULL;
        VSlot *layer = NULL;
        if (slot.loaded)
        {
            tex = slot.sts[0].t;
            if(slot.texmask&(1<<TEX_GLOW)) {
                loopv(slot.sts) if(slot.sts[i].type==TEX_GLOW)
                { glowtex = slot.sts[i].t; break; }
            }
            if (vslot.layer)
            {
                layer = &lookupvslot(vslot.layer);
                if(!layer->slot->sts.empty())
                    layertex = layer->slot->sts[0].t;
            }
        }
        else if (slot.thumbnail) tex = slot.thumbnail;
        float xt, yt;
        xt = min(1.0f, tex->xs/(float)tex->ys),
        yt = min(1.0f, tex->ys/(float)tex->xs);

        static Shader *rgbonlyshader = NULL;
        if (!rgbonlyshader) rgbonlyshader = lookupshaderbyname("rgbonly");
        rgbonlyshader->set();

        float tc[4][2] = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 0, 1 } };
        int xoff = vslot.xoffset, yoff = vslot.yoffset;
        if (vslot.rotation)
        {
            if ((vslot.rotation&5) == 1) { swap(xoff, yoff); loopk(4) swap(tc[k][0], tc[k][1]); }
            if (vslot.rotation >= 2 && vslot.rotation <= 4) { xoff *= -1; loopk(4) tc[k][0] *= -1; }
            if (vslot.rotation <= 2 || vslot.rotation == 5) { yoff *= -1; loopk(4) tc[k][1] *= -1; }
        }
        loopk(4) { tc[k][0] = tc[k][0]/xt - float(xoff)/tex->xs; tc[k][1] = tc[k][1]/yt - float(yoff)/tex->ys; }
        if(slot.loaded) glColor3fv(vslot.colorscale.v);
        glBindTexture(GL_TEXTURE_2D, tex->id);
        glBegin(GL_TRIANGLE_STRIP);
        glTexCoord2fv(tc[0]); glVertex2f(sx,   sy);
        glTexCoord2fv(tc[1]); glVertex2f(sx+w, sy);
        glTexCoord2fv(tc[3]); glVertex2f(sx,   sy+h);
        glTexCoord2fv(tc[2]); glVertex2f(sx+w, sy+h);
        glEnd();

        if (glowtex)
        {
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            glBindTexture(GL_TEXTURE_2D, glowtex->id);
            glColor3fv(vslot.glowcolor.v);
            glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2fv(tc[0]); glVertex2f(sx,   sy);
            glTexCoord2fv(tc[1]); glVertex2f(sx+w, sy);
            glTexCoord2fv(tc[3]); glVertex2f(sx,   sy+h);
            glTexCoord2fv(tc[2]); glVertex2f(sx+w, sy+h);
            glEnd();
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
        if (layertex)
        {
            glBindTexture(GL_TEXTURE_2D, layertex->id);
            glColor3fv(layer->colorscale.v);
            glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2fv(tc[0]); glVertex2f(sx+w/2, sy+h/2);
            glTexCoord2fv(tc[1]); glVertex2f(sx+w,   sy+h/2);
            glTexCoord2fv(tc[3]); glVertex2f(sx+w/2, sy+h);
            glTexCoord2fv(tc[2]); glVertex2f(sx+w,   sy+h);
            glEnd();
        }
        glColor3f(1, 1, 1);

        defaultshader->set();
    }

    void _lua_texture_draw_slot(
        int slotnum, float w, float h, float sx, float sy
    )
    {
        if (texmru.inrange(slotnum))
        {
            VSlot &vslot = lookupvslot(texmru[slotnum], false);
            Slot &slot = *vslot.slot;
            if (slot.sts.length())
            {
                if(slot.loaded || slot.thumbnail)
                    drawslot(slot, vslot, w, h, sx, sy);

                else if (totalmillis-lastthumbnail >= thumbtime)
                {
                    loadthumbnail(slot);
                    lastthumbnail = totalmillis;
                }
            }
        }
    }

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
    LAPI_EMPTY(texrefract)
    LAPI_EMPTY(reloadtex)
    LAPI_EMPTY(gendds)
    LAPI_EMPTY(flipnormalmapy)
    LAPI_EMPTY(normalizenormalmap)
    LAPI_EMPTY(removealphachannel)
    LAPI_EMPTY(mergenormalmaps)
    LAPI_EMPTY(parsepixels)
    LAPI_EMPTY(filltexlist)
    LAPI_EMPTY(getnumslots)
    LAPI_EMPTY(hastexslot)
    LAPI_EMPTY(checkvslot)
    LAPI_EMPTY(texture_draw_slot)
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
        LAPI_REG(texrefract);
        LAPI_REG(reloadtex);
        LAPI_REG(gendds);
        LAPI_REG(flipnormalmapy);
        LAPI_REG(normalizenormalmap);
        LAPI_REG(removealphachannel);
        LAPI_REG(mergenormalmaps);
        LAPI_REG(parsepixels);
        LAPI_REG(filltexlist);
        LAPI_REG(getnumslots);
        LAPI_REG(hastexslot);
        LAPI_REG(checkvslot);
        LAPI_REG(texture_draw_slot);
    }
}
