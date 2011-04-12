/*
 * luabind_edit.hpp, version 1
 * Editing API for Lua
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
extern vector<int> htextures;
extern bool havesel;
extern int orient, reptex;
extern ivec cur;
void cubecancel();
void reorient();
void selextend();
void copy();
void pastehilite();
void paste();
void editundo();
void editredo();
void clearbrush();
void brushvert(int x, int y, int v);
void pushsel(int *dir);
void editface(int *dir, int *mode);
void delcube();
void mpeditvslot(VSlot &ds, int allfaces, selinfo &sel, bool local);
void edittex_(int *dir);
void gettex();
void getcurtex();
void getseltex();
void gettexname(int *tex, int *subslot);
void replace(bool insel);
void flip();
void rotate(int *cw);
void editmat(char *name, char *filtername);
void showtexgui(int *n);
void resetlightmaps(bool fullclean);
void calclight(int *quality);
void patchlight(int *quality);
void clearlightmaps();
void dumplms();
void recalc();
void printcube();
void remip_();
void phystest();
void clearpvs();
void testpvs(int *vcsize);
void genpvs(int *viewcellsize);
void pvsstats();

namespace EditingSystem
{
#ifdef CLIENT
    extern int savedMousePosTime;
    extern vec savedMousePos;
#endif
    extern std::vector<std::string> entityClasses;
    void newEntity(std::string _class, std::string stateData);
    void prepareentityclasses();
}
void debugoctree();
void centerent();
#ifdef CLIENT
void listtex();
void massreplacetex(char *filename);
#endif

namespace lua_binds
{
    LUA_BIND_STD(editing_getworldsize, e.push, EditingSystem::getWorldSize())
    LUA_BIND_STD(editing_getgridsize, e.push, 1<<GETIV(gridpower))
    LUA_BIND_STD(editing_erasegeometry, EditingSystem::eraseGeometry)
    LUA_BIND_STD(editing_createcube, EditingSystem::createCube, e.get<int>(1), e.get<int>(2), e.get<int>(3), e.get<int>(4))
    LUA_BIND_STD(editing_deletecube, EditingSystem::deleteCube, e.get<int>(1), e.get<int>(2), e.get<int>(3), e.get<int>(4))
    LUA_BIND_STD(editing_setcubetex, EditingSystem::setCubeTexture,
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<int>(4),
        e.get<int>(5),
        e.get<int>(6)
    )
    LUA_BIND_STD(editing_setcubemat, EditingSystem::setCubeMaterial,
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<int>(4),
        e.get<int>(5)
    )
    LUA_BIND_STD(editing_pushcubecorner, EditingSystem::pushCubeCorner,
        e.get<int>(1),
        e.get<int>(2),
        e.get<int>(3),
        e.get<int>(4),
        e.get<int>(5),
        e.get<int>(6),
        e.get<int>(7)
    )
    LUA_BIND_DEF(editing_getselent, {
        LogicEntityPtr ret = EditingSystem::getSelectedEntity();
        if (ret.get() && !ret->isNone() && ret->luaRef >= 0) e.getref(ret.get()->luaRef);
        else e.push();
    })
    LUA_BIND_STD(renderprogress, renderprogress, e.get<float>(1), e.get<const char*>(2))
    LUA_BIND_STD(getmapversion, e.push, GETIV(mapversion))

    LUA_BIND_STD(edittoggle, toggleedit, false)
    LUA_BIND_STD(entcancel, entcancel)
    LUA_BIND_STD(cubecancel, cubecancel)
    LUA_BIND_STD(cancelsel, cancelsel)
    LUA_BIND_STD(reorient, reorient)
    LUA_BIND_STD(selextend, selextend)
    LUA_BIND_STD(havesel, e.push, havesel ? selchildcount : 0)
    LUA_BIND_STD(clearundos, pruneundos, 0)
    LUA_BIND_STD(copy, copy)
    LUA_BIND_STD(pastehilite, pastehilite)
    LUA_BIND_STD(paste, paste)
    LUA_BIND_STD(undo, editundo)
    LUA_BIND_STD(redo, editredo)
    LUA_BIND_STD(clearbrush, clearbrush)
    LUA_BIND_STD(brushvert, brushvert, e.get<int>(1), e.get<int>(2), e.get<int>(3))
    LUA_BIND_STD(hmapcancel, htextures.setsize, 0)
    LUA_BIND_DEF(hmapselect, {
        int t = lookupcube(cur.x, cur.y, cur.z).texture[orient];
        int i = htextures.find(t);
        if (i < 0) htextures.add(t);
        else htextures.remove(i);
    })
    LUA_BIND_STD(pushsel, pushsel, e.get<int*>(1))
    LUA_BIND_STD(editface, editface, e.get<int*>(1), e.get<int*>(2))
    LUA_BIND_STD(delcube, delcube)
    LUA_BIND_DEF(vdelta, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        SETVN(usevdelta, GETIV(usevdelta) + 1);
        e.exec(e.get<const char*>(1));
        SETVN(usevdelta, GETIV(usevdelta) - 1);
    })
    LUA_BIND_DEF(vrotate, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_ROTATION;
        ds.rotation = GETIV(usevdelta) ? e.get<int>(1) : clamp(e.get<int>(1), 0, 5);
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(voffset, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_OFFSET;
        ds.xoffset = GETIV(usevdelta) ? e.get<int>(1) : max(e.get<int>(1), 0);
        ds.yoffset = GETIV(usevdelta) ? e.get<int>(2) : max(e.get<int>(2), 0);
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(vscroll, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_SCROLL;
        ds.scrollS = e.get<float>(1)/1000.0f;
        ds.scrollT = e.get<float>(2)/1000.0f;
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(vscale, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        float scale = e.get<float>(1);
        VSlot ds;
        ds.changed = 1 << VSLOT_SCALE;
        ds.scale = scale <= 0 ? 1 : (GETIV(usevdelta) ? scale : clamp(scale, 1/8.0f, 8.0f));
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(vlayer, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_LAYER;
        ds.layer = vslots.inrange(e.get<int>(1)) ? e.get<int>(1) : 0;
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(valpha, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_ALPHA;
        ds.alphafront = clamp(e.get<float>(1), 0.0f, 1.0f);
        ds.alphaback  = clamp(e.get<float>(2), 0.0f, 1.0f);
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(vcolor, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_COLOR;
        ds.colorscale = vec(clamp(e.get<float>(1), 0.0f, 1.0f),
                            clamp(e.get<float>(2), 0.0f, 1.0f),
                            clamp(e.get<float>(3), 0.0f, 1.0f));
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(vreset, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_DEF(vshaderparam, {
        if (noedit() || (GETIV(nompedit) && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_SHPARAM;
        if(e.get<const char*>(1)[0])
        {
            ShaderParam p;
            p.name = getshaderparamname(e.get<const char*>(1));
            p.type = SHPARAM_LOOKUP;
            p.index = -1; p.loc = -1;
            p.val[0] = e.get<float>(2);
            p.val[1] = e.get<float>(3);
            p.val[2] = e.get<float>(4);
            p.val[3] = e.get<float>(5);
            ds.params.add(p);
        }
        mpeditvslot(ds, GETIV(allfaces), sel, true);
    })
    LUA_BIND_STD(edittex, edittex_, e.get<int*>(1))
    LUA_BIND_STD(gettex, gettex)
    LUA_BIND_STD(getcurtex, getcurtex)
    LUA_BIND_STD(getseltex, getseltex)
    LUA_BIND_DEF(getreptex, {
        if (!noedit()) e.push(vslots.inrange(reptex) ? reptex : -1);
    })
    LUA_BIND_STD(gettexname, gettexname, e.get<int*>(1), e.get<int*>(2))
    LUA_BIND_STD(replace, replace, false)
    LUA_BIND_STD(replacesel, replace, true)
    LUA_BIND_STD(flip, flip)
    LUA_BIND_STD(rotate, rotate, e.get<int*>(1))
    LUA_BIND_STD(editmat, editmat, e.get<char*>(1), e.get<char*>(2))
    // 0/noargs = toggle, 1 = on, other = off - will autoclose if too far away or exit editmode
    LUA_BIND_STD(showtexgui, showtexgui, e.get<int*>(1))

    LUA_BIND_SERVER(npcadd, {
        int _ref = NPC::add(e.get<const char*>(1));
        if (_ref >= 0) e.getref(_ref);
        else e.push();
    })

    #ifdef SERVER
    LUA_BIND_LE(npcdel, {
        fpsent *fpsEntity = (fpsent*)self.get()->dynamicEntity;
        NPC::remove(fpsEntity->clientnum);
    })
    #else
    LUA_BIND_DUMMY(npcdel)
    #endif

    LUA_BIND_CLIENT(save_mouse_pos, {
        EditingSystem::savedMousePosTime = Utility::SystemInfo::currTime();
        EditingSystem::savedMousePos = TargetingControl::worldPosition;
        Logging::log(Logging::DEBUG,
                     "Saved mouse pos: %f,%f,%f (%d)\r\n",
                     EditingSystem::savedMousePos.x,
                     EditingSystem::savedMousePos.y,
                     EditingSystem::savedMousePos.z,
                     EditingSystem::savedMousePosTime);
    })

    LUA_BIND_CLIENT(getentclass, {
        std::string ret = EditingSystem::entityClasses[e.get<int>(1)];
        assert( Utility::validateAlphaNumeric(ret, "_") ); // Prevent injections
        e.push(ret.c_str());
    })

    LUA_BIND_STD(prepareentityclasses, EditingSystem::prepareentityclasses)
    LUA_BIND_STD(numentityclasses, e.push, (int)EditingSystem::entityClasses.size())
    LUA_BIND_STD(spawnent, EditingSystem::newEntity, e.get<const char*>(1))
    LUA_BIND_STD_CLIENT(listtex, listtex)
    LUA_BIND_STD_CLIENT(massreplacetex, massreplacetex, e.get<char*>(1))
    LUA_BIND_STD(debugoctree, debugoctree)
    LUA_BIND_STD(centerent, centerent)

    LUA_BIND_STD_CLIENT(requestprivedit, MessageSystem::send_RequestPrivateEditMode)
    LUA_BIND_STD_CLIENT(hasprivedit, e.push, ClientSystem::editingAlone)

    LUA_BIND_STD_CLIENT(resetlightmaps, resetlightmaps, e.get<bool>(1))
    LUA_BIND_STD_CLIENT(calclight, calclight, e.get<int*>(1))
    LUA_BIND_STD_CLIENT(patchlight, patchlight, e.get<int*>(1))
    LUA_BIND_STD_CLIENT(clearlightmaps, clearlightmaps)
    LUA_BIND_STD_CLIENT(dumplms, dumplms)

    LUA_BIND_STD_CLIENT(recalc, recalc)
    LUA_BIND_STD(printcube, printcube)
    LUA_BIND_STD(remip, remip_)
    LUA_BIND_STD(phystest, phystest)
    LUA_BIND_STD(genpvs, genpvs, e.get<int*>(1))
    LUA_BIND_STD(testpvs, testpvs, e.get<int*>(1))
    LUA_BIND_STD(clearpvs, clearpvs)
    LUA_BIND_STD(pvsstats, pvsstats)
}
