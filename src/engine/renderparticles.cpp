// renderparticles.cpp

#include "engine.h"

Shader *particleshader = NULL, *particlenotextureshader = NULL, *particlesoftshader = NULL, *particletextshader = NULL;

FVARP(particlebright, 0, 2, 100);
VARP(particlesize, 20, 100, 500);

VARP(softparticles, 0, 1, 1);
VARP(softparticleblend, 1, 8, 64);
    
// Check emit_particles() to limit the rate that paricles can be emitted for models/sparklies
// Automatically stops particles being emitted when paused or in reflective drawing
VARP(emitmillis, 1, 17, 1000);
static int lastemitframe = 0, emitoffset = 0;
static bool canemit = false, regenemitters = false;

static bool emit_particles()
{
    return canemit || emitoffset;
}

VARP(showparticles, 0, 1, 1);
VAR(cullparticles, 0, 1, 1);
VAR(replayparticles, 0, 1, 1);
VARN(seedparticles, seedmillis, 0, 3000, 10000);
VAR(dbgpcull, 0, 0, 1);
VAR(dbgpseed, 0, 0, 1);

struct particleemitter
{
    extentity *ent;
    vec bbmin, bbmax;
    vec center;
    float radius;
    ivec bborigin, bbsize;
    int maxfade, lastemit, lastcull;

    particleemitter(extentity *ent)
        : ent(ent), bbmin(ent->o), bbmax(ent->o), maxfade(-1), lastemit(0), lastcull(0)
    {}

    void finalize()
    {
        center = vec(bbmin).add(bbmax).mul(0.5f);
        radius = bbmin.dist(bbmax)/2;
        bborigin = ivec(int(floor(bbmin.x)), int(floor(bbmin.y)), int(floor(bbmin.z)));
        bbsize = ivec(int(ceil(bbmax.x)), int(ceil(bbmax.y)), int(ceil(bbmax.z))).sub(bborigin);
        if(dbgpseed) conoutf(CON_DEBUG, "radius: %f, maxfade: %d", radius, maxfade);
    }
    
    void extendbb(const vec &o, float size = 0)
    {
        bbmin.x = min(bbmin.x, o.x - size);
        bbmin.y = min(bbmin.y, o.y - size);
        bbmin.z = min(bbmin.z, o.z - size);
        bbmax.x = max(bbmax.x, o.x + size);
        bbmax.y = max(bbmax.y, o.y + size);
        bbmax.z = max(bbmax.z, o.z + size);
    }

    void extendbb(float z, float size = 0)
    {
        bbmin.z = min(bbmin.z, z - size);
        bbmax.z = max(bbmax.z, z + size);
    }
};

static vector<particleemitter> emitters;
static particleemitter *seedemitter = NULL;

void clearparticleemitters()
{
    emitters.shrink(0);
    regenemitters = true;
}

void addparticleemitters()
{
    emitters.shrink(0);
    const vector<extentity *> &ents = entities::getents();
    loopv(ents)
    {
        extentity &e = *ents[i];
        if(e.type != ET_PARTICLES) continue;
        emitters.add(particleemitter(&e));
    }
    regenemitters = false;
}

enum
{
    PT_PART = 0,
    PT_TAPE,
    PT_TRAIL,
    PT_TEXT,
    PT_TEXTUP,
    PT_METER,
    PT_METERVS,
    PT_FIREBALL,
    PT_LIGHTNING,
    PT_FLARE,

    PT_MOD       = 1<<8,
    PT_RND4      = 1<<9,
    PT_LERP      = 1<<10, // use very sparingly - order of blending issues
    PT_TRACK     = 1<<11,
    PT_BRIGHT    = 1<<12,
    PT_SOFT      = 1<<13,
    PT_HFLIP     = 1<<14,
    PT_VFLIP     = 1<<15,
    PT_ROT       = 1<<16,
    PT_FEW       = 1<<17,
    PT_ICON      = 1<<18,
    PT_NOTEX     = 1<<19,
    PT_SHRINK    = 1<<20,
    PT_GROW      = 1<<21,
    PT_SHADER    = 1<<22,
    PT_SWIZZLE   = 1<<23,
    PT_FLIP      = PT_HFLIP | PT_VFLIP | PT_ROT
};

const char *partnames[] = { "part", "tape", "trail", "text", "textup", "meter", "metervs", "fireball", "lightning", "flare" };

struct particle
{
    vec o, d;
    int gravity, fade, millis;
    bvec color;
    uchar flags;
    float size, val;
    physent *owner;
    union
    {
        const char *text;
        Texture *tex;
        struct
        {
            uchar color2[3];
            uchar progress;
        };
    };
};

/* can be changed into something more sophisticated when multiple
 * metatables are needed, for now there is just one
 */
static particle *luacheckpart(lua_State *L, int idx) {
    particle **part = (particle**)luaL_checkudata(L, idx, "Particle");
    luaL_argcheck(L, part != NULL, idx, "'Particle' expected");
    return *part;
}

#define PART_ACCESSOR(field, func, setfunc) \
static int particle_get_##field(lua_State *L) { \
    particle *part = luacheckpart(L, 1); \
    lua_push##func(L, part->field); \
    return 1; \
} \
static int particle_set_##field(lua_State *L) { \
    particle *part = luacheckpart(L, 1); \
    part->field = luaL_check##setfunc(L, 2); \
    return 0; \
}

PART_ACCESSOR(gravity, integer, integer)
PART_ACCESSOR(fade, integer, integer)
PART_ACCESSOR(size, number, number)
PART_ACCESSOR(val, number, number)

static int particle_get_owner(lua_State *L) {
    particle *part = luacheckpart(L, 1);
    if (!part->owner) { lua_pushnil(L); return 1; }
    CLogicEntity *ent = LogicSystem::getLogicEntity(part->owner);
    if (!ent) { lua_pushnil(L); return 1; }
    lua_rawgeti(L, LUA_REGISTRYINDEX, ent->lua_ref);
    return 1;
}
static int particle_set_owner(lua_State *L) {
    particle *part = luacheckpart(L, 1);
    lua::push_external(L, "entity_get_attr");
    lua_pushvalue(L, 2);
    lua_pushliteral(L, "uid");
    lua_call(L, 2, 1);
    int uid = lua_tointeger(L, -1); lua_pop(L, 1);
    CLogicEntity *ent = LogicSystem::getLogicEntity(uid);
    assert(ent && ent->dynamicEntity);
    part->owner = ent->dynamicEntity;
    return 0;
}

#define PART_VEC_ACCESSOR(prefix, field) \
static int particle_get_##prefix##field(lua_State *L) { \
    particle *part = luacheckpart(L, 1); \
    lua_pushnumber(L, part->prefix.field); \
    return 1; \
} \
static int particle_set_##prefix##field(lua_State *L) { \
    particle *part = luacheckpart(L, 1); \
    part->prefix.field = luaL_checknumber(L, 2); \
    return 0; \
}

PART_VEC_ACCESSOR(o, x)
PART_VEC_ACCESSOR(o, y)
PART_VEC_ACCESSOR(o, z)
PART_VEC_ACCESSOR(d, x)
PART_VEC_ACCESSOR(d, y)
PART_VEC_ACCESSOR(d, z)

struct partvert
{
    vec pos;
    float u, v;
    bvec color;
    uchar alpha;
};

#define COLLIDERADIUS 8.0f
#define COLLIDEERROR 1.0f

void adddecal(int type, const vec &center, const vec &surface, float radius, const bvec &color = bvec(0xFF, 0xFF, 0xFF), int info = 0);

struct partrenderer
{
    Texture *tex;
    const char *texname;
    int texclamp;
    uint type;
    int collide;
   
    partrenderer(const char *texname, int texclamp, int type, int collide = 0)
        : tex(NULL), texname(texname), texclamp(texclamp), type(type), collide(collide)
    {
    }
    partrenderer(int type, int collide = 0)
        : tex(NULL), texname(NULL), texclamp(0), type(type), collide(collide)
    {
    }
    virtual ~partrenderer()
    {
    }

