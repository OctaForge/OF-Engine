/*
 * of_entities.cpp, version 1
 * Entity management for OctaForge engine.
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "targeting.h"
#include "editing_system.h"
#include "of_world.h"

void removeentity(extentity* entity);
void addentity(extentity* entity);

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

    LUAICOMMAND(setup_extent, {
        lua_pushvalue(L, 1);
        LogicSystem::setupExtent(luaL_ref(L, LUA_REGISTRYINDEX),
            luaL_checkinteger(L, 2));
        return 0;
    });

    LUAICOMMAND(setup_character, {
        lua_pushvalue(L, 1);
        LogicSystem::setupCharacter(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    });

    LUAICOMMAND(setup_nonsauer, {
        lua_pushvalue(L, 1);
        LogicSystem::setupNonSauer(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    });

    LUAICOMMAND(destroy_extent, {
        lua_pushvalue(L, 1);
        LogicSystem::dismantleExtent(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    });

    LUAICOMMAND(destroy_character, {
        lua_pushvalue(L, 1);
        LogicSystem::dismantleCharacter(luaL_ref(L, LUA_REGISTRYINDEX));
        return 0;
    });

    /* Entity attributes */

    CLUAICOMMAND(set_animation, void, (int uid, int panim, int sanim), {
        LUA_GET_ENT(entity, uid, "_C.setanim", return)
        panim &= (ANIM_INDEX | ANIM_DIR);
        sanim &= (ANIM_INDEX | ANIM_DIR);
        entity->setAnimation(panim | (sanim << ANIM_SECONDARY));
    });

    CLUAICOMMAND(set_animflags, void, (int uid, int aflags), {
        LUA_GET_ENT(entity, uid, "_C.setanimflags", return)
        entity->setAnimationFlags((aflags << ANIM_FLAGSHIFT) & ANIM_FLAGS);
    });

    CLUAICOMMAND(get_start_time, int, (int uid), {
        LUA_GET_ENT(entity, uid, "_C.getstarttime", return 0)
        return entity->getStartTime();
    });

    CLUAICOMMAND(set_model_name, void, (int uid, const char *name), {
        if (!name) name = "";
        LUA_GET_ENT(entity, uid, "_C.setmodelname", return)
        logger::log(logger::DEBUG, "_C.setmodelname(%d, \"%s\")",
            entity->getUniqueId(), name);
        extentity *ext = entity->staticEntity;
        if (!ext) return;
        removeentity(ext);
        if (name[0]) ext->m = loadmodel(name);
        addentity(ext);
    });

    LUAICOMMAND(set_attachments, {
        int uid = luaL_checkinteger(L, 1);
        LUA_GET_ENT(entity, uid, "_C.setattachments", return 0)
        entity->setAttachments(L);
        return 0;
    });

    LUAICOMMAND(get_attachment_position, {
        int uid = luaL_checkinteger(L, 1);
        const char *attachment = "";
        if (!lua_isnoneornil(L, 2)) attachment = luaL_checkstring(L, 2);
        LUA_GET_ENT(entity, uid, "_C.getattachmentpos", return 0)
        lua::push_external(L, "new_vec3");
        const vec& o = entity->getAttachmentPosition(attachment);
        lua_pushnumber(L, o.x); lua_pushnumber(L, o.y); lua_pushnumber(L, o.z);
        lua_call(L, 3, 1);
        return 1;
    });

    CLUAICOMMAND(set_can_move, void, (int uid, bool b), {
        LUA_GET_ENT(entity, uid, "_C.setcanmove", return)
        entity->canMove = b;
    });

    /* Extents */

    CLUAICOMMAND(get_attr, int, (int uid, int a), {
        LUA_GET_ENT(entity, uid, "_C.get_attr", return 0)
        extentity *ext = entity->staticEntity;
        assert(ext);
        return ext->attr[a];
    });
    CLUAICOMMAND(set_attr, void, (int uid, int a, int v), {
        LUA_GET_ENT(entity, uid, "_C.set_attr", return)
        extentity *ext = entity->staticEntity;
        assert(ext);
        if (!world::loading) removeentity(ext);
        ext->attr[a] = v;
        if (!world::loading) addentity(ext);
    });
    CLUAICOMMAND(FAST_set_attr, void, (int uid, int a, int v), {
        LUA_GET_ENT(entity, uid, "_C.FAST_set_attr", return)
        extentity *ext = entity->staticEntity;
        assert(ext);
        ext->attr[a] = v;
    });

    struct cvec3_t { double x, y, z; };

    CLUAICOMMAND(get_extent_position, cvec3_t, (int uid), {
        LUA_GET_ENT(entity, uid, "_C.getextent0",
            return ((cvec3_t){ 0, 0, 0 }))
        extentity *ext = entity->staticEntity;
        assert(ext);
        logger::log(logger::INFO,
            "_C.getextent0(%d): x: %f, y: %f, z: %f",
            entity->getUniqueId(), ext->o.x, ext->o.y, ext->o.z);
        return ((cvec3_t){ ext->o.x, ext->o.y, ext->o.z });
    });

    CLUAICOMMAND(set_extent_position, void, (int uid, double x, double y,
    double z), {
        LUA_GET_ENT(entity, uid, "_C.setextent0", return)
        extentity *ext = entity->staticEntity;
        assert(ext);

        removeentity(ext);
        ext->o.x = x;
        ext->o.y = y;
        ext->o.z = z;
        addentity(ext);
    });

    /* Dynents */

    #define DYNENT_ACCESSORS(n, t, an) \
    CLUAICOMMAND(get_##n, t, (int uid), { \
        LUA_GET_ENT(entity, uid, "_C.get"#n, return 0) \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        return d->an; \
    }); \
    CLUAICOMMAND(set_##n, void, (int uid, t v), { \
        LUA_GET_ENT(entity, uid, "_C.set"#n, return) \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        d->an = v; \
    });

    DYNENT_ACCESSORS(maxspeed, float, maxspeed)
    DYNENT_ACCESSORS(crouchtime, int, crouchtime)
    DYNENT_ACCESSORS(radius, float, radius)
    DYNENT_ACCESSORS(eyeheight, float, eyeheight)
    DYNENT_ACCESSORS(maxheight, float, maxheight)
    DYNENT_ACCESSORS(crouchheight, float, crouchheight)
    DYNENT_ACCESSORS(jumpvel, float, jumpvel)
    DYNENT_ACCESSORS(gravity, float, gravity)
    DYNENT_ACCESSORS(aboveeye, float, aboveeye)
    DYNENT_ACCESSORS(yaw, float, yaw)
    DYNENT_ACCESSORS(pitch, float, pitch)
    DYNENT_ACCESSORS(roll, float, roll)
    DYNENT_ACCESSORS(move, int, move)
    DYNENT_ACCESSORS(strafe, int, strafe)
    DYNENT_ACCESSORS(yawing, int, turn_move)
    DYNENT_ACCESSORS(crouching, int, crouching);
    DYNENT_ACCESSORS(pitching, int, look_updown_move)
    DYNENT_ACCESSORS(jumping, bool, jumping)
    DYNENT_ACCESSORS(blocked, bool, blocked)
    DYNENT_ACCESSORS(mapdefinedposdata, uint, mapDefinedPositionData)
    DYNENT_ACCESSORS(clientstate, int, state)
    DYNENT_ACCESSORS(physstate, int, physstate)
    DYNENT_ACCESSORS(inwater, int, inwater)
    DYNENT_ACCESSORS(timeinair, int, timeinair)
    #undef DYNENT_ACCESSORS

    CLUAICOMMAND(get_dynent_position, cvec3_t, (int uid), {
        LUA_GET_ENT(entity, uid, "_C.getdynent0",
            return ((cvec3_t){ 0, 0, 0 }))
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);
        return ((cvec3_t){ d->o.x, d->o.y, d->o.z
            - d->eyeheight/* - d->aboveeye*/ });
    });

    CLUAICOMMAND(set_dynent_position, void, (int uid, double x, double y,
    double z), {
        LUA_GET_ENT(entity, uid, "_C.setdynent0", return)
        fpsent *d = (fpsent*)entity->dynamicEntity;
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

    #define DYNENTVEC(name, prop) \
        CLUAICOMMAND(get_dynent_##name, cvec3_t, (int uid), { \
            LUA_GET_ENT(entity, uid, "_C.getdynent"#name, \
                return ((cvec3_t){ 0, 0, 0 })) \
            fpsent *d = (fpsent*)entity->dynamicEntity; \
            assert(d); \
            return ((cvec3_t){ d->prop.x, d->prop.y, d->prop.z }); \
        }); \
        CLUAICOMMAND(set_dynent_##name, void, (int uid, double x, \
        double y, double z), { \
            LUA_GET_ENT(entity, uid, "_C.setdynent"#name, return) \
            fpsent *d = (fpsent*)entity->dynamicEntity; \
            assert(d); \
            d->prop.x = x; \
            d->prop.y = y; \
            d->prop.z = z; \
        });

    DYNENTVEC(velocity, vel)
    DYNENTVEC(falling, falling)
    #undef DYNENTVEC

#ifndef SERVER
    LUAICOMMAND(get_target_entity_uid, {
        if (TargetingControl::targetLogicEntity) {
            lua_pushinteger(L, TargetingControl::targetLogicEntity->
                getUniqueId());
            return 1;
        }
        return 0;
    });
#endif

    CLUAICOMMAND(get_plag, int, (int uid), {
        LUA_GET_ENT(entity, uid, "_C.getplag", return -1)
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        return p->plag;
    });

    CLUAICOMMAND(get_ping, int, (int uid), {
        LUA_GET_ENT(entity, uid, "_C.getping", return -1)
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        return p->ping;
    });

    LUAICOMMAND(get_selected_entity, {
        CLogicEntity *ret = EditingSystem::getSelectedEntity();
        if (ret && ret->lua_ref != LUA_REFNIL)
            lua_rawgeti(L, LUA_REGISTRYINDEX, ret->lua_ref);
        else
            lua_pushnil(L);
        return 1;
    });

    LUAICOMMAND(get_attached_entity, {
        int uid = luaL_checkinteger(L, 1);
        LUA_GET_ENT(entity, uid, "_C.get_attached_entity", return 0)
        extentity *e = entity->staticEntity;
        if (!e || !e->attached) return 0;
        CLogicEntity *ae = LogicSystem::getLogicEntity(*e->attached);
        if (!ae) return 0;
        lua_rawgeti(L, LUA_REGISTRYINDEX, ae->lua_ref);
        return 1;
    });
} /* end namespace entities */
