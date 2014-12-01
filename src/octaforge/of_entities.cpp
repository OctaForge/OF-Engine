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
#include "client_system.h"
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

    CLUAICOMMAND(destroy_extent, void, (int uid), {
        extentity* extent = LogicSystem::getLogicEntity(uid)->staticEntity;
        if (extent->type == ET_SOUND) stopmapsound(extent);
        removeentity(extent);
        extent->type = ET_EMPTY;
    });

    CLUAICOMMAND(destroy_character, void, (int cn), {
        if (cn != ClientSystem::playerNumber)
            game::clientdisconnected(cn);
    });

    /* Entity attributes */

    CLUAICOMMAND(set_animation_dyn, void, (physent *ent, int anim), {
        if (!ent) return;
        gameent *d = (gameent*)ent;
        d->anim = anim;
        d->start_time = lastmillis;
    });

    CLUAICOMMAND(get_start_time_dyn, bool, (physent *ent, int *val), {
        if (!ent) return false;
        gameent *d = (gameent*)ent;
        *val = d->start_time;
        return true;
    });

    CLUAICOMMAND(set_animation_ext, void, (extentity *ext, int anim), {
        if (!ext) return;
        ext->anim = anim;
        ext->start_time = lastmillis;
    });

    CLUAICOMMAND(get_start_time_ext, bool, (extentity *ext, int *val), {
        if (!ext) return false;
        *val = ext->start_time;
        return true;
    });

    CLUAICOMMAND(set_model_name, void, (extentity *ext, const char *name), {
        if (!ext) return;
        removeentity(ext);
        if (name[0]) ext->m = loadmodel(name ? name : "");
        addentity(ext);
    });

    CLUAICOMMAND(set_attachments_dyn, void, (physent *ent, const char **attach), {
        if (!ent) return;
        CLogicEntity *entity = LogicSystem::getLogicEntity(((gameent*)ent)->uid);
        if (!entity) return;
        entity->setAttachments(attach);
    });

    CLUAICOMMAND(set_attachments_ext, void, (extentity *ext, const char **attach), {
        if (!ext) return;
        CLogicEntity *entity = LogicSystem::getLogicEntity(ext->uid);
        if (!entity) return;
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

    CLUAICOMMAND(set_can_move, void, (physent *ent, bool b), {
        if (!ent) return;
        gameent *d = (gameent*)ent;
        d->can_move = b;
    });

    /* Extents */

    CLUAICOMMAND(get_attr, bool, (extentity *ext, int a, int *val), {
        assert(ext);
        *val = ext->attr[a];
        return true;
    });
    CLUAICOMMAND(set_attr, void, (extentity *ext, int a, int v), {
        assert(ext);
        if (ClientSystem::scenarioStarted()) removeentity(ext);
        ext->attr[a] = v;
        if (ClientSystem::scenarioStarted()) addentity(ext);
    });
    CLUAICOMMAND(FAST_set_attr, void, (extentity *ext, int a, int v), {
        assert(ext);
        ext->attr[a] = v;
    });

    CLUAICOMMAND(get_extent_position, bool, (extentity *ext, double *pos), {
        assert(ext);
        pos[0] = ext->o.x;
        pos[1] = ext->o.y;
        pos[2] = ext->o.z;
        return true;
    });

    CLUAICOMMAND(set_extent_position, void, (extentity *ext, double x, double y,
    double z), {
        assert(ext);
        removeentity(ext);
        ext->o.x = x;
        ext->o.y = y;
        ext->o.z = z;
        addentity(ext);
    });

    /* Dynents */

    #define DYNENT_ACCESSORS(n, t, an) \
    CLUAICOMMAND(get_##n, bool, (physent *ent, t *val), { \
        gameent *d = (gameent*)ent; \
        assert(d); \
        *val = d->an; \
        return true; \
    }); \
    CLUAICOMMAND(set_##n, void, (physent *ent, t v), { \
        gameent *d = (gameent*)ent; \
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

    CLUAICOMMAND(get_dynent_position, bool, (physent *ent, double *pos), {
        gameent *d = (gameent*)ent;
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    CLUAICOMMAND(set_dynent_position, void, (physent *ent, double x, double y,
    double z), {
        gameent *d = (gameent*)ent;
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

    CLUAICOMMAND(get_dynent_position, bool, (physent *ent, double *pos), {
        gameent *d = (gameent*)ent;
        assert(d);
        pos[0] = d->o.x;
        pos[1] = d->o.y;
        pos[2] = d->o.z - d->eyeheight/* - d->aboveeye*/;
        return true;
    });

    #define DYNENTVEC(name, prop) \
        CLUAICOMMAND(get_dynent_##name, bool, (physent *ent, double *val), { \
            gameent *d = (gameent*)ent; \
            assert(d); \
            val[0] = d->o.x; \
            val[1] = d->o.y; \
            val[2] = d->o.z; \
            return true; \
        }); \
        CLUAICOMMAND(set_dynent_##name, void, (physent *ent, double x, \
        double y, double z), { \
            gameent *d = (gameent*)ent; \
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
} /* end namespace entities */
