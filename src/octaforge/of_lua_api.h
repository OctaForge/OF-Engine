int preload_sound(const char *name, int vol);

extern string homedir;

namespace EditingSystem
{
    extern vec saved_pos;
    void newent(const char *cl, const char *sd);
}

extern int gridpower;

void removeentity(extentity* entity);
void addentity(extentity* entity);

VARP(ragdoll, 0, 1, 1);

void trydisconnect(bool local);

namespace game
{
    void toserver(char *text);
    fpsent *followingplayer();
}

#ifdef CLIENT
VARP(blood, 0, 1, 1);
#endif

bool startmusic(const char *name, const char *cmd);
int preload_sound(const char *name, int vol);

#ifdef CLIENT
void filltexlist();
#endif

extern float GRAVITY;
extern physent *hitplayer;

namespace lapi_binds
{
    using namespace MessageSystem;

    int _lua_log(lua_State *L) {
        logger::log((logger::loglevel)luaL_checkinteger(L, 1),
            "%s\n", luaL_checkstring(L, 2));
        return 0;
    }

    int _lua_should_log(lua_State *L) {
        lua_pushboolean(L, logger::should_log(
            (logger::loglevel)luaL_checkinteger(L, 1)));
        return 1;
    }

    int _lua_echo(lua_State *L) {
        conoutf("\f1%s", luaL_checkstring(L, 1));
        return 0;
    }

    int _lua_lastmillis(lua_State *L) {
        lua_pushinteger(L, lastmillis);
        return 1;
    }

    int _lua_totalmillis(lua_State *L) {
        lua_pushinteger(L, totalmillis);
        return 1;
    }

    int _lua_currtime(lua_State *L) {
        lua_pushinteger(L, tools::currtime());
        return 1;
    }

    int _lua_cubescript(lua_State *L) {
        tagval v;
        executeret(luaL_checkstring(L, 1), v);
        switch (v.type) {
            case VAL_INT:
                lua_pushinteger(L, v.getint());
            case VAL_FLOAT:
                lua_pushnumber(L, v.getfloat());
            case VAL_STR:
                lua_pushstring(L, v.getstr());
            default:
                lua_pushnil(L);
        }
        return 1;
    }

    int _lua_readfile(lua_State *L) {
        const char *p = luaL_checkstring(L, 1);

        if (!p || !p[0] || p[0] == '/' ||p[0] == '\\'
        || strstr(p, "..") || strchr(p, '~')) {
            return 0;
        }

        char *loaded = NULL;
        string buf;

        if (strlen(p) >= 2 && p[0] == '.' && (p[1] == '/' || p[1] == '\\')) {
            copystring(buf, world::get_mapfile_path(p + 2));
        } else {
            formatstring(buf)("data%c%s", PATHDIV, p);
        }

        if (!(loaded = loadfile(path(buf, true), NULL))) {
            logger::log(logger::ERROR, "count not read \"%s\"", p);
            return 0;
        }
        lua_pushstring(L, loaded);
        return 1;
    }

    int _lua_getserverlogfile(lua_State *L) {
        lua_pushliteral(L, SERVER_LOGFILE);
        return 1;
    }

    int _lua_setup_library(lua_State *L) {
        lua_pushboolean(L, lua::load_library(luaL_checkstring(L, 1)));
        return 1;
    }
#ifdef CLIENT
    int _lua_save_mouse_position(lua_State *L) {
        EditingSystem::saved_pos = TargetingControl::worldPosition;
        return 0;
    }
#else
    LAPI_EMPTY(save_mouse_position)
#endif

    int _lua_var_reset(lua_State *L) {
        resetvar((char*)luaL_checkstring(L, 1));
        return 0;
    }

    int _lua_var_new_i(lua_State *L) {
        const char *name = luaL_checkstring(L, 1);
        if (!name || !name[0]) return 0;
        ident *id = getident(name);
        if (!id) {
            int *st = new int;
            *st = variable(name, luaL_checkinteger(L, 2),
                luaL_checkinteger(L, 3), luaL_checkinteger(L, 4),
                st, NULL, luaL_checkinteger(L, 5) | IDF_ALLOC);
        } else {
            logger::log(logger::ERROR, "variable %s already exists\n", name);
        }
        return 0;
    }

    int _lua_var_new_f(lua_State *L) {
        const char *name = luaL_checkstring(L, 1);
        if (!name || !name[0]) return 0;
        ident *id = getident(name);
        if (!id) {
            float *st = new float;
            *st = fvariable(name, luaL_checknumber(L, 2),
                luaL_checknumber(L, 3), luaL_checknumber(L, 4),
                st, NULL, luaL_checkinteger(L, 5) | IDF_ALLOC);
        } else {
            logger::log(logger::ERROR, "variable %s already exists\n", name);
        }
        return 0;
    }

    int _lua_var_new_s(lua_State *L) {
        const char *name = luaL_checkstring(L, 1);
        if (!name || !name[0]) return 0;
        ident *id = getident(name);
        if (!id) {
            char **st = new char*;
            *st = svariable(name, luaL_checkstring(L, 2), st, NULL,
                luaL_checkinteger(L, 3) | IDF_ALLOC);
        } else {
            logger::log(logger::ERROR, "variable %s already exists\n", name);
        }
        return 0;
    }

    int _lua_var_set_i(lua_State *L) {
        setvar(luaL_checkstring(L, 1), luaL_checkinteger(L, 2));
        return 0;
    }

    int _lua_var_set_f(lua_State *L) {
        setfvar(luaL_checkstring(L, 1), luaL_checknumber(L, 2));
        return 0;
    }

    int _lua_var_set_s(lua_State *L) {
        setsvar(luaL_checkstring(L, 1), luaL_checkstring(L, 2));
        return 0;
    }

    int _lua_var_get_i(lua_State *L) {
        lua_pushinteger(L, getvar(luaL_checkstring(L, 1)));
        return 1;
    }

    int _lua_var_get_f(lua_State *L) {
        lua_pushnumber(L, getfvar(luaL_checkstring(L, 1)));
        return 1;
    }

    int _lua_var_get_s(lua_State *L) {
        lua_pushstring(L, getsvar(luaL_checkstring(L, 1)));
        return 1;
    }

    int _lua_var_get_min_i(lua_State *L) {
        lua_pushinteger(L, getvarmin(luaL_checkstring(L, 1)));
        return 1;
    }

    int _lua_var_get_min_f(lua_State *L) {
        lua_pushnumber(L, getfvarmin(luaL_checkstring(L, 1)));
        return 1;
    }

    int _lua_var_get_max_i(lua_State *L) {
        lua_pushinteger(L, getvarmax(luaL_checkstring(L, 1)));
        return 1;
    }

    int _lua_var_get_max_f(lua_State *L) {
        lua_pushnumber(L, getfvarmax(luaL_checkstring(L, 1)));
        return 1;
    }

    int _lua_var_get_def_i(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        if (!id || id->type != ID_VAR) return 0;
        lua_pushinteger(L, id->overrideval.i);
        return 1;
    }

    int _lua_var_get_def_f(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        if (!id || id->type != ID_FVAR) return 0;
        lua_pushnumber(L, id->overrideval.f);
        return 1;
    }

    int _lua_var_get_def_s(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        if (!id || id->type != ID_SVAR) return 0;
        lua_pushstring(L, id->overrideval.s);
        return 1;
    }

    int _lua_var_get_type(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        if (!id || id->type > ID_SVAR) {
            lua_pushinteger(L, -1);
        } else {
            lua_pushinteger(L, id->type);
        }
        return 1;
    }

    int _lua_var_exists(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        lua_pushboolean(L, (!id || id->type > ID_SVAR) ? false : true);
        return 1;
    }

    int _lua_var_is_hex(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        lua_pushboolean(L, (!id || !(id->flags&IDF_HEX)) ? false : true);
        return 1;
    }

    int _lua_var_emits(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        lua_pushboolean(L, (!id || !(id->flags&IDF_SIGNAL)) ? false : true);
        return 1;
    }

    int _lua_var_emits_set(lua_State *L) {
        ident *id = getident(luaL_checkstring(L, 1));
        if (!id) return 0;
        if (lua_toboolean(L, 2)) id->flags |= IDF_SIGNAL;
        else id->flags &= ~IDF_SIGNAL;
        return 0;
    }

#ifdef CLIENT
    /* input */

    int _lua_input_get_modifier_state(lua_State *L) {
        lua_pushinteger(L, SDL_GetModState());
        return 1;
    }

    /* gui */

    int _lua_gui_set_mainmenu(lua_State *L) {
        lua_pushinteger(L, mainmenu);
        mainmenu = luaL_checkinteger(L, 1);
        return 1;
    }

    int _lua_gui_text_bounds(lua_State *L) {
        int w, h;
        text_bounds(luaL_checkstring(L, 1), w, h, luaL_checkinteger(L, 2));
        lua_pushinteger(L, w); lua_pushinteger(L, h);
        return 2;
    }

    int _lua_gui_text_bounds_f(lua_State *L) {
        float w, h;
        text_boundsf(luaL_checkstring(L, 1), w, h, luaL_checkinteger(L, 2));
        lua_pushnumber(L, w); lua_pushnumber(L, h);
        return 2;
    }

