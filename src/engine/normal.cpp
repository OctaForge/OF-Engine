#include "engine.h"

struct normal
{
    int next;
    vec surface;
};

struct tnormal
{
    int next;
    vec surface, normal;
};
 
struct nval
{
    int flat, normals, tnormals;

    nval() : flat(0), normals(-1), tnormals(-1) {}
};

hashtable<vec, nval> normalgroups(1<<16);
vector<normal> normals;
vector<tnormal> tnormals;

VARR(lerpangle, 0, 44, 180);

static float lerpthreshold = 0;

static void addnormal(const vec &key, const vec &surface)
{
    nval &val = normalgroups[key];
    normal &n = normals.add();
    n.next = val.normals;
    n.surface = surface;
    val.normals = normals.length()-1;
}

static void addtnormal(const vec &key, const vec &surface, const vec &normal)
{
    nval &val = normalgroups[key];
    tnormal &n = tnormals.add();
    n.next = val.tnormals;
    n.surface = surface;
    n.normal = normal;
    val.tnormals = tnormals.length()-1;
}

static void addnormal(const vec &key, int axis)
{
    nval &val = normalgroups[key];
    val.flat += 1<<(4*axis);
}

void findnormal(const vec &key, const vec &surface, vec &v, bool checktnormals)
{
    const nval *val = normalgroups.access(key);
    if(!val) { v = surface; return; }

    if(checktnormals)
    {
        float bestangle = lerpthreshold;
        int bestnorm = -1;
        for(int cur = val->tnormals; cur >= 0;)
        {
            tnormal &o = tnormals[cur];
            float tangle = o.surface.dot(surface);
            if(tangle >= bestangle)
            {
                bestangle = tangle;
                bestnorm = cur;
            }
            cur = o.next;
        }
        if(bestnorm >= 0)
        {
            v = tnormals[bestnorm].normal;
            return;
        }
    }

    v = vec(0, 0, 0);
    int total = 0;
    if(surface.x >= lerpthreshold) { int n = (val->flat>>4)&0xF; v.x += n; total += n; }
    else if(surface.x <= -lerpthreshold) { int n = val->flat&0xF; v.x -= n; total += n; }
    if(surface.y >= lerpthreshold) { int n = (val->flat>>12)&0xF; v.y += n; total += n; }
    else if(surface.y <= -lerpthreshold) { int n = (val->flat>>8)&0xF; v.y -= n; total += n; }
    if(surface.z >= lerpthreshold) { int n = (val->flat>>20)&0xF; v.z += n; total += n; }
    else if(surface.z <= -lerpthreshold) { int n = (val->flat>>16)&0xF; v.z -= n; total += n; }
    for(int cur = val->normals; cur >= 0;)
    {
        normal &o = normals[cur];
        if(o.surface.dot(surface) >= lerpthreshold) 
        {
            v.add(o.surface);
            total++;
        }
        cur = o.next;
    }
    if(total > 1) v.normalize();
    else if(!total) v = surface;
}

VARR(lerpsubdiv, 0, 2, 4);
VARR(lerpsubdivsize, 4, 4, 128);

static uint progress = 0;

void show_addnormals_progress()
{
    float bar1 = float(progress) / float(allocnodes);
    renderprogress(bar1, "computing normals...");
}

void show_addtnormals_progress()
{
    float bar1 = float(progress) / float(allocnodes);
    renderprogress(bar1, "computing t-normals...");
}
    
void addnormals(cube &c, const ivec &o, int size)
{
    CHECK_CALCLIGHT_PROGRESS(return, show_addnormals_progress);

    if(c.children)
    {
        progress++;
        size >>= 1;
        loopi(8) addnormals(c.children[i], ivec(i, o.x, o.y, o.z, size), size);
        return;
    }
    else if(isempty(c)) return;

    vec verts[8];
    int vertused = 0, usefaces[6];
    loopi(6) if((usefaces[i] = visibletris(c, i, o.x, o.y, o.z, size))) vertused |= fvmasks[1<<i];
    loopi(8) if(vertused&(1<<i)) calcvert(c, o.x, o.y, o.z, size, verts[i], i);
    loopi(6) if(usefaces[i])
    {
        CHECK_CALCLIGHT_PROGRESS(return, show_addnormals_progress);
        if(c.texture[i] == DEFAULT_SKY) continue;

        plane planes[2];
        int numplanes = 0;
        if(!flataxisface(c, i))
        {
            numplanes = genclipplane(c, i, verts, planes);
            if(!numplanes) continue;
        }
        vec avg;
        if(numplanes >= 2)
        {
            avg = planes[0];
            avg.add(planes[1]);
            avg.normalize();
        }
        int order = usefaces[i]&4 || faceconvexity(c, i) < 0 ? 1 : 0;
        loopj(4)
        {
            const vec &v = verts[fv[i][order+j]], &vn = verts[fv[i][(order+j+1)&3]];
            if(v==vn) continue;
            if(!numplanes) addnormal(v, i);
            else addnormal(v, numplanes < 2 || j == 1 ? planes[0] : (j == 3 ? planes[1] : avg));
        }
    }
}

