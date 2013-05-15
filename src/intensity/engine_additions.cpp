
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"
#include "client_system.h"
#include "of_tools.h"

// WorldSystem
extern void removeentity(extentity* entity);
extern void addentity(extentity* entity);

//=========================
// Logic Entities
//=========================

int CLogicEntity::getUniqueId()
{
    switch (getType())
    {
        case LE_DYNAMIC:
            return LogicSystem::getUniqueId(dynamicEntity);
        case LE_STATIC:
            return LogicSystem::getUniqueId(staticEntity);
        case LE_NONSAUER:
            return uniqueId; // This can be made to work for the others, if we ensure that uniqueId is set. Would be faster
        default:
            assert(0 && "getting the unique ID of a NONE logic entity!\r\n");
            return -1;
    };
}

int CLogicEntity::getType()
{
    if (dynamicEntity != NULL)
        return LE_DYNAMIC;
    else if (staticEntity != NULL)
        return LE_STATIC;
    else if (nonSauer)
        return LE_NONSAUER;
    else
        return LE_NONE;
}

extern vector<mapmodelinfo> mapmodels; // KLUDGE

vec CLogicEntity::getOrigin()
{
    switch (getType())
    {
        case LE_DYNAMIC:
            return dynamicEntity->o;
        case LE_STATIC:
        {
            if (staticEntity->type == ET_MAPMODEL)
            {
                vec bbcenter, bbradius;
                model *m = theModel;
                if (m)
                {
                    m->collisionbox(bbcenter, bbradius);
                    if (staticEntity->attr4 > 0) { float scale = staticEntity->attr4/100.0f; bbcenter.mul(scale); bbradius.mul(scale); }
                    rotatebb(bbcenter, bbradius, int(staticEntity->attr1), int(staticEntity->attr2), int(staticEntity->attr3));
                    bbcenter.add(staticEntity->o);
                    return bbcenter;
                } else {
                    logger::log(logger::WARNING, "Invalid mapmodel model\r\n");
                    return staticEntity->o;
                }
            } else
                return staticEntity->o;
        }
    };

    assert(0 && "getting the origin of a NONE or non-Sauer LogicEntity!");
    return vec(0,0,0);
}

float CLogicEntity::getRadius()
{
    switch (getType())
    {
        case LE_DYNAMIC:
            return 10;
        case LE_STATIC:
        {
            if (staticEntity->type == ET_MAPMODEL)
            {
                vec bbcenter, bbradius;
                model *m = theModel;
                if (m)
                {
                    m->collisionbox(bbcenter, bbradius);
                    if (staticEntity->attr4 > 0) { float scale = staticEntity->attr4/100.0f; bbcenter.mul(scale); bbradius.mul(scale); }
                    rotatebb(bbcenter, bbradius, int(staticEntity->attr1), int(staticEntity->attr2), int(staticEntity->attr3));
                    bbcenter.add(staticEntity->o);
                    return bbradius.x + bbradius.y;
                } else {
                    logger::log(logger::WARNING, "Invalid mapmodel model, cannot find radius\r\n");
                    return 8;
                }

            } else
                return 8;
        }
    };

    assert(0 && "getting the radius of a NONE or non-Sauer LogicEntity!");
    return -1;
}

void CLogicEntity::setOrigin(vec &newOrigin)
{
    lua::push_external("entity_get");
    lua_pushinteger(lua::L, getUniqueId());
    lua_call       (lua::L, 1, 1);

    lua_createtable(lua::L, 3, 0);
    lua_pushnumber (lua::L, newOrigin.x); lua_rawseti(lua::L, -2, 1);
    lua_pushnumber (lua::L, newOrigin.y); lua_rawseti(lua::L, -2, 2);
    lua_pushnumber (lua::L, newOrigin.z); lua_rawseti(lua::L, -2, 3);
    lua_setfield   (lua::L, -2, "position");
    lua_pop        (lua::L,  1);
}

int CLogicEntity::getAnimation()
{
    return animation;
}

int CLogicEntity::getStartTime()
{
    return startTime;
}

int CLogicEntity::getAnimationFrame()
{
    return 0; /* DEPRECATED for now */
}

const char *CLogicEntity::getClass()
{
    lua_getglobal(lua::L, "tostring");
    lua_rawgeti  (lua::L, LUA_REGISTRYINDEX, lua_ref);
    lua_call     (lua::L, 1, 1);
    const char *cl = luaL_optstring(lua::L, -1, "unknown");
    lua_pop(lua::L, 1);
    return cl;
}

