#include "engine.h"

VARP(oqdynent, 0, 1, 1);
VARP(animationinterpolationtime, 0, 150, 1000);

model *loadingmodel = NULL;

#include "ragdoll.h"
#include "animmodel.h"
#include "vertmodel.h"
#include "skelmodel.h"
#include "hitzone.h"

#include "of_tools.h"

static model *(__cdecl *modeltypes[NUMMODELTYPES])(const char *);

static int addmodeltype(int type, model *(__cdecl *loader)(const char *))
{
    modeltypes[type] = loader;
    return type;
}

#define MODELTYPE(modeltype, modelclass) \
static model *__loadmodel__##modelclass(const char *filename) \
{ \
    return new modelclass(filename); \
} \
static int __dummy__##modelclass = addmodeltype((modeltype), __loadmodel__##modelclass);

#include "md3.h"
#include "md5.h"
#include "obj.h"
#include "smd.h"
#include "iqm.h"

MODELTYPE(MDL_MD3, md3);
MODELTYPE(MDL_MD5, md5);
MODELTYPE(MDL_OBJ, obj);
MODELTYPE(MDL_SMD, smd);
MODELTYPE(MDL_IQM, iqm);

#define checkmdl if(!loadingmodel) { conoutf(CON_ERROR, "not loading a model"); return; }

void mdlcullface(bool cullface)
{
    checkmdl;
    loadingmodel->setcullface(cullface);
}

void mdlcollide(bool collide)
{
    checkmdl;
    loadingmodel->collide = collide;
}

void mdlellipsecollide(bool collide)
{
    checkmdl;
    loadingmodel->ellipsecollide = collide;
}   
    
void mdlspec(int percent)
{
    checkmdl;
    float spec = 1.0f; 
    if(percent>0) spec = percent/100.0f;
    else if(percent<0) spec = 0.0f;
    loadingmodel->setspec(spec);
}

void mdlambient(int percent)
{
    checkmdl;
    float ambient = 0.3f;
    if(percent>0) ambient = percent/100.0f;
    else if(percent<0) ambient = 0.0f;
    loadingmodel->setambient(ambient);
}

void mdlalphatest(float cutoff)
{   
    checkmdl;
    loadingmodel->setalphatest(max(0.0f, min(1.0f, cutoff)));
}

void mdlalphablend(bool blend)
{   
    checkmdl;
    loadingmodel->setalphablend(blend);
}

void mdlalphadepth(bool depth)
{
    checkmdl;
    loadingmodel->alphadepth = depth;
}

void mdldepthoffset(bool offset)
{
    checkmdl;
    loadingmodel->depthoffset = offset;
}

void mdlglow(int percent, int delta, float pulse)
{
    checkmdl;
    float glow = 3.0f, glowdelta = delta/100.0f, glowpulse = pulse > 0 ? pulse/1000.0f : 0;
    if(percent>0) glow = percent/100.0f;
    else if(percent<0) glow = 0.0f;
    glowdelta -= glow;
    loadingmodel->setglow(glow, glowdelta, glowpulse);
}

void mdlglare(float specglare, float glowglare)
{
    checkmdl;
    loadingmodel->setglare(specglare, glowglare);
}

void mdlenvmap(float envmapmax, float envmapmin, char *envmap)
{
    checkmdl;
    loadingmodel->setenvmap(envmapmin, envmapmax, envmap ? cubemapload(envmap) : NULL);
}

void mdlfullbright(float fullbright)
{
    checkmdl;
    loadingmodel->setfullbright(fullbright);
}

void mdlshader(char *shader)
{
    if (!shader) return;
    checkmdl;
    loadingmodel->setshader(lookupshaderbyname(shader));
}

void mdlspin(float yaw, float pitch)
{
    checkmdl;
    loadingmodel->spinyaw = yaw;
    loadingmodel->spinpitch = pitch;
}

void mdlscale(int percent)
{
    checkmdl;
    float scale = 0.3f;
    if(percent>0) scale = percent/100.0f;
    else if(percent<0) scale = 0.0f;
    loadingmodel->scale = scale;
}  

