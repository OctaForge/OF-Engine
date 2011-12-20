void removeentity(extentity* entity);
void addentity(extentity* entity);

namespace lapi_binds
{
    /* Entity management */

    void _lua_unregister_entity(int uid)
    {
        LogicSystem::unregisterLogicEntityByUniqueId(uid);
    }

    void _lua_setupextent(
        lua::Table ent, int type,
        float x, float y, float z,
        int attr1, int attr2, int attr3, int attr4
    )
    {
        LogicSystem::setupExtent(
            ent, type, x, y, z, attr1, attr2, attr3, attr4
        );
    }

    void _lua_setupcharacter(lua::Table ent)
    {
        LogicSystem::setupCharacter(ent);
    }

    void _lua_setupnonsauer(lua::Table ent)
    {
        LogicSystem::setupNonSauer(ent);
    }

    void _lua_dismantleextent(lua::Table ent)
    {
        LogicSystem::dismantleExtent(ent);
    }

    void _lua_dismantlecharacter(lua::Table ent)
    {
        LogicSystem::dismantleCharacter(ent);
    }

    /* Entity attributes */

    void _lua_setanim(lua::Table self, int anim)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setanim", return)
        entity->setAnimation(anim);
    }

    lua::Object _lua_getstarttime(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.getstarttime", return lua::Object())
        return lapi::state.wrap<lua::Object>(entity->getStartTime());
    }

    void _lua_setmodelname(lua::Table self, const char *name)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setmodelname", return)
        logger::log(
            logger::DEBUG, "CAPI.setmodelname(\"%s\", \"%s\")\n",
            entity->getClass(), name
        );
        entity->setModel(name);
    }

    void _lua_setsoundname(lua::Table self, const char *name)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setsoundname", return)
        logger::log(
            logger::DEBUG, "CAPI.setsoundname(\"%s\", \"%s\")\n",
            entity->getClass(), name
        );
        entity->setSound(name);
    }

    void _lua_setsoundvol(lua::Table self, int vol)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setsoundvol", return)
        logger::log(logger::DEBUG, "CAPI.setsoundvol(%i)\n", vol);

        extentity *ext = entity->staticEntity;
        assert(ext);

        if (!world::loading) removeentity(ext);
        ext->attr4 = vol;
        if (!world::loading) addentity(ext);

        entity->setSound(entity->sndname);
    }

    void _lua_setattachments(lua::Table self, lua::Table attachments)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setattachments", return)
        entity->setAttachments(
            lapi::state.get<lua::Function>(
                "table", "concat"
            ).call<const char*>(attachments, "|")
        );
    }

    lua::Object _lua_getattachmentpos(lua::Table self, const char *attachment)
    {
        LAPI_GET_ENT(
            entity, self, "CAPI.getattachmentpos",
            return lua::Object()
        )
        return lapi::state.wrap<lua::Object>(
            entity->getAttachmentPosition(attachment)
        );
    }

    void _lua_setcanmove(lua::Table self, bool v)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setcanmove", return)
        entity->setCanMove(v);
    }

    /* Extents */

    #define EXTENT_ACCESSORS(n) \
    lua::Object _lua_get##n(lua::Table self) \
    { \
        LAPI_GET_ENT(entity, self, "CAPI.get"#n, return lua::Object()) \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        return lapi::state.wrap<lua::Object>(ext->n); \
    } \
    void _lua_set##n(lua::Table self, int v) \
    { \
        LAPI_GET_ENT(entity, self, "CAPI.set"#n, return) \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        if (!world::loading) removeentity(ext); \
        ext->n = v; \
        if (!world::loading) addentity(ext); \
    } \
    void _lua_FAST_set##n(lua::Table self, int v) \
    { \
        LAPI_GET_ENT(entity, self, "CAPI.FAST_set"#n, return) \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        ext->n = v; \
    }

    EXTENT_ACCESSORS(attr1)
    EXTENT_ACCESSORS(attr2)
    EXTENT_ACCESSORS(attr3)
    EXTENT_ACCESSORS(attr4)
    #undef EXTENT_ACCESSORS

    #define EXTENT_LE_ACCESSORS(n, an) \
    lua::Object _lua_get##n(lua::Table self) \
    { \
        LAPI_GET_ENT(entity, self, "CAPI.get"#n, return lua::Object()) \
        return lapi::state.wrap<lua::Object>(entity->an); \
    } \
    void _lua_set##n(lua::Table self, float v) \
    { \
        LAPI_GET_ENT(entity, self, "CAPI.set"#n, return) \
        logger::log(logger::DEBUG, "ACCESSOR: Setting %s to %f\n", #an, v); \
        assert(entity->staticEntity); \
        if (!world::loading) removeentity(entity->staticEntity); \
        entity->an = v; \
        if (!world::loading) addentity(entity->staticEntity); \
    }

    EXTENT_LE_ACCESSORS(collisionradw, collisionRadiusWidth)
    EXTENT_LE_ACCESSORS(collisionradh, collisionRadiusHeight)
    #undef EXTENT_LE_ACCESSORS

    lua::Table _lua_getextent0(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.getextent0", return lua::Table())
        extentity *ext = entity->staticEntity;
        assert(ext);
        logger::log(
            logger::INFO, "CAPI.getextent0(\"%s\"): x: %f, y: %f, z: %f\n",
            entity->getClass(), ext->o.x, ext->o.y, ext->o.z
        );
        lua::Table ret = lapi::state.new_table(3, 0);
        ret[1] = ext->o.x; ret[2] = ext->o.y; ret[3] = ext->o.z;
        return ret;
    }

    void _lua_setextent0(lua::Table self, vec o)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setextent0", return)
        extentity *ext = entity->staticEntity;
        assert(ext);

        removeentity(ext);
        ext->o.x = o.x;
        ext->o.y = o.y;
        ext->o.z = o.z;
        addentity(ext);
    }

    /* Dynents */

    #define DYNENT_ACCESSORS(n, t, an) \
    lua::Object _lua_get##n(lua::Table self) \
    { \
        LAPI_GET_ENT(entity, self, "CAPI.get"#n, return lua::Object()) \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        return lapi::state.wrap<lua::Object>((t)d->an); \
    } \
    void _lua_set##n(lua::Table self, t v) \
    { \
        LAPI_GET_ENT(entity, self, "CAPI.set"#n, return) \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        d->an = v; \
    }

    DYNENT_ACCESSORS(maxspeed, float, maxspeed)
    DYNENT_ACCESSORS(radius, float, radius)
    DYNENT_ACCESSORS(eyeheight, float, eyeheight)
    DYNENT_ACCESSORS(aboveeye, float, aboveeye)
    DYNENT_ACCESSORS(yaw, float, yaw)
    DYNENT_ACCESSORS(pitch, float, pitch)
    DYNENT_ACCESSORS(move, int, move)
    DYNENT_ACCESSORS(strafe, int, strafe)
    DYNENT_ACCESSORS(yawing, int, turn_move)
    DYNENT_ACCESSORS(pitching, int, look_updown_move)
    DYNENT_ACCESSORS(jumping, bool, jumping)
    DYNENT_ACCESSORS(blocked, bool, blocked)
    /* XXX should be unsigned */
    DYNENT_ACCESSORS(mapdefinedposdata, int, mapDefinedPositionData)
    DYNENT_ACCESSORS(clientstate, int, state)
    DYNENT_ACCESSORS(physstate, int, physstate)
    DYNENT_ACCESSORS(inwater, int, inwater)
    DYNENT_ACCESSORS(timeinair, int, timeinair)
    #undef DYNENT_ACCESSORS

    lua::Table _lua_getdynent0(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.getdynent0", return lua::Table())
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);
        lua::Table ret = lapi::state.new_table(3, 0);
        ret[1] = d->o.x; ret[2] = d->o.y; ret[3] = (
            d->o.z - d->eyeheight/* - d->aboveeye*/
        );
        return ret;
    }

    void _lua_setdynent0(lua::Table self, vec o)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setdynent0", return)
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);

        d->o.x = o.x;
        d->o.y = o.y;
        d->o.z = o.z + d->eyeheight;/* + d->aboveeye; */

        /* also set newpos, otherwise this change may get overwritten */
        d->newpos = d->o;

        /* no need to interpolate to the last position - just jump */
        d->resetinterp();

        logger::log(
            logger::INFO, "(%i).setdynent0(%f, %f, %f)",
            d->uniqueId, d->o.x, d->o.y, d->o.z
        );
    }

    lua::Table _lua_getdynentvel(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.getdynentvel", return lua::Table())
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);
        lua::Table ret = lapi::state.new_table(3, 0);
        ret[1] = d->vel.x; ret[2] = d->vel.y; ret[3] = d->vel.z;
        return ret;
    }

    void _lua_setdynentvel(lua::Table self, vec vel)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setdynent0", return)
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);

        d->vel.x = vel.x;
        d->vel.y = vel.y;
        d->vel.z = vel.z;
    }

    lua::Table _lua_getdynentfalling(lua::Table self)
    {
        LAPI_GET_ENT(
            entity, self, "CAPI.getdynentfalling", return lua::Table()
        )
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);
        lua::Table ret = lapi::state.new_table(3, 0);
        ret[1] = d->falling.x; ret[2] = d->falling.y; ret[3] = d->falling.z;
        return ret;
    }

    void _lua_setdynentfalling(lua::Table self, vec fall)
    {
        LAPI_GET_ENT(entity, self, "CAPI.setdynentfalling", return)
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);

        d->falling.x = fall.x;
        d->falling.y = fall.y;
        d->falling.z = fall.z;
    }

