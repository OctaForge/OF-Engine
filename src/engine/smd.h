struct smd;

smd *loadingsmd = NULL;

string smddir;

struct smdbone
{
    string name;
    int parent;
    smdbone() : parent(-1) { name[0] = '\0'; }
};

struct smdadjustment
{
    float yaw, pitch, roll;
    vec translate;

    smdadjustment(float yaw, float pitch, float roll, const vec &translate) : yaw(yaw), pitch(pitch), roll(roll), translate(translate) {}
};

vector<smdadjustment> smdadjustments;

struct smd : skelmodel
{
    smd(const char *name) : skelmodel(name) {}

    int type() const { return MDL_SMD; }

    struct smdmesh : skelmesh
    {
    };

    struct smdmeshgroup : skelmeshgroup
    {
        smdmeshgroup() 
        {
        }

        bool skipcomment(char *&curbuf)
        {
            while(*curbuf && isspace(*curbuf)) curbuf++;
            switch(*curbuf)
            {
                case '#':
                case ';':
                case '\r':
                case '\n':
                case '\0':
                    return true;
                case '/':
                    if(curbuf[1] == '/') return true;
                    break;
            }
            return false;
        }

        void skipsection(stream *f, char *buf, size_t bufsize)
        {
            while(f->getline(buf, bufsize))
            {
                char *curbuf = buf;
                if(skipcomment(curbuf)) continue;
                if(!strncmp(curbuf, "end", 3)) break;
            }
        }

        void readname(char *&curbuf, char *name, size_t namesize)
        {
            char *curname = name;
            while(*curbuf && isspace(*curbuf)) curbuf++;
            bool allowspace = false;
            if(*curbuf == '"') { curbuf++; allowspace = true; }
            while(*curbuf)
            {
                char c = *curbuf++;
                if(c == '"') break;      
                if(isspace(c) && !allowspace) break;
                if(curname < &name[namesize-1]) *curname++ = c;
            } 
            *curname = '\0';
        }

        void readnodes(stream *f, char *buf, size_t bufsize, vector<smdbone> &bones)
        {
            while(f->getline(buf, bufsize))
            {
                char *curbuf = buf;
                if(skipcomment(curbuf)) continue;
                if(!strncmp(curbuf, "end", 3)) break;
                int id = strtol(curbuf, &curbuf, 10);
                string name;
                readname(curbuf, name, sizeof(name));
                int parent = strtol(curbuf, &curbuf, 10);
                if(id < 0 || id > 255 || parent > 255 || !name[0]) continue; 
                while(!bones.inrange(id)) bones.add();
                smdbone &bone = bones[id];
                copystring(bone.name, name);
                bone.parent = parent;
            }
        }

        void readmaterial(char *&curbuf, char *name, size_t namesize)
        {
            char *curname = name;
            while(*curbuf && isspace(*curbuf)) curbuf++;
            while(*curbuf)
            {
                char c = *curbuf++;
                if(isspace(c)) break;
                if(c == '.')
                {
                    while(*curbuf && !isspace(*curbuf)) curbuf++;
                    break;
                }
                if(curname < &name[namesize-1]) *curname++ = c;
            }
            *curname = '\0';
        }

        struct smdmeshdata
        {
            smdmesh *mesh;
            vector<vert> verts;
            vector<tri> tris;

            void finalize()
            {
                if(verts.empty() || tris.empty()) return;
                vert *mverts = new vert[mesh->numverts + verts.length()];
                if(mesh->numverts) 
                {
                    memcpy(mverts, mesh->verts, mesh->numverts*sizeof(vert));
                    delete[] mesh->verts;
                }
                memcpy(&mverts[mesh->numverts], verts.getbuf(), verts.length()*sizeof(vert));
                mesh->numverts += verts.length();
                mesh->verts = mverts;
                tri *mtris = new tri[mesh->numtris + tris.length()];
                if(mesh->numtris) 
                {
                    memcpy(mtris, mesh->tris, mesh->numtris*sizeof(tri));
                    delete[] mesh->tris;
                }
                memcpy(&mtris[mesh->numtris], tris.getbuf(), tris.length()*sizeof(tri));
                mesh->numtris += tris.length();
                mesh->tris = mtris;
            }
        };

        struct smdvertkey : vert
        {
            smdmeshdata *mesh;
            
            smdvertkey(smdmeshdata *mesh) : mesh(mesh) {}
        };
     