model* CLogicEntity::getModel()
{
#ifdef CLIENT
    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return NULL;

    return theModel;
#else
    return NULL;
#endif
}

void CLogicEntity::setModel(const char *name)
{
#ifdef CLIENT
    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    if (staticEntity)
        removeentity(staticEntity);

    if (strcmp(name, "")) theModel = loadmodel(name);

    logger::log(logger::DEBUG, "CLE:setModel: %s (%p)\r\n", name, (void*)theModel);

    if (staticEntity)
        addentity(staticEntity);
#endif
}

void CLogicEntity::setAttachments(const char *at)
{
    logger::log(logger::DEBUG, "CLogicEntity::setAttachments: %s\r\n", at);

    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    // Clean out old data
    for (int i = 0; attachments[i].tag; i++)
    {
        delete[] attachments[i].tag;
        delete[] attachments[i].name;
    }

    // Generate new data
    int num = 0, i = 0;
    char *curr = NULL, *name = NULL, *tag = NULL;
    char *data = newstring(at);
    char * pch = strchr(data, '|');

    while (pch)
    {
        num++;
        pch = strchr(pch + 1, '|');
    }
    /* Because it'd be 1 even with no attachments. */
    if (strcmp(at, "")) num++;

    assert(num <= MAX_ATTACHMENTS);

    pch = strtok(data, "|");
    while (pch)
    {
        curr = newstring(pch);
        if (!strchr(curr, ','))
        {
            name = NULL;
            tag  = curr;
        }
        else
        {
            tag  = strtok(curr, ",");
            name = strtok(NULL, ",");
        }

        /* Tags starting with a '*' indicate this is a position marker */
        if (strlen(tag) >= 1 && tag[0] == '*')
        {
            tag++;
            attachments[i].pos = &attachmentPositions[i];
            /* Initialize, as if the attachment doesn't exist in the model,
             * we don't want NaNs and such causing crashes
             */
            attachmentPositions[i] = vec(0, 0, 0);
        }
        else attachments[i].pos = NULL;

        attachments[i].tag  = newstring(tag);
        attachments[i].name = name ? newstring(name) : newstring("");
        /* attachments[i].anim = ANIM_VWEP | ANIM_LOOP;
         * This will become important if/when we have animated attachments
         */
        attachments[i].basetime = 0;

        logger::log(
            logger::DEBUG,
            "Adding attachment: %s - %s\r\n",
            attachments[i].name,
            attachments[i].tag
        );

        delete[] curr;

        pch = strtok(NULL, "|");
        i++;
    }

    /* tag=null as well - probably not needed (order reversed with following line) */
    attachments[num].tag  = NULL;
    /* Null name element at the end, for sauer to know to stop */
    attachments[num].name = NULL;

    delete[] data;
}

void CLogicEntity::setAnimation(int _animation)
{
    logger::log(logger::DEBUG, "setAnimation: %d\r\n", _animation);

    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    logger::log(logger::DEBUG, "(2) setAnimation: %d\r\n", _animation);

    animation = _animation;
    startTime = lastmillis; // tools::currtime(); XXX Do NOT want the actual time! We
                            // need 'lastmillis', sauer's clock, which doesn't advance *inside* frames,
                            // because otherwise the starttime may be
                            // LATER than lastmillis, while sauer's animation system does lastmillis-basetime,
                            // leading to a negative number and segfaults in finding frame data
}

void CLogicEntity::setSound(const char *snd)
{
    logger::log(logger::DEBUG, "setSound: %s\r\n", snd);

    // This is important as this is called before setupExtent.
    if ((!this) || !staticEntity)
        return;

    logger::log(logger::DEBUG, "(2) setSound: %s\r\n", snd);

    sndname = snd;

#ifdef CLIENT
    stopmapsound(staticEntity);
    if(camera1->o.dist(staticEntity->o) < staticEntity->attr2)
      {
        if(!staticEntity->visible) playmapsound(sndname, staticEntity, staticEntity->attr4, -1);
        else if(staticEntity->visible) stopmapsound(staticEntity);
      }
#else
    MessageSystem::send_MapSoundToClients(-1, snd, LogicSystem::getUniqueId(staticEntity));
#endif
}

const char *CLogicEntity::getSound()
{
    return sndname;
}

