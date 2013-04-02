namespace EditingSystem
{
    void newent(const char *cl, const char *sd);
}

extern int usevdelta, gridpower, nompedit, allfaces;

namespace lapi_binds
{
    int _lua_editing_getworldsize() { return getworldsize(); }
    int _lua_editing_getgridsize () { return 1 << gridpower; }

    void _lua_editing_erasegeometry() { EditingSystem::eraseGeometry(); }

    void _lua_editing_createcube(int x, int y, int z, int gridsize)
    {
        EditingSystem::createCube(x, y, z, gridsize);
    }

    void _lua_editing_deletecube(int x, int y, int z, int gridsize)
    {
        EditingSystem::deleteCube(x, y, z, gridsize);
    }

    void _lua_editing_setcubetex(
        int x, int y, int z, int gridsize, int face, int texture
    )
    {
        EditingSystem::setCubeTexture(x, y, z, gridsize, face, texture);
    }

    void _lua_editing_setcubemat(
        int x, int y, int z, int gridsize, int material
    )
    {
        EditingSystem::setCubeMaterial(x, y, z, gridsize, material);
    }

    void _lua_editing_setcubecolor(
        int x, int y, int z, int gridsize, float r, float g, float b
    )
    {
        EditingSystem::setCubeColor(x, y, z, gridsize, r, g, b);
    }

    void _lua_editing_pushcubecorner(
        int x, int y, int z, int gridsize, int face, int corner, int direction
    )
    {
        EditingSystem::pushCubeCorner(
            x, y, z, gridsize, face, corner, direction
        );
    }

    lua::Table _lua_editing_getselent()
    {
        CLogicEntity *ret = EditingSystem::getSelectedEntity();
        if (ret && !ret->isNone() && !ret->lua_ref.is_nil())
            return ret->lua_ref;
        else
            return lapi::state.wrap<lua::Table>(lua::nil);
    }

#ifdef SERVER
    lua::Table _lua_npcadd(const char *cl)
    {
        int cn = localconnect();

        types::String buf(types::String().format("Bot.%i", cn));
        logger::log(logger::DEBUG, "New NPC with client number: %i\n", cn);

        return server::createluaEntity(cn, cl ? cl : "", buf.get_buf());
    }

    void _lua_npcdel(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.npcdel", return)
        fpsent *fp = (fpsent*)entity->dynamicEntity;
        localdisconnect(true, fp->clientnum);
    }
#else
    void _lua_npcadd()
    { logger::log(logger::ERROR, "CAPI.npcadd: server-only function.\n"); }

    void _lua_npcdel()
    { logger::log(logger::ERROR, "CAPI.npcdel: server-only function.\n"); }
#endif

    void _lua_spawnent(const char *cl)
    {
        EditingSystem::newent(cl ? cl : "", "");
    }

#ifdef CLIENT
    void _lua_requestprivedit()
    {
        MessageSystem::send_RequestPrivateEditMode();
    }

    bool _lua_hasprivedit()
    {
        return ClientSystem::editingAlone;
    }
#else
    LAPI_EMPTY(requestprivedit)
    LAPI_EMPTY(hasprivedit)
#endif

    void reg_edit(lua::Table& t)
    {
        LAPI_REG(editing_getworldsize);
        LAPI_REG(editing_getgridsize);
        LAPI_REG(editing_erasegeometry);
        LAPI_REG(editing_createcube);
        LAPI_REG(editing_deletecube);
        LAPI_REG(editing_setcubetex);
        LAPI_REG(editing_setcubemat);
        LAPI_REG(editing_setcubecolor);
        LAPI_REG(editing_pushcubecorner);
        LAPI_REG(editing_getselent);
        LAPI_REG(npcadd);
        LAPI_REG(npcdel);
        LAPI_REG(spawnent);
        LAPI_REG(requestprivedit);
        LAPI_REG(hasprivedit);
    }
}
