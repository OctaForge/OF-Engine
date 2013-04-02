int preload_sound(const char *name, int vol);
bool glext(const char *ext);

extern string homedir;

namespace EditingSystem
{
    extern vec saved_pos;
}

namespace lapi_binds
{
    /* CAPI module */

    int _lua_currtime() { return tools::currtime(); }

    lua::Object _lua_cubescript(const char *input) {
        tagval v;
        executeret(input, v);
        switch (v.type) {
            case VAL_INT:
                return lapi::state.wrap<lua::Object>(v.getint());
            case VAL_FLOAT:
                return lapi::state.wrap<lua::Object>(v.getfloat());
            case VAL_STR:
                return lapi::state.wrap<lua::Object>(v.getstr());
            default:
                return lapi::state.wrap<lua::Object>(lua::nil);
        }
    }

#ifdef CLIENT
    bool _lua_glext(const char *ext) { return glext(ext); }
#else
    LAPI_EMPTY(glext)
#endif

    types::String _lua_readfile(const char *path)
    {
        /* TODO: more checks */
        if (!path              ||
            strstr(path, "..") ||
            strchr(path, '~')  ||
            path[0] == '/'     ||
            path[0] == '\\'
        ) return NULL;

        char *loaded = NULL;

        types::String buf;

        if (strlen(path) >= 2 &&
            path[0] == '.'    && (
                path[1] == '/' ||
                path[1] == '\\'
            )
        )
            buf = world::get_mapfile_path(path + 2);
        else
            buf.format("%sdata%c%s", homedir, filesystem::separator(), path);

        if (!(loaded = loadfile(buf.get_buf(), NULL)))
        {
            buf.format("data%c%s", filesystem::separator(), path);
            loaded = loadfile(buf.get_buf(), NULL);
        }

        if (!loaded)
        {
            logger::log(
                logger::ERROR,
                "Could not read file %s (paths: %sdata, .%cdata)",
                path, homedir, filesystem::separator()
            );
            return NULL;
        }

        types::String ret(loaded);
        delete[] loaded;
        return ret;
    }

    const char *_lua_getserverlogfile()
    {
        return SERVER_LOGFILE;
    }

    bool _lua_setup_library(const char *name)
    {
        return lapi::load_library(name);
    }

#ifdef CLIENT
    void _lua_save_mouse_position()
    {
        EditingSystem::saved_pos = TargetingControl::worldPosition;
    }
#else
    LAPI_EMPTY(save_mouse_position)
#endif

    void reg_base(lua::Table& t)
    {
        LAPI_REG(currtime);
        LAPI_REG(cubescript);
        LAPI_REG(glext);
        LAPI_REG(readfile);
        LAPI_REG(getserverlogfile);
        LAPI_REG(setup_library);
        LAPI_REG(save_mouse_position);
    }
}
