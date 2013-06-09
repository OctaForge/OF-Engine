// world.cpp: core map management stuff

#include "engine.h"

#include "editing_system.h" // INTENSITY
#include "message_system.h" // INTENSITY
#include "of_tools.h"

VARR(mapversion, 1, MAPVERSION, 0);
VARNR(mapscale, worldscale, 1, 0, 0);
VARNR(mapsize, worldsize, 1, 0, 0);
SVARR(maptitle, "Untitled Map by Unknown");
SVARR(player_class, "player"); /* OF: overridable pcclass */
VAR(octaentsize, 0, 128, 1024);
VAR(entselradius, 0, 2, 10);

bool getentboundingbox(extentity &e, ivec &o, ivec &r)
{
    switch(e.type)
    {
        case ET_EMPTY:
            return false;
        case ET_MAPMODEL:
        {
            CLogicEntity *entity = LogicSystem::getLogicEntity(e); // INTENSITY
            model *m = entity ? entity->getModel() : NULL; // INTENSITY
            if(m)
            {
                vec center, radius;
                m->boundbox(center, radius);
                if(e.attr[3] > 0)
                {
                    float scale = e.attr[3]/100.0f;
                    center.mul(scale);
                    radius.mul(scale);
                }
                rotatebb(center, radius, e.attr[0], e.attr[1], e.attr[2]); // OF
                o = e.o;
                o.add(center);
                r = radius;
                r.add(1);
                o.sub(r);
                r.mul(2);
                break;
            }
        }
        case ET_OBSTACLE: /* OF */
        {
            o = e.o;
            int a = e.attr[3], b = e.attr[4], c = e.attr[5];
            if (!a || !b || !c) {
                o.sub(entselradius);
                r.x = r.y = r.z = entselradius*2;
                break;
            }
            vec center = vec(0, 0, 0), radius = vec(a, b, c);
            rotatebb(center, radius, e.attr[0], e.attr[1], e.attr[2]);
            o.add(center);
            r = radius;
            r.add(1);
            o.sub(r);
            r.mul(2);
            break;
        }
        // invisible mapmodels use entselradius
        default:
            o = e.o;
            o.sub(entselradius);
            r.x = r.y = r.z = entselradius*2;
            break;
    }
    return true;
}

enum
{
    MODOE_ADD      = 1<<0,
    MODOE_UPDATEBB = 1<<1
};

