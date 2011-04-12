#include "engine.h"

#define NUMGRASSWEDGES 8

static struct grasswedge
{
    vec dir, edge1, edge2;
    plane bound1, bound2;

    grasswedge(int i) :
      dir(2*M_PI*(i+0.5f)/float(NUMGRASSWEDGES), 0),
      edge1(vec(2*M_PI*i/float(NUMGRASSWEDGES), 0).div(cos(M_PI/NUMGRASSWEDGES))),
      edge2(vec(2*M_PI*(i+1)/float(NUMGRASSWEDGES), 0).div(cos(M_PI/NUMGRASSWEDGES))),
      bound1(vec(2*M_PI*(i/float(NUMGRASSWEDGES) - 0.5f), 0), 0),
      bound2(vec(2*M_PI*((i+1)/float(NUMGRASSWEDGES) + 0.5f), 0), 0)
    {}
} grasswedges[NUMGRASSWEDGES] = { 0, 1, 2, 3, 4, 5, 6, 7 };

struct grassvert
{
    vec pos;
    uchar color[4];
    float u, v, lmu, lmv;
};

static vector<grassvert> grassverts;

struct grassgroup
{
    const grasstri *tri;
    float dist;
    int tex, lmtex, offset, numquads;
};

static vector<grassgroup> grassgroups;

#define NUMGRASSOFFSETS 32

static float grassoffsets[NUMGRASSOFFSETS] = { -1 }, grassanimoffsets[NUMGRASSOFFSETS];
static int lastgrassanim = -1;

static void animategrass()
{
    loopi(NUMGRASSOFFSETS) grassanimoffsets[i] = GETFV(grassanimscale)*sinf(2*M_PI*(grassoffsets[i] + lastmillis/float(GETIV(grassanimmillis))));
    lastgrassanim = lastmillis;
}

static inline bool clipgrassquad(const grasstri &g, vec &p1, vec &p2)
{
    loopi(g.numv)
    {
        float dist1 = g.e[i].dist(p1), dist2 = g.e[i].dist(p2);
        if(dist1 <= 0)
        {
            if(dist2 <= 0) return false;
            p1.add(vec(p2).sub(p1).mul(dist1 / (dist1 - dist2)));
        }
        else if(dist2 <= 0)
            p2.add(vec(p1).sub(p2).mul(dist2 / (dist2 - dist1)));
    }
    return true;
}

bvec grasscolor(255, 255, 255);

