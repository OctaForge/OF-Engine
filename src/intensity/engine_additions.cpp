
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
extern int getattrnum(int type);

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
        default:
            return uniqueId; // This can be made to work for the others, if we ensure that uniqueId is set. Would be faster
    };
}

int CLogicEntity::getType()
{
    if (dynamicEntity != NULL)
        return LE_DYNAMIC;
    else if (staticEntity != NULL)
        return LE_STATIC;
    else
        return LE_NONSAUER;
}

int CLogicEntity::getAnimation()
{
    return anim;
}

int CLogicEntity::getStartTime()
{
    return startTime;
}

int getanimid(const char *name);

void CLogicEntity::clear_attachments() {
#ifndef SERVER
    for (int i = 0; i < attachments.length() - 1; i++) {
        delete[] (char*)attachments[i].tag;
        delete[] (char*)attachments[i].name;
    }
    attachments.setsize(0);
    attachment_positions.clear();
#endif
}

void CLogicEntity::setAttachments(const char **attach) {
#ifndef SERVER
    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    // Clean out old data
    clear_attachments();

    while (*attach) {
        const char *str = *attach++;
        if (!str[0]) continue;
        const char *name = strchr(str, ',');
        char *tag = NULL;
        if (name) {
            const char *sp = str + (str[0] == '*');
            tag = (char*)memcpy(new char[name - sp + 1], sp, name - sp);
            tag[name - sp] = '\0';
            name++;
        } else tag = newstring(str + (str[0] == '*'));
        if (str[0] == '*') {
            entlinkpos *pos = attachment_positions.access(tag);
            modelattach &a = attachments.add(modelattach(tag, (vec*)(pos ? pos
                : &attachment_positions.access(tag, entlinkpos()))));
            a.name = name ? newstring(name) : NULL;
        } else {
            attachments.add(modelattach(tag, newstring(name ? name : "")));
        }
    }
    attachments.add(modelattach());
#endif
}

void CLogicEntity::setAnimation(int _anim)
{
    logger::log(logger::DEBUG, "setAnimation: %u", _anim);

    // This is important as this is called before setupExtent.
    if ((!this) || (!staticEntity && !dynamicEntity))
        return;

    logger::log(logger::DEBUG, "(2) setAnimation: %u", _anim);

    anim = _anim;
    startTime = lastmillis; // tools::currtime(); XXX Do NOT want the actual time! We
                            // need 'lastmillis', sauer's clock, which doesn't advance *inside* frames,
                            // because otherwise the starttime may be
                            // LATER than lastmillis, while sauer's animation system does lastmillis-basetime,
                            // leading to a negative number and segfaults in finding frame data
}

vec& CLogicEntity::getAttachmentPosition(const char *tag)
{
#ifdef SERVER
    static vec r = vec(0);
    return r;
#else
    // If last actual render - which actually calculated the attachment positions - was recent
    // enough, use that data
    vec *pos = (vec*)attachment_positions.access(tag);
    if (pos) {
        if ((lastmillis - *((int*)(pos + 1))) < 500) return *pos;
    }
    static vec missing; // Returned if no such tag, or no recent attachment position info. Note: Only one of these, static!
    if (getType() == LE_DYNAMIC) {
        missing = dynamicEntity->o;
    } else {
        if (staticEntity->type == ET_MAPMODEL) {
            vec center, radius;
            if (staticEntity->m) {
                staticEntity->m->collisionbox(center, radius);
                if (staticEntity->attr[3] > 0) {
                    float scale = staticEntity->attr[3] / 100.0f;
                    center.mul(scale); radius.mul(scale);
                }
                rotatebb(center, radius, staticEntity->attr[0], staticEntity->attr[1], staticEntity->attr[2]);
                center.add(staticEntity->o);
                missing = center;
            } else missing = staticEntity->o;
        } else {
            missing = staticEntity->o;
        }
    }
    return missing;
#endif
}

//=========================
// LogicSystem
//=========================

LogicSystem::LogicEntityMap LogicSystem::logicEntities;
bool LogicSystem::initialized = false;

