// world.cpp: core map management stuff

#include "engine.h"

#include "editing_system.h" // INTENSITY
#include "message_system.h" // INTENSITY

bool getentboundingbox(extentity &e, ivec &o, ivec &r)
{
    switch(e.type)
    {
        case ET_EMPTY:
            return false;
        case ET_MAPMODEL:
        {
            LogicEntityPtr entity = LogicSystem::getLogicEntity(e); // INTENSITY
            model *m = entity.get() ? entity->getModel() : NULL; // INTENSITY
            if(m)
            {
                vec center, radius;
                m->boundbox(0, center, radius, entity.get()); // INTENSITY: entity
                rotatebb(center, radius, e.attr1);
                o = e.o;
                o.add(center);
                r = radius;
                r.add(1);
                o.sub(r);
                r.mul(2);
                break;
            }
        }
        // invisible mapmodels use entselradius
        default:
            o = e.o;
            o.sub(GETIV(entselradius));
            r.x = r.y = r.z = GETIV(entselradius)*2;
            break;
    }
    return true;
}

enum
{
    MODOE_ADD      = 1<<0,
    MODOE_UPDATEBB = 1<<1
};

void modifyoctaentity(int flags, int id, cube *c, const ivec &cor, int size, const ivec &bo, const ivec &br, int leafsize, vtxarray *lastva = NULL)
{
    loopoctabox(cor, size, bo, br)
    {
        ivec o(i, cor.x, cor.y, cor.z, size);
        vtxarray *va = c[i].ext && c[i].ext->va ? c[i].ext->va : lastva;
        if(c[i].children != NULL && size > leafsize)
            modifyoctaentity(flags, id, c[i].children, o, size>>1, bo, br, leafsize, va);
        else if(flags&MODOE_ADD)
        {
            if(!c[i].ext || !c[i].ext->ents) ext(c[i]).ents = new octaentities(o, size);
            octaentities &oe = *c[i].ext->ents;
            switch(entities::getents()[id]->type)
            {
                case ET_MAPMODEL:
                    if(LogicSystem::getLogicEntity(*(entities::getents()[id])).get()->getModel()) //loadmodel(NULL, entities::getents()[id]->attr2)) // INTENSITY: Get model from our system
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
            switch(entities::getents()[id]->type)
            {
                case ET_MAPMODEL:
                    if(LogicSystem::getLogicEntity(*(entities::getents()[id])).get()->getModel()) // loadmodel(NULL, entities::getents()[id]->attr2)) // INTENSITY: Get model from our system
                    {
                        oe.mapmodels.removeobj(id);
                        if(va)
                        {
                            va->bbmin.x = -1;
                            if(oe.mapmodels.empty()) va->mapmodels.removeobj(&oe);
                        }
                        oe.bbmin = oe.bbmax = oe.o;
                        oe.bbmin.add(oe.size);
                        loopvj(oe.mapmodels)
                        {
                            extentity &e = *entities::getents()[oe.mapmodels[j]];
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

static bool modifyoctaent(int flags, int id)
{
    vector<extentity *> &ents = entities::getents();
    if(!ents.inrange(id)) return false;
    ivec o, r;
    extentity &e = *ents[id];
    if((flags&MODOE_ADD ? e.inoctanode : !e.inoctanode) || !getentboundingbox(e, o, r)) return false;

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
        int leafsize = GETIV(octaentsize), limit = max(r.x, max(r.y, r.z));
        while(leafsize < limit) leafsize *= 2;
        int diff = ~(leafsize-1) & ((o.x^(o.x+r.x))|(o.y^(o.y+r.y))|(o.z^(o.z+r.z)));
        if(diff && (limit > GETIV(octaentsize)/2 || diff < leafsize*2)) leafsize *= 2;
        modifyoctaentity(flags, id, worldroot, ivec(0, 0, 0), GETIV(mapsize)>>1, o, r, leafsize);
    }
    e.inoctanode = flags&MODOE_ADD ? 1 : 0;
    if(e.type == ET_LIGHT) clearlightcache(id);
    else if(e.type == ET_PARTICLES) clearparticleemitters();
    else if(flags&MODOE_ADD) lightent(e);
    return true;
}

void addentity(int id)    { modifyoctaent(MODOE_ADD|MODOE_UPDATEBB, id); } // INTENSITY: Removed 'static' and 'inline'
void removeentity(int id) { modifyoctaent(MODOE_UPDATEBB, id); } // INTENSITY: Removed 'static' and 'inline'

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
    const vector<extentity *> &ents = entities::getents();
    loopv(ents) modifyoctaent(MODOE_ADD, i);
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
        if(c[i].children && size > GETIV(octaentsize)) 
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
    int diff = (bo.x^(bo.x+br.x)) | (bo.y^(bo.y+br.y)) | (bo.z^(bo.z+br.z)) | GETIV(octaentsize),
        scale = GETIV(mapscale)-1;
    if(diff&~((1<<scale)-1) || uint(bo.x|bo.y|bo.z|(bo.x+br.x)|(bo.y+br.y)|(bo.z+br.z)) >= uint(GETIV(mapsize)))
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
    if(c->children && 1<<scale >= GETIV(octaentsize)) findents(c->children, ivec(bo).mask(~((2<<scale)-1)), 1<<scale, bo, br, low, high, notspawned, pos, invradius, found);
}

char *entname(entity &e)
{
    static string fullentname;
    copystring(fullentname, entities::entname(e.type));
    const char *einfo = entities::entnameinfo(e);
    if(*einfo)
    {
        concatstring(fullentname, ": ");
        concatstring(fullentname, einfo);
    }
    return fullentname;
}

extern selinfo sel;
extern bool havesel, selectcorners;
int entlooplevel = 0;
int efocus = -1, enthover = -1, entorient = -1, oldhover = -1;
bool undonext = true;

bool noentedit()
{
    if(!editmode) { conoutf(CON_ERROR, "operation only allowed in edit mode"); return true; }
    return !GETIV(entediting);
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

void attachentity(extentity &e)
{
    switch(e.type)
    {
        case ET_SPOTLIGHT:
            break;

        default:
            if(e.type<ET_GAMESPECIFIC || !entities::mayattach(e)) return;
            break;
    }

    detachentity(e);

    vector<extentity *> &ents = entities::getents();
    int closest = -1;
    float closedist = 1e10f;
    loopv(ents)
    {
        extentity *a = ents[i];
        if(a->attached) continue;
        switch(e.type)
        {
            case ET_SPOTLIGHT: 
                if(a->type!=ET_LIGHT) continue; 
                break;

            default:
                if(e.type<ET_GAMESPECIFIC || !entities::attachent(e, *a)) continue;
                break;
        }
        float dist = e.o.dist(a->o);
        if(dist < closedist)
        {
            closest = i;
            closedist = dist;
        }
    }
    if(closedist>GETIV(attachradius)) return;
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
#define entfocus(i, f)  { int n = efocus = (i); if(n>=0) { extentity &ent = *entities::getents()[n]; f; } }
#define entedit(i, f) \
{ \
    entfocus(i, \
    int oldtype = ent.type; \
    removeentity(n);  \
    f; \
    if(oldtype!=ent.type) detachentity(ent); \
    if(ent.type!=ET_EMPTY) { addentity(n); if(oldtype!=ent.type) attachentity(ent); } \
    entities::editent(n, true)); \
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
        entedit(ue[i].i, (entity &)ent = ue[i].e);
}

void entflip()
{
    if(noentedit()) return;
    int d = dimension(sel.orient);
    float mid = sel.s[d]*sel.grid/2+sel.o[d];
    groupeditundo(ent.o[d] -= (ent.o[d]-mid)*2);
}

void entrotate(int *cw)
{
    if(noentedit()) return;
    int d = dimension(sel.orient);
    int dd = (*cw<0) == dimcoord(sel.orient) ? R[d] : C[d];
    float mid = sel.s[dd]*sel.grid/2+sel.o[dd];
    vec s(sel.o.v);
    groupeditundo(
        ent.o[dd] -= (ent.o[dd]-mid)*2;
        ent.o.sub(s);
        swap(ent.o[R[d]], ent.o[C[d]]);
        ent.o.add(s);
    );
}

void entselectionbox(const entity &e, vec &eo, vec &es) 
{
    extentity* _e = (extentity*)&e; // INTENSITY
    LogicEntityPtr entity = LogicSystem::getLogicEntity(*_e); // INTENSITY

    model *m = NULL;
    const char *mname = entities::entmodel(e);
    if(mname && (m = loadmodel(mname)))
    {   
        m->collisionbox(0, eo, es, entity.get()); // INTENSITY: entity
        if(es.x > es.y) es.y = es.x; else es.x = es.y; // square
        es.z = (es.z + eo.z + 1 + GETIV(entselradius))/2; // enclose ent radius box and model box
        eo.x += e.o.x;
        eo.y += e.o.y;
        eo.z = e.o.z - GETIV(entselradius) + es.z;
    } 
    else if(e.type == ET_MAPMODEL && (m = entity->getModel())) // INTENSITY
    {
        m->collisionbox(0, eo, es, entity.get()); // INTENSITY
        rotatebb(eo, es, e.attr1);
#if 0
        if(m->collide)
            eo.z -= player->aboveeye; // wacky but true. see physics collide                    
        else
            es.div(2);  // cause the usual bb is too big...
#endif
        eo.add(e.o);
    }   
    else
    {
        es = vec(GETIV(entselradius));
        eo = e.o;
    }    
    eo.sub(es);
    es.mul(2);
}

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
        entselectionbox(ent, eo, es);

        editmoveplane(ent.o, ray, d, eo[d] + (dc ? es[d] : 0), handle, v, initentdragging);        

        ivec g(v);
        int z = g[d]&(~(sel.grid-1));
        g.add(sel.grid/2).mask(~(sel.grid-1));
        g[d] = z;
        
        r = (GETIV(entselsnap) ? g[R[d]] : v[R[d]]) - ent.o[R[d]];
        c = (GETIV(entselsnap) ? g[C[d]] : v[C[d]]) - ent.o[C[d]];       
    );

    if(initentdragging) makeundoent();
    groupeditpure(ent.o[R[d]] += r; ent.o[C[d]] += c);
    initentdragging = false;
}

void renderentring(const extentity &e, float radius, int axis)
{
    if(radius <= 0) return;
    glBegin(GL_LINE_LOOP);
    loopi(16)
    {
        vec p(e.o);
        p[axis>=2 ? 1 : 0] += radius*cosf(2*M_PI*i/16.0f);
        p[axis>=1 ? 2 : 1] += radius*sinf(2*M_PI*i/16.0f);
        glVertex3fv(p.v);
    }
    glEnd();
}

void renderentsphere(const extentity &e, float radius)
{
    if(radius <= 0) return;
    loopk(3) renderentring(e, radius, k);
}

void renderentattachment(const extentity &e)
{
    if(!e.attached) return;
    glBegin(GL_LINES);
    glVertex3fv(e.o.v);
    glVertex3fv(e.attached->o.v);
    glEnd();
}

void renderentarrow(const extentity &e, const vec &dir, float radius)
{
    if(radius <= 0) return;
    float arrowsize = min(radius/8, 0.5f);
    vec target = vec(dir).mul(radius).add(e.o), arrowbase = vec(dir).mul(radius - arrowsize).add(e.o), spoke;
    spoke.orthogonal(dir);
    spoke.normalize();
    spoke.mul(arrowsize);
    glBegin(GL_LINES);
    glVertex3fv(e.o.v);
    glVertex3fv(target.v);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glVertex3fv(target.v);
    loopi(5)
    {
        vec p(spoke);
        p.rotate(2*M_PI*i/4.0f, dir);
        p.add(arrowbase);
        glVertex3fv(p.v);
    }
    glEnd();
}

void renderentcone(const extentity &e, const vec &dir, float radius, float angle)
{
    if(radius <= 0) return;
    vec spot = vec(dir).mul(radius*cosf(angle*RAD)).add(e.o), spoke;
    spoke.orthogonal(dir);
    spoke.normalize();
    spoke.mul(radius*sinf(angle*RAD));
    glBegin(GL_LINES);
    loopi(8)
    {
        vec p(spoke);
        p.rotate(2*M_PI*i/8.0f, dir);
        p.add(spot);
        glVertex3fv(e.o.v);
        glVertex3fv(p.v);
    }
    glEnd();
    glBegin(GL_LINE_LOOP);
    loopi(8)
    {
        vec p(spoke);
        p.rotate(2*M_PI*i/8.0f, dir);
        p.add(spot);
        glVertex3fv(p.v);
    }
    glEnd();
}

void renderentradius(extentity &e, bool color)
{
    switch(e.type)
    {
        case ET_LIGHT:
            if(color) glColor3f(e.attr2/255.0f, e.attr3/255.0f, e.attr4/255.0f);
            renderentsphere(e, e.attr1);
            break;

        case ET_SPOTLIGHT:
            if(e.attached)
            {
                if(color) glColor3f(0, 1, 1);
                float radius = e.attached->attr1;
                if(!radius) radius = 2*e.o.dist(e.attached->o);
                vec dir = vec(e.o).sub(e.attached->o).normalize();
                float angle = max(1, min(90, int(e.attr1)));
                renderentattachment(e);
                renderentcone(*e.attached, dir, radius, angle); 
            }
            break;

        case ET_SOUND:
            if(color) glColor3f(0, 1, 1);
            renderentsphere(e, e.attr2);
            break;

        case ET_ENVMAP:
        {
            if(color) glColor3f(0, 1, 1);
            renderentsphere(e, e.attr1 ? max(0, min(10000, int(e.attr1))) : GETIV(envmapradius));
            break;
        }

        case ET_MAPMODEL:
        case ET_PLAYERSTART:
        {
            if(color) glColor3f(0, 1, 1);
            entities::entradius(e, color);
            vec dir;
            vecfromyawpitch(e.attr1, 0, 1, 0, dir);
            renderentarrow(e, dir, 4);
            break;
        }

        default:
            if(e.type>=ET_GAMESPECIFIC) 
            {
                if(color) glColor3f(0, 1, 1);
                entities::entradius(e, color);
            }
            break;
    }
}

void renderentselection(const vec &o, const vec &ray, bool entmoving)
{   
    if(noentedit()) return;
    vec eo, es;

    glColor3ub(0, 40, 0);
    loopv(entgroup) entfocus(entgroup[i],     
        entselectionbox(ent, eo, es);
        boxs3D(eo, es, 1);
    );

    if(enthover >= 0)
    {
        entfocus(enthover, entselectionbox(ent, eo, es)); // also ensures enthover is back in focus
        boxs3D(eo, es, 1);
        if(entmoving && GETIV(entmovingshadow)==1)
        {
            vec a, b;
            glColor3ub(20, 20, 20);
            (a = eo).x = eo.x - fmod(eo.x, GETIV(mapsize)); (b = es).x = a.x + GETIV(mapsize); boxs3D(a, b, 1);  
            (a = eo).y = eo.y - fmod(eo.y, GETIV(mapsize)); (b = es).y = a.x + GETIV(mapsize); boxs3D(a, b, 1);  
            (a = eo).z = eo.z - fmod(eo.z, GETIV(mapsize)); (b = es).z = a.x + GETIV(mapsize); boxs3D(a, b, 1);
        }
        glColor3ub(150,0,0);
        glLineWidth(5);
        boxs(entorient, eo, es);
        glLineWidth(1);
    }

    if(GETIV(showentradius) && (entgroup.length() || enthover >= 0))
    {
        glDepthFunc(GL_GREATER);
        glColor3f(0.25f, 0.25f, 0.25f);
        loopv(entgroup) entfocus(entgroup[i], renderentradius(ent, false));
        if(enthover>=0) entfocus(enthover, renderentradius(ent, false));
        glDepthFunc(GL_LESS);
        loopv(entgroup) entfocus(entgroup[i], renderentradius(ent, true));
        if(enthover>=0) entfocus(enthover, renderentradius(ent, true));
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

void entpush(int *dir)
{
    if(noentedit()) return;
    int d = dimension(entorient);
    int s = dimcoord(entorient) ? -*dir : *dir;
    if(GETIV(entmoving)) 
    {
        groupeditpure(ent.o[d] += float(s*sel.grid)); // editdrag supplies the undo
    }
    else 
        groupedit(ent.o[d] += float(s*sel.grid));
    if(GETIV(entitysurf)==1)
    {
        player->o[d] += float(s*sel.grid);
        player->resetinterp();
    }
}

void entautoview(int *dir) 
{
    if(!haveselent()) return;
    static int s = 0;
    vec v(player->o);
    v.sub(worldpos);
    v.normalize();
    v.mul(GETIV(entautoviewdist));
    int t = s + *dir;
    s = abs(t) % entgroup.length();
    if(t<0 && s>0) s = entgroup.length() - s;
    entfocus(entgroup[s],
        v.add(ent.o);
        player->o = v;
        player->resetinterp();
    );
}

void delent()
{
#if 0 // INTENSITY - use our own deleting
    if(noentedit()) return;
    groupedit(ent.type = ET_EMPTY;);
    entcancel();
#else
    if(noentedit()) return;

    loopv(entgroup) entfocus(
        entgroup[i],
        MessageSystem::send_RequestLogicEntityRemoval(ent.uniqueId)
    );

    entcancel();
#endif
}

int findtype(char *what)
{
    for(int i = 0; *entities::entname(i); i++) if(strcmp(what, entities::entname(i))==0) return i;
    conoutf(CON_ERROR, "unknown entity type \"%s\"", what);
    return ET_EMPTY;
}

bool dropentity(entity &e, int drop = -1)
{
    vec radius(4.0f, 4.0f, 4.0f);
    if(drop<0) drop = GETIV(entdrop);
    if(e.type == ET_MAPMODEL)
    {
        extentity& ext = *((extentity*)&e); // INTENSITY
        LogicEntityPtr entity = LogicSystem::getLogicEntity(ext); // INTENSITY
        model *m = entity.get() ? entity->getModel() : NULL; // INTENSITY
        if(m)
        {
            vec center;
            m->boundbox(0, center, radius, entity.get()); // INTENSITY: entity
            rotatebb(center, radius, e.attr1);
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
    groupedit(dropentity(ent));
}

void attachent()
{
    if(noentedit()) return;
    groupedit(attachentity(ent));
}

extentity *newentity(bool local, const vec &o, int type, int v1, int v2, int v3, int v4, int v5)
{
    extentity &e = *entities::newentity();
    e.o = o;
    e.attr1 = v1;
    e.attr2 = v2;
    e.attr3 = v3;
    e.attr4 = v4;
    e.attr5 = v5;
    e.type = type;
    e.reserved = 0;
    e.spawned = false;
    e.inoctanode = false;
    e.light.color = vec(1, 1, 1);
    e.light.dir = vec(0, 0, 1);
    if(local)
    {
        switch(type)
        {
                case ET_MAPMODEL:
                case ET_PLAYERSTART:
                    e.attr5 = e.attr4;
                    e.attr4 = e.attr3;
                    e.attr3 = e.attr2;
                    e.attr2 = e.attr1;
                    e.attr1 = (int)camera1->yaw;
                    break;
        }
        entities::fixentity(e);
    }
    return &e;
}

void newentity(int type, int a1, int a2, int a3, int a4, int a5)
{
    if(entities::getents().length() >= MAXENTS) { conoutf("too many entities"); return; }
    extentity *t = newentity(true, player->o, type, a1, a2, a3, a4, a5);
    dropentity(*t);
    entities::getents().add(t);
    int i = entities::getents().length()-1;
    t->type = ET_EMPTY;
    enttoggle(i);
    makeundoent();
    entedit(i, ent.type = type);
}

void newent(char *what, int *a1, int *a2, int *a3, int *a4, int *a5)
{
    if(noentedit()) return;
#if 0 // INTENSITY: /newent leads to sending a request to the server, in the new system
    int type = findtype(what);
    if(type != ET_EMPTY)
        newentity(type, *a1, *a2, *a3, *a4, *a5);
#else
    std::string stateData = "{";
    stateData += " 'attr1': '" + Utility::toString(*a1) + "', ";
    stateData += " 'attr2': '" + Utility::toString(*a2) + "', ";
    stateData += " 'attr3': '" + Utility::toString(*a3) + "', ";
    stateData += " 'attr4': '" + Utility::toString(*a4) + "' ";
    stateData += "}";

    EditingSystem::newEntity(what, stateData);
#endif
}

int entcopygrid;
vector<extentity> entcopybuf; // INTENSITY: extentity, for uniqueID

void entcopy()
{
    if(noentedit()) return;
    entcopygrid = sel.grid;
    entcopybuf.shrink(0);
    loopv(entgroup) 
        entfocus(entgroup[i], entcopybuf.add(ent).o.sub(sel.o.tovec()));
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
        LogicEntityPtr entity = LogicSystem::getLogicEntity(c);
        std::string _class = entity->getClass();

        using namespace lua;
        engine.getref(entity->luaRef).t_getraw("create_statedatadict");
        engine.push_index(-2).call(1, 1);
        engine.push("__ccentcopy__TEMP").shift();
        engine.setg().pop(1);

        defformatstring(s)("__ccentcopy__TEMP.position = '[%f|%f|%f]'", o.x, o.y, o.z);
        engine.exec(s);

        engine.getg("cc").t_getraw("json").t_getraw("encode");
        engine.getg("__ccentcopy__TEMP").call(1, 1);
        std::string stateData = engine.get(-1, "{}");
        engine.pop(3);

        EditingSystem::newEntity(_class, stateData);
        // INTENSITY: end Create entity using new system

// INTENSITY       extentity *e = newentity(true, o, ET_EMPTY, c.attr1, c.attr2, c.attr3, c.attr4, c.attr5);
// INTENSITY       entities::getents().add(e);
// INTENSITY       entadd(++last);
    }
// INTENSITY   int j = 0;
// INTENSITY   groupeditundo(e.type = entcopybuf[j++].type;);
}

void entset(char *what, int *a1, int *a2, int *a3, int *a4, int *a5)
{
    if(noentedit()) return;
    int type = findtype(what);
    groupedit(ent.type=type;
              ent.attr1=*a1;
              ent.attr2=*a2;
              ent.attr3=*a3;
              ent.attr4=*a4;
              ent.attr5=*a5);
}

void printent(extentity &e, char *buf)
{
    switch(e.type)
    {
        case ET_PARTICLES:
            if(printparticles(e, buf)) return; 
            break;
 
        default:
            if(e.type >= ET_GAMESPECIFIC && entities::printent(e, buf)) return;
            break;
    }
    formatstring(buf)("%s %d %d %d %d %d", entities::entname(e.type), e.attr1, e.attr2, e.attr3, e.attr4, e.attr5);
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

std::string intensityCopiedClass = "", intensityCopiedStateData = ""; // INTENSITY: Save these here safely,
                                                                      // not in a cubescript var that could be
                                                                      // injection attacked
void intensityentcopy() // INTENSITY
{
    if (efocus < 0)
    {
        intensityCopiedClass = "";
        intensityCopiedStateData = "";
        return;
    }

    extentity& e = *(entities::getents()[efocus]);
    LogicEntityPtr entity = LogicSystem::getLogicEntity(e);
    intensityCopiedClass = entity->getClass();

    using namespace lua;
    engine.getref(entity->luaRef).t_getraw("create_statedatadict");
    engine.push_index(-2).call(1, 1);
    engine.push("__ccentcopy__TEMP").shift().setg();
    engine.pop(1);

    engine.exec("__ccentcopy__TEMP.position = nil"); // Position is determined at paste time

    engine.getg("cc").t_getraw("json").t_getraw("encode");
    engine.getg("__ccentcopy__TEMP").call(1, 1);
    intensityCopiedStateData = engine.get(-1, "{}");
    engine.pop(3);

    engine.exec("__ccentcopy__TEMP = nil");
}

void intensitypasteent() // INTENSITY
{
    EditingSystem::newEntity(intensityCopiedClass, intensityCopiedStateData);
}

int findentity(int type, int index, int attr1, int attr2)
{
    const vector<extentity *> &ents = entities::getents();
    for(int i = index; i<ents.length(); i++) 
    {
        extentity &e = *ents[i];
        if(e.type==type && (attr1<0 || e.attr1==attr1) && (attr2<0 || e.attr2==attr2))
            return i;
    }
    loopj(min(index, ents.length())) 
    {
        extentity &e = *ents[j];
        if(e.type==type && (attr1<0 || e.attr1==attr1) && (attr2<0 || e.attr2==attr2))
            return j;
    }
    return -1;
}

int spawncycle = -1;

void findplayerspawn(dynent *d, int forceent, int tag)   // place at random spawn. also used by monsters!
{
    int pick = forceent;
    if(pick<0)
    {
        int r = rnd(10)+1;
        loopi(r) spawncycle = findentity(ET_PLAYERSTART, spawncycle+1, -1, tag);
        pick = spawncycle;
    }
    if(pick!=-1)
    {
        d->pitch = 0;
        d->roll = 0;
        for(int attempt = pick;;)
        {
            d->o = entities::getents()[attempt]->o;
            d->yaw = entities::getents()[attempt]->attr1;
            if(entinmap(d, true)) break;
            attempt = findentity(ET_PLAYERSTART, attempt+1, -1, tag);
            if(attempt<0 || attempt==pick)
            {
                d->o = entities::getents()[attempt]->o;
                d->yaw = entities::getents()[attempt]->attr1;
                entinmap(d);
                break;
            }    
        }
    }
    else
    {
        d->o.x = d->o.y = d->o.z = 0.5f*GETIV(mapsize);
        d->o.z += 1;
        entinmap(d);
    }
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
    var::clear();
    clearmapsounds();
    cleanreflections();
    resetblendmap();
    resetlightmaps();
    clearpvs();
    clearslots();
    clearparticles();
    cleardecals();
    cancelsel();
    pruneundos();

    SETV(gamespeed, 100);
    SETV(paused, 0);

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

    SETVFN(mapscale, scale<10 ? 10 : (scale>16 ? 16 : scale));
    SETVFN(mapsize, 1<<GETIV(mapscale));
    
    texmru.shrink(0);
    freeocta(worldroot);
    worldroot = newcubes(F_EMPTY);
    loopi(4) solidfaces(worldroot[i]);

    if(GETIV(mapsize) > 0x1000) splitocta(worldroot, GETIV(mapsize)>>1);

    clearmainmenu();

    if (usecfg)
    {
        var::overridevars = true;
        lua::engine.execf("data/cfg/default_map_settings.lua", false);
        var::overridevars = false;
    }

    clearlights();
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
    if(GETIV(mapsize) >= 1<<16) return false;

    while(outsideents.length()) removeentity(outsideents.pop());

    SETVN(mapscale, GETIV(mapscale) + 1);
    SETVN(mapsize, GETIV(mapsize) * 2);
    cube *c = newcubes(F_EMPTY);
    c[0].children = worldroot;
    loopi(3) solidfaces(c[i+1]);
    worldroot = c;

    if(GETIV(mapsize) > 0x1000) splitocta(worldroot, GETIV(mapsize)>>1);

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
    if(noedit(true) || (GETIV(nompedit) && multiplayer())) return;
    if(GETIV(mapsize) <= 1<<10) return;

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
    SETVN(mapscale, GETIV(mapscale) - 1);
    SETVN(mapsize, GETIV(mapsize) / 2);

    ivec offset(octant, 0, 0, 0, GETIV(mapsize));
    vector<extentity *> &ents = entities::getents();
    loopv(ents) ents[i]->o.sub(offset.tovec());

    shrinkblendmap(octant);
 
    allchanged();

    conoutf("shrunk map to size %d", GETIV(mapscale));
}

void newmap(int *i) { bool force = !isconnected() && !haslocalclients(); if(force) game::forceedit(""); if(emptymap(*i, force, NULL)) game::newmap(max(*i, 0)); }
void mapenlarge() { if(enlargemap(false)) game::newmap(-1); }

void mpeditent(int i, const vec &o, int type, int attr1, int attr2, int attr3, int attr4, int attr5, bool local)
{
    if(i < 0 || i >= MAXENTS) return;
    if(entities::getents().length()<=i)
    {
        while(entities::getents().length()<i) entities::getents().add(entities::newentity())->type = ET_EMPTY;
        extentity *e = newentity(local, o, type, attr1, attr2, attr3, attr4, attr5);
        entities::getents().add(e);
        addentity(i);
        attachentity(*e);
    }
    else
    {
        extentity &e = *entities::getents()[i];
        removeentity(i);
        int oldtype = e.type;
        if(oldtype!=type) detachentity(e);
        e.type = type;
        e.o = o;
        e.attr1 = attr1; e.attr2 = attr2; e.attr3 = attr3; e.attr4 = attr4; e.attr5 = attr5;
        addentity(i);
        if(oldtype!=type) attachentity(e);
        entities::editent(i, local);
    }
}

int getworldsize() { return GETIV(mapsize); }
int getmapversion() { return GETIV(mapversion); }