    virtual void init(int n) { }
    virtual void reset() = 0;
    virtual void resettracked(physent *owner) { }   
    virtual particle *addpart(const vec &o, const vec &d, int fade, int color, float size, int gravity = 0) = 0;    
    virtual void update() { }
    virtual void render() = 0;
    virtual bool haswork() = 0;
    virtual int count() = 0; //for debug
    virtual void cleanup() {}

#define PART_MT_FIELD(field) \
    lua_pushcfunction(L, particle_get_##field); \
    lua_setfield(L, -2, "get_" #field); \
    lua_pushcfunction(L, particle_set_##field); \
    lua_setfield(L, -2, "set_" #field);

    virtual void set_part_mt(lua_State *L) {
        if (luaL_newmetatable(L, "Particle")) {
            lua_createtable(L, 0, 0);
            PART_MT_FIELD(gravity)
            PART_MT_FIELD(fade)
            PART_MT_FIELD(size)
            PART_MT_FIELD(val)
            PART_MT_FIELD(owner)
            PART_MT_FIELD(ox)
            PART_MT_FIELD(oy)
            PART_MT_FIELD(oz)
            PART_MT_FIELD(dx)
            PART_MT_FIELD(dy)
            PART_MT_FIELD(dz)
            lua_setfield(L, -2, "__index");
        }
        lua_setmetatable(L, -2);
    }

    virtual void seedemitter(particleemitter &pe, const vec &o, const vec &d, int fade, float size, int gravity)
    {
    }

    virtual void preload()
    {
        if(texname && !tex) tex = textureload(texname, texclamp);
    }

    //blend = 0 => remove it
    void calc(particle *p, int &blend, int &ts, float &size, vec &o, vec &d)
    {
        o = p->o;
        d = p->d;
        if(type&PT_TRACK && p->owner) game::particletrack(p->owner, o, d);
        if(p->fade <= 5) 
        {
            ts = 1;
            blend = 255;
            size = p->size;
        }
        else
        {
            ts = lastmillis-p->millis;
            blend = max(255 - (ts<<8)/p->fade, 0);
            int weight = p->gravity;
            /* RE */
            if((type&PT_SHRINK || type&PT_GROW) && p->fade >= 50)
            {
                float amt = clamp(ts/float(p->fade), 0.0f, 1.0f);
                if(type&PT_SHRINK)
                {
                    if(type&PT_GROW) { if ((amt *= 2) > 1) amt = 2 - amt; amt *= amt; }
                    else amt = 1 - (amt * amt);
                }
                else amt *= amt;
                size = p->size * amt;
                if(weight) weight += weight * (p->size - size);
            }
            else size = p->size;
            if(weight)
            {
                if(ts > p->fade) ts = p->fade;
                float t = ts;
                o.add(vec(d).mul(t/5000.0f));
                o.z -= t*t/(2.0f * 5000.0f * weight);
            }
            if(collide && o.z < p->val)
            {
                if(collide >= 0)
                {
                    vec surface;
                    float floorz = rayfloor(vec(o.x, o.y, p->val), surface, RAY_CLIPMAT, COLLIDERADIUS);
                    float collidez = floorz<0 ? o.z-COLLIDERADIUS : p->val - floorz;
                    if(o.z >= collidez+COLLIDEERROR) 
                        p->val = collidez+COLLIDEERROR;
                    else 
                    {
                        adddecal(collide, vec(o.x, o.y, collidez), vec(p->o).sub(o).normalize(), 2*size, p->color, type&PT_RND4 ? (p->flags>>5)&3 : 0);
                        blend = 0;
                    }
                }
                else blend = 0;
            }
        }
    }
};

struct listparticle : particle
{   
    listparticle *next;
};

VARP(outlinemeters, 0, 0, 1);

struct listrenderer : partrenderer
{
    static listparticle *parempty;
    listparticle *list;

    listrenderer(const char *texname, int texclamp, int type, int collide = 0) 
        : partrenderer(texname, texclamp, type, collide), list(NULL)
    {
    }
    listrenderer(int type, int collide = 0)
        : partrenderer(type, collide), list(NULL)
    {
    }

    virtual ~listrenderer()
    {
    }

    virtual void killpart(listparticle *p)
    {
    }

    void reset()  
    {
        if(!list) return;
        listparticle *p = list;
        for(;;)
        {
            killpart(p);
            if(p->next) p = p->next;
            else break;
        }
        p->next = parempty;
        parempty = list;
        list = NULL;
    }
    
    void resettracked(physent *owner) 
    {
        if(!(type&PT_TRACK)) return;
        for(listparticle **prev = &list, *cur = list; cur; cur = *prev)
        {
            if(!owner || cur->owner==owner) 
            {
                *prev = cur->next;
                cur->next = parempty;
                parempty = cur;
            }
            else prev = &cur->next;
        }
    }
    
    particle *addpart(const vec &o, const vec &d, int fade, int color, float size, int gravity) 
    {
        if(!parempty)
        {
            listparticle *ps = new listparticle[256];
            loopi(255) ps[i].next = &ps[i+1];
            ps[255].next = parempty;
            parempty = ps;
        }
        listparticle *p = parempty;
        parempty = p->next;
        p->next = list;
        list = p;
        p->o = o;
        p->d = d;
        p->gravity = gravity;
        p->fade = fade;
        p->millis = lastmillis + emitoffset;
        p->color = bvec(color>>16, (color>>8)&0xFF, color&0xFF);
        p->size = size;
        p->val  = 0;
        p->owner = NULL;
        p->flags = 0;
        return p;
    }

    int count() 
    {
        int num = 0;
        listparticle *lp;
        for(lp = list; lp; lp = lp->next) num++;
        return num;
    }
    
    bool haswork() 
    {
        return (list != NULL);
    }
    
    virtual void startrender() = 0;
    virtual void endrender() = 0;
    virtual void renderpart(listparticle *p, const vec &o, const vec &d, int blend, int ts, float size) = 0;

    void render() 
    {
        startrender();
        if(tex) glBindTexture(GL_TEXTURE_2D, tex->id);
        
        for(listparticle **prev = &list, *p = list; p; p = *prev)
        {   
            vec o, d;
            int blend, ts;
            float size;
            calc(p, blend, ts, size, o, d);
            if(blend > 0) 
            {
                renderpart(p, o, d, blend, ts, size);

                if(p->fade > 5)
                {
                    prev = &p->next;
                    continue;
                }
            }
            //remove
            *prev = p->next;
            p->next = parempty;
            killpart(p);
            parempty = p;
        }
       
        endrender();
    }
};

listparticle *listrenderer::parempty = NULL;

struct meterrenderer : listrenderer
{
    meterrenderer(int type)
        : listrenderer(type|PT_NOTEX|PT_LERP)
    {}

    void startrender()
    {
         glDisable(GL_BLEND);
         gle::defvertex();
    }

    void endrender()
    {
         gle::disable();
         glEnable(GL_BLEND);
    }

    void renderpart(listparticle *p, const vec &o, const vec &d, int blend, int ts, float size)
    {
        int basetype = type&0xFF;
        float scale = FONTH*size/80.0f, right = 8, left = p->progress/100.0f*right;
        matrix3x4 m(vec4(camright.x, -camup.x, -camdir.x, o.x),
                    vec4(camright.y, -camup.y, -camdir.y, o.y),
                    vec4(camright.z, -camup.z, -camdir.z, o.z));
        m.scale(scale);
        m.translate(-right/2.0f, 0, 0);

        if(outlinemeters)
        {
            gle::colorf(0, 0.8f, 0);
            gle::begin(GL_TRIANGLE_STRIP);
            loopk(10)
            {
                const vec2 &sc = sincos360[k*(180/(10-1))];
                float c = (0.5f + 0.1f)*sc.y, s = 0.5f - (0.5f + 0.1f)*sc.x;
                gle::attrib(m.transform(vec2(-c, s)));
                gle::attrib(m.transform(vec2(right + c, s)));
            }
            gle::end();
        }

        if(basetype==PT_METERVS) gle::colorub(p->color2[0], p->color2[1], p->color2[2]);
        else gle::colorf(0, 0, 0);
        gle::begin(GL_TRIANGLE_STRIP);
        loopk(10)
        {
            const vec2 &sc = sincos360[k*(180/(10-1))];
            float c = 0.5f*sc.y, s = 0.5f - 0.5f*sc.x;
            gle::attrib(m.transform(vec2(left + c, s)));
            gle::attrib(m.transform(vec2(right + c, s))); 
        }
        gle::end();

        if(outlinemeters)
        {
            gle::colorf(0, 0.8f, 0);
            gle::begin(GL_TRIANGLE_FAN);
            loopk(10)
            {
                const vec2 &sc = sincos360[k*(180/(10-1))];
                float c = (0.5f + 0.1f)*sc.y, s = 0.5f - (0.5f + 0.1f)*sc.x;
                gle::attrib(m.transform(vec2(left + c, s)));
            }
            gle::end();
        }

        gle::color(p->color);
        gle::begin(GL_TRIANGLE_STRIP);
        loopk(10)
        {
            const vec2 &sc = sincos360[k*(180/(10-1))];
            float c = 0.5f*sc.y, s = 0.5f - 0.5f*sc.x;
            gle::attrib(m.transform(vec2(-c, s)));
            gle::attrib(m.transform(vec2(left + c, s)));
        }
        gle::end();
    }
};
static meterrenderer meters(PT_METER), metervs(PT_METERVS);

struct textrenderer : listrenderer
{
    textrenderer(int type = 0)
        : listrenderer(type|PT_TEXT|PT_LERP|PT_SHADER)
    {}

    void startrender()
    {
        textshader = particletextshader;
    }

    void endrender()
    {
        textshader = NULL;
    }

    void killpart(listparticle *p)
    {
        if(p->text) delete[] p->text;
    }

    void renderpart(listparticle *p, const vec &o, const vec &d, int blend, int ts, float size)
    {
        float scale = size/80.0f, xoff = -text_width(p->text)/2, yoff = 0;
        if((type&0xFF)==PT_TEXTUP) { xoff += detrnd((size_t)p, 100)-50; yoff -= detrnd((size_t)p, 101); }

        matrix3x4 m(vec4(camright.x, -camup.x, -camdir.x, o.x),
                    vec4(camright.y, -camup.y, -camdir.y, o.y),
                    vec4(camright.z, -camup.z, -camdir.z, o.z));
        m.scale(scale);
        m.translate(xoff, yoff, 50);

        textmatrix = &m;
        draw_text(p->text, 0, 0, p->color.r, p->color.g, p->color.b, blend);
        textmatrix = NULL;
    } 
};
static textrenderer texts;

/* OF */
struct iconrenderer: listrenderer {
    Texture *prevtex;

    iconrenderer(int type = 0): listrenderer(type|PT_LERP), prevtex(NULL) {}

    void startrender() {
        prevtex = NULL;
        gle::defvertex();
        gle::deftexcoord0();
    }

    void endrender() {
        gle::disable();
    }

    void renderpart(listparticle *p, const vec &o, const vec &d, int blend, int ts, float size) {
        Texture *tex = p->tex;
        if (!tex) return;
        if (tex != prevtex) {
            glBindTexture(GL_TEXTURE_2D, tex->id);
            prevtex = tex;
        }
        matrix3x4 m(vec4(camright.x, -camup.x, -camdir.x, o.x),
                    vec4(camright.y, -camup.y, -camdir.y, o.y),
                    vec4(camright.z, -camup.z, -camdir.z, o.z));
        m.scale(size);
        m.translate(-0.5f, -0.5f, 0);

        gle::color(p->color, blend);
        gle::begin(GL_TRIANGLE_STRIP);
        gle::attrib(m.transform(vec2(0, 0))); gle::attribf(0, 0);
        gle::attrib(m.transform(vec2(1, 0))); gle::attribf(1, 0);
        gle::attrib(m.transform(vec2(0, 1))); gle::attribf(0, 1);
        gle::attrib(m.transform(vec2(1, 1))); gle::attribf(1, 1);
        gle::end();
    }
};
static iconrenderer icons;

template<int T>
static inline void modifyblend(const vec &o, int &blend)
{
    blend = min(blend<<2, 255);
}

template<>
inline void modifyblend<PT_TAPE>(const vec &o, int &blend)
{
}

template<int T>
static inline void genpos(const vec &o, const vec &d, float size, int grav, int ts, partvert *vs)
{
    vec udir = vec(camup).sub(camright).mul(size);
    vec vdir = vec(camup).add(camright).mul(size);
    vs[0].pos = vec(o.x + udir.x, o.y + udir.y, o.z + udir.z);
    vs[1].pos = vec(o.x + vdir.x, o.y + vdir.y, o.z + vdir.z);
    vs[2].pos = vec(o.x - udir.x, o.y - udir.y, o.z - udir.z);
    vs[3].pos = vec(o.x - vdir.x, o.y - vdir.y, o.z - vdir.z);
}

template<>
inline void genpos<PT_TAPE>(const vec &o, const vec &d, float size, int ts, int grav, partvert *vs)
{
    vec dir1 = d, dir2 = d, c;
    dir1.sub(o);
    dir2.sub(camera1->o);
    c.cross(dir2, dir1).normalize().mul(size);
    vs[0].pos = vec(d.x-c.x, d.y-c.y, d.z-c.z);
    vs[1].pos = vec(o.x-c.x, o.y-c.y, o.z-c.z);
    vs[2].pos = vec(o.x+c.x, o.y+c.y, o.z+c.z);
    vs[3].pos = vec(d.x+c.x, d.y+c.y, d.z+c.z);
}

template<>
inline void genpos<PT_TRAIL>(const vec &o, const vec &d, float size, int ts, int grav, partvert *vs)
{
    vec e = d;
    if(grav) e.z -= float(ts)/grav;
    e.div(-75.0f).add(o);
    genpos<PT_TAPE>(o, e, size, ts, grav, vs);
}

template<int T>
static inline void genrotpos(const vec &o, const vec &d, float size, int grav, int ts, partvert *vs, int rot)
{
    genpos<T>(o, d, size, grav, ts, vs);
}

#define ROTCOEFFS(n) { \
    vec(-1,  1, 0).rotate_around_z(n*2*M_PI/32.0f), \
    vec( 1,  1, 0).rotate_around_z(n*2*M_PI/32.0f), \
    vec( 1, -1, 0).rotate_around_z(n*2*M_PI/32.0f), \
    vec(-1, -1, 0).rotate_around_z(n*2*M_PI/32.0f) \
}
static const vec rotcoeffs[32][4] =
{
    ROTCOEFFS(0),  ROTCOEFFS(1),  ROTCOEFFS(2),  ROTCOEFFS(3),  ROTCOEFFS(4),  ROTCOEFFS(5),  ROTCOEFFS(6),  ROTCOEFFS(7),
    ROTCOEFFS(8),  ROTCOEFFS(9),  ROTCOEFFS(10), ROTCOEFFS(11), ROTCOEFFS(12), ROTCOEFFS(13), ROTCOEFFS(14), ROTCOEFFS(15),
    ROTCOEFFS(16), ROTCOEFFS(17), ROTCOEFFS(18), ROTCOEFFS(19), ROTCOEFFS(20), ROTCOEFFS(21), ROTCOEFFS(22), ROTCOEFFS(7),
    ROTCOEFFS(24), ROTCOEFFS(25), ROTCOEFFS(26), ROTCOEFFS(27), ROTCOEFFS(28), ROTCOEFFS(29), ROTCOEFFS(30), ROTCOEFFS(31),
};

template<>
inline void genrotpos<PT_PART>(const vec &o, const vec &d, float size, int grav, int ts, partvert *vs, int rot)
{
    const vec *coeffs = rotcoeffs[rot];
    (vs[0].pos = o).add(vec(camright).mul(coeffs[0].x*size)).add(vec(camup).mul(coeffs[0].y*size));
    (vs[1].pos = o).add(vec(camright).mul(coeffs[1].x*size)).add(vec(camup).mul(coeffs[1].y*size));
    (vs[2].pos = o).add(vec(camright).mul(coeffs[2].x*size)).add(vec(camup).mul(coeffs[2].y*size));
    (vs[3].pos = o).add(vec(camright).mul(coeffs[3].x*size)).add(vec(camup).mul(coeffs[3].y*size));
}

template<int T>
static inline void seedpos(particleemitter &pe, const vec &o, const vec &d, int fade, float size, int grav)
{
    if(grav)
    {
        vec end(o);
        float t = fade;
        end.add(vec(d).mul(t/5000.0f));
        end.z -= t*t/(2.0f * 5000.0f * grav);
        pe.extendbb(end, size);

        float tpeak = d.z*grav;
        if(tpeak > 0 && tpeak < fade) pe.extendbb(o.z + 1.5f*d.z*tpeak/5000.0f, size);
    }
}

template<>
inline void seedpos<PT_TAPE>(particleemitter &pe, const vec &o, const vec &d, int fade, float size, int grav)
{
    pe.extendbb(d, size);
}

template<>
inline void seedpos<PT_TRAIL>(particleemitter &pe, const vec &o, const vec &d, int fade, float size, int grav)
{
    vec e = d;
    if(grav) e.z -= float(fade)/grav;
    e.div(-75.0f).add(o);
    pe.extendbb(e, size); 
}

template<int T>
struct varenderer : partrenderer
{
    partvert *verts;
    particle *parts;
    int maxparts, numparts, lastupdate, rndmask;
    GLuint vbo;

    varenderer(const char *texname, int type, int collide = 0) 
        : partrenderer(texname, 3, type, collide),
          verts(NULL), parts(NULL), maxparts(0), numparts(0), lastupdate(-1), rndmask(0), vbo(0)
    {
        if(type & PT_HFLIP) rndmask |= 0x01;
        if(type & PT_VFLIP) rndmask |= 0x02;
        if(type & PT_ROT) rndmask |= 0x1F<<2;
        if(type & PT_RND4) rndmask |= 0x03<<5;
    }
    
    void cleanup()
    {
        if(vbo) { glDeleteBuffers_(1, &vbo); vbo = 0; }
    }

    void init(int n)
    {
        DELETEA(parts);
        DELETEA(verts);
        parts = new particle[n];
        verts = new partvert[n*4];
        maxparts = n;
        numparts = 0;
        lastupdate = -1;
    }
    
    void reset() 
    {
        numparts = 0;
        lastupdate = -1;
    }
    
    void resettracked(physent *owner) 
    {
        if(!(type&PT_TRACK)) return;
        loopi(numparts)
        {
            particle *p = parts+i;
            if(!owner || (p->owner == owner)) p->fade = -1;
        }
        lastupdate = -1;
    }
    
    int count() 
    {
        return numparts;
    }
    
    bool haswork() 
    {
        return (numparts > 0);
    }

    particle *addpart(const vec &o, const vec &d, int fade, int color, float size, int gravity) 
    {
        particle *p = parts + (numparts < maxparts ? numparts++ : rnd(maxparts)); //next free slot, or kill a random kitten
        p->o = o;
        p->d = d;
        p->gravity = gravity;
        p->fade = fade;
        p->millis = lastmillis + emitoffset;
        p->color = bvec(color>>16, (color>>8)&0xFF, color&0xFF);
        p->size = size;
        p->owner = NULL;
        p->flags = 0x80 | (rndmask ? rnd(0x80) & rndmask : 0);
        lastupdate = -1;
        return p;
    }
 
    void seedemitter(particleemitter &pe, const vec &o, const vec &d, int fade, float size, int gravity)
    {
        pe.maxfade = max(pe.maxfade, fade);
        size *= SQRT2;
        pe.extendbb(o, size);

        seedpos<T>(pe, o, d, fade, size, gravity);
        if(!gravity) return;

        vec end(o);
        float t = fade;
        end.add(vec(d).mul(t/5000.0f));
        end.z -= t*t/(2.0f * 5000.0f * gravity);
        pe.extendbb(end, size);

        float tpeak = d.z*gravity;
        if(tpeak > 0 && tpeak < fade) pe.extendbb(o.z + 1.5f*d.z*tpeak/5000.0f, size);
    }
 
    void genverts(particle *p, partvert *vs, bool regen)
    {
        vec o, d;
        int blend, ts;
        float size;

        calc(p, blend, ts, size, o, d);
        if(blend <= 1 || p->fade <= 5) p->fade = -1; //mark to remove on next pass (i.e. after render)

        modifyblend<T>(o, blend);

        if(regen)
        {
            p->flags &= ~0x80;

            #define SETTEXCOORDS(u1c, u2c, v1c, v2c, body) \
            { \
                float u1 = u1c, u2 = u2c, v1 = v1c, v2 = v2c; \
                body; \
                vs[0].u = u1; \
                vs[0].v = v1; \
                vs[1].u = u2; \
                vs[1].v = v1; \
                vs[2].u = u2; \
                vs[2].v = v2; \
                vs[3].u = u1; \
                vs[3].v = v2; \
            }
            if(type&PT_RND4)
            {
                float tx = 0.5f*((p->flags>>5)&1), ty = 0.5f*((p->flags>>6)&1);
                SETTEXCOORDS(tx, tx + 0.5f, ty, ty + 0.5f,
                {
                    if(p->flags&0x01) swap(u1, u2);
                    if(p->flags&0x02) swap(v1, v2);
                });
            } 
            else if(type&PT_ICON)
            {
                float tx = 0.25f*(p->flags&3), ty = 0.25f*((p->flags>>2)&3);
                SETTEXCOORDS(tx, tx + 0.25f, ty, ty + 0.25f, {});
            }
            else SETTEXCOORDS(0, 1, 0, 1, {});

            #define SETCOLOR(r, g, b, a) \
            do { \
                uchar col[4] = { uchar(r), uchar(g), uchar(b), uchar(a) }; \
                loopi(4) memcpy(vs[i].color.v, col, sizeof(col)); \
            } while(0) 
            #define SETMODCOLOR SETCOLOR((p->color[0]*blend)>>8, (p->color[1]*blend)>>8, (p->color[2]*blend)>>8, 255)
            if(type&PT_MOD) SETMODCOLOR;
            else SETCOLOR(p->color[0], p->color[1], p->color[2], blend);
        }
        else if(type&PT_MOD) SETMODCOLOR;
        else loopi(4) vs[i].alpha = blend;

        if(type&PT_ROT) genrotpos<T>(o, d, size, ts, p->gravity, vs, (p->flags>>2)&0x1F);
        else genpos<T>(o, d, size, ts, p->gravity, vs);
    }

    void genverts()
    {
        loopi(numparts)
        {
            particle *p = &parts[i];
            partvert *vs = &verts[i*4];
            if(p->fade < 0)
            {
                do
                {
                    --numparts;
                    if(numparts <= i) return;
                }
                while(parts[numparts].fade < 0);
                *p = parts[numparts];
                genverts(p, vs, true);
            }
            else genverts(p, vs, (p->flags&0x80)!=0);
        }
    }

    void update()
    {
        if(lastmillis == lastupdate && vbo) return;
        lastupdate = lastmillis;
      
        genverts();

        if(!vbo) glGenBuffers_(1, &vbo);
        glBindBuffer_(GL_ARRAY_BUFFER, vbo);
        glBufferData_(GL_ARRAY_BUFFER, maxparts*4*sizeof(partvert), NULL, GL_STREAM_DRAW);
        glBufferSubData_(GL_ARRAY_BUFFER, 0, numparts*4*sizeof(partvert), verts);
        glBindBuffer_(GL_ARRAY_BUFFER, 0);
    }
    
    void render()
    {   
        glBindTexture(GL_TEXTURE_2D, tex->id);

        glBindBuffer_(GL_ARRAY_BUFFER, vbo);
        const partvert *ptr = 0;
        gle::vertexpointer(sizeof(partvert), &ptr->pos);
        gle::texcoord0pointer(sizeof(partvert), &ptr->u);
        gle::colorpointer(sizeof(partvert), &ptr->color);
        gle::enablevertex();
        gle::enabletexcoord0();
        gle::enablecolor();
        gle::enablequads();

        gle::drawquads(0, numparts);

        gle::disablequads();
        gle::disablevertex();
        gle::disabletexcoord0();
        gle::disablecolor();
        glBindBuffer_(GL_ARRAY_BUFFER, 0);
    }
};
typedef varenderer<PT_PART> quadrenderer;
typedef varenderer<PT_TAPE> taperenderer;
typedef varenderer<PT_TRAIL> trailrenderer;

#include "explosion.h"
#include "lensflare.h"
#include "lightning.h"

static vector<partrenderer*> parts;
static hashtable<const char*, int> partmap;

static bool get_renderer(lua_State *L, const char *name) {
    int *id = partmap.access(name);
    if (id) {
        lua_pushinteger(L, *id);
        lua_pushboolean(L, false);
        return true;
    }
    return false;
}

VARFP(maxparticles, 10, 4000, 10000, particleinit());
VARFP(fewparticles, 10, 100, 10000, particleinit());

static void register_renderer(lua_State *L, const char *s, partrenderer *rd) {
    int n = parts.length();
    partmap.access(s, n);
    parts.add(rd);
    rd->init(rd->type&PT_FEW ? min(fewparticles, maxparticles) : maxparticles);
    lua_pushinteger(L, n);
    lua_pushboolean(L, true);
}

#define REGISTER_VARENDERER(name) \
LUAICOMMAND(particle_register_renderer_##name, { \
    const char *name = luaL_checkstring(L, 1); \
    if (get_renderer(L, name)) return 2; \
    const char *path = luaL_checkstring(L, 2); \
    int flags   = luaL_checkinteger(L, 3); \
    int collide = luaL_optinteger(L, 4, 0); \
    lua_pushvalue(L, 1); lua_setfield(L, LUA_REGISTRYINDEX, name); \
    lua_pushvalue(L, 2); lua_setfield(L, LUA_REGISTRYINDEX, path); \
    register_renderer(L, name, new name##renderer(path, flags, collide)); \
    return 2; \
})

REGISTER_VARENDERER(quad)
REGISTER_VARENDERER(tape)
REGISTER_VARENDERER(trail)
#undef REGISTER_VARENDERER

#define REGISTER_PATHRENDERER(name) \
LUAICOMMAND(particle_register_renderer_##name, { \
    const char *name = luaL_checkstring(L, 1); \
    if (get_renderer(L, name)) return 2; \
    const char *path = luaL_checkstring(L, 2); \
    lua_pushvalue(L, 1); lua_setfield(L, LUA_REGISTRYINDEX, name); \
    lua_pushvalue(L, 2); lua_setfield(L, LUA_REGISTRYINDEX, path); \
    register_renderer(L, name, new name##renderer(path)); \
    return 2; \
})

REGISTER_PATHRENDERER(fireball)
REGISTER_PATHRENDERER(lightning)
#undef REGISTER_PATHRENDERER

LUAICOMMAND(particle_register_renderer_flare, {
    const char *name = luaL_checkstring(L, 1);
    if (get_renderer(L, name)) return 2;
    const char *path = luaL_checkstring(L, 2);
    int maxflares = luaL_checkinteger(L, 3);
    int flags = luaL_optinteger(L, 4, 0);
    lua_pushvalue(L, 1); lua_setfield(L, LUA_REGISTRYINDEX, name);
    lua_pushvalue(L, 2); lua_setfield(L, LUA_REGISTRYINDEX, path);
    register_renderer(L, name, new flarerenderer(path, maxflares, flags));
    return 2;
})

LUAICOMMAND(particle_register_renderer_meter, {
    const char *name = luaL_checkstring(L, 1);
    if (get_renderer(L, name)) return 2;
    int flags = luaL_optinteger(L, 2, 0);
    lua_pushvalue(L, 1); lua_setfield(L, LUA_REGISTRYINDEX, name);
    register_renderer(L, name, new meterrenderer(flags));
    return 2;
})

LUAICOMMAND(particle_get_renderer, {
    const char *s = luaL_checkstring(L, 1);
    int *id = partmap.access(s);
    if (!id) return 0;
    lua_pushinteger(L, *id);
    return 1;
})

void particleinit() 
{
    if(initing) return;
    if(!particleshader) particleshader = lookupshaderbyname("particle");
    if(!particlenotextureshader) particlenotextureshader = lookupshaderbyname("particlenotexture");
    if(!particlesoftshader) particlesoftshader = lookupshaderbyname("particlesoft");
    if(!particletextshader) particletextshader = lookupshaderbyname("particletext");

    if (parts.length()) return;
    parts.growbuf(22);
    parts.add(&texts);
    parts.add(&icons);
    parts.add(&meters);
    parts.add(&metervs);
    parts.add(new quadrenderer("<grey>media/particle/blood", PT_PART|PT_FLIP|PT_MOD|PT_RND4, 1)); // blood spats (note: rgb is inverted) 
    parts.add(new trailrenderer("media/particle/base", PT_TRAIL|PT_LERP));                            // water, entity
    parts.add(new quadrenderer("<grey>media/particle/smoke", PT_PART|PT_FLIP|PT_LERP));  // smoke
    parts.add(new quadrenderer("<grey>media/particle/steam", PT_PART|PT_FLIP));               // steam
    parts.add(new quadrenderer("<grey>media/particle/flames", PT_PART|PT_HFLIP|PT_RND4|PT_BRIGHT));   // flame on - no flipping please, they have orientation
    parts.add(new quadrenderer("media/particle/ball1", PT_PART|PT_FEW|PT_BRIGHT));                     // fireball1
    parts.add(new quadrenderer("media/particle/ball2", PT_PART|PT_FEW|PT_BRIGHT));                     // fireball2
    parts.add(new quadrenderer("media/particle/ball3", PT_PART|PT_FEW|PT_BRIGHT));                     // fireball3
    parts.add(new taperenderer("media/particle/flare", PT_TAPE|PT_BRIGHT));                            // streak
    parts.add(&lightnings);                                                                                   // lightning
    parts.add(&fireballs);                                                                                    // explosion fireball
    parts.add(&bluefireballs);                                                                                // bluish explosion fireball
    parts.add(new quadrenderer("media/particle/spark", PT_PART|PT_FLIP|PT_BRIGHT));                    // sparks
    parts.add(new quadrenderer("media/particle/snow", PT_PART|PT_FLIP|PT_RND4, -1));                  // colliding snow
    parts.add(new quadrenderer("media/particle/muzzleflash1", PT_PART|PT_FEW|PT_FLIP|PT_BRIGHT|PT_TRACK)); // muzzle flash
    parts.add(new quadrenderer("media/particle/muzzleflash2", PT_PART|PT_FEW|PT_FLIP|PT_BRIGHT|PT_TRACK)); // muzzle flash
    parts.add(new quadrenderer("media/particle/muzzleflash3", PT_PART|PT_FEW|PT_FLIP|PT_BRIGHT|PT_TRACK)); // muzzle flash
    parts.add(&flares);                                                                                        // lens flares - must be done last

    loopv(parts) parts[i]->init(parts[i]->type&PT_FEW ? min(fewparticles, maxparticles) : maxparticles);
}

void clearparticles()
{   
    loopv(parts) parts[i]->reset();
    clearparticleemitters();
}   

void cleanupparticles()
{
    loopv(parts) parts[i]->cleanup();
}

void removetrackedparticles(physent *owner)
{
    loopv(parts) parts[i]->resettracked(owner);
}

void deleteparticles() {
    clearparticles();
    cleanupparticles();
    parts.deletecontents();
    partmap.clear();
}

VAR(debugparticles, 0, 0, 1);

void renderparticles()
{
    //want to debug BEFORE the lastpass render (that would delete particles)
    if(debugparticles)
    {
        int n = parts.length();
        hudmatrix.ortho(0, FONTH*n*2*vieww/float(viewh), FONTH*n*2, 0, -1, 1); // squeeze into top-left corner
        resethudmatrix();
        hudshader->set();

        glDisable(GL_DEPTH_TEST);
        glEnable(GL_BLEND);
        loopi(n)
        {
            int type = parts[i]->type;
            const char *title = parts[i]->texname ? strrchr(parts[i]->texname, '/')+1 : NULL;
            string info = "";
            if(type&PT_LERP) concatstring(info, "l,");
            if(type&PT_MOD) concatstring(info, "m,");
            if(type&PT_RND4) concatstring(info, "r,");
            if(type&PT_TRACK) concatstring(info, "t,");
            if(type&PT_FLIP) concatstring(info, "f,");
            if(parts[i]->collide) concatstring(info, "c,");
            if(info[0]) info[strlen(info)-1] = '\0';
            defformatstring(ds)("%d\t%s(%s) %s", parts[i]->count(), partnames[type&0xFF], info, title ? title : "");
            draw_text(ds, FONTH, (i+n/2)*FONTH);
        }
        glDisable(GL_BLEND);
        glEnable(GL_DEPTH_TEST);
    }

    loopv(parts) parts[i]->update();

    bool rendered = false;
    uint lastflags = PT_LERP|PT_SHADER, flagmask = PT_LERP|PT_MOD|PT_BRIGHT|PT_NOTEX|PT_SOFT|PT_SHADER;
    int lastswizzle = -1;

    loopv(parts)
    {
        partrenderer *p = parts[i];
        if(!p->haswork()) continue;

        if(!rendered)
        {
            rendered = true;
            glDepthMask(GL_FALSE);
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);             

            glActiveTexture_(GL_TEXTURE2);
            if(msaasamples) glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, msdepthtex);
            else glBindTexture(GL_TEXTURE_RECTANGLE, gdepthtex);
            glActiveTexture_(GL_TEXTURE0);
        }
        
        p->preload();

        uint flags = p->type & flagmask, changedbits = flags ^ lastflags;
        int swizzle = p->tex ? p->tex->swizzle() : -1;
        if(swizzle != lastswizzle) changedbits |= PT_SWIZZLE;
        if(changedbits)
        {
            if(changedbits&PT_LERP) { if(flags&PT_LERP) resetfogcolor(); else zerofogcolor(); }
            if(changedbits&(PT_LERP|PT_MOD))
            {
                if(flags&PT_LERP) glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                else if(flags&PT_MOD) glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);
                else glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            }
            if(!(flags&PT_SHADER))
            {
                if(changedbits&(PT_SOFT|PT_NOTEX|PT_SHADER|PT_SWIZZLE))
                {
                    if(flags&PT_SOFT && softparticles)
                    {
                        particlesoftshader->setvariant(swizzle, 0);
                        LOCALPARAMF(softparams, (-1.0f/softparticleblend, 0, 0));
                    }
                    else if(flags&PT_NOTEX) particlenotextureshader->set();
                    else particleshader->setvariant(swizzle, 0);
                }
                if(changedbits&(PT_BRIGHT|PT_SOFT|PT_NOTEX|PT_SHADER|PT_SWIZZLE))
                {
                    float colorscale = ldrscale;
                    if(flags&PT_BRIGHT) colorscale *= particlebright;
                    LOCALPARAMF(colorscale, (colorscale, colorscale, colorscale, 1));
                }
            }
            lastflags = flags;        
            lastswizzle = swizzle; 
        }
        p->render();
    }

