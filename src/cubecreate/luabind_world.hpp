/*
 * luabind_world.hpp, version 1
 * Geometry utilities and world methods
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
extern float GRAVITY;
extern int entlooplevel, efocus, enthover, oldhover;
extern bool undonext;
extern selinfo sel;
void entadd(int id);
bool noentedit();
void printent(extentity &e, char *buf);
void nearestent();
void entset(char *what, int *a1, int *a2, int *a3, int *a4, int *a5);
void addentity(int id);
void removeentity(int id);
void detachentity(extentity &e);
void entautoview(int *dir);
void entflip();
void entrotate(int *cw);
void entpush(int *dir);
void attachent();
void newent(char *what, int *a1, int *a2, int *a3, int *a4, int *a5);
void delent();
void dropent();
void entcopy();
void entpaste();
void intensityentcopy();
void intensitypasteent();
void newmap(int *i);
void mapenlarge();
void shrinkmap();
void writeobj(char *name);

namespace lua_binds
{
    /* Geometry utilities */

    LUA_BIND_DEF(raylos, {
        vec a(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        vec b(e.get<double>(4), e.get<double>(5), e.get<double>(6));
        vec target;

        bool ret = raycubelos(a, b, target);
        e.push(ret);
    })

    LUA_BIND_DEF(raypos, {
        vec o(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        vec ray(e.get<double>(4), e.get<double>(5), e.get<double>(6));
        vec hitpos(0);

        e.push(raycubepos(o, ray, hitpos, e.get<double>(7), RAY_CLIPMAT|RAY_POLY));
    })

    LUA_BIND_DEF(rayfloor, {
        vec o(e.get<double>(1), e.get<double>(2), e.get<double>(3));
        vec floor(0);

        e.push(rayfloor(o, floor, 0, e.get<double>(4)));
    })

    LUA_BIND_CLIENT(gettargetpos, {
        // Force a determination, if needed
        TargetingControl::determineMouseTarget(true);
        e.push(TargetingControl::targetPosition);
    })

    LUA_BIND_CLIENT(gettargetent, {
        TargetingControl::determineMouseTarget(true);
        LogicEntityPtr target = TargetingControl::targetLogicEntity;
        if (target.get() && !target->isNone() && target->luaRef >= 0)
             e.getref(target->luaRef);
        else e.push();
    })

    /* World */

    LUA_BIND_DEF(iscolliding, {
        vec pos(e.get<double>(1), e.get<double>(2), e.get<double>(3));

        // TODO: Make faster, avoid this lookup
        e.push(PhysicsManager::getEngine()->isColliding(
            pos,
            e.get<double>(4),
            e.get<int>(5) != -1 ? LogicSystem::getLogicEntity(e.get<int>(5)).get() : NULL)
        );
    })

    LUA_BIND_DEF(setgravity, {
        if (PhysicsManager::hasEngine())
            PhysicsManager::getEngine()->setGravity(e.get<double>(1));
        else
        {
            Logging::log(Logging::DEBUG, "Setting gravity using sauer system, as no physics engine\r\n");
            GRAVITY = e.get<double>(1);
        }
    })

    LUA_BIND_DEF(getmat, e.push(lookupmaterial(vec(e.get<double>(1), e.get<double>(2), e.get<double>(3))));)

    // TODO: REMOVE THESE
    #define addimplicit(f)  { if(entgroup.empty() && enthover>=0) { entadd(enthover); undonext = (enthover != oldhover); f; entgroup.drop(); } else f; }
    #define entfocus(i, f)  { int n = efocus = (i); if(n>=0) { extentity &ent = *entities::getents()[n]; f; } }
    #define entedit(i, f) \
    { \
        entfocus(i, \
        int oldtype = ent.type; \
        removeentity(n);  \
        f; \
        if(oldtype!=ent.type) detachentity(ent); \
        if(ent.type!=ET_EMPTY) { addentity(n); if(oldtype!=ent.type) attachentity(ent); } \
        entities::editent(n, true)); \
    }
    #define addgroup(exp)   { loopv(entities::getents()) entfocus(i, if(exp) entadd(n)); }
    #define setgroup(exp)   { entcancel(); addgroup(exp); }
    #define groupeditloop(f){ entlooplevel++; int _ = efocus; loopv(entgroup) entedit(entgroup[i], f); efocus = _; entlooplevel--; }
    #define groupeditpure(f){ if(entlooplevel>0) { entedit(efocus, f); } else groupeditloop(f); }
    #define groupeditundo(f){ makeundoent(); groupeditpure(f); }
    #define groupedit(f)    { addimplicit(groupeditundo(f)); }

    LUA_BIND_STD(entautoview, entautoview, e.get<int*>(1))
    LUA_BIND_STD(entflip, entflip)
    LUA_BIND_STD(entrotate, entrotate, e.get<int*>(1))
    LUA_BIND_STD(entpush, entpush, e.get<int*>(1))
    LUA_BIND_STD(attachent, attachent)
    LUA_BIND_STD(newent, newent, e.get<char*>(1), e.get<int*>(2), e.get<int*>(3), e.get<int*>(4), e.get<int*>(5), e.get<int*>(6))
    LUA_BIND_STD(delent, delent)
    LUA_BIND_STD(dropent, dropent)
    LUA_BIND_STD(entcopy, entcopy)
    LUA_BIND_STD(entpaste, entpaste)
    LUA_BIND_STD(enthavesel, addimplicit, e.push(entgroup.length()))
    LUA_BIND_DEF(entselect, if (!noentedit()) addgroup(ent.type != ET_EMPTY && entgroup.find(n)<0 && e.exec<bool>(e.get<const char*>(1)) == true);)
    LUA_BIND_DEF(entloop, if(!noentedit()) addimplicit(groupeditloop(((void)ent, e.exec(e.get<const char*>(1)))));)
    LUA_BIND_DEF(insel, entfocus(efocus, e.push(pointinsel(sel, ent.o)));)
    LUA_BIND_DEF(entget, entfocus(efocus, string s; printent(ent, s); e.push(s));)
    LUA_BIND_STD(entindex, e.push, efocus)
    LUA_BIND_STD(entset, entset, e.get<char*>(1), e.get<int*>(2), e.get<int*>(3), e.get<int*>(4), e.get<int*>(5), e.get<int*>(6))
    LUA_BIND_STD(nearestent, nearestent)
    LUA_BIND_STD(intensityentcopy, intensityentcopy)
    LUA_BIND_STD(intensitypasteent, intensitypasteent)
    LUA_BIND_STD(newmap, newmap, e.get<int*>(1))
    LUA_BIND_STD(mapenlarge, mapenlarge)
    LUA_BIND_STD(shrinkmap, shrinkmap)
    LUA_BIND_STD(mapname, e.push, game::getclientmap())
    // In our new system, this is called when dragging concludes. Only then do we update the server.
    // This facilitates smooth dragging on the client, and a single bandwidth use at the end.
    LUA_BIND_DEF(finish_dragging, {
        groupeditpure(
            defformatstring(c)("cc.logent.store.get(%i).position = {%f,%f,%f}", LogicSystem::getUniqueId(&ent), ent.o[0], ent.o[1], ent.o[2]);
            e.exec(c);
        );
    })

    LUA_BIND_DEF(mapcfgname, {
        const char *mname = game::getclientmap();
        if(!*mname) mname = "untitled";

        string pakname;
        string mapname;
        string mcfgname;
        getmapfilenames(mname, NULL, pakname, mapname, mcfgname);
        defformatstring(cfgname)("data/%s/%s.lua", pakname, mcfgname);
        path(cfgname);
        e.push(cfgname);
    })

    LUA_BIND_STD(writeobj, writeobj, e.get<char*>(1))

    LUA_BIND_DEF(export_entities, {
        REFLECT_PYTHON(export_entities);
        export_entities(e.get<const char*>(1));
    })
}
