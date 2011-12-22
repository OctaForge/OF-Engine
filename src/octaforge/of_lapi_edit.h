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
void pushsel(int dir);
void editface(int dir, int mode);
void delcube();
void mpeditvslot(VSlot &ds, int allfaces, selinfo &sel, bool local);
void edittex_(int dir);
void gettex();
int getcurtex();
int getseltex();
const char *gettexname(int tex, int subslot);
void replace(bool insel);
void flip();
void rotate(int cw);
void editmat(char *name, char *filtername);
void resetlightmaps(bool fullclean);
void calclight(int quality);
void patchlight(int quality);
void clearlightmaps();
void dumplms();
void recalc();
void printcube();
void remip_();
void phystest();
void clearpvs();
void testpvs(int vcsize);
void genpvs(int viewcellsize);
void pvsstats();
void edittex(int i, bool save = true);

extern selinfo sel;

namespace EditingSystem
{
    void newent(const char *cl, const char *sd);
}

extern int& usevdelta, &gridpower, &nompedit, &allfaces;

namespace lapi_binds
{
    int _lua_editing_getworldsize() { return getworldsize(); }
    int _lua_editing_getgridsize () { return 1 << gridpower; }

    void _lua_editing_erasegeometry() { EditingSystem::eraseGeometry(); }

    void _lua_editing_createcube(int x, int y, int z, int gridsize)
    {
        EditingSystem::createCube(x, y, z, gridsize);
    }

    void _lua_editing_deletecube(int x, int y, int z, int gridsize)
    {
        EditingSystem::deleteCube(x, y, z, gridsize);
    }

    void _lua_editing_setcubetex(
        int x, int y, int z, int gridsize, int face, int texture
    )
    {
        EditingSystem::setCubeTexture(x, y, z, gridsize, face, texture);
    }

    void _lua_editing_setcubemat(
        int x, int y, int z, int gridsize, int material
    )
    {
        EditingSystem::setCubeMaterial(x, y, z, gridsize, material);
    }

    void _lua_editing_pushcubecorner(
        int x, int y, int z, int gridsize, int face, int corner, int direction
    )
    {
        EditingSystem::pushCubeCorner(
            x, y, z, gridsize, face, corner, direction
        );
    }

    lua::Table _lua_editing_getselent()
    {
        CLogicEntity *ret = EditingSystem::getSelectedEntity();
        if (ret && !ret->isNone() && !ret->lua_ref.is_nil())
            return ret->lua_ref;
        else
            return lapi::state.wrap<lua::Table>(lua::nil);
    }

    void _lua_renderprogress(float p, const char *text)
    {
        renderprogress(p, text ? text : "");
    }

    void _lua_edittoggle () { toggleedit(false); }
    void _lua_entcancel  () { entcancel(); }
    void _lua_cubecancel () { cubecancel(); }
    void _lua_cancelsel  () { cancelsel(); }
    void _lua_reorient   () { reorient(); }
    void _lua_selextend  () { selextend(); }
    int  _lua_havesel    () { return havesel ? selchildcount : 0; }
    void _lua_clearundos () { pruneundos(0); }
    void _lua_copy       () { copy(); }
    void _lua_pastehilite() { pastehilite(); }
    void _lua_paste      () { paste(); }
    void _lua_undo       () { editundo(); }
    void _lua_redo       () { editredo(); }
    void _lua_clearbrush () { clearbrush(); }

    void _lua_brushvert(int x, int y, int v) { brushvert(x, y, v); }

    void _lua_hmapcancel() { htextures.setsize(0); }
    void _lua_hmapselect()
    {
        int t = lookupcube(cur.x, cur.y, cur.z).texture[orient];
        int i = htextures.find(t);
        if (i < 0)
            htextures.add(t);
        else
            htextures.remove(i);
    }

    void _lua_pushsel (int dir)           { pushsel(dir); }
    void _lua_editface(int dir, int mode) { editface(dir, mode); }
    void _lua_delcube ()                  { delcube(); }

