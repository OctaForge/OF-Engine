namespace lapi_binds
{
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

    LUACOMMAND(get_all_map_names, _lua_get_all_map_names);
}
