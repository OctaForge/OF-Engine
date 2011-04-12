struct iqm;

iqm *loadingiqm = NULL;

string iqmdir;

struct iqmadjustment
{
    float yaw, pitch, roll;
    vec translate;

    iqmadjustment(float yaw, float pitch, float roll, const vec &translate) : yaw(yaw), pitch(pitch), roll(roll), translate(translate) {}
};

vector<iqmadjustment> iqmadjustments;

struct iqmheader
{
    char magic[16];
    uint version;
    uint filesize;
    uint flags;
    uint num_text, ofs_text;
    uint num_meshes, ofs_meshes;
    uint num_vertexarrays, num_vertexes, ofs_vertexarrays;
    uint num_triangles, ofs_triangles, ofs_adjacency;
    uint num_joints, ofs_joints;
    uint num_poses, ofs_poses;
    uint num_anims, ofs_anims;
    uint num_frames, num_framechannels, ofs_frames, ofs_bounds;
    uint num_comment, ofs_comment;
    uint num_extensions, ofs_extensions;
};

struct iqmmesh
{
    uint name;
    uint material;
    uint first_vertex, num_vertexes;
    uint first_triangle, num_triangles;
};

enum
{        
    IQM_POSITION     = 0,
    IQM_TEXCOORD     = 1,
    IQM_NORMAL       = 2,
    IQM_TANGENT      = 3,
    IQM_BLENDINDEXES = 4,
    IQM_BLENDWEIGHTS = 5,
    IQM_COLOR        = 6,
    IQM_CUSTOM       = 0x10
};  

enum
{
    IQM_BYTE   = 0,
    IQM_UBYTE  = 1,
    IQM_SHORT  = 2,
    IQM_USHORT = 3,
    IQM_INT    = 4,
    IQM_UINT   = 5,
    IQM_HALF   = 6,
    IQM_FLOAT  = 7,
    IQM_DOUBLE = 8,
};

struct iqmtriangle
{
    uint vertex[3];
};

struct iqmjoint
{
    uint name;
    int parent;
    vec pos, orient, size;
};

struct iqmpose
{
    int parent;
    uint mask;
    vec offsetpos, offsetorient, offsetsize;
    vec scalepos, scaleorient, scalesize;
};

struct iqmanim
{
    uint name;
    uint first_frame, num_frames;
    float framerate;
    uint flags;
};

struct iqmvertexarray
{
    uint type;
    uint flags;
    uint format;
    uint size;
    uint offset;
};

struct iqm : skelmodel
{
    iqm(const char *name) : skelmodel(name) {}

    int type() const { return MDL_IQM; }

    struct iqmmeshgroup : skelmeshgroup
    {
        iqmmeshgroup() 
        {
        }