void modifyoctaentity(int flags, int id, extentity &e, cube *c, const ivec &cor, int size, const ivec &bo, const ivec &br, int leafsize, vtxarray *lastva = NULL)
{
    loopoctabox(cor, size, bo, br)
    {
        ivec o(i, cor.x, cor.y, cor.z, size);
        vtxarray *va = c[i].ext && c[i].ext->va ? c[i].ext->va : lastva;
        if(c[i].children != NULL && size > leafsize)
            modifyoctaentity(flags, id, e, c[i].children, o, size>>1, bo, br, leafsize, va);
        else if(flags&MODOE_ADD)
        {
            if(!c[i].ext || !c[i].ext->ents) ext(c[i]).ents = new octaentities(o, size);
            octaentities &oe = *c[i].ext->ents;
            switch(e.type)
            {
                case ET_OBSTACLE: /* OF */
                    oe.mapmodels.add(id);
                    break;
                case ET_MAPMODEL:
                    if(LogicSystem::getLogicEntity(e)->getModel()) //loadmodel(NULL, entities::getents()[id]->attr[1])) // INTENSITY: Get model from our system
                    {
                        if(va)
                        {
                            va->bbmin.x = -1;
                            if(oe.mapmodels.empty()) va->mapmodels.add(&oe);
                        }
                        oe.mapmodels.add(id);
                        loopk(3)
                        {
                            oe.bbmin[k] = min(oe.bbmin[k], max(oe.o[k], bo[k]));
                            oe.bbmax[k] = max(oe.bbmax[k], min(oe.o[k]+size, bo[k]+br[k]));
                        }
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
                case ET_OBSTACLE: /* OF */
                    oe.mapmodels.removeobj(id);
                    break;
                case ET_MAPMODEL:
                    if(LogicSystem::getLogicEntity(e)->getModel()) // loadmodel(NULL, entities::getents()[id]->attr[1])) // INTENSITY: Get model from our system
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
                            if(getentboundingbox(e, eo, er)) loopk(3)
                            {
                                oe.bbmin[k] = min(oe.bbmin[k], eo[k]);
                                oe.bbmax[k] = max(oe.bbmax[k], eo[k]+er[k]);
                            }
                        }
                        loopk(3)
                        {
                            oe.bbmin[k] = max(oe.bbmin[k], oe.o[k]);
                            oe.bbmax[k] = min(oe.bbmax[k], oe.o[k]+size);
                        }
                        break;
                    }
                    // invisible mapmodel
                default:
                    oe.other.removeobj(id);
                    break;
            }
            if(oe.mapmodels.empty() && oe.other.empty()) 
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

static bool modifyoctaent(int flags, int id, extentity &e)
{
    if(flags&MODOE_ADD ? e.inoctanode : !e.inoctanode) return false;

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
        int leafsize = octaentsize, limit = max(r.x, max(r.y, r.z));
        while(leafsize < limit) leafsize *= 2;
        int diff = ~(leafsize-1) & ((o.x^(o.x+r.x))|(o.y^(o.y+r.y))|(o.z^(o.z+r.z)));
        if(diff && (limit > octaentsize/2 || diff < leafsize*2)) leafsize *= 2;
        modifyoctaentity(flags, id, e, worldroot, ivec(0, 0, 0), worldsize>>1, o, r, leafsize);
    }
    e.inoctanode = flags&MODOE_ADD ? 1 : 0;
    if(e.type == ET_LIGHT) clearlightcache(id);
    else if(e.type == ET_PARTICLES) clearparticleemitters();
    return true;
}

/* OctaForge: getentid */
static int getentid(extentity *entity) {
    int id = 0;
    const vector<extentity *> &ents = entities::getents();
    while (ents[id] != entity) {
        id++;
        assert(id < ents.length());
    }

    return id;
}

static inline bool modifyoctaent(int flags, int id) {
    return entities::getents().inrange(id) && modifyoctaent(flags, id, *entities::getents()[id]);
}

void addentity(int id)    { modifyoctaent(MODOE_ADD|MODOE_UPDATEBB, id); } // INTENSITY: Removed 'static' and 'inline'
void removeentity(int id) { modifyoctaent(MODOE_UPDATEBB, id); } // INTENSITY: Removed 'static' and 'inline'

/* OctaForge: extentity* versions */
void addentity(extentity* entity) { addentity(getentid(entity)); }
void removeentity(extentity *entity) { removeentity(getentid(entity)); }

void freeoctaentities(cube &c)
{
    if(!c.ext) return;
    if(entities::getents().length())
    {
        while(c.ext->ents && !c.ext->ents->mapmodels.empty()) removeentity(c.ext->ents->mapmodels.pop());
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
        if(e.type >= low && e.type <= high && (e.spawned || notspawned) && vec(e.o).mul(radius).squaredlen() <= 1) found.add(id);
    }
}

static inline void findents(cube *c, const ivec &o, int size, const ivec &bo, const ivec &br, int low, int high, bool notspawned, const vec &pos, const vec &radius, vector<int> &found)
{
    loopoctabox(o, size, bo, br)
    {
        if(c[i].ext && c[i].ext->ents) findents(*c[i].ext->ents, low, high, notspawned, pos, radius, found);
        if(c[i].children && size > octaentsize) 
        {
            ivec co(i, o.x, o.y, o.z, size);
            findents(c[i].children, co, size>>1, bo, br, low, high, notspawned, pos, radius, found);
        }
    }
}

void findents(int low, int high, bool notspawned, const vec &pos, const vec &radius, vector<int> &found)
{
    vec invradius(1/radius.x, 1/radius.y, 1/radius.z);
    ivec bo = vec(pos).sub(radius).sub(1),
         br = vec(radius).add(1).mul(2);
    int diff = (bo.x^(bo.x+br.x)) | (bo.y^(bo.y+br.y)) | (bo.z^(bo.z+br.z)) | octaentsize,
        scale = worldscale-1;
    if(diff&~((1<<scale)-1) || uint(bo.x|bo.y|bo.z|(bo.x+br.x)|(bo.y+br.y)|(bo.z+br.z)) >= uint(worldsize))
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

bool pointinsel(selinfo &sel, vec &o)
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
#define addimplicit(f)  { if(entgroup.empty() && enthover>=0) { entadd(enthover); undonext = (enthover != oldhover); f; entgroup.drop(); } else f; }
#define entfocus(i, f)  { int n = efocus = (i); if(n>=0) { extentity &e = *entities::getents()[n]; f; } }
#define entedit(i, f) \
{ \
    entfocus(i, \
    int oldtype = e.type; \
    removeentity(n);  \
    f; \
    if(oldtype!=e.type) detachentity(e); \
    if(e.type!=ET_EMPTY) { addentity(n); if(oldtype!=e.type) attachentity(e); }) \
    clearshadowcache(); \
}
#define addgroup(exp)   { loopv(entities::getents()) entfocus(i, if(exp) entadd(n)); }
#define setgroup(exp)   { entcancel(); addgroup(exp); }
#define groupeditloop(f){ entlooplevel++; int _ = efocus; loopv(entgroup) entedit(entgroup[i], f); efocus = _; entlooplevel--; }
#define groupeditpure(f){ if(entlooplevel>0) { entedit(efocus, f); } else groupeditloop(f); }
#define groupeditundo(f){ makeundoent(); groupeditpure(f); }
#define groupedit(f)    { addimplicit(groupeditundo(f)); }

vec getselpos()
{
    vector<extentity *> &ents = entities::getents();
    if(entgroup.length() && ents.inrange(entgroup[0])) return ents[entgroup[0]]->o;
    if(ents.inrange(enthover)) return ents[enthover]->o;
    return sel.o.tovec();
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

void pasteundoents(undoblock *u)
{
    undoent *ue = u->ents();
    loopi(u->numents)
        entedit(ue[i].i, (entity &)e = ue[i].e);
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
    CLogicEntity *entity = LogicSystem::getLogicEntity(*_e); // INTENSITY

    model *m = NULL;
    if(e.type == ET_MAPMODEL && (m = entity->getModel())) // INTENSITY
    {
        m->collisionbox(eo, es);
        if(e.attr[3] > 0) { float scale = e.attr[3]/100.0f; eo.mul(scale); es.mul(scale); }
        rotatebb(eo, es, e.attr[0], e.attr[1], e.attr[2]); // OF
        eo.add(e.o);
    }
    else if(e.type == ET_OBSTACLE && e.attr[3] && e.attr[4] && e.attr[5]) /* OF */
    {
        eo = vec(0, 0, 0);
        es = vec(e.attr[3], e.attr[4], e.attr[5]);
        rotatebb(eo, es, e.attr[0], e.attr[1], e.attr[2]);
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
extern void editmoveplane(const vec &o, const vec &ray, int d, float off, vec &handle, vec &dest, bool first);

bool initentdragging = true;

void entdrag(const vec &ray)
{
    if(noentedit() || !haveselent()) return;

    float r = 0, c = 0;
    static vec v, handle;
    vec eo, es;
    int d = dimension(entorient),
        dc= dimcoord(entorient);

    entfocus(entgroup.last(),        
        entselectionbox(e, eo, es);

        editmoveplane(e.o, ray, d, eo[d] + (dc ? es[d] : 0), handle, v, initentdragging);        

        ivec g(v);
        int z = g[d]&(~(sel.grid-1));
        g.add(sel.grid/2).mask(~(sel.grid-1));
        g[d] = z;
        
        r = (entselsnap ? g[R[d]] : v[R[d]]) - e.o[R[d]];
        c = (entselsnap ? g[C[d]] : v[C[d]]) - e.o[C[d]];       
    );

    if(initentdragging) makeundoent();
    groupeditpure(e.o[R[d]] += r; e.o[C[d]] += c);
    initentdragging = false;
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
    gle::end();
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
    gle::end();
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
    gle::end();

    gle::begin(GL_TRIANGLE_FAN);
    gle::attrib(target);
    loopi(5) gle::attrib(vec(spoke).rotate(2*M_PI*i/4.0f, dir).add(arrowbase));
    gle::end();
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
    gle::end();

    gle::begin(GL_LINE_LOOP);
    loopi(8) gle::attrib(vec(spoke).rotate(2*M_PI*i/8.0f, dir).add(spot));
    gle::end();
}

void renderentradius(extentity &e, bool color)
{
    switch(e.type)
    {
        case ET_LIGHT:
            if(color) gle::colorf(e.attr[1]/255.0f, e.attr[2]/255.0f, e.attr[3]/255.0f);
            renderentsphere(e, e.attr[0]);
            goto attach; /* OF */

        case ET_SPOTLIGHT:
            if(e.attached)
            {
                if(color) gle::colorf(0, 1, 1);
                float radius = e.attached->attr[0];
                if(!radius) radius = 2*e.o.dist(e.attached->o);
                vec dir = vec(e.o).sub(e.attached->o).normalize();
                float angle = clamp(int(e.attr[0]), 1, 89);
                renderentattachment(e);
                renderentcone(*e.attached, dir, radius, angle); 
            }
            goto attach; /* OF */

        case ET_SOUND:
            if(color) gle::colorf(0, 1, 1);
            renderentsphere(e, e.attr[1]);
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

        /* OF */
        default:
        attach:
            CLogicEntity *el = LogicSystem::getLogicEntity(e);
            if (!el) break;

            lua::push_external("entity_get_attached");
            lua_rawgeti(lua::L, LUA_REGISTRYINDEX, el->lua_ref);
            lua_call(lua::L, 1, 2);
            if (lua_isnil(lua::L, -2)) { lua_pop(lua::L, 2); break; }

            CLogicEntity *a1 = NULL, *a2 = NULL;

            lua_getfield(lua::L, -2, "uid");
            a1 = LogicSystem::getLogicEntity(lua_tointeger(lua::L, -1));
            lua_pop(lua::L, 1);

            if (!a1 || !a1->staticEntity) break;
            if (!lua_isnil(lua::L, -1)) {
                lua_getfield(lua::L, -1, "uid");
                a2 = LogicSystem::getLogicEntity(lua_tointeger(lua::L, -1));
                lua_pop(lua::L, 1);
            }

            if (color) gle::colorf(0, 1, 1);
            renderentattachment(*a1->staticEntity, a2 ? a2->staticEntity : NULL);
            break;
    }
}

void renderentselection(const vec &o, const vec &ray, bool entmoving)
{   
    if(noentedit()) return;
    vec eo, es;

    gle::colorub(0, 40, 0);
    loopv(entgroup) entfocus(entgroup[i],     
        entselectionbox(e, eo, es);
        boxs3D(eo, es, 1);
    );

    if(enthover >= 0)
    {
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

    if(showentradius && (entgroup.length() || enthover >= 0))
    {
        glDepthFunc(GL_GREATER);
        gle::colorf(0.25f, 0.25f, 0.25f);
        loopv(entgroup) entfocus(entgroup[i], renderentradius(e, false));
        if(enthover>=0) entfocus(enthover, renderentradius(e, false));
        glDepthFunc(GL_LESS);
        loopv(entgroup) entfocus(entgroup[i], renderentradius(e, true));
        if(enthover>=0) entfocus(enthover, renderentradius(e, true));
        gle::disable();
    }
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
VARF(entmoving, 0, 0, 2,
    if(enthover < 0 || noentedit())
        entmoving = 0;
    else if(entmoving == 1)
        entmoving = enttoggle(enthover);
    else if(entmoving == 2 && entgroup.find(enthover) < 0)
        entadd(enthover);
    if(entmoving > 0)
        initentdragging = true;
);

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
        MessageSystem::send_RequestLogicEntityRemoval(e.uniqueId)
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
        CLogicEntity *entity = LogicSystem::getLogicEntity(ext); // INTENSITY
        model *m = entity ? entity->getModel() : NULL; // INTENSITY
        if(m)
        {
            vec center;
            m->boundbox(center, radius);
            if(e.attr[3] > 0) { float scale = e.attr[3]/100.0f; center.mul(scale); radius.mul(scale); }
            rotatebb(center, radius, e.attr[0], e.attr[1], e.attr[2]); // OF
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
        e.o = sel.o.tovec();
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

/* OF */
static const int attrnums[] = {
    0, /* ET_EMPTY */
    0, /* ET_MARKER */
    2, /* ET_ORIENTED_MARKER */
    5, /* ET_LIGHT */
    1, /* ET_SPOTLIGHT */
    1, /* ET_ENVMAP */
    3, /* ET_SOUND */
    5, /* ET_PARTICLES */
    4, /* ET_MAPMODEL */
    7  /* ET_OBSTACLE */
};

int getattrnum(int type) {
    return attrnums[(type >= 0 &&
        (size_t)type < (sizeof(attrnums) / sizeof(int))) ? type : 0];
}

int entcopygrid;
vector<extentity> entcopybuf; // INTENSITY: extentity, for uniqueID

void entcopy()
{
    if(noentedit()) return;
    entcopygrid = sel.grid;
    entcopybuf.shrink(0);
    loopv(entgroup) 
        entfocus(entgroup[i], entcopybuf.add(e).o.sub(sel.o.tovec()));
}

void entpaste()
{
    if(noentedit()) return;
    if(entcopybuf.length()==0) return;
    entcancel();
//    int last = entities::getents().length()-1; // INTENSITY
    float m = float(sel.grid)/float(entcopygrid);
    loopv(entcopybuf)
    {
        extentity &c = entcopybuf[i]; // INTENSITY: extentity, for uniqueID
        vec o(c.o);
        o.mul(m).add(sel.o.tovec());

        // INTENSITY: Create entity using new system
        CLogicEntity *entity = LogicSystem::getLogicEntity(c);
        if (!entity) return;

        lua::push_external("entity_get_class_name");
        lua_rawgeti(lua::L, LUA_REGISTRYINDEX, entity->lua_ref);
        lua_call(lua::L, 1, 1);
        const char *cn = lua_tostring(lua::L, -1); lua_pop(lua::L, -1);

        lua_rawgeti (lua::L, LUA_REGISTRYINDEX, entity->lua_ref);
        lua_getfield(lua::L, -1, "build_sdata");
        lua_insert  (lua::L, -2);
        lua_call    (lua::L,  1, 1);

        lua_pushfstring(lua::L, "[%f|%f|%f]", o.x, o.y, o.z);
        lua_setfield   (lua::L, -2, "position");

        lua::push_external("table_serialize"); lua_insert(lua::L, -2);
        lua_call(lua::L, 1, 1);
        const char *sd = luaL_optstring(lua::L, -1, "{}");
        lua_pop(lua::L, 1);

        EditingSystem::newent(cn, sd);
    }
// INTENSITY   int j = 0;
// INTENSITY   groupeditundo(e.type = entcopybuf[j++].type;);
}

COMMAND(delent, "");
COMMAND(dropent, "");
COMMAND(entcopy, "");
COMMAND(entpaste, "");

/* OF */
void printent(extentity &e, char *buf) {
    lua::push_external("entity_get_edit_info");
    lua_rawgeti(lua::L, LUA_REGISTRYINDEX,
        LogicSystem::getLogicEntity(e)->lua_ref);
    lua_call(lua::L, 1, 2);
    const char *info = lua_tostring(lua::L, -1);
    const char *name = lua_tostring(lua::L, -2); lua_pop(lua::L, 2);
    if (!info || !info[0]) formatstring(buf)("%s", name);
    else formatstring(buf)("%s (%s)", name, info);
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
            
ICOMMAND(enthavesel,"",  (), addimplicit(intret(entgroup.length())));
ICOMMAND(entselect, "e", (uint *body), if(!noentedit()) addgroup(e.type != ET_EMPTY && entgroup.find(n)<0 && executebool(body)));
ICOMMAND(entloop,   "e", (uint *body), if(!noentedit()) addimplicit(groupeditloop(((void)e, execute(body)))));
ICOMMAND(insel,     "",  (), entfocus(efocus, intret(pointinsel(sel, e.o))));
ICOMMAND(entget,    "",  (), entfocus(efocus, string s; printent(e, s); result(s)));
ICOMMAND(entindex,  "",  (), intret(efocus));
COMMAND(nearestent, "");

static string copied_class = {'\0'};
static char copied_sdata[4096] = {'\0'};

void intensityentcopy() // INTENSITY
{
    if (efocus < 0) {
        copied_class[0] = copied_sdata[0] = '\0'; return;
    }

    extentity& e = *(entities::getents()[efocus]);
    CLogicEntity *entity = LogicSystem::getLogicEntity(e);

    lua::push_external("entity_get_class_name");
    lua_rawgeti(lua::L, LUA_REGISTRYINDEX, entity->lua_ref);
    lua_call(lua::L, 1, 1);
    copystring(copied_class, lua_tostring(lua::L, -1)); lua_pop(lua::L, -1);

    lua_rawgeti (lua::L, LUA_REGISTRYINDEX, entity->lua_ref);
    lua_getfield(lua::L, -1, "build_sdata");
    lua_insert  (lua::L, -2);
    lua_call    (lua::L,  1, 1);

    lua_pushnil (lua::L);
    lua_setfield(lua::L, -2, "position");

    lua::push_external("table_serialize"); lua_insert(lua::L, -2);
    lua_call(lua::L,  1, 1);
    copystring(copied_sdata, luaL_optstring(lua::L, -1, "{}"), sizeof(copied_sdata));
    lua_pop(lua::L, 1);
}

void intensitypasteent() // INTENSITY
{
    EditingSystem::newent(copied_class, copied_sdata);
}

COMMAND(intensityentcopy, "");
COMMAND(intensitypasteent, "");

/* OF */
void enttype(char *type, int *numargs) {
    if (*numargs >= 1) {
        groupedit(
            vec pos(e.o);
            MessageSystem::send_RequestLogicEntityRemoval(e.uniqueId);
            MessageSystem::send_NewEntityRequest(type, pos.x, pos.y, pos.z,
                "{}");
        );
    } else entfocus(efocus, {
        lua::push_external("entity_get_class_name");
        lua_rawgeti(lua::L, LUA_REGISTRYINDEX,
            LogicSystem::getLogicEntity(e)->lua_ref);
        lua_call(lua::L, 1, 1);
        const char *str = lua_tostring(lua::L, -1); lua_pop(lua::L, -1);
        result(str);
    })
}

/* OF */
void entattr(char *attr, char *val, int *numargs) {
    if (*numargs >= 2) {
        groupedit(
            lua::push_external("entity_set_gui_attr");
            lua_rawgeti(lua::L, LUA_REGISTRYINDEX,
                LogicSystem::getLogicEntity(e)->lua_ref);
            lua_pushstring(lua::L, attr);
            lua_pushstring(lua::L, val);
            lua_call(lua::L, 3, 0);
        );
    } else entfocus(efocus, {
        lua::push_external("entity_get_gui_attr");
        lua_rawgeti(lua::L, LUA_REGISTRYINDEX,
            LogicSystem::getLogicEntity(e)->lua_ref);
        lua_pushstring(lua::L, attr);
        lua_call(lua::L, 2, 1);
        const char *str = lua_tostring(lua::L, -1); lua_pop(lua::L, -1);
        result(str);
    });
}

COMMAND(enttype, "sN");
COMMAND(entattr, "ssN");

int findentity(int type, int index, int attr1, int attr2)
{
    const vector<extentity *> &ents = entities::getents();
    for(int i = index; i<ents.length(); i++) 
    {
        extentity &e = *ents[i];
        if(e.type==type && (attr1<0 || e.attr[0]==attr1) && (attr2<0 || e.attr[1]==attr2))
            return i;
    }
    loopj(min(index, ents.length())) 
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
    clearmapsounds();
#ifndef SERVER
    resetblendmap();
    clearlights();
    clearpvs();
#endif
    clearslots();
    clearparticles();
    cleardecals();
    clearsleep();
    cancelsel();
    pruneundos();
    clearmapcrc();

    setvar("gamespeed", 100);
    setvar("paused", 0);

    entities::clearents();
    outsideents.setsize(0);
}

void startmap(const char *name)
{
    game::startmap(name);
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

#ifndef SERVER
    lua::push_external("gui_clear"); lua_call(lua::L, 0, 0);
#endif

    if (usecfg)
    {
        identflags |= IDF_OVERRIDDEN;
        execfile("config/default_map_settings.cfg", false);
        identflags &= ~IDF_OVERRIDDEN;
    }

    initlights();
    allchanged(true);

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

#ifndef SERVER
    enlargeblendmap();
#endif

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

    ivec offset(octant, 0, 0, 0, worldsize);
    vector<extentity *> &ents = entities::getents();
    loopv(ents) ents[i]->o.sub(offset.tovec());

#ifndef SERVER
    shrinkblendmap(octant);
#endif

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
        lua::push_external("entity_set_attr_uid");
        lua_pushinteger(lua::L, LogicSystem::getUniqueId(&e));
        lua_pushliteral(lua::L, "position");
        lua::push_external("new_vec3");
        lua_pushnumber (lua::L, o.x);
        lua_pushnumber (lua::L, o.y);
        lua_pushnumber (lua::L, o.z);
        lua_call       (lua::L, 3, 1);
        lua_call       (lua::L, 3, 0);
    );
}

COMMAND(finish_dragging, "");

int getworldsize() { return worldsize; }
int getmapversion() { return mapversion; }