        void readtriangles(stream *f, char *buf, size_t bufsize)
        {
            smdmeshdata *curmesh = NULL;
            hashtable<const char *, smdmeshdata> materials(1<<6);
            hashset<int> verts(1<<12); 
            while(f->getline(buf, bufsize))
            {
                char *curbuf = buf;
                if(skipcomment(curbuf)) continue;
                if(!strncmp(curbuf, "end", 3)) break;
                string material;
                readmaterial(curbuf, material, sizeof(material)); 
                if(!curmesh || strcmp(curmesh->mesh->name, material))
                {
                    curmesh = materials.access(material);
                    if(!curmesh)
                    {
                        smdmesh *m = new smdmesh;
                        m->group = this;
                        m->name = newstring(material);
                        meshes.add(m);
                        curmesh = &materials[m->name];
                        curmesh->mesh = m;
                    }
                }
                tri curtri;
                loopi(3)                        
                {
                    char *curbuf;
                    do
                    {
                        if(!f->getline(buf, bufsize)) goto endsection;
                        curbuf = buf;
                    } while(skipcomment(curbuf));
                    smdvertkey key(curmesh);     
                    int parent = -1, numlinks = 0, len = 0;
                    if(sscanf(curbuf, " %d %f %f %f %f %f %f %f %f %d%n", &parent, &key.pos.x, &key.pos.y, &key.pos.z, &key.norm.x, &key.norm.y, &key.norm.z, &key.u, &key.v, &numlinks, &len) < 9) goto endsection;    
                    curbuf += len;
                    key.pos.y = -key.pos.y;
                    key.norm.y = -key.norm.y;
                    key.v = 1 - key.v;
                    blendcombo c;
                    int sorted = 0;
                    float pweight = 0, tweight = 0;
                    for(; numlinks > 0; numlinks--)
                    {
                        int bone = -1, len = 0;
                        float weight = 0;
                        if(sscanf(curbuf, " %d %f%n", &bone, &weight, &len) < 2) break;
                        curbuf += len;
                        tweight += weight;
                        if(bone == parent) pweight += weight;                       
                        else sorted = c.addweight(sorted, weight, bone);
                    }
                    if(tweight < 1) pweight += 1 - tweight;
                    if(pweight > 0) sorted = c.addweight(sorted, pweight, parent);
                    c.finalize(sorted);
                    key.blend = curmesh->mesh->addblendcombo(c);
                    int index = verts.access(key, curmesh->verts.length());
                    if(index == curmesh->verts.length()) curmesh->verts.add(key);
                    curtri.vert[2-i] = index;
                }
                curmesh->tris.add(curtri);
            }
        endsection:
            enumerate(materials, smdmeshdata, data, data.finalize());
        }

        void readskeleton(stream *f, char *buf, size_t bufsize)
        {
            int frame = -1;
            while(f->getline(buf, bufsize))
            {
                char *curbuf = buf;
                if(skipcomment(curbuf)) continue;
                if(sscanf(curbuf, " time %d", &frame) == 1) continue;
                else if(!strncmp(curbuf, "end", 3)) break;
                else if(frame != 0) continue;
                int bone;
                vec pos, rot;
                if(sscanf(curbuf, " %d %f %f %f %f %f %f", &bone, &pos.x, &pos.y, &pos.z, &rot.x, &rot.y, &rot.z) != 7)
                    continue;
                if(bone < 0 || bone >= skel->numbones)
                    continue;
                float cx = cosf(rot.x/2), sx = sinf(rot.x/2),
                      cy = cosf(rot.y/2), sy = sinf(rot.y/2),
                      cz = cosf(rot.z/2), sz = sinf(rot.z/2);
                pos.y = -pos.y;
                dualquat dq(quat(-(sx*cy*cz - cx*sy*sz),
                                 cx*sy*cz + sx*cy*sz,
                                 -(cx*cy*sz - sx*sy*cz),
                                 cx*cy*cz + sx*sy*sz),
                            pos);
                boneinfo &b = skel->bones[bone];
                if(b.parent < 0) b.base = dq;
                else b.base.mul(skel->bones[b.parent].base, dq);
                (b.invbase = b.base).invert();
            }
        }

