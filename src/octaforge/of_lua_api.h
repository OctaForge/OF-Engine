void trydisconnect(bool local);

namespace game
{
    fpsent *followingplayer();
}

extern float GRAVITY;
extern physent *collideplayer;

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
            formatstring(buf, "media%c%s", PATHDIV, p);
        }

        if (!(loaded = loadfile(path(buf, true), NULL))) {
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
        /* returns true  == 1 when there is an entity on the stack
         * returns false == 0 when there is no entity on the stack */
        return server::createluaEntity(cn, cl ? cl : "", buf);
    }

    int _lua_npcdel(lua_State *L) {
        int uid = luaL_checkinteger(L, 1);
        LUA_GET_ENT(entity, uid, "_C.npcdel", return 0)
        fpsent *fp = (fpsent*)entity->dynamicEntity;
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
        fpsent *f = game::followingplayer();
        lua_pushinteger(L, f ? f->clientnum : -1);
        return 1;
    }

#ifndef SERVER
    int _lua_do_upload(lua_State *L) {
        renderprogress(0.1f, "compiling scripts ..");

        if (lua::load_file(L, world::get_mapscript_filename()))
        {
            assert(lua::push_external(L, "gui_show_message"));
            lua_pushliteral(L, "Compilation failed");
            lua_pushvalue  (L, -3);
            lua_call       (L,  2, 0);
            lua_pop        (L, 1);
            return 0;
        }
        lua_pop(L, 1);

        renderprogress(0.3, "generating map ..");
        save_world(game::getclientmap());

        renderprogress(0.4, "exporting entities ..");
        world::export_ents("entities.lua");
        return 0;
    }
    ICOMMAND(savemap, "", (), { _lua_do_upload(lua::L); });

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
        if (target && target->lua_ref != LUA_REFNIL) {
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

    int _lua_getmat(lua_State *L) {
        lua_pushinteger(L, lookupmaterial(vec(luaL_checknumber(L, 1),
            luaL_checknumber(L, 2), luaL_checknumber(L, 3))));
        return 1;
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
        defformatstring(buf, "media%cmap%c%s%cpreview.png", PATHDIV, PATHDIV,
            luaL_checkstring(L, 1), PATHDIV);
        if (fileexists(buf, "r")) {
            lua_pushstring(L, buf);
            return 1;
        }

        defformatstring(buff, "%s%s", homedir, buf);
        if (fileexists(buff, "r")) {
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

    LAPI_REG(log);
    LAPI_REG(should_log);
    LAPI_REG(echo);
    LAPI_REG(readfile);

    /* edit */
    LAPI_REG(npcadd);
    LAPI_REG(npcdel);
    LAPI_REG(requestprivedit);
    LAPI_REG(hasprivedit);

    /* input */
    LAPI_REG(set_targeted_entity);

    /* messages */
    LAPI_REG(personal_servmsg);
    LAPI_REG(statedata_changerequest);
    LAPI_REG(statedata_changerequest_unreliable);
    LAPI_REG(notify_numents);
    LAPI_REG(le_notification_complete);
    LAPI_REG(le_removal);
    LAPI_REG(statedata_update);
    LAPI_REG(statedata_update_unreliable);
    LAPI_REG(do_click);
    LAPI_REG(extent_notification_complete);

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

    /* world */
    LAPI_REG(gettargetpos);
    LAPI_REG(gettargetent);
    LAPI_REG(iscolliding);
    LAPI_REG(setgravity);
    LAPI_REG(getmat);
    LAPI_REG(hasmap);
    LAPI_REG(get_map_preview_filename);
    LAPI_REG(get_all_map_names);
}
