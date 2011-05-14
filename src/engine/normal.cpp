#include "engine.h"

struct normal
{
    int next;
    vec surface;
};

struct nval
{
    int flat, normals;

    nval() : flat(0), normals(-1) {}
};

hashtable<vec, nval> normalgroups(1<<16);
vector<normal> normals;

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

static void addnormal(const vec &key, int axis)
{
    nval &val = normalgroups[key];
    val.flat += 1<<(4*axis);
}

void findnormal(const vec &key, const vec &surface, vec &v)
{
    const nval *val = normalgroups.access(key);
    if(!val) { v = surface; return; }

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

void show_calcnormals_progress()
{
    float bar1 = float(progress) / float(allocnodes);
    renderprogress(bar1, "computing normals...");
}

#define CHECK_PROGRESS(exit) CHECK_CALCLIGHT_PROGRESS(exit, show_calcnormals_progress)

void addnormals(cube &c, const ivec &o, int size)
{
    CHECK_PROGRESS(return);

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
        CHECK_PROGRESS(return);
        if(c.texture[i] == DEFAULT_SKY) continue;

        plane planes[2];
        int numplanes = 0;
        if(!flataxisface(c, i))
        {
            numplanes = genclipplane(c, i, verts, planes);
            if(!numplanes) continue;
        }
        int subdiv = 0;
        if(lerpsubdiv && size > lerpsubdivsize) // && faceedges(c, i) == F_SOLID)
        {
            subdiv = 1<<lerpsubdiv;
            while(size/subdiv < lerpsubdivsize) subdiv >>= 1; 
        }
        vec avg;
        if(numplanes >= 2)
        {
            avg = planes[0];
            avg.add(planes[1]);
            avg.normalize();
        }
        int idxs[4];
        loopj(4) idxs[j] = faceverts(c, i, j);
        loopj(4)
        {
            const vec &v = verts[idxs[j]], &vn = verts[idxs[(j+1)%4]];
            if(v==vn) continue;
            if(!numplanes)
            {
                addnormal(v, i);
                if(subdiv < 2) continue;
                vec dv = vec(vn).sub(v);
                if(dv.iszero()) continue;
                dv.div(subdiv);
                vec vs(v);
                loopk(subdiv - 1)
                {
                    vs.add(dv);
                    addnormal(vs, i);
                }
                continue;
            }
            const vec &cur = numplanes < 2 || j == 1 ? planes[0] : (j == 3 ? planes[1] : avg);
            addnormal(v, cur);
            if(subdiv < 2) continue;
            vec dv = vec(vn).sub(v);
            if(dv.iszero()) continue;
            dv.div(subdiv);
            vec vs(v);
            if(numplanes < 2) loopk(subdiv - 1)
            {
                vs.add(dv);
                addnormal(vs, planes[0]);
            }
            else
            {
                vec dn(j==0 ? planes[0] : (j == 2 ? planes[1] : avg));
                dn.sub(cur);
                dn.div(subdiv);
                vec n(cur);
                loopk(subdiv - 1)
                {
                    vs.add(dv);
                    n.add(dn);
                    addnormal(vs, vec(dn).normalize());
                }
            }
        }
    }
}

void calcnormals()
{
    if(!lerpangle) return;
    lerpthreshold = cos(lerpangle*RAD) - 1e-5f; 
    progress = 1;
    loopi(8) addnormals(worldroot[i], ivec(i, 0, 0, 0, worldsize/2), worldsize/2);
}

void clearnormals()
{
    normalgroups.clear();
    normals.setsize(0);
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

