#include "engine.h"
#include "game.h" // OF

VARP(oqdynent, 0, 1, 1);
VARP(animationinterpolationtime, 0, 150, 1000);

model *loadingmodel = NULL;

/* OF */
extern vector<int> lua_anims;

#include "ragdoll.h"
#include "animmodel.h"
#include "vertmodel.h"
#include "skelmodel.h"
#include "hitzone.h"

#include "client_system.h"
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

void mdlcullface(int *cullface)
{
    checkmdl;
    loadingmodel->setcullface(*cullface!=0);
}

COMMAND(mdlcullface, "i");

void mdlcollide(int *collide)
{
    checkmdl;
    loadingmodel->collide = *collide!=0 ? (loadingmodel->collide ? loadingmodel->collide : COLLIDE_OBB) : COLLIDE_NONE;
}

COMMAND(mdlcollide, "i");

void mdlellipsecollide(int *collide)
{
    checkmdl;
    loadingmodel->collide = *collide!=0 ? COLLIDE_ELLIPSE : COLLIDE_NONE;
}

COMMAND(mdlellipsecollide, "i");

void mdltricollide(char *collide)
{
    checkmdl;
    DELETEA(loadingmodel->collidemodel);
    char *end = NULL;
    int val = strtol(collide, &end, 0);
    if(*end) { val = 1; loadingmodel->collidemodel = newstring(collide); }
    loadingmodel->collide = val ? COLLIDE_TRI : COLLIDE_NONE;
}

COMMAND(mdltricollide, "s");

void mdlspec(float *percent)
{
    checkmdl;
    float spec = *percent > 0 ? *percent/100.0f : 0.0f;
    loadingmodel->setspec(spec);
}

COMMAND(mdlspec, "f");

void mdlambient(float *percent)
{
    checkmdl;
    float ambient = *percent > 0 ? *percent/100.0f : 0.0f;
    loadingmodel->setambient(ambient);
}

COMMAND(mdlambient, "f");

void mdlalphatest(float *cutoff)
{
    checkmdl;
    loadingmodel->setalphatest(max(0.0f, min(1.0f, *cutoff)));
}

COMMAND(mdlalphatest, "f");

void mdldepthoffset(int *offset)
{
    checkmdl;
    loadingmodel->depthoffset = *offset!=0;
}

COMMAND(mdldepthoffset, "i");

void mdlglow(float *percent, float *delta, float *pulse)
{
    checkmdl;
    float glow = *percent > 0 ? *percent/100.0f : 0.0f, glowdelta = *delta/100.0f, glowpulse = *pulse > 0 ? *pulse/1000.0f : 0;
    glowdelta -= glow;
    loadingmodel->setglow(glow, glowdelta, glowpulse);
}

COMMAND(mdlglow, "fff");

void mdlenvmap(float *envmapmax, float *envmapmin, char *envmap)
{
    checkmdl;
    loadingmodel->setenvmap(*envmapmin, *envmapmax, envmap[0] ? cubemapload(envmap) : NULL);
}

COMMAND(mdlenvmap, "ffs");

void mdlfullbright(float *fullbright)
{
    checkmdl;
    loadingmodel->setfullbright(*fullbright);
}

COMMAND(mdlfullbright, "f");

void mdlshader(char *shader)
{
    checkmdl;
    loadingmodel->setshader(lookupshaderbyname(shader));
}

COMMAND(mdlshader, "s");

void mdlspin(float *yaw, float *pitch, float *roll)
{
    checkmdl;
    loadingmodel->spinyaw = *yaw;
    loadingmodel->spinpitch = *pitch;
    loadingmodel->spinroll = *roll;
}

COMMAND(mdlspin, "fff");

void mdlscale(float *percent)
{
    checkmdl;
    float scale = *percent > 0 ? *percent/100.0f : 1.0f;
    loadingmodel->scale = scale;
}

COMMAND(mdlscale, "f");

void mdltrans(float *x, float *y, float *z)
{
    checkmdl;
    loadingmodel->translate = vec(*x, *y, *z);
}

COMMAND(mdltrans, "fff");

void mdlyaw(float *angle)
{
    checkmdl;
    loadingmodel->offsetyaw = *angle;
}

COMMAND(mdlyaw, "f");

