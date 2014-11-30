// world.cpp: core map management stuff

#include "engine.h"

#include "message_system.h" // INTENSITY

VARR(mapversion, 1, MAPVERSION, 0);
VARNR(mapscale, worldscale, 1, 0, 0);
VARNR(mapsize, worldsize, 1, 0, 0);
SVARR(maptitle, "Untitled Map by Unknown");
VAR(octaentsize, 0, 64, 1024);
VAR(entselradius, 0, 2, 10);

static inline void transformbb(const entity &e, vec &center, vec &radius)
{
    if(e.attr[3] > 0) { float scale = e.attr[3]/100.0f; center.mul(scale); radius.mul(scale); }
    rotatebb(center, radius, e.attr[0], e.attr[1], e.attr[2]);
}

static inline void mmboundbox(const entity &e, model *m, vec &center, vec &radius)
{
    m->boundbox(center, radius);
    transformbb(e, center, radius);
}

static inline void mmcollisionbox(const extentity &e, model *m, vec &center, vec &radius)
{
    m->collisionbox(center, radius);
    transformbb(e, center, radius);
}

static inline void decalboundbox(const entity &e, DecalSlot &s, vec &center, vec &radius)
{
    float size = max(float(e.attr[4]), 1.0f);
    center = vec(0, s.depth * size/2, 0);
    radius = vec(size/2, s.depth * size/2, size/2);
    rotatebb(center, radius, e.attr[1], e.attr[2], e.attr[3]);
}

bool getentboundingbox(const extentity &e, ivec &o, ivec &r)
{
    switch(e.type)
    {
        case ET_EMPTY:
            return false;
        case ET_DECAL:
            {
                DecalSlot &s = lookupdecalslot(e.attr[0], false);
                vec center, radius;
                decalboundbox(e, s, center, radius);
                center.add(e.o);
                radius.max(entselradius);
                o = vec(center).sub(radius);
                r = vec(center).add(radius).add(1);
                break;
            }
        case ET_MAPMODEL:
            if(model *m = e.m)
            {
                vec center, radius;
                mmboundbox(e, m, center, radius);
                center.add(e.o);
                radius.max(entselradius);
                o = vec(center).sub(radius);
                r = vec(center).add(radius).add(1);
                break;
            }
        case ET_OBSTACLE: /* OF */
        {
            int a = e.attr[3], b = e.attr[4], c = e.attr[5];
            if (!a || !b || !c) {
                o = vec(e.o).sub(entselradius);
                r = vec(e.o).add(entselradius+1);
                break;
            }
            vec center = vec(0, 0, 0), radius = vec(a, b, c);
            rotatebb(center, radius, e.attr[0], e.attr[1], e.attr[2]);
            center.add(e.o);
            radius.max(entselradius);
            o = vec(center).sub(radius);
            r = vec(center).add(radius).add(1);
            break;
        }
        // invisible mapmodels use entselradius
        default:
            o = vec(e.o).sub(entselradius);
            r = vec(e.o).add(entselradius+1);
            break;
    }
    return true;
}

enum
{
    MODOE_ADD      = 1<<0,
    MODOE_UPDATEBB = 1<<1,
    MODOE_CHANGED  = 1<<2
};

void modifyoctaentity(int flags, int id, extentity &e, cube *c, const ivec &cor, int size, const ivec &bo, const ivec &br, int leafsize, vtxarray *lastva = NULL)
{
    loopoctabox(cor, size, bo, br)
    {
        ivec o(i, cor, size);
        vtxarray *va = c[i].ext && c[i].ext->va ? c[i].ext->va : lastva;
        if(c[i].children != NULL && size > leafsize)
            modifyoctaentity(flags, id, e, c[i].children, o, size>>1, bo, br, leafsize, va);
        else if(flags&MODOE_ADD)
        {
            if(!c[i].ext || !c[i].ext->ents) ext(c[i]).ents = new octaentities(o, size);
            octaentities &oe = *c[i].ext->ents;
            switch(e.type)
            {
                case ET_DECAL:
                    if(va)
                    {
                        va->bbmin.x = -1;
                        if(oe.decals.empty()) va->decals.add(&oe);
                    }
                    oe.decals.add(id);
                    oe.bbmin.min(bo).max(oe.o);
                    oe.bbmax.max(br).min(ivec(oe.o).add(oe.size));
                    break;
                case ET_OBSTACLE: /* OF */
                case ET_MAPMODEL:
                    if(e.m || e.type == ET_OBSTACLE)
                    {
                        if(va)
                        {
                            va->bbmin.x = -1;
                            if(oe.mapmodels.empty()) va->mapmodels.add(&oe);
                        }
                        oe.mapmodels.add(id);
                        oe.bbmin.min(bo).max(oe.o);
                        oe.bbmax.max(br).min(ivec(oe.o).add(oe.size));
                        break;
                    }
                    // invisible mapmodel
                default:
                    oe.other.add(id);
                    break;
            }

        }
        else if(c[i].ext && c[i].ext->ents)
        {
            octaentities &oe = *c[i].ext->ents;
            switch(e.type)
            {
                case ET_DECAL:
                    oe.decals.removeobj(id);
                    if(va)
                    {
                        va->bbmin.x = -1;
                        if(oe.decals.empty()) va->decals.removeobj(&oe);
                    }
                    oe.bbmin = oe.bbmax = oe.o;
                    oe.bbmin.add(oe.size);
                    loopvj(oe.decals)
                    {
                        extentity &e = *entities::getents()[oe.decals[j]];
                        ivec eo, er;
                        if(getentboundingbox(e, eo, er))
                        {
                            oe.bbmin.min(eo);
                            oe.bbmax.max(er);
                        }
                    }
                    oe.bbmin.max(oe.o);
                    oe.bbmax.min(ivec(oe.o).add(oe.size));
                    break;
                case ET_OBSTACLE: /* OF */
                case ET_MAPMODEL:
                    if(e.m || e.type == ET_OBSTACLE)
                    {
                        oe.mapmodels.removeobj(id);
                        if(va)
                        {
                            va->bbmin.x = -1;
                            if(oe.mapmodels.empty()) va->mapmodels.removeobj(&oe);
                        }
                        oe.bbmin = oe.bbmax = oe.o;
                        oe.bbmin.add(oe.size);
                        const vector<extentity *> &ents = entities::getents();
                        loopvj(oe.mapmodels)
                        {
                            extentity &e = *ents[oe.mapmodels[j]];
                            ivec eo, er;
                            if(getentboundingbox(e, eo, er))
                            {
                                oe.bbmin.min(eo);
                                oe.bbmax.max(er);
                            }
                        }
                        oe.bbmin.max(oe.o);
                        oe.bbmax.min(ivec(oe.o).add(oe.size));
                        break;
                    }
                    // invisible mapmodel
                default:
                    oe.other.removeobj(id);
                    break;
            }
            if(oe.mapmodels.empty() && oe.decals.empty() && oe.other.empty())
                freeoctaentities(c[i]);
        }
        if(c[i].ext && c[i].ext->ents) c[i].ext->ents->query = NULL;
        if(va && va!=lastva)
        {
            if(lastva)
            {
                if(va->bbmin.x < 0) lastva->bbmin.x = -1;
            }
            else if(flags&MODOE_UPDATEBB) updatevabb(va);
        }
    }
}

