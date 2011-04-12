// octarender.cpp: fill vertex arrays with different cube surfaces.

#include "engine.h"

#include "intensity_texture.h"
#include "intensity_physics.h"

struct vboinfo
{
    int uses;
    uchar *data;
};

static inline uint hthash(GLuint key)
{
    return key;
}

static inline bool htcmp(GLuint x, GLuint y)
{
    return x==y;
}

hashtable<GLuint, vboinfo> vbos;

enum
{
    VBO_VBUF = 0,
    VBO_EBUF,
    VBO_SKYBUF,
    NUMVBO
};

static vector<uchar> vbodata[NUMVBO];
static vector<vtxarray *> vbovas[NUMVBO];
static int vbosize[NUMVBO];

void destroyvbo(GLuint vbo)
{
    vboinfo *exists = vbos.access(vbo);
    if(!exists) return;
    vboinfo &vbi = *exists;
    if(vbi.uses <= 0) return;
    vbi.uses--;
    if(!vbi.uses) 
    {
        if(hasVBO) glDeleteBuffers_(1, &vbo);
        else if(vbi.data) delete[] vbi.data;
        vbos.remove(vbo);
    }
}

void genvbo(int type, void *buf, int len, vtxarray **vas, int numva)
{
    GLuint vbo;
    uchar *data = NULL;
    if(hasVBO)
    {
        glGenBuffers_(1, &vbo);
        GLenum target = type==VBO_VBUF ? GL_ARRAY_BUFFER_ARB : GL_ELEMENT_ARRAY_BUFFER_ARB;
        glBindBuffer_(target, vbo);
        glBufferData_(target, len, buf, GL_STATIC_DRAW_ARB);
        glBindBuffer_(target, 0);
    }
    else
    {
        static GLuint nextvbo = 0;
        if(!nextvbo) nextvbo++; // just in case it ever wraps around
        vbo = nextvbo++;
        data = new uchar[len];
        memcpy(data, buf, len);
    }
    vboinfo &vbi = vbos[vbo]; 
    vbi.uses = numva;
    vbi.data = data;
 
    if(GETIV(printvbo)) conoutf(CON_DEBUG, "vbo %d: type %d, size %d, %d uses", vbo, type, len, numva);

    loopi(numva)
    {
        vtxarray *va = vas[i];
        switch(type)
        {
            case VBO_VBUF: 
                va->vbuf = vbo; 
                if(!hasVBO) va->vdata = (vertex *)(data + (size_t)va->vdata);
                break;
            case VBO_EBUF: 
                va->ebuf = vbo; 
                if(!hasVBO) va->edata = (ushort *)(data + (size_t)va->edata);
                break;
            case VBO_SKYBUF: 
                va->skybuf = vbo; 
                if(!hasVBO) va->skydata = (ushort *)(data + (size_t)va->skydata);
                break;
        }
    }
}

bool readva(vtxarray *va, ushort *&edata, uchar *&vdata)
{
    if(!va->vbuf || !va->ebuf) return false;

    edata = new ushort[3*va->tris];
    vdata = new uchar[va->verts*VTXSIZE];

    if(hasVBO)
    {
        glBindBuffer_(GL_ELEMENT_ARRAY_BUFFER_ARB, va->ebuf);
        glGetBufferSubData_(GL_ELEMENT_ARRAY_BUFFER_ARB, (size_t)va->edata, 3*va->tris*sizeof(ushort), edata);
        glBindBuffer_(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);

        glBindBuffer_(GL_ARRAY_BUFFER_ARB, va->vbuf);
        glGetBufferSubData_(GL_ARRAY_BUFFER_ARB, va->voffset*VTXSIZE, va->verts*VTXSIZE, vdata);
        glBindBuffer_(GL_ARRAY_BUFFER_ARB, 0);
        return true;
    }
    else
    {
        memcpy(edata, va->edata, 3*va->tris*sizeof(ushort));
        memcpy(vdata, (uchar *)va->vdata + va->voffset*VTXSIZE, va->verts*VTXSIZE);
        return true;
    }
}

void flushvbo(int type = -1)
{
    if(type < 0)
    {
        loopi(NUMVBO) flushvbo(i);
        return;
    }

    vector<uchar> &data = vbodata[type];
    if(data.empty()) return;
    vector<vtxarray *> &vas = vbovas[type];
    genvbo(type, data.getbuf(), data.length(), vas.getbuf(), vas.length());
    data.setsize(0);
    vas.setsize(0);
    vbosize[type] = 0;
}

uchar *addvbo(vtxarray *va, int type, int numelems, int elemsize)
{
    vbosize[type] += numelems;

    vector<uchar> &data = vbodata[type];
    vector<vtxarray *> &vas = vbovas[type];

    vas.add(va);

    int len = numelems*elemsize;
    uchar *buf = data.reserve(len).buf;
    data.advance(len);
    return buf; 
}
 
struct verthash
{
    static const int SIZE = 1<<13;
    int table[SIZE];
    vector<vertex> verts;
    vector<int> chain;

    verthash() { clearverts(); }

    void clearverts() 
    { 
        memset(table, -1, sizeof(table));
        chain.setsize(0); 
        verts.setsize(0);
    }

    int addvert(const vertex &v)
    {
        uint h = hthash(v.pos)&(SIZE-1);
        for(int i = table[h]; i>=0; i = chain[i])
        {
            const vertex &c = verts[i];
            if(c.pos==v.pos && c.u==v.u && c.v==v.v && c.norm==v.norm && c.tangent==v.tangent && c.bitangent==v.bitangent)
            {
                 if(!v.lmu && !v.lmv) return i; 
                 if(c.lmu==v.lmu && c.lmv==v.lmv) return i;
            }
        }
        if(verts.length() >= USHRT_MAX) return -1;
        verts.add(v);
        chain.add(table[h]);
        return table[h] = verts.length()-1;
    }

    int addvert(const vec &pos, float u = 0, float v = 0, short lmu = 0, short lmv = 0, const bvec &norm = bvec(128, 128, 128), const bvec &tangent = bvec(128, 128, 128), uchar bitangent = 128)
    {
        vertex vtx;
        vtx.pos = pos;
        vtx.u = u;
        vtx.v = v;
        vtx.lmu = lmu;
        vtx.lmv = lmv;
        vtx.norm = norm;
        vtx.reserved = 0;
        vtx.tangent = tangent;
        vtx.bitangent = bitangent;
        return addvert(vtx);
    } 
};

enum
{
    NO_ALPHA = 0,
    ALPHA_BACK,
    ALPHA_FRONT
};

struct sortkey
{
     ushort tex, lmid, envmap;
     uchar dim, layer, alpha;

     sortkey() {}
     sortkey(ushort tex, ushort lmid, uchar dim, uchar layer = LAYER_TOP, ushort envmap = EMID_NONE, uchar alpha = NO_ALPHA)
      : tex(tex), lmid(lmid), envmap(envmap), dim(dim), layer(layer), alpha(alpha)
     {}

     bool operator==(const sortkey &o) const { return tex==o.tex && lmid==o.lmid && envmap==o.envmap && dim==o.dim && layer==o.layer && alpha==o.alpha; }
};

struct sortval
{
     int unlit;
     vector<ushort> tris[2];

     sortval() : unlit(0) {}
};

static inline bool htcmp(const sortkey &x, const sortkey &y)
{
    return x == y;
}

static inline uint hthash(const sortkey &k)
{
    return k.tex + k.lmid*9741;
}

struct vacollect : verthash
{
    ivec origin;
    int size;
    hashtable<sortkey, sortval> indices;
    vector<sortkey> texs;
    vector<grasstri> grasstris;
    vector<materialsurface> matsurfs;
    vector<octaentities *> mapmodels;
    vector<ushort> skyindices, explicitskyindices;
    int worldtris, skytris, skyfaces, skyclip, skyarea;

    void clear()
    {
        clearverts();
        worldtris = skytris = 0;
        skyfaces = 0;
        skyclip = INT_MAX;
        skyarea = 0;
        indices.clear();
        skyindices.setsize(0);
        explicitskyindices.setsize(0);
        matsurfs.setsize(0);
        mapmodels.setsize(0);
        grasstris.setsize(0);
        texs.setsize(0);
    }

