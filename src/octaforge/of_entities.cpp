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

    LUAICOMMAND(unregister_entity, {
        LogicSystem::unregisterLogicEntityByUniqueId(luaL_checkinteger(L, 1));
        return 0;
    });

    LUAICOMMAND(setup_extent, {
        lua_pushvalue(L, 1);
        LogicSystem::setupExtent(
            luaL_ref(L, LUA_REGISTRYINDEX), luaL_checkinteger(L, 2),
            luaL_checknumber(L, 3), luaL_checknumber(L, 4),
            luaL_checknumber(L, 5), luaL_checkinteger(L, 6),
            luaL_checkinteger(L, 7), luaL_checkinteger(L, 8),
            luaL_checkinteger(L, 9), luaL_checkinteger(L, 10));
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

    LUAICOMMAND(set_animation, {
        LUA_GET_ENT(entity, "_C.setanim", return 0)
        entity->setAnimation(luaL_checkinteger(L, 2));
        return 0;
    });

    LUAICOMMAND(get_start_time, {
        LUA_GET_ENT(entity, "_C.getstarttime", return 0)
        lua_pushinteger(L, entity->getStartTime());
        return 1;
    });

    LUAICOMMAND(set_model_name, {
        const char *name = "";
        if (!lua_isnoneornil(L, 2)) name = luaL_checkstring(L, 2);
        LUA_GET_ENT(entity, "_C.setmodelname", return 0)
        logger::log(logger::DEBUG, "_C.setmodelname(%d, \"%s\")\n",
            entity->getUniqueId(), name);
        entity->setModel(name);
        return 0;
    });

    LUAICOMMAND(set_sound_name, {
        const char *name = "";
        if (!lua_isnoneornil(L, 2)) name = luaL_checkstring(L, 2);
        LUA_GET_ENT(entity, "_C.setsoundname", return 0)
        logger::log(logger::DEBUG, "_C.setsoundname(%d, \"%s\")\n",
            entity->getUniqueId(), name);
        entity->setSound(name);
        return 0;
    });

    LUAICOMMAND(set_sound_volume, {
        LUA_GET_ENT(entity, "_C.setsoundvol", return 0)
        int vol = luaL_checkinteger(L, 2);
        logger::log(logger::DEBUG, "_C.setsoundvol(%i)\n", vol);

        if (!entity->sndname) return 0;

        extentity *ext = entity->staticEntity;
        assert(ext);

        if (!world::loading) removeentity(ext);
        ext->attr4 = vol;
        if (!world::loading) addentity(ext);

        entity->setSound(entity->sndname);
        return 0;
    });

    LUAICOMMAND(set_attachments, {
        LUA_GET_ENT(entity, "_C.setattachments", return 0)
        lua_getglobal(L, "table");
        lua_getfield (L, -1, "concat");
        lua_remove   (L, -2);
        lua_pushvalue(L,  2);
        lua_call     (L, 1, 1);
        entity->setAttachments(lua_tostring(L, -1));
        lua_pop(L, 1);
        return 0;
    });

    LUAICOMMAND(get_attachment_position, {
        const char *attachment = "";
        if (!lua_isnoneornil(L, 2)) attachment = luaL_checkstring(L, 2);
        LUA_GET_ENT(entity, "_C.getattachmentpos", return 0)
        lua::push_external(L, "new_vec3");
        const vec& o = entity->getAttachmentPosition(attachment);
        lua_pushnumber(L, o.x); lua_pushnumber(L, o.y); lua_pushnumber(L, o.z);
        lua_call(L, 3, 1);
        return 1;
    });

    LUAICOMMAND(set_can_move, {
        LUA_GET_ENT(entity, "_C.setcanmove", return 0)
        entity->setCanMove(lua_toboolean(L, 2));
        return 0;
    });

    /* Extents */

    #define EXTENT_ACCESSORS(n) \
    LUAICOMMAND(get_##n, { \
        LUA_GET_ENT(entity, "_C.get"#n, return 0) \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        lua_pushinteger(L, ext->n); \
        return 1; \
    }); \
    LUAICOMMAND(set_##n, { \
        LUA_GET_ENT(entity, "_C.set"#n, return 0) \
        int v = luaL_checkinteger(L, 2); \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        if (!world::loading) removeentity(ext); \
        ext->n = v; \
        if (!world::loading) addentity(ext); \
        return 0; \
    }); \
    LUAICOMMAND(FAST_set_##n, { \
        LUA_GET_ENT(entity, "_C.FAST_set"#n, return 0) \
        int v = luaL_checkinteger(L, 2); \
        extentity *ext = entity->staticEntity; \
        assert(ext); \
        ext->n = v; \
        return 0; \
    });

    EXTENT_ACCESSORS(attr1)
    EXTENT_ACCESSORS(attr2)
    EXTENT_ACCESSORS(attr3)
    EXTENT_ACCESSORS(attr4)
    EXTENT_ACCESSORS(attr5)
    #undef EXTENT_ACCESSORS

    LUAICOMMAND(get_extent_position, {
        LUA_GET_ENT(entity, "_C.getextent0", return 0)
        extentity *ext = entity->staticEntity;
        assert(ext);
        logger::log(logger::INFO,
            "_C.getextent0(%d): x: %f, y: %f, z: %f\n",
            entity->getUniqueId(), ext->o.x, ext->o.y, ext->o.z);
        lua_createtable(L, 3, 0);
        lua_pushnumber(L, ext->o.x); lua_rawseti(L, -2, 1);
        lua_pushnumber(L, ext->o.y); lua_rawseti(L, -2, 2);
        lua_pushnumber(L, ext->o.z); lua_rawseti(L, -2, 3);
        return 1;
    });

    LUAICOMMAND(set_extent_position, {
        LUA_GET_ENT(entity, "_C.setextent0", return 0)
        luaL_checktype(L, 2, LUA_TTABLE);
        extentity *ext = entity->staticEntity;
        assert(ext);

        removeentity(ext);
        lua_pushinteger(L, 1); lua_gettable(L, -2);
        ext->o.x = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 2); lua_gettable(L, -2);
        ext->o.y = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 3); lua_gettable(L, -2);
        ext->o.z = luaL_checknumber(L, -1); lua_pop(L, 1);
        addentity(ext);
        return 0;
    });

    /* Dynents */

    #define luaL_checkboolean lua_toboolean

    #define DYNENT_ACCESSORS(n, t, tt, an) \
    LUAICOMMAND(get_##n, { \
        LUA_GET_ENT(entity, "_C.get"#n, return 0) \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        lua_push##tt(L, d->an); \
        return 1; \
    }); \
    LUAICOMMAND(set_##n, { \
        LUA_GET_ENT(entity, "_C.set"#n, return 0) \
        t v = luaL_check##tt(L, 2); \
        fpsent *d = (fpsent*)entity->dynamicEntity; \
        assert(d); \
        d->an = v; \
        return 0; \
    });

    DYNENT_ACCESSORS(maxspeed, float, number, maxspeed)
    DYNENT_ACCESSORS(radius, float, number, radius)
    DYNENT_ACCESSORS(eyeheight, float, number, eyeheight)
    DYNENT_ACCESSORS(aboveeye, float, number, aboveeye)
    DYNENT_ACCESSORS(yaw, float, number, yaw)
    DYNENT_ACCESSORS(pitch, float, number, pitch)
    DYNENT_ACCESSORS(roll, float, number, roll)
    DYNENT_ACCESSORS(move, int, integer, move)
    DYNENT_ACCESSORS(strafe, int, integer, strafe)
    DYNENT_ACCESSORS(yawing, int, integer, turn_move)
    DYNENT_ACCESSORS(pitching, int, integer, look_updown_move)
    DYNENT_ACCESSORS(jumping, bool, boolean, jumping)
    DYNENT_ACCESSORS(blocked, bool, boolean, blocked)
    /* XXX should be unsigned */
    DYNENT_ACCESSORS(mapdefinedposdata, int, integer, mapDefinedPositionData)
    DYNENT_ACCESSORS(clientstate, int, integer, state)
    DYNENT_ACCESSORS(physstate, int, integer, physstate)
    DYNENT_ACCESSORS(inwater, int, integer, inwater)
    DYNENT_ACCESSORS(timeinair, int, integer, timeinair)
    #undef DYNENT_ACCESSORS
    #undef luaL_checkboolean

    LUAICOMMAND(get_dynent_position, {
        LUA_GET_ENT(entity, "_C.getdynent0", return 0)
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);
        lua_createtable(L, 3, 0);
        lua_pushnumber(L, d->o.x); lua_rawseti(L, -2, 1);
        lua_pushnumber(L, d->o.y); lua_rawseti(L, -2, 2);
        lua_pushnumber(L, d->o.z - d->eyeheight/* - d->aboveeye*/);
        lua_rawseti(L, -2, 3);
        return 1;
    });

    LUAICOMMAND(set_dynent_position, {
        LUA_GET_ENT(entity, "_C.setdynent0", return 0)
        luaL_checktype(L, 2, LUA_TTABLE);
        fpsent *d = (fpsent*)entity->dynamicEntity;
        assert(d);

        lua_pushinteger(L, 1); lua_gettable(L, -2);
        d->o.x = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 2); lua_gettable(L, -2);
        d->o.y = luaL_checknumber(L, -1); lua_pop(L, 1);
        lua_pushinteger(L, 3); lua_gettable(L, -2);
        d->o.z = luaL_checknumber(L, -1) + d->eyeheight;/* + d->aboveeye; */
        lua_pop(L, 1);

        /* also set newpos, otherwise this change may get overwritten */
        d->newpos = d->o;

        /* no need to interpolate to the last position - just jump */
        d->resetinterp();

        logger::log(
            logger::INFO, "(%i).setdynent0(%f, %f, %f)",
            d->uniqueId, d->o.x, d->o.y, d->o.z
        );
        return 0;
    });

    #define DYNENTVEC(name, prop) \
        LUAICOMMAND(get_dynent_##name, { \
            LUA_GET_ENT(entity, "_C.getdynent"#name, return 0) \
            fpsent *d = (fpsent*)entity->dynamicEntity; \
            assert(d); \
            lua_createtable(L, 3, 0); \
            lua_pushnumber(L, d->prop.x); lua_rawseti(L, -2, 1); \
            lua_pushnumber(L, d->prop.y); lua_rawseti(L, -2, 2); \
            lua_pushnumber(L, d->prop.z); lua_rawseti(L, -2, 3); \
            return 1; \
        }); \
        LUAICOMMAND(set_dynent_##name, { \
            LUA_GET_ENT(entity, "_C.setdynent"#name, return 0) \
            fpsent *d = (fpsent*)entity->dynamicEntity; \
            assert(d); \
            lua_pushinteger(L, 1); lua_gettable(L, -2); \
            d->prop.x = luaL_checknumber(L, -1); lua_pop(L, 1); \
            lua_pushinteger(L, 2); lua_gettable(L, -2); \
            d->prop.y = luaL_checknumber(L, -1); lua_pop(L, 1); \
            lua_pushinteger(L, 3); lua_gettable(L, -2); \
            d->prop.z = luaL_checknumber(L, -1); lua_pop(L, 1); \
            return 0; \
        });

    DYNENTVEC(velocity, vel)
    DYNENTVEC(falling, falling)
    #undef DYNENTVEC

