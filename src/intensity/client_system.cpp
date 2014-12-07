
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "of_world.h"

/* the buffer is large enough to hold the uuid */
string ClientSystem::currScenarioCode   = "";

bool _scenarioStarted = false;
bool _mapCompletelyReceived = false;

void ClientSystem::login(int clientNumber)
{
    logger::log(logger::DEBUG, "ClientSystem::login()");
    game::addmsg(N_LOGINREQUEST, "r");
}

void ClientSystem::onDisconnect()
{
    _scenarioStarted  = false;
    _mapCompletelyReceived = false;

    // it's also useful to stop all mapsounds and gamesounds (but only for client that disconnects!)
    stopsounds();

    // we also must get the lua system into clear state
    lua::call_external("entities_remove_all", "");
    lua::reset();
    game::haslogicsys = false;
    lua::call_external("has_logic_sys_set", "b", false);
}

bool ClientSystem::scenarioStarted()
{
    if (!_mapCompletelyReceived)
        logger::log(logger::INFO, "Map not completely received, so scenario not started");

    // If not already started, test if indeed started
    if (_mapCompletelyReceived && !_scenarioStarted)
    {
        if (lua::L) {
            lua::pop_external_ret(lua::call_external_ret("scene_is_ready", "",
                "b", &_scenarioStarted));
        }
    }

    return _mapCompletelyReceived && _scenarioStarted;
}

void ClientSystem::finishLoadWorld()
{
    extern bool finish_load_world();
    finish_load_world();

    _mapCompletelyReceived = true; // We have the original map + static entities (still, scenarioStarted might want more stuff)

    lua::call_external("gui_clear", ""); // (see prepareForMap)
}

void ClientSystem::prepareForNewScenario(const char *sc)
{
    _mapCompletelyReceived = false; // We no longer have a map. This implies scenarioStarted will return false, thus
                                    // stopping sending of position updates, as well as rendering

    setvar("mainmenu", 1); // Keep showing GUI meanwhile (in particular, to show the message about a new map on the way

    // Clear the logic system, as it is no longer valid - were it running, we might try to process messages from
    // the new map being set up on the server, even though they are irrelevant to the existing engine, set up for
    // another map with its Classes etc.
    lua::call_external("entities_remove_all", "");
    game::haslogicsys = false;
    lua::call_external("has_logic_sys_set", "b", false);

    copystring(currScenarioCode, sc);
}

bool ClientSystem::isAdmin()
{
    if (!game::player1) return false;
    bool b;
    lua::pop_external_ret(lua::call_external_ret("entity_get_attr", "is",
        "b", game::player1->uid, "can_edit", &b));
    return b;
}