vec& CLogicEntity::getAttachmentPosition(const char *tag)
{
    // If last actual render - which actually calculated the attachment positions - was recent
    // enough, use that data
    if (abs(lastmillis - lastActualRenderMillis) < 500)
    {
        // TODO: Use a hash table. But, if just 1-4 attachments, then fast enough for now as is
        for (int i = 0; attachments[i].tag; i++)
        {
            if (!strcmp(attachments[i].tag, tag))
                return attachmentPositions[i];
        }
    }
    static vec missing; // Returned if no such tag, or no recent attachment position info. Note: Only one of these, static!
    missing = getOrigin();
    return missing;
}

void CLogicEntity::noteActualRender()
{
    lastActualRenderMillis = lastmillis;
}


//=========================
// LogicSystem
//=========================

LogicSystem::LogicEntityMap LogicSystem::logicEntities;
bool LogicSystem::initialized = false;

void LogicSystem::clear(bool restart_lua)
{
    logger::log(logger::DEBUG, "clear()ing LogicSystem\r\n");
    INDENT_LOG(logger::DEBUG);

    if (lua::L)
    {
        lua::push_external("entities_remove_all"); lua_call(lua::L, 0, 0);
        enumerate(logicEntities, CLogicEntity*, ent, assert(!ent));
        if (restart_lua) lua::reset();
    }

    LogicSystem::initialized = false;
}

void LogicSystem::init()
{
    lua::init();
    LogicSystem::initialized = true;
}

void LogicSystem::registerLogicEntity(CLogicEntity *newEntity)
{
    logger::log(logger::DEBUG, "C registerLogicEntity: %d\r\n", newEntity->getUniqueId());
    INDENT_LOG(logger::DEBUG);

    int uniqueId = newEntity->getUniqueId();
    assert(!logicEntities.access(uniqueId));
    logicEntities.access(uniqueId, newEntity);

    lua::push_external("entity_get");
    lua_pushinteger(lua::L, uniqueId);
    lua_call       (lua::L, 1, 1);
    newEntity->lua_ref = luaL_ref(lua::L, LUA_REGISTRYINDEX);
    assert(newEntity->lua_ref != LUA_REFNIL);

    logger::log(logger::DEBUG, "C registerLogicEntity completes\r\n");
}

CLogicEntity *LogicSystem::registerLogicEntity(physent* entity)
{
    if (getUniqueId(entity) < 0)
    {
        logger::log(logger::ERROR, "Trying to register an entity with an invalid unique Id: %d (D)\r\n", getUniqueId(entity));
        assert(0);
    }

    CLogicEntity *newEntity = new CLogicEntity(entity);

    logger::log(logger::DEBUG, "adding physent %d\r\n", newEntity->getUniqueId());

    registerLogicEntity(newEntity);

    return newEntity;
}

CLogicEntity *LogicSystem::registerLogicEntity(extentity* entity)
{
    if (getUniqueId(entity) < 0)
    {
        logger::log(logger::ERROR, "Trying to register an entity with an invalid unique Id: %d (S)\r\n", getUniqueId(entity));
        assert(0);
    }

    CLogicEntity *newEntity = new CLogicEntity(entity);

//    logger::log(logger::DEBUG, "adding entity %d : %d,%d,%d,%d\r\n", entity->type, entity->attr1, entity->attr2, entity->attr3, entity->attr4);

    registerLogicEntity(newEntity);

    return newEntity;
}

void LogicSystem::registerLogicEntityNonSauer(int uniqueId)
{
    CLogicEntity *newEntity = new CLogicEntity(uniqueId);

    newEntity->nonSauer = true; // Set as non-Sauer

    logger::log(logger::DEBUG, "adding non-Sauer entity %d\r\n", uniqueId);

    registerLogicEntity(newEntity);

//    return newEntity;
}

void LogicSystem::unregisterLogicEntityByUniqueId(int uniqueId)
{
    logger::log(logger::DEBUG, "UNregisterLogicEntity by UniqueID: %d\r\n", uniqueId);

    if (!logicEntities.access(uniqueId)) return;

    CLogicEntity *ptr = logicEntities[uniqueId];
    logicEntities.remove(uniqueId);

    for (int i = 0; ptr->attachments[i].tag; i++)
    {
        delete[] ptr->attachments[i].tag;
        delete[] ptr->attachments[i].name;
    }

    luaL_unref(lua::L, LUA_REGISTRYINDEX, ptr->lua_ref);
    delete ptr;
}