static void gengrassquads(grassgroup *&group, const grasswedge &w, const grasstri &g, Texture *tex)
{
    float t = camera1->o.dot(w.dir);
    int tstep = int(ceil(t/GETFV(grassstep)));
    float tstart = tstep*GETFV(grassstep), tfrac = tstart - t;

    float t1 = w.dir.dot(g.v[0]), t2 = w.dir.dot(g.v[1]), t3 = w.dir.dot(g.v[2]),
          tmin = min(t1, min(t2, t3)),
          tmax = max(t1, max(t2, t3));
    if(g.numv>3)
    {
        float t4 = w.dir.dot(g.v[3]);
        tmin = min(tmin, t4);
        tmax = max(tmax, t4);
    }
 
    if(tmax < tstart || tmin > t + GETIV(grassdist)) return;

    int minstep = max(int(ceil(tmin/GETFV(grassstep))) - tstep, 1),
        maxstep = int(floor(min(tmax, t + GETIV(grassdist))/GETFV(grassstep))) - tstep,
        numsteps = maxstep - minstep + 1;

    float texscale = (GETIV(grassscale)*tex->ys)/float(GETIV(grassheight)*tex->xs), animscale = GETIV(grassheight)*texscale;
    vec tc;
    tc.cross(g.surface, w.dir).mul(texscale);

    int color = tstep + maxstep;
    if(color < 0) color = NUMGRASSOFFSETS - (-color)%NUMGRASSOFFSETS;
    color += numsteps + NUMGRASSOFFSETS - numsteps%NUMGRASSOFFSETS;

    float taperdist = GETIV(grassdist)*GETFV(grasstaper),
          taperscale = 1.0f / (GETIV(grassdist) - taperdist);

    for(int i = maxstep; i >= minstep; i--, color--)
    {
        float dist = i*GETFV(grassstep) + tfrac;
        vec p1 = vec(w.edge1).mul(dist).add(camera1->o),
            p2 = vec(w.edge2).mul(dist).add(camera1->o);
        p1.z = g.surface.zintersect(p1);
        p2.z = g.surface.zintersect(p2);

        if(!clipgrassquad(g, p1, p2)) continue;

        if(!group)
        {
            group = &grassgroups.add();
            group->tri = &g;
            group->tex = tex->id;
            group->lmtex = lightmaptexs.inrange(g.lmid) ? lightmaptexs[g.lmid].id : notexture->id;
            group->offset = grassverts.length();
            group->numquads = 0;
            if(lastgrassanim!=lastmillis) animategrass();
        }
  
        group->numquads++;
 
        float offset = grassoffsets[color%NUMGRASSOFFSETS],
              animoffset = animscale*grassanimoffsets[color%NUMGRASSOFFSETS],
              tc1 = tc.dot(p1) + offset, tc2 = tc.dot(p2) + offset,
              lm1u = g.tcu.dot(p1), lm1v = g.tcv.dot(p1),
              lm2u = g.tcu.dot(p2), lm2v = g.tcv.dot(p2),
              fade = dist > taperdist ? (GETIV(grassdist) - dist)*taperscale : 1,
              height = GETIV(grassheight) * fade;
        uchar color[4] = { grasscolor.x, grasscolor.y, grasscolor.z, uchar(fade*GETFV(grassalpha)*255) };

        #define GRASSVERT(n, tcv, modify) { \
            grassvert &gv = grassverts.add(); \
            gv.pos = p##n; \
            memcpy(gv.color, color, sizeof(color)); \
            gv.u = tc##n; gv.v = tcv; \
            gv.lmu = lm##n##u; gv.lmv = lm##n##v; \
            modify; \
        }
    
        GRASSVERT(2, 0, { gv.pos.z += height; gv.u += animoffset; });
        GRASSVERT(1, 0, { gv.pos.z += height; gv.u += animoffset; });
        GRASSVERT(1, 1, );
        GRASSVERT(2, 1, );
    }
}             

static void gengrassquads(vtxarray *va)
{
    loopv(va->grasstris)
    {
        grasstri &g = va->grasstris[i];
        if(isfoggedsphere(g.radius, g.center)) continue;
        float dist = g.center.dist(camera1->o);
        if(dist - g.radius > GETIV(grassdist)) continue;
            
        Slot &s = *lookupvslot(g.texture, false).slot;
        if(!s.grasstex) 
        {
            if(!s.autograss) continue;
            s.grasstex = textureload(s.autograss, 2);
        }

        grassgroup *group = NULL;
        loopi(NUMGRASSWEDGES)
        {
            grasswedge &w = grasswedges[i];    
            if(w.bound1.dist(g.center) > g.radius || w.bound2.dist(g.center) > g.radius) continue;
            gengrassquads(group, w, g, s.grasstex);
        }
        if(group) group->dist = dist;
    }
}

static inline int comparegrassgroups(const grassgroup *x, const grassgroup *y)
{
    if(x->dist > y->dist) return -1;
    else if(x->dist < y->dist) return 1;
    else return 0;
}