    void remapunlit(vector<sortkey> &remap)
    {
        uint lastlmid[8] = { LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT }, 
             firstlmid[8] = { LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT, LMID_AMBIENT };
        int firstlit[8] = { -1, -1, -1, -1, -1, -1, -1, -1 };
        loopv(texs)
        {
            sortkey &k = texs[i];
            if(k.lmid>=LMID_RESERVED) 
            {
                LightMapTexture &lmtex = lightmaptexs[k.lmid];
                int type = lmtex.type&LM_TYPE;
                if(k.layer&LAYER_BLEND) type += 2;
                else if(k.alpha) type = 4 + 2*(k.alpha-1);
                lastlmid[type] = lmtex.unlitx>=0 ? k.lmid : LMID_AMBIENT;
                if(firstlmid[type]==LMID_AMBIENT && lastlmid[type]!=LMID_AMBIENT)
                {
                    firstlit[type] = i;
                    firstlmid[type] = lastlmid[type];
                }
            }
            else if(k.lmid==LMID_AMBIENT)
            {
                Shader *s = lookupvslot(k.tex, false).slot->shader;
                int type = s->type&SHADER_NORMALSLMS ? LM_BUMPMAP0 : LM_DIFFUSE;
                if(k.layer&LAYER_BLEND) type += 2;
                else if(k.alpha) type = 4 + 2*(k.alpha-1);
                if(lastlmid[type]!=LMID_AMBIENT)
                {
                    sortval &t = indices[k];
                    if(t.unlit<=0) t.unlit = lastlmid[type];
                }
            }
        }
        loopj(2)
        {
            int offset = 2*j;
            if(firstlmid[offset]==LMID_AMBIENT && firstlmid[offset+1]==LMID_AMBIENT) continue;
            loopi(max(firstlit[offset], firstlit[offset+1]))
            {
                sortkey &k = texs[i];
                if((j ? !(k.layer&LAYER_BLEND) : k.layer&LAYER_BLEND) || k.alpha) continue;
                if(k.lmid!=LMID_AMBIENT) continue;
                Shader *s = lookupvslot(k.tex, false).slot->shader;
                int type = offset + (s->type&SHADER_NORMALSLMS ? LM_BUMPMAP0 : LM_DIFFUSE);
                if(firstlmid[type]==LMID_AMBIENT) continue;
                indices[k].unlit = firstlmid[type];
            }
        }  
        loopj(2)
        {
            int offset = 4 + 2*j;
            if(firstlmid[offset]==LMID_AMBIENT && firstlmid[offset+1]==LMID_AMBIENT) continue;
            loopi(max(firstlit[offset], firstlit[offset+1]))
            {
                sortkey &k = texs[i];
                if(k.alpha != j+1) continue;
                if(k.lmid!=LMID_AMBIENT) continue;
                Shader *s = lookupvslot(k.tex, false).slot->shader;
                int type = offset + (s->type&SHADER_NORMALSLMS ? LM_BUMPMAP0 : LM_DIFFUSE);
                if(firstlmid[type]==LMID_AMBIENT) continue;
                indices[k].unlit = firstlmid[type];
            }
        } 
        loopv(remap)
        {
            sortkey &k = remap[i];
            sortval &t = indices[k];
            if(t.unlit<=0) continue; 
            LightMapTexture &lm = lightmaptexs[t.unlit];
            short u = short(ceil((lm.unlitx + 0.5f) * SHRT_MAX/lm.w)), 
                  v = short(ceil((lm.unlity + 0.5f) * SHRT_MAX/lm.h));
            loopl(2) loopvj(t.tris[l])
            {
                vertex &vtx = verts[t.tris[l][j]];
                if(!vtx.lmu && !vtx.lmv)
                {
                    vtx.lmu = u;
                    vtx.lmv = v;
                }
                else if(vtx.lmu != u || vtx.lmv != v) 
                {
                    vertex vtx2 = vtx;
                    vtx2.lmu = u;
                    vtx2.lmv = v;
                    t.tris[l][j] = addvert(vtx2);
                }
            }
            sortval *dst = indices.access(sortkey(k.tex, t.unlit, k.dim, k.layer, k.envmap, k.alpha));
            if(dst) loopl(2) loopvj(t.tris[l]) dst->tris[l].add(t.tris[l][j]);
        }
    }
                    
    void optimize()
    {
        vector<sortkey> remap;
        enumeratekt(indices, sortkey, k, sortval, t,
            loopl(2) if(t.tris[l].length() && t.unlit<=0)
            {
                if(k.lmid>=LMID_RESERVED && lightmaptexs[k.lmid].unlitx>=0)
                {
                    sortkey ukey(k.tex, LMID_AMBIENT, k.dim, k.layer, k.envmap, k.alpha);
                    sortval *uval = indices.access(ukey);
                    if(uval && uval->unlit<=0)
                    {
                        if(uval->unlit<0) texs.removeobj(ukey);
                        else remap.add(ukey);
                        uval->unlit = k.lmid;
                    }
                }
                else if(k.lmid==LMID_AMBIENT)
                {
                    remap.add(k);
                    t.unlit = -1;
                }
                texs.add(k);
                break;
            }
        );
        texs.sort(texsort);

        remapunlit(remap);

        matsurfs.shrink(optimizematsurfs(matsurfs.getbuf(), matsurfs.length()));
    }

    static int texsort(const sortkey *x, const sortkey *y)
    {
        if(x->alpha < y->alpha) return -1;
        if(x->alpha > y->alpha) return 1;
        if(x->layer < y->layer) return -1;
        if(x->layer > y->layer) return 1;
        if(x->tex == y->tex) 
        {
            if(x->lmid < y->lmid) return -1;
            if(x->lmid > y->lmid) return 1;
            if(x->envmap < y->envmap) return -1;
            if(x->envmap > y->envmap) return 1;
            if(x->dim < y->dim) return -1;
            if(x->dim > y->dim) return 1;
            return 0;
        }
        if(GETIV(renderpath)!=R_FIXEDFUNCTION)
        {
            VSlot &xs = lookupvslot(x->tex, false), &ys = lookupvslot(y->tex, false);
            if(xs.slot->shader < ys.slot->shader) return -1;
            if(xs.slot->shader > ys.slot->shader) return 1;
            if(xs.slot->params.length() < ys.slot->params.length()) return -1;
            if(xs.slot->params.length() > ys.slot->params.length()) return 1;
        }
        if(x->tex < y->tex) return -1;
        else return 1;
    }

#define GENVERTS(type, ptr, body) do \
    { \
        type *f = (type *)ptr; \
        loopv(verts) \
        { \
            const vertex &v = verts[i]; \
            body; \
            f++; \
        } \
    } while(0)
#define GENVERTSPOSNORMUV(type, ptr, body) GENVERTS(type, ptr, { f->pos = v.pos; f->norm = v.norm; f->norm.flip(); f->reserved = 0; f->u = v.u; f->v = v.v; body; })

    void genverts(void *buf)
    {
        if(GETIV(renderpath)==R_FIXEDFUNCTION)
            GENVERTSPOSNORMUV(vertexff, buf, { f->lmu = v.lmu/float(SHRT_MAX); f->lmv = v.lmv/float(SHRT_MAX); });
        else 
            GENVERTS(vertex, buf, { *f = v; f->norm.flip(); });
    }

