// worldio.cpp: loading & saving of maps and savegames

#include "engine.h"
#include "game.h" // INTENSITY

// INTENSITY
#include "intensity.h"
#include "world_system.h"
#include "message_system.h"
#ifdef CLIENT
    #include "client_system.h"
#endif
#include "intensity_physics.h"

void backup(char *name, char *backupname)
{
    string backupfile;
    copystring(backupfile, findfile(backupname, "wb"));
    remove(backupfile);
    rename(findfile(name, "wb"), backupfile);
}

string ogzname, bakname, cfgname, picname;

void cutogz(char *s)
{
    char *ogzp = strstr(s, ".ogz");
    if(ogzp) *ogzp = '\0';
}

void getmapfilenames(const char *fname, const char *cname, char *pakname, char *mapname, char *cfgname)
{
    if(!cname) cname = fname;
    string name;
    copystring(name, cname, 100);
    cutogz(name);
    char *slash = strpbrk(name, "/\\");
    if(slash)
    {
        copystring(pakname, name, slash-name+1);
        copystring(cfgname, slash+1);
    }
    else
    {
        copystring(pakname, "base");
        copystring(cfgname, name);
    }
    if(strpbrk(fname, "/\\")) copystring(mapname, fname);
    else formatstring(mapname)("base/%s", fname);
    cutogz(mapname);
}

void setmapfilenames(const char *fname, const char *cname = 0)
{
    string pakname, mapname, mcfgname;
    getmapfilenames(fname, cname, pakname, mapname, mcfgname);

    formatstring(ogzname)("data/%s.ogz", mapname);
    if(GETIV(savebak)==1) formatstring(bakname)("data/%s.BAK", mapname);
    else formatstring(bakname)("data/%s_%d.BAK", mapname, totalmillis);
    formatstring(cfgname)("data/%s/%s.cfg", pakname, mcfgname);
    formatstring(picname)("data/%s.jpg", mapname);

    path(ogzname);
    path(bakname);
    path(cfgname);
    path(picname);
}

enum { OCTSAV_CHILDREN = 0, OCTSAV_EMPTY, OCTSAV_SOLID, OCTSAV_NORMAL, OCTSAV_LODCUBE };

void savec(cube *c, stream *f, bool nolms)
{
    loopi(8)
    {
        if(c[i].children && (!c[i].ext || !c[i].ext->surfaces))
        {
            f->putchar(OCTSAV_CHILDREN);
            savec(c[i].children, f, nolms);
        }
        else
        {
            int oflags = 0;
            if(c[i].ext && c[i].ext->merged) oflags |= 0x80;
            if(c[i].children) f->putchar(oflags | OCTSAV_LODCUBE);
            else if(isempty(c[i])) f->putchar(oflags | OCTSAV_EMPTY);
            else if(isentirelysolid(c[i])) f->putchar(oflags | OCTSAV_SOLID);
            else
            {
                f->putchar(oflags | OCTSAV_NORMAL);
                f->write(c[i].edges, 12);
            }
            loopj(6) f->putlil<ushort>(c[i].texture[j]);
            uchar mask = 0;
            if(c[i].ext)
            {
                if(c[i].ext->material != MAT_AIR) mask |= 0x80;
                if(c[i].ext->normals && !nolms)
                {
                    mask |= 0x40;
                    loopj(6) if(c[i].ext->normals[j].normals[0] != bvec(128, 128, 128)) mask |= 1 << j;
                }
            }
            // save surface info for lighting
            if(!c[i].ext || !c[i].ext->surfaces || nolms)
            {
                f->putchar(mask);
                if(c[i].ext)
                {
                    if(c[i].ext->material != MAT_AIR) f->putchar(c[i].ext->material);
                    if(c[i].ext->normals && !nolms) loopj(6) if(mask & (1 << j))
                    {
                        loopk(sizeof(surfaceinfo)) f->putchar(0);
                        f->write(&c[i].ext->normals[j], sizeof(surfacenormals));
                    } 
                }
            }
            else
            {
                int numsurfs = 6;
                loopj(6) 
                {
                    surfaceinfo &surface = c[i].ext->surfaces[j];
                    if(surface.lmid >= LMID_RESERVED || surface.layer!=LAYER_TOP) 
                    {
                        mask |= 1 << j;
                        if(surface.layer&LAYER_BLEND) numsurfs++;
                    }
                }
                f->putchar(mask);
                if(c[i].ext->material != MAT_AIR) f->putchar(c[i].ext->material);
                loopj(numsurfs) if(j >= 6 || mask & (1 << j))
                {
                    surfaceinfo tmp = c[i].ext->surfaces[j];
                    lilswap(&tmp.x, 2);
                    f->write(&tmp, sizeof(surfaceinfo));
                    if(j < 6 && c[i].ext->normals) f->write(&c[i].ext->normals[j], sizeof(surfacenormals));
                }
            }
            if(c[i].ext && c[i].ext->merged)
            {
                f->putchar(c[i].ext->merged | (c[i].ext->mergeorigin ? 0x80 : 0));
                if(c[i].ext->mergeorigin)
                {
                    f->putchar(c[i].ext->mergeorigin);
                    int index = 0;
                    loopj(6) if(c[i].ext->mergeorigin&(1<<j))
                    {
                        mergeinfo tmp = c[i].ext->merges[index++];
                        lilswap(&tmp.u1, 4);
                        f->write(&tmp, sizeof(mergeinfo));
                    }
                }
            }
            if(c[i].children) savec(c[i].children, f, nolms);
        }
    }
}

cube *loadchildren(stream *f);