        bool loadiqmmeshes(const char *filename, const iqmheader &hdr, uchar *buf)
        {
            lilswap((uint *)&buf[hdr.ofs_vertexarrays], hdr.num_vertexarrays*sizeof(iqmvertexarray)/sizeof(uint));
            lilswap((uint *)&buf[hdr.ofs_triangles], hdr.num_triangles*sizeof(iqmtriangle)/sizeof(uint));
            lilswap((uint *)&buf[hdr.ofs_meshes], hdr.num_meshes*sizeof(iqmmesh)/sizeof(uint));
            lilswap((uint *)&buf[hdr.ofs_joints], hdr.num_joints*sizeof(iqmjoint)/sizeof(uint));

            const char *str = hdr.ofs_text ? (char *)&buf[hdr.ofs_text] : "";
            float *vpos = NULL, *vnorm = NULL, *vtan = NULL, *vtc = NULL;
            uchar *vindex = NULL, *vweight = NULL;
            iqmvertexarray *vas = (iqmvertexarray *)&buf[hdr.ofs_vertexarrays];
            loopi(hdr.num_vertexarrays)
            {
                iqmvertexarray &va = vas[i];
                switch(va.type)
                {
                    case IQM_POSITION: if(va.format != IQM_FLOAT || va.size != 3) return false; vpos = (float *)&buf[va.offset]; lilswap(vpos, 3*hdr.num_vertexes); break;
                    case IQM_NORMAL: if(va.format != IQM_FLOAT || va.size != 3) return false; vnorm = (float *)&buf[va.offset]; lilswap(vnorm, 3*hdr.num_vertexes); break;
                    case IQM_TANGENT: if(va.format != IQM_FLOAT || va.size != 4) return false; vtan = (float *)&buf[va.offset]; lilswap(vtan, 4*hdr.num_vertexes); break;
                    case IQM_TEXCOORD: if(va.format != IQM_FLOAT || va.size != 2) return false; vtc = (float *)&buf[va.offset]; lilswap(vtc, 2*hdr.num_vertexes); break;
                    case IQM_BLENDINDEXES: if(va.format != IQM_UBYTE || va.size != 4) return false; vindex = (uchar *)&buf[va.offset]; break;
                    case IQM_BLENDWEIGHTS: if(va.format != IQM_UBYTE || va.size != 4) return false; vweight = (uchar *)&buf[va.offset]; break;
                }
            }
            iqmtriangle *tris = (iqmtriangle *)&buf[hdr.ofs_triangles];
            iqmmesh *imeshes = (iqmmesh *)&buf[hdr.ofs_meshes];
            iqmjoint *joints = (iqmjoint *)&buf[hdr.ofs_joints];

            if(hdr.num_joints)
            {
                if(skel->numbones <= 0)
                {
                    skel->numbones = hdr.num_joints;
                    skel->bones = new boneinfo[skel->numbones]; 
                    loopi(hdr.num_joints)
                    {
                        iqmjoint &j = joints[i]; 
                        boneinfo &b = skel->bones[i];
                        if(!b.name) b.name = newstring(&str[j.name]);
                        b.parent = j.parent;
                        if(skel->shared <= 1)
                        {
                            j.pos.y = -j.pos.y;
                            j.orient.x = -j.orient.x;
                            j.orient.z = -j.orient.z;
                            b.base = dualquat(quat(j.orient), j.pos);     
                            if(b.parent >= 0) b.base.mul(skel->bones[b.parent].base, dualquat(b.base));
                            (b.invbase = b.base).invert();
                        }
                    }
                }

                if(skel->shared <= 1)
                    skel->linkchildren();
            }

            loopi(hdr.num_meshes)
            {
                iqmmesh &im = imeshes[i];
                skelmesh *m = new skelmesh;
                m->group = this;   
                meshes.add(m);
                m->name = newstring(&str[im.name]);
                m->numverts = im.num_vertexes;
                if(m->numverts) 
                {
                    m->verts = new vert[m->numverts];
                    if(vtan) m->bumpverts = new bumpvert[m->numverts];
                }
                loopj(im.num_vertexes)
                {
                    int fj = j + im.first_vertex;
                    vert &v = m->verts[j];
                    loopk(3) v.pos[k] = vpos[3*fj + k];    
                    v.pos.y = -v.pos.y;
                    v.u = vtc[2*fj + 0];
                    v.v = vtc[2*fj + 1];
                    if(vnorm) 
                    {
                        loopk(3) v.norm[k] = vnorm[3*fj + k];
                        v.norm.y = -v.norm.y;
                        if(vtan)
                        {
                            bumpvert &bv = m->bumpverts[j];
                            loopk(3) bv.tangent[k] = vtan[4*fj + k];
                            bv.tangent.x = -bv.tangent.x;
                            bv.tangent.z = -bv.tangent.z;
                            bv.bitangent = vtan[4*fj + 3];
                        }
                    } 
                    blendcombo c;
                    int sorted = 0;
                    if(vindex && vweight) loopk(4) sorted = c.addweight(sorted, vweight[4*fj + k], vindex[4*fj + k]);
                    c.finalize(sorted);
                    v.blend = m->addblendcombo(c);
                }
                m->numtris = im.num_triangles;
                if(m->numtris) m->tris = new tri[m->numtris]; 
                loopj(im.num_triangles)
                {
                    int fj = j + im.first_triangle;
                    loopk(3) m->tris[j].vert[k] = tris[fj].vertex[k] - im.first_vertex;
                }
                if(!m->numtris || !m->numverts)
                {
                    conoutf("empty mesh in %s", filename);
                    meshes.removeobj(m);
                    delete m;
                }
            }

            sortblendcombos();
                
            return true;
        }

