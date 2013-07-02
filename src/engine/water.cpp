#include "engine.h"

#define NUMCAUSTICS 32

static Texture *caustictex[NUMCAUSTICS] = { NULL };

void loadcaustics(bool force)
{
    static bool needcaustics = false;
    if(force) needcaustics = true;
    if(!caustics || !needcaustics) return;
    useshaderbyname("caustics");
    if(caustictex[0]) return;
    loopi(NUMCAUSTICS)
    {
        /* OF */
        defformatstring(name, "<grey>media/texture/mat_water/caustic/caust%.2d", i);
        caustictex[i] = textureload(name);
    }
}

void cleanupcaustics()
{
    loopi(NUMCAUSTICS) caustictex[i] = NULL;
}

VARFR(causticscale, 0, 50, 10000, preloadwatershaders());
VARFR(causticmillis, 0, 75, 1000, preloadwatershaders());
FVARR(causticcontrast, 0, 0.6f, 2);
FVARR(causticoffset, 0, 0.7f, 1);
VARFP(caustics, 0, 1, 1, { loadcaustics(); preloadwatershaders(); });

void setupcaustics(int tmu, float surface = -1e16f)
{
    if(!caustictex[0]) loadcaustics(true);

    vec s = vec(0.011f, 0, 0.0066f).mul(100.0f/causticscale), t = vec(0, 0.011f, 0.0066f).mul(100.0f/causticscale);
    int tex = (lastmillis/causticmillis)%NUMCAUSTICS;
    float frac = float(lastmillis%causticmillis)/causticmillis;
    loopi(2)
    {
        glActiveTexture_(GL_TEXTURE0+tmu+i);
        glBindTexture(GL_TEXTURE_2D, caustictex[(tex+i)%NUMCAUSTICS]->id);
    }
    glActiveTexture_(GL_TEXTURE0);
    float blendscale = causticcontrast, blendoffset = 1;
    if(surface > -1e15f)
    {
        float bz = surface + camera1->o.z + (vertwater ? WATER_AMPLITUDE : 0);
        glmatrix m(vec4(s, 0), vec4(t, 0), vec4(0, 0, -1, bz));
        m.mul(worldmatrix);
        GLOBALPARAM(causticsmatrix, m);
        blendscale *= 0.5f;
        blendoffset = 0;
    }
    else
    {
        GLOBALPARAM(causticsS, s);
        GLOBALPARAM(causticsT, t);
    }
    GLOBALPARAMF(causticsblend, blendscale*(1-frac), blendscale*frac, blendoffset - causticoffset*blendscale);
}

void rendercaustics(float surface, float syl, float syr)
{
    if(!caustics || !causticscale || !causticmillis) return;
    glBlendFunc(GL_DST_COLOR, GL_SRC_COLOR);
    setupcaustics(0, surface);
    SETSHADER(caustics);
    gle::defvertex(2);
    gle::begin(GL_TRIANGLE_STRIP);
    gle::attribf(1, -1);
    gle::attribf(-1, -1);
    gle::attribf(1, syr);
    gle::attribf(-1, syl);
    gle::end();
    gle::disable();
}