void addtnormals(cube &c, const ivec &o, int size)
{
    CHECK_CALCLIGHT_PROGRESS(return, show_addtnormals_progress);

    if(c.children)
    {
        progress++;
        size >>= 1;
        loopi(8) addtnormals(c.children[i], ivec(i, o.x, o.y, o.z, size), size);
        return;
    }
    else if(isempty(c) || !c.ext || c.ext->tjoints < 0) return;

    vec pos[4];
    int tj = c.ext->tjoints, vis;
    loopi(6) if((vis = visibletris(c, i, o.x, o.y, o.z, size)))
    {
        CHECK_CALCLIGHT_PROGRESS(return, show_addtnormals_progress);
        if(c.texture[i] == DEFAULT_SKY) continue;

        while(tj >= 0 && tjoints[tj].edge < i*4) tj = tjoints[tj].next;
        if(tj < 0) break;
        if(tjoints[tj].edge/4 != i) continue;

        if(c.merged&(1<<i))
        {
            if(!c.ext->merges || c.ext->merges[i].empty()) continue;

            const mergeinfo &m = c.ext->merges[i];
            genmergedverts(c, i, o, size, m, pos, vis);
        }
        else 
        {
            int order = vis&4 || faceconvexity(c, i)<0 ? 1 : 0;
            loopj(4) calcvert(c, o.x, o.y, o.z, size, pos[j], fv[i][(order+j)&3]);
            if(!(vis&1)) pos[1] = pos[0];
            if(!(vis&2)) pos[3] = pos[0];
        }

        loopk(2) if(vis&k)
        {
            plane surf;
            if(!surf.toplane(pos[0], pos[1+k], pos[2+k])) continue; 

            loopj(2)
            {
                int e1 = 2*k + j, edge = i*4 + e1;
                if(tj < 0 || tjoints[tj].edge > edge) continue;
                int e2 = (e1 + 1)%4;
                const vec &v1 = pos[e1], &v2 = pos[e2];
                ivec d(vec(v2).sub(v1).mul(8));
                int axis = abs(d.x) > abs(d.y) ? (abs(d.x) > abs(d.z) ? 0 : 2) : (abs(d.y) > abs(d.z) ? 1 : 2);
                if(d[axis] < 0) d.neg();
                reduceslope(d);
                int origin = int(min(v1[axis], v2[axis])*8)&~0x7FFF,
                    offset1 = (int(v1[axis]*8) - origin) / d[axis],
                    offset2 = (int(v2[axis]*8) - origin) / d[axis];
                vec o = vec(v1).sub(d.tovec().mul(offset1/8.0f)), n1, n2;
                float doffset = 1.0f / (offset2 - offset1);
                findnormal(v1, surf, n1, false);
                findnormal(v2, surf, n2, false);

                while(tj >= 0)
                {
                    tjoint &t = tjoints[tj];
                    if(t.edge != edge) break;
                    float offset = (t.offset - offset1) * doffset;
                    vec tpos = d.tovec().mul(t.offset/8.0f).add(o);
                    addtnormal(tpos, surf, vec().lerp(n1, n2, offset).normalize());
                    tj = t.next;
                }
            }
        }
    }
}

void calcnormals(bool lerptjoints)
{
    if(!lerpangle) return;
    lerpthreshold = cos(lerpangle*RAD) - 1e-5f; 
    progress = 1;
    loopi(8) addnormals(worldroot[i], ivec(i, 0, 0, 0, worldsize/2), worldsize/2);
    if(lerptjoints) 
    {
        findtjoints();
        progress = 1;
        loopi(8) addtnormals(worldroot[i], ivec(i, 0, 0, 0, worldsize/2), worldsize/2);
    }
}

void clearnormals()
{
    normalgroups.clear();
    normals.setsize(0);
    tnormals.setsize(0);
}