    void _lua_vdelta(lua::Function f)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        ++usevdelta;
        f();
        --usevdelta;
    }

    void _lua_vrotate(int rot)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed  = 1 << VSLOT_ROTATION;
        ds.rotation = usevdelta ? rot : clamp(rot, 0, 5);
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_voffset(int x, int y)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_OFFSET;
        ds.xoffset = usevdelta ? x : max(x, 0);
        ds.yoffset = usevdelta ? y : max(y, 0);
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_vscroll(float s, float t)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_SCROLL;
        ds.scrollS = s / 1000.0f;
        ds.scrollT = t / 1000.0f;
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_vscale(float scale)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_SCALE;
        ds.scale = (scale <= 0) ? 1 : (
            usevdelta ? scale : clamp(scale, 1 / 8.0f, 8.0f)
        );
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_vlayer(int n)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_LAYER;
        ds.layer = vslots.inrange(n) ? n : 0;
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_valpha(float front, float back)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_ALPHA;
        ds.alphafront = clamp(front, 0.0f, 1.0f);
        ds.alphaback  = clamp(back,  0.0f, 1.0f);
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_vcolor(float r, float g, float b)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_COLOR;
        ds.colorscale = vec(
            clamp(r, 0.0f, 1.0f),
            clamp(g, 0.0f, 1.0f),
            clamp(b, 0.0f, 1.0f)
        );
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_vreset()
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_vshaderparam(const char *n, float x, float y, float z, float w)
    {
        if (noedit() || (nompedit && multiplayer())) return;
        VSlot ds;
        ds.changed = 1 << VSLOT_SHPARAM;
        if (n && n[0])
        {
            ShaderParam p;
            p.name   = getshaderparamname(n);
            p.type   = SHPARAM_LOOKUP;
            p.index  = -1;
            p.loc    = -1;
            p.val[0] = x;
            p.val[1] = y;
            p.val[2] = z;
            p.val[3] = w;
            ds.params.add(p);
        }
        mpeditvslot(ds, allfaces, sel, true);  
    }

    void _lua_edittex(int n) { edittex_(n); }
    void _lua_settex (int n)
    {
        if (!noedit() && texmru.inrange(n))
            edittex(texmru[n]);
    }

    void _lua_gettex   () { gettex(); }
    int  _lua_getcurtex() { return getcurtex(); }
    int  _lua_getseltex() { return getseltex(); }

    lua::Object _lua_getreptex()
    {
        if (!noedit())
            return lapi::state.wrap<lua::Object>(
                vslots.inrange(reptex) ? reptex : -1
            );
        return lapi::state.wrap<lua::Object>(lua::nil);
    }

    const char *_lua_gettexname(int tex, int subslot)
    {
        return gettexname(tex, subslot);
    }

    void _lua_replace   () { return replace(false); }
    void _lua_replacesel() { return replace(true ); }
    void _lua_flip      () { flip(); }

    void _lua_rotate(int cw) { rotate(cw); }

    void _lua_editmat(const char *name, const char *filtername)
    {
        editmat(
            (char*)(name ? name : ""),
            (char*)(filtername ? filtername : "")
        );
    }

#ifdef SERVER
    lua::Table _lua_npcadd(const char *cl)
    {
        int cn = localconnect();

        types::String buf(types::String().format("Bot.%i", cn));
        logger::log(logger::DEBUG, "New NPC with client number: %i\n", cn);

        return server::createluaEntity(cn, cl ? cl : "", buf.get_buf());
    }

    void _lua_npcdel(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.npcdel", return)
        fpsent *fp = (fpsent*)entity->dynamicEntity;
        localdisconnect(true, fp->clientnum);
    }
#else
    void _lua_npcadd()
    { logger::log(logger::ERROR, "CAPI.npcadd: server-only function.\n"); }

    void _lua_npcdel()
    { logger::log(logger::ERROR, "CAPI.npcdel: server-only function.\n"); }
#endif

    void _lua_spawnent(const char *cl)
    {
        EditingSystem::newent(cl ? cl : "", "");
    }