void renderwaterfog(int mat, float surface)
{
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);

    glActiveTexture_(GL_TEXTURE9);
    if(msaasamples) glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, msdepthtex);
    else glBindTexture(GL_TEXTURE_RECTANGLE, gdepthtex);
    glActiveTexture_(GL_TEXTURE0);

    vec p[4] = 
    {
        invcamprojmatrix.perspectivetransform(vec(-1, -1, -1)),
        invcamprojmatrix.perspectivetransform(vec(-1, 1, -1)),
        invcamprojmatrix.perspectivetransform(vec(1, -1, -1)),
        invcamprojmatrix.perspectivetransform(vec(1, 1, -1))
    }; 
    float bz = surface + camera1->o.z + (vertwater ? WATER_AMPLITUDE : 0),
          syl = p[1].z > p[0].z ? 2*(bz - p[0].z)/(p[1].z - p[0].z) - 1 : 1,
          syr = p[3].z > p[2].z ? 2*(bz - p[2].z)/(p[3].z - p[2].z) - 1 : 1;

    if((mat&MATF_VOLUME) == MAT_WATER)
    {
        const bvec &deepcolor = getwaterdeepcolorv(mat);
        const bvec &deepfadecolor = getwaterdeepfadecolorv(mat);
        int deep = getwaterdeep(mat);
        GLOBALPARAMF(waterdeepcolor, deepcolor.x*ldrscaleb, deepcolor.y*ldrscaleb, deepcolor.z*ldrscaleb);
        ivec deepfade = ivec(deepfadecolor.x, deepfadecolor.y, deepfadecolor.z).mul(deep);
        GLOBALPARAMF(waterdeepfade, deepfade.x ? 255.0f/deepfade.x : 1e4f, deepfade.y ? 255.0f/deepfade.y : 1e4f, deepfade.z ? 255.0f/deepfade.z : 1e4f, deep ? 1.0f/deep : 1e4f);

        rendercaustics(surface, syl, syr);
    }
    else
    {
        GLOBALPARAMF(waterdeepcolor, 0, 0, 0);
        GLOBALPARAMF(waterdeepfade, 0, 0, 0);
    }

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    vec4 d = cammatrix.getrow(2);
    glmatrix m(d, vec4(0, 1, 0, 0), vec4(0, 0, -1, bz));
    m.mul(worldmatrix);
    GLOBALPARAM(waterfogmatrix, m);

    SETSHADER(waterfog);
    gle::defvertex(2);
    gle::begin(GL_TRIANGLE_STRIP);
    gle::attribf(1, -1);
    gle::attribf(-1, -1);
    gle::attribf(1, syr);
    gle::attribf(-1, syl);
    gle::end();
    gle::disable();

    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
}

/* vertex water */
VARP(watersubdiv, 0, 2, 3);
VARP(waterlod, 0, 1, 3);

static int wx1, wy1, wx2, wy2, wsize;
static float whscale, whoffset;

#define VERTW(vertw, defbody, body) \
    static inline void def##vertw() \
    { \
        gle::defvertex(); \
        defbody; \
    } \
    static inline void vertw(float v1, float v2, float v3) \
    { \
        float angle = float((v1-wx1)*(v2-wy1))*float((v1-wx2)*(v2-wy2))*whscale+whoffset; \
        float s = angle - int(angle) - 0.5f; \
        s *= 8 - fabs(s)*16; \
        float h = WATER_AMPLITUDE*s-WATER_OFFSET; \
        gle::attribf(v1, v2, v3+h); \
        body; \
    }
#define VERTWN(vertw, defbody, body) \
    static inline void def##vertw() \
    { \
        gle::defvertex(); \
        defbody; \
    } \
    static inline void vertw(float v1, float v2, float v3) \
    { \
        float h = -WATER_OFFSET; \
        gle::attribf(v1, v2, v3+h); \
        body; \
    }
#define VERTWT(vertwt, defbody, body) \
    VERTW(vertwt, defbody, { \
        float v = angle - int(angle+0.25f) - 0.25f; \
        v *= 8 - fabs(v)*16; \
        float duv = 0.5f*v; \
        body; \
    })

VERTW(vertwt, {
    gle::deftexcoord0();
}, {
    gle::attribf(v1/8.0f, v2/8.0f);
})
VERTWN(vertwtn, {
    gle::deftexcoord0();
}, {
    gle::attribf(v1/8.0f, v2/8.0f);
})

static float lavaxk = 1.0f, lavayk = 1.0f, lavascroll = 0.0f;

VERTW(vertl, {
    gle::deftexcoord0();
}, {
    gle::attribf(lavaxk*(v1+lavascroll), lavayk*(v2+lavascroll));
})
VERTWN(vertln, {
    gle::deftexcoord0();
}, {
    gle::attribf(lavaxk*(v1+lavascroll), lavayk*(v2+lavascroll));
})

