#include "engine.h"

#define MAXLIGHTMAPTASKS 4096
#define LIGHTMAPBUFSIZE (2*1024*1024)

struct lightmapinfo;
struct lightmaptask;

struct lightmapworker
{
    uchar *buf;
    int bufstart, bufused;
    lightmapinfo *firstlightmap, *lastlightmap, *curlightmaps;
    cube *c;
    uchar *colorbuf;
    bvec *raybuf;
    uchar mincolor[4], maxcolor[4];
    uchar *ambient, *blur;
    vec *colordata, *raydata;
    int type, bpp, w, h, orient, rotate;
    VSlot *vslot;
    Slot *slot;
    vector<const extentity *> lights1, lights2;
    ShadowRayCache *shadowraycache;
    BlendMapCache *blendmapcache;
    bool needspace, doneworking;
    SDL_cond *spacecond;
    SDL_Thread *thread;

    lightmapworker();
    ~lightmapworker();

    void reset();
    bool setupthread();
    void cleanupthread();

    static int work(void *data);
};

struct lightmapinfo
{
    lightmapinfo *next;
    cube *c;
    uchar *colorbuf;
    bvec *raybuf;
    bool packed;
    int type, bpp, bufsize, surface1, surface2;
};

struct lightmaptask
{
    ivec o;
    int size, vertused, usefaces, progress;
    cube *c;
    lightmapinfo *lightmaps;
    lightmapworker *worker;
};

static vector<lightmapworker *> lightmapworkers;
static vector<lightmaptask> lightmaptasks[2];
static int packidx = 0, allocidx = 0;
static SDL_mutex *lightlock = NULL, *tasklock = NULL;
static SDL_cond *fullcond = NULL, *emptycond = NULL;

int lightmapping = 0;

vector<LightMap> lightmaps;

bvec ambientcolor(0x19, 0x19, 0x19), skylightcolor(0, 0, 0);

static surfaceinfo brightsurfaces[6] =
{
    {{0}, 0, 0, 0, 0, LMID_BRIGHT, LAYER_TOP},
    {{0}, 0, 0, 0, 0, LMID_BRIGHT, LAYER_TOP},
    {{0}, 0, 0, 0, 0, LMID_BRIGHT, LAYER_TOP},
    {{0}, 0, 0, 0, 0, LMID_BRIGHT, LAYER_TOP},
    {{0}, 0, 0, 0, 0, LMID_BRIGHT, LAYER_TOP},
    {{0}, 0, 0, 0, 0, LMID_BRIGHT, LAYER_TOP},
};

// quality parameters, set by the calclight arg
static int lmshadows = 2, lmaa = 3;

static uint progress = 0, taskprogress = 0;
static GLuint progresstex = 0;
static int progresstexticks = 0, progresslightmap = -1;

bool calclight_canceled = false;
volatile bool check_calclight_progress = false;

void check_calclight_canceled()
{
    if(interceptkey(SDLK_ESCAPE)) 
    {
        calclight_canceled = true;
        loopv(lightmapworkers) lightmapworkers[i]->doneworking = true;
    }
    if(!calclight_canceled) check_calclight_progress = false;
}

void show_calclight_progress()
{
    float bar1 = float(progress) / float(allocnodes);
    defformatstring(text1)("%d%% using %d textures", int(bar1 * 100), lightmaps.length());

    if(LM_PACKW <= GETIV(hwtexsize) && !progresstex)
    {
        glGenTextures(1, &progresstex);
        createtexture(progresstex, LM_PACKW, LM_PACKH, NULL, 3, 1, GL_RGB);
    }

    // only update once a sec (4 * 250 ms ticks) to not kill performance
    if(progresstex && !calclight_canceled && progresslightmap >= 0 && !(progresstexticks++ % 4)) 
    {
        if(tasklock) SDL_LockMutex(tasklock);
        LightMap &lm = lightmaps[progresslightmap];
        uchar *data = lm.data;
        int bpp = lm.bpp;
        if(tasklock) SDL_UnlockMutex(tasklock);
        glBindTexture(GL_TEXTURE_2D, progresstex);
        glPixelStorei(GL_UNPACK_ALIGNMENT, texalign(data, LM_PACKW, bpp));
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, LM_PACKW, LM_PACKH, bpp > 3 ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, data);
    }
    renderprogress(bar1, text1, progresstexticks ? progresstex : 0);
}

#define CHECK_PROGRESS_LOCKED(exit, before, after) CHECK_CALCLIGHT_PROGRESS_LOCKED(exit, show_calclight_progress, before, after)
#define CHECK_PROGRESS(exit) CHECK_PROGRESS_LOCKED(exit, , )

bool PackNode::insert(ushort &tx, ushort &ty, ushort tw, ushort th)
{
    if((available < tw && available < th) || w < tw || h < th)
        return false;
    if(child1)
    {
        bool inserted = child1->insert(tx, ty, tw, th) ||
                        child2->insert(tx, ty, tw, th);
        available = max(child1->available, child2->available);
        if(!available) clear();
        return inserted;    
    }
    if(w == tw && h == th)
    {
        available = 0;
        tx = x;
        ty = y;
        return true;
    }
    
    if(w - tw > h - th)
    {
        child1 = new PackNode(x, y, tw, h);
        child2 = new PackNode(x + tw, y, w - tw, h);
    }
    else
    {
        child1 = new PackNode(x, y, w, th);
        child2 = new PackNode(x, y + th, w, h - th);
    }

    bool inserted = child1->insert(tx, ty, tw, th);
    available = max(child1->available, child2->available);
    return inserted;
}

bool LightMap::insert(ushort &tx, ushort &ty, uchar *src, ushort tw, ushort th)
{
    if((type&LM_TYPE) != LM_BUMPMAP1 && !packroot.insert(tx, ty, tw, th))
        return false;

    copy(tx, ty, src, tw, th);
    return true;
}

void LightMap::copy(ushort tx, ushort ty, uchar *src, ushort tw, ushort th)
{
    uchar *dst = data + bpp * tx + ty * bpp * LM_PACKW;
    loopi(th)
    {
        memcpy(dst, src, bpp * tw);
        dst += bpp * LM_PACKW;
        src += bpp * tw;
    }
    ++lightmaps;
    lumels += tw * th;
}

static void insertunlit(int i)
{
    LightMap &l = lightmaps[i];
    if((l.type&LM_TYPE) == LM_BUMPMAP1)
    {
        l.unlitx = l.unlity = -1;
        return;
    }
    ushort x, y;
    uchar unlit[4] = { ambientcolor[0], ambientcolor[1], ambientcolor[2], 255 };
    if(l.insert(x, y, unlit, 1, 1))
    {
        if((l.type&LM_TYPE) == LM_BUMPMAP0)
        {
            bvec front(128, 128, 255);
            ASSERT(lightmaps[i+1].insert(x, y, front.v, 1, 1));
        }
        l.unlitx = x;
        l.unlity = y;
    }
}

static void insertlightmap(lightmapinfo &li, surfaceinfo &si)
{
    loopv(lightmaps)
    {
        if(lightmaps[i].type == li.type && lightmaps[i].insert(si.x, si.y, li.colorbuf, si.w, si.h))
        {
            si.lmid = i + LMID_RESERVED;
            if((li.type&LM_TYPE) == LM_BUMPMAP0) ASSERT(lightmaps[i+1].insert(si.x, si.y, (uchar *)li.raybuf, si.w, si.h));
            return;
        }
    }

    progresslightmap = lightmaps.length();

    si.lmid = lightmaps.length() + LMID_RESERVED;
    LightMap &l = lightmaps.add();
    l.type = li.type;
    l.bpp = li.bpp;
    l.data = new uchar[li.bpp*LM_PACKW*LM_PACKH];
    memset(l.data, 0, li.bpp*LM_PACKW*LM_PACKH);
    ASSERT(l.insert(si.x, si.y, li.colorbuf, si.w, si.h));
    if((li.type&LM_TYPE) == LM_BUMPMAP0)
    {
        LightMap &r = lightmaps.add();
        r.type = LM_BUMPMAP1 | (li.type&~LM_TYPE);
        r.bpp = 3;
        r.data = new uchar[3*LM_PACKW*LM_PACKH];
        memset(r.data, 0, 3*LM_PACKW*LM_PACKH);
        ASSERT(r.insert(si.x, si.y, (uchar *)li.raybuf, si.w, si.h));
    }
}

static void copylightmap(lightmapinfo &li, surfaceinfo &si)
{
    lightmaps[si.lmid-LMID_RESERVED].copy(si.x, si.y, li.colorbuf, si.w, si.h);
    if((li.type&LM_TYPE)==LM_BUMPMAP0 && lightmaps.inrange(si.lmid+1-LMID_RESERVED))
        lightmaps[si.lmid+1-LMID_RESERVED].copy(si.x, si.y, (uchar *)li.raybuf, si.w, si.h);
}

struct compresskey
{
    lightmapinfo &lightmap;
    surfaceinfo &surface;

    compresskey(lightmapinfo &lightmap, surfaceinfo &surface) : lightmap(lightmap), surface(surface) {}
};

struct compressval 
{ 
    ushort x, y, lmid;
    uchar w, h;

    compressval() {}
    compressval(const surfaceinfo &s) : x(s.x), y(s.y), lmid(s.lmid), w(s.w), h(s.h) {} 
};

static inline bool htcmp(const compresskey &k, const compressval &v)
{
    int kw = k.surface.w, kh = k.surface.h;
    if(kw != v.w || kh != v.h) return false;
    LightMap &vlm = lightmaps[v.lmid - LMID_RESERVED];
    int ktype = k.lightmap.type;
    if(ktype != vlm.type) return false;
    int kbpp = k.lightmap.bpp;
    const uchar *kcolor = k.lightmap.colorbuf, *vcolor = vlm.data + kbpp*(v.x + v.y*LM_PACKW);
    loopi(kh)
    {
        if(memcmp(kcolor, vcolor, kbpp*kw)) return false;
        kcolor += kbpp*kw;
        vcolor += kbpp*LM_PACKW;
    }
    if((ktype&LM_TYPE) != LM_BUMPMAP0) return true;
    const bvec *kdir = k.lightmap.raybuf, *vdir = (const bvec *)lightmaps[v.lmid+1 - LMID_RESERVED].data;
    loopi(kh)
    {
        if(memcmp(kdir, vdir, kw*sizeof(bvec))) return false;
        kdir += kw;
        vdir += LM_PACKW;
    }
    return true;
}
    
static inline uint hthash(const compresskey &k)
{
    int kw = k.surface.w, kh = k.surface.h, kbpp = k.lightmap.bpp; 
    uint hash = kw + (kh<<8);
    const uchar *color = k.lightmap.colorbuf;
    loopi(kw*kh)
    {
       hash ^= color[0] + (color[1] << 4) + (color[2] << 8);
       color += kbpp;
    }
    return hash;  
}

static hashset<compressval> compressed;

static bool packlightmap(lightmapinfo &l, surfaceinfo &surface) 
{
    if((int)surface.w <= GETIV(lightcompress) && (int)surface.h <= GETIV(lightcompress))
    {
        compresskey key(l, surface);
        compressval *val = compressed.access(key);
        if(!val)
        {
            insertlightmap(l, surface);
            compressed[key] = surface;
        }
        else
        {
            surface.x = val->x;
            surface.y = val->y;
            surface.lmid = val->lmid;
            return false;
        }
    }
    else insertlightmap(l, surface);
    return true;
}

