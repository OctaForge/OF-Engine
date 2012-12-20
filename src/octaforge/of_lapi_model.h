void mapmodelreset(int n);
void mmodel(char *name);
extern vector<mapmodelinfo> mapmodels;
void clearmodel(char *name);

const char *mdlname();
void mdlalphatest(float cutoff);
void mdlalphablend(bool blend);
void mdlalphadepth(bool depth);
void mdldepthoffset(bool offset);
void mdlcullface(bool cullface);
void mdlcollide(bool collide);
void mdlellipsecollide(bool collide);
void mdlspec(int percent);
void mdlambient(int percent);
void mdlglow(int percent, int delta, float pulse);
void mdlglare(float specglare, float glowglare);
void mdlenvmap(float envmapmax, float envmapmin, char *envmap);
void mdlfullbright(float fullbright);
void mdlshader(char *shader);
void mdlspin(float yaw, float pitch);
void mdlscale(int percent);
void mdltrans(const vec& v);
void mdlyaw(float angle);
void mdlpitch(float angle);
void mdlshadow(bool shadow);
void mdlbb(float rad, float h, float eyeheight);
void mdlextendbb(const vec& extend);
void mdlperentitycollisionboxes(bool val);
void rdvert(const vec& o, float radius);
void rdeye(int v);
void rdtri(int v1, int v2, int v3);
void rdjoint(int n, int t, int v1, int v2, int v3);
void rdlimitdist(int v1, int v2, float mindist, float maxdist);
void rdlimitrot(int t1, int t2, float maxangle, float qx, float qy, float qz, float qw);
void rdanimjoints(bool on);

void clearmodel(char *name);

VARP(ragdoll, 0, 1, 1);

namespace lapi_binds
{
#ifdef CLIENT
    void _lua_mapmodelreset(int            n) { mapmodelreset(n);          }
    void _lua_mapmodel     (const char *name) { mmodel((char*)name);       }
    int  _lua_nummapmodels (                ) { return mapmodels.length(); }
    void _lua_clearmodel   (const char *name) { clearmodel((char*)name);   }

    void _lua_mdlname      (            ) { mdlname();            }
    void _lua_mdlalphatest (float cutoff) { mdlalphatest(cutoff); }
    void _lua_mdlalphablend(bool   blend) { mdlalphablend(blend); }
    void _lua_mdlalphadepth(bool   depth) { mdlalphadepth(depth); }

    void _lua_mdlbb(float rad, float h, float eh) { mdlbb(rad, h, eh); }
    void _lua_mdlextendbb(vec extend) { mdlextendbb(extend); }

    void _lua_mdlscale(int percent) { mdlscale(percent); }
    void _lua_mdlspec (int percent) { mdlspec (percent); }

    void _lua_mdlglow(int percent, int delta, float pulse)
    {
        mdlglow(percent, delta, pulse);
    }

    void _lua_mdlglare(float specg, float lowg)
    {
        mdlglare(specg, lowg);
    }

    void _lua_mdlambient(int percent)
    {
        mdlambient(percent);
    }

    void _lua_mdlcullface(bool cf)
    {
        mdlcullface(cf);
    }

    void _lua_mdldepthoffset(bool doff)
    {
        mdldepthoffset(doff);
    }

    void _lua_mdlfullbright(float fb)
    {
        mdlfullbright(fb);
    }

    void _lua_mdlspin(float yaw, float pitch)
    {
        mdlspin(yaw, pitch);
    }

    void _lua_mdlenvmap(float emax, float emin, const char *emap)
    {
        mdlenvmap(emax, emin, (char*)emap);
    }

    void _lua_mdlshader (const char *shd) { mdlshader((char*)shd); }
    void _lua_mdltrans  (vec           t) { mdltrans(t);           }
    void _lua_mdlyaw    (float       yaw) { mdlyaw(yaw);           }
    void _lua_mdlpitch  (float     pitch) { mdlpitch(pitch);       }
    void _lua_mdlshadow (bool          s) { mdlshadow(s);          }
    void _lua_mdlcollide(bool          c) { mdlcollide(c);         }

    void _lua_mdlperentitycollisionboxes(bool p)
    {
        mdlperentitycollisionboxes(p);
    }

    void _lua_mdlellipsecollide(bool c)
    {
        mdlellipsecollide(c);
    }

    void _lua_rdvert(vec o, float       rad) { rdvert(o, rad);     }
    void _lua_rdeye (int                  v) { rdeye (v);          }
    void _lua_rdtri (int v1, int v2, int v3) { rdtri (v1, v2, v3); }

    void _lua_rdjoint(int n, int t, int v1, int v2, int v3)
    {
        rdjoint(n, t, v1, v2, v3);
    }