void mdltrans(const vec& v)
{
    checkmdl;
    loadingmodel->translate = v;
} 

void mdlyaw(float angle)
{
    checkmdl;
    loadingmodel->offsetyaw = angle;
}

void mdlpitch(float angle)
{
    checkmdl;
    loadingmodel->offsetpitch = angle;
}

void mdlshadow(bool shadow)
{
    checkmdl;
    loadingmodel->shadow = shadow;
}

void mdlbb(float rad, float h, float eyeheight)
{
    checkmdl;
    loadingmodel->collideradius = rad;
    loadingmodel->collideheight = h;
    loadingmodel->eyeheight = eyeheight; 
}

void mdlextendbb(const vec& extend)
{
    checkmdl;
    loadingmodel->bbextend = extend;
}

const char *mdlname()
{
    if (!loadingmodel)
    {
        conoutf(CON_ERROR, "not loading a model");
        return NULL;
    }
    return loadingmodel->name();
}

#define checkragdoll \
    if(!loadingmodel->skeletal()) { conoutf(CON_ERROR, "not loading a skeletal model"); return; } \
    skelmodel *m = (skelmodel *)loadingmodel; \
    skelmodel::skelmeshgroup *meshes = (skelmodel::skelmeshgroup *)m->parts.last()->meshes; \
    if(!meshes) return; \
    skelmodel::skeleton *skel = meshes->skel; \
    if(!skel->ragdoll) skel->ragdoll = new ragdollskel; \
    ragdollskel *ragdoll = skel->ragdoll; \
    if(ragdoll->loaded) return;
    

void rdvert(const vec& o, float radius)
{
    checkragdoll;
    ragdollskel::vert &v = ragdoll->verts.add();
    v.pos = o;
    v.radius = radius > 0 ? radius : 1;
}

void rdeye(int v)
{
    checkragdoll;
    ragdoll->eye = v;
}

void rdtri(int v1, int v2, int v3)
{
    checkragdoll;
    ragdollskel::tri &t = ragdoll->tris.add();
    t.vert[0] = v1;
    t.vert[1] = v2;
    t.vert[2] = v3;
}

void rdjoint(int n, int t, int v1, int v2, int v3)
{
    checkragdoll;
    if(n < 0 || n >= skel->numbones) return;
    ragdollskel::joint &j = ragdoll->joints.add();
    j.bone = n;
    j.tri = t;
    j.vert[0] = v1;
    j.vert[1] = v2;
    j.vert[2] = v3;
}
   
void rdlimitdist(int v1, int v2, float mindist, float maxdist)
{
    checkragdoll;
    ragdollskel::distlimit &d = ragdoll->distlimits.add();
    d.vert[0] = v1;
    d.vert[1] = v2;
    d.mindist = mindist;
    d.maxdist = max(maxdist, mindist);
}

void rdlimitrot(int t1, int t2, float maxangle, float qx, float qy, float qz, float qw)
{
    checkragdoll;
    ragdollskel::rotlimit &r = ragdoll->rotlimits.add();
    r.tri[0] = t1;
    r.tri[1] = t2;
    r.maxangle = maxangle * RAD;
    r.middle = matrix3x3(quat(qx, qy, qz, qw));
}

void rdanimjoints(bool on)
{
    checkragdoll;
    ragdoll->animjoints = on;
}

// mapmodels

vector<mapmodelinfo> mapmodels;

void mmodel(char *name)
{
    mapmodelinfo &mmi = mapmodels.add();
    copystring(mmi.name, name);
    mmi.m = NULL;
}

void mapmodelcompat(int rad, int h, int tex, char *name, char *shadow)
{
    mmodel(name);
}

void mapmodelreset(int n) 
{ 
    if(!varsys::overridevars && !game::allowedittoggle()) return;
    mapmodels.shrink(clamp(n, 0, mapmodels.length())); 
}