vector<int> outsideents;
int spotlights = 0, volumetriclights = 0;

static bool modifyoctaent(int flags, int id, extentity &e)
{
    if(flags&MODOE_ADD ? e.flags&EF_OCTA : !(e.flags&EF_OCTA)) return false;

    ivec o, r;
    if(!getentboundingbox(e, o, r)) return false;

    if(!insideworld(e.o))
    {
        int idx = outsideents.find(id);
        if(flags&MODOE_ADD)
        {
            if(idx < 0) outsideents.add(id);
        }
        else if(idx >= 0) outsideents.removeunordered(idx);
    }
    else
    {
        int leafsize = octaentsize, limit = max(r.x - o.x, max(r.y - o.y, r.z - o.z));
        while(leafsize < limit) leafsize *= 2;
        int diff = ~(leafsize-1) & ((o.x^r.x)|(o.y^r.y)|(o.z^r.z));
        if(diff && (limit > octaentsize/2 || diff < leafsize*2)) leafsize *= 2;
        modifyoctaentity(flags, id, e, worldroot, ivec(0, 0, 0), worldsize>>1, o, r, leafsize);
    }
    e.flags ^= EF_OCTA;
    switch(e.type)
    {
        case ET_LIGHT: clearlightcache(id); if(e.attr[4]&L_VOLUMETRIC) { if(flags&MODOE_ADD) volumetriclights++; else --volumetriclights; } break;
        case ET_SPOTLIGHT: if(!(flags&MODOE_ADD ? spotlights++ : --spotlights)) { cleardeferredlightshaders(); cleanupvolumetric(); } break;
        case ET_PARTICLES: clearparticleemitters(); break;
        case ET_DECAL: if(flags&MODOE_CHANGED) changed(o, r, false); break;
    }
    return true;
}

/* OctaForge: getentid */
static int getentid(extentity *entity) {
    const vector<extentity *> &ents = entities::getents();
    loopv(ents) if (ents[i] == entity) return i;
    assert(false);
    return -1;
}

static inline bool modifyoctaent(int flags, int id) {
    return entities::getents().inrange(id) && modifyoctaent(flags, id, *entities::getents()[id]);
}

              void addentity(int id)        { modifyoctaent(MODOE_ADD|MODOE_UPDATEBB, id); } // INTENSITY: Removed 'static' and 'inline'
              void removeentity(int id)     { modifyoctaent(MODOE_UPDATEBB, id); } // INTENSITY: Removed 'static' and 'inline'
static inline void addentityedit(int id)    { modifyoctaent(MODOE_ADD|MODOE_UPDATEBB|MODOE_CHANGED, id); }
static inline void removeentityedit(int id) { modifyoctaent(MODOE_UPDATEBB|MODOE_CHANGED, id); }

/* OctaForge: extentity* versions */
void addentity(extentity* entity) { addentity(getentid(entity)); }
void removeentity(extentity *entity) { removeentity(getentid(entity)); }

void freeoctaentities(cube &c)
{
    if(!c.ext) return;
    if(entities::getents().length())
    {
        while(c.ext->ents && !c.ext->ents->mapmodels.empty()) removeentity(c.ext->ents->mapmodels.pop());
        while(c.ext->ents && !c.ext->ents->decals.empty())    removeentity(c.ext->ents->decals.pop());
        while(c.ext->ents && !c.ext->ents->other.empty())     removeentity(c.ext->ents->other.pop());
    }
    if(c.ext->ents)
    {
        delete c.ext->ents;
        c.ext->ents = NULL;
    }
}

void entitiesinoctanodes()
{
    vector<extentity *> &ents = entities::getents();
    loopv(ents) modifyoctaent(MODOE_ADD, i, *ents[i]);
}

static inline void findents(octaentities &oe, int low, int high, bool notspawned, const vec &pos, const vec &radius, vector<int> &found)
{
    vector<extentity *> &ents = entities::getents();
    loopv(oe.other)
    {
        int id = oe.other[i];
        extentity &e = *ents[id];
        if(e.type >= low && e.type <= high && (e.spawned() || notspawned) && vec(e.o).mul(radius).squaredlen() <= 1) found.add(id);
    }
}

static inline void findents(cube *c, const ivec &o, int size, const ivec &bo, const ivec &br, int low, int high, bool notspawned, const vec &pos, const vec &radius, vector<int> &found)
{
    loopoctabox(o, size, bo, br)
    {
        if(c[i].ext && c[i].ext->ents) findents(*c[i].ext->ents, low, high, notspawned, pos, radius, found);
        if(c[i].children && size > octaentsize)
        {
            ivec co(i, o, size);
            findents(c[i].children, co, size>>1, bo, br, low, high, notspawned, pos, radius, found);
        }
    }
}