        bool loadmesh(const char *filename)
        {
            stream *f = openfile(filename, "r");
            if(!f) return false;
            
            char buf[512];
            int version = -1;
            while(f->getline(buf, sizeof(buf)))
            {
                char *curbuf = buf;
                if(skipcomment(curbuf)) continue;
                if(sscanf(curbuf, " version %d", &version) == 1)
                {
                    if(version != 1) { delete f; return false; }
                }
                else if(!strncmp(curbuf, "nodes", 5))
                {
                    if(skel->numbones > 0) { skipsection(f, buf, sizeof(buf)); continue; }
                    vector<smdbone> bones;
                    readnodes(f, buf, sizeof(buf), bones); 
                    if(bones.empty()) continue;
                    skel->numbones = bones.length();
                    skel->bones = new boneinfo[skel->numbones];
                    loopv(bones)
                    {
                        boneinfo &dst = skel->bones[i];
                        smdbone &src = bones[i];
                        dst.name = newstring(src.name);
                        dst.parent = src.parent;
                    }
                    skel->linkchildren();
                }
                else if(!strncmp(curbuf, "triangles", 9))
                    readtriangles(f, buf, sizeof(buf));
                else if(!strncmp(curbuf, "skeleton", 8))
                {
                    if(skel->shared > 1) skipsection(f, buf, sizeof(buf));
                    else readskeleton(f, buf, sizeof(buf));
                }
                else if(!strncmp(curbuf, "vertexanimation", 15))
                    skipsection(f, buf, sizeof(buf));
            }

            sortblendcombos();

            delete f;
            return true;
        }

        int readframes(stream *f, char *buf, size_t bufsize, vector<dualquat> &animbones)
        {
            int frame = -1, numframes = 0, lastbone = skel->numbones;
            while(f->getline(buf, bufsize))
            {
                char *curbuf = buf;
                if(skipcomment(curbuf)) continue;
                int nextframe = -1;
                if(sscanf(curbuf, " time %d", &nextframe) == 1)
                {
                    for(; lastbone < skel->numbones; lastbone++) animbones[frame*skel->numbones + lastbone] = animbones[lastbone];
                    if(nextframe >= numframes)
                    {
                        databuf<dualquat> framebones = animbones.reserve(skel->numbones * (nextframe + 1 - numframes));
                        loopi(nextframe - numframes) framebones.put(animbones.getbuf(), skel->numbones);
                        animbones.addbuf(framebones);
                        animbones.advance(skel->numbones);
                        numframes = nextframe + 1;
                    }
                    frame = nextframe;
                    lastbone = 0;
                    continue;
                }
                else if(!strncmp(curbuf, "end", 3)) break;
                int bone;
                vec pos, rot;
                if(sscanf(curbuf, " %d %f %f %f %f %f %f", &bone, &pos.x, &pos.y, &pos.z, &rot.x, &rot.y, &rot.z) != 7)
                    continue;
                if(bone < 0 || bone >= skel->numbones)
                    continue;
                for(; lastbone < bone; lastbone++) animbones[frame*skel->numbones + lastbone] = animbones[lastbone];
                lastbone++;
                float cx = cosf(rot.x/2), sx = sinf(rot.x/2),
                      cy = cosf(rot.y/2), sy = sinf(rot.y/2),
                      cz = cosf(rot.z/2), sz = sinf(rot.z/2);
                pos.y = -pos.y;
                dualquat dq(quat(-(sx*cy*cz - cx*sy*sz),
                                 cx*sy*cz + sx*cy*sz,
                                 -(cx*cy*sz - sx*sy*cz),
                                 cx*cy*cz + sx*sy*sz),
                            pos);
                if(smdadjustments.inrange(bone))
                {
                    if(smdadjustments[bone].yaw) dq.mulorient(quat(vec(0, 0, 1), smdadjustments[bone].yaw*RAD));
                    if(smdadjustments[bone].pitch) dq.mulorient(quat(vec(0, -1, 0), smdadjustments[bone].pitch*RAD));
                    if(smdadjustments[bone].roll) dq.mulorient(quat(vec(-1, 0, 0), smdadjustments[bone].roll*RAD));
                    if(!smdadjustments[bone].translate.iszero()) dq.translate(smdadjustments[bone].translate);
                }
                dq.mul(skel->bones[bone].invbase);
                dualquat &dst = animbones[frame*skel->numbones + bone];
                if(skel->bones[bone].parent < 0) dst = dq;
                else dst.mul(skel->bones[skel->bones[bone].parent].base, dq);
                dst.fixantipodal(skel->numframes > 0 ? skel->framebones[bone] : animbones[bone]);
            }
            for(; lastbone < skel->numbones; lastbone++) animbones[frame*skel->numbones + lastbone] = animbones[lastbone];
            return numframes;
        }