    if(rendered)
    {
        if(lastflags&(PT_LERP|PT_MOD)) glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        if(!(lastflags&PT_LERP)) resetfogcolor();
        glDisable(GL_BLEND);
        glDepthMask(GL_TRUE);
    }
}

static int addedparticles = 0;

static inline particle *newparticle(const vec &o, const vec &d, int fade, int type, int color, float size, int gravity = 0)
{
    static particle dummy;
    if(seedemitter) 
    {
        parts[type]->seedemitter(*seedemitter, o, d, fade, size, gravity);
        return &dummy;
    }
    if(fade + emitoffset < 0) return &dummy;
    addedparticles++;
    return parts[type]->addpart(o, d, fade, color, size, gravity);
}

LUAICOMMAND(particle_new, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushnil(L); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    float dx = luaL_checknumber(L, 5);
    float dy = luaL_checknumber(L, 6);
    float dz = luaL_checknumber(L, 7);
    int color = luaL_checkinteger(L, 8);
    int fade = luaL_checkinteger(L, 9);
    float size = luaL_checknumber(L, 10);
    int gravity = luaL_checkinteger(L, 11);
    *((particle**)lua_newuserdata(L, sizeof(void*))) = newparticle(
        vec(ox, oy, oz), vec(dx, dy, dz), fade, type, color, size, gravity);
    parts[type]->set_part_mt(L);
    return 1;
});