void mdlpitch(float *angle)
{
    checkmdl;
    loadingmodel->offsetpitch = *angle;
}

COMMAND(mdlpitch, "f");

void mdlroll(float *angle)
{
    checkmdl;
    loadingmodel->offsetroll = *angle;
}

COMMAND(mdlroll, "f");

void mdlshadow(int *shadow)
{
    checkmdl;
    loadingmodel->shadow = *shadow!=0;
}

COMMAND(mdlshadow, "i");

void mdlalphashadow(int *alphashadow)
{
    checkmdl;
    loadingmodel->alphashadow = *alphashadow!=0;
}

COMMAND(mdlalphashadow, "i");

void mdlbb(float *rad, float *h, float *eyeheight)
{
    checkmdl;
    loadingmodel->collidexyradius = *rad;
    loadingmodel->collideheight = *h;
    loadingmodel->eyeheight = *eyeheight;
}

COMMAND(mdlbb, "fff");

void mdlextendbb(float *x, float *y, float *z)
{
    checkmdl;
    loadingmodel->bbextend = vec(*x, *y, *z);
}

COMMAND(mdlextendbb, "fff");

void mdlname()
{
    checkmdl;
    result(loadingmodel->name);
}

COMMAND(mdlname, "");

#define checkragdoll \
    if(!loadingmodel->skeletal()) { conoutf(CON_ERROR, "not loading a skeletal model"); return; } \
    skelmodel *m = (skelmodel *)loadingmodel; \
    if(m->parts.empty()) return; \
    skelmodel::skelmeshgroup *meshes = (skelmodel::skelmeshgroup *)m->parts.last()->meshes; \
    if(!meshes) return; \
    skelmodel::skeleton *skel = meshes->skel; \
    if(!skel->ragdoll) skel->ragdoll = new ragdollskel; \
    ragdollskel *ragdoll = skel->ragdoll; \
    if(ragdoll->loaded) return;


void rdvert(float *x, float *y, float *z, float *radius)
{
    checkragdoll;
    ragdollskel::vert &v = ragdoll->verts.add();
    v.pos = vec(*x, *y, *z);
    v.radius = *radius > 0 ? *radius : 1;
}
COMMAND(rdvert, "ffff");

void rdeye(int *v)
{
    checkragdoll;
    ragdoll->eye = *v;
}
COMMAND(rdeye, "i");

void rdtri(int *v1, int *v2, int *v3)
{
    checkragdoll;
    ragdollskel::tri &t = ragdoll->tris.add();
    t.vert[0] = *v1;
    t.vert[1] = *v2;
    t.vert[2] = *v3;
}
COMMAND(rdtri, "iii");

void rdjoint(int *n, int *t, int *v1, int *v2, int *v3)
{
    checkragdoll;
    if(*n < 0 || *n >= skel->numbones) return;
    ragdollskel::joint &j = ragdoll->joints.add();
    j.bone = *n;
    j.tri = *t;
    j.vert[0] = *v1;
    j.vert[1] = *v2;
    j.vert[2] = *v3;
}
COMMAND(rdjoint, "iibbb");

void rdlimitdist(int *v1, int *v2, float *mindist, float *maxdist)
{
    checkragdoll;
    ragdollskel::distlimit &d = ragdoll->distlimits.add();
    d.vert[0] = *v1;
    d.vert[1] = *v2;
    d.mindist = *mindist;
    d.maxdist = max(*maxdist, *mindist);
}
COMMAND(rdlimitdist, "iiff");

void rdlimitrot(int *t1, int *t2, float *maxangle, float *qx, float *qy, float *qz, float *qw)
{
    checkragdoll;
    ragdollskel::rotlimit &r = ragdoll->rotlimits.add();
    r.tri[0] = *t1;
    r.tri[1] = *t2;
    r.maxangle = *maxangle * RAD;
    r.middle = matrix3(quat(*qx, *qy, *qz, *qw));
}
COMMAND(rdlimitrot, "iifffff");

void rdanimjoints(int *on)
{
    checkragdoll;
    ragdoll->animjoints = *on!=0;
}
COMMAND(rdanimjoints, "i");

// model registry

hashnameset<model *> models;
vector<const char *> preloadmodels;
hashset<char *> failedmodels;