void loadc(stream *f, cube &c)
{
    bool haschildren = false;
    int octsav = f->getchar();
    switch(octsav&0x7)
    {
        case OCTSAV_CHILDREN:
            c.children = loadchildren(f);
            return;

        case OCTSAV_LODCUBE: haschildren = true;    break;
        case OCTSAV_EMPTY:  emptyfaces(c);          break;
        case OCTSAV_SOLID:  solidfaces(c);          break;
        case OCTSAV_NORMAL: f->read(c.edges, 12); break;

        default:
            fatal("garbage in map");
    }
    loopi(6) c.texture[i] = GETIV(mapversion)<14 ? f->getchar() : f->getlil<ushort>();
    if(GETIV(mapversion) < 7) f->seek(3, SEEK_CUR);
    else
    {
        uchar mask = f->getchar();
        if(mask & 0x80) 
        {
            int mat = f->getchar();
            if(GETIV(mapversion) < 27)
            {
                static uchar matconv[] = { MAT_AIR, MAT_WATER, MAT_CLIP, MAT_GLASS|MAT_CLIP, MAT_NOCLIP, MAT_LAVA|MAT_DEATH, MAT_GAMECLIP, MAT_DEATH };
                mat = size_t(mat) < sizeof(matconv)/sizeof(matconv[0]) ? matconv[mat] : MAT_AIR;
            }
            ext(c).material = mat;
        }
        if(mask & 0x3F)
        {
            uchar lit = 0, bright = 0;
            static surfaceinfo surfaces[12];
            memset(surfaces, 0, 6*sizeof(surfaceinfo));
            if(mask & 0x40) newnormals(c);
            int numsurfs = 6;
            loopi(numsurfs)
            {
                if(i >= 6 || mask & (1 << i))
                {
                    f->read(&surfaces[i], sizeof(surfaceinfo));
                    lilswap(&surfaces[i].x, 2);
                    if(GETIV(mapversion) < 10) ++surfaces[i].lmid;
                    if(GETIV(mapversion) < 18)
                    {
                        if(surfaces[i].lmid >= LMID_AMBIENT1) ++surfaces[i].lmid;
                        if(surfaces[i].lmid >= LMID_BRIGHT1) ++surfaces[i].lmid;
                    }
                    if(GETIV(mapversion) < 19)
                    {
                        if(surfaces[i].lmid >= LMID_DARK) surfaces[i].lmid += 2;
                    }
                    if(i < 6)
                    {
                        if(mask & 0x40) f->read(&c.ext->normals[i], sizeof(surfacenormals));
                        if(surfaces[i].layer != LAYER_TOP) lit |= 1 << i;
                        else if(surfaces[i].lmid == LMID_BRIGHT) bright |= 1 << i;
                        else if(surfaces[i].lmid != LMID_AMBIENT) lit |= 1 << i;
                        if(surfaces[i].layer&LAYER_BLEND) numsurfs++;
                    }
                }
                else surfaces[i].lmid = LMID_AMBIENT;
            }
            if(lit) newsurfaces(c, surfaces, numsurfs);
            else if(bright) brightencube(c);
        }
        if(GETIV(mapversion) >= 20)
        {
            if(octsav&0x80)
            {
                int merged = f->getchar();
                ext(c).merged = merged&0x3F;
                if(merged&0x80)
                {
                    c.ext->mergeorigin = f->getchar();
                    int nummerges = 0;
                    loopi(6) if(c.ext->mergeorigin&(1<<i)) nummerges++;
                    if(nummerges)
                    {
                        c.ext->merges = new mergeinfo[nummerges];
                        loopi(nummerges)
                        {
                            mergeinfo *m = &c.ext->merges[i];
                            f->read(m, sizeof(mergeinfo));
                            lilswap(&m->u1, 4);
                            if(GETIV(mapversion) <= 25)
                            {
                                int uorigin = m->u1 & 0xE000, vorigin = m->v1 & 0xE000;
                                m->u1 = (m->u1 - uorigin) << 2;
                                m->u2 = (m->u2 - uorigin) << 2;
                                m->v1 = (m->v1 - vorigin) << 2;
                                m->v2 = (m->v2 - vorigin) << 2;
                            }
                        }
                    }
                }
            }    
        }                
    }
    c.children = (haschildren ? loadchildren(f) : NULL);
}

cube *loadchildren(stream *f)
{
    cube *c = newcubes();
    loopi(8) loadc(f, c[i]);
    // TODO: remip c from children here
    return c;
}

void savevslot(stream *f, VSlot &vs, int prev)
{
    f->putlil<int>(vs.changed);
    f->putlil<int>(prev);
    if(vs.changed & (1<<VSLOT_SHPARAM))
    {
        f->putlil<ushort>(vs.params.length());
        loopv(vs.params)
        {
            ShaderParam &p = vs.params[i];
            f->putlil<ushort>(strlen(p.name));
            f->write(p.name, strlen(p.name));
            loopk(4) f->putlil<float>(p.val[k]);
        }
    }
    if(vs.changed & (1<<VSLOT_SCALE)) f->putlil<float>(vs.scale);
    if(vs.changed & (1<<VSLOT_ROTATION)) f->putlil<int>(vs.rotation);
    if(vs.changed & (1<<VSLOT_OFFSET))
    {
        f->putlil<int>(vs.xoffset);
        f->putlil<int>(vs.yoffset);
    }
    if(vs.changed & (1<<VSLOT_SCROLL))
    {
        f->putlil<float>(vs.scrollS);
        f->putlil<float>(vs.scrollT);
    }
    if(vs.changed & (1<<VSLOT_LAYER)) f->putlil<int>(vs.layer);
    if(vs.changed & (1<<VSLOT_ALPHA))
    {
        f->putlil<float>(vs.alphafront);
        f->putlil<float>(vs.alphaback);
    }
    if(vs.changed & (1<<VSLOT_COLOR)) 
    {
        loopk(3) f->putlil<float>(vs.colorscale[k]);
    }
}

