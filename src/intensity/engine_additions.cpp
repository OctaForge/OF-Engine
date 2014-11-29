
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
#ifndef STANDALONE
    for (int i = 0; i < attachments.length() - 1; i++) {
        delete[] (char*)attachments[i].tag;
        delete[] (char*)attachments[i].name;
    }
    attachments.setsize(0);
    attachment_positions.clear();
#endif
}

void CLogicEntity::setAttachments(const char **attach) {
#ifndef STANDALONE
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
#ifdef STANDALONE
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
    if (dynamicEntity) {
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
    logger::log(logger::DEBUG, "C registerLogicEntity: %d", newEntity->uniqueId);
    INDENT_LOG(logger::DEBUG);

    int uniqueId = newEntity->uniqueId;
    assert(!logicEntities.access(uniqueId));
    logicEntities.access(uniqueId, newEntity);

    logger::log(logger::DEBUG, "C registerLogicEntity completes");
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
    return getLogicEntity(((gameent*)entity)->uid);
}

void LogicSystem::setupExtent(int uid, int type)
{
    logger::log(logger::DEBUG, "setupExtent: %d, %d", uid, type);
    INDENT_LOG(logger::DEBUG);
#ifndef STANDALONE
    extentity *e = new extentity;
    entities::getents().add(e);

    e->type = type;
    e->o = vec(0, 0, 0);
    int numattrs = getattrnum(type);
    for (int i = 0; i < numattrs; ++i) e->attr.add(0);

    addentity(e);
    attachentity(*e);
    e->uid = uid;
    CLogicEntity *newEntity = new CLogicEntity(e);
#else
    CLogicEntity *newEntity = new CLogicEntity();
#endif
    newEntity->uniqueId = uid;
    registerLogicEntity(newEntity);
}

void LogicSystem::setupCharacter(int uid, int cn)
{
    logger::log(logger::DEBUG, "setupCharacter: %d, %d", uid, cn);
    INDENT_LOG(logger::DEBUG);

    #ifndef STANDALONE
        logger::log(logger::DEBUG, "client numbers: %d, %d", ClientSystem::playerNumber, cn);

        if (uid == ClientSystem::uniqueId)
            lua::call_external("entity_set_cn", "ii", uid, (cn = ClientSystem::playerNumber));
    #endif

    assert(cn >= 0);

#ifndef STANDALONE
    gameent* gameEntity;

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
    {
        logger::log(logger::DEBUG, "This is a remote client, do a newClient for the gameent");

        // This is another client. Connect this new client using newClient
        gameEntity = game::newclient(cn);
    }

    // Register with the C++ system.
    gameEntity->uid = uid;
    CLogicEntity *newEntity = new CLogicEntity(gameEntity);
#else
    CLogicEntity *newEntity = new CLogicEntity();
#endif
    newEntity->uniqueId = uid;
    registerLogicEntity(newEntity);
}

void LogicSystem::setupNonSauer(int uid)
{
    logger::log(logger::DEBUG, "setupNonSauer: %d\r\n", uid);
    INDENT_LOG(logger::DEBUG);

    CLogicEntity *newEntity = new CLogicEntity(uid);
    registerLogicEntity(newEntity);
}