        skelanimspec *loadanim(const char *filename)
        {
            skelanimspec *sa = skel->findskelanim(filename);
            if(sa || skel->numbones <= 0) return sa;

            stream *f = openfile(filename, "r");
            if(!f) return NULL;

            char buf[512];
            int version = -1;
            vector<dualquat> animbones;
            while(f->getline(buf, sizeof(buf)))
            {
                char *curbuf = buf;
                if(skipcomment(curbuf)) continue;
                if(sscanf(curbuf, " version %d", &version) == 1)
                {
                    if(version != 1) { delete f; return NULL; }
                }
                else if(!strncmp(curbuf, "nodes", 5))
                {
                    vector<smdbone> bones;
                    readnodes(f, buf, sizeof(buf), bones);
                    if(bones.length() != skel->numbones) { delete f; return NULL; }
                }
                else if(!strncmp(curbuf, "triangles", 9))
                    skipsection(f, buf, sizeof(buf));
                else if(!strncmp(curbuf, "skeleton", 8))
                    readframes(f, buf, sizeof(buf), animbones);
                else if(!strncmp(curbuf, "vertexanimation", 15))
                    skipsection(f, buf, sizeof(buf));
            }
            int numframes = animbones.length() / skel->numbones;
            dualquat *framebones = new dualquat[(skel->numframes+numframes)*skel->numbones];             
            if(skel->framebones)
            {
                memcpy(framebones, skel->framebones, skel->numframes*skel->numbones*sizeof(dualquat));
                delete[] skel->framebones;
            }
            memcpy(&framebones[skel->numframes*skel->numbones], animbones.getbuf(), numframes*skel->numbones*sizeof(dualquat));
            skel->framebones = framebones;
            sa = &skel->addskelanim(filename);
            sa->frame = skel->numframes;
            sa->range = numframes;
            skel->numframes += numframes;

            delete f;

            return sa;
        }

        bool load(const char *meshfile)
        {
            name = newstring(meshfile);

            if(!loadmesh(meshfile)) return false;
            
            return true;
        }
    };            

    meshgroup *loadmeshes(char *name, va_list args)
    {
        smdmeshgroup *group = new smdmeshgroup;
        group->shareskeleton(va_arg(args, char *));
        if(!group->load(name)) { delete group; return NULL; }
        return group;
    }

    bool loaddefaultparts()
    {
        skelpart &mdl = *new skelpart;
        parts.add(&mdl);
        mdl.model = this;
        mdl.index = 0;
        mdl.pitchscale = mdl.pitchoffset = mdl.pitchmin = mdl.pitchmax = 0;
        smdadjustments.setsize(0);
        const char *fname = loadname + strlen(loadname);
        do --fname; while(fname >= loadname && *fname!='/' && *fname!='\\');
        fname++;
        defformatstring(meshname)("data/models/%s/%s.smd", loadname, fname);
        mdl.meshes = sharemeshes(path(meshname), NULL);
        if(!mdl.meshes) return false;
        mdl.initanimparts();
        mdl.initskins();
        return true;
    }