void findents(int low, int high, bool notspawned, const vec &pos, const vec &radius, vector<int> &found)
{
    vec invradius(1/radius.x, 1/radius.y, 1/radius.z);
    ivec bo = vec(pos).sub(radius).sub(1),
         br = vec(pos).add(radius).add(1);
    int diff = (bo.x^br.x) | (bo.y^br.y) | (bo.z^br.z) | octaentsize,
        scale = worldscale-1;
    if(diff&~((1<<scale)-1) || uint(bo.x|bo.y|bo.z|br.x|br.y|br.z) >= uint(worldsize))
    {
        findents(worldroot, ivec(0, 0, 0), 1<<scale, bo, br, low, high, notspawned, pos, invradius, found);
        return;
    }
    cube *c = &worldroot[octastep(bo.x, bo.y, bo.z, scale)];
    if(c->ext && c->ext->ents) findents(*c->ext->ents, low, high, notspawned, pos, invradius, found);
    scale--;
    while(c->children && !(diff&(1<<scale)))
    {
        c = &c->children[octastep(bo.x, bo.y, bo.z, scale)];
        if(c->ext && c->ext->ents) findents(*c->ext->ents, low, high, notspawned, pos, invradius, found);
        scale--;
    }
    if(c->children && 1<<scale >= octaentsize) findents(c->children, ivec(bo).mask(~((2<<scale)-1)), 1<<scale, bo, br, low, high, notspawned, pos, invradius, found);
}

extern selinfo sel;
extern bool havesel;
int entlooplevel = 0;
int efocus = -1, enthover = -1, entorient = -1, oldhover = -1;
bool undonext = true;

VARF(entediting, 0, 0, 1, { if(!entediting) { entcancel(); efocus = enthover = -1; } });

bool noentedit()
{
    if(!editmode) { conoutf(CON_ERROR, "operation only allowed in edit mode"); return true; }
    return !entediting;
}

bool pointinsel(const selinfo &sel, const vec &o)
{
    return(o.x <= sel.o.x+sel.s.x*sel.grid
        && o.x >= sel.o.x
        && o.y <= sel.o.y+sel.s.y*sel.grid
        && o.y >= sel.o.y
        && o.z <= sel.o.z+sel.s.z*sel.grid
        && o.z >= sel.o.z);
}

vector<int> entgroup;

bool haveselent()
{
    return entgroup.length() > 0;
}

void entcancel()
{
    entgroup.shrink(0);
}

void entadd(int id)
{
    undonext = true;
    entgroup.add(id);
}

undoblock *newundoent()
{
    int numents = entgroup.length();
    if(numents <= 0) return NULL;
    undoblock *u = (undoblock *)new uchar[sizeof(undoblock) + numents*sizeof(undoent)];
    u->numents = numents;
    undoent *e = (undoent *)(u + 1);
    loopv(entgroup)
    {
        e->i = entgroup[i];
        e->e.attr.disown(); //points to random values; this causes problems
        e->e = *entities::getents()[entgroup[i]];
        e++;
    }
    return u;
}

void makeundoent()
{
    if(!undonext) return;
    undonext = false;
    oldhover = enthover;
    undoblock *u = newundoent();
    if(u) addundo(u);
}

void detachentity(extentity &e)
{
    if(!e.attached) return;
    e.attached->attached = NULL;
    e.attached = NULL;
}

VAR(attachradius, 1, 100, 1000);

void attachentity(extentity &e)
{
    if (e.type != ET_SPOTLIGHT) return;

    detachentity(e);

    int closest = -1;
    float closedist = 1e10f;
    const vector<extentity *> &ents = entities::getents();
    loopv(ents)
    {
        extentity *a = ents[i];
        if(a->attached || a->type != ET_LIGHT) continue;
        float dist = e.o.dist(a->o);
        if(dist < closedist)
        {
            closest = i;
            closedist = dist;
        }
    }
    if(closedist>attachradius) return;
    e.attached = ents[closest];
    ents[closest]->attached = &e;
}

void attachentities()
{
    vector<extentity *> &ents = entities::getents();
    loopv(ents) attachentity(*ents[i]);
}

// convenience macros implicitly define:
// e         entity, currently edited ent
// n         int,    index to currently edited ent
#define addimplicit(f)    { if(entgroup.empty() && enthover>=0) { entadd(enthover); undonext = (enthover != oldhover); f; entgroup.drop(); } else f; }
#define entfocusv(i, f, v){ int n = efocus = (i); if(n>=0) { extentity &e = *v[n]; f; } }
#define entfocus(i, f)    entfocusv(i, f, entities::getents())
#define enteditv(i, f, v) \
{ \
    entfocusv(i, \
    { \
        int oldtype = e.type; \
        removeentityedit(n);  \
        f; \
        if(oldtype!=e.type) detachentity(e); \
        if(e.type!=ET_EMPTY) { addentityedit(n); if(oldtype!=e.type) attachentity(e); } \
        clearshadowcache(); \
    }, v); \
}
#define entedit(i, f)   enteditv(i, f, entities::getents())
#define addgroup(exp)   { vector<extentity *> &ents = entities::getents(); loopv(ents) entfocusv(i, if(exp) entadd(n), ents); }
#define setgroup(exp)   { entcancel(); addgroup(exp); }
#define groupeditloop(f){ vector<extentity *> &ents = entities::getents(); entlooplevel++; int _ = efocus; loopv(entgroup) enteditv(entgroup[i], f, ents); efocus = _; entlooplevel--; }
#define groupeditpure(f){ if(entlooplevel>0) { entedit(efocus, f); } else { groupeditloop(f); commitchanges(); } }
#define groupeditundo(f){ makeundoent(); groupeditpure(f); }
#define groupedit(f)    { addimplicit(groupeditundo(f)); }

vec getselpos()
{
    vector<extentity *> &ents = entities::getents();
    if(entgroup.length() && ents.inrange(entgroup[0])) return ents[entgroup[0]]->o;
    if(ents.inrange(enthover)) return ents[enthover]->o;
    return vec(sel.o);
}

undoblock *copyundoents(undoblock *u)
{
    entcancel();
    undoent *e = u->ents();
    loopi(u->numents)
        entadd(e[i].i);
    undoblock *c = newundoent();
    loopi(u->numents) if(e[i].e.type==ET_EMPTY)
        entgroup.removeobj(e[i].i);
    return c;
}

void pasteundoent(int idx, const entity &ue)
{
    if(idx < 0 || idx >= MAXENTS) return;
    //vector<extentity *> &ents = entities::getents();
    //while(ents.length() < idx) ents.add(entities::newentity())->type = ET_EMPTY;
    int efocus = -1;
    entedit(idx, (entity &)e = ue);
}

void pasteundoents(undoblock *u)
{
    undoent *ue = u->ents();
    loopi(u->numents) pasteundoent(ue[i].i, ue[i].e);
}