mapmodelinfo *getmminfo(int i) { return /*mapmodels.inrange(i) ? &mapmodels[i] :*/ NULL; } // INTENSITY
const char *mapmodelname(int i) { return /*mapmodels.inrange(i) ? mapmodels[i].name :*/ NULL; } // INTENSITY

// model registry

hashtable<const char *, model *> mdllookup;
vector<const char *> preloadmodels;

void preloadmodel(const char *name)
{
    if(!name || !name[0] || mdllookup.access(name)) return;
    preloadmodels.add(newstring(name));
}

void flushpreloadedmodels(bool msg)
{
    loopv(preloadmodels)
    {
        loadprogress = float(i+1)/preloadmodels.length();
        model *m = loadmodel(preloadmodels[i], -1, msg);
        if(!m) { if(msg) conoutf(CON_WARN, "could not load model: %s", preloadmodels[i]); }
        else
        {
            m->preloadmeshes();
            m->preloadshaders();
        }
    }
    preloadmodels.deletearrays();
    loadprogress = 0;
}

model *loadmodel(const char *name, int i, bool msg)
{
    if(!name)
    {
        if(!mapmodels.inrange(i)) return NULL;
        mapmodelinfo &mmi = mapmodels[i];
        if(mmi.m) return mmi.m;
        name = mmi.name;
    }
    model **mm = mdllookup.access(name);
    model *m;
    if(mm) m = *mm;
    else
    {
        if(!name[0] || loadingmodel) return NULL;
        if(msg)
        {
            defformatstring(filename)("data/models/%s", name);
            renderprogress(loadprogress, filename);
        }
        loopi(NUMMODELTYPES)
        {
            m = modeltypes[i](name);
            if(!m) continue;
            loadingmodel = m;
            if(m->load()) break;
            DELETEP(m);
        }
        loadingmodel = NULL;
        if(!m) return NULL;
        mdllookup.access(m->name(), m);
    }
    if(mapmodels.inrange(i) && !mapmodels[i].m) mapmodels[i].m = m;
    return m;
}

void clear_mdls()
{
    enumerate(mdllookup, model *, m, delete m);
}

void cleanupmodels()
{
    enumerate(mdllookup, model *, m, m->cleanup());
}

void clearmodel(char *name)
{
    if (!name) return;
    model **m = mdllookup.access(name);
    if(!m) { conoutf("model %s is not loaded", name); return; }
    loopv(mapmodels) if(mapmodels[i].m==*m) mapmodels[i].m = NULL;
    mdllookup.remove(name);
    (*m)->cleanup();
    delete *m;
    conoutf("cleared model %s", name);
}

bool modeloccluded(const vec &center, float radius)
{
#ifdef CLIENT
    int br = int(radius*2)+1;
    return pvsoccluded(ivec(int(center.x-radius), int(center.y-radius), int(center.z-radius)), ivec(br, br, br)) ||
           bboccluded(ivec(int(center.x-radius), int(center.y-radius), int(center.z-radius)), ivec(br, br, br));
#else
    return false;
#endif
}

struct batchedmodel
{
    vec pos, center;
    float radius, yaw, pitch, sizescale;
    int anim, basetime, basetime2, flags, visible, attached;
    dynent *d;
    occludequery *query;
    int next;
};  
struct modelbatch
{
    model *m;
    int flags, batched;
};  
static vector<batchedmodel> batchedmodels;
static vector<modelbatch> batches;
static vector<modelattach> modelattached;
static occludequery *modelquery = NULL;

void resetmodelbatches()
{
    batchedmodels.setsize(0);
    batches.setsize(0);
    modelattached.setsize(0);
}

void addbatchedmodel(model *m, batchedmodel &bm, int idx)
{
    modelbatch *b = NULL;
    if(batches.inrange(m->batch) && batches[m->batch].m == m) b = &batches[m->batch];
    else
    {
        m->batch = batches.length();
        b = &batches.add();
        b->m = m;
        b->flags = 0;
        b->batched = -1;
    }
    b->flags |= bm.flags;
    bm.next = b->batched;
    b->batched = idx;
}