static void updatelightmap(const surfaceinfo &surface)
{
    if(max(LM_PACKW, LM_PACKH) > GETIV(hwtexsize)) return;

    LightMap &lm = lightmaps[surface.lmid-LMID_RESERVED];
    if(lm.tex < 0)
    {
        lm.offsetx = lm.offsety = 0;
        lm.tex = lightmaptexs.length();
        LightMapTexture &tex = lightmaptexs.add();
        tex.type = GETIV(renderpath)==R_FIXEDFUNCTION ? (lm.type&~LM_TYPE) | LM_DIFFUSE : lm.type;
        tex.w = LM_PACKW;
        tex.h = LM_PACKH;
        tex.unlitx = lm.unlitx;
        tex.unlity = lm.unlity;
        glGenTextures(1, &tex.id);
        createtexture(tex.id, tex.w, tex.h, NULL, 3, 1, tex.type&LM_ALPHA ? GL_RGBA : GL_RGB);
        if(GETIV(renderpath)!=R_FIXEDFUNCTION && (lm.type&LM_TYPE)==LM_BUMPMAP0 && lightmaps.inrange(surface.lmid+1-LMID_RESERVED))
        {
            LightMap &lm2 = lightmaps[surface.lmid+1-LMID_RESERVED];
            lm2.offsetx = lm2.offsety = 0;
            lm2.tex = lightmaptexs.length();
            LightMapTexture &tex2 = lightmaptexs.add();
            tex2.type = (lm.type&~LM_TYPE) | LM_BUMPMAP0;
            tex2.w = LM_PACKW;
            tex2.h = LM_PACKH;
            tex2.unlitx = lm2.unlitx;
            tex2.unlity = lm2.unlity;
            glGenTextures(1, &tex2.id);
            createtexture(tex2.id, tex2.w, tex2.h, NULL, 3, 1, GL_RGB);
        }
    }

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, LM_PACKW);

    glBindTexture(GL_TEXTURE_2D, lightmaptexs[lm.tex].id);
    glTexSubImage2D(GL_TEXTURE_2D, 0, lm.offsetx + surface.x, lm.offsety + surface.y, surface.w, surface.h, lm.type&LM_ALPHA ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, &lm.data[(surface.y*LM_PACKW + surface.x)*lm.bpp]);
    if(GETIV(renderpath)!=R_FIXEDFUNCTION && (lm.type&LM_TYPE)==LM_BUMPMAP0 && lightmaps.inrange(surface.lmid+1-LMID_RESERVED))
    {
        LightMap &lm2 = lightmaps[surface.lmid+1-LMID_RESERVED];
        glBindTexture(GL_TEXTURE_2D, lightmaptexs[lm2.tex].id);
        glTexSubImage2D(GL_TEXTURE_2D, 0, lm2.offsetx + surface.x, lm2.offsety + surface.y, surface.w, surface.h, GL_RGB, GL_UNSIGNED_BYTE, &lm2.data[(surface.y*LM_PACKW + surface.x)*3]);
    }
 
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
}
 
        
static uint generatelumel(lightmapworker *w, const float tolerance, uint lightmask, const vector<const extentity *> &lights, const vec &target, const vec &normal, vec &sample, int x, int y)
{
    vec avgray(0, 0, 0);
    float r = 0, g = 0, b = 0;
    uint lightused = 0;
    loopv(lights)
    {
        if(lightmask&(1<<i)) continue;
        const extentity &light = *lights[i];
        vec ray = target;
        ray.sub(light.o);
        float mag = ray.magnitude();
        if(!mag) continue;
        float attenuation = 1;
        if(light.attr1)
        {
            attenuation -= mag / float(light.attr1);
            if(attenuation <= 0) continue;
        }
        ray.mul(1.0f / mag);
        float angle = -ray.dot(normal);
        if(angle <= 0) continue;
        if(light.attached && light.attached->type==ET_SPOTLIGHT)
        {
            vec spot(vec(light.attached->o).sub(light.o).normalize());
            float maxatten = 1-cosf(max(1, min(90, int(light.attached->attr1)))*RAD);
            float spotatten = 1-(1-ray.dot(spot))/maxatten;
            if(spotatten <= 0) continue;
            attenuation *= spotatten;
        }
        if(lmshadows && mag)
        {
            float dist = shadowray(w->shadowraycache, light.o, ray, mag - tolerance, RAY_SHADOW | (lmshadows > 1 ? RAY_ALPHAPOLY : 0));
            if(dist < mag - tolerance) continue;
        }
        lightused |= 1<<i;
        float intensity;
        switch(w->type&LM_TYPE)
        {
            case LM_BUMPMAP0: 
                intensity = attenuation; 
                avgray.add(ray.mul(-attenuation));
                break;
            default:
                intensity = angle * attenuation;
                break;
        }
        r += intensity * float(light.attr2);
        g += intensity * float(light.attr3);
        b += intensity * float(light.attr4);
    }
    switch(w->type&LM_TYPE)
    {
        case LM_BUMPMAP0:
            if(avgray.iszero()) break;
            // transform to tangent space
            extern vec orientation_tangent[6][3];
            extern vec orientation_binormal[6][3];            
            vec S(orientation_tangent[w->rotate][dimension(w->orient)]),
                T(orientation_binormal[w->rotate][dimension(w->orient)]);
            normal.orthonormalize(S, T);
            avgray.normalize();
            w->raydata[y*w->w+x].add(vec(S.dot(avgray)/S.magnitude(), T.dot(avgray)/T.magnitude(), normal.dot(avgray)));
            break;
    }
    sample.x = min(255.0f, max(r, float(ambientcolor[0])));
    sample.y = min(255.0f, max(g, float(ambientcolor[1])));
    sample.z = min(255.0f, max(b, float(ambientcolor[2])));
    return lightused;
}

static bool lumelsample(const vec &sample, int aasample, int stride)
{
    if(sample.x >= int(ambientcolor[0])+1 || sample.y >= int(ambientcolor[1])+1 || sample.z >= int(ambientcolor[2])+1) return true;
#define NCHECK(n) \
    if((n).x >= int(ambientcolor[0])+1 || (n).y >= int(ambientcolor[1])+1 || (n).z >= int(ambientcolor[2])+1) \
        return true;
    const vec *n = &sample - stride - aasample;
    NCHECK(n[0]); NCHECK(n[aasample]); NCHECK(n[2*aasample]);
    n += stride;
    NCHECK(n[0]); NCHECK(n[2*aasample]);
    n += stride;
    NCHECK(n[0]); NCHECK(n[aasample]); NCHECK(n[2*aasample]);
    return false;
}

static void calcskylight(lightmapworker *w, const vec &o, const vec &normal, float tolerance, uchar *skylight, int flags = RAY_ALPHAPOLY, extentity *t = NULL)
{
    static const vec rays[17] =
    {
        vec(cosf(21*RAD)*cosf(50*RAD), sinf(21*RAD)*cosf(50*RAD), sinf(50*RAD)),
        vec(cosf(111*RAD)*cosf(50*RAD), sinf(111*RAD)*cosf(50*RAD), sinf(50*RAD)),
        vec(cosf(201*RAD)*cosf(50*RAD), sinf(201*RAD)*cosf(50*RAD), sinf(50*RAD)),
        vec(cosf(291*RAD)*cosf(50*RAD), sinf(291*RAD)*cosf(50*RAD), sinf(50*RAD)),

        vec(cosf(66*RAD)*cosf(70*RAD), sinf(66*RAD)*cosf(70*RAD), sinf(70*RAD)),
        vec(cosf(156*RAD)*cosf(70*RAD), sinf(156*RAD)*cosf(70*RAD), sinf(70*RAD)),
        vec(cosf(246*RAD)*cosf(70*RAD), sinf(246*RAD)*cosf(70*RAD), sinf(70*RAD)),
        vec(cosf(336*RAD)*cosf(70*RAD), sinf(336*RAD)*cosf(70*RAD), sinf(70*RAD)),
       
        vec(0, 0, 1),

        vec(cosf(43*RAD)*cosf(60*RAD), sinf(43*RAD)*cosf(60*RAD), sinf(60*RAD)),
        vec(cosf(133*RAD)*cosf(60*RAD), sinf(133*RAD)*cosf(60*RAD), sinf(60*RAD)),
        vec(cosf(223*RAD)*cosf(60*RAD), sinf(223*RAD)*cosf(60*RAD), sinf(60*RAD)),
        vec(cosf(313*RAD)*cosf(60*RAD), sinf(313*RAD)*cosf(60*RAD), sinf(60*RAD)),

        vec(cosf(88*RAD)*cosf(80*RAD), sinf(88*RAD)*cosf(80*RAD), sinf(80*RAD)),
        vec(cosf(178*RAD)*cosf(80*RAD), sinf(178*RAD)*cosf(80*RAD), sinf(80*RAD)),
        vec(cosf(268*RAD)*cosf(80*RAD), sinf(268*RAD)*cosf(80*RAD), sinf(80*RAD)),
        vec(cosf(358*RAD)*cosf(80*RAD), sinf(358*RAD)*cosf(80*RAD), sinf(80*RAD)),

    };
    flags |= RAY_SHADOW;
    if(GETIV(skytexturelight)) flags |= RAY_SKIPSKY;
    int hit = 0;
    if(w) loopi(17) 
    {
        if(normal.dot(rays[i])>=0 && shadowray(w->shadowraycache, vec(rays[i]).mul(tolerance).add(o), rays[i], 1e16f, flags, t)>1e15f) hit++;
    }
    else loopi(17) 
    {
        if(normal.dot(rays[i])>=0 && shadowray(vec(rays[i]).mul(tolerance).add(o), rays[i], 1e16f, flags, t)>1e15f) hit++;
    }

    loopk(3) skylight[k] = uchar(ambientcolor[k] + (max(skylightcolor[k], ambientcolor[k]) - ambientcolor[k])*hit/17.0f);
}

static inline bool hasskylight()
{
    return skylightcolor[0]>ambientcolor[0] || skylightcolor[1]>ambientcolor[1] || skylightcolor[2]>ambientcolor[2];
}

static void blurlightmap(int n, int bpp, int w, int h, uchar *dst, const uchar *src)
{
    static const int matrix3x3[9] =
    {
        0x10, 0x20, 0x10,
        0x20, 0x40, 0x20,
        0x10, 0x20, 0x10
    };
    static const int matrix5x5[25] =
    {
        0x05, 0x05, 0x09, 0x05, 0x05,
        0x05, 0x0A, 0x14, 0x0A, 0x05,
        0x09, 0x14, 0x28, 0x14, 0x09,
        0x05, 0x0A, 0x14, 0x0A, 0x05,
        0x05, 0x05, 0x09, 0x05, 0x05
    };
    const int *mat = n > 1 ? matrix5x5 : matrix3x3;
    int mstride = 2*n + 1,
        mstartoffset = n*(mstride + 1),
        stride = bpp*w, 
        startoffset = n*bpp,
        nextoffset1 = stride + mstride*bpp,
        nextoffset2 = stride - mstride*bpp;
    loop(y, h) loop(x, w)
    {
        loopk(3)
        {
            int val = 0; 
            const uchar *p = src - startoffset;
            const int *m = mat + mstartoffset;
            for(int t = y; t >= y-n; t--, p -= nextoffset1, m -= mstride)
            {
                if(t < 0) p += stride;
                int a = 0;
                if(n > 1) { a += m[-2]; if(x >= 2) { val += *p * a; a = 0; } p += bpp; }
                a += m[-1]; if(x >= 1) { val += *p * a; a = 0; } p += bpp;
                int c = *p; val += c * (a + m[0]); p += bpp;
                if(x+1 < w) c = *p; val += c * m[1]; p += bpp; 
                if(n > 1) { if(x+2 < w) c = *p; val += c * m[2]; p += bpp; }
            }
            p = src - startoffset + stride;
            m = mat + mstartoffset + mstride;
            for(int t = y+1; t <= y+n; t++, p += nextoffset2, m += mstride) 
            {
                if(t >= h) p -= stride;
                int a = 0;
                if(n > 1) { a += m[-2]; if(x >= 2) { val += *p * a; a = 0; } p += bpp; }
                a += m[-1]; if(x >= 1) { val += *p * a; a = 0; } p += bpp; 
                int c = *p; val += c * (a + m[0]); p += bpp;
                if(x+1 < w) c = *p; val += c * m[1]; p += bpp;
                if(n > 1) { if(x+2 < w) c = *p; val += c * m[2]; p += bpp; }
            }
            *dst++ = val>>8;
            src++;
        }
        if(bpp > 3) *dst++ = *src++;
    }
}

static inline void generatealpha(lightmapworker *w, float tolerance, const vec &pos, uchar &alpha)
{
    alpha = lookupblendmap(w->blendmapcache, pos);
    if(w->slot->layermask)
    {
        static const int sdim[] = { 1, 0, 0 }, tdim[] = { 2, 2, 1 };
        int dim = dimension(w->orient);
        float k = 8.0f/w->vslot->scale,
              s = (pos[sdim[dim]] * k - w->vslot->xoffset) / w->slot->layermaskscale,
              t = (pos[tdim[dim]] * (dim <= 1 ? -k : k) - w->vslot->yoffset) / w->slot->layermaskscale;
        if((w->rotate&5)==1) swap(s, t);
        if(w->rotate>=2 && w->rotate<=4) s = -s;
        if((w->rotate>=1 && w->rotate<=2) || w->rotate==5) t = -t;
        const ImageData &mask = *w->slot->layermask;
        int mx = int(floor(s))%mask.w, my = int(floor(t))%mask.h;
        if(mx < 0) mx += mask.w;
        if(my < 0) my += mask.h;
        uchar maskval = mask.data[mask.bpp*(mx + 1) - 1 + mask.pitch*my];
        switch(w->slot->layermaskmode)
        {
            case 2: alpha = min(alpha, maskval); break;
            case 3: alpha = max(alpha, maskval); break;
            case 4: alpha = min(alpha, uchar(0xFF - maskval)); break;
            case 5: alpha = max(alpha, uchar(0xFF - maskval)); break;
            default: alpha = maskval; break;
        }
    }
}