        bool loadiqmanims(const char *filename, const iqmheader &hdr, uchar *buf)
        {
            lilswap((uint *)&buf[hdr.ofs_poses], hdr.num_poses*sizeof(iqmpose)/sizeof(uint));
            lilswap((uint *)&buf[hdr.ofs_anims], hdr.num_anims*sizeof(iqmanim)/sizeof(uint));
            lilswap((ushort *)&buf[hdr.ofs_frames], hdr.num_frames*hdr.num_framechannels);

            const char *str = hdr.ofs_text ? (char *)&buf[hdr.ofs_text] : "";
            iqmpose *poses = (iqmpose *)&buf[hdr.ofs_poses];
            iqmanim *anims = (iqmanim *)&buf[hdr.ofs_anims];
            ushort *frames = (ushort *)&buf[hdr.ofs_frames];
            loopi(hdr.num_anims)
            {
                iqmanim &a = anims[i];
                string name;
                copystring(name, filename);
                concatstring(name, ":");
                concatstring(name, &str[a.name]);
                skelanimspec *sa = skel->findskelanim(name);
                if(sa) continue;
                sa = &skel->addskelanim(name);
                sa->frame = skel->numframes;
                sa->range = a.num_frames;
                dualquat *animbones = new dualquat[(skel->numframes+a.num_frames)*skel->numbones];
                if(skel->bones)
                {
                    memcpy(animbones, skel->framebones, skel->numframes*skel->numbones*sizeof(dualquat));
                    delete[] skel->framebones;
                }
                skel->framebones = animbones;
                animbones += skel->numframes*skel->numbones;
                skel->numframes += a.num_frames;
                ushort *animdata = &frames[a.first_frame*hdr.num_framechannels];
                loopj(a.num_frames)
                {
                    dualquat *frame = &animbones[j*skel->numbones];
                    loopk(skel->numbones)
                    {
                        iqmpose &p = poses[k];
                        vec pos, orient;
                        pos.x = p.offsetpos.x; if(p.mask&0x01) pos.x += *animdata++ * p.scalepos.x;
                        pos.y = -p.offsetpos.y; if(p.mask&0x02) pos.y -= *animdata++ * p.scalepos.y;
                        pos.z = p.offsetpos.z; if(p.mask&0x04) pos.z += *animdata++ * p.scalepos.z;
                        orient.x = -p.offsetorient.x; if(p.mask&0x08) orient.x -= *animdata++ * p.scaleorient.x;
                        orient.y = p.offsetorient.y; if(p.mask&0x10) orient.y += *animdata++ * p.scaleorient.y;
                        orient.z = -p.offsetorient.z; if(p.mask&0x20) orient.z -= *animdata++ * p.scaleorient.z;
                        if(p.mask&0x1C0)
                        {
                            if(p.mask&0x40) animdata++;
                            if(p.mask&0x80) animdata++;
                            if(p.mask&0x100) animdata++;
                        }
                        frame[k] = dualquat(quat(orient), pos);
                        if(iqmadjustments.inrange(k))
                        {
                            if(iqmadjustments[k].yaw) frame[k].mulorient(quat(vec(0, 0, 1), iqmadjustments[k].yaw*RAD));
                            if(iqmadjustments[k].pitch) frame[k].mulorient(quat(vec(0, -1, 0), iqmadjustments[k].pitch*RAD));
                            if(iqmadjustments[k].roll) frame[k].mulorient(quat(vec(-1, 0, 0), iqmadjustments[k].roll*RAD));
                            if(!iqmadjustments[k].translate.iszero()) frame[k].translate(iqmadjustments[k].translate);
                        }
                        boneinfo &b = skel->bones[k];
                        frame[k].mul(b.invbase);
                        if(b.parent >= 0) frame[k].mul(skel->bones[b.parent].base, dualquat(frame[k]));
                        frame[k].fixantipodal(skel->framebones[k]);
                    }
                } 
            }
     
            return true;
        }