void LogicSystem::manageActions(long millis)
{
    logger::log(logger::INFO, "manageActions: %d\r\n", millis);
    INDENT_LOG(logger::INFO);

    if (lua::L) {
        lua::push_external("frame_handle");
        lua_pushnumber (lua::L, double(millis) / 1000.0f);
        lua_pushinteger(lua::L, lastmillis);
        lua_call       (lua::L,  2, 0);
    }

    logger::log(logger::INFO, "manageActions complete\r\n");
}

CLogicEntity *LogicSystem::getLogicEntity(int uniqueId)
{
    if (!logicEntities.access(uniqueId))
    {
        logger::log(logger::INFO, "(C++) Trying to get a non-existant logic entity %d\r\n", uniqueId);
        return NULL;
    }

    return logicEntities[uniqueId];
}

CLogicEntity *LogicSystem::getLogicEntity(const extentity &extent)
{
    return getLogicEntity(extent.uniqueId);
}


CLogicEntity *LogicSystem::getLogicEntity(physent* entity)
{
    return getLogicEntity(getUniqueId(entity)); // TODO: do this directly, without the intermediary getUniqueId, for speed?
}

int LogicSystem::getUniqueId(extentity* staticEntity)
{
    return staticEntity->uniqueId;
}

int LogicSystem::getUniqueId(physent* dynamicEntity)
{
    return ((fpsent*)dynamicEntity)->uniqueId;
}

// TODO: Use this whereever it should be used
void LogicSystem::setUniqueId(extentity* staticEntity, int uniqueId)
{
    if (getUniqueId(staticEntity) >= 0)
    {
        logger::log(logger::ERROR, "Trying to set to %d a unique Id that has already been set, to %d (S)\r\n",
                                     uniqueId,
                                     getUniqueId(staticEntity));
        assert(0);
    }

    staticEntity->uniqueId = uniqueId;
}

// TODO: Use this whereever it should be used
void LogicSystem::setUniqueId(physent* dynamicEntity, int uniqueId)
{
    logger::log(logger::DEBUG, "Setting a unique ID: %d (of addr: %d)\r\n", uniqueId, dynamicEntity != NULL);

    if (getUniqueId(dynamicEntity) >= 0)
    {
        logger::log(logger::ERROR, "Trying to set to %d a unique Id that has already been set, to %d (D)\r\n",
                                     uniqueId,
                                     getUniqueId(dynamicEntity));
        assert(0);
    }

    ((fpsent*)dynamicEntity)->uniqueId = uniqueId;
}

void LogicSystem::setupExtent(int ref, int type, float x, float y, float z, int attr1, int attr2, int attr3, int attr4, int attr5)
{
    lua_rawgeti (lua::L, LUA_REGISTRYINDEX, ref);
    lua_getfield(lua::L, -1, "uid");
    int uid = lua_tointeger(lua::L, -1); lua_pop(lua::L, 2);
    luaL_unref(lua::L, LUA_REGISTRYINDEX, ref);
    logger::log(logger::DEBUG, "setupExtent: %d,  %d : %f,%f,%f : %d,%d,%d,%d,%d\r\n", uid, type, x, y, z, attr1, attr2, attr3, attr4, attr5);
    INDENT_LOG(logger::DEBUG);

    extentity *e = new extentity;
    entities::getents().add(e);

    e->type  = type;
    e->o     = vec(x,y,z);
    e->attr1 = attr1;
    e->attr2 = attr2;
    e->attr3 = attr3;
    e->attr4 = attr4;
    e->attr5 = attr5;

    e->inoctanode = false; // This is not set by the constructor in sauer, but by those calling "new extentity", so we also do that here

    extern void addentity(extentity* entity);
    addentity(e);
    attachentity(*e);

    LogicSystem::setUniqueId(e, uid);
    LogicSystem::registerLogicEntity(e);
}