    void setupdata(vtxarray *va)
    {
        va->verts = verts.length();
        va->tris = worldtris/3;
        va->vbuf = 0;
        va->vdata = 0;
        va->minvert = 0;
        va->maxvert = va->verts-1;
        va->voffset = 0;
        if(va->verts)
        {
            if(vbosize[VBO_VBUF] + verts.length() > GETIV(vbosize) || 
               vbosize[VBO_EBUF] + worldtris > USHRT_MAX ||
               vbosize[VBO_SKYBUF] + skytris > USHRT_MAX) 
                flushvbo();

            va->voffset = vbosize[VBO_VBUF];
            uchar *vdata = addvbo(va, VBO_VBUF, va->verts, VTXSIZE);
            // INTENSITY: Set up physical verts
            PhysicsManager::setupWorldGeometryVerts(verts); 
            // Go over each item in vc's "hashtable<sortkey, sortval> indices;", each is a group of tris
            enumeratekt(indices, sortkey, k, sortval, t,
                {
                    loopl(2)
                        PhysicsManager::setupWorldGeometryTriGroup(t.tris[l], k.tex, k.lmid, l);
                }
            );
            PhysicsManager::finishWorldGeometryVerts();
            // INTENSITY: end
            genverts(vdata);
            va->minvert += va->voffset;
            va->maxvert += va->voffset;
        }

        va->matbuf = NULL;
        va->matsurfs = matsurfs.length();
        if(va->matsurfs) 
        {
            va->matbuf = new materialsurface[matsurfs.length()];
            memcpy(va->matbuf, matsurfs.getbuf(), matsurfs.length()*sizeof(materialsurface));
        }

        va->skybuf = 0;
        va->skydata = 0;
        va->sky = skyindices.length();
        va->explicitsky = explicitskyindices.length();
        if(va->sky + va->explicitsky)
        {
            va->skydata += vbosize[VBO_SKYBUF];
            ushort *skydata = (ushort *)addvbo(va, VBO_SKYBUF, va->sky+va->explicitsky, sizeof(ushort));
            memcpy(skydata, skyindices.getbuf(), va->sky*sizeof(ushort));
            memcpy(skydata+va->sky, explicitskyindices.getbuf(), va->explicitsky*sizeof(ushort));
            if(va->voffset) loopi(va->sky+va->explicitsky) skydata[i] += va->voffset; 
        }

        va->eslist = NULL;
        va->texs = texs.length();
        va->blendtris = 0;
        va->blends = 0;
        va->alphabacktris = 0;
        va->alphaback = 0;
        va->alphafronttris = 0;
        va->alphafront = 0;
        va->ebuf = 0;
        va->edata = 0;
        if(va->texs)
        {
            va->eslist = new elementset[va->texs];
            va->edata += vbosize[VBO_EBUF];
            ushort *edata = (ushort *)addvbo(va, VBO_EBUF, worldtris, sizeof(ushort)), *curbuf = edata;
            loopv(texs)
            {
                const sortkey &k = texs[i];
                const sortval &t = indices[k];
                elementset &e = va->eslist[i];
                e.texture = k.tex;
                e.lmid = t.unlit>0 ? t.unlit : k.lmid;
                e.dim = k.dim;
                e.layer = k.layer;
                e.envmap = k.envmap;
                ushort *startbuf = curbuf;
                loopl(2) 
                {
                    e.minvert[l] = USHRT_MAX;
                    e.maxvert[l] = 0;

                    if(t.tris[l].length())
                    {
                        memcpy(curbuf, t.tris[l].getbuf(), t.tris[l].length() * sizeof(ushort));

                        loopvj(t.tris[l])
                        {
                            curbuf[j] += va->voffset;
                            e.minvert[l] = min(e.minvert[l], curbuf[j]);
                            e.maxvert[l] = max(e.maxvert[l], curbuf[j]);
                        }

                        curbuf += t.tris[l].length();
                    }
                    e.length[l] = curbuf-startbuf;
                }
                if(k.layer&LAYER_BLEND) { va->texs--; va->tris -= e.length[1]/3; va->blends++; va->blendtris += e.length[1]/3; }
                else if(k.alpha==ALPHA_BACK) { va->texs--; va->tris -= e.length[1]/3; va->alphaback++; va->alphabacktris += e.length[1]/3; }
                else if(k.alpha==ALPHA_FRONT) { va->texs--; va->tris -= e.length[1]/3; va->alphafront++; va->alphafronttris += e.length[1]/3; } 
            }
        }

        va->texmask = 0;
        loopi(va->texs+va->blends+va->alphaback+va->alphafront)
        {
            Slot &slot = *lookupvslot(va->eslist[i].texture, false).slot;
            loopvj(slot.sts) va->texmask |= 1<<slot.sts[j].type;
            if(slot.shader->type&SHADER_ENVMAP && (GETIV(renderpath)!=R_FIXEDFUNCTION || (slot.ffenv && hasCM && GETIV(maxtmus) >= 2))) va->texmask |= 1<<TEX_ENVMAP;
        }

        if(grasstris.length())
        {
            va->grasstris.move(grasstris);
            useshaderbyname("grass");
        }

        if(mapmodels.length()) va->mapmodels.put(mapmodels.getbuf(), mapmodels.length());
    }

    bool emptyva()
    {
        return verts.empty() && matsurfs.empty() && skyindices.empty() && explicitskyindices.empty() && grasstris.empty() && mapmodels.empty();
    }            
} vc;

int recalcprogress = 0;
#define progress(s)     if((recalcprogress++&0xFFF)==0) renderprogress(recalcprogress/(float)allocnodes, s);

vector<tjoint> tjoints;

vec shadowmapmin, shadowmapmax;

int calcshadowmask(vec *vv)
{
    extern vec shadowdir;
    int mask = 0, used = 0;
    if(vv[0]==vv[2]) return 0;
    vec v2 = vec(vv[2]).sub(vv[0]);
    if(vv[0]!=vv[1] && vv[1]!=vv[2])
    {
        vec v1 = vec(vv[1]).sub(vv[0]);
        if(vec().cross(v1, v2).dot(shadowdir)>0) { mask |= 1; used |= 0x7; } 
    }
    if(vv[0]!=vv[3] && vv[2]!=vv[3])
    {
        vec v3 = vec(vv[3]).sub(vv[0]);
        if(vec().cross(v2, v3).dot(shadowdir)>0) { mask |= 2; used |= 0xD; }
    }
    if(used) loopi(4) if(used&(1<<i))
    {
        const vec &v = vv[i];
        loopk(3)
        {
            if(v[k]<shadowmapmin[k]) shadowmapmin[k] = v[k];
            if(v[k]>shadowmapmax[k]) shadowmapmax[k] = v[k];
        }
    }
    return mask;
}

void reduceslope(ivec &n)
{
    int mindim = -1, minval = 64;
    loopi(3) if(n[i])
    {
        int val = abs(n[i]);
        if(mindim < 0 || val < minval)
        {
            mindim = i;
            minval = val;
        }
    }
    if(!(n[R[mindim]]%minval) && !(n[C[mindim]]%minval)) n.div(minval);
    while(!((n.x|n.y|n.z)&1)) n.shr(1);
}

// [rotation][dimension]
vec orientation_tangent [6][3] =
{
    { vec(0,  1,  0), vec( 1, 0,  0), vec( 1,  0, 0) },
    { vec(0,  0, -1), vec( 0, 0, -1), vec( 0,  1, 0) },
    { vec(0, -1,  0), vec(-1, 0,  0), vec(-1,  0, 0) },
    { vec(0,  0,  1), vec( 0, 0,  1), vec( 0, -1, 0) },
    { vec(0, -1,  0), vec(-1, 0,  0), vec(-1,  0, 0) },
    { vec(0,  1,  0), vec( 1, 0,  0), vec( 1,  0, 0) },
};
vec orientation_binormal[6][3] =
{
    { vec(0,  0, -1), vec( 0, 0, -1), vec( 0,  1, 0) },
    { vec(0, -1,  0), vec(-1, 0,  0), vec(-1,  0, 0) },
    { vec(0,  0,  1), vec( 0, 0,  1), vec( 0, -1, 0) },
    { vec(0,  1,  0), vec( 1, 0,  0), vec( 1,  0, 0) },
    { vec(0,  0, -1), vec( 0, 0, -1), vec( 0,  1, 0) },
    { vec(0,  0,  1), vec( 0, 0,  1), vec( 0, -1, 0) },
};

void addtris(const sortkey &key, int orient, vertex verts[4], int index[4], int shadowmask, int tj)
{
    int &total = key.tex==DEFAULT_SKY ? vc.skytris : vc.worldtris;
    loopi(2) if(index[0]!=index[i+1] && index[i+1]!=index[i+2] && index[i+2]!=index[0])
    {
        vector<ushort> &idxs = key.tex==DEFAULT_SKY ? vc.explicitskyindices : vc.indices[key].tris[(shadowmask>>i)&1];
        int left = index[2*i], mid = index[2*i + 1], right = index[(2*i + 2)%4];
        loopj(2)
        {
            int e1 = 2*i + j, edge = orient*4 + e1;
            if(tj < 0 || tjoints[tj].edge > edge) continue;
            int e2 = (e1 + 1)%4;
            vertex &v1 = verts[e1], &v2 = verts[e2];
            ivec d(vec(v2.pos).sub(v1.pos).mul(8));
            int axis = abs(d.x) > abs(d.y) ? (abs(d.x) > abs(d.z) ? 0 : 2) : (abs(d.y) > abs(d.z) ? 1 : 2);
            if(d[axis] < 0) d.neg();
            reduceslope(d);
            int origin = int(min(v1.pos[axis], v2.pos[axis])*8)&~0x7FFF,
                offset1 = (int(v1.pos[axis]*8) - origin) / d[axis], 
                offset2 = (int(v2.pos[axis]*8) - origin) / d[axis];
            vec o = vec(v1.pos).sub(d.tovec().mul(offset1/8.0f));
            float doffset = 1.0f / (offset2 - offset1);

            if(j)
            {
                int tmp = right;
                right = left;
                left = mid;
                mid = tmp;
            }

            while(tj >= 0)
            {
                tjoint &t = tjoints[tj];
                if(t.edge != edge) break;
                float offset = (t.offset - offset1) * doffset;
                vertex vt;
                vt.pos = d.tovec().mul(t.offset/8.0f).add(o);
                vt.reserved = 0;
                vt.u = v1.u + (v2.u-v1.u)*offset;
                vt.v = v1.v + (v2.v-v1.v)*offset;
                vt.lmu = short(v1.lmu + (v2.lmu-v1.lmu)*offset),
                vt.lmv = short(v1.lmv + (v2.lmv-v1.lmv)*offset);
                vt.norm.lerp(v1.norm, v2.norm, offset);
                vt.tangent.lerp(v1.tangent, v2.tangent, offset);
                vt.bitangent = v1.bitangent;
                int nextindex = vc.addvert(vt);
                if(nextindex < 0 || total + 3 > USHRT_MAX) return;
                total += 3;
                idxs.add(right);
                idxs.add(left);
                idxs.add(nextindex);
                tj = t.next;
                left = nextindex;
            }
        }

        if(total + 3 > USHRT_MAX) return;
        total += 3;
        idxs.add(right);
        idxs.add(left);
        idxs.add(mid);
    }
}