void savevslots(stream *f, int numvslots)
{
    if(vslots.empty()) return;
    int *prev = new int[numvslots];
    memset(prev, -1, numvslots*sizeof(int));
    loopi(numvslots)
    {
        VSlot *vs = vslots[i];
        if(vs->changed) continue;
        for(;;)
        {
            VSlot *cur = vs;
            do vs = vs->next; while(vs && vs->index >= numvslots);
            if(!vs) break;
            prev[vs->index] = cur->index;
        } 
    }
    int lastroot = 0;
    loopi(numvslots)
    {
        VSlot &vs = *vslots[i];
        if(!vs.changed) continue;
        if(lastroot < i) f->putlil<int>(-(i - lastroot));
        savevslot(f, vs, prev[i]);
        lastroot = i+1;
    }
    if(lastroot < numvslots) f->putlil<int>(-(numvslots - lastroot));
    if (numvslots > 0) delete[] prev; // INTENSITY - check for numvslots, for server
}
            
void loadvslot(stream *f, VSlot &vs, int changed)
{
    vs.changed = changed;
    if(vs.changed & (1<<VSLOT_SHPARAM))
    {
        int numparams = f->getlil<ushort>();
        string name;
        loopi(numparams)
        {
            ShaderParam &p = vs.params.add();
            int nlen = f->getlil<ushort>();
            f->read(name, min(nlen, MAXSTRLEN-1));
            name[min(nlen, MAXSTRLEN-1)] = '\0';
            if(nlen >= MAXSTRLEN) f->seek(nlen - (MAXSTRLEN-1), SEEK_CUR);
            p.name = getshaderparamname(name);
            p.type = SHPARAM_LOOKUP;
            p.index = -1;
            p.loc = -1;
            loopk(4) p.val[k] = f->getlil<float>();
        }
    }
    if(vs.changed & (1<<VSLOT_SCALE)) vs.scale = f->getlil<float>();
    if(vs.changed & (1<<VSLOT_ROTATION)) vs.rotation = f->getlil<int>();
    if(vs.changed & (1<<VSLOT_OFFSET))
    {
        vs.xoffset = f->getlil<int>();
        vs.yoffset = f->getlil<int>();
    }
    if(vs.changed & (1<<VSLOT_SCROLL))
    {
        vs.scrollS = f->getlil<float>();
        vs.scrollT = f->getlil<float>();
    }
    if(vs.changed & (1<<VSLOT_LAYER)) vs.layer = f->getlil<int>();
    if(vs.changed & (1<<VSLOT_ALPHA))
    {
        vs.alphafront = f->getlil<float>();
        vs.alphaback = f->getlil<float>();
    }
    if(vs.changed & (1<<VSLOT_COLOR)) 
    {
        loopk(3) vs.colorscale[k] = f->getlil<float>();
    }
}

void loadvslots(stream *f, int numvslots)
{
    int *prev = new int[numvslots];
    memset(prev, -1, numvslots*sizeof(int));
    while(numvslots > 0)
    {
        int changed = f->getlil<int>();
        if(changed < 0)
        {
            loopi(-changed) vslots.add(new VSlot(NULL, vslots.length()));
            numvslots += changed;
        }
        else
        {
            prev[vslots.length()] = f->getlil<int>();
            loadvslot(f, *vslots.add(new VSlot(NULL, vslots.length())), changed);    
            numvslots--;
        }
    }
    loopv(vslots) if(vslots.inrange(prev[i])) vslots[prev[i]]->next = vslots[i];
    if (numvslots > 0) delete[] prev; // INTENSITY - check for numvslots, for server
}

bool save_world(const char *mname, bool nolms)
{
    if(!*mname) mname = game::getclientmap();
    setmapfilenames(*mname ? mname : "untitled");
    if(GETIV(savebak)) backup(ogzname, bakname);
    stream *f = opengzfile(ogzname, "wb");
    if(!f) { conoutf(CON_WARN, "could not write map to %s", ogzname); return false; }

    int numvslots = vslots.length();
    if(!nolms && !multiplayer(false))
    {
        numvslots = compactvslots();
        allchanged();
    }

    renderprogress(0, "saving map...");

    octaheader hdr;
    memcpy(hdr.magic, "OCTA", 4);
    hdr.version = MAPVERSION;
    hdr.headersize = sizeof(hdr);
    hdr.worldsize = GETIV(mapsize);
    hdr.numents = 0;
//    const vector<extentity *> &ents = entities::getents(); // INTENSITY: No ents in .ogz
//    loopv(ents) if(ents[i]->type!=ET_EMPTY || nolms) hdr.numents++; // INTENSITY: No ents in .ogz
    hdr.numpvs = nolms ? 0 : getnumviewcells();
    hdr.lightmaps = nolms ? 0 : lightmaps.length();
    hdr.blendmap = shouldsaveblendmap();
    hdr.numvars = 0;
    hdr.numvslots = numvslots;
    enumerate(*var::vars, var::cvar*, v, {
        if (v->isoverridable() && !v->isreadonly() && v->isoverriden()) hdr.numvars++;
    });
    lilswap(&hdr.version, 9);
    f->write(&hdr, sizeof(hdr));
   
    enumerate(*var::vars, var::cvar*, v,
    {
        if(!v->isoverridable() || v->isreadonly() || !v->isoverriden()) continue;
        f->putchar(v->gt());
        f->putlil<ushort>(strlen(v->gn()));
        f->write(v->gn(), strlen(v->gn()));
        switch(v->gt())
        {
            case var::VAR_I:
            {
                if(GETIV(dbgvars)) conoutf(CON_DEBUG, "wrote var %s: %d", v->gn(), v->gi());
                f->putlil<int>(v->gi());
                break;
            }
            case var::VAR_F:
            {
                if(GETIV(dbgvars)) conoutf(CON_DEBUG, "wrote fvar %s: %f", v->gn(), v->gf());
                f->putlil<float>(v->gf());
                break;
            }
            case var::VAR_S:
            {
                if(GETIV(dbgvars)) conoutf(CON_DEBUG, "wrote svar %s: %s", v->gn(), v->gs());
                f->putlil<ushort>(strlen(v->gs()));
                f->write(v->gs(), strlen(v->gs()));
                break;
            }
        }
    });

    if(GETIV(dbgvars)) conoutf(CON_DEBUG, "wrote %d vars", hdr.numvars);

    f->putchar((int)strlen(game::gameident()));
    f->write(game::gameident(), (int)strlen(game::gameident())+1);
    f->putlil<ushort>(entities::extraentinfosize());
    vector<char> extras;
    game::writegamedata(extras);
    f->putlil<ushort>(extras.length());
    f->write(extras.getbuf(), extras.length());
    
    f->putlil<ushort>(texmru.length());
    loopv(texmru) f->putlil<ushort>(texmru[i]);
#if 0 // INTENSITY: No ents in .ogz
    char *ebuf = new char[entities::extraentinfosize()];
    loopv(ents)
    {
        if(ents[i]->type!=ET_EMPTY || nolms)
        {
            entity tmp = *ents[i];
            lilswap(&tmp.o.x, 3);
            lilswap(&tmp.attr1, 5);
            f->write(&tmp, sizeof(entity));
            entities::writeent(*ents[i], ebuf);
            if(entities::extraentinfosize()) f->write(ebuf, entities::extraentinfosize());
        }
    }
    delete[] ebuf;
#endif // 0

    savevslots(f, numvslots);

    savec(worldroot, f, nolms);
    if(!nolms) 
    {
        loopv(lightmaps)
        {
            LightMap &lm = lightmaps[i];
            f->putchar(lm.type | (lm.unlitx>=0 ? 0x80 : 0));
            if(lm.unlitx>=0)
            {
                f->putlil<ushort>(ushort(lm.unlitx));
                f->putlil<ushort>(ushort(lm.unlity));
            }
            f->write(lm.data, lm.bpp*LM_PACKW*LM_PACKH);
        }
        if(getnumviewcells()>0) savepvs(f);
    }
    if(shouldsaveblendmap()) saveblendmap(f);

    delete f;
    conoutf("wrote map file %s", ogzname);

    return true;
}

