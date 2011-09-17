/*
 * of_lua_model.h, version 1
 * Model handling for Lua
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

/* PROTOTYPES */
void mapmodelreset(int n);
void mmodel(char *name);
extern vector<mapmodelinfo> mapmodels;
void clearmodel(char *name);

void mdlname();
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
void rdjoint(int n, int t, char *v1, char *v2, char *v3);
void rdlimitdist(int v1, int v2, float mindist, float maxdist);
void rdlimitrot(int t1, int t2, float maxangle, float qx, float qy, float qz, float qw);
void rdanimjoints(bool on);

void clearmodel(char *name);

VARP(ragdoll, 0, 1, 1);

namespace lua_binds
{
    LUA_BIND_DEF(mapmodelreset, mapmodelreset(e.get<int>(1));)
    LUA_BIND_DEF(mapmodel, mmodel(e.get<char*>(1));)
    LUA_BIND_DEF(nummapmodels, e.push(mapmodels.length());)
    LUA_BIND_STD(clearmodel, clearmodel, e.get<char*>(1))

    LUA_BIND_STD(mdlname, mdlname)
    LUA_BIND_STD(mdlalphatest, mdlalphatest, e.get<float>(1))
    LUA_BIND_STD(mdlalphablend, mdlalphablend, e.get<bool>(1))
    LUA_BIND_STD(mdlalphadepth, mdlalphadepth, e.get<bool>(1))
    LUA_BIND_STD(mdlbb, mdlbb, e.get<float>(1), e.get<float>(2), e.get<float>(3))
    LUA_BIND_STD(mdlextendbb, mdlextendbb, e.get<vec>(1))
    LUA_BIND_STD(mdlscale, mdlscale, e.get<int>(1))
    LUA_BIND_STD(mdlspec, mdlspec, e.get<int>(1))
    LUA_BIND_STD(mdlglow, mdlglow, e.get<int>(1), e.get<int>(2), e.get<float>(3))
    LUA_BIND_STD(mdlglare, mdlglare, e.get<float>(1), e.get<float>(2))
    LUA_BIND_STD(mdlambient, mdlambient, e.get<int>(1))
    LUA_BIND_STD(mdlcullface, mdlcullface, e.get<bool>(1))
    LUA_BIND_STD(mdldepthoffset, mdldepthoffset, e.get<bool>(1))
    LUA_BIND_STD(mdlfullbright, mdlfullbright, e.get<float>(1))
    LUA_BIND_STD(mdlspin, mdlspin, e.get<float>(1), e.get<float>(2))
    LUA_BIND_STD(mdlenvmap, mdlenvmap, e.get<float>(1), e.get<float>(2), e.get<char*>(3))
    LUA_BIND_STD(mdlshader, mdlshader, e.get<char*>(1))
    LUA_BIND_STD(mdltrans, mdltrans, e.get<vec>(1))
    LUA_BIND_STD(mdlyaw, mdlyaw, e.get<float>(1))
    LUA_BIND_STD(mdlpitch, mdlpitch, e.get<float>(1))
    LUA_BIND_STD(mdlshadow, mdlshadow, e.get<bool>(1))
    LUA_BIND_STD(mdlcollide, mdlcollide, e.get<bool>(1))
    LUA_BIND_STD(mdlperentitycollisionboxes, mdlperentitycollisionboxes, e.get<bool>(1))
    LUA_BIND_STD(mdlellipsecollide, mdlellipsecollide, e.get<bool>(1))

    LUA_BIND_STD(rdvert, rdvert, e.get<vec>(1), e.get<float>(2));
    LUA_BIND_STD(rdeye, rdeye, e.get<int>(1));
    LUA_BIND_STD(rdtri, rdtri, e.get<int>(1), e.get<int>(2), e.get<int>(3));
    LUA_BIND_STD(rdjoint, rdjoint, e.get<int>(1), e.get<int>(2), e.get<char*>(3), e.get<char*>(4), e.get<char*>(5));
    LUA_BIND_STD(rdlimitdist, rdlimitdist, e.get<int>(1), e.get<int>(2), e.get<float>(3), e.get<float>(4));
    LUA_BIND_STD(rdlimitrot, rdlimitrot, e.get<int>(1), e.get<int>(2), e.get<float>(3), e.get<float>(4), e.get<float>(5), e.get<float>(6), e.get<float>(7));
    LUA_BIND_STD(rdanimjoints, rdanimjoints, e.get<bool>(1));