void generategrass()
{
    if(!GETIV(grass) || !GETIV(grassdist)) return;

    grassgroups.setsize(0);
    grassverts.setsize(0);

    if(grassoffsets[0] < 0) loopi(NUMGRASSOFFSETS) grassoffsets[i] = rnd(0x1000000)/float(0x1000000);

    loopi(NUMGRASSWEDGES)
    {
        grasswedge &w = grasswedges[i];
        w.bound1.offset = -camera1->o.dot(w.bound1);
        w.bound2.offset = -camera1->o.dot(w.bound2);
    }

    extern vtxarray *visibleva;
    for(vtxarray *va = visibleva; va; va = va->next)
    {
        if(va->grasstris.empty() || va->occluded >= OCCLUDE_GEOM) continue;
        if(va->distance > GETIV(grassdist)) continue;
        if(reflecting || refracting>0 ? va->o.z+va->size<reflectz : va->o.z>=reflectz) continue;
        gengrassquads(va);
    }

    grassgroups.sort(comparegrassgroups);
}

void rendergrass()
{
    if(!GETIV(grass) || !GETIV(grassdist) || grassgroups.empty() || GETIV(dbggrass)) return;

    glDisable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDepthMask(GL_FALSE);

    SETSHADER(grass);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, sizeof(grassvert), grassverts[0].pos.v);

    glEnableClientState(GL_COLOR_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(grassvert), grassverts[0].color);

    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, sizeof(grassvert), &grassverts[0].u);

    if(GETIV(renderpath)!=R_FIXEDFUNCTION || GETIV(maxtmus)>=2)
    {
        glActiveTexture_(GL_TEXTURE1_ARB);
        glClientActiveTexture_(GL_TEXTURE1_ARB);
        glEnable(GL_TEXTURE_2D);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, sizeof(grassvert), &grassverts[0].lmu);
        if(GETIV(renderpath)==R_FIXEDFUNCTION) setuptmu(1, "P * T x 2"); 
        glClientActiveTexture_(GL_TEXTURE0_ARB);
        glActiveTexture_(GL_TEXTURE0_ARB);
    }

    int texid = -1, lmtexid = -1;
    loopv(grassgroups)
    {
        grassgroup &g = grassgroups[i];

        if(reflecting || refracting)
        {
            if(refracting < 0 ?
                min(g.tri->numv>3 ? min(g.tri->v[0].z, g.tri->v[3].z) : g.tri->v[0].z, min(g.tri->v[1].z, g.tri->v[2].z)) > reflectz :
                max(g.tri->numv>3 ? max(g.tri->v[0].z, g.tri->v[3].z) : g.tri->v[0].z, max(g.tri->v[1].z, g.tri->v[2].z)) + GETIV(grassheight) < reflectz) 
                continue;
            if(isfoggedsphere(g.tri->radius, g.tri->center)) continue;
        }

        if(texid != g.tex)
        {
            glBindTexture(GL_TEXTURE_2D, g.tex);
            texid = g.tex;
        }
        if(lmtexid != g.lmtex)
        {
            if(GETIV(renderpath)!=R_FIXEDFUNCTION || GETIV(maxtmus)>=2)
            {
                glActiveTexture_(GL_TEXTURE1_ARB);
                glBindTexture(GL_TEXTURE_2D, g.lmtex);
                glActiveTexture_(GL_TEXTURE0_ARB);
            }
            lmtexid = g.lmtex;
        }

        glDrawArrays(GL_QUADS, g.offset, 4*g.numquads);
        xtravertsva += 4*g.numquads;
    }

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

    if(GETIV(renderpath)!=R_FIXEDFUNCTION || GETIV(maxtmus)>=2)
    {
        glActiveTexture_(GL_TEXTURE1_ARB);
        glClientActiveTexture_(GL_TEXTURE1_ARB);
        if(GETIV(renderpath)==R_FIXEDFUNCTION) resettmu(1);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisable(GL_TEXTURE_2D);
        glClientActiveTexture_(GL_TEXTURE0_ARB);
        glActiveTexture_(GL_TEXTURE0_ARB);
    }

    glDisable(GL_BLEND);
    glDepthMask(GL_TRUE);
    glEnable(GL_CULL_FACE);
}

