namespace lapi_binds
{
    using namespace MessageSystem;

    void _lua_personal_servmsg(int cn, const char *title, const char *content)
    {
        send_PersonalServerMessage(cn, title, content);
    }

    void _lua_particle_splash_toclients(
        int cn, int type, int num, int fade, float x, float y, float z
    )
    {
        send_ParticleSplashToClients(cn, type, num, fade, x, y, z);
    }

    void _lua_particle_regularsplash_toclients(
        int cn, int type, int num, int fade, float x, float y, float z
    )
    {
        send_ParticleSplashRegularToClients(cn, type, num, fade, x, y, z);
    }

    void _lua_sound_toclients_byname(
        int cn, float x, float y, float z, const char *sn, int ocn
    )
    {
        send_SoundToClientsByName(cn, x, y, z, sn, ocn);
    }

    void _lua_statedata_changerequest(int uid, int kpid, const char *val)
    {
        send_StateDataChangeRequest(uid, kpid, val);
    }

    void _lua_statedata_changerequest_unreliable(
        int uid, int kpid, const char *val
    )
    {
        send_UnreliableStateDataChangeRequest(uid, kpid, val);
    }

    void _lua_notify_numents(int cn, int num)
    {
        send_NotifyNumEntities(cn, num);
    }

    void _lua_le_notification_complete(
        int cn, int ocn, int ouid, const char *oc, const char *sd
    )
    {
        send_LogicEntityCompleteNotification(cn, ocn, ouid, oc, sd);
    }

    void _lua_le_removal(int cn, int uid)
    {
        send_LogicEntityRemoval(cn, uid);
    }

    void _lua_statedata_update(
        int cn, int uid, int kpid, const char *val, int ocn
    )
    {
        send_StateDataUpdate(cn, uid, kpid, val, ocn);
    }

    void _lua_statedata_update_unreliable(
        int cn, int uid, int kpid, const char *val, int ocn
    )
    {
        send_UnreliableStateDataUpdate(cn, uid, kpid, val, ocn);
    }

    void _lua_do_click(int btn, int down, float x, float y, float z, int uid)
    {
        send_DoClick(btn, down, x, y, z, uid);
    }

    void _lua_extent_notification_complete(
        int cn, int ouid,
        const char *oc, const char *sd,
        float x, float y, float z,
        int attr1, int attr2, int attr3, int attr4
    )
    {
        send_ExtentCompleteNotification(
            cn, ouid, oc, sd, x, y, z, attr1, attr2, attr3, attr4
        );
    }

    void reg_messages(lua::Table& t)
    {
        LAPI_REG(personal_servmsg);
        LAPI_REG(particle_splash_toclients);
        LAPI_REG(particle_regularsplash_toclients);
        LAPI_REG(sound_toclients_byname);
        LAPI_REG(statedata_changerequest);
        LAPI_REG(statedata_changerequest_unreliable);
        LAPI_REG(notify_numents);
        LAPI_REG(le_notification_complete);
        LAPI_REG(le_removal);
        LAPI_REG(statedata_update);
        LAPI_REG(statedata_update_unreliable);
        LAPI_REG(do_click);
        LAPI_REG(extent_notification_complete);
    }
}