        bool loadiqm(const char *filename, bool doloadmesh, bool doloadanim)
        {
            stream *f = openfile(filename, "r");
            if(!f) return false;

            uchar *buf = NULL;
            iqmheader hdr;
            if(f->read(&hdr, sizeof(hdr)) != sizeof(hdr) || memcmp(hdr.magic, "INTERQUAKEMODEL", sizeof(hdr.magic))) goto error;
            lilswap(&hdr.version, (sizeof(hdr) - sizeof(hdr.magic))/sizeof(uint));
            if(hdr.version != 1) goto error;
            if(hdr.filesize > (16<<20)) goto error; // sanity check... don't load files bigger than 16 MB
            buf = new uchar[hdr.filesize];
            if(f->read(buf + sizeof(hdr), hdr.filesize - sizeof(hdr)) != int(hdr.filesize - sizeof(hdr))) goto error;

            if(doloadmesh && !loadiqmmeshes(filename, hdr, buf)) goto error;
            if(doloadanim && !loadiqmanims(filename, hdr, buf)) goto error;

            delete[] buf;
            delete f;
            return true;

        error:
            if(buf) delete[] buf;
            delete f;
            return false;
        }

        bool loadmesh(const char *filename)
        {
            name = newstring(filename);

            return loadiqm(filename, true, false);
        }

        skelanimspec *loadanim(const char *animname)
        {
            const char *sep = strchr(animname, ':');
            skelanimspec *sa = skel->findskelanim(animname, sep ? '\0' : ':');
            if(!sa)
            {
                string filename;
                copystring(filename, animname);
                if(sep) filename[sep - animname] = '\0';
                if(loadiqm(filename, false, true))
                    sa = skel->findskelanim(animname, sep ? '\0' : ':');
            }
            return sa;
        }
    };            

    meshgroup *loadmeshes(char *name, va_list args)
    {
        iqmmeshgroup *group = new iqmmeshgroup;
        group->shareskeleton(va_arg(args, char *));
        if(!group->loadmesh(name)) { delete group; return NULL; }
        return group;
    }

    bool loaddefaultparts()
    {
        skelpart &mdl = *new skelpart;
        parts.add(&mdl);
        mdl.model = this;
        mdl.index = 0;
        mdl.pitchscale = mdl.pitchoffset = mdl.pitchmin = mdl.pitchmax = 0;
        iqmadjustments.setsize(0);
        const char *fname = loadname + strlen(loadname);
        do --fname; while(fname >= loadname && *fname!='/' && *fname!='\\');
        fname++;
        defformatstring(meshname)("data/models/%s/%s.iqm", loadname, fname);
        mdl.meshes = sharemeshes(path(meshname), NULL);
        if(!mdl.meshes) return false;
        mdl.initanimparts();
        mdl.initskins();
        return true;
    }