enum
{
    NO_SURFACE = 0,
    SURFACE_AMBIENT_BOTTOM,
    SURFACE_AMBIENT_TOP,
    SURFACE_LIGHTMAP_BOTTOM,
    SURFACE_LIGHTMAP_TOP,
    SURFACE_LIGHTMAP_BLEND 
};

#define SURFACE_AMBIENT SURFACE_AMBIENT_BOTTOM
#define SURFACE_LIGHTMAP SURFACE_LIGHTMAP_BOTTOM

static bool generatelightmap(lightmapworker *w, float lpu, int y1, int y2, const vec &origin, const lerpvert *lv, int numv, const vec &ustep, const vec &vstep)
{
    static const float aacoords[8][2] =
    {
        {0.0f, 0.0f},
        {-0.5f, -0.5f},
        {0.0f, -0.5f},
        {-0.5f, 0.0f},

        {0.3f, -0.6f},
        {0.6f, 0.3f},
        {-0.3f, 0.6f},
        {-0.6f, -0.3f},
    };
    float tolerance = 0.5 / lpu;
    vector<const extentity *> &lights = (y1 == 0 ? w->lights1 : w->lights2);
    uint lightmask = 0, lightused = 0;
    vec v = origin;
    vec offsets[8];
    loopi(8) loopj(3) offsets[i][j] = aacoords[i][0]*ustep[j] + aacoords[i][1]*vstep[j];

    if(y1 == 0)
    {
        if((w->type&LM_TYPE) == LM_BUMPMAP0) memset(w->raydata, 0, LM_MAXW*LM_MAXH*sizeof(vec));
    }

    int aasample = min(1 << lmaa, 4);
    int stride = aasample*(w->w+1);
    vec *sample = &w->colordata[stride*y1];
    uchar *skylight = &w->ambient[w->bpp*w->w*y1];
    lerpbounds start, end;
    initlerpbounds(lv, numv, start, end);
    for(int y = y1; y < y2; ++y, v.add(vstep)) 
    {
        vec normal, nstep;
        lerpnormal(y, lv, numv, start, end, normal, nstep);
        
        vec u(v);
        for(int x = 0; x < w->w; ++x, u.add(ustep), normal.add(nstep), skylight += w->bpp) 
        {
            lightused |= generatelumel(w, tolerance, 0, lights, u, vec(normal).normalize(), *sample, x, y);
            if(hasskylight())
            {
                if((w->type&LM_TYPE)==LM_BUMPMAP0 || !GETIV(adaptivesample) || sample->x<skylightcolor[0] || sample->y<skylightcolor[1] || sample->z<skylightcolor[2])
                    calcskylight(w, u, normal, tolerance, skylight, lmshadows > 1 ? RAY_ALPHAPOLY : 0);
                else loopk(3) skylight[k] = max(skylightcolor[k], ambientcolor[k]);
            }
            else loopk(3) skylight[k] = ambientcolor[k];
            if(w->type&LM_ALPHA) generatealpha(w, tolerance, u, skylight[3]);
            sample += aasample;
        }
        sample += aasample;
    }
    if(GETIV(adaptivesample) > 1 && min(w->w, w->h) >= 2) lightmask = ~lightused;
    v = origin;
    sample = &w->colordata[stride*y1];
    initlerpbounds(lv, numv, start, end);
    for(int y = y1; y < y2; ++y, v.add(vstep)) 
    {
        vec normal, nstep;
        lerpnormal(y, lv, numv, start, end, normal, nstep);

        vec u(v);
        for(int x = 0; x < w->w; ++x, u.add(ustep), normal.add(nstep)) 
        {
            vec &center = *sample++;
            if(GETIV(adaptivesample) && x > 0 && x+1 < w->w && y > y1 && y+1 < y2 && !lumelsample(center, aasample, stride))
                loopi(aasample-1) *sample++ = center;
            else
            {
#define EDGE_TOLERANCE(i) \
    ((!x && aacoords[i][0] < 0) \
     || (x+1==w->w && aacoords[i][0] > 0) \
     || (!y && aacoords[i][1] < 0) \
     || (y+1==w->h && aacoords[i][1] > 0) \
     ? GETIV(edgetolerance) : 1)
                vec n(normal);
                n.normalize();
                loopi(aasample-1)
                    generatelumel(w, EDGE_TOLERANCE(i+1) * tolerance, lightmask, lights, vec(u).add(offsets[i+1]), n, *sample++, x, y);
                if(lmaa == 3) 
                {
                    loopi(4)
                    {
                        vec s;
                        generatelumel(w, EDGE_TOLERANCE(i+4) * tolerance, lightmask, lights, vec(u).add(offsets[i+4]), n, s, x, y);
                        center.add(s);
                    }
                    center.div(5);
                }
            }
        }
        if(aasample > 1)
        {
            normal.normalize();
            generatelumel(w, tolerance, lightmask, lights, vec(u).add(offsets[1]), normal, sample[1], w->w-1, y);
            if(aasample > 2)
                generatelumel(w, GETIV(edgetolerance) * tolerance, lightmask, lights, vec(u).add(offsets[3]), normal, sample[3], w->w-1, y);
        }
        sample += aasample;
    }

    if(y2 == w->h)
    {
        if(aasample > 1)
        {
            vec normal, nstep;
            lerpnormal(w->h, lv, numv, start, end, normal, nstep);

            for(int x = 0; x <= w->w; ++x, v.add(ustep), normal.add(nstep))
            {
                vec n(normal);
                n.normalize();
                generatelumel(w, GETIV(edgetolerance) * tolerance, lightmask, lights, vec(v).add(offsets[1]), n, sample[1], min(x, w->w-1), w->h-1);
                if(aasample > 2)
                    generatelumel(w, GETIV(edgetolerance) * tolerance, lightmask, lights, vec(v).add(offsets[2]), n, sample[2], min(x, w->w-1), w->h-1);
                sample += aasample;
            } 
        }
    }
    return true;
}
     
static int finishlightmap(lightmapworker *w)
{ 
    if(hasskylight() && GETIV(blurskylight) && (w->w>1 || w->h>1)) 
    {
        blurlightmap(GETIV(blurskylight), w->bpp, w->w, w->h, w->blur, w->ambient);
        swap(w->blur, w->ambient);
    }
    vec *sample = w->colordata;
    int aasample = min(1 << lmaa, 4), stride = aasample*(w->w+1);
    float weight = 1.0f / (1.0f + 4.0f*lmaa),
          cweight = weight * (lmaa == 3 ? 5.0f : 1.0f);
    uchar *skylight = w->ambient;
    vec *ray = w->raydata;
    uchar *dstcolor = w->colorbuf;
    uchar mincolor[4] = { 255, 255, 255, 255 }, maxcolor[4] = { 0, 0, 0, 0 };
    bvec *dstray = w->raybuf;
    bvec minray(255, 255, 255), maxray(0, 0, 0);
    loop(y, w->h)
    {
        loop(x, w->w)
        {
            vec l(0, 0, 0);
            const vec &center = *sample++;
            loopi(aasample-1) l.add(*sample++);
            if(aasample > 1)
            {
                l.add(sample[1]);
                if(aasample > 2) l.add(sample[3]);
            }
            vec *next = sample + stride - aasample;
            if(aasample > 1)
            {
                l.add(next[1]);
                if(aasample > 2) l.add(next[2]);
                l.add(next[aasample+1]);
            }

            int r = int(center.x*cweight + l.x*weight),
                g = int(center.y*cweight + l.y*weight),
                b = int(center.z*cweight + l.z*weight),
                ar = skylight[0], ag = skylight[1], ab = skylight[2];
            dstcolor[0] = max(ar, r);
            dstcolor[1] = max(ag, g);
            dstcolor[2] = max(ab, b);
            loopk(3)
            {
                mincolor[k] = min(mincolor[k], dstcolor[k]);
                maxcolor[k] = max(maxcolor[k], dstcolor[k]);
            }
            if(w->type&LM_ALPHA)
            {
                dstcolor[3] = skylight[3];
                mincolor[3] = min(mincolor[3], dstcolor[3]);
                maxcolor[3] = max(maxcolor[3], dstcolor[3]);
            }
            if((w->type&LM_TYPE) == LM_BUMPMAP0)
            {
                if(ray->iszero()) dstray[0] = bvec(128, 128, 255);
                else
                {
                    // bias the normals towards the amount of ambient/skylight in the lumel 
                    // this is necessary to prevent the light values in shaders from dropping too far below the skylight (to the ambient) if N.L is small 
                    ray->normalize();
                    int l = max(r, max(g, b)), a = max(ar, max(ag, ab));
                    ray->mul(max(l-a, 0));
                    ray->z += a;
                    dstray[0] = bvec(ray->normalize());
                }
                loopk(3)
                {
                    minray[k] = min(minray[k], dstray[0][k]);
                    maxray[k] = max(maxray[k], dstray[0][k]);
                }
                ray++;
                dstray++;
            }
            dstcolor += w->bpp;
            skylight += w->bpp;
        }
        sample += aasample;
    }
    if(int(maxcolor[0]) - int(mincolor[0]) <= GETIV(lighterror) &&
       int(maxcolor[1]) - int(mincolor[1]) <= GETIV(lighterror) &&
       int(maxcolor[2]) - int(mincolor[2]) <= GETIV(lighterror) &&
       mincolor[3] >= maxcolor[3])
    {
        uchar color[3];
        loopk(3) color[k] = (int(maxcolor[k]) + int(mincolor[k])) / 2;
        if(color[0] <= int(ambientcolor[0]) + GETIV(lighterror) && 
           color[1] <= int(ambientcolor[1]) + GETIV(lighterror) && 
           color[2] <= int(ambientcolor[2]) + GETIV(lighterror) &&
           (maxcolor[3]==0 || mincolor[3]==255))
            return mincolor[3]==255 ? SURFACE_AMBIENT_TOP : SURFACE_AMBIENT_BOTTOM;
        if((w->type&LM_TYPE) != LM_BUMPMAP0 || 
            (int(maxray.x) - int(minray.x) <= GETIV(bumperror) &&
             int(maxray.y) - int(minray.z) <= GETIV(bumperror) &&
             int(maxray.z) - int(minray.z) <= GETIV(bumperror)))

        {
            memcpy(w->colorbuf, color, 3);
            if(w->type&LM_ALPHA) w->colorbuf[3] = mincolor[3];
            if((w->type&LM_TYPE) == LM_BUMPMAP0) 
            {
                loopk(3) w->raybuf[0][k] = uchar((int(maxray[k])+int(minray[k]))/2);
            }
            w->w = 1;
            w->h = 1;
        }
    }
    if(GETIV(blurlms) && (w->w>1 || w->h>1)) 
    {
        blurlightmap(GETIV(blurlms), w->bpp, w->w, w->h, w->blur, w->colorbuf);
        memcpy(w->colorbuf, w->blur, w->bpp*w->w*w->h);
    }
    if(mincolor[3]==255) return SURFACE_LIGHTMAP_TOP;
    else if(maxcolor[3]==0) return SURFACE_LIGHTMAP_BOTTOM;
    else return SURFACE_LIGHTMAP_BLEND;
}

static int previewlightmapalpha(lightmapworker *w, float lpu, int y1, int y2, const vec &origin, const vec &ustep, const vec &vstep)
{
    float tolerance = 0.5 / lpu;
    uchar *dst = &w->colorbuf[4*w->w*y1];
    vec v = origin;
    if(y1 <= 0) { memset(w->mincolor, 255, sizeof(w->mincolor)); memset(w->maxcolor, 0, sizeof(w->maxcolor)); }
    for(int y = y1; y < y2; ++y, v.add(vstep))
    {
        vec u(v);
        for(int x = 0; x < w->w; ++x, u.add(ustep), dst += 4)
        {
            loopk(3) dst[k] = GETIV(fullbrightlevel);        
            generatealpha(w, tolerance, u, dst[3]);
            w->mincolor[3] = min(w->mincolor[3], dst[3]);
            w->maxcolor[3] = max(w->maxcolor[3], dst[3]);
        }
    }
    if(y2 >= w->h)
    {
        if(w->mincolor[3]==255) return SURFACE_AMBIENT_TOP;
        if(w->maxcolor[3]==0) return SURFACE_AMBIENT_BOTTOM;
        if(w->mincolor[3]==w->maxcolor[3]) w->w = w->h = 1;    
        if((w->type&LM_TYPE) == LM_BUMPMAP0) loopi(w->w*w->h) w->raybuf[i] = bvec(128, 128, 255);
    }
    return SURFACE_LIGHTMAP_BLEND;
}        