VARP(maxparticledistance, 256, 1024, 4096);

static void splash(int type, int color, int radius, int num, int fade, const vec &p, float size, int gravity)
{
    if(camera1->o.dist(p) > maxparticledistance && !seedemitter) return;
    float collidez = parts[type]->collide ? p.z - raycube(p, vec(0, 0, -1), COLLIDERADIUS, RAY_CLIPMAT) + (parts[type]->collide >= 0 ? COLLIDEERROR : 0) : -1; 
    int fmin = 1;
    int fmax = fade*3;
    loopi(num)
    {
        int x, y, z;
        do
        {
            x = rnd(radius*2)-radius;
            y = rnd(radius*2)-radius;
            z = rnd(radius*2)-radius;
        }
        while(x*x+y*y+z*z>radius*radius);
    	vec tmp = vec((float)x, (float)y, (float)z);
        int f = (num < 10) ? (fmin + rnd(fmax)) : (fmax - (i*(fmax-fmin))/(num-1)); //help deallocater by using fade distribution rather than random
        newparticle(p, tmp, f, type, color, size, gravity)->val = collidez;
    }
}

LUAICOMMAND(particle_splash_unbounded, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    int radius = luaL_checkinteger(L, 5);
    int num = luaL_checkinteger(L, 6);
    int color = luaL_checkinteger(L, 7);
    int fade = luaL_checkinteger(L, 8);
    float size = luaL_checknumber(L, 9);
    int gravity = luaL_checkinteger(L, 10);
    splash(type, color, radius, num, fade, vec(ox, oy, oz), size, gravity);
    lua_pushboolean(L, true);
    return 1;
});

