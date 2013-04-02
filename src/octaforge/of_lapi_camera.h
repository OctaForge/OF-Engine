namespace lapi_binds
{
#ifdef CLIENT
    lua::Table _lua_getcam()
    {
        lua::Table t = lapi::state.new_table(0, 4);
        const vec& o = camera1->o;
        t["position"] = lapi::state.get<lua::Function>("external", "new_vec3")
            .call<lua::Table>(o.x, o.y, o.z);
        t["yaw"     ] = camera1->yaw;
        t["pitch"   ] = camera1->pitch;
        t["roll"    ] = camera1->roll;
        return t;
    }
#else
    LAPI_EMPTY(getcam)
#endif

    void reg_camera(lua::Table& t)
    {
        LAPI_REG(getcam);
    }
}