#ifdef CLIENT
    lua::Object _lua_get_target_entity_uid()
    {
        if (
            TargetingControl::targetLogicEntity &&
           !TargetingControl::targetLogicEntity->isNone()
        ) return lapi::state.wrap<lua::Object>(
            TargetingControl::targetLogicEntity->getUniqueId()
        );

        return lua::Object();
    }
#endif

    lua::Object _lua_getplag(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.getplag", return lua::Object())
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        return lapi::state.wrap<lua::Object>(p->plag);
    }

    lua::Object _lua_getping(lua::Table self)
    {
        LAPI_GET_ENT(entity, self, "CAPI.getping", return lua::Object())
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        return lapi::state.wrap<lua::Object>(p->ping);
    }

    void reg_entity(lua::Table& t)
    {
        LAPI_REG(unregister_entity);
        LAPI_REG(setupextent);
        LAPI_REG(setupcharacter);
        LAPI_REG(setupnonsauer);
        LAPI_REG(dismantleextent);
        LAPI_REG(dismantlecharacter);
        LAPI_REG(setanim);
        LAPI_REG(getstarttime);
        LAPI_REG(setmodelname);
        LAPI_REG(setsoundname);
        LAPI_REG(setsoundvol);
        LAPI_REG(setattachments);
        LAPI_REG(getattachmentpos);
        LAPI_REG(setcanmove);
        LAPI_REG(getattr1);
        LAPI_REG(setattr1);
        LAPI_REG(FAST_setattr1);
        LAPI_REG(getattr2);
        LAPI_REG(setattr2);
        LAPI_REG(FAST_setattr2);
        LAPI_REG(getattr3);
        LAPI_REG(setattr3);
        LAPI_REG(FAST_setattr3);
        LAPI_REG(getattr4);
        LAPI_REG(setattr4);
        LAPI_REG(FAST_setattr4);
        LAPI_REG(getcollisionradw);
        LAPI_REG(setcollisionradw);
        LAPI_REG(getcollisionradh);
        LAPI_REG(setcollisionradh);
        LAPI_REG(getextent0);
        LAPI_REG(setextent0);
        LAPI_REG(getmaxspeed);
        LAPI_REG(setmaxspeed);
        LAPI_REG(getradius);
        LAPI_REG(setradius);
        LAPI_REG(geteyeheight);
        LAPI_REG(seteyeheight);
        LAPI_REG(getaboveeye);
        LAPI_REG(setaboveeye);
        LAPI_REG(getyaw);
        LAPI_REG(setyaw);
        LAPI_REG(getpitch);
        LAPI_REG(setpitch);
        LAPI_REG(getmove);
        LAPI_REG(setmove);
        LAPI_REG(getstrafe);
        LAPI_REG(setstrafe);
        LAPI_REG(getyawing);
        LAPI_REG(setyawing);
        LAPI_REG(getpitching);
        LAPI_REG(setpitching);
        LAPI_REG(getjumping);
        LAPI_REG(setjumping);
        LAPI_REG(getblocked);
        LAPI_REG(setblocked);
        LAPI_REG(getmapdefinedposdata);
        LAPI_REG(setmapdefinedposdata);
        LAPI_REG(getclientstate);
        LAPI_REG(setclientstate);
        LAPI_REG(getphysstate);
        LAPI_REG(setphysstate);
        LAPI_REG(getinwater);
        LAPI_REG(setinwater);
        LAPI_REG(gettimeinair);
        LAPI_REG(settimeinair);
        LAPI_REG(getdynent0);
        LAPI_REG(setdynent0);
        LAPI_REG(getdynentvel);
        LAPI_REG(setdynentvel);
        LAPI_REG(getdynentfalling);
        LAPI_REG(setdynentfalling);
#ifdef CLIENT
        LAPI_REG(get_target_entity_uid);
#endif
        LAPI_REG(getplag);
        LAPI_REG(getping);
    }
}