#ifdef CLIENT
    LUAICOMMAND(get_target_entity_uid, {
        if (TargetingControl::targetLogicEntity &&
           !TargetingControl::targetLogicEntity->isNone()) {
            lua_pushinteger(L, TargetingControl::targetLogicEntity->
                getUniqueId());
            return 1;
        }
        return 0;
    });
#endif

    LUAICOMMAND(get_plag, {
        LUA_GET_ENT(entity, "_C.getplag", return 0)
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        lua_pushinteger(L, p->plag);
        return 1;
    });

    LUAICOMMAND(get_ping, {
        LUA_GET_ENT(entity, "_C.getping", return 0)
        fpsent *p = (fpsent*)entity->dynamicEntity;
        assert(p);
        lua_pushinteger(L, p->ping);
        return 1;
    });

    LUAICOMMAND(get_selected_entity, {
        CLogicEntity *ret = EditingSystem::getSelectedEntity();
        if (ret && !ret->isNone() && ret->lua_ref != LUA_REFNIL)
            lua_rawgeti(L, LUA_REGISTRYINDEX, ret->lua_ref);
        else
            lua_pushnil(L);
        return 1;
    });

    LUAICOMMAND(get_attached_entity, {
        LUA_GET_ENT(entity, "_C.get_attached_entity", return 0)
        extentity *e = entity->staticEntity;
        if (!e || !e->attached) return 0;
        CLogicEntity *ae = LogicSystem::getLogicEntity(*e->attached);
        if (!ae) return 0;
        lua_rawgeti(L, LUA_REGISTRYINDEX, ae->lua_ref);
        return 1;
    });
} /* end namespace entities */