void preloadmodel(const char *name)
{
    if(!name || !name[0] || models.access(name) || preloadmodels.htfind(name) >= 0) return;
    preloadmodels.add(newstring(name));
}

COMMAND(preloadmodel, "s");

void flushpreloadedmodels(bool msg)
{
    loopv(preloadmodels)
    {
        loadprogress = float(i+1)/preloadmodels.length();
        model *m = loadmodel(preloadmodels[i], msg);
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

void preloadusedmapmodels(bool msg, bool bih) {
    vector<extentity *> &ents = entities::getents();
    vector<extentity *> used;
    loopv(ents) {
        extentity *e = ents[i];
        if (e->type != ET_MAPMODEL || !e->m) continue;
        used.add(e);
    }

    vector<const char *> col;
    loopv(used) {
        loadprogress = float(i + 1) / used.length();
        extentity &e = *used[i];
        model *m = e.m;
        if (bih)
            m->preloadBIH();
        else if (m->collide == COLLIDE_TRI && !m->collidemodel && m->bih)
            m->setBIH();
        m->preloadmeshes();
        m->preloadshaders();
        if (m->collidemodel && col.htfind(m->collidemodel) < 0)
            col.add(m->collidemodel);
    }

    loopv(col) {
        loadprogress = float(i + 1) / col.length();
        model *m = loadmodel(col[i], msg);
        if (!m) {  if (msg) conoutf(CON_WARN,
            "could not load collide model: %s", col[i]);
        } else if (!m->bih) m->setBIH();
    }

    loadprogress = 0;
}

model *loadmodel(const char *name, bool msg)
{
    model **mm = models.access(name);
    model *m;
    if(mm) m = *mm;
    else
    {
        if(!name[0] || loadingmodel || failedmodels.find(name, NULL)) return NULL;
        if(msg)
        {
            defformatstring(filename, "media/model/%s", name);
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
        if(!m)
        {
            failedmodels.add(newstring(name));
            return NULL;
        }
        models.access(m->name, m);
    }
    return m;
}

void clear_models()
{
    enumerate(models, model *, m, delete m);
}

void cleanupmodels()
{
    enumerate(models, model *, m, m->cleanup());
}

void clearmodel(char *name)
{
    if (!name || !name[0]) return;
    model *m = models.find(name, NULL);
    if(!m) { conoutf("model %s is not loaded", name); return; }
    models.remove(name);
    m->cleanup();
    delete m;
    conoutf("cleared model %s", name);

    model *_new = loadmodel(name);
    const vector<extentity *> &ents = entities::getents();
    loopv(ents) {
        extentity &e = *ents[i];
        if (e.m == m) {
            e.m = _new;
            e.collide = NULL;
        }
    }
}
COMMAND(clearmodel, "s");

bool modeloccluded(const vec &center, float radius)
{
#ifndef SERVER
    ivec bbmin = vec(center).sub(radius), bbmax = vec(center).add(radius+1);
    return pvsoccluded(bbmin, bbmax) || bboccluded(bbmin, bbmax);
#else
    return false;
#endif
}

#ifndef SERVER
struct batchedmodel
{
    vec pos, center;
    float radius, yaw, pitch, roll, sizescale, transparent;
    int anim, basetime, basetime2, flags, attached;
    union
    {
        int visible;
        int culled;
    };
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

    m->render(anim, b.basetime, b.basetime2, b.pos, b.yaw, b.pitch, b.roll, b.d, a, b.sizescale, b.transparent);
}

VARP(maxmodelradiusdistance, 10, 200, 1000);

static inline void enablecullmodelquery()
{
    nocolorshader->set();
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    glDepthMask(GL_FALSE);
    gle::defvertex();
}

static inline void rendercullmodelquery(model *m, dynent *d, const vec &center, float radius)
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
    startquery(d->query);
    int br = int(radius*2)+1;
    drawbb(ivec(int(center.x-radius), int(center.y-radius), int(center.z-radius)), ivec(br, br, br));
    endquery(d->query);
}

static inline void disablecullmodelquery()
{
    gle::disable();
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask(GL_TRUE);
}

static inline int cullmodel(model *m, const vec &center, float radius, int flags, dynent *d = NULL)
{
    if(flags&MDL_CULL_DIST && center.dist(camera1->o)/radius>maxmodelradiusdistance) return MDL_CULL_DIST;
    if(flags&MDL_CULL_VFC && isfoggedsphere(radius, center)) return MDL_CULL_VFC;
    if(flags&MDL_CULL_OCCLUDED && modeloccluded(center, radius)) return MDL_CULL_OCCLUDED;
    else if(flags&MDL_CULL_QUERY && d->query && d->query->owner==d && checkquery(d->query)) return MDL_CULL_QUERY;
    return 0;
}

static inline int shadowmaskmodel(const vec &center, float radius)
{
    switch(shadowmapping)
    {
        case SM_REFLECT:
            return calcspherersmsplits(center, radius);
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
        if(b.flags&MDL_MAPMODEL || b.transparent < 1) break;
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

void rendershadowmodelbatches(bool dynmodel)
{
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(b.batched < 0 || !b.m->shadow || (!dynmodel && (!(b.flags&MDL_MAPMODEL) || b.m->animated()))) continue;
        bool rendered = false;
        for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            if(!(bm.visible&(1<<shadowside))) continue;
            if(!rendered) { b.m->startrender(); rendered = true; }
            renderbatchedmodel(b.m, bm);
        }
        if(rendered) b.m->endrender();
    }
}

void rendermapmodelbatches()
{
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(b.batched < 0 || !(b.flags&MDL_MAPMODEL)) continue;
        bool rendered = false;
        occludequery *query = NULL;
        for(int j = b.batched; j >= 0;)
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
                setaamask(b.m->animated());
            }
            renderbatchedmodel(b.m, bm);
        }
        if(query) endquery(query);
        if(rendered) b.m->endrender();
    }
}