void addgrasstri(int face, vertex *verts, int numv, ushort texture, ushort lmid)
{
    grasstri &g = vc.grasstris.add();
    int i1 = 2*face, i2 = i1+1, i3 = (i1+2)%4;
    g.v[0] = verts[i1].pos;
    g.v[1] = verts[i2].pos;
    g.v[2] = verts[i3].pos;
    if(numv>3) g.v[3] = verts[3].pos;
    g.numv = numv;

    g.surface.toplane(g.v[0], g.v[1], g.v[2]);
    if(g.surface.z <= 0) { vc.grasstris.pop(); return; }

    loopi(numv)
    {
        vec edir = g.v[(i+1)%numv];
        edir.sub(g.v[i]);
        g.e[i].cross(g.surface, edir).normalize();
        g.e[i].offset = -g.e[i].dot(g.v[i]);
    }

    g.center = vec(0, 0, 0);
    loopk(numv) g.center.add(g.v[k]);
    g.center.div(numv);
    g.radius = 0;
    loopk(numv) g.radius = max(g.radius, g.v[k].dist(g.center));

    vec area, bx, by;
    area.cross(vec(g.v[1]).sub(g.v[0]), vec(g.v[2]).sub(g.v[0]));
    float scale;
    int px, py;

    if(fabs(area.x) >= fabs(area.y) && fabs(area.x) >= fabs(area.z))
        scale = 1/area.x, px = 1, py = 2;
    else if(fabs(area.y) >= fabs(area.x) && fabs(area.y) >= fabs(area.z))
        scale = -1/area.y, px = 0, py = 2;
    else
        scale = 1/area.z, px = 0, py = 1;

    bx.x = (g.v[2][py] - g.v[0][py])*scale;
    bx.y = (g.v[2][px] - g.v[0][px])*scale;
    bx.z = bx.x*g.v[2][px] - bx.y*g.v[2][py];

    by.x = (g.v[2][py] - g.v[1][py])*scale;
    by.y = (g.v[2][px] - g.v[1][px])*scale;
    by.z = by.x*g.v[1][px] - by.y*g.v[1][py] - 1;
    by.sub(bx);

    float tc1u = verts[i1].lmu/float(SHRT_MAX),
          tc1v = verts[i1].lmv/float(SHRT_MAX),
          tc2u = (verts[i2].lmu - verts[i1].lmu)/float(SHRT_MAX),
          tc2v = (verts[i2].lmv - verts[i1].lmv)/float(SHRT_MAX),
          tc3u = (verts[i3].lmu - verts[i1].lmu)/float(SHRT_MAX),
          tc3v = (verts[i3].lmv - verts[i1].lmv)/float(SHRT_MAX);
        
    g.tcu = vec4(0, 0, 0, tc1u - (bx.z*tc2u + by.z*tc3u));
    g.tcu[px] = bx.x*tc2u + by.x*tc3u;
    g.tcu[py] = -(bx.y*tc2u + by.y*tc3u);

    g.tcv = vec4(0, 0, 0, tc1v - (bx.z*tc2v + by.z*tc3v));
    g.tcv[px] = bx.x*tc2v + by.x*tc3v;
    g.tcv[py] = -(bx.y*tc2v + by.y*tc3v);

    g.texture = texture;
    g.lmid = lmid;
}

static inline void calctexgen(VSlot &vslot, int dim, vec4 &sgen, vec4 &tgen)
{
    Texture *tex = vslot.slot->sts.empty() ? notexture : vslot.slot->sts[0].t;
    float k = TEX_SCALE/vslot.scale,
          xs = vslot.rotation>=2 && vslot.rotation<=4 ? -tex->xs : tex->xs,
          ys = (vslot.rotation>=1 && vslot.rotation<=2) || vslot.rotation==5 ? -tex->ys : tex->ys,
          sk = k/xs, tk = k/ys,
          soff = -((vslot.rotation&5)==1 ? vslot.yoffset : vslot.xoffset)/xs,
          toff = -((vslot.rotation&5)==1 ? vslot.xoffset : vslot.yoffset)/ys;
    static const int si[] = { 1, 0, 0 }, ti[] = { 2, 2, 1 };
    int sdim = si[dim], tdim = ti[dim];
    sgen = vec4(0, 0, 0, soff); 
    tgen = vec4(0, 0, 0, toff);
    if((vslot.rotation&5)==1)
    {
        sgen[tdim] = (dim <= 1 ? -sk : sk);
        tgen[sdim] = tk;
    }
    else
    {
        sgen[sdim] = sk;
        tgen[tdim] = (dim <= 1 ? -tk : tk);
    }
}
 
void addcubeverts(VSlot &vslot, int orient, int size, vec *pos, ushort texture, surfaceinfo *surface, surfacenormals *normals, int tj = -1, ushort envmap = EMID_NONE, int grassy = 0, bool alpha = false)
{
    int dim = dimension(orient);
    int index[4];
    int shadowmask = texture==DEFAULT_SKY || alpha ? 0 : calcshadowmask(pos);
    LightMap *lm = NULL;
    LightMapTexture *lmtex = NULL;
    if(!GETIV(nolights) && surface && lightmaps.inrange(surface->lmid-LMID_RESERVED))
    {
        lm = &lightmaps[surface->lmid-LMID_RESERVED];
        if((lm->type&LM_TYPE)==LM_DIFFUSE ||
            ((lm->type&LM_TYPE)==LM_BUMPMAP0 &&
                lightmaps.inrange(surface->lmid+1-LMID_RESERVED) &&
                (lightmaps[surface->lmid+1-LMID_RESERVED].type&LM_TYPE)==LM_BUMPMAP1))
            lmtex = &lightmaptexs[lm->tex];
        else lm = NULL;
    }
    vec4 sgen, tgen;
    calctexgen(vslot, dim, sgen, tgen);
    vertex verts[4];
    loopk(4)
    {
        vertex &v = verts[k];
        v.pos = pos[k];
        v.reserved = 0;
        v.u = sgen.dot(v.pos);
        v.v = tgen.dot(v.pos);
        if(lmtex)
        {
            v.lmu = short(ceil((lm->offsetx + surface->x + (surface->texcoords[k*2] / 255.0f) * (surface->w - 1) + 0.5f) * SHRT_MAX/lmtex->w));
            v.lmv = short(ceil((lm->offsety + surface->y + (surface->texcoords[k*2 + 1] / 255.0f) * (surface->h - 1) + 0.5f) * SHRT_MAX/lmtex->h));
        }
        else v.lmu = v.lmv = 0;
        if(GETIV(renderpath)!=R_FIXEDFUNCTION && normals)
        {
            v.norm = normals->normals[k];
            vec n = normals->normals[k].tovec(), t = orientation_tangent[vslot.rotation][dim];
            t.sub(vec(n).mul(n.dot(t))).normalize();
            v.tangent = bvec(t);
            v.bitangent = vec().cross(n, t).dot(orientation_binormal[vslot.rotation][dim]) < 0 ? 0 : 255;
        }
        else
        {
            v.norm = normals && envmap != EMID_NONE ? normals->normals[k] : bvec(128, 128, 128);
            v.tangent = bvec(128, 128, 128);
            v.bitangent = 128;
        }
        index[k] = vc.addvert(v);
        if(index[k] < 0) return;
    }

    if(texture == DEFAULT_SKY)
    {
        loopk(4) vc.skyclip = min(vc.skyclip, int(pos[k].z*8)>>3);
        vc.skyfaces |= 0x3F&~(1<<orient);
    }

    int lmid = LMID_AMBIENT;
    if(surface)
    {
        if(surface->lmid < LMID_RESERVED) lmid = surface->lmid;
        else if(lm) lmid = lm->tex;
    }

    sortkey key(texture, lmid, vslot.scrollS || vslot.scrollT ? dim : 3, surface ? surface->layer&LAYER_BLEND : LAYER_TOP, envmap, alpha ? (vslot.alphaback ? ALPHA_BACK : (vslot.alphafront ? ALPHA_FRONT : NO_ALPHA)) : NO_ALPHA);
    addtris(key, orient, verts, index, shadowmask, tj);

    if(grassy) 
    {
        int faces = 0;
        loopi(2) if(index[0]!=index[i+1] && index[i+1]!=index[i+2] && index[i+2]!=index[0]) faces |= 1<<i;
        if(grassy>1 && faces==3) addgrasstri(0, verts, 4, texture, lmid);
        else loopi(2) if(faces&(1<<i)) addgrasstri(i, verts, 3, texture, lmid);
    }
}

