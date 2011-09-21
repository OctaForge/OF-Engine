/*
 * of_lua_world.h, version 1
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
extern physent *hitplayer;
void entadd(int id);
bool noentedit();
void printent(extentity &e, char *buf);
void nearestent();
void entset(char *what, int a1, int a2, int a3, int a4, int a5);
void addentity(int id);
void removeentity(int id);
void detachentity(extentity &e);
void entautoview(int dir);
void entflip();
void entrotate(int cw);
void entpush(int dir);
void attachent();
void delent();
void dropent();
void entcopy();
void entpaste();
void intensityentcopy();
void intensitypasteent();
void newmap(int i);
void mapenlarge();
void shrinkmap();
void writeobj(char *name);

namespace lua_binds
{
    /* Geometry utilities */

    LUA_BIND_DEF(raylos, {
        vec target;
        e.push(raycubelos(e.get<vec>(1), e.get<vec>(2), target));
    })

    LUA_BIND_DEF(raypos, {
        vec hitpos(0);
        e.push(raycubepos(
            e.get<vec>(1), e.get<vec>(2),
            hitpos, e.get<double>(3), RAY_CLIPMAT|RAY_POLY
        ));
    })

    LUA_BIND_DEF(rayfloor, {
        vec floor(0);
        e.push(rayfloor(e.get<vec>(1), floor, 0, e.get<double>(2)));
    })

    LUA_BIND_CLIENT(gettargetpos, {
        // Force a determination, if needed
        TargetingControl::determineMouseTarget(true);
        e.push(TargetingControl::targetPosition);
    })

    LUA_BIND_CLIENT(gettargetent, {
        TargetingControl::determineMouseTarget(true);
        CLogicEntity *target = TargetingControl::targetLogicEntity;
        if (target && !target->isNone() && target->luaRef >= 0)
             e.getref(target->luaRef);
        else e.push();
    })

    /* World */

    LUA_BIND_DEF(iscolliding, {
        // TODO: Make faster, avoid this lookup
        CLogicEntity *ignore = e.get<int>(3) != -1 ? LogicSystem::getLogicEntity(e.get<int>(3)) : NULL;
        physent tester;
        tester.reset();
        tester.type = ENT_BOUNCE;
        tester.o = e.get<vec>(1);
        tester.radius = tester.xradius = tester.yradius = e.get<double>(2);
        tester.eyeheight = e.get<double>(2);
        tester.aboveeye = e.get<double>(2);

        if (!collide(&tester, vec(0, 0, 0)))
        {
            if (ignore && ignore->isDynamic() && ignore->dynamicEntity == hitplayer)
            {
                // Try to see if the ignore was the sole cause of collision - move it away, test, then move it back
                vec save = ignore->dynamicEntity->o;
                avoidcollision(ignore->dynamicEntity, vec(1,1,1), &tester, 0.1f);
                bool ret = !collide(&tester, vec(0, 0, 0));
                ignore->dynamicEntity->o = save;
                e.push(ret);
                return;
            }
            else
            {
                e.push(true);
                return;
            }
        } else
            e.push(false);
    })

    LUA_BIND_DEF(setgravity, {
        logger::log(logger::DEBUG, "Setting gravity using sauer system, as no physics engine\r\n");
        GRAVITY = e.get<double>(1);
    })

    LUA_BIND_DEF(getmat, e.push(lookupmaterial(e.get<vec>(1)));)

    // TODO: REMOVE THESE
    #define addimplicit(f)  { if(entgroup.empty() && enthover>=0) { entadd(enthover); undonext = (enthover != oldhover); f; entgroup.drop(); } else f; }
    #define entfocus(i, f)  { int n = efocus = (i); if(n>=0) { extentity &ent = *entities::get(n); f; } }
    #define entedit(i, f) \
    { \
        entfocus(i, \
        int oldtype = ent.type; \
        removeentity(n);  \
        f; \
        if(oldtype!=ent.type) detachentity(ent); \
        if(ent.type!=ET_EMPTY) { addentity(n); if(oldtype!=ent.type) attachentity(ent); }) \
    }
    #define addgroup(exp)   { loopv(entities::storage) entfocus(i, if(exp) entadd(n)); }
    #define setgroup(exp)   { entcancel(); addgroup(exp); }
    #define groupeditloop(f){ entlooplevel++; int _ = efocus; loopv(entgroup) entedit(entgroup[i], f); efocus = _; entlooplevel--; }
    #define groupeditpure(f){ if(entlooplevel>0) { entedit(efocus, f); } else groupeditloop(f); }
    #define groupeditundo(f){ makeundoent(); groupeditpure(f); }
    #define groupedit(f)    { addimplicit(groupeditundo(f)); }

    LUA_BIND_STD(entautoview, entautoview, e.get<int>(1))
    LUA_BIND_STD(entflip, entflip)
    LUA_BIND_STD(entrotate, entrotate, e.get<int>(1))
    LUA_BIND_STD(entpush, entpush, e.get<int>(1))
    LUA_BIND_STD(attachent, attachent)
    LUA_BIND_STD(delent, delent)
    LUA_BIND_STD(dropent, dropent)
    LUA_BIND_STD(entcopy, entcopy)
    LUA_BIND_STD(entpaste, entpaste)
    LUA_BIND_STD(enthavesel, addimplicit, e.push(entgroup.length()))
    LUA_BIND_DEF(entselect, {
            if (!noentedit())
            {
                e.push_index(1).call(0, 1);
                addgroup(ent.type != ET_EMPTY && entgroup.find(n)<0 && e.get<bool>(-1) == true);
                e.pop(1);
            }
    })
    LUA_BIND_DEF(entloop, if(!noentedit()) addimplicit(groupeditloop(((void)ent, e.push_index(1), e.call(0, 0))));)
    LUA_BIND_DEF(insel, entfocus(efocus, e.push(pointinsel(sel, ent.o) ? true : false));)
    LUA_BIND_DEF(entget, entfocus(efocus, string s; printent(ent, s); e.push(s));)
    LUA_BIND_STD(entindex, e.push, efocus)
    LUA_BIND_STD(entset, entset, e.get<char*>(1), e.get<int>(2), e.get<int>(3), e.get<int>(4), e.get<int>(5), e.get<int>(6))
    LUA_BIND_STD(nearestent, nearestent)
    LUA_BIND_STD(intensityentcopy, intensityentcopy)
    LUA_BIND_STD(intensitypasteent, intensitypasteent)
    LUA_BIND_STD(newmap, newmap, e.get<int>(1))
    LUA_BIND_STD(mapenlarge, mapenlarge)
    LUA_BIND_STD(shrinkmap, shrinkmap)
    LUA_BIND_STD(mapname, e.push, game::getclientmap().get_buf())
    // In our new system, this is called when dragging concludes. Only then do we update the server.
    // This facilitates smooth dragging on the client, and a single bandwidth use at the end.
    LUA_BIND_DEF(finish_dragging, {
        groupeditpure(
            defformatstring(c)("entity_store.get(%i).position = {%f,%f,%f}", LogicSystem::getUniqueId(&ent), ent.o[0], ent.o[1], ent.o[2]);
            e.exec(c);
        );
    })

    LUA_BIND_DEF(mapcfgname, {
        types::string mname = game::getclientmap();
        if (mname.is_empty()) mname = "untitled";

        string pakname;
        string mapname;
        string mcfgname;
        getmapfilenames(mname.get_buf(), NULL, pakname, mapname, mcfgname);
        defformatstring(cfgname)("data/%s/%s.lua", pakname, mcfgname);
        path(cfgname);
        e.push(cfgname);
    })

    LUA_BIND_STD(writeobj, writeobj, e.get<char*>(1))
    LUA_BIND_STD(export_entities, world::export_ents, e.get<const char*>(1))

    LUA_BIND_CLIENT(map, {
        if (e.is<void>(1))
            local_server::stop();
        else
            local_server::run(e.get<const char*>(1));
    })

    LUA_BIND_STD_CLIENT(hasmap, e.push, local_server::is_running())

    LUA_BIND_DEF(get_map_preview_filename, {
        types::string buf;

        buf.format(
            "data%cmaps%c%s%cpreview.png",
            PATHDIV, PATHDIV, e.get<const char*>(1), PATHDIV
        );
        if (fileexists(buf.get_buf(), "r"))
        {
            e.push(buf.get_buf());
            return;
        }

        buf.format("%s%s", homedir, buf.get_buf());
        if (fileexists(buf.get_buf(), "r"))
        {
            e.push(buf.get_buf());
            return;
        }
        e.push();
    })

    LUA_BIND_DEF(get_all_map_names, {
        vector<char *> glob;
        vector<char *> user;

        types::string buf;

        e.t_new();
        buf.format("data%cmaps", PATHDIV);
        listdir(buf.get_buf(), false, NULL, glob);
        if (glob.length() > 0)
        {
            loopv(glob)
            {
                if (strchr(glob[i], '.')) continue;
                e.t_set(i + 1, glob[i]);
            }
        }

        e.t_new();
        buf.format("%s%s", homedir, buf.get_buf());
        listdir(buf.get_buf(), false, NULL, user);
        if (user.length() > 0)
        {
            loopv(user)
            {
                if (strchr(user[i], '.')) continue;
                e.t_set(i + 1, user[i]);
            }
        }

        glob.deletecontents();
        user.deletecontents();
    })
}