static void clearsurfaces(cube *c)
{
    loopi(8)
    {
        if(c[i].ext)
        {
            if(c[i].ext->surfaces) freesurfaces(c[i]);
            if(c[i].ext->normals) freenormals(c[i]);
        }
        if(c[i].children) clearsurfaces(c[i].children);
    }
}

#define LIGHTCACHESIZE 1024

static struct lightcacheentry
{
    int x, y;
    vector<int> lights;
} lightcache[LIGHTCACHESIZE];

#define LIGHTCACHEHASH(x, y) (((((x)^(y))<<5) + (((x)^(y))>>5)) & (LIGHTCACHESIZE - 1))

void clearlightcache(int e)
{
    if(e < 0 || !entities::getents()[e]->attr1)
    {
        for(lightcacheentry *lce = lightcache; lce < &lightcache[LIGHTCACHESIZE]; lce++)
        {
            lce->x = -1;
            lce->lights.setsize(0);
        }
    }
    else
    {
        const extentity &light = *entities::getents()[e];
        int radius = light.attr1;
        for(int x = int(max(light.o.x-radius, 0.0f))>>GETIV(lightcachesize), ex = int(min(light.o.x+radius, GETIV(mapsize)-1.0f))>>GETIV(lightcachesize); x <= ex; x++)
        for(int y = int(max(light.o.y-radius, 0.0f))>>GETIV(lightcachesize), ey = int(min(light.o.y+radius, GETIV(mapsize)-1.0f))>>GETIV(lightcachesize); y <= ey; y++)
        {
            lightcacheentry &lce = lightcache[LIGHTCACHEHASH(x, y)];
            if(lce.x != x || lce.y != y) continue;
            lce.x = -1;
            lce.lights.setsize(0);
        }
    }
}

const vector<int> &checklightcache(int x, int y)
{
    x >>= GETIV(lightcachesize);
    y >>= GETIV(lightcachesize); 
    lightcacheentry &lce = lightcache[LIGHTCACHEHASH(x, y)];
    if(lce.x == x && lce.y == y) return lce.lights;

    lce.lights.setsize(0);
    int csize = 1<<GETIV(lightcachesize), cx = x<<GETIV(lightcachesize), cy = y<<GETIV(lightcachesize);
    const vector<extentity *> &ents = entities::getents();
    loopv(ents)
    {
        const extentity &light = *ents[i];
        switch(light.type)
        {
            case ET_LIGHT:
            {
                int radius = light.attr1;
                if(radius > 0)
                {
                    if(light.o.x + radius < cx || light.o.x - radius > cx + csize ||
                       light.o.y + radius < cy || light.o.y - radius > cy + csize)
                        continue;
                }
                break;
            }
            default: continue;
        }
        lce.lights.add(i);
    }

    lce.x = x;
    lce.y = y;
    return lce.lights;
}

static inline void addlight(lightmapworker *w, const extentity &light, int cx, int cy, int cz, int size, const vec *v, const vec *n, const vec *n2)
{
    int radius = light.attr1;
    if(radius > 0)
    {
        if(light.o.x + radius < cx || light.o.x - radius > cx + size ||
           light.o.y + radius < cy || light.o.y - radius > cy + size ||
           light.o.z + radius < cz || light.o.z - radius > cz + size)
            return;
    }

    if(!n2)
    {
        loopi(4)
        {
            vec p(light.o);
            p.sub(v[i]);
            float dist = p.dot(n[i]);
            if(dist >= 0 && (!radius || dist < radius))
            {
                w->lights1.add(&light);
                return;
            }
        }
        return;
    }

    bool plane1 = false, plane2 = false;
    loopi(4)
    {
        vec p(light.o);
        p.sub(v[i]);
        if(i != 3)
        {
            float dist = p.dot(n[i]);
            if(dist >= 0 && (!radius || dist < radius)) 
            {
                plane1 = true;
                if(plane2) break;
            }
        }
        if(i != 1)
        {
            float dist = p.dot(n2[i > 0 ? i-1 : 0]);
            if(dist >= 0 && (!radius || dist < radius)) 
            {
                plane2 = true;
                if(plane1) break;
            }
        }
    }

    if(plane1) w->lights1.add(&light);
    if(plane2) w->lights2.add(&light);
} 

static bool findlights(lightmapworker *w, int cx, int cy, int cz, int size, const vec *v, const vec *n, const vec *n2, const Slot &slot, const VSlot &vslot)
{
    w->lights1.setsize(0);
    w->lights2.setsize(0);
    const vector<extentity *> &ents = entities::getents();
    static volatile bool usinglightcache = false;
    if(size <= 1<<GETIV(lightcachesize) && (!lightlock || !usinglightcache))
    {
        if(lightlock) { SDL_LockMutex(lightlock); usinglightcache = true; }
        const vector<int> &lights = checklightcache(cx, cy);
        loopv(lights)
        {
            const extentity &light = *ents[lights[i]];
            switch(light.type)
            {
                case ET_LIGHT: addlight(w, light, cx, cy, cz, size, v, n, n2); break;
            }
        }
        if(lightlock) { usinglightcache = false; SDL_UnlockMutex(lightlock); }
    }
    else loopv(ents)
    {
        const extentity &light = *ents[i];
        switch(light.type)
        {
            case ET_LIGHT: addlight(w, light, cx, cy, cz, size, v, n, n2); break;
        }
    }
    if(vslot.layer && (setblendmaporigin(w->blendmapcache, ivec(cx, cy, cz), size) || slot.layermask)) return true;
    return w->lights1.length() || w->lights2.length() || hasskylight();
}

static int packlightmaps(lightmapworker *w = NULL)
{
    int numpacked = 0;
    for(; packidx < lightmaptasks[0].length(); packidx++, numpacked++)
    {
        lightmaptask &t = lightmaptasks[0][packidx];
        if(!t.lightmaps) break;
        progress = t.progress;
        lightmapinfo *l = t.lightmaps;
        if(l == (lightmapinfo *)-1) continue;
        int space = 0; 
        for(; l && l->c == t.c; l = l->next)
        {
            l->packed = true;
            space += l->bufsize;
            if(l->surface1 < 0 || !t.c->ext || !t.c->ext->surfaces) continue; 
            surfaceinfo &s = t.c->ext->surfaces[l->surface1];
            packlightmap(*l, s);
            if(l->surface2 < 0) continue;
            surfaceinfo &s2 = t.c->ext->surfaces[l->surface2];
            s2.x = s.x;
            s2.y = s.y;
            s2.lmid = s.lmid;
        }
        if(t.worker == w)
        {
            w->bufused -= space;
            w->bufstart = (w->bufstart + space)%LIGHTMAPBUFSIZE;
            w->firstlightmap = l;
            if(!l) 
            {
                w->lastlightmap = NULL;
                w->bufstart = w->bufused = 0;
            }
        }
        if(t.worker->needspace) SDL_CondSignal(t.worker->spacecond);
    }
    return numpacked;
}

static lightmapinfo *alloclightmap(lightmapworker *w)
{
    int needspace1 = sizeof(lightmapinfo) + w->w*w->h*w->bpp,
        needspace2 = (w->type&LM_TYPE) == LM_BUMPMAP0 ? w->w*w->h*3 : 0,
        needspace = needspace1 + needspace2,
        bufend = (w->bufstart + w->bufused)%LIGHTMAPBUFSIZE, 
        availspace = LIGHTMAPBUFSIZE - w->bufused,
        availspace1 = min(availspace, LIGHTMAPBUFSIZE - bufend),
        availspace2 = min(availspace, w->bufstart);
    if(availspace < needspace || (max(availspace1, availspace2) < needspace && (availspace1 < needspace1 || availspace2 < needspace2)))
    {
        if(tasklock) SDL_LockMutex(tasklock);
        while(!w->doneworking)
        {
            lightmapinfo *l = w->firstlightmap;
            for(; l && l->packed; l = l->next)
            {
                w->bufused -= l->bufsize;
                w->bufstart = (w->bufstart + l->bufsize)%LIGHTMAPBUFSIZE;
            }
            w->firstlightmap = l;
            if(!l) 
            {
                w->lastlightmap = NULL;
                w->bufstart = w->bufused = 0;
            }
            bufend = (w->bufstart + w->bufused)%LIGHTMAPBUFSIZE;
            availspace = LIGHTMAPBUFSIZE - w->bufused;
            availspace1 = min(availspace, LIGHTMAPBUFSIZE - bufend);
            availspace2 = min(availspace, w->bufstart);
            if(availspace >= needspace && (max(availspace1, availspace2) >= needspace || (availspace1 >= needspace1 && availspace2 >= needspace2))) break;
            if(packlightmaps(w)) continue;
            if(!w->spacecond || !tasklock) break;
            w->needspace = true;
            SDL_CondWait(w->spacecond, tasklock);
            w->needspace = false;
        }
        if(tasklock) SDL_UnlockMutex(tasklock);
    }
    int usedspace = needspace;
    lightmapinfo *l = NULL;
    if(availspace1 >= needspace1)
    {
        l = (lightmapinfo *)&w->buf[bufend];
        w->colorbuf = (uchar *)(l + 1);
        if((w->type&LM_TYPE) != LM_BUMPMAP0) w->raybuf = NULL;
        else if(availspace1 >= needspace) w->raybuf = (bvec *)&w->buf[bufend + needspace1];
        else
        {
            w->raybuf = (bvec *)w->buf;
            usedspace += availspace1 - needspace1;
        }
    }
    else if(availspace2 >= needspace)
    {
        usedspace += availspace1;
        l = (lightmapinfo *)w->buf;
        w->colorbuf = (uchar *)(l + 1);
        w->raybuf = (w->type&LM_TYPE) == LM_BUMPMAP0 ? (bvec *)&w->buf[needspace1] : NULL;
    }
    else return NULL;
    w->bufused += usedspace;
    l->next = NULL;
    l->c = w->c;
    l->type = w->type;
    l->bpp = w->bpp;
    l->colorbuf = w->colorbuf;
    l->raybuf = w->raybuf;
    l->packed = false;
    l->bufsize = usedspace;
    l->surface1 = l->surface2 = -1;
    if(!w->firstlightmap) w->firstlightmap = l;
    if(w->lastlightmap) w->lastlightmap->next = l;
    w->lastlightmap = l;
    if(!w->curlightmaps) w->curlightmaps = l;
    return l;
}

static void freelightmap(lightmapworker *w)
{
    lightmapinfo *l = w->lastlightmap;
    if(!l || l->surface1 >= 0) return;
    if(w->firstlightmap == w->lastlightmap)
    {
        w->firstlightmap = w->lastlightmap = w->curlightmaps = NULL;
        w->bufstart = w->bufused = 0;
    }
    else
    {
        w->bufused -= l->bufsize - sizeof(lightmapinfo);
        l->bufsize = sizeof(lightmapinfo);
        l->packed = true;
    }
    if(w->curlightmaps == l) w->curlightmaps = NULL;
}
 