struct edgegroup
{
    ivec slope, origin;
    int axis;
};

static uint hthash(const edgegroup &g)
{
    return g.slope.x^g.slope.y^g.slope.z^g.origin.x^g.origin.y^g.origin.z;
}

static bool htcmp(const edgegroup &x, const edgegroup &y) 
{ 
    return x.slope==y.slope && x.origin==y.origin;
}

enum
{
    CE_START = 1<<0,
    CE_END   = 1<<1,
    CE_FLIP  = 1<<2,
    CE_DUP   = 1<<3
};

struct cubeedge
{
    cube *c;
    int next, offset;
    ushort size;
    uchar index, flags;
};

vector<cubeedge> cubeedges;
hashtable<edgegroup, int> edgegroups(1<<13);

void gencubeedges(cube &c, int x, int y, int z, int size)
{
    ivec pos[4];
    int mergeindex = 0, vis;
    loopi(6) if((vis = visibletris(c, i, x, y, z, size)))
    {
        if(c.ext && c.ext->merged&(1<<i))
        {
            if(!(c.ext->mergeorigin&(1<<i))) continue;

            const mergeinfo &m = c.ext->merges[mergeindex++];
            vec mv[4];
            genmergedverts(c, i, ivec(x, y, z), size, m, mv);
            loopj(4) pos[j] = ivec(mv[j].mul(8));
        } 
        else 
        {
            int order = vis&4 || faceconvexity(c, i)<0 ? 1 : 0;
            loopj(4)
            {
                int k = fv[i][(j+order)&3];
                if(isentirelysolid(c)) pos[j] = cubecoords[k];
                else genvectorvert(cubecoords[k], c, pos[j]);
                pos[j].mul(size).add(ivec(x, y, z).shl(3));
            }
            if(!(vis&1)) pos[1] = pos[0];
            if(!(vis&2)) pos[3] = pos[0];
        }
        loopj(4)
        {
            int e1 = j, e2 = (j+1)%4;
            ivec d = pos[e2];
            d.sub(pos[e1]);
            if(d.iszero()) continue;
            int axis = abs(d.x) > abs(d.y) ? (abs(d.x) > abs(d.z) ? 0 : 2) : (abs(d.y) > abs(d.z) ? 1 : 2);
            if(d[axis] < 0)
            {
                d.neg();
                swap(e1, e2);
            }
            reduceslope(d);

            int t1 = pos[e1][axis]/d[axis],
                t2 = pos[e2][axis]/d[axis];
            edgegroup g;
            g.origin = ivec(pos[e1]).sub(ivec(d).mul(t1));
            g.slope = d;
            g.axis = axis;
            cubeedge ce;
            ce.c = &c;
            ce.offset = t1;
            ce.size = t2 - t1;
            ce.index = i*4+j;
            ce.flags = CE_START | CE_END | (e1!=j ? CE_FLIP : 0);
            ce.next = -1;

            bool insert = true;
            int *exists = edgegroups.access(g);
            if(exists)
            {
                int prev = -1, cur = *exists;
                while(cur >= 0)
                {
                    cubeedge &p = cubeedges[cur];
                    if(p.flags&CE_DUP ? 
                        ce.offset>=p.offset && ce.offset+ce.size<=p.offset+p.size : 
                        ce.offset==p.offset && ce.size==p.size)
                    {
                        p.flags |= CE_DUP;
                        insert = false;
                        break;
                    }
                    else if(ce.offset >= p.offset)
                    {
                        if(ce.offset == p.offset+p.size) ce.flags &= ~CE_START;
                        prev = cur;
                        cur = p.next;
                    }
                    else break;
                }
                if(insert)
                {
                    ce.next = cur;
                    while(cur >= 0)
                    {
                        cubeedge &p = cubeedges[cur];
                        if(ce.offset+ce.size==p.offset) { ce.flags &= ~CE_END; break; }
                        cur = p.next;
                    }
                    if(prev>=0) cubeedges[prev].next = cubeedges.length();
                    else *exists = cubeedges.length();
                }
            }
            else edgegroups[g] = cubeedges.length();

            if(insert) cubeedges.add(ce);
        }
    }
}

void gencubeedges(cube *c = worldroot, int x = 0, int y = 0, int z = 0, int size = GETIV(mapsize)>>1)
{
    progress("fixing t-joints...");
    neighbourstack[++neighbourdepth] = c;
    loopi(8)
    {
        ivec o(i, x, y, z, size);
        if(c[i].ext) c[i].ext->tjoints = -1;
        if(c[i].children) gencubeedges(c[i].children, o.x, o.y, o.z, size>>1);
        else if(!isempty(c[i])) gencubeedges(c[i], o.x, o.y, o.z, size);
    }
    --neighbourdepth;
}

void gencubeverts(cube &c, int x, int y, int z, int size, int csi, uchar &vismask, uchar &clipmask)
{
    freeclipplanes(c);                          // physics planes based on rendering
    if(c.ext) c.ext->visible = 0;

    int tj = c.ext ? c.ext->tjoints : -1, numblends = 0, vis;
    loopi(6) if((vis = visibletris(c, i, x, y, z, size)))
    {
        if(c.texture[i]!=DEFAULT_SKY) vismask |= 1<<i;

        cubeext &e = ext(c);

        // this is necessary for physics to work, even if the face is merged
        if(touchingface(c, i)) 
        {
            e.visible |= 1<<i;
            if(c.texture[i]!=DEFAULT_SKY && faceedges(c, i)==F_SOLID) clipmask |= 1<<i;
        }

        if(e.surfaces && e.surfaces[i].layer&LAYER_BLEND) numblends++; 

        if(e.merged&(1<<i)) continue;

        int order = vis&4 || faceconvexity(c, i)<0 ? 1 : 0;
        vec pos[4];
        loopk(4) calcvert(c, x, y, z, size, pos[k], fv[i][(k+order)&3]);
        if(!(vis&1)) pos[1] = pos[0];
        if(!(vis&2)) pos[3] = pos[0];

        VSlot &vslot = lookupvslot(c.texture[i], true),
              *layer = vslot.layer && !(c.ext && c.ext->material&MAT_ALPHA) ? &lookupvslot(vslot.layer, true) : NULL;
        ushort envmap = vslot.slot->shader->type&SHADER_ENVMAP ? (vslot.slot->texmask&(1<<TEX_ENVMAP) ? EMID_CUSTOM : closestenvmap(i, x, y, z, size)) : EMID_NONE,
               envmap2 = layer && layer->slot->shader->type&SHADER_ENVMAP ? (layer->slot->texmask&(1<<TEX_ENVMAP) ? EMID_CUSTOM : closestenvmap(i, x, y, z, size)) : EMID_NONE;
        while(tj >= 0 && tjoints[tj].edge < i*4) tj = tjoints[tj].next;
        int hastj = tj >= 0 && tjoints[tj].edge/4 == i ? tj : -1;
        int grassy = vslot.slot->autograss && i!=O_BOTTOM ? (vis!=3 || faceconvexity(c, i) ? 1 : 2) : 0;
        if(!e.surfaces || e.surfaces[i].layer!=LAYER_BOTTOM)
            addcubeverts(vslot, i, size, pos, c.texture[i], e.surfaces ? &e.surfaces[i] : NULL, e.normals ? &e.normals[i] : NULL, hastj, envmap, grassy, c.ext && c.ext->material&MAT_ALPHA);
        if(e.surfaces && e.surfaces[i].layer!=LAYER_TOP)
            addcubeverts(layer ? *layer : vslot, i, size, pos, vslot.layer, &e.surfaces[e.surfaces[i].layer&LAYER_BLEND ? 5+numblends : i], e.normals ? &e.normals[i] : NULL, hastj, envmap2);
    }
    else if(touchingface(c, i))
    {
        if(visibleface(c, i, x, y, z, size, MAT_AIR, MAT_NOCLIP, MATF_CLIP)) ext(c).visible |= 1<<i;
        if(faceedges(c, i)==F_SOLID) clipmask |= 1<<i;
    }
}

