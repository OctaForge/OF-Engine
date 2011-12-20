bool startmusic(const char *name, const char *cmd);
int preload_sound(const char *name, int vol);

namespace lapi_binds
{
#ifdef CLIENT
    void _lua_playsoundname(const char *n, vec loc, lua::Object vol)
    {
        if (loc.x || loc.y || loc.z)
            playsoundname(n, &loc, (vol.is_nil() ? 100 : vol.to<int>()));
        else
            playsoundname(n, NULL, (vol.is_nil() ? 100 : vol.to<int>()));
    }

    void _lua_stopsoundname(const char *n, lua::Object vol)
    {
        stopsoundbyid(getsoundid(n, (vol.is_nil() ? 100 : vol.to<int>())));
    }

    void _lua_music(const char *n)
    {
        startmusic(n, "sound.music_callback()");
    }

    int _lua_preloadsound(const char *n, lua::Object vol)
    {
        renderprogress(0, types::String().format(
            "preloadign sound '%s' ..", n
        ).get_buf());

        return preload_sound(
            n, min((vol.is_nil() ? 100 : vol.to<int>()), 100)
        );
    }

    void _lua_playsound(int n)
    {
        playsound(n);
    }
#else
    void _lua_playsound(int n)
    {
        MessageSystem::send_SoundToClients(-1, n, -1);
    }

    LAPI_EMPTY(playsoundname)
    LAPI_EMPTY(stopsoundname)
    LAPI_EMPTY(music)
    LAPI_EMPTY(preloadsound)
#endif

    void reg_sound(lua::Table& t)
    {
        LAPI_REG(playsoundname);
        LAPI_REG(stopsoundname);
        LAPI_REG(music);
        LAPI_REG(preloadsound);
        LAPI_REG(playsound);
    }
}