    bool load()
    {
        if(loaded) return true;
        formatstring(iqmdir)("data/models/%s", loadname);
        defformatstring(cfgname)("data/models/%s/iqm.lua", loadname); // INTENSITY

        loadingiqm = this;
        var::persistvars = false;
        if (lua::engine.execf(path(cfgname), false) && parts.length()) // INTENSITY: execfile(cfgname, false) && parts.length()) // configured iqm, will call the iqm* commands below
        {
            var::persistvars = true;
            loadingiqm = NULL;
            loopv(parts) if(!parts[i]->meshes) return false;
        }
        else // iqm without configuration, try default tris and skin 
        {
            var::persistvars = true;
            if(!loaddefaultparts()) 
            {
                loadingiqm = NULL;
                return false;
            }
            loadingiqm = NULL;
        }
        scale /= 4;
        parts[0]->translate = translate;
        loopv(parts) 
        {
            skelpart *p = (skelpart *)parts[i];
            p->endanimparts();
            p->meshes->shared++;
        }
        preloadshaders();
        return loaded = true;
    }
};

void setiqmdir(char *name)
{
    if(!loadingiqm) { conoutf("not loading an iqm"); return; }
    formatstring(iqmdir)("data/models/%s", name);
}
    
void iqmload(char *meshfile, char *skelname)
{
    if(!loadingiqm) { conoutf("not loading an iqm"); return; }
    defformatstring(filename)("%s/%s", iqmdir, meshfile);
    iqm::skelpart &mdl = *new iqm::skelpart;
    loadingiqm->parts.add(&mdl);
    mdl.model = loadingiqm;
    mdl.index = loadingiqm->parts.length()-1;
    mdl.pitchscale = mdl.pitchoffset = mdl.pitchmin = mdl.pitchmax = 0;
    iqmadjustments.setsize(0);
    mdl.meshes = loadingiqm->sharemeshes(path(filename), skelname[0] ? skelname : NULL);
    if(!mdl.meshes) conoutf("could not load %s", filename); // ignore failure
    else 
    {
        mdl.initanimparts();
        mdl.initskins();
    }
}

void iqmtag(char *name, char *tagname)
{
    if(!loadingiqm || loadingiqm->parts.empty()) { conoutf("not loading an iqm"); return; }
    iqm::part &mdl = *loadingiqm->parts.last();
    int i = mdl.meshes ? ((iqm::skelmeshgroup *)mdl.meshes)->skel->findbone(name) : -1;
    if(i >= 0)
    {
        ((iqm::skelmeshgroup *)mdl.meshes)->skel->addtag(tagname, i);
        return;
    }
    conoutf("could not find bone %s for tag %s", name, tagname);
}
        
void iqmpitch(char *name, float *pitchscale, float *pitchoffset, float *pitchmin, float *pitchmax)
{
    if(!loadingiqm || loadingiqm->parts.empty()) { conoutf("not loading an iqm"); return; }
    iqm::part &mdl = *loadingiqm->parts.last();

    if(name[0])
    {
        int i = mdl.meshes ? ((iqm::skelmeshgroup *)mdl.meshes)->skel->findbone(name) : -1;
        if(i>=0)
        {
            iqm::boneinfo &b = ((iqm::skelmeshgroup *)mdl.meshes)->skel->bones[i];
            b.pitchscale = *pitchscale;
            b.pitchoffset = *pitchoffset;
            if(*pitchmin || *pitchmax)
            {
                b.pitchmin = *pitchmin;
                b.pitchmax = *pitchmax;
            }
            else
            {
                b.pitchmin = -360*b.pitchscale;
                b.pitchmax = 360*b.pitchscale;
            }
            return;
        }
        conoutf("could not find bone %s to pitch", name);
        return;
    }

    mdl.pitchscale = *pitchscale;
    mdl.pitchoffset = *pitchoffset;
    if(*pitchmin || *pitchmax)
    {
        mdl.pitchmin = *pitchmin;
        mdl.pitchmax = *pitchmax;
    }
    else
    {
        mdl.pitchmin = -360*mdl.pitchscale;
        mdl.pitchmax = 360*mdl.pitchscale;
    }
}