bool skyoccluded(cube &c, int orient)
{
    if(isempty(c)) return false;
//    if(c.texture[orient] == DEFAULT_SKY) return true;
    if(touchingface(c, orient) && faceedges(c, orient) == F_SOLID && !(c.ext && c.ext->material&MAT_ALPHA)) return true;
    return false;
}

int hasskyfaces(cube &c, int x, int y, int z, int size, int faces[6])
{
    int numfaces = 0;
    if(x == 0 && !skyoccluded(c, O_LEFT)) faces[numfaces++] = O_LEFT;
    if(x + size == GETIV(mapsize) && !skyoccluded(c, O_RIGHT)) faces[numfaces++] = O_RIGHT;
    if(y == 0 && !skyoccluded(c, O_BACK)) faces[numfaces++] = O_BACK;
    if(y + size == GETIV(mapsize) && !skyoccluded(c, O_FRONT)) faces[numfaces++] = O_FRONT;
    if(z == 0 && !skyoccluded(c, O_BOTTOM)) faces[numfaces++] = O_BOTTOM;
    if(z + size == GETIV(mapsize) && !skyoccluded(c, O_TOP)) faces[numfaces++] = O_TOP;
    return numfaces;
}

vector<cubeface> skyfaces[6];
 
void minskyface(cube &cu, int orient, const ivec &co, int size, mergeinfo &orig)
{   
    mergeinfo mincf;
    mincf.u1 = orig.u2;
    mincf.u2 = orig.u1;
    mincf.v1 = orig.v2;
    mincf.v2 = orig.v1;
    mincubeface(cu, orient, co, size, orig, mincf, MAT_ALPHA, MAT_ALPHA);
    orig.u1 = max(mincf.u1, orig.u1);
    orig.u2 = min(mincf.u2, orig.u2);
    orig.v1 = max(mincf.v1, orig.v1);
    orig.v2 = min(mincf.v2, orig.v2);
}  

void genskyfaces(cube &c, const ivec &o, int size)
{
    if(isentirelysolid(c) && !(c.ext && c.ext->material&MAT_ALPHA)) return;

    int faces[6],
        numfaces = hasskyfaces(c, o.x, o.y, o.z, size, faces);
    if(!numfaces) return;

    loopi(numfaces)
    {
        int orient = faces[i], dim = dimension(orient);
        cubeface m;
        m.c = NULL;
        m.u1 = (o[C[dim]]&0xFFF)<<3; 
        m.u2 = m.u1 + (size<<3);
        m.v1 = (o[R[dim]]&0xFFF)<<3;
        m.v2 = m.v1 + (size<<3);
        minskyface(c, orient, o, size, m);
        if(m.u1 >= m.u2 || m.v1 >= m.v2) continue;
        vc.skyarea += (int(m.u2-m.u1)*int(m.v2-m.v1) + (1<<(2*3))-1)>>(2*3);
        skyfaces[orient].add(m);
    }
}

void addskyverts(const ivec &o, int size)
{
    loopi(6)
    {
        int dim = dimension(i), c = C[dim], r = R[dim];
        vector<cubeface> &sf = skyfaces[i]; 
        if(sf.empty()) continue;
        vc.skyfaces |= 0x3F&~(1<<opposite(i));
        sf.setsize(mergefaces(i, sf.getbuf(), sf.length()));
        loopvj(sf)
        {
            mergeinfo &m = sf[j];
            int index[4];
            loopk(4)
            {
                const ivec &coords = cubecoords[fv[i][3-k]];
                vec v;
                v[dim] = o[dim];
                if(coords[dim]) v[dim] += size;
                v[c] = (o[c]&~0xFFF) + (coords[c] ? m.u2 : m.u1)/8.0f;
                v[r] = (o[r]&~0xFFF) + (coords[r] ? m.v2 : m.v1)/8.0f;
                index[k] = vc.addvert(v);
                if(index[k] < 0) goto nextskyface;
                vc.skyclip = min(vc.skyclip, int(v.z*8)>>3);
            }
            if(vc.skytris + 6 > USHRT_MAX) break;
            vc.skytris += 6;
            vc.skyindices.add(index[0]);
            vc.skyindices.add(index[1]);
            vc.skyindices.add(index[2]);

            vc.skyindices.add(index[0]);
            vc.skyindices.add(index[2]);
            vc.skyindices.add(index[3]);
        nextskyface:;
        }
        sf.setsize(0);
    }
}
                    
////////// Vertex Arrays //////////////

int allocva = 0;
int wtris = 0, wverts = 0, vtris = 0, vverts = 0, glde = 0, gbatches = 0;
vector<vtxarray *> valist, varoot;

vtxarray *newva(int x, int y, int z, int size)
{
    vc.optimize();

    vtxarray *va = new vtxarray;
    va->parent = NULL;
    va->o = ivec(x, y, z);
    va->size = size;
    va->skyarea = vc.skyarea;
    va->skyfaces = vc.skyfaces;
    va->skyclip = vc.skyclip < INT_MAX ? vc.skyclip : INT_MAX;
    va->curvfc = VFC_NOT_VISIBLE;
    va->occluded = OCCLUDE_NOTHING;
    va->query = NULL;
    va->bbmin = ivec(-1, -1, -1);
    va->bbmax = ivec(-1, -1, -1);
    va->hasmerges = 0;

    vc.setupdata(va);

    wverts += va->verts;
    wtris  += va->tris + va->blends + va->alphabacktris + va->alphafronttris;
    allocva++;
    valist.add(va);

    return va;
}

void destroyva(vtxarray *va, bool reparent)
{
    wverts -= va->verts;
    wtris -= va->tris + va->blends + va->alphabacktris + va->alphafronttris;
    allocva--;
    valist.removeobj(va);
    if(!va->parent) varoot.removeobj(va);
    if(reparent)
    {
        if(va->parent) va->parent->children.removeobj(va);
        loopv(va->children)
        {
            vtxarray *child = va->children[i];
            child->parent = va->parent;
            if(child->parent) child->parent->children.add(child);
        }
    }
    if(va->vbuf) destroyvbo(va->vbuf);
    if(va->ebuf) destroyvbo(va->ebuf);
    if(va->skybuf) destroyvbo(va->skybuf);
    if(va->eslist) delete[] va->eslist;
    if(va->matbuf) delete[] va->matbuf;
    delete va;
}

void clearvas(cube *c)
{
    loopi(8)
    {
        if(c[i].ext)
        {
            if(c[i].ext->va) destroyva(c[i].ext->va, false);
            c[i].ext->va = NULL;
            c[i].ext->tjoints = -1;
        }
        if(c[i].children) clearvas(c[i].children);
    }
}

void updatevabb(vtxarray *va, bool force)
{
    if(!force && va->bbmin.x >= 0) return;

    va->bbmin = va->geommin;
    va->bbmax = va->geommax;
    loopk(3)
    {
        va->bbmin[k] = min(va->bbmin[k], va->matmin[k]);
        va->bbmax[k] = max(va->bbmax[k], va->matmax[k]);
    }
    loopv(va->children)
    {
        vtxarray *child = va->children[i];
        updatevabb(child, force);
        loopk(3)
        {
            va->bbmin[k] = min(va->bbmin[k], child->bbmin[k]);
            va->bbmax[k] = max(va->bbmax[k], child->bbmax[k]);
        }
    }
    loopv(va->mapmodels)
    {
        octaentities *oe = va->mapmodels[i];
        loopk(3)
        {
            va->bbmin[k] = min(va->bbmin[k], oe->bbmin[k]);
            va->bbmax[k] = max(va->bbmax[k], oe->bbmax[k]);
        }
    }

    if(va->skyfaces)
    {
        va->skyfaces |= 0x80;
        if(va->sky) loop(dim, 3) if(va->skyfaces&(3<<(2*dim)))
        {
            int r = R[dim], c = C[dim];
            if((va->skyfaces&(1<<(2*dim)) && va->o[dim] < va->bbmin[dim]) ||
               (va->skyfaces&(2<<(2*dim)) && va->o[dim]+va->size > va->bbmax[dim]) ||
               va->o[r] < va->bbmin[r] || va->o[r]+va->size > va->bbmax[r] ||
               va->o[c] < va->bbmin[c] || va->o[c]+va->size > va->bbmax[c])
            {
                va->skyfaces &= ~0x80;
                break;
            }
        }
    }
}

void updatevabbs(bool force)
{
    loopv(varoot) updatevabb(varoot[i], force);
}

struct mergedface
{   
    uchar orient, mat;
    ushort tex, envmap;
    vec v[4];
    surfaceinfo *surface;
    surfacenormals *normals;
    int tjoints;
};  

static int vahasmerges = 0, vamergemax = 0;
static vector<mergedface> vamerges[13];

