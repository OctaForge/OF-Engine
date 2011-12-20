namespace lapi_binds
{
#ifdef CLIENT
    void _lua_forcecam(vec pos, float yaw, float pitch, float roll, float fov)
    {
        CameraControl::forceCamera(pos, yaw, pitch, roll, fov);
    }

    void _lua_forcepos(vec pos)
    {
        CameraControl::forcePosition(pos);
    }

    void _lua_forceyaw  (float yaw  ) { CameraControl::forceYaw  (yaw  ); }
    void _lua_forcepitch(float pitch) { CameraControl::forcePitch(pitch); }
    void _lua_forceroll (float roll ) { CameraControl::forceRoll (roll ); }
    void _lua_forcefov  (float fov  ) { CameraControl::forceFov  (fov  ); }

    void _lua_resetcam()
    {
        CameraControl::positionCamera(CameraControl::getCamera());
    }

    lua::Table _lua_getcam()
    {
        lua::Table t = lapi::state.new_table(0, 4);
        physent *camera = CameraControl::getCamera();
        t["position"] = camera->o;
        t["yaw"     ] = camera->yaw;
        t["pitch"   ] = camera->pitch;
        t["roll"    ] = camera->roll;
        return t;
    }

    void _lua_caminc() { CameraControl::incrementCameraDist( 1); }
    void _lua_camdec() { CameraControl::incrementCameraDist(-1); }

    void _lua_mouselook    () { GuiControl::toggleMouselook       (); }
    void _lua_characterview() { GuiControl::toggleCharacterViewing(); }
#else
    LAPI_EMPTY(forcecam)
    LAPI_EMPTY(forcepos)
    LAPI_EMPTY(forceyaw)
    LAPI_EMPTY(forcepitch)
    LAPI_EMPTY(forceroll)
    LAPI_EMPTY(forcefov)
    LAPI_EMPTY(resetcam)
    LAPI_EMPTY(getcam)
    LAPI_EMPTY(caminc)
    LAPI_EMPTY(camdec)
    LAPI_EMPTY(mouselook)
    LAPI_EMPTY(characterview)
#endif

    void reg_camera(lua::Table& t)
    {
        LAPI_REG(forcecam);
        LAPI_REG(forcepos);
        LAPI_REG(forceyaw);
        LAPI_REG(forcepitch);
        LAPI_REG(forceroll);
        LAPI_REG(forcefov);
        LAPI_REG(resetcam);
        LAPI_REG(getcam);
        LAPI_REG(caminc);
        LAPI_REG(camdec);
        LAPI_REG(mouselook);
        LAPI_REG(characterview);
    }
}
