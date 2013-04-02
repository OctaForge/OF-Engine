extern float GRAVITY;
extern physent *hitplayer;

namespace lapi_binds
{
    using namespace filesystem;

    /* Geometry utilities */

    bool _lua_raylos(float x, float y, float z, float dx, float dy, float dz)
    {
        vec target(0);
        return raycubelos(vec(x, y, z), vec(dx, dy, dz), target);
    }

    float _lua_raypos(float x, float y, float z, float rx, float ry,
        float rz, float r)
    {
        vec hitpos(0);
        return raycubepos(vec(x, y, z), vec(rx, ry, rz), hitpos, r,
            RAY_CLIPMAT | RAY_POLY);
    }

    float _lua_rayfloor(float x, float y, float z, float r)
    {
        vec floor(0);
        return rayfloor(vec(x, y, z), floor, 0, r);
    }

#ifdef CLIENT
    types::Tuple<float, float, float> _lua_gettargetpos()
    {
        TargetingControl::determineMouseTarget(true);
        vec o(TargetingControl::targetPosition);
        return types::make_tuple(o.x, o.y, o.z);
    }

    lua::Table _lua_gettargetent()
    {
        TargetingControl::determineMouseTarget(true);
        CLogicEntity *target = TargetingControl::targetLogicEntity;

        if (target && !target->isNone() && !target->lua_ref.is_nil())
            return target->lua_ref;

        return lapi::state.wrap<lua::Table>(lua::nil);
    }
#else
    LAPI_EMPTY(gettargetpos)
    LAPI_EMPTY(gettargetent)
#endif

    /* World */

    bool _lua_iscolliding(float x, float y, float z, float r, int uid)
    {
        CLogicEntity *ignore = (
            (uid != -1) ? LogicSystem::getLogicEntity(uid) : NULL
        );

        physent tester;

        tester.reset();
        tester.type      = ENT_BOUNCE;
        tester.o         = vec(x, y, z);
        tester.radius    = tester.xradius = tester.yradius = r;
        tester.eyeheight = tester.aboveeye  = r;

        if (!collide(&tester, vec(0)))
        {
            if (
                ignore && ignore->isDynamic() &&
                ignore->dynamicEntity == hitplayer
            )
            {
                vec save = ignore->dynamicEntity->o;
                avoidcollision(ignore->dynamicEntity, vec(1), &tester, 0.1f);

                bool ret = !collide(&tester, vec(0));
                ignore->dynamicEntity->o = save;

                return ret;
            }
            else return true;
        }

        return false;
    }

    void _lua_setgravity(float g)
    {
        GRAVITY = g;
    }

    int _lua_getmat(float x, float y, float z)
    {
        return lookupmaterial(vec(x, y, z));
    }

#ifdef CLIENT
    bool _lua_hasmap() { return local_server::is_running(); }
#else
    LAPI_EMPTY(hasmap)
#endif

    types::String _lua_get_map_preview_filename(const char *name)
    {
        types::String buf;

        buf.format(
            "data%cmaps%c%s%cpreview.png",
            PATHDIV, PATHDIV, name, PATHDIV
        );
        if (fileexists(buf.get_buf(), "r"))
            return buf;

        buf.format("%s%s", homedir, buf.get_buf());
        if (fileexists(buf.get_buf(), "r"))
            return buf;

        return NULL;
    }

    types::Tuple<lua::Table, lua::Table> _lua_get_all_map_names()
    {
        lua::Table gret = lapi::state.new_table();
        lua::Table uret = lapi::state.new_table();

        File_Info path = join_path("data", "maps");
        size_t       i = 1;

        for (File_Info::it it = path.begin(); it != path.end(); ++it)
        {
            if (it->type() == OFTL_FILE_DIR)
            {
                gret[i] = it->filename();
                ++i;
            }
        }

        path = join_path(homedir, "data", "maps");
        i    = 1;

        for (File_Info::it it = path.begin(); it != path.end(); ++it)
        {
            if (it->type() == OFTL_FILE_DIR)
            {
                uret[i] = it->filename();
                ++i;
            }
        }

        return types::make_tuple(gret, uret);
    }

    void reg_world(lua::Table& t)
    {
        LAPI_REG(raylos);
        LAPI_REG(raypos);
        LAPI_REG(rayfloor);
        LAPI_REG(gettargetpos);
        LAPI_REG(gettargetent);
        LAPI_REG(iscolliding);
        LAPI_REG(setgravity);
        LAPI_REG(getmat);
        LAPI_REG(hasmap);
        LAPI_REG(get_map_preview_filename);
        LAPI_REG(get_all_map_names);

    }
}