    LUA_BIND_STD(preloadmodel, preloadmodel, e.get<const char*>(1))
    LUA_BIND_DEF(reloadmodel, {
        const char *name = e.get<const char*>(1);
        if (!name) return;
        model *old = loadmodel(name);
        if (!old) return;
        
        defformatstring(cmd)("CAPI.clearmodel(\"%s\")", name);
        lua::engine.exec(cmd);

        model* _new = loadmodel(name);

        lua::engine.getg("entity_store").t_getraw("get_all").call(0, 1);
        LUA_TABLE_FOREACH(lua::engine, {
                CLogicEntity *ent = lua::engine.get<CLogicEntity*>(-1);
                if (ent->theModel == old) ent->theModel = _new;
                e.pop(1);
        })
        lua::engine.pop(1);
    })

#ifdef CLIENT
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
                engine.getref(self->luaRef).t_getraw("set_local_animation").push_index(-2).push(anim).call(2, 0);
                engine.pop(1);
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
        engine.getref(self->luaRef).t_getraw("rendering_hash_hint");
        if (!engine.is<void>(-1))
        {
            static bool initialized = false;
            static fpsent *fpsentsfr[1024];
            if (!initialized)
            {
                for (int i = 0; i < 1024; i++) fpsentsfr[i] = new fpsent;
                initialized = true;
            }

            int rhashhint = engine.get<int>(-1);
            engine.pop(2);
            rhashhint = rhashhint & 1023;
            assert(rhashhint >= 0 && rhashhint < 1024);
            return fpsentsfr[rhashhint];
        }
        else
        {
            engine.pop(2);
            return NULL;
        }
    }

    LUA_BIND_LE(rendermodel, {
        int anim = e.get<int>(3);

        preparerd(anim, self);
        fpsent *fp = NULL;
        if (self->dynamicEntity) fp = (fpsent*)self->dynamicEntity;
        else fp = getproxyfpsent(self);
        rendermodel(NULL,
                    e.get<const char*>(2),
                    anim, e.get<vec>(4), self,
                    e.get<float>(5),
                    e.get<float>(6),
                    e.get<int>(7),
                    fp,
                    self->attachments,
                    e.get<int>(8),
                    0, 1);
    })
#else
    LUA_BIND_DUMMY(rendermodel)
#endif

    LUA_BIND_DEF(scriptmdlbb, {
        model* theModel = loadmodel(e.get<const char*>(1));
        if (!theModel)
        {
            e.push();
            return;
        }
        vec center;
        vec radius;
        theModel->boundbox(0, center, radius);

        e.t_new().t_set("center", center).t_set("radius", radius);
    });

    LUA_BIND_DEF(scriptmdlcb, {
        model* theModel = loadmodel(e.get<const char*>(1));
        if (!theModel)
        {
            e.push();
            return;
        }
        vec center;
        vec radius;
        theModel->collisionbox(0, center, radius);

        e.t_new().t_set("center", center).t_set("radius", radius);
    });

    LUA_BIND_DEF(mdlmesh, {
        model* theModel = loadmodel(e.get<const char*>(1));
        if (!theModel)
        {
            e.push();
            return;
        }

        vector<BIH::tri> tris2[2];
        theModel->gentris(0, tris2);
        vector<BIH::tri>& tris = tris2[0];
        types::string buf;

        e.t_new().t_set("length", tris.length());
        for (int i = 0; i < tris.length(); i++)
        {
            BIH::tri& bt = tris[i];
            e.push(buf.format("%i", i).buf)
                .t_new()
                .t_set("a", bt.a)
                .t_set("b", bt.b)
                .t_set("c", bt.c)
                .t_set();
        }
    });

    LUA_BIND_DEF(findanims, {
        vector<int> anims;
        findanims(e.get<char*>(1), anims);

        e.t_new();
        loopv(anims) e.t_set(i + 1, anims[i]);
    });
}
