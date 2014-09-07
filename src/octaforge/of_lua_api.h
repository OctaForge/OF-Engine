void trydisconnect(bool local);

namespace game
{
    gameent *followingplayer();
}

extern float GRAVITY;
extern physent *collideplayer;
void writemediacfg(int level);

namespace lapi_binds
{
    using namespace MessageSystem;

    int _lua_log(lua_State *L) {
        logger::log((logger::loglevel)luaL_checkinteger(L, 1),
            "%s", luaL_checkstring(L, 2));
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
            formatstring(buf, "media/%s", p);
        }

        if (!(loaded = loadfile(path(buf), NULL))) {
            logger::log(logger::ERROR, "count not read \"%s\"", p);
            return 0;
        }
        lua_pushstring(L, loaded);
        return 1;
    }

    /* edit */

#ifdef SERVER
    int _lua_npcadd(lua_State *L) {
        int cn = localconnect();

        defformatstring(buf, "Bot.%d", cn);
        logger::log(logger::DEBUG, "New NPC with client number: %i", cn);

        const char *cl = luaL_checkstring(L, 1);
        lua_pushinteger(L, server::createluaEntity(cn, cl ? cl : "", buf));
        return 1;
    }

    int _lua_npcdel(lua_State *L) {
        int uid = luaL_checkinteger(L, 1);
        LUA_GET_ENT(entity, uid, "_C.npcdel", return 0)
        gameent *fp = (gameent*)entity->dynamicEntity;
        localdisconnect(true, fp->clientnum);
        return 0;
    }
#else
    int _lua_npcadd(lua_State *L) {
        logger::log(logger::ERROR, "_C.npcadd: server-only function.");
        return 0;
    }

    int _lua_npcdel(lua_State *L) {
        logger::log(logger::ERROR, "_C.npcdel: server-only function.");
        return 0;
    }
#endif

#ifndef SERVER
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

    /* input */

#ifndef SERVER
    int _lua_set_targeted_entity(lua_State *L) {
        if (TargetingControl::targetLogicEntity)
            delete TargetingControl::targetLogicEntity;

        TargetingControl::targetLogicEntity = LogicSystem::getLogicEntity(
            luaL_checkinteger(L, 1));
        lua_pushboolean(L, TargetingControl::targetLogicEntity != NULL);
        return 1;
    }
#else
    LAPI_EMPTY(set_targeted_entity)
#endif

    /* messages */

    int _lua_personal_servmsg(lua_State *L) {
        const char *title   = luaL_checkstring(L, 2);
        const char *content = luaL_checkstring(L, 3);
        send_PersonalServerMessage(luaL_checkinteger(L, 1),
            title ? title : "", content ? content : "");
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
        send_DoClick(luaL_checkinteger(L, 1), lua_toboolean(L, 2),
            luaL_checknumber(L, 3), luaL_checknumber (L, 4),
            luaL_checknumber(L, 5), luaL_checkinteger(L, 6));
        return 0;
    }

    int _lua_extent_notification_complete(lua_State *L) {
        const char *oc = luaL_checkstring(L, 3);
        const char *sd = luaL_checkstring(L, 4);
        send_ExtentCompleteNotification(
            luaL_checkinteger(L, 1), luaL_checkinteger(L, 2),
            oc ? oc : "", sd ? sd : "");
        return 0;
    }

    /* network */

#ifndef SERVER
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
        gameent *f = game::followingplayer();
        lua_pushinteger(L, f ? f->clientnum : -1);
        return 1;
    }

#ifndef SERVER
    static void do_upload(bool skipmedia, int medialevel) {
        renderprogress(0.1f, "compiling scripts...");

        bool b;
        lua::pop_external_ret(lua::call_external_ret("mapscript_verify", "s",
            "b", world::get_mapfile_path("map.oct"), &b));
        if (!b) return;

        renderprogress(0.3, "generating map...");
        save_world(game::getclientmap());

        renderprogress(0.4, "exporting entities...");
        world::export_ents("entities.oct");

        if (!skipmedia) writemediacfg(medialevel);
    }

    int _lua_do_upload(lua_State *L) {
        do_upload(lua_toboolean(L, 1), luaL_optinteger(L, 2, 0));
        return 0;
    }
    ICOMMAND(savemap, "ii", (int *skipmedia, int *medialevel), {
        do_upload(*skipmedia != 0, *medialevel);
    });

    int _lua_restart_map(lua_State *L) {
        MessageSystem::send_RestartMap();
        return 0;
    }
#else
    LAPI_EMPTY(do_upload)
    LAPI_EMPTY(restart_map)
#endif