void entflip()
{
    if(noentedit()) return;
    int d = dimension(sel.orient);
    float mid = sel.s[d]*sel.grid/2+sel.o[d];
    groupeditundo(e.o[d] -= (e.o[d]-mid)*2);
}

void entrotate(int *cw)
{
    if(noentedit()) return;
    int d = dimension(sel.orient);
    int dd = (*cw<0) == dimcoord(sel.orient) ? R[d] : C[d];
    float mid = sel.s[dd]*sel.grid/2+sel.o[dd];
    vec s(sel.o.v);
    groupeditundo(
        e.o[dd] -= (e.o[dd]-mid)*2;
        e.o.sub(s);
        swap(e.o[R[d]], e.o[C[d]]);
        e.o.add(s);
    );
}

void entselectionbox(const entity &e, vec &eo, vec &es)
{
    extentity* _e = (extentity*)&e; // INTENSITY

    model *m = NULL;
    if(e.type == ET_MAPMODEL && (m = _e->m)) // INTENSITY
    {
        mmcollisionbox(*_e, m, eo, es);
        es.max(entselradius);
        eo.add(e.o);
    }
    else if(e.type == ET_OBSTACLE && e.attr[3] && e.attr[4] && e.attr[5]) /* OF */
    {
        eo = vec(0, 0, 0);
        es = vec(e.attr[3], e.attr[4], e.attr[5]);
        rotatebb(eo, es, e.attr[0], e.attr[1], e.attr[2]);
        es.max(entselradius);
        eo.add(e.o);
    }
    else if(e.type == ET_DECAL)
    {
        DecalSlot &s = lookupdecalslot(e.attr[0], false);
        decalboundbox(e, s, eo, es);
        es.max(entselradius);
        eo.add(e.o);
    }
    else
    {
        es = vec(entselradius);
        eo = e.o;
    }
    eo.sub(es);
    es.mul(2);
}

VAR(entselsnap, 0, 0, 1);
VAR(entmovingshadow, 0, 1, 1);

extern void boxs(int orient, vec o, const vec &s);
extern void boxs3D(const vec &o, vec s, int g);
extern bool editmoveplane(const vec &o, const vec &ray, int d, float off, vec &handle, vec &dest, bool first);

int entmoving = 0;

void entdrag(const vec &ray)
{
    if(noentedit() || !haveselent()) return;

    float r = 0, c = 0;
    static vec dest, handle;
    vec eo, es;
    int d = dimension(entorient),
        dc= dimcoord(entorient);

    entfocus(entgroup.last(),
        entselectionbox(e, eo, es);

        if(!editmoveplane(e.o, ray, d, eo[d] + (dc ? es[d] : 0), handle, dest, entmoving==1))
            return;

        ivec g = dest;
        int z = g[d]&(~(sel.grid-1));
        g.add(sel.grid/2).mask(~(sel.grid-1));
        g[d] = z;

        r = (entselsnap ? g[R[d]] : dest[R[d]]) - e.o[R[d]];
        c = (entselsnap ? g[C[d]] : dest[C[d]]) - e.o[C[d]];
    );

    if(entmoving==1) makeundoent();
    groupeditpure(e.o[R[d]] += r; e.o[C[d]] += c);
    entmoving = 2;
}

VAR(showentradius, 0, 1, 1);

void renderentring(const extentity &e, float radius, int axis)
{
    if(radius <= 0) return;
    gle::defvertex();
    gle::begin(GL_LINE_LOOP);
    loopi(15)
    {
        vec p(e.o);
        const vec2 &sc = sincos360[i*(360/15)];
        p[axis>=2 ? 1 : 0] += radius*sc.x;
        p[axis>=1 ? 2 : 1] += radius*sc.y;
        gle::attrib(p);
    }
    xtraverts += gle::end();
}

void renderentsphere(const extentity &e, float radius)
{
    if(radius <= 0) return;
    loopk(3) renderentring(e, radius, k);
}

/* OF */
void render_arrow(const vec& pos, const vec& dir) {
    vec target = vec(dir).mul(4.0f).add(pos), arrowbase = vec(dir).add(pos);
    vec spoke;
    spoke.orthogonal(dir);
    spoke.normalize();

    gle::begin(GL_TRIANGLE_FAN);
    gle::attrib(target);
    loopi(5) gle::attrib(vec(spoke).rotate(2*M_PI*i/4.0f, dir).add(arrowbase));
    gle::end();
}

void renderentattachment(const extentity &e, extentity *ea)
{
    if (!ea && !e.attached) return; /* OF */
    gle::defvertex();
    gle::begin(GL_LINES);
    gle::attrib(e.o);
    gle::attrib(ea ? ea->o : e.attached->o);
    xtraverts += gle::end();
    /* OF */
    if (ea) {
        vec dir = vec(ea->o).sub(e.o).normalize();
        render_arrow(vec(e.o).lerp(ea->o, 0.25f), dir);
        render_arrow(vec(e.o).lerp(ea->o, 0.75f), dir);
    }
}

void renderentarrow(const extentity &e, const vec &dir, float radius)
{
    if(radius <= 0) return;
    float arrowsize = min(radius/8, 0.5f);
    vec target = vec(dir).mul(radius).add(e.o), arrowbase = vec(dir).mul(radius - arrowsize).add(e.o), spoke;
    spoke.orthogonal(dir);
    spoke.normalize();
    spoke.mul(arrowsize);

    gle::defvertex();

    gle::begin(GL_LINES);
    gle::attrib(e.o);
    gle::attrib(target);
    xtraverts += gle::end();

    gle::begin(GL_TRIANGLE_FAN);
    gle::attrib(target);
    loopi(5) gle::attrib(vec(spoke).rotate(2*M_PI*i/4.0f, dir).add(arrowbase));
    xtraverts += gle::end();
}

void renderentcone(const extentity &e, const vec &dir, float radius, float angle)
{
    if(radius <= 0) return;
    vec spot = vec(dir).mul(radius*cosf(angle*RAD)).add(e.o), spoke;
    spoke.orthogonal(dir);
    spoke.normalize();
    spoke.mul(radius*sinf(angle*RAD));

    gle::defvertex();

    gle::begin(GL_LINES);
    loopi(8)
    {
        gle::attrib(e.o);
        gle::attrib(vec(spoke).rotate(2*M_PI*i/8.0f, dir).add(spot));
    }
    xtraverts += gle::end();

    gle::begin(GL_LINE_LOOP);
    loopi(8) gle::attrib(vec(spoke).rotate(2*M_PI*i/8.0f, dir).add(spot));
    xtraverts += gle::end();
}