static uint mapcrc = 0;

uint getmapcrc() { return mapcrc; }

static void swapXZ(cube *c)
{    
    loopi(8) 
    {
        swap(c[i].faces[0],   c[i].faces[2]);
        swap(c[i].texture[0], c[i].texture[4]);
        swap(c[i].texture[1], c[i].texture[5]);
        if(c[i].ext && c[i].ext->surfaces)
        {
            swap(c[i].ext->surfaces[0], c[i].ext->surfaces[4]);
            swap(c[i].ext->surfaces[1], c[i].ext->surfaces[5]);
        }
        if(c[i].children) swapXZ(c[i].children);
    }
}

static void fixoversizedcubes(cube *c, int size)
{
    if(size <= 0x1000) return;
    loopi(8)
    {
        if(!c[i].children) subdividecube(c[i], true, false);
        fixoversizedcubes(c[i].children, size>>1);
    }
}

bool finish_load_world(); // INTENSITY: Added this, and use it inside load_world

const char *_saved_mname = NULL; // INTENSITY
const char *_saved_cname = NULL; // INTENSITY
octaheader *saved_hdr = NULL; // INTENSITY

bool load_world(const char *mname, const char *cname)        // still supports all map formats that have existed since the earliest cube betas!
{
    WorldSystem::loadingWorld = true; // INTENSITY
    LogicSystem::init(); // INTENSITY: Start our game data system, wipe all existing LogicEntities, and add the player

#if 0 // INTENSITY
    int loadingstart = SDL_GetTicks();
#endif
    setmapfilenames(mname, cname);

    _saved_mname = mname; // INTENSITY
    _saved_cname = cname; // INTENSITY

    stream *f = opengzfile(ogzname, "rb");
    if(!f) { conoutf(CON_ERROR, "could not read map %s", ogzname); return false; }
    saved_hdr = new octaheader; // INTENSITY
    octaheader& hdr = *saved_hdr; // INTENSITY
    if(f->read(&hdr, 7*sizeof(int))!=int(7*sizeof(int))) { conoutf(CON_ERROR, "map %s has malformatted header", ogzname); delete f; return false; }
    lilswap(&hdr.version, 6);
    if(strncmp(hdr.magic, "OCTA", 4)!=0 || hdr.worldsize <= 0|| hdr.numents < 0) { conoutf(CON_ERROR, "map %s has malformatted header", ogzname); delete f; return false; }
    if(hdr.version>MAPVERSION) { conoutf(CON_ERROR, "map %s requires a newer version of Cube 2: Sauerbraten", ogzname); delete f; return false; }
    compatheader chdr;
    if(hdr.version <= 28)
    {
        if(f->read(&chdr.lightprecision, sizeof(chdr) - 7*sizeof(int)) != int(sizeof(chdr) - 7*sizeof(int))) { conoutf(CON_ERROR, "map %s has malformatted header", ogzname); delete f; return false; }
    }
    else 
    {
        int extra = 0;
        if(hdr.version <= 29) extra++; 
        if(f->read(&hdr.blendmap, sizeof(hdr) - (7+extra)*sizeof(int)) != int(sizeof(hdr) - (7+extra)*sizeof(int))) { conoutf(CON_ERROR, "map %s has malformatted header", ogzname); delete f; return false; }
    }

    resetmap();
    Texture *mapshot = textureload(picname, 3, true, false);
    renderbackground("loading...", mapshot, mname, game::getmapinfo());

    SETVFN(mapversion, hdr.version);

    if(hdr.version <= 28)
    {
        lilswap(&chdr.lightprecision, 3);
        if(hdr.version<=20) conoutf(CON_WARN, "loading older / less efficient map format, may benefit from \"calclight\", then \"savecurrentmap\"");
        if(chdr.lightprecision) SETVF(lightprecision, chdr.lightprecision);
        if(chdr.lighterror) SETVF(lighterror, chdr.lighterror);
        if(chdr.bumperror) SETVF(bumperror, chdr.bumperror);
        SETVF(lightlod, chdr.lightlod);
        if(chdr.ambient) SETVF(ambient, chdr.ambient);
        SETVF(skylight, (int(chdr.skylight[0])<<16) | (int(chdr.skylight[1])<<8) | int(chdr.skylight[2]));
        SETVF(watercolour, (int(chdr.watercolour[0])<<16) | (int(chdr.watercolour[1])<<8) | int(chdr.watercolour[2]));
        SETVF(waterfallcolour, (int(chdr.waterfallcolour[0])<<16) | (int(chdr.waterfallcolour[1])<<8) | int(chdr.waterfallcolour[2]));
        SETVF(lavacolour, (int(chdr.lavacolour[0])<<16) | (int(chdr.lavacolour[1])<<8) | int(chdr.lavacolour[2]));
        SETVF(fullbright, 0);
        if(chdr.lerpsubdivsize || chdr.lerpangle) SETVF(lerpangle, chdr.lerpangle);
        if(chdr.lerpsubdivsize)
        {
            SETVF(lerpsubdiv, chdr.lerpsubdiv);
            SETVF(lerpsubdivsize, chdr.lerpsubdivsize);
        }
        SETVF(maptitle, chdr.maptitle);
        hdr.blendmap = chdr.blendmap;
        hdr.numvars = 0; 
        hdr.numvslots = 0;
    }
    else 
    {
        lilswap(&hdr.blendmap, 2);
        if(hdr.version <= 29) hdr.numvslots = 0;
        else lilswap(&hdr.numvslots, 1);
    }

    loopi(hdr.numvars)
    {
        int type = f->getchar(), ilen = f->getlil<ushort>();
        string name;
        f->read(name, min(ilen, MAXSTRLEN-1));
        name[min(ilen, MAXSTRLEN-1)] = '\0';
        if(ilen >= MAXSTRLEN) f->seek(ilen - (MAXSTRLEN-1), SEEK_CUR);
        var::cvar *v = var::get(name);
        bool exists = v && v->gt() == type;
        switch(type)
        {
            case var::VAR_I:
            {
                int val = f->getlil<int>();
                if(exists && v->gmni() <= v->gmxi()) v->s(val, true, true, false);
                if(GETIV(dbgvars)) conoutf(CON_DEBUG, "read var %s: %d", name, val);
                break;
            }
 
            case var::VAR_F:
            {
                float val = f->getlil<float>();
                if(exists && v->gmnf() <= v->gmxf()) v->s(val, true, true, false);
                if(GETIV(dbgvars)) conoutf(CON_DEBUG, "read fvar %s: %f", name, val);
                break;
            }
    
            case var::VAR_S:
            {
                int slen = f->getlil<ushort>();
                string val;
                f->read(val, min(slen, MAXSTRLEN-1));
                val[min(slen, MAXSTRLEN-1)] = '\0';
                if(slen >= MAXSTRLEN) f->seek(slen - (MAXSTRLEN-1), SEEK_CUR);
                if(exists) v->s(val, true, true, false);
                if(GETIV(dbgvars)) conoutf(CON_DEBUG, "read svar %s: %s", name, val);
                break;
            }
        }
    }
    if(GETIV(dbgvars)) conoutf(CON_DEBUG, "read %d vars", hdr.numvars);

    string gametype;
    copystring(gametype, "fps");
    bool samegame = true;
    int eif = 0;
    if(hdr.version>=16)
    {
        int len = f->getchar();
        f->read(gametype, len+1);
    }
    if(strcmp(gametype, game::gameident())!=0)
    {
        samegame = false;
        conoutf(CON_WARN, "WARNING: loading map from %s game, ignoring entities except for lights/mapmodels)", gametype);
    }
    if(hdr.version>=16)
    {
        eif = f->getlil<ushort>();
        int extrasize = f->getlil<ushort>();
        vector<char> extras;
        loopj(extrasize) extras.add(f->getchar());
        if(samegame) game::readgamedata(extras);
    }
    
    renderprogress(0, "clearing world...");

    texmru.shrink(0);
    if(hdr.version<14)
    {
        uchar oldtl[256];
        f->read(oldtl, sizeof(oldtl));
        loopi(256) texmru.add(oldtl[i]);
    }
    else
    {
        ushort nummru = f->getlil<ushort>();
        loopi(nummru) texmru.add(f->getlil<ushort>());
    }

    freeocta(worldroot);
    worldroot = NULL;

    SETVFN(mapsize, hdr.worldsize);
    int worldscale = 0;
    while(1<<worldscale < hdr.worldsize) worldscale++;
    SETVFN(mapscale, worldscale);

    renderprogress(0, "loading entities...");

    vector<extentity *> &ents = entities::getents();
    int einfosize = entities::extraentinfosize();
    char *ebuf = einfosize > 0 ? new char[einfosize] : NULL;
    loopi(min(hdr.numents, MAXENTS))
    {
//        extentity &e = *entities::newentity();
//        ents.add(&e);
        extentity e; // INTENSITY: Do *NOT* actually load entities from .ogz files - we use our own system.
                     // But, read the data from the file so we can move on (might be a sauer .ogz)
                     // So 'e' here is just a dummy

        f->read(&e, sizeof(entity));
        lilswap(&e.o.x, 3);
        lilswap(&e.attr1, 5);
        e.spawned = false;
        e.inoctanode = false;
        if(hdr.version <= 10 && e.type >= 7) e.type++;
        if(hdr.version <= 12 && e.type >= 8) e.type++;
        if(hdr.version <= 14 && e.type >= ET_MAPMODEL && e.type <= 16)
        {
            if(e.type == 16) e.type = ET_MAPMODEL;
            else e.type++;
        }
        if(hdr.version <= 20 && e.type >= ET_ENVMAP) e.type++;
        if(hdr.version <= 21 && e.type >= ET_PARTICLES) e.type++;
        if(hdr.version <= 22 && e.type >= ET_SOUND) e.type++;
        if(hdr.version <= 23 && e.type >= ET_SPOTLIGHT) e.type++;
        if(hdr.version <= 30 && (e.type == ET_MAPMODEL || e.type == ET_PLAYERSTART)) e.attr1 = (int(e.attr1)+180)%360;
        if(samegame)
        {
            if(einfosize > 0) f->read(ebuf, einfosize);
            entities::readent(e, ebuf);
        }
        else
        {
            if(eif > 0) f->seek(eif, SEEK_CUR);
            if(e.type>=ET_GAMESPECIFIC || hdr.version<=14)
            {
                entities::deleteentity(ents.pop());
                continue;
            }
        }
        if(!insideworld(e.o))
        {
            if(e.type != ET_LIGHT && e.type != ET_SPOTLIGHT)
            {
                conoutf(CON_WARN, "warning: ent outside of world: enttype[%s] index %d (%f, %f, %f)", entities::entname(e.type), i, e.o.x, e.o.y, e.o.z);
            }
        }
        if(hdr.version <= 14 && e.type == ET_MAPMODEL)
        {
            e.o.z += e.attr3;
            if(e.attr4) conoutf(CON_WARN, "warning: mapmodel ent (index %d) uses texture slot %d", i, e.attr4);
            e.attr3 = e.attr4 = 0;
        }
        // INTENSITY: Print ent out, useful for copy-paste importing sauer maps
        // we usually begin with 3 on emptymap

#define PRINT_STD(e) \
    printf("\"attr1\":\"%d\", ", e.attr1); \
    printf("\"attr2\":\"%d\", ", e.attr2); \
    printf("\"attr3\":\"%d\", ", e.attr3); \
    printf("\"attr4\":\"%d\", ", e.attr4); \
    printf("\"position\":\"[%f|%f|%f]\", ", e.o.x, e.o.y, e.o.z); \
    printf("\"animation\":\"130\", ");

        static bool writeEntity = false;

        switch (e.type) // check if to write the entity
        {
            case ET_LIGHT:
            case ET_SPOTLIGHT:
            case ET_ENVMAP:
            case ET_PARTICLES:
            case ET_MAPMODEL:
            case ET_SOUND:
            case ET_PLAYERSTART:
            case JUMPPAD:
            case TELEPORT:
            case TELEDEST:
                writeEntity = true;
                break;
            default:
                writeEntity = false;
                break;
        }

        static int uniqueId = 3;
        if (writeEntity)
        {
            printf("[%d, \"", uniqueId);
            switch (e.type)
            {
                case ET_LIGHT:
                {
                    printf("light\", {");
                    goto standardEntity;
                }
                case ET_SPOTLIGHT:
                {
                    printf("spotlight\", {");
                    goto standardEntity;
                }
                case ET_ENVMAP:
                {
                    printf("envmap\", {");
                    goto standardEntity;
                }
                case ET_PARTICLES:
                {
                    printf("particle_effect\", {");
                    goto standardEntity;
                }
                case ET_MAPMODEL:
                {
                    printf("mapmodel\", {");
                    PRINT_STD(e)
                    printf("\"modelname\":\"@REPLACE_MODEL_PATH@\", ");
                    printf("\"attachments\":\"[]\", ");
                    printf("\"tags\":\"[]\", ");
                    printf("\"_persistent\":\"true\"");
                    break;
                }
                case ET_SOUND:
                {
                    printf("ambient_sound\", {");
                    PRINT_STD(e)
                    printf("\"modelname\":\"\", ");
                    printf("\"soundname\":\"@REPLACE_SOUND_PATH@\", ");
                    printf("\"attachments\":\"[]\", ");
                    printf("\"tags\":\"[]\", ");
                    printf("\"_persistent\":\"true\"");
                    break;
                }
                case ET_PLAYERSTART:
                {
                    printf("world_marker\", {");
                    PRINT_STD(e)
                    printf("\"modelname\":\"\", ");
                    printf("\"attachments\":\"[]\", ");
                    printf("\"tags\":\"[start_@REPLACE_TEAM@]\", ");
                    printf("\"_persistent\":\"true\"");
                    break;
                }
                case JUMPPAD:
                {
                    printf("jumppad\", {");
                    printf("\"jumpvel\":\"[%f|%f|%f]\", ", (int)(char)e.attr3*10.0f, (int)(char)e.attr2*10.0f, e.attr1*12.5f);
                    printf("\"padmodel\":\"\", ");
                    printf("\"padrotate\":\"false\", ");
                    printf("\"padpitch\":\"0\", ");
                    printf("\"attr1\":\"0\", ");
                    printf("\"collision_radius_width\":\"5\", ");
                    printf("\"collision_radius_height\":\"1\", ");
                    printf("\"position\":\"[%f|%f|%f]\", ", e.o.x, e.o.y, e.o.z);
                    printf("\"attr2\":\"-1\", ");
                    printf("\"attr3\":\"0\", ");
                    printf("\"attr4\":\"0\", ");
                    printf("\"animation\":\"130\", ");
                    printf("\"modelname\":\"areatrigger\", ");
                    printf("\"attachments\":\"[]\", ");
                    printf("\"tags\":\"[]\", ");
                    printf("\"_persistent\":\"true\"");
                    break;
                }
                case TELEPORT:
                {
                    printf("teleporter\", {");
                    printf("\"target\":\"[0|0|0]\", ");
                    printf("\"targetyaw\":\"0\", ");
                    printf("\"teledest\":\"%d\", ", e.attr1);
                    printf("\"attr1\":\"0\", ");
                    printf("\"collision_radius_width\":\"5\", ");
                    printf("\"collision_radius_height\":\"5\", ");
                    printf("\"position\":\"[%f|%f|%f]\", ", e.o.x, e.o.y, e.o.z);
                    printf("\"attr2\":\"%d\", ", e.attr2);
                    printf("\"attr3\":\"%d\", ", e.attr3);
                    printf("\"attr4\":\"%d\", ", e.attr4);
                    printf("\"animation\":\"130\", ");
                    printf("\"modelname\":\"%s\", ", (e.attr2 < 0) ? "areatrigger" : "@REPLACE_MODEL_PATH@");
                    printf("\"soundname\":\"0ad/alarmcreatemiltaryfoot_1.ogg\", ");
                    printf("\"attachments\":\"[]\", ");
                    printf("\"tags\":\"[]\", ");
                    printf("\"_persistent\":\"true\"");
                    break;
                }
                case TELEDEST:
                {
                    printf("world_marker\", {");
                    printf("\"attr1\":\"%d\", ", e.attr1);
                    printf("\"attr2\":\"0\", ");
                    printf("\"attr3\":\"%d\", ", e.attr3);
                    printf("\"attr4\":\"%d\", ", e.attr4);
                    printf("\"position\":\"[%f|%f|%f]\", ", e.o.x, e.o.y, e.o.z);
                    printf("\"animation\":\"130\", ");
                    printf("\"modelname\":\"\", ");
                    printf("\"attachments\":\"[]\", ");
                    printf("\"tags\":\"[teledest_%i]\", ", e.attr2);
                    printf("\"_persistent\":\"true\"");
                    break;
                }
                default: standardEntity:
                {
                    PRINT_STD(e)
                    printf("\"modelname\":\"\", ");
                    printf("\"attachments\":\"[]\", ");
                    printf("\"tags\":\"[]\", ");
                    printf("\"_persistent\":\"true\"");
                    break;
                }
            }
            printf("}],\r\n");
            uniqueId++;
        }
        // INTENSITY: end Print ent out
    }
    if(ebuf) delete[] ebuf;

    if(hdr.numents > MAXENTS) 
    {
        conoutf(CON_WARN, "warning: map has %d entities", hdr.numents);
        f->seek((hdr.numents-MAXENTS)*(samegame ? sizeof(entity) + einfosize : eif), SEEK_CUR);
    }

    renderprogress(0, "loading slots...");
    loadvslots(f, hdr.numvslots);

    renderprogress(0, "loading octree...");
    worldroot = loadchildren(f);

    if(hdr.version <= 11)
        swapXZ(worldroot);

    if(hdr.version <= 8)
        converttovectorworld();

    if(hdr.version <= 25 && hdr.worldsize > 0x1000)
        fixoversizedcubes(worldroot, hdr.worldsize>>1);

    renderprogress(0, "validating...");
    validatec(worldroot, hdr.worldsize>>1);

#ifdef CLIENT // INTENSITY: Server doesn't need lightmaps, pvs and blendmap (and current code for server wouldn't clean
              //            them up if we did read them, so would have a leak)
    if(hdr.version >= 7) loopi(hdr.lightmaps)
    {
        renderprogress(i/(float)hdr.lightmaps, "loading lightmaps...");
        LightMap &lm = lightmaps.add();
        if(hdr.version >= 17)
        {
            int type = f->getchar();
            lm.type = type&0x7F;
            if(hdr.version >= 20 && type&0x80)
            {
                lm.unlitx = f->getlil<ushort>();
                lm.unlity = f->getlil<ushort>();
            }
        }
        if(lm.type&LM_ALPHA && (lm.type&LM_TYPE)!=LM_BUMPMAP1) lm.bpp = 4;
        lm.data = new uchar[lm.bpp*LM_PACKW*LM_PACKH];
        f->read(lm.data, lm.bpp * LM_PACKW * LM_PACKH);
        lm.finalize();
    }

    if(hdr.version >= 25 && hdr.numpvs > 0) loadpvs(f, hdr.numpvs);
    if(hdr.version >= 28 && hdr.blendmap) loadblendmap(f, hdr.blendmap);
#endif // INTENSITY

//    mapcrc = f->getcrc(); // INTENSITY: We use our own signatures
    delete f;

#if 0 // INTENSITY
    conoutf("read map %s (%.1f seconds)", ogzname, (SDL_GetTicks()-loadingstart)/1000.0f);
#endif

    clearmainmenu();

    var::overridevars = true;
    if (lua::engine.hashandle())
    {
        lua::engine.execf("data/cfg/default_map_settings.lua", false);
        WorldSystem::runMapScript();
    }
    var::overridevars = false;
   
#ifdef CLIENT // INTENSITY: Stop, finish loading later when we have all the entities
    renderprogress(0, "requesting entities...");
    Logging::log(Logging::DEBUG, "Requesting active entities...\r\n");
    MessageSystem::send_ActiveEntitiesRequest(ClientSystem::currScenarioCode); // Ask for the NPCs and other players, which are not part of the map proper
#else // SERVER
    Logging::log(Logging::DEBUG, "Finishing loading of the world...\r\n");
    finish_load_world();
#endif

    return true;
}