    int _lua_gui_text_pos(lua_State *L) {
        int cx, cy;
        text_pos(luaL_checkstring(L, 1), luaL_checkinteger(L, 2),
            cx, cy, luaL_checkinteger(L, 3));
        lua_pushinteger(L, cx); lua_pushinteger(L, cy);
        return 2;
    }

    int _lua_gui_text_pos_f(lua_State *L) {
        float cx, cy;
        text_posf(luaL_checkstring(L, 1), luaL_checkinteger(L, 2),
            cx, cy, luaL_checkinteger(L, 3));
        lua_pushnumber(L, cx); lua_pushnumber(L, cy);
        return 2;
    }

    int _lua_gui_text_visible(lua_State *L) {
        lua_pushinteger(L, text_visible(luaL_checkstring(L, 1),
            luaL_checknumber(L, 2), luaL_checknumber(L, 3),
            luaL_checkinteger(L, 4)));
        return 1;
    }

    int _lua_gui_draw_text(lua_State *L) {
        draw_text(luaL_checkstring(L, 1), luaL_checkinteger(L, 2),
            luaL_checkinteger(L, 3), luaL_checkinteger(L, 4), luaL_checkinteger(L, 5),
            luaL_checkinteger(L, 6), luaL_checkinteger(L, 7), luaL_checkinteger(L, 8),
            luaL_checkinteger(L, 9));
        return 0;
    }
#endif

    /* camera */

#ifdef CLIENT
    int _lua_getcamyaw(lua_State *L) {
        lua_pushinteger(L, camera1->yaw);
        return 1;
    }
    int _lua_getcampitch(lua_State *L) {
        lua_pushinteger(L, camera1->pitch);
        return 1;
    }
    int _lua_getcamroll(lua_State *L) {
        lua_pushinteger(L, camera1->roll);
        return 1;
    }
    int _lua_getcampos(lua_State *L) {
        lua::push_external(L, "new_vec3");
        const vec& o = camera1->o;
        lua_pushnumber(L, o.x); 
        lua_pushnumber(L, o.y);
        lua_pushnumber(L, o.z);
        lua_call(L, 3, 1);
        return 1;
    }
#else
    LAPI_EMPTY(getcamyaw)
    LAPI_EMPTY(getcampitch)
    LAPI_EMPTY(getcamroll)
    LAPI_EMPTY(getcampos)
#endif

    /* edit */

    int _lua_editing_getworldsize(lua_State *L) {
        lua_pushinteger(L, getworldsize());
        return 1;
    }
    int _lua_editing_getgridsize (lua_State *L) {
        lua_pushinteger(L, 1 << gridpower);
        return 1;
    }

    int _lua_editing_erasegeometry(lua_State *L) {
        EditingSystem::eraseGeometry();
        return 0;
    }

    int _lua_editing_createcube(lua_State *L) {
        EditingSystem::createCube(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
                                  luaL_checkinteger(L, 3), luaL_checkinteger(L, 4));
        return 0;
    }

    int _lua_editing_deletecube(lua_State *L) {
        EditingSystem::deleteCube(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
                                  luaL_checkinteger(L, 3), luaL_checkinteger(L, 4));
        return 0;
    }

    int _lua_editing_setcubetex(lua_State *L) {
        EditingSystem::setCubeTexture(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
                                      luaL_checkinteger(L, 3), luaL_checkinteger(L, 4),
                                      luaL_checkinteger(L, 5), luaL_checkinteger(L, 6));
        return 0;
    }

    int _lua_editing_setcubemat(lua_State *L) {
        EditingSystem::setCubeMaterial(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
                                       luaL_checkinteger(L, 3), luaL_checkinteger(L, 4),
                                       luaL_checkinteger(L, 5));
        return 0;
    }

    int _lua_editing_setcubecolor(lua_State *L) {
        EditingSystem::setCubeColor(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
                                    luaL_checkinteger(L, 3), luaL_checkinteger(L, 4),
                                    luaL_checknumber(L, 5),
                                    luaL_checknumber(L, 6),
                                    luaL_checknumber(L, 7));
        return 0;
    }

    int _lua_editing_pushcubecorner(lua_State *L) {
        EditingSystem::pushCubeCorner(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
                                      luaL_checkinteger(L, 3), luaL_checkinteger(L, 4),
                                      luaL_checkinteger(L, 5), luaL_checkinteger(L, 6),
                                      luaL_checkinteger(L, 7));
        return 0;
    }

    int _lua_editing_getselent(lua_State *L) {
        CLogicEntity *ret = EditingSystem::getSelectedEntity();
        if (ret && !ret->isNone() && ret->lua_ref != LUA_REFNIL)
            lua_rawgeti(L, LUA_REGISTRYINDEX, ret->lua_ref);
        else
            lua_pushnil(L);
        return 1;
    }

#ifdef SERVER
    int _lua_npcadd(lua_State *L) {
        int cn = localconnect();

        defformatstring(buf)("Bot.%d", cn);
        logger::log(logger::DEBUG, "New NPC with client number: %i\n", cn);

        const char *cl = luaL_checkstring(L, 1);
        /* returns true  == 1 when there is an entity on the stack
         * returns false == 0 when there is no entity on the stack */
        return server::createluaEntity(cn, cl ? cl : "", buf);
    }

    int _lua_npcdel(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.npcdel", return 0)
        fpsent *fp = (fpsent*)entity->dynamicEntity;
        localdisconnect(true, fp->clientnum);
        return 0;
    }
#else
    int _lua_npcadd(lua_State *L) {
        logger::log(logger::ERROR, "CAPI.npcadd: server-only function.\n");
        return 0;
    }

    int _lua_npcdel(lua_State *L) {
        logger::log(logger::ERROR, "CAPI.npcdel: server-only function.\n");
        return 0;
    }
#endif

    int _lua_spawnent(lua_State *L) {
        const char *cl = luaL_checkstring(L, 1);
        EditingSystem::newent(cl ? cl : "", "");
        return 0;
    }

#ifdef CLIENT
    int _lua_requestprivedit(lua_State *L) {
        MessageSystem::send_RequestPrivateEditMode();
        return 0;
    }

    int _lua_hasprivedit(lua_State *L) {
        lua_pushboolean(L, ClientSystem::editingAlone);
        return 1;
    }
#else
    LAPI_EMPTY(requestprivedit)
    LAPI_EMPTY(hasprivedit)
#endif

    /* Entity management */

    int _lua_unregister_entity(lua_State *L) {
        LogicSystem::unregisterLogicEntityByUniqueId(luaL_checkinteger(L, 1));
        return 0;
    }

    int _lua_setupextent(lua_State *L) {
        lua_pushvalue(L, 1);
        LogicSystem::setupExtent(
            luaL_ref(L, LUA_REGISTRYINDEX), luaL_checkinteger(L, 2),
            luaL_checknumber(L, 3), luaL_checknumber(L, 4), luaL_checknumber(L, 5),
            luaL_checkinteger(L, 6), luaL_checkinteger(L, 7), luaL_checkinteger(L, 8),
            luaL_checkinteger(L, 9), luaL_checkinteger(L, 10));
        return 0;
    }

