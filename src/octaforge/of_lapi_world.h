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

namespace lapi_binds
{
    using namespace filesystem;

    /* Geometry utilities */

    bool _lua_raylos(vec o, vec d)
    {
        vec target(0);
        return raycubelos(o, d, target);
    }

    float _lua_raypos(vec o, vec ray, float r)
    {
        vec hitpos(0);
        return raycubepos(o, ray, hitpos, r, RAY_CLIPMAT | RAY_POLY);
    }

    float _lua_rayfloor(vec o, float r)
    {
        vec floor(0);
        return rayfloor(o, floor, 0, r);
    }

#ifdef CLIENT
    vec _lua_gettargetpos()
    {
        TargetingControl::determineMouseTarget(true);
        return TargetingControl::targetPosition;
    }

    lua::Table _lua_gettargetent()
    {
        TargetingControl::determineMouseTarget(true);
        CLogicEntity *target = TargetingControl::targetLogicEntity;

        if (target && !target->isNone() && !target->lua_ref.is_nil())
            return target->lua_ref;

        return lapi::state.wrap<lua::Table>(lua::nil);
    }
#else
    LAPI_EMPTY(gettargetpos)
    LAPI_EMPTY(gettargetent)
#endif

    /* World */

    bool _lua_iscolliding(vec o, float r, int uid)
    {
        CLogicEntity *ignore = (
            (uid != -1) ? LogicSystem::getLogicEntity(uid) : NULL
        );

        physent tester;

        tester.reset();
        tester.type      = ENT_BOUNCE;
        tester.o         = o;
        tester.radius    = tester.xradius = tester.yradius = r;
        tester.eyeheight = tester.aboveeye  = r;

        if (!collide(&tester, vec(0)))
        {
            if (
                ignore && ignore->isDynamic() &&
                ignore->dynamicEntity == hitplayer
            )
            {
                vec save = ignore->dynamicEntity->o;
                avoidcollision(ignore->dynamicEntity, vec(1), &tester, 0.1f);

                bool ret = !collide(&tester, vec(0));
                ignore->dynamicEntity->o = save;

                return ret;
            }
            else return true;
        }

        return false;
    }

    void _lua_setgravity(float g)
    {
        GRAVITY = g;
    }

    int _lua_getmat(vec o)
    {
        return lookupmaterial(o);
    }

    // TODO: REMOVE THESE
    #define addimplicit(f) \
    { \
        if (entgroup.empty() && enthover >= 0) \
        { \
            entadd(enthover); \
            undonext = (enthover != oldhover); \
            f; \
            entgroup.drop(); \
        } \
        else f; \
    }
    #define entfocus(i, f) \
    { \
        int n = efocus = (i); \
        if (n >= 0) \
        { \
            extentity &ent = *entities::get(n); \
            f; \
        } \
    }
    #define entedit(i, f) \
    { \
        entfocus(i, \
            int oldtype = ent.type; \
            removeentity(n);  \
            f; \
            if (oldtype != ent.type) \
                detachentity(ent); \
            if (ent.type != ET_EMPTY) \
            { \
                addentity(n); \
                if (oldtype != ent.type) \
                    attachentity(ent); \
            } \
        ) \
    }
    #define addgroup(exp) \
    { \
        loopv(entities::storage) \
            entfocus(i, if (exp) entadd(n)); \
    }
    #define setgroup(exp) \
    { \
        entcancel(); \
        addgroup(exp); \
    }
    #define groupeditloop(f) \
    { \
        entlooplevel++; \
        int _ = efocus; \
        loopv(entgroup) \
            entedit(entgroup[i], f); \
        efocus = _; \
        entlooplevel--; \
    }
    #define groupeditpure(f) \
    { \
        if (entlooplevel > 0) \
        { \
            entedit(efocus, f); \
        } \
        else \
            groupeditloop(f); \
    }
    #define groupeditundo(f) \
    { \
        makeundoent(); \
        groupeditpure(f); \
    }
    #define groupedit(f) { addimplicit(groupeditundo(f)); }

    void _lua_entautoview(int dir) { entautoview(dir); }
    void _lua_entflip    (       ) { entflip    (   ); }
    void _lua_entrotate  (int  cw) { entrotate  ( cw); }
    void _lua_entpush    (int dir) { entpush    (dir); }
    void _lua_attachent  (       ) { attachent  (   ); }
    void _lua_delent     (       ) { delent     (   ); }
    void _lua_dropent    (       ) { dropent    (   ); }
    void _lua_entcopy    (       ) { entcopy    (   ); }
    void _lua_entpaste   (       ) { entpaste   (   ); }

    int _lua_enthavesel()
    {
        return entgroup.length();
    }

    void _lua_entselect(lua::Function f)
    {
        if (!noentedit()) addgroup(
            (ent.type != ET_EMPTY) &&
            (entgroup.find(n) < 0) &&
            (f.call<bool>() == true)
        );
    }

    void _lua_entloop(lua::Function f)
    {
        if (!noentedit()) addimplicit(groupeditloop(((void)ent, f())));
    }

