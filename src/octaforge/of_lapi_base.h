int preload_sound(const char *name, int vol);

extern string homedir;

namespace EditingSystem
{
    extern vec saved_pos;
}

namespace lapi_binds
{
    void _lua_log(int level, const char *msg) {
        logger::log((logger::loglevel)level, "%s\n", msg);
    }

    bool _lua_should_log(int level) {
        return logger::should_log((logger::loglevel)level);
    }

    void _lua_echo(const char *msg) {
        conoutf("\f1%s", msg);
    }

    int _lua_lastmillis() { return lastmillis; }
    int _lua_totalmillis() { return totalmillis; }

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

#ifdef CLIENT
    void _lua_varray_begin(uint mode) { varray::begin(mode); }
    int _lua_varray_end() { return varray::end(); }
    void _lua_varray_disable() { varray::disable(); }

    #define EAPI_VARRAY_DEFATTRIB(name) \
        void _lua_varray_def##name(int size) { varray::def##name(size, GL_FLOAT); }

    EAPI_VARRAY_DEFATTRIB(vertex)
    EAPI_VARRAY_DEFATTRIB(color)
    EAPI_VARRAY_DEFATTRIB(texcoord0)
    EAPI_VARRAY_DEFATTRIB(texcoord1)

    #define EAPI_VARRAY_INITATTRIB(name) \
        void _lua_varray_##name##1f(float x) { varray::name##f(x); } \
        void _lua_varray_##name##2f(float x, float y) { varray::name##f(x, y); } \
        void _lua_varray_##name##3f(float x, float y, float z) { varray::name##f(x, y, z); } \
        void _lua_varray_##name##4f(float x, float y, float z, float w) { varray::name##f(x, y, z, w); }

    EAPI_VARRAY_INITATTRIB(vertex)
    EAPI_VARRAY_INITATTRIB(color)
    EAPI_VARRAY_INITATTRIB(texcoord0)
    EAPI_VARRAY_INITATTRIB(texcoord1)

    #define EAPI_VARRAY_INITATTRIBN(name, suffix, type) \
        void _lua_varray_##name##3##suffix(type x, type y, type z) { varray::name##suffix(x, y, z); } \
        void _lua_varray_##name##4##suffix(type x, type y, type z, type w) { varray::name##suffix(x, y, z, w); }

    EAPI_VARRAY_INITATTRIBN(color, ub, uchar)

    #define EAPI_VARRAY_ATTRIB(suffix, type) \
        void _lua_varray_attrib##1##suffix(type x) { varray::attrib##suffix(x); } \
        void _lua_varray_attrib##2##suffix(type x, type y) { varray::attrib##suffix(x, y); } \
        void _lua_varray_attrib##3##suffix(type x, type y, type z) { varray::attrib##suffix(x, y, z); } \
        void _lua_varray_attrib##4##suffix(type x, type y, type z, type w) { varray::attrib##suffix(x, y, z, w); }

    EAPI_VARRAY_ATTRIB(f, float)
    EAPI_VARRAY_ATTRIB(d, double)
    EAPI_VARRAY_ATTRIB(b, char)
    EAPI_VARRAY_ATTRIB(ub, uchar)
    EAPI_VARRAY_ATTRIB(s, short)
    EAPI_VARRAY_ATTRIB(us, ushort)
    EAPI_VARRAY_ATTRIB(i, int)
    EAPI_VARRAY_ATTRIB(ui, uint)
#endif

    void reg_base(lua::Table& t)
    {
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

#ifdef CLIENT
        LAPI_REG(varray_begin);
        LAPI_REG(varray_end);
        LAPI_REG(varray_disable);
        
        LAPI_REG(varray_defvertex);
        LAPI_REG(varray_defcolor);
        LAPI_REG(varray_deftexcoord0);
        LAPI_REG(varray_deftexcoord1);
        
        LAPI_REG(varray_vertex1f);
        LAPI_REG(varray_vertex2f);
        LAPI_REG(varray_vertex3f);
        LAPI_REG(varray_vertex4f);
        LAPI_REG(varray_color1f);
        LAPI_REG(varray_color2f);
        LAPI_REG(varray_color3f);
        LAPI_REG(varray_color4f);
        LAPI_REG(varray_texcoord01f);
        LAPI_REG(varray_texcoord02f);
        LAPI_REG(varray_texcoord03f);
        LAPI_REG(varray_texcoord04f);
        LAPI_REG(varray_texcoord11f);
        LAPI_REG(varray_texcoord12f);
        LAPI_REG(varray_texcoord13f);
        LAPI_REG(varray_texcoord14f);
        
        LAPI_REG(varray_color3ub);
        LAPI_REG(varray_color4ub);
        
        LAPI_REG(varray_attrib1f);
        LAPI_REG(varray_attrib2f);
        LAPI_REG(varray_attrib3f);
        LAPI_REG(varray_attrib4f);
        LAPI_REG(varray_attrib1d);
        LAPI_REG(varray_attrib2d);
        LAPI_REG(varray_attrib3d);
        LAPI_REG(varray_attrib4d);
        LAPI_REG(varray_attrib1b);
        LAPI_REG(varray_attrib2b);
        LAPI_REG(varray_attrib3b);
        LAPI_REG(varray_attrib4b);
        LAPI_REG(varray_attrib1ub);
        LAPI_REG(varray_attrib2ub);
        LAPI_REG(varray_attrib3ub);
        LAPI_REG(varray_attrib4ub);
        LAPI_REG(varray_attrib1s);
        LAPI_REG(varray_attrib2s);
        LAPI_REG(varray_attrib3s);
        LAPI_REG(varray_attrib4s);
        LAPI_REG(varray_attrib1us);
        LAPI_REG(varray_attrib2us);
        LAPI_REG(varray_attrib3us);
        LAPI_REG(varray_attrib4us);
        LAPI_REG(varray_attrib1i);
        LAPI_REG(varray_attrib2i);
        LAPI_REG(varray_attrib3i);
        LAPI_REG(varray_attrib4i);
        LAPI_REG(varray_attrib1ui);
        LAPI_REG(varray_attrib2ui);
        LAPI_REG(varray_attrib3ui);
        LAPI_REG(varray_attrib4ui);
#endif
    }
}