void genmergedfaces(cube &c, const ivec &co, int size, int minlevel = -1)
{
    if(!c.ext || !c.ext->merges || isempty(c)) return;
    int index = 0, tj = c.ext->tjoints, numblends = 0;
    loopi(6) 
    {
        if(c.ext->surfaces && c.ext->surfaces[i].layer&LAYER_BLEND) numblends++;
        if(!(c.ext->mergeorigin & (1<<i))) continue;
        mergeinfo &m = c.ext->merges[index++];
        if(m.u1>=m.u2 || m.v1>=m.v2) continue;
        mergedface mf;
        mf.orient = i;
        mf.mat = c.ext ? c.ext->material : MAT_AIR;
        mf.tex = c.texture[i];
        mf.envmap = EMID_NONE;
        mf.surface = c.ext->surfaces ? &c.ext->surfaces[i] : NULL;
        mf.normals = c.ext->normals ? &c.ext->normals[i] : NULL;
        mf.tjoints = -1;
        genmergedverts(c, i, co, size, m, mf.v);
        int level = calcmergedsize(i, co, size, m, mf.v);
        if(level > minlevel)
        {
            while(tj >= 0 && tjoints[tj].edge < i*4) tj = tjoints[tj].next;
            if(tj >= 0 && tjoints[tj].edge/4 == i) mf.tjoints = tj;

            VSlot &vslot = lookupvslot(mf.tex, true),
                  *layer = vslot.layer && !(c.ext && c.ext->material&MAT_ALPHA) ? &lookupvslot(vslot.layer, true) : NULL;
            if(vslot.slot->shader->type&SHADER_ENVMAP)
                mf.envmap = vslot.slot->texmask&(1<<TEX_ENVMAP) ? EMID_CUSTOM : closestenvmap(i, co.x, co.y, co.z, size);
            ushort envmap2 = layer && layer->slot->shader->type&SHADER_ENVMAP ? (layer->slot->texmask&(1<<TEX_ENVMAP) ? EMID_CUSTOM : closestenvmap(i, co.x, co.y, co.z, size)) : EMID_NONE;

            if(c.ext->surfaces)
            {
                if(c.ext->surfaces[i].layer&LAYER_BLEND)
                {
                    mergedface mf2 = mf;
                    mf2.tex = vslot.layer;
                    mf2.envmap = envmap2;
                    mf2.surface = &c.ext->surfaces[5+numblends];
                    vamerges[level].add(mf2);
                }
                else if(c.ext->surfaces[i].layer==LAYER_BOTTOM)
                {
                    mf.tex = vslot.layer;
                    mf.envmap = envmap2;
                }
            } 

            vamerges[level].add(mf);
            vamergemax = max(vamergemax, level);
            vahasmerges |= MERGE_ORIGIN;
        }
    }
}

void findmergedfaces(cube &c, const ivec &co, int size, int csi, int minlevel)
{
    if(c.ext && c.ext->va && !(c.ext->va->hasmerges&MERGE_ORIGIN)) return;
    if(c.children)
    {
        loopi(8)
        {
            ivec o(i, co.x, co.y, co.z, size/2); 
            findmergedfaces(c.children[i], o, size/2, csi-1, minlevel);
        }
    }
    else if(c.ext && c.ext->merges) genmergedfaces(c, co, size, minlevel);
}

void addmergedverts(int level)
{
    vector<mergedface> &mfl = vamerges[level];
    if(mfl.empty()) return;
    loopv(mfl)
    {
        mergedface &mf = mfl[i];
        VSlot &vslot = lookupvslot(mf.tex, true);
        int grassy = vslot.slot->autograss && mf.orient!=O_BOTTOM && (!mf.surface || mf.surface->layer!=LAYER_BOTTOM) ? 2 : 0;
        addcubeverts(vslot, mf.orient, 1<<level, mf.v, mf.tex, mf.surface, mf.normals, mf.tjoints, mf.envmap, grassy, (mf.mat&MAT_ALPHA)!=0);
        vahasmerges |= MERGE_USE;
    }
    mfl.setsize(0);
}

static uchar unusedmask;

void rendercube(cube &c, int cx, int cy, int cz, int size, int csi, uchar &vismask = unusedmask, uchar &clipmask = unusedmask)  // creates vertices and indices ready to be put into a va
{
    //if(size<=16) return;
    if(c.ext && c.ext->va) 
    {
        vismask = c.children ? c.vismask : 0x3F;
        clipmask = c.children ? c.clipmask : 0;
        return;                            // don't re-render
    }

    if(c.children)
    {
        uchar visparent = 0, clipparent = 0x3F;
        uchar clipchild[8];
        neighbourstack[++neighbourdepth] = c.children;
        loopi(8)
        {
            ivec o(i, cx, cy, cz, size/2);
            rendercube(c.children[i], o.x, o.y, o.z, size/2, csi-1, c.vismasks[i], clipchild[i]);
            uchar mask = (1<<octacoord(0, i)) | (4<<octacoord(1, i)) | (16<<octacoord(2, i));
            visparent |= c.vismasks[i];
            clipparent &= (clipchild[i]&mask) | ~mask;
            clipparent &= ~(c.vismasks[i] & (mask^0x3F));
        }
        --neighbourdepth;
        vismask = c.vismask = visparent;
        clipmask = c.clipmask = clipparent;

        if(csi < int(sizeof(vamerges)/sizeof(vamerges[0])) && vamerges[csi].length()) addmergedverts(csi);

        if(c.ext)
        {
            if(c.ext->ents && c.ext->ents->mapmodels.length()) vc.mapmodels.add(c.ext->ents);
        }
        return;
    }
    
    genskyfaces(c, ivec(cx, cy, cz), size);

    vismask = clipmask = 0;

    if(!isempty(c)) gencubeverts(c, cx, cy, cz, size, csi, vismask, clipmask);

    if(c.ext)
    {
        if(c.ext->ents && c.ext->ents->mapmodels.length()) vc.mapmodels.add(c.ext->ents);
        if(c.ext->material != MAT_AIR) genmatsurfs(c, cx, cy, cz, size, vc.matsurfs, vismask, clipmask);
        if(c.ext->merges) genmergedfaces(c, ivec(cx, cy, cz), size);
        if(c.ext->merged & ~c.ext->mergeorigin) vahasmerges |= MERGE_PART;
    }

    if(csi < int(sizeof(vamerges)/sizeof(vamerges[0])) && vamerges[csi].length()) addmergedverts(csi);
}

void calcgeombb(int cx, int cy, int cz, int size, ivec &bbmin, ivec &bbmax)
{
    vec vmin(cx, cy, cz), vmax = vmin;
    vmin.add(size);

    loopv(vc.verts)
    {
        const vec &v = vc.verts[i].pos;
        loopj(3)
        {
            if(v[j]<vmin[j]) vmin[j] = v[j];
            if(v[j]>vmax[j]) vmax[j] = v[j];
        }
    }

    bbmin = ivec(vmin.mul(8)).shr(3);
    bbmax = ivec(vmax.mul(8)).add(7).shr(3);
}

void calcmatbb(int cx, int cy, int cz, int size, ivec &bbmin, ivec &bbmax)
{
    bbmax = ivec(cx, cy, cz);
    (bbmin = bbmax).add(size);
    loopv(vc.matsurfs)
    {
        materialsurface &m = vc.matsurfs[i];
        switch(m.material)
        {
            case MAT_WATER:
            case MAT_GLASS:
            case MAT_LAVA:
                break;

            default:
                continue;
        }

        int dim = dimension(m.orient),
            r = R[dim],
            c = C[dim];
        bbmin[dim] = min(bbmin[dim], m.o[dim]);
        bbmax[dim] = max(bbmax[dim], m.o[dim]);

        bbmin[r] = min(bbmin[r], m.o[r]);
        bbmax[r] = max(bbmax[r], m.o[r] + m.rsize);

        bbmin[c] = min(bbmin[c], m.o[c]);
        bbmax[c] = max(bbmax[c], m.o[c] + m.csize);
    }
}

void setva(cube &c, int cx, int cy, int cz, int size, int csi)
{
    ASSERT(size <= 0x1000);

    int vamergeoffset[sizeof(vamerges)/sizeof(vamerges[0])];
    loopi(sizeof(vamerges)/sizeof(vamerges[0])) vamergeoffset[i] = vamerges[i].length();

    vc.origin = ivec(cx, cy, cz);
    vc.size = size;

    shadowmapmin = vec(cx+size, cy+size, cz+size);
    shadowmapmax = vec(cx, cy, cz);

    rendercube(c, cx, cy, cz, size, csi);

    ivec bbmin, bbmax;

    calcgeombb(cx, cy, cz, size, bbmin, bbmax);

    addskyverts(ivec(cx, cy, cz), size);

    if(!vc.emptyva())
    {
        vtxarray *va = newva(cx, cy, cz, size);
        ext(c).va = va;
        va->geommin = bbmin;
        va->geommax = bbmax;
        calcmatbb(cx, cy, cz, size, va->matmin, va->matmax);
        va->shadowmapmin = ivec(shadowmapmin.mul(8)).shr(3);
        va->shadowmapmax = ivec(shadowmapmax.mul(8)).add(7).shr(3);
        va->hasmerges = vahasmerges;
    }
    else
    {
        loopi(sizeof(vamerges)/sizeof(vamerges[0])) vamerges[i].setsize(vamergeoffset[i]);
    }

    vc.clear();
}