void LogicSystem::setupCharacter(int ref)
{
//    #ifdef CLIENT
//        assert(0); // until we figure this out
//    #endif

    lua_rawgeti (lua::L, LUA_REGISTRYINDEX, ref);
    lua_getfield(lua::L, -1, "uid");
    int uid = lua_tointeger(lua::L, -1); lua_pop(lua::L, 1);

    logger::log(logger::DEBUG, "setupCharacter: %d\r\n", uid);
    INDENT_LOG(logger::DEBUG);

    fpsent* fpsEntity;

    lua_getfield(lua::L, -1, "cn");
    int cn = lua_tointeger(lua::L, -1); lua_pop(lua::L, 1);
    logger::log(logger::DEBUG, "(a) cn: %d\r\n", cn);

    #ifdef CLIENT
        logger::log(logger::DEBUG, "client numbers: %d, %d\r\n", ClientSystem::playerNumber, cn);

        if (uid == ClientSystem::uniqueId) {
            lua_pushinteger(lua::L, ClientSystem::playerNumber);
            lua_setfield   (lua::L, -2, "cn");
        }
    #endif

    lua_pop(lua::L, 1); // pop the entity
    luaL_unref(lua::L, LUA_REGISTRYINDEX, ref);

    logger::log(logger::DEBUG, "(b) cn: %d\r\n", cn);

    assert(cn >= 0);

    #ifdef CLIENT
    // If this is the player. There should already have been created an fpsent for this client,
    // which we can fetch with the valid client #
    logger::log(logger::DEBUG, "UIDS: in ClientSystem %d, and given to us%d\r\n", ClientSystem::uniqueId, uid);

    if (uid == ClientSystem::uniqueId)
    {
        logger::log(logger::DEBUG, "This is the player, use existing clientnumber for fpsent (should use player1?) \r\n");

        fpsEntity = game::getclient(cn);

        // Wipe clean the uid set for the fpsent, so we can re-use it.
        fpsEntity->uniqueId = -77;
    }
    else
    #endif
    {
        logger::log(logger::DEBUG, "This is a remote client or NPC, do a newClient for the fpsent\r\n");

        // This is another client, perhaps NPC. Connect this new client using newClient
        fpsEntity = game::newclient(cn);
    }

    // Register with the C++ system.

    LogicSystem::setUniqueId(fpsEntity, uid);
    LogicSystem::registerLogicEntity(fpsEntity);
}

void LogicSystem::setupNonSauer(int ref)
{
    lua_rawgeti (lua::L, LUA_REGISTRYINDEX, ref);
    lua_getfield(lua::L, -1, "uid");
    int uid = lua_tointeger(lua::L, -1); lua_pop(lua::L, 2);
    luaL_unref(lua::L, LUA_REGISTRYINDEX, ref);

    logger::log(logger::DEBUG, "setupNonSauer: %d\r\n", uid);
    INDENT_LOG(logger::DEBUG);

    LogicSystem::registerLogicEntityNonSauer(uid);
}

void LogicSystem::dismantleExtent(int ref)
{
    lua_rawgeti (lua::L, LUA_REGISTRYINDEX, ref);
    lua_getfield(lua::L, -1, "uid");
    int uid = lua_tointeger(lua::L, -1); lua_pop(lua::L, 2);
    luaL_unref(lua::L, LUA_REGISTRYINDEX, ref);

    logger::log(logger::DEBUG, "Dismantle extent: %d\r\n", uid);

    extentity* extent = getLogicEntity(uid)->staticEntity;
#ifdef CLIENT
    if (extent->type == ET_SOUND) stopmapsound(extent);
#endif
    removeentity(extent);
    extent->type = ET_EMPTY;

//    delete extent; extent = NULL; // For symmetry with the "new extentity" this should be here, but sauer does it
                                                     // in clearents() in the next load_world.
}

void LogicSystem::dismantleCharacter(int ref)
{
    lua_rawgeti (lua::L, LUA_REGISTRYINDEX, ref);
    lua_getfield(lua::L, -1, "cn");
    int cn = lua_tointeger(lua::L, -1); lua_pop(lua::L, 2);
    luaL_unref(lua::L, LUA_REGISTRYINDEX, ref);

    #ifdef CLIENT
    if (cn == ClientSystem::playerNumber)
        logger::log(logger::DEBUG, "Not dismantling own client\r\n", cn);
    else
    #endif
    {
        logger::log(logger::DEBUG, "Dismantling other client %d\r\n", cn);

#ifdef SERVER
        fpsent* fpsEntity = game::getclient(cn);
        bool isNPC = fpsEntity->serverControlled;
#endif

        game::clientdisconnected(cn);

#ifdef SERVER
        if (isNPC)
        {
            /* The server connections of NPCs are removed when they are dismantled -
             * they must be re-created manually in the new scenario, unlike players */
            localdisconnect(true, cn);
        }
#endif
    }
}