float transmdlsx1 = -1, transmdlsy1 = -1, transmdlsx2 = 1, transmdlsy2 = 1;
uint transmdltiles[LIGHTTILE_MAXH];

void rendermodelbatches()
{
    transmdlsx1 = transmdlsy1 = 1;
    transmdlsx2 = transmdlsy2 = -1;
    memset(transmdltiles, 0, sizeof(transmdltiles));

    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(b.batched < 0 || b.flags&MDL_MAPMODEL) continue;
        bool rendered = false;
        for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            bm.culled = cullmodel(b.m, bm.center, bm.radius, bm.flags, bm.d);
            if(bm.culled) continue;
            if(bm.transparent < 1)
            {
                float sx1, sy1, sx2, sy2;
                if(calcbbscissor(vec(bm.center).sub(bm.radius), vec(bm.center).add(bm.radius+1), sx1, sy1, sx2, sy2))
                {
                    transmdlsx1 = min(transmdlsx1, sx1);
                    transmdlsy1 = min(transmdlsy1, sy1);
                    transmdlsx2 = max(transmdlsx2, sx2);
                    transmdlsy2 = max(transmdlsy2, sy2);
                    masktiles(transmdltiles, sx1, sy1, sx2, sy2);
                }
                continue;
            }
            if(!rendered)
            {
                b.m->startrender();
                rendered = true;
                setaamask(true);
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
        if(rendered) b.m->endrender();
        if(b.flags&MDL_CULL_QUERY && !viewidx)
        {
            bool queried = false;
            for(int j = b.batched; j >= 0;)
            {
                batchedmodel &bm = batchedmodels[j];
                j = bm.next;
                if(bm.culled&(MDL_CULL_OCCLUDED|MDL_CULL_QUERY) && bm.flags&MDL_CULL_QUERY)
                {
                    if(!queried) { enablecullmodelquery(); queried = true; }
                    rendercullmodelquery(b.m, bm.d, bm.center, bm.radius);
                }
            }
            if(queried) disablecullmodelquery();
        }
    }
}