    void _lua_rdlimitdist(int v1, int v2, float mind, float maxd)
    {
        rdlimitdist(v1, v2, mind, maxd);
    }

    void _lua_rdlimitrot(
        int t1, int t2, float ma, float qx, float qy, float qz, float qw
    )
    {
        rdlimitrot(t1, t2, ma, qx, qy, qz, qw);
    }

    void _lua_rdanimjoints(bool a) { rdanimjoints(a); }

    void _lua_preloadmodel(const char *name) { preloadmodel(name); }

    void _lua_reloadmodel(const char *name)
    {
        if (!name || !name[0]) return;
        model *old = loadmodel(name);
        if (!old) return;

        clearmodel((char*)name);
        model *_new = loadmodel(name);

        lua::Table ents = lapi::state.get<lua::Function>(
            "LAPI", "World", "Entities", "get_all"
        ).call<lua::Table>();

        for (lua::Table::it it = ents.begin(); it != ents.end(); ++it)
        {
            CLogicEntity *ent = LogicSystem::getLogicEntity(
                lua::Table(*it).get<int>(lapi::state.get<lua::Object>(
                    "LAPI", "World", "Entity", "Properties", "id"
                ))
            );
            if (!ent) continue;
            if (ent->theModel == old) ent->theModel = _new;
        }
    }

    static int oldtp = -1;

    void preparerd(int& anim, CLogicEntity *self)
    {
        if (anim&ANIM_RAGDOLL)
        {
            //if (!ragdoll || loadmodel(mdl);
            fpsent *fp = (fpsent*)self->dynamicEntity;

            if (fp->clientnum == ClientSystem::playerNumber)
            {
                if (oldtp == -1 && thirdperson == 0)
                {
                    oldtp = thirdperson;
                    SETV(thirdperson, 1);
                }
            }

            if (fp->ragdoll || !ragdoll)
            {
                anim &= ~ANIM_RAGDOLL;
                lapi::state.get<lua::Function>(
                    "LAPI", "World", "Entity", "set_local_animation"
                )(self->lua_ref, anim);
            }
        }
        else
        {
            if (self->dynamicEntity)
            {
                fpsent *fp = (fpsent*)self->dynamicEntity;

                if (fp->clientnum == ClientSystem::playerNumber && oldtp != -1)
                {
                    SETV(thirdperson, oldtp);
                    oldtp = -1;
                }
            }
        }
    }

    fpsent *getproxyfpsent(CLogicEntity *self)
    {
        lua::Object h(self->lua_ref[lapi::state.get<lua::Object>(
            "LAPI", "World", "Entity", "Properties", "rendering_hash_hint"
        )]);
        if (!h.is_nil())
        {
            static bool initialized = false;
            static fpsent *fpsentsfr[1024];
            if (!initialized)
            {
                for (int i = 0; i < 1024; i++) fpsentsfr[i] = new fpsent;
                initialized = true;
            }

            int rhashhint = h.to<int>();
            rhashhint = rhashhint & 1023;
            assert(rhashhint >= 0 && rhashhint < 1024);
            return fpsentsfr[rhashhint];
        }
        else return NULL;
    }

    void _lua_rendermodel(
        lua::Table self, const char *mdl,
        int anim, vec o,
        float yaw, float pitch,
        int flags, int basetime
    )
    {
        LAPI_GET_ENT(entity, self, "CAPI.rendermodel", return)

        preparerd(anim, entity);
        fpsent *fp = NULL;

        if (entity->dynamicEntity)
            fp = (fpsent*)entity->dynamicEntity;
        else
            fp = getproxyfpsent(entity);

        rendermodel(mdl, anim, o, yaw, pitch, flags, fp,
            entity->attachments, basetime, 0, 1);
    }

    lua::Table _lua_scriptmdlbb(const char *name)
    {
        model *mdl = loadmodel(name);
        if   (!mdl)
            return lapi::state.wrap<lua::Table>(lua::nil);

        vec center, radius;
        mdl->boundbox(center, radius);

        lua::Table ret(lapi::state.new_table(0, 2));
        ret["center"] = center; ret["radius"] = radius;
        return ret;
    }

    lua::Table _lua_scriptmdlcb(const char *name)
    {
        model *mdl = loadmodel(name);
        if   (!mdl)
            return lapi::state.wrap<lua::Table>(lua::nil);

        vec center, radius;
        mdl->collisionbox(center, radius);

        lua::Table ret(lapi::state.new_table(0, 2));
        ret["center"] = center; ret["radius"] = radius;
        return ret;
    }