void iqmadjust(char *name, float *yaw, float *pitch, float *roll, float *tx, float *ty, float *tz)
{
    if(!loadingiqm || loadingiqm->parts.empty()) { conoutf("not loading an iqm"); return; }
    iqm::part &mdl = *loadingiqm->parts.last();

    if(!name[0]) return;
    int i = mdl.meshes ? ((iqm::skelmeshgroup *)mdl.meshes)->skel->findbone(name) : -1;
    if(i < 0) {  conoutf("could not find bone %s to adjust", name); return; }
    while(!iqmadjustments.inrange(i)) iqmadjustments.add(iqmadjustment(0, 0, 0, vec(0, 0, 0)));
    iqmadjustments[i] = iqmadjustment(*yaw, *pitch, *roll, vec(*tx/4, *ty/4, *tz/4));
}
 
#define loopiqmmeshes(meshname, m, body) \
    if(!loadingiqm || loadingiqm->parts.empty()) { conoutf("not loading an iqm"); return; } \
    iqm::part &mdl = *loadingiqm->parts.last(); \
    if(!mdl.meshes) return; \
    loopv(mdl.meshes->meshes) \
    { \
        iqm::skelmesh &m = *(iqm::skelmesh *)mdl.meshes->meshes[i]; \
        if(!strcmp(meshname, "*") || (m.name && !strcmp(m.name, meshname))) \
        { \
            body; \
        } \
    }

#define loopiqmskins(meshname, s, body) loopiqmmeshes(meshname, m, { iqm::skin &s = mdl.skins[i]; body; })

void iqmskin(char *meshname, char *tex, char *masks, float *envmapmax, float *envmapmin)
{
    loopiqmskins(meshname, s,
        s.tex = textureload(makerelpath(iqmdir, tex), 0, true, false);
        if(*masks)
        {
            s.masks = textureload(makerelpath(iqmdir, masks, "<stub>"), 0, true, false);
            s.envmapmax = *envmapmax;
            s.envmapmin = *envmapmin;
        }
    );
}

void iqmspec(char *meshname, int *percent)
{
    float spec = 1.0f;
    if(*percent>0) spec = *percent/100.0f;
    else if(*percent<0) spec = 0.0f;
    loopiqmskins(meshname, s, s.spec = spec);
}

void iqmambient(char *meshname, int *percent)
{
    float ambient = 0.3f;
    if(*percent>0) ambient = *percent/100.0f;
    else if(*percent<0) ambient = 0.0f;
    loopiqmskins(meshname, s, s.ambient = ambient);
}

void iqmglow(char *meshname, int *percent)
{
    float glow = 3.0f;
    if(*percent>0) glow = *percent/100.0f;
    else if(*percent<0) glow = 0.0f;
    loopiqmskins(meshname, s, s.glow = glow);
}

void iqmglare(char *meshname, float *specglare, float *glowglare)
{
    loopiqmskins(meshname, s, { s.specglare = *specglare; s.glowglare = *glowglare; });
}

void iqmalphatest(char *meshname, float *cutoff)
{
    loopiqmskins(meshname, s, s.alphatest = max(0.0f, min(1.0f, *cutoff)));
}

void iqmalphablend(char *meshname, int *blend)
{
    loopiqmskins(meshname, s, s.alphablend = *blend!=0);
}

void iqmcullface(char *meshname, int *cullface)
{
    loopiqmskins(meshname, s, s.cullface = *cullface!=0);
}

void iqmenvmap(char *meshname, char *envmap)
{
    Texture *tex = cubemapload(envmap);
    loopiqmskins(meshname, s, s.envmap = tex);
}

void iqmbumpmap(char *meshname, char *normalmap, char *skin)
{
    Texture *normalmaptex = NULL, *skintex = NULL;
    normalmaptex = textureload(makerelpath(iqmdir, normalmap, "<noff>"), 0, true, false);
    if(skin[0]) skintex = textureload(makerelpath(iqmdir, skin, "<noff>"), 0, true, false);
    loopiqmskins(meshname, s, { s.unlittex = skintex; s.normalmap = normalmaptex; m.calctangents(); });
}

