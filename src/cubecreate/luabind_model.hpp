/*
 * luabind_model.hpp, version 1
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
void mapmodelreset(int *n);
void mmodel(char *name);
extern vector<mapmodelinfo> mapmodels;
void clearmodel(char *name);

void mdlname();
void mdlalphatest(float *cutoff);
void mdlalphablend(int *blend);
void mdlalphadepth(int *depth);
void mdldepthoffset(int *offset);
void mdlcullface(int *cullface);
void mdlcollide(int *collide);
void mdlellipsecollide(int *collide);
void mdlspec(int *percent);
void mdlambient(int *percent);
void mdlglow(int *percent);
void mdlglare(float *specglare, float *glowglare);
void mdlenvmap(float *envmapmax, float *envmapmin, char *envmap);
void mdlfullbright(float *fullbright);
void mdlshader(char *shader);
void mdlspin(float *yaw, float *pitch);
void mdlscale(int *percent);
void mdltrans(float *x, float *y, float *z);
void mdlyaw(float *angle);
void mdlpitch(float *angle);
void mdlshadow(int *shadow);
void mdlbb(float *rad, float *h, float *eyeheight);
void mdlextendbb(float *x, float *y, float *z);
void mdlcollisionsonlyfortriggering(int *val);
void mdlperentitycollisionboxes(int *val);
void rdvert(float *x, float *y, float *z, float *radius);
void rdeye(int *v);
void rdtri(int *v1, int *v2, int *v3);
void rdjoint(int *n, int *t, char *v1, char *v2, char *v3);
void rdlimitdist(int *v1, int *v2, float *mindist, float *maxdist);
void rdlimitrot(int *t1, int *t2, float *maxangle, float *qx, float *qy, float *qz, float *qw);
void rdanimjoints(int *on);

void objload(char *model, float *smooth);
void objpitch(float *pitchscale, float *pitchoffset, float *pitchmin, float *pitchmax);
void objskin(char *meshname, char *tex, char *masks, float *envmapmax, float *envmapmin);
void objspec(char *meshname, int *percent);
void objambient(char *meshname, int *percent);
void objglow(char *meshname, int *percent);
void objglare(char *meshname, float *specglare, float *glowglare);
void objalphatest(char *meshname, float *cutoff);
void objalphablend(char *meshname, int *blend);
void objcullface(char *meshname, int *cullface);
void objenvmap(char *meshname, char *envmap);
void objbumpmap(char *meshname, char *normalmap, char *skin);
void objfullbright(char *meshname, float *fullbright);
void objshader(char *meshname, char *shader);
void objscroll(char *meshname, float *scrollu, float *scrollv);
void objnoclip(char *meshname, int *noclip);

void setmd5dir(char *name);  
void md5load(char *meshfile, char *skelname, float *smooth);
void md5tag(char *name, char *tagname);        
void md5pitch(char *name, float *pitchscale, float *pitchoffset, float *pitchmin, float *pitchmax);
void md5adjust(char *name, float *yaw, float *pitch, float *roll, float *tx, float *ty, float *tz);
void md5skin(char *meshname, char *tex, char *masks, float *envmapmax, float *envmapmin);
void md5spec(char *meshname, int *percent);
void md5ambient(char *meshname, int *percent);
void md5glow(char *meshname, int *percent);
void md5glare(char *meshname, float *specglare, float *glowglare);
void md5alphatest(char *meshname, float *cutoff);
void md5alphablend(char *meshname, int *blend);
void md5cullface(char *meshname, int *cullface);
void md5envmap(char *meshname, char *envmap);
void md5bumpmap(char *meshname, char *normalmap, char *skin);
void md5fullbright(char *meshname, float *fullbright);
void md5shader(char *meshname, char *shader);
void md5scroll(char *meshname, float *scrollu, float *scrollv);
void md5anim(char *anim, char *animfile, float *speed, int *priority);
void md5animpart(char *maskstr);
void md5link(int *parent, int *child, char *tagname, float *x, float *y, float *z);
void md5noclip(char *meshname, int *noclip);

void setiqmdir(char *name);  
void iqmload(char *meshfile, char *skelname);
void iqmtag(char *name, char *tagname);        
void iqmpitch(char *name, float *pitchscale, float *pitchoffset, float *pitchmin, float *pitchmax);
void iqmadjust(char *name, float *yaw, float *pitch, float *roll, float *tx, float *ty, float *tz);
void iqmskin(char *meshname, char *tex, char *masks, float *envmapmax, float *envmapmin);
void iqmspec(char *meshname, int *percent);
void iqmambient(char *meshname, int *percent);
void iqmglow(char *meshname, int *percent);
void iqmglare(char *meshname, float *specglare, float *glowglare);
void iqmalphatest(char *meshname, float *cutoff);
void iqmalphablend(char *meshname, int *blend);
void iqmcullface(char *meshname, int *cullface);
void iqmenvmap(char *meshname, char *envmap);
void iqmbumpmap(char *meshname, char *normalmap, char *skin);
void iqmfullbright(char *meshname, float *fullbright);
void iqmshader(char *meshname, char *shader);
void iqmscroll(char *meshname, float *scrollu, float *scrollv);
void iqmanim(char *anim, char *animfile, float *speed, int *priority);
void iqmanimpart(char *maskstr);
void iqmlink(int *parent, int *child, char *tagname, float *x, float *y, float *z);
void iqmnoclip(char *meshname, int *noclip);

void setsmddir(char *name);  
void smdload(char *meshfile, char *skelname);
void smdtag(char *name, char *tagname);        
void smdpitch(char *name, float *pitchscale, float *pitchoffset, float *pitchmin, float *pitchmax);
void smdadjust(char *name, float *yaw, float *pitch, float *roll, float *tx, float *ty, float *tz);
void smdskin(char *meshname, char *tex, char *masks, float *envmapmax, float *envmapmin);
void smdspec(char *meshname, int *percent);
void smdambient(char *meshname, int *percent);
void smdglow(char *meshname, int *percent);
void smdglare(char *meshname, float *specglare, float *glowglare);
void smdalphatest(char *meshname, float *cutoff);
void smdalphablend(char *meshname, int *blend);
void smdcullface(char *meshname, int *cullface);
void smdenvmap(char *meshname, char *envmap);
void smdbumpmap(char *meshname, char *normalmap, char *skin);
void smdfullbright(char *meshname, float *fullbright);
void smdshader(char *meshname, char *shader);
void smdscroll(char *meshname, float *scrollu, float *scrollv);
void smdanim(char *anim, char *animfile, float *speed, int *priority);
void smdanimpart(char *maskstr);
void smdlink(int *parent, int *child, char *tagname, float *x, float *y, float *z);
void smdnoclip(char *meshname, int *noclip);

void clearmodel(char *name);

namespace lua_binds
{
    LUA_BIND_DEF(mapmodelreset, mapmodelreset(e.get<int*>(1));)
    LUA_BIND_DEF(mapmodel, mmodel(e.get<char*>(1));)
    LUA_BIND_DEF(nummapmodels, e.push(mapmodels.length());)
    LUA_BIND_STD(clearmodel, clearmodel, e.get<char*>(1))

    LUA_BIND_STD(mdlname, mdlname)
    LUA_BIND_STD(mdlalphatest, mdlalphatest, e.get<float*>(1))
    LUA_BIND_STD(mdlalphablend, mdlalphablend, e.get<int*>(1))
    LUA_BIND_STD(mdlalphadepth, mdlalphadepth, e.get<int*>(1))
    LUA_BIND_STD(mdlbb, mdlbb, e.get<float*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(mdlextendbb, mdlextendbb, e.get<float*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(mdlscale, mdlscale, e.get<int*>(1))
    LUA_BIND_STD(mdlspec, mdlspec, e.get<int*>(1))
    LUA_BIND_STD(mdlglow, mdlglow, e.get<int*>(1))
    LUA_BIND_STD(mdlglare, mdlglare, e.get<float*>(1), e.get<float*>(2))
    LUA_BIND_STD(mdlambient, mdlambient, e.get<int*>(1))
    LUA_BIND_STD(mdlcullface, mdlcullface, e.get<int*>(1))
    LUA_BIND_STD(mdldepthoffset, mdldepthoffset, e.get<int*>(1))
    LUA_BIND_STD(mdlfullbright, mdlfullbright, e.get<float*>(1))
    LUA_BIND_STD(mdlspin, mdlspin, e.get<float*>(1), e.get<float*>(2))
    LUA_BIND_STD(mdlenvmap, mdlenvmap, e.get<float*>(1), e.get<float*>(2), e.get<char*>(3))
    LUA_BIND_STD(mdlshader, mdlshader, e.get<char*>(1))
    LUA_BIND_STD(mdlcollisionsonlyfortriggering, mdlcollisionsonlyfortriggering, e.get<int*>(1))
    LUA_BIND_STD(mdltrans, mdltrans, e.get<float*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(mdlyaw, mdlyaw, e.get<float*>(1))
    LUA_BIND_STD(mdlpitch, mdlpitch, e.get<float*>(1))
    LUA_BIND_STD(mdlshadow, mdlshadow, e.get<int*>(1))
    LUA_BIND_STD(mdlcollide, mdlcollide, e.get<int*>(1))
    LUA_BIND_STD(mdlperentitycollisionboxes, mdlperentitycollisionboxes, e.get<int*>(1))
    LUA_BIND_STD(mdlellipsecollide, mdlellipsecollide, e.get<int*>(1))

    LUA_BIND_STD(objload, objload, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(objskin, objskin, e.get<char*>(1), e.get<char*>(2), e.get<char*>(3), e.get<float*>(4), e.get<float*>(5))
    LUA_BIND_STD(objbumpmap, objbumpmap, e.get<char*>(1), e.get<char*>(2), e.get(3, (char*)""))
    LUA_BIND_STD(objenvmap, objenvmap, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(objspec, objspec, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(objpitch, objpitch, e.get<float*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4))
    LUA_BIND_STD(objambient, objambient, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(objglow, objglow, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(objglare, objglare, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(objalphatest, objalphatest, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(objalphablend, objalphablend, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(objcullface, objcullface, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(objfullbright, objfullbright, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(objshader, objshader, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(objscroll, objscroll, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(objnoclip, objnoclip, e.get<char*>(1), e.get<int*>(2))

    LUA_BIND_STD(md5dir, setmd5dir, e.get<char*>(1))
    LUA_BIND_STD(md5load, md5load, e.get<char*>(1), e.get<char*>(2), e.get<float*>(3))
    LUA_BIND_STD(md5tag, md5tag, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(md5pitch, md5pitch, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4), e.get<float*>(5))
    LUA_BIND_STD(md5adjust, md5adjust, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4), e.get<float*>(5), e.get<float*>(6), e.get<float*>(7))
    LUA_BIND_STD(md5skin, md5skin, e.get<char*>(1), e.get<char*>(2), e.get(3, (char*)""), e.get<float*>(4), e.get<float*>(5))
    LUA_BIND_STD(md5spec, md5spec, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(md5ambient, md5ambient, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(md5glow, md5glow, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(md5glare, md5glare, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(md5alphatest, md5alphatest, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(md5alphablend, md5alphablend, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(md5cullface, md5cullface, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(md5envmap, md5envmap, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(md5bumpmap, md5bumpmap, e.get<char*>(1), e.get<char*>(2), e.get(3, (char*)""))
    LUA_BIND_STD(md5fullbright, md5fullbright, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(md5shader, md5shader, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(md5scroll, md5scroll, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(md5animpart, md5animpart, e.get<char*>(1))
    LUA_BIND_STD(md5anim, md5anim, e.get<char*>(1), e.get<char*>(2), e.get<float*>(3), e.get<int*>(4))
    LUA_BIND_STD(md5link, md5link, e.get<int*>(1), e.get<int*>(2), e.get<char*>(3), e.get<float*>(4), e.get<float*>(5), e.get<float*>(6))
    LUA_BIND_STD(md5noclip, md5noclip, e.get<char*>(1), e.get<int*>(2))

    LUA_BIND_STD(iqmdir, setiqmdir, e.get<char*>(1))
    LUA_BIND_STD(iqmload, iqmload, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(iqmtag, iqmtag, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(iqmpitch, iqmpitch, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4), e.get<float*>(5))
    LUA_BIND_STD(iqmadjust, iqmadjust, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4), e.get<float*>(5), e.get<float*>(6), e.get<float*>(7))
    LUA_BIND_STD(iqmskin, iqmskin, e.get<char*>(1), e.get<char*>(2), e.get(3, (char*)""), e.get<float*>(4), e.get<float*>(5))
    LUA_BIND_STD(iqmspec, iqmspec, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(iqmambient, iqmambient, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(iqmglow, iqmglow, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(iqmglare, iqmglare, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(iqmalphatest, iqmalphatest, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(iqmalphablend, iqmalphablend, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(iqmcullface, iqmcullface, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(iqmenvmap, iqmenvmap, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(iqmbumpmap, iqmbumpmap, e.get<char*>(1), e.get<char*>(2), e.get(3, (char*)""))
    LUA_BIND_STD(iqmfullbright, iqmfullbright, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(iqmshader, iqmshader, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(iqmscroll, iqmscroll, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(iqmanimpart, iqmanimpart, e.get<char*>(1))
    LUA_BIND_STD(iqmanim, iqmanim, e.get<char*>(1), e.get<char*>(2), e.get<float*>(3), e.get<int*>(4))
    LUA_BIND_STD(iqmlink, iqmlink, e.get<int*>(1), e.get<int*>(2), e.get<char*>(3), e.get<float*>(4), e.get<float*>(5), e.get<float*>(6))
    LUA_BIND_STD(iqmnoclip, iqmnoclip, e.get<char*>(1), e.get<int*>(2))

    LUA_BIND_STD(smddir, setsmddir, e.get<char*>(1))
    LUA_BIND_STD(smdload, smdload, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(smdtag, smdtag, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(smdpitch, smdpitch, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4), e.get<float*>(5))
    LUA_BIND_STD(smdadjust, smdadjust, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4), e.get<float*>(5), e.get<float*>(6), e.get<float*>(7))
    LUA_BIND_STD(smdskin, smdskin, e.get<char*>(1), e.get<char*>(2), e.get(3, (char*)""), e.get<float*>(4), e.get<float*>(5))
    LUA_BIND_STD(smdspec, smdspec, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(smdambient, smdambient, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(smdglow, smdglow, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(smdglare, smdglare, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(smdalphatest, smdalphatest, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(smdalphablend, smdalphablend, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(smdcullface, smdcullface, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(smdenvmap, smdenvmap, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(smdbumpmap, smdbumpmap, e.get<char*>(1), e.get<char*>(2), e.get(3, (char*)""))
    LUA_BIND_STD(smdfullbright, smdfullbright, e.get<char*>(1), e.get<float*>(2))
    LUA_BIND_STD(smdshader, smdshader, e.get<char*>(1), e.get<char*>(2))
    LUA_BIND_STD(smdscroll, smdscroll, e.get<char*>(1), e.get<float*>(2), e.get<float*>(3))
    LUA_BIND_STD(smdanimpart, smdanimpart, e.get<char*>(1))
    LUA_BIND_STD(smdanim, smdanim, e.get<char*>(1), e.get<char*>(2), e.get<float*>(3), e.get<int*>(4))
    LUA_BIND_STD(smdlink, smdlink, e.get<int*>(1), e.get<int*>(2), e.get<char*>(3), e.get<float*>(4), e.get<float*>(5), e.get<float*>(6))
    LUA_BIND_STD(smdnoclip, smdnoclip, e.get<char*>(1), e.get<int*>(2))

    LUA_BIND_STD(rdvert, rdvert, e.get<float*>(1), e.get<float*>(2), e.get<float*>(3), e.get<float*>(4));
    LUA_BIND_STD(rdeye, rdeye, e.get<int*>(1));
    LUA_BIND_STD(rdtri, rdtri, e.get<int*>(1), e.get<int*>(2), e.get<int*>(3));
    LUA_BIND_STD(rdjoint, rdjoint, e.get<int*>(1), e.get<int*>(2), e.get<char*>(3), e.get<char*>(4), e.get<char*>(5));
    LUA_BIND_STD(rdlimitdist, rdlimitdist, e.get<int*>(1), e.get<int*>(2), e.get<float*>(3), e.get<float*>(4));
    LUA_BIND_STD(rdlimitrot, rdlimitrot, e.get<int*>(1), e.get<int*>(2), e.get<float*>(3), e.get<float*>(4), e.get<float*>(5), e.get<float*>(6), e.get<float*>(7));
    LUA_BIND_STD(rdanimjoints, rdanimjoints, e.get<int*>(1));

    LUA_BIND_STD(preloadmodel, preloadmodel, e.get<const char*>(1))
    LUA_BIND_DEF(reloadmodel, {
        const char *name = e.get<const char*>(1);
        model *old = loadmodel(name);
        if (!old) return;
        
        defformatstring(cmd)("CAPI.clearmodel(\"%s\")", name);
        lua::engine.exec(cmd);

        model* _new = loadmodel(name);

        for (LogicSystem::LogicEntityMap::iterator iter = LogicSystem::logicEntities.begin()
                ;iter != LogicSystem::logicEntities.end()
                ;iter++
            )
        {
            LogicEntityPtr entity = iter->second;
            if (entity->theModel == old) entity->theModel = _new;
        }
    })

#ifdef CLIENT
    static int oldtp = -1;

    void preparerd(int& anim, LogicEntityPtr self)
    {
        if (anim&ANIM_RAGDOLL)
        {
            //if (!ragdoll || loadmodel(mdl);
            fpsent *fp = (fpsent*)self->dynamicEntity;

            if (fp->clientnum == ClientSystem::playerNumber)
            {
                if (oldtp == -1 && GETIV(thirdperson) == 0)
                {
                    oldtp = GETIV(thirdperson);
                    SETV(thirdperson, 1);
                }
            }

            if (fp->ragdoll || !GETIV(ragdoll) || !PhysicsManager::getEngine()->prepareRagdoll(self))
            {
                anim &= ~ANIM_RAGDOLL;
                engine.getref(self.get()->luaRef).t_getraw("set_localanim").push_index(-2).push(anim).call(2, 0);
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

    fpsent *getproxyfpsent(LogicEntityPtr self)
    {
        engine.getref(self.get()->luaRef).t_getraw("rendering_hash_hint");
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

    #define PREP_RENDER_MODEL \
    int anim = e.get<int>(3); \
    \
    preparerd(anim, self); \
    \
    vec o(e.get<float>(4), e.get<float>(5), e.get<float>(6)); \
    fpsent *fp = NULL; \
    \
    if (self->dynamicEntity) fp = (fpsent*)self->dynamicEntity; \
    else fp = getproxyfpsent(self);

    LUA_BIND_LE(rendermodel, {
        PREP_RENDER_MODEL
        quat rotation(e.get<float>(12), e.get<float>(13), e.get<float>(14), e.get<float>(15));
        rendermodel(NULL,
                    e.get<const char*>(2),
                    anim, o, self,
                    e.get<float>(7),
                    e.get<float>(8),
                    e.get<float>(9),
                    e.get<int>(10),
                    fp,
                    self->attachments,
                    e.get<int>(11),
                    0, 1, rotation);
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

        e.t_new().t_set("length", tris.length());
        for (int i = 0; i < tris.length(); i++)
        {
            BIH::tri& bt = tris[i];

            e.push(Utility::toString(i).c_str())
                .t_new()
                .t_set("a", bt.a)
                .t_set("b", bt.b)
                .t_set("c", bt.c)
                .t_set();
        }
    });
}