    int _lua_setupcharacter(lua_State *L) {
        lua_pushvalue(L, 1);
        LogicSystem::setupCharacter(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    }

    int _lua_setupnonsauer(lua_State *L) {
        lua_pushvalue(L, 1);
        LogicSystem::setupNonSauer(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    }

    int _lua_dismantleextent(lua_State *L) {
        lua_pushvalue(L, 1);
        LogicSystem::dismantleExtent(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    }

    int _lua_dismantlecharacter(lua_State *L) {
        lua_pushvalue(L, 1);
        LogicSystem::dismantleCharacter(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    }

    /* Entity attributes */

    int _lua_setanim(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.setanim", return 0)
        entity->setAnimation(luaL_checkinteger(L, 2));
        return 0;
    }

    int _lua_getstarttime(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.getstarttime", return 0)
        lua_pushinteger(L, entity->getStartTime());
        return 1;
    }

    int _lua_setmodelname(lua_State *L) {
        const char *name = "";
        if (!lua_isnoneornil(L, 2)) name = luaL_checkstring(L, 2);
        LAPI_GET_ENT(entity, "CAPI.setmodelname", return 0)
        logger::log(logger::DEBUG, "CAPI.setmodelname(\"%s\", \"%s\")\n",
            entity->getClass(), name);
        entity->setModel(name);
        return 0;
    }

    int _lua_setsoundname(lua_State *L) {
        const char *name = "";
        if (!lua_isnoneornil(L, 2)) name = luaL_checkstring(L, 2);
        LAPI_GET_ENT(entity, "CAPI.setsoundname", return 0)
        logger::log(logger::DEBUG, "CAPI.setsoundname(\"%s\", \"%s\")\n",
            entity->getClass(), name);
        entity->setSound(name);
        return 0;
    }

    int _lua_setsoundvol(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.setsoundvol", return 0)
        int vol = luaL_checkinteger(L, 2);
        logger::log(logger::DEBUG, "CAPI.setsoundvol(%i)\n", vol);

        if (!entity->sndname) return 0;

        extentity *ext = entity->staticEntity;
        assert(ext);

        if (!world::loading) removeentity(ext);
        ext->attr4 = vol;
        if (!world::loading) addentity(ext);

        entity->setSound(entity->sndname);
        return 0;
    }

    int _lua_setattachments(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.setattachments", return 0)
        lua_getglobal(L, "table");
        lua_getfield (L, -1, "concat");
        lua_remove   (L, -2);
        lua_pushvalue(L,  2);
        lua_call     (L, 1, 1);
        entity->setAttachments(lua_tostring(L, -1));
        lua_pop(L, 1);
        return 0;
    }

    int _lua_getattachmentpos(lua_State *L) {
        const char *attachment = "";
        if (!lua_isnoneornil(L, 2)) attachment = luaL_checkstring(L, 2);
        LAPI_GET_ENT(entity, "CAPI.getattachmentpos", return 0)
        lua::push_external(L, "new_vec3");
        const vec& o = entity->getAttachmentPosition(attachment);
        lua_pushnumber(L, o.x); lua_pushnumber(L, o.y); lua_pushnumber(L, o.z);
        lua_call(L, 3, 1);
        return 1;
    }

    int _lua_setcanmove(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.setcanmove", return 0)
        entity->setCanMove(lua_toboolean(L, 2));
        return 0;
    }

    /* Extents */

    #define EXTENT_ACCESSORS(n) \
    int _lua_get##n(lua_State *L) { \
        LAPI_GET_ENT(entity, "CAPI.get"#n, return 0) \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        lua_pushinteger(L, ext->n); \
        return 1; \
    } \
    int _lua_set##n(lua_State *L) { \
        LAPI_GET_ENT(entity, "CAPI.set"#n, return 0) \
        int v = luaL_checkinteger(L, 2); \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        if (!world::loading) removeentity(ext); \
        ext->n = v; \
        if (!world::loading) addentity(ext); \
        return 0; \
    } \
    int _lua_FAST_set##n(lua_State *L) { \
        LAPI_GET_ENT(entity, "CAPI.FAST_set"#n, return 0) \
        int v = luaL_checkinteger(L, 2); \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        ext->n = v; \
        return 0; \
    }

    EXTENT_ACCESSORS(attr1)
    EXTENT_ACCESSORS(attr2)
    EXTENT_ACCESSORS(attr3)
    EXTENT_ACCESSORS(attr4)
    EXTENT_ACCESSORS(attr5)
    #undef EXTENT_ACCESSORS

    #define EXTENT_LE_ACCESSORS(n, an) \
    int _lua_get##n(lua_State *L) { \
        LAPI_GET_ENT(entity, "CAPI.get"#n, return 0) \
        lua_pushnumber(L, entity->an); \
        return 1; \
    } \
    int _lua_set##n(lua_State *L) { \
        LAPI_GET_ENT(entity, "CAPI.set"#n, return 0) \
        float v = luaL_checknumber(L, 2); \
        logger::log(logger::DEBUG, "ACCESSOR: Setting %s to %f\n", #an, v); \
        assert(entity->staticEntity); \
        if (!world::loading) removeentity(entity->staticEntity); \
        entity->an = v; \
        if (!world::loading) addentity(entity->staticEntity); \
        return 0; \
    }

    EXTENT_LE_ACCESSORS(collisionradw, collisionRadiusWidth)
    EXTENT_LE_ACCESSORS(collisionradh, collisionRadiusHeight)
    #undef EXTENT_LE_ACCESSORS

    int _lua_getextent0(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.getextent0", return 0)
        extentity *ext = entity->staticEntity;
        assert(ext);
        logger::log(logger::INFO,
            "CAPI.getextent0(\"%s\"): x: %f, y: %f, z: %f\n",
            entity->getClass(), ext->o.x, ext->o.y, ext->o.z);
        lua_createtable(L, 3, 0);
        lua_pushnumber(L, ext->o.x); lua_rawseti(L, -2, 1);
        lua_pushnumber(L, ext->o.y); lua_rawseti(L, -2, 2);
        lua_pushnumber(L, ext->o.z); lua_rawseti(L, -2, 3);
        return 1;
    }

    int _lua_setextent0(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.setextent0", return 0)
        luaL_checktype(L, 2, LUA_TTABLE);
        extentity *ext = entity->staticEntity;
        assert(ext);

        removeentity(ext);
        lua_pushinteger(L, 1); lua_gettable(L, -2);
        ext->o.x = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 2); lua_gettable(L, -2);
        ext->o.y = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 3); lua_gettable(L, -2);
        ext->o.z = luaL_checknumber(L, -1); lua_pop(L, 1);
        addentity(ext);
        return 0;
    }

    /* Dynents */

    #define luaL_checkboolean lua_toboolean

    #define DYNENT_ACCESSORS(n, t, tt, an) \
    int _lua_get##n(lua_State *L) { \
        LAPI_GET_ENT(entity, "CAPI.get"#n, return 0) \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        lua_push##tt(L, d->an); \
        return 1; \
    } \
    int _lua_set##n(lua_State *L) { \
        LAPI_GET_ENT(entity, "CAPI.set"#n, return 0) \
        t v = luaL_check##tt(L, 2); \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        d->an = v; \
        return 0; \
    }

    DYNENT_ACCESSORS(maxspeed, float, number, maxspeed)
    DYNENT_ACCESSORS(radius, float, number, radius)
    DYNENT_ACCESSORS(eyeheight, float, number, eyeheight)
    DYNENT_ACCESSORS(aboveeye, float, number, aboveeye)
    DYNENT_ACCESSORS(yaw, float, number, yaw)
    DYNENT_ACCESSORS(pitch, float, number, pitch)
    DYNENT_ACCESSORS(move, int, integer, move)
    DYNENT_ACCESSORS(strafe, int, integer, strafe)
    DYNENT_ACCESSORS(yawing, int, integer, turn_move)
    DYNENT_ACCESSORS(pitching, int, integer, look_updown_move)
    DYNENT_ACCESSORS(jumping, bool, boolean, jumping)
    DYNENT_ACCESSORS(blocked, bool, boolean, blocked)
    /* XXX should be unsigned */
    DYNENT_ACCESSORS(mapdefinedposdata, int, integer, mapDefinedPositionData)
    DYNENT_ACCESSORS(clientstate, int, integer, state)
    DYNENT_ACCESSORS(physstate, int, integer, physstate)
    DYNENT_ACCESSORS(inwater, int, integer, inwater)
    DYNENT_ACCESSORS(timeinair, int, integer, timeinair)
    #undef DYNENT_ACCESSORS
    #undef luaL_checkboolean

    int _lua_getdynent0(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.getdynent0", return 0)
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);
        lua_createtable(L, 3, 0);
        lua_pushnumber(L, d->o.x); lua_rawseti(L, -2, 1);
        lua_pushnumber(L, d->o.y); lua_rawseti(L, -2, 2);
        lua_pushnumber(L, d->o.z - d->eyeheight/* - d->aboveeye*/);
        lua_rawseti(L, -2, 3);
        return 1;
    }

    int _lua_setdynent0(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.setdynent0", return 0)
        luaL_checktype(L, 2, LUA_TTABLE);
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);

        lua_pushinteger(L, 1); lua_gettable(L, -2);
        d->o.x = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 2); lua_gettable(L, -2);
        d->o.y = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 3); lua_gettable(L, -2);
        d->o.z = luaL_checknumber(L, -1) + d->eyeheight;/* + d->aboveeye; */
        lua_pop(L, 1);

        /* also set newpos, otherwise this change may get overwritten */
        d->newpos = d->o;

        /* no need to interpolate to the last position - just jump */
        d->resetinterp();

        logger::log(
            logger::INFO, "(%i).setdynent0(%f, %f, %f)",
            d->uniqueId, d->o.x, d->o.y, d->o.z
        );
        return 0;
    }

    #define DYNENTVEC(name) \
        int _lua_getdynent##name(lua_State *L) { \
            LAPI_GET_ENT(entity, "CAPI.getdynent"#name, return 0) \
            fpsent *d = (fpsent*)entity->dynamicEntity; \
            assert(d); \
            lua_createtable(L, 3, 0); \
            lua_pushnumber(L, d->name.x); lua_rawseti(L, -2, 1); \
            lua_pushnumber(L, d->name.y); lua_rawseti(L, -2, 2); \
            lua_pushnumber(L, d->name.z); lua_rawseti(L, -2, 3); \
            return 1; \
        } \
        int _lua_setdynent##name(lua_State *L) { \
            LAPI_GET_ENT(entity, "CAPI.setdynent"#name, return 0) \
            fpsent *d = (fpsent*)entity->dynamicEntity; \
            assert(d); \
            lua_pushinteger(L, 1); lua_gettable(L, -2); \
            d->name.x = luaL_checknumber(L, -1); lua_pop(L, 1); \
            lua_pushinteger(L, 2); lua_gettable(L, -2); \
            d->name.y = luaL_checknumber(L, -1); lua_pop(L, 1); \
            lua_pushinteger(L, 3); lua_gettable(L, -2); \
            d->name.z = luaL_checknumber(L, -1); lua_pop(L, 1); \
            return 0; \
        }

    DYNENTVEC(vel)
    DYNENTVEC(falling)
    #undef DYNENTVEC

#ifdef CLIENT
    int _lua_get_target_entity_uid(lua_State *L) {
        if (TargetingControl::targetLogicEntity &&
           !TargetingControl::targetLogicEntity->isNone()) {
            lua_pushinteger(L, TargetingControl::targetLogicEntity->getUniqueId());
            return 1;
        }
        return 0;
    }