bool finish_load_world() // INTENSITY: Second half, after all entities received
{
    renderprogress(0, "finalizing world..."); // INTENSITY

    const char *mname = _saved_mname; // INTENSITY
    const char *cname = _saved_cname; // INTENSITY
    octaheader& hdr = *saved_hdr; // INTENSITY

    extern void fixlightmapnormals();
    if(hdr.version <= 25) fixlightmapnormals();

#if 0 // INTENSITY: We use our own preloading system
    vector<int> mapmodels;
    loopv(ents)
    {
        extentity &e = *ents[i];
        if(e.type==ET_MAPMODEL && e.attr2 >= 0)
        {
            if(mapmodels.find(e.attr2) < 0) mapmodels.add(e.attr2);
        }
    }

    loopv(mapmodels)
    {
        loadprogress = float(i+1)/mapmodels.length();
        int mmindex = mapmodels[i];
        mapmodelinfo &mmi = getmminfo(mmindex);
        if(!&mmi) conoutf(CON_WARN, "could not find map model: %d", mmindex);
        else if(!loadmodel(NULL, mmindex, true)) conoutf(CON_WARN, "could not load model: %s", mmi.name);
        else if(mmi.m && bih) mmi.m->preloadBIH();
    }
#endif // INTENSITY

    loadprogress = 0;

    game::preload();
    flushpreloadedmodels();

    entitiesinoctanodes();
    attachentities();
    initlights();
    allchanged(true);

//    if(GETSV(maptitle)[0] && strcmp(GETSV(maptitle), "Untitled Map by Unknown")) conoutf(CON_ECHO, "%s", GETSV(maptitle).c_str()); // INTENSITY

    startmap(cname ? cname : mname);
    
    Logging::log(Logging::DEBUG, "load_world complete.\r\n"); // INTENSITY
    WorldSystem::loadingWorld = false; // INTENSITY

    delete saved_hdr; // INTENSITY

    printf("\r\n\r\n[[MAP LOADING]] - Success.\r\n"); // INTENSITY

    return true;
}