static void regularsplash(int type, int color, int radius, int num, int fade, const vec &p, float size, int gravity, int delay = 0) 
{
    if(!emit_particles() || (delay > 0 && rnd(delay) != 0)) return;
    splash(type, color, radius, num, fade, p, size, gravity);
}

LUAICOMMAND(particle_splash, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    int radius = luaL_checkinteger(L, 5);
    int num = luaL_checkinteger(L, 6);
    int color = luaL_checkinteger(L, 7);
    int fade = luaL_checkinteger(L, 8);
    float size = luaL_checknumber(L, 9);
    int gravity = luaL_checkinteger(L, 10);
    int delay = luaL_checkinteger(L, 11);
    regularsplash(type, color, radius, num, fade, vec(ox, oy, oz), size,
        gravity, delay);
    lua_pushboolean(L, true);
    return 1;
});

VARP(maxtrail, 1, 500, 10000);

LUAICOMMAND(particle_trail, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    float dx = luaL_checknumber(L, 5);
    float dy = luaL_checknumber(L, 6);
    float dz = luaL_checknumber(L, 7);
    int color = luaL_checkinteger(L, 8);
    int fade = luaL_checkinteger(L, 9);
    float size = luaL_checknumber(L, 10);
    int gravity = luaL_checkinteger(L, 11);

    vec s(ox, oy, oz);
    vec e(dx, dy, dz);
    vec v;
    float d = e.dist(s, v);
    int steps = clamp(int(d*2), 1, maxtrail);
    v.div(steps);
    vec p = s;
    loopi(steps) {
        p.add(v);
        vec tmp = vec(float(rnd(11) - 5), float(rnd(11) - 5),
            float(rnd(11) - 5));
        newparticle(p, tmp, rnd(fade) + fade, type, color, size, gravity);
    }
    lua_pushboolean(L, true);
    return 1;
});