/* extra model API */

vector<int> lua_anims;
static hashtable<const char*, int> animmap;

bool matchanim(const char *name, const char *pattern)
{
    for(;; pattern++)
    {
        const char *s = name;
        char c;
        for(;; pattern++)
        {
            c = *pattern;
            if(!c || c=='|') break;
            else if(c=='*') 
            {
                if(!*s || iscubespace(*s)) break;
                do s++; while(*s && !iscubespace(*s));
            }
            else if(c!=*s) break;
            else s++;
        }
        if(!*s && (!c || c=='|')) return true;
        pattern = strchr(pattern, '|');
        if(!pattern) break;
    }
    return false;
}

void findanims(const char *pattern, vector<int> &anims)
{
    enumeratekt(animmap, const char*, s, int, v, {
        if (matchanim(s, pattern)) anims.add(v);
    });
    string num;
    loopi(ANIM_ALL + 1) {
        formatstring(num)("%d", i);
        if (matchanim(num, pattern)) anims.add(i);
    }
    anims.sort();
}

LUAICOMMAND(model_register_anim, {
    /* don't let it overflow */
    const char *s = luaL_checkstring(L, 1);
    int *a = animmap.access(s);
    if (a) {
        lua_pushinteger(L, *a);
        lua_pushboolean(L, false);
        return 2;
    }
    else if (lua_anims.length() > ANIM_ALL) return 0;
    /* pin it */
    lua_pushvalue(L, 1); lua_setfield(L, LUA_REGISTRYINDEX, s);
    int n = lua_anims.length();
    animmap.access(s, n);
    lua_anims.add(n);
    lua_pushinteger(L, n);
    lua_pushboolean(L, true);
    return 2;
});

LUAICOMMAND(model_get_anim, {
    const char *s = luaL_checkstring(L, 1);
    int *a = animmap.access(s);
    if (!a) return 0;
    lua_pushinteger(L, *a);
    return 1;
});

void clearanims() {
    lua_anims.setsize(0);
    loopi(animmap.size) {
        for (hashtable<const char*, int>::chain *c = animmap.chains[i]; c;) {
            const char *s = c->elem.key;
            c = c->next;
            lua_pushnil(lua::L); lua_setfield(lua::L, LUA_REGISTRYINDEX, s);
        }
    }
    animmap.clear();
}
LUAICOMMAND(model_clear_anims, { clearanims(); return 0; });
