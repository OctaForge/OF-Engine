void trydisconnect(bool local);

namespace game
{
    gameent *followingplayer();
}

extern float GRAVITY;
extern physent *collideplayer;

namespace lapi_binds
{
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

    /* world */
    LUACOMMAND(gettargetpos, _lua_gettargetpos);
    LUACOMMAND(gettargetent, _lua_gettargetent);
    LUACOMMAND(get_all_map_names, _lua_get_all_map_names);
}
