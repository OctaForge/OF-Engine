#ifdef CLIENT
void filltexlist();
#endif
namespace lapi_binds
{
#ifdef CLIENT
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

        vec2 tc[4] = { vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 1) };
        int xoff = vslot.offset.x, yoff = vslot.offset.y;
        if (vslot.rotation)
        {
            if ((vslot.rotation&5) == 1) { swap(xoff, yoff); loopk(4) swap(tc[k].x, tc[k].y); }
            if (vslot.rotation >= 2 && vslot.rotation <= 4) { xoff *= -1; loopk(4) tc[k].x *= -1; }
            if (vslot.rotation <= 2 || vslot.rotation == 5) { yoff *= -1; loopk(4) tc[k].y *= -1; }
        }
        loopk(4) { tc[k].x = tc[k].x/xt - float(xoff)/tex->xs; tc[k].y = tc[k].y/yt - float(yoff)/tex->ys; }
        varray::color(slot.loaded ? vslot.colorscale : vec(1, 1, 1));
        glBindTexture(GL_TEXTURE_2D, tex->id);
        varray::defvertex(2);
        varray::deftexcoord0();
        varray::begin(GL_TRIANGLE_STRIP);
        varray::attribf(sx,     sy);     varray::attrib(tc[0]);
        varray::attribf(sx + w, sy);     varray::attrib(tc[1]);
        varray::attribf(sx,     sy + h); varray::attrib(tc[3]);
        varray::attribf(sx + w, sy + h); varray::attrib(tc[2]);
        varray::end();

        if (glowtex)
        {
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            glBindTexture(GL_TEXTURE_2D, glowtex->id);
            varray::color(vslot.glowcolor);
            varray::begin(GL_TRIANGLE_STRIP);
            varray::attribf(sx,     sy);     varray::attrib(tc[0]);
            varray::attribf(sx + w, sy);     varray::attrib(tc[1]);
            varray::attribf(sx,     sy + h); varray::attrib(tc[3]);
            varray::attribf(sx + w, sy + h); varray::attrib(tc[2]);
            varray::end();
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
        if (layertex)
        {
            glBindTexture(GL_TEXTURE_2D, layertex->id);
            varray::color(layer->colorscale);
            varray::begin(GL_TRIANGLE_STRIP);
            varray::attribf(sx + w / 2, sy + h / 2); varray::attrib(tc[0]);
            varray::attribf(sx + w,     sy + h / 2); varray::attrib(tc[1]);
            varray::attribf(sx + w / 2, sy + h);     varray::attrib(tc[3]);
            varray::attribf(sx + w,     sy + h);     varray::attrib(tc[2]);
            varray::end();
        }

        varray::color(vec(1, 1, 1));
        hudshader->set();
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
    LAPI_EMPTY(parsepixels)
    LAPI_EMPTY(filltexlist)
    LAPI_EMPTY(getnumslots)
    LAPI_EMPTY(hastexslot)
    LAPI_EMPTY(checkvslot)
    LAPI_EMPTY(texture_draw_slot)
#endif

    void reg_tex(lua::Table& t)
    {
        LAPI_REG(parsepixels);
        LAPI_REG(filltexlist);
        LAPI_REG(getnumslots);
        LAPI_REG(hastexslot);
        LAPI_REG(checkvslot);
        LAPI_REG(texture_draw_slot);
    }
}