VARP(particletext, 0, 1, 1);
VARP(maxparticletextdistance, 0, 128, 10000);

void particle_textcopy(const vec &s, const char *t, int type, int fade, int color, float size, int gravity)
{
    if(!particletext || camera1->o.dist(s) > maxparticletextdistance) return;
    particle *p = newparticle(s, vec(0, 0, 1), fade, type, color, size, gravity);
    p->text = newstring(t);
}

LUAICOMMAND(particle_text, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    size_t slen;
    const char *text = luaL_checklstring(L, 5, &slen);
    int color = luaL_checkinteger(L, 6);
    int fade = luaL_checkinteger(L, 7);
    float size = luaL_checknumber(L, 8);
    int gravity = luaL_checkinteger(L, 9);

    vec s(ox, oy, oz);
    if(!particletext || camera1->o.dist(s) > maxparticletextdistance) {
        lua_pushboolean(L, true);
        return 1;
    }
    particle *p = newparticle(s, vec(0, 0, 1), fade, type,
        color, size, gravity);
    p->text = newstring(text, slen);

    lua_pushboolean(L, true);
    return 1;
});

void particle_icon(const vec &s, int ix, int iy, int type, int fade, int color, float size, int gravity)
{
    particle *p = newparticle(s, vec(0, 0, 1), fade, type, color, size, gravity);
    p->flags |= ix | (iy<<2);
}

LUAICOMMAND(particle_icon, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    int ix = luaL_checkinteger(L, 5);
    int iy = luaL_checkinteger(L, 6);
    int color = luaL_checkinteger(L, 7);
    int fade = luaL_checkinteger(L, 8);
    float size = luaL_checknumber(L, 9);
    int gravity = luaL_checkinteger(L, 10);
    particle_icon(vec(ox, oy, oz), ix, iy, type, fade, color, size, gravity);
    lua_pushboolean(L, true);
    return 1;
});

void particle_meter(const vec &s, float val, int type, int fade, int color, int color2, float size)
{
    particle *p = newparticle(s, vec(0, 0, 1), fade, type, color, size);
    p->color2[0] = color2>>16;
    p->color2[1] = (color2>>8)&0xFF;
    p->color2[2] = color2&0xFF;
    p->progress = clamp(int(val*100), 0, 100);
}

LUAICOMMAND(particle_meter, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    float val = luaL_checknumber(L, 5);
    int color = luaL_checkinteger(L, 6);
    int color2 = luaL_checkinteger(L, 7);
    int fade = luaL_checkinteger(L, 8);
    float size = luaL_checknumber(L, 9);
    particle_meter(vec(ox, oy, oz), val, type, fade, color, color2, size);
    lua_pushboolean(L, true);
    return 1;
});