static inline void renderbatchedmodel(model *m, batchedmodel &b)
{
    modelattach *a = NULL;
    if(b.attached>=0) a = &modelattached[b.attached];

    int anim = b.anim;
    if(shadowmapping > SM_REFLECT) anim |= ANIM_NOSKIN;
    else
    {
        if(b.flags&MDL_FULLBRIGHT) anim |= ANIM_FULLBRIGHT;
    }

    m->render(anim, b.basetime, b.basetime2, b.pos, b.yaw, b.pitch, b.d, a, b.sizescale);
}

VARP(maxmodelradiusdistance, 10, 200, 1000);

static inline void rendermodelquery(model *m, dynent *d, const vec &center, float radius)
{
    if(fabs(camera1->o.x-center.x) < radius+1 &&
       fabs(camera1->o.y-center.y) < radius+1 &&
       fabs(camera1->o.z-center.z) < radius+1)
    {
        d->query = NULL;
        return;
    }
    d->query = newquery(d);
    if(!d->query) return;
    nocolorshader->set();
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    glDepthMask(GL_FALSE);
    startquery(d->query);
    int br = int(radius*2)+1;
    drawbb(ivec(int(center.x-radius), int(center.y-radius), int(center.z-radius)), ivec(br, br, br));
    endquery(d->query);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask(GL_TRUE);
}

static inline bool cullmodel(model *m, const vec &center, float radius, int flags, dynent *d = NULL)
{
    if(flags&MDL_CULL_DIST && center.dist(camera1->o)/radius>maxmodelradiusdistance) return true;
    if(flags&MDL_CULL_VFC && isfoggedsphere(radius, center)) return true;
    if(flags&MDL_CULL_OCCLUDED && modeloccluded(center, radius))
    {
        if(d)
        {
            d->occluded = OCCLUDE_PARENT;
            if(flags&MDL_CULL_QUERY) rendermodelquery(m, d, center, radius);
        }
        return true;
    }
    else if(flags&MDL_CULL_QUERY && d->query && d->query->owner==d && checkquery(d->query))
    {
        if(d->occluded<OCCLUDE_BB) d->occluded++;
        rendermodelquery(m, d, center, radius);
        return true;
    }
    return false;
}

static inline int shadowmaskmodel(const vec &center, float radius)
{
    switch(shadowmapping)
    {
        case SM_REFLECT:
            return calcspherersmsplits(center, radius);
        case SM_TETRA:
        {
            vec scenter = vec(center).sub(shadoworigin);
            float sradius = radius + shadowradius;
            if(scenter.squaredlen() >= sradius*sradius) return 0;
            return calcspheretetramask(scenter, radius, shadowbias*shadowradius);
        }
        case SM_CUBEMAP:
        {
            vec scenter = vec(center).sub(shadoworigin);
            float sradius = radius + shadowradius;
            if(scenter.squaredlen() >= sradius*sradius) return 0;
            return calcspheresidemask(scenter, radius, shadowbias);
        }
        case SM_CASCADE:
            return calcspherecsmsplits(center, radius);
        case SM_SPOT:
        {
            vec scenter = vec(center).sub(shadoworigin);
            float sradius = radius + shadowradius;
            return scenter.squaredlen() < sradius*sradius && sphereinsidespot(shadowdir, shadowspot, scenter, radius) ? 1 : 0;
        }
    }
    return 0;
}

void shadowmaskbatchedmodels(bool dynshadow)
{
    loopv(batchedmodels) 
    {
        batchedmodel &b = batchedmodels[i];
        if(b.flags&MDL_MAPMODEL) break;
        b.visible = dynshadow ? shadowmaskmodel(b.center, b.radius) : 0;
    }
}

