void trydisconnect();

namespace game
{
    void toserver(char *text);
    fpsent *followingplayer();
}

namespace lapi_binds
{
#ifdef CLIENT
    void _lua_connect(const char *addr, int port)
    {
        ClientSystem::connect(addr, port);
    }
#else
    LAPI_EMPTY(connect)
#endif

    bool _lua_isconnected(bool attempt)
    {
        return isconnected(attempt);
    }

    bool _lua_haslocalclients()
    {
        return haslocalclients();
    }

    types::String _lua_connectedip()
    {
        const ENetAddress *addr = connectedpeer();

        char hostname[128];
        return (
            (addr && enet_address_get_host_ip(
                addr, hostname, sizeof(hostname)
            ) >= 0) ? hostname : ""
        );
    }

    int _lua_connectedport()
    {
        const ENetAddress *addr = connectedpeer();
        return (addr ? addr->port : -1);
    }

    void _lua_connectserv(const char *name, int port, const char *passwd)
    {
        connectserv(name, port, passwd);
    }

    void _lua_lanconnect(int port, const char *passwd)
    {
        connectserv(NULL, port, passwd);
    }

    void _lua_disconnect() { trydisconnect(); }

    void _lua_localconnect()
    {
        if (!isconnected() && !haslocalclients()) localconnect();
    }

    void _lua_localdisconnect()
    {
        if (haslocalclients()) localdisconnect();
    }

    int _lua_getfollow()
    {
        fpsent *f = game::followingplayer();
        return (f ? f->clientnum : -1);
    }

#ifdef CLIENT
    void _lua_do_upload()
    {
        renderprogress(0.1f, "compiling scripts ..");

        types::String fname(world::get_mapscript_filename());

        auto err = lapi::state.load_file(fname);
        if (types::get<0>(err))
        {
            lapi::state.get<lua::Function>("LAPI", "GUI", "show_message")(
                "Compilation failed", types::get<1>(err)
            );
            return;
        }

        renderprogress(0.3, "generating map ..");
        save_world(game::getclientmap().get_buf());

        renderprogress(0.4, "exporting entities ..");
        world::export_ents("entities.json");
    }

    void _lua_restart_map()
    {
        MessageSystem::send_RestartMap();
    }
#else
    LAPI_EMPTY(do_upload)
    LAPI_EMPTY(restart_map)
#endif

    void reg_network(lua::Table& t)
    {
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
    }
}