LUAICOMMAND(particle_flare, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    float dx = luaL_checknumber(L, 5);
    float dy = luaL_checknumber(L, 6);
    float dz = luaL_checknumber(L, 7);
    int color = luaL_checkinteger(L, 8);
    int fade = luaL_checkinteger(L, 9);
    float size = luaL_checknumber(L, 10);
    int uid = lua_tointeger(L, 11);
    physent *owner = NULL;
    if (uid > 0) {
        CLogicEntity *o = LogicSystem::getLogicEntity(uid);
        assert(o->dynamicEntity);
        owner = o->dynamicEntity;
    }
    newparticle(vec(ox, oy, oz), vec(dx, dy, dz), fade,
        type, color, size)->owner = owner;
    lua_pushboolean(L, true);
    return 1;
});

LUAICOMMAND(particle_fireball, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    int color = luaL_checkinteger(L, 5);
    int fade = luaL_checkinteger(L, 6);
    float size = luaL_checknumber(L, 7);
    float maxsize = luaL_checknumber(L, 8);
    float growth = maxsize - size;
    if(fade < 0) fade = int(growth*20);
    newparticle(vec(ox, oy, oz), vec(0, 0, 1), fade,
        type, color, size)->val = growth;
    lua_pushboolean(L, true);
    return 1;
});

//dir = 0..6 where 0=up
static inline vec offsetvec(vec o, int dir, int dist) 
{
    vec v = vec(o);    
    v[(2+dir)%3] += (dir>2)?(-dist):dist;
    return v;
}

/* Experiments in shapes...
 * dir: (where dir%3 is similar to offsetvec with 0=up)
 * 0..2 circle
 * 3.. 5 cylinder shell
 * 6..11 cone shell
 * 12..14 plane volume
 * 15..20 line volume, i.e. wall
 * 21 sphere
 * 24..26 flat plane
 * +32 to inverse direction
 */
void regularshape(int type, int radius, int color, int dir, int num, int fade, const vec &p, float size, int gravity, int vel = 200)
{
    if(!emit_particles()) return;
    
    int basetype = parts[type]->type&0xFF;
    bool flare = (basetype == PT_TAPE) || (basetype == PT_LIGHTNING),
         inv = (dir&0x20)!=0, taper = (dir&0x40)!=0 && !seedemitter;
    dir &= 0x1F;
    loopi(num)
    {
        vec to, from;
        if(dir < 12) 
        { 
            const vec2 &sc = sincos360[rnd(360)];
            to[dir%3] = sc.y*radius;
            to[(dir+1)%3] = sc.x*radius;
            to[(dir+2)%3] = 0.0;
            to.add(p);
            if(dir < 3) //circle
                from = p;
            else if(dir < 6) //cylinder
            {
                from = to;
                to[(dir+2)%3] += radius;
                from[(dir+2)%3] -= radius;
            }
            else //cone
            {
                from = p;
                to[(dir+2)%3] += (dir < 9)?radius:(-radius);
            }
        }
        else if(dir < 15) //plane
        { 
            to[dir%3] = float(rnd(radius<<4)-(radius<<3))/8.0;
            to[(dir+1)%3] = float(rnd(radius<<4)-(radius<<3))/8.0;
            to[(dir+2)%3] = radius;
            to.add(p);
            from = to;
            from[(dir+2)%3] -= 2*radius;
        }
        else if(dir < 21) //line
        {
            if(dir < 18) 
            {
                to[dir%3] = float(rnd(radius<<4)-(radius<<3))/8.0;
                to[(dir+1)%3] = 0.0;
            } 
            else 
            {
                to[dir%3] = 0.0;
                to[(dir+1)%3] = float(rnd(radius<<4)-(radius<<3))/8.0;
            }
            to[(dir+2)%3] = 0.0;
            to.add(p);
            from = to;
            to[(dir+2)%3] += radius;  
        } 
        else if(dir < 24) //sphere
        {   
            to = vec(PI2*float(rnd(1000))/1000.0, PI*float(rnd(1000)-500)/1000.0).mul(radius); 
            to.add(p);
            from = p;
        }
        else if(dir < 27) // flat plane
        {
            to[dir%3] = float(rndscale(2*radius)-radius);
            to[(dir+1)%3] = float(rndscale(2*radius)-radius);
            to[(dir+2)%3] = 0.0;
            to.add(p);
            from = to; 
        }
        else from = to = p; 

        if(inv) swap(from, to);

        if(taper)
        {
            float dist = clamp(from.dist2(camera1->o)/maxparticledistance, 0.0f, 1.0f);
            if(dist > 0.2f)
            {
                dist = 1 - (dist - 0.2f)/0.8f;
                if(rnd(0x10000) > dist*dist*0xFFFF) continue;
            }
        }
 
        if(flare)
            newparticle(from, to, rnd(fade*3)+1, type, color, size, gravity);
        else 
        {  
            vec d = vec(to).sub(from).rescale(vel); //velocity
            particle *n = newparticle(from, d, rnd(fade*3)+1, type, color, size, gravity);
            if(parts[type]->collide)
                n->val = from.z - raycube(from, vec(0, 0, -1), parts[type]->collide >= 0 ? COLLIDERADIUS : max(from.z, 0.0f), RAY_CLIPMAT) + (parts[type]->collide >= 0 ? COLLIDEERROR : 0);
        }
    }
}

LUAICOMMAND(particle_shape, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    int radius = luaL_checkinteger(L, 5);
    int dir = luaL_checkinteger(L, 6);
    int num = luaL_checkinteger(L, 7);
    int color = luaL_checkinteger(L, 8);
    int fade = luaL_checkinteger(L, 9);
    float size = luaL_checknumber(L, 10);
    int gravity = luaL_checkinteger(L, 11);
    int vel = luaL_checkinteger(L, 12);
    regularshape(type, radius, color, dir, num, fade, vec(ox, oy, oz),
        size, gravity, vel);
    lua_pushboolean(L, true);
    return 1;
});

void regularflame(int type, const vec &p, float radius, float height, int color, int density = 3, float scale = 2.0f, float speed = 200.0f, float fade = 600.0f, int gravity = -15)
{
    if(!emit_particles()) return;
    
    float size = scale * min(radius, height);
    vec v(0, 0, min(1.0f, height)*speed);
    loopi(density)
    {
        vec s = p;        
        s.x += rndscale(radius*2.0f)-radius;
        s.y += rndscale(radius*2.0f)-radius;
        newparticle(s, v, rnd(max(int(fade*height), 1))+1, type, color, size, gravity);
    }
}

LUAICOMMAND(particle_flame, {
    int type = luaL_checkinteger(L, 1);
    if (!parts.inrange(type)) { lua_pushboolean(L, false); return 1; }
    float ox = luaL_checknumber(L, 2);
    float oy = luaL_checknumber(L, 3);
    float oz = luaL_checknumber(L, 4);
    float radius = luaL_checknumber(L, 5);
    float height = luaL_checknumber(L, 6);
    int density = luaL_checkinteger(L, 7);
    int color = luaL_checkinteger(L, 8);
    float fade = luaL_checknumber(L, 9);
    float scale = luaL_checknumber(L, 10);
    float speed = luaL_checknumber(L, 11);
    int gravity = luaL_checkinteger(L, 12);
    regularflame(type, vec(ox, oy, oz), radius, height, color, density,
        scale, speed, fade, gravity);
    lua_pushboolean(L, true);
    return 1;
});

enum
{
    PART_TEXT = 0,
    PART_ICON,
    PART_METER,
    PART_METER_VS,
    PART_BLOOD,
    PART_WATER,
    PART_SMOKE,
    PART_STEAM,
    PART_FLAME,
    PART_FIREBALL1, PART_FIREBALL2, PART_FIREBALL3,
    PART_STREAK, PART_LIGHTNING,
    PART_EXPLOSION, PART_EXPLOSION_BLUE,
    PART_SPARK,
    PART_SNOW,
    PART_MUZZLE_FLASH1, PART_MUZZLE_FLASH2, PART_MUZZLE_FLASH3,
    PART_LENS_FLARE
};