int updateva(cube *c, int cx, int cy, int cz, int size, int csi)
{
    progress("recalculating geometry...");
    static int faces[6];
    int ccount = 0, cmergemax = vamergemax, chasmerges = vahasmerges;
    neighbourstack[++neighbourdepth] = c;
    loopi(8)                                    // counting number of semi-solid/solid children cubes
    {
        int count = 0, childpos = varoot.length();
        ivec o(i, cx, cy, cz, size);
        vamergemax = 0;
        vahasmerges = 0;
        if(c[i].ext && c[i].ext->va) 
        {
            //count += vacubemax+1;       // since must already have more then max cubes
            varoot.add(c[i].ext->va);
            if(c[i].ext->va->hasmerges&MERGE_ORIGIN) findmergedfaces(c[i], o, size, csi, csi);
        }
        else
        {
            if(c[i].children) count += updateva(c[i].children, o.x, o.y, o.z, size/2, csi-1);
            else if(!isempty(c[i]) || hasskyfaces(c[i], o.x, o.y, o.z, size, faces)) count++;
            int tcount = count + (csi < int(sizeof(vamerges)/sizeof(vamerges[0])) ? vamerges[csi].length() : 0);
            if(tcount > GETIV(vacubemax) || (tcount >= GETIV(vacubemin) && size >= GETIV(vacubesize)) || size == min(0x1000, GETIV(mapsize)/2)) 
            {
                loadprogress = clamp(recalcprogress/float(allocnodes), 0.0f, 1.0f);
                setva(c[i], o.x, o.y, o.z, size, csi);
                if(c[i].ext && c[i].ext->va)
                {
                    while(varoot.length() > childpos)
                    {
                        vtxarray *child = varoot.pop();
                        c[i].ext->va->children.add(child);
                        child->parent = c[i].ext->va;
                    }
                    varoot.add(c[i].ext->va);
                    if(vamergemax > size)
                    {
                        cmergemax = max(cmergemax, vamergemax);
                        chasmerges |= vahasmerges&~MERGE_USE;
                    }
                    continue;
                }
                else count = 0;
            }
        }
        if(csi+1 < int(sizeof(vamerges)/sizeof(vamerges[0])) && vamerges[csi].length()) vamerges[csi+1].move(vamerges[csi]);
        cmergemax = max(cmergemax, vamergemax);
        chasmerges |= vahasmerges;
        ccount += count;
    }
    --neighbourdepth;
    vamergemax = cmergemax;
    vahasmerges = chasmerges;

    return ccount;
}

void buildclipmasks(cube &c, uchar &vismask = unusedmask, uchar &clipmask = unusedmask)
{
    if(c.ext && c.ext->va)
    {
        vismask = c.children ? c.vismask : 0x3F;
        clipmask = c.children ? c.clipmask : 0;
        return;
    }
    if(!c.children)
    {
        if(isempty(c)) c.vismask = c.clipmask = 0;
        vismask = clipmask = 0;
        return;
    }
    uchar visparent = 0, clipparent = 0x3F;
    uchar clipchild[8];
    loopi(8)
    {
        buildclipmasks(c.children[i], c.vismasks[i], clipchild[i]);
        uchar mask = (1<<octacoord(0, i)) | (4<<octacoord(1, i)) | (16<<octacoord(2, i));
        visparent |= c.vismasks[i];
        clipparent &= (clipchild[i]&mask) | ~mask;
        clipparent &= ~(c.vismasks[i] & (mask^0x3F));
    }
    vismask = c.vismask = visparent;
    clipmask = c.clipmask = clipparent;
}

void addtjoint(const edgegroup &g, const cubeedge &e, int offset)
{
    int vcoord = (g.slope[g.axis]*offset + g.origin[g.axis]) & 0x7FFF;
    tjoint &tj = tjoints.add();
    tj.offset = vcoord / g.slope[g.axis];
    tj.edge = e.index;

    int prev = -1, cur = ext(*e.c).tjoints;
    while(cur >= 0)
    {
        tjoint &o = tjoints[cur];
        if(tj.edge < o.edge || (tj.edge==o.edge && (e.flags&CE_FLIP ? tj.offset > o.offset : tj.offset < o.offset))) break;
        prev = cur;
        cur = o.next;
    }

    tj.next = cur;
    if(prev < 0) e.c->ext->tjoints = tjoints.length()-1;
    else tjoints[prev].next = tjoints.length()-1; 
}

void findtjoints(int cur, const edgegroup &g)
{
    int active = -1;
    while(cur >= 0)
    {
        cubeedge &e = cubeedges[cur];
        int prevactive = -1, curactive = active;
        while(curactive >= 0)
        {
            cubeedge &a = cubeedges[curactive];
            if(a.offset+a.size <= e.offset)
            {
                if(prevactive >= 0) cubeedges[prevactive].next = a.next;
                else active = a.next;
            }
            else
            {
                prevactive = curactive;
                if(!(a.flags&CE_DUP))
                {
                    if(e.flags&CE_START && e.offset > a.offset && e.offset < a.offset+a.size)
                        addtjoint(g, a, e.offset);
                    if(e.flags&CE_END && e.offset+e.size > a.offset && e.offset+e.size < a.offset+a.size)
                        addtjoint(g, a, e.offset+e.size);
                }
                if(!(e.flags&CE_DUP))
                {
                    if(a.flags&CE_START && a.offset > e.offset && a.offset < e.offset+e.size)
                        addtjoint(g, e, a.offset);
                    if(a.flags&CE_END && a.offset+a.size > e.offset && a.offset+a.size < e.offset+e.size)
                        addtjoint(g, e, a.offset+a.size);
                }
            }
            curactive = a.next;
        }
        int next = e.next;
        e.next = active;
        active = cur;
        cur = next;
    }
}

void octarender()                               // creates va s for all leaf cubes that don't already have them
{
    int csi = 0;
    while(1<<csi < GETIV(mapsize)) csi++;

    recalcprogress = 0;
    varoot.setsize(0);
    updateva(worldroot, 0, 0, 0, GETIV(mapsize)/2, csi-1);
    loadprogress = 0;
    flushvbo();

    loopi(8) buildclipmasks(worldroot[i]);

    explicitsky = 0;
    skyarea = 0;
    loopv(valist)
    {
        vtxarray *va = valist[i];
        explicitsky += va->explicitsky;
        skyarea += va->skyarea;
    }

    extern vtxarray *visibleva;
    visibleva = NULL;
}

void precachetextures()
{
#ifdef CLIENT
    IntensityTexture::resetBackgroundLoading(); // INTENSITY: see below for backgroundLoading
#endif

    vector<int> texs;
    loopv(valist)
    {
        vtxarray *va = valist[i];
        loopj(va->texs + va->blends) if(texs.find(va->eslist[j].texture) < 0) texs.add(va->eslist[j].texture);
    }
    loopv(texs)
    {
        loadprogress = float(i+1)/texs.length();
        lookupvslot(texs[i]);
    }

#ifdef CLIENT
    IntensityTexture::doBackgroundLoading(true); // INTENSITY: lookuptexture just queues, now, so here we need to flush all the requests
#endif

    loadprogress = 0;
}

void allchanged(bool load)
{
    renderprogress(0, "clearing vertex arrays...");

    PhysicsManager::clearWorldGeometry(); // New world geometry, from scratch // INTENSITY

    clearvas(worldroot);
    resetqueries();
    if(load) initenvmaps();
    guessshadowdir();
    entitiesinoctanodes();
    tjoints.setsize(0);
    if(GETIV(filltjoints))
    {
        recalcprogress = 0;
        gencubeedges();
        enumeratekt(edgegroups, edgegroup, g, int, e, findtjoints(e, g));
        cubeedges.setsize(0);
        edgegroups.clear();
    }
    octarender();
    if(load) precachetextures();
    setupmaterials();
    invalidatepostfx();
    updatevabbs(true);
    resetblobs();
    if(load) 
    {
        seedparticles();
        genenvmaps();
        drawminimap();
    }

    PhysicsManager::finalizeWorldGeometry(); // INTENSITY
}

void recalc()
{
    allchanged(true);
}

