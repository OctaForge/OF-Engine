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

#ifndef STANDALONE
    int _lua_hasprivedit(lua_State *L) {
        lua_pushboolean(L, !multiplayer());
        return 1;
    }
#else
    LAPI_EMPTY(hasprivedit)
#endif

    /* network */

#ifndef STANDALONE
    int _lua_connect(lua_State *L) {
        connectserv((char*)luaL_checkstring(L, 1), luaL_checkinteger(L, 2), "");
        return 0;
    }

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
#else
    LAPI_EMPTY(connect)
    LAPI_EMPTY(isconnected)
    LAPI_EMPTY(haslocalclients)
    LAPI_EMPTY(connectedip)
    LAPI_EMPTY(connectedport)
    LAPI_EMPTY(connectserv)
    LAPI_EMPTY(lanconnect)
    LAPI_EMPTY(disconnect)
    LAPI_EMPTY(localconnect)
    LAPI_EMPTY(localdisconnect)
    LAPI_EMPTY(getfollow)
#endif

#ifndef STANDALONE
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
#else
    LAPI_EMPTY(do_upload)
#endif

#ifndef STANDALONE
    int _lua_gettargetpos(lua_State *L) {
        vec o;
        game::determinetarget(true, &o);
        lua_pushnumber(L, o.x); lua_pushnumber(L, o.y); lua_pushnumber(L, o.z);
        return 3;
    }

    int _lua_gettargetent(lua_State *L) {
        extentity *ext;
        gameent *ent;
        game::determinetarget(true, NULL, &ext, (dynent**)&ent);
        if (ext)
            lua_pushinteger(L, ext->uid);
        else if (ent)
            lua_pushinteger(L, ent->uid);
        else
            lua_pushinteger(L, -1);
        return 1;
    }
#else
    LAPI_EMPTY(gettargetpos)
    LAPI_EMPTY(gettargetent)
#endif

    /* World */

#ifndef STANDALONE
    CLUAICOMMAND(iscolliding, bool, (float x, float y, float z, float r, physent *ignore), {
        physent tester;
        tester.reset();
        tester.type = ENT_BOUNCE;
        tester.o    = vec(x, y, z);
        tester.radius    = tester.xradius = tester.yradius = r;
        tester.eyeheight = tester.aboveeye  = r;
        if (collide(&tester, vec(0))) {
            if (ignore && ignore == collideplayer) {
                vec save = ignore->o;
                avoidcollision(ignore, vec(1), &tester, 0.1f);
                bool ret = collide(&tester, vec(0));
                ignore->o = save;
                return ret;
            }
            return true;
        }
        return false;
    });

    int _lua_setgravity(lua_State *L) {
        GRAVITY = luaL_checknumber(L, 1);
        return 0;
    }
#else
    LAPI_EMPTY(setgravity)
#endif

#ifndef STANDALONE
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
        int j = 0;
        loopv(dirs) {
            char *dir = dirs[i];
            if (dir[0] == '.') { delete[] dir; continue; }
            lua_pushstring(L, dir);
            lua_rawseti(L, -2, j);
            delete[] dir;
            ++j;
        }
        lua_pushinteger(L, dirs.length());

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
        j = 0;
        loopv(dirs) {
            char *dir = dirs[i];
            if (dir[0] == '.') { delete[] dir; continue; }
            lua_pushstring(L, dir);
            lua_rawseti(L, -2, j);
            delete[] dir;
            ++j;
        }
        lua_pushinteger(L, dirs.length());

        return 4;
    }

    LUACOMMAND(readfile, _lua_readfile);

    /* edit */
    LUACOMMAND(hasprivedit, _lua_hasprivedit);

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

    /* world */
    LUACOMMAND(gettargetpos, _lua_gettargetpos);
    LUACOMMAND(gettargetent, _lua_gettargetent);
    LUACOMMAND(setgravity, _lua_setgravity);
    LUACOMMAND(hasmap, _lua_hasmap);
    LUACOMMAND(get_map_preview_filename, _lua_get_map_preview_filename);
    LUACOMMAND(get_all_map_names, _lua_get_all_map_names);
}