static void makeparticles(entity &e) 
{
    switch(e.attr[0])
    {
        case 0: //fire and smoke -  <radius> <height> <rgb> - 0 values default to compat for old maps
        {
            //regularsplash(PART_FIREBALL1, 0xFFC8C8, 150, 1, 40, e.o, 4.8f);
            //regularsplash(PART_SMOKE, 0x897661, 50, 1, 200,  vec(e.o.x, e.o.y, e.o.z+3.0f), 2.4f, -20, 3);
            float radius = e.attr[1] ? float(e.attr[1])/100.0f : 1.5f,
                  height = e.attr[2] ? float(e.attr[2])/100.0f : radius/3;
            regularflame(PART_FLAME, e.o, radius, height, e.attr[3] ? e.attr[3] : 0x903020, 3, 2.0f);
            regularflame(PART_SMOKE, vec(e.o.x, e.o.y, e.o.z + 4.0f*min(radius, height)), radius, height, 0x303020, 1, 4.0f, 100.0f, 2000.0f, -20);
            break;
        }
        case 1: //steam vent - <dir>
            regularsplash(PART_STEAM, 0x897661, 50, 1, 200, offsetvec(e.o, e.attr[1], rnd(10)), 2.4f, -20);
            break;
        case 2: //water fountain - <dir>
        {
            int color;
            if(e.attr[2] > 0) color = e.attr[2];
            else
            {
                int mat = MAT_WATER + clamp(-e.attr[2], 0, 3);
                const bvec &wfcol = getwaterfallcolorv(mat);
                color = (int(wfcol[0])<<16) | (int(wfcol[1])<<8) | int(wfcol[2]);
                if(!color)
                {
                    const bvec &wcol = getwatercolorv(mat);
                    color = (int(wcol[0])<<16) | (int(wcol[1])<<8) | int(wcol[2]);
                }
            }
            regularsplash(PART_WATER, color, 150, 4, 200, offsetvec(e.o, e.attr[1], rnd(10)), 0.6f, 2);
            break;
        }
        case 3: //fire ball - <size> <rgb>
            newparticle(e.o, vec(0, 0, 1), 1, PART_EXPLOSION, e.attr[2], 4.0f)->val = 1+e.attr[1];
            break;
        case 4:  //tape - <dir> <length> <rgb>
        case 7:  //lightning 
        case 9:  //steam
        case 10: //water
        case 13: //snow
        {
            static const int typemap[]   = { PART_STREAK, -1, -1, PART_LIGHTNING, -1, PART_STEAM, PART_WATER, -1, -1, PART_SNOW };
            static const float sizemap[] = { 0.28f, 0.0f, 0.0f, 1.0f, 0.0f, 2.4f, 0.60f, 0.0f, 0.0f, 0.5f };
            static const int gravmap[] = { 0, 0, 0, 0, 0, -20, 2, 0, 0, 20 };
            int type = typemap[e.attr[0]-4];
            float size = sizemap[e.attr[0]-4];
            int gravity = gravmap[e.attr[0]-4];
            if(e.attr[1] >= 256) regularshape(type, max(1+e.attr[2], 1), e.attr[3], e.attr[1]-256, 5, e.attr[4] > 0 ? min(int(e.attr[4]), 10000) : 200, e.o, size, gravity);
            else newparticle(e.o, offsetvec(e.o, e.attr[1], max(1+e.attr[2], 0)), 1, type, e.attr[3], size, gravity);
            break;
        }
        case 5: //meter, metervs - <percent> <rgb> <rgb2>
        case 6:
        {
            particle *p = newparticle(e.o, vec(0, 0, 1), 1, e.attr[0]==5 ? PART_METER : PART_METER_VS, e.attr[2], 2.0f);
            int color2 = e.attr[3];
            p->color2[0] = color2>>16;
            p->color2[1] = (color2>>8)&0xFF;
            p->color2[2] = color2&0xFF;
            p->progress = clamp(int(e.attr[1]), 0, 100);
            break;
        }
        case 11: // flame <radius> <height> <rgb> - radius=100, height=100 is the classic size
            regularflame(PART_FLAME, e.o, float(e.attr[1])/100.0f, float(e.attr[2])/100.0f, e.attr[3], 3, 2.0f);
            break;
        case 12: // smoke plume <radius> <height> <rgb>
            regularflame(PART_SMOKE, e.o, float(e.attr[1])/100.0f, float(e.attr[2])/100.0f, e.attr[3], 1, 4.0f, 100.0f, 2000.0f, -20);
            break;
        case 32: //lens flares - plain/sparkle/sun/sparklesun <red> <green> <blue>
        case 33:
        case 34:
        case 35:
            flares.addflare(e.o, e.attr[1], e.attr[2], e.attr[3], (e.attr[0]&0x02)!=0, (e.attr[0]&0x01)!=0);
            break;
        default:
            if(!editmode)
            {
                defformatstring(ds)("particles %d?", e.attr[0]);
                particle_textcopy(e.o, ds, PART_TEXT, 1, 0x6496FF, 2.0f, 0);
            }
            break;
    }
}

void seedparticles()
{
    renderprogress(0, "seeding particles");
    addparticleemitters();
    canemit = true;
    loopv(emitters)
    {
        particleemitter &pe = emitters[i];
        extentity &e = *pe.ent;
        seedemitter = &pe;
        for(int millis = 0; millis < seedmillis; millis += min(emitmillis, seedmillis/10))
            makeparticles(e);    
        seedemitter = NULL;
        pe.lastemit = -seedmillis;
        pe.finalize();
    }
}

FVARFP(editpartsize, 0.0f, 4.0f, 100.0f, particleinit());

void updateparticles()
{
    if(regenemitters) addparticleemitters();

    if(lastmillis - lastemitframe >= emitmillis)
    {
        canemit = true;
        lastemitframe = lastmillis - (lastmillis%emitmillis);
    }
    else canemit = false;
   
    flares.makelightflares();

    if(!editmode || showparticles) 
    {
        int emitted = 0, replayed = 0;
        addedparticles = 0;
        loopv(emitters)
        {
            particleemitter &pe = emitters[i];
            extentity &e = *pe.ent;
            if(e.o.dist(camera1->o) > maxparticledistance) { pe.lastemit = lastmillis; continue; } 
            if(cullparticles && pe.maxfade >= 0)
            {
                if(isfoggedsphere(pe.radius, pe.center)) { pe.lastcull = lastmillis; continue; }
                if(pvsoccluded(pe.bborigin, pe.bbsize)) { pe.lastcull = lastmillis; continue; }
            }
            makeparticles(e);
            emitted++;
            if(replayparticles && pe.maxfade > 5 && pe.lastcull > pe.lastemit)
            {
                for(emitoffset = max(pe.lastemit + emitmillis - lastmillis, -pe.maxfade); emitoffset < 0; emitoffset += emitmillis)
                {
                    makeparticles(e);
                    replayed++;
                }
                emitoffset = 0;
            } 
            pe.lastemit = lastmillis;
        }
        if(dbgpcull && (canemit || replayed) && addedparticles) conoutf(CON_DEBUG, "%d emitters, %d particles", emitted, addedparticles);
    }
    if(editmode) // show sparkly thingies for map entities in edit mode
    {
        const vector<extentity *> &ents = entities::getents();
        // note: order matters in this case as particles of the same type are drawn in the reverse order that they are added
        loopv(entgroup)
        {
            extentity &e = *ents[entgroup[i]];
            CLogicEntity *le = LogicSystem::getLogicEntity(e);
            if (!le) continue;
            lua::push_external("entity_get_class_name");
            lua_rawgeti(lua::L, LUA_REGISTRYINDEX, le->lua_ref);
            lua_call(lua::L, 1, 1);
            particle_textcopy(e.o, lua_tostring(lua::L, -1), PART_TEXT, 1, 0xFF4B19, 2.0f, 0);
            lua_pop(lua::L, 1);
        }
        loopv(ents)
        {
            extentity &e = *ents[i];
            CLogicEntity *le = LogicSystem::getLogicEntity(e);
            if (!le) continue;
            lua::push_external("entity_get_edit_icon_info");
            lua_rawgeti(lua::L, LUA_REGISTRYINDEX, le->lua_ref);

            lua::push_external("entity_get_class_name");
            lua_pushvalue(lua::L, -2);
            lua_call(lua::L, 1, 1);
            const char *name = lua_tostring(lua::L, -1); lua_pop(lua::L, 1);

            lua_call(lua::L, 1, 2);
            int color = lua_tointeger(lua::L, -1);
            const char *icon = lua_tostring(lua::L, -2);
            lua_pop(lua::L, 2);

            particle_textcopy(e.o, name, PART_TEXT, 1, 0x1EC850, 2.0f, 0);
            particle *part = newparticle(e.o, vec(0, 0, 0), 0, PART_ICON, color, editpartsize);
            part->tex = textureload(icon);
        }
    }
}

#undef PART_MT_FIELD