int batcheddynamicmodels()
{
    int visible = 0;
    loopv(batchedmodels)
    {
        batchedmodel &b = batchedmodels[i];
        if(b.flags&MDL_MAPMODEL) break;
        visible |= b.visible;
    }
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(!(b.flags&MDL_MAPMODEL) || b.batched < 0 || !b.m->animated()) continue;
        for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            visible |= bm.visible;
        }
    }
    return visible;
}

int batcheddynamicmodelbounds(int mask, vec &bbmin, vec &bbmax)
{
    int vis = 0;
    loopv(batchedmodels)
    {
        batchedmodel &b = batchedmodels[i];
        if(b.flags&MDL_MAPMODEL) break;
        if(b.visible&mask)
        {
            bbmin.min(vec(b.center).sub(b.radius)); 
            bbmax.max(vec(b.center).add(b.radius));
            ++vis;
        }
    }
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(!(b.flags&MDL_MAPMODEL) || b.batched < 0 || !b.m->animated()) continue;
        for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            if(bm.visible&mask)
            {
                bbmin.min(vec(bm.center).sub(bm.radius)); 
                bbmax.max(vec(bm.center).add(bm.radius));
                ++vis;
            }
        }
    }
    return vis;
}

void rendermodelbatches()
{
    float aamask = -1;
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(b.batched < 0) continue;
        bool rendered = false;
        occludequery *query = NULL;
        if(shadowmapping) for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            if(!(bm.visible&(1<<shadowside))) continue;
            if(!rendered) { b.m->startrender(); rendered = true; }
            renderbatchedmodel(b.m, bm);
        }
        else if(b.flags&MDL_MAPMODEL) for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            if(bm.query!=query)
            {
                if(query) endquery(query);
                query = bm.query;
                if(query) startquery(query);
            }
            if(!rendered) 
            { 
                b.m->startrender(); 
                rendered = true; 
                if(b.m->animated()) 
                { 
                    if(aamask!=1) GLOBALPARAM(aamask, (aamask = 1)); 
                } 
                else if(aamask!=0) GLOBALPARAM(aamask, (aamask = 0));
            }
            renderbatchedmodel(b.m, bm);
        }
        else for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            if(cullmodel(b.m, bm.center, bm.radius, bm.flags, bm.d)) continue;
            if(!rendered) 
            { 
                b.m->startrender(); 
                rendered = true; 
                if(aamask!=1) GLOBALPARAM(aamask, (aamask = 1)); 
            }
            if(bm.flags&MDL_CULL_QUERY) 
            {
                bm.d->query = newquery(bm.d);
                if(bm.d->query) 
                {
                    startquery(bm.d->query);
                    renderbatchedmodel(b.m, bm);
                    endquery(bm.d->query);
                    continue;
                }
            }
            renderbatchedmodel(b.m, bm);
        }
        if(query) endquery(query);
        if(rendered) b.m->endrender();
    }
}

void startmodelquery(occludequery *query)
{
    modelquery = query;
}

void endmodelquery()
{
    int querybatches = 0;
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(b.batched < 0 || batchedmodels[b.batched].query != modelquery) continue;
        querybatches++;
    }
    if(querybatches<=1)
    {
        if(!querybatches) modelquery->fragments = 0;
        modelquery = NULL;
        return;
    }
    int minattached = modelattached.length();
    startquery(modelquery);
    float aamask = -1;
    loopv(batches)
    {
        modelbatch &b = batches[i];
        int j = b.batched;
        if(j < 0 || batchedmodels[j].query != modelquery) continue;
        b.m->startrender();
        if(b.m->animated())
        {
            if(aamask!=1) GLOBALPARAM(aamask, (aamask = 1));
        }
        else if(aamask!=0) GLOBALPARAM(aamask, (aamask = 0));
        do
        {
            batchedmodel &bm = batchedmodels[j];
            if(bm.query != modelquery) break;
            j = bm.next;
            if(bm.attached>=0) minattached = min(minattached, bm.attached);
            renderbatchedmodel(b.m, bm);
        }
        while(j >= 0);
        b.batched = j;
        b.m->endrender();
    }
    endquery(modelquery);
    modelquery = NULL;
    modelattached.setsize(minattached);
}