#ifdef CLIENT
    void _lua_requestprivedit()
    {
        MessageSystem::send_RequestPrivateEditMode();
    }

    bool _lua_hasprivedit()
    {
        return ClientSystem::editingAlone;
    }

    void _lua_calclight(int quality)
    {
        calclight(quality);
    }

    void _lua_patchlight(int quality)
    {
        patchlight(quality);
    }

    void _lua_clearlightmaps() { clearlightmaps(); }
    void _lua_dumplms       () { dumplms       (); }
    void _lua_recalc        () { recalc        (); }
#else
    LAPI_EMPTY(requestprivedit)
    LAPI_EMPTY(hasprivedit)
    LAPI_EMPTY(calclight)
    LAPI_EMPTY(patchlight)
    LAPI_EMPTY(clearlightmaps)
    LAPI_EMPTY(dumplms)
    LAPI_EMPTY(recalc)
#endif

    void _lua_printcube() { printcube(); }
    void _lua_remip    () { remip_   (); }
    void _lua_phystest () { phystest (); }
    void _lua_clearpvs () { clearpvs (); }
    void _lua_pvsstats () { pvsstats (); }

    void _lua_genpvs (int vcsize) { genpvs (vcsize); }
    void _lua_testpvs(int vcsize) { testpvs(vcsize); }

    void reg_edit(lua::Table& t)
    {
        LAPI_REG(editing_getworldsize);
        LAPI_REG(editing_getgridsize);
        LAPI_REG(editing_erasegeometry);
        LAPI_REG(editing_createcube);
        LAPI_REG(editing_deletecube);
        LAPI_REG(editing_setcubetex);
        LAPI_REG(editing_setcubemat);
        LAPI_REG(editing_pushcubecorner);
        LAPI_REG(editing_getselent);
        LAPI_REG(renderprogress);
        LAPI_REG(edittoggle);
        LAPI_REG(entcancel);
        LAPI_REG(cubecancel);
        LAPI_REG(cancelsel);
        LAPI_REG(reorient);
        LAPI_REG(selextend);
        LAPI_REG(havesel);
        LAPI_REG(clearundos);
        LAPI_REG(copy);
        LAPI_REG(pastehilite);
        LAPI_REG(paste);
        LAPI_REG(undo);
        LAPI_REG(redo);
        LAPI_REG(clearbrush);
        LAPI_REG(brushvert);
        LAPI_REG(hmapcancel);
        LAPI_REG(hmapselect);
        LAPI_REG(pushsel);
        LAPI_REG(editface);
        LAPI_REG(delcube);
        LAPI_REG(vdelta);
        LAPI_REG(vrotate);
        LAPI_REG(voffset);
        LAPI_REG(vscroll);
        LAPI_REG(vscale);
        LAPI_REG(vlayer);
        LAPI_REG(valpha);
        LAPI_REG(vcolor);
        LAPI_REG(vreset);
        LAPI_REG(vshaderparam);
        LAPI_REG(edittex);
        LAPI_REG(settex);
        LAPI_REG(gettex);
        LAPI_REG(getcurtex);
        LAPI_REG(getseltex);
        LAPI_REG(getreptex);
        LAPI_REG(gettexname);
        LAPI_REG(replace);
        LAPI_REG(replacesel);
        LAPI_REG(flip);
        LAPI_REG(rotate);
        LAPI_REG(editmat);
        LAPI_REG(npcadd);
        LAPI_REG(npcdel);
        LAPI_REG(spawnent);
        LAPI_REG(requestprivedit);
        LAPI_REG(hasprivedit);
        LAPI_REG(calclight);
        LAPI_REG(patchlight);
        LAPI_REG(clearlightmaps);
        LAPI_REG(dumplms);
        LAPI_REG(recalc);
        LAPI_REG(printcube);
        LAPI_REG(remip);
        LAPI_REG(phystest);
        LAPI_REG(clearpvs);
        LAPI_REG(pvsstats);
        LAPI_REG(genpvs);
        LAPI_REG(testpvs);
    }
}