#define renderwaterstrips(vertw, z) { \
    def##vertw(); \
    for(int x = wx1; x<wx2; x += subdiv) \
    { \
        gle::begin(GL_TRIANGLE_STRIP); \
        vertw(x,        wy1, z); \
        vertw(x+subdiv, wy1, z); \
        for(int y = wy1; y<wy2; y += subdiv) \
        { \
            vertw(x,        y+subdiv, z); \
            vertw(x+subdiv, y+subdiv, z); \
        } \
        xtraverts += gle::end(); \
    } \
}

void rendervertwater(uint subdiv, int xo, int yo, int z, uint size, int mat)
{   
    wx1 = xo;
    wy1 = yo;
    wx2 = wx1 + size,
    wy2 = wy1 + size;
    wsize = size;
    whscale = 59.0f/(23.0f*wsize*wsize)/(2*M_PI);

    ASSERT((wx1 & (subdiv - 1)) == 0);
    ASSERT((wy1 & (subdiv - 1)) == 0);

    switch(mat)
    {
        case MAT_WATER:
        {
            whoffset = fmod(float(lastmillis/600.0f/(2*M_PI)), 1.0f);
            renderwaterstrips(vertwt, z);
            break;
        }

        case MAT_LAVA:
        {
            whoffset = fmod(float(lastmillis/2000.0f/(2*M_PI)), 1.0f);
            renderwaterstrips(vertl, z);
            break;
        }
    }
}

uint calcwatersubdiv(int x, int y, int z, uint size)
{
    float dist;
    if(camera1->o.x >= x && camera1->o.x < x + size &&
       camera1->o.y >= y && camera1->o.y < y + size)
        dist = fabs(camera1->o.z - float(z));
    else
    {
        vec t(x + size/2, y + size/2, z + size/2);
        dist = t.dist(camera1->o) - size*1.42f/2;
    }
    uint subdiv = watersubdiv + int(dist) / (32 << waterlod);
    if(subdiv >= 8*sizeof(subdiv))
        subdiv = ~0;
    else
        subdiv = 1 << subdiv;
    return subdiv;
}

uint renderwaterlod(int x, int y, int z, uint size, int mat)
{
    if(size <= (uint)(32 << waterlod))
    {
        uint subdiv = calcwatersubdiv(x, y, z, size);
        if(subdiv < size * 2) rendervertwater(min(subdiv, size), x, y, z, size, mat);
        return subdiv;
    }
    else
    {
        uint subdiv = calcwatersubdiv(x, y, z, size);
        if(subdiv >= size)
        {
            if(subdiv < size * 2) rendervertwater(size, x, y, z, size, mat);
            return subdiv;
        }
        uint childsize = size / 2,
             subdiv1 = renderwaterlod(x, y, z, childsize, mat),
             subdiv2 = renderwaterlod(x + childsize, y, z, childsize, mat),
             subdiv3 = renderwaterlod(x + childsize, y + childsize, z, childsize, mat),
             subdiv4 = renderwaterlod(x, y + childsize, z, childsize, mat),
             minsubdiv = subdiv1;
        minsubdiv = min(minsubdiv, subdiv2);
        minsubdiv = min(minsubdiv, subdiv3);
        minsubdiv = min(minsubdiv, subdiv4);
        if(minsubdiv < size * 2)
        {
            if(minsubdiv >= size) rendervertwater(size, x, y, z, size, mat);
            else
            {
                if(subdiv1 >= size) rendervertwater(childsize, x, y, z, childsize, mat);
                if(subdiv2 >= size) rendervertwater(childsize, x + childsize, y, z, childsize, mat);
                if(subdiv3 >= size) rendervertwater(childsize, x + childsize, y + childsize, z, childsize, mat);
                if(subdiv4 >= size) rendervertwater(childsize, x, y + childsize, z, childsize, mat);
            } 
        }
        return minsubdiv;
    }
}