    lua::Table _lua_mdlmesh(const char *name)
    {
        model *mdl = loadmodel(name);
        if   (!mdl)
            return lapi::state.wrap<lua::Table>(lua::nil);

        vector<BIH::tri> tris2[2];
        mdl->gentris(tris2);
        vector<BIH::tri>& tris = tris2[0];
        types::String buf;

        lua::Table ret(lapi::state.new_table(0, 1));
        ret["length"] = tris.length();

        for (int i = 0; i < tris.length(); ++i)
        {
            BIH::tri& bt = tris[i];

            lua::Table t(lapi::state.new_table(0, 3));
            t["a"] = bt.a; t["b"] = bt.b; t["c"] = bt.c;

            ret[buf.format("%i", i).get_buf()] = t;
        }

        return ret;
    }

    lua::Table _lua_findanims(const char *pattern)
    {
        vector<int> anims;
        findanims(pattern, anims);

        lua::Table ret(lapi::state.new_table());
        for (int i = 0; i < anims.length(); ++i)
            ret[i + 1] = anims[i];
        return ret;
    }
#else
    LAPI_EMPTY(mapmodelreset)
    LAPI_EMPTY(mapmodel)
    LAPI_EMPTY(nummapmodels)
    LAPI_EMPTY(clearmodel)
    LAPI_EMPTY(mdlname)
    LAPI_EMPTY(mdlalphatest)
    LAPI_EMPTY(mdlalphablend)
    LAPI_EMPTY(mdlalphadepth)
    LAPI_EMPTY(mdlbb)
    LAPI_EMPTY(mdlextendbb)
    LAPI_EMPTY(mdlscale)
    LAPI_EMPTY(mdlspec)
    LAPI_EMPTY(mdlglow)
    LAPI_EMPTY(mdlglare)
    LAPI_EMPTY(mdlambient)
    LAPI_EMPTY(mdlcullface)
    LAPI_EMPTY(mdldepthoffset)
    LAPI_EMPTY(mdlfullbright)
    LAPI_EMPTY(mdlspin)
    LAPI_EMPTY(mdlenvmap)
    LAPI_EMPTY(mdlshader)
    LAPI_EMPTY(mdltrans)
    LAPI_EMPTY(mdlyaw)
    LAPI_EMPTY(mdlpitch)
    LAPI_EMPTY(mdlshadow)
    LAPI_EMPTY(mdlcollide)
    LAPI_EMPTY(mdlperentitycollisionboxes)
    LAPI_EMPTY(mdlellipsecollide)
    LAPI_EMPTY(rdvert)
    LAPI_EMPTY(rdeye)
    LAPI_EMPTY(rdtri)
    LAPI_EMPTY(rdjoint)
    LAPI_EMPTY(rdlimitdist)
    LAPI_EMPTY(rdlimitrot)
    LAPI_EMPTY(rdanimjoints)
    LAPI_EMPTY(preloadmodel)
    LAPI_EMPTY(reloadmodel)
    LAPI_EMPTY(rendermodel)
    LAPI_EMPTY(scriptmdlbb)
    LAPI_EMPTY(scriptmdlcb)
    LAPI_EMPTY(mdlmesh)
    LAPI_EMPTY(findanims)
#endif

    void reg_model(lua::Table& t)
    {
        LAPI_REG(mapmodelreset);
        LAPI_REG(mapmodel);
        LAPI_REG(nummapmodels);
        LAPI_REG(clearmodel);
        LAPI_REG(mdlname);
        LAPI_REG(mdlalphatest);
        LAPI_REG(mdlalphablend);
        LAPI_REG(mdlalphadepth);
        LAPI_REG(mdlbb);
        LAPI_REG(mdlextendbb);
        LAPI_REG(mdlscale);
        LAPI_REG(mdlspec);
        LAPI_REG(mdlglow);
        LAPI_REG(mdlglare);
        LAPI_REG(mdlambient);
        LAPI_REG(mdlcullface);
        LAPI_REG(mdldepthoffset);
        LAPI_REG(mdlfullbright);
        LAPI_REG(mdlspin);
        LAPI_REG(mdlenvmap);
        LAPI_REG(mdlshader);
        LAPI_REG(mdltrans);
        LAPI_REG(mdlyaw);
        LAPI_REG(mdlpitch);
        LAPI_REG(mdlshadow);
        LAPI_REG(mdlcollide);
        LAPI_REG(mdlperentitycollisionboxes);
        LAPI_REG(mdlellipsecollide);
        LAPI_REG(rdvert);
        LAPI_REG(rdeye);
        LAPI_REG(rdtri);
        LAPI_REG(rdjoint);
        LAPI_REG(rdlimitdist);
        LAPI_REG(rdlimitrot);
        LAPI_REG(rdanimjoints);
        LAPI_REG(preloadmodel);
        LAPI_REG(reloadmodel);
        LAPI_REG(rendermodel);
        LAPI_REG(scriptmdlbb);
        LAPI_REG(scriptmdlcb);
        LAPI_REG(mdlmesh);
        LAPI_REG(findanims);
    }
}