void renderentbox(const extentity &e, const vec &center, const vec &radius, int yaw, int pitch, int roll)
{
    matrix4x3 orient;
    orient.identity();
    orient.settranslation(e.o);
    if(yaw) orient.rotate_around_z(sincosmod360(yaw));
    if(pitch) orient.rotate_around_x(sincosmod360(pitch));
    if(roll) orient.rotate_around_y(sincosmod360(-roll));
    orient.translate(center);

    gle::defvertex();

    vec front[4] = { vec(-radius.x, -radius.y, -radius.z), vec( radius.x, -radius.y, -radius.z), vec( radius.x, -radius.y,  radius.z), vec(-radius.x, -radius.y,  radius.z) },
        back[4] = { vec(-radius.x, radius.y, -radius.z), vec( radius.x, radius.y, -radius.z), vec( radius.x, radius.y,  radius.z), vec(-radius.x, radius.y,  radius.z) };
    loopi(4)
    {
        front[i] = orient.transform(front[i]);
        back[i] = orient.transform(back[i]);
    }

    gle::begin(GL_LINE_LOOP);
    loopi(4) gle::attrib(front[i]);
    xtraverts += gle::end();

    gle::begin(GL_LINES);
    gle::attrib(front[0]);
        gle::attrib(front[2]);
    gle::attrib(front[1]);
        gle::attrib(front[3]);
    loopi(4)
    {
        gle::attrib(front[i]);
        gle::attrib(back[i]);
    }
    xtraverts += gle::end();

    gle::begin(GL_LINE_LOOP);
    loopi(4) gle::attrib(back[i]);
    xtraverts += gle::end();
}

void renderentradius(extentity &e, bool color)
{
    switch(e.type)
    {
        case ET_LIGHT:
            if(e.attr[0] <= 0) break;
            if(color) gle::colorf(e.attr[1]/255.0f, e.attr[2]/255.0f, e.attr[3]/255.0f);
            renderentsphere(e, e.attr[0]);
            goto attach; /* OF */

        case ET_SPOTLIGHT:
            if(e.attached)
            {
                if(color) gle::colorf(0, 1, 1);
                float radius = e.attached->attr[0];
                if(radius <= 0) break;
                vec dir = vec(e.o).sub(e.attached->o).normalize();
                float angle = clamp(int(e.attr[0]), 1, 89);
                renderentattachment(e);
                renderentcone(*e.attached, dir, radius, angle);
            }
            goto attach; /* OF */

        case ET_SOUND:
            if(color) gle::colorf(0, 1, 1);
            renderentsphere(e, e.attr[0]);
            goto attach; /* OF */

        case ET_ENVMAP:
        {
            extern int envmapradius;
            if(color) gle::colorf(0, 1, 1);
            renderentsphere(e, e.attr[0] ? max(0, min(10000, int(e.attr[0]))) : envmapradius);
            goto attach; /* OF */
        }

        /* OF */
        case ET_MAPMODEL:
        case ET_OBSTACLE:
        case ET_ORIENTED_MARKER:
        {
            if(color) gle::colorf(0, 1, 1);
            vec dir;
            vecfromyawpitch(e.attr[0], e.attr[1], 1, 0, dir);
            renderentarrow(e, dir, 4);
            goto attach;
        }

        case ET_DECAL:
        {
            if(color) gle::colorf(0, 1, 1);
            DecalSlot &s = lookupdecalslot(e.attr[0], false);
            float size = max(float(e.attr[4]), 1.0f);
            renderentbox(e, vec(0, s.depth * size/2, 0), vec(size/2, s.depth * size/2, size/2), e.attr[1], e.attr[2], e.attr[3]);
            goto attach;
        }

        /* OF */
        default:
        attach:
            if (color) gle::colorf(0, 1, 1);
            lua::call_external("entity_draw_attached", "i", e.uid);
            break;
    }
}

CLUAICOMMAND(entity_draw_attachment, void, (int uid1, int uid2), {
    CLogicEntity *e1 = LogicSystem::getLogicEntity(uid1);
    CLogicEntity *e2 = LogicSystem::getLogicEntity(uid2);
    if (!e1 || !e2 || !e1->staticEntity || !e2->staticEntity) return;
    renderentattachment(*e1->staticEntity, e2->staticEntity);
});

static void renderentbox(const vec &eo, vec es)
{
    es.add(eo);

    // bottom quad
    gle::attrib(eo.x, eo.y, eo.z); gle::attrib(es.x, eo.y, eo.z);
    gle::attrib(es.x, eo.y, eo.z); gle::attrib(es.x, es.y, eo.z);
    gle::attrib(es.x, es.y, eo.z); gle::attrib(eo.x, es.y, eo.z);
    gle::attrib(eo.x, es.y, eo.z); gle::attrib(eo.x, eo.y, eo.z);

    // top quad
    gle::attrib(eo.x, eo.y, es.z); gle::attrib(es.x, eo.y, es.z);
    gle::attrib(es.x, eo.y, es.z); gle::attrib(es.x, es.y, es.z);
    gle::attrib(es.x, es.y, es.z); gle::attrib(eo.x, es.y, es.z);
    gle::attrib(eo.x, es.y, es.z); gle::attrib(eo.x, eo.y, es.z);

    // sides
    gle::attrib(eo.x, eo.y, eo.z); gle::attrib(eo.x, eo.y, es.z);
    gle::attrib(es.x, eo.y, eo.z); gle::attrib(es.x, eo.y, es.z);
    gle::attrib(es.x, es.y, eo.z); gle::attrib(es.x, es.y, es.z);
    gle::attrib(eo.x, es.y, eo.z); gle::attrib(eo.x, es.y, es.z);
}