    bool load()
    {
        if(loaded) return true;
        formatstring(smddir)("data/models/%s", loadname);
        defformatstring(cfgname)("data/models/%s/smd.lua", loadname); // INTENSITY

        loadingsmd = this;
        var::persistvars = false;
        if(lua::engine.execf(path(cfgname), false) && parts.length()) // INTENSITY: execfile(cfgname, false) && parts.length()) // configured smd, will call the smd* commands below
        {
            var::persistvars = true;
            loadingsmd = NULL;
            loopv(parts) if(!parts[i]->meshes) return false;
        }
        else // smd without configuration, try default tris and skin 
        {
            var::persistvars = true;
            if(!loaddefaultparts()) 
            {
                loadingsmd = NULL;
                return false;
            }
            loadingsmd = NULL;
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

static inline uint hthash(const smd::smdmeshgroup::smdvertkey &k)
{
    return hthash(k.pos);
}

static inline bool htcmp(const smd::smdmeshgroup::smdvertkey &k, int index)
{
    if(!k.mesh->verts.inrange(index)) return false;
    const smd::vert &v = k.mesh->verts[index];
    return k.pos == v.pos && k.norm == v.norm && k.u == v.u && k.v == v.v && k.blend == v.blend;
}

void setsmddir(char *name)
{
    if(!loadingsmd) { conoutf("not loading an smd"); return; }
    formatstring(smddir)("data/models/%s", name);
}
    
void smdload(char *meshfile, char *skelname)
{
    if(!loadingsmd) { conoutf("not loading an smd"); return; }
    defformatstring(filename)("%s/%s", smddir, meshfile);
    smd::skelpart &mdl = *new smd::skelpart;
    loadingsmd->parts.add(&mdl);
    mdl.model = loadingsmd;
    mdl.index = loadingsmd->parts.length()-1;
    mdl.pitchscale = mdl.pitchoffset = mdl.pitchmin = mdl.pitchmax = 0;
    smdadjustments.setsize(0);
    mdl.meshes = loadingsmd->sharemeshes(path(filename), skelname[0] ? skelname : NULL);
    if(!mdl.meshes) conoutf("could not load %s", filename); // ignore failure
    else 
    {
        mdl.initanimparts();
        mdl.initskins();
    }
}

void smdtag(char *name, char *tagname)
{
    if(!loadingsmd || loadingsmd->parts.empty()) { conoutf("not loading an smd"); return; }
    smd::part &mdl = *loadingsmd->parts.last();
    int i = mdl.meshes ? ((smd::skelmeshgroup *)mdl.meshes)->skel->findbone(name) : -1;
    if(i >= 0)
    {
        ((smd::skelmeshgroup *)mdl.meshes)->skel->addtag(tagname, i);
        return;
    }
    conoutf("could not find bone %s for tag %s", name, tagname);
}
        
void smdpitch(char *name, float *pitchscale, float *pitchoffset, float *pitchmin, float *pitchmax)
{
    if(!loadingsmd || loadingsmd->parts.empty()) { conoutf("not loading an smd"); return; }
    smd::part &mdl = *loadingsmd->parts.last();

    if(name[0])
    {
        int i = mdl.meshes ? ((smd::skelmeshgroup *)mdl.meshes)->skel->findbone(name) : -1;
        if(i>=0)
        {
            smd::boneinfo &b = ((smd::skelmeshgroup *)mdl.meshes)->skel->bones[i];
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

void smdadjust(char *name, float *yaw, float *pitch, float *roll, float *tx, float *ty, float *tz)
{
    if(!loadingsmd || loadingsmd->parts.empty()) { conoutf("not loading an smd"); return; }
    smd::part &mdl = *loadingsmd->parts.last();

    if(!name[0]) return;
    int i = mdl.meshes ? ((smd::skelmeshgroup *)mdl.meshes)->skel->findbone(name) : -1;
    if(i < 0) {  conoutf("could not find bone %s to adjust", name); return; }
    while(!smdadjustments.inrange(i)) smdadjustments.add(smdadjustment(0, 0, 0, vec(0, 0, 0)));
    smdadjustments[i] = smdadjustment(*yaw, *pitch, *roll, vec(*tx/4, *ty/4, *tz/4));
}
 
#define loopsmdmeshes(meshname, m, body) \
    if(!loadingsmd || loadingsmd->parts.empty()) { conoutf("not loading an smd"); return; } \
    smd::part &mdl = *loadingsmd->parts.last(); \
    if(!mdl.meshes) return; \
    loopv(mdl.meshes->meshes) \
    { \
        smd::skelmesh &m = *(smd::skelmesh *)mdl.meshes->meshes[i]; \
        if(!strcmp(meshname, "*") || (m.name && !strcmp(m.name, meshname))) \
        { \
            body; \
        } \
    }

#define loopsmdskins(meshname, s, body) loopsmdmeshes(meshname, m, { smd::skin &s = mdl.skins[i]; body; })

void smdskin(char *meshname, char *tex, char *masks, float *envmapmax, float *envmapmin)
{
    loopsmdskins(meshname, s,
        s.tex = textureload(makerelpath(smddir, tex), 0, true, false);
        if(*masks)
        {
            s.masks = textureload(makerelpath(smddir, masks, "<stub>"), 0, true, false);
            s.envmapmax = *envmapmax;
            s.envmapmin = *envmapmin;
        }
    );
}

void smdspec(char *meshname, int *percent)
{
    float spec = 1.0f;
    if(*percent>0) spec = *percent/100.0f;
    else if(*percent<0) spec = 0.0f;
    loopsmdskins(meshname, s, s.spec = spec);
}

void smdambient(char *meshname, int *percent)
{
    float ambient = 0.3f;
    if(*percent>0) ambient = *percent/100.0f;
    else if(*percent<0) ambient = 0.0f;
    loopsmdskins(meshname, s, s.ambient = ambient);
}

void smdglow(char *meshname, int *percent)
{
    float glow = 3.0f;
    if(*percent>0) glow = *percent/100.0f;
    else if(*percent<0) glow = 0.0f;
    loopsmdskins(meshname, s, s.glow = glow);
}

void smdglare(char *meshname, float *specglare, float *glowglare)
{
    loopsmdskins(meshname, s, { s.specglare = *specglare; s.glowglare = *glowglare; });
}

void smdalphatest(char *meshname, float *cutoff)
{
    loopsmdskins(meshname, s, s.alphatest = max(0.0f, min(1.0f, *cutoff)));
}

void smdalphablend(char *meshname, int *blend)
{
    loopsmdskins(meshname, s, s.alphablend = *blend!=0);
}

void smdcullface(char *meshname, int *cullface)
{
    loopsmdskins(meshname, s, s.cullface = *cullface!=0);
}

void smdenvmap(char *meshname, char *envmap)
{
    Texture *tex = cubemapload(envmap);
    loopsmdskins(meshname, s, s.envmap = tex);
}

void smdbumpmap(char *meshname, char *normalmap, char *skin)
{
    Texture *normalmaptex = NULL, *skintex = NULL;
    normalmaptex = textureload(makerelpath(smddir, normalmap, "<noff>"), 0, true, false);
    if(skin[0]) skintex = textureload(makerelpath(smddir, skin, "<noff>"), 0, true, false);
    loopsmdskins(meshname, s, { s.unlittex = skintex; s.normalmap = normalmaptex; m.calctangents(); });
}

void smdfullbright(char *meshname, float *fullbright)
{
    loopsmdskins(meshname, s, s.fullbright = *fullbright);
}

void smdshader(char *meshname, char *shader)
{
    loopsmdskins(meshname, s, s.shader = lookupshaderbyname(shader));
}

void smdscroll(char *meshname, float *scrollu, float *scrollv)
{
    loopsmdskins(meshname, s, { s.scrollu = *scrollu; s.scrollv = *scrollv; });
}

void smdanim(char *anim, char *animfile, float *speed, int *priority)
{
    if(!loadingsmd || loadingsmd->parts.empty()) { conoutf("not loading an smd"); return; }

    vector<int> anims;
    findanims(anim, anims);
    if(anims.empty()) conoutf("could not find animation %s", anim);
    else 
    {
        smd::part *p = loadingsmd->parts.last();
        if(!p->meshes) return;
        defformatstring(filename)("%s/%s", smddir, animfile);
        smd::skelanimspec *sa = ((smd::smdmeshgroup *)p->meshes)->loadanim(path(filename));
        if(!sa) conoutf("could not load smd file %s", filename);
        else loopv(anims)
        {
            loadingsmd->parts.last()->setanim(p->numanimparts-1, anims[i], sa->frame, sa->range, *speed, *priority);
        }
    }
}

void smdanimpart(char *maskstr)
{
    if(!loadingsmd || loadingsmd->parts.empty()) { conoutf("not loading an smd"); return; }

    smd::skelpart *p = (smd::skelpart *)loadingsmd->parts.last();

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
        int bone = p->meshes ? ((smd::skelmeshgroup *)p->meshes)->skel->findbone(bonestr[0]=='!' ? bonestr+1 : bonestr) : -1;
        if(bone<0) { conoutf("could not find bone %s for anim part mask [%s]", bonestr, maskstr); bonestrs.deletearrays(); return; }
        bonemask.add(bone | (bonestr[0]=='!' ? BONEMASK_NOT : 0));
    }
    bonestrs.deletearrays();
    bonemask.sort(bonemaskcmp);
    if(bonemask.length()) bonemask.add(BONEMASK_END);

    if(!p->addanimpart(bonemask.getbuf())) conoutf("too many animation parts");
}

void smdlink(int *parent, int *child, char *tagname, float *x, float *y, float *z)
{
    if(!loadingsmd) { conoutf("not loading an smd"); return; }
    if(!loadingsmd->parts.inrange(*parent) || !loadingsmd->parts.inrange(*child)) { conoutf("no models loaded to link"); return; }
    if(!loadingsmd->parts[*parent]->link(loadingsmd->parts[*child], tagname, vec(*x, *y, *z))) conoutf("could not link model %s", loadingsmd->loadname);
}

void smdnoclip(char *meshname, int *noclip)
{
    loopsmdmeshes(meshname, m, m.noclip = *noclip!=0);
}     