void clearbatchedmapmodels()
{
    if(batchedmodels.empty()) return;
    int len = 0;
    loopvrev(batchedmodels) if(!(batchedmodels[i].flags&MDL_MAPMODEL))
    {
        len = i+1;
        break;
    } 
    if(len >= batchedmodels.length()) return;
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(b.batched < 0) continue;
        int j = b.batched;
        while(j >= len) j = batchedmodels[j].next;
        b.batched = j;
    }
    batchedmodels.setsize(len);
}

void rendermapmodel(CLogicEntity *e, int anim, const vec &o, float yaw, float pitch, int flags, int basetime, float size)
{
    if(!e) return;
    model *m = e->getModel();

    vec center, bbradius;
    m->boundbox(center, bbradius);
    float radius = bbradius.magnitude();
    center.mul(size);
    center.rotate_around_z(yaw*RAD);
    center.add(o);
    radius *= size;

    int visible = 0;
    if(shadowmapping) 
    {
        visible = shadowmaskmodel(center, radius);
        if(!visible) return;
    }
    else if(flags&(MDL_CULL_VFC|MDL_CULL_DIST|MDL_CULL_OCCLUDED) && cullmodel(m, center, radius, flags))
        return;

    batchedmodel &b = batchedmodels.add();
    b.query = modelquery;
    b.pos = o;
    b.center = center;
    b.radius = radius;
    b.anim = anim;
    b.yaw = yaw;
    b.pitch = pitch;
    b.basetime = basetime;
    b.basetime2 = 0;
    b.sizescale = size;
    b.flags = flags | MDL_MAPMODEL;
    b.visible = visible;
    b.d = NULL;
    b.attached = -1;
    addbatchedmodel(m, b, batchedmodels.length()-1);
}

void rendermodel(const char *mdl, int anim, const vec &o, float yaw, float pitch, int flags, dynent *d, modelattach *a, int basetime, int basetime2, float size)
{
    model *m = loadmodel(mdl); 
    if(!m) return;

    vec center, bbradius;
    m->boundbox(center, bbradius);
    float radius = bbradius.magnitude();
    if(d && d->ragdoll)
    {
        radius = max(radius, d->ragdoll->radius);
        center = d->ragdoll->center;
    }
    else
    {
        center.mul(size);
        center.rotate_around_z(yaw*RAD);
        center.add(o);
    }
    radius *= size;

    if(flags&MDL_NORENDER) anim |= ANIM_NORENDER;

    if(a) for(int i = 0; a[i].tag; i++)
    {
        if(a[i].name) a[i].m = loadmodel(a[i].name);
        //if(a[i].m && a[i].m->type()!=m->type()) a[i].m = NULL;
    }

    if(flags&MDL_CULL_QUERY)
    {
        if(!hasOQ || !oqfrags || !oqdynent || !d) flags &= ~MDL_CULL_QUERY;
    }

    if(flags&MDL_NOBATCH)
    {
        if(cullmodel(m, center, radius, flags, d)) return;
        if(flags&MDL_CULL_QUERY) 
        {
            d->query = newquery(d);
            if(d->query) startquery(d->query);
        }
        m->startrender();
        GLOBALPARAM(aamask, (1.0f));
        if(flags&MDL_FULLBRIGHT) anim |= ANIM_FULLBRIGHT;
        m->render(anim, basetime, basetime2, o, yaw, pitch, d, a, size);
        m->endrender();
        if(flags&MDL_CULL_QUERY && d->query) endquery(d->query);
        return;
    }

    batchedmodel &b = batchedmodels.add();
    b.query = modelquery;
    b.pos = o;
    b.center = center;
    b.radius = radius;
    b.anim = anim;
    b.yaw = yaw;
    b.pitch = pitch;
    b.basetime = basetime;
    b.basetime2 = basetime2;
    b.sizescale = size;
    b.flags = flags;
    b.d = d;
    b.attached = a ? modelattached.length() : -1;
    if(a) for(int i = 0;; i++) { modelattached.add(a[i]); if(!a[i].tag) break; }
    addbatchedmodel(m, b, batchedmodels.length()-1);
}