void renderentselection(const vec &o, const vec &ray, bool entmoving)
{
    if(noentedit() || (entgroup.empty() && enthover < 0)) return;
    vec eo, es;

    if(entgroup.length())
    {
        gle::colorub(0, 40, 0);
        gle::defvertex();
        gle::begin(GL_LINES, entgroup.length()*24);
        loopv(entgroup) entfocus(entgroup[i],
            entselectionbox(e, eo, es);
            renderentbox(eo, es);
        );
        xtraverts += gle::end();
    }

    if(enthover >= 0)
    {
        gle::colorub(0, 40, 0);
        entfocus(enthover, entselectionbox(e, eo, es)); // also ensures enthover is back in focus
        boxs3D(eo, es, 1);
        if(entmoving && entmovingshadow==1)
        {
            vec a, b;
            gle::colorub(20, 20, 20);
            (a = eo).x = eo.x - fmod(eo.x, worldsize); (b = es).x = a.x + worldsize; boxs3D(a, b, 1);
            (a = eo).y = eo.y - fmod(eo.y, worldsize); (b = es).y = a.x + worldsize; boxs3D(a, b, 1);
            (a = eo).z = eo.z - fmod(eo.z, worldsize); (b = es).z = a.x + worldsize; boxs3D(a, b, 1);
        }
        gle::colorub(200,0,0);
        boxs(entorient, eo, es);
    }

    if(showentradius)
    {
        glDepthFunc(GL_GREATER);
        gle::colorf(0.25f, 0.25f, 0.25f);
        loopv(entgroup) entfocus(entgroup[i], renderentradius(e, false));
        if(enthover>=0) entfocus(enthover, renderentradius(e, false));
        glDepthFunc(GL_LESS);
        loopv(entgroup) entfocus(entgroup[i], renderentradius(e, true));
        if(enthover>=0) entfocus(enthover, renderentradius(e, true));
    }

    gle::disable();
}

bool enttoggle(int id)
{
    undonext = true;
    int i = entgroup.find(id);
    if(i < 0)
        entadd(id);
    else
        entgroup.remove(i);
    return i < 0;
}

bool hoveringonent(int ent, int orient)
{
    if(noentedit()) return false;
    entorient = orient;
    if((efocus = enthover = ent) >= 0)
        return true;
    efocus   = entgroup.empty() ? -1 : entgroup.last();
    enthover = -1;
    return false;
}

VAR(entitysurf, 0, 0, 1);

ICOMMAND(entadd, "", (),
{
    if(enthover >= 0 && !noentedit())
    {
        if(entgroup.find(enthover) < 0) entadd(enthover);
        if(entmoving > 1) entmoving = 1;
    }
});

ICOMMAND(enttoggle, "", (),
{
    if(enthover < 0 || noentedit() || !enttoggle(enthover)) { entmoving = 0; intret(0); }
    else { if(entmoving > 1) entmoving = 1; intret(1); }
});

ICOMMAND(entmoving, "b", (int *n),
{
    if(*n >= 0)
    {
        if(!*n || enthover < 0 || noentedit()) entmoving = 0;
        else
        {
            if(entgroup.find(enthover) < 0) { entadd(enthover); entmoving = 1; }
            else if(!entmoving) entmoving = 1;
        }
    }
    intret(entmoving);
});

void entpush(int *dir)
{
    if(noentedit()) return;
    int d = dimension(entorient);
    int s = dimcoord(entorient) ? -*dir : *dir;
    if(entmoving)
    {
        groupeditpure(e.o[d] += float(s*sel.grid)); // editdrag supplies the undo
    }
    else
        groupedit(e.o[d] += float(s*sel.grid));
    if(entitysurf==1)
    {
        player->o[d] += float(s*sel.grid);
        player->resetinterp();
    }
}

VAR(entautoviewdist, 0, 25, 100);
void entautoview(int *dir)
{
    if(!haveselent()) return;
    static int s = 0;
    vec v(player->o);
    v.sub(worldpos);
    v.normalize();
    v.mul(entautoviewdist);
    int t = s + *dir;
    s = abs(t) % entgroup.length();
    if(t<0 && s>0) s = entgroup.length() - s;
    entfocus(entgroup[s],
        v.add(e.o);
        player->o = v;
        player->resetinterp();
    );
}

COMMAND(entautoview, "i");
COMMAND(entflip, "");
COMMAND(entrotate, "i");
COMMAND(entpush, "i");

void delent()
{
    if(noentedit()) return;

    loopv(entgroup) entfocus(
        entgroup[i],
        MessageSystem::send_RequestLogicEntityRemoval(e.uid)
    );

    entcancel();
}

VAR(entdrop, 0, 2, 3);

bool dropentity(entity &e, int drop = -1)
{
    extern int entdrop;
    vec radius(4.0f, 4.0f, 4.0f);
    if(drop<0) drop = entdrop;
    if(e.type == ET_MAPMODEL)
    {
        extentity& ext = *((extentity*)&e); // INTENSITY
        model *m = ext.m; // INTENSITY
        if(m)
        {
            vec center;
            mmboundbox(ext, m, center, radius);
            radius.x += fabs(center.x);
            radius.y += fabs(center.y);
        }
        radius.z = 0.0f;
    }
    switch(drop)
    {
    case 1:
        if(e.type != ET_LIGHT && e.type != ET_SPOTLIGHT)
            dropenttofloor(&e);
        break;
    case 2:
    case 3:
        int cx = 0, cy = 0;
        if(sel.cxs == 1 && sel.cys == 1)
        {
            cx = (sel.cx ? 1 : -1) * sel.grid / 2;
            cy = (sel.cy ? 1 : -1) * sel.grid / 2;
        }
        e.o = vec(sel.o);
        int d = dimension(sel.orient), dc = dimcoord(sel.orient);
        e.o[R[d]] += sel.grid / 2 + cx;
        e.o[C[d]] += sel.grid / 2 + cy;
        if(!dc)
            e.o[D[d]] -= radius[D[d]];
        else
            e.o[D[d]] += sel.grid + radius[D[d]];

        if(drop == 3)
            dropenttofloor(&e);
        break;
    }
    return true;
}

void dropent()
{
    if(noentedit()) return;
    groupedit(dropentity(e));
}

void attachent()
{
    if(noentedit()) return;
    groupedit(attachentity(e));
}

COMMAND(attachent, "");

vec saved_pos;

#define FAR_PLACING_FACTOR 0.9