void calclerpverts(const vec2 *c, const vec *n, lerpvert *lv, int &numv)
{
    int i = 0;
    loopj(numv)
    {
        if(j)
        {
            if(c[j] == c[j-1] && n[j] == n[j-1]) continue;
            if(j == numv-1 && c[j] == c[0] && n[j] == n[0]) continue;
        }
        lv[i].normal = n[j];
        lv[i].u = c[j].x;
        lv[i].v = c[j].y;
        i++;
    }
    numv = i;
}

void setlerpstep(float v, lerpbounds &bounds)
{
    if(bounds.min->v + 1 > bounds.max->v)
    {
        bounds.nstep = vec(0, 0, 0);
        bounds.normal = bounds.min->normal;
        if(bounds.min->normal != bounds.max->normal)
        {
            bounds.normal.add(bounds.max->normal);
            bounds.normal.normalize();
        }
        bounds.ustep = 0;
        bounds.u = bounds.min->u;
        return;
    }

    bounds.nstep = bounds.max->normal;
    bounds.nstep.sub(bounds.min->normal);
    bounds.nstep.div(bounds.max->v-bounds.min->v);

    bounds.normal = bounds.nstep;
    bounds.normal.mul(v - bounds.min->v);
    bounds.normal.add(bounds.min->normal);

    bounds.ustep = (bounds.max->u-bounds.min->u) / (bounds.max->v-bounds.min->v);
    bounds.u = bounds.ustep * (v-bounds.min->v) + bounds.min->u;
}

void initlerpbounds(const lerpvert *lv, int numv, lerpbounds &start, lerpbounds &end)
{
    const lerpvert *first = &lv[0], *second = NULL;
    loopi(numv-1)
    {
        if(lv[i+1].v < first->v) { second = first; first = &lv[i+1]; }
        else if(!second || lv[i+1].v < second->v) second = &lv[i+1];
    }

    if(int(first->v) < int(second->v)) { start.min = end.min = first; }
    else if(first->u > second->u) { start.min = second; end.min = first; }
    else { start.min = first; end.min = second; }

    if((lv[1].u - lv->u)*(lv[2].v - lv->v) > (lv[1].v - lv->v)*(lv[2].u - lv->u))
    { 
        start.winding = end.winding = 1;
        start.max = (start.min == lv ? &lv[numv-1] : start.min-1);
        end.max = (end.min == &lv[numv-1] ? lv : end.min+1);
    }
    else
    {
        start.winding = end.winding = -1;
        start.max = (start.min == &lv[numv-1] ? lv : start.min+1);
        end.max = (end.min == lv ? &lv[numv-1] : end.min-1);
    }

    setlerpstep(0, start);
    setlerpstep(0, end);
}

void updatelerpbounds(float v, const lerpvert *lv, int numv, lerpbounds &start, lerpbounds &end)
{
    if(v >= start.max->v)
    {
        const lerpvert *next = start.winding > 0 ?
                (start.max == lv ? &lv[numv-1] : start.max-1) :
                (start.max == &lv[numv-1] ? lv : start.max+1);
        if(next->v > start.max->v)
        {
            start.min = start.max;
            start.max = next;
            setlerpstep(v, start);
        }
    }
    if(v >= end.max->v)
    {
        const lerpvert *next = end.winding > 0 ?
                (end.max == &lv[numv-1] ? lv : end.max+1) :
                (end.max == lv ? &lv[numv-1] : end.max-1);
        if(next->v > end.max->v)
        {
            end.min = end.max;
            end.max = next;
            setlerpstep(v, end);
        }
    }
}

void lerpnormal(float v, const lerpvert *lv, int numv, lerpbounds &start, lerpbounds &end, vec &normal, vec &nstep)
{   
    updatelerpbounds(v, lv, numv, start, end);

    if(start.u + 1 > end.u)
    {
        nstep = vec(0, 0, 0);
        normal = start.normal;
        normal.add(end.normal);
        normal.normalize();
    }
    else
    {
        vec nstart(start.normal), nend(end.normal);
        nstart.normalize();
        nend.normalize();
       
        nstep = nend;
        nstep.sub(nstart);
        nstep.div(end.u-start.u);

        normal = nstep;
        normal.mul(-start.u);
        normal.add(nstart);
        normal.normalize();
    }
     
    start.normal.add(start.nstep);
    start.u += start.ustep;

    end.normal.add(end.nstep); 
    end.u += end.ustep;
}

void newnormals(cube &c)
{
    if(!c.ext) newcubeext(c);
    if(!c.ext->normals)
    {
        c.ext->normals = new surfacenormals[6];
        memset(c.ext->normals, 128, 6*sizeof(surfacenormals));
    }
}

void freenormals(cube &c)
{
    if(c.ext) DELETEA(c.ext->normals);
}