int intersectmodel(const char *mdl, int anim, const vec &pos, float yaw, float pitch, const vec &o, const vec &ray, float &dist, int mode, dynent *d, modelattach *a, int basetime, int basetime2, float size)
{
    model *m = loadmodel(mdl);
    if(!m) return -1;
    if(a) for(int i = 0; a[i].tag; i++)
    {
        if(a[i].name) a[i].m = loadmodel(a[i].name);
    }
    return m->intersect(anim, basetime, basetime2, pos, yaw, pitch, d, a, size, o, ray, dist, mode);
}

void abovemodel(vec &o, const char *mdl)
{
    model *m = loadmodel(mdl);
    if(!m) return;
    o.z += m->above();
}

bool matchanim(const char *name, const char *pattern)
{
    for(;; pattern++)
    {
        const char *s = name;
        char c;
        for(;; pattern++)
        {
            c = *pattern;
            if(!c || c=='|') break;
            else if(c=='*') 
            {
                if(!*s || iscubespace(*s)) break;
                do s++; while(*s && !iscubespace(*s));
            }
            else if(c!=*s) break;
            else s++;
        }
        if(!*s && (!c || c=='|')) return true;
        pattern = strchr(pattern, '|');
        if(!pattern) break;
    }
    return false;
}

void findanims(const char *pattern, vector<int> &anims)
{
    loopi(sizeof(animnames)/sizeof(animnames[0])) if(matchanim(animnames[i], pattern)) anims.add(i);
    types::String buf;

    // INTENSITY: Accept integer values as well, up to 128 of them
    loopi(ANIM_ALL+1)
    {
        buf.format("%i", i);
        if(matchanim(buf.get_buf(), pattern)) anims.add(i);
    }
    // INTENSITY: End Accept integer values as well
}

void loadskin(const char *dir, const char *altdir, Texture *&skin, Texture *&masks) // model skin sharing
{
#define ifnoload(tex, path) if((tex = textureload(path, 0, true, false))==notexture)
#define tryload(tex, prefix, cmd, name) \
    ifnoload(tex, makerelpath(mdir, name ".jpg", prefix, cmd)) \
    { \
        ifnoload(tex, makerelpath(mdir, name ".png", prefix, cmd)) \
        { \
            ifnoload(tex, makerelpath(maltdir, name ".jpg", prefix, cmd)) \
            { \
                ifnoload(tex, makerelpath(maltdir, name ".png", prefix, cmd)) return; \
            } \
        } \
    }
   
    defformatstring(mdir)("data/models/%s", dir);
    defformatstring(maltdir)("data/models/%s", altdir);
    masks = notexture;
    tryload(skin, NULL, NULL, "skin");
    tryload(masks, NULL, NULL, "masks");
}

// convenient function that covers the usual anims for players/monsters/npcs

VAR(animoverride, -1, 0, NUMANIMS-1);
VAR(testanims, 0, 0, 1);
VAR(testpitch, -90, 0, 90);