void newent(const char *cl, const char *sd, const char *nd, vec fp)
{
    fp.mul(FAR_PLACING_FACTOR);
    vec cp = player->o;
    cp.mul(1 - FAR_PLACING_FACTOR);
    cp.add(fp);

    if (!sd || !sd[0]) sd = "{}";
    MessageSystem::send_NewEntityRequest(cl, cp.x, cp.y, cp.z, sd, nd ? nd : "");
}

#undef FAR_PLACING_FACTOR

void newent(const char *cl, const char *sd) {
    newent(cl, sd, NULL, saved_pos);
}

ICOMMAND(newent, "V", (tagval *args, int numargs), {
    const char *cl = args[0].getstr();
    vector<char> buf;
    buf.add('[');
    for (int i = 1; i < numargs; ++i) {
        const char *str = args[i].getstr();
        int len = strlen(str);
        buf.reserve(len + 2);
        buf.add('"');
        memcpy(&buf[buf.ulen], str, len);
        buf.advance(len);
        buf.add('"');
        if (i < (numargs - 1)) buf.add(',');
    }
    buf.add(']');
    buf.add('\0');
    newent(cl, NULL, buf.getbuf(), worldpos);
});

ICOMMAND(newentpos, "V", (tagval *args, int numargs), {
    if (numargs < 4) return;
    vec pos(args[0].getfloat(), args[1].getfloat(), args[2].getfloat());
    const char *cl = args[3].getstr();
    vector<char> buf;
    buf.add('[');
    for (int i = 4; i < numargs; ++i) {
        const char *str = args[i].getstr();
        int len = strlen(str);
        buf.reserve(len + 2);
        buf.add('"');
        memcpy(&buf[buf.ulen], str, len);
        buf.advance(len);
        buf.add('"');
        if (i < (numargs - 1)) buf.add(',');
    }
    buf.add(']');
    buf.add('\0');
    newent(cl, NULL, buf.getbuf(), pos);
})

LUAICOMMAND(new_entity, {
    vec pos = saved_pos;
    if (!lua_isnoneornil(L, 3)) {
        pos.x = luaL_optnumber(L, 3, 0);
        pos.y = luaL_optnumber(L, 4, 0);
        pos.z = luaL_optnumber(L, 5, 0);
    }
    newent(luaL_checkstring(L, 1), luaL_optstring(L, 2, ""), NULL, pos);
    return 0;
});

ICOMMAND(save_mouse_position, "", (), saved_pos = worldpos);

CLUAICOMMAND(save_mouse_position, void, (), {
    saved_pos = worldpos;
});

int entcopygrid;
vector<extentity> entcopybuf; // INTENSITY: extentity, for uniqueID

void entcopy()
{
    if(noentedit()) return;
    entcopygrid = sel.grid;
    entcopybuf.shrink(0);
    addimplicit({
        loopv(entgroup) entfocus(entgroup[i], entcopybuf.add(e).o.sub(vec(sel.o)));
    });
}

void entpaste()
{
    if(noentedit() || entcopybuf.empty()) return;
    entcancel();
//    int last = entities::getents().length()-1; // INTENSITY
    float m = float(sel.grid)/float(entcopygrid);
    loopv(entcopybuf)
    {
        const extentity &c = entcopybuf[i]; // INTENSITY: extentity, for uniqueID
        vec o = vec(c.o).mul(m).add(vec(sel.o));

        const char *cn;
        lua::pop_external_ret(lua::call_external_ret("entity_get_proto_name",
            "i", "s", c.uid, &cn));

        const char *sd;
        int npop = lua::call_external_ret("entity_serialize_sdata", "ifff", "s",
            c.uid, o.x, o.y, o.z, &sd);

        newent(cn, sd);
        lua::pop_external_ret(npop);
    }
// INTENSITY   int j = 0;
// INTENSITY   groupeditundo(e.type = entcopybuf[j++].type;);
}

COMMAND(delent, "");
COMMAND(dropent, "");
COMMAND(entcopy, "");
COMMAND(entpaste, "");

/* OF */
void printent(extentity &e, char *buf, int len) {
    const char *name, *info;
    int npop = lua::call_external_ret("entity_get_edit_info", "i", "ss", e.uid,
        &name, &info);
    if (!info || !info[0]) nformatstring(buf, len, "%s", name);
    else nformatstring(buf, len, "%s\n\f7%s (\f2%d\f7)", info, name, e.uid);
    lua::pop_external_ret(npop);
}

void nearestent()
{
    if(noentedit()) return;
    int closest = -1;
    float closedist = 1e16f;
    vector<extentity *> &ents = entities::getents();
    loopv(ents)
    {
        extentity &e = *ents[i];
        if(e.type == ET_EMPTY) continue;
        float dist = e.o.dist(player->o);
        if(dist < closedist)
        {
            closest = i;
            closedist = dist;
        }
    }
    if(closest >= 0) entadd(closest);
}

ICOMMAND(enthavesel, "",  (), addimplicit(intret(entgroup.length())));
ICOMMAND(entselect,  "e", (uint *body), if(!noentedit()) addgroup(e.type != ET_EMPTY && entgroup.find(n)<0 && executebool(body)));
ICOMMAND(entloop,    "e", (uint *body), if(!noentedit()) addimplicit(groupeditloop(((void)e, execute(body)))));
ICOMMAND(insel,      "",  (), entfocus(efocus, intret(pointinsel(sel, e.o))));
ICOMMAND(entgetinfo, "",  (), entfocus(efocus, string s; printent(e, s, sizeof(s)); result(s)));
ICOMMAND(entindex,   "",  (), intret(efocus));
COMMAND(nearestent,  "");

static string copied_class = {'\0'};
static char copied_sdata[4096] = {'\0'};

void intensityentcopy() // INTENSITY
{
    if (efocus < 0) {
        copied_class[0] = copied_sdata[0] = '\0'; return;
    }

    extentity& e = *(entities::getents()[efocus]);

    const char *name;
    lua::pop_external_ret(lua::call_external_ret("entity_get_proto_name",
        "i", "s", e.uid, &name));
    copystring(copied_class, name);

    const char *sd;
    int npop = lua::call_external_ret("entity_serialize_sdata", "i", "s",
        e.uid, &sd);

    copystring(copied_sdata, sd, sizeof(copied_sdata));
    lua::pop_external_ret(npop);
}

