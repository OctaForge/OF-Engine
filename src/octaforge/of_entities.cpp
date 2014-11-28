/*
 * of_entities.cpp, version 1
 * Entity management for OctaForge engine.
 *
 * author: q66 <quaker66@gmail.com>
 * license: see COPYING.txt
 */

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "targeting.h"
#include "of_world.h"

void removeentity(extentity* entity);
void addentity(extentity* entity);

extern int efocus;

/* OF */
static const int attrnums[] = {
    0, /* ET_EMPTY */
    0, /* ET_MARKER */
    2, /* ET_ORIENTED_MARKER */
    5, /* ET_LIGHT */
    1, /* ET_SPOTLIGHT */
    1, /* ET_ENVMAP */
    2, /* ET_SOUND */
    0, /* ET_PARTICLES */
    4, /* ET_MAPMODEL */
    7, /* ET_OBSTACLE */
    5  /* ET_DECAL */
};

int getattrnum(int type) {
    return attrnums[(type >= 0 &&
        (size_t)type < (sizeof(attrnums) / sizeof(int))) ? type : 0];
}

namespace entities
{
    struct Entity_Storage {
        vector<extentity*> data;
        Entity_Storage(): data() {}
        ~Entity_Storage() {
            for (int i = 0; i < data.length(); ++i) {
                delete data[i];
            }
        }
    };
    static Entity_Storage storage;

    vector<extentity*> &getents() {
        return storage.data;
    }

    void clearents() {
        while (storage.data.length())
            delete storage.data.pop();
    }

    /* OF Lua entity API */

    CLUAICOMMAND(unregister_entity, void, (int uid), {
        LogicSystem::unregisterLogicEntityByUniqueId(uid);
    });

    CLUAICOMMAND(setup_extent, void, (int uid, int type), {
        LogicSystem::setupExtent(uid, type);
    });

    CLUAICOMMAND(setup_character, void, (int uid, int cn), {
        LogicSystem::setupCharacter(uid, cn);
    });

    CLUAICOMMAND(setup_nonsauer, void, (int uid), {
        LogicSystem::setupNonSauer(uid);
    });

    CLUAICOMMAND(destroy_extent, void, (int uid), {
        LogicSystem::dismantleExtent(uid);
    });

    CLUAICOMMAND(destroy_character, void, (int cn), {
        LogicSystem::dismantleCharacter(cn);
    });

    /* Entity attributes */

#ifndef SERVER
    CLUAICOMMAND(set_animation, void, (int uid, int anim), {
        LUA_GET_ENT(entity, uid, "_C.setanim", return)
        entity->setAnimation(anim);
    });

    CLUAICOMMAND(get_start_time, bool, (int uid, int *val), {
        LUA_GET_ENT(entity, uid, "_C.getstarttime", return false)
        *val = entity->getStartTime();
        return true;
    });

    CLUAICOMMAND(set_model_name, void, (int uid, const char *name), {
        if (!name) name = "";
        LUA_GET_ENT(entity, uid, "_C.setmodelname", return)
        logger::log(logger::DEBUG, "_C.setmodelname(%d, \"%s\")",
            entity->uniqueId, name);
        extentity *ext = entity->staticEntity;
        if (!ext) return;
        removeentity(ext);
        if (name[0]) ext->m = loadmodel(name);
        addentity(ext);
    });

    CLUAICOMMAND(set_attachments, void, (int uid, const char **attach), {
        LUA_GET_ENT(entity, uid, "_C.setattachments", return)
        entity->setAttachments(attach);
    });

    LUAICOMMAND(get_attachment_position, {
        int uid = luaL_checkinteger(L, 1);
        const char *attachment = "";
        if (!lua_isnoneornil(L, 2)) attachment = luaL_checkstring(L, 2);
        LUA_GET_ENT(entity, uid, "_C.getattachmentpos", return 0)
        const vec& o = entity->getAttachmentPosition(attachment);
        lua_pushnumber(L, o.x); lua_pushnumber(L, o.y); lua_pushnumber(L, o.z);
        return 3;
    });

