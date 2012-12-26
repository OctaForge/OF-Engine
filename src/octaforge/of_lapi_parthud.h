#ifdef CLIENT
VARP(blood, 0, 1, 1);
#endif
namespace lapi_binds
{
#ifdef CLIENT
    void _lua_adddecal(
        int type, float px, float py, float pz, float sx, float sy, float sz,
        float radius, int r, int g, int b, int info
    )
    {
        adddecal(type, vec(px, py, pz), vec(sx, sy, sz), radius,
            bvec((uchar)r, (uchar)g, (uchar)b), info);
    }

    void _lua_particle_splash(int type, int num, int fade, float x, float y,
        float z, int color, float size, int radius, int gravity)
    {
        if (type == PART_BLOOD && !blood) return;
        particle_splash(type, num, fade, vec(x, y, z), color, size, radius,
            gravity);
    }

    void _lua_regular_particle_splash(
        int type, int num, int fade, float x, float y, float z, int color,
        float size, int radius, int gravity, int delay
    )
    {
        if (type == PART_BLOOD && !blood) return;
        regular_particle_splash(
            type, num, fade, vec(x, y, z), color, size, radius, gravity, delay
        );
    }

    void _lua_particle_fireball(
        float x, float y, float z, float max, int type, int fade, int color,
        float size
    )
    {
        particle_fireball(vec(x, y, z), max, type, fade, color, size);
    }

    void _lua_particle_flare(
        float sx, float sy, float sz, float tx, float ty, float tz, int fade,
        int type, int color, float size, int uid
    )
    {
        if (uid < 0)
            particle_flare(vec(sx, sy, sz), vec(tx, ty, tz), fade, type,
                color, size, NULL);
        else
        {
            CLogicEntity *o = LogicSystem::getLogicEntity(uid);
            assert(o->dynamicEntity);

            particle_flare(vec(sx, sy, sz), vec(tx, ty, tz), fade, type,
                color, size, (fpsent*)(o->dynamicEntity));
        }
    }

    void _lua_particle_trail(
        int type, int fade, float fx, float fy, float fz, float tx, float ty,
        float tz, int color, float size, int gravity
    )
    {
        particle_trail(type, fade, vec(fx, fy, fz), vec(tx, ty, tz), color,
            size, gravity);
    }

    void _lua_particle_flame(
        int type, float x, float y, float z, float radius, float height,
        int color, int density, float scale, float speed, float fade,
        int gravity
    )
    {
        regular_particle_flame(
            type, vec(x, y, z), radius, height, color,
            density, scale, speed, fade, gravity
        );
    }

    void _lua_adddynlight(
        float x, float y, float z, float rad, float cx, float cy, float cz,
        int fade, int peak, int flags, float irad, float ix, float iy, float iz
    )
    {
        queuedynlight(vec(x, y, z), rad, vec(cx, cy, cz), fade, peak, flags,
            irad, vec(ix, iy, iz), NULL);
    }

    void _lua_particle_meter(float x, float y, float z, float val, int type,
        int fade)
    {
        particle_meter(vec(x, y, z), val, type, fade);
    }

    void _lua_particle_text(
        float x, float y, float z, const char *t, int type, int fade,
        int color, float size, float gravity
    )
    {
        particle_textcopy(vec(x, y, z), t, type, fade, color, size, gravity);
    }

    void _lua_client_damage_effect(int roll, int n)
    {
        ((fpsent*)player)->damageroll(roll);
        damageblend(n);
    }
#else
    LAPI_EMPTY(adddecal)
    LAPI_EMPTY(particle_splash)
    LAPI_EMPTY(regular_particle_splash)
    LAPI_EMPTY(particle_fireball)
    LAPI_EMPTY(particle_flare)
    LAPI_EMPTY(particle_trail)
    LAPI_EMPTY(particle_flame)
    LAPI_EMPTY(adddynlight)
    LAPI_EMPTY(particle_meter)
    LAPI_EMPTY(particle_text)
    LAPI_EMPTY(client_damage_effect)
#endif

    void reg_parthud(lua::Table& t)
    {
        LAPI_REG(adddecal);
        LAPI_REG(particle_splash);
        LAPI_REG(regular_particle_splash);
        LAPI_REG(particle_fireball);
        LAPI_REG(particle_flare);
        LAPI_REG(particle_trail);
        LAPI_REG(particle_flame);
        LAPI_REG(adddynlight);
        LAPI_REG(particle_meter);
        LAPI_REG(particle_text);
        LAPI_REG(client_damage_effect);
    }
}
