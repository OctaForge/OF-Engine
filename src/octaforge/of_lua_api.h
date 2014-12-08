void trydisconnect(bool local);

namespace game
{
    gameent *followingplayer();
}

extern float GRAVITY;
extern physent *collideplayer;

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

    /* world */
    LUACOMMAND(gettargetpos, _lua_gettargetpos);
    LUACOMMAND(gettargetent, _lua_gettargetent);
    LUACOMMAND(get_map_preview_filename, _lua_get_map_preview_filename);
    LUACOMMAND(get_all_map_names, _lua_get_all_map_names);
}