void iqmfullbright(char *meshname, float *fullbright)
{
    loopiqmskins(meshname, s, s.fullbright = *fullbright);
}

void iqmshader(char *meshname, char *shader)
{
    loopiqmskins(meshname, s, s.shader = lookupshaderbyname(shader));
}

void iqmscroll(char *meshname, float *scrollu, float *scrollv)
{
    loopiqmskins(meshname, s, { s.scrollu = *scrollu; s.scrollv = *scrollv; });
}

void iqmanim(char *anim, char *animfile, float *speed, int *priority)
{
    if(!loadingiqm || loadingiqm->parts.empty()) { conoutf("not loading an iqm"); return; }

    vector<int> anims;
    findanims(anim, anims);
    if(anims.empty()) conoutf("could not find animation %s", anim);
    else 
    {
        iqm::part *p = loadingiqm->parts.last();
        if(!p->meshes) return;
        defformatstring(filename)("%s/%s", iqmdir, animfile);
        iqm::skelanimspec *sa = ((iqm::iqmmeshgroup *)p->meshes)->loadanim(path(filename));
        if(!sa) conoutf("could not load iqm anim file %s", filename);
        else loopv(anims)
        {
            loadingiqm->parts.last()->setanim(p->numanimparts-1, anims[i], sa->frame, sa->range, *speed, *priority);
        }
    }
}

void iqmanimpart(char *maskstr)
{
    if(!loadingiqm || loadingiqm->parts.empty()) { conoutf("not loading an iqm"); return; }

    iqm::skelpart *p = (iqm::skelpart *)loadingiqm->parts.last();

    vector<char *> bonestrs;

    // TODO: get rid of this thing
    maskstr += strspn(maskstr, "\n\t ");
    while(*maskstr)
    {
        const char *elem = maskstr;
        *maskstr=='"' ? (++maskstr, maskstr += strcspn(maskstr, "\"\n\0"), maskstr += *maskstr=='"') : maskstr += strcspn(maskstr, "\n\t \0");
        bonestrs.add(*elem=='"' ? newstring(elem+1, maskstr-elem-(maskstr[-1]=='"' ? 2 : 1)) : newstring(elem, maskstr-elem));
        maskstr += strspn(maskstr, "\n\t ");
    }

    vector<ushort> bonemask;
    loopv(bonestrs)
    {
        char *bonestr = bonestrs[i];
        int bone = p->meshes ? ((iqm::skelmeshgroup *)p->meshes)->skel->findbone(bonestr[0]=='!' ? bonestr+1 : bonestr) : -1;
        if(bone<0) { conoutf("could not find bone %s for anim part mask [%s]", bonestr, maskstr); bonestrs.deletearrays(); return; }
        bonemask.add(bone | (bonestr[0]=='!' ? BONEMASK_NOT : 0));
    }
    bonestrs.deletearrays();
    bonemask.sort(bonemaskcmp);
    if(bonemask.length()) bonemask.add(BONEMASK_END);

    if(!p->addanimpart(bonemask.getbuf())) conoutf("too many animation parts");
}

void iqmlink(int *parent, int *child, char *tagname, float *x, float *y, float *z)
{
    if(!loadingiqm) { conoutf("not loading an iqm"); return; }
    if(!loadingiqm->parts.inrange(*parent) || !loadingiqm->parts.inrange(*child)) { conoutf("no models loaded to link"); return; }
    if(!loadingiqm->parts[*parent]->link(loadingiqm->parts[*child], tagname, vec(*x, *y, *z))) conoutf("could not link model %s", loadingiqm->loadname);
}

void iqmnoclip(char *meshname, int *noclip)
{
    loopiqmmeshes(meshname, m, m.noclip = *noclip!=0);
}