#else
    LAPI_EMPTY(get_target_entity_uid)
#endif

    int _lua_getplag(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.getplag", return 0)
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        lua_pushinteger(L, p->plag);
        return 1;
    }

    int _lua_getping(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.getping", return 0)
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        lua_pushinteger(L, p->ping);
        return 1;
    }

    /* input */

#ifdef CLIENT
    int _lua_set_targeted_entity(lua_State *L) {
        if (TargetingControl::targetLogicEntity)
            delete TargetingControl::targetLogicEntity;

        TargetingControl::targetLogicEntity = LogicSystem::getLogicEntity(
            luaL_checkinteger(L, 1));
        lua_pushboolean(L, TargetingControl::targetLogicEntity != NULL);
        return 1;
    }

    int _lua_is_modifier_pressed(lua_State *L) {
        lua_pushboolean(L, SDL_GetModState() != KMOD_NONE);
        return 1;
    }

    int _lua_keyrepeat(lua_State *L) {
        keyrepeat(lua_toboolean(L, 1), luaL_checkinteger(L, 2));
        return 0;
    }

    int _lua_textinput(lua_State *L) {
        textinput(lua_toboolean(L, 1), luaL_checkinteger(L, 2));
        return 0;
    }
#else
    LAPI_EMPTY(set_targeted_entity)
    LAPI_EMPTY(is_modifier_pressed)
    LAPI_EMPTY(textinput)
    LAPI_EMPTY(keyrepeat)
#endif

    /* messages */

    int _lua_personal_servmsg(lua_State *L) {
        const char *title   = luaL_checkstring(L, 2);
        const char *content = luaL_checkstring(L, 3);
        send_PersonalServerMessage(luaL_checkinteger(L, 1),
            title ? title : "", content ? content : "");
        return 0;
    }

    int _lua_particle_splash_toclients(lua_State *L) {
        send_ParticleSplashToClients(luaL_checkinteger(L, 1),
            luaL_checkinteger(L, 2), luaL_checkinteger(L, 3),
            luaL_checkinteger(L, 4), luaL_checknumber(L, 5),
            luaL_checknumber(L, 6), luaL_checknumber(L, 7));
        return 0;
    }

    int _lua_particle_regularsplash_toclients(lua_State *L) {
        send_ParticleSplashRegularToClients(luaL_checkinteger(L, 1),
            luaL_checkinteger(L, 2), luaL_checkinteger(L, 3),
            luaL_checkinteger(L, 4), luaL_checknumber(L, 5),
            luaL_checknumber(L, 6), luaL_checknumber(L, 7));
        return 0;
    }

    int _lua_sound_toclients_byname(lua_State *L) {
        const char *sn = luaL_checkstring(L, 5);
        send_SoundToClientsByName(luaL_checkinteger(L, 1),
            luaL_checknumber(L, 2), luaL_checknumber(L, 3),
            luaL_checknumber(L, 4), sn ? sn : "", luaL_checkinteger(L, 6));
        return 0;
    }

    int _lua_statedata_changerequest(lua_State *L) {
        const char *val = luaL_optstring(L, 3, "");
        send_StateDataChangeRequest(luaL_checkinteger(L, 1),
            luaL_checkinteger(L, 2), val);
        return 0;
    }

    int _lua_statedata_changerequest_unreliable(lua_State *L) {
        const char *val = luaL_optstring(L, 3, "");
        send_UnreliableStateDataChangeRequest(luaL_checkinteger(L, 1),
            luaL_checkinteger(L, 2), val);
        return 0;
    }

    int _lua_notify_numents(lua_State *L) {
        send_NotifyNumEntities(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2));
        return 0;
    }

    int _lua_le_notification_complete(lua_State *L) {
        const char *oc = luaL_checkstring(L, 4);
        const char *sd = luaL_checkstring(L, 5);
        send_LogicEntityCompleteNotification(luaL_checkinteger(L, 1),
            luaL_checkinteger(L, 2), luaL_checkinteger(L, 3), oc, sd ? sd : "");
        return 0;
    }

    int _lua_le_removal(lua_State *L) {
        send_LogicEntityRemoval(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2));
        return 0;
    }

    int _lua_statedata_update(lua_State *L) {
        const char *val = luaL_checkstring(L, 4);
        send_StateDataUpdate(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
            luaL_checkinteger(L, 3), val ? val : "" , luaL_checkinteger(L, 5));
        return 0;
    }

    int _lua_statedata_update_unreliable(lua_State *L) {
        const char *val = luaL_checkstring(L, 4);
        send_UnreliableStateDataUpdate(luaL_checkinteger(L, 1),
            luaL_checkinteger(L, 2), luaL_checkinteger(L, 3), val ? val : "",
            luaL_checkinteger(L, 5));
        return 0;
    }

    int _lua_do_click(lua_State *L) {
        send_DoClick(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
            luaL_checknumber(L, 3), luaL_checknumber (L, 4),
            luaL_checknumber(L, 5), luaL_checkinteger(L, 6));
        return 0;
    }

    int _lua_extent_notification_complete(lua_State *L) {
        const char *oc = luaL_checkstring(L, 3);
        const char *sd = luaL_checkstring(L, 4);
        send_ExtentCompleteNotification(
            luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
            oc ? oc : "", sd ? sd : "",
            luaL_checknumber (L,  5), luaL_checknumber (L,  6),
            luaL_checknumber (L,  7), luaL_checkinteger(L,  8),
            luaL_checkinteger(L,  9), luaL_checkinteger(L, 10),
            luaL_checkinteger(L, 11), luaL_checkinteger(L, 12));
        return 0;
    }

    /* model */