    bool _lua_insel()
    {
        entfocus(efocus, return (pointinsel(sel, ent.o) ? true : false));
        return false;
    }

    types::String _lua_entget()
    {
        entfocus(efocus, string s; printent(ent, s); return s);
        return NULL;
    }

    int _lua_entindex() { return efocus; }

    void _lua_entset(const char *what, int a1, int a2, int a3, int a4, int a5)
    {
        entset((char*)(what ? what : ""), a1, a2, a3, a4, a5);
    }

    void _lua_nearestent() { nearestent(); }

    void _lua_intensityentcopy (     ) { intensityentcopy  ( ); }
    void _lua_intensitypasteent(     ) { intensitypasteent ( ); }
    void _lua_newmap           (int s) { newmap            (s); }
    void _lua_mapenlarge       (     ) { mapenlarge        ( ); }
    void _lua_shrinkmap        (     ) { shrinkmap         ( ); }
    types::String _lua_mapname() { return game::getclientmap(); }

    /* In our new system, this is called when dragging concludes.
     * Only then do we update the server. This facilitates smooth 
     * dragging on the client, and a single bandwidth use at the end.
     */

    void _lua_finish_dragging()
    {
        groupeditpure(
            lapi::state.get<lua::Function>(
                "entity_store", "get"
            ).call<lua::Table>(
                LogicSystem::getUniqueId(&ent)
            )["position"] = ent.o;
        );
    }

    types::String _lua_mapcfgname()
    {
        types::String mname(game::getclientmap());
        if (mname.is_empty()) mname = "untitled";

        string pakname, mapname, mcfgname;
        getmapfilenames(mname.get_buf(), NULL, pakname, mapname, mcfgname);

        defformatstring(cfgname)("data/%s/%s.lua", pakname, mcfgname);
        path(cfgname);

        return cfgname;
    }

    void _lua_writeobj(const char *fn)
    {
        writeobj((char*)fn);
    }

    void _lua_export_entities(const char *fn)
    {
        world::export_ents(fn);
    }

#ifdef CLIENT
    void _lua_map(const char *name)
    {
        if (!name || !name[0])
            local_server::stop();
        else
            local_server::run(name);
    }

    bool _lua_hasmap() { return local_server::is_running(); }
#else
    LAPI_EMPTY(map)
    LAPI_EMPTY(hasmap)
#endif

    types::String _lua_get_map_preview_filename(const char *name)
    {
        types::String buf;

        buf.format(
            "data%cmaps%c%s%cpreview.png",
            PATHDIV, PATHDIV, name, PATHDIV
        );
        if (fileexists(buf.get_buf(), "r"))
            return buf;

        buf.format("%s%s", homedir, buf.get_buf());
        if (fileexists(buf.get_buf(), "r"))
            return buf;

        return NULL;
    }

    types::Tuple<lua::Table, lua::Table> _lua_get_all_map_names()
    {
        lua::Table gret = lapi::state.new_table();
        lua::Table uret = lapi::state.new_table();

        File_Info path = join_path("data", "maps");
        size_t       i = 1;

        for (File_Info::it it = path.begin(); it != path.end(); ++it)
        {
            if (it->type() == OFTL_FILE_DIR)
            {
                gret[i] = it->filename();
                ++i;
            }
        }

        path = join_path(homedir, "data", "maps");
        i    = 1;

        for (File_Info::it it = path.begin(); it != path.end(); ++it)
        {
            if (it->type() == OFTL_FILE_DIR)
            {
                uret[i] = it->filename();
                ++i;
            }
        }

        return types::make_tuple(gret, uret);
    }

    void reg_world(lua::Table& t)
    {
        LAPI_REG(raylos);
        LAPI_REG(raypos);
        LAPI_REG(rayfloor);
        LAPI_REG(gettargetpos);
        LAPI_REG(gettargetent);
        LAPI_REG(iscolliding);
        LAPI_REG(setgravity);
        LAPI_REG(getmat);
        LAPI_REG(entautoview);
        LAPI_REG(entflip);
        LAPI_REG(entrotate);
        LAPI_REG(entpush);
        LAPI_REG(attachent);
        LAPI_REG(delent);
        LAPI_REG(dropent);
        LAPI_REG(entcopy);
        LAPI_REG(entpaste);
        LAPI_REG(enthavesel);
        LAPI_REG(entselect);
        LAPI_REG(entloop);
        LAPI_REG(insel);
        LAPI_REG(entget);
        LAPI_REG(entindex);
        LAPI_REG(entset);
        LAPI_REG(nearestent);
        LAPI_REG(intensityentcopy);
        LAPI_REG(intensitypasteent);
        LAPI_REG(newmap);
        LAPI_REG(mapenlarge);
        LAPI_REG(shrinkmap);
        LAPI_REG(mapname);
        LAPI_REG(finish_dragging);
        LAPI_REG(mapcfgname);
        LAPI_REG(writeobj);
        LAPI_REG(export_entities);
        LAPI_REG(map);
        LAPI_REG(hasmap);
        LAPI_REG(get_map_preview_filename);
        LAPI_REG(get_all_map_names);

    }
}