void intensitypasteent() // INTENSITY
{
    newent(copied_class, copied_sdata);
}

COMMAND(intensityentcopy, "");
COMMAND(intensitypasteent, "");

/* OF */
void enttype(char *type, int *numargs) {
    if (*numargs >= 1) {
        groupedit(
            vec pos(e.o);
            MessageSystem::send_RequestLogicEntityRemoval(e.uid);
            MessageSystem::send_NewEntityRequest(type, pos.x, pos.y, pos.z,
                "{}", "");
        );
    } else entfocus(efocus, {
        const char *name;
        lua::pop_external_ret(lua::call_external_ret("entity_get_proto_name",
            "i", "s", e.uid, &name));
        result(name ? name : "");
    })
}

/* OF */
void entattr(char *attr, char *val, int *numargs) {
    if (*numargs >= 2) {
        groupedit(
            lua::call_external("entity_set_gui_attr", "iss", e.uid, attr, val);
        );
    } else entfocus(efocus, {
        const char *str;
        int npop = lua::call_external_ret("entity_get_gui_attr", "is", "s",
            e.uid, attr, &str);
        result(str ? str : "");
        lua::pop_external_ret(npop);
    });
}

COMMAND(enttype, "sN");
COMMAND(entattr, "ssN");

int findentity(int type, int index, int attr1, int attr2)
{
    const vector<extentity *> &ents = entities::getents();
    if(index > ents.length()) index = ents.length();
    else for(int i = index; i<ents.length(); i++)
    {
        extentity &e = *ents[i];
        if(e.type==type && (attr1<0 || e.attr[0]==attr1) && (attr2<0 || e.attr[1]==attr2))
            return i;
    }
    loopj(index)
    {
        extentity &e = *ents[j];
        if(e.type==type && (attr1<0 || e.attr[0]==attr1) && (attr2<0 || e.attr[1]==attr2))
            return j;
    }
    return -1;
}

void splitocta(cube *c, int size)
{
    if(size <= 0x1000) return;
    loopi(8)
    {
        if(!c[i].children) c[i].children = newcubes(isempty(c[i]) ? F_EMPTY : F_SOLID);
        splitocta(c[i].children, size>>1);
    }
}

void resetmap()
{
    clearoverrides();
    stopmapsounds();
    resetblendmap();
    clearlights();
    clearpvs();
    clearslots();
    clearparticles();
    clearstains();
    clearsleep();
    cancelsel();
    pruneundos();
    clearmapcrc();

    gamespeed = 100;
    paused = 0;

    entities::clearents();
    outsideents.setsize(0);
    spotlights = 0;
    volumetriclights = 0;
}

void startmap(const char *name)
{
    game::startmap(name);
    ovr::reset();
}

bool emptymap(int scale, bool force, const char *mname, bool usecfg)    // main empty world creation routine
{
    if(!force && !editmode)
    {
        conoutf(CON_ERROR, "newmap only allowed in edit mode");
        return false;
    }

    resetmap();

    setvar("mapscale", scale<10 ? 10 : (scale>16 ? 16 : scale), true, false);
    setvar("mapsize", 1<<worldscale, true, false);

    texmru.shrink(0);
    freeocta(worldroot);
    worldroot = newcubes(F_EMPTY);
    loopi(4) solidfaces(worldroot[i]);

    if(worldsize > 0x1000) splitocta(worldroot, worldsize>>1);

    extern void clear_texpacks(int n = 0); clear_texpacks();
    lua::call_external("gui_clear", "");

    if (usecfg)
    {
        identflags |= IDF_OVERRIDDEN;
        execfile("config/default_map_settings.cfg", false);
        identflags &= ~IDF_OVERRIDDEN;
    }

    initlights();
    allchanged(usecfg);

    startmap(mname);

    return true;
}

bool enlargemap(bool force)
{
    if(!force && !editmode)
    {
        conoutf(CON_ERROR, "mapenlarge only allowed in edit mode");
        return false;
    }
    if(worldsize >= 1<<16) return false;

    while(outsideents.length()) removeentity(outsideents.pop());

    worldscale++;
    worldsize *= 2;
    cube *c = newcubes(F_EMPTY);
    c[0].children = worldroot;
    loopi(3) solidfaces(c[i+1]);
    worldroot = c;

    if(worldsize > 0x1000) splitocta(worldroot, worldsize>>1);

    enlargeblendmap();
    allchanged();

    return true;
}

static bool isallempty(cube &c)
{
    if(!c.children) return isempty(c);
    loopi(8) if(!isallempty(c.children[i])) return false;
    return true;
}

void shrinkmap()
{
    extern int nompedit;
    if(noedit(true) || (nompedit && multiplayer())) return;
    if(worldsize <= 1<<10) return;

    int octant = -1;
    loopi(8) if(!isallempty(worldroot[i]))
    {
        if(octant >= 0) return;
        octant = i;
    }
    if(octant < 0) return;

    while(outsideents.length()) removeentity(outsideents.pop());

    if(!worldroot[octant].children) subdividecube(worldroot[octant], false, false);
    cube *root = worldroot[octant].children;
    worldroot[octant].children = NULL;
    freeocta(worldroot);
    worldroot = root;
    worldscale--;
    worldsize /= 2;

    ivec offset(octant, ivec(0, 0, 0), worldsize);
    vector<extentity *> &ents = entities::getents();
    loopv(ents) ents[i]->o.sub(vec(offset));

    shrinkblendmap(octant);
    allchanged();

    conoutf("shrunk map to size %d", worldscale);
}

//void newmap(int i) { bool force = !isconnected(); if(emptymap(i, force, NULL)) game::newmap(max(i, 0)); }
void mapenlarge() { if(enlargemap(false)) game::newmap(-1); }
//COMMAND(newmap, "i");
COMMAND(mapenlarge, "");
COMMAND(shrinkmap, "");

void mapname()
{
    result(game::getclientmap());
}

COMMAND(mapname, "");

void finish_dragging() {
    groupeditpure(
        const vec& o = e.o;
        defformatstring(pos, "[%f|%f|%f]", o.x, o.y, o.z);
        lua::call_external("entity_set_gui_attr", "iss", e.uid,
            "position", pos);
    );
}

COMMAND(finish_dragging, "");

int getworldsize() { return worldsize; }
int getmapversion() { return mapversion; }
