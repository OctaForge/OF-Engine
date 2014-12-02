
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"
#include "client_system.h"

// WorldSystem
extern void addentity(extentity* entity);
extern int getattrnum(int type);

//=========================
// LogicSystem
//=========================

bool LogicSystem::initialized = false;

void LogicSystem::clear(bool restart_lua)
{
    logger::log(logger::DEBUG, "clear()ing LogicSystem");
    INDENT_LOG(logger::DEBUG);

    if (lua::L)
    {
        lua::call_external("entities_remove_all", "");
        if (restart_lua) lua::reset();
    }

    LogicSystem::initialized = false;
}

void LogicSystem::init()
{
    lua::init();
    LogicSystem::initialized = true;
}

CLUAICOMMAND(setup_extent, extentity *, (int uid, int type), {
    logger::log(logger::DEBUG, "setup_extent: %d, %d", uid, type);
    INDENT_LOG(logger::DEBUG);
    extentity *e;
    if (type == ET_MAPMODEL) {
        e = new modelentity;
    } else {
        e = new extentity;
    }
    entities::getents().add(e);

    e->type = type;
    e->o = vec(0, 0, 0);
    int numattrs = getattrnum(type);
    for (int i = 0; i < numattrs; ++i) e->attr.add(0);

    addentity(e);
    attachentity(*e);
    e->uid = uid;
    return e;
});

CLUAICOMMAND(setup_character, physent *, (int uid, int cn), {
    logger::log(logger::DEBUG, "setup_character: %d, %d", uid, cn);
    INDENT_LOG(logger::DEBUG);

    logger::log(logger::DEBUG, "client numbers: %d, %d", ClientSystem::playerNumber, cn);

    if (uid == ClientSystem::uniqueId)
        lua::call_external("entity_set_cn", "ii", uid, (cn = ClientSystem::playerNumber));

    assert(cn >= 0);

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
    return gameEntity;
});
