
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"

#include "targeting.h"

#include "client_system.h"
#include "of_world.h"

int            ClientSystem::playerNumber       = -1;
CLogicEntity  *ClientSystem::playerLogicEntity  = NULL;
bool           ClientSystem::loggedIn           = false;
bool           ClientSystem::editingAlone       = false;
int            ClientSystem::uniqueId           = -1;
/* the buffer is large enough to hold the uuid */
string         ClientSystem::currScenarioCode   = "";

bool _scenarioStarted = false;
bool _mapCompletelyReceived = false;

void ClientSystem::connect(const char *host, int port)
{
    editingAlone = false;

    connectserv((char *)host, port, "");
}

void ClientSystem::login(int clientNumber)
{
    logger::log(logger::DEBUG, "ClientSystem::login()");

    playerNumber = clientNumber;

    MessageSystem::send_LoginRequest();
}

void ClientSystem::finishLogin(bool local)
{
    editingAlone = local;
    loggedIn = true;

    logger::log(logger::DEBUG, "Now logged in, with unique_ID: %d", uniqueId);
}

void ClientSystem::doDisconnect()
{
    disconnect();
}

void ClientSystem::onDisconnect()
{
    editingAlone = false;
    playerNumber = -1;
    loggedIn     = false;
    _scenarioStarted  = false;
    _mapCompletelyReceived = false;

    // it's also useful to stop all mapsounds and gamesounds (but only for client that disconnects!)
    stopsounds();

    // we also must get the lua system into clear state
    LogicSystem::clear(true);
}

bool ClientSystem::scenarioStarted()
{
    if (!_mapCompletelyReceived)
        logger::log(logger::INFO, "Map not completely received, so scenario not started");

    // If not already started, test if indeed started
    if (_mapCompletelyReceived && !_scenarioStarted)
    {
        if (lua::L) {
            lua::push_external("scene_is_ready"); lua_call(lua::L,  0, 1);
            _scenarioStarted = lua_toboolean(lua::L, -1);
            lua_pop(lua::L, 1);
        }
    }

    return _mapCompletelyReceived && _scenarioStarted;
}

void ClientSystem::frameTrigger(int curtime)
{
    if (scenarioStarted())
    {
        float delta = float(curtime)/1000.0f;

        /* turn if mouse is at borders */
        lua::push_external("cursor_get_position");
        lua_call(lua::L, 0, 2);

        float x = lua_tonumber(lua::L, -2);
        float y = lua_tonumber(lua::L, -1);
        lua_pop(lua::L, 2);

        lua::push_external("cursor_exists");
        lua_call(lua::L, 0, 1);

        bool b = lua_toboolean(lua::L, -1);
        lua_pop(lua::L, 1);

        /* do not scroll with mouse */
        if (b) x = y = 0.5;

        /* turning */
        gameent *fp = (gameent*)player;
        lua::push_external("entity_get_attr");
        lua_rawgeti    (lua::L, LUA_REGISTRYINDEX, ClientSystem::playerLogicEntity->lua_ref);
        lua_pushliteral(lua::L, "facing_speed");
        lua_call       (lua::L,  2, 1);
        float fs = lua_tonumber(lua::L, -1); lua_pop(lua::L, 1);

        if (fp->turn_move || fabs(x - 0.5) > 0.45)
        {
            player->yaw += fs * (
                fp->turn_move ? fp->turn_move : (x > 0.5 ? 1 : -1)
            ) * delta;
        }

        if (fp->look_updown_move || fabs(y - 0.5) > 0.45)
        {
            player->pitch += fs * (
                fp->look_updown_move ? fp->look_updown_move : (y > 0.5 ? -1 : 1)
            ) * delta;
        }

        /* normalize and limit the yaw and pitch values to appropriate ranges */
        extern void fixcamerarange();
        fixcamerarange();

        TargetingControl::determineMouseTarget();
    }
}

void ClientSystem::finishLoadWorld()
{
    extern bool finish_load_world();
    finish_load_world();

    _mapCompletelyReceived = true; // We have the original map + static entities (still, scenarioStarted might want more stuff)

    ClientSystem::editingAlone = false; // Assume not in this mode

    lua::push_external("gui_clear"); lua_call(lua::L, 0, 0); // (see prepareForMap)
}

void ClientSystem::prepareForNewScenario(const char *sc)
{
    _mapCompletelyReceived = false; // We no longer have a map. This implies scenarioStarted will return false, thus
                                    // stopping sending of position updates, as well as rendering

    mainmenu = 1; // Keep showing GUI meanwhile (in particular, to show the message about a new map on the way

    // Clear the logic system, as it is no longer valid - were it running, we might try to process messages from
    // the new map being set up on the server, even though they are irrelevant to the existing engine, set up for
    // another map with its Classes etc.
    LogicSystem::clear();

    copystring(currScenarioCode, sc);
}

bool ClientSystem::isAdmin()
{
    if (!loggedIn) return false;
    if (!playerLogicEntity) return false;

    lua::push_external("entity_get_attr");
    lua_rawgeti    (lua::L, LUA_REGISTRYINDEX, playerLogicEntity->lua_ref);
    lua_pushliteral(lua::L, "can_edit");
    lua_call       (lua::L,  2, 1);
    bool b = lua_toboolean(lua::L, -1); lua_pop(lua::L, 1);
    return b;
}