#ifndef SERVER
    int _lua_gettargetpos(lua_State *L) {
        TargetingControl::determineMouseTarget(true);
        vec o(TargetingControl::targetPosition);
        lua_pushnumber(L, o.x); lua_pushnumber(L, o.y); lua_pushnumber(L, o.z);
        return 3;
    }

    int _lua_gettargetent(lua_State *L) {
        TargetingControl::determineMouseTarget(true);
        CLogicEntity *target = TargetingControl::targetLogicEntity;
        if (target)
            lua_pushinteger(L, target->getUniqueId());
        else
            lua_pushinteger(L, -1);
        return 1;
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

        if (collide(&tester, vec(0))) {
            if (ignore && ignore->isDynamic() &&
                ignore->dynamicEntity == collideplayer
            ) {
                vec save = ignore->dynamicEntity->o;
                avoidcollision(ignore->dynamicEntity, vec(1), &tester, 0.1f);

                bool ret = collide(&tester, vec(0));
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

#ifndef SERVER
    int _lua_hasmap(lua_State *L) {
        lua_pushboolean(L, local_server::is_running());
        return 1;
    }
#else
    LAPI_EMPTY(hasmap)
#endif

    int _lua_get_map_preview_filename(lua_State *L) {
        defformatstring(buf, "media/map/%s/preview.png",
            luaL_checkstring(L, 1));
        if (fileexists(path(buf), "r")) {
            lua_pushstring(L, buf);
            return 1;
        }

        defformatstring(buff, "%s%s", homedir, buf);
        if (fileexists(path(buff), "r")) {
            lua_pushstring(L, buff);
            return 1;
        }

        return 0;
    }

    int _lua_get_all_map_names(lua_State *L) {
        vector<char*> dirs;

        lua_createtable(L, 0, 0);
        listfiles("media/map", NULL, dirs, FTYPE_DIR, LIST_ROOT);
        int j = 1;
        loopv(dirs) {
            char *dir = dirs[i];
            if (dir[0] == '.') { delete[] dir; continue; }
            lua_pushstring(L, dir);
            lua_rawseti(L, -2, j);
            delete[] dir;
            ++j;
        }

        dirs.setsize(0);

        lua_createtable(L, 0, 0);
        listfiles("media/map", NULL, dirs,
            FTYPE_DIR, LIST_HOMEDIR|LIST_PACKAGE|LIST_ZIP);
        loopvrev(dirs) {
            char *dir = dirs[i];
            bool r = false;
            loopj(i) if (!strcmp(dirs[j], dir)) { r = true; break; }
            if (r) delete[] dirs.removeunordered(i);
        }
        j = 1;
        loopv(dirs) {
            char *dir = dirs[i];
            if (dir[0] == '.') { delete[] dir; continue; }
            lua_pushstring(L, dir);
            lua_rawseti(L, -2, j);
            delete[] dir;
            ++j;
        }

        return 2;
    }

    LUACOMMAND(log, _lua_log);
    LUACOMMAND(should_log, _lua_should_log);
    LUACOMMAND(echo, _lua_echo);
    LUACOMMAND(readfile, _lua_readfile);

    /* edit */
    LUACOMMAND(npcadd, _lua_npcadd);
    LUACOMMAND(npcdel, _lua_npcdel);
    LUACOMMAND(requestprivedit, _lua_requestprivedit);
    LUACOMMAND(hasprivedit, _lua_hasprivedit);

    /* input */
    LUACOMMAND(set_targeted_entity, _lua_set_targeted_entity);

    /* messages */
    LUACOMMAND(personal_servmsg, _lua_personal_servmsg);
    LUACOMMAND(statedata_changerequest, _lua_statedata_changerequest);
    LUACOMMAND(statedata_changerequest_unreliable, _lua_statedata_changerequest_unreliable);
    LUACOMMAND(notify_numents, _lua_notify_numents);
    LUACOMMAND(le_notification_complete, _lua_le_notification_complete);
    LUACOMMAND(le_removal, _lua_le_removal);
    LUACOMMAND(statedata_update, _lua_statedata_update);
    LUACOMMAND(statedata_update_unreliable, _lua_statedata_update_unreliable);
    LUACOMMAND(do_click, _lua_do_click);
    LUACOMMAND(extent_notification_complete, _lua_extent_notification_complete);

    /* network */
    LUACOMMAND(connect, _lua_connect);
    LUACOMMAND(isconnected, _lua_isconnected);
    LUACOMMAND(haslocalclients, _lua_haslocalclients);
    LUACOMMAND(connectedip, _lua_connectedip);
    LUACOMMAND(connectedport, _lua_connectedport);
    LUACOMMAND(connectserv, _lua_connectserv);
    LUACOMMAND(lanconnect, _lua_lanconnect);
    LUACOMMAND(disconnect, _lua_disconnect);
    LUACOMMAND(localconnect, _lua_localconnect);
    LUACOMMAND(localdisconnect, _lua_localdisconnect);
    LUACOMMAND(getfollow, _lua_getfollow);
    LUACOMMAND(do_upload, _lua_do_upload);
    LUACOMMAND(restart_map, _lua_restart_map);

    /* world */
    LUACOMMAND(gettargetpos, _lua_gettargetpos);
    LUACOMMAND(gettargetent, _lua_gettargetent);
    LUACOMMAND(iscolliding, _lua_iscolliding);
    LUACOMMAND(setgravity, _lua_setgravity);
    LUACOMMAND(hasmap, _lua_hasmap);
    LUACOMMAND(get_map_preview_filename, _lua_get_map_preview_filename);
    LUACOMMAND(get_all_map_names, _lua_get_all_map_names);
}