void renderclient(dynent *d, const char *mdlname, CLogicEntity *entity, modelattach *attachments, int hold, int attack, int attackdelay, int lastaction, int lastpain, float fade, bool ragdoll)
{
    int anim = hold ? hold : ANIM_IDLE|ANIM_LOOP;
    float yaw = testanims && d==player ? 0 : d->yaw+90,
          pitch = testpitch && d==player ? testpitch : d->pitch;
    vec o = d->feetpos();
    int basetime = 0;
    if(animoverride) anim = (animoverride<0 ? ANIM_ALL : animoverride)|ANIM_LOOP;

    else if(d->state==CS_EDITING || d->state==CS_SPECTATOR) anim = ANIM_EDIT|ANIM_LOOP;
    else if(d->state==CS_LAGGED)                            anim = ANIM_LAG|ANIM_LOOP;
    else
    {
////////////////////        if (attack != ANIM_IDLE) // INTENSITY: TODO: Reconsider this
        anim = attack;
        basetime = lastaction; 

        if(d->inwater && d->physstate<=PHYS_FALL) anim |= (((game::allowmove(d) && (d->move || d->strafe)) || d->vel.z+d->falling.z>0 ? ANIM_SWIM : ANIM_SINK)|ANIM_LOOP)<<ANIM_SECONDARY;
        else if(d->timeinair>100) anim |= (ANIM_JUMP|ANIM_END)<<ANIM_SECONDARY;
        else if(game::allowmove(d) && (d->move || d->strafe)) 
        {
            if(d->move>0) anim |= (ANIM_FORWARD|ANIM_LOOP)<<ANIM_SECONDARY;
            else if(d->strafe) anim |= ((d->strafe>0 ? ANIM_LEFT : ANIM_RIGHT)|ANIM_LOOP)<<ANIM_SECONDARY;
            else if(d->move<0) anim |= (ANIM_BACKWARD|ANIM_LOOP)<<ANIM_SECONDARY;
        }
        
        if((anim&ANIM_INDEX)==ANIM_IDLE && (anim>>ANIM_SECONDARY)&ANIM_INDEX) anim >>= ANIM_SECONDARY;
    }
    if(d->ragdoll && (!ragdoll || (anim&ANIM_INDEX)!=ANIM_DYING)) DELETEP(d->ragdoll);
    if(!((anim>>ANIM_SECONDARY)&ANIM_INDEX)) anim |= (ANIM_IDLE|ANIM_LOOP)<<ANIM_SECONDARY;
    int flags = 0;
    if(d!=player && !(anim&ANIM_RAGDOLL)) flags |= MDL_CULL_VFC | MDL_CULL_OCCLUDED | MDL_CULL_QUERY;
    if(d->type==ENT_PLAYER) flags |= MDL_FULLBRIGHT;
    else flags |= MDL_CULL_DIST;
    if(d->state==CS_LAGGED) fade = min(fade, 0.3f);
    if(modelpreviewing) flags &= ~(MDL_FULLBRIGHT | MDL_CULL_VFC | MDL_CULL_OCCLUDED | MDL_CULL_QUERY | MDL_CULL_DIST);

    // INTENSITY: If using the attack1 or 2 animations, then the start time (basetime) is determined by our action system
    // TODO: Other attacks as well
    // XXX Note: The basetime appears to be ignored if you do ANIM_LOOP
    if (anim&ANIM_ATTACK1 || anim&ANIM_ATTACK2)
        basetime = entity->getStartTime();

    rendermodel(mdlname, anim, o, yaw, pitch, flags, d, attachments, basetime, 0, fade);
}

void setbbfrommodel(dynent *d, const char *mdl, CLogicEntity *entity) // INTENSITY: Added entity
{
    model *m = loadmodel(mdl); 
    if(!m) return;
    vec center, radius;
    m->collisionbox(center, radius, entity); // INTENSITY: Added entity
    if(!m->ellipsecollide)
    {
        d->collidetype = COLLIDE_OBB;
        //d->collidetype = COLLIDE_AABB;
        //rotatebb(center, radius, int(d->yaw));
    }
    d->xradius   = radius.x + fabs(center.x);
    d->yradius   = radius.y + fabs(center.y);
    d->radius    = d->collidetype==COLLIDE_OBB ? sqrtf(d->xradius*d->xradius + d->yradius*d->yradius) : max(d->xradius, d->yradius);
    d->eyeheight = (center.z-radius.z) + radius.z*2*m->eyeheight;
    d->aboveeye  = radius.z*2*(1.0f-m->eyeheight);
}

// INTENSITY: States that we get the collision box size from the entity, not the model type
void mdlperentitycollisionboxes(bool val)
{
    checkmdl;
    loadingmodel->perentitycollisionboxes = val;
}