static int mtlsort(const int *x, const int *y)
{
    if(*x < *y) return -1;
    if(*x > *y) return 1;
    return 0;
}

void writeobj(char *name)
{
    defformatstring(fname)("%s.obj", name);
    stream *f = openfile(path(fname), "w"); 
    if(!f) return;
    f->printf("# obj file of Cube 2 level\n\n");
    defformatstring(mtlname)("%s.mtl", name);
    path(mtlname);
    f->printf("mtllib %s\n\n", mtlname); 
    extern vector<vtxarray *> valist;
    vector<vec> verts;
    vector<vec2> texcoords;
    hashtable<vec, int> shareverts(1<<16);
    hashtable<vec2, int> sharetc(1<<16);
    hashtable<int, vector<ivec> > mtls(1<<8);
    vector<int> usedmtl;
    vec bbmin(1e16f, 1e16f, 1e16f), bbmax(-1e16f, -1e16f, -1e16f);
    loopv(valist)
    {
        vtxarray &va = *valist[i];
        ushort *edata = NULL;
        uchar *vdata = NULL;
        if(!readva(&va, edata, vdata)) continue;
        int vtxsize = VTXSIZE;
        ushort *idx = edata;
        loopj(va.texs)
        {
            elementset &es = va.eslist[j];
            if(usedmtl.find(es.texture) < 0) usedmtl.add(es.texture);
            vector<ivec> &keys = mtls[es.texture];
            loopk(es.length[1])
            {
                int n = idx[k] - va.voffset;
                const vec &pos = GETIV(renderpath)==R_FIXEDFUNCTION ? ((const vertexff *)&vdata[n*vtxsize])->pos : ((const vertex *)&vdata[n*vtxsize])->pos;
                vec2 tc(GETIV(renderpath)==R_FIXEDFUNCTION ? ((const vertexff *)&vdata[n*vtxsize])->u : ((const vertex *)&vdata[n*vtxsize])->u,
                        GETIV(renderpath)==R_FIXEDFUNCTION ? ((const vertexff *)&vdata[n*vtxsize])->v : ((const vertex *)&vdata[n*vtxsize])->v);
                ivec &key = keys.add();
                key.x = shareverts.access(pos, verts.length());
                if(key.x == verts.length()) 
                {
                    verts.add(pos);
                    loopl(3)
                    {
                        bbmin[l] = min(bbmin[l], pos[l]);
                        bbmax[l] = max(bbmax[l], pos[l]);
                    }
                }
                key.y = sharetc.access(tc, texcoords.length());
                if(key.y == texcoords.length()) texcoords.add(tc);
            }
            idx += es.length[1];
        }
        delete[] edata;
        delete[] vdata;
    }

    vec center(-(bbmax.x + bbmin.x)/2, -(bbmax.y + bbmin.y)/2, -bbmin.z);
    loopv(verts)
    {
        vec v = verts[i];
        v.add(center);
        if(v.y != floor(v.y)) f->printf("v %.3f ", -v.y); else f->printf("v %d ", int(-v.y));
        if(v.z != floor(v.z)) f->printf("%.3f ", v.z); else f->printf("%d ", int(v.z));
        if(v.x != floor(v.x)) f->printf("%.3f\n", v.x); else f->printf("%d\n", int(v.x));
    } 
    f->printf("\n");
    loopv(texcoords)
    {
        const vec2 &tc = texcoords[i];
        f->printf("vt %.6f %.6f\n", tc.x, 1-tc.y);  
    }
    f->printf("\n");

    usedmtl.sort(mtlsort);
    loopv(usedmtl)
    {
        vector<ivec> &keys = mtls[usedmtl[i]];
        f->printf("g slot%d\n", usedmtl[i]);
        f->printf("usemtl slot%d\n\n", usedmtl[i]);
        for(int i = 0; i < keys.length(); i += 3)
        {
            f->printf("f");
            loopk(3) f->printf(" %d/%d", keys[i+2-k].x+1, keys[i+2-k].y+1);
            f->printf("\n");
        }
        f->printf("\n");
    }
    delete f;

    f = openfile(mtlname, "w");
    if(!f) return;
    f->printf("# mtl file of Cube 2 level\n\n");
    loopv(usedmtl)
    {
        VSlot &vslot = lookupvslot(usedmtl[i], false);
        f->printf("newmtl slot%d\n", usedmtl[i]);
        f->printf("map_Kd %s\n", vslot.slot->sts.empty() ? notexture->name : path(makerelpath("data", vslot.slot->sts[0].name)));
        f->printf("\n");
    } 
    delete f;
}