static int setupsurface(lightmapworker *w, plane planes[2], const vec *p, const vec *n, const vec *n2, uchar texcoords[8], bool preview = false)
{
    vec u, v, s, t;
    float umin(0.0f), umax(0.0f),
          vmin(0.0f), vmax(0.0f),
          tmin(0.0f), tmax(0.0f);

    #define COORDMINMAX(u, v, orig, vert) \
    { \
        vec tovert = p[vert]; \
        tovert.sub(p[orig]); \
        float u ## coord = u.dot(tovert), \
              v ## coord = v.dot(tovert); \
        u ## min = min(u ## coord, u ## min); \
        u ## max = max(u ## coord, u ## max); \
        v ## min = min(v ## coord, v ## min); \
        v ## max = max(v ## coord, v ## max);  \
    }

    if(!n2)
    {
        u = (p[0] == p[1] ? p[2] : p[1]);
        u.sub(p[0]);
        u.normalize();
        v.cross(planes[0], u);

        COORDMINMAX(u, v, 0, 1);
        COORDMINMAX(u, v, 0, 2);
        COORDMINMAX(u, v, 0, 3);
    }
    else
    {
        u = p[2];
        u.sub(p[0]);
        u.normalize();
        v.cross(u, planes[0]);
        t.cross(planes[1], u);

        COORDMINMAX(u, v, 0, 1);
        COORDMINMAX(u, v, 0, 2);
        COORDMINMAX(u, t, 0, 2);
        COORDMINMAX(u, t, 0, 3);
    }

    int scale = int(min(umax - umin, vmax - vmin));
    if(n2) scale = min(scale, int(tmax));
    float lpu = 16.0f / float(scale < (1 << GETIV(lightlod)) ? GETIV(lightprecision) / 2 : GETIV(lightprecision));
    int ul((int)ceil((umax - umin + 1) * lpu)),
        vl((int)ceil((vmax - vmin + 1) * lpu)),
        tl(0);
    vl = max(LM_MINW, vl);
    if(n2)
    {
        tl = (uint)ceil((tmax + 1) * lpu);
        tl = max(LM_MINW, tl);
    }
    w->w = max(LM_MINW, min(LM_MAXW, ul));
    w->h = min(LM_MAXH, vl + tl);

    if(!alloclightmap(w)) return NO_SURFACE;
         
    vec origin1(p[0]), origin2, uo(u), vo(v);
    uo.mul(umin);
    if(!n2)
    {
        vo.mul(vmin);
    }
    else
    {
        vo.mul(vmax);
        v.mul(-1);
    }
    origin1.add(uo);
    origin1.add(vo);
    
    vec ustep(u), vstep(v);
    ustep.mul((umax - umin) / (w->w - 1));
    uint split = vl * w->h / (vl + tl);
    vstep.mul((vmax - vmin) / (split - 1));
    int surftype = NO_SURFACE;
    if(preview)
    {
        if(!n2) surftype = previewlightmapalpha(w, lpu, 0, w->h, origin1, ustep, vstep);
        else
        {
            origin2 = p[0];
            origin2.add(uo);
            vec tstep(t);
            tstep.mul(tmax / (w->h - split - 1));

            surftype = previewlightmapalpha(w, lpu, 0, split, origin1, ustep, vstep);
            if(surftype<SURFACE_LIGHTMAP) return surftype;
            surftype = previewlightmapalpha(w, lpu, split, w->h, origin2, ustep, tstep);
        }
    }
    else if(!n2)
    {
        lerpvert lv[4];
        int numv = 4;
        calclerpverts(origin1, p, n, ustep, vstep, lv, numv);

        if(!generatelightmap(w, lpu, 0, w->h, origin1, lv, numv, ustep, vstep)) return NO_SURFACE;
        surftype = finishlightmap(w);
    }
    else
    {
        origin2 = p[0];
        origin2.add(uo);
        vec tstep(t);
        tstep.mul(tmax / (w->h - split - 1));

        vec p1[3] = {p[0], p[1], p[2]},
            p2[3] = {p[0], p[2], p[3]};
        lerpvert lv1[3], lv2[3];
        int numv1 = 3, numv2 = 3;
        calclerpverts(origin1, p1, n, ustep, vstep, lv1, numv1);
        calclerpverts(origin2, p2, n2, ustep, tstep, lv2, numv2);

        if(!generatelightmap(w, lpu, 0, split, origin1, lv1, numv1, ustep, vstep) ||
           !generatelightmap(w, lpu, split, w->h, origin2, lv2, numv2, ustep, tstep)) 
            return NO_SURFACE;
        surftype = finishlightmap(w);
    }
    if(surftype<SURFACE_LIGHTMAP) return surftype;

    #define CALCVERT(origin, u, v, offset, vert) \
    { \
        vec tovert = p[vert]; \
        tovert.sub(origin); \
        float u ## coord = u.dot(tovert), \
              v ## coord = v.dot(tovert); \
        texcoords[vert*2] = uchar(u ## coord * u ## scale); \
        texcoords[vert*2+1] = offset + uchar(v ## coord * v ## scale); \
    }

    float uscale = 255.0f / float(umax - umin),
          vscale = 255.0f / float(vmax - vmin) * float(split) / float(w->h);
    CALCVERT(origin1, u, v, 0, 0)
    CALCVERT(origin1, u, v, 0, 1)
    CALCVERT(origin1, u, v, 0, 2)
    if(!n2)
    {
        CALCVERT(origin1, u, v, 0, 3)
    }
    else
    {
        uchar toffset = uchar(255.0 * float(split) / float(w->h));
        float tscale = 255.0f / float(tmax - tmin) * float(w->h - split) / float(w->h);
        CALCVERT(origin2, u, t, toffset, 3)
    }
    return surftype;
}

static void removelmalpha(lightmapworker *w)
{
    if(!(w->type&LM_ALPHA)) return;
    for(uchar *dst = w->colorbuf, *src = w->colorbuf, *end = &src[w->w*w->h*4];
        src < end;
        dst += 3, src += 4)
    {
        dst[0] = src[0];
        dst[1] = src[1];
        dst[2] = src[2];
    }
    w->type &= ~LM_ALPHA;
    w->bpp = 3;
    w->lastlightmap->type = w->type;
    w->lastlightmap->bpp = w->bpp;
}

static lightmapinfo *setupsurfaces(lightmapworker *w, lightmaptask &task)
{
    cube &c = *task.c;
    const ivec &co = task.o;
    int size = task.size, usefacemask = task.usefaces;
    
    vec verts[8];
    loopi(8) if(task.vertused&(1<<i)) calcvert(c, co.x, co.y, co.z, size, verts[i], i);

    w->curlightmaps = NULL;
    w->c = &c;

    int mergeindex = 0;
    surfaceinfo surfaces[12];
    int numsurfs = 0;
    loopi(6)
    {
        int usefaces = usefacemask&0xF;
        usefacemask >>= 4;
        if(!usefaces) continue;

        if(c.texture[i] == DEFAULT_SKY) continue;

        plane planes[2];
        vec v[4], n[4], n2[3];
        int numplanes;

        VSlot &vslot = lookupvslot(c.texture[i], false),
             *layer = vslot.layer && !(c.ext && c.ext->material&MAT_ALPHA) ? &lookupvslot(vslot.layer, false) : NULL;
        Shader *shader = vslot.slot->shader;
        int shadertype = shader->type;
        if(layer) shadertype |= layer->slot->shader->type;
        if(c.ext && c.ext->merged&(1<<i))
        {
            if(!(c.ext->mergeorigin&(1<<i))) continue;
            const mergeinfo &m = c.ext->merges[mergeindex++];
            ivec mo(co);
            genmergedverts(c, i, mo, size, m, v, planes);

            numplanes = 1;
            int msz = calcmergedsize(i, mo, size, m, v);
            mo.mask(~((1<<msz)-1));

            loopj(4) findnormal(v[j], planes[0], n[j]);

            if(!findlights(w, mo.x, mo.y, mo.z, 1<<msz, v, n, NULL, *vslot.slot, vslot))
            {
                if(!(shadertype&(SHADER_NORMALSLMS | SHADER_ENVMAP))) continue;
            }
        }
        else
        {
            numplanes = genclipplane(c, i, verts, planes);
            if(!numplanes) continue;

            vec avg;
            if(numplanes >= 2)
            {
                if(!(usefaces&1)) { planes[0] = planes[1]; numplanes--; }
                else if(!(usefaces&2)) numplanes--;
                else
                {
                    avg = planes[0];
                    avg.add(planes[1]);
                    avg.normalize();
                }
            }

            int order = usefaces&4 || faceconvexity(c, i)<0 ? 1 : 0;
            loopj(4)
            {
                int index = fv[i][(j+order)&3];
                v[j] = verts[index];
                if(numplanes < 2 || j == 1) findnormal(v[j], planes[0], n[j]);
                else if(j==3) findnormal(v[j], planes[1], n2[2]);
                else
                {
                    findnormal(v[j], avg, n[j]);
                    if(j) n2[j-1] = n[j];
                    else n2[0] = n[0];
                }
            }

            if(!(usefaces&1)) { v[1] = v[0]; n[1] = n[0]; }
            if(!(usefaces&2)) { v[3] = v[0]; n[3] = n[0]; }

            if(!findlights(w, co.x, co.y, co.z, size, v, n, numplanes > 1 ? n2 : NULL, *vslot.slot, vslot))
            {
                if(!(shadertype&(SHADER_NORMALSLMS | SHADER_ENVMAP))) continue;
            }
        }
        if(shadertype&(SHADER_NORMALSLMS | SHADER_ENVMAP))
        {
            newnormals(c);
            surfacenormals *cn = c.ext->normals;
            cn[i].normals[0] = bvec(n[0]);
            cn[i].normals[1] = bvec(n[1]);
            cn[i].normals[2] = bvec(n[2]);
            cn[i].normals[3] = bvec(numplanes < 2 ? n[3] : n2[2]);
        }
        if(w->lights1.empty() && w->lights2.empty() && (!layer || (!hasblendmap(w->blendmapcache) && !vslot.slot->layermask)) && !hasskylight()) continue;

        uchar texcoords[8];

        w->slot = vslot.slot;
        w->vslot = &vslot;
        w->type = shader->type&SHADER_NORMALSLMS ? LM_BUMPMAP0 : LM_DIFFUSE;
        if(layer) w->type |= LM_ALPHA;
        w->bpp = w->type&LM_ALPHA ? 4 : 3;
        w->orient = i;
        w->rotate = vslot.rotation;
        int surftype = setupsurface(w, planes, v, n, numplanes >= 2 ? n2 : NULL, texcoords);
        switch(surftype)
        {
            case SURFACE_LIGHTMAP_BOTTOM:
                if((shader->type^layer->slot->shader->type)&SHADER_NORMALSLMS ||
                   (shader->type&SHADER_NORMALSLMS && vslot.rotation!=layer->rotation))
                {
                    freelightmap(w);
                    break;
                }
                // fall through
            case SURFACE_LIGHTMAP_BLEND:
            case SURFACE_LIGHTMAP_TOP:
            {
                if(!numsurfs) { numsurfs = 6; memset(surfaces, 0, sizeof(surfaces)); }
                w->lastlightmap->surface1 = i;
                surfaceinfo &surface = surfaces[i];
                surface.w = w->w;
                surface.h = w->h;
                if(surftype==SURFACE_LIGHTMAP_BLEND) surface.layer = LAYER_TOP|LAYER_BLEND;
                else
                {
                    if(surftype==SURFACE_LIGHTMAP_BOTTOM) surface.layer = LAYER_BOTTOM;
                    if(w->type&LM_ALPHA) removelmalpha(w);
                } 
                memcpy(surface.texcoords, texcoords, 8);
                if(surftype!=SURFACE_LIGHTMAP_BLEND) continue;
                if((shader->type^layer->slot->shader->type)&SHADER_NORMALSLMS ||
                   (shader->type&SHADER_NORMALSLMS && vslot.rotation!=layer->rotation)) 
                    break;
                w->lastlightmap->surface2 = numsurfs;
                surfaces[numsurfs] = surface;
                surfaces[numsurfs++].layer = LAYER_BOTTOM;
                continue;
            }

            case SURFACE_AMBIENT_BOTTOM:
                freelightmap(w);
                if(layer)
                {
                    if(!numsurfs) { numsurfs = 6; memset(surfaces, 0, sizeof(surfaces)); }
                    surfaces[i].layer = LAYER_BOTTOM;
                }
                continue;

            default: freelightmap(w); continue;
        }

        w->slot = layer->slot;
        w->vslot = layer;
        w->type = layer->slot->shader->type&SHADER_NORMALSLMS ? LM_BUMPMAP0 : LM_DIFFUSE;
        w->bpp = 3;
        w->rotate = layer->rotation;
        switch(setupsurface(w, planes, v, n, numplanes >= 2 ? n2 : NULL, texcoords))
        {
            case SURFACE_LIGHTMAP_TOP:
            {
                if(!numsurfs) { numsurfs = 6; memset(surfaces, 0, sizeof(surfaces)); }
                int surfidx = surftype==SURFACE_LIGHTMAP_BLEND ? numsurfs++ : i;
                w->lastlightmap->surface1 = surfidx;
                surfaceinfo &surface = surfaces[surfidx];
                surface.w = w->w;
                surface.h = w->h;
                surface.layer = LAYER_BOTTOM;
                memcpy(surface.texcoords, texcoords, 8);
                break;
            }

            case SURFACE_AMBIENT_TOP:
            {
                freelightmap(w);
                if(!numsurfs) { numsurfs = 6; memset(surfaces, 0, sizeof(surfaces)); }
                surfaceinfo &surface = surfaces[surftype==SURFACE_LIGHTMAP_BLEND ? numsurfs++ : i];
                memset(&surface, 0, sizeof(surface));
                surface.layer = LAYER_BOTTOM;
                break;
            }

            default: freelightmap(w); break;
        }
    }
    if(numsurfs) newsurfaces(c, surfaces, numsurfs);
    return w->curlightmaps ? w->curlightmaps : (lightmapinfo *)-1;
}

int lightmapworker::work(void *data)
{
    lightmapworker *w = (lightmapworker *)data;
    SDL_LockMutex(tasklock);
    while(!w->doneworking)
    {
        if(allocidx < lightmaptasks[0].length())
        {
            lightmaptask &t = lightmaptasks[0][allocidx++];
            t.worker = w;
            SDL_UnlockMutex(tasklock);
            lightmapinfo *l = setupsurfaces(w, t);
            SDL_LockMutex(tasklock);
            t.lightmaps = l;
            packlightmaps(w);
        }
        else 
        {
            if(packidx >= lightmaptasks[0].length()) SDL_CondSignal(emptycond);   
            SDL_CondWait(fullcond, tasklock);
        }
    }
    SDL_UnlockMutex(tasklock);
    return 0;
}

static bool processtasks(bool finish = false)
{
    if(tasklock) SDL_LockMutex(tasklock);
    while(finish || lightmaptasks[1].length())
    {
        if(packidx >= lightmaptasks[0].length())
        {
            if(lightmaptasks[1].empty()) break;
            lightmaptasks[0].setsize(0);
            lightmaptasks[0].move(lightmaptasks[1]);
            packidx = allocidx = 0;
            if(fullcond) SDL_CondBroadcast(fullcond);
        }
        else if(lightmapping > 1)
        {
            SDL_CondWaitTimeout(emptycond, tasklock, 250);
            CHECK_PROGRESS_LOCKED({ SDL_UnlockMutex(tasklock); return false; }, SDL_UnlockMutex(tasklock), SDL_LockMutex(tasklock));
        }
        else 
        {
            while(allocidx < lightmaptasks[0].length())
            {
                lightmaptask &t = lightmaptasks[0][allocidx++];
                t.worker = lightmapworkers[0];
                t.lightmaps = setupsurfaces(lightmapworkers[0], t);
                packlightmaps(lightmapworkers[0]);
                CHECK_PROGRESS(return false);
            }
        }
    }
    if(tasklock) SDL_UnlockMutex(tasklock);
    return true;
}

static void generatelightmaps(cube *c, int cx, int cy, int cz, int size)
{
    CHECK_PROGRESS(return);

    taskprogress++;

    loopi(8)
    {
        ivec o(i, cx, cy, cz, size);
        if(c[i].children)
            generatelightmaps(c[i].children, o.x, o.y, o.z, size >> 1);
        else if(!isempty(c[i]))
        {
            if(c[i].ext && c[i].ext->surfaces)
            {
                loopj(6) if(c[i].ext->surfaces[j].lmid >= LMID_RESERVED) goto nextcube;
                freesurfaces(c[i]);
                freenormals(c[i]);
            }
            int vertused = 0, usefacemask = 0;
            loopj(6) if(c[i].texture[j] != DEFAULT_SKY && (!c[i].ext || !(c[i].ext->merged&(1<<j)) || c[i].ext->mergeorigin&(1<<j)))
            {   
                int usefaces = visibletris(c[i], j, o.x, o.y, o.z, size);
                if(usefaces)
                {   
                    usefacemask |= usefaces<<(4*j);
                    vertused |= fvmasks[1<<j];
                }
            }
            if(usefacemask)
            {
                lightmaptask &t = lightmaptasks[1].add();
                t.o = o;
                t.size = size;
                t.vertused = vertused; 
                t.usefaces = usefacemask;
                t.c = &c[i]; 
                t.lightmaps = NULL;
                t.progress = taskprogress;
                if(lightmaptasks[1].length() >= MAXLIGHTMAPTASKS && !processtasks()) return;
            }
        }
    nextcube:;
    } 
}

static bool previewblends(lightmapworker *w, cube &c, const ivec &co, int size)
{
    if(isempty(c) || (c.ext && c.ext->material&MAT_ALPHA)) return false;

    int usefaces[6];
    int vertused = 0;
    loopi(6) if((usefaces[i] = lookupvslot(c.texture[i], false).layer ? visibletris(c, i, co.x, co.y, co.z, size) : 0))
        vertused |= fvmasks[1<<i];
    if(!vertused) return false;

    if(!setblendmaporigin(w->blendmapcache, co, size))
    {
        if(!c.ext || !c.ext->surfaces || c.ext->surfaces==brightsurfaces) return false;
        bool blends = false;
        loopi(6) if(c.ext->surfaces[i].layer&LAYER_BLEND || c.ext->surfaces[i].layer==LAYER_BOTTOM)
        {
            surfaceinfo &surface = c.ext->surfaces[i];
            memset(&surface, 0, sizeof(surfaceinfo));
            surface.lmid = LMID_BRIGHT;
            surface.layer = LAYER_TOP;
            blends = true;
        }
        return blends;
    }

    vec verts[8];
    loopi(8) if(vertused&(1<<i)) calcvert(c, co.x, co.y, co.z, size, verts[i], i);

    w->firstlightmap = w->lastlightmap = w->curlightmaps = NULL;
    w->bufstart = w->bufused = 0;
    w->c = &c;

    surfaceinfo surfaces[12], *srcsurfaces = c.ext && c.ext->surfaces && c.ext->surfaces!=brightsurfaces ? c.ext->surfaces : NULL;
    int numsurfs = srcsurfaces ? 6 : 0, numsrcsurfs = srcsurfaces ? 6 : 0;
    if(srcsurfaces) memcpy(surfaces, srcsurfaces, 6*sizeof(surfaceinfo));
    else 
    {
        memset(surfaces, 0, 6*sizeof(surfaceinfo));
        loopi(6) surfaces[i].lmid = LMID_BRIGHT;
    }
    loopi(6)
    {
        if(surfaces[i].layer&LAYER_BLEND) 
        {
            if(!usefaces[i]) 
            {
                surfaces[numsurfs++] = srcsurfaces[numsrcsurfs++];
                continue;
            }
            numsrcsurfs++;
        }
        else if(!usefaces[i]) continue;

        plane planes[2];
        int numplanes = genclipplane(c, i, verts, planes);
        if(!numplanes) continue;

        VSlot &vslot = lookupvslot(c.texture[i], false),
              &layer = lookupvslot(vslot.layer, false);
        Shader *shader = vslot.slot->shader;
        int shadertype = shader->type | layer.slot->shader->type;
            
        int order = usefaces[i]&4 || faceconvexity(c, i)<0 ? 1 : 0;
        vec v[4];
        loopk(4) v[k] = verts[fv[i][(k+order)&3]];
        if(!(usefaces[i]&1)) { v[1] = v[0]; if(numplanes>1) { planes[0] = planes[1]; --numplanes; } }
        if(!(usefaces[i]&2)) { v[3] = v[0]; if(numplanes>1) --numplanes; }

        static const vec n[4] = { vec(0, 0, 1), vec(0, 0, 1), vec(0, 0, 1), vec(0, 0, 1) };
        uchar texcoords[8];

        w->slot = vslot.slot;
        w->vslot = &vslot;
        w->type = shadertype&SHADER_NORMALSLMS ? LM_BUMPMAP0|LM_ALPHA : LM_DIFFUSE|LM_ALPHA;
        w->bpp = 4;
        w->orient = i;
        w->rotate = vslot.rotation;
        int surftype = setupsurface(w, planes, v, n, numplanes >= 2 ? n : NULL, texcoords, true);
        switch(surftype)
        {
            case SURFACE_AMBIENT_TOP:
                if(srcsurfaces) 
                {
                    memset(&surfaces[i], 0, sizeof(surfaceinfo));
                    surfaces[i].lmid = LMID_BRIGHT;
                }
                continue;

            case SURFACE_AMBIENT_BOTTOM:
                if(!numsurfs) numsurfs = 6;
                if(srcsurfaces) 
                {
                    memset(&surfaces[i], 0, sizeof(surfaceinfo));
                    surfaces[i].lmid = LMID_BRIGHT;
                }
                surfaces[i].layer = LAYER_BOTTOM;
                continue;

            case SURFACE_LIGHTMAP_BLEND:
            {
                if(!numsurfs) numsurfs = 6;
                surfaceinfo &surface = surfaces[i];
                if(surface.w==w->w && surface.h==w->h && 
                   surface.layer==(LAYER_TOP|LAYER_BLEND) && 
                   !memcmp(surface.texcoords, texcoords, 8) &&
                   lightmaps.inrange(surface.lmid-LMID_RESERVED) &&
                   lightmaps[surface.lmid-LMID_RESERVED].type==w->type)           
                {
                    copylightmap(*w->lastlightmap, surface);
                    updatelightmap(surface);
                    surfaces[numsurfs] = surface;
                    surfaces[numsurfs++].layer = LAYER_BOTTOM;
                    continue;
                }
                surface.w = w->w;
                surface.h = w->h;
                surface.layer = LAYER_TOP|LAYER_BLEND;
                memcpy(surface.texcoords, texcoords, 8);
                if(packlightmap(*w->lastlightmap, surface)) updatelightmap(surface);
                surfaces[numsurfs] = surface;
                surfaces[numsurfs++].layer = LAYER_BOTTOM;
                continue;
            }
        }
    }
    if(numsurfs>numsrcsurfs) 
    {
        freesurfaces(c);
        newsurfaces(c, surfaces, numsurfs);
        return true;
    }
    else if(numsurfs!=numsrcsurfs || memcmp(srcsurfaces, surfaces, numsurfs*sizeof(surfaceinfo))) 
    {
        if(!numsurfs) brightencube(c);
        else memcpy(srcsurfaces, surfaces, numsurfs*sizeof(surfaceinfo));
        return true;
    }
    else return false;
}

static bool previewblends(lightmapworker *w, cube *c, const ivec &co, int size, const ivec &bo, const ivec &bs)
{
    bool changed = false;
    loopoctabox(co, size, bo, bs)
    {
        ivec o(i, co.x, co.y, co.z, size);
        cubeext *ext = c[i].ext;
        if(ext && ext->va && ext->va->hasmerges)
        {
            destroyva(ext->va);
            ext->va = NULL;
            invalidatemerges(c[i], true);
            changed = true;
        }
        if(c[i].children ? previewblends(w, c[i].children, o, size/2, bo, bs) : previewblends(w, c[i], o, size))  
        {
            changed = true;
            if(ext && ext->va)
            {
                int hasmerges = ext->va->hasmerges;
                destroyva(ext->va);
                ext->va = NULL;
                if(hasmerges) invalidatemerges(c[i], true);
            }
        }
    }
    return changed;
}

void previewblends(const ivec &bo, const ivec &bs)
{
    loadlayermasks();
    if(lightmapworkers.empty()) lightmapworkers.add(new lightmapworker);
    lightmapworkers[0]->reset();
    if(previewblends(lightmapworkers[0], worldroot, ivec(0, 0, 0), GETIV(mapsize)/2, bo, bs))
        commitchanges(true);
}
                            
void cleanuplightmaps()
{
    loopv(lightmaps)
    {
        LightMap &lm = lightmaps[i];
        lm.tex = lm.offsetx = lm.offsety = -1;
    }
    loopv(lightmaptexs) glDeleteTextures(1, &lightmaptexs[i].id);
    lightmaptexs.shrink(0);
    if(progresstex) { glDeleteTextures(1, &progresstex); progresstex = 0; }
}

void resetlightmaps(bool fullclean)
{
    cleanuplightmaps();
    lightmaps.shrink(0);
    compressed.clear();
    clearlightcache();
    if(fullclean) while(lightmapworkers.length()) delete lightmapworkers.pop();
}

lightmapworker::lightmapworker()
{
    buf = new uchar[LIGHTMAPBUFSIZE];
    bufstart = bufused = 0;
    firstlightmap = lastlightmap = curlightmaps = NULL;
    ambient = new uchar[4*LM_MAXW*LM_MAXH];
    blur = new uchar[4*LM_MAXW*LM_MAXH];
    colordata = new vec[4*(LM_MAXW+1)*(LM_MAXH+1)];
    raydata = new vec[LM_MAXW*LM_MAXH];
    shadowraycache = newshadowraycache();
    blendmapcache = newblendmapcache();
    needspace = doneworking = false;
    spacecond = NULL;
    thread = NULL;
}

lightmapworker::~lightmapworker()
{
    cleanupthread();
    delete[] buf;
    delete[] ambient;
    delete[] blur;
    delete[] colordata;
    delete[] raydata;
    freeshadowraycache(shadowraycache);
    freeblendmapcache(blendmapcache);
}

void lightmapworker::cleanupthread()
{
    if(spacecond) { SDL_DestroyCond(spacecond); spacecond = NULL; }
    thread = NULL;
}

void lightmapworker::reset()
{
    bufstart = bufused = 0;
    firstlightmap = lastlightmap = curlightmaps = NULL;
    needspace = doneworking = false;
    resetshadowraycache(shadowraycache);
}

bool lightmapworker::setupthread()
{
    if(!spacecond) spacecond = SDL_CreateCond();
    if(!spacecond) return false;
    thread = SDL_CreateThread(work, this);
    return thread!=NULL;
}

static Uint32 calclighttimer(Uint32 interval, void *param)
{
    check_calclight_progress = true;
    return interval;
}

bool setlightmapquality(int quality)
{
    switch(quality)
    {
        case  1: lmshadows = 2; lmaa = 3; break;
        case  0: lmshadows = GETIV(lmshadows); lmaa = GETIV(lmaa); break;
        case -1: lmshadows = 1; lmaa = 0; break;
        default: return false;
    }
    return true;
}

#define ALLOCLOCK(name, init) { if(lightmapping > 1) name = init(); if(!name) lightmapping = 1; }
#define FREELOCK(name, destroy) { if(name) { destroy(name); name = NULL; } }

static void cleanuplocks()
{
    FREELOCK(lightlock, SDL_DestroyMutex);
    FREELOCK(tasklock, SDL_DestroyMutex);
    FREELOCK(fullcond, SDL_DestroyCond);
    FREELOCK(emptycond, SDL_DestroyCond);
}

static void setupthreads()
{
    loopi(2) lightmaptasks[i].setsize(0);
    packidx = allocidx = 0;
    lightmapping = GETIV(lightthreads);
    if(lightmapping > 1)
    {
        ALLOCLOCK(lightlock, SDL_CreateMutex);
        ALLOCLOCK(tasklock, SDL_CreateMutex);
        ALLOCLOCK(fullcond, SDL_CreateCond);
        ALLOCLOCK(emptycond, SDL_CreateCond);
    }
    while(lightmapworkers.length() < lightmapping) lightmapworkers.add(new lightmapworker);
    loopi(lightmapping)
    {
        lightmapworker *w = lightmapworkers[i];
        w->reset();
        if(lightmapping <= 1 || w->setupthread()) continue;
        w->cleanupthread();
        lightmapping = i >= 1 ? max(i, 2) : 1;
        break;
    }
    if(lightmapping <= 1) cleanuplocks();
}

static void cleanupthreads()
{
    processtasks(true);
    if(lightmapping > 1)
    {
        SDL_LockMutex(tasklock);
        loopv(lightmapworkers) lightmapworkers[i]->doneworking = true;
        SDL_CondBroadcast(fullcond);
        loopv(lightmapworkers)
        {
            lightmapworker *w = lightmapworkers[i];
            if(w->needspace && w->spacecond) SDL_CondSignal(w->spacecond);
        }
        SDL_UnlockMutex(tasklock);
        loopv(lightmapworkers) 
        {
            lightmapworker *w = lightmapworkers[i];
            if(w->thread) SDL_WaitThread(w->thread, NULL);
        }
    }
    loopv(lightmapworkers) lightmapworkers[i]->cleanupthread();
    cleanuplocks();
    lightmapping = 0;
}

void calclight(int *quality)
{
    if(!setlightmapquality(*quality))
    {
        conoutf(CON_ERROR, "valid range for calclight quality is -1..1"); 
        return;
    }
    renderbackground("computing lightmaps... (esc to abort)");
    mpremip(true);
    optimizeblendmap();
    loadlayermasks();
    resetlightmaps(false);
    clearsurfaces(worldroot);
    taskprogress = progress = 0;
    progresstexticks = 0;
    progresslightmap = -1;
    calclight_canceled = false;
    check_calclight_progress = false;
    SDL_TimerID timer = SDL_AddTimer(250, calclighttimer, NULL);
    Uint32 start = SDL_GetTicks();
    calcnormals();
    show_calclight_progress();
    setupthreads();
    generatelightmaps(worldroot, 0, 0, 0, GETIV(mapsize) >> 1);
    cleanupthreads();
    clearnormals();
    Uint32 end = SDL_GetTicks();
    if(timer) SDL_RemoveTimer(timer);
    uint total = 0, lumels = 0;
    loopv(lightmaps)
    {
        insertunlit(i);
        if(!editmode) lightmaps[i].finalize();
        total += lightmaps[i].lightmaps;
        lumels += lightmaps[i].lumels;
    }
    if(!editmode) compressed.clear();
    initlights();
    renderbackground("lighting done...");
    allchanged();
    if(calclight_canceled)
        conoutf("calclight aborted");
    else
        conoutf("generated %d lightmaps using %d%% of %d textures (%.1f seconds)",
            total,
            lightmaps.length() ? lumels * 100 / (lightmaps.length() * LM_PACKW * LM_PACKH) : 0,
            lightmaps.length(),
            (end - start) / 1000.0f);
}

void patchlight(int *quality)
{
    if(noedit(true)) return;
    if(!setlightmapquality(*quality))
    {
        conoutf(CON_ERROR, "valid range for patchlight quality is -1..1"); 
        return;
    }
    renderbackground("patching lightmaps... (esc to abort)");
    loadlayermasks();
    cleanuplightmaps();
    taskprogress = progress = 0;
    progresstexticks = 0;
    progresslightmap = -1;
    int total = 0, lumels = 0;
    loopv(lightmaps)
    {
        if((lightmaps[i].type&LM_TYPE) != LM_BUMPMAP1) progresslightmap = i;
        total -= lightmaps[i].lightmaps;
        lumels -= lightmaps[i].lumels;
    }
    calclight_canceled = false;
    check_calclight_progress = false;
    SDL_TimerID timer = SDL_AddTimer(250, calclighttimer, NULL);
    if(GETIV(patchnormals)) renderprogress(0, "computing normals...");
    Uint32 start = SDL_GetTicks();
    if(GETIV(patchnormals)) calcnormals();
    show_calclight_progress();
    setupthreads();
    generatelightmaps(worldroot, 0, 0, 0, GETIV(mapsize) >> 1);
    cleanupthreads();
    if(GETIV(patchnormals)) clearnormals();
    Uint32 end = SDL_GetTicks();
    if(timer) SDL_RemoveTimer(timer);
    loopv(lightmaps)
    {
        total += lightmaps[i].lightmaps;
        lumels += lightmaps[i].lumels;
    }
    initlights();
    renderbackground("lighting done...");
    allchanged();
    if(calclight_canceled)
        conoutf("patchlight aborted");
    else
        conoutf("patched %d lightmaps using %d%% of %d textures (%.1f seconds)",
            total,
            lightmaps.length() ? lumels * 100 / (lightmaps.length() * LM_PACKW * LM_PACKH) : 0,
            lightmaps.length(),
            (end - start) / 1000.0f); 
}

void clearlightmaps()
{
    if(noedit(true)) return;
    renderprogress(0, "clearing lightmaps...");
    resetlightmaps(false);
    clearsurfaces(worldroot);
    initlights();
    allchanged();
}

void setfullbrightlevel(int fullbrightlevel)
{
    if(lightmaptexs.length() > LMID_BRIGHT)
    {
        uchar bright[3] = { uchar(fullbrightlevel), uchar(fullbrightlevel), uchar(fullbrightlevel) };
        createtexture(lightmaptexs[LMID_BRIGHT].id, 1, 1, bright, 0, 1);
    }
    initlights();
}

vector<LightMapTexture> lightmaptexs;

static void rotatenormals(LightMap &lmlv, int x, int y, int w, int h, int rotate)
{
    bool flipx = rotate>=2 && rotate<=4,
         flipy = (rotate>=1 && rotate<=2) || rotate==5,
         swapxy = (rotate&5)==1;
    uchar *lv = lmlv.data + 3*(y*LM_PACKW + x);
    int stride = 3*(LM_PACKW-w);
    loopi(h)
    {
        loopj(w)
        {
            if(flipx) lv[0] = 255 - lv[0];
            if(flipy) lv[1] = 255 - lv[1];
            if(swapxy) swap(lv[0], lv[1]);
            lv += 3;
        }
        lv += stride;
    }
}

static void rotatenormals(cube *c)
{
    loopi(8)
    {
        cube &ch = c[i];
        if(ch.children)
        {
            rotatenormals(ch.children);
            continue;
        }
        else if(!ch.ext || !ch.ext->surfaces) continue;
        loopj(6) if(lightmaps.inrange(ch.ext->surfaces[j].lmid+1-LMID_RESERVED))
        {
            VSlot &vslot = lookupvslot(ch.texture[j], false);
            if(!vslot.rotation) continue;
            surfaceinfo &surface = ch.ext->surfaces[j];
            LightMap &lmlv = lightmaps[surface.lmid+1-LMID_RESERVED];
            if((lmlv.type&LM_TYPE)!=LM_BUMPMAP1) continue;
            rotatenormals(lmlv, surface.x, surface.y, surface.w, surface.h, vslot.rotation < 4 ? 4-vslot.rotation : vslot.rotation);
        }
    }
}

void fixlightmapnormals()
{
    rotatenormals(worldroot);
}

static void convertlightmap(LightMap &lmc, LightMap &lmlv, uchar *dst, size_t stride)
{
    const uchar *c = lmc.data;
    const bvec *lv = (const bvec *)lmlv.data;
    loopi(LM_PACKH)
    {
        uchar *dstrow = dst;
        loopj(LM_PACKW)
        {
            int z = int(lv->z)*2 - 255,
                r = (int(c[0]) * z) / 255,
                g = (int(c[1]) * z) / 255,
                b = (int(c[2]) * z) / 255;
            dstrow[0] = max(r, int(ambientcolor[0]));
            dstrow[1] = max(g, int(ambientcolor[1]));
            dstrow[2] = max(b, int(ambientcolor[2]));
            if(lmc.bpp==4) dstrow[3] = c[3];
            c += lmc.bpp;
            lv++;
            dstrow += lmc.bpp;
        }
        dst += stride;
    }
}

static void copylightmap(LightMap &lm, uchar *dst, size_t stride)
{
    const uchar *c = lm.data;
    loopi(LM_PACKH)
    {
        memcpy(dst, c, lm.bpp*LM_PACKW);
        c += lm.bpp*LM_PACKW;
        dst += stride;
    }
}

void genreservedlightmaptexs()
{
    while(lightmaptexs.length() < LMID_RESERVED)
    {
        LightMapTexture &tex = lightmaptexs.add();
        tex.type = GETIV(renderpath) != R_FIXEDFUNCTION && lightmaptexs.length()&1 ? LM_DIFFUSE : LM_BUMPMAP1;
        glGenTextures(1, &tex.id);
    }
    uchar unlit[3] = { ambientcolor[0], ambientcolor[1], ambientcolor[2] };
    createtexture(lightmaptexs[LMID_AMBIENT].id, 1, 1, unlit, 0, 1);
    bvec front(128, 128, 255);
    createtexture(lightmaptexs[LMID_AMBIENT1].id, 1, 1, &front, 0, 1);
    uchar bright[3] = { uchar(GETIV(fullbrightlevel)), uchar(GETIV(fullbrightlevel)), uchar(GETIV(fullbrightlevel)) };
    createtexture(lightmaptexs[LMID_BRIGHT].id, 1, 1, bright, 0, 1);
    createtexture(lightmaptexs[LMID_BRIGHT1].id, 1, 1, &front, 0, 1);
    uchar dark[3] = { 0, 0, 0 };
    createtexture(lightmaptexs[LMID_DARK].id, 1, 1, dark, 0, 1);
    createtexture(lightmaptexs[LMID_DARK1].id, 1, 1, &front, 0, 1);
}

static void findunlit(int i)
{
    LightMap &lm = lightmaps[i];
    if(lm.unlitx>=0) return;
    else if((lm.type&LM_TYPE)==LM_BUMPMAP0)
    {
        if(i+1>=lightmaps.length() || (lightmaps[i+1].type&LM_TYPE)!=LM_BUMPMAP1) return;
    }
    else if((lm.type&LM_TYPE)!=LM_DIFFUSE) return;
    uchar *data = lm.data;
    loop(y, 2) loop(x, LM_PACKW)
    {
        if(!data[0] && !data[1] && !data[2])
        {
            memcpy(data, ambientcolor.v, 3);
            if((lm.type&LM_TYPE)==LM_BUMPMAP0) ((bvec *)lightmaps[i+1].data)[y*LM_PACKW + x] = bvec(128, 128, 255);
            lm.unlitx = x;
            lm.unlity = y;
            return;
        }
        if(data[0]==ambientcolor[0] && data[1]==ambientcolor[1] && data[2]==ambientcolor[2])
        {
            if((lm.type&LM_TYPE)!=LM_BUMPMAP0 || ((bvec *)lightmaps[i+1].data)[y*LM_PACKW + x] == bvec(128, 128, 255))
            {
                lm.unlitx = x;
                lm.unlity = y;
                return;
            }
        }
        data += lm.bpp;
    }
}

void genlightmaptexs(int flagmask, int flagval)
{
    if(lightmaptexs.length() < LMID_RESERVED) genreservedlightmaptexs();

    int remaining[3] = { 0, 0, 0 }, total = 0; 
    loopv(lightmaps) 
    {
        LightMap &lm = lightmaps[i];
        if(lm.tex >= 0 || (lm.type&flagmask)!=flagval) continue;
        int type = lm.type&LM_TYPE;
        remaining[type]++; 
        total++;
        if(lm.unlitx < 0) findunlit(i);
    }

    if(GETIV(renderpath)==R_FIXEDFUNCTION)
    {
        remaining[LM_DIFFUSE] += remaining[LM_BUMPMAP0];
        remaining[LM_BUMPMAP0] = remaining[LM_BUMPMAP1] = 0;
    }

    int sizelimit = (GETIV(maxtexsize) ? min(GETIV(maxtexsize), GETIV(hwtexsize)) : GETIV(hwtexsize))/max(LM_PACKW, LM_PACKH);
    sizelimit = min(GETIV(batchlightmaps), sizelimit*sizelimit);
    while(total)
    {
        int type = LM_DIFFUSE;
        LightMap *firstlm = NULL;
        loopv(lightmaps)
        {
            LightMap &lm = lightmaps[i];
            if(lm.tex >= 0 || (lm.type&flagmask) != flagval) continue;
            if(GETIV(renderpath) != R_FIXEDFUNCTION) type = lm.type&LM_TYPE;
            else if((lm.type&LM_TYPE) == LM_BUMPMAP1) continue;
            firstlm = &lm; 
            break; 
        }
        if(!firstlm) break;
        int used = 0, uselimit = min(remaining[type], sizelimit);
        do used++; while((1<<used) <= uselimit);
        used--;
        int oldval = remaining[type];
        remaining[type] -= 1<<used;
        if(remaining[type] && (2<<used) <= min(GETIV(roundlightmaptex), sizelimit))
        {
            remaining[type] -= min(remaining[type], 1<<used);
            used++;
        }
        total -= oldval - remaining[type];
        LightMapTexture &tex = lightmaptexs.add();
        tex.type = firstlm->type;
        tex.w = LM_PACKW<<((used+1)/2);
        tex.h = LM_PACKH<<(used/2);
        int bpp = firstlm->bpp;
        uchar *data = used || (GETIV(renderpath) == R_FIXEDFUNCTION && (firstlm->type&LM_TYPE) == LM_BUMPMAP0 && GETIV(convertlms)) ? 
            new uchar[bpp*tex.w*tex.h] : 
            NULL;
        int offsetx = 0, offsety = 0;
        loopv(lightmaps)
        {
            LightMap &lm = lightmaps[i];
            if(lm.tex >= 0 || (lm.type&flagmask) != flagval || 
               (GETIV(renderpath)==R_FIXEDFUNCTION ? 
                (lm.type&LM_TYPE) == LM_BUMPMAP1 : 
                (lm.type&LM_TYPE) != type))
                continue;

            lm.tex = lightmaptexs.length()-1;
            lm.offsetx = offsetx;
            lm.offsety = offsety;
            if(tex.unlitx < 0 && lm.unlitx >= 0) 
            { 
                tex.unlitx = offsetx + lm.unlitx; 
                tex.unlity = offsety + lm.unlity;
            }

            if(data)
            {
                if(GETIV(renderpath) == R_FIXEDFUNCTION && (lm.type&LM_TYPE) == LM_BUMPMAP0 && GETIV(convertlms))
                    convertlightmap(lm, lightmaps[i+1], &data[bpp*(offsety*tex.w + offsetx)], bpp*tex.w);
                else copylightmap(lm, &data[bpp*(offsety*tex.w + offsetx)], bpp*tex.w);
            }

            offsetx += LM_PACKW;
            if(offsetx >= tex.w) { offsetx = 0; offsety += LM_PACKH; }
            if(offsety >= tex.h) break;
        }
        
        glGenTextures(1, &tex.id);
        createtexture(tex.id, tex.w, tex.h, data ? data : firstlm->data, 3, 1, bpp==4 ? GL_RGBA : GL_RGB);
        if(data) delete[] data;
    }        
}

bool brightengeom = false;

void clearlights()
{
    clearlightcache();
    const vector<extentity *> &ents = entities::getents();
    loopv(ents)
    {
        extentity &e = *ents[i];
        e.light.color = vec(1, 1, 1);
        e.light.dir = vec(0, 0, 1);
    }
    if(GETIV(nolights)) return;

    genlightmaptexs(LM_ALPHA, 0);
    genlightmaptexs(LM_ALPHA, LM_ALPHA);
    brightengeom = true;
}

void lightent(extentity &e, float height)
{
    if(e.type==ET_LIGHT) return;
    float ambient = 0.0f;
    if(e.type==ET_MAPMODEL)
    {
        LogicEntityPtr entity = LogicSystem::getLogicEntity(e); // INTENSITY
        model *m = entity.get() ? entity->getModel() : NULL; // INTENSITY
        if(m) height = m->above()*0.75f;
    }
    else if(e.type>=ET_GAMESPECIFIC) ambient = 0.4f;
    vec target(e.o.x, e.o.y, e.o.z + height);
    lightreaching(target, e.light.color, e.light.dir, false, &e, ambient);
}

void updateentlighting()
{
    const vector<extentity *> &ents = entities::getents();
    loopv(ents) lightent(*ents[i]);
}

void initlights()
{
    if(GETIV(nolights) || (GETIV(fullbright) && editmode) || lightmaps.empty())
    {
        clearlights();
        return;
    }

    clearlightcache();
    updateentlighting();
    genlightmaptexs(LM_ALPHA, 0);
    genlightmaptexs(LM_ALPHA, LM_ALPHA);
    brightengeom = false;
}

static inline void fastskylight(const vec &o, float tolerance, uchar *skylight, int flags = RAY_ALPHAPOLY, extentity *t = NULL, bool fast = false)
{
    flags |= RAY_SHADOW;
    if(GETIV(skytexturelight)) flags |= RAY_SKIPSKY;
    if(fast)
    {
        static const vec ray(0, 0, 1);
        if(shadowray(vec(ray).mul(tolerance).add(o), ray, 1e16f, flags, t)>1e15f)
            memcpy(skylight, skylightcolor.v, 3);
        else memcpy(skylight, ambientcolor.v, 3);
    }
    else
    {
        static const vec rays[5] =
        {
            vec(cosf(66*RAD)*cosf(65*RAD), sinf(66*RAD)*cosf(65*RAD), sinf(65*RAD)),
            vec(cosf(156*RAD)*cosf(65*RAD), sinf(156*RAD)*cosf(65*RAD), sinf(65*RAD)),
            vec(cosf(246*RAD)*cosf(65*RAD), sinf(246*RAD)*cosf(65*RAD), sinf(65*RAD)),
            vec(cosf(336*RAD)*cosf(65*RAD), sinf(336*RAD)*cosf(65*RAD), sinf(65*RAD)),
            vec(0, 0, 1),
        };
        int hit = 0;
        loopi(5) if(shadowray(vec(rays[i]).mul(tolerance).add(o), rays[i], 1e16f, flags, t)>1e15f) hit++;
        loopk(3) skylight[k] = uchar(ambientcolor[k] + (max(skylightcolor[k], ambientcolor[k]) - ambientcolor[k])*hit/5.0f);
    }
}

void lightreaching(const vec &target, vec &color, vec &dir, bool fast, extentity *t, float ambient)
{
    if(GETIV(nolights) || (GETIV(fullbright) && editmode) || lightmaps.empty())
    {
        color = vec(1, 1, 1);
        dir = vec(0, 0, 1);
        return;
    }

    color = dir = vec(0, 0, 0);
    const vector<extentity *> &ents = entities::getents();
    const vector<int> &lights = checklightcache(int(target.x), int(target.y));
    loopv(lights)
    {
        extentity &e = *ents[lights[i]];
        if(e.type != ET_LIGHT)
            continue;
    
        vec ray(target);
        ray.sub(e.o);
        float mag = ray.magnitude();
        if(e.attr1 && mag >= float(e.attr1))
            continue;
    
        ray.div(mag);
        if(shadowray(e.o, ray, mag, RAY_SHADOW | RAY_POLY, t) < mag)
            continue;
        float intensity = 1;
        if(e.attr1)
            intensity -= mag / float(e.attr1);
        if(e.attached && e.attached->type==ET_SPOTLIGHT)
        {
            vec spot(vec(e.attached->o).sub(e.o).normalize());
            float maxatten = 1-cosf(max(1, min(90, int(e.attached->attr1)))*RAD);
            float spotatten = 1-(1-ray.dot(spot))/maxatten;
            if(spotatten<=0) continue;
            intensity *= spotatten;
        }

        //if(target==player->o)
        //{
        //    conoutf(CON_DEBUG, "%d - %f %f", i, intensity, mag);
        //}
 
        color.add(vec(e.attr2, e.attr3, e.attr4).div(255).mul(intensity));

        intensity *= e.attr2*e.attr3*e.attr4;

        if(fabs(mag)<1e-3) dir.add(vec(0, 0, 1));
        else dir.add(vec(e.o).sub(target).mul(intensity/mag));
    }

    if(hasskylight())
    {
        uchar skylight[3];
        if(t) calcskylight(NULL, target, vec(0, 0, 0), 0.5f, skylight, RAY_POLY, t);
        else fastskylight(target, 0.5f, skylight, RAY_POLY, t, fast);
        loopk(3) color[k] = min(1.5f, max(max(skylight[k]/255.0f, ambient), color[k]));
    }
    else loopk(3) color[k] = min(1.5f, max(max(ambientcolor[k]/255.0f, ambient), color[k]));
    if(dir.iszero()) dir = vec(0, 0, 1);
    else dir.normalize();
}

entity *brightestlight(const vec &target, const vec &dir)
{
    const vector<extentity *> &ents = entities::getents();
    const vector<int> &lights = checklightcache(int(target.x), int(target.y));
    extentity *brightest = NULL;
    float bintensity = 0;
    loopv(lights)
    {
        extentity &e = *ents[lights[i]];
        if(e.type != ET_LIGHT || vec(e.o).sub(target).dot(dir)<0)
            continue;

        vec ray(target);
        ray.sub(e.o);
        float mag = ray.magnitude();
        if(e.attr1 && mag >= float(e.attr1))
             continue;

        ray.div(mag);
        if(shadowray(e.o, ray, mag, RAY_SHADOW | RAY_POLY) < mag)
            continue;
        float intensity = 1;
        if(e.attr1)
            intensity -= mag / float(e.attr1);
        if(e.attached && e.attached->type==ET_SPOTLIGHT)
        {
            vec spot(vec(e.attached->o).sub(e.o).normalize());
            float maxatten = 1-cosf(max(1, min(90, int(e.attached->attr1)))*RAD);
            float spotatten = 1-(1-ray.dot(spot))/maxatten;
            if(spotatten<=0) continue;
            intensity *= spotatten;
        }

        if(!brightest || intensity > bintensity)
        {
            brightest = &e;
            bintensity = intensity;
        }
    }
    return brightest;
}

void brightencube(cube &c)
{
    if(c.ext && c.ext->surfaces)
    {
        if(c.ext->surfaces==brightsurfaces) return;
        freesurfaces(c);
    }
    ext(c).surfaces = brightsurfaces;
}
        
void newsurfaces(cube &c, const surfaceinfo *surfs, int numsurfs)
{
    if(!c.ext) newcubeext(c);
    if(!c.ext->surfaces || c.ext->surfaces==brightsurfaces)
    {
        c.ext->surfaces = new surfaceinfo[numsurfs];
        memcpy(c.ext->surfaces, surfs, numsurfs*sizeof(surfaceinfo));
    }
}

void freesurfaces(cube &c)
{
    if(c.ext)
    {
        if(c.ext->surfaces==brightsurfaces) c.ext->surfaces = NULL;
        else DELETEA(c.ext->surfaces);
    }
}

void dumplms()
{
    loopv(lightmaps)
    {
        ImageData temp(LM_PACKW, LM_PACKH, lightmaps[i].bpp, lightmaps[i].data);
        const char *map = game::getclientmap(), *name = strrchr(map, '/');
        defformatstring(buf)("lightmap_%s_%d.png", name ? name+1 : map, i);
        savepng(buf, temp, true);
    }
}