#ifdef CLIENT
    static int oldtp = -1;

    void preparerd(lua_State *L, int& anim, CLogicEntity *self) {
        if (anim&ANIM_RAGDOLL) {
            //if (!ragdoll || loadmodel(mdl);
            fpsent *fp = (fpsent*)self->dynamicEntity;

            if (fp->clientnum == ClientSystem::playerNumber) {
                if (oldtp == -1 && thirdperson == 0) {
                    oldtp = thirdperson;
                    thirdperson = 1;
                }
            }

            if (fp->ragdoll || !ragdoll) {
                anim &= ~ANIM_RAGDOLL;
                lua_rawgeti    (L, LUA_REGISTRYINDEX, self->lua_ref);
                lua_getfield   (L, -1, "set_local_animation");
                lua_insert     (L, -2);
                lua_pushinteger(L, anim);
                lua_call       (L,  2, 0);
            }
        } else {
            if (self->dynamicEntity) {
                fpsent *fp = (fpsent*)self->dynamicEntity;

                if (fp->clientnum == ClientSystem::playerNumber && oldtp != -1) {
                    thirdperson = oldtp;
                    oldtp = -1;
                }
            }
        }
    }

    fpsent *getproxyfpsent(lua_State *L, CLogicEntity *self) {
        lua_rawgeti (L, LUA_REGISTRYINDEX, self->lua_ref);
        lua_getfield(L, -1, "rendering_hash_hint");
        lua_remove  (L, -2);
        if (!lua_isnil(L, -1)) {
            static bool initialized = false;
            static fpsent *fpsentsfr[1024];
            if (!initialized) {
                for (int i = 0; i < 1024; i++) fpsentsfr[i] = new fpsent;
                initialized = true;
            }

            int rhashhint = lua_tointeger(L, -1);
            lua_pop(L, 1);
            rhashhint = rhashhint & 1023;
            assert(rhashhint >= 0 && rhashhint < 1024);
            return fpsentsfr[rhashhint];
        } else {
            lua_pop(L, 1);
            return NULL;
        }
    }

    int _lua_rendermodel(lua_State *L) {
        LAPI_GET_ENT(entity, "CAPI.rendermodel", return 0)

        int anim = luaL_checkinteger(L, 3);
        preparerd(L, anim, entity);
        fpsent *fp = NULL;

        if (entity->dynamicEntity)
            fp = (fpsent*)entity->dynamicEntity;
        else
            fp = getproxyfpsent(L, entity);

        rendermodel(luaL_checkstring(L, 2), anim, vec(luaL_checknumber(L, 4),
            luaL_checknumber(L, 5), luaL_checknumber(L, 6)),
            luaL_checknumber(L, 7), luaL_checknumber(L, 8),
            luaL_checkinteger(L, 9), fp, entity->attachments,
            luaL_checkinteger(L, 10), 0, 1, luaL_optnumber(L, 11, 1.0f));
        return 0;
    }

    #define SMDLBOX(nm, func) \
        int _lua_scriptmdl##nm(lua_State *L) { \
            model *mdl = loadmodel(luaL_checkstring(L, 1)); \
            if   (!mdl) return 0; \
            vec center, radius; \
            mdl->func(center, radius); \
            lua::push_external(L, "new_vec3"); \
            lua_pushnumber(L, center.x); lua_pushnumber(L, center.y); \
            lua_pushnumber(L, center.z); lua_call(L, 3, 1); \
            lua::push_external(L, "new_vec3"); \
            lua_pushnumber(L, radius.x); lua_pushnumber(L, radius.y); \
            lua_pushnumber(L, radius.z); lua_call(L, 3, 1); \
            return 2; \
        }

    SMDLBOX(bb, boundbox)
    SMDLBOX(cb, collisionbox)

    int _lua_mdlmesh(lua_State *L) {
        model *mdl = loadmodel(luaL_checkstring(L, 1));
        if   (!mdl) return 0;

        vector<BIH::tri> tris2[2];
        mdl->gentris(tris2);
        vector<BIH::tri>& tris = tris2[0];

        lua_createtable (L, tris.length(), 0);
        for (int i = 0; i < tris.length(); ++i) {
            BIH::tri& bt = tris[i];
            lua_pushinteger(L, i + 1); /* key   */
            lua_createtable(L, 0, 3);  /* value */

            #define TRIFIELD(n) \
                lua::push_external(L, "new_vec3"); \
                lua_pushnumber(L, bt.n.x); \
                lua_pushnumber(L, bt.n.y); \
                lua_pushnumber(L, bt.n.z); \
                lua_call      (L, 3, 1); \
                lua_setfield  (L, -2, #n); \

            TRIFIELD(a)
            TRIFIELD(b)
            TRIFIELD(c)
            #undef TRIFIELD
            lua_settable(L, -3);
        }
        return 1;
    }
#else
    LAPI_EMPTY(rendermodel)
    LAPI_EMPTY(scriptmdlbb)
    LAPI_EMPTY(scriptmdlcb)
    LAPI_EMPTY(mdlmesh)
#endif

    /* network */

#ifdef CLIENT
    int _lua_connect(lua_State *L) {
        ClientSystem::connect(luaL_checkstring(L, 1), luaL_checkinteger(L, 2));
        return 0;
    }
#else
    LAPI_EMPTY(connect)
#endif

    int _lua_isconnected(lua_State *L) {
        lua_pushboolean(L, isconnected(lua_toboolean(L, 1),
            lua_toboolean(L, 2)));
        return 1;
    }

    int _lua_haslocalclients(lua_State *L) {
        lua_pushboolean(L, haslocalclients());
        return 1;
    }

    int _lua_connectedip(lua_State *L) {
        const ENetAddress *addr = connectedpeer();
        char hn[128];
        if (addr && enet_address_get_host_ip(addr, hn, sizeof(hn)) >= 0) {
            lua_pushstring(L, hn);
            return 1;
        }
        return 0;
    }

    int _lua_connectedport(lua_State *L) {
        const ENetAddress *addr = connectedpeer();
        lua_pushinteger(L, addr ? addr->port : -1);
        return 1;
    }

    int _lua_connectserv(lua_State *L) {
        connectserv(luaL_checkstring(L, 1), luaL_checkinteger(L, 2),
            luaL_optstring(L, 3, NULL));
        return 0;
    }

    int _lua_lanconnect(lua_State *L) {
        connectserv(NULL, luaL_checkinteger(L, 1), luaL_optstring(L, 2, NULL));
        return 0;
    }

    int _lua_disconnect(lua_State *L) {
        trydisconnect(lua_toboolean(L, 1));
        return 0;
    }

    int _lua_localconnect(lua_State *L) {
        if (!isconnected() && !haslocalclients()) localconnect();
        return 0;
    }

    int _lua_localdisconnect(lua_State *L) {
        if (haslocalclients()) localdisconnect();
        return 0;
    }

    int _lua_getfollow(lua_State *L) {
        fpsent *f = game::followingplayer();
        lua_pushinteger(L, f ? f->clientnum : -1);
        return 1;
    }

#ifdef CLIENT
    int _lua_do_upload(lua_State *L) {
        renderprogress(0.1f, "compiling scripts ..");

        if (luaL_loadfile(L, world::get_mapscript_filename()))
        {
            lua_getglobal  (L, "LAPI"); lua_getfield(L, -1, "GUI");
            lua_getfield   (L, -1, "show_message");
            lua_pushliteral(L, "Compilation failed");
            lua_pushvalue  (L, -5);
            lua_call       (L,  2, 0); lua_pop(L, 2);
            return 1;
        }

        renderprogress(0.3, "generating map ..");
        save_world(game::getclientmap());

        renderprogress(0.4, "exporting entities ..");
        world::export_ents("entities.lua");
        return 0;
    }

    int _lua_restart_map(lua_State *L) {
        MessageSystem::send_RestartMap();
        return 0;
    }
#else
    LAPI_EMPTY(do_upload)
    LAPI_EMPTY(restart_map)
#endif

    /* particles */

#ifdef CLIENT
    int _lua_adddecal(lua_State *L) {
        adddecal(luaL_checkinteger(L, 1),
            vec(luaL_checknumber(L, 2), luaL_checknumber(L, 3),
                luaL_checknumber(L, 4)),
            vec(luaL_checknumber(L, 5), luaL_checknumber(L, 6),
                luaL_checknumber(L, 7)),
            luaL_checknumber(L, 8),
            bvec((uchar)luaL_checkinteger(L, 9),
                 (uchar)luaL_checkinteger(L, 10),
                 (uchar)luaL_checkinteger(L, 11)),
            luaL_checkinteger(L, 12));
        return 0;
    }

    int _lua_particle_splash(lua_State *L) {
        int type = luaL_checkinteger(L, 1);
        if (type == PART_BLOOD && !blood) return 0;
        particle_splash(type, luaL_checkinteger(L, 2), luaL_checkinteger(L, 3),
            vec(luaL_checknumber(L, 4), luaL_checknumber(L, 5),
                luaL_checknumber(L, 6)),
            luaL_checkinteger(L, 7), luaL_checknumber(L, 8),
            luaL_checkinteger(L, 9), luaL_checkinteger(L, 10));
        return 0;
    }

    int _lua_regular_particle_splash(lua_State *L) {
        int type = luaL_checkinteger(L, 1);
        if (type == PART_BLOOD && !blood) return 0;
        regular_particle_splash(
            type, luaL_checkinteger(L, 2), luaL_checkinteger(L, 3),
            vec(luaL_checknumber(L, 4), luaL_checknumber(L, 5),
                luaL_checknumber(L, 6)),
            luaL_checkinteger(L, 7), luaL_checknumber(L, 8),
            luaL_checkinteger(L, 9), luaL_checkinteger(L, 10),
            luaL_checkinteger(L, 11));
        return 0;
    }

    int _lua_particle_fireball(lua_State *L) {
        particle_fireball(vec(luaL_checknumber(L, 1),
            luaL_checknumber(L, 3), luaL_checknumber(L, 3)),
            luaL_checknumber(L, 4), luaL_checkinteger(L, 5),
            luaL_checkinteger(L, 6), luaL_checkinteger(L, 7),
            luaL_checknumber(L, 8));
        return 0;
    }

    int _lua_particle_flare(lua_State *L) {
        int uid = luaL_checkinteger(L, 11);
        if (uid < 0) {
            particle_flare(vec(luaL_checknumber(L, 1),
                luaL_checknumber(L, 2), luaL_checknumber(L, 3)),
                vec(luaL_checknumber(L, 4), luaL_checknumber(L, 5),
                    luaL_checknumber(L, 6)),
                luaL_checkinteger(L, 7), luaL_checkinteger(L, 8),
                luaL_checkinteger(L, 9), luaL_checknumber(L, 10), NULL);
        } else {
            CLogicEntity *o = LogicSystem::getLogicEntity(uid);
            assert(o->dynamicEntity);

            particle_flare(vec(luaL_checknumber(L, 1),
                luaL_checknumber(L, 2), luaL_checknumber(L, 3)),
                vec(luaL_checknumber(L, 4), luaL_checknumber(L, 5),
                    luaL_checknumber(L, 6)),
                luaL_checkinteger(L, 7), luaL_checkinteger(L, 8),
                luaL_checkinteger(L, 9), luaL_checknumber(L, 10),
                (fpsent*)(o->dynamicEntity));
        }
        return 0;
    }

    int _lua_particle_trail(lua_State *L) {
        particle_trail(luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
            vec(luaL_checknumber(L, 3), luaL_checknumber(L, 4),
                luaL_checknumber(L, 5)),
            vec(luaL_checknumber(L, 6), luaL_checknumber(L, 7),
                luaL_checknumber(L, 8)), luaL_checkinteger(L, 9),
            luaL_checknumber(L, 10), luaL_checkinteger(L, 11));
        return 0;
    }

    int _lua_particle_flame(lua_State *L) {
        regular_particle_flame(luaL_checkinteger(L, 1),
            vec(luaL_checknumber(L, 2), luaL_checknumber(L, 3),
                luaL_checknumber(L, 4)),
            luaL_checknumber(L, 5), luaL_checknumber(L, 6),
            luaL_checkinteger(L, 7), luaL_checkinteger(L, 8),
            luaL_checknumber(L, 9), luaL_checknumber(L, 10),
            luaL_checknumber(L, 11), luaL_checkinteger(L, 12)
        );
        return 0;
    }

    int _lua_adddynlight(lua_State *L) {
        queuedynlight(vec(luaL_checknumber(L, 1), luaL_checknumber(L, 2),
            luaL_checknumber(L, 3)), luaL_checknumber(L, 4),
            vec(luaL_checknumber(L, 5), luaL_checknumber(L, 6),
                luaL_checknumber(L, 7)),
            luaL_checkinteger(L, 8), luaL_checkinteger(L, 9),
            luaL_checkinteger(L, 10), luaL_checknumber(L, 11),
            vec(luaL_checknumber(L, 12), luaL_checknumber(L, 13),
                luaL_checknumber(L, 14)), NULL);
        return 0;
    }

    int _lua_particle_meter(lua_State *L) {
        particle_meter(vec(luaL_checknumber(L, 1), luaL_checknumber(L, 2),
            luaL_checknumber(L, 3)), luaL_checknumber(L, 4),
            luaL_checkinteger(L, 5), luaL_checkinteger(L, 6));
        return 0;
    }

    int _lua_particle_text(lua_State *L) {
        particle_textcopy(vec(luaL_checknumber(L, 1), luaL_checknumber(L, 2),
            luaL_checknumber(L, 3)), luaL_checkstring(L, 4),
            luaL_checkinteger(L, 5), luaL_checkinteger(L, 6),
            luaL_checkinteger(L, 7), luaL_checknumber(L, 8),
            luaL_checknumber(L, 9));
        return 0;
    }

    int _lua_client_damage_effect(lua_State *L) {
        ((fpsent*)player)->damageroll(luaL_checkinteger(L, 1));
        damageblend(luaL_checkinteger(L, 2));
        return 0;
    }
#else
    LAPI_EMPTY(adddecal)
    LAPI_EMPTY(particle_splash)
    LAPI_EMPTY(regular_particle_splash)
    LAPI_EMPTY(particle_fireball)
    LAPI_EMPTY(particle_flare)
    LAPI_EMPTY(particle_trail)
    LAPI_EMPTY(particle_flame)
    LAPI_EMPTY(adddynlight)
    LAPI_EMPTY(particle_meter)
    LAPI_EMPTY(particle_text)
    LAPI_EMPTY(client_damage_effect)
#endif

    /* sound */

#ifdef CLIENT
    int _lua_playsoundname(lua_State *L) {
        const char *n = "";
        if (!lua_isnoneornil(L, 1)) n = luaL_checkstring(L, 1);
        float x = luaL_checknumber(L, 2), y = luaL_checknumber(L, 3),
              z = luaL_checknumber(L, 4);
        int vol = luaL_optinteger (L, 5, 100);
        if (x || y || z) {
            vec loc(x, y, z);
            playsoundname(n, &loc, vol);
        } else
            playsoundname(n, NULL, vol);
        return 0;
    }

    int _lua_stopsoundname(lua_State *L) {
        const char *n = "";
        if (!lua_isnoneornil(L, 1)) n = luaL_checkstring(L, 1);
        stopsoundbyid(getsoundid(n, luaL_optinteger(L, 2, 100)));
        return 0;
    }

    int _lua_music(lua_State *L) {
        const char *n = "";
        if (!lua_isnoneornil(L, 1)) n = luaL_checkstring(L, 1);
        startmusic(n, "sound.music_callback()");
        return 0;
    }

    int _lua_preloadsound(lua_State *L) {
        const char *n = "";
        if (!lua_isnoneornil(L, 1)) n = luaL_checkstring(L, 1);
        defformatstring(buf)("preloading sound '%s' ...", n);
        renderprogress(0, buf);
        return preload_sound(n, luaL_optinteger(L, 2, 100));
    }

    int _lua_playsound(lua_State *L) {
        playsound(luaL_optinteger(L, 1, 1));
        return 0;
    }
#else
    int _lua_playsound(lua_State *L) {
        MessageSystem::send_SoundToClients(-1, luaL_optinteger(L, 1, 1), -1);
        return 0;
    }

    LAPI_EMPTY(playsoundname)
    LAPI_EMPTY(stopsoundname)
    LAPI_EMPTY(music)
    LAPI_EMPTY(preloadsound)
#endif

    /* textures */

#ifdef CLIENT
    int _lua_parsepixels(lua_State *L) {
        const char *fn = "";
        if (!lua_isnoneornil(L, 1)) fn = luaL_checkstring(L, 1);

        ImageData d;
        if (!loadimage(fn, d)) return 0;

        lua_createtable(L, 0, 3);
        lua_pushinteger(L, d.w); lua_setfield(L, -2, "w");
        lua_pushinteger(L, d.h); lua_setfield(L, -2, "h");

        lua_createtable(L,  d.w, 0);
        for (int x = 0; x < d.w; ++x)
        {
            lua_pushinteger(L, x + 1);
            lua_createtable(L,  d.h, 0);
            for (int y = 0; y < d.h; ++y)
            {
                uchar *p = d.data + y * d.pitch + x * d.bpp;

                Uint32 ret;
                switch (d.bpp)
                {
                    case 1:
                        ret = *p;
                        break;
                    case 2:
                        ret = *(Uint16*)p;
                        break;
                    case 3:
                        if (SDL_BYTEORDER == SDL_BIG_ENDIAN)
                            ret = (p[0] << 16 | p[1] << 8 | p[2]);
                        else
                            ret = (p[0] | p[1] << 8 | p[2] << 16);
                        break;
                    case 4:
                        ret = *(Uint32*)p;
                        break;
                    default:
                        ret = 0;
                        break;
                }

                uchar r, g, b;
                SDL_GetRGB(ret, ((SDL_Surface*)d.owner)->format, &r, &g, &b);

                lua_pushinteger(L, y + 1);
                lua_createtable(L, 0, 3);
                lua_pushinteger(L, r); lua_setfield(L, -2, "r");
                lua_pushinteger(L, g); lua_setfield(L, -2, "g");
                lua_pushinteger(L, b); lua_setfield(L, -2, "b");
                lua_settable   (L, -3);
            }
            lua_settable(L, -3);
        }
        lua_setfield(L, -2, "data");
        return 1;
    }

    int _lua_filltexlist(lua_State *L) {
        filltexlist();
        return 0;
    }

    int _lua_getnumslots(lua_State *L) {
        lua_pushinteger(L, slots.length());
        return 1;
    }

    int _lua_hastexslot(lua_State *L) {
        lua_pushboolean(L, texmru.inrange((int)luaL_checkinteger(L, 1)));
        return 1;
    }

    int _lua_checkvslot(lua_State *L) {
        VSlot &vslot = lookupvslot(texmru[luaL_checkinteger(L, 1)], false);
        if(vslot.slot->sts.length() && (vslot.slot->loaded || vslot.slot->thumbnail))
            lua_pushboolean(L, true);
        lua_pushboolean(L, false);
        return 1;
    }

    VAR(thumbtime, 0, 25, 1000);
    static int lastthumbnail = 0;

    void drawslot(Slot &slot, VSlot &vslot, float w, float h, float sx, float sy) {
        Texture *tex = notexture, *glowtex = NULL, *layertex = NULL;
        VSlot *layer = NULL;
        if (slot.loaded) {
            tex = slot.sts[0].t;
            if(slot.texmask&(1<<TEX_GLOW)) {
                loopv(slot.sts) if(slot.sts[i].type==TEX_GLOW)
                { glowtex = slot.sts[i].t; break; }
            }
            if (vslot.layer) {
                layer = &lookupvslot(vslot.layer);
                if(!layer->slot->sts.empty())
                    layertex = layer->slot->sts[0].t;
            }
        }
        else if (slot.thumbnail) tex = slot.thumbnail;
        float xt, yt;
        xt = min(1.0f, tex->xs/(float)tex->ys),
        yt = min(1.0f, tex->ys/(float)tex->xs);

        static Shader *rgbonlyshader = NULL;
        if (!rgbonlyshader) rgbonlyshader = lookupshaderbyname("rgbonly");
        rgbonlyshader->set();

        vec2 tc[4] = { vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 1) };
        int xoff = vslot.offset.x, yoff = vslot.offset.y;
        if (vslot.rotation) {
            if ((vslot.rotation&5) == 1) { swap(xoff, yoff); loopk(4) swap(tc[k].x, tc[k].y); }
            if (vslot.rotation >= 2 && vslot.rotation <= 4) { xoff *= -1; loopk(4) tc[k].x *= -1; }
            if (vslot.rotation <= 2 || vslot.rotation == 5) { yoff *= -1; loopk(4) tc[k].y *= -1; }
        }
        loopk(4) { tc[k].x = tc[k].x/xt - float(xoff)/tex->xs; tc[k].y = tc[k].y/yt - float(yoff)/tex->ys; }
        gle::color(slot.loaded ? vslot.colorscale : vec(1, 1, 1));
        glBindTexture(GL_TEXTURE_2D, tex->id);
        gle::defvertex(2);
        gle::deftexcoord0();
        gle::begin(GL_TRIANGLE_STRIP);
        gle::attribf(sx,     sy);     gle::attrib(tc[0]);
        gle::attribf(sx + w, sy);     gle::attrib(tc[1]);
        gle::attribf(sx,     sy + h); gle::attrib(tc[3]);
        gle::attribf(sx + w, sy + h); gle::attrib(tc[2]);
        gle::end();

        if (glowtex) {
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            glBindTexture(GL_TEXTURE_2D, glowtex->id);
            gle::color(vslot.glowcolor);
            gle::begin(GL_TRIANGLE_STRIP);
            gle::attribf(sx,     sy);     gle::attrib(tc[0]);
            gle::attribf(sx + w, sy);     gle::attrib(tc[1]);
            gle::attribf(sx,     sy + h); gle::attrib(tc[3]);
            gle::attribf(sx + w, sy + h); gle::attrib(tc[2]);
            gle::end();
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
        if (layertex) {
            glBindTexture(GL_TEXTURE_2D, layertex->id);
            gle::color(layer->colorscale);
            gle::begin(GL_TRIANGLE_STRIP);
            gle::attribf(sx + w / 2, sy + h / 2); gle::attrib(tc[0]);
            gle::attribf(sx + w,     sy + h / 2); gle::attrib(tc[1]);
            gle::attribf(sx + w / 2, sy + h);     gle::attrib(tc[3]);
            gle::attribf(sx + w,     sy + h);     gle::attrib(tc[2]);
            gle::end();
        }

        gle::color(vec(1, 1, 1));
        hudshader->set();
    }

    int _lua_texture_draw_slot(lua_State *L) {
        int slotnum = luaL_checkinteger(L, 1);
        float w  = luaL_checknumber(L, 2), h  = luaL_checknumber(L, 3);
        float sx = luaL_checknumber(L, 4), sy = luaL_checknumber(L, 5);
        if (texmru.inrange(slotnum))
        {
            VSlot &vslot = lookupvslot(texmru[slotnum], false);
            Slot &slot = *vslot.slot;
            if (slot.sts.length())
            {
                if(slot.loaded || slot.thumbnail)
                    drawslot(slot, vslot, w, h, sx, sy);

                else if (totalmillis-lastthumbnail >= thumbtime)
                {
                    loadthumbnail(slot);
                    lastthumbnail = totalmillis;
                }
            }
        }
        return 0;
    }

    #define TEXPROP(field, func) \
    static int texture_get_##field(lua_State *L) { \
        Texture *tex = luachecktexture(L, 1); \
        lua_push##func(L, tex->field); \
        return 1; \
    }

    TEXPROP(name, string)
    TEXPROP(type, integer)
    TEXPROP(w, integer)
    TEXPROP(h, integer)
    TEXPROP(xs, integer)
    TEXPROP(ys, integer)
    TEXPROP(bpp, integer)
    TEXPROP(clamp, integer)
    TEXPROP(mipmap, boolean)
    TEXPROP(canreduce, boolean)
    TEXPROP(id, integer)
    #undef TEXPROP

    static int texture_get_alphamask(lua_State *L) {
        Texture *tex = luachecktexture(L, 1);
        if (lua_gettop(L) > 1) {
            int idx = luaL_checkinteger(L, 2);
            luaL_argcheck(L, idx < (tex->h * ((tex->w + 7) / 8)),
                1, "index out of range");
            lua_pushinteger(L, tex->alphamask[idx]);
        } else {
            lua_pushboolean(L, tex->alphamask != NULL);
        }
        return 1;
    }

    static void texture_setmeta(lua_State *L) {
        if (luaL_newmetatable(L, "Texture")) {
            lua_createtable(L, 0, 11);
            #define TEXFIELD(field) \
                lua_pushcfunction(L, texture_get_##field); \
                lua_setfield(L, -2, "get_" #field);

            TEXFIELD(name)
            TEXFIELD(type)
            TEXFIELD(w)
            TEXFIELD(h)
            TEXFIELD(xs)
            TEXFIELD(ys)
            TEXFIELD(bpp)
            TEXFIELD(clamp)
            TEXFIELD(mipmap)
            TEXFIELD(canreduce)
            TEXFIELD(id)
            TEXFIELD(alphamask)
            #undef TEXFIELD
            lua_setfield(L, -2, "__index");
        }
        lua_setmetatable(L, -2);
    }

    int _lua_texture_load(lua_State *L) {
        const char *path = luaL_checkstring(L, 1);
        Texture **tex = (Texture**)lua_newuserdata(L, sizeof(void*));
        texture_setmeta(L);
        *tex = textureload(path, 3, true, false);
        return 1;
    }

    int _lua_texture_is_notexture(lua_State *L) {
        lua_pushboolean(L, luachecktexture(L, 1) == notexture);
        return 1;
    }

    int _lua_texture_load_alpha_mask(lua_State *L) {
        loadalphamask(luachecktexture(L, 1));
        return 0;
    }

#else
    LAPI_EMPTY(parsepixels)
    LAPI_EMPTY(filltexlist)
    LAPI_EMPTY(getnumslots)
    LAPI_EMPTY(hastexslot)
    LAPI_EMPTY(checkvslot)
    LAPI_EMPTY(texture_draw_slot)
#endif

    /* Geometry utilities */

    int _lua_raylos(lua_State *L) {
        vec target(0);
        lua_pushboolean(L, raycubelos(vec(luaL_checknumber(L, 1),
            luaL_checknumber(L, 2), luaL_checknumber(L, 3)),
            vec(luaL_checknumber(L, 4), luaL_checknumber(L, 5),
                luaL_checknumber(L, 6)), target));
        return 1;
    }

    int _lua_raypos(lua_State *L) {
        vec hitpos(0);
        lua_pushnumber(L, raycubepos(vec(luaL_checknumber(L, 1),
            luaL_checknumber(L, 2), luaL_checknumber(L, 3)),
            vec(luaL_checknumber(L, 4), luaL_checknumber(L, 5),
                luaL_checknumber(L, 6)), hitpos, luaL_checknumber(L, 7),
            RAY_CLIPMAT | RAY_POLY));
        return 1;
    }

    int _lua_rayfloor(lua_State *L) {
        vec floor(0);
        lua_pushnumber(L, rayfloor(vec(luaL_checknumber(L, 1),
            luaL_checknumber(L, 2), luaL_checknumber(L, 3)), floor, 0,
                luaL_checknumber(L, 4)));
        return 1;
    }

#ifdef CLIENT
    int _lua_gettargetpos(lua_State *L) {
        TargetingControl::determineMouseTarget(true);
        vec o(TargetingControl::targetPosition);
        lua_pushnumber(L, o.x); lua_pushnumber(L, o.y); lua_pushnumber(L, o.z);
        return 3;
    }

    int _lua_gettargetent(lua_State *L) {
        TargetingControl::determineMouseTarget(true);
        CLogicEntity *target = TargetingControl::targetLogicEntity;
        if (target && !target->isNone() && target->lua_ref != LUA_REFNIL) {
            lua_rawgeti(L, LUA_REGISTRYINDEX, target->lua_ref);
            return 1;
        }
        return 0;
    }
#else
    LAPI_EMPTY(gettargetpos)
    LAPI_EMPTY(gettargetent)
#endif

    /* World */

    int _lua_iscolliding(lua_State *L) {
        int uid = luaL_checkinteger(L, 5);
        CLogicEntity *ignore = (uid != -1) ? LogicSystem::getLogicEntity(uid)
            : NULL;

        physent tester;

        tester.reset();
        tester.type = ENT_BOUNCE;
        tester.o    = vec(luaL_checknumber(L, 1), luaL_checknumber(L, 2),
                               luaL_checknumber(L, 3));
        float r = luaL_checknumber(L, 4);
        tester.radius    = tester.xradius = tester.yradius = r;
        tester.eyeheight = tester.aboveeye  = r;

        if (!collide(&tester, vec(0))) {
            if (ignore && ignore->isDynamic() &&
                ignore->dynamicEntity == hitplayer
            ) {
                vec save = ignore->dynamicEntity->o;
                avoidcollision(ignore->dynamicEntity, vec(1), &tester, 0.1f);

                bool ret = !collide(&tester, vec(0));
                ignore->dynamicEntity->o = save;

                lua_pushboolean(L, ret);
            }
            else lua_pushboolean(L, true);
        } else lua_pushboolean(L, false);
        return 1;
    }

    int _lua_setgravity(lua_State *L) {
        GRAVITY = luaL_checknumber(L, 1);
        return 0;
    }

    int _lua_getmat(lua_State *L) {
        lua_pushinteger(L, lookupmaterial(vec(luaL_checknumber(L, 1),
            luaL_checknumber(L, 2), luaL_checknumber(L, 3))));
        return 1;
    }

#ifdef CLIENT
    int _lua_hasmap(lua_State *L) {
        lua_pushboolean(L, local_server::is_running());
        return 1;
    }
#else
    LAPI_EMPTY(hasmap)
#endif

    int _lua_get_map_preview_filename(lua_State *L) {
        defformatstring(buf)("data%cmaps%c%s%cpreview.png", PATHDIV, PATHDIV,
            luaL_checkstring(L, 1), PATHDIV);
        if (fileexists(buf, "r")) {
            lua_pushstring(L, buf);
            return 1;
        }

        defformatstring(buff)("%s%s", homedir, buf);
        if (fileexists(buff, "r")) {
            lua_pushstring(L, buff);
            return 1;
        }

        return 0;
    }

    int _lua_get_all_map_names(lua_State *L) {
        vector<char*> dirs;

        lua_createtable(L, 0, 0);
        listfiles("data/maps", NULL, dirs, FTYPE_DIR, LIST_ROOT);
        loopv(dirs) {
            char *dir = dirs[i];
            lua_pushstring(L, dir);
            lua_rawseti(L, -2, i + 1);
            delete[] dir;
        }

        dirs.setsize(0);

        lua_createtable(L, 0, 0);
        listfiles("data/maps", NULL, dirs,
            FTYPE_DIR, LIST_HOMEDIR|LIST_PACKAGE|LIST_ZIP);
        loopv(dirs) {
            char *dir = dirs[i];
            /* redundancy check - we're taking multiple source directories,
             * there is a high possibility of duplicate entries */
            bool r = false;
            loopj(i) if (!strcmp(dirs[j], dir)) { r = true; break; }
            if (r) { delete[] dir; continue; }
            lua_pushstring(L, dir);
            lua_rawseti(L, -2, i + 1);
            delete[] dir;
        }

        return 2;
    }

    LAPI_REG(log);
    LAPI_REG(should_log);
    LAPI_REG(echo);
    LAPI_REG(lastmillis);
    LAPI_REG(totalmillis);
    LAPI_REG(currtime);
    LAPI_REG(cubescript);
    LAPI_REG(readfile);
    LAPI_REG(getserverlogfile);
    LAPI_REG(setup_library);
    LAPI_REG(save_mouse_position);

    LAPI_REG(var_reset);
    LAPI_REG(var_new_i);
    LAPI_REG(var_new_f);
    LAPI_REG(var_new_s);
    LAPI_REG(var_set_i);
    LAPI_REG(var_set_f);
    LAPI_REG(var_set_s);
    LAPI_REG(var_get_i);
    LAPI_REG(var_get_f);
    LAPI_REG(var_get_s);
    LAPI_REG(var_get_min_i);
    LAPI_REG(var_get_min_f);
    LAPI_REG(var_get_max_i);
    LAPI_REG(var_get_max_f);
    LAPI_REG(var_get_def_i);
    LAPI_REG(var_get_def_f);
    LAPI_REG(var_get_def_s);
    LAPI_REG(var_get_type);
    LAPI_REG(var_exists);
    LAPI_REG(var_is_hex);
    LAPI_REG(var_emits);
    LAPI_REG(var_emits_set);

#ifdef CLIENT
    LAPI_REG(input_get_modifier_state);
    LAPI_REG(gui_set_mainmenu);
    LAPI_REG(gui_text_bounds);
    LAPI_REG(gui_text_bounds_f);
    LAPI_REG(gui_text_pos);
    LAPI_REG(gui_text_pos_f);
    LAPI_REG(gui_text_visible);
    LAPI_REG(gui_draw_text);
#endif
    /* camera */
    LAPI_REG(getcamyaw);
    LAPI_REG(getcampitch);
    LAPI_REG(getcamroll);
    LAPI_REG(getcampos);

    /* edit */
    LAPI_REG(editing_getworldsize);
    LAPI_REG(editing_getgridsize);
    LAPI_REG(editing_erasegeometry);
    LAPI_REG(editing_createcube);
    LAPI_REG(editing_deletecube);
    LAPI_REG(editing_setcubetex);
    LAPI_REG(editing_setcubemat);
    LAPI_REG(editing_setcubecolor);
    LAPI_REG(editing_pushcubecorner);
    LAPI_REG(editing_getselent);
    LAPI_REG(npcadd);
    LAPI_REG(npcdel);
    LAPI_REG(spawnent);
    LAPI_REG(requestprivedit);
    LAPI_REG(hasprivedit);

    /* entity */
    LAPI_REG(unregister_entity);
    LAPI_REG(setupextent);
    LAPI_REG(setupcharacter);
    LAPI_REG(setupnonsauer);
    LAPI_REG(dismantleextent);
    LAPI_REG(dismantlecharacter);
    LAPI_REG(setanim);
    LAPI_REG(getstarttime);
    LAPI_REG(setmodelname);
    LAPI_REG(setsoundname);
    LAPI_REG(setsoundvol);
    LAPI_REG(setattachments);
    LAPI_REG(getattachmentpos);
    LAPI_REG(setcanmove);
    LAPI_REG(getattr1);
    LAPI_REG(setattr1);
    LAPI_REG(FAST_setattr1);
    LAPI_REG(getattr2);
    LAPI_REG(setattr2);
    LAPI_REG(FAST_setattr2);
    LAPI_REG(getattr3);
    LAPI_REG(setattr3);
    LAPI_REG(FAST_setattr3);
    LAPI_REG(getattr4);
    LAPI_REG(setattr4);
    LAPI_REG(FAST_setattr4);
    LAPI_REG(getattr5);
    LAPI_REG(setattr5);
    LAPI_REG(FAST_setattr5);
    LAPI_REG(getcollisionradw);
    LAPI_REG(setcollisionradw);
    LAPI_REG(getcollisionradh);
    LAPI_REG(setcollisionradh);
    LAPI_REG(getextent0);
    LAPI_REG(setextent0);
    LAPI_REG(getmaxspeed);
    LAPI_REG(setmaxspeed);
    LAPI_REG(getradius);
    LAPI_REG(setradius);
    LAPI_REG(geteyeheight);
    LAPI_REG(seteyeheight);
    LAPI_REG(getaboveeye);
    LAPI_REG(setaboveeye);
    LAPI_REG(getyaw);
    LAPI_REG(setyaw);
    LAPI_REG(getpitch);
    LAPI_REG(setpitch);
    LAPI_REG(getmove);
    LAPI_REG(setmove);
    LAPI_REG(getstrafe);
    LAPI_REG(setstrafe);
    LAPI_REG(getyawing);
    LAPI_REG(setyawing);
    LAPI_REG(getpitching);
    LAPI_REG(setpitching);
    LAPI_REG(getjumping);
    LAPI_REG(setjumping);
    LAPI_REG(getblocked);
    LAPI_REG(setblocked);
    LAPI_REG(getmapdefinedposdata);
    LAPI_REG(setmapdefinedposdata);
    LAPI_REG(getclientstate);
    LAPI_REG(setclientstate);
    LAPI_REG(getphysstate);
    LAPI_REG(setphysstate);
    LAPI_REG(getinwater);
    LAPI_REG(setinwater);
    LAPI_REG(gettimeinair);
    LAPI_REG(settimeinair);
    LAPI_REG(getdynent0);
    LAPI_REG(setdynent0);
    LAPI_REG(getdynentvel);
    LAPI_REG(setdynentvel);
    LAPI_REG(getdynentfalling);
    LAPI_REG(setdynentfalling);
    LAPI_REG(get_target_entity_uid);
    LAPI_REG(getplag);
    LAPI_REG(getping);

    /* input */
    LAPI_REG(set_targeted_entity);
    LAPI_REG(is_modifier_pressed);
    LAPI_REG(textinput);
    LAPI_REG(keyrepeat);

    /* messages */
    LAPI_REG(personal_servmsg);
    LAPI_REG(particle_splash_toclients);
    LAPI_REG(particle_regularsplash_toclients);
    LAPI_REG(sound_toclients_byname);
    LAPI_REG(statedata_changerequest);
    LAPI_REG(statedata_changerequest_unreliable);
    LAPI_REG(notify_numents);
    LAPI_REG(le_notification_complete);
    LAPI_REG(le_removal);
    LAPI_REG(statedata_update);
    LAPI_REG(statedata_update_unreliable);
    LAPI_REG(do_click);
    LAPI_REG(extent_notification_complete);

    /* model */
    LAPI_REG(rendermodel);
    LAPI_REG(scriptmdlbb);
    LAPI_REG(scriptmdlcb);
    LAPI_REG(mdlmesh);

    /* network */
    LAPI_REG(connect);
    LAPI_REG(isconnected);
    LAPI_REG(haslocalclients);
    LAPI_REG(connectedip);
    LAPI_REG(connectedport);
    LAPI_REG(connectserv);
    LAPI_REG(lanconnect);
    LAPI_REG(disconnect);
    LAPI_REG(localconnect);
    LAPI_REG(localdisconnect);
    LAPI_REG(getfollow);
    LAPI_REG(do_upload);
    LAPI_REG(restart_map);

    /* particles */
    LAPI_REG(adddecal);
    LAPI_REG(particle_splash);
    LAPI_REG(regular_particle_splash);
    LAPI_REG(particle_fireball);
    LAPI_REG(particle_flare);
    LAPI_REG(particle_trail);
    LAPI_REG(particle_flame);
    LAPI_REG(adddynlight);
    LAPI_REG(particle_meter);
    LAPI_REG(particle_text);
    LAPI_REG(client_damage_effect);

    /* sound */
    LAPI_REG(playsoundname);
    LAPI_REG(stopsoundname);
    LAPI_REG(music);
    LAPI_REG(preloadsound);
    LAPI_REG(playsound);

    /* textures */
    LAPI_REG(parsepixels);
    LAPI_REG(filltexlist);
    LAPI_REG(getnumslots);
    LAPI_REG(hastexslot);
    LAPI_REG(checkvslot);
    LAPI_REG(texture_draw_slot);
#ifdef CLIENT
    LAPI_REG(texture_load);
    LAPI_REG(texture_is_notexture);
    LAPI_REG(texture_load_alpha_mask);
#endif

    /* world */
    LAPI_REG(raylos);
    LAPI_REG(raypos);
    LAPI_REG(rayfloor);
    LAPI_REG(gettargetpos);
    LAPI_REG(gettargetent);
    LAPI_REG(iscolliding);
    LAPI_REG(setgravity);
    LAPI_REG(getmat);
    LAPI_REG(hasmap);
    LAPI_REG(get_map_preview_filename);
    LAPI_REG(get_all_map_names);
}
