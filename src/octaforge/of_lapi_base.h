void keymap(int code, const char *key);
int preload_sound(const char *name, int vol);
types::Tuple<int, int, int> getfps_(bool raw);
types::String getwallclock();
extern int conskip, miniconskip;
void setconskip(int &skip, int filter, int n);
extern vector<cline> conlines;
void bindkey(const char *key, const char *action, int state);
types::String getbind(const char *key, int type);
lua::Table searchbinds(const char *action, int type);
void inputcommand(
    const char *init, const char *action = NULL, const char *prompt = NULL
);
void history_(int n);
void screenshot(char *filename);
void movie(char *name);
namespace recorder {
    bool isrecording();
}
bool glext(const char *ext);
void loadcrosshair_(const char *name, int *i);
void scorebshow(bool on);
bool addzip(
    const char *name, const char *mount = NULL, const char *strip = NULL
);
bool removezip(const char *name);

extern string homedir;
extern int fullconsole, fullconfilter, confilter, miniconfilter;

#ifdef CLIENT
VARFN(scoreboard, showscoreboard, 0, 0, 1, scorebshow(showscoreboard!=0));
#endif

namespace EditingSystem
{
    extern vec saved_pos;
}

namespace lapi_binds
{
    /* Logger module */

    void _lua_say(types::Vector<const char*> args)
    {
        switch (args.length())
        {
            case 0: game::toserver((char*)""     ); break;
            case 1: game::toserver((char*)args[0]); break;
            default:
            {
                types::String s;
                for (size_t i = 0; i < args.length(); ++i)
                    s += args[i];
                game::toserver((char*)s.get_buf());
                break;
            }
        }
    }

    /* CAPI module */

    int _lua_currtime() { return tools::currtime(); }

#ifdef CLIENT
    void _lua_keymap       (int key, const char *name) { keymap(key, name); }
    bool _lua_glext        (const char           *ext) { return glext(ext); }

    types::Tuple<int, int, int> _lua_getfps(bool  raw)
    {
        return getfps_(raw);
    }

    types::String _lua_getwallclock()
    { 
        return getwallclock();
    }

    void _lua_registersound(const char *snd, int vol )
    {
        preload_sound(snd ? snd : "", vol);
    }

    void _lua_screenshot(const char *name)
    {
        screenshot((char*)name);
    }

    void _lua_movie(const char *name)
    {
        movie((char*)name);
    }
    
    bool _lua_isrecording()
    {
        return recorder::isrecording();
    }

    void _lua_showscores()
    {
        bool on = (addreleaseaction(
            lapi::state.get<lua::Function>("CAPI", "showscores")
        ) != NULL);
        showscoreboard = on ? 1 : 0;
        scorebshow(on);
    }
#else
    LAPI_EMPTY(keymap)
    LAPI_EMPTY(glext)
    LAPI_EMPTY(getfps)
    LAPI_EMPTY(getwallclock)
    LAPI_EMPTY(registersound)
    LAPI_EMPTY(screenshot)
    LAPI_EMPTY(movie)
    LAPI_EMPTY(isrecording)
    LAPI_EMPTY(showscores)
#endif

    void _lua_writecfg(const char *name)
    {
        tools::writecfg(name);
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

    void _lua_addzip(const char *name, const char *mount, const char *strip)
    {
        addzip(name, mount, strip);
    }

    void _lua_removezip(const char *name)
    {
        removezip(name);
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

    /* console */

#ifdef CLIENT
    void _lua_toggleconsole()
    {
        SETV(fullconsole, fullconsole ^ 1);
    }

    void _lua_conskip(int sk)
    {
        setconskip(conskip, (fullconsole ? fullconfilter : confilter), sk);
    }

    void _lua_miniconskip (int sk)
    {
        setconskip(miniconskip, miniconfilter, sk);
    }

    void _lua_clearconsole()
    {
        while (conlines.length()) conlines.pop();
    }

    void _lua_bind(const char *key, int state, const char *action)
    {
        bindkey(key ? key : "", action, state);
    }

    types::String _lua_getbind(const char *key, int type)
    {
        return getbind(key ? key : "", type);
    }

    lua::Table _lua_searchbinds(const char *action, int type)
    {
        return searchbinds(action, type);
    }

    void _lua_prompt(const char *init, const char *action, const char *prompt)
    {
        inputcommand(init ? init : "", action, prompt);
    }

    void _lua_history(int n)
    {
        history_(n);
    }

    const char *_lua_onrelease(lua::Function f)
    {
        return addreleaseaction(f);
    }
#else
    LAPI_EMPTY(toggleconsole)
    LAPI_EMPTY(conskip)
    LAPI_EMPTY(miniconskip)
    LAPI_EMPTY(clearconsole)
    LAPI_EMPTY(bind)
    LAPI_EMPTY(getbind)
    LAPI_EMPTY(searchbinds)
    LAPI_EMPTY(prompt)
    LAPI_EMPTY(history)
    LAPI_EMPTY(onrelease)
#endif

    void reg_base(lua::Table& t)
    {
        LAPI_REG(say);
        LAPI_REG(currtime);
        LAPI_REG(keymap);
        LAPI_REG(registersound);
        LAPI_REG(glext);
        LAPI_REG(getfps);
        LAPI_REG(getwallclock);
        LAPI_REG(screenshot);
        LAPI_REG(movie);
        LAPI_REG(isrecording);
        LAPI_REG(showscores);
        LAPI_REG(writecfg);
        LAPI_REG(readfile);
        LAPI_REG(addzip);
        LAPI_REG(removezip);
        LAPI_REG(getserverlogfile);
        LAPI_REG(setup_library);
        LAPI_REG(save_mouse_position);
        LAPI_REG(toggleconsole);
        LAPI_REG(conskip);
        LAPI_REG(miniconskip);
        LAPI_REG(clearconsole);
        LAPI_REG(bind);
        LAPI_REG(getbind);
        LAPI_REG(searchbinds);
        LAPI_REG(prompt);
        LAPI_REG(history);
        LAPI_REG(onrelease);
    }
}