    CLUAICOMMAND(set_can_move, void, (int uid, bool b), {
        LUA_GET_ENT(entity, uid, "_C.setcanmove", return)
        entity->canMove = b;
    });
#endif

    /* Extents */

    CLUAICOMMAND(get_attr, bool, (int uid, int a, int *val), {
        LUA_GET_ENT(entity, uid, "_C.get_attr", return false)
        extentity *ext = entity->staticEntity;
        assert(ext);
        *val = ext->attr[a];
        return true;
    });
    CLUAICOMMAND(set_attr, void, (int uid, int a, int v), {
        LUA_GET_ENT(entity, uid, "_C.set_attr", return)
        extentity *ext = entity->staticEntity;
        assert(ext);
#ifndef SERVER
        if (!world::loading) removeentity(ext);
#endif
        ext->attr[a] = v;
#ifndef SERVER
        if (!world::loading) addentity(ext);
#endif
    });
    CLUAICOMMAND(FAST_set_attr, void, (int uid, int a, int v), {
        LUA_GET_ENT(entity, uid, "_C.FAST_set_attr", return)
        extentity *ext = entity->staticEntity;
        assert(ext);
        ext->attr[a] = v;
    });

    CLUAICOMMAND(get_extent_position, bool, (int uid, double *pos), {
        LUA_GET_ENT(entity, uid, "_C.getextent0", return false)
        extentity *ext = entity->staticEntity;
        assert(ext);
        logger::log(logger::INFO,
            "_C.getextent0(%d): x: %f, y: %f, z: %f",
            entity->uniqueId, ext->o.x, ext->o.y, ext->o.z);
        pos[0] = ext->o.x;
        pos[1] = ext->o.y;
        pos[2] = ext->o.z;
        return true;
    });

    CLUAICOMMAND(set_extent_position, void, (int uid, double x, double y,
    double z), {
        LUA_GET_ENT(entity, uid, "_C.setextent0", return)
        extentity *ext = entity->staticEntity;
        assert(ext);

#ifndef SERVER
        removeentity(ext);
#endif
        ext->o.x = x;
        ext->o.y = y;
        ext->o.z = z;
#ifndef SERVER
        addentity(ext);
#endif
    });

    /* Dynents */

#ifndef SERVER
    #define DYNENT_ACCESSORS(n, t, an) \
    CLUAICOMMAND(get_##n, bool, (int uid, t *val), { \
        LUA_GET_ENT(entity, uid, "_C.get"#n, return false) \
        gameent *d = (gameent*)entity->dynamicEntity; \
        assert(d); \
        *val = d->an; \
        return true; \
    }); \
    CLUAICOMMAND(set_##n, void, (int uid, t v), { \
        LUA_GET_ENT(entity, uid, "_C.set"#n, return) \
        gameent *d = (gameent*)entity->dynamicEntity; \
        assert(d); \
        d->an = v; \
    });

    DYNENT_ACCESSORS(maxspeed, float, maxspeed)
    DYNENT_ACCESSORS(crouchtime, int, crouchtime)
    DYNENT_ACCESSORS(radius, float, radius)
    DYNENT_ACCESSORS(eyeheight, float, eyeheight)
    DYNENT_ACCESSORS(maxheight, float, maxheight)
    DYNENT_ACCESSORS(crouchheight, float, crouchheight)
    DYNENT_ACCESSORS(crouchspeed, float, crouchspeed)
    DYNENT_ACCESSORS(jumpvel, float, jumpvel)
    DYNENT_ACCESSORS(gravity, float, gravity)
    DYNENT_ACCESSORS(aboveeye, float, aboveeye)
    DYNENT_ACCESSORS(yaw, float, yaw)
    DYNENT_ACCESSORS(pitch, float, pitch)
    DYNENT_ACCESSORS(roll, float, roll)
    DYNENT_ACCESSORS(move, int, move)
    DYNENT_ACCESSORS(strafe, int, strafe)
    DYNENT_ACCESSORS(yawing, int, turn_move)
    DYNENT_ACCESSORS(crouching, int, crouching)
    DYNENT_ACCESSORS(pitching, int, look_updown_move)
    DYNENT_ACCESSORS(jumping, bool, jumping)
    DYNENT_ACCESSORS(blocked, bool, blocked)
    DYNENT_ACCESSORS(clientstate, int, state)
    DYNENT_ACCESSORS(physstate, int, physstate)
    DYNENT_ACCESSORS(inwater, int, inwater)
    DYNENT_ACCESSORS(timeinair, int, timeinair)
    #undef DYNENT_ACCESSORS