void rendertransparentmodelbatches()
{
    loopv(batches)
    {
        modelbatch &b = batches[i];
        if(b.batched < 0 || b.flags&MDL_MAPMODEL) continue;
        bool rendered = false;
        for(int j = b.batched; j >= 0;)
        {
            batchedmodel &bm = batchedmodels[j];
            j = bm.next;
            bm.culled = cullmodel(b.m, bm.center, bm.radius, bm.flags, bm.d);
            if(bm.culled || bm.transparent >= 1) continue;
            if(!rendered)
            {
                b.m->startrender();
                rendered = true;
                setaamask(true);
            }
            if(bm.flags&MDL_CULL_QUERY && !viewidx)
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
    loopv(batches)
    {
        modelbatch &b = batches[i];
        int j = b.batched;
        if(j < 0 || batchedmodels[j].query != modelquery) continue;
        b.m->startrender();
        setaamask(b.m->animated());
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

void rendermapmodel(CLogicEntity *e, int anim, const vec &o, float yaw, float pitch, float roll, int flags, int basetime, float size)
{
    if(!e) return;
    model *m = e->staticEntity->m;
    if(!m) return;
    modelattach *a = e->attachments.length() > 1 ? e->attachments.getbuf() : NULL;

    vec center, bbradius;
    m->boundbox(center, bbradius);
    float radius = bbradius.magnitude();
    center.mul(size);
    if(roll) center.rotate_around_y(-roll*RAD);
    if(pitch && m->pitched()) center.rotate_around_x(pitch*RAD);
    center.rotate_around_z(yaw*RAD);
    center.add(o);
    radius *= size;

    int visible = 0;
    if(shadowmapping)
    {
        if(!m->shadow) return;
        visible = shadowmaskmodel(center, radius);
        if(!visible) return;
    }
    else if(flags&(MDL_CULL_VFC|MDL_CULL_DIST|MDL_CULL_OCCLUDED) && cullmodel(m, center, radius, flags))
        return;

    if(a) for(int i = 0; a[i].tag; i++)
    {
        if(a[i].name) a[i].m = loadmodel(a[i].name);
    }

    batchedmodel &b = batchedmodels.add();
    b.query = modelquery;
    b.pos = o;
    b.center = center;
    b.radius = radius;
    b.anim = anim;
    b.yaw = yaw;
    b.pitch = pitch;
    b.roll = roll;
    b.basetime = basetime;
    b.basetime2 = 0;
    b.sizescale = size;
    b.transparent = 1;
    b.flags = flags | MDL_MAPMODEL;
    b.visible = visible;
    b.d = NULL;
    b.attached = a ? modelattached.length() : -1;
    if(a) for(int i = 0;; i++) { modelattached.add(a[i]); if(!a[i].tag) break; }
    addbatchedmodel(m, b, batchedmodels.length()-1);
}

void rendermodel(const char *mdl, int anim, const vec &o, float yaw, float pitch, float roll, int flags, dynent *d, modelattach *a, int basetime, int basetime2, float size, float trans)
{
    model *m = loadmodel(mdl);
    if(!m) return;

    vec center, bbradius;
    m->boundbox(center, bbradius);
    float radius = bbradius.magnitude();
    if(d)
    {
        if(d->ragdoll)
        {
            if(anim&ANIM_RAGDOLL && d->ragdoll->millis >= basetime)
            {
                radius = max(radius, d->ragdoll->radius);
                center = d->ragdoll->center;
                goto hasboundbox;
            }
            DELETEP(d->ragdoll);
        }
        if(anim&ANIM_RAGDOLL) flags &= ~(MDL_CULL_VFC | MDL_CULL_OCCLUDED | MDL_CULL_QUERY);
    }
    center.mul(size);
    if(roll) center.rotate_around_y(-roll*RAD);
    if(pitch && m->pitched()) center.rotate_around_x(pitch*RAD);
    center.rotate_around_z(yaw*RAD);
    center.add(o);
hasboundbox:
    radius *= size;

    if(flags&MDL_NORENDER) anim |= ANIM_NORENDER;

    if(a) for(int i = 0; a[i].tag; i++)
    {
        if(a[i].name) a[i].m = loadmodel(a[i].name);
        //if(a[i].m && a[i].m->type()!=m->type()) a[i].m = NULL;
    }

    if(flags&MDL_CULL_QUERY)
    {
        if(!oqfrags || !oqdynent || !d) flags &= ~MDL_CULL_QUERY;
    }

    if(flags&MDL_NOBATCH)
    {
        int culled = cullmodel(m, center, radius, flags, d);
        if(culled)
        {
            if(culled&(MDL_CULL_OCCLUDED|MDL_CULL_QUERY) && flags&MDL_CULL_QUERY && !viewidx)
            {
                enablecullmodelquery();
                rendercullmodelquery(m, d, center, radius);
                disablecullmodelquery();
            }
            return;
        }
        if(flags&MDL_CULL_QUERY && !viewidx)
        {
            d->query = newquery(d);
            if(d->query) startquery(d->query);
        }
        m->startrender();
        setaamask(true);
        if(flags&MDL_FULLBRIGHT) anim |= ANIM_FULLBRIGHT;
        m->render(anim, basetime, basetime2, o, yaw, pitch, roll, d, a, size);
        m->endrender();
        if(flags&MDL_CULL_QUERY && !viewidx && d->query) endquery(d->query);
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
    b.roll = roll;
    b.basetime = basetime;
    b.basetime2 = basetime2;
    b.sizescale = size;
    b.transparent = trans;
    b.flags = flags;
    b.visible = 0;
    b.d = d;
    b.attached = a ? modelattached.length() : -1;
    if(a) for(int i = 0;; i++) { modelattached.add(a[i]); if(!a[i].tag) break; }
    addbatchedmodel(m, b, batchedmodels.length()-1);
}

int intersectmodel(const char *mdl, int anim, const vec &pos, float yaw, float pitch, float roll, const vec &o, const vec &ray, float &dist, int mode, dynent *d, modelattach *a, int basetime, int basetime2, float size)
{
    model *m = loadmodel(mdl);
    if(!m) return -1;
    if(d && d->ragdoll && (!(anim&ANIM_RAGDOLL) || d->ragdoll->millis < basetime)) DELETEP(d->ragdoll);
    if(a) for(int i = 0; a[i].tag; i++)
    {
        if(a[i].name) a[i].m = loadmodel(a[i].name);
    }
    return m->intersect(anim, basetime, basetime2, pos, yaw, pitch, roll, d, a, size, o, ray, dist, mode);
}

void abovemodel(vec &o, const char *mdl)
{
    model *m = loadmodel(mdl);
    if(!m) return;
    o.z += m->above();
}

/* OF */
void findanims(const char *pattern, vector<int> &anims);

ICOMMAND(findanims, "s", (char *name),
{
    vector<int> anims;
    findanims(name, anims);
    vector<char> buf;
    string num;
    loopv(anims)
    {
        formatstring(num, "%d", anims[i]);
        if(i > 0) buf.add(' ');
        buf.put(num, strlen(num));
    }
    buf.add('\0');
    result(buf.getbuf());
});

LUAICOMMAND(findanims, {
    vector<int> anims;
    findanims(luaL_checkstring(L, 1), anims);
    lua_createtable(L, anims.length(), 0);
    for (int i = 0; i < anims.length(); ++i) {
        lua_pushinteger(L, i + 1);
        lua_pushinteger(L, anims[i]);
        lua_settable   (L, -3);
    }
    return 1;
});

void loadskin(const char *dir, const char *altdir, Texture *&skin, Texture *&masks) // model skin sharing
{
/* OF */
#define ifnoload(tex, path) if((tex = textureload(path, 0, true, false))==notexture)
#define tryload(tex, prefix, cmd, name) \
    ifnoload(tex, makerelpath(mdir, name "", prefix, cmd)) \
    { \
        ifnoload(tex, makerelpath(maltdir, name "", prefix, cmd)) return; \
    }

    defformatstring(mdir, "media/model/%s", dir);
    defformatstring(maltdir, "media/model/%s", altdir);
    masks = notexture;
    tryload(skin, NULL, NULL, "skin");
    tryload(masks, NULL, NULL, "masks");
}

void setbbfrommodel(dynent *d, const char *mdl, CLogicEntity *entity) // INTENSITY: Added entity
{
    model *m = loadmodel(mdl);
    if(!m) return;
    vec center, radius;
    m->collisionbox(center, radius);
    if(m->collide != COLLIDE_ELLIPSE) d->collidetype = COLLIDE_OBB;
    d->xradius   = radius.x + fabs(center.x);
    d->yradius   = radius.y + fabs(center.y);
    d->radius    = d->collidetype==COLLIDE_OBB ? sqrtf(d->xradius*d->xradius + d->yradius*d->yradius) : max(d->xradius, d->yradius);
    d->eyeheight = (center.z-radius.z) + radius.z*2*m->eyeheight;
    d->aboveeye  = radius.z*2*(1.0f-m->eyeheight);
}

VARP(ragdoll, 0, 1, 1);

static int oldtp = -1;

void preparerd(lua_State *L, int &anim, CLogicEntity *self) {
    if (anim&ANIM_RAGDOLL) {
        //if (!ragdoll || loadmodel(mdl);
        fpsent *fp = (fpsent*)self->dynamicEntity;

        if (fp->clientnum == ClientSystem::playerNumber) {
            if (oldtp == -1 && thirdperson == 0) {
                oldtp = thirdperson;
                thirdperson = 1;
            }
        }

        if (fp->ragdoll || !ragdoll) {
            anim &= ~ANIM_RAGDOLL;
            lua_rawgeti    (L, LUA_REGISTRYINDEX, self->lua_ref);
            lua_getfield   (L, -1, "set_local_animation");
            lua_pushvalue  (L, -2);
            lua_pushinteger(L, anim & (ANIM_INDEX | ANIM_DIR));
            lua_call       (L,  2, 0);
            lua_getfield   (L, -1, "set_local_animation_flags");
            lua_insert     (L, -2);
            lua_pushinteger(L, (anim & ANIM_FLAGS) >> ANIM_FLAGSHIFT);
            lua_call       (L,  2, 0);
        }
    } else {
        if (self->dynamicEntity) {
            fpsent *fp = (fpsent*)self->dynamicEntity;

            if (fp->clientnum == ClientSystem::playerNumber && oldtp != -1) {
                thirdperson = oldtp;
                oldtp = -1;
            }
        }
    }
}

fpsent *getproxyfpsent(lua_State *L, CLogicEntity *self) {
    lua_rawgeti (L, LUA_REGISTRYINDEX, self->lua_ref);
    lua_getfield(L, -1, "rendering_hash_hint");
    lua_remove  (L, -2);
    if (!lua_isnil(L, -1)) {
        static bool initialized = false;
        static fpsent *fpsentsfr[1024];
        if (!initialized) {
            for (int i = 0; i < 1024; i++) fpsentsfr[i] = new fpsent;
            initialized = true;
        }

        int rhashhint = lua_tointeger(L, -1);
        lua_pop(L, 1);
        rhashhint = rhashhint & 1023;
        assert(rhashhint >= 0 && rhashhint < 1024);
        return fpsentsfr[rhashhint];
    } else {
        lua_pop(L, 1);
        return NULL;
    }
}

LUAICOMMAND(model_render, {
    int uid = luaL_checkinteger(L, 1);
    LUA_GET_ENT(entity, uid, "_C.rendermodel", return 0)

    lua_pushinteger(L, 1);
    lua_gettable(L, 3);
    int panim = lua_tointeger(L, -1) & (ANIM_INDEX | ANIM_DIR);
    lua_pushinteger(L, 2);
    lua_gettable(L, 3);
    int sanim = lua_tointeger(L, -1) & (ANIM_INDEX | ANIM_DIR); lua_pop(L, 2);

    int anim = panim | (sanim << ANIM_SECONDARY)
        | ((luaL_checkinteger(L, 4) << ANIM_FLAGSHIFT) & ANIM_FLAGS);
    preparerd(L, anim, entity);
    fpsent *fp = NULL;

    if (entity->dynamicEntity)
        fp = (fpsent*)entity->dynamicEntity;
    else
        fp = getproxyfpsent(L, entity);

    rendermodel(luaL_checkstring(L, 2), anim,
        vec(luaL_checknumber(L, 5), luaL_checknumber(L, 6),
            luaL_checknumber(L, 7)),
        luaL_checknumber(L, 8), luaL_checknumber(L, 9),
        luaL_checknumber(L, 10), luaL_checkinteger(L, 11), fp,
        entity->attachments.getbuf(), luaL_checkinteger(L, 12), 0, 1,
        luaL_optnumber(L, 13, 1.0f));
    return 0;
});

#define SMDLBOX(nm) LUAICOMMAND(model_get_##nm, { \
    model *mdl = loadmodel(luaL_checkstring(L, 1)); \
    if   (!mdl) return 0; \
    vec center; \
    vec radius; \
    mdl->nm(center, radius); \
    lua::push_external(L, "new_vec3"); \
    lua_pushnumber(L, center.x); lua_pushnumber(L, center.y); \
    lua_pushnumber(L, center.z); lua_call(L, 3, 1); \
    lua::push_external(L, "new_vec3"); \
    lua_pushnumber(L, radius.x); lua_pushnumber(L, radius.y); \
    lua_pushnumber(L, radius.z); lua_call(L, 3, 1); \
    return 2; \
});

SMDLBOX(boundbox)
SMDLBOX(collisionbox)

CLUAICOMMAND(model_preload, void, (const char *name), { preloadmodel(name); });
CLUAICOMMAND(model_clear, void, (const char *name), { clearmodel((char*)name); });

CLUAICOMMAND(model_preview_start, void, (int x, int y, int dx, int dy, bool scissor), {
    gle::disable();
    modelpreview::start(x, y, dx, dy, false, scissor);
});

LUAICOMMAND(model_preview, {
    const char *mdl = luaL_checkstring(L, 1);

    lua_pushinteger(L, 1);
    lua_gettable(L, 2);
    int panim = lua_tointeger(L, -1) & (ANIM_INDEX | ANIM_DIR);
    lua_pushinteger(L, 2);
    lua_gettable(L, 2);
    int sanim = lua_tointeger(L, -1) & (ANIM_INDEX | ANIM_DIR); lua_pop(L, 2);

    int anim = panim | (sanim << ANIM_SECONDARY)
        | ((luaL_checkinteger(L, 3) << ANIM_FLAGSHIFT) & ANIM_FLAGS);

    model *m = loadmodel(mdl);
    if (m) {
        vec center; vec radius;
        m->boundbox(center, radius);
        float dist = 2.0f * max(max(radius.x, radius.y), 1.1f * radius.z);
        float yaw = fmod(totalmillis / 10000.f * 360.f, 360.f);
        vec o(-center.x, dist - center.y, -0.1f * dist - center.z);

        vector<modelattach> attach;
        int len = lua_objlen(L, 4);
        if (len) {
            attach.reserve(len);
            for (int i = 1; i <= len; ++i) {
                lua_rawgeti(L,  4, i); /* attachments[i] */
                lua_rawgeti(L, -1, 1); /* attachments[i][1] */
                lua_rawgeti(L, -2, 2); /* attachments[i][2] */
                attach.add(modelattach(lua_tostring(L, -2),
                    lua_tostring(L, -1)));
                lua_pop(L, 3);
            }
            attach.add(modelattach());
        }
        dynent ent;
        rendermodel(mdl, anim, o, yaw, 0, 0, 0, &ent, attach.getbuf(), 0, 0, 1);
    }
    return 0;
});

CLUAICOMMAND(model_preview_end, void, (), {
    modelpreview::end();
});

vector<int> lua_anims;
static hashtable<const char*, int> animmap;

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
    enumeratekt(animmap, const char*, s, int, v, {
        if (matchanim(s, pattern)) anims.add(v);
    });
    string num;
    loopi(ANIM_ALL + 1) {
        formatstring(num, "%d", i);
        if (matchanim(num, pattern)) anims.add(i);
    }
    anims.sort();
}

LUAICOMMAND(model_register_anim, {
    /* don't let it overflow */
    const char *s = luaL_checkstring(L, 1);
    int *a = animmap.access(s);
    if (a) {
        lua_pushinteger(L, *a);
        lua_pushboolean(L, false);
        return 2;
    } else if (lua_anims.length() > ANIM_ALL) return 0;
    /* pin it */
    lua::pin_string(L, s);
    int n = lua_anims.length();
    animmap.access(s, n);
    lua_anims.add(n);
    lua_pushinteger(L, n);
    lua_pushboolean(L, true);
    return 2;
});

LUAICOMMAND(model_get_anim, {
    const char *s = luaL_checkstring(L, 1);
    int *a = animmap.access(s);
    if (!a) return 0;
    lua_pushinteger(L, *a);
    return 1;
});

int getanimid(const char *name) {
    int *a = animmap.access(name);
    if (!a) return 0;
    return *a;
}

void clearanims() {
    lua_anims.setsize(0);
    enumeratekt(animmap, const char*, name, int, value, {
        lua::unpin_string(name);
        (void)value; /* supress warnings */
    });
    animmap.clear();
}
#endif