void LogicSystem::clear(bool restart_lua)
{
    logger::log(logger::DEBUG, "clear()ing LogicSystem");
    INDENT_LOG(logger::DEBUG);

    if (lua::L)
    {
        lua::call_external("entities_remove_all", "");
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
    logger::log(logger::DEBUG, "C registerLogicEntity: %d", newEntity->getUniqueId());
    INDENT_LOG(logger::DEBUG);

    int uniqueId = newEntity->getUniqueId();
    assert(!logicEntities.access(uniqueId));
    logicEntities.access(uniqueId, newEntity);

    logger::log(logger::DEBUG, "C registerLogicEntity completes");
}

CLogicEntity *LogicSystem::registerLogicEntity(physent* entity)
{
    if (getUniqueId(entity) < 0)
    {
        logger::log(logger::ERROR, "Trying to register an entity with an invalid unique Id: %d (D)", getUniqueId(entity));
        assert(0);
    }

    CLogicEntity *newEntity = new CLogicEntity(entity);

    logger::log(logger::DEBUG, "adding physent %d", newEntity->getUniqueId());

    registerLogicEntity(newEntity);

    return newEntity;
}

CLogicEntity *LogicSystem::registerLogicEntity(extentity* entity)
{
    if (getUniqueId(entity) < 0)
    {
        logger::log(logger::ERROR, "Trying to register an entity with an invalid unique Id: %d (S)", getUniqueId(entity));
        assert(0);
    }

    CLogicEntity *newEntity = new CLogicEntity(entity);

//    logger::log(logger::DEBUG, "adding entity %d : %d,%d,%d,%d", entity->type, entity->attr[0], entity->attr[1], entity->attr[2], entity->attr[3]);

    registerLogicEntity(newEntity);

    return newEntity;
}

void LogicSystem::registerLogicEntityNonSauer(int uniqueId)
{
    CLogicEntity *newEntity = new CLogicEntity(uniqueId);
    logger::log(logger::DEBUG, "adding non-Sauer entity %d", uniqueId);
    registerLogicEntity(newEntity);
//    return newEntity;
}

void LogicSystem::unregisterLogicEntityByUniqueId(int uniqueId)
{
    logger::log(logger::DEBUG, "UNregisterLogicEntity by UniqueID: %d", uniqueId);

    if (!logicEntities.access(uniqueId)) return;

    CLogicEntity *ptr = logicEntities[uniqueId];
    logicEntities.remove(uniqueId);

    ptr->clear_attachments();
    delete ptr;
}

void LogicSystem::manageActions(long millis)
{
    logger::log(logger::INFO, "manageActions: %d", millis);
    INDENT_LOG(logger::INFO);
    if (lua::L) lua::call_external("frame_handle", "ii", millis, lastmillis);
    logger::log(logger::INFO, "manageActions complete");
}

CLogicEntity *LogicSystem::getLogicEntity(int uniqueId)
{
    if (!logicEntities.access(uniqueId))
    {
        logger::log(logger::INFO, "(C++) Trying to get a non-existant logic entity %d", uniqueId);
        return NULL;
    }

    return logicEntities[uniqueId];
}

CLogicEntity *LogicSystem::getLogicEntity(const extentity &extent)
{
    return getLogicEntity(extent.uid);
}


CLogicEntity *LogicSystem::getLogicEntity(physent* entity)
{
    return getLogicEntity(getUniqueId(entity)); // TODO: do this directly, without the intermediary getUniqueId, for speed?
}

int LogicSystem::getUniqueId(extentity* staticEntity)
{
    return staticEntity->uid;
}

int LogicSystem::getUniqueId(physent* dynamicEntity)
{
    return ((gameent*)dynamicEntity)->uid;
}

// TODO: Use this whereever it should be used
void LogicSystem::setUniqueId(extentity* staticEntity, int uniqueId)
{
    if (getUniqueId(staticEntity) >= 0)
    {
        logger::log(logger::ERROR, "Trying to set to %d a unique Id that has already been set, to %d (S)",
                                     uniqueId,
                                     getUniqueId(staticEntity));
        assert(0);
    }

    staticEntity->uid = uniqueId;
}

// TODO: Use this whereever it should be used
void LogicSystem::setUniqueId(physent* dynamicEntity, int uniqueId)
{
    logger::log(logger::DEBUG, "Setting a unique ID: %d (of addr: %d)", uniqueId, dynamicEntity != NULL);

    if (getUniqueId(dynamicEntity) >= 0)
    {
        logger::log(logger::ERROR, "Trying to set to %d a unique Id that has already been set, to %d (D)",
                                     uniqueId,
                                     getUniqueId(dynamicEntity));
        assert(0);
    }

    ((gameent*)dynamicEntity)->uid = uniqueId;
}

void LogicSystem::setupExtent(int uid, int type)
{
    logger::log(logger::DEBUG, "setupExtent: %d, %d", uid, type);
    INDENT_LOG(logger::DEBUG);

    extentity *e = new extentity;
    entities::getents().add(e);

    e->type = type;
    e->o = vec(0, 0, 0);
    int numattrs = getattrnum(type);
    for (int i = 0; i < numattrs; ++i) e->attr.add(0);

#ifndef SERVER
    addentity(e);
    attachentity(*e);
#endif

    LogicSystem::setUniqueId(e, uid);
    LogicSystem::registerLogicEntity(e);
}

void LogicSystem::setupCharacter(int uid, int cn)
{
    logger::log(logger::DEBUG, "setupCharacter: %d, %d", uid, cn);
    INDENT_LOG(logger::DEBUG);

    gameent* gameEntity;

    #ifndef SERVER
        logger::log(logger::DEBUG, "client numbers: %d, %d", ClientSystem::playerNumber, cn);

        if (uid == ClientSystem::uniqueId)
            lua::call_external("entity_set_cn", "ii", uid, (cn = ClientSystem::playerNumber));
    #endif

    assert(cn >= 0);

    #ifndef SERVER
    // If this is the player. There should already have been created an gameent for this client,
    // which we can fetch with the valid client #
    logger::log(logger::DEBUG, "UIDS: in ClientSystem %d, and given to us%d", ClientSystem::uniqueId, uid);

    if (uid == ClientSystem::uniqueId)
    {
        logger::log(logger::DEBUG, "This is the player, use existing clientnumber for gameent (should use player1?)");

        gameEntity = game::getclient(cn);

        // Wipe clean the uid set for the gameent, so we can re-use it.
        gameEntity->uid = -77;
    }
    else
    #endif
    {
        logger::log(logger::DEBUG, "This is a remote client, do a newClient for the gameent");

        // This is another client. Connect this new client using newClient
        gameEntity = game::newclient(cn);
    }

    // Register with the C++ system.

    LogicSystem::setUniqueId(gameEntity, uid);
    LogicSystem::registerLogicEntity(gameEntity);
}

void LogicSystem::setupNonSauer(int uid)
{
    logger::log(logger::DEBUG, "setupNonSauer: %d\r\n", uid);
    INDENT_LOG(logger::DEBUG);

    LogicSystem::registerLogicEntityNonSauer(uid);
}

void LogicSystem::dismantleExtent(int uid)
{
    logger::log(logger::DEBUG, "Dismantle extent: %d\r\n", uid);

    extentity* extent = getLogicEntity(uid)->staticEntity;
#ifndef SERVER
    if (extent->type == ET_SOUND) stopmapsound(extent);
    removeentity(extent);
#endif
    extent->type = ET_EMPTY;

//    delete extent; extent = NULL; // For symmetry with the "new extentity" this should be here, but sauer does it
                                                     // in clearents() in the next load_world.
}

void LogicSystem::dismantleCharacter(int cn)
{
    #ifndef SERVER
    if (cn == ClientSystem::playerNumber)
        logger::log(logger::DEBUG, "Not dismantling own client\r\n", cn);
    else
    #endif
    {
        logger::log(logger::DEBUG, "Dismantling other client %d\r\n", cn);
        game::clientdisconnected(cn);
    }
}