    CLUAICOMMAND(get_dynent_position, bool, (int uid, double *pos), {
        LUA_GET_ENT(entity, uid, "_C.getdynent0", return false)
        gameent *d = (gameent*)entity->dynamicEntity;
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    CLUAICOMMAND(set_dynent_position, void, (int uid, double x, double y,
    double z), {
        LUA_GET_ENT(entity, uid, "_C.setdynent0", return)
        gameent *d = (gameent*)entity->dynamicEntity;
        assert(d);

        d->o.x = x;
        d->o.y = y;
        d->o.z = z + d->eyeheight;/* + d->aboveeye; */

        /* also set newpos, otherwise this change may get overwritten */
        d->newpos = d->o;

        /* no need to interpolate to the last position - just jump */
        d->resetinterp();

        logger::log(
            logger::INFO, "(%i).setdynent0(%f, %f, %f)",
            d->uid, d->o.x, d->o.y, d->o.z
        );
    });

    CLUAICOMMAND(get_dynent_position, bool, (int uid, double *pos), {
        LUA_GET_ENT(entity, uid, "_C.getdynent0", return false)
        gameent *d = (gameent*)entity->dynamicEntity;
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    #define DYNENTVEC(name, prop) \
        CLUAICOMMAND(get_dynent_##name, bool, (int uid, double *val), { \
            LUA_GET_ENT(entity, uid, "_C.getdynent"#name, return false) \
            gameent *d = (gameent*)entity->dynamicEntity; \
            assert(d); \
            val[0] = d->o.x; \
            val[1] = d->o.y; \
            val[2] = d->o.z; \
            return true; \
        }); \
        CLUAICOMMAND(set_dynent_##name, void, (int uid, double x, \
        double y, double z), { \
            LUA_GET_ENT(entity, uid, "_C.setdynent"#name, return) \
            gameent *d = (gameent*)entity->dynamicEntity; \
            assert(d); \
            d->prop.x = x; \
            d->prop.y = y; \
            d->prop.z = z; \
        });

    DYNENTVEC(velocity, vel)
    DYNENTVEC(falling, falling)
    #undef DYNENTVEC

    CLUAICOMMAND(get_target_entity_uid, bool, (int *uid), {
        if (TargetingControl::targetLogicEntity) {
            *uid = TargetingControl::targetLogicEntity->uniqueId;
            return true;
        }
        return false;
    });

    CLUAICOMMAND(get_plag, bool, (int uid, int *val), {
        LUA_GET_ENT(entity, uid, "_C.getplag", return false)
        gameent *p = (gameent*)entity->dynamicEntity;
        assert(p);
        *val = p->plag;
        return true;
    });

    CLUAICOMMAND(get_ping, bool, (int uid, int *val), {
        LUA_GET_ENT(entity, uid, "_C.getping", return false)
        gameent *p = (gameent*)entity->dynamicEntity;
        assert(p);
        *val = p->ping;
        return true;
    });

    CLUAICOMMAND(get_selected_entity, int, (), {
        const vector<extentity *> &ents = entities::getents();
        if (!ents.inrange(efocus)) return -1;
        return ents[efocus]->uid;
    });

    CLUAICOMMAND(get_attached_entity, int, (int uid), {
        LUA_GET_ENT(entity, uid, "_C.get_attached_entity", return 0)
        extentity *e = entity->staticEntity;
        if (!e || !e->attached) return -1;
        return e->attached->uid;
    });
#endif
} /* end namespace entities */