#define renderwaterquad(vertwn, z) \
    { \
        if(gle::data.empty()) { def##vertwn(); gle::begin(GL_QUADS); } \
        vertwn(x, y, z); \
        vertwn(x+rsize, y, z); \
        vertwn(x+rsize, y+csize, z); \
        vertwn(x, y+csize, z); \
        xtraverts += 4; \
    }

void renderflatwater(int x, int y, int z, uint rsize, uint csize, int mat)
{
    switch(mat)
    {
        case MAT_WATER:
            renderwaterquad(vertwtn, z);
            break;

        case MAT_LAVA:
            renderwaterquad(vertln, z);
            break;
    }
}

VARFP(vertwater, 0, 1, 1, allchanged());

static inline void renderwater(const materialsurface &m, int mat = MAT_WATER)
{
    if(!vertwater || drawtex == DRAWTEX_MINIMAP) renderflatwater(m.o.x, m.o.y, m.o.z, m.rsize, m.csize, mat);
    else if(renderwaterlod(m.o.x, m.o.y, m.o.z, m.csize, mat) >= (uint)m.csize * 2)
        rendervertwater(m.csize, m.o.x, m.o.y, m.o.z, m.csize, mat);
}

void renderlava(const materialsurface &m, Texture *tex, float scale)
{
    lavaxk = 8.0f/(tex->xs*scale);
    lavayk = 8.0f/(tex->ys*scale); 
    lavascroll = lastmillis/1000.0f;
    renderwater(m, MAT_LAVA);
}

#define WATERVARS(name) \
    bvec name##colorv(0x01, 0x21, 0x2C), name##deepcolorv(0x01, 0x0A, 0x10), name##deepfadecolorv(0x60, 0xBF, 0xFF), name##refractcolorv(0xFF, 0xFF, 0xFF), name##fallcolorv(0, 0, 0), name##fallrefractcolorv(0xFF, 0xFF, 0xFF); \
    HVARFR(name##color, 0, 0x01212C, 0xFFFFFF, \
    { \
        if(!name##color) name##color = 0x01212C; \
        name##colorv = bvec((name##color>>16)&0xFF, (name##color>>8)&0xFF, name##color&0xFF); \
    }); \
    HVARFR(name##deepcolor, 0, 0x010A10, 0xFFFFFF, \
    { \
        if(!name##deepcolor) name##deepcolor = 0x010A10; \
        name##deepcolorv = bvec((name##deepcolor>>16)&0xFF, (name##deepcolor>>8)&0xFF, name##deepcolor&0xFF); \
    }); \
    HVARFR(name##deepfade, 0, 0x60BFFF, 0xFFFFFF, \
    { \
        if(!name##deepfade) name##deepfade = 0x60BFFF; \
        name##deepfadecolorv = bvec((name##deepfade>>16)&0xFF, (name##deepfade>>8)&0xFF, name##deepfade&0xFF); \
    }); \
    HVARFR(name##refractcolor, 0, 0xFFFFFF, 0xFFFFFF, \
    { \
        if(!name##refractcolor) name##refractcolor = 0xFFFFFF; \
        name##refractcolorv = bvec((name##refractcolor>>16)&0xFF, (name##refractcolor>>8)&0xFF, name##refractcolor&0xFF); \
    }); \
    VARR(name##fog, 0, 30, 10000); \
    VARR(name##deep, 0, 50, 10000); \
    VARR(name##spec, 0, 150, 200); \
    FVARR(name##refract, 0, 0.1f, 1e3f); \
    HVARFR(name##fallcolor, 0, 0, 0xFFFFFF, \
    { \
        name##fallcolorv = bvec((name##fallcolor>>16)&0xFF, (name##fallcolor>>8)&0xFF, name##fallcolor&0xFF); \
    }); \
    HVARFR(name##fallrefractcolor, 0, 0, 0xFFFFFF, \
    { \
        name##fallrefractcolorv = bvec((name##fallrefractcolor>>16)&0xFF, (name##fallrefractcolor>>8)&0xFF, name##fallrefractcolor&0xFF); \
    }); \
    VARR(name##fallspec, 0, 150, 200); \
    FVARR(name##fallrefract, 0, 0.1f, 1e3f);

WATERVARS(water)
WATERVARS(water2)
WATERVARS(water3)
WATERVARS(water4)

GETMATIDXVAR(water, color, int)
GETMATIDXVAR(water, colorv, const bvec &)
GETMATIDXVAR(water, deepcolor, int)
GETMATIDXVAR(water, deepcolorv, const bvec &)
GETMATIDXVAR(water, deepfade, int)
GETMATIDXVAR(water, deepfadecolorv, const bvec &)
GETMATIDXVAR(water, refractcolor, int)
GETMATIDXVAR(water, refractcolorv, const bvec &)
GETMATIDXVAR(water, fallcolor, int)
GETMATIDXVAR(water, fallcolorv, const bvec &)
GETMATIDXVAR(water, fallrefractcolor, int)
GETMATIDXVAR(water, fallrefractcolorv, const bvec &)
GETMATIDXVAR(water, fog, int)
GETMATIDXVAR(water, deep, int)
GETMATIDXVAR(water, spec, int)
GETMATIDXVAR(water, refract, float)
GETMATIDXVAR(water, fallspec, int)
GETMATIDXVAR(water, fallrefract, float)

#define LAVAVARS(name) \
    bvec name##colorv(0xFF, 0x40, 0x00); \
    HVARFR(name##color, 0, 0xFF4000, 0xFFFFFF, \
    { \
        if(!name##color) name##color = 0xFF4000; \
        name##colorv = bvec((name##color>>16)&0xFF, (name##color>>8)&0xFF, name##color&0xFF); \
    }); \
    VARR(name##fog, 0, 50, 10000); \
    FVARR(name##glowmin, 0, 0.25f, 2); \
    FVARR(name##glowmax, 0, 1.0f, 2); \
    VARR(name##spec, 0, 25, 200);

LAVAVARS(lava)
LAVAVARS(lava2)
LAVAVARS(lava3)
LAVAVARS(lava4)

GETMATIDXVAR(lava, color, int)
GETMATIDXVAR(lava, colorv, const bvec &)
GETMATIDXVAR(lava, fog, int)
GETMATIDXVAR(lava, glowmin, float)
GETMATIDXVAR(lava, glowmax, float)
GETMATIDXVAR(lava, spec, int)

VARFP(waterreflect, 0, 1, 1, { preloadwatershaders(); });
VARR(waterreflectstep, 1, 32, 10000);
VARFP(waterenvmap, 0, 1, 1, { preloadwatershaders(); });
VARFP(waterfallenv, 0, 1, 1, preloadwatershaders());

void preloadwatershaders(bool force)
{
    static bool needwater = false;
    if(force) needwater = true;
    if(!needwater) return;

    if(caustics && causticscale && causticmillis)
    {
        if(waterreflect) useshaderbyname("waterreflectcaustics");
        else if(waterenvmap) useshaderbyname("waterenvcaustics");
        else useshaderbyname("watercaustics");
    }
    else
    {
        if(waterreflect) useshaderbyname("waterreflect");
        else if(waterenvmap) useshaderbyname("waterenv");
        else useshaderbyname("water");
    }

    useshaderbyname("underwater");

    if(waterfallenv) useshaderbyname("waterfallenv");
    useshaderbyname("waterfall");

    useshaderbyname("waterfog");

    useshaderbyname("waterminimap");
}

static float wfwave, wfscroll, wfxscale, wfyscale;

static void renderwaterfall(const materialsurface &m, float offset, const vec *normal = NULL)
{
    if(gle::data.empty())
    {
        gle::defvertex();
        if(normal) gle::defnormal();
        gle::deftexcoord0();
        gle::begin(GL_QUADS);
    }
    float x = m.o.x, y = m.o.y, zmin = m.o.z, zmax = zmin;
    if(m.ends&1) zmin += -WATER_OFFSET-WATER_AMPLITUDE;
    if(m.ends&2) zmax += wfwave;
    int csize = m.csize, rsize = m.rsize;
#define GENFACEORIENT(orient, v0, v1, v2, v3) \
        case orient: v0 v1 v2 v3 break;
#undef GENFACEVERTX
#define GENFACEVERTX(orient, vert, mx,my,mz, sx,sy,sz) \
            { \
                vec v(mx sx, my sy, mz sz); \
                gle::attribf(v.x, v.y, v.z); \
                GENFACENORMAL \
                gle::attribf(wfxscale*v.y, -wfyscale*(v.z+wfscroll)); \
            }
#undef GENFACEVERTY
#define GENFACEVERTY(orient, vert, mx,my,mz, sx,sy,sz) \
            { \
                vec v(mx sx, my sy, mz sz); \
                gle::attribf(v.x, v.y, v.z); \
                GENFACENORMAL \
                gle::attribf(wfxscale*v.x, -wfyscale*(v.z+wfscroll)); \
            }
#define GENFACENORMAL gle::attribf(n.x, n.y, n.z);
    if(normal)
    {
        vec n = *normal;
        switch(m.orient) { GENFACEVERTSXY(x, x, y, y, zmin, zmax, /**/, + csize, /**/, + rsize, + offset, - offset) }
    }
#undef GENFACENORMAL
#define GENFACENORMAL
    else switch(m.orient) { GENFACEVERTSXY(x, x, y, y, zmin, zmax, /**/, + csize, /**/, + rsize, + offset, - offset) }
#undef GENFACENORMAL
#undef GENFACEORIENT
#undef GENFACEVERTX
#define GENFACEVERTX(o,n, x,y,z, xv,yv,zv) GENFACEVERT(o,n, x,y,z, xv,yv,zv)
#undef GENFACEVERTY
#define GENFACEVERTY(o,n, x,y,z, xv,yv,zv) GENFACEVERT(o,n, x,y,z, xv,yv,zv)
}

void renderlava()
{
    loopk(4)
    {
        if(lavasurfs[k].empty() && (drawtex == DRAWTEX_MINIMAP || lavafallsurfs[k].empty())) continue;

        MSlot &lslot = lookupmaterialslot(MAT_LAVA+k);

        SETSHADER(lava);
        float t = lastmillis/2000.0f;
        t -= floor(t);
        t = 1.0f - 2*fabs(t-0.5f);
        t = 0.5f + 0.5f*t;
        float glowmin = getlavaglowmin(k), glowmax = getlavaglowmax(k);
        int spec = getlavaspec(k);
        LOCALPARAMF(lavaglow, 0.5f*(glowmin + (glowmax-glowmin)*t));
        LOCALPARAMF(lavaspec, 0.5f*spec/100.0f);

        if(lavasurfs[k].length())
        {
            Texture *tex = lslot.sts.inrange(0) ? lslot.sts[0].t: notexture;
            glBindTexture(GL_TEXTURE_2D, tex->id);
            glActiveTexture_(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, lslot.sts.inrange(1) ? lslot.sts[1].t->id : notexture->id);
            glActiveTexture_(GL_TEXTURE0);

            vector<materialsurface> &surfs = lavasurfs[k];
            loopv(surfs) renderlava(surfs[i], tex, lslot.scale);
            xtraverts += gle::end();
        }

        if(drawtex != DRAWTEX_MINIMAP && lavafallsurfs[k].length())
        {
            Texture *tex = lslot.sts.inrange(2) ? lslot.sts[2].t : (lslot.sts.inrange(0) ? lslot.sts[0].t : notexture);
            float angle = fmod(float(lastmillis/2000.0f/(2*M_PI)), 1.0f),
                  s = angle - int(angle) - 0.5f;
            s *= 8 - fabs(s)*16;
            wfwave = vertwater ? WATER_AMPLITUDE*s-WATER_OFFSET : -WATER_OFFSET;
            wfscroll = 16.0f*lastmillis/3000.0f;
            wfxscale = TEX_SCALE/(tex->xs*lslot.scale);
            wfyscale = TEX_SCALE/(tex->ys*lslot.scale);

            glBindTexture(GL_TEXTURE_2D, tex->id);
            glActiveTexture_(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, lslot.sts.inrange(2) ? (lslot.sts.inrange(3) ? lslot.sts[3].t->id : notexture->id) : (lslot.sts.inrange(1) ? lslot.sts[1].t->id : notexture->id));
            glActiveTexture_(GL_TEXTURE0);

            vector<materialsurface> &surfs = lavafallsurfs[k];
            loopv(surfs) 
            {
                materialsurface &m = surfs[i];
                renderwaterfall(m, 0.1f, &matnormals[m.orient]);
            }
            xtraverts += gle::end();
        }
    }
}

void renderwaterfalls()
{
    loopk(4)
    {
        vector<materialsurface> &surfs = waterfallsurfs[k];
        if(surfs.empty()) continue;

        MSlot &wslot = lookupmaterialslot(MAT_WATER+k);

        Texture *tex = wslot.sts.inrange(2) ? wslot.sts[2].t : (wslot.sts.inrange(0) ? wslot.sts[0].t : notexture);
        float angle = fmod(float(lastmillis/600.0f/(2*M_PI)), 1.0f),
              s = angle - int(angle) - 0.5f;
        s *= 8 - fabs(s)*16;
        wfwave = vertwater ? WATER_AMPLITUDE*s-WATER_OFFSET : -WATER_OFFSET;
        wfscroll = 16.0f*lastmillis/1000.0f;
        wfxscale = TEX_SCALE/(tex->xs*wslot.scale);
        wfyscale = TEX_SCALE/(tex->ys*wslot.scale);
  
        bvec color = getwaterfallcolorv(k), refractcolor = getwaterfallrefractcolorv(k);
        if(color.iszero()) color = getwatercolorv(k);
        if(refractcolor.iszero()) refractcolor = getwaterrefractcolorv(k);
        float colorscale = (0.5f/255), refractscale = colorscale/ldrscale;
        float refract = getwaterfallrefract(k);
        int spec = getwaterfallspec(k);
        GLOBALPARAMF(waterfallcolor, color.x*colorscale, color.y*colorscale, color.z*colorscale);
        GLOBALPARAMF(waterfallrefract, refractcolor.x*refractscale, refractcolor.y*refractscale, refractcolor.z*refractscale, refract*viewh);
        GLOBALPARAMF(waterfallspec, 0.5f*spec/100.0f);
 
        if(waterfallenv) SETSHADER(waterfallenv);
        else SETSHADER(waterfall);
 
        glBindTexture(GL_TEXTURE_2D, tex->id);
        glActiveTexture_(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, wslot.sts.inrange(2) ? (wslot.sts.inrange(3) ? wslot.sts[3].t->id : notexture->id) : (wslot.sts.inrange(1) ? wslot.sts[1].t->id : notexture->id));
        if(waterfallenv)
        {
            glActiveTexture_(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_CUBE_MAP, lookupenvmap(wslot));
        }
        glActiveTexture_(GL_TEXTURE0);

        loopv(surfs) 
        {
            materialsurface &m = surfs[i];
            renderwaterfall(m, 0.1f, &matnormals[m.orient]);
        }
        xtraverts += gle::end();
    }
}

void renderwater()
{
    loopk(4)
    {
        vector<materialsurface> &surfs = watersurfs[k];
        if(surfs.empty()) continue;

        MSlot &wslot = lookupmaterialslot(MAT_WATER+k);

        glBindTexture(GL_TEXTURE_2D, wslot.sts.inrange(0) ? wslot.sts[0].t->id : notexture->id);
        glActiveTexture_(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, wslot.sts.inrange(1) ? wslot.sts[1].t->id : notexture->id);
        if(caustics && causticscale && causticmillis) setupcaustics(2);
        if(waterenvmap && !waterreflect && drawtex != DRAWTEX_MINIMAP)
        {
            glActiveTexture_(GL_TEXTURE4);
            glBindTexture(GL_TEXTURE_CUBE_MAP, lookupenvmap(wslot));
        }
        glActiveTexture_(GL_TEXTURE0);

        float colorscale = 0.5f/255, refractscale = colorscale/ldrscale, reflectscale = 0.5f/ldrscale;
        const bvec &color = getwatercolorv(k);
        const bvec &deepcolor = getwaterdeepcolorv(k);
        const bvec &deepfadecolor = getwaterdeepfadecolorv(k);
        const bvec &refractcolor = getwaterrefractcolorv(k);
        int fog = getwaterfog(k), deep = getwaterdeep(k), spec = getwaterspec(k);
        float refract = getwaterrefract(k);
        GLOBALPARAMF(watercolor, color.x*colorscale, color.y*colorscale, color.z*colorscale);
        GLOBALPARAMF(waterdeepcolor, deepcolor.x*colorscale, deepcolor.y*colorscale, deepcolor.z*colorscale);
        GLOBALPARAMF(waterfog, fog ? 1.0f/fog : 1e4f);
        ivec deepfade = ivec(deepfadecolor.x, deepfadecolor.y, deepfadecolor.z).mul(deep);
        GLOBALPARAMF(waterdeepfade, deepfade.x ? 255.0f/deepfade.x : 1e4f, deepfade.y ? 255.0f/deepfade.y : 1e4f, deepfade.z ? 255.0f/deepfade.z : 1e4f, deep ? 1.0f/deep : 1e4f);
        GLOBALPARAMF(waterspec, 0.5f*spec/100.0f);
        GLOBALPARAMF(waterreflect, reflectscale, reflectscale, reflectscale, waterreflectstep);
        GLOBALPARAMF(waterrefract, refractcolor.x*refractscale, refractcolor.y*refractscale, refractcolor.z*refractscale, refract*viewh);

        #define SETWATERSHADER(which, name) \
        do { \
            static Shader *name##shader = NULL; \
            if(!name##shader) name##shader = lookupshaderbyname(#name); \
            which##shader = name##shader; \
        } while(0)

        Shader *aboveshader = NULL;
        if(drawtex == DRAWTEX_MINIMAP) SETWATERSHADER(above, waterminimap);
        else if(caustics && causticscale && causticmillis)
        {
            if(waterreflect) SETWATERSHADER(above, waterreflectcaustics);
            else if(waterenvmap) SETWATERSHADER(above, waterenvcaustics);
            else SETWATERSHADER(above, watercaustics);
        }
        else
        {
            if(waterreflect) SETWATERSHADER(above, waterreflect);
            else if(waterenvmap) SETWATERSHADER(above, waterenv);
            else SETWATERSHADER(above, water);
        }

        Shader *belowshader = NULL;
        if(drawtex != DRAWTEX_MINIMAP) SETWATERSHADER(below, underwater);

        aboveshader->set();
        loopv(surfs)
        {
            materialsurface &m = surfs[i];
            if(camera1->o.z < m.o.z - WATER_OFFSET) continue;
            renderwater(m);
        }
        xtraverts += gle::end();

        if(belowshader)
        {
            belowshader->set();
            loopv(surfs)
            {
                materialsurface &m = surfs[i];
                if(camera1->o.z >= m.o.z - WATER_OFFSET) continue;
                renderwater(m);
            }
            xtraverts += gle::end();
        }
    }
}

