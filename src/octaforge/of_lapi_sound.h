bool startmusic(const char *name, const char *cmd);
int preload_sound(const char *name, int vol);

namespace lapi_binds
{
#ifdef CLIENT
    void _lua_playsoundname(const char *n, vec loc, int vol)
    {
        if (loc.x || loc.y || loc.z)
            playsoundname(n, &loc, vol);
        else
            playsoundname(n, NULL, vol);
    }

    void _lua_stopsoundname(const char *n, int vol)
    {
        stopsoundbyid(getsoundid(n, vol));
    }

    void _lua_music(const char *n)
    {
        startmusic(n, "sound.music_callback()");
    }

    int _lua_preloadsound(const char *n, int vol)
    {
        renderprogress(0, types::String().format(
            "preloadign sound '%s' ..", n
        ).get_buf());

        return preload_sound(n, min((vol ? vol : 100), 100));
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
#endif

    void reg_sound(lua::Table& t)
    {
#ifdef CLIENT
        LAPI_REG(playsoundname);
        LAPI_REG(stopsoundname);
        LAPI_REG(music);
        LAPI_REG(preloadsound);
#endif
        LAPI_REG(playsound);
    }
}
